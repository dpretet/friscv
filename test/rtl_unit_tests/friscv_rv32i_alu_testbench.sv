/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

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
    logic [5             -1:0] logics_rs1_addr;
    logic [XLEN          -1:0] logics_rs1_val;
    logic [5             -1:0] logics_rs2_addr;
    logic [XLEN          -1:0] logics_rs2_val;
    logic [5             -1:0] logics_rd_addr;
    logic [XLEN          -1:0] logics_rd_val;
    logic                      mem_en;
    logic                      mem_wr;
    logic [ADDRW         -1:0] mem_addr;
    logic [XLEN          -1:0] mem_wdata;
    logic [XLEN/8        -1:0] mem_strb;
    logic [XLEN          -1:0] mem_rdata;
    logic                      mem_ready;

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
    logics_rs1_addr,
    logics_rs1_val,
    logics_rs2_addr,
    logics_rs2_val,
    logics_rd_addr,
    logics_rd_val,
    mem_en,
    mem_wr,
    mem_addr,
    mem_wdata,
    mem_strb,
    mem_rdata,
    mem_ready
    );

    /// to create a clock:
    /// initial aclk = 0;
    always #1 aclk = ~aclk;

    /// to dump data for visualization:
    /// initial begin
    ///     $dumpfile("waveform.vcd");
    ///     $dumpvars(0, friscv_rv32i_alu_testbench);
    /// end

    task setup(msg="");
    begin
        /// setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("SUITE_NAME")

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

    `UNIT_TEST("TEST_NAME")

        /// Describe here the testcase scenario
        ///
        /// Because SVUT uses long nested macros, it's possible
        /// some local variable declaration leads to compilation issue.
        /// You should declare your variables after the IOs declaration to avoid that.

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
