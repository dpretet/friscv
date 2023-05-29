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


module friscv_cache_prefetcher

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Name used for tracer file name
        parameter NAME = "prefetcher",
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // RISCV Architecture
        parameter XLEN = 32,

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
        // Memory controller read interface
        output logic                      memctrl_arvalid,
        input  wire                       memctrl_arready,
        output logic [AXI_ADDR_W    -1:0] memctrl_araddr,
        output logic [3             -1:0] memctrl_arprot,
        output logic [AXI_ID_W      -1:0] memctrl_arid,
        // Cache line read interface
        input  wire                       cache_writing,
        input  wire                       cache_ren,
        input  wire  [AXI_ADDR_W    -1:0] cache_raddr,
        input  wire  [AXI_ID_W      -1:0] cache_rid,
        input  wire  [3             -1:0] cache_rprot,
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

    // FFD stage to propagate potential addr/id to fetch
    // later in cache miss
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
            arprot_ffd <= '0;
        end else if (srst) begin
            araddr_ffd <= {AXI_ADDR_W{1'b0}};
            arid_ffd <= {AXI_ID_W{1'b0}};
            arprot_ffd <= '0;
        end else begin
            araddr_ffd <= cache_raddr;
            arid_ffd <= cache_rid;
            arprot_ffd <= cache_rprot;
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Memory controller management and prefetch stage
    ///////////////////////////////////////////////////////////////////////////


    // FSM sequencer controlling the cache lines and the memory controller
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
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

            case (loader)

                // Wait for the address requests from the instruction fetcher
                default: begin
                    if (cache_miss) begin
                        memctrl_arvalid <= 1'b1;
                        // Always fetch a complete cache blocks
                        // TODO: Adapt based on cache block vs axi data width
                        memctrl_araddr <= {araddr_ffd[AXI_ADDR_W-1:ADDR_LSB_W],{ADDR_LSB_W{1'b0}}};
                        memctrl_arid <= arid_ffd;
                        memctrl_arprot <= arprot_ffd;
                        loader <= LOAD;
                    end else begin
                        memctrl_arvalid <= 1'b0;
                    end
                end

                // Load a new cache line containing the miss-fetch
                LOAD: begin

                    // Handshaked with memory controller, now
                    // wait for the write stage to restart
                    if (memctrl_arvalid && memctrl_arready) begin
                        `ifdef TRACE_CACHE
                        $fwrite(f, "@ %0t: Fetch memory - Addr=0x%x\n", $realtime, memctrl_araddr);
                        `endif
                        memctrl_arvalid <= 1'b0;
                    end

                    // Go to read the cache lines once the memory controller
                    // wrote a new cache line, being the read completion
                    if (cache_writing) begin
                        `ifdef TRACE_CACHE
                        $fwrite(f, "@ %0t: Read completion received\n", $realtime);
                        `endif
                        loader <= FETCH;
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


endmodule

`resetall
