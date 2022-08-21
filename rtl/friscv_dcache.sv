// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Data cache circuit
//
// - Direct-mapped (1-way) placement policy
// - Parametrizable cache depth
// - Parametrizable cache line width
// - Transparent operation, no need of user management
// - IO mapping for direct read/write access to GPIOs and IO peripherals
// - Slave AXI4-lite interface to fetch instructions
// - Master AXI4 interface to read/write the  central memory
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
        // IO regions for direct read/write access
        parameter IO_REGION_NUMBER = 1,
        // IO address ranges, organized by memory region as END-ADDR_START-ADDR:
        // > 0xEND-MEM2_START-MEM2_END_MEM1-STARr-MEM1_END-MEM0_START-MEM0
        // IO mapping can be contiguous or sparse, no restriction on the number,
        // the size or the range if it fits into the XLEN addressable space
        parameter [XLEN*2*IO_REGION_NUMBER-1:0] IO_MAP = 64'h001000FF_00100000,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,
        // ID Mask to apply to identify the data cache in the AXI4 infrastructure
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
        // Global interface
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,

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

        // AXI4 write channels interface to central memory
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

        // AXI4 read channels interface to central memory
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


    // Signals driving the cache blocks
    logic                          memctrl_cache_wen;
    logic [AXI_ADDR_W        -1:0] memctrl_cache_waddr;
    logic [CACHE_BLOCK_W     -1:0] memctrl_cache_wdata;
    logic                          fetcher_cache_ren;
    logic [AXI_ADDR_W        -1:0] fetcher_cache_raddr;
    logic [ILEN              -1:0] fetcher_cache_rdata;
    logic                          fetcher_cache_hit;
    logic                          fetcher_cache_miss;
    logic                          pusher_cache_wen;
    logic [AXI_ADDR_W        -1:0] pusher_cache_waddr;
    logic [CACHE_BLOCK_W     -1:0] pusher_cache_wdata;
    logic [CACHE_BLOCK_W/8   -1:0] pusher_cache_wstrb;
    logic                          pusher_cache_ren;
    logic [AXI_ADDR_W        -1:0] pusher_cache_raddr;
    logic [ILEN              -1:0] pusher_cache_rdata;
    logic                          pusher_cache_hit;
    logic                          pusher_cache_miss;

    logic                          cache_loading;

    // Memory controller interface
    logic                     memctrl_arvalid;
    logic                     memctrl_arready;
    logic [AXI_ADDR_W   -1:0] memctrl_araddr;
    logic [3            -1:0] memctrl_arprot;
    logic [AXI_ID_W     -1:0] memctrl_arid;
    logic                     memctrl_awvalid;
    logic                     memctrl_awready;
    logic [AXI_ADDR_W   -1:0] memctrl_awaddr;
    logic [3            -1:0] memctrl_awprot;
    logic [AXI_ID_W     -1:0] memctrl_awid;
    logic                     memctrl_wvalid;
    logic                     memctrl_wready;
    logic [XLEN         -1:0] memctrl_wdata;
    logic [XLEN/8       -1:0] memctrl_wstrb;
    logic                     memctrl_bvalid;
    logic                     memctrl_bready;
    logic [AXI_ID_W     -1:0] memctrl_bid;
    logic [2            -1:0] memctrl_bresp;

    // Flag to pause fetcher and pusher on concurrent read/write access
    // to ensure the ordering rules are correctly applied
    logic                     pending_rd;
    logic                     pending_wr;
    logic                     flushing;


    ///////////////////////////////////////////////////////////////////////////
    // Cache sequencers, fetcher manages read requests, pusher write requests
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_fetcher
    #(
        .NAME             ("dCache-Fetcher"),
        .ILEN             (ILEN),
        .XLEN             (XLEN),
        .OSTDREQ_NUM      (OSTDREQ_NUM),
        .IO_REGION_NUMBER (IO_REGION_NUMBER),
        .IO_MAP           (IO_MAP),
        .AXI_ADDR_W       (AXI_ADDR_W),
        .AXI_ID_W         (AXI_ID_W),
        .AXI_DATA_W       (AXI_DATA_W)
    )
    fetcher
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .flush_reqs      (1'b0),
        .flush_blocks    (1'b0),
        .flush_ack       (),
        .pending_wr      (pending_wr),
        .pending_rd      (pending_rd),
        .mst_arvalid     (memfy_arvalid),
        .mst_arready     (memfy_arready),
        .mst_araddr      (memfy_araddr),
        .mst_arprot      (memfy_arprot),
        .mst_arid        (memfy_arid),
        .mst_rvalid      (memfy_rvalid),
        .mst_rready      (memfy_rready),
        .mst_rid         (memfy_rid),
        .mst_rresp       (memfy_rresp),
        .mst_rdata       (memfy_rdata),
        .memctrl_arvalid (memctrl_arvalid),
        .memctrl_arready (memctrl_arready),
        .memctrl_araddr  (memctrl_araddr),
        .memctrl_arprot  (memctrl_arprot),
        .memctrl_arid    (memctrl_arid),
        .cache_writing   (memctrl_cache_wen),
        .cache_loading   (cache_loading),
        .cache_ren       (fetcher_cache_ren),
        .cache_raddr     (fetcher_cache_raddr),
        .cache_rdata     (fetcher_cache_rdata),
        .cache_hit       (fetcher_cache_hit),
        .cache_miss      (fetcher_cache_miss)
    );

    friscv_cache_pusher 
    #(
        .ILEN             (ILEN),
        .XLEN             (XLEN),
        .OSTDREQ_NUM      (OSTDREQ_NUM),
        .IO_REGION_NUMBER (IO_REGION_NUMBER),
        .IO_MAP           (IO_MAP),
        .AXI_ADDR_W       (AXI_ADDR_W),
        .AXI_ID_W         (AXI_ID_W),
        .AXI_DATA_W       (AXI_DATA_W),
        .AXI_ID_MASK      (AXI_ID_MASK),
        .CACHE_BLOCK_W    (CACHE_BLOCK_W)
    )
    pusher 
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .pending_wr      (pending_wr),
        .pending_rd      (pending_rd),
        .mst_awvalid     (memfy_awvalid),
        .mst_awready     (memfy_awready),
        .mst_awaddr      (memfy_awaddr),
        .mst_awprot      (memfy_awprot),
        .mst_awid        (memfy_awid),
        .mst_wvalid      (memfy_wvalid),
        .mst_wready      (memfy_wready),
        .mst_wdata       (memfy_wdata),
        .mst_wstrb       (memfy_wstrb),
        .mst_bvalid      (memfy_bvalid),
        .mst_bready      (memfy_bready),
        .mst_bid         (memfy_bid),
        .mst_bresp       (memfy_bresp),
        .memctrl_awvalid (memctrl_awvalid),
        .memctrl_awready (memctrl_awready),
        .memctrl_awaddr  (memctrl_awaddr),
        .memctrl_awprot  (memctrl_awprot),
        .memctrl_awid    (memctrl_awid),
        .memctrl_wvalid  (memctrl_wvalid),
        .memctrl_wready  (memctrl_wready),
        .memctrl_wdata   (memctrl_wdata),
        .memctrl_wstrb   (memctrl_wstrb),
        .memctrl_bvalid  (memctrl_bvalid),
        .memctrl_bready  (memctrl_bready),
        .memctrl_bid     (memctrl_bid),
        .memctrl_bresp   (memctrl_bresp),
        .cache_ren       (pusher_cache_ren),
        .cache_raddr     (pusher_cache_raddr),
        .cache_hit       (pusher_cache_hit),
        .cache_miss      (pusher_cache_miss),
        .cache_wen       (pusher_cache_wen),
        .cache_wstrb     (pusher_cache_wstrb),
        .cache_waddr     (pusher_cache_waddr),
        .cache_wdata     (pusher_cache_wdata)
    );


    ///////////////////////////////////////////////////////////////////////////
    // Cache blocks Storage
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_blocks
    #(
        .ILEN          (ILEN),
        .ADDR_W        (AXI_ADDR_W),
        .CACHE_BLOCK_W (CACHE_BLOCK_W),
        .CACHE_DEPTH   (CACHE_DEPTH)
    )
    cache_blocks
    (
        .aclk       (aclk),
        .aresetn    (aresetn),
        .srst       (srst),
        .flush      (flushing),
        .p1_wen     (memctrl_cache_wen),
        .p1_wstrb   ({CACHE_BLOCK_W/8{1'b1}}),
        .p1_waddr   (memctrl_cache_waddr),
        .p1_wdata   (memctrl_cache_wdata),
        .p1_ren     (fetcher_cache_ren),
        .p1_raddr   (fetcher_cache_raddr),
        .p1_rdata   (fetcher_cache_rdata),
        .p1_hit     (fetcher_cache_hit),
        .p1_miss    (fetcher_cache_miss),
        .p2_wen     (pusher_cache_wen),
        .p2_wstrb   (pusher_cache_wstrb),
        .p2_waddr   (pusher_cache_waddr),
        .p2_wdata   (pusher_cache_wdata),
        .p2_ren     (pusher_cache_ren),
        .p2_raddr   (pusher_cache_raddr),
        .p2_rdata   (),
        .p2_hit     (pusher_cache_hit),
        .p2_miss    (pusher_cache_miss)
    );


    ///////////////////////////////////////////////////////////////////////////
    // AXI4 memory controller to read external memory
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_memctrl
    #(
        .ILEN          (ILEN),
        .XLEN          (XLEN),
        .RW_MODE       (1),
        .OSTDREQ_NUM   (OSTDREQ_NUM),
        .AXI_ADDR_W    (AXI_ADDR_W),
        .AXI_ID_W      (AXI_ID_W),
        .AXI_DATA_W    (AXI_DATA_W),
        .AXI_ID_MASK   (AXI_ID_MASK),
        .CACHE_BLOCK_W (CACHE_BLOCK_W),
        .CACHE_DEPTH   (CACHE_DEPTH)
    )
    mem_ctrl
    (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .srst           (srst),
        .flush_blocks   (1'b0),
        .flush_ack      (),
        .flushing       (flushing),
        .mst_arvalid    (memctrl_arvalid),
        .mst_arready    (memctrl_arready),
        .mst_araddr     (memctrl_araddr),
        .mst_arprot     (memctrl_arprot),
        .mst_arid       (memctrl_arid),
        .mst_awvalid    (memctrl_awvalid),
        .mst_awready    (memctrl_awready),
        .mst_awaddr     (memctrl_awaddr),
        .mst_awprot     (memctrl_awprot),
        .mst_awid       (memctrl_awid),
        .mst_wvalid     (memctrl_wvalid),
        .mst_wready     (memctrl_wready),
        .mst_wdata      (memctrl_wdata),
        .mst_wstrb      (memctrl_wstrb),
        .mst_bvalid     (memctrl_bvalid),
        .mst_bready     (memctrl_bready),
        .mst_bid        (memctrl_bid),
        .mst_bresp      (memctrl_bresp),
        .mem_awvalid    (dcache_awvalid),
        .mem_awready    (dcache_awready),
        .mem_awaddr     (dcache_awaddr),
        .mem_awlen      (dcache_awlen),
        .mem_awsize     (dcache_awsize),
        .mem_awburst    (dcache_awburst),
        .mem_awlock     (dcache_awlock),
        .mem_awcache    (dcache_awcache),
        .mem_awprot     (dcache_awprot),
        .mem_awqos      (dcache_awqos),
        .mem_awregion   (dcache_awregion),
        .mem_awid       (dcache_awid),
        .mem_wvalid     (dcache_wvalid),
        .mem_wready     (dcache_wready),
        .mem_wlast      (dcache_wlast),
        .mem_wdata      (dcache_wdata),
        .mem_wstrb      (dcache_wstrb),
        .mem_bvalid     (dcache_bvalid),
        .mem_bready     (dcache_bready),
        .mem_bid        (dcache_bid),
        .mem_bresp      (dcache_bresp),
        .mem_arvalid    (dcache_arvalid),
        .mem_arready    (dcache_arready),
        .mem_araddr     (dcache_araddr),
        .mem_arlen      (dcache_arlen),
        .mem_arsize     (dcache_arsize),
        .mem_arburst    (dcache_arburst),
        .mem_arlock     (dcache_arlock),
        .mem_arcache    (dcache_arcache),
        .mem_arprot     (dcache_arprot),
        .mem_arqos      (dcache_arqos),
        .mem_arregion   (dcache_arregion),
        .mem_arid       (dcache_arid),
        .mem_rvalid     (dcache_rvalid),
        .mem_rready     (dcache_rready),
        .mem_rid        (dcache_rid),
        .mem_rresp      (dcache_rresp),
        .mem_rdata      (dcache_rdata),
        .mem_rlast      (dcache_rlast),
        .cache_loading  (cache_loading),
        .cache_wen      (memctrl_cache_wen),
        .cache_waddr    (memctrl_cache_waddr),
        .cache_wdata    (memctrl_cache_wdata)
    );

endmodule

`resetall
