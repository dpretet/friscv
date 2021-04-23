// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_alu

    #(
        parameter ADDRW = 16,
        parameter XLEN  = 32
    )(
        // clock & reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // ALU instruction bus
        input  logic                      alu_en,
        output logic                      alu_ready,
        output logic                      alu_empty,
        input  logic [`ALU_INSTBUS_W-1:0] alu_instbus,
        // register source 1 query interface
        output logic [5             -1:0] alu_rs1_addr,
        input  logic [XLEN          -1:0] alu_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] alu_rs2_addr,
        input  logic [XLEN          -1:0] alu_rs2_val,
        // register estination for query interface
        output logic                      alu_rd_wr,
        output logic [5             -1:0] alu_rd_addr,
        output logic [XLEN          -1:0] alu_rd_val,
        output logic [XLEN/8        -1:0] alu_rd_strb
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // instructions fields
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

    logic                    r_i_opcode;

    logic        [XLEN -1:0] _add;
    logic        [XLEN -1:0] _sub;
    logic        [XLEN -1:0] _slt;
    logic        [XLEN -1:0] _sltu;
    logic        [XLEN -1:0] _xor;
    logic        [XLEN -1:0] _or;
    logic        [XLEN -1:0] _and;
    logic        [XLEN -1:0] _sll;
    logic        [XLEN -1:0] _srl;
    logic        [XLEN -1:0] _sra;

    logic        [XLEN -1:0] _addi;
    logic        [XLEN -1:0] _slti;
    logic        [XLEN -1:0] _sltiu;
    logic        [XLEN -1:0] _xori;
    logic        [XLEN -1:0] _ori;
    logic        [XLEN -1:0] _andi;
    logic        [XLEN -1:0] _slli;
    logic        [XLEN -1:0] _srli;
    logic        [XLEN -1:0] _srai;

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
    assign zimm   = alu_instbus[`ZIMM   +: `ZIMM_W  ];
    assign imm12  = alu_instbus[`IMM12  +: `IMM12_W ];
    assign imm20  = alu_instbus[`IMM20  +: `IMM20_W ];
    assign csr    = alu_instbus[`CSR    +: `CSR_W   ];
    assign shamt  = alu_instbus[`SHAMT  +: `SHAMT_W ];

    assign r_i_opcode = (opcode==`R_ARITH || opcode==`I_ARITH) ? 1'b1 : 1'b0;

    assign alu_ready = 1'b1;
    assign alu_empty = 1'b0;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Registers IOS
    //
    ///////////////////////////////////////////////////////////////////////////

    assign alu_rs1_addr = rs1;

    assign alu_rs2_addr = rs2;

    assign alu_rd_wr = alu_en & r_i_opcode;

    assign alu_rd_addr = rd;

    assign alu_rd_val = (opcode==`I_ARITH && funct3==`ADDI)                    ? _addi :
                        (opcode==`I_ARITH && funct3==`SLTI)                    ? _slti :
                        (opcode==`I_ARITH && funct3==`SLTIU)                   ? _sltiu :
                        (opcode==`I_ARITH && funct3==`XORI)                    ? _xori :
                        (opcode==`I_ARITH && funct3==`ORI)                     ? _ori :
                        (opcode==`I_ARITH && funct3==`ANDI)                    ? _andi :
                        (opcode==`I_ARITH && funct3==`SLLI)                    ? _slli :
                        (opcode==`I_ARITH && funct3==`SRLI && funct7[5]==1'b0) ? _srli :
                        (opcode==`I_ARITH && funct3==`SRAI && funct7[5]==1'b1) ? _srai :
                        (opcode==`R_ARITH && funct3==`ADD && funct7[5]==1'b0)  ? _add :
                        (opcode==`R_ARITH && funct3==`SUB && funct7[5]==1'b1)  ? _sub :
                        (opcode==`R_ARITH && funct3==`SLT)                     ? _slt :
                        (opcode==`R_ARITH && funct3==`SLTU)                    ? _sltu :
                        (opcode==`R_ARITH && funct3==`XOR)                     ? _xor :
                        (opcode==`R_ARITH && funct3==`OR)                      ? _or :
                        (opcode==`R_ARITH && funct3==`AND)                     ? _and :
                        (opcode==`R_ARITH && funct3==`SLL)                     ? _sll :
                        (opcode==`R_ARITH && funct3==`SRL && funct7[5]==1'b0)  ? _srl :
                        (opcode==`R_ARITH && funct3==`SRA && funct7[5]==1'b1)  ? _sra :
                                                                                 {XLEN{1'b0}};

    assign alu_rd_strb = (r_i_opcode) ? {(XLEN/8){1'b1}} : {(XLEN/8){1'b0}};


    ///////////////////////////////////////////////////////////////////////////
    //
    // ALU computations
    //
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // I-type instructions
    ///////////////////////////////////////////////////////////////////////////

    assign _addi = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(alu_rs1_val);

    assign _slti = ($signed(alu_rs1_val) < $signed({{(XLEN-12){imm12[11]}}, imm12})) ? {{XLEN-1{1'b0}}, 1'b1} :
                                                                                       {XLEN{1'b0}};

    assign _sltiu = ({{(XLEN-12){imm12[11]}}, imm12} < alu_rs1_val) ? {{XLEN-1{1'b0}}, 1'b1} :
                                                                      {XLEN{1'b0}};

    assign _xori = {{(XLEN-12){imm12[11]}}, imm12} ^ alu_rs1_val;

    assign _ori = {{(XLEN-12){imm12[11]}}, imm12} | alu_rs1_val;

    assign _andi = {{(XLEN-12){imm12[11]}}, imm12} & alu_rs1_val;

    assign _slli = (shamt == 6'd01) ? {alu_rs1_val[XLEN-1-01:0],  1'b0} :
                   (shamt == 6'd02) ? {alu_rs1_val[XLEN-1-02:0],  2'b0} :
                   (shamt == 6'd03) ? {alu_rs1_val[XLEN-1-03:0],  3'b0} :
                   (shamt == 6'd04) ? {alu_rs1_val[XLEN-1-04:0],  4'b0} :
                   (shamt == 6'd05) ? {alu_rs1_val[XLEN-1-05:0],  5'b0} :
                   (shamt == 6'd06) ? {alu_rs1_val[XLEN-1-06:0],  6'b0} :
                   (shamt == 6'd07) ? {alu_rs1_val[XLEN-1-07:0],  7'b0} :
                   (shamt == 6'd08) ? {alu_rs1_val[XLEN-1-08:0],  8'b0} :
                   (shamt == 6'd09) ? {alu_rs1_val[XLEN-1-09:0],  9'b0} :
                   (shamt == 6'd10) ? {alu_rs1_val[XLEN-1-10:0], 10'b0} :
                   (shamt == 6'd11) ? {alu_rs1_val[XLEN-1-11:0], 11'b0} :
                   (shamt == 6'd12) ? {alu_rs1_val[XLEN-1-12:0], 12'b0} :
                   (shamt == 6'd13) ? {alu_rs1_val[XLEN-1-13:0], 13'b0} :
                   (shamt == 6'd14) ? {alu_rs1_val[XLEN-1-14:0], 14'b0} :
                   (shamt == 6'd15) ? {alu_rs1_val[XLEN-1-15:0], 15'b0} :
                   (shamt == 6'd16) ? {alu_rs1_val[XLEN-1-16:0], 16'b0} :
                   (shamt == 6'd17) ? {alu_rs1_val[XLEN-1-17:0], 17'b0} :
                   (shamt == 6'd18) ? {alu_rs1_val[XLEN-1-18:0], 18'b0} :
                   (shamt == 6'd19) ? {alu_rs1_val[XLEN-1-19:0], 19'b0} :
                   (shamt == 6'd20) ? {alu_rs1_val[XLEN-1-20:0], 20'b0} :
                   (shamt == 6'd21) ? {alu_rs1_val[XLEN-1-21:0], 21'b0} :
                   (shamt == 6'd22) ? {alu_rs1_val[XLEN-1-22:0], 22'b0} :
                   (shamt == 6'd23) ? {alu_rs1_val[XLEN-1-23:0], 23'b0} :
                   (shamt == 6'd24) ? {alu_rs1_val[XLEN-1-24:0], 24'b0} :
                   (shamt == 6'd25) ? {alu_rs1_val[XLEN-1-25:0], 25'b0} :
                   (shamt == 6'd26) ? {alu_rs1_val[XLEN-1-26:0], 26'b0} :
                   (shamt == 6'd27) ? {alu_rs1_val[XLEN-1-27:0], 27'b0} :
                   (shamt == 6'd28) ? {alu_rs1_val[XLEN-1-28:0], 28'b0} :
                   (shamt == 6'd29) ? {alu_rs1_val[XLEN-1-29:0], 29'b0} :
                   (shamt == 6'd30) ? {alu_rs1_val[XLEN-1-30:0], 30'b0} :
                   (shamt == 6'd31) ? {alu_rs1_val[XLEN-1-31:0], 31'b0} :
                                      {alu_rs1_val[XLEN-1:0]} ;

    assign _srli = (shamt == 6'd01) ? {01'b0, alu_rs1_val[XLEN-1:01]} :
                   (shamt == 6'd02) ? {02'b0, alu_rs1_val[XLEN-1:02]} :
                   (shamt == 6'd03) ? {03'b0, alu_rs1_val[XLEN-1:03]} :
                   (shamt == 6'd04) ? {04'b0, alu_rs1_val[XLEN-1:04]} :
                   (shamt == 6'd05) ? {05'b0, alu_rs1_val[XLEN-1:05]} :
                   (shamt == 6'd06) ? {06'b0, alu_rs1_val[XLEN-1:06]} :
                   (shamt == 6'd07) ? {07'b0, alu_rs1_val[XLEN-1:07]} :
                   (shamt == 6'd08) ? {08'b0, alu_rs1_val[XLEN-1:08]} :
                   (shamt == 6'd09) ? {09'b0, alu_rs1_val[XLEN-1:09]} :
                   (shamt == 6'd10) ? {10'b0, alu_rs1_val[XLEN-1:10]} :
                   (shamt == 6'd11) ? {11'b0, alu_rs1_val[XLEN-1:11]} :
                   (shamt == 6'd12) ? {12'b0, alu_rs1_val[XLEN-1:12]} :
                   (shamt == 6'd13) ? {13'b0, alu_rs1_val[XLEN-1:13]} :
                   (shamt == 6'd14) ? {14'b0, alu_rs1_val[XLEN-1:14]} :
                   (shamt == 6'd15) ? {15'b0, alu_rs1_val[XLEN-1:15]} :
                   (shamt == 6'd16) ? {16'b0, alu_rs1_val[XLEN-1:16]} :
                   (shamt == 6'd17) ? {17'b0, alu_rs1_val[XLEN-1:17]} :
                   (shamt == 6'd18) ? {18'b0, alu_rs1_val[XLEN-1:18]} :
                   (shamt == 6'd19) ? {19'b0, alu_rs1_val[XLEN-1:19]} :
                   (shamt == 6'd20) ? {20'b0, alu_rs1_val[XLEN-1:20]} :
                   (shamt == 6'd21) ? {21'b0, alu_rs1_val[XLEN-1:21]} :
                   (shamt == 6'd22) ? {22'b0, alu_rs1_val[XLEN-1:22]} :
                   (shamt == 6'd23) ? {23'b0, alu_rs1_val[XLEN-1:23]} :
                   (shamt == 6'd24) ? {24'b0, alu_rs1_val[XLEN-1:24]} :
                   (shamt == 6'd25) ? {25'b0, alu_rs1_val[XLEN-1:25]} :
                   (shamt == 6'd26) ? {26'b0, alu_rs1_val[XLEN-1:26]} :
                   (shamt == 6'd27) ? {27'b0, alu_rs1_val[XLEN-1:27]} :
                   (shamt == 6'd28) ? {28'b0, alu_rs1_val[XLEN-1:28]} :
                   (shamt == 6'd29) ? {29'b0, alu_rs1_val[XLEN-1:29]} :
                   (shamt == 6'd30) ? {30'b0, alu_rs1_val[XLEN-1:30]} :
                   (shamt == 6'd31) ? {31'b0, alu_rs1_val[XLEN-1:31]} :
                                      {alu_rs1_val[XLEN-1:0]} ;

    assign _srai = (shamt == 6'd01) ? {{01{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:01]} :
                   (shamt == 6'd02) ? {{02{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:02]} :
                   (shamt == 6'd03) ? {{03{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:03]} :
                   (shamt == 6'd04) ? {{04{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:04]} :
                   (shamt == 6'd05) ? {{05{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:05]} :
                   (shamt == 6'd06) ? {{06{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:06]} :
                   (shamt == 6'd07) ? {{07{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:07]} :
                   (shamt == 6'd08) ? {{08{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:08]} :
                   (shamt == 6'd09) ? {{09{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:09]} :
                   (shamt == 6'd10) ? {{10{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:10]} :
                   (shamt == 6'd11) ? {{11{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:11]} :
                   (shamt == 6'd12) ? {{12{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:12]} :
                   (shamt == 6'd13) ? {{13{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:13]} :
                   (shamt == 6'd14) ? {{14{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:14]} :
                   (shamt == 6'd15) ? {{15{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:15]} :
                   (shamt == 6'd16) ? {{16{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:16]} :
                   (shamt == 6'd17) ? {{17{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:17]} :
                   (shamt == 6'd18) ? {{18{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:18]} :
                   (shamt == 6'd19) ? {{19{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:19]} :
                   (shamt == 6'd20) ? {{20{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:20]} :
                   (shamt == 6'd21) ? {{21{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:21]} :
                   (shamt == 6'd22) ? {{22{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:22]} :
                   (shamt == 6'd23) ? {{23{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:23]} :
                   (shamt == 6'd24) ? {{24{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:24]} :
                   (shamt == 6'd25) ? {{25{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:25]} :
                   (shamt == 6'd26) ? {{26{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:26]} :
                   (shamt == 6'd27) ? {{27{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:27]} :
                   (shamt == 6'd28) ? {{28{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:28]} :
                   (shamt == 6'd29) ? {{29{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:29]} :
                   (shamt == 6'd30) ? {{30{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:30]} :
                   (shamt == 6'd31) ? {{31{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:31]} :
                                      {alu_rs1_val[XLEN-1:0]} ;

    ///////////////////////////////////////////////////////////////////////////
    // R-type instructions
    ///////////////////////////////////////////////////////////////////////////

    assign _add = $signed(alu_rs1_val) + $signed(alu_rs2_val);

    assign _sub = $signed(alu_rs1_val) - $signed(alu_rs2_val);

    assign _slt = ($signed(alu_rs1_val) < $signed(alu_rs2_val)) ? {{XLEN-1{1'b0}}, 1'b1} :
                                                                  {XLEN{1'b0}};

    assign _sltu = (alu_rs1_val < alu_rs2_val) ? {{XLEN-1{1'b0}}, 1'b1} :
                                                  {XLEN{1'b0}};

    assign _xor = alu_rs1_val ^ alu_rs2_val;

    assign _or = alu_rs1_val | alu_rs2_val;

    assign _and = alu_rs1_val & alu_rs2_val;

    assign _sll = (alu_rs2_val[5:0] == 6'd01) ? {alu_rs1_val[XLEN-1-01:0], 01'b0} :
                  (alu_rs2_val[5:0] == 6'd02) ? {alu_rs1_val[XLEN-1-02:0], 02'b0} :
                  (alu_rs2_val[5:0] == 6'd03) ? {alu_rs1_val[XLEN-1-03:0], 03'b0} :
                  (alu_rs2_val[5:0] == 6'd04) ? {alu_rs1_val[XLEN-1-04:0], 04'b0} :
                  (alu_rs2_val[5:0] == 6'd05) ? {alu_rs1_val[XLEN-1-05:0], 05'b0} :
                  (alu_rs2_val[5:0] == 6'd06) ? {alu_rs1_val[XLEN-1-06:0], 06'b0} :
                  (alu_rs2_val[5:0] == 6'd07) ? {alu_rs1_val[XLEN-1-07:0], 07'b0} :
                  (alu_rs2_val[5:0] == 6'd08) ? {alu_rs1_val[XLEN-1-08:0], 08'b0} :
                  (alu_rs2_val[5:0] == 6'd09) ? {alu_rs1_val[XLEN-1-09:0], 09'b0} :
                  (alu_rs2_val[5:0] == 6'd10) ? {alu_rs1_val[XLEN-1-10:0], 10'b0} :
                  (alu_rs2_val[5:0] == 6'd11) ? {alu_rs1_val[XLEN-1-11:0], 11'b0} :
                  (alu_rs2_val[5:0] == 6'd12) ? {alu_rs1_val[XLEN-1-12:0], 12'b0} :
                  (alu_rs2_val[5:0] == 6'd13) ? {alu_rs1_val[XLEN-1-13:0], 13'b0} :
                  (alu_rs2_val[5:0] == 6'd14) ? {alu_rs1_val[XLEN-1-14:0], 14'b0} :
                  (alu_rs2_val[5:0] == 6'd15) ? {alu_rs1_val[XLEN-1-15:0], 15'b0} :
                  (alu_rs2_val[5:0] == 6'd16) ? {alu_rs1_val[XLEN-1-16:0], 16'b0} :
                  (alu_rs2_val[5:0] == 6'd17) ? {alu_rs1_val[XLEN-1-17:0], 17'b0} :
                  (alu_rs2_val[5:0] == 6'd18) ? {alu_rs1_val[XLEN-1-18:0], 18'b0} :
                  (alu_rs2_val[5:0] == 6'd19) ? {alu_rs1_val[XLEN-1-19:0], 19'b0} :
                  (alu_rs2_val[5:0] == 6'd20) ? {alu_rs1_val[XLEN-1-20:0], 20'b0} :
                  (alu_rs2_val[5:0] == 6'd21) ? {alu_rs1_val[XLEN-1-21:0], 21'b0} :
                  (alu_rs2_val[5:0] == 6'd22) ? {alu_rs1_val[XLEN-1-22:0], 22'b0} :
                  (alu_rs2_val[5:0] == 6'd23) ? {alu_rs1_val[XLEN-1-23:0], 23'b0} :
                  (alu_rs2_val[5:0] == 6'd24) ? {alu_rs1_val[XLEN-1-24:0], 24'b0} :
                  (alu_rs2_val[5:0] == 6'd25) ? {alu_rs1_val[XLEN-1-25:0], 25'b0} :
                  (alu_rs2_val[5:0] == 6'd26) ? {alu_rs1_val[XLEN-1-26:0], 26'b0} :
                  (alu_rs2_val[5:0] == 6'd27) ? {alu_rs1_val[XLEN-1-27:0], 27'b0} :
                  (alu_rs2_val[5:0] == 6'd28) ? {alu_rs1_val[XLEN-1-28:0], 28'b0} :
                  (alu_rs2_val[5:0] == 6'd29) ? {alu_rs1_val[XLEN-1-29:0], 29'b0} :
                  (alu_rs2_val[5:0] == 6'd30) ? {alu_rs1_val[XLEN-1-30:0], 30'b0} :
                  (alu_rs2_val[5:0] == 6'd31) ? {alu_rs1_val[XLEN-1-31:0], 31'b0} :
                                                {alu_rs1_val[XLEN-1:0]} ;

    assign _srl = (alu_rs2_val[5:0] == 6'd01) ? {01'b0, alu_rs1_val[XLEN-1:01]} :
                  (alu_rs2_val[5:0] == 6'd02) ? {02'b0, alu_rs1_val[XLEN-1:02]} :
                  (alu_rs2_val[5:0] == 6'd03) ? {03'b0, alu_rs1_val[XLEN-1:03]} :
                  (alu_rs2_val[5:0] == 6'd04) ? {04'b0, alu_rs1_val[XLEN-1:04]} :
                  (alu_rs2_val[5:0] == 6'd05) ? {05'b0, alu_rs1_val[XLEN-1:05]} :
                  (alu_rs2_val[5:0] == 6'd06) ? {06'b0, alu_rs1_val[XLEN-1:06]} :
                  (alu_rs2_val[5:0] == 6'd07) ? {07'b0, alu_rs1_val[XLEN-1:07]} :
                  (alu_rs2_val[5:0] == 6'd08) ? {08'b0, alu_rs1_val[XLEN-1:08]} :
                  (alu_rs2_val[5:0] == 6'd09) ? {09'b0, alu_rs1_val[XLEN-1:09]} :
                  (alu_rs2_val[5:0] == 6'd10) ? {10'b0, alu_rs1_val[XLEN-1:10]} :
                  (alu_rs2_val[5:0] == 6'd11) ? {11'b0, alu_rs1_val[XLEN-1:11]} :
                  (alu_rs2_val[5:0] == 6'd12) ? {12'b0, alu_rs1_val[XLEN-1:12]} :
                  (alu_rs2_val[5:0] == 6'd13) ? {13'b0, alu_rs1_val[XLEN-1:13]} :
                  (alu_rs2_val[5:0] == 6'd14) ? {14'b0, alu_rs1_val[XLEN-1:14]} :
                  (alu_rs2_val[5:0] == 6'd15) ? {15'b0, alu_rs1_val[XLEN-1:15]} :
                  (alu_rs2_val[5:0] == 6'd16) ? {16'b0, alu_rs1_val[XLEN-1:16]} :
                  (alu_rs2_val[5:0] == 6'd17) ? {17'b0, alu_rs1_val[XLEN-1:17]} :
                  (alu_rs2_val[5:0] == 6'd18) ? {18'b0, alu_rs1_val[XLEN-1:18]} :
                  (alu_rs2_val[5:0] == 6'd19) ? {19'b0, alu_rs1_val[XLEN-1:19]} :
                  (alu_rs2_val[5:0] == 6'd20) ? {20'b0, alu_rs1_val[XLEN-1:20]} :
                  (alu_rs2_val[5:0] == 6'd21) ? {21'b0, alu_rs1_val[XLEN-1:21]} :
                  (alu_rs2_val[5:0] == 6'd22) ? {22'b0, alu_rs1_val[XLEN-1:22]} :
                  (alu_rs2_val[5:0] == 6'd23) ? {23'b0, alu_rs1_val[XLEN-1:23]} :
                  (alu_rs2_val[5:0] == 6'd24) ? {24'b0, alu_rs1_val[XLEN-1:24]} :
                  (alu_rs2_val[5:0] == 6'd25) ? {25'b0, alu_rs1_val[XLEN-1:25]} :
                  (alu_rs2_val[5:0] == 6'd26) ? {26'b0, alu_rs1_val[XLEN-1:26]} :
                  (alu_rs2_val[5:0] == 6'd27) ? {27'b0, alu_rs1_val[XLEN-1:27]} :
                  (alu_rs2_val[5:0] == 6'd28) ? {28'b0, alu_rs1_val[XLEN-1:28]} :
                  (alu_rs2_val[5:0] == 6'd29) ? {29'b0, alu_rs1_val[XLEN-1:29]} :
                  (alu_rs2_val[5:0] == 6'd30) ? {30'b0, alu_rs1_val[XLEN-1:30]} :
                  (alu_rs2_val[5:0] == 6'd31) ? {31'b0, alu_rs1_val[XLEN-1:31]} :
                                                {alu_rs1_val[XLEN-1:0]} ;

    assign _sra = (alu_rs2_val[5:0] == 6'd01) ? {{01{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:01]} :
                  (alu_rs2_val[5:0] == 6'd02) ? {{02{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:02]} :
                  (alu_rs2_val[5:0] == 6'd03) ? {{03{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:03]} :
                  (alu_rs2_val[5:0] == 6'd04) ? {{04{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:04]} :
                  (alu_rs2_val[5:0] == 6'd05) ? {{05{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:05]} :
                  (alu_rs2_val[5:0] == 6'd06) ? {{06{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:06]} :
                  (alu_rs2_val[5:0] == 6'd07) ? {{07{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:07]} :
                  (alu_rs2_val[5:0] == 6'd08) ? {{08{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:08]} :
                  (alu_rs2_val[5:0] == 6'd09) ? {{09{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:09]} :
                  (alu_rs2_val[5:0] == 6'd10) ? {{10{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:10]} :
                  (alu_rs2_val[5:0] == 6'd11) ? {{11{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:11]} :
                  (alu_rs2_val[5:0] == 6'd12) ? {{12{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:12]} :
                  (alu_rs2_val[5:0] == 6'd13) ? {{13{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:13]} :
                  (alu_rs2_val[5:0] == 6'd14) ? {{14{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:14]} :
                  (alu_rs2_val[5:0] == 6'd15) ? {{15{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:15]} :
                  (alu_rs2_val[5:0] == 6'd16) ? {{16{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:16]} :
                  (alu_rs2_val[5:0] == 6'd17) ? {{17{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:17]} :
                  (alu_rs2_val[5:0] == 6'd18) ? {{18{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:18]} :
                  (alu_rs2_val[5:0] == 6'd19) ? {{19{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:19]} :
                  (alu_rs2_val[5:0] == 6'd20) ? {{20{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:20]} :
                  (alu_rs2_val[5:0] == 6'd21) ? {{21{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:21]} :
                  (alu_rs2_val[5:0] == 6'd22) ? {{22{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:22]} :
                  (alu_rs2_val[5:0] == 6'd23) ? {{23{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:23]} :
                  (alu_rs2_val[5:0] == 6'd24) ? {{24{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:24]} :
                  (alu_rs2_val[5:0] == 6'd25) ? {{25{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:25]} :
                  (alu_rs2_val[5:0] == 6'd26) ? {{26{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:26]} :
                  (alu_rs2_val[5:0] == 6'd27) ? {{27{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:27]} :
                  (alu_rs2_val[5:0] == 6'd28) ? {{28{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:28]} :
                  (alu_rs2_val[5:0] == 6'd29) ? {{29{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:29]} :
                  (alu_rs2_val[5:0] == 6'd30) ? {{30{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:30]} :
                  (alu_rs2_val[5:0] == 6'd31) ? {{31{alu_rs1_val[XLEN-1]}}, alu_rs1_val[XLEN-1:31]} :
                                                {alu_rs1_val[XLEN-1:0]} ;


endmodule

`resetall
