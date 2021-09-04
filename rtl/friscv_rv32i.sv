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

module friscv_rv32i

    #(
        ///////////////////////////////////////////////////////////////////////////
        // Global setup
        ///////////////////////////////////////////////////////////////////////////

        // Instruction length (always 32, whatever the architecture)
        parameter ILEN               = 32,
        // RISCV Architecture
        parameter XLEN               = 32,
        // Boot address used by the control unit
        parameter BOOT_ADDR          = 0,
        // Number of outstanding requests used by the control unit
        parameter INST_OSTDREQ_NUM   = 8,
        // Core Hart ID
        parameter MHART_ID           = 0,
        // RV32E architecture, limits integer registers to 16, else 32
        parameter RV32E              = 0,

        ///////////////////////////////////////////////////////////////////////////
        // AXI4 / AXI4-lite interface setup
        ///////////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W         = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W           = 8,
        // AXI4 data width, for instruction and a data bus
        parameter AXI_IMEM_W         = XLEN,
        parameter AXI_DMEM_W         = XLEN,

        ///////////////////////////////////////////////////////////////////////////
        // Cache setup
        ///////////////////////////////////////////////////////////////////////////

        // Enable instruction cache
        parameter ICACHE_EN          = 0,
        // Line width defining only the data payload, in bits, must an
        // integer multiple of XLEN
        parameter ICACHE_LINE_W       = XLEN*4,
        // Number of lines in the cache
        parameter ICACHE_DEPTH        = 512

    )(
        // clock/reset interface
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // enable signal to activate the core
        input  logic                      enable,
        // Internal core status
        output logic [8             -1:0] status,
        // instruction memory interface
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
        // data memory interface
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

    logic                        flush_req;
    logic                        flush_ack;

    logic [4               -1:0] traps;
    logic                        csr_ro_trap;

    logic                        ctrl_mepc_wr;
    logic [XLEN            -1:0] ctrl_mepc;
    logic                        ctrl_mstatus_wr;
    logic [XLEN            -1:0] ctrl_mstatus;
    logic                        ctrl_mcause_wr;
    logic [XLEN            -1:0] ctrl_mcause;
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
    // CSR circuit received a command to write into a read-only register
    assign status[4] = csr_ro_trap;
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
        .traps          (traps ),
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
        .csr_sb         (csr_sb)
    );


    generate
    if (ICACHE_EN) begin : USE_ICACHE

    friscv_icache
    #(
        .ILEN         (ILEN),
        .XLEN         (XLEN),
        .OSTDREQ_NUM  (INST_OSTDREQ_NUM),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_DATA_W   (AXI_IMEM_W),
        .CACHE_LINE_W (ICACHE_LINE_W),
        .CACHE_DEPTH  (ICACHE_DEPTH)
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
    assign imem_arid = inst_arid_s;
    assign inst_rvalid_s = imem_rvalid;
    assign imem_rready = inst_rready_s;
    assign inst_rid_s = imem_rid;
    assign inst_rresp_s = imem_rresp;
    assign inst_rdata_s = imem_rdata;

    // Always assert ack if requesting cache flush to avoid deadlock
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
        .valid           (csr_en),
        .ready           (csr_ready),
        .instbus         (csr_instbus),
        .rs1_addr        (csr_rs1_addr),
        .rs1_val         (csr_rs1_val),
        .rd_wr_en        (csr_rd_wr),
        .rd_wr_addr      (csr_rd_addr),
        .rd_wr_val       (csr_rd_val),
        .ro_trap         (csr_ro_trap),
        .ctrl_mepc_wr    (ctrl_mepc_wr),
        .ctrl_mepc       (ctrl_mepc),
        .ctrl_mstatus_wr (ctrl_mstatus_wr),
        .ctrl_mstatus    (ctrl_mstatus),
        .ctrl_mcause_wr  (ctrl_mcause_wr),
        .ctrl_mcause     (ctrl_mcause),
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
        .AXI_DATA_W   (AXI_DMEM_W)
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
        .awvalid        (dmem_awvalid),
        .awready        (dmem_awready),
        .awaddr         (dmem_awaddr),
        .awprot         (dmem_awprot),
        .awid           (dmem_awid),
        .wvalid         (dmem_wvalid),
        .wready         (dmem_wready),
        .wdata          (dmem_wdata),
        .wstrb          (dmem_wstrb),
        .bvalid         (dmem_bvalid),
        .bready         (dmem_bready),
        .bid            (dmem_bid),
        .bresp          (dmem_bresp),
        .arvalid        (dmem_arvalid),
        .arready        (dmem_arready),
        .araddr         (dmem_araddr),
        .arprot         (dmem_arprot),
        .arid           (dmem_arid),
        .rvalid         (dmem_rvalid),
        .rready         (dmem_rready),
        .rid            (dmem_rid),
        .rresp          (dmem_rresp),
        .rdata          (dmem_rdata)
    );


endmodule
`resetall
