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


module friscv_icache_fetcher

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // Enable pipeline on cache
        //   - bit 0: Use pass-thru mode in fetcher's FIFOs
        parameter CACHE_PIPELINE = 32'h00000000,

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
        // Flush control
        input  wire                       flush_req,
        output logic                      flush_ack,
        // Control unit interface
        input  wire                       ctrl_arvalid,
        output logic                      ctrl_arready,
        input  wire  [AXI_ADDR_W    -1:0] ctrl_araddr,
        input  wire  [3             -1:0] ctrl_arprot,
        input  wire  [AXI_ID_W      -1:0] ctrl_arid,
        output logic                      ctrl_rvalid,
        input  wire                       ctrl_rready,
        output logic [AXI_ID_W      -1:0] ctrl_rid,
        output logic [2             -1:0] ctrl_rresp,
        output logic [ILEN          -1:0] ctrl_rdata,
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
    localparam PASS_THRU_MODE = CACHE_PIPELINE[0];

    // Control fsm, the sequencer driving the cache read and the memory controller
    typedef enum logic[2:0] {
        IDLE = 0,
        SERVE = 1,
        LOAD = 2,
        MISSED = 3,
        FLUSH = 4
    } seq_fsm;

    seq_fsm seq;

    // Sync reset controlled on flush request
    logic                     flush_fifo;
    // Synch reset asserted when core controller changes the ARID
    logic                     reboot;
    logic [AXI_ID_W     -1:0] arid_reboot;

    // Signals driving the FIFO buffering the to-fetch instruction
    logic                     fifo_full_if;
    logic                     pull_addr_if;
    logic                     fifo_empty_if;
    // Signals driving the missed-fetch instruction
    logic                     fifo_full_mf;
    logic                     pull_addr_mf;
    logic                     fifo_empty_mf;
    logic                     rvalid_r;

    // Instruction fetch address and ID read from the FIFO
    // buffering the instruction fetch stage
    logic [AXI_ADDR_W   -1:0] araddr_if;
    logic [AXI_ID_W     -1:0] arid_if;

    // Miss-fetched instruction and address, to read again once the
    // memory controller will fill the cache
    logic [AXI_ADDR_W   -1:0] araddr_mf;
    logic [AXI_ID_W     -1:0] arid_mf;

    // Pipeline stage to move back data to AXI4-lite and to missed-fecth FIFO
    logic [AXI_ADDR_W   -1:0] araddr_ffd;
    logic [AXI_ID_W     -1:0] arid_ffd;
    logic [AXI_ID_W     -1:0] cache_rid;

    // Logger setup
    `ifdef USE_SVL
    `include "svlogger.sv"
    svlogger log;
    initial log = new("iCache-Fetcher",
                      `ICACHE_VERBOSITY,
                      `ICACHE_ROUTE);
    `endif

    ///////////////////////////////////////////////////////////////////////////
    // Buffering stage
    ///////////////////////////////////////////////////////////////////////////

    // Reboot is asserted when core controller is jumping/branching and so
    // change the ARID. Flush the FIFOs on this event
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) arid_reboot <= {AXI_ID_W{1'b0}};
        else if (srst) arid_reboot <= {AXI_ID_W{1'b0}};
        else arid_reboot <= ctrl_arid;
    end

    assign reboot = (ctrl_arid!=arid_reboot) ? 1'b1 : 1'b0;

    // FIFO buffering the instruction to fetch from the controller
    friscv_scfifo
    #(
        .PASS_THRU (PASS_THRU_MODE),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    if_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush_fifo | reboot),
        .data_in  ({ctrl_arid, ctrl_araddr}),
        .push     (ctrl_arvalid),
        .full     (fifo_full_if),
        .data_out ({arid_if, araddr_if}),
        .pull     (pull_addr_if & ctrl_rready),
        .empty    (fifo_empty_if)
    );

    // FFD stage to propagate potential addr/id to fetch
    // later in cache miss
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
        end else if (srst || reboot) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
        end else begin
            araddr_ffd <= cache_raddr;
            arid_ffd <= cache_rid;
        end
    end

    // FIFO buffering missed-fetch instructions,
    // depth can store up to 2 missed instruction
    friscv_scfifo
    #(
        .PASS_THRU (PASS_THRU_MODE),
        .ADDR_WIDTH ($clog2(MF_FIFO_DEPTH)),
        .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    mf_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush_fifo | reboot),
        .data_in  ({arid_ffd, araddr_ffd}),
        .push     (cache_miss),
        .full     (fifo_full_mf),
        .data_out ({arid_mf, araddr_mf}),
        .pull     (pull_addr_mf & ctrl_rready),
        .empty    (fifo_empty_mf)
    );

    // Read cache when the FIFO is filled or when missed-fetch instruction
    // occured, but never if the cache is rebooting.
    assign cache_ren = ((~fifo_empty_if && (seq==IDLE || seq==SERVE)) ||
                        (~fifo_empty_mf && (seq==MISSED))
                       ) ? ~reboot & ctrl_rready : 1'b0;

    // Multiplexer stage to drive missed-fetch or to-fetch requests
    assign cache_raddr = (~fifo_empty_mf) ? araddr_mf : araddr_if;
    assign cache_rid = (~fifo_empty_mf) ? arid_mf : arid_if;


    ///////////////////////////////////////////////////////////////////////////
    // Control flow
    ///////////////////////////////////////////////////////////////////////////

    // FSM sequencer controlling the cache lines and the memory controller
    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            pull_addr_if <= 1'b0;
            pull_addr_mf <= 1'b0;
            memctrl_arvalid <= 1'b0;
            memctrl_araddr <= {AXI_ADDR_W{1'b0}};
            memctrl_arid <= {AXI_ID_W{1'b0}};
            flush_fifo <= 1'b0;
            flush_ack <= 1'b0;
            seq <= IDLE;
        end else if (srst) begin
            pull_addr_if <= 1'b0;
            pull_addr_mf <= 1'b0;
            memctrl_arvalid <= 1'b0;
            memctrl_araddr <= {AXI_ADDR_W{1'b0}};
            memctrl_arid <= {AXI_ID_W{1'b0}};
            flush_fifo <= 1'b0;
            flush_ack <= 1'b0;
            seq <= IDLE;
        end else begin

            if (flush_ack) begin
                // flush is done in 1 cycle in fetcher, wait req
                // deassertion then go back to IDLE to reboot
                flush_fifo <= 1'b0;
                if (flush_req==1'b0) begin
                    `ifdef USE_SVL
                    log.debug("Finished flush procedure");
                    `endif
                    pull_addr_if <= 1'b1;
                    flush_ack <= 1'b0;
                    seq <= IDLE;
                end
            end else if (flush_req) begin
                pull_addr_if <= 1'b0;
                pull_addr_mf <= 1'b0;
                flush_fifo <= 1'b1;
                flush_ack <= 1'b1;
            end else begin

                case (seq)
                    // Wait for the address requests from the instruction fetcher
                    default: begin
                        pull_addr_if <= 1'b1;
                        pull_addr_mf <= 1'b0;
                        if (~fifo_empty_if) begin
                            `ifdef USE_SVL
                            log.debug("Start to serve");
                            `endif
                            seq <= SERVE;
                        end
                    end
                    // State to serve the instruction read request from the
                    // core controller
                    SERVE: begin
                        // Move back to IDLE if ARID changed, meaning the 
                        // control is jumping to another memory location
                        if (reboot) begin
                            pull_addr_if <= 1'b0;
                            pull_addr_mf <= 1'b0;
                            seq <= IDLE;
                        // As soon a cache miss is detected, stop to pull the
                        // FIFO and move to read the AXI4 interface to grab the
                        // missing instruction
                        end else if (cache_miss) begin
                            `ifdef USE_SVL
                            log.debug("Cache miss");
                            `endif
                            pull_addr_if <= 1'b0;
                            memctrl_arvalid <= 1'b1;
                            memctrl_araddr <= araddr_ffd;
                            memctrl_arid <= arid_ffd;
                            seq <= LOAD;
                        // When empty, go back to IDLE to wait new requests
                        end else if (fifo_empty_if) begin
                            `ifdef USE_SVL
                            log.debug("Go back to IDLE");
                            `endif
                            seq <= IDLE;
                        end
                    end
                    // State to fetch the missed-fetch instruction in the
                    // dedicated FIFO. Empties it, possibiliy along several epochs
                    // Equivalent behavior than SERVE state.
                    // TODO: Try to merge FETCH and MISS states
                    MISSED: begin
                        // Move back to IDLE if ARID changed, meaning the 
                        // control is jumping to another memory location
                        if (reboot) begin
                            pull_addr_if <= 1'b0;
                            pull_addr_mf <= 1'b0;
                            seq <= IDLE;
                        // As soon a cache miss is detected, stop to pull the
                        // FIFO and move to read the AXI4 interface to grab the
                        // missing instruction
                        end else if (cache_miss) begin
                            `ifdef USE_SVL
                            log.debug("Cache miss");
                            `endif
                            pull_addr_mf <= 1'b0;
                            memctrl_arvalid <= 1'b1;
                            memctrl_araddr <= araddr_ffd;
                            memctrl_arid <= arid_ffd;
                            seq <= LOAD;
                        // If other instruction fetchs have been issue,
                        // continue to serve the core controller
                        end else if (~fifo_empty_if && fifo_empty_mf) begin
                            `ifdef USE_SVL
                            log.debug("Go to to-fetch state");
                            `endif
                            pull_addr_if <= 1'b1;
                            pull_addr_mf <= 1'b0;
                            seq <= SERVE;
                        // When empty, go back to IDLE to wait new requests
                        end else if (fifo_empty_mf) begin
                            `ifdef USE_SVL
                            log.debug("Go back to IDLE");
                            `endif
                            pull_addr_mf <= 1'b0;
                            seq <= IDLE;
                        end
                    end
                    // Fetch a new instruction in external memory
                    LOAD: begin

                        // Handshaked with memory controller, now
                        // wait for the write stage to restart
                        if (memctrl_arvalid && memctrl_arready) begin
                            `ifdef USE_SVL
                            log.debug("Read memory");
                            `endif
                            memctrl_arvalid <= 1'b0;
                        end

                        // If a reboot has been initiated, move back to IDLE
                        // to avoid a race condition which will fetch twice 
                        // the next first instruction
                        if (reboot) begin
                            seq <= IDLE;
                        // Go to read the cache lines once the memory controller
                        // wrote a new cache line, the read completion
                        end else if (cache_writing) begin
                            `ifdef USE_SVL
                            log.debug("Go to missed-fetch state");
                            `endif
                            pull_addr_mf <= 1'b1;
                            seq <= MISSED;
                        end
                    end
                endcase
            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // AXI4-lite interface management
    ///////////////////////////////////////////////////////////////////////////


    // Read address request handshake if able to receive
    assign ctrl_arready = (~fifo_full_if && ~reboot) ? 1'b1 : 1'b0;

    // Manage read data channel back-pressure in case RVALID has been
    // asserted but RREADY wasn't asserted. RDATA stay stable, even after
    // RVALID has been deasserted, RVALID is asserted only one cycle
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rvalid_r <= 1'b0;
        end else if (srst) begin
            rvalid_r <= 1'b0;
        end else begin
            if (ctrl_rvalid && !ctrl_rready) rvalid_r <= 1'b1;
            else rvalid_r <= 1'b0;
        end
    end

    assign ctrl_rvalid = cache_hit | rvalid_r;
    assign ctrl_rdata = cache_rdata;
    assign ctrl_rresp = 2'b0;
    assign ctrl_rid = arid_ffd;

    // Just transmit, and not managed at all in the core
    assign memctrl_arprot = ctrl_arprot;

endmodule

`resetall
