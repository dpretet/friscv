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

    parameter CSR_DEPTH = 12;
    parameter ADDRW     = 16;
    parameter BOOT_ADDR =  0;
    parameter XLEN      = 32;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      inst_en;
    logic                      ebreak;
    logic [ADDRW        -1:0]  inst_addr;
    logic [XLEN         -1:0]  inst_rdata;
    logic                      inst_ready;
    logic                      proc_en;
    logic                      proc_ready;
    logic                      proc_empty;
    logic [`INST_BUS_W   -1:0] proc_instbus;
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
    logic [5             -1:0] rd;
    logic [12            -1:0] imm12;
    logic [20            -1:0] imm20;
    logic [4             -1:0] fenceinfo;

    logic [XLEN          -1:0] instructions[16-1:0];
    logic [XLEN          -1:0] data[16-1:0];
    logic [XLEN          -1:0] result[16-1:0];
    logic [ADDRW        -1:0]  inst_addr_r;

    friscv_rv32i_control
    #(
    CSR_DEPTH,
    ADDRW,
    BOOT_ADDR,
    XLEN
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    ebreak,
    inst_en,
    inst_addr,
    inst_rdata,
    inst_ready,
    proc_en,
    proc_ready,
    proc_empty,
    fenceinfo,
    proc_instbus,
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
        proc_ready = 1'b1;
        proc_empty = 1'b1;
        fenceinfo = 4'b0;
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
        repeat (3) @(posedge aclk);
    end
    endtask

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) inst_addr_r <= 'h0;
        else if (srst) inst_addr_r <= 'h0;
        else inst_addr_r <= inst_addr;
    end

    `TEST_SUITE("Control Testsuite")

    `UNIT_TEST("Verify the ISA's opcodes")

        @(posedge aclk);
        @(posedge aclk);

        `MSG("AUIPC");
        inst_rdata = 7'b0010111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("FENCE");
        inst_rdata = 7'b0001111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("JAL");
        inst_rdata = 7'b1101111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("JALR");
        inst_rdata = 7'b1100111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("BRANCHING");
        inst_rdata = 7'b1100011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("LOAD");
        inst_rdata = 7'b0000011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("ARITHMETIC REGISTER-to-REGISTER");
        inst_rdata = 7'b0100011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("ARITHMETIC IMMEDIATE");
        inst_rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("LUI");
        inst_rdata = 7'b0110011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("CSR");
        inst_rdata = 7'b1110011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

    `UNIT_TEST_END

    `UNIT_TEST("Verify invalid opcodes lead to failure")

        `MSG("INVALID");
        @(negedge aclk);
        inst_rdata = 7'b0000001;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

        `MSG("INVALID");
        @(negedge aclk);
        inst_rdata = 7'b0101001;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

        `MSG("INVALID");
        @(negedge aclk);
        inst_rdata = 7'b1111111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

        `MSG("INVALID");
        @(negedge aclk);
        inst_rdata = 7'b0000000;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue");

    `UNIT_TEST_END

    `UNIT_TEST("Check ALU/MEMFY is activated with valid opcodes")

        while (inst_en == 1'b0) @(posedge aclk);
        inst_ready = 1'b1;
        proc_ready = 1'b1;
        @(posedge aclk);

        `MSG("LOAD");
        inst_rdata = 7'b0000011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));

        `MSG("STORE");
        inst_rdata = 7'b0100011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));

        `MSG("AITHMETIC IMMEDIATE");
        inst_rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));

        `MSG("AITHMETIC REGISTER-to-REGISTER");
        inst_rdata = 7'b0110011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));


    `UNIT_TEST_END

    `UNIT_TEST("Check AUIPC opcode")

        while (inst_en == 1'b0) @(posedge aclk);

        `MSG("Zero move");
        inst_ready = 1'b1;
        inst_rdata = {20'b0, 5'b0, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4), "program counter must be 0x4");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == 32'h0), "rd must store 0x0");
        @(posedge aclk);

        `MSG("Move forward by 4 KB");
        inst_ready = 1'b1;
        inst_rdata = {20'h00001, 5'h0, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h8), "program counter must be 0x8");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == 32'h1004), "rd must store 0x1004");
        @(posedge aclk);

        `MSG("Move forward by 4 KB");
        inst_ready = 1'b1;
        inst_rdata = {20'h00001, 5'h3, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'hC), "program counter must be 0xC");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h3), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == 32'h1008), "rd must store pc");
        @(posedge aclk);

        `MSG("Move backward by 4 KB");
        inst_ready = 1'b1;
        inst_rdata = {20'hFFFFF, 5'h18, 7'b0010111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h10), "program counter must be0x10");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h18), "wrong rd target");
        `ASSERT((dut.ctrl_rd_val == 32'hFFFFF00C), "rd must store pc");

    `UNIT_TEST_END

    `UNIT_TEST("Check JAL opcode")

        while (inst_en == 1'b0) @(posedge aclk);
        @(posedge aclk);

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
        @(posedge aclk);

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
        @(posedge aclk);
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

    `UNIT_TEST("Verify LUI instruction")

        @(posedge aclk);

        rd = 5;
        imm12 = 12'b1;
        imm20 = 20'h98765;

        fork
        begin
            while (inst_en==1'b0) @ (posedge aclk);
            inst_ready = 1'b1;
            inst_rdata = {imm20, rd, `LUI};
            @(posedge aclk);
            inst_ready = 1'b0;
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
        end
        begin
            `MSG("Inspect ISA registers access");
            while(ctrl_rd_wr==1'b0) @ (posedge aclk);
            `ASSERT((ctrl_rd_addr==rd), "ALU doesn't target correct RD registers");
            `ASSERT((ctrl_rd_val=={imm20,12'b0}), "ALU doesn't store correct data in RD");
        end
        join

    `UNIT_TEST_END

    `UNIT_TEST("FENCE instructions")

        @(posedge aclk);
        @(posedge aclk);
        while (inst_en == 1'b0) @(posedge aclk);

        `MSG("FENCE move");
        inst_ready = 1'b1;
        inst_rdata = {20'b0, 5'b0, 7'b0001111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4), "FENCE - program counter must be 0x4");
        @(posedge aclk);

        `MSG("FENCE move but stalled by ALU/Memfy not ready");
        proc_ready = 1'b0;
        inst_ready = 1'b1;
        inst_rdata = {20'b0, 5'b0, 7'b0001111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h8), "FENCE - program counter must be 0x8");
        @(posedge aclk);

        `MSG("FENCE.I move");
        proc_ready = 1'b1;
        inst_ready = 1'b1;
        inst_rdata = {20'b1, 5'b0, 7'b0001111};
        @(posedge aclk);
        `ASSERT((dut.pc == 32'hC), "FENCE.I - program counter must be 0xC");
        @(posedge aclk);
        `CRITICAL("TODO: Check interleaving with processing instruction (or anyone else)");

    `UNIT_TEST_END

    `UNIT_TEST("ENV instructions - ECALL/EBREAK")

        while (inst_en == 1'b0) @(posedge aclk);

        `MSG("ECALL move");
        inst_ready = 1'b1;
        inst_rdata = {12'b0, 5'b0, 3'b0, 5'b0, 7'b1110011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4), "program counter must be 0x4");
        @(posedge aclk);

        `MSG("EBREAK move");
        inst_ready = 1'b1;
        inst_rdata = {12'b1, 5'b0, 3'b0, 5'b0, 7'b1110011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h8), "program counter must be 0x8");
        @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("ENV instructions - CSR")

        `CRITICAL("TODO: Complete all CSR instructions check");
        `CRITICAL("Check X0 as rs/rd");

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
