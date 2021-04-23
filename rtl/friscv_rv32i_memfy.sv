// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_memfy

    #(
        parameter ADDRW = 16,
        parameter XLEN  = 32
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // ALU instruction bus
        input  logic                        memfy_en,
        output logic                        memfy_ready,
        output logic                        memfy_empty,
        input  logic [`ALU_INSTBUS_W  -1:0] memfy_instbus,
        // register source 1 query interface
        output logic [5               -1:0] memfy_rs1_addr,
        input  logic [XLEN            -1:0] memfy_rs1_val,
        // register source 2 for query interface
        output logic [5               -1:0] memfy_rs2_addr,
        input  logic [XLEN            -1:0] memfy_rs2_val,
        // register estination for query interface
        output logic                        memfy_rd_wr,
        output logic [5               -1:0] memfy_rd_addr,
        output logic [XLEN            -1:0] memfy_rd_val,
        output logic [XLEN/8          -1:0] memfy_rd_strb,
        // data memory interface
        output logic                        mem_en,
        output logic                        mem_wr,
        output logic [ADDRW           -1:0] mem_addr,
        output logic [XLEN            -1:0] mem_wdata,
        output logic [XLEN/8          -1:0] mem_strb,
        input  logic [XLEN            -1:0] mem_rdata,
        input  logic                        mem_ready
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // instructions fields
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`ZIMM_W     -1:0] zimm;
    logic [`IMM12_W    -1:0] imm12;
    logic [`IMM20_W    -1:0] imm20;
    logic [`CSR_W      -1:0] csr;
    logic [`SHAMT_W    -1:0] shamt;

    logic                    mem_access;
    logic                    memorying;
    logic signed [XLEN -1:0] addr;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus fields
    //
    ///////////////////////////////////////////////////////////////////////////

    assign opcode = memfy_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = memfy_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct7 = memfy_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = memfy_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = memfy_instbus[`RS2    +: `RS2_W   ];
    assign rd     = memfy_instbus[`RD     +: `RD_W    ];
    assign zimm   = memfy_instbus[`ZIMM   +: `ZIMM_W  ];
    assign imm12  = memfy_instbus[`IMM12  +: `IMM12_W ];
    assign imm20  = memfy_instbus[`IMM20  +: `IMM20_W ];
    assign csr    = memfy_instbus[`CSR    +: `CSR_W   ];
    assign shamt  = memfy_instbus[`SHAMT  +: `SHAMT_W ];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control circuit managing memory and registers accesses
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            memorying <= 1'b0;
            memfy_ready <= 1'b0;
        end else if (srst == 1'b1) begin
            memorying <= 1'b0;
            memfy_ready <= 1'b0;
        end else begin

            // memorying flags the ongoing memory accesses, preventing to
            // accept a new instruction before the current one is processed.
            // Memory read accesses span over multiple cycles, thus obliges to
            // pause the pipeline
            if (memorying) begin
                // Accepts a new instruction once memory completes the request
                if (mem_en && mem_ready) begin
                    memorying <= 1'b0;
                    memfy_ready <= 1'b1;
                end
            // When accessing the memory (read or write), we pause the
            // processing and wait for memory completion
            end else if (memfy_en && mem_access) begin
                memorying <= 1'b1;
                memfy_ready <= 1'b0;
            end else if (memfy_en && opcode==`LUI) begin
                memorying <= 1'b0;
                memfy_ready <= 1'b1;
            end else begin
                memorying <= 1'b0;
                memfy_ready <= 1'b0;
            end
        end

    end

    assign mem_access = (opcode == `LOAD)  ? 1'b1 :
                        (opcode == `STORE) ? 1'b1 :
                                             1'b0;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Memory IOs
    //
    ///////////////////////////////////////////////////////////////////////////

    assign mem_en = (memfy_en && mem_access) ? 1'b1: 1'b0;

    assign mem_wr = (opcode==`STORE) ? 1'b1 : 1'b0;

    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);
    assign mem_addr = addr[ADDRW-1:0];

    assign mem_wdata = memfy_rs2_val;

    assign mem_strb = (opcode==`STORE && funct3==`SB) ? {{(XLEN/8-1){1'b0}},1'b1} :
                      (opcode==`STORE && funct3==`SH) ? {{(XLEN/8-2){1'b0}},2'b11} :
                      (opcode==`STORE && funct3==`SW) ? {(XLEN/8){1'b1}} :
                                                        {XLEN/8{1'b0}};


    ///////////////////////////////////////////////////////////////////////////
    //
    // Registers IOs
    //
    ///////////////////////////////////////////////////////////////////////////

    assign memfy_rs1_addr = rs1;

    assign memfy_rs2_addr = rs2;

    assign memfy_rd_wr = (memfy_en && opcode==`LUI) ? 1'b1: 
                         (memorying && mem_ready  ) ? 1'b1:
                                                      1'b0;

    assign memfy_rd_addr = rd;

    assign memfy_rd_val = (opcode==`LOAD && funct3==`LB)  ? {{24{mem_rdata[7]}}, mem_rdata[7:0]} :
                          (opcode==`LOAD && funct3==`LBU) ? {{24{1'b0}}, mem_rdata[7:0]} :
                          (opcode==`LOAD && funct3==`LH)  ? {{16{mem_rdata[15]}}, mem_rdata[15:0]} :
                          (opcode==`LOAD && funct3==`LHU) ? {{16{1'b0}}, mem_rdata[15:0]} :
                          (opcode==`LOAD && funct3==`LW)  ?  mem_rdata :
                          (opcode==`LUI)                  ? {imm20, 12'b0} :
                                                            {XLEN{1'b0}};

    assign memfy_rd_strb = (opcode == `LOAD && funct3==`LB)  ? {{(XLEN/8-1){1'b0}},1'b1} :
                           (opcode == `LOAD && funct3==`LBU) ? {{(XLEN/8-1){1'b0}},1'b1} :
                           (opcode == `LOAD && funct3==`LH)  ? {{(XLEN/8-2){1'b0}},2'b11} :
                           (opcode == `LOAD && funct3==`LHU) ? {{(XLEN/8-2){1'b0}},2'b11} :
                           (opcode == `LOAD && funct3==`LW)  ? {(XLEN/8){1'b1}} :
                           (opcode == `LUI)                  ? {(XLEN/8){1'b1}} :
                                                               {XLEN/8{1'b0}};

endmodule

`resetall
