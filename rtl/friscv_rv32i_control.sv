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
        // interface to activate~the ALU processing
        output logic                      alu_en,
        input  logic                      alu_ready,
        output logic [`ALU_INSTBUS_W-1:0] alu_instbus,
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

    // decoded instructions
    logic [7    -1:0] opcode;
    logic [3    -1:0] funct3;
    logic [7    -1:0] funct7;
    logic [5    -1:0] rs1;
    logic [5    -1:0] rs2;
    logic [5    -1:0] rd;
    logic [5    -1:0] zimm;
    logic [12   -1:0] imm12;
    logic [20   -1:0] imm20;
    logic [12   -1:0] csr;
    logic [5    -1:0] shamt;
    logic [4    -1:0] pred;
    logic [4    -1:0] succ;

    // signals driving the FIFO storing ALU's instructions
    logic [`ALU_INSTBUS_W-1:0] alu_instbus_in;
    logic [`ALU_INSTBUS_W-1:0] alu_instbus_out;
    logic                      alu_inst_wr;
    logic                      alu_inst_rd;
    logic                      alu_inst_full;
    logic                      alu_inst_empty;

    // flags of the instruction decoder to drive the control unit
    logic auipc;
    logic jal;
    logic jalr;
    logic branching;
    logic system;
    logic processing;
    // flag raised when receiving an unsupported/undefined instruction
    logic inst_error;

    // control fsm
    typedef enum logic[3:0] {
        BOOT = 0,
        RUN = 1,
        BR_JP = 2,
        SYS = 3,
        TRAP = 4
    } pc_fsm;

    pc_fsm cfsm;

    // program counter, expressed in bytes
    localparam              PC_W = 32;
    logic        [PC_W-1:0] pc_plus4;
    logic signed [PC_W-1:0] pc_auipc;
    logic signed [PC_W-1:0] pc_jal;
    logic signed [PC_W-1:0] pc_jalr;
    logic signed [PC_W-1:0] pc_branching;
    logic        [PC_W-1:0] pc;
    logic        [PC_W-1:0] pc_reg;
    // extra decoding used during branching
    logic                   beq;
    logic                   bne;
    logic                   blt;
    logic                   bge;
    logic                   bltu;
    logic                   bgeu;
    logic                   goto_branch;
    // circuit stoing an instruction which can't be process now
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
    // Decodes instruction which will trigger the control and data flows.
    //
    // The instruction set is divided in 4 parts:
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
    // Processing is handled by ALU, responsible of data memory access,
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
    // FIFO storing incoming instructions processed by ALU
    //
    ///////////////////////////////////////////////////////////////////////////

    assign alu_inst_wr = (inst_ready | load_stored) & processing & ~alu_inst_full;

    assign alu_instbus_in[`OPCODE +: `OPCODE_W] = opcode;
    assign alu_instbus_in[`FUNCT3 +: `FUNCT3_W] = funct3;
    assign alu_instbus_in[`FUNCT7 +: `FUNCT7_W] = funct7;
    assign alu_instbus_in[`RS1    +: `RS1_W   ] = rs1   ;
    assign alu_instbus_in[`RS2    +: `RS2_W   ] = rs2   ;
    assign alu_instbus_in[`RD     +: `RD_W    ] = rd    ;
    assign alu_instbus_in[`ZIMM   +: `ZIMM_W  ] = zimm  ;
    assign alu_instbus_in[`IMM12  +: `IMM12_W ] = imm12 ;
    assign alu_instbus_in[`IMM20  +: `IMM20_W ] = imm20 ;
    assign alu_instbus_in[`CSR    +: `CSR_W   ] = csr   ;
    assign alu_instbus_in[`SHAMT  +: `SHAMT_W ] = shamt ;

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(`ALU_FIFO_DEPTH)),
        .DATA_WIDTH (`ALU_INSTBUS_W         )
    )
    processing_scfifo
    (
        .aclk     (aclk                ),
        .aresetn  (aresetn             ),
        .srst     (srst                ),
        .data_in  (alu_instbus_in      ),
        .push     (alu_inst_wr         ),
        .full     (alu_inst_full       ),
        .data_out (alu_instbus_out     ),
        .pull     (alu_inst_rd         ),
        .empty    (alu_inst_empty      )
    );

    assign alu_en = ~alu_inst_empty;
    assign alu_inst_rd = alu_ready & ~alu_inst_empty;
    assign alu_instbus = alu_instbus_out;

    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control flow FSM
    //
    ///////////////////////////////////////////////////////////////////////////

    // program counter computation based on instructions
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
    assign pc_branching =  $signed(pc_reg) + $signed({18'b0, imm12, 1'b0});

    // program counter switching logic
    assign pc = (auipc)                     ? pc_auipc :
                (jal)                       ? pc_jal : 
                (jalr)                      ? {pc_jalr[31:1],1'b0} :
                (branching && goto_branch)  ? pc_branching :
                (branching && ~goto_branch) ? pc_plus4 :
                (processing)                ? pc_plus4 :
                                              pc_reg;

    // branching flags and its checks
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

    // two flags to stop the process if ALU is struggling to process
    assign cant_branch_now = ((auipc || jal ||  jalr ||  branching) &&
                               ~alu_inst_empty) ? 1'b1 : 
                                                  1'b0;

    assign cant_process_now = (alu_inst_full) ? 1'b1 : 1'b0;

    // The FSM switching the program counter
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            pc_reg <= {(PC_W){1'b0}};
            load_stored <= 1'b0;
            stored_inst <= {XLEN{1'b0}};
        end else if (srst == 1'b1) begin
            cfsm <= BOOT;
            pc_reg <= {(PC_W){1'b0}};
            load_stored <= 1'b0;
            stored_inst <= {XLEN{1'b0}};
        end else begin

            case (cfsm)

                // start to boot the RAM after reset
                default: begin
                    pc_reg <= BOOT_ADDR << 2;
                    cfsm <= RUN;
                end

                // Run the core
                RUN: begin

                    // Completly stop the execution and $stop the simulation
                    if (`HALT_ON_ERROR && inst_error) begin
                        cfsm <= TRAP;
                    end

                    if (inst_ready || load_stored) begin

                        // was waiting for ALU to be ready to branch, now
                        // FIFO's empty and process can restart
                        if (load_stored && ~alu_inst_full) begin
                            load_stored <= 1'b0;
                        // Need to branch but ALU didn't finish yet or need
                        // to process but ALU's FIFO is full
                        end else if (inst_ready && (cant_branch_now ||
                                                    cant_process_now)) begin
                            load_stored <= 1'b1;
                            stored_inst <= inst_rdata;
                        end

                        if (~cant_branch_now && ~cant_process_now) begin
                            pc_reg <= pc;
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

    assign inst_en = (cfsm == RUN && 
                      (~cant_branch_now && ~cant_process_now)) ? 1'b1:
                                                                 1'b0;
    // select only MSB because RAM is addressed by word while program counter
    // is byte-oriented
    assign inst_addr = pc[2+:ADDRW];

    // register source 1 & 2 read
    assign ctrl_rs1_addr = rs1;
    assign ctrl_rs2_addr = rs2;

    // register destination 
    assign ctrl_rd_wr =  ((~cant_branch_now && ~cant_process_now) &&
                          (auipc || jal || jalr)) ? 1'b1 :
                                                    1'b0;
    assign ctrl_rd_addr = rd;
    assign ctrl_rd_val = (jal || jalr) ? pc_plus4 : pc;

endmodule

`resetall
