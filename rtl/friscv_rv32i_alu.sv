`timescale 1 ns / 1 ps
`default_nettype none

module friscv_rv32i_alu

    #(
        parameter             ADDRW     = 16,
        parameter             XLEN      = 32
    )(
        // clock & reset
        input  wire               aclk,
        input  wire               aresetn,
        input  wire               srst,
        // enable to activate the ALU
        input  wire               alu_en,
        output logic              alu_ready,
        // all info extracted from instruction
        input  wire  [7     -1:0] opcode,
        input  wire  [3     -1:0] funct3,
        input  wire  [7     -1:0] funct7,
        input  wire  [5     -1:0] rs1,
        input  wire  [5     -1:0] rs2,
        input  wire  [5     -1:0] rd,
        input  wire  [5     -1:0] zimm,
        input  wire  [12    -1:0] imm12,
        input  wire  [20    -1:0] imm20,
        input  wire  [12    -1:0] csr,
        input  wire  [5     -1:0] shamt,
        // register source 1 query interface
        output logic [5     -1:0] regs_rs1_addr,
        input  wire  [XLEN  -1:0] regs_rs1_val,
        // register source 2 for query interface
        output logic [5     -1:0] regs_rs2_addr,
        input  wire  [XLEN  -1:0] regs_rs2_val,
        // register estination for query interface
        output logic [5     -1:0] regs_rd_addr,
        input  wire  [XLEN  -1:0] regs_rd_val,
        // data memory interface
        output logic              mem_en,
        output logic              mem_wr,
        output logic [ADDRW -1:0] mem_addr,
        output logic [XLEN  -1:0] mem_wdata,
        output logic [XLEN/8-1:0] mem_strb,
        input  wire  [XLEN  -1:0] mem_rdata,
        input  wire               mem_ready
    );

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
