// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_csr

    #(
        // Architecture selection:
        // 32 or 64 bits support
        parameter XLEN = 32,
        // Floating-point extension support
        parameter F_EXTENSION = 0,
        // Multiply/Divide extension support
        parameter M_EXTENSION = 0,
        // Reduced RV32 arch
        parameter RV32E = 0,
        // MHART_ID CSR
        parameter MHART_ID = 0
    )(
        // Clock/reset interface
        input  logic                   aclk,
        input  logic                   aresetn,
        input  logic                   srst,
        // Interrupts
        input  logic                   ext_irq,
        input  logic                   sw_irq,
        input  logic                   timer_irq,
        // Instruction bus
        input  logic                   valid,
        output logic                   ready,
        input  logic [`INST_BUS_W-1:0] instbus,
        // Register source 1 query interface
        output logic [5          -1:0] rs1_addr,
        input  logic [XLEN       -1:0] rs1_val,
        output logic                   rd_wr_en,
        output logic [5          -1:0] rd_wr_addr,
        output logic [XLEN       -1:0] rd_wr_val,
        // External source of CSRs
        input  logic                   ctrl_mepc_wr,
        input  logic [XLEN       -1:0] ctrl_mepc,
        input  logic                   ctrl_mstatus_wr,
        input  logic [XLEN       -1:0] ctrl_mstatus,
        input  logic                   ctrl_mcause_wr,
        input  logic [XLEN       -1:0] ctrl_mcause,
        input  logic                   ctrl_mtval_wr,
        input  logic [XLEN       -1:0] ctrl_mtval,
        // CSR shared bus
        output logic [`CSR_SB_W  -1:0] csr_sb
    );

    // ------------------------------------------------------------------------
    // TODO: Ensure CSRRW/CSRRWI read doesn't indude side effect on read if
    //       rd=0 as specified in chapter 9 Zicsr
    // TODO: Print CSR implemented at startup
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    // Declarations
    // ------------------------------------------------------------------------

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE
    } fsm;

    fsm cfsm;

    // instructions fields
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`RS1_W      -1:0] rs1;
    logic [`RD_W       -1:0] rd;
    logic [`ZIMM_W     -1:0] zimm;
    logic [`CSR_W      -1:0] csr;

    logic                  csr_wren;
    logic                  csr_rden;
    logic [XLEN      -1:0] oldval;
    logic [XLEN      -1:0] newval;

    logic [`FUNCT3_W -1:0] funct3_r;
    logic [`CSR_W    -1:0] csr_r;
    logic [`ZIMM_W   -1:0] zimm_r;
    logic [5         -1:0] rs1_addr_r;
    logic [XLEN      -1:0] rs1_val_r;

    logic                  ext_irq_sync;
    logic                  timer_irq_sync;
    logic                  sw_irq_sync;

    //////////////////////////////////////////////////////////////////////////
    // Machine-level CSRs:
    //////////////////////////////////////////////////////////////////////////

    // Machine Information Status
    // logic [XLEN-1:0] mvendorid;  // 0xF11    MRO (not implemented)
    // logic [XLEN-1:0] marchid;    // 0xF12    MRO (not implemented)
    // logic [XLEN-1:0] mimpid;     // 0xF13    MRO (not implemented)
    logic [XLEN-1:0] mhartid;       // 0xF14    MRO
    // logic [XLEN-1:0] mconfigptr; // 0xF15    MRO (not implemented)

    // Machine Trap Status
    logic [XLEN-1:0] mstatus;       // 0x300    MRW
    logic [XLEN-1:0] misa;          // 0x301    MRW
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

    // Machine Memory Protection
    // logic [XLEN-1:0] pmpcfg0;       // 0x3A0    MRW (not implemented)
    // logic [XLEN-1:0] pmpcfg1;       // 0x3A1    MRW (not implemented)
    // logic [XLEN-1:0] pmpcfg2;       // 0x3A2    MRW (not implemented)
    // logic [XLEN-1:0] pmpcfg3;       // 0x3A3    MRW (not implemented)
    // logic [XLEN-1:0] pmpaddr0;      // 0x3B0    MRW (not implemented)


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
    // CSR execution machine
    //////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn==1'b0) begin
            rd_wr_en <= 1'b0;
            rd_wr_val <= {XLEN{1'b0}};
            ready <= 1'b0;
            csr_wren <= 1'b0;
            newval <= {XLEN{1'b0}};
            funct3_r <= {`FUNCT3_W{1'b0}};
            csr_r <= {`CSR_W{1'b0}};
            zimm_r <= {`ZIMM_W{1'b0}};
            rs1_addr_r <= 5'b0;
            rs1_val_r <= {XLEN{1'b0}};
            rd_wr_addr <= 5'b0;
            cfsm <= IDLE;
        end else if (srst) begin
            rd_wr_en <= 1'b0;
            rd_wr_val <= {XLEN{1'b0}};
            ready <= 1'b0;
            csr_wren <= 1'b0;
            newval <= {XLEN{1'b0}};
            funct3_r <= {`FUNCT3_W{1'b0}};
            csr_r <= {`CSR_W{1'b0}};
            zimm_r <= {`ZIMM_W{1'b0}};
            rs1_addr_r <= 5'b0;
            rs1_val_r <= {XLEN{1'b0}};
            rd_wr_addr <= 5'b0;
            cfsm <= IDLE;
        end else begin

            // Wait for a new instruction
            case (cfsm)

                default: begin

                    csr_wren <= 1'b0;
                    rd_wr_en <= 1'b0;
                    ready <= 1'b1;

                    if (valid) begin
                        ready <= 1'b0;
                        funct3_r <= funct3;
                        csr_r <= csr;
                        zimm_r <= zimm;
                        rs1_addr_r <= rs1;
                        rs1_val_r <= rs1_val;
                        rd_wr_addr <= rd;
                        cfsm <= COMPUTE;
                    end
                end

                // Compute the new CSR value and drive
                // the ISA register
                COMPUTE: begin

                    cfsm <= IDLE;
                    ready <= 1'b1;

                    // Swap RS1 and CSR
                    if (funct3_r==`CSRRW) begin
                        csr_wren <= 1'b1;
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        newval <= rs1_val_r;

                    // Save CSR in RS1 and apply a set mask with rs1
                    end else if (funct3_r==`CSRRS) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (rs1_addr_r!=5'b0) begin
                            csr_wren <= 1'b1;
                            newval <= oldval | rs1_val_r;
                        end

                    // Save CSR in RS1 then apply a clear mask fwith rs1
                    end else if (funct3_r==`CSRRC) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (rs1_addr_r!=5'b0) begin
                            csr_wren <= 1'b1;
                            newval <= oldval & rs1_val_r;
                        end

                    // Store CSR in RS1 then set CSR to Zimm
                    end else if (funct3_r==`CSRRWI) begin
                        csr_wren <= 1'b1;
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        newval <= {{XLEN-5{1'b0}}, zimm_r};

                    // Save CSR in RS1 and apply a set mask with Zimm
                    end else if (funct3_r==`CSRRSI) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (zimm_r!=5'b0) begin
                            csr_wren <= 1'b1;
                            newval <= oldval | {{(XLEN-`ZIMM_W){1'b0}}, zimm_r};
                        end

                    // Save CSR in RS1 and apply a clear mask with Zimm
                    end else if (funct3_r==`CSRRCI) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (zimm_r!=5'b0) begin
                            csr_wren <= 1'b1;
                            newval <= oldval & {{(XLEN-`ZIMM_W){1'b0}}, zimm_r};
                        end

                    end
                end

            endcase
        end
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
    assign mhartid = MHART_ID;

    ///////////////////////////////////////////////////////////////////////////
    // MISA - 0x301 (RO)
    ///////////////////////////////////////////////////////////////////////////

    // Supported extensions
    assign misa[0]  = 1'b0;                         // A Atomic extension
    assign misa[1]  = 1'b0;                         // B Tentatively reserved for Bit-Manipulation extension
    assign misa[2]  = 1'b0;                         // C Compressed extension
    assign misa[3]  = 1'b0;                         // D Double-precision floating-point extension
    assign misa[4]  = (RV32E) ? 1'b1 : 1'b0;        // E RV32E base ISA
    assign misa[5]  = (F_EXTENSION) ? 1'b1 : 1'b0;  // F Single-precision floating-point extension
    assign misa[6]  = 1'b0;                         // G Additional standard extensions present
    assign misa[7]  = 1'b0;                         // H Hypervisor extension
    assign misa[8]  = (~RV32E) ? 1'b1 : 1'b0;       // I RV32I/64I/128I base ISA
    assign misa[9]  = 1'b0;                         // J Tentatively reserved for Dynamically Translated Languages extension
    assign misa[10] = 1'b0;                         // K Reserved
    assign misa[11] = 1'b0;                         // L Tentatively reserved for Decimal Floating-Point extension
    assign misa[12] = (M_EXTENSION) ? 1'b1 : 1'b0;  // M Integer Multiply/Divide extension
    assign misa[13] = 1'b0;                         // N User-level interrupts supported
    assign misa[14] = 1'b0;                         // O Reserved
    assign misa[15] = 1'b0;                         // P Tentatively reserved for Packed-SIMD extension
    assign misa[16] = 1'b0;                         // Q Quad-precision floating-point extension
    assign misa[17] = 1'b0;                         // R Reserved
    assign misa[18] = 1'b0;                         // S Supervisor mode implemented
    assign misa[19] = 1'b0;                         // T Tentatively reserved for Transactional Memory extension
    assign misa[20] = 1'b0;                         // U User mode implemented
    assign misa[21] = 1'b0;                         // V Tentatively reserved for Vector extension
    assign misa[22] = 1'b0;                         // W Reserved
    assign misa[23] = 1'b0;                         // X Non-standard extensions present
    assign misa[24] = 1'b0;                         // Y Reserved
    assign misa[25] = 1'b0;                         // Z Reserved

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

    ///////////////////////////////////////////////////////////////////////////
    // MSTATUS - 0x300
    // 
    // 31:      SD related to XS FS, 0 for the moment
    // 30:23:   (WPRI)
    // 22:      TSR Supervisor mode, 0 N/A
    // 21:      TW Timeout Wait, 0 N/A
    // 20:      TVM Virtualization, 0 N/A
    // 19:      MXR Virtual Mem, 0 N/A
    // 18:      SUM Virtual Mem, 0 N/A
    // 17:      MPRV Virtual Mem, 0 N/A
    // 16:15:   XS FP, 0 N/A
    // 14:13:   FS FP, 0 N/A
    // 12:11:   MPP: Machine-mode, previous priviledge mode, 0 N/A
    // 10:9:    (WPRI)
    // 8:       SPP Supervisor mode, 0 N/A
    // 7:       MPIE: Machine-mode, Interrupt enable (prior to the trap)
    // 6:       (WPRI)
    // 5:       SPIE Supervisor mode, 0 N/A
    // 4:       UPIE User mode, 0 N/A
    // 3:       MIE: Machine-mode, Interrupt enable
    // 2:       (WPRI)
    // 1:       SIE Supervisor mode, 0 N/A
    // 0:       UIE User mode, 0 N/A
    //
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mstatus <= {XLEN{1'b0}};
        end else if (srst) begin
            mstatus <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mstatus_wr) begin
                mstatus <= {ctrl_mstatus[31], 8'b0, ctrl_mstatus[22:11], 2'b0,
                            ctrl_mstatus[8:7], 1'b0, ctrl_mstatus[5:3], 1'b0,
                            ctrl_mstatus[1:0]};
            end else if (csr_wren) begin
                if (csr_r==12'h300) begin
                    mstatus <= {newval[31], 8'b0, newval[22:11], 2'b0,
                                newval[8:7], 1'b0, newval[5:3], 1'b0,
                                newval[1:0]};
                end
            end
        end
    end 

    ///////////////////////////////////////////////////////////////////////////
    // MIE - 0x304
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mie <= {XLEN{1'b0}};
        end else if (srst) begin
            mie <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr_r==12'h304) begin
                    mie <= newval;
                end
            end
        end
    end 

    ///////////////////////////////////////////////////////////////////////////
    // MTVEC - 0x305
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mtvec <= {XLEN{1'b0}};
        end else if (srst) begin
            mtvec <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr_r==12'h305) begin
                    mtvec <= newval;
                end
            end
        end
    end 

    ///////////////////////////////////////////////////////////////////////////
    // MSCRATCH - 0x340
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mscratch <= {XLEN{1'b0}};
        end else if (srst) begin
            mscratch <= {XLEN{1'b0}};
        end else begin
            if (csr_wren) begin
                if (csr_r==12'h340) begin
                    mscratch <= newval;
                end
            end
        end
    end 

    ///////////////////////////////////////////////////////////////////////////
    // MEPC, only support IALIGN=32 - 0x341
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mepc <= {XLEN{1'b0}};
        end else if (srst) begin
            mepc <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mepc_wr) begin
                mepc <= {ctrl_mepc[XLEN-1:2], 2'b0}; 
            end else if (csr_wren) begin
                if (csr_r==12'h341) begin
                    mepc <= {newval[XLEN-1:2], 2'b0};
                end
            end
        end
    end 

    ///////////////////////////////////////////////////////////////////////////
    // MCAUSE - 0x342
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mcause <= {XLEN{1'b0}};
        end else if (srst) begin
            mcause <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mcause_wr) begin
                mcause <= ctrl_mcause;
            end else if (csr_wren) begin
                if (csr_r==12'h342) begin
                    mcause <= newval;
                end
            end
        end
    end 

    ///////////////////////////////////////////////////////////////////////////
    // MTVAL - 0x343
    ///////////////////////////////////////////////////////////////////////////
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            mtval <= {XLEN{1'b0}};
        end else if (srst) begin
            mtval <= {XLEN{1'b0}};
        end else begin
            if (ctrl_mtval_wr) begin
                mtval <= ctrl_mtval;
            end else if (csr_wren) begin
                if (csr_r==12'h343) begin
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
        if (~aresetn) begin
            mip <= {XLEN{1'b0}};
        end else if (srst) begin
            mip <= {XLEN{1'b0}};
        end else begin
            if (ext_irq_sync || timer_irq_sync || sw_irq_sync) begin    
                // external interrupt enable && external interrupt pin asserted
                if (mie[11] && ext_irq_sync) begin      
                    mip[11] <= 1'b1;
                end
                // software interrupt enable && software interrupt pin asserted
                if (mie[3] && sw_irq_sync) begin      
                    mip[3] <= 1'b1;
                end
                // timer interrupt enable && timer interrupt pin asserted
                if (mie[7] && timer_irq_sync) begin      
                    mip[7] <= 1'b1;
                end
            end else if (csr_wren) begin
                if (csr_r==12'h344) begin
                    mip <= newval;
                end
            end
        end
    end 

    //////////////////////////////////////////////////////////////////////////
    // Read circuit
    //////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            oldval <= {XLEN{1'b0}};
        end else if (srst) begin
            oldval <= {XLEN{1'b0}};
        end else begin
            if (cfsm==IDLE && valid) begin
                if (csr==12'h300) begin
                    oldval <= mstatus;
                end else if (csr==12'h301) begin
                    oldval <= misa;
                end else if (csr==12'h304) begin
                    oldval <= mie;
                end else if (csr==12'h305) begin
                    oldval <= mtvec;
                end else if (csr==12'h340) begin
                    oldval <= mscratch;
                end else if (csr==12'h341) begin
                    oldval <= mepc;
                end else if (csr==12'h342) begin
                    oldval <= mcause;
                end else if (csr==12'h343) begin
                    oldval <= mtval;
                end else if (csr==12'h344) begin
                    oldval <= mip;
                end else if (csr==12'hF14) begin
                    oldval <= mhartid;
                end else begin
                    oldval <= {XLEN{1'b0}};
                end
            end
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // CSR Shared bus, for registers used across the processor
    //////////////////////////////////////////////////////////////////////////

    assign csr_sb[`MTVEC+:XLEN] = mtvec;
    assign csr_sb[`MEPC+:XLEN] = mepc;
    assign csr_sb[`MSTATUS+:XLEN] = mstatus;

    assign csr_sb[`MEIP] = mip[11];
    assign csr_sb[`MTIP] = mip[7];
    assign csr_sb[`MSIP] = mip[3];

endmodule

`resetall
