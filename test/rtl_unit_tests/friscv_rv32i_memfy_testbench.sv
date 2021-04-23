/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"

`timescale 1 ns / 1 ps

module friscv_rv32i_memfy_testbench();

    `SVUT_SETUP

    parameter ADDRW = 16;
    parameter XLEN  = 32;

    logic                        aclk;
    logic                        aresetn;
    logic                        srst;
    logic                        memfy_en;
    logic                        memfy_ready;
    logic                        memfy_empty;
    logic [`ALU_INSTBUS_W  -1:0] memfy_instbus;
    logic [5               -1:0] memfy_rs1_addr;
    logic [XLEN            -1:0] memfy_rs1_val;
    logic [5               -1:0] memfy_rs2_addr;
    logic [XLEN            -1:0] memfy_rs2_val;
    logic                        memfy_rd_wr;
    logic [5               -1:0] memfy_rd_addr;
    logic [XLEN            -1:0] memfy_rd_val;
    logic [XLEN/8          -1:0] memfy_rd_strb;
    logic                        mem_en;
    logic                        mem_wr;
    logic [ADDRW           -1:0] mem_addr;
    logic [XLEN            -1:0] mem_wdata;
    logic [XLEN/8          -1:0] mem_strb;
    logic [XLEN            -1:0] mem_rdata;
    logic                        mem_ready;

    logic [7               -1:0] opcode;
    logic [3               -1:0] funct3;
    logic [7               -1:0] funct7;
    logic [5               -1:0] rs1;
    logic [5               -1:0] rs2;
    logic [5               -1:0] rd;
    logic [5               -1:0] zimm;
    logic [12              -1:0] imm12;
    logic [20              -1:0] imm20;
    logic [12              -1:0] csr;
    logic [5               -1:0] shamt;

    logic [12              -1:0] offset;
    logic [`ALU_INSTBUS_W  -1:0] instructions[16-1:0];
    logic [`ALU_INSTBUS_W  -1:0] insts_load[16-1:0];
    logic [`ALU_INSTBUS_W  -1:0] insts_store[16-1:0];
    logic [`ALU_INSTBUS_W  -1:0] insts_lui[16-1:0];
    logic [`ALU_INSTBUS_W  -1:0] instruction;
    logic [XLEN            -1:0] datas[16-1:0];
    logic [XLEN            -1:0] rs1_data[16-1:0];
    logic [XLEN            -1:0] rs2_data[16-1:0];
    logic [XLEN            -1:0] results[16-1:0];

    integer                    timeout;

    friscv_rv32i_memfy
    #(
    ADDRW,
    XLEN
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    memfy_en,
    memfy_ready,
    memfy_empty,
    memfy_instbus,
    memfy_rs1_addr,
    memfy_rs1_val,
    memfy_rs2_addr,
    memfy_rs2_val,
    memfy_rd_wr,
    memfy_rd_addr,
    memfy_rd_val,
    memfy_rd_strb,
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
        $dumpfile("friscv_rv32i_memfy_testbench.vcd");
        $dumpvars(0, friscv_rv32i_memfy_testbench);
    end

    task setup(msg="");
    begin
        aresetn =1'b0;
        srst = 1'b0;
        memfy_en = 1'b0;
        memfy_instbus = {`ALU_INSTBUS_W{1'b0}};
        memfy_rs1_val = {XLEN{1'b0}};
        memfy_rs2_val = {XLEN{1'b0}};
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


    `TEST_SUITE("Memfy Testsuite")

    `UNIT_TEST("Verify STORE instructions")

        @(posedge aclk);

        rs1 = 10;
        rs2 = 20;
        memfy_rs1_val = 0;
        memfy_rs2_val = 0;
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
                `MSG("Store in memory");
                memfy_en = 1'b1;
                memfy_instbus = instructions[i];
                memfy_rs1_val = i;
                memfy_rs2_val = datas[i];
                @(posedge aclk);
                memfy_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
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
                `ASSERT((memfy_rs1_addr==rs1), "ALU doesn't access the correct rs1 register")
                `ASSERT((memfy_rs2_addr==rs2), "ALU doesn't access the correct rs2 register")
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
        memfy_rs1_val = 0;
        memfy_rs2_val = 0;
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
            memfy_en = 1'b1;
            memfy_instbus = instructions[i];
            memfy_rs1_val = i;
            memfy_rs2_val = datas[i];
            @(posedge aclk);
            memfy_en = 1'b0;
            @(posedge aclk);
            @(posedge aclk);
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
                `MSG("Load memory");
                memfy_en = 1'b1;
                memfy_instbus = instructions[i];
                memfy_rs1_val = i;
                memfy_rs2_val = datas[i];
                @(posedge aclk);
                memfy_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);
            end
            begin
                `MSG("Inspect ISA registers access");
                while(memfy_rd_wr==1'b0) @ (posedge aclk);
                `ASSERT((memfy_rd_addr==rd), "ALU doesn't target correct RD registers");

                if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LBU) begin
                    `ASSERT((memfy_rd_val=={24'b0, datas[i][7:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0001), "STRB should be 4'b0001");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LHU) begin
                    `ASSERT((memfy_rd_val=={24'b0, datas[i][15:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0011), "STRB should be 4'b0011");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LB) begin
                    `ASSERT((memfy_rd_val=={{24{datas[i][7]}}, datas[i][7:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0001), "STRB should be 4'b0001");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LH) begin
                    `ASSERT((memfy_rd_val=={{16{datas[i][15]}}, datas[i][15:0]}), "ALU doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0011), "STRB should be 4'b0011");

                end else if (instructions[i][`FUNCT3 +: `FUNCT3_W]==`LW) begin
                    `ASSERT((memfy_rd_val==datas[i]), "ALU doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b1111), "STRB should be 4'b1111");
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
        memfy_rs1_val = 0;
        memfy_rs2_val = 0;
        rd = 5;

        rs1 = 10;
        rs2 = 20;
        memfy_rs1_val = 0;
        memfy_rs2_val = 0;
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
            memfy_en = 1'b1;
            memfy_instbus = instructions[0];
            @(posedge aclk);
            memfy_en = 1'b0;
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
        end
        begin
            `MSG("Inspect ISA registers access");
            while(memfy_rd_wr==1'b0) @ (posedge aclk);
            `ASSERT((memfy_rd_addr==rd), "ALU doesn't target correct RD registers");
            `ASSERT((memfy_rd_val=={imm20,12'b0}), "ALU doesn't store correct data in RD");
            `ASSERT((memfy_rd_strb==4'b1111), "STRB should be 4'b1111");
        end
        join

    `UNIT_TEST_END

    `UNIT_TEST("Verify LUI -> STORE -> LOAD round-trip")

        `MSG("Load in register a value, then store it in memory and load it back to registers");

        rs1 = 10;
        rs2 = 5;
        rd = 5;
        memfy_rs1_val = 0;
        memfy_rs2_val = 0;
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
                memfy_en = 1'b1;
                memfy_instbus = insts_lui[i];
                @(posedge aclk);
                memfy_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);

                `MSG("Store its content in memory");
                @(posedge aclk);
                memfy_en = 1'b1;
                memfy_instbus = insts_store[i];
                memfy_rs1_val = i;
                memfy_rs2_val = datas[i];
                @(posedge aclk);
                memfy_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);

                `MSG("Load back the memory in register");
                @(posedge aclk);
                memfy_en = 1'b1;
                memfy_instbus = insts_load[i];
                memfy_rs2_val = datas[i];
                @(posedge aclk);
                memfy_en = 1'b0;
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);
                @(posedge aclk);
            end
            begin

                `MSG("Inspect LUI ISA registers access");
                while(memfy_rd_wr==1'b0) @ (negedge aclk);
                `ASSERT((memfy_rd_addr==rd), "LUI doesn't target correct RD registers");
                `ASSERT((memfy_rd_val=={datas[i][19:0],12'b0}), "LUI doesn't store correct data in RD");
                `ASSERT((memfy_rd_strb==4'b1111), "LUI STRB should be 4'b1111");
                @(posedge aclk);

            end
            begin
                `MSG("Wait for STORE memory access");
                while(mem_en==1'b0 && mem_wr==1'b0) @ (negedge aclk);

                `ASSERT((mem_addr==(i+imm12)), "STORE doesn't target right address");
                `ASSERT((mem_wdata==datas[i]), "STORE doesn't write correct data");

                if (insts_store[i][`FUNCT3 +: `FUNCT3_W]==`SB) begin
                    `ASSERT((mem_strb==4'b0001), "STORE STRB should be 4'b0001");

                end else if (insts_store[i][`FUNCT3 +: `FUNCT3_W]==`SH) begin
                    `ASSERT((mem_strb==4'b0011), "STORE STRB should be 4'b0011");

                end else if (insts_store[i][`FUNCT3 +: `FUNCT3_W]==`SW) begin
                    `ASSERT((mem_strb==4'b1111), "STORE STRB should be 4'b1111");
                end
                @(posedge aclk);

                `MSG("Wait for LOAD memory access");
                while(mem_en==1'b0 && mem_wr==1'b0) @ (negedge aclk);
                @(posedge aclk);
                @(posedge aclk);

                `MSG("Inspect LOAD ISA registers access");
                while(memfy_rd_wr==1'b0) @ (posedge aclk);

                `ASSERT((memfy_rd_addr==rd), "LOAD doesn't target correct RD registers");

                if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LBU) begin
                    `ASSERT((memfy_rd_val=={24'b0, datas[i][7:0]}), "LOAD doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0001), "LOAD STRB should be 4'b0001");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LHU) begin
                    `ASSERT((memfy_rd_val=={24'b0, datas[i][15:0]}), "LOAD doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0011), "LOAD STRB should be 4'b0011");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LB) begin
                    `ASSERT((memfy_rd_val=={{24{datas[i][7]}}, datas[i][7:0]}), "LOAD doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0001), "LOAD STRB should be 4'b0001");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LH) begin
                    `ASSERT((memfy_rd_val=={{16{datas[i][15]}}, datas[i][15:0]}), "LOAD doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b0011), "LOAD STRB should be 4'b0011");

                end else if (insts_load[i][`FUNCT3 +: `FUNCT3_W]==`LW) begin
                    `ASSERT((memfy_rd_val==datas[i]), "LOAD doesn't store correct data in RD");
                    `ASSERT((memfy_rd_strb==4'b1111), "LOAD STRB should be 4'b1111");
                end
                $display("");
            end
            join
        end

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
