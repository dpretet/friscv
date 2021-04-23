/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps

module friscv_rv32i_decoder_testbench();

    `SVUT_SETUP

    parameter XLEN = 32;

    logic [XLEN -1:0] instruction;
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
    logic [6    -1:0] shamt;
    logic             auipc;
    logic             jal;
    logic             jalr;
    logic             branching;
    logic             system;
    logic             processing;
    logic             inst_error;
    logic [4    -1:0] pred;
    logic [4    -1:0] succ;
    logic             aclk;

    friscv_rv32i_decoder
    #(
    XLEN
    )
    dut
    (
    instruction,
    opcode,
    funct3,
    funct7,
    rs1,
    rs2,
    rd,
    zimm,
    imm12,
    imm20,
    csr,
    shamt,
    auipc,
    jal,
    jalr,
    branching,
    system,
    processing,
    inst_error,
    pred,
    succ
    );

    /// to create a clock:
    initial aclk = 0;
    always #2 aclk = ~aclk;

    /// to dump data for visualization:
    initial begin
         $dumpfile("friscv_rv32i_decoder_testbench.vcd");
         $dumpvars(0, friscv_rv32i_decoder_testbench);
    end

    task setup(msg="");
    begin
        instruction = 0;
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("Decoder Testsuite")

    `UNIT_TEST("Failling sintructions in c testsuite")

        @(posedge aclk);
        @(posedge aclk);
        instruction = 32'h00C12403;
        @(posedge aclk);
        @(posedge aclk);

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
