// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_m_ext

    #(
        parameter XLEN  = 32
    )(
        // clock & reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // ALU instruction bus
        input  logic                      m_en,
        output logic                      m_ready,
        input  logic [`INST_BUS_W   -1:0] m_instbus,
        // register source 1 query interface
        output logic [5             -1:0] m_rs1_addr,
        input  logic [XLEN          -1:0] m_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] m_rs2_addr,
        input  logic [XLEN          -1:0] m_rs2_val,
        // register estination for query interface
        output logic                      m_rd_wr,
        output logic [5             -1:0] m_rd_addr,
        output logic [XLEN          -1:0] m_rd_val,
        output logic [XLEN/8        -1:0] m_rd_strb
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    // instructions fields
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus fields
    //
    ///////////////////////////////////////////////////////////////////////////

    assign opcode = alu_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = alu_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct7 = alu_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = alu_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = alu_instbus[`RS2    +: `RS2_W   ];
    assign rd     = alu_instbus[`RD     +: `RD_W    ];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Multiply / divide operations
    //
    ///////////////////////////////////////////////////////////////////////////


endmodule

`resetall
