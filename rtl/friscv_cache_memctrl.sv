// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Memory controller managing AXI4-lite read request from Fetcher to read
// central memory to fill caches lines.
//
// TODO: Support AXI4 transfer with different width than the cache block width
// TODO: Support width adaptation between ctrl and memory (a5f613f50f861)
// TODO: Support Wrap mode for read channel
// TODO: Manage RRESP
// TODO: Add tracer
//
///////////////////////////////////////////////////////////////////////////////

module friscv_cache_memctrl

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////
        
        // Module name for printing
        parameter NAME = "Cache-MemCtrl",
        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Generate a write channel, 0=read-only, 1=read-write
        parameter RW_MODE = 0,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 10,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 128,
        // Use original ID issued or fix it to ensure in-order execution
        parameter AXI_IN_ORDER = 1,
        // ID Mask to apply to identify the data cache in the AXI4 infrastructure
        parameter AXI_ID_MASK = 'h20,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Cache block width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128

    )(
        // Global signals
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // ctrl read address interface
        input  wire                       mst_arvalid,
        output logic                      mst_arready,
        input  wire  [AXI_ADDR_W    -1:0] mst_araddr,
        input  wire  [3             -1:0] mst_arprot,
        input  wire  [4             -1:0] mst_arcache,
        input  wire  [AXI_ID_W      -1:0] mst_arid,
        // Control read completion
        output logic                      mst_rvalid,
        input  wire                       mst_rready,
        output logic                      mst_rcache,
        output logic [AXI_ADDR_W    -1:0] mst_raddr,
        output logic [AXI_ID_W      -1:0] mst_rid,
        output logic [2             -1:0] mst_rresp,
        output logic [CACHE_BLOCK_W -1:0] mst_rdata_blk,
        output logic [XLEN          -1:0] mst_rdata,
        // ctrl write interface
        input  wire                       mst_awvalid,
        output logic                      mst_awready,
        input  wire  [AXI_ADDR_W    -1:0] mst_awaddr,
        input  wire  [3             -1:0] mst_awprot,
        input  wire  [4             -1:0] mst_awcache,
        input  wire  [AXI_ID_W      -1:0] mst_awid,
        input  wire                       mst_wvalid,
        output logic                      mst_wready,
        input  wire  [XLEN          -1:0] mst_wdata,
        input  wire  [XLEN/8        -1:0] mst_wstrb,
        output logic [AXI_ID_W      -1:0] mst_bid,
        output logic [2             -1:0] mst_bresp,
        output logic                      mst_bvalid,
        input  wire                       mst_bready,
        // AXI4 Write channels interface to central memory
        output logic                      mem_awvalid,
        input  wire                       mem_awready,
        output logic [AXI_ADDR_W    -1:0] mem_awaddr,
        output logic [8             -1:0] mem_awlen,
        output logic [3             -1:0] mem_awsize,
        output logic [2             -1:0] mem_awburst,
        output logic [2             -1:0] mem_awlock,
        output logic [4             -1:0] mem_awcache,
        output logic [3             -1:0] mem_awprot,
        output logic [4             -1:0] mem_awqos,
        output logic [4             -1:0] mem_awregion,
        output logic [AXI_ID_W      -1:0] mem_awid,
        output logic                      mem_wvalid,
        input  wire                       mem_wready,
        output logic                      mem_wlast,
        output logic [AXI_DATA_W    -1:0] mem_wdata,
        output logic [AXI_DATA_W/8  -1:0] mem_wstrb,
        input  wire                       mem_bvalid,
        output logic                      mem_bready,
        input  wire  [AXI_ID_W      -1:0] mem_bid,
        input  wire  [2             -1:0] mem_bresp,
        // AXI4 Read channels interface to central memory
        output logic                      mem_arvalid,
        input  wire                       mem_arready,
        output logic [AXI_ADDR_W    -1:0] mem_araddr,
        output logic [8             -1:0] mem_arlen,
        output logic [3             -1:0] mem_arsize,
        output logic [2             -1:0] mem_arburst,
        output logic [2             -1:0] mem_arlock,
        output logic [4             -1:0] mem_arcache,
        output logic [3             -1:0] mem_arprot,
        output logic [4             -1:0] mem_arqos,
        output logic [4             -1:0] mem_arregion,
        output logic [AXI_ID_W      -1:0] mem_arid,
        input  wire                       mem_rvalid,
        output logic                      mem_rready,
        input  wire  [AXI_ID_W      -1:0] mem_rid,
        input  wire  [2             -1:0] mem_rresp,
        input  wire  [AXI_DATA_W    -1:0] mem_rdata,
        input  wire                       mem_rlast
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    // Used along the module to buffer the outstanding requests' IDs
    localparam NB_TAG_W = $clog2(OSTDREQ_NUM);
    // Lowest part of the address replaced by 0 to access a complete cache block
    // (AXI_DATA_W = CACHE_BLOCK_W is the only setup supported)
    localparam ADDR_LSB_W = $clog2(AXI_DATA_W/8);

    // Offset part into address to index a DWORD or QWORD
    localparam SCALE = AXI_DATA_W / XLEN;
    localparam OFFSET_IX = (XLEN==32) ? 2 : 3;
    localparam OFFSET_W = $clog2(SCALE);

    // Used on flush request to erase the cache content
    logic [AXI_ADDR_W-1:0] araddr;
    logic [3         -1:0] asize;
    logic                  arcache;
    logic [OFFSET_W  -1:0] roffset;
    logic                  rch_full;
    logic                  wch_full;
    logic                  rch_empty;
    logic                  wch_empty;
    logic                  wch_aempty;
    logic                  push_woffset;
    logic                  push_woffset_r;
    logic                  pull_woffset;

    logic [OFFSET_W  -1:0] wr_strb_pos;
    logic [OFFSET_W  -1:0] woffset;
    logic [OFFSET_W  -1:0] woffset_r;

    logic [AXI_ID_W  -1:0] arid_m;
    logic [AXI_ID_W  -1:0] rid_m;

    ///////////////////////////////////////////////////////////////////////////
    // Fixed ASIZE, narrow transfers are not supported neither necessary
    ///////////////////////////////////////////////////////////////////////////

    assign asize = (AXI_DATA_W/8 ==  1) ? 3'b000:
                   (AXI_DATA_W/8 ==  2) ? 3'b001:
                   (AXI_DATA_W/8 ==  4) ? 3'b010:
                   (AXI_DATA_W/8 ==  8) ? 3'b011:
                   (AXI_DATA_W/8 == 16) ? 3'b100:
                   (AXI_DATA_W/8 == 32) ? 3'b101:
                   (AXI_DATA_W/8 == 64) ? 3'b110:
                                          3'b111;

    ///////////////////////////////////////////////////////////////////////////
    // Optional signals, unused and tied to recommended default values
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arregion = 4'b0;
    assign mem_arlock = 2'b0;
    assign mem_arcache = 4'b0;
    assign mem_arqos = 4'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    // Always use INCR mode
    assign mem_arburst = 2'b01;

    // Issue only transfer with a single dataphase
    assign mem_arlen = 8'b0;

    // Fixed ASIZE, narrow transfers are not supported neither necessary
    assign mem_arsize = asize;


    ///////////////////////////////////////////////////////////////////////////
    // Drive AXI4 read address channel directly from AXI4-lite
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arvalid = mst_arvalid;
    assign mst_arready = mem_arready && !rch_full;

    assign mem_araddr = mst_araddr;
    assign mem_arprot = mst_arprot;
    assign mem_arid = mst_arid;

    generate
    if (AXI_IN_ORDER>0) begin: IN_ORDER_CPL

        friscv_scfifo
        #(
            .PASS_THRU  (0),
            .ADDR_WIDTH (NB_TAG_W),
            .DATA_WIDTH (AXI_ADDR_W + 1 /*ARCACHE[1]*/)
        )
        araddr_fifo
        (
            .aclk     (aclk),
            .aresetn  (aresetn),
            .srst     (srst),
            .flush    (1'b0),
            .data_in  ({mst_arcache[1], mst_araddr}),
            .push     (mst_arvalid & mst_arready),
            .full     (rch_full),
            .afull    (),
            .data_out ({arcache, araddr}),
            .pull     (mem_rvalid & mem_rready),
            .empty    (rch_empty),
            .aempty   ()
        );

        assign arid_m = {AXI_ID_W{1'b0}};
        assign rid_m = {AXI_ID_W{1'b0}};
    
    end else begin

        friscv_ram
        #(
            .ADDR_WIDTH (NB_TAG_W),
            .DATA_WIDTH (AXI_ADDR_W + 1 /*ARCACHE[1]*/)
        )
        araddr_ram
        (
            .aclk       (aclk),
            .wr_en      (mst_arvalid & mst_arready),
            .addr_in    (arid_m[NB_TAG_W-1:0]),
            .data_in    ({mst_arcache[1], mst_araddr}),
            .addr_out   (rid_m[NB_TAG_W-1:0]),
            .data_out   ({arcache, araddr})
        );

        // Remove the ID mask before parsing the RAM while expecting IDs
        // numbered from 0
        assign arid_m = mst_arid ^ AXI_ID_MASK;
        assign rid_m = mst_rid ^ AXI_ID_MASK;

        assign rch_full = 1'b0;
        assign rch_empty = 1'b0;

    end
    endgenerate


    // Offset to use for RDATA extraction whithin the cache block
    assign roffset = araddr[OFFSET_IX+:OFFSET_W];

    `ifdef FRISCV_SIM
    always @ (posedge aclk) begin
        if (mem_rvalid && rch_empty && (aresetn && !srst))
            $display("ERROR: (@ %t) %s - Receive an unexpected read request", $realtime, NAME);
    end
    `endif


    ///////////////////////////////////////////////////////////////////////////
    // Read completion channel, used also as a cache block write interface
    //
    // Add extra signals for cache write purpose:
    //
    //  - raddr: the original ARADDR of the request to drive cache write interface
    //  - rcache: ARCACHE[1], used to drive IO request to cache completion
    //    channel and so bypass the cache blocks
    //  - rdata_blk: the whole address line fetched, the controller always
    //    read a whole block
    //  - rdata: RDATA extracted from the interface to match the exact address 
    //    while we always fetch a whole cache block. Make the controller usable 
    //    for both instruction and data cache
    ///////////////////////////////////////////////////////////////////////////

    assign mst_rvalid = mem_rvalid;
    assign mem_rready = mst_rready;
    assign mst_rid = mem_rid ;
    assign mst_rresp = mem_rresp;
    assign mst_rdata = mem_rdata[XLEN*roffset+:XLEN];
    // custom signals
    assign mst_raddr = araddr;
    assign mst_rcache = (rch_empty) ? 1'b0 : arcache;
    assign mst_rdata_blk = mem_rdata;


    ///////////////////////////////////////////////////////////////////////////
    // Write channels
    ///////////////////////////////////////////////////////////////////////////
    generate if (RW_MODE) begin : WRITE_CHANNELS

        // Write address channel
        assign mem_awvalid = mst_awvalid & !wch_full;
        assign mst_awready = mem_awready & !wch_full;
        assign mem_awaddr = mst_awaddr;
        // Single beat request
        assign mem_awlen = 8'b0;
        // No narrow request support
        assign mem_awsize = asize;
        // Always use INCR mode
        assign mem_awburst = 2'b1;
        // Unused features
        assign mem_awlock = 2'b0;
        assign mem_awcache = 4'b0;
        assign mem_awprot = mst_awprot;
        assign mem_awqos = 4'b0;
        assign mem_awregion = 4'b0;
        assign mem_awid = mst_awid;

        // Write data channel
        assign mem_wvalid = mst_wvalid & !wch_full;
        assign mst_wready = mem_wready & !wch_full;
        assign mem_wlast = 1'b1;
        assign mem_wdata = {SCALE{mst_wdata}};

        always @ (*) begin: GEN_WSTRB
            for (int i=0;i<SCALE;i=i+1) begin
                if (i==wr_strb_pos) begin: WSTRB_ON
                    mem_wstrb[i*XLEN/8+:XLEN/8] = mst_wstrb;
                end else begin: WSTRB_OFF
                    mem_wstrb[i*XLEN/8+:XLEN/8] = {XLEN/8{1'b0}};
                end
            end
        end


        friscv_scfifo
        #(
            .PASS_THRU  (0),
            .ADDR_WIDTH (NB_TAG_W),
            .DATA_WIDTH (OFFSET_W)
        )
        wroffset_fifo
        (
            .aclk     (aclk),
            .aresetn  (aresetn),
            .srst     (srst),
            .flush    (1'b0),
            .data_in  (woffset),
            .push     (push_woffset),
            .full     (wch_full),
            .afull    (),
            .data_out (woffset_r),
            .pull     (pull_woffset),
            .empty    (wch_empty),
            .aempty   (wch_aempty)
        );

        assign woffset = mst_awaddr[OFFSET_IX+:OFFSET_W];

        // Push in the FIFO if data channel not ready or if previous request on data channel has
        // been stalled
        assign push_woffset = mem_awvalid & mem_awready & (mem_wvalid & (!mem_wready | push_woffset_r));
        assign pull_woffset = mem_wvalid & mem_wready & push_woffset_r;
        assign wr_strb_pos = (wch_empty) ? woffset : woffset_r;

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                push_woffset_r <= 1'b0;
            end else if (srst) begin
                push_woffset_r <= 1'b0;
            end else begin
                if (mem_awvalid && mem_awready && (mem_wvalid && !mem_wready)) begin
                    push_woffset_r <= 1'b1;
                end else if (wch_aempty && pull_woffset && !push_woffset) begin
                    push_woffset_r <= 1'b0;
                end
            end
        end

        // Write response channel
        assign mst_bvalid = mem_bvalid;
        assign mst_bresp = mem_bresp;
        assign mst_bid = mem_bid;
        assign mem_bready = mst_bready;

    end else begin

        assign mem_awvalid = 1'b0;
        assign mem_awaddr = {AXI_ADDR_W{1'b0}};
        assign mem_awlen = 8'b0;
        assign mem_awsize = 3'b0;
        assign mem_awburst = 2'b0;
        assign mem_awlock = 2'b0;
        assign mem_awcache = 4'b0;
        assign mem_awprot = 3'b0;
        assign mem_awqos = 4'b0;
        assign mem_awregion = 4'b0;
        assign mem_awid = {AXI_ID_W{1'b0}};
        assign mem_wvalid = 1'b0;
        assign mem_wlast = 1'b0;
        assign mem_wdata = {AXI_DATA_W{1'b0}};
        assign mem_wstrb = {AXI_DATA_W/8{1'b0}};
        assign mem_bready = 1'b1;
        assign wr_strb_pos = {OFFSET_W{1'b0}};
        assign woffset = {OFFSET_W{1'b0}};
        assign woffset_r = {OFFSET_W{1'b0}};
        assign wch_full = 1'b0;
        assign wch_empty = 1'b0;
        assign wch_aempty = 1'b0;
        assign push_woffset = 1'b0;
        assign push_woffset_r = 1'b0;
        assign pull_woffset = 1'b0;
    end
    endgenerate

endmodule

`resetall
