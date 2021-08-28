// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_registers

    #(
        parameter RV32E = 0,
        parameter XLEN = 32
    )(
        // clock and resets
        input  logic              aclk,
        input  logic              aresetn,
        input  logic              srst,
        // register source 1 for control unit
        input  logic [5     -1:0] ctrl_rs1_addr,
        output logic [XLEN  -1:0] ctrl_rs1_val,
        // register source 2 for control unit
        input  logic [5     -1:0] ctrl_rs2_addr,
        output logic [XLEN  -1:0] ctrl_rs2_val,
        // register destination write from Control Unit
        input  logic              ctrl_rd_wr,
        input  logic [5     -1:0] ctrl_rd_addr,
        input  logic [XLEN  -1:0] ctrl_rd_val,
        // register source   1 for ALU
        input  logic [5     -1:0] alu_rs1_addr,
        output logic [XLEN  -1:0] alu_rs1_val,
        // register source 2 for ALU
        input  logic [5     -1:0] alu_rs2_addr,
        output logic [XLEN  -1:0] alu_rs2_val,
        // register destination write from ALU
        input  logic              alu_rd_wr,
        input  logic [5     -1:0] alu_rd_addr,
        input  logic [XLEN  -1:0] alu_rd_val,
        input  logic [XLEN/8-1:0] alu_rd_strb,
        // register source 1 for memfy
        input  logic [5     -1:0] memfy_rs1_addr,
        output logic [XLEN  -1:0] memfy_rs1_val,
        // register source 2 for memfy
        input  logic [5     -1:0] memfy_rs2_addr,
        output logic [XLEN  -1:0] memfy_rs2_val,
        // register destination write from memfy
        input  logic              memfy_rd_wr,
        input  logic [5     -1:0] memfy_rd_addr,
        input  logic [XLEN  -1:0] memfy_rd_val,
        input  logic [XLEN/8-1:0] memfy_rd_strb,
        // register source 1 for csr
        input  logic [5     -1:0] csr_rs1_addr,
        output logic [XLEN  -1:0] csr_rs1_val,
        // register destination write from memfy
        input  logic              csr_rd_wr,
        input  logic [5     -1:0] csr_rd_addr,
        input  logic [XLEN  -1:0] csr_rd_val
    );

    localparam REGNUM = (RV32E) ? 16 : 32;

    // ISA registers 0-31
    logic [XLEN-1:0] regs [REGNUM-1:0];

    genvar i;
    integer s;

    generate

    for (i=0; i<REGNUM; i++) begin: RegisterGeneration

    // registers' write circuit
    always @ (posedge aclk or negedge aresetn) begin
        // asynchronous reset
        if (aresetn == 1'b0) begin
            regs[i] <= {XLEN{1'b0}};
        // synchronous reset
        end else if (srst) begin
            regs[i] <= {XLEN{1'b0}};
        // write access to registers
        end else begin

            ///////////////////////////////////////////////
            // register 0 is alwyas 0, can't be overwritten
            ///////////////////////////////////////////////

            if (i==0) begin
                regs[i] <= {XLEN{1'b0}};

            ///////////////////////////////////////////////
            // registers 1-31
            ///////////////////////////////////////////////

            // Access from central controller
            end else if (ctrl_rd_wr && ctrl_rd_addr==i) begin
                regs[i] <= ctrl_rd_val;

            // Access from CSR manager
            end else if (csr_rd_wr && csr_rd_addr==i) begin
                regs[i] <= csr_rd_val;

            // Access from data memory controller
            end else if (memfy_rd_wr && memfy_rd_addr==i) begin
                for (s=0;s<(XLEN/8);s=s+1) begin
                    if (memfy_rd_strb[s]) begin
                        regs[i][s*8+:8] <= memfy_rd_val[s*8+:8];
                    end
                end

            // Acess from ALU
            end else if (alu_rd_wr && alu_rd_addr==i) begin
                for (s=0;s<(XLEN/8);s=s+1) begin
                    if (alu_rd_strb[s]) begin
                        regs[i][s*8+:8] <= alu_rd_val[s*8+:8];
                    end
                end
            end
        end
    end

    end
    endgenerate

    // register source 1 read circuit for control unit
    assign ctrl_rs1_val = regs[ctrl_rs1_addr];

    // register source 2 read circuit for control unit
    assign ctrl_rs2_val = regs[ctrl_rs2_addr];

    // register source 1 read circuit for ALU
    assign alu_rs1_val = regs[alu_rs1_addr];

    // register source 2 read circuit for ALU
    assign alu_rs2_val = regs[alu_rs2_addr];

    // register source 1 read circuit for memfy
    assign memfy_rs1_val = regs[memfy_rs1_addr];

    // register source 2 read circuit for memfy
    assign memfy_rs2_val = regs[memfy_rs2_addr];

    // register source 1 read circuit for CSR
    assign csr_rs1_val = regs[csr_rs1_addr];

    `ifdef FRISCV_SIM

    logic [XLEN-1:0] x0;
    logic [XLEN-1:0] x1;
    logic [XLEN-1:0] x2;
    logic [XLEN-1:0] x3;
    logic [XLEN-1:0] x4;
    logic [XLEN-1:0] x5;
    logic [XLEN-1:0] x6;
    logic [XLEN-1:0] x7;
    logic [XLEN-1:0] x8;
    logic [XLEN-1:0] x9;
    logic [XLEN-1:0] x10;
    logic [XLEN-1:0] x11;
    logic [XLEN-1:0] x12;
    logic [XLEN-1:0] x13;
    logic [XLEN-1:0] x14;
    logic [XLEN-1:0] x15;
    logic [XLEN-1:0] x16;
    logic [XLEN-1:0] x17;
    logic [XLEN-1:0] x18;
    logic [XLEN-1:0] x19;
    logic [XLEN-1:0] x20;
    logic [XLEN-1:0] x21;
    logic [XLEN-1:0] x22;
    logic [XLEN-1:0] x23;
    logic [XLEN-1:0] x24;
    logic [XLEN-1:0] x25;
    logic [XLEN-1:0] x26;
    logic [XLEN-1:0] x27;
    logic [XLEN-1:0] x28;
    logic [XLEN-1:0] x29;
    logic [XLEN-1:0] x30;
    logic [XLEN-1:0] x31;

    assign x0  = regs[ 0];
    assign x1  = regs[ 1];
    assign x2  = regs[ 2];
    assign x3  = regs[ 3];
    assign x4  = regs[ 4];
    assign x5  = regs[ 5];
    assign x6  = regs[ 6];
    assign x7  = regs[ 7];
    assign x8  = regs[ 8];
    assign x9  = regs[ 9];
    assign x10 = regs[10];
    assign x11 = regs[11];
    assign x12 = regs[12];
    assign x13 = regs[13];
    assign x14 = regs[14];
    assign x15 = regs[15];
    assign x16 = regs[16];
    assign x17 = regs[17];
    assign x18 = regs[18];
    assign x19 = regs[19];
    assign x20 = regs[20];
    assign x21 = regs[21];
    assign x22 = regs[22];
    assign x23 = regs[23];
    assign x24 = regs[24];
    assign x25 = regs[25];
    assign x26 = regs[26];
    assign x27 = regs[27];
    assign x28 = regs[28];
    assign x29 = regs[29];
    assign x30 = regs[30];
    assign x31 = regs[31];

    `endif

endmodule

`resetall
