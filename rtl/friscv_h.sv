// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef FRISCV_H
`define FRISCV_H

// Stop simulation if received an undefined/unsupported instruction
`ifndef HALT_ON_ERROR
`define HALT_ON_ERROR 1
`endif

`define JALR    3'b000

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
`define ECALL   3'b000
`define EBREAK  3'b000
`define CSRRW   3'b001
`define CSRRS   3'b010
`define CSRRC   3'b011
`define CSRRWI  3'b101
`define CSRRSI  3'b110
`define CSRRCI  3'b111

`endif
