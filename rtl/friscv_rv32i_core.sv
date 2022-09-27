// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1ns / 1ps
`default_nettype none

`define RV32I

`ifndef XLEN
`define XLEN 32
`endif

`include "friscv_h.sv"
`include "friscv_debug_h.sv"
`include "friscv_checkers.sv"

module friscv_rv32i_core

    #(
        ////////////////////////////////////////////////////////////////////////
        // Global setup
        ////////////////////////////////////////////////////////////////////////

        // Instruction length (always 32, whatever the architecture,
        // compressed ISA is not supported)
        parameter ILEN              = 32,
        // RISCV Architecture
        parameter XLEN              = 32,
        // Boot address used by the control unit
        parameter BOOT_ADDR         = 0,
        // Number of outstanding requests used by the control unit
        parameter INST_OSTDREQ_NUM  = 8,
        // Number of outstanding requests used by the LOAD/STORE unit
        parameter DATA_OSTDREQ_NUM  = 8,
        // Core Hart ID
        parameter HART_ID          = 0,
        // RV32E architecture, limits integer registers to 16, else 32 available
        parameter RV32E             = 0,
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
        // AXI4 data width, for instruction and a data bus
        parameter AXI_IMEM_W         = XLEN,
        parameter AXI_DMEM_W         = XLEN,
        // ID used by instruction and data buses
        parameter AXI_IMEM_MASK     = 'h10,
        parameter AXI_DMEM_MASK     = 'h20,

        ////////////////////////////////////////////////////////////////////////
        // Caches setup
        ////////////////////////////////////////////////////////////////////////

        // Enable instruction & data caches
        parameter CACHE_EN           = 0,

        // Enable cache block prefetch
        parameter ICACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter ICACHE_BLOCK_W     = XLEN*4,
        // Number of blocks in the cache
        parameter ICACHE_DEPTH       = 512,
            
        // IO regions for direct read/write access
        parameter IO_MAP_NB = 0,
        // IO address ranges, organized by memory region as END-ADDR_START-ADDR:
        // > 0xEND-MEM2_START-MEM2_END-MEM1_START-MEM1_END-MEM0_START-MEM0
        // IO mapping can be contiguous or sparse, no restriction on the number,
        // the size or the range if it fits into the XLEN addressable space
        parameter [XLEN*2*IO_MAP_NB-1:0] IO_MAP = 64'h001000FF_00100000,

        // Enable cache block prefetch
        parameter DCACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter DCACHE_BLOCK_W     = XLEN*4,
        // Number of blocks in the cache
        parameter DCACHE_DEPTH       = 512,
        // Reorder read completion for Memfy
        parameter DCACHE_REORDER_CPL = 0
    )(
        // Clock/reset interface
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Interrupts
        input  wire                       ext_irq,
        input  wire                       sw_irq,
        input  wire                       timer_irq,
        // Internal core debug
        output logic [8             -1:0] status,
        output logic [32*XLEN       -1:0] dbg_regs,
        // Instruction memory interface
        output logic                      imem_arvalid,
        input  wire                       imem_arready,
        output logic [AXI_ADDR_W    -1:0] imem_araddr,
        output logic [3             -1:0] imem_arprot,
        output logic [AXI_ID_W      -1:0] imem_arid,
        input  wire                       imem_rvalid,
        output logic                      imem_rready,
        input  wire  [AXI_ID_W      -1:0] imem_rid,
        input  wire  [2             -1:0] imem_rresp,
        input  wire  [AXI_IMEM_W    -1:0] imem_rdata,
        // Data memory interface
        output logic                      dmem_awvalid,
        input  wire                       dmem_awready,
        output logic [AXI_ADDR_W    -1:0] dmem_awaddr,
        output logic [3             -1:0] dmem_awprot,
        output logic [AXI_ID_W      -1:0] dmem_awid,
        output logic                      dmem_wvalid,
        input  wire                       dmem_wready,
        output logic [AXI_DMEM_W    -1:0] dmem_wdata,
        output logic [AXI_DMEM_W/8  -1:0] dmem_wstrb,
        input  wire                       dmem_bvalid,
        output logic                      dmem_bready,
        input  wire  [AXI_ID_W      -1:0] dmem_bid,
        input  wire  [2             -1:0] dmem_bresp,
        output logic                      dmem_arvalid,
        input  wire                       dmem_arready,
        output logic [AXI_ADDR_W    -1:0] dmem_araddr,
        output logic [3             -1:0] dmem_arprot,
        output logic [AXI_ID_W      -1:0] dmem_arid,
        input  wire                       dmem_rvalid,
        output logic                      dmem_rready,
        input  wire  [AXI_ID_W      -1:0] dmem_rid,
        input  wire  [2             -1:0] dmem_rresp,
        input  wire  [AXI_DMEM_W    -1:0] dmem_rdata
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    localparam NB_ALU_UNIT = 2 + M_EXTENSION + F_EXTENSION;
    localparam MAX_ALU_UNIT = 4;

    logic [5                   -1:0] ctrl_rs1_addr;
    logic [XLEN                -1:0] ctrl_rs1_val;
    logic [5                   -1:0] ctrl_rs2_addr;
    logic [XLEN                -1:0] ctrl_rs2_val;
    logic                            ctrl_rd_wr;
    logic [5                   -1:0] ctrl_rd_addr;
    logic [XLEN                -1:0] ctrl_rd_val;

    // ISA registers interface
    logic [NB_ALU_UNIT*5       -1:0] proc_rs1_addr;
    logic [NB_ALU_UNIT*XLEN    -1:0] proc_rs1_val;
    logic [NB_ALU_UNIT*5       -1:0] proc_rs2_addr;
    logic [NB_ALU_UNIT*XLEN    -1:0] proc_rs2_val;
    logic [NB_ALU_UNIT         -1:0] proc_rd_wr;
    logic [NB_ALU_UNIT*5       -1:0] proc_rd_addr;
    logic [NB_ALU_UNIT*XLEN    -1:0] proc_rd_val;
    logic [NB_ALU_UNIT*XLEN/8  -1:0] proc_rd_strb;

    logic [5                   -1:0] csr_rs1_addr;
    logic [XLEN                -1:0] csr_rs1_val;
    logic                            csr_rd_wr;
    logic [5                   -1:0] csr_rd_addr;
    logic [XLEN                -1:0] csr_rd_val;

    logic                            proc_valid;
    logic [`INST_BUS_W         -1:0] proc_instbus;
    logic                            proc_ready;
    logic                            proc_busy;
    logic [4                   -1:0] proc_fenceinfo;
    logic [2                   -1:0] proc_exceptions;

    logic                            csr_en;
    logic [`INST_BUS_W         -1:0] csr_instbus;
    logic                            csr_ready;

    logic                            inst_arvalid_s;
    logic                            inst_arready_s;
    logic [AXI_ADDR_W          -1:0] inst_araddr_s;
    logic [3                   -1:0] inst_arprot_s;
    logic [AXI_ID_W            -1:0] inst_arid_s;
    logic                            inst_rvalid_s;
    logic                            inst_rready_s;
    logic [AXI_ID_W            -1:0] inst_rid_s;
    logic [2                   -1:0] inst_rresp_s;
    logic [ILEN                -1:0] inst_rdata_s;

    logic                            memfy_awvalid;
    logic                            memfy_awready;
    logic [AXI_ADDR_W          -1:0] memfy_awaddr;
    logic [3                   -1:0] memfy_awprot;
    logic [4                   -1:0] memfy_awcache;
    logic [AXI_ID_W            -1:0] memfy_awid;
    logic                            memfy_wvalid;
    logic                            memfy_wready;
    logic [XLEN                -1:0] memfy_wdata;
    logic [XLEN/8              -1:0] memfy_wstrb;
    logic                            memfy_bvalid;
    logic                            memfy_bready;
    logic [AXI_ID_W            -1:0] memfy_bid;
    logic [2                   -1:0] memfy_bresp;
    logic                            memfy_arvalid;
    logic                            memfy_arready;
    logic [AXI_ADDR_W          -1:0] memfy_araddr;
    logic [3                   -1:0] memfy_arprot;
    logic [4                   -1:0] memfy_arcache;
    logic [AXI_ID_W            -1:0] memfy_arid;
    logic                            memfy_rvalid;
    logic                            memfy_rready;
    logic [AXI_ID_W            -1:0] memfy_rid;
    logic [2                   -1:0] memfy_rresp;
    logic [XLEN                -1:0] memfy_rdata;

    logic                            flush_reqs;
    logic                            flush_blocks;
    logic                            flush_ack;

    logic [5                   -1:0] traps;

    logic                            ctrl_mepc_wr;
    logic [XLEN                -1:0] ctrl_mepc;
    logic                            ctrl_mstatus_wr;
    logic [XLEN                -1:0] ctrl_mstatus;
    logic                            ctrl_mcause_wr;
    logic [XLEN                -1:0] ctrl_mcause;
    logic                            ctrl_mtval_wr;
    logic [XLEN                -1:0] ctrl_mtval;
    logic [`CSR_SB_W           -1:0] csr_sb;
    logic [64                  -1:0] ctrl_rdinstret;


    //////////////////////////////////////////////////////////////////////////
    // Check parameters setup consistency and break up if not supported
    //////////////////////////////////////////////////////////////////////////
    initial begin

        `CHECKER((ILEN!=32),
            "ILEN can't be something else than 32 bits");

        `CHECKER((XLEN!=32),
            "Wrong architecture definition: 32 bits expected");

        `CHECKER((`XLEN!=32),
            "Wrong architecture definition: 32 bits expected");

        `CHECKER((RV32E!=0 && RV32E!=1),
            "RV32E can be only equal to 0 or 1");

        `CHECKER((CACHE_EN==0 && AXI_IMEM_W != XLEN),
            "If cache is disable, AXI_IMEM_W must be XLEN");

        `CHECKER((CACHE_EN==0 && AXI_DMEM_W != XLEN),
            "If cache is disable, AXI_DMEM_W must be XLEN");

        `CHECKER((CACHE_EN==1 && AXI_IMEM_W != ICACHE_BLOCK_W),
           "Only AXI_IMEM_W = ICACHE_BLOCK_W is supported for the moment");

        `CHECKER((CACHE_EN==1 && AXI_DMEM_W != DCACHE_BLOCK_W),
            "Only AXI_DMEM_W = DCACHE_BLOCK_W is supported for the moment");

        `CHECKER((CACHE_EN==1 && (ICACHE_BLOCK_W/ILEN)!=4),
            "Only a ratio = 4 between instruction bus and cache block width is supported");

        `CHECKER((CACHE_EN==1 && (DCACHE_BLOCK_W/XLEN)!=4),
            "Only a ratio = 4 between data bus and cache block width is supported");

    end

    //////////////////////////////////////////////////////////////////////////
    // Status bus moving out the core
    //////////////////////////////////////////////////////////////////////////

    // ECALL
    assign status[0] = traps[0];
    // EBREAK instruction received
    assign status[1] = traps[1];
    // MRET is under execution
    assign status[2] = traps[2];
    // Received a unsupported instruction
    assign status[3] = traps[3];
    // Received a command to write into a read-only CSR
    assign status[4] = traps[4];
    // RESERVED
    assign status[7:5] = 3'b0;


    //////////////////////////////////////////////////////////////////////////
    // ISA integer registers
    //////////////////////////////////////////////////////////////////////////

    friscv_registers
    #(
        .RV32E        (RV32E),
        .XLEN         (XLEN),
        .SYNC_READ    (0),
        .NB_ALU_UNIT  (NB_ALU_UNIT)
    )
    isa_registers
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .x1_ra           (dbg_regs[ `X1*XLEN+:XLEN]),
        .x2_sp           (dbg_regs[ `X2*XLEN+:XLEN]),
        .x3_gp           (dbg_regs[ `X3*XLEN+:XLEN]),
        .x4_tp           (dbg_regs[ `X4*XLEN+:XLEN]),
        .x5_t0           (dbg_regs[ `X5*XLEN+:XLEN]),
        .x6_t1           (dbg_regs[ `X6*XLEN+:XLEN]),
        .x7_t2           (dbg_regs[ `X7*XLEN+:XLEN]),
        .x8_s0_fp        (dbg_regs[ `X8*XLEN+:XLEN]),
        .x9_s1           (dbg_regs[ `X9*XLEN+:XLEN]),
        .x10_a0          (dbg_regs[`X10*XLEN+:XLEN]),
        .x11_a1          (dbg_regs[`X11*XLEN+:XLEN]),
        .x12_a2          (dbg_regs[`X12*XLEN+:XLEN]),
        .x13_a3          (dbg_regs[`X13*XLEN+:XLEN]),
        .x14_a4          (dbg_regs[`X14*XLEN+:XLEN]),
        .x15_a5          (dbg_regs[`X15*XLEN+:XLEN]),
        .x16_a6          (dbg_regs[`X16*XLEN+:XLEN]),
        .x17_a7          (dbg_regs[`X17*XLEN+:XLEN]),
        .x18_s2          (dbg_regs[`X18*XLEN+:XLEN]),
        .x19_s3          (dbg_regs[`X19*XLEN+:XLEN]),
        .x20_s4          (dbg_regs[`X20*XLEN+:XLEN]),
        .x21_s5          (dbg_regs[`X21*XLEN+:XLEN]),
        .x22_s6          (dbg_regs[`X22*XLEN+:XLEN]),
        .x23_s7          (dbg_regs[`X23*XLEN+:XLEN]),
        .x24_s8          (dbg_regs[`X24*XLEN+:XLEN]),
        .x25_s9          (dbg_regs[`X25*XLEN+:XLEN]),
        .x26_s10         (dbg_regs[`X26*XLEN+:XLEN]),
        .x27_s11         (dbg_regs[`X27*XLEN+:XLEN]),
        .x28_t3          (dbg_regs[`X28*XLEN+:XLEN]),
        .x29_t4          (dbg_regs[`X29*XLEN+:XLEN]),
        .x30_t5          (dbg_regs[`X30*XLEN+:XLEN]),
        .x31_t6          (dbg_regs[`X31*XLEN+:XLEN]),
        .ctrl_rs1_addr   (ctrl_rs1_addr),
        .ctrl_rs1_val    (ctrl_rs1_val),
        .ctrl_rs2_addr   (ctrl_rs2_addr),
        .ctrl_rs2_val    (ctrl_rs2_val),
        .ctrl_rd_wr      (ctrl_rd_wr),
        .ctrl_rd_addr    (ctrl_rd_addr),
        .ctrl_rd_val     (ctrl_rd_val),
        .proc_rs1_addr   (proc_rs1_addr),
        .proc_rs1_val    (proc_rs1_val),
        .proc_rs2_addr   (proc_rs2_addr),
        .proc_rs2_val    (proc_rs2_val),
        .proc_rd_wr      (proc_rd_wr),
        .proc_rd_addr    (proc_rd_addr),
        .proc_rd_val     (proc_rd_val),
        .proc_rd_strb    (proc_rd_strb),
        .csr_rs1_addr    (csr_rs1_addr),
        .csr_rs1_val     (csr_rs1_val),
        .csr_rd_wr       (csr_rd_wr),
        .csr_rd_addr     (csr_rd_addr),
        .csr_rd_val      (csr_rd_val)
    );




    //////////////////////////////////////////////////////////////////////////
    // Central controller sequencing the operations
    //////////////////////////////////////////////////////////////////////////

    friscv_control
    #(
        .ILEN           (ILEN),
        .XLEN           (XLEN),
        .RV32E          (RV32E),
        .AXI_ADDR_W     (AXI_ADDR_W),
        .AXI_ID_W       (AXI_ID_W),
        .AXI_ID_MASK    (AXI_IMEM_MASK),
        .AXI_DATA_W     (XLEN),
        .OSTDREQ_NUM    (INST_OSTDREQ_NUM),
        .BOOT_ADDR      (BOOT_ADDR)
    )
    control
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        .traps              (traps),
        .pc_val             (dbg_regs[`PC*XLEN+:XLEN]),
        .flush_reqs         (flush_reqs),
        .flush_blocks       (flush_blocks),
        .flush_ack          (flush_ack),
        .arvalid            (inst_arvalid_s),
        .arready            (inst_arready_s),
        .araddr             (inst_araddr_s),
        .arprot             (inst_arprot_s),
        .arid               (inst_arid_s),
        .rvalid             (inst_rvalid_s),
        .rready             (inst_rready_s),
        .rid                (inst_rid_s),
        .rresp              (inst_rresp_s),
        .rdata              (inst_rdata_s),
        .proc_valid         (proc_valid),
        .proc_ready         (proc_ready),
        .proc_fenceinfo     (proc_fenceinfo),
        .proc_exceptions    (proc_exceptions),
        .proc_instbus       (proc_instbus),
        .proc_busy          (proc_busy),
        .csr_en             (csr_en),
        .csr_ready          (csr_ready),
        .csr_instbus        (csr_instbus),
        .ctrl_rs1_addr      (ctrl_rs1_addr),
        .ctrl_rs1_val       (ctrl_rs1_val),
        .ctrl_rs2_addr      (ctrl_rs2_addr),
        .ctrl_rs2_val       (ctrl_rs2_val),
        .ctrl_rd_wr         (ctrl_rd_wr),
        .ctrl_rd_addr       (ctrl_rd_addr),
        .ctrl_rd_val        (ctrl_rd_val),
        .mepc_wr            (ctrl_mepc_wr),
        .mepc               (ctrl_mepc),
        .mstatus_wr         (ctrl_mstatus_wr),
        .mstatus            (ctrl_mstatus),
        .mcause_wr          (ctrl_mcause_wr),
        .mcause             (ctrl_mcause),
        .mtval_wr           (ctrl_mtval_wr),
        .mtval              (ctrl_mtval),
        .instret            (ctrl_rdinstret),
        .csr_sb             (csr_sb)
    );


    //////////////////////////////////////////////////////////////////////////
    // Instruction cache stage
    //////////////////////////////////////////////////////////////////////////

    generate
    if (CACHE_EN) begin : USE_ICACHE

    friscv_icache
    #(
        .ILEN              (ILEN),
        .XLEN              (XLEN),
        .OSTDREQ_NUM       (INST_OSTDREQ_NUM),
        .AXI_ADDR_W        (AXI_ADDR_W),
        .AXI_ID_W          (AXI_ID_W),
        .AXI_ID_MASK       (AXI_IMEM_MASK),
        .AXI_DATA_W        (AXI_IMEM_W),
        .CACHE_PREFETCH_EN (ICACHE_PREFETCH_EN),
        .CACHE_BLOCK_W     (ICACHE_BLOCK_W),
        .CACHE_DEPTH       (ICACHE_DEPTH)
    )
    icache
    (
        .aclk              (aclk),
        .aresetn           (aresetn),
        .srst              (srst),
        .flush_reqs        (flush_reqs),
        .flush_blocks      (flush_blocks),
        .flush_ack         (flush_ack),
        .ctrl_arvalid      (inst_arvalid_s),
        .ctrl_arready      (inst_arready_s),
        .ctrl_araddr       (inst_araddr_s),
        .ctrl_arprot       (inst_arprot_s),
        .ctrl_arid         (inst_arid_s),
        .ctrl_rvalid       (inst_rvalid_s),
        .ctrl_rready       (inst_rready_s),
        .ctrl_rid          (inst_rid_s),
        .ctrl_rresp        (inst_rresp_s),
        .ctrl_rdata        (inst_rdata_s),
        .icache_arvalid    (imem_arvalid),
        .icache_arready    (imem_arready),
        .icache_araddr     (imem_araddr),
        .icache_arlen      (),
        .icache_arsize     (),
        .icache_arburst    (),
        .icache_arlock     (),
        .icache_arcache    (),
        .icache_arqos      (),
        .icache_arregion   (),
        .icache_arid       (imem_arid),
        .icache_arprot     (imem_arprot),
        .icache_rvalid     (imem_rvalid),
        .icache_rready     (imem_rready),
        .icache_rid        (imem_rid),
        .icache_rresp      (imem_rresp),
        .icache_rdata      (imem_rdata),
        .icache_rlast      (1'b1)
    );

    end else begin : NO_ICACHE

    // Connect controller directly to top interface
    assign imem_arvalid = inst_arvalid_s;
    assign inst_arready_s = imem_arready;
    assign imem_araddr = inst_araddr_s;
    assign imem_arprot = inst_arprot_s;
    assign imem_arid = inst_arid_s;
    assign inst_rvalid_s = imem_rvalid;
    assign imem_rready = inst_rready_s;
    assign inst_rid_s = imem_rid;
    assign inst_rresp_s = imem_rresp;
    assign inst_rdata_s = imem_rdata;

    // Always assert ack if requesting a cache flush to avoid deadlock
    assign flush_ack = 1'b1;

    end
    endgenerate


    //////////////////////////////////////////////////////////////////////////
    // ISA CSR registers
    //////////////////////////////////////////////////////////////////////////

    friscv_csr
    #(
        .RV32E       (RV32E),
        .HART_ID     (HART_ID),
        .XLEN        (XLEN),
        .F_EXTENSION (F_EXTENSION),
        .M_EXTENSION (M_EXTENSION)
    )
    csrs
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .ext_irq         (ext_irq),
        .sw_irq          (sw_irq),
        .timer_irq       (timer_irq),
        .valid           (csr_en),
        .ready           (csr_ready),
        .instbus         (csr_instbus),
        .rs1_addr        (csr_rs1_addr),
        .rs1_val         (csr_rs1_val),
        .rd_wr_en        (csr_rd_wr),
        .rd_wr_addr      (csr_rd_addr),
        .rd_wr_val       (csr_rd_val),
        .ctrl_mepc_wr    (ctrl_mepc_wr),
        .ctrl_mepc       (ctrl_mepc),
        .ctrl_mstatus_wr (ctrl_mstatus_wr),
        .ctrl_mstatus    (ctrl_mstatus),
        .ctrl_mcause_wr  (ctrl_mcause_wr),
        .ctrl_mcause     (ctrl_mcause),
        .ctrl_mtval_wr   (ctrl_mtval_wr),
        .ctrl_mtval      (ctrl_mtval),
        .ctrl_rdinstret  (ctrl_rdinstret),
        .csr_sb          (csr_sb)
    );


    //////////////////////////////////////////////////////////////////////////
    // All ISA enxtensions supported:
    //  - standard integer arithmetic
    //  - memory LOAD/STORE
    //  - multiply / divide
    //  - atomic
    //  - ...
    //////////////////////////////////////////////////////////////////////////

    friscv_processing
    #(
        .XLEN              (XLEN),
        .F_EXTENSION       (F_EXTENSION),
        .M_EXTENSION       (M_EXTENSION),
        .RV32E             (RV32E),
        .AXI_ADDR_W        (AXI_ADDR_W),
        .AXI_ID_W          (AXI_ID_W),
        .AXI_DATA_W        (XLEN),
        .AXI_ID_MASK       (AXI_DMEM_MASK),
        .AXI_REORDER_CPL   (0),
        .NB_UNIT           (NB_ALU_UNIT),
        .MAX_UNIT          (MAX_ALU_UNIT),
        .DATA_OSTDREQ_NUM  (DATA_OSTDREQ_NUM),
        .INST_BUS_PIPELINE (PROCESSING_BUS_PIPELINE),
        .INST_QUEUE_DEPTH  (PROCESSING_QUEUE_DEPTH),
        .IO_MAP_NB         (IO_MAP_NB),
        .IO_MAP            (IO_MAP)
    )
    processing
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        .proc_valid         (proc_valid),
        .proc_ready         (proc_ready),
        .proc_fenceinfo     (proc_fenceinfo),
        .proc_exceptions    (proc_exceptions),
        .proc_instbus       (proc_instbus),
        .proc_busy          (proc_busy),
        .proc_rs1_addr      (proc_rs1_addr),
        .proc_rs1_val       (proc_rs1_val),
        .proc_rs2_addr      (proc_rs2_addr),
        .proc_rs2_val       (proc_rs2_val),
        .proc_rd_wr         (proc_rd_wr),
        .proc_rd_addr       (proc_rd_addr),
        .proc_rd_val        (proc_rd_val),
        .proc_rd_strb       (proc_rd_strb),
        .awvalid            (memfy_awvalid),
        .awready            (memfy_awready),
        .awaddr             (memfy_awaddr),
        .awprot             (memfy_awprot),
        .awcache            (memfy_awcache),
        .awid               (memfy_awid),
        .wvalid             (memfy_wvalid),
        .wready             (memfy_wready),
        .wdata              (memfy_wdata),
        .wstrb              (memfy_wstrb),
        .bvalid             (memfy_bvalid),
        .bready             (memfy_bready),
        .bid                (memfy_bid),
        .bresp              (memfy_bresp),
        .arvalid            (memfy_arvalid),
        .arready            (memfy_arready),
        .araddr             (memfy_araddr),
        .arprot             (memfy_arprot),
        .arcache            (memfy_arcache),
        .arid               (memfy_arid),
        .rvalid             (memfy_rvalid),
        .rready             (memfy_rready),
        .rid                (memfy_rid),
        .rresp              (memfy_rresp),
        .rdata              (memfy_rdata)
    );

    generate

    if (CACHE_EN) begin: DCACHE_ON

        friscv_dcache
        #(
            .ILEN              (ILEN),
            .XLEN              (XLEN),
            .OSTDREQ_NUM       (DATA_OSTDREQ_NUM),
            .AXI_ADDR_W        (AXI_ADDR_W),
            .AXI_ID_W          (AXI_ID_W),
            .AXI_DATA_W        (AXI_DMEM_W),
            .AXI_ID_MASK       (AXI_DMEM_MASK),
            .AXI_REORDER_CPL   (DCACHE_REORDER_CPL),
            .IO_MAP_NB         (IO_MAP_NB),
            .CACHE_PREFETCH_EN (DCACHE_PREFETCH_EN),
            .CACHE_BLOCK_W     (DCACHE_BLOCK_W),
            .CACHE_DEPTH       (DCACHE_DEPTH)
        )
        dcache
        (
            .aclk            (aclk),
            .aresetn         (aresetn),
            .srst            (srst),
            .memfy_awvalid   (memfy_awvalid),
            .memfy_awready   (memfy_awready),
            .memfy_awaddr    (memfy_awaddr),
            .memfy_awprot    (memfy_awprot),
            .memfy_awcache   (memfy_awcache),
            .memfy_awid      (memfy_awid),
            .memfy_wvalid    (memfy_wvalid),
            .memfy_wready    (memfy_wready),
            .memfy_wdata     (memfy_wdata),
            .memfy_wstrb     (memfy_wstrb),
            .memfy_bvalid    (memfy_bvalid),
            .memfy_bready    (memfy_bready),
            .memfy_bid       (memfy_bid),
            .memfy_bresp     (memfy_bresp),
            .memfy_arvalid   (memfy_arvalid),
            .memfy_arready   (memfy_arready),
            .memfy_araddr    (memfy_araddr),
            .memfy_arprot    (memfy_arprot),
            .memfy_arcache   (memfy_arcache),
            .memfy_arid      (memfy_arid),
            .memfy_rvalid    (memfy_rvalid),
            .memfy_rready    (memfy_rready),
            .memfy_rid       (memfy_rid),
            .memfy_rresp     (memfy_rresp),
            .memfy_rdata     (memfy_rdata),
            .dcache_awvalid  (dmem_awvalid),
            .dcache_awready  (dmem_awready),
            .dcache_awaddr   (dmem_awaddr),
            .dcache_awlen    (),
            .dcache_awsize   (),
            .dcache_awburst  (),
            .dcache_awlock   (),
            .dcache_awcache  (),
            .dcache_awprot   (dmem_awprot),
            .dcache_awqos    (),
            .dcache_awregion (),
            .dcache_awid     (dmem_awid),
            .dcache_wvalid   (dmem_wvalid),
            .dcache_wready   (dmem_wready),
            .dcache_wlast    (),
            .dcache_wdata    (dmem_wdata),
            .dcache_wstrb    (dmem_wstrb),
            .dcache_bvalid   (dmem_bvalid),
            .dcache_bready   (dmem_bready),
            .dcache_bid      (dmem_bid),
            .dcache_bresp    (dmem_bresp),
            .dcache_arvalid  (dmem_arvalid),
            .dcache_arready  (dmem_arready),
            .dcache_araddr   (dmem_araddr),
            .dcache_arlen    (),
            .dcache_arsize   (),
            .dcache_arburst  (),
            .dcache_arlock   (),
            .dcache_arcache  (),
            .dcache_arprot   (dmem_arprot),
            .dcache_arqos    (),
            .dcache_arregion (),
            .dcache_arid     (dmem_arid),
            .dcache_rvalid   (dmem_rvalid),
            .dcache_rready   (dmem_rready),
            .dcache_rid      (dmem_rid),
            .dcache_rresp    (dmem_rresp),
            .dcache_rdata    (dmem_rdata),
            .dcache_rlast    (1'b1)
        );

    end else begin: DCACHE_OFF

        assign dmem_awvalid = memfy_awvalid;
        assign memfy_awready = dmem_awready;
        assign dmem_awaddr = memfy_awaddr;
        assign dmem_awprot = memfy_awprot;
        assign dmem_awid = memfy_awid;

        assign dmem_wvalid = memfy_wvalid;
        assign memfy_wready = dmem_wready;
        assign dmem_wdata = memfy_wdata;
        assign dmem_wstrb = memfy_wstrb;

        assign memfy_bvalid = dmem_bvalid;
        assign dmem_bready = memfy_bready;
        assign memfy_bid = dmem_bid;
        assign memfy_bresp = dmem_bresp;

        assign dmem_arvalid = memfy_arvalid;
        assign memfy_arready = dmem_arready;
        assign dmem_araddr = memfy_araddr;
        assign dmem_arprot = memfy_arprot;
        assign dmem_arid = memfy_arid;

        assign memfy_rvalid = dmem_rvalid;
        assign dmem_rready = memfy_rready;
        assign memfy_rid = dmem_rid;
        assign memfy_rresp = dmem_rresp;
        assign memfy_rdata = dmem_rdata;

    end
    endgenerate

endmodule
`resetall
