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
        input  logic [`INST_BUS_W     -1:0] memfy_instbus,
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

    function automatic logic [XLEN/8-1:0] get_mem_strb(

        input logic [6:0] opcode,
        input logic [2:0] funct3
    );

        if      (opcode==`STORE && funct3==`SB) get_mem_strb = {{(XLEN/8-1){1'b0}},1'b1};
        else if (opcode==`STORE && funct3==`SH) get_mem_strb = {{(XLEN/8-2){1'b0}},2'b11};
        else if (opcode==`STORE && funct3==`SW) get_mem_strb = {(XLEN/8){1'b1}};
        else                                    get_mem_strb = {XLEN/8{1'b0}};

    endfunction

    function automatic logic [XLEN-1:0] get_rd_val(

        input logic [7   -1:0] opcode,
        input logic [3   -1:0] funct3,
        input logic [XLEN-1:0] rdata
    );
             if  (opcode==`LOAD && funct3==`LB)  get_rd_val = {{24{rdata[7]}}, rdata[7:0]};
        else if  (opcode==`LOAD && funct3==`LBU) get_rd_val = {{24{1'b0}}, rdata[7:0]};
        else if  (opcode==`LOAD && funct3==`LH)  get_rd_val = {{16{rdata[15]}}, rdata[15:0]};
        else if  (opcode==`LOAD && funct3==`LHU) get_rd_val = {{16{1'b0}}, rdata[15:0]};
        else if  (opcode==`LOAD && funct3==`LW)  get_rd_val =  rdata;

    endfunction

    function automatic logic [XLEN/8-1:0] get_rd_strb(

        input logic [7   -1:0] opcode,
        input logic [3   -1:0] funct3
    );

             if (opcode == `LOAD && funct3==`LB)  get_rd_strb = {{(XLEN/8-1){1'b0}},1'b1};
        else if (opcode == `LOAD && funct3==`LBU) get_rd_strb = {{(XLEN/8-1){1'b0}},1'b1};
        else if (opcode == `LOAD && funct3==`LH)  get_rd_strb = {{(XLEN/8-2){1'b0}},2'b11}; 
        else if (opcode == `LOAD && funct3==`LHU) get_rd_strb = {{(XLEN/8-2){1'b0}},2'b11}; 
        else if (opcode == `LOAD && funct3==`LW)  get_rd_strb = {(XLEN/8){1'b1}};
        else                                      get_rd_strb = {XLEN/8{1'b0}};

    endfunction

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
    logic signed [XLEN -1:0] addr;

    logic [`OPCODE_W   -1:0] opcode_r;
    logic [`FUNCT3_W   -1:0] funct3_r;
    logic [XLEN/8      -1:0] mem_strb_w;

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
            memfy_ready <= 1'b0;
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            mem_en <= 1'b0;
            mem_wr <= 1'b0;
            mem_addr <= {ADDRW{1'b0}};
            mem_wdata <= {XLEN{1'b0}};
            mem_strb <= {XLEN/8{1'b0}};
            memfy_rd_wr <= 1'b0;
            memfy_rd_addr <= 5'b0;
            memfy_rd_val <= {XLEN{1'b0}};
            memfy_rd_strb <= {XLEN/8{1'b0}};
        end else if (srst == 1'b1) begin
            memfy_ready <= 1'b0;
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            mem_en <= 1'b0;
            mem_wr <= 1'b0;
            mem_addr <= {ADDRW{1'b0}};
            mem_wdata <= {XLEN{1'b0}};
            mem_strb <= {XLEN/8{1'b0}};
            memfy_rd_wr <= 1'b0;
            memfy_rd_addr <= 5'b0;
            memfy_rd_val <= {XLEN{1'b0}};
            memfy_rd_strb <= {XLEN/8{1'b0}};
        end else begin

            // LOAD or STORE completion: memory accesses span over multiple
            // cycles, thus obliges to pause the pipeline
            // Accepts a new instruction once memory completes the request
            if (mem_en) begin
                if (mem_ready) begin
                    mem_en <= 1'b0;
                    mem_wr <= 1'b0;
                    memfy_ready <= 1'b1;
                    if (opcode_r==`LOAD) begin
                        memfy_rd_wr <= 1'b1;
                        memfy_rd_val <= get_rd_val(opcode_r, funct3_r, mem_rdata);
                        memfy_rd_strb <= get_rd_strb(opcode_r, funct3_r);
                    end else begin
                        memfy_rd_wr <= 1'b0;
                    end
                end

            // LOAD or STORE instruction acknowledgment
            end else if (memfy_en && mem_access) begin
                memfy_ready <= 1'b0;
                opcode_r <= opcode;
                funct3_r <= funct3;
                mem_en <= 1'b1;
                mem_addr <= {addr[ADDRW-1:2], 2'b0};
                if (opcode==`STORE) begin
                    mem_wr <= 1'b1;
                    mem_wdata <= memfy_rs2_val;
                    mem_strb <= get_mem_strb(opcode, funct3);
                end else begin
                    mem_wr <= 1'b0;
                    mem_wdata <= {XLEN{1'b0}};
                    mem_strb <= {XLEN/8{1'b0}};
                end
                memfy_rd_wr <= 1'b0;
                memfy_rd_addr <= rd;

            // Wait for an instruction
            end else begin
                memfy_ready <= 1'b1;
                mem_en <= 1'b0;
                mem_wr <= 1'b0;
                memfy_rd_wr <= 1'b0;
                memfy_rd_addr <= 5'b0;
                memfy_rd_val <= {XLEN{1'b0}};
                memfy_rd_strb <= {XLEN/8{1'b0}};
            end
        end

    end

    assign mem_access = (opcode == `LOAD)  ? 1'b1 :
                        (opcode == `STORE) ? 1'b1 :
                                             1'b0 ;

    assign memfy_rs1_addr = rs1;

    assign memfy_rs2_addr = rs2;

    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);

    assign memfy_empty = 1'b1;


endmodule

`resetall
