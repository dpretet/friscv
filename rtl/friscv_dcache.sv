// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Data cache module
//
// - 2/4/8 way associative placement policy
// - Random replacement policy
// - Parametrizable cache depth
// - Parametrizable cache line width
// - Transparent operation, no need of user management
// - Software-based flush control with FENCE.i instruction
// - Cache control & status observable by a debug interface
// - slave AXI4-lite interface to fetch instructions
// - master AXI4 interface to read central memory
//
///////////////////////////////////////////////////////////////////////////////

module friscv_dcache

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,
        // ID Mask to apply to identify the instruction cache in the AXI4
        // infrastructure
        parameter AXI_ID_MASK = 'h20,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Enable automatic prefetch in memory controller
        parameter CACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of blocks in the cache
        parameter CACHE_DEPTH = 512

    )(
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Flush control
        input  wire                       flush_req,
        output logic                      flush_ack,
        // memfy memory interface
        input  wire                       memfy_awvalid,
        output logic                      memfy_awready,
        input  wire  [AXI_ADDR_W    -1:0] memfy_awaddr,
        input  wire  [3             -1:0] memfy_awprot,
        input  wire  [AXI_ID_W      -1:0] memfy_awid,
        input  wire                       memfy_wvalid,
        output logic                      memfy_wready,
        input  wire  [XLEN          -1:0] memfy_wdata,
        input  wire  [XLEN/8        -1:0] memfy_wstrb,
        output logic                      memfy_bvalid,
        input  wire                       memfy_bready,
        output logic [AXI_ID_W      -1:0] memfy_bid,
        output logic [2             -1:0] memfy_bresp,
        input  wire                       memfy_arvalid,
        output logic                      memfy_arready,
        input  wire  [AXI_ADDR_W    -1:0] memfy_araddr,
        input  wire  [3             -1:0] memfy_arprot,
        input  wire  [AXI_ID_W      -1:0] memfy_arid,
        output logic                      memfy_rvalid,
        input  wire                       memfy_rready,
        output logic [AXI_ID_W      -1:0] memfy_rid,
        output logic [2             -1:0] memfy_rresp,
        output logic [XLEN          -1:0] memfy_rdata,
        // AXI4 Write channels interface to central memory
        output logic                      dcache_awvalid,
        input  wire                       dcache_awready,
        output logic [AXI_ADDR_W    -1:0] dcache_awaddr,
        output logic [8             -1:0] dcache_awlen,
        output logic [3             -1:0] dcache_awsize,
        output logic [2             -1:0] dcache_awburst,
        output logic [2             -1:0] dcache_awlock,
        output logic [4             -1:0] dcache_awcache,
        output logic [3             -1:0] dcache_awprot,
        output logic [4             -1:0] dcache_awqos,
        output logic [4             -1:0] dcache_awregion,
        output logic [AXI_ID_W      -1:0] dcache_awid,
        output logic                      dcache_wvalid,
        input  wire                       dcache_wready,
        output logic                      dcache_wlast,
        output logic [AXI_DATA_W    -1:0] dcache_wdata,
        output logic [AXI_DATA_W/8  -1:0] dcache_wstrb,
        input  wire                       dcache_bvalid,
        output logic                      dcache_bready,
        input  wire  [AXI_ID_W      -1:0] dcache_bid,
        input  wire  [2             -1:0] dcache_bresp,
        // AXI4 Read channels interface to central memory
        output logic                      dcache_arvalid,
        input  wire                       dcache_arready,
        output logic [AXI_ADDR_W    -1:0] dcache_araddr,
        output logic [8             -1:0] dcache_arlen,
        output logic [3             -1:0] dcache_arsize,
        output logic [2             -1:0] dcache_arburst,
        output logic [2             -1:0] dcache_arlock,
        output logic [4             -1:0] dcache_arcache,
        output logic [3             -1:0] dcache_arprot,
        output logic [4             -1:0] dcache_arqos,
        output logic [4             -1:0] dcache_arregion,
        output logic [AXI_ID_W      -1:0] dcache_arid,
        input  wire                       dcache_rvalid,
        output logic                      dcache_rready,
        input  wire  [AXI_ID_W      -1:0] dcache_rid,
        input  wire  [2             -1:0] dcache_rresp,
        input  wire  [AXI_DATA_W    -1:0] dcache_rdata,
        input  wire                       dcache_rlast
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals declarations
    ///////////////////////////////////////////////////////////////////////////

    localparam ADDR_LSB = $clog2(XLEN/8);
    localparam SCALE = AXI_DATA_W / XLEN;
    localparam SCALE_W = $clog2(SCALE);

    logic [AXI_ADDR_W    -1:0] awaddr_w;
    logic [AXI_ADDR_W    -1:0] araddr_w;
    logic [SCALE_W-1:0] wr_position;
    logic [SCALE_W-1:0] rd_position;

    logic                  wch_full;
    logic                  wch_empty;
    logic                  rch_full;
    logic                  rch_empty;


    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    assign flush_ack = 1'b1;


    ///////////////////////////////////////////////////////////////////////////
    // Write Address channel
    ///////////////////////////////////////////////////////////////////////////

    // This FIFO stores the address for write data alignement
    friscv_scfifo
    #(
    .PASS_THRU  (0),
    .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
    .DATA_WIDTH (AXI_ADDR_W)
    )
    wch_addr
    (
    .aclk     (aclk),
    .aresetn  (aresetn),
    .srst     (srst),
    .flush    (1'b0),
    .data_in  (memfy_awaddr),
    .push     (memfy_awvalid & memfy_awready),
    .full     (wch_full),
    .data_out (awaddr_w),
    .pull     (dcache_wvalid & dcache_wready & dcache_wlast),
    .empty    (wch_empty)
    );

    // Drive address channel signals
    assign dcache_awvalid = memfy_awvalid & !wch_full;
    assign memfy_awready = dcache_awready & !wch_full;
    assign dcache_awaddr = memfy_awaddr;
    assign dcache_awlen = 8'h0;
    assign dcache_awburst = 2'b01;
    assign dcache_awid = memfy_awid | AXI_ID_MASK;
    assign dcache_awregion = 4'b0;
    assign dcache_awsize = 3'b0;
    assign dcache_awlock = 2'b0;
    assign dcache_awcache = 4'b0;
    assign dcache_awprot = 3'b0;
    assign dcache_awqos = 4'b0;



    ///////////////////////////////////////////////////////////////////////////
    // Write Data channel
    ///////////////////////////////////////////////////////////////////////////

    assign wr_position = memfy_awaddr[ADDR_LSB+:SCALE_W];

    always @ (*) begin: GEN_WSTRB
        for (int i=0;i<SCALE;i=i+1) begin
            if (i==wr_position) begin: WSTRB_ON
                dcache_wstrb[i*XLEN/8+:XLEN/8] = memfy_wstrb;
            end else begin: WSTRB_OFF
                dcache_wstrb[i*XLEN/8+:XLEN/8] = {XLEN/8{1'b0}};
            end
        end
    end

    assign dcache_wdata = {SCALE{memfy_wdata}};
    assign dcache_wvalid = memfy_wvalid;
    assign memfy_wready = dcache_wready;
    assign dcache_wlast = 1'b1;

    ///////////////////////////////////////////////////////////////////////////
    // Write Reponse channel
    ///////////////////////////////////////////////////////////////////////////

    assign memfy_bvalid = dcache_bvalid;
    assign memfy_bid = dcache_bid;
    assign memfy_bresp = dcache_bresp;
    assign dcache_bready = memfy_bready;

    ///////////////////////////////////////////////////////////////////////////
    // Read Address channel
    ///////////////////////////////////////////////////////////////////////////

    // This FIFO stores the address for read data alignement
    friscv_scfifo
    #(
    .PASS_THRU  (0),
    .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
    .DATA_WIDTH (AXI_ADDR_W)
    )
    rch_addr
    (
    .aclk     (aclk),
    .aresetn  (aresetn),
    .srst     (srst),
    .flush    (1'b0),
    .data_in  (memfy_araddr),
    .push     (memfy_arvalid & memfy_arready),
    .full     (rch_full),
    .data_out (araddr_w),
    .pull     (dcache_rvalid & dcache_rready & dcache_rlast),
    .empty    (rch_empty)
    );

    // Drive address channel signals
    assign dcache_arvalid = memfy_arvalid & !rch_full;
    assign memfy_arready = dcache_arready & !rch_full;
    assign dcache_araddr = memfy_araddr;
    assign dcache_arlen = 8'h0;
    assign dcache_arburst = 2'b01;
    assign dcache_arsize = 3'b0;
    assign dcache_arid = memfy_arid | AXI_ID_MASK;
    assign dcache_arregion = 4'b0;
    assign dcache_arlock = 2'b0;
    assign dcache_arcache = 4'b0;
    assign dcache_arprot = 3'b0;
    assign dcache_arqos = 4'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Read Data channel
    ///////////////////////////////////////////////////////////////////////////

    assign rd_position = araddr_w[ADDR_LSB+:SCALE_W];

    assign memfy_rdata = dcache_rdata[rd_position*XLEN+:XLEN];
    assign memfy_rvalid = dcache_rvalid;
    assign dcache_rready = memfy_rready;
    assign memfy_rid = dcache_rid;
    assign memfy_rresp = dcache_rresp;

endmodule

`resetall

