// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_alu

    #(
        parameter             ADDRW     = 16,
        parameter             XLEN      = 32
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // ALU instruction bus
        input  wire                       alu_en,
        output logic                      alu_ready,
        input  wire  [`ALU_INSTBUS_W-1:0] alu_instbus,
        // register source 1 query interface
        output logic [5             -1:0] regs_rs1_addr,
        input  wire  [XLEN          -1:0] regs_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] regs_rs2_addr,
        input  wire  [XLEN          -1:0] regs_rs2_val,
        // register estination for query interface
        output logic [5             -1:0] regs_rd_addr,
        input  wire  [XLEN          -1:0] regs_rd_val,
        // data memory interface
        output logic                      mem_en,
        output logic                      mem_wr,
        output logic [ADDRW         -1:0] mem_addr,
        output logic [XLEN          -1:0] mem_wdata,
        output logic [XLEN/8        -1:0] mem_strb,
        input  wire  [XLEN          -1:0] mem_rdata,
        input  wire                       mem_ready
    );

    // instructions fields
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

    assign opcode = alu_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = alu_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct7 = alu_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = alu_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = alu_instbus[`RS2    +: `RS2_W   ];
    assign rd     = alu_instbus[`RD     +: `RD_W    ];
    assign zimm   = alu_instbus[`ZIMM   +: `ZIMM_W  ];
    assign imm12  = alu_instbus[`IMM12  +: `IMM12_W ];
    assign imm20  = alu_instbus[`IMM20  +: `IMM20_W ];
    assign csr    = alu_instbus[`CSR    +: `CSR_W   ];
    assign shamt  = alu_instbus[`SHAMT  +: `SHAMT_W ];

    assign alu_ready = 1'b1;

    assign regs_rs1_addr = rs1;
    assign regs_rs2_addr = rs2;
    assign regs_rd_addr = rd;

    assign mem_en = 1'b0;
    assign mem_wr = 1'b0;
    assign mem_addr = {ADDRW{1'b0}};
    assign mem_wdata = {XLEN{1'b0}};
    assign mem_strb = {XLEN/8{1'b0}};

endmodule

`resetall
