/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"

`timescale 1 ns / 100 ps

module friscv_rv32i_alu_testbench();

    `SVUT_SETUP

    parameter             ADDRW     = 16;
    parameter             XLEN      = 32;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      alu_en;
    logic                      alu_ready;
    logic [`ALU_INSTBUS_W-1:0] alu_instbus;
    logic [5             -1:0] alu_rs1_addr;
    logic [XLEN          -1:0] alu_rs1_val;
    logic [5             -1:0] alu_rs2_addr;
    logic [XLEN          -1:0] alu_rs2_val;
    logic                      alu_rd_wr;
    logic [5             -1:0] alu_rd_addr;
    logic [XLEN          -1:0] alu_rd_val;
    logic                      mem_en;
    logic                      mem_wr;
    logic [ADDRW         -1:0] mem_addr;
    logic [XLEN          -1:0] mem_wdata;
    logic [XLEN/8        -1:0] mem_strb;
    logic [XLEN          -1:0] mem_rdata;
    logic                      mem_ready;

    logic [7             -1:0] opcode;
    logic [3             -1:0] funct3;
    logic [7             -1:0] funct7;
    logic [5             -1:0] rs1;
    logic [5             -1:0] rs2;
    logic [5             -1:0] rd;
    logic [5             -1:0] zimm;
    logic [12            -1:0] imm12;
    logic [20            -1:0] imm20;
    logic [12            -1:0] csr;
    logic [5             -1:0] shamt;

    friscv_rv32i_alu
    #(
    ADDRW,
    XLEN
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    alu_en,
    alu_ready,
    alu_instbus,
    alu_rs1_addr,
    alu_rs1_val,
    alu_rs2_addr,
    alu_rs2_val,
    alu_rd_wr,
    alu_rd_addr,
    alu_rd_val,
    mem_en,
    mem_wr,
    mem_addr,
    mem_wdata,
    mem_strb,
    mem_rdata,
    mem_ready
    );

    /// to create a clock:
    initial aclk = 0;
    always #1 aclk = ~aclk;

    /// to dump data for visualization:
    initial begin
        $dumpfile("friscv_rv32i_alu_testbench.vcd");
        $dumpvars(0, friscv_rv32i_alu_testbench);
    end

    task setup(msg="");
    begin
        aresetn =1'b0;
        srst = 1'b0;
        alu_en = 1'b0;
        alu_instbus = {`ALU_INSTBUS_W{1'b0}};
        alu_rs1_val = {XLEN{1'b0}};
        alu_rs2_val = {XLEN{1'b0}};
        mem_rdata = {XLEN{1'b0}};
        mem_ready = 1'b0;
        opcode = 7'b0;
        funct3 = 3'b0;
        funct7 = 7'b0;
        rs1 = 5'b0;
        rs2 = 5'b0;
        rd = 5'b0;
        zimm = 5'b0;
        imm12 = 12'b0;
        imm20 = 20'b0;
        csr = 12'b0;
        shamt = 5;
        #10;
        aresetn = 1'b1;
    end
    endtask

    task teardown(msg="");
    begin
        #10;
    end
    endtask

    `TEST_SUITE("ALU Testsuite")

    `UNIT_TEST("LOAD Instructions")

        @(posedge aclk);
        alu_en = 1'b1;

        alu_instbus = {37'b0, 12'b1, 5'b0, 5'h2, 5'h1, 5'h0, 7'b0, `LB,`LOAD};
        @(posedge aclk);
        @(posedge aclk);
        mem_rdata = 'hA;
        mem_ready = 1;
        @(posedge aclk);
        mem_ready = 0;
        @(posedge aclk);
        @(posedge aclk);

        alu_instbus = {37'b0, 12'b1, 5'b0, 5'h2, 5'h1, 5'h0, 7'b0, `LH,`LOAD};
        @(posedge aclk);
        mem_rdata = 'hAB;
        mem_ready = 1;
        @(posedge aclk);
        mem_ready = 0;
        @(posedge aclk);
        @(posedge aclk);

        alu_instbus = {37'b0, 12'b1, 5'b0, 5'h2, 5'h1, 5'h0, 7'b0, `LW,`LOAD};
        @(posedge aclk);
        mem_rdata = 'hABCD;
        mem_ready = 1;
        @(posedge aclk);
        mem_ready = 0;
        @(posedge aclk);
        @(posedge aclk);

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
