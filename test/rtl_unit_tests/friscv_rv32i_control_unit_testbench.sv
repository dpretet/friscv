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
    // Address bus width defined for both control and AXI4 address signals
    parameter AXI_ADDR_W = 8;
    // AXI ID width; setup by default to 8 and unused
    parameter AXI_ID_W = 8;
    // AXI4 data width; independant of control unit width
    parameter AXI_DATA_W = XLEN;
    // Number of outstanding requests supported
    parameter OSTDREQ_NUM = 16;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      ebreak;
    logic                      arvalid;
    logic                      arready;
    logic [AXI_ADDR_W    -1:0] araddr;
    logic [3             -1:0] arprot;
    logic [AXI_ID_W      -1:0] arid;
    logic                      rvalid;
    logic                      rready;
    logic [AXI_ID_W      -1:0] rid;
    logic [2             -1:0] rresp;
    logic [AXI_DATA_W    -1:0] rdata;
    logic                      proc_en;
    logic                      proc_ready;
    logic                      proc_empty;
    logic [`INST_BUS_W   -1:0] proc_instbus;
    logic                      csr_en;
    logic                      csr_ready;
    logic [`INST_BUS_W   -1:0] csr_instbus;
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
    logic [ADDRW        -1:0]  araddr_r;

    friscv_rv32i_control
    #(
        XLEN,
        AXI_ADDR_W,
        AXI_ID_W,
        AXI_DATA_W,
        OSTDREQ_NUM,
        BOOT_ADDR
    )
    dut
    (
        aclk,
        aresetn,
        srst,
        ebreak,
        arvalid,
        arready,
        araddr,
        arprot,
        arid,
        rvalid,
        rready,
        rid,
        rresp,
        rdata,
        proc_en,
        proc_ready,
        proc_empty,
        fenceinfo,
        proc_instbus,
        csr_en,
        csr_ready,
        csr_instbus,
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
        csr_ready = 1'b1;
        rdata = {XLEN{1'b0}};
        rresp = 2'b0;
        arready = 1'b0;
        rvalid = 1'b0;
        ctrl_rs1_val <= {XLEN{1'b0}};
        ctrl_rs2_val <= {XLEN{1'b0}};
        #10;
        aresetn = 1'b1;
        arready = 1'b1;
    end
    endtask

    assign rid = arid;

    task teardown(msg="");
    begin
        repeat (3) @(posedge aclk);
    end
    endtask

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) araddr_r <= 'h0;
        else if (srst) araddr_r <= 'h0;
        else araddr_r <= araddr;
    end

    `TEST_SUITE("Control Testsuite")

    `UNIT_TEST("Verify the ISA's opcodes")

        @(posedge aclk);
        @(posedge aclk);
        rvalid = 1'b1;

        `MSG("AUIPC");
        rdata = 7'b0010111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("FENCE");
        rdata = 7'b0001111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("JAL");
        rdata = 7'b1101111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("JALR");
        rdata = 7'b1100111;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("BRANCHING");
        rdata = 7'b1100011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("LOAD");
        rdata = 7'b0000011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("ARITHMETIC REGISTER-to-REGISTER");
        rdata = 7'b0100011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("ARITHMETIC IMMEDIATE");
        rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("LUI");
        rdata = 7'b0110011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

        @(posedge aclk);

        `MSG("CSR");
        rdata = 7'b1110011;
        @(posedge aclk);
        `ASSERT((dut.inst_error==1'b0));

    `UNIT_TEST_END

    `UNIT_TEST("Verify invalid opcodes lead to failure")

        rvalid = 1'b1;

        `MSG("INVALID");
        @(negedge aclk);
        rdata = 7'b0000001;
        while (dut.pull_inst==1'b0) @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue with 0000001");

        `MSG("INVALID");
        @(negedge aclk);
        rdata = 7'b0101001;
        while (dut.pull_inst==1'b0) @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue with 0000001");

        `MSG("INVALID");
        @(negedge aclk);
        rdata = 7'b1111111;
        while (dut.pull_inst==1'b0) @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue with 0000001");

        `MSG("INVALID");
        @(negedge aclk);
        rdata = 7'b0000000;
        while (dut.pull_inst==1'b0) @(posedge aclk);
        `ASSERT((dut.inst_error==1'b1), "should detect an issue with 0000001");

    `UNIT_TEST_END

    `UNIT_TEST("Check ALU/MEMFY is activated with valid opcodes")

        while (arvalid == 1'b0) @(posedge aclk);
        rvalid = 1'b1;
        proc_ready = 1'b1;
        @(posedge aclk);

        `MSG("LOAD");
        rdata = 7'b0000011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));

        `MSG("STORE");
        rdata = 7'b0100011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));

        `MSG("AITHMETIC IMMEDIATE");
        rdata = 7'b0010011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));

        `MSG("AITHMETIC REGISTER-to-REGISTER");
        rdata = 7'b0110011;
        @(posedge aclk);
        `ASSERT((dut.proc_en==1'b1));


    `UNIT_TEST_END

    `UNIT_TEST("Check AUIPC opcode")

        while (arvalid == 1'b0) @(posedge aclk);
        @(posedge aclk);

        fork
        begin
            @(negedge aclk)
            rvalid = 1'b1;
            rdata = {20'b0, 5'b0, 7'b010111};
            @(negedge aclk);
            rdata = {20'h00001, 5'h0, 7'b0010111};
            @(negedge aclk);
            rdata = {20'h00001, 5'h3, 7'b0010111};
            @(negedge aclk);
            rdata = {20'hFFFFF, 5'h18, 7'b0010111};
            @(negedge aclk);
            rvalid = 1'b0;
        end
        begin
            while (dut.ctrl_rd_wr==1'b0) @(negedge aclk);
            // @(negedge aclk)
            `MSG("AUIPC Imm. +0KB RD=0x0");
            `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            `ASSERT((dut.ctrl_rd_addr == 32'h0), "wrong rd target");
            `ASSERT((dut.ctrl_rd_val == 32'h0), "rd must store 0x0");
            // @(posedge aclk);

            @(negedge aclk)
            `MSG("AUIPC Imm. +4KB RD=0x0");
            `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            `ASSERT((dut.ctrl_rd_addr == 32'h0), "wrong rd target");
            `ASSERT((dut.ctrl_rd_val == 32'h1004), "rd must store 0x1004");
            // @(posedge aclk);

            @(negedge aclk)
            `MSG("AUIPC Imm. +4KB RD=0x3");
            `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            `ASSERT((dut.ctrl_rd_addr == 32'h3), "wrong rd target");
            `ASSERT((dut.ctrl_rd_val == 32'h1008), "rd must store pc");
            // @(posedge aclk);

            @(negedge aclk)
            `MSG("AUIPC Imm. -4KB RD=0x18");
            `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            `ASSERT((dut.ctrl_rd_addr == 32'h18), "wrong rd target");
            `ASSERT((dut.ctrl_rd_val == 32'hFFFFF00C), "rd must store pc");
            @(posedge aclk);
        end
        join

    `UNIT_TEST_END

    `UNIT_TEST("Check JAL opcode")

        while (arvalid == 1'b0) @(posedge aclk);
        @(posedge aclk);

        fork
        begin
            @(negedge aclk)
            rvalid = 1'b1;
            // rdata = {25'b0, 7'b1101111};
            // @(negedge aclk)
            // rdata = {25'h3, 7'b1101111};
            // @(negedge aclk)
            rdata = {{1'b0, 10'b0, 1'b1, 8'b0}, 5'h5, 7'b1101111};
            @(negedge aclk)
            rvalid = 1'b0;
        end
        begin
            while (dut.ctrl_rd_wr==1'b0) @(negedge aclk);
            // `MSG("Jump +0, rd=x0");
            // prev_pc = dut.pc + 4;
            // @(negedge aclk);
            // `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
            // `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            // `ASSERT((dut.ctrl_rd_addr == 32'h0), "rd must target x0");
            // `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");

            // `MSG("Jump +0, rd=x3");
            // prev_pc = dut.pc + 4;
            // @(negedge aclk);
            // `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
            // `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            // `ASSERT((dut.ctrl_rd_addr == 32'h3), "rd must target x3");
            // `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");

            `MSG("Jump +2048, rd=x5");
            prev_pc = dut.pc + 4;
            @(negedge aclk);
            `ASSERT((dut.pc == 32'h800), "program counter must be 2KB");
            `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
            `ASSERT((dut.ctrl_rd_addr == 32'h5), "rd must target x3");
            `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        end
        join


    `UNIT_TEST_END

/*
    `UNIT_TEST("Check JALR opcode")

        while (arvalid == 1'b0) @(posedge aclk);
        @(posedge aclk);

        `MSG("Jump +0, rd=x0");
        prev_pc = dut.pc + 4;
        rvalid = 1'b1;
        rdata = {25'b0, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must keep 0 value");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h0));
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +4KB, rd=x1");
        prev_pc = dut.pc + 4;
        rvalid = 1'b1;
        rdata = {12'h0, 5'h0, 3'h0, 5'h1, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h1), "rd must target x1");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +4KB, rd=x2");
        prev_pc = dut.pc + 4;
        rvalid = 1'b1;
        rdata = {12'h1, 5'h0, 3'h0, 5'h2, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h0), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h2), "rd must target x2");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");
        @(posedge aclk);

        `MSG("Jump +4KB, rd=x2");
        prev_pc = dut.pc + 4;
        rvalid = 1'b1;
        rdata = {12'h2, 5'h0, 3'h0, 5'h2, 7'b1100111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h2), "program counter must be 4KB");
        `ASSERT((dut.ctrl_rd_wr == 1'b1), "rd is not under write");
        `ASSERT((dut.ctrl_rd_addr == 32'h2), "rd must target x2");
        `ASSERT((dut.ctrl_rd_val == prev_pc), "rd must store pc(-1)+4");

    `UNIT_TEST_END

    `UNIT_TEST("Check all branching")

        while (arvalid == 1'b0) @(posedge aclk);
        @(posedge aclk);
        rvalid = 1'b1;

        `MSG("BEQ is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        rdata = {17'h0, `BEQ, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h10), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BEQ is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'h00000000;
        rdata = {17'h0, `BEQ, 5'h2, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h14), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BNE is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BNE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h24), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BNE is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        rdata = {17'h0, `BNE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h28), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BLT is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BLT, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h38), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BLT is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        rdata = {17'h0, `BLT, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h3C), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BGE is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h00FFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BGE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4C), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BGE is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0FFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BGE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h5C), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BGE is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0F0FFFFF;
        ctrl_rs2_val = 32'h0FFFFFFF;
        rdata = {17'h0, `BGE, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h60), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BLTU is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0000FFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BLTU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h70), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BLTU is false");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'hFFFFFFFF;
        ctrl_rs2_val = 32'hFFFFFFFF;
        rdata = {17'h0, `BLTU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h74), "program counter must move forward by 4 bytes");
        @(posedge aclk);

        `MSG("BGEU is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h0FFFFFFF;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BGEU, 5'h10, 7'b1100011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h84), "program counter must move forward by 16 bytes");
        @(posedge aclk);

        `MSG("BGEU is true");
        prev_pc = dut.pc + 4;
        next_pc = dut.pc + offset;
        ctrl_rs1_val = 32'h00FFFFF0;
        ctrl_rs2_val = 32'h00FFFFFF;
        rdata = {17'h0, `BGEU, 5'h10, 7'b1100011};
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
            while (arvalid==1'b0) @ (posedge aclk);
            rvalid = 1'b1;
            rdata = {imm20, rd, `LUI};
            @(posedge aclk);
            rvalid = 1'b0;
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
        while (arvalid == 1'b0) @(posedge aclk);

        `MSG("FENCE move");
        rvalid = 1'b1;
        rdata = {20'b0, 5'b0, 7'b0001111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4), "FENCE - program counter must be 0x4");
        @(posedge aclk);

        `MSG("FENCE move but stalled by ALU/Memfy not ready");
        proc_ready = 1'b0;
        rvalid = 1'b1;
        rdata = {20'b0, 5'b0, 7'b0001111};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h8), "FENCE - program counter must be 0x8");
        @(posedge aclk);

        `MSG("FENCE.I move");
        proc_ready = 1'b1;
        rvalid = 1'b1;
        rdata = {20'b1, 5'b0, 7'b0001111};
        @(posedge aclk);
        `ASSERT((dut.pc == 32'hC), "FENCE.I - program counter must be 0xC");
        @(posedge aclk);
        `CRITICAL("TODO: Check interleaving with processing instruction (or anyone else)");

    `UNIT_TEST_END

    `UNIT_TEST("ENV instructions - ECALL/EBREAK")

        while (arvalid == 1'b0) @(posedge aclk);

        `MSG("ECALL move");
        rvalid = 1'b1;
        rdata = {12'b0, 5'b0, 3'b0, 5'b0, 7'b1110011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h4), "program counter must be 0x4");
        @(posedge aclk);

        `MSG("EBREAK move");
        rvalid = 1'b1;
        rdata = {12'b1, 5'b0, 3'b0, 5'b0, 7'b1110011};
        @(negedge aclk);
        `ASSERT((dut.pc == 32'h8), "program counter must be 0x8");
        @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("ENV instructions - CSR")

        `CRITICAL("TODO: Complete all CSR instructions check");
        `CRITICAL("Check X0 as rs/rd");

    `UNIT_TEST_END
*/
    `TEST_SUITE_END

endmodule
