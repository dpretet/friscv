// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Data cache module
//
// - 2/4/8 way associative placement policy
// - Random replacement policy
// - Parametrizable cache depth
// - Parametrizable cache line width
// - Transparent operation, no need of user management
// - Software-based flush control with FENCE.i instruction
// - Cache control & status observable by a debug interface
// - slave AXI4-lite interface to fetch instructions
// - master AXI4 interface to read central memory
//
///////////////////////////////////////////////////////////////////////////////

module friscv_dcache

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
    parameter AXI_DATA_W = 8,

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
    input  logic                      flush,
    // instruction memory interface
    input  logic                      inst_en,
    input  logic [ADDR_W        -1:0] inst_addr,
    output logic [XLEN          -1:0] inst_rdata,
    output logic                      inst_ready,
    // AXI4 Write channels interface to central memory
    output logic                      dcache_awvalid,
    input  logic                      dcache_awready,
    output logic [ADDR_W        -1:0] dcache_awaddr,
    output logic [8             -1:0] dcache_awlen,
    output logic [3             -1:0] dcache_awsize,
    output logic [2             -1:0] dcache_awburst,
    output logic [2             -1:0] dcache_awlock,
    output logic [4             -1:0] dcache_awcache,
    output logic [3             -1:0] dcache_awprot,
    output logic [4             -1:0] dcache_awqos,
    output logic [4             -1:0] dcache_awregion,
    output logic [AXI_ID_W      -1:0] dcache_awid,
    output logic                      dcache_wvalid,
    input  logic                      dcache_wready,
    input  logic                      dcache_wlast,
    output logic [AXI_DATA_W    -1:0] dcache_wdata,
    output logic [AXI_DATA_W/8  -1:0] dcache_wstrb,
    input  logic                      dcache_bvalid,
    output logic                      dcache_bready,
    input  logic [AXI_ID_W      -1:0] dcache_bid,
    input  logic [2             -1:0] dcache_bresp,
    // AXI4 Read channels interface to central memory
    output logic                      dcache_arvalid,
    input  logic                      dcache_arready,
    output logic [ADDR_W        -1:0] dcache_araddr,
    output logic [8             -1:0] dcache_arlen,
    output logic [3             -1:0] dcache_arsize,
    output logic [2             -1:0] dcache_arburst,
    output logic [2             -1:0] dcache_arlock,
    output logic [4             -1:0] dcache_arcache,
    output logic [3             -1:0] dcache_arprot,
    output logic [4             -1:0] dcache_arqos,
    output logic [4             -1:0] dcache_arregion,
    output logic [AXI_ID_W      -1:0] dcache_arid,
    input  logic                      dcache_rvalid,
    output logic                      dcache_rready,
    input  logic [AXI_ID_W      -1:0] dcache_rid,
    input  logic [2             -1:0] dcache_rresp,
    input  logic [AXI_DATA_W    -1:0] dcache_rdata,
    input  logic                      dcache_rlast
    );

    ///////////////////////////////////////////////////////////////////////////
    // Optional signals, unused and tied to recommended default values
    ///////////////////////////////////////////////////////////////////////////

    assign dcache_awregion = 4'b0;
    assign dcache_awlock = 2'b0;
    assign dcache_awcache = 4'b0;
    assign dcache_awprot = 3'b0;
    assign dcache_awqos = 4'b0;

    assign dcache_arregion = 4'b0;
    assign dcache_arlock = 2'b0;
    assign dcache_arcache = 4'b0;
    assign dcache_arprot = 3'b0;
    assign dcache_arqos = 4'b0;

    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    assign dcache_awid = {AXI_ID_W{1'b0}};
    assign dcache_arid = {AXI_ID_W{1'b0}};
    assign dcache_awburst = 2'b01;
    assign dcache_arburst = 2'b01;

endmodule

`resetall

