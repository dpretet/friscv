// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"


///////////////////////////////////////////////////////////////////////////////
// CLINT controller (Core Local Interrupt Controller), implementing next CSRs:
//
//   - MTIME / MTIMECMP (machine time registers)
//   - a platform specific MSIP output to interrupt another hart
//
// Registers mapping:
//
// - 0x00 - 0x07:   MSIP output
// - 0x08 - 0x0F:   MTIME
// - 0x10 - 0x17:   MTIMECMP
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
        input  logic                  aclk,
        input  logic                  aresetn,
        input  logic                  srst,
        // APB slave interface
        input  logic                  slv_en,
        input  logic                  slv_wr,
        input  logic [ADDRW     -1:0] slv_addr,
        input  logic [XLEN      -1:0] slv_wdata,
        input  logic [XLEN/8    -1:0] slv_strb,
        output logic [XLEN      -1:0] slv_rdata,
        output logic                  slv_ready,
        // real-time clock, shared across the harts
        input  logic                  rtc,
        // software interrupt 
        output logic                  sw_irq,
        // timer interrupt 
        output logic                  timer_irq
    );

    logic [64   -1:0] mtime;
    logic [64   -1:0] mtimecmp;
    logic [32   -1:0] msip;
    logic             rtc_sync;

    // Synchronize the real-time clock tick into the core clock domain
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
            slv_ready <= 1'b0;
        end else if (srst) begin
            sw_irq <= 1'b0;
            timer_irq <= 1'b0;
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
                    end else begin
                        slv_rdata <= {31'h0, sw_irq};
                    end

                // MTIME Register, 32 bits LSB
                end else if (slv_addr=={{ADDRW-4{1'b0}},4'h8}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtime[ 0+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtime[ 8+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtime[16+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtime[24+:8] <= slv_wdata[24+:8];
                    end else begin
                        slv_rdata <= mtime[0+:32];
                    end

                // MTIME Register, 32 bits MSB
                end else if (slv_addr=={{ADDRW-4{1'b0}},4'hC}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtime[32+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtime[40+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtime[48+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtime[56+:8] <= slv_wdata[24+:8];
                    end else begin
                        slv_rdata <= mtime[32+:32];
                    end

                // MTIMECMP Register, 32 bits LSB
                end else if (slv_addr=={{ADDRW-5{1'b0}},5'h10}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtimecmp[ 0+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtimecmp[ 8+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtimecmp[16+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtimecmp[24+:8] <= slv_wdata[24+:8];
                    end else begin
                        slv_rdata <= mtimecmp[0+:32];
                    end

                // MTIMECMP Register, 32 bits MSB
                end else if (slv_addr=={{ADDRW-5{1'b0}},5'h14}) begin

                    if (slv_wr) begin
                        if (slv_strb[0]) mtimecmp[32+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) mtimecmp[40+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) mtimecmp[48+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) mtimecmp[56+:8] <= slv_wdata[24+:8];
                    end else begin
                        slv_rdata <= mtimecmp[32+:32];
                    end

                end

            // Execute the timer and its comparator
            end else begin

                if (rtc_sync) begin
                    mtime <= mtime + 1;
                end

                if (mtime >= mtimecmp) begin
                    timer_irq <= 1'b1;
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
