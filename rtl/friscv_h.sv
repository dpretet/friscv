// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef FRISCV_H
`define FRISCV_H

`ifndef XLEN
`define XLEN 32
`endif

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
// PMP / PMA
//////////////////////////////////////////////////////////////////

`define PMP_OFF   0
`define PMP_TOR   1
`define PMP_NA4   2
`define PMP_NAPOT 3

`define PMA_R 0
`define PMA_W 1
`define PMA_X 2
`define PMA_A 3 // 4:3
`define PMA_L 7

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

// Load misaligned in memfy
`define LD_MA 0
// Store misaligned in memfy
`define ST_MA 1

//////////////////////////////////////////////////////////////////
// CSR Shared Bus Definition
//////////////////////////////////////////////////////////////////

// CSR shared bus placement
`define CSR_SB_PMPCFG0      0
`define CSR_SB_PMPCFG1      `CSR_SB_PMPCFG0 + `XLEN
`define CSR_SB_PMPCFG2      `CSR_SB_PMPCFG1 + `XLEN
`define CSR_SB_PMPCFG3      `CSR_SB_PMPCFG2 + `XLEN
`define CSR_SB_PMPADDR0     `CSR_SB_PMPCFG3 + `XLEN
`define CSR_SB_PMPADDR1     `CSR_SB_PMPADDR0 + `XLEN
`define CSR_SB_PMPADDR2     `CSR_SB_PMPADDR1 + `XLEN
`define CSR_SB_PMPADDR3     `CSR_SB_PMPADDR2 + `XLEN
`define CSR_SB_PMPADDR4     `CSR_SB_PMPADDR3 + `XLEN
`define CSR_SB_PMPADDR5     `CSR_SB_PMPADDR4 + `XLEN
`define CSR_SB_PMPADDR6     `CSR_SB_PMPADDR5 + `XLEN
`define CSR_SB_PMPADDR7     `CSR_SB_PMPADDR6 + `XLEN
`define CSR_SB_PMPADDR8     `CSR_SB_PMPADDR7 + `XLEN
`define CSR_SB_PMPADDR9     `CSR_SB_PMPADDR8 + `XLEN
`define CSR_SB_PMPADDR10    `CSR_SB_PMPADDR9 + `XLEN
`define CSR_SB_PMPADDR11    `CSR_SB_PMPADDR10 + `XLEN
`define CSR_SB_PMPADDR12    `CSR_SB_PMPADDR11 + `XLEN
`define CSR_SB_PMPADDR13    `CSR_SB_PMPADDR12 + `XLEN
`define CSR_SB_PMPADDR14    `CSR_SB_PMPADDR13 + `XLEN
`define CSR_SB_PMPADDR15    `CSR_SB_PMPADDR14 + `XLEN
`define CSR_SB_MTVEC        `CSR_SB_PMPADDR15 + `XLEN
`define CSR_SB_MEPC         `CSR_SB_MTVEC + `XLEN
`define CSR_SB_MSTATUS      `CSR_SB_MEPC + `XLEN
`define CSR_SB_MIE          `CSR_SB_MSTATUS + `XLEN
`define CSR_SB_MEIP         `CSR_SB_MIE + 1
`define CSR_SB_MTIP         `CSR_SB_MEIP + 1
`define CSR_SB_MSIP         `CSR_SB_MTIP + 1

// CSR shared bus width
`define CSR_SB_W `CSR_SB_MSIP + 1

`define CTRL_SB_MEPC       0
`define CTRL_SB_MEPC_WR    `CTRL_SB_MEPC + `XLEN 
`define CTRL_SB_MSTATUS    `CTRL_SB_MEPC_WR + 1
`define CTRL_SB_MSTATUS_WR `CTRL_SB_MSTATUS + `XLEN
`define CTRL_SB_MCAUSE     `CTRL_SB_MSTATUS_WR + 1
`define CTRL_SB_MCAUSE_WR  `CTRL_SB_MCAUSE + `XLEN
`define CTRL_SB_MTVAL      `CTRL_SB_MCAUSE_WR + 1
`define CTRL_SB_MTVAL_WR   `CTRL_SB_MTVAL + `XLEN 
`define CTRL_CLR_MEIP      `CTRL_SB_MTVAL_WR + 1
`define CTRL_INSTRET       `CTRL_CLR_MEIP + 1

`define CTRL_SB_W `CTRL_INSTRET + `XLEN*2

//////////////////////////////////////////////////////////////////
// execution mode
//////////////////////////////////////////////////////////////////

`define MMODE 2'b11
`define HMODE 2'b10
`define SMODE 2'b01
`define UMODE 2'b00


`endif // FRISCV_H
