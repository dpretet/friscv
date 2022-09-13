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
// - manage multipe R/W ports but only exclusive access are supported
//
///////////////////////////////////////////////////////////////////////////////

module friscv_cache_blocks

    #(
        // Name used for tracer file name
        parameter NAME = "blocks",
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // Address bus width
        parameter ADDR_W = 32,
        // Line width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of blocks in the cache
        parameter CACHE_DEPTH = 512
    )(
        input  wire                           aclk,
        input  wire                           aresetn,
        input  wire                           srst,
        input  wire                           flush,
        input  wire                           p1_wen,
        input  wire  [ADDR_W            -1:0] p1_waddr,
        input  wire  [CACHE_BLOCK_W     -1:0] p1_wdata,
        input  wire  [CACHE_BLOCK_W/8   -1:0] p1_wstrb,
        input  wire                           p1_ren,
        input  wire  [ADDR_W            -1:0] p1_raddr,
        output logic [ILEN              -1:0] p1_rdata,
        output logic                          p1_hit,
        output logic                          p1_miss,
        input  wire                           p2_wen,
        input  wire  [ADDR_W            -1:0] p2_waddr,
        input  wire  [CACHE_BLOCK_W     -1:0] p2_wdata,
        input  wire  [CACHE_BLOCK_W/8   -1:0] p2_wstrb,
        input  wire                           p2_ren,
        input  wire  [ADDR_W            -1:0] p2_raddr,
        output logic [ILEN              -1:0] p2_rdata,
        output logic                          p2_hit,
        output logic                          p2_miss
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
    // address is byte-oriented but we address dword (ILEN)
    localparam TAG_IX = INDEX_IX + INDEX_W;
    localparam TAG_W = ADDR_W - INDEX_W - OFFSET_W - 2;

    // Number of isntruction per block, used to parse the words to write
    localparam NB_INST_PER_BLK = CACHE_BLOCK_W / ILEN;

    // Cache block width, tag + data + set bit
    localparam FULL_BLOCK_W = CACHE_BLOCK_W + TAG_W + 1;


    //////////////////////////////////////////////////////////////////////////
    // Logic declaration
    //////////////////////////////////////////////////////////////////////////

    // signals used to parse the RAM/regfiles
    logic                          wen;
    logic [INDEX_W           -1:0] windex;
    logic [CACHE_BLOCK_W     -1:0] wdata;
    logic [CACHE_BLOCK_W/8   -1:0] wstrb;
    logic [TAG_W             -1:0] wtag;
    logic [INDEX_W           -1:0] rindex;

    // extracted from the write interface
    logic [INDEX_W        -1:0] p1_windex;
    logic [TAG_W          -1:0] p1_wtag;
    logic [FULL_BLOCK_W   -1:0] p1_wblock;
    logic [INDEX_W        -1:0] p2_windex;
    logic [TAG_W          -1:0] p2_wtag;
    logic [FULL_BLOCK_W   -1:0] p2_wblock;

    // extracted from the read interface
    logic [INDEX_W        -1:0] p1_rindex;
    logic [TAG_W          -1:0] p1_rtag;
    logic [CACHE_BLOCK_W  -1:0] p1_rblock;
    logic                       p1_rset;
    logic [OFFSET_W       -1:0] p1_roffset;
    logic [INDEX_W        -1:0] p2_rindex;
    logic [TAG_W          -1:0] p2_rtag;
    logic [CACHE_BLOCK_W  -1:0] p2_rblock;
    logic                       p2_rset;
    logic [OFFSET_W       -1:0] p2_roffset;
    // extracted from the blocks
    logic [TAG_W          -1:0] rblock_tag;
    logic [CACHE_BLOCK_W  -1:0] rblock_data;
    logic                       rblock_set;

    genvar i;
    integer j;
    genvar k;

    // Tracer setup
    `ifdef TRACE_CACHE
    integer f;
    string fname;
    initial begin
        $sformat(fname, "trace_%s.txt", NAME);
        f = $fopen(fname, "w");
    end
    `endif

    // Print read access either for port 1 or 2
    `define trace_read(PNUM) \
        $fwrite(f, "@ %0t: Port PNUM read @ 0x%x\n", $realtime, p``PNUM``_raddr);\
        $fwrite(f, "  Block:\n");\
        $fwrite(f, "    - set 0x%x\n", rblock_set);\
        $fwrite(f, "    - tag 0x%x\n", rblock_tag);\
        $fwrite(f, "    - data 0x%x\n", rblock_data);\
        $fwrite(f, "  Request:\n");\
        if (rblock_set && p``PNUM``_rtag==rblock_tag)\
            $fwrite(f, "    - hit\n");\
        else\
            $fwrite(f, "    - miss\n");\
        $fwrite(f, "    - index 0x%x\n", p``PNUM``_rindex);\
        $fwrite(f, "    - tag 0x%x\n", p``PNUM``_rtag);\
        $fwrite(f, "    - offset 0x%x\n", p``PNUM``_roffset);\
        $fwrite(f, "    - data 0x%x\n", rblock_data[p``PNUM``_roffset*ILEN+:ILEN]);


    //////////////////////////////////////////////////////////////////////////
    // Address parsing and cache line construction
    //////////////////////////////////////////////////////////////////////////

    // index is used to parse the cache blocks
    assign p1_windex = p1_waddr[INDEX_IX+:INDEX_W];
    assign p2_windex = p2_waddr[INDEX_IX+:INDEX_W];

    // address's MSB to identify the memory address source
    assign p1_wtag = p1_waddr[TAG_IX+:TAG_W];
    assign p2_wtag = p2_waddr[TAG_IX+:TAG_W];

    assign wen = p1_wen | p2_wen;
    assign windex = (p1_wen) ? p1_windex : p2_windex;
    assign wtag = (p1_wen) ? p1_wtag : p2_wtag;
    assign wstrb = (p1_wen) ? p1_wstrb : p2_wstrb;
    assign wdata = (p1_wen) ? p1_wdata : p2_wdata;

    `ifdef TRACE_BLOCKS
    always @ (posedge aclk) begin
        if (wen) begin
            if (p1_wen) $fwrite(f, "@ %0t: Port 1 write @ 0x%x\n", $realtime, p1_waddr);
            else        $fwrite(f, "@ %0t: Port 2 write @ 0x%x\n", $realtime, p2_waddr);
            $fwrite(f, "  - index 0x%x\n", windex);
            $fwrite(f, "  - tag 0x%x\n", wtag);
            $fwrite(f, "  - data 0x%x\n", wdata);
            $fwrite(f, "  - strb 0x%x\n", wstrb);
        end
    end
    `endif


    //////////////////////////////////////////////////////////////////////////
    // Two RAM / regfiles to store the cache blocks
    //////////////////////////////////////////////////////////////////////////

    friscv_rambe
    #(
        `ifdef CACHE_SIM_ENV
        .INIT       (1),
        `endif
        .ADDR_WIDTH ($clog2(CACHE_DEPTH)),
        .DATA_WIDTH (CACHE_BLOCK_W),
        .FFD_EN     (0)
    )
    data_ram
    (
        .aclk     (aclk),
        .wr_en    (wen),
        .wr_be    (wstrb),
        .addr_in  (windex),
        .data_in  (wdata),
        .addr_out (rindex),
        .data_out (rblock_data)
    );

    friscv_ram
    #(
        `ifdef CACHE_SIM_ENV
        .INIT       (1),
        `endif
        .ADDR_WIDTH ($clog2(CACHE_DEPTH)),
        .DATA_WIDTH (1+TAG_W),
        .FFD_EN     (0)
    )
    metadata_ram
    (
        .aclk     (aclk),
        .wr_en    (wen),
        .addr_in  (windex),
        .data_in  ({~flush, wtag}),
        .addr_out (rindex),
        .data_out ({rblock_set, rblock_tag})
    );


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
    assign p1_roffset = p1_raddr[OFFSET_IX+:OFFSET_W];
    assign p2_roffset = p1_raddr[OFFSET_IX+:OFFSET_W];
    // address's MSB to identify the memory address source
    assign p1_rtag = p1_raddr[TAG_IX+:TAG_W];
    assign p2_rtag = p2_raddr[TAG_IX+:TAG_W];
    // index is used to parse the cache blocks
    assign p1_rindex = p1_raddr[INDEX_IX+:INDEX_W];
    assign p2_rindex = p2_raddr[INDEX_IX+:INDEX_W];

    // read the corresponding cache line
    assign rindex = (p1_ren) ? p1_rindex : p2_rindex;


    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            p1_hit <= 1'b0;
            p1_miss <= 1'b0;
            p1_rdata <= {ILEN{1'b0}};
            p2_hit <= 1'b0;
            p2_miss <= 1'b0;
            p2_rdata <= {ILEN{1'b0}};
        end else if (srst) begin
            p1_hit <= 1'b0;
            p1_miss <= 1'b0;
            p1_rdata <= {ILEN{1'b0}};
            p2_hit <= 1'b0;
            p2_miss <= 1'b0;
            p2_rdata <= {ILEN{1'b0}};
        end else begin
            // - hit indicates the cache line store the expected instruction
            // - miss indicates the cache is not initialized or doesn't contain
            //   the expected instruction address
            if (p1_ren) begin
                p1_hit <= (rblock_set && p1_rtag==rblock_tag) ? 1'b1 : 1'b0;
                p1_miss <= (~rblock_set || p1_rtag!=rblock_tag) ? 1'b1 : 1'b0;
                p1_rdata <= rblock_data[p1_roffset*ILEN+:ILEN];
                `ifdef TRACE_BLOCKS
                `trace_read(1)
                `endif
            end else if (p2_ren) begin
                p2_hit <= (rblock_set && p2_rtag==rblock_tag) ? 1'b1 : 1'b0;
                p2_miss <= (~rblock_set || p2_rtag!=rblock_tag) ? 1'b1 : 1'b0;
                p2_rdata <= rblock_data[p2_roffset*ILEN+:ILEN];
                `ifdef TRACE_BLOCKS
                `trace_read(2)
                `endif
            end else begin
                p1_hit <= 1'b0;
                p1_miss <= 1'b0;
                p2_hit <= 1'b0;
                p2_miss <= 1'b0;
            end
        end
    end

endmodule

`resetall
