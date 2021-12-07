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

module friscv_rv32i_core

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
        // Number of outstanding requests used by the control unit
        parameter INST_OSTDREQ_NUM   = 8,
        // Core Hart ID
        parameter MHART_ID           = 0,
        // RV32E architecture, limits integer registers to 16, else 32 available
        parameter RV32E              = 0,

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

        // Enable instruction cache
        parameter ICACHE_EN          = 0,
        // Enable cache block prefetch
        parameter ICACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter ICACHE_BLOCK_W     = XLEN*4,
        // Number of blocks in the cache
        parameter ICACHE_DEPTH       = 512,

        // Enable data cache
        parameter DCACHE_EN          = 0,
        // Enable cache block prefetch
        parameter DCACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter DCACHE_BLOCK_W     = XLEN*4,
        // Number of blocks in the cache
        parameter DCACHE_DEPTH       = 512
    )(
        // Clock/reset interface
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // External interrupt
        input  logic                      irq,
        // Internal core status
        output logic [8             -1:0] status,
        `ifdef FRISCV_SIM
        output logic                      error,
        `endif
        // Instruction memory interface
        output logic                      imem_arvalid,
        input  logic                      imem_arready,
        output logic [AXI_ADDR_W    -1:0] imem_araddr,
        output logic [3             -1:0] imem_arprot,
        output logic [AXI_ID_W      -1:0] imem_arid,
        input  logic                      imem_rvalid,
        output logic                      imem_rready,
        input  logic [AXI_ID_W      -1:0] imem_rid,
        input  logic [2             -1:0] imem_rresp,
        input  logic [AXI_IMEM_W    -1:0] imem_rdata,
        // Data memory interface
        output logic                      dmem_awvalid,
        input  logic                      dmem_awready,
        output logic [AXI_ADDR_W    -1:0] dmem_awaddr,
        output logic [3             -1:0] dmem_awprot,
        output logic [AXI_ID_W      -1:0] dmem_awid,
        output logic                      dmem_wvalid,
        input  logic                      dmem_wready,
        output logic [AXI_DMEM_W    -1:0] dmem_wdata,
        output logic [AXI_DMEM_W/8  -1:0] dmem_wstrb,
        input  logic                      dmem_bvalid,
        output logic                      dmem_bready,
        input  logic [AXI_ID_W      -1:0] dmem_bid,
        input  logic [2             -1:0] dmem_bresp,
        output logic                      dmem_arvalid,
        input  logic                      dmem_arready,
        output logic [AXI_ADDR_W    -1:0] dmem_araddr,
        output logic [3             -1:0] dmem_arprot,
        output logic [AXI_ID_W      -1:0] dmem_arid,
        input  logic                      dmem_rvalid,
        output logic                      dmem_rready,
        input  logic [AXI_ID_W      -1:0] dmem_rid,
        input  logic [2             -1:0] dmem_rresp,
        input  logic [AXI_DMEM_W    -1:0] dmem_rdata
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    logic [5               -1:0] ctrl_rs1_addr;
    logic [XLEN            -1:0] ctrl_rs1_val;
    logic [5               -1:0] ctrl_rs2_addr;
    logic [XLEN            -1:0] ctrl_rs2_val;
    logic                        ctrl_rd_wr;
    logic [5               -1:0] ctrl_rd_addr;
    logic [XLEN            -1:0] ctrl_rd_val;

    logic [5               -1:0] alu_rs1_addr;
    logic [XLEN            -1:0] alu_rs1_val;
    logic [5               -1:0] alu_rs2_addr;
    logic [XLEN            -1:0] alu_rs2_val;
    logic                        alu_rd_wr;
    logic [5               -1:0] alu_rd_addr;
    logic [XLEN            -1:0] alu_rd_val;
    logic [XLEN/8          -1:0] alu_rd_strb;

    logic [5               -1:0] memfy_rs1_addr;
    logic [XLEN            -1:0] memfy_rs1_val;
    logic [5               -1:0] memfy_rs2_addr;
    logic [XLEN            -1:0] memfy_rs2_val;
    logic                        memfy_rd_wr;
    logic [5               -1:0] memfy_rd_addr;
    logic [XLEN            -1:0] memfy_rd_val;
    logic [XLEN/8          -1:0] memfy_rd_strb;

    logic [5               -1:0] csr_rs1_addr;
    logic [XLEN            -1:0] csr_rs1_val;
    logic                        csr_rd_wr;
    logic [5               -1:0] csr_rd_addr;
    logic [XLEN            -1:0] csr_rd_val;
    logic [XLEN/8          -1:0] csr_rd_strb;

    logic                        proc_en;
    logic [`INST_BUS_W     -1:0] proc_instbus;
    logic                        proc_ready;
    logic                        memfy_ready;
    logic                        proc_empty;
    logic [4               -1:0] proc_fenceinfo;

    logic                        csr_en;
    logic [`INST_BUS_W     -1:0] csr_instbus;
    logic                        csr_ready;

    logic                        inst_arvalid_s;
    logic                        inst_arready_s;
    logic [AXI_ADDR_W      -1:0] inst_araddr_s;
    logic [3               -1:0] inst_arprot_s;
    logic [AXI_ID_W        -1:0] inst_arid_s;
    logic                        inst_rvalid_s;
    logic                        inst_rready_s;
    logic [AXI_ID_W        -1:0] inst_rid_s;
    logic [2               -1:0] inst_rresp_s;
    logic [ILEN            -1:0] inst_rdata_s;

    logic                        memfy_awvalid;
    logic                        memfy_awready;
    logic [AXI_ADDR_W      -1:0] memfy_awaddr;
    logic [3               -1:0] memfy_awprot;
    logic [AXI_ID_W        -1:0] memfy_awid;
    logic                        memfy_wvalid;
    logic                        memfy_wready;
    logic [XLEN            -1:0] memfy_wdata;
    logic [XLEN/8          -1:0] memfy_wstrb;
    logic                        memfy_bvalid;
    logic                        memfy_bready;
    logic [AXI_ID_W        -1:0] memfy_bid;
    logic [2               -1:0] memfy_bresp;
    logic                        memfy_arvalid;
    logic                        memfy_arready;
    logic [AXI_ADDR_W      -1:0] memfy_araddr;
    logic [3               -1:0] memfy_arprot;
    logic [AXI_ID_W        -1:0] memfy_arid;
    logic                        memfy_rvalid;
    logic                        memfy_rready;
    logic [AXI_ID_W        -1:0] memfy_rid;
    logic [2               -1:0] memfy_rresp;
    logic [XLEN            -1:0] memfy_rdata;

    logic                        flush_req;
    logic                        flush_ack;

    logic [5               -1:0] traps;

    logic                        ctrl_mepc_wr;
    logic [XLEN            -1:0] ctrl_mepc;
    logic                        ctrl_mstatus_wr;
    logic [XLEN            -1:0] ctrl_mstatus;
    logic                        ctrl_mcause_wr;
    logic [XLEN            -1:0] ctrl_mcause;
    logic                        ctrl_mtval_wr;
    logic [XLEN            -1:0] ctrl_mtval;
    logic [`CSR_SB_W       -1:0] csr_sb;

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
        .RV32E  (RV32E),
        .XLEN   (XLEN)
    )
    isa_registers
    (
        .aclk            (aclk           ),
        .aresetn         (aresetn        ),
        .srst            (srst           ),
        `ifdef FRISCV_SIM
        .error           (error          ),
        `endif
        .ctrl_rs1_addr   (ctrl_rs1_addr  ),
        .ctrl_rs1_val    (ctrl_rs1_val   ),
        .ctrl_rs2_addr   (ctrl_rs2_addr  ),
        .ctrl_rs2_val    (ctrl_rs2_val   ),
        .ctrl_rd_wr      (ctrl_rd_wr     ),
        .ctrl_rd_addr    (ctrl_rd_addr   ),
        .ctrl_rd_val     (ctrl_rd_val    ),
        .alu_rs1_addr    (alu_rs1_addr   ),
        .alu_rs1_val     (alu_rs1_val    ),
        .alu_rs2_addr    (alu_rs2_addr   ),
        .alu_rs2_val     (alu_rs2_val    ),
        .alu_rd_wr       (alu_rd_wr      ),
        .alu_rd_addr     (alu_rd_addr    ),
        .alu_rd_val      (alu_rd_val     ),
        .alu_rd_strb     (alu_rd_strb    ),
        .memfy_rs1_addr  (memfy_rs1_addr ),
        .memfy_rs1_val   (memfy_rs1_val  ),
        .memfy_rs2_addr  (memfy_rs2_addr ),
        .memfy_rs2_val   (memfy_rs2_val  ),
        .memfy_rd_wr     (memfy_rd_wr    ),
        .memfy_rd_addr   (memfy_rd_addr  ),
        .memfy_rd_val    (memfy_rd_val   ),
        .memfy_rd_strb   (memfy_rd_strb  ),
        .csr_rs1_addr    (csr_rs1_addr   ),
        .csr_rs1_val     (csr_rs1_val    ),
        .csr_rd_wr       (csr_rd_wr      ),
        .csr_rd_addr     (csr_rd_addr    ),
        .csr_rd_val      (csr_rd_val     )
    );


    //////////////////////////////////////////////////////////////////////////
    // Central controller sequencing the operations
    //////////////////////////////////////////////////////////////////////////

    friscv_control
    #(
        .ILEN        (ILEN),
        .XLEN        (XLEN),
        .AXI_ADDR_W  (AXI_ADDR_W),
        .AXI_ID_W    (AXI_ID_W),
        .AXI_DATA_W  (XLEN),
        .OSTDREQ_NUM (INST_OSTDREQ_NUM),
        .BOOT_ADDR   (BOOT_ADDR)
    )
    control
    (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .srst           (srst),
        .traps          (traps),
        .flush_req      (flush_req),
        .flush_ack      (flush_ack),
        .arvalid        (inst_arvalid_s),
        .arready        (inst_arready_s),
        .araddr         (inst_araddr_s),
        .arprot         (inst_arprot_s),
        .arid           (inst_arid_s),
        .rvalid         (inst_rvalid_s),
        .rready         (inst_rready_s),
        .rid            (inst_rid_s),
        .rresp          (inst_rresp_s),
        .rdata          (inst_rdata_s),
        .proc_en        (proc_en),
        .proc_ready     (proc_ready),
        .proc_empty     (proc_empty),
        .proc_fenceinfo (proc_fenceinfo),
        .proc_instbus   (proc_instbus),
        .csr_en         (csr_en),
        .csr_ready      (csr_ready),
        .csr_instbus    (csr_instbus),
        .ctrl_rs1_addr  (ctrl_rs1_addr),
        .ctrl_rs1_val   (ctrl_rs1_val),
        .ctrl_rs2_addr  (ctrl_rs2_addr),
        .ctrl_rs2_val   (ctrl_rs2_val),
        .ctrl_rd_wr     (ctrl_rd_wr),
        .ctrl_rd_addr   (ctrl_rd_addr),
        .ctrl_rd_val    (ctrl_rd_val),
        .mepc_wr        (ctrl_mepc_wr),
        .mepc           (ctrl_mepc),
        .mstatus_wr     (ctrl_mstatus_wr),
        .mstatus        (ctrl_mstatus),
        .mcause_wr      (ctrl_mcause_wr),
        .mcause         (ctrl_mcause),
        .mtval_wr       (ctrl_mtval_wr),
        .mtval          (ctrl_mtval),
        .csr_sb         (csr_sb)
    );


    //////////////////////////////////////////////////////////////////////////
    // Instruction cache stage
    //////////////////////////////////////////////////////////////////////////

    generate
    if (ICACHE_EN) begin : USE_ICACHE

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
        .flush_req         (flush_req),
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
    assign imem_arid = inst_arid_s | AXI_IMEM_MASK;
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
        .RV32E     (RV32E),
        .MHART_ID  (MHART_ID),
        .XLEN      (XLEN)
    )
    csrs
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .eirq            (irq),
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
        .csr_sb          (csr_sb)
    );


    //////////////////////////////////////////////////////////////////////////
    // All ISA enxtensions supported: standard arithmetic / memory, ...
    //////////////////////////////////////////////////////////////////////////

    friscv_processing
    #(
        .XLEN         (XLEN),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_DATA_W   (XLEN),
        .AXI_ID_MASK  (AXI_DMEM_MASK)
    )
    processing
    (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .srst           (srst),
        .proc_en        (proc_en),
        .proc_ready     (proc_ready),
        .proc_empty     (proc_empty),
        .proc_fenceinfo (proc_fenceinfo),
        .proc_instbus   (proc_instbus),
        .alu_rs1_addr   (alu_rs1_addr),
        .alu_rs1_val    (alu_rs1_val),
        .alu_rs2_addr   (alu_rs2_addr),
        .alu_rs2_val    (alu_rs2_val),
        .alu_rd_wr      (alu_rd_wr),
        .alu_rd_addr    (alu_rd_addr),
        .alu_rd_val     (alu_rd_val),
        .alu_rd_strb    (alu_rd_strb),
        .memfy_rs1_addr (memfy_rs1_addr),
        .memfy_rs1_val  (memfy_rs1_val),
        .memfy_rs2_addr (memfy_rs2_addr),
        .memfy_rs2_val  (memfy_rs2_val),
        .memfy_rd_wr    (memfy_rd_wr),
        .memfy_rd_addr  (memfy_rd_addr),
        .memfy_rd_val   (memfy_rd_val),
        .memfy_rd_strb  (memfy_rd_strb),
        .awvalid        (memfy_awvalid),
        .awready        (memfy_awready),
        .awaddr         (memfy_awaddr),
        .awprot         (memfy_awprot),
        .awid           (memfy_awid),
        .wvalid         (memfy_wvalid),
        .wready         (memfy_wready),
        .wdata          (memfy_wdata),
        .wstrb          (memfy_wstrb),
        .bvalid         (memfy_bvalid),
        .bready         (memfy_bready),
        .bid            (memfy_bid),
        .bresp          (memfy_bresp),
        .arvalid        (memfy_arvalid),
        .arready        (memfy_arready),
        .araddr         (memfy_araddr),
        .arprot         (memfy_arprot),
        .arid           (memfy_arid),
        .rvalid         (memfy_rvalid),
        .rready         (memfy_rready),
        .rid            (memfy_rid),
        .rresp          (memfy_rresp),
        .rdata          (memfy_rdata)
    );

    generate

    if (DCACHE_EN) begin: DCACHE_ON

    friscv_dcache
    #(
    .ILEN              (ILEN),
    .XLEN              (XLEN),
    .OSTDREQ_NUM       (4),
    .AXI_ADDR_W        (AXI_ADDR_W),
    .AXI_ID_W          (AXI_ID_W),
    .AXI_DATA_W        (AXI_DMEM_W),
    .AXI_ID_MASK       (AXI_DMEM_MASK),
    .CACHE_PREFETCH_EN (DCACHE_PREFETCH_EN),
    .CACHE_BLOCK_W     (DCACHE_BLOCK_W),
    .CACHE_DEPTH       (DCACHE_DEPTH)
    )
    dcache
    (
    .aclk            (aclk),
    .aresetn         (aresetn),
    .srst            (srst),
    .flush_req       (1'b0),
    .flush_ack       (),
    .memfy_awvalid   (memfy_awvalid),
    .memfy_awready   (memfy_awready),
    .memfy_awaddr    (memfy_awaddr),
    .memfy_awprot    (memfy_awprot),
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
    assign dmem_awid = memfy_awid | AXI_DMEM_MASK;

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
    assign dmem_arid = memfy_arid | AXI_DMEM_MASK;

    assign memfy_rvalid = dmem_rvalid;
    assign dmem_rready = memfy_rready;
    assign memfy_rid = dmem_rid;
    assign memfy_rresp = dmem_rresp;
    assign memfy_rdata = dmem_rdata;

    end
    endgenerate

endmodule
`resetall
