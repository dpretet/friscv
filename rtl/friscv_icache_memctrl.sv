// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Memory controller managing AXI4-lite read request from Fetcher to read
// central memory to fill caches lines.
//
// TODO: support AXI4 transfer with different width than the cache line width
// TODO: support outstanding requests
// TODO: Manage RRESP
//
///////////////////////////////////////////////////////////////////////////////

module friscv_icache_memctrl

    #(
        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 10,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 128,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Line width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512

    )(
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        input  logic                      flush_req,
        output logic                      flush_ack,
        output logic                      flush,
        // ctrlruction memory interface
        input  logic                      ctrl_arvalid,
        output logic                      ctrl_arready,
        input  logic [AXI_ADDR_W    -1:0] ctrl_araddr,
        input  logic [3             -1:0] ctrl_arprot,
        input  logic [AXI_ID_W      -1:0] ctrl_arid,
        // AXI4 Read channels interface to central memory
        output logic                      mem_arvalid,
        input  logic                      mem_arready,
        output logic [AXI_ADDR_W    -1:0] mem_araddr,
        output logic [8             -1:0] mem_arlen,
        output logic [3             -1:0] mem_arsize,
        output logic [2             -1:0] mem_arburst,
        output logic [2             -1:0] mem_arlock,
        output logic [4             -1:0] mem_arcache,
        output logic [3             -1:0] mem_arprot,
        output logic [4             -1:0] mem_arqos,
        output logic [4             -1:0] mem_arregion,
        output logic [AXI_ID_W      -1:0] mem_arid,
        input  logic                      mem_rvalid,
        output logic                      mem_rready,
        input  logic [AXI_ID_W      -1:0] mem_rid,
        input  logic [2             -1:0] mem_rresp,
        input  logic [AXI_DATA_W    -1:0] mem_rdata,
        input  logic                      mem_rlast,
        // Cache lines write interface
        output logic                      cache_wen,
        output logic [AXI_ADDR_W    -1:0] cache_waddr,
        output logic [CACHE_BLOCK_W -1:0] cache_wdata
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    // Control fsm
    typedef enum logic[1:0] {
        IDLE = 0,
        FLUSH = 1,
        ACK = 2
    } ctrl_fsm;

    ctrl_fsm cfsm;

    // Used on flush request to erase the cache content
    logic                erase_wen;
    logic [AXI_ADDR_W:0] erase_addr;


    ///////////////////////////////////////////////////////////////////////////
    // Optional signals, unused and tied to recommended default values
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arregion = 4'b0;
    assign mem_arlock = 2'b0;
    assign mem_arcache = 4'b0;
    assign mem_arqos = 4'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Hardcoded setup
    ///////////////////////////////////////////////////////////////////////////

    // Always use INCR mode
    assign mem_arburst = 2'b01;

    // Issue only transfer with a single dataphase
    assign mem_arlen = 8'b0;

    // Fixeds ASIZE, narrow transfers are not supported neither necessary
    assign mem_arsize = (AXI_DATA_W/8 ==  1) ? 3'b000:
                        (AXI_DATA_W/8 ==  2) ? 3'b001:
                        (AXI_DATA_W/8 ==  4) ? 3'b010:
                        (AXI_DATA_W/8 ==  8) ? 3'b011:
                        (AXI_DATA_W/8 == 16) ? 3'b100:
                        (AXI_DATA_W/8 == 32) ? 3'b101:
                        (AXI_DATA_W/8 == 64) ? 3'b110:
                                               3'b111;


    ///////////////////////////////////////////////////////////////////////////
    // Drive AXI4 read address channel directly from AXI4-lite
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arvalid = ctrl_arvalid;
    assign ctrl_arready = mem_arready;
    assign mem_araddr = ctrl_araddr;
    assign mem_arprot = ctrl_arprot;
    assign mem_arid = ctrl_arid;

    // TODO: Drive properly
    assign mem_rready = 1'b1;


    ///////////////////////////////////////////////////////////////////////////
    // Cache write
    ///////////////////////////////////////////////////////////////////////////

    assign cache_wen = (cfsm==IDLE) ? mem_rvalid : erase_wen;
    assign cache_waddr = (cfsm==IDLE) ? ctrl_araddr : erase_addr[AXI_ADDR_W-1:0];
    assign cache_wdata = mem_rdata;


    ///////////////////////////////////////////////////////////////////////////
    // Flush support on FENCE.i instruction execution
    //
    // flush_ack is asserted for one cycle once flush_req has been asserted and
    // the entire cache lines have been erased
    ///////////////////////////////////////////////////////////////////////////


    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= IDLE;
            flush_ack <= 1'b0;
            flush <= 1'b0;
            erase_wen <= 1'b0;
            erase_addr <= {AXI_ADDR_W+1{1'b0}};
        end else if (srst == 1'b1) begin
            cfsm <= IDLE;
            flush_ack <= 1'b0;
            flush <= 1'b0;
            erase_wen <= 1'b0;
            erase_addr <= {AXI_ADDR_W+1{1'b0}};
        end else begin

            case (cfsm)
                // Wait for flush request
                default: begin
                    flush <= 1'b0;
                    flush_ack <= 1'b0;
                    if (flush_req) begin
                        erase_wen <= 1'b1;
                        cfsm <= FLUSH;
                    end
                end
                FLUSH: begin
                    flush <= 1'b1;
                    erase_wen <= 1'b1;
                    erase_addr <= erase_addr + CACHE_BLOCK_W/8;
                    if (erase_addr==CACHE_DEPTH) begin
                        erase_wen <= 1'b0;
                        erase_addr <= {AXI_ADDR_W+1{1'b0}};
                        flush <= 1'b0;
                        cfsm <= ACK;
                    end
                end
                // Once cache has been erased wait for req deassertion
                ACK: begin
                    flush <= 1'b0;
                    if (~flush_req) begin
                        flush_ack <= 1'b0;
                        cfsm <= IDLE;
                    end else  begin
                        flush_ack <= 1'b1;
                    end
                end
            endcase

        end
    end

endmodule

`resetall
