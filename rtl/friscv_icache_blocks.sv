// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

///////////////////////////////////////////////////////////////////////////////
//
// Instruction cache blocks
//
// - classic RAM interface (wr/rd, addr, data)
// - direct-mapped (1-way) cache
// - hit/miss flags to indicate cache status on read operation
// - format the cache line (block) fetched from the memory before storage
// - extract the requested instruction and manage hit/miss flags
//
///////////////////////////////////////////////////////////////////////////////

module friscv_icache_blocks

    #(
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // Architecture
        parameter XLEN = 32,
        // Address bus width
        parameter ADDR_W = 32,
        // Line width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of blocks in the cache
        parameter CACHE_DEPTH = 512
    )(
        input  wire                      aclk,
        input  wire                      aresetn,
        input  wire                      srst,
        input  wire                      flush,
        input  wire                      wen,
        input  wire  [ADDR_W       -1:0] waddr,
        input  wire  [CACHE_BLOCK_W-1:0] wdata,
        input  wire                      ren,
        input  wire  [ADDR_W       -1:0] raddr,
        output logic [ILEN         -1:0] rdata,
        output logic                     hit,
        output logic                     miss
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters to parse the address and cache blocks
    //////////////////////////////////////////////////////////////////////////

    // Offset part into address value, 2 because we index dword (ILEN)
    localparam OFFSET_IX = 2;
    localparam OFFSET_W = $clog2(CACHE_BLOCK_W/ILEN);

    // Index part into address value, to parse the cache blocks
    localparam INDEX_IX = OFFSET_IX + OFFSET_W;
    localparam INDEX_W = $clog2(CACHE_DEPTH);

    // Tag part, address's MSB stored along the data values, -2 because the
    // address if byte oriented but we address dword (ILEN)
    localparam TAG_IX = INDEX_IX + INDEX_W;
    localparam TAG_W = ADDR_W - INDEX_W - OFFSET_W - 2;

    // Cache block width, tag + data + set bit
    localparam FULL_BLOCK_W = CACHE_BLOCK_W + TAG_W + 1;


    //////////////////////////////////////////////////////////////////////////
    // Logic declaration
    //////////////////////////////////////////////////////////////////////////

    logic [FULL_BLOCK_W  -1:0] cache_blocks [CACHE_DEPTH-1:0];

    logic [INDEX_W       -1:0] windex;
    logic [TAG_W         -1:0] wtag;
    logic [FULL_BLOCK_W  -1:0] wblock;

    logic [INDEX_W       -1:0] rindex;
    logic [TAG_W         -1:0] rtag;
    logic [CACHE_BLOCK_W -1:0] rblock;
    logic                      rset;
    logic [OFFSET_W      -1:0] roffset;


    //////////////////////////////////////////////////////////////////////////
    // Cache blocks init for simulation, ensures set bit is 0 and any
    // comparaison with X values.
    //////////////////////////////////////////////////////////////////////////

    `ifdef FRISCV_SIM
    initial begin
        for (int i=0;i<CACHE_DEPTH;i=i+1) begin
            cache_blocks[i] = {FULL_BLOCK_W{1'b0}};
        end
    end
    `endif


    //////////////////////////////////////////////////////////////////////////
    // Address parsing and cache line construction
    //////////////////////////////////////////////////////////////////////////

    // index is used to parse the cache blocks
    assign windex = waddr[INDEX_IX+:INDEX_W];

    // address's MSB to identify the memory address source
    assign wtag = waddr[TAG_IX+:TAG_W];

    // the complete block storing the address (tag) and the instructions
    // The SET bit is here to know if the block is initialized, asserted
    // during FENCE.i execution, thus tieded-off the SET bit, enabling it
    // when cache block is written.
    assign wblock = {~flush, wtag, wdata};

    always @ (posedge aclk) begin
        if (wen) begin
            cache_blocks[windex] <= wblock;
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // Follow the block fetch, the data selection and the hit/miss generation.
    // raddr is decomposed in three parts:
    //
    // raddr =  | tag | index | offset |
    //
    //     - offset: log2(nb instructions per block), select the right
    //               instruction in the cache block
    //     - index:  log2(cache depth), select a cache block in the pool
    //     - tag:    the remaining MSBs, the part helping to determine
    //               a cache hit/miss
    //
    // The MSB of a cache block is the set bit, set to 1 once the block
    // has been written and so valid. This bit is set back to 0 during flush.
    //////////////////////////////////////////////////////////////////////////

    // offset is used to select the correct instruction across the cache line
    assign roffset = raddr[OFFSET_IX+:OFFSET_W];

    // index is used to parse the cache blocks
    assign rindex = raddr[INDEX_IX+:INDEX_W];

    // read the corresponding cache line
    assign {rset, rtag, rblock} = cache_blocks[rindex];

    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            hit <= 1'b0;
            miss <= 1'b0;
            rdata <= {ILEN{1'b0}};
        end else if (srst) begin
            hit <= 1'b0;
            miss <= 1'b0;
            rdata <= {ILEN{1'b0}};
        end else begin
            if (ren) begin
                // hit indicates the cache line store the expected instruction
                hit <= (rset && rtag==raddr[TAG_IX+:TAG_W]) ? 1'b1 : 1'b0;
                // miss indicates the cache is not initialized or doesn't contain
                // the expected instruction address
                miss <= (~rset || rtag!=raddr[TAG_IX+:TAG_W]) ? 1'b1 : 1'b0;
                // extract the instruction within the cache line
                rdata <= rblock[roffset*ILEN+:ILEN];
            end else begin
                hit <= 1'b0;
                miss <= 1'b0;
            end
        end
    end


endmodule

`resetall
