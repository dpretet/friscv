// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_icache_memctrl

    #(

    ///////////////////////////////////////////////////////////////////////////
    // RISCV Architecture
    ///////////////////////////////////////////////////////////////////////////

    parameter XLEN = 32,

    ///////////////////////////////////////////////////////////////////////////
    // Interface Setup
    ///////////////////////////////////////////////////////////////////////////

    // Address bus width defined for both control and AXI4 address signals
    parameter ADDR_W = 8,
    // AXI ID width, setup by default to 8 and unused
    parameter AXI_ID_W = 8,
    // AXI4 data width, independant of control unit width
    parameter AXI_DATA_W = 128,

    ///////////////////////////////////////////////////////////////////////////
    // Cache Setup
    ///////////////////////////////////////////////////////////////////////////

    // Line width defining only the data payload, in bits
    parameter CACHE_LINE_W = 128,
    // Number of lines in the cache
    parameter CACHE_DEPTH = 512

    )(
    input  logic                      aclk,
    input  logic                      aresetn,
    input  logic                      srst,
    input  logic                      flush_req,
    output logic                      flush_ack,
    output logic                      flushing,
    // Instruction memory interface
    input  logic                      inst_en,
    input  logic [ADDR_W        -1:0] inst_addr,
    output logic [XLEN          -1:0] inst_rdata,
    output logic                      inst_ready,
    // AXI4 Read channels interface to central memory
    output logic                      mem_arvalid,
    input  logic                      mem_arready,
    output logic [ADDR_W        -1:0] mem_araddr,
    output logic [8             -1:0] mem_arlen,
    output logic [3             -1:0] mem_arsize,
    output logic [2             -1:0] mem_arburst,
    output logic [2             -1:0] mem_arlock,
    output logic [4             -1:0] mem_arcache,
    output logic [3             -1:0] mem_arprot,
    output logic [4             -1:0] mem_arqos,
    output logic [4             -1:0] mem_arregion,
    output logic [AXI_ID_W      -1:0] mem_arid,
    input  logic                      mem_rvalid,
    output logic                      mem_rready,
    input  logic [AXI_ID_W      -1:0] mem_rid,
    input  logic [2             -1:0] mem_rresp,
    input  logic [AXI_DATA_W    -1:0] mem_rdata,
    input  logic                      mem_rlast,
    // Cache lines write interface
    output logic                      cache_wen,
    output logic [ADDR_W        -1:0] cache_waddr,
    output logic [CACHE_LINE_W  -1:0] cache_wdata
    );

    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    // Offset part into address value
    localparam OFFSET_IX = 0;
    localparam OFFSET_W = CACHE_LINE_W/XLEN;

    logic [OFFSET_W      -1:0] roffset;

    ///////////////////////////////////////////////////////////////////////////
    // Optional signals, unused and tied to recommended default values
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arregion = 4'b0;
    assign mem_arlock = 2'b0;
    assign mem_arcache = 4'b0;
    assign mem_arprot = 3'b0;
    assign mem_arqos = 4'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    // Zero by default, unused in this version
    assign mem_arid = {AXI_ID_W{1'b0}};
    // Always use INCR mode
    assign mem_arburst = 2'b01;

    assign mem_arsize = (AXI_DATA_W/8 ==  1) ? 3'b000 :
                        (AXI_DATA_W/8 ==  2) ? 3'b001 :
                        (AXI_DATA_W/8 ==  4) ? 3'b010 :
                        (AXI_DATA_W/8 ==  8) ? 3'b011 :
                        (AXI_DATA_W/8 == 16) ? 3'b100 :
                        (AXI_DATA_W/8 == 32) ? 3'b101 :
                        (AXI_DATA_W/8 == 64) ? 3'b110 :
                                               3'b111 ;


    ///////////////////////////////////////////////////////////////////////////
    // Simple APB to AXI4 translation
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arvalid = inst_en;
    assign mem_araddr = inst_addr;
    assign mem_arlen = 8'b0;

    assign inst_ready = mem_rvalid;
    assign mem_rready = inst_en;
    // offset is used to select the correct data across the read cache line
    assign roffset = inst_addr[OFFSET_IX+:OFFSET_W];
    assign inst_rdata = mem_rdata[roffset*XLEN+:XLEN];


    ///////////////////////////////////////////////////////////////////////////
    // Cache write
    ///////////////////////////////////////////////////////////////////////////

    assign cache_wen = mem_rvalid & inst_en;
    assign cache_waddr = inst_addr;
    assign cache_wdata = mem_rdata;

    assign flushing = 1'b0;
    assign flush_ack = 1'b0;

endmodule

`resetall

