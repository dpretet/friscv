// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_alu

    #(
        parameter ADDRW = 16,
        parameter XLEN  = 32
    )(
        // clock & reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // ALU instruction bus
        input  logic                      alu_en,
        output logic                      alu_ready,
        output logic                      alu_empty,
        input  logic [`ALU_INSTBUS_W-1:0] alu_instbus,
        // register source 1 query interface
        output logic [5             -1:0] alu_rs1_addr,
        input  logic [XLEN          -1:0] alu_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] alu_rs2_addr,
        input  logic [XLEN          -1:0] alu_rs2_val,
        // register estination for query interface
        output logic                      alu_rd_wr,
        output logic [5             -1:0] alu_rd_addr,
        output logic [XLEN          -1:0] alu_rd_val,
        output logic [XLEN/8        -1:0] alu_rd_strb,
        // data memory interface
        output logic                      mem_en,
        output logic                      mem_wr,
        output logic [ADDRW         -1:0] mem_addr,
        output logic [XLEN          -1:0] mem_wdata,
        output logic [XLEN/8        -1:0] mem_strb,
        input  logic [XLEN          -1:0] mem_rdata,
        input  logic                      mem_ready
    );

    // instructions fields
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

    logic                             mem_access;
    logic                             memorying;
    logic        [XLEN          -1:0] rd_lui;
    logic signed [XLEN          -1:0] addr;

    assign opcode = alu_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = alu_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct7 = alu_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = alu_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = alu_instbus[`RS2    +: `RS2_W   ];
    assign rd     = alu_instbus[`RD     +: `RD_W    ];
    assign zimm   = alu_instbus[`ZIMM   +: `ZIMM_W  ];
    assign imm12  = alu_instbus[`IMM12  +: `IMM12_W ];
    assign imm20  = alu_instbus[`IMM20  +: `IMM20_W ];
    assign csr    = alu_instbus[`CSR    +: `CSR_W   ];
    assign shamt  = alu_instbus[`SHAMT  +: `SHAMT_W ];


    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            memorying <= 1'b0;
            alu_ready <= 1'b0;
            alu_rd_wr <= 1'b0;
        end else if (srst == 1'b1) begin
            memorying <= 1'b0;
            alu_ready <= 1'b0;
            alu_rd_wr <= 1'b0;
        end else begin

            // memorying flags the ongoing memory accesses, preventing to
            // accept a new instruction before the current one is processed.
            // Memory read accesses span over multiple cycles, thus obliges to
            // pause the pipeline
            if (memorying) begin
                // Accepts a new instruction once memory completes the request
                if (mem_en && mem_ready) begin
                    alu_rd_wr <= 1'b0;
                    alu_ready <= 1'b1;
                    memorying <= 1'b0;
                end
            // Manages the ALU instruction bus acknowledgment
            end else if (alu_en && mem_access) begin
                if (opcode==`LOAD) begin
                    alu_rd_wr <= 1'b1;
                    memorying <= 1'b1;
                    alu_ready <= 1'b0;
                end else begin
                    alu_rd_wr <= 1'b0;
                    memorying <= 1'b0;
                    alu_ready <= 1'b1;
                end
            end else if (alu_en && opcode==`LUI) begin
                alu_rd_wr <= 1'b1;
            // When instruction does not access the memory, ALU is always ready
            end else begin
                alu_rd_wr <= 1'b0;
                memorying <= 1'b0;
                alu_ready <= 1'b1;
            end
        end

    end

    assign mem_access = (opcode == `LOAD) ? 1'b1 :
                        (opcode == `STORE) ? 1'b1 : 1'b0;

    assign mem_en = (memorying) ? 1'b1 :
                    (alu_en && alu_ready && mem_access) ? 1'b1 :
                                                          1'b0;
    assign mem_wr = (opcode == `STORE) ? 1'b1 : 1'b0;

    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(alu_rs1_val);
    assign mem_addr = addr[ADDRW-1:0];

    assign mem_wdata = alu_rs2_val;
    assign mem_strb = (opcode == `STORE && funct3==`SB) ? {{(XLEN/8-1){1'b0}},1'b1} :
                      (opcode == `STORE && funct3==`SH) ? {{(XLEN/8-2){1'b0}},2'b11} :
                      (opcode == `STORE && funct3==`SW) ? {(XLEN/8){1'b1}} :
                                                          {XLEN/8{1'b0}};

    assign alu_rs1_addr = rs1;
    assign alu_rs2_addr = rs2;
    assign alu_rd_addr = rd;
    assign alu_rd_val = (opcode==`LOAD && funct3==`LB) ? {{24{mem_rdata[7]}}, mem_rdata[7:0]} :
                        (opcode==`LOAD && funct3==`LBU) ? {{24{1'b0}}, mem_rdata[7:0]} :
                        (opcode==`LOAD && funct3==`LH) ? {{16{mem_rdata[15]}}, mem_rdata[15:0]} :
                        (opcode==`LOAD && funct3==`LHU) ? {{16{1'b0}}, mem_rdata[15:0]} :
                        (opcode==`LOAD && funct3==`LW) ?  mem_rdata :
                        (opcode==`LUI)  ? {imm20, 12'b0} :
                                          {XLEN{1'b0}};

    assign alu_rd_strb = (opcode == `LOAD && funct3==`LB) ? {{(XLEN/8-1){1'b0}},1'b1} :
                         (opcode == `LOAD && funct3==`LBU) ? {{(XLEN/8-1){1'b0}},1'b1} :
                         (opcode == `LOAD && funct3==`LH) ? {{(XLEN/8-2){1'b0}},2'b11} :
                         (opcode == `LOAD && funct3==`LHU) ? {{(XLEN/8-2){1'b0}},2'b11} :
                         (opcode == `LOAD && funct3==`LW) ? {(XLEN/8){1'b1}} :
                         (opcode == `LUI)                 ? {(XLEN/8){1'b1}} :
                                                            {XLEN/8{1'b0}};

    assign alu_empty = 1'b0;

endmodule

`resetall
