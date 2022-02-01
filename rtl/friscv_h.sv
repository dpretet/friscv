// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef FRISCV_H
`define FRISCV_H

//////////////////////////////////////////////////////////////////
// Opcodes' define
//////////////////////////////////////////////////////////////////

`define LUI     7'b0110111
`define AUIPC   7'b0010111
`define JAL     7'b1101111
`define JALR    7'b1100111
`define BRANCH  7'b1100011
`define LOAD    7'b0000011
`define STORE   7'b0100011
`define I_ARITH 7'b0010011
`define R_ARITH 7'b0110011
`define SYS     7'b1110011
`define FENCEX  7'b0001111
`define MULDIV  7'b0110011
`define MULDIVW 7'b0111011


//////////////////////////////////////////////////////////////////
// funct3 opcodes for instruction decoding
//////////////////////////////////////////////////////////////////

`define BEQ     3'b000
`define BNE     3'b001
`define BLT     3'b100
`define BGE     3'b101
`define BLTU    3'b110
`define BGEU    3'b111

`define LB      3'b000
`define LH      3'b001
`define LW      3'b010
`define LBU     3'b100
`define LHU     3'b101

`define SB      3'b000
`define SH      3'b001
`define SW      3'b010

`define ADDI    3'b000
`define SLTI    3'b010
`define SLTIU   3'b011
`define XORI    3'b100
`define ORI     3'b110
`define ANDI    3'b111

`define SLLI    3'b001
`define SRLI    3'b101
`define SRAI    3'b101

`define ADD     3'b000
`define SUB     3'b000
`define SLL     3'b001
`define SLT     3'b010
`define SLTU    3'b011
`define XOR     3'b100
`define SRL     3'b101
`define SRA     3'b101
`define OR      3'b110
`define AND     3'b111

`define FENCE   3'b000
`define FENCEI  3'b001

`define IS_FENCE  0
`define IS_FENCEI 1

`define CSRRW   3'b001
`define CSRRS   3'b010
`define CSRRC   3'b011
`define CSRRWI  3'b101
`define CSRRSI  3'b110
`define CSRRCI  3'b111

`define MUL     3'b000
`define MULH    3'b001
`define MULHSU  3'b010
`define MULHU   3'b011
`define DIV     3'b100
`define DIVU    3'b101
`define REM     3'b110
`define REMU    3'b111

`define MULW    3'b000
`define DIVW    3'b100
`define DIVUW   3'b101
`define REMW    3'b110
`define REMUW   3'b111

///////////////////////////////////////////////////////////////////
// env signal driven by decoder to indicate environment instruction
///////////////////////////////////////////////////////////////////

`define ECALL   3'b001
`define EBREAK  3'b010
`define CSRX    3'b100

`define IS_ECALL  0
`define IS_EBREAK 1
`define IS_CSR    2
`define IS_MRET   3
`define IS_SRET   4
`define IS_WFI    5

//////////////////////////////////////////////////////////////////
// Instruction bus feeding ALUs
//////////////////////////////////////////////////////////////////

// instruction bus fields's width
`define OPCODE_W    7
`define FUNCT3_W    3
`define FUNCT7_W    7
`define RS1_W       5
`define RS2_W       5
`define RD_W        5
`define ZIMM_W      5
`define IMM12_W     12
`define IMM20_W     20
`define CSR_W       12
`define SHAMT_W     5
`define PRED_W      4
`define SUCC_W      4

