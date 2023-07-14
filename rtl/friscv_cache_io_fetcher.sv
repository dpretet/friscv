// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none
`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////
//
// Fetcher stage: manages the read request in the IO ranges. No more than
// a FIFO instance to buffer read outstanding requests
//
///////////////////////////////////////////////////////////////////////////


module friscv_cache_io_fetcher

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Name used for tracer file name
        parameter NAME = "io-fetcher",
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for AXI4 to central memory
        parameter AXI_ADDR_W = 32,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8

    )(
        // Clock / Reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,

        // Control unit interface
        input  wire                       mst_arvalid,
        output logic                      mst_arready,
        input  wire  [AXI_ADDR_W    -1:0] mst_araddr,
        input  wire  [3             -1:0] mst_arprot,
        input  wire  [AXI_ID_W      -1:0] mst_arid,

        // Memory controller read interface
        output logic                      memctrl_arvalid,
        input  wire                       memctrl_arready,
        output logic [AXI_ADDR_W    -1:0] memctrl_araddr,
        output logic [3             -1:0] memctrl_arprot,
        output logic [AXI_ID_W      -1:0] memctrl_arid
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    ///////////////////////////////////////////////////////////////////////////

    localparam PASS_THRU_MODE = 0;

    logic fifo_full;
    logic fifo_empty;

    // Tracer setup
    `ifdef TRACE_CACHE
    string fname;
    integer f;
    initial begin
        $sformat(fname, "trace_%s.txt", NAME);
        f = $fopen(fname, "w");
    end
    `endif

    ///////////////////////////////////////////////////////////////////////////
    // Read address channel
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .PASS_THRU (PASS_THRU_MODE),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (3+AXI_ADDR_W+AXI_ID_W)
    )
    if_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({mst_arprot, mst_arid, mst_araddr}),
        .push     (mst_arvalid),
        .full     (fifo_full),
        .afull    (),
        .data_out ({memctrl_arprot, memctrl_arid, memctrl_araddr}),
        .pull     (memctrl_arready),
        .empty    (fifo_empty),
        .aempty   ()
    );

    assign mst_arready = !fifo_full;
    assign memctrl_arvalid = !fifo_empty;

endmodule

`resetall
