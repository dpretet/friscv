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
    parameter AXI_ADDR_W = 8,
    // AXI ID width, setup by default to 8 and unused
    parameter AXI_ID_W = 8,
    // AXI4 data width, independant of control unit width
    parameter AXI_DATA_W = XLEN*4,

    ///////////////////////////////////////////////////////////////////////////
    // Cache Setup
    ///////////////////////////////////////////////////////////////////////////

    // Line width defining only the data payload, in bits
    parameter CACHE_LINE_W = 128,
    // Number of lines in the cache
    parameter CACHE_DEPTH = XLEN*4

    )(
    input  logic                      aclk,
    input  logic                      aresetn,
    input  logic                      srst,
    input  logic                      flush_req,
    output logic                      flush_ack,
    output logic                      flush,
    // ctrlruction memory interface
    input  logic                      ctrl_arvalid,
    output logic                      ctrl_arready,
    input  logic [AXI_ADDR_W    -1:0] ctrl_araddr,
    input  logic [3             -1:0] ctrl_arprot,
    input  logic [AXI_ID_W      -1:0] ctrl_arid,
    // AXI4 Read channels interface to central memory
    output logic                      mem_arvalid,
    input  logic                      mem_arready,
    output logic [AXI_ADDR_W    -1:0] mem_araddr,
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
    output logic [AXI_ADDR_W    -1:0] cache_waddr,
    output logic [CACHE_LINE_W  -1:0] cache_wdata
    );


    // TODO: support AXI4 transfer with different width than the cache line width
    // TODO: support outstanding requests
    // TODO: support different clock on cache core and AXI4 interface
    // TODO: Manage RRESP

    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // Optional signals, unused and tied to recommended default values
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arregion = 4'b0;
    assign mem_arlock = 2'b0;
    assign mem_arcache = 4'b0;
    assign mem_arqos = 4'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    // Always use INCR mode
    assign mem_arburst = 2'b01;

    // Issue only transfer with a single dataphase
    assign mem_arlen = 8'b0;

    // Fixeds ASIZE, narrow transfers are not supported neither necessary
    assign mem_arsize = (AXI_DATA_W/8 ==  1) ? 3'b000:
                        (AXI_DATA_W/8 ==  2) ? 3'b001:
                        (AXI_DATA_W/8 ==  4) ? 3'b010:
                        (AXI_DATA_W/8 ==  8) ? 3'b011:
                        (AXI_DATA_W/8 == 16) ? 3'b100:
                        (AXI_DATA_W/8 == 32) ? 3'b101:
                        (AXI_DATA_W/8 == 64) ? 3'b110:
                                               3'b111;


    ///////////////////////////////////////////////////////////////////////////
    // Drive AXI4 read address channel directly from AXI4-lite
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arvalid = ctrl_arvalid;
    assign ctrl_arready = mem_arready;
    assign mem_araddr = ctrl_araddr;
    assign mem_arprot = ctrl_arprot;
    assign mem_arid = ctrl_arid;

    // TODO: Drive properly
    assign mem_rready = 1'b1;


    ///////////////////////////////////////////////////////////////////////////
    // Cache write
    ///////////////////////////////////////////////////////////////////////////

    assign cache_wen = mem_rvalid;
    assign cache_waddr = ctrl_araddr;
    assign cache_wdata = mem_rdata;


    ///////////////////////////////////////////////////////////////////////////
    // Flush support on FENCE.i instruction
    //
    // flush_ack is asserted for one cycle on flush_req has been asserted and
    // the entire cache lines have been erased
    ///////////////////////////////////////////////////////////////////////////

    assign flush_ack = 1'b0;
    assign flush = 1'b0;

endmodule

`resetall

