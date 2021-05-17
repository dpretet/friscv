/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"

`timescale 1 ns / 1 ps

module friscv_rv32i_alu_testbench();

    `SVUT_SETUP

    parameter XLEN  = 32;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      alu_en;
    logic                      alu_ready;
    logic                      alu_empty;
    logic [`INST_BUS_W-1:0] alu_instbus;
    logic [5             -1:0] alu_rs1_addr;
    logic [XLEN          -1:0] alu_rs1_val;
    logic [5             -1:0] alu_rs2_addr;
    logic [XLEN          -1:0] alu_rs2_val;
    logic                      alu_rd_wr;
    logic [5             -1:0] alu_rd_addr;
    logic [XLEN          -1:0] alu_rd_val;
    logic [XLEN/8        -1:0] alu_rd_strb;

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

    logic [12            -1:0] offset;
    logic [`INST_BUS_W-1:0] instructions[16-1:0];
    logic [`INST_BUS_W-1:0] insts_load[16-1:0];
    logic [`INST_BUS_W-1:0] insts_store[16-1:0];
    logic [`INST_BUS_W-1:0] insts_lui[16-1:0];
    logic [`INST_BUS_W-1:0] instruction;
    logic [XLEN       -1:0] datas[16-1:0];
    logic [XLEN       -1:0] rs1_data[16-1:0];
    logic [XLEN       -1:0] rs2_data[16-1:0];
    logic [XLEN       -1:0] results[16-1:0];

    integer                    timeout;

    friscv_rv32i_alu
    #(
    XLEN
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    alu_en,
    alu_ready,
    alu_empty,
    alu_instbus,
    alu_rs1_addr,
    alu_rs1_val,
    alu_rs2_addr,
    alu_rs2_val,
    alu_rd_wr,
    alu_rd_addr,
    alu_rd_val,
    alu_rd_strb
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
        alu_instbus = {`INST_BUS_W{1'b0}};
        alu_rs1_val = {XLEN{1'b0}};
        alu_rs2_val = {XLEN{1'b0}};
        // mem_rdata = {XLEN{1'b0}};
        // mem_ready = 1'b0;
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

    task drive_i_arith;
        input [`INST_BUS_W-1:0] instructions;
        input [XLEN          -1:0] rs1_data;
        input [XLEN          -1:0] results;
        input [XLEN          -1:0] _rd;
    begin
        fork
        begin
            while(alu_ready==1'b0) @ (posedge aclk);
            `MSG("Source an instruction:");
            $display("%x", instructions);
            alu_en = 1'b1;
            alu_instbus = instructions;
            alu_rs1_val = rs1_data;
            @(posedge aclk);
            alu_en = 1'b0;
            @(posedge aclk);
        end
        begin
            while(alu_rd_wr==1'b0) @ (posedge aclk);
            @(negedge aclk);
            `MSG("Inspect ISA registers access");
            $display("i=%d", _rd);
            `ASSERT((alu_rd_addr==_rd), "ALU doesn't access the correct rd register")
            `ASSERT((alu_rd_val==results), "computation went wrong");
            `ASSERT((alu_rd_strb==4'b1111), "ALU should write a complete word (STRB=4'1111)");
            @(posedge aclk);
        end
        join
    end
    endtask

    task drive_r_arith;
        input [`INST_BUS_W-1:0] instructions;
        input [XLEN          -1:0] rs1_data;
        input [XLEN          -1:0] rs2_data;
        input [XLEN          -1:0] results;
        input [XLEN          -1:0] _rd;
    begin
        fork
        begin
            while(alu_ready==1'b0) @ (posedge aclk);
            `MSG("Source an instruction:");
            $display("%x", instructions);
            alu_en = 1'b1;
            alu_instbus = instructions;
            alu_rs1_val = rs1_data;
            alu_rs2_val = rs2_data;
            @(posedge aclk);
            alu_en = 1'b0;
            @(posedge aclk);
        end
        begin
            while(alu_rd_wr==1'b0) @ (posedge aclk);
            @(negedge aclk);
            `MSG("Inspect ISA registers access");
            $display("i=%d", _rd);
            `ASSERT((alu_rd_addr==_rd), "ALU doesn't access the correct rd register")
            `ASSERT((alu_rd_val==results), "computation went wrong");
            `ASSERT((alu_rd_strb==4'b1111), "ALU should write a complete word (STRB=4'1111)");
            @(posedge aclk);
        end
        join
    end
    endtask

    `TEST_SUITE("ALU Testsuite")


    `UNIT_TEST("Verify ADDI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {37'b0, 12'h0, 5'b0, 5'h0, rs2, rs1, 7'b0, `ADDI, `I_ARITH};
        instructions[1] = {37'b0, 12'hFFF, 5'b0, 5'h1, rs2, rs1, 7'b0, `ADDI, `I_ARITH};
        instructions[2] = {37'b0, 12'h1, 5'b0, 5'h2, rs2, rs1, 7'b0, `ADDI, `I_ARITH};
        instructions[3] = {37'b0, 12'hFFF, 5'b0, 5'h3, rs2, rs1, 7'b0, `ADDI, `I_ARITH};
        instructions[4] = {37'b0, 12'h1, 5'b0, 5'h4, rs2, rs1, 7'b0, `ADDI, `I_ARITH};
        datas[0] = 'h0;
        datas[1] = 'h1;
        datas[2] = 'h080F4321;
        datas[3] = 'h80543210;
        datas[4] = 'h7FFFFFFF;
        results[0] = 'h0;
        results[1] = 'h0;
        results[2] = 'h080F4322;
        results[3] = 'h8054320F;
        results[4] = 'h80000000;

        @(posedge aclk);

        `MSG("Start to test ADDI instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SLTI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {37'b0, 12'h2, 5'b0, 5'h0, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[1] = {37'b0, 12'h2, 5'b0, 5'h1, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[2] = {37'b0, 12'h2, 5'b0, 5'h2, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        datas[0] = 'h1;
        datas[1] = 'h2;
        datas[2] = 'h3;
        results[0] = 'h1;
        results[1] = 'h0;
        results[2] = 'h0;
        // RS1 <, <=, > when negative
        instructions[3] = {37'b0, 12'hFFD, 5'b0, 5'h3, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[4] = {37'b0, 12'hFFD, 5'b0, 5'h4, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[5] = {37'b0, 12'hFFD, 5'b0, 5'h5, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        datas[3] = 'hFFFFFFFC;
        datas[4] = 'hFFFFFFFD;
        datas[5] = 'hFFFFFFFE;
        results[3] = 'h1;
        results[4] = 'h0;
        results[5] = 'h0;
        // RS1 <, <=, > when around zero
        instructions[6] = {37'b0, 12'h0, 5'b0, 5'h6, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[7] = {37'b0, 12'h0, 5'b0, 5'h7, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[8] = {37'b0, 12'h0, 5'b0, 5'h8, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        datas[6] = 'hFFFFFFFF;
        datas[7] = 'h0;
        datas[8] = 'h10;
        results[6] = 'h1;
        results[7] = 'h0;
        results[8] = 'h0;

        `MSG("Start to test SLTI instruction");
        @(posedge aclk);

        for (int i=0;i<9;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");
    `UNIT_TEST_END

    `UNIT_TEST("Verify SLTIU instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {37'b0, 12'h2, 5'b0, 5'h0, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[1] = {37'b0, 12'h2, 5'b0, 5'h1, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        instructions[2] = {37'b0, 12'h2, 5'b0, 5'h2, rs2, rs1, 7'b0, `SLTI, `I_ARITH};
        datas[0] = 'h1;
        datas[1] = 'h2;
        datas[2] = 'h3;
        results[0] = 'h1;
        results[1] = 'h0;
        results[2] = 'h0;

        `MSG("Start to test SLTIU instruction");
        @(posedge aclk);

        for (int i=0;i<3;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify XORI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {37'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `XORI, `I_ARITH};
        instructions[1] = {37'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `XORI, `I_ARITH};
        instructions[2] = {37'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `XORI, `I_ARITH};
        datas[0] = 'h00000000;
        datas[1] = 'h000005A5;
        datas[2] = 'hFFFFFFFF;
        results[0] = 'hFFFFFFFF;
        results[1] = 'hFFFFFFFF;
        results[2] = 'h00000000;

        `MSG("Start to test XORI instruction");
        @(posedge aclk);

        for (int i=0;i<3;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify ORI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {37'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `ORI, `I_ARITH};
        instructions[1] = {37'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `ORI, `I_ARITH};
        instructions[2] = {37'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `ORI, `I_ARITH};
        instructions[3] = {37'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `ORI, `I_ARITH};
        datas[0] = 'h00000000;
        datas[1] = 'h000005A5;
        datas[2] = 'hFFFFFFFF;
        datas[3] = 'h00000000;
        results[0] = 'hFFFFFFFF;
        results[1] = 'hFFFFFFFF;
        results[2] = 'hFFFFFFFF;
        results[3] = 'h00000000;

        `MSG("Start to test ORI instruction");
        @(posedge aclk);

        for (int i=0;i<4;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify ANDI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {37'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `ANDI, `I_ARITH};
        instructions[1] = {37'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `ANDI, `I_ARITH};
        instructions[2] = {37'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `ANDI, `I_ARITH};
        instructions[3] = {37'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `ANDI, `I_ARITH};
        datas[0] = 'h00000000;
        datas[1] = 'h000005A5;
        datas[2] = 'hFFFFFFFF;
        datas[3] = 'h00000000;
        results[0] = 'h0;
        results[1] = 'h0;
        results[2] = 'hFFFFFFFF;
        results[3] = 'h00000000;

        `MSG("Start to test ANDI instruction");
        @(posedge aclk);

        for (int i=0;i<4;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SLLI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {6'd0, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `SLLI, `I_ARITH};
        instructions[1] = {6'd1, 12'b0, 20'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `SLLI, `I_ARITH};
        instructions[2] = {6'd24, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `SLLI, `I_ARITH};
        instructions[3] = {6'd31, 12'b0, 20'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `SLLI, `I_ARITH};
        instructions[4] = {6'd32, 12'b0, 20'b0, 12'h000, 5'b0, 5'h4, rs2, rs1, 7'b0, `SLLI, `I_ARITH};
        datas[0] = 'hFFFFFFFF;
        datas[1] = 'hFFFFFFFF;
        datas[2] = 'hFFFFFFFF;
        datas[3] = 'hFFFFFFFF;
        datas[3] = 'hFFFFFFFF;
        datas[4] = 'hFFFFFFFF;
        results[0] = 'hFFFFFFFF;
        results[1] = 'hFFFFFFFE;
        results[2] = 'hFF000000;
        results[3] = 'h80000000;
        results[4] = 'hFFFFFFFF;

        `MSG("Start to test SLLI instruction");
        @(posedge aclk);

        for (int i=0;i<5;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SRLI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {6'd0, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `SRLI, `I_ARITH};
        instructions[1] = {6'd1, 12'b0, 20'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `SRLI, `I_ARITH};
        instructions[2] = {6'd24, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `SRLI, `I_ARITH};
        instructions[3] = {6'd31, 12'b0, 20'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `SRLI, `I_ARITH};
        instructions[4] = {6'd32, 12'b0, 20'b0, 12'h000, 5'b0, 5'h4, rs2, rs1, 7'b0, `SRLI, `I_ARITH};
        datas[0] = 'hFFFFFFFF;
        datas[1] = 'hFFFFFFFF;
        datas[2] = 'hFFFFFFFF;
        datas[3] = 'hFFFFFFFF;
        datas[3] = 'hFFFFFFFF;
        datas[4] = 'hFFFFFFFF;
        results[0] = 'hFFFFFFFF;
        results[1] = 'h7FFFFFFF;
        results[2] = 'h000000FF;
        results[3] = 'h00000001;
        results[4] = 'hFFFFFFFF;

        `MSG("Start to test SRLI instruction");
        @(posedge aclk);

        for (int i=0;i<5;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SRAI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        // RS1 <, <=, > when positive
        instructions[0] = {6'd0, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0100000, `SRAI, `I_ARITH};
        instructions[1] = {6'd1, 12'b0, 20'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0100000, `SRAI, `I_ARITH};
        instructions[2] = {6'd24, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0100000, `SRAI, `I_ARITH};
        instructions[3] = {6'd31, 12'b0, 20'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0100000, `SRAI, `I_ARITH};
        instructions[4] = {6'd32, 12'b0, 20'b0, 12'h000, 5'b0, 5'h4, rs2, rs1, 7'b0100000, `SRAI, `I_ARITH};
        datas[0] = 'hFFFFFFFF;
        datas[1] = 'h7FFFFFFF;
        datas[2] = 'hF0FF00FF;
        datas[3] = 'h09A42345;
        datas[4] = 'hAA005500;
        results[0] = 'hFFFFFFFF;
        results[1] = 'h3FFFFFFF;
        results[2] = 'hFFFFFFF0;
        results[3] = 'h00000000;
        results[4] = 'hAA005500;

        `MSG("Start to test SRAI instruction");
        @(posedge aclk);

        for (int i=0;i<5;i=i+1) begin
            drive_i_arith(instructions[i], datas[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify ADD instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `ADD, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `ADD, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `ADD, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `ADD, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `ADD, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFF;
        rs1_data[4] = 'h0;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'hFFFFFFFF;
        rs2_data[2] = 'h10;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h0;
        results[0] = 'h0;
        results[1] = 'h0;
        results[2] = 'h20;
        results[3] = 'hFFFFFFFE;
        results[4] = 'h00000000;

        @(posedge aclk);

        `MSG("Start to test ADD instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SUB instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0100000, `ADD, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0100000, `ADD, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0100000, `ADD, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0100000, `ADD, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0100000, `ADD, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFF;
        rs1_data[4] = 'hFFFFFFFF;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'hFFFFFFFF;
        rs2_data[2] = 'h10;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h1;
        results[0] = 'h0;
        results[1] = 'h2;
        results[2] = 'h0;
        results[3] = 'h0;
        results[4] = 'hFFFFFFFE;

        @(posedge aclk);

        `MSG("Start to test SUB instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SLT instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `SLT, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `SLT, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `SLT, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `SLT, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `SLT, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFE;
        rs1_data[4] = 'hFFFFFFFF;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'h2;
        rs2_data[2] = 'h9;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h1;
        results[0] = 'h0;
        results[1] = 'h1;
        results[2] = 'h0;
        results[3] = 'h1;
        results[4] = 'h1;

        @(posedge aclk);

        `MSG("Start to test SLT instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SLTU instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `SLTU, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `SLTU, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `SLTU, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `SLTU, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `SLTU, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFE;
        rs1_data[4] = 'hFFFFFFFF;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'h2;
        rs2_data[2] = 'h9;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h1;
        results[0] = 'h0;
        results[1] = 'h1;
        results[2] = 'h0;
        results[3] = 'h1;
        results[4] = 'h0;

        @(posedge aclk);

        `MSG("Start to test SLTU instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify XOR instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `XOR, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `XOR, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `XOR, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `XOR, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `XOR, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFE;
        rs1_data[4] = 'hFFFFFFFF;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'h2;
        rs2_data[2] = 'h9;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h1;
        results[0] = 'h0;
        results[1] = 'h3;
        results[2] = 'h19;
        results[3] = 'h1;
        results[4] = 'hFFFFFFFE;

        @(posedge aclk);

        `MSG("Start to test XOR instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify OR instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `OR, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `OR, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `OR, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `OR, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `OR, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFE;
        rs1_data[4] = 'hFFFFFFFF;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'h2;
        rs2_data[2] = 'h9;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h1;
        results[0] = 'h0;
        results[1] = 'h3;
        results[2] = 'h19;
        results[3] = 'hFFFFFFFF;
        results[4] = 'hFFFFFFFF;

        @(posedge aclk);

        `MSG("Start to test OR instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify AND instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `AND, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `AND, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `AND, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `AND, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `AND, `R_ARITH};
        rs1_data[0] = 'h0;
        rs1_data[1] = 'h1;
        rs1_data[2] = 'h10;
        rs1_data[3] = 'hFFFFFFFE;
        rs1_data[4] = 'hFFFFFFFF;
        rs2_data[0] = 'h0;
        rs2_data[1] = 'h2;
        rs2_data[2] = 'h9;
        rs2_data[3] = 'hFFFFFFFF;
        rs2_data[4] = 'h1;
        results[0] = 'h0;
        results[1] = 'h0;
        results[2] = 'h0;
        results[3] = 'hFFFFFFFE;
        results[4] = 'h1;

        @(posedge aclk);

        `MSG("Start to test OR instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SLL instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `SLL, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `SLL, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `SLL, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `SLL, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `SLL, `R_ARITH};
        rs1_data[0] = 'hAEFCDBF0;
        rs1_data[1] = 'hAEFCDBF0;
        rs1_data[2] = 'hAEFCDBF0;
        rs1_data[3] = 'hAEFCDBF1;
        rs1_data[4] = 'hAEFCDBF0;
        rs2_data[0] = 'd0;
        rs2_data[1] = 'd4;
        rs2_data[2] = 'd16;
        rs2_data[3] = 'd31;
        rs2_data[4] = 'd41;
        results[0] = 'hAEFCDBF0;
        results[1] = 'hEFCDBF00;
        results[2] = 'hDBF00000;
        results[3] = 'h80000000;
        results[4] = 'hAEFCDBF0;

        @(posedge aclk);

        `MSG("Start to test SLL instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SRL instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0, `SRL, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0, `SRL, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0, `SRL, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0, `SRL, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0, `SRL, `R_ARITH};
        rs1_data[0] = 'hAEFCDBF0;
        rs1_data[1] = 'hAEFCDBF0;
        rs1_data[2] = 'hAEFCDBF0;
        rs1_data[3] = 'hAEFCDBF1;
        rs1_data[4] = 'hAEFCDBF0;
        rs2_data[0] = 'd0;
        rs2_data[1] = 'd4;
        rs2_data[2] = 'd16;
        rs2_data[3] = 'd31;
        rs2_data[4] = 'd41;
        results[0] = 'hAEFCDBF0;
        results[1] = 'h0AEFCDBF;
        results[2] = 'h0000AEFC;
        results[3] = 'h00000001;
        results[4] = 'hAEFCDBF0;

        @(posedge aclk);

        `MSG("Start to test SRL instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify SRA instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {54'b0, 5'h0, rs2, rs1, 7'b0100000, `SRA, `R_ARITH};
        instructions[1] = {54'b0, 5'h1, rs2, rs1, 7'b0100000, `SRA, `R_ARITH};
        instructions[2] = {54'b0, 5'h2, rs2, rs1, 7'b0100000, `SRA, `R_ARITH};
        instructions[3] = {54'b0, 5'h3, rs2, rs1, 7'b0100000, `SRA, `R_ARITH};
        instructions[4] = {54'b0, 5'h4, rs2, rs1, 7'b0100000, `SRA, `R_ARITH};
        rs1_data[0] = 'hAEFCDBF0;
        rs1_data[1] = 'hAEFCDBF0;
        rs1_data[2] = 'h5EFCDBF0;
        rs1_data[3] = 'hAEFCDBF1;
        rs1_data[4] = 'hAEFCDBF0;
        rs2_data[0] = 'd0;
        rs2_data[1] = 'd4;
        rs2_data[2] = 'd16;
        rs2_data[3] = 'd31;
        rs2_data[4] = 'd41;
        results[0] = 'hAEFCDBF0;
        results[1] = 'hFAEFCDBF;
        results[2] = 'h00005EFC;
        results[3] = 'hFFFFFFFF;
        results[4] = 'hAEFCDBF0;

        @(posedge aclk);

        `MSG("Start to test SRA instruction");
        for (int i=0;i<5;i=i+1) begin
            drive_r_arith(instructions[i], rs1_data[i], rs2_data[i], results[i], i);
        end
        $display("");

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
