// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Instruction cache circuit
//
// - Direct-mapped (1-way) placement policy
// - Parametrizable cache depth
// - Parametrizable cache line width (instruction per line)
// - Transparent operation, no need of user management
// - Software-based flush control with FENCE.i instruction (req/ack handshake)
// - Possibility to reboot the requests servicing and flush the previous 
//   requests issued for jump / branch event
// - Slave AXI4-lite interface to fetch instructions
// - Master AXI4 interface to read the central memory
//
///////////////////////////////////////////////////////////////////////////////

module friscv_icache

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

        // Address bus width defined for AXI4 to central memory
        parameter AXI_ADDR_W = 32,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,
        // ID Mask to apply to identify the instruction cache in the AXI4
        // infrastructure
        parameter AXI_ID_MASK = 'h10,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Enable automatic prefetch in memory controller
        parameter CACHE_PREFETCH_EN = 0,
        // Line width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512,
        // Enable pipeline on cache
        //   - bit 0: use pass-thru mode in fetcher's FIFOs
        parameter CACHE_PIPELINE = 32'h00000001

    )(
        // Clock / Reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Flush control to clear outstanding request in buffers
        input  wire                       flush_reqs,
        // Flush control to execute FENCE.i
        input  wire                       flush_blocks,
        output logic                      flush_ack,
        // Control unit interface
        input  wire                       ctrl_arvalid,
        output logic                      ctrl_arready,
        input  wire  [AXI_ADDR_W    -1:0] ctrl_araddr,
        input  wire  [3             -1:0] ctrl_arprot,
        input  wire  [AXI_ID_W      -1:0] ctrl_arid,
        output logic                      ctrl_rvalid,
        input  wire                       ctrl_rready,
        output logic [AXI_ID_W      -1:0] ctrl_rid,
        output logic [2             -1:0] ctrl_rresp,
        output logic [ILEN          -1:0] ctrl_rdata,
        // AXI4 Read channels interface to central memory
        output logic                      icache_arvalid,
        input  wire                       icache_arready,
        output logic [AXI_ADDR_W    -1:0] icache_araddr,
        output logic [8             -1:0] icache_arlen,
        output logic [3             -1:0] icache_arsize,
        output logic [2             -1:0] icache_arburst,
        output logic [2             -1:0] icache_arlock,
        output logic [4             -1:0] icache_arcache,
        output logic [3             -1:0] icache_arprot,
        output logic [4             -1:0] icache_arqos,
        output logic [4             -1:0] icache_arregion,
        output logic [AXI_ID_W      -1:0] icache_arid,
        input  wire                       icache_rvalid,
        output logic                      icache_rready,
        input  wire  [AXI_ID_W      -1:0] icache_rid,
        input  wire  [2             -1:0] icache_rresp,
        input  wire  [AXI_DATA_W    -1:0] icache_rdata,
        input  wire                       icache_rlast
    );


    // Signals driving the cache lines pool
    logic                     cache_wen;
    logic [AXI_ADDR_W   -1:0] cache_waddr;
    logic [CACHE_BLOCK_W-1:0] cache_wdata;
    logic                     cache_ren;
    logic [AXI_ADDR_W   -1:0] cache_raddr;
    logic [ILEN         -1:0] cache_rdata;
    logic                     cache_hit;
    logic                     cache_miss;
    logic                     cache_loading;
    // Memory controller interface
    logic                     memctrl_arvalid;
    logic                     memctrl_arready;
    logic [AXI_ADDR_W   -1:0] memctrl_araddr;
    logic [3            -1:0] memctrl_arprot;
    logic [AXI_ID_W     -1:0] memctrl_arid;

    // Signal to control the flush operation
    logic                     flushing;
    logic                     flush_ack_fetcher;
    logic                     flush_ack_memctrl;

    ///////////////////////////////////////////////////////////////////////////
    // Cache sequencer
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_fetcher
    #(
        .NAME             ("iCache-fetcher"),
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
        .pending_wr      (1'b0),
        .pending_rd      (),
        .flush_reqs      (flush_reqs),
        .flush_blocks    (flush_blocks),
        .flush_ack       (flush_ack_fetcher),
        .mst_arvalid     (ctrl_arvalid),
        .mst_arready     (ctrl_arready),
        .mst_araddr      (ctrl_araddr),
        .mst_arprot      (ctrl_arprot),
        .mst_arid        (ctrl_arid),
        .mst_rvalid      (ctrl_rvalid),
        .mst_rready      (ctrl_rready),
        .mst_rid         (ctrl_rid),
        .mst_rresp       (ctrl_rresp),
        .mst_rdata       (ctrl_rdata),
        .memctrl_arvalid (memctrl_arvalid),
        .memctrl_arready (memctrl_arready),
        .memctrl_araddr  (memctrl_araddr),
        .memctrl_arprot  (memctrl_arprot),
        .memctrl_arid    (memctrl_arid),
        .cache_writing   (cache_wen),
        .cache_loading   (cache_loading),
        .cache_ren       (cache_ren),
        .cache_raddr     (cache_raddr),
        .cache_rdata     (cache_rdata),
        .cache_hit       (cache_hit),
        .cache_miss      (cache_miss)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Cache blocks Storage
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_blocks
    #(
        .NAME          ("iCache-blocks"),
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
        .p1_wen     (cache_wen),
        .p1_waddr   (cache_waddr),
        .p1_wdata   (cache_wdata),
        .p1_wstrb   ({CACHE_BLOCK_W/8{1'b1}}),
        .p1_ren     (cache_ren),
        .p1_raddr   (cache_raddr),
        .p1_rdata   (cache_rdata),
        .p1_hit     (cache_hit),
        .p1_miss    (cache_miss),
        .p2_wen     (1'b0),
        .p2_waddr   ({AXI_ADDR_W{1'b0}}),
        .p2_wdata   ({CACHE_BLOCK_W{1'b0}}),
        .p2_wstrb   ({CACHE_BLOCK_W/8{1'b0}}),
        .p2_ren     (1'b0),
        .p2_raddr   ({AXI_ADDR_W{1'b0}}),
        .p2_rdata   (),
        .p2_hit     (),
        .p2_miss    ()
    );


    ///////////////////////////////////////////////////////////////////////////
    // AXI4 memory controller to read external memory
    ///////////////////////////////////////////////////////////////////////////

    friscv_cache_memctrl
    #(
        .ILEN          (ILEN),
        .XLEN          (XLEN),
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
        .flush_blocks   (flush_blocks),
        .flush_ack      (flush_ack_memctrl),
        .flushing       (flushing),
        .mst_arvalid    (memctrl_arvalid),
        .mst_arready    (memctrl_arready),
        .mst_araddr     (memctrl_araddr),
        .mst_arprot     (memctrl_arprot),
        .mst_arid       (memctrl_arid),
        .mst_awvalid    (1'b0),
        .mst_awready    (),
        .mst_awaddr     ({AXI_ADDR_W{1'b0}}),
        .mst_awprot     (3'b0),
        .mst_awid       ({AXI_ID_W{1'b0}}),
        .mst_wvalid     (1'b0),
        .mst_wready     (),
        .mst_wdata      ({XLEN{1'b0}}),
        .mst_wstrb      ({XLEN/8{1'b0}}),
        .mst_bvalid     (),
        .mst_bready     (1'b0),
        .mst_bid        (),
        .mst_bresp      (),
        .mem_awvalid    (),
        .mem_awready    (1'b0),
        .mem_awaddr     (),
        .mem_awlen      (),
        .mem_awsize     (),
        .mem_awburst    (),
        .mem_awlock     (),
        .mem_awcache    (),
        .mem_awprot     (),
        .mem_awqos      (),
        .mem_awregion   (),
        .mem_awid       (),
        .mem_wvalid     (),
        .mem_wready     (1'b0),
        .mem_wlast      (),
        .mem_wdata      (),
        .mem_wstrb      (),
        .mem_bvalid     (1'b0),
        .mem_bready     (),
        .mem_bid        ({AXI_ID_W{1'b0}}),
        .mem_bresp      (2'b0),
        .mem_arvalid    (icache_arvalid),
        .mem_arready    (icache_arready),
        .mem_araddr     (icache_araddr),
        .mem_arlen      (icache_arlen),
        .mem_arsize     (icache_arsize),
        .mem_arburst    (icache_arburst),
        .mem_arlock     (icache_arlock),
        .mem_arcache    (icache_arcache),
        .mem_arprot     (icache_arprot),
        .mem_arqos      (icache_arqos),
        .mem_arregion   (icache_arregion),
        .mem_arid       (icache_arid),
        .mem_rvalid     (icache_rvalid),
        .mem_rready     (icache_rready),
        .mem_rid        (icache_rid),
        .mem_rresp      (icache_rresp),
        .mem_rdata      (icache_rdata),
        .mem_rlast      (icache_rlast),
        .cache_loading  (cache_loading),
        .cache_wen      (cache_wen),
        .cache_waddr    (cache_waddr),
        .cache_wdata    (cache_wdata)
    );

    assign flush_ack = flush_ack_fetcher & flush_ack_memctrl;

endmodule

`resetall
