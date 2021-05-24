// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
// Instruction cache module
//
// - Direct-mapped placement policy
// - Random replacement policy
// - Parametrizable cache depth
// - Parametrizable cache line width
// - Transparent operation for user, no need of user management
// - Software-based flush control with FENCE.i instruction
// - Cache control & status observable by a debug interface
//
// The module is controlled by an APB interface driven by the control unit of
// the processor, and requests to memory with an AXI4 interface.
//
///////////////////////////////////////////////////////////////////////////////

module friscv_icache

    #(
    ///////////////////////////////////////////////////////////////////////////
    // RISCV Architecture
    ///////////////////////////////////////////////////////////////////////////

    parameter XLEN = 32,

    ///////////////////////////////////////////////////////////////////////////
    // Interface Setup
    ///////////////////////////////////////////////////////////////////////////

    // Address bus width defined for both control and AXI4 address signals
    parameter ADDRW = 8,
    // AXI ID width, setup by default to 8 and unused
    parameter AXI_IDW = 8,
    // AXI4 data width, independant of control unit width
    parameter AXI_DATAW = 8,

    ///////////////////////////////////////////////////////////////////////////
    // Cache setup
    ///////////////////////////////////////////////////////////////////////////

    // Line width defining only the data payload in bits
    parameter CACHE_LINE_WIDTH = 128,
    // Number of lines in the cache
    parameter CACHE_DEPTH = 512

    )(
    input  logic                      aclk,
    input  logic                      aresetn,
    input  logic                      srst,
    input  logic                      flush,
    // instruction memory interface
    input  logic                      inst_en,
    input  logic [ADDRW         -1:0] inst_addr,
    output logic [XLEN          -1:0] inst_rdata,
    output logic                      inst_ready,
    // AXI4 Read channels interface to central memory
    output logic                      icache_arvalid,
    input  logic                      icache_arready,
    output logic [ADDRW         -1:0] icache_araddr,
    output logic [8             -1:0] icache_arlen,
    output logic [3             -1:0] icache_arsize,
    output logic [2             -1:0] icache_arburst,
    output logic [2             -1:0] icache_arlock,
    output logic [4             -1:0] icache_arcache,
    output logic [3             -1:0] icache_arprot,
    output logic [4             -1:0] icache_arqos,
    output logic [4             -1:0] icache_arregion,
    output logic [AXI_IDW       -1:0] icache_arid,
    input  logic                      icache_rvalid,
    output logic                      icache_rready,
    input  logic [AXI_IDW       -1:0] icache_rid,
    input  logic [2             -1:0] icache_rresp,
    input  logic [AXI_DATAW     -1:0] icache_rdata
    );

    ///////////////////////////////////////////////////////////////////////////
    // Optional signals, unused and tied to recommended default values
    ///////////////////////////////////////////////////////////////////////////

    assign icache_arregion = 4'b0;
    assign icache_arlock = 2'b0;
    assign icache_arcache = 4'b0;
    assign icache_arprot = 3'b0;
    assign icache_arqos = 4'b0;

    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    // Zero by default, unused in this version
    assign icache_arid = {AXI_IDW{1'b0}};
    // Always use INCR mode
    assign icache_arburst = 2'b01;

endmodule

`resetall