// instruction bus fields's index
`define OPCODE      0
`define FUNCT3      `OPCODE + `OPCODE_W
`define FUNCT7      `FUNCT3 + `FUNCT3_W
`define RS1         `FUNCT7 + `FUNCT7_W
`define RS2         `RS1 +    `RS1_W
`define RD          `RS2 +    `RS2_W
`define ZIMM        `RD +     `RD_W
`define IMM12       `ZIMM +   `ZIMM_W
`define IMM20       `IMM12 +  `IMM12_W
`define CSR         `IMM20 +  `IMM20_W
`define SHAMT       `CSR +    `CSR_W

// total length of ALU instruction bus
`define INST_BUS_W `OPCODE_W + `FUNCT3_W + `FUNCT7_W + `RS1_W + `RS2_W + \
                   `RD_W + `ZIMM_W + `IMM12_W + `IMM20_W + `CSR_W + `SHAMT_W


//////////////////////////////////////////////////////////////////
// CSR Shared Bus Definition
//////////////////////////////////////////////////////////////////

// CSR shared bus placement
`define MTVEC    0
`define MEPC    `MTVEC + `XLEN
`define MSTATUS `MEPC + `XLEN
`define MEIP    `MSTATUS + `XLEN
`define MTIP    `MEIP + 1
`define MSIP    `MTIP + 1

// CSR shared bus width
`define CSR_SB_W `MSIP + 1


//////////////////////////////////////////////////////////////////
// Loggers setup
//////////////////////////////////////////////////////////////////

`ifdef FRISCV_SIM

`include "svlogger.sv"

`ifndef LOGGER
`define LOGGER
    `ifndef ICACHE_VERBOSITY
        `define ICACHE_VERBOSITY `SVL_VERBOSE_WARNING
        `define ICACHE_ROUTE `SVL_ROUTE_ALL
    `endif
    `ifndef CONTROL_VERBOSITY
        `define CONTROL_VERBOSITY `SVL_VERBOSE_DEBUG
        `define CONTROL_ROUTE `SVL_ROUTE_ALL
    `endif
    `ifndef CSR_VERBOSITY
        `define CSR_VERBOSITY `SVL_VERBOSE_DEBUG
        `define CSR_ROUTE `SVL_ROUTE_ALL
    `endif
`endif


//////////////////////////////////////////////////////////////////
// Shared tasks
//////////////////////////////////////////////////////////////////

function automatic string get_inst_desc(
    input string            instruction,
    input string            pc,
    input logic [7    -1:0] opcode,
    input logic [3    -1:0] funct3,
    input logic [7    -1:0] funct7,
    input logic [5    -1:0] rs1,
    input logic [5    -1:0] rs2,
    input logic [5    -1:0] rd,
    input logic [12   -1:0] imm12,
    input logic [20   -1:0] imm20,
    input logic [12   -1:0] csr
);

    string text = "UNKNOWN";
    string temp;

    if (opcode==`LUI) begin
        text = "LUI / U-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Imm20: %x", imm20);
        text = {temp, " / ", text};
    end
    if (opcode==`AUIPC) begin
        text = "AUIPC / U-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Imm20: %x", imm20);
        text = {temp, " / ", text};
    end
    if (opcode==`JALR) begin
        text = "JALR / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`LOAD) begin
        text = "LOAD / I-type";
        $sformat(temp, "rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`I_ARITH) begin
        text = "ARITH / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`FENCEX) begin
        if (funct3==`FENCE) text = "FENCE / I-type";
        else text = "FENCE.i / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`SYS) begin
        if (funct3==3'b000 && funct7==7'b0000000) text = "ECALL - I-type";
        else if (funct3==3'b000 && funct7==7'b0000001) text = "EBREAK - I-type";
        else if (funct3==3'b000 && csr==12'h105) text = "WFI - I-type";
        else if (funct3==3'b000 && csr==12'h102) text = "SRET - I-type";
        else if (funct3==3'b000 && csr==12'h302) text = "MRET - I-type";
        else text = "CSR / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Csr: %x", csr);
        text = {temp, " / ", text};
    end
    if (opcode==`JAL) begin
        text = "JAL / J-type";
        $sformat(temp, "rd: %x ", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Imm20: %x", imm20);
        text = {temp, " / ", text};
    end
    if (opcode==`BRANCH) begin
        text = "BRANCH / B-type";
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Rs2: %x", rs2);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`STORE) begin
        text = "STORE / S-type";
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Rs2: %x", rs2);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`R_ARITH) begin
        if (funct7==7'b0000001) text = "MULDIV / R-type";
        else text = "ARITH / R-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Rs2: %x", rs2);
        text = {temp, " / ", text};
        $sformat(temp, "Funct7: %x", funct7);
        text = {temp, " / ", text};
    end

    text = {"PC=", pc, " - ", instruction, " / ", text};
    get_inst_desc = text;

endfunction

`endif

`endif // FRISCV_H
