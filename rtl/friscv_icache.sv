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
// - Cache control & status observable by a debug interface
// - Slave AXI4-lite interface to fetch instructions, with ARID support.
//   New incoming ARID reboots the cache to save latency but doesn't flush.
// - Master AXI4 interface to read central memory
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

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for AXI4 to central memory
        parameter AXI_ADDR_W = 32,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Enable automatic prefetch in memory controller
        parameter PREFETCH_EN = 0,
        // Line width defining only the data payload, in bits
        parameter CACHE_LINE_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512,
        // Enable pipeline on cache
        //   - bit 0: use pass-thru mode in fetcher's FIFOs
        parameter CACHE_PIPELINE = 32'h00000001

    )(
        // Clock / Reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // Flush control
        input  logic                      flush_req,
        output logic                      flush_ack,
        // Control unit interface
        input  logic                      ctrl_arvalid,
        output logic                      ctrl_arready,
        input  logic [AXI_ADDR_W    -1:0] ctrl_araddr,
        input  logic [3             -1:0] ctrl_arprot,
        input  logic [AXI_ID_W      -1:0] ctrl_arid,
        output logic                      ctrl_rvalid,
        input  logic                      ctrl_rready,
        output logic [AXI_ID_W      -1:0] ctrl_rid,
        output logic [2             -1:0] ctrl_rresp,
        output logic [ILEN          -1:0] ctrl_rdata,
        // AXI4 Read channels interface to central memory
        output logic                      icache_arvalid,
        input  logic                      icache_arready,
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
        input  logic                      icache_rvalid,
        output logic                      icache_rready,
        input  logic [AXI_ID_W      -1:0] icache_rid,
        input  logic [2             -1:0] icache_rresp,
        input  logic [AXI_DATA_W    -1:0] icache_rdata,
        input  logic                      icache_rlast
    );


    // Signals driving the cache lines pool
    logic                     cache_wen;
    logic [AXI_ADDR_W   -1:0] cache_waddr;
    logic [CACHE_LINE_W -1:0] cache_wdata;
    logic                     cache_ren;
    logic [AXI_ADDR_W   -1:0] cache_raddr;
    logic [ILEN         -1:0] cache_rdata;
    logic                     cache_hit;
    logic                     cache_miss;

    // Signal to control the flush operation
    logic                     is_flushing;

    logic                     memctrl_arvalid;
    logic                     memctrl_arready;
    logic [AXI_ADDR_W   -1:0] memctrl_araddr;
    logic [3            -1:0] memctrl_arprot;
    logic [AXI_ID_W     -1:0] memctrl_arid;


    logic flush_ack_fetcher;
    logic flush_ack_memctrl;

    ///////////////////////////////////////////////////////////////////////////
    // Cache sequencer
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_fetcher
    #(
    .ILEN           (ILEN),
    .XLEN           (XLEN),
    .OSTDREQ_NUM    (OSTDREQ_NUM),
    .AXI_ADDR_W     (AXI_ADDR_W),
    .AXI_ID_W       (AXI_ID_W),
    .AXI_DATA_W     (AXI_DATA_W),
    .CACHE_PIPELINE (CACHE_PIPELINE)
    )
    fetcher
    (
    .aclk            (aclk),
    .aresetn         (aresetn),
    .srst            (srst),
    .flush_req       (flush_req),
    .flush_ack       (flush_ack_fetcher),
    .ctrl_arvalid    (ctrl_arvalid),
    .ctrl_arready    (ctrl_arready),
    .ctrl_araddr     (ctrl_araddr),
    .ctrl_arprot     (ctrl_arprot),
    .ctrl_arid       (ctrl_arid),
    .ctrl_rvalid     (ctrl_rvalid),
    .ctrl_rready     (ctrl_rready),
    .ctrl_rid        (ctrl_rid),
    .ctrl_rresp      (ctrl_rresp),
    .ctrl_rdata      (ctrl_rdata),
    .memctrl_arvalid (memctrl_arvalid),
    .memctrl_arready (memctrl_arready),
    .memctrl_araddr  (memctrl_araddr),
    .memctrl_arprot  (memctrl_arprot),
    .memctrl_arid    (memctrl_arid),
    .cache_writing   (cache_wen),
    .cache_ren       (cache_ren),
    .cache_raddr     (cache_raddr),
    .cache_rdata     (cache_rdata),
    .cache_hit       (cache_hit),
    .cache_miss      (cache_miss)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Cache lines Storage
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_lines
    #(
    .ILEN         (ILEN),
    .XLEN         (XLEN),
    .ADDR_W       (AXI_ADDR_W),
    .CACHE_LINE_W (CACHE_LINE_W),
    .CACHE_DEPTH  (CACHE_DEPTH)
    )
    cache_lines
    (
    .aclk    (aclk),
    .aresetn (aresetn),
    .srst    (srst),
    .flush   (is_flushing),
    .wen     (cache_wen),
    .waddr   (cache_waddr),
    .wdata   (cache_wdata),
    .ren     (cache_ren),
    .raddr   (cache_raddr),
    .rdata   (cache_rdata),
    .hit     (cache_hit),
    .miss    (cache_miss)
    );


    ///////////////////////////////////////////////////////////////////////////
    // AXI4 memory controller to read external memory
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_memctrl
    #(
    .AXI_ADDR_W   (AXI_ADDR_W),
    .AXI_ID_W     (AXI_ID_W),
    .AXI_DATA_W   (AXI_DATA_W),
    .CACHE_LINE_W (CACHE_LINE_W),
    .CACHE_DEPTH  (CACHE_DEPTH)
    )
    mem_ctrl
    (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .srst           (srst),
    .flush_req      (flush_req),
    .flush_ack      (flush_ack_memctrl),
    .flush          (is_flushing),
    .ctrl_arvalid   (memctrl_arvalid),
    .ctrl_arready   (memctrl_arready),
    .ctrl_araddr    (memctrl_araddr),
    .ctrl_arprot    (memctrl_arprot),
    .ctrl_arid      (memctrl_arid),
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
    .cache_wen      (cache_wen),
    .cache_waddr    (cache_waddr),
    .cache_wdata    (cache_wdata)
    );

    assign flush_ack = flush_ack_fetcher & flush_ack_memctrl;

endmodule

`resetall
