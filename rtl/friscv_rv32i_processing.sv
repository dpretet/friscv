// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_processing

    #(
        parameter ADDRW = 16,
        parameter XLEN  = 32
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // ALU instruction bus
        input  logic                        proc_en,
        output logic                        proc_ready,
        output logic                        proc_empty,
        output logic [4               -1:0] proc_fenceinfo,
        input  logic [`INST_BUS_W     -1:0] proc_instbus,
        // register source 1 query interface
        output logic [5               -1:0] alu_rs1_addr,
        input  logic [XLEN            -1:0] alu_rs1_val,
        // register source 2 for query interface
        output logic [5               -1:0] alu_rs2_addr,
        input  logic [XLEN            -1:0] alu_rs2_val,
        // register estination for query interface
        output logic                        alu_rd_wr,
        output logic [5               -1:0] alu_rd_addr,
        output logic [XLEN            -1:0] alu_rd_val,
        output logic [XLEN/8          -1:0] alu_rd_strb,
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

    logic alu_ready;
    logic alu_empty;
    logic memfy_ready;
    logic memfy_empty;

    friscv_rv32i_alu
    #(
    .ADDRW     (ADDRW),
    .XLEN      (XLEN)
    )
    alu
    (
    .aclk          (aclk        ),
    .aresetn       (aresetn     ),
    .srst          (srst        ),
    .alu_en        (proc_en     ),
    .alu_ready     (alu_ready   ),
    .alu_empty     (alu_empty   ),
    .alu_instbus   (proc_instbus),
    .alu_rs1_addr  (alu_rs1_addr),
    .alu_rs1_val   (alu_rs1_val ),
    .alu_rs2_addr  (alu_rs2_addr),
    .alu_rs2_val   (alu_rs2_val ),
    .alu_rd_wr     (alu_rd_wr   ),
    .alu_rd_addr   (alu_rd_addr ),
    .alu_rd_val    (alu_rd_val  ),
    .alu_rd_strb   (alu_rd_strb )
    );


    friscv_rv32i_memfy
    #(
    .ADDRW     (ADDRW),
    .XLEN      (XLEN)
    )
    memfy
    (
    .aclk            (aclk          ),
    .aresetn         (aresetn       ),
    .srst            (srst          ),
    .memfy_en        (proc_en       ),
    .memfy_ready     (memfy_ready   ),
    .memfy_empty     (memfy_empty   ),
    .memfy_fenceinfo (proc_fenceinfo),
    .memfy_instbus   (proc_instbus  ),
    .memfy_rs1_addr  (memfy_rs1_addr),
    .memfy_rs1_val   (memfy_rs1_val ),
    .memfy_rs2_addr  (memfy_rs2_addr),
    .memfy_rs2_val   (memfy_rs2_val ),
    .memfy_rd_wr     (memfy_rd_wr   ),
    .memfy_rd_addr   (memfy_rd_addr ),
    .memfy_rd_val    (memfy_rd_val  ),
    .memfy_rd_strb   (memfy_rd_strb ),
    .mem_en          (mem_en        ),
    .mem_wr          (mem_wr        ),
    .mem_addr        (mem_addr      ),
    .mem_wdata       (mem_wdata     ),
    .mem_strb        (mem_strb      ),
    .mem_rdata       (mem_rdata     ),
    .mem_ready       (mem_ready     )
    );


    assign proc_ready = alu_ready & memfy_ready;
    assign proc_empty = alu_empty & memfy_empty;


endmodule

`resetall

