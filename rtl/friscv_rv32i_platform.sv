// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1ns / 1ps
`default_nettype none

`define RV32I

`ifndef XLEN
`define XLEN 32
`endif

`include "friscv_h.sv"
`include "friscv_checkers.sv"



module friscv_rv32i_platform

    #(
        ////////////////////////////////////////////////////////////////////////
        // Global setup
        ////////////////////////////////////////////////////////////////////////

        // Instruction length (always 32, whatever the architecture,
        // compressed ISA is not supported)
        parameter ILEN               = 32,
        // RISCV Architecture
        parameter XLEN               = 32,
        // Boot address used by the control unit
        parameter BOOT_ADDR          = 0,
        // Number of outstanding requests used by the control unit and icache
        parameter INST_OSTDREQ_NUM  = 8,
        // Number of outstanding requests used by the LOAD/STORE unit and dcache
        parameter DATA_OSTDREQ_NUM  = 8,
        // Core Hart ID
        parameter HART_ID            = 0,
        // RV32E architecture, limits integer registers to 16, else 32 available
        parameter RV32E              = 0,
        // Floating-point extension support
        parameter F_EXTENSION       = 0,
        // Multiply/Divide extension support
        parameter M_EXTENSION       = 0,
        // Insert a pipeline on instruction bus coming from the controller
        parameter PROCESSING_BUS_PIPELINE = 0,
        // FIFO depth of processing unit, buffering the instruction to execute
        parameter PROCESSING_QUEUE_DEPTH = 0,

        ////////////////////////////////////////////////////////////////////////
        // AXI4 / AXI4-lite interface setup
        ////////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W         = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W           = 8,
        // AXI4 data width
        parameter AXI_DATA_W         = XLEN*4,
        // ID used by instruction and data buses
        parameter AXI_IMEM_MASK     = 'h10,
        parameter AXI_DMEM_MASK     = 'h20,

        ////////////////////////////////////////////////////////////////////////
        // Cache setup
        ////////////////////////////////////////////////////////////////////////

        // Enable instruction & data caches
        parameter CACHE_EN           = 0,

        // Enable cache block prefetch
        parameter ICACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits, must be an
        // integer multiple of XLEN (power of two)
        parameter ICACHE_BLOCK_W     = AXI_DATA_W,
        // Number of blocks in the cache
        parameter ICACHE_DEPTH       = 512,

        // Enable cache block prefetch
        parameter DCACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter DCACHE_BLOCK_W     = AXI_DATA_W,
        // Number of blocks in the cache
        parameter DCACHE_DEPTH       = 512

    )(
        // Clock/reset interface
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Real-time reference clock
        input  wire                       rtc,
        // Interrupts
        input  wire                       ext_irq,
        // Internal core debug
        output logic [8             -1:0] status,
        output logic [32*XLEN       -1:0] dbg_regs,
        // Central Memory interface
        output logic                      mem_awvalid,
        input  wire                       mem_awready,
        output logic [AXI_ADDR_W    -1:0] mem_awaddr,
        output logic [3             -1:0] mem_awprot,
        output logic [AXI_ID_W      -1:0] mem_awid,
        output logic                      mem_wvalid,
        input  wire                       mem_wready,
        output logic [AXI_DATA_W    -1:0] mem_wdata,
        output logic [AXI_DATA_W/8  -1:0] mem_wstrb,
        input  wire                       mem_bvalid,
        output logic                      mem_bready,
        input  wire  [AXI_ID_W      -1:0] mem_bid,
        input  wire  [2             -1:0] mem_bresp,
        output logic                      mem_arvalid,
        input  wire                       mem_arready,
        output logic [AXI_ADDR_W    -1:0] mem_araddr,
        output logic [3             -1:0] mem_arprot,
        output logic [AXI_ID_W      -1:0] mem_arid,
        input  wire                       mem_rvalid,
        output logic                      mem_rready,
        input  wire  [AXI_ID_W      -1:0] mem_rid,
        input  wire  [2             -1:0] mem_rresp,
        input  wire  [AXI_DATA_W    -1:0] mem_rdata,
        // GPIOs interface
        input  wire  [XLEN          -1:0] gpio_in,
        output logic [XLEN          -1:0] gpio_out,
        // UART interface
        input  wire                       uart_rx,
        output logic                      uart_tx,
        output logic                      uart_rts,
        input  wire                       uart_cts
    );

    ///////////////////////////////////////////////////////////////////////////
    // AXI4-lite interfaces of instruction and data bus interfaces
    ///////////////////////////////////////////////////////////////////////////

    localparam AXI_IMEM_W = AXI_DATA_W;
    localparam AXI_DMEM_W = AXI_DATA_W;


    logic                      imem_arvalid;
    logic                      imem_arready;
    logic [AXI_ADDR_W    -1:0] imem_araddr;
    logic [3             -1:0] imem_arprot;
    logic [AXI_ID_W      -1:0] imem_arid;
    logic                      imem_rvalid;
    logic                      imem_rready;
    logic [AXI_ID_W      -1:0] imem_rid;
    logic [2             -1:0] imem_rresp;
    logic [AXI_IMEM_W    -1:0] imem_rdata;

    logic                      dmem_awvalid;
    logic                      dmem_awready;
    logic [AXI_ADDR_W    -1:0] dmem_awaddr;
    logic [3             -1:0] dmem_awprot;
    logic [AXI_ID_W      -1:0] dmem_awid;
    logic                      dmem_wvalid;
    logic                      dmem_wready;
    logic [AXI_DMEM_W    -1:0] dmem_wdata;
    logic [AXI_DMEM_W/8  -1:0] dmem_wstrb;
    logic                      dmem_bvalid;
    logic                      dmem_bready;
    logic [AXI_ID_W      -1:0] dmem_bid;
    logic [2             -1:0] dmem_bresp;
    logic                      dmem_arvalid;
    logic                      dmem_arready;
    logic [AXI_ADDR_W    -1:0] dmem_araddr;
    logic [3             -1:0] dmem_arprot;
    logic [AXI_ID_W      -1:0] dmem_arid;
    logic                      dmem_rvalid;
    logic                      dmem_rready;
    logic [AXI_ID_W      -1:0] dmem_rid;
    logic [2             -1:0] dmem_rresp;
    logic [AXI_DMEM_W    -1:0] dmem_rdata;

    logic                      sw_irq;

    ///////////////////////////////////////////////////////////////////////////
    // IO subsytem configuration (APB interconnect), connected as slave 1
    // of the AXI4-lite interconnect
    ///////////////////////////////////////////////////////////////////////////

    // GPIOs
    parameter IO_SLV0_ADDR       = 0;
    parameter IO_SLV0_SIZE       = 8;
    // UART
    parameter IO_SLV1_ADDR       = IO_SLV0_ADDR + IO_SLV0_SIZE;
    parameter IO_SLV1_SIZE       = 16;
    // CLINT
    parameter IO_SLV2_ADDR       = IO_SLV1_ADDR + IO_SLV1_SIZE;
    parameter IO_SLV2_SIZE       = 20;

    parameter IO_UART_FIFO_DEPTH = 64;

    logic                      ios_awvalid;
    logic                      ios_awready;
    logic [AXI_ADDR_W    -1:0] ios_awaddr;
    logic [AXI_ID_W      -1:0] ios_awid;
    logic [3             -1:0] ios_awprot;
    logic                      ios_wvalid;
    logic                      ios_wready;
    logic [AXI_DATA_W    -1:0] ios_wdata;
    logic [AXI_DATA_W/8  -1:0] ios_wstrb;
    logic                      ios_bvalid;
    logic                      ios_bready;
    logic [2             -1:0] ios_bresp;
    logic [AXI_ID_W      -1:0] ios_bid;
    logic                      ios_arvalid;
    logic                      ios_arready;
    logic [AXI_ADDR_W    -1:0] ios_araddr;
    logic [AXI_ID_W      -1:0] ios_arid;
    logic [3             -1:0] ios_arprot;
    logic                      ios_rvalid;
    logic                      ios_rready;
    logic [2             -1:0] ios_rresp;
    logic [AXI_DATA_W    -1:0] ios_rdata;
    logic [AXI_ID_W      -1:0] ios_rid;

    logic                      timer_irq;

    ///////////////////////////////////////////////////////////////////////////
    // AXI4-lite Crossbar parameters and signals
    ///////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////
    // Memory Mapping:
    //
    // RAM  : 0x000000-0x100000
    // GPIOs: 0x100000-0x100007
    // UART : 0x100008-0x100017
    // CLINT: 0x100018-0x100027
    //////////////////////////////////////


    parameter MST_NB = 4;
    parameter SLV_NB = 4;

    parameter MST_PIPELINE = 1;
    parameter SLV_PIPELINE = 1;

    parameter STRB_MODE = 1;
    parameter AXI_SIGNALING = 0;
    parameter USER_SUPPORT = 0;

    parameter AXI_AUSER_W = 1;
    parameter AXI_WUSER_W = 1;
    parameter AXI_BUSER_W = 1;
    parameter AXI_RUSER_W = 1;

    parameter TIMEOUT_VALUE = 10000;
    parameter TIMEOUT_ENABLE = 0;

    parameter MST0_RW = 0;
    parameter MST0_CDC = 0;
    parameter MST0_OSTDREQ_NUM = 0;
    parameter MST0_PRIORITY = 0;
    parameter [SLV_NB-1:0] MST0_ROUTES = 4'b1_1_1_1;
    parameter [AXI_ID_W-1:0] MST0_ID_MASK = AXI_IMEM_MASK;

    parameter MST1_RW = 0;
    parameter MST1_CDC = 0;
    parameter MST1_OSTDREQ_NUM = 0;
    parameter MST1_PRIORITY = 0;
    parameter [SLV_NB-1:0] MST1_ROUTES = 4'b1_1_1_1;
    parameter [AXI_ID_W-1:0] MST1_ID_MASK = AXI_DMEM_MASK;

    parameter MST2_RW = 0;
    parameter MST2_CDC = 0;
    parameter MST2_OSTDREQ_NUM = 0;
    parameter MST2_PRIORITY = 0;
    parameter [SLV_NB-1:0] MST2_ROUTES = 4'b1_1_1_1;
    parameter [AXI_ID_W-1:0] MST2_ID_MASK = 'h30;

    parameter MST3_RW = 0;
    parameter MST3_CDC = 0;
    parameter MST3_OSTDREQ_NUM = 0;
    parameter MST3_PRIORITY = 0;
    parameter [SLV_NB-1:0] MST3_ROUTES = 4'b1_1_1_1;
    parameter [AXI_ID_W-1:0] MST3_ID_MASK = 'h40;

    parameter SLV0_CDC = 0;
    parameter SLV0_START_ADDR = 0;
    parameter SLV0_END_ADDR = 1048575; // 0x000FFFFF
    parameter SLV0_OSTDREQ_NUM = 0;
    parameter SLV0_KEEP_BASE_ADDR = 0;

    parameter SLV1_CDC = 0;
    parameter SLV1_START_ADDR = 1048576; // 0x00100000
    parameter SLV1_END_ADDR = 1048639;   // 0x0010003F
    parameter SLV1_OSTDREQ_NUM = 0;
    parameter SLV1_KEEP_BASE_ADDR = 0;

    parameter SLV2_CDC = 0;
    parameter SLV2_START_ADDR = 1050000; // Random value
    parameter SLV2_END_ADDR = 1050003;
    parameter SLV2_OSTDREQ_NUM = 0;
    parameter SLV2_KEEP_BASE_ADDR = 0;

    parameter SLV3_CDC = 0;
    parameter SLV3_START_ADDR = 1050004; // Random value
    parameter SLV3_END_ADDR = 1050007;
    parameter SLV3_OSTDREQ_NUM = 0;
    parameter SLV3_KEEP_BASE_ADDR = 0;

    // IO regions for direct read/write access
    parameter IO_MAP_NB = 1;
    // IO address ranges, organized by memory region as END-ADDR_START-ADDR:
    // > 0xEND-MEM2_START-MEM2_END-MEM1_START-MEM1_END-MEM0_START-MEM0
    // IO mapping can be contiguous or sparse, no restriction on the number,
    // the size or the range if it fits into the XLEN addressable space
    parameter [XLEN*2*IO_MAP_NB-1:0] IO_MAP = 64'h001000FF_00100000;

    ///////////////////////////////////////////////////////////////////////////
    // IPs Instances
    ///////////////////////////////////////////////////////////////////////////

    friscv_rv32i_core
    #(
        .ILEN (ILEN),
        .XLEN (XLEN),
        .M_EXTENSION (M_EXTENSION),
        .F_EXTENSION (F_EXTENSION),
        .PROCESSING_QUEUE_DEPTH (PROCESSING_QUEUE_DEPTH),
        .PROCESSING_BUS_PIPELINE (PROCESSING_BUS_PIPELINE),
        .BOOT_ADDR (BOOT_ADDR),
        .INST_OSTDREQ_NUM (INST_OSTDREQ_NUM),
        .DATA_OSTDREQ_NUM (DATA_OSTDREQ_NUM),
        .HART_ID (HART_ID),
        .RV32E (RV32E),
        .AXI_ADDR_W (AXI_ADDR_W),
        .AXI_ID_W (AXI_ID_W),
        .AXI_IMEM_W (AXI_IMEM_W),
        .AXI_DMEM_W (AXI_DMEM_W),
        .AXI_IMEM_MASK (AXI_IMEM_MASK),
        .AXI_DMEM_MASK (AXI_DMEM_MASK),
        .CACHE_EN (CACHE_EN),
        .ICACHE_PREFETCH_EN (ICACHE_PREFETCH_EN),
        .ICACHE_BLOCK_W (ICACHE_BLOCK_W),
        .ICACHE_DEPTH (ICACHE_DEPTH),
        .IO_MAP_NB (IO_MAP_NB),
        .IO_MAP (IO_MAP),
        .DCACHE_PREFETCH_EN (DCACHE_PREFETCH_EN),
        .DCACHE_BLOCK_W (DCACHE_BLOCK_W),
        .DCACHE_DEPTH (DCACHE_DEPTH),
        .DCACHE_REORDER_CPL (1)
    )
    cpu0
    (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .srst         (srst),
        .ext_irq      (ext_irq),
        .sw_irq       (1'b0),
        .timer_irq    (timer_irq),
        .status       (status),
        .dbg_regs     (dbg_regs),
        .imem_arvalid (imem_arvalid),
        .imem_arready (imem_arready),
        .imem_araddr  (imem_araddr),
        .imem_arprot  (imem_arprot),
        .imem_arid    (imem_arid),
        .imem_rvalid  (imem_rvalid),
        .imem_rready  (imem_rready),
        .imem_rid     (imem_rid),
        .imem_rresp   (imem_rresp),
        .imem_rdata   (imem_rdata),
        .dmem_awvalid (dmem_awvalid),
        .dmem_awready (dmem_awready),
        .dmem_awaddr  (dmem_awaddr),
        .dmem_awprot  (dmem_awprot),
        .dmem_awid    (dmem_awid),
        .dmem_wvalid  (dmem_wvalid),
        .dmem_wready  (dmem_wready),
        .dmem_wdata   (dmem_wdata),
        .dmem_wstrb   (dmem_wstrb),
        .dmem_bvalid  (dmem_bvalid),
        .dmem_bready  (dmem_bready),
        .dmem_bid     (dmem_bid),
        .dmem_bresp   (dmem_bresp),
        .dmem_arvalid (dmem_arvalid),
        .dmem_arready (dmem_arready),
        .dmem_araddr  (dmem_araddr),
        .dmem_arprot  (dmem_arprot),
        .dmem_arid    (dmem_arid),
        .dmem_rvalid  (dmem_rvalid),
        .dmem_rready  (dmem_rready),
        .dmem_rid     (dmem_rid),
        .dmem_rresp   (dmem_rresp),
        .dmem_rdata   (dmem_rdata)
    );


    axicb_crossbar_lite_top
    #(
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (AXI_DATA_W),
        .MST_NB              (MST_NB),
        .SLV_NB              (SLV_NB),
        .MST_PIPELINE        (MST_PIPELINE),
        .SLV_PIPELINE        (SLV_PIPELINE),
        .STRB_MODE           (STRB_MODE),
        .USER_SUPPORT        (USER_SUPPORT),
        .AXI_AUSER_W         (AXI_AUSER_W),
        .AXI_WUSER_W         (AXI_WUSER_W),
        .AXI_BUSER_W         (AXI_BUSER_W),
        .AXI_RUSER_W         (AXI_RUSER_W),
        .TIMEOUT_VALUE       (TIMEOUT_VALUE),
        .TIMEOUT_ENABLE      (TIMEOUT_ENABLE),
        .MST0_CDC            (MST0_CDC),
        .MST0_OSTDREQ_NUM    (MST0_OSTDREQ_NUM),
        .MST0_PRIORITY       (MST0_PRIORITY),
        .MST0_ROUTES         (MST0_ROUTES),
        .MST0_ID_MASK        (MST0_ID_MASK),
        .MST0_RW             (MST0_RW),
        .MST1_CDC            (MST1_CDC),
        .MST1_OSTDREQ_NUM    (MST1_OSTDREQ_NUM),
        .MST1_PRIORITY       (MST1_PRIORITY),
        .MST1_ROUTES         (MST1_ROUTES),
        .MST1_ID_MASK        (MST1_ID_MASK),
        .MST1_RW             (MST1_RW),
        .MST2_CDC            (MST2_CDC),
        .MST2_OSTDREQ_NUM    (MST2_OSTDREQ_NUM),
        .MST2_PRIORITY       (MST2_PRIORITY),
        .MST2_ROUTES         (MST2_ROUTES),
        .MST2_ID_MASK        (MST2_ID_MASK),
        .MST2_RW             (MST2_RW),
        .MST3_CDC            (MST3_CDC),
        .MST3_OSTDREQ_NUM    (MST3_OSTDREQ_NUM),
        .MST3_PRIORITY       (MST3_PRIORITY),
        .MST3_ROUTES         (MST3_ROUTES),
        .MST3_ID_MASK        (MST3_ID_MASK),
        .MST3_RW             (MST3_RW),
        .SLV0_CDC            (SLV0_CDC),
        .SLV0_START_ADDR     (SLV0_START_ADDR),
        .SLV0_END_ADDR       (SLV0_END_ADDR),
        .SLV0_OSTDREQ_NUM    (SLV0_OSTDREQ_NUM),
        .SLV0_KEEP_BASE_ADDR (SLV0_KEEP_BASE_ADDR),
        .SLV1_CDC            (SLV1_CDC),
        .SLV1_START_ADDR     (SLV1_START_ADDR),
        .SLV1_END_ADDR       (SLV1_END_ADDR),
        .SLV1_OSTDREQ_NUM    (SLV1_OSTDREQ_NUM),
        .SLV1_KEEP_BASE_ADDR (SLV1_KEEP_BASE_ADDR),
        .SLV2_CDC            (SLV2_CDC),
        .SLV2_START_ADDR     (SLV2_START_ADDR),
        .SLV2_END_ADDR       (SLV2_END_ADDR),
        .SLV2_OSTDREQ_NUM    (SLV2_OSTDREQ_NUM),
        .SLV2_KEEP_BASE_ADDR (SLV2_KEEP_BASE_ADDR),
        .SLV3_CDC            (SLV3_CDC),
        .SLV3_START_ADDR     (SLV3_START_ADDR),
        .SLV3_END_ADDR       (SLV3_END_ADDR),
        .SLV3_OSTDREQ_NUM    (SLV3_OSTDREQ_NUM),
        .SLV3_KEEP_BASE_ADDR (SLV3_KEEP_BASE_ADDR)
    )
    axi4lite_crossbar
    (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .srst         (srst),
        .slv0_aclk    (aclk),
        .slv0_aresetn (aresetn),
        .slv0_srst    (srst),
        .slv0_awvalid (1'b0),
        .slv0_awready (),
        .slv0_awaddr  ({AXI_ADDR_W{1'b0}}),
        .slv0_awprot  (3'h0),
        .slv0_awid    ({AXI_ID_W{1'h0}}),
        .slv0_awuser  (1'h0),
        .slv0_wvalid  (1'b0),
        .slv0_wready  (),
        .slv0_wdata   ({AXI_DATA_W{1'b0}}),
        .slv0_wstrb   ({AXI_DATA_W/8{1'b0}}),
        .slv0_wuser   (1'h0),
        .slv0_bvalid  (),
        .slv0_bready  (1'b1),
        .slv0_bid     (),
        .slv0_bresp   (),
        .slv0_buser   (),
        .slv0_arvalid (imem_arvalid),
        .slv0_arready (imem_arready),
        .slv0_araddr  (imem_araddr),
        .slv0_arprot  (imem_arprot),
        .slv0_arid    (imem_arid),
        .slv0_aruser  (1'b0),
        .slv0_rvalid  (imem_rvalid),
        .slv0_rready  (imem_rready),
        .slv0_rid     (imem_rid),
        .slv0_rresp   (imem_rresp),
        .slv0_rdata   (imem_rdata),
        .slv0_ruser   (),
        .slv1_aclk    (aclk),
        .slv1_aresetn (aresetn),
        .slv1_srst    (srst),
        .slv1_awvalid (dmem_awvalid),
        .slv1_awready (dmem_awready),
        .slv1_awaddr  (dmem_awaddr),
        .slv1_awprot  (dmem_awprot),
        .slv1_awid    (dmem_awid),
        .slv1_awuser  (1'b0),
        .slv1_wvalid  (dmem_wvalid),
        .slv1_wready  (dmem_wready),
        .slv1_wdata   (dmem_wdata),
        .slv1_wstrb   (dmem_wstrb),
        .slv1_wuser   (1'b0),
        .slv1_bvalid  (dmem_bvalid),
        .slv1_bready  (dmem_bready),
        .slv1_bid     (dmem_bid),
        .slv1_bresp   (dmem_bresp),
        .slv1_buser   (),
        .slv1_arvalid (dmem_arvalid),
        .slv1_arready (dmem_arready),
        .slv1_araddr  (dmem_araddr),
        .slv1_arprot  (dmem_arprot),
        .slv1_arid    (dmem_arid),
        .slv1_aruser  (1'b0),
        .slv1_rvalid  (dmem_rvalid),
        .slv1_rready  (dmem_rready),
        .slv1_rid     (dmem_rid),
        .slv1_rresp   (dmem_rresp),
        .slv1_rdata   (dmem_rdata),
        .slv1_ruser   (),
        .slv2_aclk    (1'h0),
        .slv2_aresetn (1'h0),
        .slv2_srst    (1'h0),
        .slv2_awvalid (1'h0),
        .slv2_awready (),
        .slv2_awaddr  ({AXI_ADDR_W{1'b0}}),
        .slv2_awprot  (3'h0),
        .slv2_awid    ({AXI_ID_W{1'b0}}),
        .slv2_awuser  (1'h0),
        .slv2_wvalid  (1'h0),
        .slv2_wready  (),
        .slv2_wdata   ({AXI_DATA_W{1'b0}}),
        .slv2_wstrb   ({AXI_DATA_W/8{1'b0}}),
        .slv2_wuser   (1'h0),
        .slv2_bvalid  (),
        .slv2_bready  (1'h1),
        .slv2_bid     (),
        .slv2_bresp   (),
        .slv2_buser   (),
        .slv2_arvalid (1'h0),
        .slv2_arready (),
        .slv2_araddr  ({AXI_ADDR_W{1'b0}}),
        .slv2_arprot  (3'h0),
        .slv2_arid    ({AXI_ID_W{1'b0}}),
        .slv2_aruser  (1'h0),
        .slv2_rvalid  (),
        .slv2_rready  (1'h1),
        .slv2_rid     (),
        .slv2_rresp   (),
        .slv2_rdata   (),
        .slv2_ruser   (),
        .slv3_aclk    (1'h0),
        .slv3_aresetn (1'h0),
        .slv3_srst    (1'h0),
        .slv3_awvalid (1'h0),
        .slv3_awready (),
        .slv3_awaddr  ({AXI_ADDR_W{1'b0}}),
        .slv3_awprot  (3'h0),
        .slv3_awid    ({AXI_ID_W{1'b0}}),
        .slv3_awuser  (1'h0),
        .slv3_wvalid  (1'h0),
        .slv3_wready  (),
        .slv3_wdata   ({AXI_DATA_W{1'b0}}),
        .slv3_wstrb   ({AXI_DATA_W/8{1'b0}}),
        .slv3_wuser   (1'h0),
        .slv3_bvalid  (),
        .slv3_bready  (1'h1),
        .slv3_bid     (),
        .slv3_bresp   (),
        .slv3_buser   (),
        .slv3_arvalid (1'h0),
        .slv3_arready (),
        .slv3_araddr  ({AXI_ADDR_W{1'b0}}),
        .slv3_arprot  (3'h0),
        .slv3_arid    ({AXI_ID_W{1'b0}}),
        .slv3_aruser  (1'h0),
        .slv3_rvalid  (),
        .slv3_rready  (1'h1),
        .slv3_rid     (),
        .slv3_rresp   (),
        .slv3_rdata   (),
        .slv3_ruser   (),
        .mst0_aclk    (aclk),
        .mst0_aresetn (aresetn),
        .mst0_srst    (srst),
        .mst0_awvalid (mem_awvalid),
        .mst0_awready (mem_awready),
        .mst0_awaddr  (mem_awaddr),
        .mst0_awprot  (mem_awprot),
        .mst0_awid    (mem_awid),
        .mst0_awuser  (),
        .mst0_wvalid  (mem_wvalid),
        .mst0_wready  (mem_wready),
        .mst0_wdata   (mem_wdata),
        .mst0_wstrb   (mem_wstrb),
        .mst0_wuser   (),
        .mst0_bvalid  (mem_bvalid),
        .mst0_bready  (mem_bready),
        .mst0_bid     (mem_bid),
        .mst0_bresp   (mem_bresp),
        .mst0_buser   (1'b0),
        .mst0_arvalid (mem_arvalid),
        .mst0_arready (mem_arready),
        .mst0_araddr  (mem_araddr),
        .mst0_arprot  (mem_arprot),
        .mst0_arid    (mem_arid),
        .mst0_aruser  (),
        .mst0_rvalid  (mem_rvalid),
        .mst0_rready  (mem_rready),
        .mst0_rid     (mem_rid),
        .mst0_rresp   (mem_rresp),
        .mst0_rdata   (mem_rdata),
        .mst0_ruser   (1'b0),
        .mst1_aclk    (aclk),
        .mst1_aresetn (aresetn),
        .mst1_srst    (srst),
        .mst1_awvalid (ios_awvalid),
        .mst1_awready (ios_awready),
        .mst1_awaddr  (ios_awaddr),
        .mst1_awprot  (ios_awprot),
        .mst1_awid    (ios_awid),
        .mst1_awuser  (),
        .mst1_wvalid  (ios_wvalid),
        .mst1_wready  (ios_wready),
        .mst1_wdata   (ios_wdata),
        .mst1_wstrb   (ios_wstrb),
        .mst1_wuser   (),
        .mst1_bvalid  (ios_bvalid),
        .mst1_bready  (ios_bready),
        .mst1_bid     (ios_bid),
        .mst1_bresp   (ios_bresp),
        .mst1_buser   (1'b0),
        .mst1_arvalid (ios_arvalid),
        .mst1_arready (ios_arready),
        .mst1_araddr  (ios_araddr),
        .mst1_arprot  (ios_arprot),
        .mst1_arid    (ios_arid),
        .mst1_aruser  (),
        .mst1_rvalid  (ios_rvalid),
        .mst1_rready  (ios_rready),
        .mst1_rid     (ios_rid),
        .mst1_rresp   (ios_rresp),
        .mst1_rdata   (ios_rdata),
        .mst1_ruser   (1'b0),
        .mst2_aclk    (1'h0),
        .mst2_aresetn (1'h0),
        .mst2_srst    (1'h0),
        .mst2_awvalid (),
        .mst2_awready (1'h1),
        .mst2_awaddr  (),
        .mst2_awprot  (),
        .mst2_awid    (),
        .mst2_awuser  (),
        .mst2_wvalid  (),
        .mst2_wready  (1'h1),
        .mst2_wdata   (),
        .mst2_wstrb   (),
        .mst2_wuser   (),
        .mst2_bvalid  (1'h0),
        .mst2_bready  (),
        .mst2_bid     ({AXI_ID_W{1'b0}}),
        .mst2_bresp   (2'h0),
        .mst2_buser   (1'h0),
        .mst2_arvalid (),
        .mst2_arready (1'b1),
        .mst2_araddr  (),
        .mst2_arprot  (),
        .mst2_arid    (),
        .mst2_aruser  (),
        .mst2_rvalid  (1'h0),
        .mst2_rready  (),
        .mst2_rid     ({AXI_ID_W{1'b0}}),
        .mst2_rresp   (2'h0),
        .mst2_rdata   ({AXI_DATA_W{1'b0}}),
        .mst2_ruser   (1'b0),
        .mst3_aclk    (1'h0),
        .mst3_aresetn (1'h0),
        .mst3_srst    (1'h0),
        .mst3_awvalid (),
        .mst3_awready (1'h1),
        .mst3_awaddr  (),
        .mst3_awprot  (),
        .mst3_awid    (),
        .mst3_awuser  (),
        .mst3_wvalid  (),
        .mst3_wready  (1'h1),
        .mst3_wdata   (),
        .mst3_wstrb   (),
        .mst3_wuser   (),
        .mst3_bvalid  (1'h0),
        .mst3_bready  (),
        .mst3_bid     ({AXI_ID_W{1'b0}}),
        .mst3_bresp   (2'h0),
        .mst3_buser   (1'b0),
        .mst3_arvalid (),
        .mst3_arready (1'b1),
        .mst3_araddr  (),
        .mst3_arprot  (),
        .mst3_arid    (),
        .mst3_aruser  (),
        .mst3_rvalid  (1'h0),
        .mst3_rready  (),
        .mst3_rid     ({AXI_ID_W{1'b0}}),
        .mst3_rresp   (2'h0),
        .mst3_rdata   ({AXI_DATA_W{1'b0}}),
        .mst3_ruser   (1'h0)
    );

    friscv_io_subsystem
    #(
        .ADDRW           (AXI_ADDR_W),
        .DATAW           (AXI_DATA_W),
        .IDW             (AXI_ID_W),
        .XLEN            (XLEN),
        // GPIOs
        .SLV0_ADDR       (IO_SLV0_ADDR),
        .SLV0_SIZE       (IO_SLV0_SIZE),
        // UART
        .SLV1_ADDR       (IO_SLV1_ADDR),
        .SLV1_SIZE       (IO_SLV1_SIZE),
        // CLINT
        .SLV2_ADDR       (IO_SLV2_ADDR),
        .SLV2_SIZE       (IO_SLV2_SIZE),
        .UART_FIFO_DEPTH (IO_UART_FIFO_DEPTH)
    )
    io_subsystem
    (
        .aclk        (aclk),
        .aresetn     (aresetn),
        .srst        (srst),
        .rtc         (rtc),
        .slv_awvalid (ios_awvalid),
        .slv_awready (ios_awready),
        .slv_awaddr  (ios_awaddr),
        .slv_awprot  (ios_awprot),
        .slv_awid    (ios_awid),
        .slv_wvalid  (ios_wvalid),
        .slv_wready  (ios_wready),
        .slv_wdata   (ios_wdata),
        .slv_wstrb   (ios_wstrb),
        .slv_bvalid  (ios_bvalid),
        .slv_bready  (ios_bready),
        .slv_bresp   (ios_bresp),
        .slv_bid     (ios_bid),
        .slv_arvalid (ios_arvalid),
        .slv_arready (ios_arready),
        .slv_araddr  (ios_araddr),
        .slv_arprot  (ios_arprot),
        .slv_arid    (ios_arid),
        .slv_rvalid  (ios_rvalid),
        .slv_rready  (ios_rready),
        .slv_rresp   (ios_rresp),
        .slv_rdata   (ios_rdata),
        .slv_rid     (ios_rid),
        .gpio_in     (gpio_in),
        .gpio_out    (gpio_out),
        .uart_rx     (uart_rx),
        .uart_tx     (uart_tx),
        .uart_rts    (uart_rts),
        .uart_cts    (uart_cts),
        .sw_irq      (sw_irq),
        .timer_irq   (timer_irq)
    );

endmodule
`resetall
