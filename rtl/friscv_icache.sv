// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Instruction cache module
//
// - Direct-mapped placement policy
// - Parametrizable cache depth
// - Parametrizable cache line width (instruction per line)
// - Transparent operation, no need of user management
// - Software-based flush control with FENCE.i instruction
// - Cache control & status observable by a debug interface
// - Slave APB interface to fetch instructions
// - Master AXI4 interface to read central memory
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
    parameter ADDR_W = 32,
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
    // Clock / Reset
    input  logic                      aclk,
    input  logic                      aresetn,
    input  logic                      srst,
    // Flush control
    input  logic                      flush_req,
    output logic                      flush_ack,
    // Instruction memory interface
    input  logic                      inst_en,
    input  logic [ADDR_W        -1:0] inst_addr,
    output logic [XLEN          -1:0] inst_rdata,
    output logic                      inst_ready,
    // AXI4 Read channels interface to central memory
    output logic                      icache_arvalid,
    input  logic                      icache_arready,
    output logic [ADDR_W        -1:0] icache_araddr,
    output logic [8             -1:0] icache_arlen,
    output logic [3             -1:0] icache_arsize,
    output logic [2             -1:0] icache_arburst,
    output logic [2             -1:0] icache_arlock,
    output logic [4             -1:0] icache_arcache,
    output logic [3             -1:0] icache_arprot,
    output logic [4             -1:0] icache_arqos,
    output logic [4             -1:0] icache_arregion,
    output logic [AXI_ID_W      -1:0] icache_arid,
    input  logic                      icache_rvalid,
    output logic                      icache_rready,
    input  logic [AXI_ID_W      -1:0] icache_rid,
    input  logic [2             -1:0] icache_rresp,
    input  logic [AXI_DATA_W    -1:0] icache_rdata,
    input  logic                      icache_rlast
    );


    ///////////////////////////////////////////////////////////////////////////
    // Logic declarations
    ///////////////////////////////////////////////////////////////////////////

    logic                     cache_wen;
    logic [ADDR_W       -1:0] cache_waddr;
    logic [CACHE_LINE_W -1:0] cache_wdata;
    logic                     cache_ren;
    logic [ADDR_W       -1:0] cache_raddr;
    logic [XLEN         -1:0] cache_rdata;
    logic                     cache_hit;
    logic                     cache_miss;
    logic                     flushing;
    logic [XLEN         -1:0] inst_rdata_axi;
    logic                     inst_ready_axi;


    ///////////////////////////////////////////////////////////////////////////
    // Cache lines Storage
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_lines
    #(
        .XLEN         (XLEN),
        .ADDR_W       (ADDR_W),
        .CACHE_LINE_W (CACHE_LINE_W),
        .CACHE_DEPTH  (CACHE_DEPTH)
    )
    cache_lines
    (
        .aclk    (aclk       ),
        .aresetn (aresetn    ),
        .srst    (srst       ),
        .flush   (flushing   ),
        .wen     (cache_wen  ),
        .waddr   (cache_waddr),
        .wdata   (cache_wdata),
        .ren     (cache_ren  ),
        .raddr   (cache_raddr),
        .rdata   (cache_rdata),
        .hit     (cache_hit  ),
        .miss    (cache_miss )
    );


    ///////////////////////////////////////////////////////////////////////////
    // AXI4 memory controller
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_memctrl
    #(
    .XLEN         (XLEN),
    .ADDR_W       (ADDR_W),
    .AXI_ID_W     (AXI_ID_W),
    .AXI_DATA_W   (AXI_DATA_W),
    .CACHE_LINE_W (CACHE_LINE_W),
    .CACHE_DEPTH  (CACHE_DEPTH)
    )
    mem_ctrl
    (
    .aclk           (aclk           ),
    .aresetn        (aresetn        ),
    .srst           (srst           ),
    .flush_req      (flush_req      ),
    .flush_ack      (flush_ack      ),
    .flushing       (flushing       ),
    .inst_en        (inst_en        ),
    .inst_addr      (inst_addr      ),
    .inst_rdata     (inst_rdata_axi ),
    .inst_ready     (inst_ready_axi ),
    .mem_arvalid    (icache_arvalid ),
    .mem_arready    (icache_arready ),
    .mem_araddr     (icache_araddr  ),
    .mem_arlen      (icache_arlen   ),
    .mem_arsize     (icache_arsize  ),
    .mem_arburst    (icache_arburst ),
    .mem_arlock     (icache_arlock  ),
    .mem_arcache    (icache_arcache ),
    .mem_arprot     (icache_arprot  ),
    .mem_arqos      (icache_arqos   ),
    .mem_arregion   (icache_arregion),
    .mem_arid       (icache_arid    ),
    .mem_rvalid     (icache_rvalid  ),
    .mem_rready     (icache_rready  ),
    .mem_rid        (icache_rid     ),
    .mem_rresp      (icache_rresp   ),
    .mem_rdata      (icache_rdata   ),
    .mem_rlast      (icache_rlast   ),
    .cache_wen      (cache_wen      ),
    .cache_waddr    (cache_waddr    ),
    .cache_wdata    (cache_wdata    )
    );

    assign cache_ren = inst_en;
    assign cache_raddr = inst_addr;

    assign inst_ready = (cache_hit)  ? 1'b1 :
                        (cache_miss) ? icache_rvalid :
                                       1'b0;

    assign inst_rdata = (cache_hit)  ? cache_rdata :
                        (cache_miss) ? inst_rdata_axi :
                                       {XLEN{1'b0}};
endmodule

`resetall
