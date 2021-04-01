// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_control

    #(
        parameter             ADDRW     = 16,
        parameter [ADDRW-1:0] BOOT_ADDR = {ADDRW{1'b0}},
        parameter             XLEN      = 32
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // instruction memory interface
        output logic                      inst_en,
        output logic [ADDRW         -1:0] inst_addr,
        input  wire  [XLEN          -1:0] inst_rdata,
        input  wire                       inst_ready,
        // interface to activate~the ALU processing
        output logic                      alu_en,
        input  wire                       alu_ready,
        output logic [`ALU_INSTBUS_W-1:0] alu_instbus,
        // register source 1 query interface
        output logic [5             -1:0] regs_rs1_addr,
        input  wire  [XLEN          -1:0] regs_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] regs_rs2_addr,
        input  wire  [XLEN          -1:0] regs_rs2_val
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameter and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // decoded instructions signals
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
    logic               jumping;
    logic               branching;
    logic               system;
    logic               processing;
    // flag raised when receiving an unsupported/undefined instruction
    logic               inst_error;

    // control fsm
    typedef enum logic[3:0] {
        BOOT = 0,
        ALU = 1,
        BR_JP = 2,
        SYS = 3,
        TRAP = 4
    } pc_fsm;

    pc_fsm cfsm;

    // program counter, expressed in bytes
    logic [ADDRW+2-1:0] pc;

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

    friscv_rv32i_decoder
    #(
        .XLEN   (XLEN)
    )
    decoder
    (
        .instruction (inst_rdata),
        .opcode      (opcode    ),
        .funct3      (funct3    ),
        .funct7      (funct7    ),
        .rs1         (rs1       ),
        .rs2         (rs2       ),
        .rd          (rd        ),
        .zimm        (zimm      ),
        .imm12       (imm12     ),
        .imm20       (imm20     ),
        .csr         (csr       ),
        .shamt       (shamt     ),
        .jumping     (jumping   ),
        .branching   (branching ),
        .system      (system    ),
        .processing  (processing),
        .inst_error  (inst_error),
        .pred        (pred      ),
        .succ        (succ      )
    );

    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    //
    // FIFO storing incoming instructions processed by ALU
    //
    ///////////////////////////////////////////////////////////////////////////

    assign alu_inst_wr = inst_ready & processing & ~alu_inst_full;

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

    assign inst_en = (cfsm == ALU && ((processing && ~alu_inst_full) ||
                                      (~processing && ~inst_error))) ? 1'b1:
                                                                       1'b0;

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            pc <= {(ADDRW+2){1'b0}};
        end else if (srst == 1'b1) begin
            cfsm <= BOOT;
            pc <= {(ADDRW+2){1'b0}};
        end else begin

            case (cfsm)

                // start to boot the RAM after reset
                default: begin
                    pc <= {BOOT_ADDR,2'b0};
                    cfsm <= ALU;
                end

                // Run the core
                ALU: begin
                    if (inst_error) begin
                        cfsm <= TRAP;
                    end else if (inst_en && inst_ready) begin
                        if (processing && ~alu_inst_full) begin
                            // increment counter by 4 because we index bytes
                            pc <= pc + {{(ADDRW+2-3){1'b0}},3'b100};
                        end
                    end
                end

                // TRAP reached when:
                // - received an undefined/unsupported instruction
                TRAP: begin
                    // $error("ERROR: Received an unsupported/unspecified instruction");
                    if (`HALT_ON_ERROR) begin
                         $stop();
                    end
                end

            endcase

        end
    end

    // select only MSB because RAM is addressed by word while program counter
    // is byte oriented
    assign inst_addr = pc[2+:ADDRW];

    // register source 1 & 2 read
    assign regs_rs1_addr = rs1;
    assign regs_rs2_addr = rs2;

endmodule

`resetall
