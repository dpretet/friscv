// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

///////////////////////////////////////////////////////////////////////////////
//
// Instruction cache lines
//
// - classic RAM interface (wr/rd, addr, data)
// - direct-mapped cache
// - hit/miss flags to indicate cache status on read operation
// - format the cache line (block) fetched from the memory before storage
// - extract the requested instruction and manage hit/miss flags
//
///////////////////////////////////////////////////////////////////////////////

module friscv_icache_lines

    #(
        // Architecture
        parameter XLEN = 32,
        // Address bus width
        parameter ADDR_W = 32,
        // Line width defining only the data payload, in bits
        parameter CACHE_LINE_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512
    )(
        input  logic                     aclk,
        input  logic                     aresetn,
        input  logic                     srst,
        input  logic                     flush,
        input  logic                     wen,
        input  logic [ADDR_W       -1:0] waddr,
        input  logic [CACHE_LINE_W -1:0] wdata,
        input  logic                     ren,
        input  logic [ADDR_W       -1:0] raddr,
        output logic [XLEN         -1:0] rdata,
        output logic                     hit,
        output logic                     miss
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters to parse the address and cache line
    //////////////////////////////////////////////////////////////////////////

    // Offset part into address value
    localparam OFFSET_IX = 0;
    localparam OFFSET_W = CACHE_LINE_W/XLEN;
    // Index part into address value, to parse the cache lines
    localparam INDEX_IX = OFFSET_W;
    localparam INDEX_W = $clog2(CACHE_DEPTH);
    // Tag part, address's MSB stored along the data values
    localparam TAG_IX = OFFSET_W + INDEX_W;
    localparam TAG_W   = ADDR_W - INDEX_W - OFFSET_W;
    // Cache line width, tag + data + set bit
    localparam FULL_LINE_W = CACHE_LINE_W + TAG_W + 1;


    //////////////////////////////////////////////////////////////////////////
    // Logic declaration
    //////////////////////////////////////////////////////////////////////////

    logic [FULL_LINE_W   -1:0] lines [CACHE_DEPTH-1:0];

    logic [INDEX_W       -1:0] windex;
    logic [TAG_W         -1:0] wtag;
    logic [FULL_LINE_W   -1:0] wline;

    logic [INDEX_W       -1:0] rindex;
    logic [TAG_W         -1:0] rtag;
    logic [CACHE_LINE_W  -1:0] rline;
    logic                      rset;
    logic [OFFSET_W      -1:0] roffset;


    //////////////////////////////////////////////////////////////////////////
    // Cache lines init for simulation, ensures set bit is 0 and any
    // comparaison with X values.
    //////////////////////////////////////////////////////////////////////////

    `ifdef FRISCV_SIM
    initial begin
        for (int i=0;i<CACHE_DEPTH;i=i+1) begin
            lines[i] = {FULL_LINE_W{1'b0}};
        end
    end
    `endif


    //////////////////////////////////////////////////////////////////////////
    // Address parsing and cache line construction
    //////////////////////////////////////////////////////////////////////////

    // index is used to parse the cache lines
    assign windex = waddr[INDEX_IX+:INDEX_W];
    // address's MSB to identify the memory address source
    assign wtag = waddr[TAG_IX+:TAG_W];
    // the complete line storing the address and the instruction(s)
    // ~flush is the set bit to know if the line is initialized, asserted
    // during FENCE.i execution
    assign wline = {~flush, wtag, wdata};

    always @ (posedge aclk) begin
        if (wen) begin
            lines[windex] <= wline;
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // Lines parsing, data forwarding and hit/miss generation
    //////////////////////////////////////////////////////////////////////////

    // offset is used to select the correct data across the cache line
    assign roffset = raddr[OFFSET_IX+:OFFSET_W];
    // index is used to parse the cache lines
    assign rindex = raddr[INDEX_IX+:INDEX_W];
    // retrieve the corresponding cache line
    assign {rset, rtag, rline} = lines[rindex];

    // hit indicates the cache line store the expected instruction
    assign hit = (rset & rtag==raddr[TAG_IX+:TAG_W]) ? 1'b1 : 1'b0;
    // miss indicates the cache is not initialized or doesn't contain the
    // expected instruction
    assign miss = (~rset | rtag!=raddr[TAG_IX+:TAG_W]) ? 1'b1 : 1'b0;
    // extract the instruction into the cache line
    assign rdata = rline[roffset*XLEN+:XLEN];


endmodule

`resetall
