/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps

module friscv_rv32i_control_testbench();

    `SVUT_SETUP

    parameter             ADDRW     = 16;
    parameter [ADDRW-1:0] BOOT_ADDR = {ADDRW{1'b0}};
    parameter             XLEN      = 32;

    logic             aclk;
    logic             aresetn;
    logic             srst;
    logic             inst_en;
    logic [ADDRW-1:0] inst_addr;
    logic [XLEN -1:0] inst_rdata;
    logic             inst_ready;
    logic             alu_en;
    logic             alu_ready;
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
    logic [5    -1:0] regs_rs1_addr;
    logic [XLEN -1:0] regs_rs1_val;
    logic [5    -1:0] regs_rs2_addr;
    logic [XLEN -1:0] regs_rs2_val;

    friscv_rv32i_control
    #(
    ADDRW,
    BOOT_ADDR,
    XLEN
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    inst_en,
    inst_addr,
    inst_rdata,
    inst_ready,
    alu_en,
    alu_ready,
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
    regs_rs1_addr,
    regs_rs1_val,
    regs_rs2_addr,
    regs_rs2_val
    );

    /// An example to create a clock for icarus:
    /// initial aclk = 0;
    /// always #2 aclk <= ~aclk;

    /// An example to dump data for visualization
    /// initial begin
    ///     $dumpfile("waveform.vcd");
    ///     $dumpvars(0, friscv_rv32i_control_testbench);
    /// end

    task setup(msg="");
    begin
        aresetn = 1'b0;
        srst = 1'b0;
        alu_ready = 1'b0;
        inst_rdata = {XLEN{1'b0}};
        inst_ready = 1'b0;
        #10;
        aresetn = 1'b1;
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("FIRST_ONE")

    ///    Available macros:"
    ///
    ///    - `MSG("message"):       Print a raw white message
    ///    - `INFO("message"):      Print a blue message with INFO: prefix
    ///    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    ///    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    ///    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
    ///    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    ///
    ///    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    ///    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    ///    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    ///    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    ///    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    ///    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    ///
    ///    Available flag:
    ///
    ///    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    `UNIT_TEST("TESTNAME")

        /// Describe here the testcase scenario
        ///
        /// Because SVUT uses long nested macros, it's possible
        /// some local variable declaration leads to compilation issue.
        /// You should declare your variables after the IOs declaration to avoid that.

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
