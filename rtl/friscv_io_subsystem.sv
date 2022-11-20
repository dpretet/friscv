// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

///////////////////////////////////////////////////////////////////////////////
//
// The module enclosing all the low-speed IO cores. It connects through an
// AXI4-lite interface all the modules, usually using an APB interface.
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_io_subsystem

    #(
        parameter ADDRW           = 16,
        parameter DATAW           = 128,
        parameter IDW             = 16,
        parameter XLEN            = 32,
        parameter SLV0_ADDR       = 0,
        parameter SLV0_SIZE       = 8,
        parameter SLV1_ADDR       = 8,
        parameter SLV1_SIZE       = 16,
        parameter SLV2_ADDR       = 32,
        parameter SLV2_SIZE       = 16,
        parameter UART_FIFO_DEPTH = 4
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // real-time clock, shared across the harts for timing
        input  wire                       rtc,
        // AXI4-lite slave interface
        input  wire                       slv_awvalid,
        output logic                      slv_awready,
        input  wire  [ADDRW         -1:0] slv_awaddr,
        input  wire  [3             -1:0] slv_awprot,
        input  wire  [IDW           -1:0] slv_awid,
        input  wire                       slv_wvalid,
        output logic                      slv_wready,
        input  wire  [DATAW         -1:0] slv_wdata,
        input  wire  [DATAW/8       -1:0] slv_wstrb,
        output logic                      slv_bvalid,
        input  wire                       slv_bready,
        output logic [2             -1:0] slv_bresp,
        output logic [IDW           -1:0] slv_bid,
        input  wire                       slv_arvalid,
        output logic                      slv_arready,
        input  wire  [ADDRW         -1:0] slv_araddr,
        input  wire  [3             -1:0] slv_arprot,
        input  wire  [IDW           -1:0] slv_arid,
        output logic                      slv_rvalid,
        input  wire                       slv_rready,
        output logic [2             -1:0] slv_rresp,
        output logic [DATAW         -1:0] slv_rdata,
        output logic [IDW           -1:0] slv_rid,
        // GPIOs interface
        input  wire  [XLEN          -1:0] gpio_in,
        output logic [XLEN          -1:0] gpio_out,
        // UART interface
        input  wire                       uart_rx,
        output logic                      uart_tx,
        output logic                      uart_rts,
        input  wire                       uart_cts,
        // software interrupt
        output logic                      sw_irq,
        // timer interrupt
        output logic                      timer_irq
    );

    ///////////////////////////////////////////////////////////////////////////
    // Logic declaration
    ///////////////////////////////////////////////////////////////////////////

    // Control fsm
    typedef enum logic[1:0] {
        IDLE = 0,
        WAIT_WDATA = 1,
        WAIT_BRESP = 2,
        WAIT_RRESP = 3
    } axi4l_fsm;


    localparam DSCALE = DATAW / XLEN;
    localparam DWIX = $clog2(DSCALE);

    logic              mst_en;
    logic              mst_wr;
    logic [ADDRW -1:0] mst_addr;
    logic [XLEN  -1:0] mst_wdata;
    logic [XLEN/8-1:0] mst_strb;
    logic [XLEN  -1:0] mst_rdata;
    logic              mst_ready;

    logic              slv0_en;
    logic              slv0_wr;
    logic [ADDRW -1:0] slv0_addr;
    logic [XLEN  -1:0] slv0_wdata;
    logic [XLEN/8-1:0] slv0_strb;
    logic [XLEN  -1:0] slv0_rdata;
    logic              slv0_ready;

    logic              slv1_en;
    logic              slv1_wr;
    logic [ADDRW -1:0] slv1_addr;
    logic [XLEN  -1:0] slv1_wdata;
    logic [XLEN/8-1:0] slv1_strb;
    logic [XLEN  -1:0] slv1_rdata;
    logic              slv1_ready;

    logic              slv2_en;
    logic              slv2_wr;
    logic [ADDRW -1:0] slv2_addr;
    logic [XLEN  -1:0] slv2_wdata;
    logic [XLEN/8-1:0] slv2_strb;
    logic [XLEN  -1:0] slv2_rdata;
    logic              slv2_ready;

    logic [DWIX  -1:0] ix;
    logic              misroute;
    axi4l_fsm          cfsm;



    ///////////////////////////////////////////////////////////////////////////
    // FSM converting AXI4-lite to APB
    ///////////////////////////////////////////////////////////////////////////

    always @ (*)
    begin
        if (mst_addr>=SLV0_ADDR && mst_addr<(SLV0_ADDR+SLV0_SIZE)) begin
            misroute = 1'b0;
        end else if (mst_addr>=SLV1_ADDR && mst_addr<(SLV1_ADDR+SLV1_SIZE)) begin
            misroute = 1'b0;
        end else if (mst_addr>=SLV2_ADDR && mst_addr<(SLV2_ADDR+SLV2_SIZE)) begin
            misroute = 1'b0;
        end else begin
            misroute = 1'b1;
        end
    end
    assign ix = slv_awaddr[2+:DWIX];
    assign slv_rresp = (misroute) ? 2'h3 : 2'b0;
    assign slv_bresp = (misroute) ? 2'h3 : 2'b0;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            cfsm <= IDLE;
            slv_awready <= 1'b0;
            slv_arready <= 1'b0;
            slv_wready <= 1'b0;
            slv_rdata <= {DATAW{1'b0}};
            slv_rid <= {IDW{1'b0}};
            slv_bid <= {IDW{1'b0}};
            slv_rvalid <= 1'b0;
            slv_bvalid <= 1'b0;
            mst_en <= 1'b0;
            mst_wr <= 1'b0;
            mst_addr <= {ADDRW{1'b0}};
            mst_wdata <= {XLEN{1'b0}};
            mst_strb <= {XLEN/8{1'b0}};
        end else if (srst) begin
            cfsm <= IDLE;
            slv_awready <= 1'b0;
            slv_arready <= 1'b0;
            slv_wready <= 1'b0;
            slv_rdata <= {DATAW{1'b0}};
            slv_rid <= {IDW{1'b0}};
            slv_bid <= {IDW{1'b0}};
            slv_rvalid <= 1'b0;
            slv_bvalid <= 1'b0;
            mst_en <= 1'b0;
            mst_wr <= 1'b0;
            mst_addr <= {ADDRW{1'b0}};
            mst_wdata <= {XLEN{1'b0}};
            mst_strb <= {XLEN/8{1'b0}};
        end else begin

            case (cfsm)

                // Wait for a read or write request
                IDLE: begin

                    if (slv_awvalid) begin

                        slv_awready <= 1'b1;
                        slv_wready <= 1'b1;
                        mst_addr <= slv_awaddr;
                        slv_bid <= slv_awid;

                        if (!slv_wvalid) begin
                            cfsm <= WAIT_WDATA;
                        end else begin
                            mst_en <= 1'b1;
                            mst_wr <= 1'b1;
                            mst_wdata <= slv_wdata[ix*XLEN+:XLEN];
                            mst_strb <= slv_wstrb[ix*XLEN/8+:XLEN/8];
                            cfsm <= WAIT_BRESP;
                        end

                    end else if (slv_arvalid) begin
                        mst_en <= 1'b1;
                        mst_wr <= 1'b0;
                        mst_addr <= slv_araddr;
                        slv_arready <= 1'b1;
                        slv_rid <= slv_arid;
                        cfsm <= WAIT_RRESP;
                    end
                end

                // In case write data wasn't synchro with aw channel, wait
                // for its assertion, then assert APB request and wait for
                // the handshake
                WAIT_WDATA: begin

                    slv_awready <= 1'b0;

                    if (slv_wvalid) begin
                        slv_wready <= 1'b0;
                        mst_en <= 1'b1;
                        mst_wr <= 1'b1;
                        mst_wdata <= slv_wdata[ix*XLEN+:XLEN];
                        mst_strb <= slv_wstrb[ix*XLEN/8+:XLEN/8];
                    end

                    if (mst_en && mst_ready) begin
                        slv_bvalid <= 1'b1;
                        mst_en <= 1'b0;
                        mst_wr <= 1'b0;
                        cfsm <= WAIT_BRESP;
                    end
                end

                // Handshake with BRESP channel
                WAIT_BRESP: begin

                    slv_awready <= 1'b0;
                    slv_wready <= 1'b0;

                    if (slv_bready) begin
                        slv_bvalid <= 1'b0;
                        cfsm <= IDLE;
                    end
                end

                // Wait APB response to drive AXI4-lite read data channel
                WAIT_RRESP: begin

                    slv_arready <= 1'b0;

                    if (mst_en && mst_ready) begin
                        mst_en <= 1'b0;
                        slv_rvalid <= 1'b1;
                        slv_rdata <= {DSCALE{mst_rdata}};
                    end

                    if (slv_rvalid && slv_rready) begin
                        slv_rvalid <= 1'b0;
                        cfsm <= IDLE;
                    end
                end

            endcase
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Modules' instances
    ///////////////////////////////////////////////////////////////////////////

    friscv_apb_interconnect
    #(
        .ADDRW     (ADDRW),
        .XLEN      (XLEN),
        .SLV0_ADDR (SLV0_ADDR),
        .SLV0_SIZE (SLV0_SIZE),
        .SLV1_ADDR (SLV1_ADDR),
        .SLV1_SIZE (SLV1_SIZE),
        .SLV2_ADDR (SLV2_ADDR),
        .SLV2_SIZE (SLV2_SIZE)
    )
    apb_interconnect
    (
        .aclk       (aclk),
        .aresetn    (aresetn),
        .srst       (srst),
        .slv_en     (mst_en),
        .slv_wr     (mst_wr),
        .slv_addr   (mst_addr),
        .slv_wdata  (mst_wdata),
        .slv_strb   (mst_strb),
        .slv_rdata  (mst_rdata),
        .slv_ready  (mst_ready),
        .mst0_en    (slv0_en),
        .mst0_wr    (slv0_wr),
        .mst0_addr  (slv0_addr),
        .mst0_wdata (slv0_wdata),
        .mst0_strb  (slv0_strb),
        .mst0_rdata (slv0_rdata),
        .mst0_ready (slv0_ready),
        .mst1_en    (slv1_en),
        .mst1_wr    (slv1_wr),
        .mst1_addr  (slv1_addr),
        .mst1_wdata (slv1_wdata),
        .mst1_strb  (slv1_strb),
        .mst1_rdata (slv1_rdata),
        .mst1_ready (slv1_ready),
        .mst2_en    (slv2_en),
        .mst2_wr    (slv2_wr),
        .mst2_addr  (slv2_addr),
        .mst2_wdata (slv2_wdata),
        .mst2_strb  (slv2_strb),
        .mst2_rdata (slv2_rdata),
        .mst2_ready (slv2_ready)
    );


    friscv_gpios
    #(
        .ADDRW (ADDRW),
        .XLEN  (XLEN)
    )
    gpios
    (
        .aclk      (aclk),
        .aresetn   (aresetn),
        .srst      (srst),
        .slv_en    (slv0_en),
        .slv_wr    (slv0_wr),
        .slv_addr  (slv0_addr),
        .slv_wdata (slv0_wdata),
        .slv_strb  (slv0_strb),
        .slv_rdata (slv0_rdata),
        .slv_ready (slv0_ready),
        .gpio_in   (gpio_in),
        .gpio_out  (gpio_out)
    );


    friscv_uart
    #(
        .ADDRW           (ADDRW),
        .XLEN            (XLEN),
        .RXTX_FIFO_DEPTH (UART_FIFO_DEPTH)
    )
    uart
    (
        .aclk      (aclk),
        .aresetn   (aresetn),
        .srst      (srst),
        .slv_en    (slv1_en),
        .slv_wr    (slv1_wr),
        .slv_addr  (slv1_addr),
        .slv_wdata (slv1_wdata),
        .slv_strb  (slv1_strb),
        .slv_rdata (slv1_rdata),
        .slv_ready (slv1_ready),
        .uart_rx   (uart_rx),
        .uart_tx   (uart_tx),
        .uart_rts  (uart_rts),
        .uart_cts  (uart_cts)
    );

    friscv_clint
    #(
        .ADDRW (ADDRW),
        .XLEN  (XLEN)
    )
    clint
    (
        .aclk      (aclk),
        .aresetn   (aresetn),
        .srst      (srst),
        .slv_en    (slv2_en),
        .slv_wr    (slv2_wr),
        .slv_addr  (slv2_addr),
        .slv_wdata (slv2_wdata),
        .slv_strb  (slv2_strb),
        .slv_rdata (slv2_rdata),
        .slv_ready (slv2_ready),
        .rtc       (rtc),
        .sw_irq    (sw_irq),
        .timer_irq (timer_irq)
    );

endmodule

`resetall
