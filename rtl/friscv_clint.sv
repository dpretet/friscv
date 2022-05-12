// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none


///////////////////////////////////////////////////////////////////////////////
// CLINT controller (Core Local Interrupt Controller), implementing next CSRs:
//
//   - MTIME / MTIMECMP (machine time registers)
//   - a platform specific MSIP output to interrupt another hart
//
// Registers mapping:
//
// - 0x00 - 0x03:   MSIP
// - 0x04 - 0x0B:   MTIME
// - 0x0C - 0x13:   MTIMECMP
//
///////////////////////////////////////////////////////////////////////////////


module friscv_clint

    #(
        // APB address width
        parameter ADDRW = 16,
        // Architecture setup
        parameter XLEN = 32
    )(
        // clock & reset
        input  wire                   aclk,
        input  wire                   aresetn,
        input  wire                   srst,
        // APB slave interface
        input  wire                   slv_en,
        input  wire                   slv_wr,
        input  wire  [ADDRW     -1:0] slv_addr,
        input  wire  [XLEN      -1:0] slv_wdata,
        input  wire  [XLEN/8    -1:0] slv_strb,
        output logic [XLEN      -1:0] slv_rdata,
        output logic                  slv_ready,
        // real-time clock, shared across the harts
        input  wire                   rtc,
        // software interrupt 
        output logic                  sw_irq,
        // timer interrupt 
        output logic                  timer_irq
    );

    logic [64   -1:0] mtime;
    logic [64   -1:0] mtimecmp;
    logic [32   -1:0] msip;
    logic             rtc_sync;
    logic             mtime_en;

    assign mtime_en = |mtimecmp;

    // Synchronize the real-time clock tick into the peripheral clock domain
    friscv_bit_sync 
    #(
        .DEPTH (2)
    )
    rtc_synchronizer
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .bit_i   (rtc),
        .bit_o   (rtc_sync)
    );

    generate

    if (XLEN==32) begin: XLEN_32

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            sw_irq <= 1'b0;
            timer_irq <= 1'b0;
            slv_rdata <= {XLEN{1'b0}};
            mtime <= 64'b0;
            mtimecmp <= 64'b0;
            slv_ready <= 1'b0;
        end else if (srst) begin
            sw_irq <= 1'b0;
            timer_irq <= 1'b0;
            mtime <= 64'b0;
            mtimecmp <= 64'b0;
            slv_rdata <= {XLEN{1'b0}};
            slv_ready <= 1'b0;
        end else begin

            // READY assertion
            if (slv_en && ~slv_ready) begin
                slv_ready <= 1'b1;
            end else begin
                slv_ready <= 1'b0;
            end

            // Registers Access
            if (slv_en) begin

                // MSIP register
                if (slv_addr=={ADDRW{1'b0}}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) sw_irq <= slv_wdata[0];
                    end

                    slv_rdata <= {31'h0, sw_irq};

                // MTIME Register, 32 bits LSB
                end else if (slv_addr=={{ADDRW-4{1'b0}},4'h4}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtime[ 0+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtime[ 8+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtime[16+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtime[24+:8] <= slv_wdata[24+:8];
                    end

                    slv_rdata <= mtime[0+:32];

                // MTIME Register, 32 bits MSB
                end else if (slv_addr=={{ADDRW-4{1'b0}},4'h8}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtime[32+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtime[40+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtime[48+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtime[56+:8] <= slv_wdata[24+:8];
                    end

                    slv_rdata <= mtime[32+:32];

                // MTIMECMP Register, 32 bits LSB
                end else if (slv_addr=={{ADDRW-4{1'b0}},4'hC}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtimecmp[ 0+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtimecmp[ 8+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtimecmp[16+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtimecmp[24+:8] <= slv_wdata[24+:8];
                    end 

                    slv_rdata <= mtimecmp[0+:32];

                // MTIMECMP Register, 32 bits MSB
                end else if (slv_addr=={{ADDRW-5{1'b0}},5'h10}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtimecmp[32+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtimecmp[40+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtimecmp[48+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtimecmp[56+:8] <= slv_wdata[24+:8];
                    end

                    slv_rdata <= mtimecmp[32+:32];

                end

            // Execute the timer and its comparator
            end else begin

                if (mtime_en) begin
                    if (rtc_sync)
                        mtime <= mtime + 1;
                end else begin
                    mtime <= 64'b0;
                end

                if (mtime_en) begin
                    if (mtime >= mtimecmp)
                        timer_irq <= 1'b1;
                    else
                        timer_irq <= 1'b0;
                end else begin
                    timer_irq <= 1'b0;
                end
            end
        end
    end
    
    end
    endgenerate

endmodule

`resetall
