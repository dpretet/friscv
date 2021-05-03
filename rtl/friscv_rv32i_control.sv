// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_control

    #(
        parameter ADDRW     = 16,
        parameter BOOT_ADDR = 0,
        parameter XLEN      = 32
    )(
        // clock & reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // instruction memory interface
        output logic                      inst_en,
        output logic [ADDRW         -1:0] inst_addr,
        input  logic [XLEN          -1:0] inst_rdata,
        input  logic                      inst_ready,
        // interface to activate the processing
        output logic                      proc_en,
        input  logic                      proc_ready,
        input  logic                      proc_empty,
        input  logic [4             -1:0] proc_fenceinfo,
        output logic [`INST_BUS_W   -1:0] proc_instbus,
        // register source 1 query interface
        output logic [5             -1:0] ctrl_rs1_addr,
        input  logic [XLEN          -1:0] ctrl_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] ctrl_rs2_addr,
        input  logic [XLEN          -1:0] ctrl_rs2_val,
        // register destination for write
        output logic                      ctrl_rd_wr,
        output logic [5             -1:0] ctrl_rd_addr,
        output logic [XLEN          -1:0] ctrl_rd_val
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // Decoded instructions
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`ZIMM_W     -1:0] zimm;
    logic [`IMM12_W    -1:0] imm12;
    logic [`IMM20_W    -1:0] imm20;
    logic [`CSR_W      -1:0] csr;
    logic [`SHAMT_W    -1:0] shamt;
    logic [`PRED_W     -1:0] pred;
    logic [`SUCC_W     -1:0] succ;

    // Flags of the instruction decoder to drive the control unit
    logic lui;
    logic auipc;
    logic jal;
    logic jalr;
    logic branching;
    logic system;
    logic processing;

    // Flag raised when receiving an unsupported/undefined instruction
    logic inst_error;

    // Control fsm
    typedef enum logic[3:0] {
        BOOT = 0,
        RUN = 1,
        BR_JP = 2,
        SYS = 3,
        TRAP = 4
    } pc_fsm;

    pc_fsm cfsm;

    // Program counter, expressed in bytes
    localparam              PC_W = 32;

    logic        [PC_W-1:0] pc_plus4;
    logic signed [PC_W-1:0] pc_auipc;
    logic signed [PC_W-1:0] pc_jal;
    logic signed [PC_W-1:0] pc_jalr;
    logic signed [PC_W-1:0] pc_branching;
    logic        [PC_W-1:0] pc;
    logic        [PC_W-1:0] pc_reg;
    // Extra decoding used during branching
    logic                   beq;
    logic                   bne;
    logic                   blt;
    logic                   bge;
    logic                   bltu;
    logic                   bgeu;
    logic                   goto_branch;
    // Circuit stoing an instruction which can't be process now
    logic                   load_stored;
    logic [XLEN       -1:0] stored_inst;
    logic [XLEN       -1:0] instruction;
    // Two flags used intot the FSM to stall the process and control
    // the instruction storage
    logic                   cant_branch_now;
    logic                   cant_process_now;

    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    //
    // Decode instruction stage:
    //
    // Will trigger the control and data flows. The instruction set is divided
    // in 4 parts:
    //
    //   - jumping
    //   - branching
    //   - system
    //   - processing
    //
    // The first three sets are handlded in control (this module) and dedicated
    // to instruction memory parsing thru the pc (program counter) and software
    // interaction (for instance `ecall` or `break` instructions).
    //
    // Processing is handled by ALU & Memfy, responsible of data memory access,
    // registers management and arithmetic/logic operations.
    //
    ///////////////////////////////////////////////////////////////////////////

    // In case control unit has been stalled, use the last instruction
    // received.
    assign instruction = (load_stored) ? stored_inst : inst_rdata;

    friscv_rv32i_decoder
    #(
        .XLEN   (XLEN)
    )
    decoder
    (
        .instruction (instruction),
        .opcode      (opcode     ),
        .funct3      (funct3     ),
        .funct7      (funct7     ),
        .rs1         (rs1        ),
        .rs2         (rs2        ),
        .rd          (rd         ),
        .zimm        (zimm       ),
        .imm12       (imm12      ),
        .imm20       (imm20      ),
        .csr         (csr        ),
        .shamt       (shamt      ),
        .lui         (lui        ),
        .auipc       (auipc      ),
        .jal         (jal        ),
        .jalr        (jalr       ),
        .branching   (branching  ),
        .system      (system     ),
        .processing  (processing ),
        .inst_error  (inst_error ),
        .pred        (pred       ),
        .succ        (succ       )
    );

    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction sourcing Stage
    //
    ///////////////////////////////////////////////////////////////////////////

    assign proc_en = (inst_ready | load_stored) & processing & (cfsm==RUN);

    assign proc_instbus[`OPCODE +: `OPCODE_W] = opcode;
    assign proc_instbus[`FUNCT3 +: `FUNCT3_W] = funct3;
    assign proc_instbus[`FUNCT7 +: `FUNCT7_W] = funct7;
    assign proc_instbus[`RS1    +: `RS1_W   ] = rs1   ;
    assign proc_instbus[`RS2    +: `RS2_W   ] = rs2   ;
    assign proc_instbus[`RD     +: `RD_W    ] = rd    ;
    assign proc_instbus[`ZIMM   +: `ZIMM_W  ] = zimm  ;
    assign proc_instbus[`IMM12  +: `IMM12_W ] = imm12 ;
    assign proc_instbus[`IMM20  +: `IMM20_W ] = imm20 ;
    assign proc_instbus[`CSR    +: `CSR_W   ] = csr   ;
    assign proc_instbus[`SHAMT  +: `SHAMT_W ] = shamt ;


    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control flow FSM
    //
    ///////////////////////////////////////////////////////////////////////////

    // Program counter computation
    ///////////////////////////////////////////////////////////////////////////

    // increment counter by 4 because we index bytes
    assign pc_plus4 = pc_reg + {{(PC_W-3){1'b0}},3'b100};

    // AUIPC: Add Upper Immediate into Program Counter
    assign pc_auipc = $signed(pc_reg) + $signed({imm20,12'b0});

    // JAL: current program counter + offset
    assign pc_jal = $signed(pc_reg) + $signed({{11{imm20[19]}}, imm20, 1'b0});

    // JALR: program counter equals  rs1 + offset
    assign pc_jalr = $signed(ctrl_rs1_val) + $signed({{20{imm12[11]}}, imm12});

    // For all branching instruction
    assign pc_branching =  $signed(pc_reg) + $signed({{19{imm12[11]}}, imm12, 1'b0});

    // program counter switching logic
    assign pc = (cfsm==BOOT)                ? pc_reg :
                (lui)                       ? pc_plus4 :
                (auipc)                     ? pc_plus4 :
                (jal)                       ? pc_jal :
                (jalr)                      ? {pc_jalr[31:1],1'b0} :
                (branching && goto_branch)  ? pc_branching :
                (branching && ~goto_branch) ? pc_plus4 :
                (processing)                ? pc_plus4 :
                                              pc_reg;

    // Branching flags
    ///////////////////////////////////////////////////////////////////////////

    // BEQ: branch if equal
    assign beq = ($signed(ctrl_rs1_val) == $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BNE: branch if not equal
    assign bne = ($signed(ctrl_rs1_val) != $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BLT: branch if less
    assign blt = ($signed(ctrl_rs1_val) < $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BGE: branch if greater
    assign bge = ($signed(ctrl_rs1_val) >= $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BLTU: branch if less (unsigned)
    assign bltu = (ctrl_rs1_val < ctrl_rs2_val) ? 1'b1 : 1'b0;

    // BGE: branch if greater (unsigned)
    assign bgeu = (ctrl_rs1_val >= ctrl_rs2_val) ? 1'b1 : 1'b0;

    // activate branching only if valid FUNCT3 received
    assign goto_branch = ((funct3 == `BEQ  && beq)  ||
                          (funct3 == `BNE  && bne)  ||
                          (funct3 == `BLT  && blt)  ||
                          (funct3 == `BGE  && bge)  ||
                          (funct3 == `BLTU && bltu) ||
                          (funct3 == `BGEU && bgeu)) ? 1'b1 :
                                                       1'b0;

    // The FSM switching the program counter
    ///////////////////////////////////////////////////////////////////////////

    // Two flags to stop the process if ALU/memfy are struggling to process
    assign cant_branch_now = ((auipc || jal || jalr || branching) &&
                               ~proc_ready) ? 1'b1 :
                                              1'b0;

    assign cant_process_now = (~proc_ready) ? 1'b1 : 1'b0;

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            inst_en <= 1'b0;
            pc_reg <= {(PC_W){1'b0}};
            load_stored <= 1'b0;
            stored_inst <= {XLEN{1'b0}};
        end else if (srst == 1'b1) begin
            cfsm <= BOOT;
            inst_en <= 1'b0;
            pc_reg <= {(PC_W){1'b0}};
            load_stored <= 1'b0;
            stored_inst <= {XLEN{1'b0}};
        end else begin

            case (cfsm)

                // Start to boot the RAM after reset. Take time to load the 
                // RAM and wait for readiness before moving forward to be sure
                // the RAM drives a valid instruction
                default: begin
                    inst_en <= 1'b1;
                    pc_reg <= BOOT_ADDR << 2;

                    if (inst_ready && inst_en) begin
                        cfsm <= RUN;
                    end
                end

                // Run the core operations
                RUN: begin

                    // Completly stop the execution and $stop the simulation
                    if (`HALT_ON_ERROR && inst_error) begin
                        cfsm <= TRAP;
                    end

                    if (inst_ready || load_stored) begin

                        // Wait for ALU/memfy to be ready to branch
                        if (load_stored) begin
                            if (proc_ready) load_stored <= 1'b0;
                        // Need to branch/process but ALU/memfy didn't finish
                        // to execute last instruction
                        end else if (inst_ready && ~lui && 
                                     (cant_branch_now || cant_process_now)) begin
                            load_stored <= 1'b1;
                            stored_inst <= inst_rdata;
                        end

                        if (lui || (~cant_branch_now && ~cant_process_now)) begin
                            pc_reg <= pc;
                            inst_en <= 1'b1;
                        end else begin
                            inst_en <= 1'b0;
                        end

                    end
                end

                // TRAP reached when:
                // - received an undefined/unsupported instruction
                // - TODO: reach if address are not 4 bytes aligned
                TRAP: begin
                    $error("ERROR: Received an unsupported/unspecified instruction");
                    $stop();
                end

            endcase

        end
    end

    // select only MSB because RAM is addressed by word while program counter
    // is byte-oriented
    assign inst_addr = pc[2+:ADDRW];

    // ISA registers write stage
    ///////////////////////////////////////////////////////////////////////////

    // register source 1 & 2 read
    assign ctrl_rs1_addr = rs1;
    assign ctrl_rs2_addr = rs2;

    // register destination
    assign ctrl_rd_wr =  (~cant_branch_now && ~cant_process_now &&
                             (auipc || jal || jalr))    ? 1'b1 :
                         (~cant_process_now && lui)     ? 1'b1 :
                         (auipc)                        ? 1'b1 :
                                                          1'b0 ;
    assign ctrl_rd_addr = rd;

    assign ctrl_rd_val = (jal || jalr) ? pc_plus4 :
                         (lui)         ? {imm20, 12'b0} : 
                         (auipc)       ? pc_auipc :
                                         pc;

endmodule

`resetall
