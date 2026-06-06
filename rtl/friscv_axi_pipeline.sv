// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_axi_pipeline
    #(
        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // AXI R / W address channel width, all signals concatenated
        parameter AXI_ACH_W = 32,
        // AXI R / W data channel width, all signals concatenated
        parameter AXI_DCH_W = 128,
        // AXI B response channel width, all signals concatenated
        parameter AXI_BCH_W = 128,
        // AXI R response channel width, all signals concatenated
        parameter AXI_RCH_W = 128
    )(
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        input  wire                       flush,

        input  wire                       s_awvalid,
        output logic                      s_awready,
        input  wire  [AXI_ACH_W     -1:0] s_awch,
        input  wire                       s_wvalid,
        output logic                      s_wready,
        input  wire  [AXI_DCH_W     -1:0] s_wch,
        output logic                      s_bvalid,
        input  wire                       s_bready,
        output logic [AXI_BCH_W     -1:0] s_bch,
        input  wire                       s_arvalid,
        output logic                      s_arready,
        input  wire  [AXI_ACH_W     -1:0] s_arch,
        output logic                      s_rvalid,
        input  wire                       s_rready,
        output logic [AXI_RCH_W     -1:0] s_rch,

        output logic                      m_awvalid,
        input  wire                       m_awready,
        output logic [AXI_ACH_W     -1:0] m_awch,
        output logic                      m_wvalid,
        input  wire                       m_wready,
        output logic [AXI_DCH_W     -1:0] m_wch,
        input  wire                       m_bvalid,
        output logic                      m_bready,
        input  wire  [AXI_BCH_W     -1:0] m_bch,
        output logic                      m_arvalid,
        input  wire                       m_arready,
        output logic [AXI_ACH_W     -1:0] m_arch,
        input  wire                       m_rvalid,
        output logic                      m_rready,
        input  wire  [AXI_RCH_W     -1:0] m_rch
    );

    localparam OR_NUM_W = $clog2(OSTDREQ_NUM);

    logic                aw_full;
    logic                aw_empty;
    logic                w_full;
    logic                w_empty;
    logic                b_full;
    logic                b_empty;
    logic                ar_full;
    logic                ar_empty;
    logic                r_full;
    logic                r_empty;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (AXI_ACH_W)
    )
    awfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  (s_awch),
        .push     (s_awvalid),
        .full     (aw_full),
        .afull    (),
        .data_out (m_awch),
        .pull     (m_awready),
        .empty    (aw_empty),
        .aempty   ()
    );

    assign s_awready = !aw_full;
    assign m_awvalid = !aw_empty;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (AXI_DCH_W)
    )
    wfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  (s_wch),
        .push     (s_wvalid),
        .full     (w_full),
        .afull    (),
        .data_out (m_wch),
        .pull     (m_wready),
        .empty    (w_empty),
        .aempty   ()
    );

    assign s_wready = !w_full;
    assign m_wvalid = !w_empty;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (AXI_BCH_W)
    )
    bfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  (m_bch),
        .push     (m_bvalid),
        .full     (b_full),
        .afull    (),
        .data_out (s_bch),
        .pull     (s_bready),
        .empty    (b_empty),
        .aempty   ()
    );

    assign m_bready = !b_full;
    assign s_bvalid = !b_empty;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (AXI_ACH_W)
    )
    arfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  (s_arch),
        .push     (s_arvalid),
        .full     (ar_full),
        .afull    (),
        .data_out (m_arch),
        .pull     (m_arready),
        .empty    (ar_empty),
        .aempty   ()
    );

    assign s_arready = !ar_full;
    assign m_arvalid = !ar_empty;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (AXI_RCH_W)
    )
    rfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  (m_rch),
        .push     (m_rvalid),
        .full     (r_full),
        .afull    (),
        .data_out (s_rch),
        .pull     (s_rready),
        .empty    (r_empty),
        .aempty   ()
    );

    assign m_rready = !r_full;
    assign s_rvalid = !r_empty;




endmodule

`resetall

