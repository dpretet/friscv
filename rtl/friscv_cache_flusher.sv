// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// State machine managing cache initialization and cache flush (FENCE.i)
//
///////////////////////////////////////////////////////////////////////////////

module friscv_cache_flusher

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Module name for printing
        parameter NAME = "Cache-Flusher",


        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Cache block width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512,
        // Address width, common with AXI4 bus
        parameter AXI_ADDR_W = 12

    )(
        // Global signals
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Flush interface
        input  wire                       flush_blocks,
        output logic                      flush_ack,
        output logic                      flushing,

        // Control read completion
        output logic                      cache_wren,
        output logic [AXI_ADDR_W    -1:0] cache_waddr,
        output logic [CACHE_BLOCK_W -1:0] cache_wdata
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    localparam MAX_CACHE_ADDR = CACHE_DEPTH << $clog2(CACHE_BLOCK_W/8);

    typedef enum logic[1:0] {
        IDLE = 0,
        FLUSH = 1,
        ACK = 2
    } ctrl_fsm;

    ctrl_fsm cfsm;

    logic blocks_zeroed;


    ///////////////////////////////////////////////////////////////////////////
    // Flush support on FENCE.i instruction execution
    //
    // flush_ack is asserted for one cycle once flush_blocks has been asserted
    // and the entire cache lines have been erased
    ///////////////////////////////////////////////////////////////////////////

    assign cache_wdata = {CACHE_BLOCK_W{1'b0}};

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= IDLE;
            flush_ack <= 1'b0;
            flushing <= 1'b0;
            cache_wren <= 1'b0;
            cache_waddr <= {AXI_ADDR_W{1'b0}};
            blocks_zeroed <= 1'b0;
        end else if (srst == 1'b1) begin
            cfsm <= IDLE;
            flush_ack <= 1'b0;
            flushing <= 1'b0;
            cache_wren <= 1'b0;
            cache_waddr <= {AXI_ADDR_W{1'b0}};
            blocks_zeroed <= 1'b0;
        end else begin

            case (cfsm)
                // Wait for flush request
                default: begin
                    flushing <= 1'b0;
                    flush_ack <= 1'b0;
                    if (flush_blocks || !blocks_zeroed) begin
                        flushing <= 1'b1;
                        cache_wren <= 1'b1;
                        cfsm <= FLUSH;
                    end
                end
                FLUSH: begin
                    flushing <= 1'b1;
                    cache_wren <= 1'b1;
                    // Increment erase address by the number of byte per cache block
                    cache_waddr <= cache_waddr + CACHE_BLOCK_W/8;
                    if (cache_waddr==MAX_CACHE_ADDR) begin
                        blocks_zeroed <= 1'b1;
                        cache_wren <= 1'b0;
                        cache_waddr <= {AXI_ADDR_W{1'b0}};
                        flushing <= 1'b0;
                    flush_ack <= 1'b1;
                        cfsm <= ACK;
                    end
                end
                // Once cache has been erased wait for req deassertion
                ACK: begin
                    flushing <= 1'b0;
                    flush_ack <= 1'b0;
                    cfsm <= IDLE;
                end
            endcase

        end
    end

endmodule

`resetall
