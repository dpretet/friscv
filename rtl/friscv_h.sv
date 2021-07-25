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
`define ENV     7'b1110011


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

`define CSRRW   3'b001
`define CSRRS   3'b010
`define CSRRC   3'b011
`define CSRRWI  3'b101
`define CSRRSI  3'b110
`define CSRRCI  3'b111

//////////////////////////////////////////////////////////////////
// env signal driven by decoder to indicate environment instruction
//////////////////////////////////////////////////////////////////

`define ECALL   3'b001
`define EBREAK  3'b010
`define CSRX    3'b100


//////////////////////////////////////////////////////////////////
// Instruction bus feeding ALU
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
`define SHAMT_W     6
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
// Control Unit Configuration
//////////////////////////////////////////////////////////////////

// Stop simulation if received an undefined/unsupported instruction
`ifndef TRAP_ERROR
`define TRAP_ERROR 0
`endif

`ifndef LOGGER
`define LOGGER
`define ICACHE_VERBOSITY 1
`define CONTROL_VERBOSITY 1
`endif

`endif
