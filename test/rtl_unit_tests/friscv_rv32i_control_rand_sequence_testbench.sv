// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 100 ps
`default_nettype none

/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "friscv_h.sv"

module friscv_rv32i_control_rand_sequence_testbench();

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
    logic [`ALU_INSTBUS_W-1:0] alu_instbus;
    logic [5             -1:0] ctrl_rs1_addr;
    logic [XLEN          -1:0] ctrl_rs1_val;
    logic [5             -1:0] ctrl_rs2_addr;
    logic [XLEN          -1:0] ctrl_rs2_val;
    logic                      ctrl_rd_wr;
    logic [5             -1:0] ctrl_rd_addr;
    logic [XLEN          -1:0] ctrl_rd_val;

    parameter                  CLK_PERIOD = 2;
    parameter                  MAX_RUN = 150;
    integer                    SEED = 0;
    integer                    instructions[MAX_RUN-1:0];
    integer unsigned           alu_latency;
    integer                    inst_latency;
    logic [XLEN          -1:0] driver_inst;
    logic [XLEN          -1:0] consumer_inst;
    logic [ADDRW         -1:0] last_addr;

    integer                    ialu;
    integer                    iinst;

    parameter LOAD     = 0;
    parameter STORE    = 1;
    parameter ARITH    = 2;
    parameter LOGIC    = 3;
    parameter AUIPC    = 4;
    parameter JAL      = 5;
    parameter JALR     = 6;
    parameter BRANCH   = 7;

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
    always #(CLK_PERIOD/2) aclk = ~aclk;

    /// An example to dump data for visualization
    initial begin
        $dumpfile("friscv_rv32i_control_rand_sequence_testbench.vcd");
        $dumpvars(0, friscv_rv32i_control_rand_sequence_testbench);
    end

    initial begin
        for (int i=0;i<MAX_RUN;i=i+1) begin
            instructions[i] = $urandom(SEED) % 7;
        end
    end

    task setup(msg="");
    begin
        aresetn = 1'b0;
        srst = 1'b0;
        alu_ready = 1'b0;
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

    function [XLEN-1:0] get_instruction(input int i);
    begin
        if (i == LOAD) begin
            `MSG("LOAD");
            return {17'b0, i[2:0], 5'b0, `LOAD};
        end else if (i == STORE) begin
            `MSG("STORE");
            return {17'b0, i[2:0], 5'b0, `STORE};
        end else if (i == ARITH) begin
            `MSG("ARITH");
            return {20'b0, i[2:0], 5'b0, `ARITH};
        end else if (i == LOGIC) begin
            `MSG("LOGIC");
            return {20'b0, i[2:0], 5'b0, `LOGIC};
        end else if (i == AUIPC) begin
            `MSG("AUIPC");
            return {20'h1, 5'h10, `AUIPC};
        end else if (i == JAL) begin
            `MSG("JAL");
            return {{1'b0, 10'b0, 1'b1, 8'b0}, 5'h0, `JAL};
        end else if (i == JALR) begin
            `MSG("JALR");
            return {12'h400, 5'h0, 3'h0, 5'h1, `JALR};
        end else if (i == BRANCH) begin
            `MSG("BRANCH");
            return {17'h0, i[2:0], 5'h10, `BRANCH};
        end else begin
            `MSG("SYSTEM");
            return {XLEN{1'b0}};
        end
    end
    endfunction

    task moveToRisingEdge;
    begin
        @(negedge aclk);
        #((CLK_PERIOD/2)-0.1);
    end
    endtask

    task moveToFallingEdge;
    begin
        @(posedge aclk);
        #((CLK_PERIOD/2)-0.1);
    end
    endtask

    task moveToALURisingEdge;
    begin
        while (alu_en == 1'b0) begin
            moveToRisingEdge;
        end
    end
    endtask

    task moveToALUFallingEdge;
    begin
        while (alu_en == 1'b0) begin
            moveToFallingEdge;
        end
    end
    endtask

    always @ (posedge aclk) begin
        if (aresetn==1'b0) last_addr <= 0;
        else if (srst) last_addr <= 0;
        else last_addr <= inst_addr;
    end

    `TEST_SUITE("Control Testsuite")

    `UNIT_TEST("Drives the control unit and check it jumps and processes correctly")

        alu_ready = 1'b0;
        inst_ready = 1'b0;

        fork
            begin : INSTRUCTION_DRIVER

                inst_latency = 0;
                // Wait for the control unit fetchs an instruction
                while (inst_en == 1'b0) @(posedge aclk);

                for (iinst=0; iinst<MAX_RUN; iinst=iinst+1) begin

                    `INFO("INST: Drive a new instruction");
                    $display("i=%d", iinst);
                    driver_inst = get_instruction(instructions[iinst]);
                    $display("INST: instruction=%x", driver_inst);

                    inst_ready = 1'b1;
                    inst_rdata = driver_inst;

                    if (instructions[iinst] == AUIPC || instructions[iinst] == BRANCH ||
                        instructions[iinst] == JAL  || instructions[iinst] == JALR)
                    begin
                        // move after the edge to check value propagated
                        @(negedge aclk);

                        `MSG("INST: Control is jumping/branching");
                        if (instructions[iinst] == JALR) begin
                            `ASSERT((inst_addr=='h100), "JALR should reach 0x100");
                            `ASSERT((((last_addr<<2) + 3'h4) == ctrl_rd_val), "RD should receive PC+4");
                        end
                        if (instructions[iinst] == JAL) begin
                            `ASSERT((inst_addr==(last_addr+'h200)), "JAL must move forward by 0x200");
                            `ASSERT((((last_addr<<2) + 3'h4) == ctrl_rd_val), "RD should receive PC+4");
                        end
                        if (instructions[iinst] == AUIPC) begin
                            `ASSERT((inst_addr==(last_addr+'h400)), "AUIPC must move forward by 0x400");
                            `ASSERT(((inst_addr<<2) == ctrl_rd_val), "RD should receive PC+4");
                        end
                    end

                    do begin
                        @(posedge aclk);
                    end
                    while (inst_en==1'b0);

                end
                inst_ready = 1'b0;
            end
            begin: ALU_CONSUMER
                alu_latency = 1;
                alu_ready = 1'b1;
                for (ialu=0; ialu<MAX_RUN; ialu=ialu+1) begin

                    if (instructions[ialu] == LOGIC || instructions[ialu] == ARITH ||
                        instructions[ialu] == LOAD  || instructions[ialu] == STORE)
                    begin

                        // TODO: Introduce random latency when asserting
                        // alu_ready
                        while (alu_en == 1'b0) @ (posedge aclk);
                        alu_ready = 1;

                        `INFO("Consume an ALU instruction");
                        $display("ALU: i=%d", ialu);
                        consumer_inst = get_instruction(instructions[ialu]);
                        $display("ALU: INST consumed: %x - %x", consumer_inst, {consumer_inst[14:12], consumer_inst[6:0]});
                        $display("ALU: ALU read: %x", alu_instbus[9:0]);

                        if (instructions[ialu] == LOGIC)
                            `ASSERT((alu_instbus[9:0] === {consumer_inst[14:12], consumer_inst[6:0]}), "LOGIC");

                        if (instructions[ialu] == ARITH)
                            `ASSERT((alu_instbus[9:0] === {consumer_inst[14:12], consumer_inst[6:0]}), "ARITH");

                        if (instructions[ialu] == LOAD)
                            `ASSERT((alu_instbus[9:0] === {consumer_inst[14:12], consumer_inst[6:0]}), "LOAD");

                        if (instructions[ialu] == STORE)
                            `ASSERT((alu_instbus[9:0] === {consumer_inst[14:12], consumer_inst[6:0]}), "STORE");

                        if (alu_instbus[9:0] === {consumer_inst[14:12], consumer_inst[6:0]})
                            `SUCCESS("ALU: ALU correctly activated");

                        @(posedge aclk);

                    end
                end
            end
            join_any
            // join

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
