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

    // Offset part into address value, 2 because we index dword (XLEN)
    localparam OFFSET_IX = 2;
    localparam OFFSET_W = $clog2(CACHE_LINE_W/XLEN);

    // Index part into address value, to parse the cache lines
    localparam INDEX_IX = OFFSET_IX + OFFSET_W;
    localparam INDEX_W = $clog2(CACHE_DEPTH);

    // Tag part, address's MSB stored along the data values, -2 because the
    // address if by oriented but we address dword (XLEN)
    localparam TAG_IX = INDEX_IX + INDEX_W;
    localparam TAG_W = ADDR_W - INDEX_W - OFFSET_W - 2;

    // Cache line width, tag + data + set bit
    localparam FULL_LINE_W = CACHE_LINE_W + TAG_W + 1;


    //////////////////////////////////////////////////////////////////////////
    // Logic declaration
    //////////////////////////////////////////////////////////////////////////

    logic [FULL_LINE_W   -1:0] cache_lines [CACHE_DEPTH-1:0];

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
            cache_lines[i] = {FULL_LINE_W{1'b0}};
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

    // the complete line storing the address (tag) and the instructions
    // The SET bit is here to know if the line is initialized, asserted
    // during FENCE.i execution, thus tieded-off the SET bit, enabling it
    // when cache line is written.
    assign wline = {~flush, wtag, wdata};

    always @ (posedge aclk) begin
        if (wen) begin
            cache_lines[windex] <= wline;
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // Follow the line fetch, the data selection and the hit/miss generation.
    // raddr is decomposed in three parts:
    //
    // raddr =  | tag | index | offset |
    //
    //     - offset: log2(nb instructions per line), select the right
    //               instruction in the cache line
    //     - index:  log2(cache depth), select a cache line in the pool
    //     - tag:    the remaining MSBs, the part helping to determine
    //               a cache hit/miss
    //
    // The MSB of a cache line is the set bit, set to 1 once the line
    // has been written and so valid. This bit is set back to 0 during flush.
    //////////////////////////////////////////////////////////////////////////

    // offset is used to select the correct instruction across the cache line
    assign roffset = raddr[OFFSET_IX+:OFFSET_W];

    // index is used to parse the cache lines
    assign rindex = raddr[INDEX_IX+:INDEX_W];

    // read the corresponding cache line
    assign {rset, rtag, rline} = cache_lines[rindex];

    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            hit <= 1'b0;
            miss <= 1'b0;
            rdata <= {XLEN{1'b0}};
        end else if (srst) begin
            hit <= 1'b0;
            miss <= 1'b0;
            rdata <= {XLEN{1'b0}};
        end else begin
            if (ren) begin
                // hit indicates the cache line store the expected instruction
                hit <= (rset && rtag==raddr[TAG_IX+:TAG_W]) ? 1'b1 : 1'b0;
                // miss indicates the cache is not initialized or doesn't contain
                // the expected instruction address
                miss <= (~rset || rtag!=raddr[TAG_IX+:TAG_W]) ? 1'b1 : 1'b0;
                // extract the instruction within the cache line
                rdata <= rline[roffset*XLEN+:XLEN];
            end else begin
                hit <= 1'b0;
                miss <= 1'b0;
            end
        end
    end


endmodule

`resetall
