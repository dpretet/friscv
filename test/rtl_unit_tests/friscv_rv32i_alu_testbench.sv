/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"

`timescale 1 ns / 1 ps

module friscv_rv32i_alu_testbench();

    `SVUT_SETUP

    parameter ADDRW = 16;
    parameter XLEN  = 32;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      alu_en;
    logic                      alu_ready;
    logic                      alu_empty;
    logic [`ALU_INSTBUS_W-1:0] alu_instbus;
    logic [5             -1:0] alu_rs1_addr;
    logic [XLEN          -1:0] alu_rs1_val;
    logic [5             -1:0] alu_rs2_addr;
    logic [XLEN          -1:0] alu_rs2_val;
    logic                      alu_rd_wr;
    logic [5             -1:0] alu_rd_addr;
    logic [XLEN          -1:0] alu_rd_val;
    logic [XLEN/8        -1:0] alu_rd_strb;
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

    logic [12            -1:0] offset;
    logic [`ALU_INSTBUS_W-1:0] instructions[16-1:0];
    logic [`ALU_INSTBUS_W-1:0] insts_load[16-1:0];
    logic [`ALU_INSTBUS_W-1:0] insts_store[16-1:0];
    logic [`ALU_INSTBUS_W-1:0] insts_lui[16-1:0];
    logic [`ALU_INSTBUS_W-1:0] instruction;
    logic [XLEN          -1:0] datas[16-1:0];
    logic [XLEN          -1:0] results[16-1:0];

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
    alu_empty,
    alu_instbus,
    alu_rs1_addr,
    alu_rs1_val,
    alu_rs2_addr,
    alu_rs2_val,
    alu_rd_wr,
    alu_rd_addr,
    alu_rd_val,
    alu_rd_strb,
    mem_en,
    mem_wr,
    mem_addr,
    mem_wdata,
    mem_strb,
    mem_rdata,
    mem_ready
    );

    scram 
    #(
    .ADDRW (ADDRW),
    .DATAW (XLEN)
    )
    data_ram 
    (
    .aclk       (aclk),
    .p1_en      (mem_en),
    .p1_wr      (mem_wr),
    .p1_addr    (mem_addr),
    .p1_wdata   (mem_wdata),
    .p1_strb    (mem_strb),
    .p1_rdata   (mem_rdata),
    .p1_ready   (mem_ready),
    .p2_en      (1'h0),
    .p2_wr      (1'h0),
    .p2_addr    ({ADDRW{1'h0}}),
    .p2_wdata   ({XLEN{1'h0}}),
    .p2_strb    ({XLEN/8{1'h0}}),
    .p2_rdata   (),
    .p2_ready   ()
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
        input [`ALU_INSTBUS_W-1:0] instructions;
        input [XLEN          -1:0] datas;
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
            alu_rs1_val = datas;
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

    `UNIT_TEST("Verify STORE instructions")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        imm12 = 12'b1;
        instructions[0] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SB, `STORE};
        instructions[1] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SH, `STORE};
        instructions[2] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        datas[0] = 'h000000AB;
        datas[1] = 'h00004321;
        datas[2] = 'h76543210;

        @(posedge aclk);

        for (int i=0;i<3;i=i+1) begin
            $display("");
            `MSG("Source an instruction:");
            $display("%x", instructions[i]);
            fork
            begin
                while(alu_ready==1'b0) @ (posedge aclk);
                `MSG("Store in memory");
                alu_en = 1'b1;
                alu_instbus = instructions[i];
                alu_rs1_val = i;
                alu_rs2_val = datas[i];
                @(posedge aclk);
                alu_en = 1'b0;
                @(posedge aclk);
            end
            begin
                while(mem_en==1'b0) @ (posedge aclk);
                @(negedge aclk);
                `MSG("Inspect data memory access");
                `ASSERT((mem_addr==(i+imm12)), "STORE doesn't target right address");
                `ASSERT((mem_wdata==datas[i]), "STORE doesn't write correct data");
                if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`SB) begin
                    `ASSERT((mem_strb==4'b0001), "STRB should be 4'b0001");
                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`SH) begin
                    `ASSERT((mem_strb==4'b0011), "STRB should be 4'b0011");
                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`SW) begin
                    `ASSERT((mem_strb==4'b1111), "STRB should be 4'b1111");
                end

                `MSG("Inspect ISA registers access");
                `ASSERT((alu_rs1_addr==rs1), "ALU doesn't access the correct rs1 register")
                `ASSERT((alu_rs2_addr==rs2), "ALU doesn't access the correct rs2 register")
                @(posedge aclk);
            end
            join
            @(posedge aclk);
        end
        $display("");

    `UNIT_TEST_END

    `UNIT_TEST("Verify LOAD instructions")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        imm12 = 12'b1;
        datas[0] = 'h000000AB;
        datas[1] = 'hF000F321;
        datas[2] = 'h76543210;
        datas[3] = 'h0A0BC043;
        datas[4] = 'hFCB3E211;

        instructions[0] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        instructions[1] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        instructions[2] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        instructions[3] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        instructions[4] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};

        `MSG("Start by storing data in memory to initialize the RAM");

        @(posedge aclk);
        for (int i=0;i<5;i=i+1) begin
            while(alu_ready==1'b0) @ (posedge aclk);
            alu_en = 1'b1;
            alu_instbus = instructions[i];
            alu_rs1_val = i;
            alu_rs2_val = datas[i];
            @(posedge aclk);
            alu_en = 1'b0;
            @(posedge aclk);
        end

        `MSG("Now load data from memory");

        @(posedge aclk);
        instructions[0] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LB, `LOAD};
        instructions[1] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LH, `LOAD};
        instructions[2] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LW, `LOAD};
        instructions[3] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LBU, `LOAD};
        instructions[4] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LHU, `LOAD};
        @(posedge aclk);

        for (int i=0;i<5;i=i+1) begin
            $display("");
            `MSG("Source an instruction:");
            $display("%x", instructions[i]);
            fork
            begin
                while(alu_ready==1'b0) @ (posedge aclk);
                `MSG("Load memory");
                alu_en = 1'b1;
                alu_instbus = instructions[i];
                alu_rs1_val = i;
                alu_rs2_val = datas[i];
                @(posedge aclk);
                alu_en = 1'b0;
                @(posedge aclk);
            end
            begin
                `MSG("Inspect ISA registers access");
                while(alu_rd_wr==1'b0) @ (posedge aclk);
                `ASSERT((alu_rd_addr==rd), "ALU doesn't target correct RD registers");

                if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LBU) begin
                    `ASSERT((alu_rd_val=={24'b0, datas[i][7:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0001), "STRB should be 4'b0001");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LHU) begin
                    `ASSERT((alu_rd_val=={24'b0, datas[i][15:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0011), "STRB should be 4'b0011");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LB) begin
                    `ASSERT((alu_rd_val=={{24{datas[i][7]}}, datas[i][7:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0001), "STRB should be 4'b0001");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LH) begin
                    `ASSERT((alu_rd_val=={{16{datas[i][15]}}, datas[i][15:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0011), "STRB should be 4'b0011");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LW) begin
                    `ASSERT((alu_rd_val==datas[i]), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b1111), "STRB should be 4'b1111");
                end
            end
            join
            @(posedge aclk);
        end

    `UNIT_TEST_END

    `UNIT_TEST("Verify LUI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        imm12 = 12'b1;
        imm20 = 20'h98765;

        datas[0] = 'h000000AB;
        datas[1] = 'h00004321;
        datas[2] = 'h76543210;
        datas[3] = 'h0A0BC043;
        datas[4] = 'hFCB3E211;


        instructions[0] = {imm20, 12'b0, 5'b0, rd, 5'b0, 5'b0, 3'b0, 7'b0, `LUI};

        fork
        begin
            while(alu_ready==1'b0) @ (posedge aclk);
            alu_en = 1'b1;
            alu_instbus = instructions[0];
            @(posedge aclk);
            alu_en = 1'b0;
            @(posedge aclk);
        end
        begin
            `MSG("Inspect ISA registers access");
            while(alu_rd_wr==1'b0) @ (posedge aclk);
            `ASSERT((alu_rd_addr==rd), "ALU doesn't target correct RD registers");
            `ASSERT((alu_rd_val=={imm20,12'b0}), "ALU doesn't store correct data in RD");
            `ASSERT((alu_rd_strb==4'b1111), "STRB should be 4'b1111");
        end
        join

    `UNIT_TEST_END

    `UNIT_TEST("Verify LUI -> STORE -> LOAD round-trip")

        `MSG("Load in register a value, then store it in memory and load it back to registers");

        rs1 = 10;
        rs2 = 5;
        rd = 5;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        imm12 = 12'b1;
        imm20 = 20'h98765;
        @(posedge aclk);

        datas[0] = 'h000000AB;
        datas[1] = 'h00004321;
        datas[2] = 'h76543210;
        datas[3] = 'h0A0BC043;
        datas[4] = 'hFCB3E211;
        @(posedge aclk);

        insts_lui[0] = {datas[0][19:0], 12'b0, 5'b0, rd, 5'b0, 5'b0, 3'b0, 7'b0, `LUI};
        insts_lui[1] = {datas[1][19:0], 12'b0, 5'b0, rd, 5'b0, 5'b0, 3'b0, 7'b0, `LUI};
        insts_lui[2] = {datas[2][19:0], 12'b0, 5'b0, rd, 5'b0, 5'b0, 3'b0, 7'b0, `LUI};
        insts_lui[3] = {datas[3][19:0], 12'b0, 5'b0, rd, 5'b0, 5'b0, 3'b0, 7'b0, `LUI};
        insts_lui[4] = {datas[4][19:0], 12'b0, 5'b0, rd, 5'b0, 5'b0, 3'b0, 7'b0, `LUI};
        @(posedge aclk);

        insts_store[0] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        insts_store[1] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        insts_store[2] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        insts_store[3] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        insts_store[4] = {37'b0, imm12, 5'b0, 5'h0, rs2, rs1, 7'b0, `SW, `STORE};
        @(posedge aclk);

        insts_load[0] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LB, `LOAD};
        insts_load[1] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LH, `LOAD};
        insts_load[2] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LW, `LOAD};
        insts_load[3] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LBU, `LOAD};
        insts_load[4] = {37'b0, imm12, 5'b0, rd, 5'h0, rs1, 7'b0, `LHU, `LOAD};
        @(posedge aclk);

        for (int i=0; i<5; i=i+1) begin

            fork 
            begin
                `MSG("Load a register");
                while(alu_ready==1'b0) @ (posedge aclk);
                alu_en = 1'b1;
                alu_instbus = insts_lui[i];
                @(posedge aclk);
                alu_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
                
                `MSG("Store its content in memory");
                @(posedge aclk);
                while(alu_ready==1'b0) @ (posedge aclk);
                alu_en = 1'b1;
                alu_instbus = insts_store[i];
                alu_rs1_val = i;
                alu_rs2_val = datas[i];
                @(posedge aclk);
                alu_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);

                `MSG("Load back the memory in register");
                @(posedge aclk);
                while(alu_ready==1'b0) @ (posedge aclk);
                alu_en = 1'b1;
                alu_instbus = insts_load[i];
                alu_rs2_val = datas[i];
                @(posedge aclk);
                alu_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
            end
            begin

                `MSG("Inspect ISA registers access");
                while(alu_rd_wr==1'b0) @ (negedge aclk);
                `ASSERT((alu_rd_addr==rd), "ALU doesn't target correct RD registers");
                `ASSERT((alu_rd_val=={datas[i][19:0],12'b0}), "ALU doesn't store correct data in RD");
                `ASSERT((alu_rd_strb==4'b1111), "STRB should be 4'b1111");
                @(posedge aclk);

            end
            begin
                `MSG("Inspect store memory access");
                while(mem_en==1'b0 && mem_wr==1'b0) @ (negedge aclk);

                `ASSERT((mem_addr==(i+imm12)), "STORE doesn't target right address");
                `ASSERT((mem_wdata==datas[i]), "STORE doesn't write correct data");

                if (insts_store[i][`FUNCT3 +: `FUNCT3_W]==`SB) begin
                    `ASSERT((mem_strb==4'b0001), "STRB should be 4'b0001");

                end else if (insts_store[i][`FUNCT3 +: `FUNCT3_W]==`SH) begin
                    `ASSERT((mem_strb==4'b0011), "STRB should be 4'b0011");

                end else if (insts_store[i][`FUNCT3 +: `FUNCT3_W]==`SW) begin
                    `ASSERT((mem_strb==4'b1111), "STRB should be 4'b1111");
                end
                @(posedge aclk);

                `MSG("Wait for memory ready");
                while(mem_en==1'b0 && mem_wr==1'b0) @ (negedge aclk);

                `MSG("Inspect ISA registers access");
                while(alu_rd_wr==1'b0) @ (posedge aclk);

                `ASSERT((alu_rd_addr==rd), "ALU doesn't target correct RD registers");

                if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LBU) begin
                    `ASSERT((alu_rd_val=={24'b0, datas[i][7:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0001), "STRB should be 4'b0001");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LHU) begin
                    `ASSERT((alu_rd_val=={24'b0, datas[i][15:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0011), "STRB should be 4'b0011");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LB) begin
                    `ASSERT((alu_rd_val=={{24{datas[i][7]}}, datas[i][7:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0001), "STRB should be 4'b0001");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LH) begin
                    `ASSERT((alu_rd_val=={{16{datas[i][15]}}, datas[i][15:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b0011), "STRB should be 4'b0011");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LW) begin
                    `ASSERT((alu_rd_val==datas[i]), "ALU doesn't store correct data in RD");
                    `ASSERT((alu_rd_strb==4'b1111), "STRB should be 4'b1111");
                end
                $display("");
            end
            join
        end

    `UNIT_TEST_END

    `UNIT_TEST("Verify ADDI instruction")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        alu_rs1_val = 0;
        alu_rs2_val = 0;
        rd = 5;
        instructions[0] = {37'b0, 12'h0, 5'b0, 5'h0, rs2, rs1, 7'b0, `ADDI, `R_ARITH};
        instructions[1] = {37'b0, 12'hFFF, 5'b0, 5'h1, rs2, rs1, 7'b0, `ADDI, `R_ARITH};
        instructions[2] = {37'b0, 12'h1, 5'b0, 5'h2, rs2, rs1, 7'b0, `ADDI, `R_ARITH};
        instructions[3] = {37'b0, 12'hFFF, 5'b0, 5'h3, rs2, rs1, 7'b0, `ADDI, `R_ARITH};
        instructions[4] = {37'b0, 12'h1, 5'b0, 5'h4, rs2, rs1, 7'b0, `ADDI, `R_ARITH};
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
        instructions[0] = {37'b0, 12'h2, 5'b0, 5'h0, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[1] = {37'b0, 12'h2, 5'b0, 5'h1, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[2] = {37'b0, 12'h2, 5'b0, 5'h2, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        datas[0] = 'h1;
        datas[1] = 'h2;
        datas[2] = 'h3;
        results[0] = 'h1;
        results[1] = 'h0;
        results[2] = 'h0;
        // RS1 <, <=, > when negative
        instructions[3] = {37'b0, 12'hFFD, 5'b0, 5'h3, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[4] = {37'b0, 12'hFFD, 5'b0, 5'h4, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[5] = {37'b0, 12'hFFD, 5'b0, 5'h5, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        datas[3] = 'hFFFFFFFC;
        datas[4] = 'hFFFFFFFD;
        datas[5] = 'hFFFFFFFE;
        results[3] = 'h1;
        results[4] = 'h0;
        results[5] = 'h0;
        // RS1 <, <=, > when around zero
        instructions[6] = {37'b0, 12'h0, 5'b0, 5'h6, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[7] = {37'b0, 12'h0, 5'b0, 5'h7, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[8] = {37'b0, 12'h0, 5'b0, 5'h8, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
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
        instructions[0] = {37'b0, 12'h2, 5'b0, 5'h0, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[1] = {37'b0, 12'h2, 5'b0, 5'h1, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
        instructions[2] = {37'b0, 12'h2, 5'b0, 5'h2, rs2, rs1, 7'b0, `SLTI, `R_ARITH};
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
        instructions[0] = {37'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `XORI, `R_ARITH};
        instructions[1] = {37'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `XORI, `R_ARITH};
        instructions[2] = {37'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `XORI, `R_ARITH};
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
        instructions[0] = {37'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `ORI, `R_ARITH};
        instructions[1] = {37'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `ORI, `R_ARITH};
        instructions[2] = {37'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `ORI, `R_ARITH};
        instructions[3] = {37'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `ORI, `R_ARITH};
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
        instructions[0] = {37'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `ANDI, `R_ARITH};
        instructions[1] = {37'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `ANDI, `R_ARITH};
        instructions[2] = {37'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `ANDI, `R_ARITH};
        instructions[3] = {37'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `ANDI, `R_ARITH};
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
        instructions[0] = {6'h0, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `SLLI, `R_ARITH};
        instructions[1] = {6'h1, 12'b0, 20'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `SLLI, `R_ARITH};
        instructions[2] = {6'h24, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `SLLI, `R_ARITH};
        instructions[3] = {6'h31, 12'b0, 20'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `SLLI, `R_ARITH};
        instructions[4] = {6'h32, 12'b0, 20'b0, 12'h000, 5'b0, 5'h4, rs2, rs1, 7'b0, `SLLI, `R_ARITH};
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
        instructions[0] = {6'h0, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0, `SRLI, `R_ARITH};
        instructions[1] = {6'h1, 12'b0, 20'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0, `SRLI, `R_ARITH};
        instructions[2] = {6'h24, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0, `SRLI, `R_ARITH};
        instructions[3] = {6'h31, 12'b0, 20'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0, `SRLI, `R_ARITH};
        instructions[4] = {6'h32, 12'b0, 20'b0, 12'h000, 5'b0, 5'h4, rs2, rs1, 7'b0, `SRLI, `R_ARITH};
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
        instructions[0] = {6'h0, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h0, rs2, rs1, 7'b0100000, `SRAI, `R_ARITH};
        instructions[1] = {6'h1, 12'b0, 20'b0, 12'hA5A, 5'b0, 5'h1, rs2, rs1, 7'b0100000, `SRAI, `R_ARITH};
        instructions[2] = {6'h24, 12'b0, 20'b0, 12'hFFF, 5'b0, 5'h2, rs2, rs1, 7'b0100000, `SRAI, `R_ARITH};
        instructions[3] = {6'h31, 12'b0, 20'b0, 12'h000, 5'b0, 5'h3, rs2, rs1, 7'b0100000, `SRAI, `R_ARITH};
        instructions[4] = {6'h32, 12'b0, 20'b0, 12'h000, 5'b0, 5'h4, rs2, rs1, 7'b0100000, `SRAI, `R_ARITH};
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

    `UNIT_TEST("Verify back-to-back instructions execution")
        // TODO: Test back to back d'instructions
    `UNIT_TEST_END


    `TEST_SUITE_END

endmodule
