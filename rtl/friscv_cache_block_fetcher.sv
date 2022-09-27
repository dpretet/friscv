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
// Composed by two FIFOs, the first buffers the incoming requests from
// the fetch stage of the controller, the second buffers the missed
// entries in the cache.
//
// A sequencer drives the cache read and the memory controller
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
        // Flush control to clear outstanding request in buffers
        input  wire                       flush_reqs,
        // Flush control to execute FENCE.i
        input  wire                       flush_blocks,
        output logic                      flush_ack,
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
        // Memory controller read interface
        output logic                      memctrl_arvalid,
        input  wire                       memctrl_arready,
        output logic [AXI_ADDR_W    -1:0] memctrl_araddr,
        output logic [3             -1:0] memctrl_arprot,
        output logic [AXI_ID_W      -1:0] memctrl_arid,
        // Cache line read interface
        input  wire                       cache_writing,
        output logic                      cache_ren,
        output logic [AXI_ADDR_W    -1:0] cache_raddr,
        input  wire  [ILEN          -1:0] cache_rdata,
        input  wire                       cache_hit,
        input  wire                       cache_miss
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    ///////////////////////////////////////////////////////////////////////////

    // Missed-fetch FIFO depth
    localparam MF_FIFO_DEPTH = 8;
    localparam PASS_THRU_MODE = 0;

    // Control fsm, the sequencer driving the cache read and the memory controller
    typedef enum logic[2:0] {
        IDLE = 0,
        FETCH = 1,
        MISSED = 2,
        LOAD = 3
    } seq_fsm;

    seq_fsm seq;
    seq_fsm loader;

    // Signals driving the FIFO buffering the to-fetch instruction
    logic                     fifo_full_if;
    logic                     read_addr_if;
    logic                     pull_addr_if;
    logic                     push_addr_if;
    logic                     fifo_empty_if;
    // Signals driving the missed-fetch instruction
    logic                     fifo_full_mf;
    logic                     read_addr_mf;
    logic                     pull_addr_mf;
    logic                     push_addr_mf;
    logic                     fifo_empty_mf;
    logic                     rvalid_r;

    // Instruction fetch address and ID read from the FIFO
    // buffering the instruction fetch stage
    logic [AXI_ADDR_W   -1:0] araddr_if;
    logic [AXI_ID_W     -1:0] arid_if;
    logic [3            -1:0] arprot_if;

    // Miss-fetched instruction and address, to read again once the
    // memory controller will fill the cache
    logic [AXI_ADDR_W   -1:0] araddr_mf;
    logic [AXI_ID_W     -1:0] arid_mf;
    logic [3            -1:0] arprot_mf;

    // Pipeline stage to move back data to AXI4-lite and to missed-fecth FIFO
    logic [AXI_ADDR_W   -1:0] araddr_ffd;
    logic [AXI_ID_W     -1:0] arid_ffd;
    logic [3            -1:0] arprot_ffd;
    logic [AXI_ID_W     -1:0] cache_rid;
    logic [3            -1:0] cache_prot;
    logic [ILEN         -1:0] rdata_r;
    logic [AXI_ID_W     -1:0] rid_r;
    `ifdef TRACE_CACHE
    logic [AXI_ADDR_W   -1:0] araddr_r;
    `endif

    // A flag to drive all request to miss fetch FIFO in case a first
    // read in the block in a burst read
    logic                     cache_miss_r;
    // flag tracking a read request has been issued
    logic                     cache_loading;

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

    // FIFO buffering the instruction to fetch from the controller
    friscv_scfifo
    #(
        .PASS_THRU (PASS_THRU_MODE),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (3+AXI_ADDR_W+AXI_ID_W)
    )
    if_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush_blocks | flush_reqs),
        .data_in  ({mst_arprot, mst_arid, mst_araddr}),
        .push     (push_addr_if),
        .full     (fifo_full_if),
        .afull    (),
        .data_out ({arprot_if, arid_if, araddr_if}),
        .pull     (pull_addr_if),
        .empty    (fifo_empty_if),
        .aempty   ()
    );

    assign push_addr_if = mst_arvalid;
    assign pull_addr_if = read_addr_if & mst_rready & !cache_loading & !pending_wr;

    // FFD stage to propagate potential addr/id to fetch
    // later in cache miss
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
            arprot_ffd <= 3'b0;
        end else if (srst || flush_reqs) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
            arprot_ffd <= 3'b0;
        end else begin
            araddr_ffd <= cache_raddr;
            arid_ffd <= cache_rid;
            arprot_ffd <= cache_prot;
        end
    end

    // FIFO buffering missed-fetch instructions,
    // depth can store up to 2 missed instruction
    friscv_scfifo
    #(
        .PASS_THRU (PASS_THRU_MODE),
        .ADDR_WIDTH ($clog2(MF_FIFO_DEPTH)),
        .DATA_WIDTH (3+AXI_ADDR_W+AXI_ID_W)
    )
    mf_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush_blocks | flush_reqs),
        .data_in  ({arprot_ffd, arid_ffd, araddr_ffd}),
        .push     (push_addr_mf),
        .full     (fifo_full_mf),
        .afull    (),
        .data_out ({arprot_mf, arid_mf, araddr_mf}),
        .pull     (pull_addr_mf),
        .empty    (fifo_empty_mf),
        .aempty   ()
    );

    assign push_addr_mf = cache_miss | cache_miss_r & cache_hit;
    assign pull_addr_mf = read_addr_mf & mst_rready;

    // Read cache when the FIFO is filled or when missed-fetch instruction
    // occured, but never if the cache is rebooting.
    assign cache_ren = ((!fifo_empty_if && (seq==IDLE && !cache_loading && !pending_wr || seq==FETCH)) ||
                        (!fifo_empty_mf && (seq==MISSED))
                       ) ? !flush_reqs & !flush_blocks & mst_rready : 1'b0;

    // Multiplexer stage to drive missed-fetch or to-fetch requests
    assign cache_raddr = (!fifo_empty_mf) ? araddr_mf : araddr_if;
    assign cache_rid = (!fifo_empty_mf) ? arid_mf : arid_if;
    assign cache_prot = (!fifo_empty_mf) ? arprot_mf : arprot_if;

    // Pending read request flag, indicating some read completion still need to be issued
    assign pending_rd = !fifo_empty_mf | cache_loading;

    // Read address request handshake if able to receive
    assign mst_arready = (~fifo_full_if && ~flush_reqs) ? 1'b1 : 1'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Control flow to fetch request between to-fetch and miss-fetch FIFOs
    ///////////////////////////////////////////////////////////////////////////

    // FSM sequencer controlling the FIFOs and the cache blocks
    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            read_addr_if <= 1'b0;
            read_addr_mf <= 1'b0;
            flush_ack <= 1'b0;
            cache_miss_r <= 1'b0;
            seq <= IDLE;
        end else if (srst) begin
            read_addr_if <= 1'b0;
            read_addr_mf <= 1'b0;
            flush_ack <= 1'b0;
            cache_miss_r <= 1'b0;
            seq <= IDLE;
        end else begin

            ////////////////////////////////////////////////////////////
            // First part of the process manages the flushing procedures
            ////////////////////////////////////////////////////////////

            // A flush block procedure is occuring
            if (flush_ack) begin
                // flush is done in 1 cycle in fetcher, wait req deassertion from the memory
                // controller then go back to IDLE and reboot
                if (flush_blocks==1'b0) begin
                    `ifdef TRACE_CACHE
                    $fwrite(f, "@ %0t: Finished flush procedure\n", $realtime);
                    `endif
                    flush_ack <= 1'b0;
                end
            // Must start a flush block procedure, this module clears its buffers while the
            // memory controller clear the cache blocks
            end else if (flush_blocks) begin
                read_addr_if <= 1'b0;
                read_addr_mf <= 1'b0;
                flush_ack <= 1'b1;
                cache_miss_r <= 1'b0;
                seq <= IDLE;
            // Move back to IDLE if the requester wants to move to a new batch of read requests.
            // Can occur if it wants to jump in a new memory location for instance
            end else if (flush_reqs) begin
                read_addr_if <= 1'b0;
                read_addr_mf <= 1'b0;
                cache_miss_r <= 1'b0;
                seq <= IDLE;

            //////////////////////////////////////////////////////////////
            // Second part manages the FIFOs read and cache read sequences
            //////////////////////////////////////////////////////////////

            end else begin
                case (seq)
                    // IDLE: Wait for the address requests from the front-end FIFO
                    default: begin
                        read_addr_if <= 1'b1;
                        read_addr_mf <= 1'b0;
                        cache_miss_r <= 1'b0;
                        if (!fifo_empty_if && !cache_loading && !pending_wr) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Start to serve\n", $realtime);
                            `endif
                            seq <= FETCH;
                        end
                    end
                    // State to serve the instruction read request from the core controller
                    FETCH: begin

                        // As soon a cache miss is detected, stop to pull the
                        // FIFO and move to read the AXI4 interface to grab the
                        // missing instruction
                        if (cache_miss) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Cache miss - Addr=0x%x\n", $realtime, araddr_ffd);
                            `endif
                            cache_miss_r <= 1'b1;
                            read_addr_if <= 1'b0;
                            seq <= LOAD;
                        // When empty, go back to IDLE to wait new requests
                        end else if (fifo_empty_if) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Go back to IDLE state\n", $realtime);
                            `endif
                            seq <= IDLE;
                        end
                    end
                    // State to fetch the missed-fetch instruction in the
                    // dedicated FIFO. Empties it, possibiliy along several epochs
                    // Equivalent behavior than FETCH state.
                    MISSED: begin

                        // As soon a cache miss is detected, stop to pull the
                        // FIFO and move to read the AXI4 interface to grab the
                        // missing instruction
                        if (cache_miss) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Cache miss - Addr=0x%x\n", $realtime, araddr_ffd);
                            `endif
                            cache_miss_r <= 1'b1;
                            read_addr_mf <= 1'b0;
                            seq <= LOAD;
                        // If other instruction fetchs have been issue,
                        // continue to serve the core controller
                        end else if (!fifo_empty_if && fifo_empty_mf) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Go to FETCH state\n", $realtime);
                            `endif
                            read_addr_if <= 1'b1;
                            read_addr_mf <= 1'b0;
                            seq <= FETCH;
                        // When empty, go back to IDLE to wait new requests
                        end else if (fifo_empty_mf) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Go back to IDLE state\n", $realtime);
                            `endif
                            read_addr_if <= 1'b1;
                            read_addr_mf <= 1'b0;
                            seq <= IDLE;
                        end
                    end

                    // Fetch a new instruction in external memory
                    LOAD: begin

                        // Go to read the cache lines once the memory controller
                        // wrote a new cache line
                        if (cache_writing) begin
                            `ifdef TRACE_CACHE
                            $fwrite(f, "@ %0t: Go to missed-fetch state\n", $realtime);
                            `endif
                            read_addr_mf <= 1'b1;
                            cache_miss_r <= 1'b0;
                            seq <= MISSED;
                        end
                    end
                endcase
            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // AXI4-lite read completion channel
    ///////////////////////////////////////////////////////////////////////////


    // Manage read data channel back-pressure in case RVALID has been
    // asserted but RREADY wasn't asserted. RDATA stay stable, even after
    // RVALID has been deasserted, RVALID is asserted only one cycle
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rvalid_r <= 1'b0;
            rid_r <= {AXI_ID_W{1'b0}};
            rdata_r <= {ILEN{1'b0}};
            `ifdef TRACE_CACHE
            araddr_r <= {AXI_ADDR_W{1'b0}};
            `endif
        end else if (srst | flush_blocks) begin
            rvalid_r <= 1'b0;
            rid_r <= {AXI_ID_W{1'b0}};
            rdata_r <= {ILEN{1'b0}};
            `ifdef TRACE_CACHE
            araddr_r <= {AXI_ADDR_W{1'b0}};
            `endif
        end else begin
            if (mst_rvalid && !mst_rready) rvalid_r <= 1'b1;
            else rvalid_r <= 1'b0;

            if (rvalid_r==1'b0) begin
                rdata_r <= cache_rdata;
                rid_r <= arid_ffd;
                `ifdef TRACE_CACHE
                araddr_r <= araddr_ffd;
                `endif
            end
            `ifdef TRACE_CACHE
            if (mst_rvalid && mst_rready) begin
                $fwrite(f, "@ %0t: Cache hit\n", $realtime);
                if (rvalid_r)
                    $fwrite(f, "  - addr 0x%x\n", araddr_r);
                else
                    $fwrite(f, "  - addr 0x%x\n", araddr_ffd);
                $fwrite(f, "  - data 0x%x\n", mst_rdata);
            end
            `endif
        end
    end

    assign mst_rvalid = (cache_hit & !cache_miss_r | rvalid_r);
    assign mst_rdata = (rvalid_r) ? rdata_r : cache_rdata;
    assign mst_rresp = 2'b0;
    assign mst_rid = (rvalid_r) ? rid_r : arid_ffd;


    ///////////////////////////////////////////////////////////////////////////
    // Memory controller management
    ///////////////////////////////////////////////////////////////////////////

    // FSM sequencer controlling the cache lines and the memory controller
    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            memctrl_arvalid <= 1'b0;
            memctrl_araddr <= {AXI_ADDR_W{1'b0}};
            memctrl_arid <= {AXI_ID_W{1'b0}};
            memctrl_arprot <= 3'b0;
            loader <= IDLE;
        end else if (srst) begin
            memctrl_arvalid <= 1'b0;
            memctrl_araddr <= {AXI_ADDR_W{1'b0}};
            memctrl_arid <= {AXI_ID_W{1'b0}};
            memctrl_arprot <= 3'b0;
            loader <= IDLE;
        end else begin

            case (seq)
                // Wait for the address requests from the instruction fetcher
                default: begin
                    if (cache_miss) begin
                        memctrl_arvalid <= 1'b1;
                        memctrl_araddr <= araddr_ffd;
                        memctrl_arid <= arid_ffd;
                        memctrl_arprot <= arprot_ffd;
                        loader <= LOAD;
                    end else begin
                        memctrl_arvalid <= 1'b0;
                    end
                end
                // Fetch a new instruction in external memory
                LOAD: begin

                    // Handshaked with memory controller, now
                    // wait for the write stage to restart
                    if (memctrl_arvalid && memctrl_arready) begin
                        `ifdef TRACE_CACHE
                        $fwrite(f, "@ %0t: Read memory - Addr=0x%x\n", $realtime, memctrl_araddr);
                        `endif
                        memctrl_arvalid <= 1'b0;
                    end

                    // If a reboot has been initiated, move back to IDLE
                    // to avoid a race condition which will fetch twice
                    // the next first instruction
                    if (flush_reqs || flush_blocks) begin
                        loader <= IDLE;
                        memctrl_arvalid <= 1'b0;
                    // Go to read the cache lines once the memory controller
                    // wrote a new cache line, the read completion
                    end else if (cache_writing) begin
                        `ifdef TRACE_CACHE
                        $fwrite(f, "@ %0t: Read completion received\n", $realtime);
                        `endif
                        loader <= IDLE;
                    end
                end
            endcase
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // Flag indicating a memory read request is occuring, waiting for a 
    // completion thus blocking any further execution
    ///////////////////////////////////////////////////////////////////////////
    
    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cache_loading <= 1'b0;
        end else if (srst == 1'b1) begin
            cache_loading <= 1'b0;
        end else begin
            if (memctrl_arready && memctrl_arvalid) cache_loading <= 1'b1;
            else if (cache_writing) cache_loading <= 1'b0;
        end
    end
endmodule

`resetall
