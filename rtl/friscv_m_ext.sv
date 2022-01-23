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
        input  logic                      m_valid,
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

    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT3_W   -1:0] funct3_r;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`RD_W       -1:0] rd_r;
    logic [2*XLEN      -1:0] muldiv32;
    logic [2*XLEN      -1:0] muldiv64;
    logic [2*XLEN      -1:0] mul_h;
    logic [2*XLEN+2    -1:0] mulhsu;
    logic [2*XLEN      -1:0] mulhu;
    logic [2*XLEN      -1:0] mulw;

    logic [XLEN        -1:0] quot;
    logic [XLEN        -1:0] quotu;
    logic [XLEN        -1:0] rem;
    logic [XLEN        -2:0] remu;
    logic                    rd_wr_div;
    logic                    m_valid_div;
    logic                    signed_div;



    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus fields
    //
    ///////////////////////////////////////////////////////////////////////////

    assign opcode = m_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = m_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct7 = m_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = m_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = m_instbus[`RS2    +: `RS2_W   ];
    assign rd     = m_instbus[`RD     +: `RD_W    ];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Multiply / divide operations
    //
    ///////////////////////////////////////////////////////////////////////////

    // 32 bits multiplication instructions
    assign mul_h = $signed(m_rs1_val) * $signed(m_rs2_val);
    // TODO: Share this multiplier with mul if timing closure is difficult
    assign mulhsu = $signed({m_rs1_val[31],m_rs1_val}) * $signed({1'b0, m_rs2_val[31:0]});
    assign mulhu = m_rs1_val * m_rs2_val;

    assign muldiv32 = (funct3==`MUL)    ? mul_h[0+:32] :
                      (funct3==`MULH)   ? mul_h[32+:32] :
                      (funct3==`MULHSU) ? mulhsu[32+:32] :
                      (funct3==`MULHU)  ? mulhu[32+:32] :
                                          {XLEN{1'b0}};


    // 32 bits division
    assign quotu = {XLEN{1'b0}};
    assign remu = {XLEN{1'b0}};

    generate

    if (XLEN==64) begin: l_MULDIV64_GEN

        // 64 bits multiplication instruction
        assign mulw = $signed(m_rs1_val[0+:32]) * $signed(m_rs2_val[0+:32]);

        assign muldiv64 = {{32{mulw[31]}},mulw[31:0]};

    end else begin: l_NO_MULDIV64_GEN

        assign muldiv64 = {XLEN{1'b0}};

    end
    endgenerate


    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            funct3_r <= {`FUNCT3_W{1'b0}};
            rd_r <= 5'b0;
        end else if (srst) begin
            funct3_r <= {`FUNCT3_W{1'b0}};
            rd_r <= 5'b0;
        end else begin
            if (m_valid & m_ready) begin
                funct3_r <= funct3;
                rd_r <= rd;
            end
        end
    end

    assign m_valid_div = m_valid & funct3[2];
    assign signed_div = (funct3==`DIV) | (funct3==`REM);

    friscv_div 
    #(
        .WIDTH (XLEN)
    )
    div32
    (
        .aclk       (aclk),
        .aresetn    (aresetn),
        .srst       (srst),
        .i_valid    (m_valid_div),
        .i_ready    (m_ready),
        .signed_div (signed_div),
        .divd       (m_rs1_val),
        .divs       (m_rs2_val),
        .o_valid    (rd_wr_div),
        .o_ready    (1'b1),
        .zero_div   (),
        .quot       (quot),
        .rem        (rem)
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // ISA Registers interface
    //
    ///////////////////////////////////////////////////////////////////////////

    assign m_rs1_addr = rs1;

    assign m_rs2_addr = rs2;

    assign m_rd_wr = (m_valid & !funct3[2]) | rd_wr_div;

    assign m_rd_addr = (rd_wr_div) ? rd_r : rd;

    assign m_rd_strb = {XLEN/8{1'b1}};

    generate

    if (XLEN==64) begin: l_MULDIV64_SUPPORT

    assign m_rd_val =   (rd_wr_div && (funct3_r==`DIV || funct3_r==`DIVU)) ? quot :
                        (rd_wr_div && (funct3_r==`REM || funct3_r==`REMU)) ? rem :
                        (opcode==`MULDIVW)                                 ? muldiv64 : 
                                                                             muldiv32 ;

    end else begin: l_NO_MULDIV64_SUPPORT

    assign m_rd_val =   (rd_wr_div && (funct3_r==`DIV || funct3_r==`DIVU)) ? quot :
                        (rd_wr_div && (funct3_r==`REM || funct3_r==`REMU)) ? rem :
                                                                             muldiv32;

    end
    endgenerate

endmodule

`resetall
