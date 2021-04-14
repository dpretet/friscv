// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 100 ps
`default_nettype none

/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"

module friscv_rv32i_control_unit_testbench();

    `SVUT_SETUP

    parameter ADDRW     = 16;
    parameter BOOT_ADDR =  0;
    parameter XLEN      = 32;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      inst_en;
    logic [ADDRW        -1:0]  inst_addr;
    logic [XLEN         -1:0]  inst_rdata;
    logic                      inst_ready;
    logic                      alu_en;
    logic                      alu_ready;
    logic                      alu_empty;
    logic [`ALU_INSTBUS_W-1:0] alu_instbus;
    logic [5             -1:0] ctrl_rs1_addr;
    logic [XLEN          -1:0] ctrl_rs1_val;
    logic [5             -1:0] ctrl_rs2_addr;
    logic [XLEN          -1:0] ctrl_rs2_val;
    logic                      ctrl_rd_wr;
    logic [5             -1:0] ctrl_rd_addr;
    logic [XLEN          -1:0] ctrl_rd_val;

    logic [32            -1:0] prev_pc;
    logic [32            -1:0] next_pc;
    logic [12            -1:0] offset;

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
    alu_empty,
    alu_instbus,
    ctrl_rs1_addr,
    ctrl_rs1_val,
    ctrl_rs2_addr,
    ctrl_rs2_val,
    ctrl_rd_wr,
    ctrl_rd_addr,
    ctrl_rd_val
    );

    /// An example to create a clock for icarus:
    initial aclk = 0;
    always #2 aclk = ~aclk;

    /// An example to dump data for visualization
    initial begin
        $dumpfile("friscv_rv32i_control_unit_testbench.vcd");
        $dumpvars(0, friscv_rv32i_control_unit_testbench);
    end

    task setup(msg="");
    begin
        aresetn = 1'b0;
        srst = 1'b0;
        alu_ready = 1'b1;
        alu_empty = 1'b1;
        inst_rdata = {XLEN{1'b0}};
        inst_ready = 1'b0;
        ctrl_rs1_val <= {XLEN{1'b0}};
        ctrl_rs2_val <= {XLEN{1'b0}};
        #10;
        aresetn = 1'b1;
    end
    endtask

    task teardown(msg="");
    begin
        #10;
    end
    endtask

    `TEST_SUITE("Control Testsuite")

    `UNIT_TEST("Verify the ISA's opcodes")

        inst_rdata = 7'b0010111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b1101111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b1100111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b1100011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b0000000;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b0000011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b0110111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b0100011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b0110011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        inst_rdata = 7'b1110011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

    `UNIT_TEST_END

    `UNIT_TEST("Verify invalid opcodes lead to failure")

        @(negedge aclk);
        inst_rdata = 7'b0000001;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

        @(negedge aclk);
        inst_rdata = 7'b0101001;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

        @(negedge aclk);
        inst_rdata = 7'b1111111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

    `UNIT_TEST_END

    `UNIT_TEST("Check ALU is activated with valid opcodes")

        while (inst_en == 1'b0) @(posedge aclk);
        inst_ready = 1'b1;
        alu_ready = 1'b1;

        inst_rdata = 7'b0000011;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

        inst_rdata = 7'b0110111;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

        inst_rdata = 7'b0100011;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

        inst_rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

        inst_rdata = 7'b0110011;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

        inst_rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

        inst_rdata = 7'b1110011;
        @(posedge aclk);
        `ASSERT((dut.alu_en==1'b1));

    `UNIT_TEST_END

    `UNIT_TEST("Check AUIPC opcode")

        while (inst_en == 1'b0) @(posedge aclk);

        `MSG("Zero move");
        inst_ready = 1'b1;
        inst_rdata = {25'b0, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == dut.pc), "rd must store pc");
        @(posedge aclk);

        `MSG("Move forward by 4 KB");
        inst_ready = 1'b1;
        inst_rdata = {20'h00001, 5'h0, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h1000), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == dut.pc), "rd must store pc");
        @(posedge aclk);

        `MSG("Move forward by 4 KB");
        inst_ready = 1'b1;
        inst_rdata = {20'h00001, 5'h3, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h2000), "program counter must be 8KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h3), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == dut.pc), "rd must store pc");
        @(posedge aclk);

        `MSG("Move backward by 4 KB");
        inst_ready = 1'b1;
        inst_rdata = {20'hFFFFF, 5'h18, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h1000), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h18), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == dut.pc), "rd must store pc");

    `UNIT_TEST_END

    `UNIT_TEST("Check JAL opcode")

        while (inst_en == 1'b0) @(posedge aclk);

        `MSG("Jump +0, rd=x0");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {25'b0, 7'b1101111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0), "rd must target x0");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +0, rd=x3");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {25'h3, 7'b1101111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h3), "rd must target x3");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +2048, rd=x5");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {{1'b0, 10'b0, 1'b1, 8'b0}, 5'h5, 7'b1101111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h800), "program counter must be 2KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h5), "rd must target x3");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");

    `UNIT_TEST_END

    `UNIT_TEST("Check JALR opcode")

        while (inst_en == 1'b0) @(posedge aclk);

        `MSG("Jump +0, rd=x0");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {25'b0, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0));
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +4KB, rd=x1");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {12'h0, 5'h0, 3'h0, 5'h1, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h1), "rd must target x1");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +4KB, rd=x2");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {12'h1, 5'h0, 3'h0, 5'h2, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h2), "rd must target x2");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +4KB, rd=x2");
        prev_pc = dut.pc + 4;
        inst_ready = 1'b1;
        inst_rdata = {12'h2, 5'h0, 3'h0, 5'h2, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h2), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h2), "rd must target x2");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");

    `UNIT_TEST_END

    `UNIT_TEST("Check all branching")

        while (inst_en == 1'b0) @(posedge aclk);
        inst_ready = 1'b1;

        `MSG("BEQ is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        inst_rdata = {17'h0, `BEQ, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h10), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BEQ is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'h00000000;
        inst_rdata = {17'h0, `BEQ, 5'h2, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h14), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BNE is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BNE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h24), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BNE is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        inst_rdata = {17'h0, `BNE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h28), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BLT is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BLT, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h38), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BLT is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        inst_rdata = {17'h0, `BLT, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h3C), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BGE is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h00FFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BGE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4C), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BGE is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0FFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BGE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h5C), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BGE is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0F0FFFFF;
        ctrl_rs2_val = 32'h0FFFFFFF;
        inst_rdata = {17'h0, `BGE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h60), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BLTU is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0000FFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BLTU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h70), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BLTU is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        inst_rdata = {17'h0, `BLTU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h74), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BGEU is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0FFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BGEU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h84), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BGEU is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h00FFFFF0;
        ctrl_rs2_val = 32'h00FFFFFF;
        inst_rdata = {17'h0, `BGEU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h88), "program counter must move forward by 16 bytes");

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
