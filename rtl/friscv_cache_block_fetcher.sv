// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none
`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////
//
// Fetcher stage: manages the read request in the cache or issue
// a read request in central memory
//
///////////////////////////////////////////////////////////////////////////


module friscv_cache_block_fetcher

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Name used for tracer file name
        parameter NAME = "block-fetcher",
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for AXI4 to central memory
        parameter AXI_ADDR_W = 32,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8

    )(
        // Clock / Reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        input  logic                      pending_wr,
        output logic                      pending_rd,
        // Flush current outstanding request in buffers
        input  wire                       flush_reqs,
        // Flush control to execute FENCE.i
        input  wire                       flush_blocks,
        // Control unit interface
        input  wire                       mst_arvalid,
        output logic                      mst_arready,
        input  wire  [AXI_ADDR_W    -1:0] mst_araddr,
        input  wire  [3             -1:0] mst_arprot,
        input  wire  [AXI_ID_W      -1:0] mst_arid,
        output logic                      mst_rvalid,
        input  wire                       mst_rready,
        output logic [AXI_ID_W      -1:0] mst_rid,
        output logic [2             -1:0] mst_rresp,
        output logic [ILEN          -1:0] mst_rdata,
        // Cache line read interface
        input  wire                       cache_writing,
        output logic                      cache_ren,
        output logic [AXI_ADDR_W    -1:0] cache_raddr,
        output logic [AXI_ID_W      -1:0] cache_rid,
        output logic [3             -1:0] cache_rprot,
        input  wire  [ILEN          -1:0] cache_rdata,
        input  wire                       cache_hit,
        input  wire                       cache_miss
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    ///////////////////////////////////////////////////////////////////////////

    // Lowest part of the address replaced by 0 to access a complete cache block
    // (AXI_DATA_W = CACHE_BLOCK_W is the only setup supported)
    localparam ADDR_LSB_W = $clog2(AXI_DATA_W/8);

    // Control fsm, the sequencer driving the cache read and the memory controller
    typedef enum logic[1:0] {
        IDLE = 0,
        LOAD = 1,
        FETCH = 2
    } seq_fsm;

    seq_fsm loader;

    // Pipeline stage to move back data to AXI4-lite and to missed-fecth FIFO
    logic [AXI_ADDR_W   -1:0] araddr_ffd;
    logic [AXI_ID_W     -1:0] arid_ffd;
    logic [3            -1:0] arprot_ffd;

    // To flush the core whatever the flush control asserted
    logic                     flush;
    // FSM fetching toi memory controller is fetching
    logic                     fetching;
    // read data channel FIFO
    logic                     arvalid;
    logic                     arready;
    logic                     rac_full;
    logic                     rac_empty;
    logic                     push_rac;
    logic                     pull_rac;
    logic [AXI_ADDR_W   -1:0] araddr;
    logic [AXI_ID_W     -1:0] arid;
    logic [3            -1:0] arprot;

    logic                     sel_mf;

    // read data channel FIFO
    logic                     rdc_full;
    logic                     rdc_afull;
    logic                     rdc_empty;
    logic                     push_rdc;
    logic                     pull_rdc;


    // Tracer setup
    `ifdef TRACE_CACHE
    string fname;
    integer f;
    initial begin
        $sformat(fname, "trace_%s.txt", NAME);
        f = $fopen(fname, "w");
    end
    `endif

    ///////////////////////////////////////////////////////////////////////////
    // Buffering stage
    ///////////////////////////////////////////////////////////////////////////
    
    assign push_rac = mst_arvalid;
    assign mst_arready = !rac_full;

    assign flush = flush_blocks | flush_reqs;

    friscv_scfifo
    #(
        .PASS_THRU  (1),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (3+AXI_ADDR_W+AXI_ID_W)
    )
    rac_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  ({mst_arprot, mst_arid, mst_araddr}),
        .push     (push_rac),
        .full     (rac_full),
        .afull    (),
        .data_out ({arprot, arid, araddr}),
        .pull     (pull_rac),
        .empty    (rac_empty),
        .aempty   ()
    );

    // FFD stage to propagate potential addr/id to fetch
    // later in cache miss
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
        end else if (srst) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
        end else begin
            araddr_ffd <= cache_raddr;
            arid_ffd <= cache_rid;
        end
    end

    // Multiplexer stage to drive missed-fetch or to-fetch requests to the blocks
    assign sel_mf = (fetching || cache_miss) && !flush && !cache_hit;

    // Cache read interface
    assign cache_ren = arvalid & arready | (loader != IDLE);
    assign cache_raddr = sel_mf ? araddr_ffd : araddr;
    assign cache_rid =   sel_mf ? arid_ffd   : arid;
    assign cache_rprot = sel_mf ? arprot_ffd : arprot;

    // Read address request handshake if able to receive
    assign pull_rac = (!(cache_miss & !flush) & !(fetching & !cache_hit) |
                      ((!cache_hit & !cache_miss) & flush)) &
                      !((rdc_full | rdc_afull) & !flush) & !pending_wr;
    assign arready = pull_rac;
    assign arvalid = !rac_empty;


    ///////////////////////////////////////////////////////////////////////////
    // AXI4-lite read completion channel
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk) begin
        `ifdef TRACE_CACHE
        if (cache_hit) begin
            $fwrite(f, "@ %0t: Cache hit\n", $realtime);
            $fwrite(f, "  - addr 0x%x\n", araddr_ffd);
            $fwrite(f, "  - data 0x%x\n", cache_rdata);
        end
        if (cache_miss) begin
            $fwrite(f, "@ %0t: Cache miss\n", $realtime);
            $fwrite(f, "  - addr 0x%x\n", araddr_ffd);
        end
        `endif
    end

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (ILEN+AXI_ID_W)
    )
    rdc_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush),
        .data_in  ({arid_ffd, cache_rdata}),
        .push     (push_rdc),
        .full     (rdc_full),
        .afull    (rdc_afull),
        .data_out ({mst_rid, mst_rdata}),
        .pull     (pull_rdc),
        .empty    (rdc_empty),
        .aempty   ()
    );

    assign push_rdc = cache_hit & !flush;
    assign pull_rdc = mst_rready;
    assign mst_rvalid = !rdc_empty;
    assign mst_rresp = 2'b0;

    ///////////////////////////////////////////////////////////////////////////
    // Sequencer to switch between cache load and cache fetch
    ///////////////////////////////////////////////////////////////////////////

    assign fetching = loader == LOAD;

    // FSM sequencer controlling the cache lines and the memory controller
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            loader <= IDLE;
        end else if (srst || flush) begin
            loader <= IDLE;
        end else begin

            case (loader)

                // Wait for the address requests from the instruction fetcher
                default: begin
                    if (cache_miss && !flush) begin
                        loader <= LOAD;
                    end
                end

                // Wait for load a new cache line containing the miss-fetch
                LOAD: begin
                    // Go to read the cache lines once the memory controller
                    // wrote a new cache line, being the read completion
                    if (cache_writing) begin
                        loader <= FETCH;
                    end else if (cache_hit) begin
                        loader <= IDLE;
                    end
                end 

                // Wait state, once write has been deasserted, this state needs to 
                // drive the next address if requested by the master
                FETCH: begin
                    if (!cache_writing)
                        loader <= IDLE;
                end
            endcase
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Flag indicating a memory read request is occuring, waiting for a 
    // completion thus blocking any further execution. Ensures read / write
    // requests sequencing is respected
    ///////////////////////////////////////////////////////////////////////////
    
    // TODO: Check if here address/data channel from master interface shouldn't 
    // be better to use to enforce the read/write ordering
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            pending_rd <= 1'b0;
        end else if (srst) begin
            pending_rd <= 1'b0;
        end else begin
            if (loader==IDLE && !flush && cache_miss) pending_rd <= 1'b1;
            else if (cache_writing) pending_rd <= 1'b0;
        end
    end
endmodule

`resetall
