// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"
`include "friscv_checkers.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Data cache circuit
//
// - Direct-mapped (1-way) placement policy
// - Write-through policy, updating central memory when updating cache blocks
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

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 32,
        // AXI ID width
        parameter AXI_ID_W = 8,
        // AXI4 data width, to setup to cache block width
        parameter AXI_DATA_W = 128,
        // ID Mask used to identify the data cache in the AXI4 infrastructure
        parameter AXI_ID_MASK = 'h40,
        // AXI ID issued on slave interface is fixed, save some logic
        parameter AXI_ID_FIXED = 1,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // IO regions for direct read/write access
        parameter IO_MAP_NB = 1,
        // Bypass if possible the OoO output RAM stage. Imply the completion path
        // will be combinatorial but reduce the latency, increase the bandwidth
        parameter FAST_FWD_CPL = 1,
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
        output logic                      cache_ready,

        // memfy memory interface
        input  wire                       memfy_awvalid,
        output logic                      memfy_awready,
        input  wire  [AXI_ADDR_W    -1:0] memfy_awaddr,
        input  wire  [3             -1:0] memfy_awprot,
        input  wire  [4             -1:0] memfy_awcache,
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
        input  wire  [4             -1:0] memfy_arcache,
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

    logic                          fetcher_cache_ren;
    logic [AXI_ADDR_W        -1:0] fetcher_cache_raddr;
    logic [ILEN              -1:0] fetcher_cache_rdata;
    logic [AXI_ID_W          -1:0] fetcher_cache_rid;
    logic [3                 -1:0] fetcher_cache_rprot;
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

    // Memory controller interface
    logic                          memfy_arvalid_io;
    logic                          memfy_arvalid_blk;
    logic                          memfy_arready_io;
    logic                          memfy_arready_blk;

    logic                          blk_fetcher_arvalid;
    logic                          blk_fetcher_arready;
    logic [AXI_ADDR_W        -1:0] blk_fetcher_araddr;
    logic [3                 -1:0] blk_fetcher_arprot;
    logic [AXI_ID_W          -1:0] blk_fetcher_arid;

    logic                          blk_fetcher_rvalid;
    logic                          blk_fetcher_rready;
    logic [XLEN              -1:0] blk_fetcher_rdata;
    logic [AXI_ID_W          -1:0] blk_fetcher_rid;
    logic [2                 -1:0] blk_fetcher_rresp;

    logic                          io_fetcher_arvalid;
    logic                          io_fetcher_arready;
    logic [AXI_ADDR_W        -1:0] io_fetcher_araddr;
    logic [3                 -1:0] io_fetcher_arprot;
    logic [AXI_ID_W          -1:0] io_fetcher_arid;

    logic                          memctrl_arvalid;
    logic                          memctrl_arready;
    logic [AXI_ADDR_W        -1:0] memctrl_araddr;
    logic [3                 -1:0] memctrl_arprot;
    logic [4                 -1:0] memctrl_arcache;
    logic [AXI_ID_W          -1:0] memctrl_arid;

    logic                          memctrl_awvalid;
    logic                          memctrl_awready;
    logic [AXI_ADDR_W        -1:0] memctrl_awaddr;
    logic [3                 -1:0] memctrl_awprot;
    logic [AXI_ID_W          -1:0] memctrl_awid;

    logic                          memctrl_wvalid;
    logic                          memctrl_wready;
    logic [XLEN              -1:0] memctrl_wdata;
    logic [XLEN/8            -1:0] memctrl_wstrb;

    logic                          memctrl_bvalid;
    logic                          memctrl_bready;
    logic [AXI_ID_W          -1:0] memctrl_bid;
    logic [2                 -1:0] memctrl_bresp;

    logic                          memctrl_rvalid;
    logic                          memctrl_rcache;
    logic                          memctrl_rready;
    logic [AXI_ADDR_W        -1:0] memctrl_raddr;
    logic [CACHE_BLOCK_W     -1:0] memctrl_rdata_blk;
    logic [XLEN              -1:0] memctrl_rdata;
    logic [AXI_ID_W          -1:0] memctrl_rid;
    logic [2                 -1:0] memctrl_rresp;
    // flag to indicate a flush request is under execution
    logic                          flushing;
    // mix of ready flags between fetchers and read completer
    logic                          memfy_arready_w;
    logic                          memfy_awready_w;
    logic                          rtag_avlb;
    logic                          wtag_avlb;
    // substituted tags, provided by the Out-of-Order managers if present
    logic [AXI_ID_W          -1:0] memfy_arid_w;
    logic [AXI_ID_W          -1:0] memfy_awid_w;
    logic [AXI_ID_W          -1:0] memfy_arid_next;
    logic [AXI_ID_W          -1:0] memfy_awid_next;
    // pusher write response channel
    logic                          pusher_bvalid;
    logic                          pusher_bready;
    logic [AXI_ID_W          -1:0] pusher_bid;
    logic [2                 -1:0] pusher_bresp;
    // cache write interface
    logic                          cache_wren;
    logic [AXI_ADDR_W        -1:0] cache_waddr;
    logic [CACHE_BLOCK_W     -1:0] cache_wdata;

    // flag from prefetch to indicate the cache-miss block is under Write
    logic                          block_fill;


    ///////////////////////////////////////////////////////////////////////////
    // Parameters setup checks
    ///////////////////////////////////////////////////////////////////////////

    initial begin
        `CHECKER((OSTDREQ_NUM%2 != 0), "OSTDREQ_NUM must be a power of two");
    end


    ///////////////////////////////////////////////////////////////////////////
    // Cache fetchers, IO and block
    ///////////////////////////////////////////////////////////////////////////

    // Multiplex read requests between IO and block fetcher based on cachable
    // property of the requets

    generate
    if (IO_MAP_NB > 0) begin: ARCH_MEMFY_MUX

        assign memfy_arvalid_io = (memfy_arcache[1]) ? memfy_arvalid & rtag_avlb : 1'b0;
        assign memfy_arvalid_blk = (!memfy_arcache[1]) ? memfy_arvalid & rtag_avlb : 1'b0;
        assign memfy_arready_w = (memfy_arcache[1]) ? memfy_arready_io : memfy_arready_blk;
        assign memfy_arready = memfy_arready_w & rtag_avlb;
        assign memfy_arid_w = memfy_arid_next;

    end else begin: BLK_FETCHER_ONLY

        assign memfy_arvalid_blk = memfy_arvalid;
        assign memfy_arready = memfy_arready_blk;
        assign memfy_arid_w = memfy_arid;

        assign memfy_rvalid = blk_fetcher_rvalid;
        assign memfy_rid = blk_fetcher_rid;
        assign memfy_rresp = blk_fetcher_rresp;
        assign memfy_rdata = blk_fetcher_rdata;
        assign blk_fetcher_rready = memfy_rready;
    end
    endgenerate

    friscv_cache_block_fetcher
    #(
        .NAME                ("dCache-block-fetcher"),
        .ILEN                (ILEN),
        .XLEN                (XLEN),
        .OSTDREQ_NUM         (OSTDREQ_NUM),
        .NO_CPL_BACKPRESSURE (1),
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (AXI_DATA_W)
    )
    block_fetcher
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        // unused flush control
        .flush_reqs      (1'b0),
        .flush_blocks    (1'b0),
        // read address channel from the application
        .mst_arvalid     (memfy_arvalid_blk),
        .mst_arready     (memfy_arready_blk),
        .mst_araddr      (memfy_araddr),
        .mst_arprot      (memfy_arprot),
        .mst_arid        (memfy_arid_w),
        // read data completion to read completion manager
        .mst_rvalid      (blk_fetcher_rvalid),
        .mst_rready      (blk_fetcher_rready),
        .mst_rid         (blk_fetcher_rid),
        .mst_rresp       (blk_fetcher_rresp),
        .mst_rdata       (blk_fetcher_rdata),
        // status flag of the memory controller
        .block_fill      (memctrl_rvalid & !memctrl_rcache),
        .cache_ren       (fetcher_cache_ren),
        .cache_raddr     (fetcher_cache_raddr),
        .cache_rprot     (fetcher_cache_rprot),
        .cache_rid       (fetcher_cache_rid),
        .cache_rdata     (fetcher_cache_rdata),
        .cache_hit       (fetcher_cache_hit),
        .cache_miss      (fetcher_cache_miss)
    );

    friscv_cache_prefetcher
    #(
        .NAME              ("dCache-prefetcher"),
        .ILEN              (ILEN),
        .XLEN              (XLEN),
        .AXI_ADDR_W        (AXI_ADDR_W),
        .AXI_ID_W          (AXI_ID_W),
        .AXI_DATA_W        (AXI_DATA_W),
        .CACHE_PREFETCH_EN (CACHE_PREFETCH_EN),
        .CACHE_BLOCK_W     (CACHE_BLOCK_W)
    )
    prefetcher
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        // read request to the memory controller
        .memctrl_arvalid (blk_fetcher_arvalid),
        .memctrl_arready (blk_fetcher_arready),
        .memctrl_araddr  (blk_fetcher_araddr),
        .memctrl_arprot  (blk_fetcher_arprot),
        .memctrl_arid    (blk_fetcher_arid),
        // status flag of the memory controller
        .mem_cpl_wr      (memctrl_rvalid & !memctrl_rcache),
        .mem_cpl_rid     (memctrl_rid),
        .block_fill      (block_fill),
        .cache_ren       (fetcher_cache_ren),
        .cache_raddr     (fetcher_cache_raddr),
        .cache_rid       (fetcher_cache_rid),
        .cache_rprot     (fetcher_cache_rprot),
        .cache_rdata     (fetcher_cache_rdata),
        .cache_hit       (fetcher_cache_hit),
        .cache_miss      (fetcher_cache_miss)
    );


    generate
    if (IO_MAP_NB > 0) begin: IO_FECTHER_INSTANCE

    friscv_cache_io_fetcher
    #(
        .NAME            ("dCache-io-fetcher"),
        .OSTDREQ_NUM     (OSTDREQ_NUM),
        .AXI_ADDR_W      (AXI_ADDR_W),
        .AXI_ID_W        (AXI_ID_W)
    )
    io_fetcher
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        // read address channel from the application
        .mst_arvalid     (memfy_arvalid_io),
        .mst_arready     (memfy_arready_io),
        .mst_araddr      (memfy_araddr),
        .mst_arprot      (memfy_arprot),
        .mst_arid        (memfy_arid_w),
        // read request to the memory controller
        .memctrl_arvalid (io_fetcher_arvalid),
        .memctrl_arready (io_fetcher_arready),
        .memctrl_araddr  (io_fetcher_araddr),
        .memctrl_arprot  (io_fetcher_arprot),
        .memctrl_arid    (io_fetcher_arid)
    );

    end else begin: NO_IO_FETCHER

        assign memfy_arready_io = 1'b0;
        assign io_fetcher_araddr = {AXI_ADDR_W{1'b0}};
        assign io_fetcher_arprot = 3'b0;
        assign io_fetcher_arid = {AXI_ID_W{1'b0}};
    end
    endgenerate

    ////////////////////////////////////////////////////////////////////////////////////
    // Drive read requests to memory controller, IO requests being always serviced first
    ////////////////////////////////////////////////////////////////////////////////////

    generate
    if (IO_MAP_NB > 0) begin: ARCH_MEMCTRL_MUX

        assign memctrl_arvalid = io_fetcher_arvalid | blk_fetcher_arvalid;

        assign io_fetcher_arready = (io_fetcher_arvalid) ? memctrl_arready : 1'b0;
        assign blk_fetcher_arready = (io_fetcher_arvalid) ? 1'b0 : memctrl_arready;

        assign memctrl_araddr = (io_fetcher_arvalid) ? io_fetcher_araddr : blk_fetcher_araddr;
        assign memctrl_arid = (io_fetcher_arvalid) ? io_fetcher_arid : blk_fetcher_arid;
        assign memctrl_arprot = (io_fetcher_arvalid) ? io_fetcher_arprot : blk_fetcher_arprot;
        assign memctrl_arcache = (io_fetcher_arvalid) ? 4'b0010 : 4'b0000;

    end else begin: BLK_TO_MEMCTRL

        assign memctrl_arvalid = blk_fetcher_arvalid;
        assign blk_fetcher_arready = memctrl_arready;
        assign memctrl_araddr = blk_fetcher_araddr;
        assign memctrl_arid = blk_fetcher_arid;
        assign memctrl_arprot = blk_fetcher_arprot;
        assign memctrl_arcache = 4'b0000;
        assign memctrl_rready = 1'b1;

    end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////
    // Manage the read channels, distributing tags and routing read data completion
    // in-order back to the application
    ///////////////////////////////////////////////////////////////////////////


    if (IO_MAP_NB > 0) begin: RD_OOO_INSTANCE

    friscv_cache_ooo_mgt
    #(
        .XLEN                (XLEN),
        .OSTDREQ_NUM         (OSTDREQ_NUM),
        .NAME                ("dCache-OoO-RdMgt"),
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (AXI_DATA_W),
        .AXI_ID_MASK         (AXI_ID_MASK),
        .AXI_ID_FIXED        (AXI_ID_FIXED),
        .FAST_FWD_CPL        (FAST_FWD_CPL)
    )
    rd_ooo_mgt
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        // Tag to use for read address channel in both fetchers
        .next_tag           (memfy_arid_next),
        // Next tag is available
        .tag_avlb           (rtag_avlb),
        // read address channel from the application
        .slv_avalid         (memfy_arvalid),
        .slv_aready         (memfy_arready),
        .slv_addr           (memfy_araddr),
        .slv_acache         (memfy_arcache),
        .slv_aid            (memfy_arid),
        // read data completion from cache block
        .cpl1_valid         (blk_fetcher_rvalid),
        .cpl1_ready         (blk_fetcher_rready),
        .cpl1_id            (blk_fetcher_rid),
        .cpl1_resp          (blk_fetcher_rresp),
        .cpl1_data          (blk_fetcher_rdata),
        // read data completion from memory controller for IO R/W
        .cpl2_valid         (memctrl_rvalid & memctrl_rcache),
        .cpl2_ready         (memctrl_rready),
        .cpl2_id            (memctrl_rid),
        .cpl2_resp          (memctrl_rresp),
        .cpl2_data          (memctrl_rdata),
        // read data completion back to the application
        .slv_valid          (memfy_rvalid),
        .slv_ready          (memfy_rready),
        .slv_id             (memfy_rid),
        .slv_resp           (memfy_rresp),
        .slv_data           (memfy_rdata)
    );

    end

    ///////////////////////////////////////////////////////////////////////////
    // Write block management
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_pusher
    #(
        .NAME            ("dCache-pusher"),
        .XLEN            (XLEN),
        .OSTDREQ_NUM     (OSTDREQ_NUM),
        .AXI_ADDR_W      (AXI_ADDR_W),
        .AXI_ID_W        (AXI_ID_W),
        .AXI_ID_MASK     (AXI_ID_MASK),
        .CACHE_BLOCK_W   (CACHE_BLOCK_W)
    )
    pusher
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        // write addess channels from application
        .mst_awvalid     (memfy_awvalid),
        .mst_awready     (memfy_awready_w),
        .mst_awaddr      (memfy_awaddr),
        .mst_awprot      (memfy_awprot),
        .mst_awcache     (memfy_awcache),
        .mst_awid        (memfy_awid_w),
        .mst_wvalid      (memfy_wvalid),
        .mst_wready      (memfy_wready),
        .mst_wdata       (memfy_wdata),
        .mst_wstrb       (memfy_wstrb),
        .mst_bvalid      (pusher_bvalid),
        .mst_bready      (pusher_bready),
        .mst_bid         (pusher_bid),
        .mst_bresp       (pusher_bresp),
        // write interface to memory controller
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
        // cache write interface to update a cache block
        .cache_ren       (pusher_cache_ren),
        .cache_raddr     (pusher_cache_raddr),
        .cache_hit       (pusher_cache_hit),
        .cache_miss      (pusher_cache_miss),
        .cache_wen       (pusher_cache_wen),
        .cache_wstrb     (pusher_cache_wstrb),
        .cache_waddr     (pusher_cache_waddr),
        .cache_wdata     (pusher_cache_wdata)
    );

    assign memfy_awready = wtag_avlb & memfy_awready_w;
    assign memfy_awid_w = memfy_awid_next;

    friscv_cache_ooo_mgt
    #(
        .XLEN                (XLEN),
        .OSTDREQ_NUM         (OSTDREQ_NUM),
        .NAME                ("dCache-OoO-WrMgt"),
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (AXI_DATA_W),
        .AXI_ID_MASK         (AXI_ID_MASK),
        .AXI_ID_FIXED        (AXI_ID_FIXED),
        .CPL_PAYLOAD         (0),
        .FAST_FWD_CPL        (FAST_FWD_CPL)
    )
    wr_ooo_mgt
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        // Tag to use for read address channel in both fetchers
        .next_tag           (memfy_awid_next),
        // Next tag is available
        .tag_avlb           (wtag_avlb),
        // read address channel from the application
        .slv_avalid         (memfy_awvalid),
        .slv_aready         (memfy_awready),
        .slv_addr           (memfy_awaddr),
        .slv_acache         (memfy_awcache),
        .slv_aid            (memfy_awid),
        // read data completion from cache block
        .cpl1_valid         (pusher_bvalid),
        .cpl1_ready         (pusher_bready),
        .cpl1_id            (pusher_bid),
        .cpl1_resp          (pusher_bresp),
        .cpl1_data          ('0),
        // read data completion from memory controller for IO R/W
        .cpl2_valid         ('0),
        .cpl2_ready         (),
        .cpl2_id            ('0),
        .cpl2_resp          ('0),
        .cpl2_data          ('0),
        // read data completion back to the application
        .slv_valid          (memfy_bvalid),
        .slv_ready          (memfy_bready),
        .slv_id             (memfy_bid),
        .slv_resp           (memfy_bresp),
        .slv_data           ()
    );

    ///////////////////////////////////////////////////////////////////////////
    // Cache Blocks Storage and Eraser
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_blocks
    #(
        .NAME          ("dCache-blocks"),
        .WLEN          (XLEN),
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
        .p1_wen     (memctrl_rvalid & !memctrl_rcache | cache_wren),
        .p1_wstrb   ({CACHE_BLOCK_W/8{1'b1}}),
        .p1_waddr   ((cache_wren) ? cache_waddr : memctrl_raddr),
        .p1_wdata   ((cache_wren) ? cache_wdata : memctrl_rdata_blk),
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


    friscv_cache_flusher
    #(
        .NAME          ("dCache-Flusher"),
        .CACHE_BLOCK_W (CACHE_BLOCK_W),
        .CACHE_DEPTH   (CACHE_DEPTH),
        .AXI_ADDR_W    (AXI_ADDR_W)
    )
    flusher
    (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .srst         (srst),
        .ready        (cache_ready),
        .flush_blocks (1'b0),
        .flush_ack    (),
        .flushing     (flushing),
        .cache_wren   (cache_wren),
        .cache_waddr  (cache_waddr),
        .cache_wdata  (cache_wdata)
    );


    ///////////////////////////////////////////////////////////////////////////
    // AXI4 memory controller to read external memory
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_memctrl
    #(
        .NAME          ("dCache-MemCtrl"),
        .XLEN          (XLEN),
        .RW_MODE       (1),
        .OSTDREQ_NUM   (OSTDREQ_NUM),
        .AXI_ADDR_W    (AXI_ADDR_W),
        .AXI_ID_W      (AXI_ID_W),
        .AXI_DATA_W    (AXI_DATA_W),
        .AXI_ID_MASK   (AXI_ID_MASK),
        .AXI_IN_ORDER  (IO_MAP_NB==0),
        .CACHE_BLOCK_W (CACHE_BLOCK_W)
    )
    mem_ctrl
    (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .srst           (srst),
        // AXI4-lite read address channels from fetchers stage
        .mst_arvalid    (memctrl_arvalid),
        .mst_arready    (memctrl_arready),
        .mst_araddr     (memctrl_araddr),
        .mst_arprot     (memctrl_arprot),
        .mst_arcache    (memctrl_arcache),
        .mst_arid       (memctrl_arid),
        // AXI4-lite read data channel to cache block and read completion module
        .mst_rvalid     (memctrl_rvalid),
        .mst_rready     (memctrl_rready),
        .mst_rcache     (memctrl_rcache),
        .mst_raddr      (memctrl_raddr),
        .mst_rid        (memctrl_rid),
        .mst_rresp      (memctrl_rresp),
        .mst_rdata_blk  (memctrl_rdata_blk),
        .mst_rdata      (memctrl_rdata),
        // AXI4-lite write channels from pusher stage
        .mst_awvalid    (memctrl_awvalid),
        .mst_awready    (memctrl_awready),
        .mst_awaddr     (memctrl_awaddr),
        .mst_awprot     (memctrl_awprot),
        .mst_awcache    (4'b0),
        .mst_awid       (memctrl_awid),
        .mst_wvalid     (memctrl_wvalid),
        .mst_wready     (memctrl_wready),
        .mst_wdata      (memctrl_wdata),
        .mst_wstrb      (memctrl_wstrb),
        .mst_bvalid     (memctrl_bvalid),
        .mst_bready     (memctrl_bready),
        .mst_bid        (memctrl_bid),
        .mst_bresp      (memctrl_bresp),
        // AXI channels to central memory
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
        .mem_rlast      (dcache_rlast)
    );

endmodule

`resetall
