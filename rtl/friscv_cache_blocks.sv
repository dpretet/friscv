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
        // data length, ILEN for i$ or XLEN for d$
        parameter WLEN = 32,
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
        output logic [WLEN              -1:0] p1_rdata,
        output logic                          p1_hit,
        output logic                          p1_miss,
        input  wire                           p2_wen,
        input  wire  [ADDR_W            -1:0] p2_waddr,
        input  wire  [CACHE_BLOCK_W     -1:0] p2_wdata,
        input  wire  [CACHE_BLOCK_W/8   -1:0] p2_wstrb,
        input  wire                           p2_ren,
        input  wire  [ADDR_W            -1:0] p2_raddr,
        output logic [WLEN              -1:0] p2_rdata,
        output logic                          p2_hit,
        output logic                          p2_miss
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters to parse the address and cache blocks
    //////////////////////////////////////////////////////////////////////////

    // Offset part into address to index a DWORD or QWORD
    localparam OFFSET_IX = (WLEN==32) ? 2 : 3; // 32 or 64 bits support
    localparam OFFSET_W = $clog2(CACHE_BLOCK_W/WLEN);

    // Index part into address value, to parse the cache blocks
    localparam INDEX_IX = OFFSET_IX + OFFSET_W;
    localparam INDEX_W = $clog2(CACHE_DEPTH);

    // Tag part, address's MSB stored along the data values,
    localparam TAG_IX = INDEX_IX + INDEX_W;
    localparam TAG_W = ADDR_W - INDEX_W - OFFSET_W - OFFSET_IX;

    // Number of isntruction per block, used to parse the words to write
    localparam NB_INST_PER_BLK = CACHE_BLOCK_W / WLEN;

    // Cache block width, tag + data + set bit
    localparam FULL_BLOCK_W = CACHE_BLOCK_W + TAG_W + 1;


    //////////////////////////////////////////////////////////////////////////
    // Logic declaration
    //////////////////////////////////////////////////////////////////////////

    // extracted from the write interface
    logic [INDEX_W        -1:0] p1_windex;
    logic [TAG_W          -1:0] p1_wtag;

    logic [INDEX_W        -1:0] p2_windex;
    logic [TAG_W          -1:0] p2_wtag;

    logic [INDEX_W        -1:0] p1_index;
    logic [INDEX_W        -1:0] p2_index;

    // extracted from the read interface
    logic [INDEX_W        -1:0] p1_rindex;
    logic [TAG_W          -1:0] p1_rtag;
    logic [OFFSET_W       -1:0] p1_roffset;

    logic [INDEX_W        -1:0] p2_rindex;
    logic [TAG_W          -1:0] p2_rtag;
    logic [OFFSET_W       -1:0] p2_roffset;

    // extracted from the blocks
    logic [TAG_W          -1:0] p1_rblock_tag;
    logic [CACHE_BLOCK_W  -1:0] p1_rblock_data;
    logic                       p1_rblock_set;

    logic [TAG_W          -1:0] p2_rblock_tag;
    logic [CACHE_BLOCK_W  -1:0] p2_rblock_data;
    logic                       p2_rblock_set;


    genvar i;
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
        $fwrite(f, "    - set 0x%x\n", p``PNUM``_rblock_set);\
        $fwrite(f, "    - tag 0x%x\n", p``PNUM``_rblock_tag);\
        $fwrite(f, "    - data 0x%x\n", p``PNUM``_rblock_data);\
        $fwrite(f, "  Request:\n");\
        if (p``PNUM``_rblock_set && p``PNUM``_rtag==p``PNUM``_rblock_tag)\
            $fwrite(f, "    - hit\n");\
        else\
            $fwrite(f, "    - miss\n");\
        $fwrite(f, "    - index 0x%x\n", p``PNUM``_rindex);\
        $fwrite(f, "    - tag 0x%x\n", p``PNUM``_rtag);\
        $fwrite(f, "    - offset 0x%x\n", p``PNUM``_roffset);\
        $fwrite(f, "    - data 0x%x\n", p``PNUM``_rblock_data[p``PNUM``_roffset*WLEN+:WLEN]);

    `ifdef TRACE_BLOCKS
    always @ (posedge aclk) begin
        if (p1_wen) begin
            $fwrite(f, "@ %0t: Port 1 write @ 0x%x\n", $realtime, p1_waddr);
            $fwrite(f, "  - index 0x%x\n", p1_windex);
            $fwrite(f, "  - tag 0x%x\n", p1_wtag);
            $fwrite(f, "  - data 0x%x\n", p1_wdata);
            $fwrite(f, "  - strb 0x%x\n", p1_wstrb);
        end
        if (p2_wen) begin
            $fwrite(f, "@ %0t: Port 2 write @ 0x%x\n", $realtime, p2_waddr);
            $fwrite(f, "  - index 0x%x\n", p2_windex);
            $fwrite(f, "  - tag 0x%x\n", p2_wtag);
            $fwrite(f, "  - data 0x%x\n", p2_wdata);
            $fwrite(f, "  - strb 0x%x\n", p2_wstrb);
        end
    end
    `endif

    //////////////////////////////////////////////////////////////////////////
    // Address parsing and cache line construction
    //////////////////////////////////////////////////////////////////////////

    // index is used to parse the cache blocks
    assign p1_windex = p1_waddr[INDEX_IX+:INDEX_W];
    assign p2_windex = p2_waddr[INDEX_IX+:INDEX_W];

    // address's MSB to identify the memory address source
    assign p1_wtag = p1_waddr[TAG_IX+:TAG_W];
    assign p2_wtag = p2_waddr[TAG_IX+:TAG_W];

    //////////////////////////////////////////////////////////////////////////
    // Two RAM / regfiles to store the cache blocks
    //////////////////////////////////////////////////////////////////////////

    assign p1_index = (p1_wen) ? p1_windex : p1_rindex;
    assign p2_index = (p2_wen) ? p2_windex : p2_rindex;

    friscv_dprambe
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
        .aclk        (aclk),
        .p1_wren     (p1_wen),
        .p1_wbe      (p1_wstrb),
        .p1_addr     (p1_index),
        .p1_data_in  (p1_wdata),
        .p1_data_out (p1_rblock_data),
        .p2_wren     (p2_wen),
        .p2_wbe      (p2_wstrb),
        .p2_addr     (p2_index),
        .p2_data_in  (p2_wdata),
        .p2_data_out (p2_rblock_data)
    );


    friscv_dpram
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
        .aclk        (aclk),
        .p1_wren     (p1_wen),
        .p1_addr     (p1_index),
        .p1_data_in  ({~flush, p1_wtag}),
        .p1_data_out ({p1_rblock_set, p1_rblock_tag}),
        .p2_wren     (p2_wen),
        .p2_addr     (p2_index),
        .p2_data_in  ({~flush, p2_wtag}),
        .p2_data_out ({p2_rblock_set, p2_rblock_tag})
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
    // 
    // Generate hit/miss flags based on read_tag == block_tag:
    //   - hit indicates the cache line store the expected instruction
    //   - miss indicates the cache is not initialized or doesn't contain
    //     the expected address
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


    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            p1_hit <= 1'b0;
            p1_miss <= 1'b0;
            p1_rdata <= {WLEN{1'b0}};
            p2_hit <= 1'b0;
            p2_miss <= 1'b0;
            p2_rdata <= {WLEN{1'b0}};
        end else if (srst) begin
            p1_hit <= 1'b0;
            p1_miss <= 1'b0;
            p1_rdata <= {WLEN{1'b0}};
            p2_hit <= 1'b0;
            p2_miss <= 1'b0;
            p2_rdata <= {WLEN{1'b0}};
        end else begin

            if (p1_ren) begin
                p1_hit <= (p1_rblock_set && p1_rtag==p1_rblock_tag);
                p1_miss <= (~p1_rblock_set || p1_rtag!=p1_rblock_tag);
                p1_rdata <= p1_rblock_data[p1_roffset*WLEN+:WLEN];
                `ifdef TRACE_BLOCKS
                `trace_read(1)
                `endif
            end else begin
                p1_hit <= 1'b0;
                p1_miss <= 1'b0;
            end

            if (p2_ren) begin
                p2_hit <= (p2_rblock_set && p2_rtag==p2_rblock_tag);
                p2_miss <= (~p2_rblock_set || p2_rtag!=p2_rblock_tag);
                p2_rdata <= p1_rblock_data[p2_roffset*WLEN+:WLEN];
                `ifdef TRACE_BLOCKS
                `trace_read(2)
                `endif
            end else begin
                p2_hit <= 1'b0;
                p2_miss <= 1'b0;
            end
        end
    end

endmodule

`resetall
