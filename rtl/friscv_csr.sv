// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_csr

    #(
        parameter PERF_REG_W  = 32,
        parameter PERF_NB_BUS = 3,
        // Architecture selection:
        // 32 or 64 bits support
        parameter XLEN = 32,
        // Floating-point extension support
        parameter F_EXTENSION = 0,
        // Multiply/Divide extension support
        parameter M_EXTENSION = 0,
        // Support hypervisor mode
        parameter HYPERVISOR_MODE = 0,
        // Support supervisor mode
        parameter SUPERVISOR_MODE = 0,
        // Support user mode
        parameter USER_MODE = 0,
        // Reduced RV32 arch
        parameter RV32E = 0,
        // MHART_ID CSR value
        parameter HART_ID = 0,
        // PMP / PMA supported
        //  = 0, no PMP
        //  = 1, PMP available but fixed synthesis thus at boot time
        //  > 1, PMP available and configurable at runtime
        parameter MPU_SUPPORT = 0,
        // Number of physical memory protection regions
        parameter NB_PMP_REGION = 16,
        // Maximum PMP regions support by the core
        parameter MAX_PMP_REGION = 16,
        // PMP value at initialization
        parameter PMPCFG0_INIT   = 32'h0,
        parameter PMPCFG1_INIT   = 32'h0,
        parameter PMPCFG2_INIT   = 32'h0,
        parameter PMPCFG3_INIT   = 32'h0,
        parameter PMPADDR0_INIT  = 32'h0,
        parameter PMPADDR1_INIT  = 32'h0,
        parameter PMPADDR2_INIT  = 32'h0,
        parameter PMPADDR3_INIT  = 32'h0,
        parameter PMPADDR4_INIT  = 32'h0,
        parameter PMPADDR5_INIT  = 32'h0,
        parameter PMPADDR6_INIT  = 32'h0,
        parameter PMPADDR7_INIT  = 32'h0,
        parameter PMPADDR8_INIT  = 32'h0,
        parameter PMPADDR9_INIT  = 32'h0,
        parameter PMPADDR10_INIT = 32'h0,
        parameter PMPADDR11_INIT = 32'h0,
        parameter PMPADDR12_INIT = 32'h0,
        parameter PMPADDR13_INIT = 32'h0,
        parameter PMPADDR14_INIT = 32'h0,
        parameter PMPADDR15_INIT = 32'h0,
        // Virtual memory support
        parameter MMU_SUPPORT = 0
    )(
        // Clock/reset interface
        input  wire                    aclk,
        input  wire                    aresetn,
        input  wire                    srst,
        // Interrupts
        input  wire                    ext_irq,
        input  wire                    sw_irq,
        input  wire                    timer_irq,
        // privilege bus, encoding current mode
        input  wire  [4          -1:0] priv,
        // Instruction bus
        input  wire                    valid,
        output logic                   ready,
        input  wire  [`INST_BUS_W-1:0] instbus,
        // Register source 1 query interface
        output logic [5          -1:0] rs1_addr,
        input  wire  [XLEN       -1:0] rs1_val,
        output logic                   rd_wr_en,
        output logic [5          -1:0] rd_wr_addr,
        output logic [XLEN       -1:0] rd_wr_val,
        // Performance registers bus
        input  wire  [PERF_REG_W*3*PERF_NB_BUS -1:0] perfs,
        // CSR shared bus
        output logic [`CSR_SB_W  -1:0] csr_sb,
        input  logic [`CTRL_SB_W -1:0] ctrl_sb
    );

    // ------------------------------------------------------------------------
    // TODO: Ensure CSRRW/CSRRWI read doesn't indude side effect on read if
    //       rd=0 as specified in chapter 9 Zicsr
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    // Declarations
    // ------------------------------------------------------------------------

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        STORE
    } fsm;

    fsm cfsm;

    // instructions fields
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`RS1_W      -1:0] rs1;
    logic [`RD_W       -1:0] rd;
    logic [`ZIMM_W     -1:0] zimm;
    logic [`CSR_W      -1:0] csr;

    logic                    csr_wren;
    logic                    csr_rden;
    logic [XLEN        -1:0] oldval;
    logic [XLEN        -1:0] newval;

    logic                    ext_irq_sync;
    logic                    timer_irq_sync;
    logic                    sw_irq_sync;

    // External source of CSRs
    logic                    ctrl_mepc_wr;
    logic  [XLEN       -1:0] ctrl_mepc;
    logic                    ctrl_mstatus_wr;
    logic  [XLEN       -1:0] ctrl_mstatus;
    logic                    ctrl_mcause_wr;
    logic  [XLEN       -1:0] ctrl_mcause;
    logic                    ctrl_mtval_wr;
    logic  [XLEN       -1:0] ctrl_mtval;
    logic  [64         -1:0] ctrl_rdinstret;
    logic                    ctrl_clr_meip;


    ///////////////////////////////////////////////////////////////////////////
    // Build mstatus content 
    // @data: the new value to write into the CSR
    // @returns the formatted register based on spec and extension supported
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN-1:0] get_mstatus (
        input logic [XLEN-1:0] data
    );
        // SD
        get_mstatus[31] = '0;
        // WPRI
        get_mstatus[30:23] = '0;
        // TSR
        if (SUPERVISOR_MODE)
            get_mstatus[22] = data[22];
        else
            get_mstatus[22] = '0;
        // TW
        if (SUPERVISOR_MODE || USER_MODE)
            get_mstatus[21] = data[21];
        else
            get_mstatus[21] = '0;
        // TVM
        if (SUPERVISOR_MODE)
            get_mstatus[20] = data[20];
        else
            get_mstatus[20] = '0;
        // MXR
        if (SUPERVISOR_MODE)
            get_mstatus[19] = data[19];
        else
            get_mstatus[19] = '0;
        // SUM
        if (SUPERVISOR_MODE)
            get_mstatus[18] = data[18];
        else
            get_mstatus[18] = '0;
        // MPRV
        if (SUPERVISOR_MODE || USER_MODE)
            get_mstatus[17] = data[17];
        else
            get_mstatus[17] = '0;
        // XS
        get_mstatus[16:15] = '0;
        // FS
        if (F_EXTENSION)
            get_mstatus[14:13] = data[14:13];
        else
            get_mstatus[14:13] = '0;
        // MPP
        get_mstatus[12:11] = data[12:11];
        // VS
        get_mstatus[10:9] = '0;
        // SPP
        if (SUPERVISOR_MODE)
            get_mstatus[8] = data[8];
        else
            get_mstatus[8] = '0;
        // MPIE
        get_mstatus[7] = data[7];
        // UBE
        get_mstatus[6] = '0;
        // SPIE
        if (SUPERVISOR_MODE)
            get_mstatus[5] = data[5];
        else
            get_mstatus[5] = '0;
        // WPRI
        get_mstatus[4] = '0;
        // MIE
        get_mstatus[3] = data[3];
        // WPRI
        get_mstatus[2] = '0;
        // SIE
        if (SUPERVISOR_MODE)
            get_mstatus[1] = data[1];
        else
            get_mstatus[1] = '0;
        // WPRI
        get_mstatus[0] = '0;

    endfunction

    //////////////////////////////////////////////////////////////////////////
    // CSR Addresses
    //////////////////////////////////////////////////////////////////////////

    /*
     * Machine-level CSR addresses
     */

    // Machine Information Registers
    localparam MHART_ID     = 12'hF14;
    // Machine Trap Setup
    localparam MSTATUS      = 12'h300;
    localparam MISA         = 12'h301;
    localparam MEDELEG      = 12'h302;
    localparam MIDELEG      = 12'h303;
    localparam MIE          = 12'h304;
    localparam MTVEC        = 12'h305;
    localparam MCOUNTEREN   = 12'h306;
    // Machine Trap Handling
    localparam MSCRATCH     = 12'h340;
    localparam MEPC         = 12'h341;
    localparam MCAUSE       = 12'h342;
    localparam MTVAL        = 12'h343;
    localparam MIP          = 12'h344;
    // Machine Memory Protection
    localparam PMPCFG0      = 12'h3A0;
    localparam PMPCFG1      = 12'h3A1;
    localparam PMPCFG2      = 12'h3A2;
    localparam PMPCFG3      = 12'h3A3;
    localparam PMPADDR0     = 12'h3B0;
    localparam PMPADDR1     = 12'h3B1;
    localparam PMPADDR2     = 12'h3B2;
    localparam PMPADDR3     = 12'h3B3;
    localparam PMPADDR4     = 12'h3B4;
    localparam PMPADDR5     = 12'h3B5;
    localparam PMPADDR6     = 12'h3B6;
    localparam PMPADDR7     = 12'h3B7;
    localparam PMPADDR8     = 12'h3B8;
    localparam PMPADDR9     = 12'h3B9;
    localparam PMPADDR10    = 12'h3BA;
    localparam PMPADDR11    = 12'h3BB;
    localparam PMPADDR12    = 12'h3BC;
    localparam PMPADDR13    = 12'h3BD;
    localparam PMPADDR14    = 12'h3BE;
    localparam PMPADDR15    = 12'h3BF;

    /*
     * Supervisor-level CSR addresses
     */

    // Supervisor Trap Setup
    localparam SSTATUS      = 12'h100;
    localparam SIE          = 12'h104;
    localparam STVEC        = 12'h105;
    localparam SCOUNTEREN   = 12'h100;
    // Supervisor Configuration
    localparam SENVCFG      = 12'h10A;
    // Supervisor Trap Handling
    localparam SSCRATCH     = 12'h140;
    localparam SEPC         = 12'h141;
    localparam SCAUSE       = 12'h142;
    localparam STVAL        = 12'h143;
    localparam SIP          = 12'h144;
    // Supervisor Protection and Translation
    localparam SATP         = 12'h180;
    // Debug/Trace Registers
    localparam SCONTEXT     = 12'h5A8;

    /*
     * Unprivileged CSR addresses
     */

    localparam RDCYCLE      = 12'hC00;
    localparam RDTIME       = 12'hC01;
    localparam RDINSTRET    = 12'hC02;
    localparam RDCYCLEH     = 12'hC80;
    localparam RDTIMEH      = 12'hC81;
    localparam RDINSTRETH   = 12'hC82;

    /*
     * Custom unprivileged CSR addresses
     */

    localparam INSTREQ_ACTIVE   = 12'hFC0;
    localparam INSTREQ_SLEEP    = 12'hFC1;
    localparam INSTREQ_STALL    = 12'hFC2;
    localparam INSTCPL_ACTIVE   = 12'hFC3;
    localparam INSTCPL_SLEEP    = 12'hFC4;
    localparam INSTCPL_STALL    = 12'hFC5;
    localparam PROC_ACTIVE      = 12'hFC6;
    localparam PROC_SLEEP       = 12'hFC7;
    localparam PROC_STALL       = 12'hFC8;


    // Machine Information Status
    // logic [XLEN-1:0] mvendorid;  // 0xF11    MRO (not implemented)
    // logic [XLEN-1:0] marchid;    // 0xF12    MRO (not implemented)
    // logic [XLEN-1:0] mimpid;     // 0xF13    MRO (not implemented)
    logic [XLEN-1:0] mhartid;       // 0xF14    MRO
    // logic [XLEN-1:0] mconfigptr; // 0xF15    MRO (not implemented)

    // Machine Trap Status
    logic [XLEN-1:0] mstatus;       // 0x300    MRW
    logic [XLEN-1:0] misa;          // 0x301    MRO
    logic [XLEN-1:0] medeleg;       // 0x302    MRW
    logic [XLEN-1:0] mideleg;       // 0x303    MRW
    logic [XLEN-1:0] mie;           // 0x304    MRW
    logic [XLEN-1:0] mtvec;         // 0x305    MRW
    logic [XLEN-1:0] mcounteren;    // 0x306    MRW

    // Machine Trap Handling
    logic [XLEN-1:0] mscratch;      // 0x340    MRW
    logic [XLEN-1:0] mepc;          // 0x341    MRW
    logic [XLEN-1:0] mcause;        // 0x342    MRW
    logic [XLEN-1:0] mtval;         // 0x343    MRW
    logic [XLEN-1:0] mip;           // 0x344    MRW

    // Physical Memory Protection (PMP)
    logic [XLEN-1:0] pmpcfg0;       // 0x3A0    MRW
    logic [XLEN-1:0] pmpcfg1;       // 0x3A1    MRW
    logic [XLEN-1:0] pmpcfg2;       // 0x3A2    MRW
    logic [XLEN-1:0] pmpcfg3;       // 0x3A3    MRW
    logic [XLEN-1:0] pmpaddr0;      // 0x3B0    MRW
    logic [XLEN-1:0] pmpaddr1;      // 0x3B1    MRW
    logic [XLEN-1:0] pmpaddr2;      // 0x3B2    MRW
    logic [XLEN-1:0] pmpaddr3;      // 0x3B3    MRW
    logic [XLEN-1:0] pmpaddr4;      // 0x3B4    MRW
    logic [XLEN-1:0] pmpaddr5;      // 0x3B5    MRW
    logic [XLEN-1:0] pmpaddr6;      // 0x3B6    MRW
    logic [XLEN-1:0] pmpaddr7;      // 0x3B7    MRW
    logic [XLEN-1:0] pmpaddr8;      // 0x3B8    MRW
    logic [XLEN-1:0] pmpaddr9;      // 0x3B9    MRW
    logic [XLEN-1:0] pmpaddr10;     // 0x3BA    MRW
    logic [XLEN-1:0] pmpaddr11;     // 0x3BB    MRW
    logic [XLEN-1:0] pmpaddr12;     // 0x3BC    MRW
    logic [XLEN-1:0] pmpaddr13;     // 0x3BD    MRW
    logic [XLEN-1:0] pmpaddr14;     // 0x3BE    MRW
    logic [XLEN-1:0] pmpaddr15;     // 0x3BF    MRW

    // “Zicntr” Standard Extension for Base Counters and Timers
    logic [64  -1:0] rdcycle;          // 0xC00    MRO (0xC80 for 32b MSBs)
    logic [64  -1:0] rdtime;           // 0xC01    MRO (0xC81 for 32b MSBs)
    logic [64  -1:0] rdinstret;        // 0xC02    MRO (0xC82 for 32b MSBs)

    // Custom register spying on AXI4-lite bus
    logic [32  -1:0] instreq_perf_active;
    logic [32  -1:0] instreq_perf_sleep;
    logic [32  -1:0] instreq_perf_stall;
    logic [32  -1:0] instcpl_perf_active;
    logic [32  -1:0] instcpl_perf_sleep;
    logic [32  -1:0] instcpl_perf_stall;
    logic [32  -1:0] proc_perf_active;
    logic [32  -1:0] proc_perf_sleep;
    logic [32  -1:0] proc_perf_stall;

    //////////////////////////////////////////////////////////////////////////
    // Supervisor-level CSRs:
    //////////////////////////////////////////////////////////////////////////

    // Supervisor Protection and Translation
    // logic [XLEN-1:0] satp;          // 0x180


    //////////////////////////////////////////////////////////////////////////
    // User-level CSRs:
    //////////////////////////////////////////////////////////////////////////

    // User Counter/Timers
    // logic [XLEN-1:0] ucycle;         // 0xC00


    //////////////////////////////////////////////////////////////////////////
    // Decompose the instruction bus
    //////////////////////////////////////////////////////////////////////////

    assign opcode = instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = instbus[`FUNCT3 +: `FUNCT3_W];
    assign rs1    = instbus[`RS1    +: `RS1_W   ];
    assign rd     = instbus[`RD     +: `RD_W    ];
    assign zimm   = instbus[`ZIMM   +: `ZIMM_W  ];
    assign csr    = instbus[`CSR    +: `CSR_W   ];

    assign rs1_addr = rs1;

    // Always handshakes the request but this flag could stop
    // the transfer if needed in case of extra pipeline
    assign ready = 1'b1;

    //////////////////////////////////////////////////////////////////////////
    // Synchronize the IRQs in the core's clock domain
    //////////////////////////////////////////////////////////////////////////

    friscv_bit_sync
    #(
        .DEPTH (2)
    )
    ext_irq_synchro
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .bit_i   (ext_irq),
        .bit_o   (ext_irq_sync)
    );

    friscv_bit_sync
    #(
        .DEPTH (2)
    )
    timer_irq_synchro
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .bit_i   (timer_irq),
        .bit_o   (timer_irq_sync)
    );

    friscv_bit_sync
    #(
        .DEPTH (2)
    )
    sw_irq_synchro
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .bit_i   (sw_irq),
        .bit_o   (sw_irq_sync)
    );


    //////////////////////////////////////////////////////////////////////////
    // ISA register Write Stage
    //////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd_wr_en <= 1'b0;
            rd_wr_addr <= 5'b0;
            rd_wr_val <= {XLEN{1'b0}};
        end else if (srst) begin
            rd_wr_en <= 1'b0;
            rd_wr_addr <= 5'b0;
            rd_wr_val <= {XLEN{1'b0}};
        end else begin
            rd_wr_en <= valid;
            rd_wr_addr <= rd;
            rd_wr_val <= oldval;
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // Activation of write in CSR and preparation of the new value
    //////////////////////////////////////////////////////////////////////////
    always @ (*) begin

        if (valid) begin

            csr_wren = 1'b0;
            newval = '0;

            if (funct3==`CSRRW) begin
                csr_wren = 1'b1;
                newval = rs1_val;

            // Save CSR in RS1 and apply a set mask with rs1
            end else if (funct3==`CSRRS) begin
                if (rs1_addr!=5'b0) begin
                    csr_wren = 1'b1;
                    newval = oldval | rs1_val;
                end

            // Save CSR in RS1 then apply a clear mask fwith rs1
            end else if (funct3==`CSRRC) begin
                if (rs1_addr!=5'b0) begin
                    csr_wren = 1'b1;
                    newval = oldval & rs1_val;
                end

            // Store CSR in RS1 then set CSR to Zimm
            end else if (funct3==`CSRRWI) begin
                csr_wren = 1'b1;
                newval = {{XLEN-5{1'b0}}, zimm};

            // Save CSR in RS1 and apply a set mask with Zimm
            end else if (funct3==`CSRRSI) begin
                if (zimm!=5'b0) begin
                    csr_wren = 1'b1;
                    newval = oldval | {{(XLEN-`ZIMM_W){1'b0}}, zimm};
                end

            // Save CSR in RS1 and apply a clear mask with Zimm
            end else if (funct3==`CSRRCI) begin
                if (zimm!=5'b0) begin
                    csr_wren = 1'b1;
                    newval = oldval & {{(XLEN-`ZIMM_W){1'b0}}, zimm};
                end

            end
        end else begin
            csr_wren = 1'b0;
            newval = '0;
        end
    end

    //////////////////////////////////////////////////////////////////////////
    // Read circuit
    //////////////////////////////////////////////////////////////////////////

    always @ (*) begin
             if (csr==MSTATUS)         oldval = mstatus;
        else if (csr==MISA)            oldval = misa;
        else if (csr==MIE)             oldval = mie;
        else if (csr==MTVEC)           oldval = mtvec;
        else if (csr==MSCRATCH)        oldval = mscratch;
        else if (csr==MEPC)            oldval = mepc;
        else if (csr==MCAUSE)          oldval = mcause;
        else if (csr==MTVAL)           oldval = mtval;
        else if (csr==MIP)             oldval = mip;
        else if (csr==PMPCFG0)         oldval = pmpcfg0;
        else if (csr==PMPCFG1)         oldval = pmpcfg1;
        else if (csr==PMPCFG2)         oldval = pmpcfg2;
        else if (csr==PMPCFG3)         oldval = pmpcfg3;
        else if (csr==PMPADDR0)        oldval = pmpaddr0;
        else if (csr==PMPADDR1)        oldval = pmpaddr1;
        else if (csr==PMPADDR2)        oldval = pmpaddr2;
        else if (csr==PMPADDR3)        oldval = pmpaddr3;
        else if (csr==PMPADDR4)        oldval = pmpaddr4;
        else if (csr==PMPADDR5)        oldval = pmpaddr5;
        else if (csr==PMPADDR6)        oldval = pmpaddr6;
        else if (csr==PMPADDR7)        oldval = pmpaddr7;
        else if (csr==PMPADDR8)        oldval = pmpaddr8;
        else if (csr==PMPADDR9)        oldval = pmpaddr9;
        else if (csr==PMPADDR10)       oldval = pmpaddr10;
        else if (csr==PMPADDR11)       oldval = pmpaddr11;
        else if (csr==PMPADDR12)       oldval = pmpaddr12;
        else if (csr==PMPADDR13)       oldval = pmpaddr13;
        else if (csr==PMPADDR14)       oldval = pmpaddr14;
        else if (csr==PMPADDR15)       oldval = pmpaddr15;
        else if (csr==RDCYCLE)         oldval = rdcycle[0+:XLEN];
        else if (csr==RDTIME)          oldval = rdtime[0+:XLEN];
        else if (csr==RDINSTRET)       oldval = rdinstret[0+:XLEN];
        else if (csr==RDCYCLEH)        oldval = rdcycle[32+:32];
        else if (csr==RDTIMEH)         oldval = rdtime[32+:32];
        else if (csr==RDINSTRETH)      oldval = rdinstret[32+:32];
        else if (csr==MHART_ID)        oldval = mhartid;
        else if (csr==MCOUNTEREN)      oldval = mcounteren;
        else if (csr==INSTREQ_ACTIVE)  oldval = instreq_perf_active;
        else if (csr==INSTREQ_SLEEP)   oldval = instreq_perf_sleep;
        else if (csr==INSTREQ_STALL)   oldval = instreq_perf_stall;
        else if (csr==INSTCPL_ACTIVE)  oldval = instcpl_perf_active;
        else if (csr==INSTCPL_SLEEP)   oldval = instcpl_perf_sleep;
        else if (csr==INSTCPL_STALL)   oldval = instcpl_perf_stall;
        else if (csr==PROC_ACTIVE)     oldval = proc_perf_active;
        else if (csr==PROC_SLEEP)      oldval = proc_perf_sleep;
        else if (csr==PROC_STALL)      oldval = proc_perf_stall;
        else                           oldval = {XLEN{1'b0}};
    end


    //////////////////////////////////////////////////////////////////////////
    // CSRs description
    //
    // WPRI: Reserved Writes Preserve Values, Reads Ignore Values
    // WARL: Write Any, Read legal
    //
    //////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // HARTID - 0xF14 (RO)
    ///////////////////////////////////////////////////////////////////////////
    assign mhartid = HART_ID;

    ///////////////////////////////////////////////////////////////////////////
    // MISA - 0x301 (RO)
    ///////////////////////////////////////////////////////////////////////////

    // Supported extensions
    assign misa[0]  = 1'b0;                            // A Atomic extension
    assign misa[1]  = 1'b0;                            // B Tentatively reserved for Bit-Manipulation extension
    assign misa[2]  = 1'b0;                            // C Compressed extension
    assign misa[3]  = 1'b0;                            // D Double-precision floating-point extension
    assign misa[4]  = (RV32E) ? 1'b1 : 1'b0;           // E RV32E base ISA
    assign misa[5]  = (F_EXTENSION) ? 1'b1 : 1'b0;     // F Single-precision floating-point extension
    assign misa[6]  = 1'b0;                            // G Additional standard extensions present
    assign misa[7]  = (HYPERVISOR_MODE) ? 1'b1 : 1'b0; // H Hypervisor extension
    assign misa[8]  = (!RV32E) ? 1'b1 : 1'b0;          // I RV32I/64I/128I base ISA
    assign misa[9]  = 1'b0;                            // J Tentatively reserved for Dynamically Translated Languages extension
    assign misa[10] = 1'b0;                            // K Reserved
    assign misa[11] = 1'b0;                            // L Tentatively reserved for Decimal Floating-Point extension
    assign misa[12] = (M_EXTENSION) ? 1'b1 : 1'b0;     // M Integer Multiply/Divide extension
    assign misa[13] = 1'b0;                            // N User-level interrupts supported
    assign misa[14] = 1'b0;                            // O Reserved
    assign misa[15] = 1'b0;                            // P Tentatively reserved for Packed-SIMD extension
    assign misa[16] = 1'b0;                            // Q Quad-precision floating-point extension
    assign misa[17] = 1'b0;                            // R Reserved
    assign misa[18] = (SUPERVISOR_MODE) ? 1'b1 : 1'b0; // S Supervisor mode implemented
    assign misa[19] = 1'b0;                            // T Tentatively reserved for Transactional Memory extension
    assign misa[20] = (USER_MODE) ? 1'b1 : 1'b0;       // U User mode implemented
    assign misa[21] = 1'b0;                            // V Tentatively reserved for Vector extension
    assign misa[22] = 1'b0;                            // W Reserved
    assign misa[23] = 1'b0;                            // X Non-standard extensions present
    assign misa[24] = 1'b0;                            // Y Reserved
    assign misa[25] = 1'b0;                            // Z Reserved

    // MXLEN field encoding
    generate
    if (XLEN==32) begin : MXLEN_32
        assign misa[31:26] = {2'h1, 4'b0};
    end else if (XLEN==64) begin: MXLEN_64
        assign misa[63:26] = {2'h2, 36'b0};
    end else begin: MXLEN_128
        assign misa[127:26] = {2'h3, 100'b0};
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////////
    // MSTATUS - 0x300
    //
    // [31]      SD, Dirty State based XS / FS / VS
    // [30:23]   (WPRI)
    // [22]      TSR, Trap SRET
    //              = 1, attempts to execute SRET while executing in S-mode will raise
    //                an illegal instruction exception
    //              = 0, this operation is permitted in S-mode.
    // [21]      TW, Timeout Wait
    //              = 0, WFI instruction may execute in lower privilege modes
    //              = 1, if WFI is executed in any less-privileged mode, 
    //                   instruction causes an illegal instruction exception
    // [20]      TVM, Trap Virtual Memory
    //              = 1, attempts to read or write the satp or exec SFENCE.VMA or 
    //                   SINVAL.VMA will raise an exception
    //              = 0, these operations are permitted in S-mode
    // [19]      MXR, Make eXecutable Readable
    //              = 0, only loads from pages marked readable
    //              = 1, loads from pages marked either readable or executable
    // [18]      SUM: Supervisor User Memory access
    //              = 0, S-mode memory accesses to pages that are accessible by U-mode
    //              = 1, these accesses are permitted
    // [17]      MPRV, Modify PRiVilege for load/store operation (for user mode)
    //              = 0, follow current privilege
    //              = 1, load/store are translated and protected
    // [16:15]   XS, encode user extension state
    // [14:13]   FS, encode Floating-point extension State
    // [12:11]   MPP: Machine-mode, previous privilege mode
    // [10:9]    VS, encode Vector extension State
    // [8]       SPP Supervisor mode
    // [7]       MPIE: Machine-mode interrupt enable (prior to the trap)
    // [6]       UBE: User Byte Endianess. Always little-endian so 0
    // [5]       SPIE Supervisor mode Interrupt Enable (Prior to the trap)
    // [4]       (WPRI)
    // [3]       MIE: Machine-mode Interrupt Enable
    // [2]       (WPRI)
    // [1]       SIE Supervisor mode Interrupt Enable
    // [0]       (WPRI)
    //
    // mstatush is not inmplemented so always 0, making the core always
    // in little-endian mode only
    //
    //////////////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mstatus <= {XLEN{1'b0}};
        end else if (srst) begin
            mstatus <= {XLEN{1'b0}};
        end else if (ctrl_mstatus_wr) begin
            mstatus <= get_mstatus(ctrl_mstatus);
        end else if (csr_wren && csr==MSTATUS) begin
            mstatus <= get_mstatus(newval);
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MIE - 0x304
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mie <= {XLEN{1'b0}};
        end else if (srst) begin
            mie <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr==MIE) begin
                    mie <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MTVEC - 0x305
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mtvec <= {XLEN{1'b0}};
        end else if (srst) begin
            mtvec <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr==MTVEC) begin
                    mtvec <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MSCRATCH - 0x340
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mscratch <= {XLEN{1'b0}};
        end else if (srst) begin
            mscratch <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr==MSCRATCH) begin
                    mscratch <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MEPC, only support IALIGN=32 - 0x341
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mepc <= {XLEN{1'b0}};
        end else if (srst) begin
            mepc <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mepc_wr) begin
                mepc <= {ctrl_mepc[XLEN-1:2], 2'b0};
            end else if (csr_wren) begin
                if (csr==MEPC) begin
                    mepc <= {newval[XLEN-1:2], 2'b0};
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MCAUSE - 0x342
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mcause <= {XLEN{1'b0}};
        end else if (srst) begin
            mcause <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mcause_wr) begin
                mcause <= ctrl_mcause;
            end else if (csr_wren) begin
                if (csr==MCAUSE) begin
                    mcause <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MTVAL - 0x343
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mtval <= {XLEN{1'b0}};
        end else if (srst) begin
            mtval <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mtval_wr) begin
                mtval <= ctrl_mtval;
            end else if (csr_wren) begin
                if (csr==MTVAL) begin
                    mtval <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MIP - 0x344
    // TODO: Study race condition when CSR is written and interrupt arrives
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mip <= {XLEN{1'b0}};
        end else if (srst) begin
            mip <= {XLEN{1'b0}};
        end else begin
            if (ext_irq_sync || timer_irq_sync || sw_irq_sync || ctrl_clr_meip) begin
                // external interrupt enable && external interrupt pin asserted
                if ( ext_irq_sync) begin
                    mip[11] <= 1'b1;
                end else if (ctrl_clr_meip) begin
                    mip[11] <= 1'b0;
                end
                // software interrupt enable && software interrupt pin asserted
                if (mie[3] && sw_irq_sync) begin
                    mip[3] <= 1'b1;
                end else begin
                    mip[3] <= 1'b0;
                end
                // timer interrupt enable && timer interrupt pin asserted
                if (mie[7] && timer_irq_sync) begin
                    mip[7] <= 1'b1;
                end else begin
                    mip[7] <= 1'b0;
                end
            end else if (csr_wren) begin
                if (csr==MIP) begin
                    mip <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // MCOUNTEREN - 0x306
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mcounteren <= {XLEN{1'b0}};
        end else if (srst) begin
            mcounteren <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr==MCOUNTEREN) begin
                    mcounteren <= newval;
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // PMPCFG0/3 - 0x3A0-0x3A3
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            pmpcfg0 <= PMPCFG0_INIT;
            pmpcfg1 <= PMPCFG1_INIT;
            pmpcfg2 <= PMPCFG2_INIT;
            pmpcfg3 <= PMPCFG3_INIT;
        end else if (srst) begin
            pmpcfg0 <= PMPCFG0_INIT;
            pmpcfg1 <= PMPCFG1_INIT;
            pmpcfg2 <= PMPCFG2_INIT;
            pmpcfg3 <= PMPCFG3_INIT;
        end else if (MPU_SUPPORT > 1) begin
            if (csr_wren) begin
                if (csr==PMPCFG0 && NB_PMP_REGION>=1) begin
                    if (!pmpcfg0[0*8+7]) pmpcfg0[0+:8]  <= newval[0+:8];
                    if (!pmpcfg0[1*8+7]) pmpcfg0[8+:8]  <= newval[8+:8];
                    if (!pmpcfg0[2*8+7]) pmpcfg0[16+:8] <= newval[16+:8];
                    if (!pmpcfg0[3*8+7]) pmpcfg0[24+:8] <= newval[24+:8];
                end
                if (csr==PMPCFG1 && NB_PMP_REGION>=5) begin
                    if (!pmpcfg1[0*8+7]) pmpcfg1[0+:8]  <= newval[0+:8];
                    if (!pmpcfg1[1*8+7]) pmpcfg1[8+:8]  <= newval[8+:8];
                    if (!pmpcfg1[2*8+7]) pmpcfg1[16+:8] <= newval[16+:8];
                    if (!pmpcfg1[3*8+7]) pmpcfg1[24+:8] <= newval[24+:8];
                end
                if (csr==PMPCFG2 && NB_PMP_REGION>=9) begin
                    if (!pmpcfg2[0*8+7]) pmpcfg2[0+:8]  <= newval[0+:8];
                    if (!pmpcfg2[1*8+7]) pmpcfg2[8+:8]  <= newval[8+:8];
                    if (!pmpcfg2[2*8+7]) pmpcfg2[16+:8] <= newval[16+:8];
                    if (!pmpcfg2[3*8+7]) pmpcfg2[24+:8] <= newval[24+:8];
                end
                if (csr==PMPCFG3 && NB_PMP_REGION>=13) begin
                    if (!pmpcfg3[0*8+7]) pmpcfg3[0+:8]  <= newval[0+:8];
                    if (!pmpcfg3[1*8+7]) pmpcfg3[8+:8]  <= newval[8+:8];
                    if (!pmpcfg3[2*8+7]) pmpcfg3[16+:8] <= newval[16+:8];
                    if (!pmpcfg3[3*8+7]) pmpcfg3[24+:8] <= newval[24+:8];
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // PMPADDR0/15 - 0x3B0-0x3BF
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            pmpaddr0  <= PMPADDR0_INIT;
            pmpaddr1  <= PMPADDR1_INIT;
            pmpaddr2  <= PMPADDR2_INIT;
            pmpaddr3  <= PMPADDR3_INIT;
            pmpaddr4  <= PMPADDR4_INIT;
            pmpaddr5  <= PMPADDR5_INIT;
            pmpaddr6  <= PMPADDR6_INIT;
            pmpaddr7  <= PMPADDR7_INIT;
            pmpaddr8  <= PMPADDR8_INIT;
            pmpaddr9  <= PMPADDR9_INIT;
            pmpaddr10 <= PMPADDR10_INIT;
            pmpaddr11 <= PMPADDR11_INIT;
            pmpaddr12 <= PMPADDR12_INIT;
            pmpaddr13 <= PMPADDR13_INIT;
            pmpaddr14 <= PMPADDR14_INIT;
            pmpaddr15 <= PMPADDR15_INIT;
        end else if (srst) begin
            pmpaddr0  <= PMPADDR0_INIT;
            pmpaddr1  <= PMPADDR1_INIT;
            pmpaddr2  <= PMPADDR2_INIT;
            pmpaddr3  <= PMPADDR3_INIT;
            pmpaddr4  <= PMPADDR4_INIT;
            pmpaddr5  <= PMPADDR5_INIT;
            pmpaddr6  <= PMPADDR6_INIT;
            pmpaddr7  <= PMPADDR7_INIT;
            pmpaddr8  <= PMPADDR8_INIT;
            pmpaddr9  <= PMPADDR9_INIT;
            pmpaddr10 <= PMPADDR10_INIT;
            pmpaddr11 <= PMPADDR11_INIT;
            pmpaddr12 <= PMPADDR12_INIT;
            pmpaddr13 <= PMPADDR13_INIT;
            pmpaddr14 <= PMPADDR14_INIT;
            pmpaddr15 <= PMPADDR15_INIT;
        end else if (MPU_SUPPORT > 1) begin
            if (csr_wren) begin
                if (csr==PMPADDR0  && !pmpcfg0[0*8+7] && NB_PMP_REGION > 0 ) pmpaddr0  <= newval;
                if (csr==PMPADDR1  && !pmpcfg0[1*8+7] && NB_PMP_REGION > 1 ) pmpaddr1  <= newval;
                if (csr==PMPADDR2  && !pmpcfg0[2*8+7] && NB_PMP_REGION > 2 ) pmpaddr2  <= newval;
                if (csr==PMPADDR3  && !pmpcfg0[3*8+7] && NB_PMP_REGION > 3 ) pmpaddr3  <= newval;
                if (csr==PMPADDR4  && !pmpcfg1[0*8+7] && NB_PMP_REGION > 4 ) pmpaddr4  <= newval;
                if (csr==PMPADDR5  && !pmpcfg1[1*8+7] && NB_PMP_REGION > 5 ) pmpaddr5  <= newval;
                if (csr==PMPADDR6  && !pmpcfg1[2*8+7] && NB_PMP_REGION > 6 ) pmpaddr6  <= newval;
                if (csr==PMPADDR7  && !pmpcfg1[3*8+7] && NB_PMP_REGION > 7 ) pmpaddr7  <= newval;
                if (csr==PMPADDR8  && !pmpcfg2[0*8+7] && NB_PMP_REGION > 8 ) pmpaddr8  <= newval;
                if (csr==PMPADDR9  && !pmpcfg2[1*8+7] && NB_PMP_REGION > 9 ) pmpaddr9  <= newval;
                if (csr==PMPADDR10 && !pmpcfg2[2*8+7] && NB_PMP_REGION > 10) pmpaddr10 <= newval;
                if (csr==PMPADDR11 && !pmpcfg2[3*8+7] && NB_PMP_REGION > 11) pmpaddr11 <= newval;
                if (csr==PMPADDR12 && !pmpcfg3[0*8+7] && NB_PMP_REGION > 12) pmpaddr12 <= newval;
                if (csr==PMPADDR13 && !pmpcfg3[1*8+7] && NB_PMP_REGION > 13) pmpaddr13 <= newval;
                if (csr==PMPADDR14 && !pmpcfg3[2*8+7] && NB_PMP_REGION > 14) pmpaddr14 <= newval;
                if (csr==PMPADDR15 && !pmpcfg3[3*8+7] && NB_PMP_REGION > 15) pmpaddr15 <= newval;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////////
    // Counters and timers
    //////////////////////////////////////////////////////////////////////////

    // TODO: Check and rework these counters for multi hart implementations.
    // This description is pretty naive and would be greatly enhanced. From
    // the specification:
    //  RDCYCLE is intended to return the number of cycles executed by the
    //  processor core, not the hart

    // Number of active cycles since moved out of reset
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rdtime <= {64{1'b0}};
        end else if (srst) begin
            rdtime <= {64{1'b0}};
        end else begin
            rdtime <= rdtime + 1;
        end
    end

    // Same than rdtime, should be implemented for power aware core
    assign rdcycle = rdtime;

    assign rdinstret = ctrl_rdinstret;

    //////////////////////////////////////////////////////////////////////////
    // Custom counters to track internal bus performance
    //////////////////////////////////////////////////////////////////////////

    assign instreq_perf_active = perfs[0*32+:32];
    assign instreq_perf_sleep  = perfs[1*32+:32];
    assign instreq_perf_stall  = perfs[2*32+:32];
    assign instcpl_perf_active = perfs[3*32+:32];
    assign instcpl_perf_sleep  = perfs[4*32+:32];
    assign instcpl_perf_stall  = perfs[5*32+:32];
    assign proc_perf_active    = perfs[6*32+:32];
    assign proc_perf_sleep     = perfs[7*32+:32];
    assign proc_perf_stall     = perfs[8*32+:32];


    //////////////////////////////////////////////////////////////////////////
    // CSR Shared bus, for registers used across the processor
    //////////////////////////////////////////////////////////////////////////

    assign csr_sb[`CSR_SB_MTVEC+:XLEN] = mtvec;
    assign csr_sb[`CSR_SB_MEPC+:XLEN] = mepc;
    assign csr_sb[`CSR_SB_MSTATUS+:XLEN] = mstatus;
    assign csr_sb[`CSR_SB_MCOUNTEREN+:XLEN] = mcounteren;

    assign csr_sb[`CSR_SB_MIE] = mstatus[3];
    assign csr_sb[`CSR_SB_MEIP] = mip[11];
    assign csr_sb[`CSR_SB_MTIP] = mip[7];
    assign csr_sb[`CSR_SB_MSIP] = mip[3];
    assign csr_sb[`CSR_SB_MEIE] = mie[11];
    assign csr_sb[`CSR_SB_MTIE] = mie[7];
    assign csr_sb[`CSR_SB_MSIE] = mie[3];

    assign csr_sb[`CSR_SB_PMPCFG0+:XLEN] = pmpcfg0;
    assign csr_sb[`CSR_SB_PMPCFG1+:XLEN] = pmpcfg1;
    assign csr_sb[`CSR_SB_PMPCFG2+:XLEN] = pmpcfg2;
    assign csr_sb[`CSR_SB_PMPCFG3+:XLEN] = pmpcfg3;

    assign csr_sb[`CSR_SB_PMPADDR0 +:XLEN] = pmpaddr0;
    assign csr_sb[`CSR_SB_PMPADDR1 +:XLEN] = pmpaddr1;
    assign csr_sb[`CSR_SB_PMPADDR2 +:XLEN] = pmpaddr2;
    assign csr_sb[`CSR_SB_PMPADDR3 +:XLEN] = pmpaddr3;
    assign csr_sb[`CSR_SB_PMPADDR4 +:XLEN] = pmpaddr4;
    assign csr_sb[`CSR_SB_PMPADDR5 +:XLEN] = pmpaddr5;
    assign csr_sb[`CSR_SB_PMPADDR6 +:XLEN] = pmpaddr6;
    assign csr_sb[`CSR_SB_PMPADDR7 +:XLEN] = pmpaddr7;
    assign csr_sb[`CSR_SB_PMPADDR8 +:XLEN] = pmpaddr8;
    assign csr_sb[`CSR_SB_PMPADDR9 +:XLEN] = pmpaddr9;
    assign csr_sb[`CSR_SB_PMPADDR10+:XLEN] = pmpaddr10;
    assign csr_sb[`CSR_SB_PMPADDR11+:XLEN] = pmpaddr11;
    assign csr_sb[`CSR_SB_PMPADDR12+:XLEN] = pmpaddr12;
    assign csr_sb[`CSR_SB_PMPADDR13+:XLEN] = pmpaddr13;
    assign csr_sb[`CSR_SB_PMPADDR14+:XLEN] = pmpaddr14;
    assign csr_sb[`CSR_SB_PMPADDR15+:XLEN] = pmpaddr15;

    assign {ctrl_rdinstret, ctrl_clr_meip, 
            ctrl_mtval_wr, ctrl_mtval,
            ctrl_mcause_wr, ctrl_mcause,
            ctrl_mstatus_wr, ctrl_mstatus,
            ctrl_mepc_wr, ctrl_mepc} = ctrl_sb;
endmodule

`resetall
