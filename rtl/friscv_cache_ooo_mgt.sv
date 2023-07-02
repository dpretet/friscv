// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
//
// Read completer circuit:
// ----------------------
//
// Tracks the read request and manage the read completion reordering. Two inputs
// from IO fetcher and block fetcher issue some read requests, then block fetcher
// and memory controller complete them, but possibly out-of-order. This module 
// manages the in-order completion.
//
// A first stage records the read request (address and ID) and compute the next 
// available tag. The next tag output will be used by fetchers to substitute the
// original tag and manage easier the completion reordering.
//
// The second stage receives the read data channels and record the completion
// information. 
//
// The third layer serves the read data channel moving back to the application
// and frees the next tag usable.
//////////////////////////////////////////////////////////////////////////////////

module friscv_cache_ooo_mgt

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // Module name for printing
        parameter NAME = "dCache-OoO-Mgt",
        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 128,
        // ID Mask to apply to identify the data cache in the AXI4 infrastructure
        parameter AXI_ID_MASK = 'h20,
        // Force read completion reordering
        parameter AXI_ID_FIXED = 1,
        // Read data channel doesn't assert back-pressure, can drive completion directly
        parameter NO_RDC_BACKPRESSURE = 0
    )(
        // Global interface
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,

        // Next tag usable, substituted in place of original tag in fetchers' input
        output logic [AXI_ID_W      -1:0] next_tag,
        // Next tag is available
        output logic                      tag_avlb,
        // Status flag for ordering rules
        output logic                      pending_rd,

        // IO / block fetchers' read address channel
        input  wire                       slv_arvalid,
        input  wire                       slv_arready,
        input  wire  [AXI_ADDR_W    -1:0] slv_araddr,
        input  wire  [AXI_ID_W      -1:0] slv_arid,
        input  wire  [4             -1:0] slv_arcache,

        // Block fetcher read data channel
        input  wire                       blk_fetcher_rvalid,
        output logic                      blk_fetcher_rready,
        input  wire  [AXI_ID_W      -1:0] blk_fetcher_rid,
        input  wire  [2             -1:0] blk_fetcher_rresp,
        input  wire  [XLEN          -1:0] blk_fetcher_rdata,

        // Memory controller read data channel, completing IO fetcher request
        input  wire                       io_fetcher_rvalid,
        output logic                      io_fetcher_rready,
        input  wire  [AXI_ID_W      -1:0] io_fetcher_rid,
        input  wire  [2             -1:0] io_fetcher_rresp,
        input  wire  [XLEN          -1:0] io_fetcher_rdata,

        // Read completion channel, going back to application
        output logic                      mst_rvalid,
        input  wire                       mst_rready,
        output logic [AXI_ID_W      -1:0] mst_rid,
        output logic [2             -1:0] mst_rresp,
        output logic [XLEN          -1:0] mst_rdata
    );

    //////////////////////////////////////////////////////////////////////////
    // Signals and parameters
    //////////////////////////////////////////////////////////////////////////

    localparam [1:0] RSVD = 2'b01;
    localparam [1:0] RCVD = 2'b11;
    localparam [1:0] FREE = 2'b00;
    localparam [1:0] ILGL = 2'b10;
    localparam       REQ = 0;
    localparam       CPL = 1;

    localparam NB_TAG = OSTDREQ_NUM;
    localparam NB_TAG_W = $clog2(NB_TAG);
    localparam MAX_TAG = NB_TAG - 1;

    // RAMs width
    localparam META_W = AXI_ID_W;
    localparam CPL_W = 2 /*RESP*/ + XLEN;

    // Stores the information of a request
    logic [META_W  -1:0] meta_ram[NB_TAG-1:0];
    // Stores the completion info which will be driven back to the application
    logic [CPL_W   -1:0] cpl_ram[NB_TAG-1:0];
    // Stores the tags available 
    logic [2*NB_TAG-1:0] tags;
    // The tag used is an IO request
    logic [NB_TAG  -1:0] io_tags;
    // Pointer to current available for next request
    logic [NB_TAG_W-1:0] req_tag_pt;
    logic [NB_TAG_W-1:0] cpl_tag_pt;

    // AXI ID received, without the ID mask applied before a request
    logic [AXI_ID_W-1:0] blk_fetcher_rid_m;
    logic [AXI_ID_W-1:0] io_fetcher_rid_m;

    ////////////////////////////////////////////////////////////////////////////////
    // AXI4-lite completions
    ////////////////////////////////////////////////////////////////////////////////

    assign io_fetcher_rready = 1'b1;
    assign blk_fetcher_rready = 1'b1;

    // Remove the ID mask applied to identify the request ID
    assign blk_fetcher_rid_m = blk_fetcher_rid ^ AXI_ID_MASK;
    assign io_fetcher_rid_m = io_fetcher_rid ^ AXI_ID_MASK;


    ////////////////////////////////////////////////////////////////////////////////
    // Tag management, reserving and freeing the available tags
    //
    // A tag can be setup with 3 status:
    //   - RSVD (2'b01): has been issued within a read request
    //   - RCVD (2'b11): has been received from IO or Block completion channel
    //   - FREE (2'b00): has been send back to the application or never used
    //
    ////////////////////////////////////////////////////////////////////////////////

    assign tag_avlb = (tags[2*req_tag_pt+:2] == FREE);
    assign next_tag = req_tag_pt | AXI_ID_MASK;
    assign pending_rd = |tags;

    for (genvar i=0; i<NB_TAG; i=i+1) begin

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                tags[2*i+:2] <= FREE;
            end else if (srst) begin
                tags[2*i+:2] <= FREE;
            end else begin

                // Send a request with this tag, so reserve it
                if (slv_arvalid && slv_arready && i[0+:NB_TAG_W]==req_tag_pt)
                    tags[2*i+REQ] <= 1'b1;

                // Send back the final completion with this tag, so free it
                else if (mst_rvalid && mst_rready && i[0+:NB_TAG_W]==cpl_tag_pt)
                    tags[2*i+:2] <= FREE;

                // Receive a completion using this tag, so make it ready to finalize completion
                else if ((blk_fetcher_rvalid && i[0+:AXI_ID_W]==blk_fetcher_rid_m) ||
                         (io_fetcher_rvalid && i[0+:AXI_ID_W]==io_fetcher_rid_m))
                    tags[2*i+CPL] <= 1'b1;

                `ifdef FRISCV_SIM
                if (tags[2*i+:2] == ILGL)
                    $display("ERROR: (@ %0t) - %s: Illegal status for tag 0x%0x", $realtime, NAME, i);
                `endif 
            end
        end

        // Stores the ID to give back on completion
        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                meta_ram[i] <= {AXI_ID_W{1'b0}};
            end else if (srst) begin
                meta_ram[i] <= {AXI_ID_W{1'b0}};
            end else if (AXI_ID_FIXED == 0) begin
                if (slv_arvalid && slv_arready && i[0+:NB_TAG_W]==req_tag_pt) begin
                    meta_ram[i] <= slv_arid;
                end
            end else begin
                meta_ram[i] <= {AXI_ID_W{1'b0}};
            end
        end

        // Stores info if request is an I/O request
        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                io_tags[i] <= 1'b0;
            end else if (srst) begin
                io_tags[i] <= 1'b0;
            end else begin
                if (slv_arvalid && slv_arready && i[0+:NB_TAG_W]==req_tag_pt) begin
                    io_tags[i] <= slv_arcache[1];
                end else if (mst_rvalid && mst_rready && i[0+:NB_TAG_W]==cpl_tag_pt) begin
                    io_tags[i] <= 1'b0;
                end
            end
        end

        // Stores the completion data/resp to give back on completion
        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                cpl_ram[i] <= {2'b0, {XLEN{1'b0}}};
            end else if (srst) begin
                cpl_ram[i] <= {2'b0, {XLEN{1'b0}}};
            end else begin
                if (io_fetcher_rvalid && io_fetcher_rready && io_fetcher_rid_m==i)
                    cpl_ram[i] <= {io_fetcher_rresp, io_fetcher_rdata};
                else if (blk_fetcher_rvalid && blk_fetcher_rready && blk_fetcher_rid_m==i)
                    cpl_ram[i] <= {blk_fetcher_rresp, blk_fetcher_rdata};
            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pointer management for request and completion
    // TODO: Replace with a FIFO to better use tags and be opportunistic
    // to avoid blocking the request
    ////////////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            req_tag_pt <= {NB_TAG_W{1'b0}};
            cpl_tag_pt <= {NB_TAG_W{1'b0}};
        end else if (srst) begin
            req_tag_pt <= {NB_TAG_W{1'b0}};
            cpl_tag_pt <= {NB_TAG_W{1'b0}};
        end else begin

            if (slv_arvalid & slv_arready) begin
                if (req_tag_pt==MAX_TAG) req_tag_pt <= {NB_TAG_W{1'b0}};
                else req_tag_pt <= req_tag_pt + 1'b1;
            end
            
            if (mst_rvalid & mst_rready) begin
                if (cpl_tag_pt==MAX_TAG) cpl_tag_pt <= {NB_TAG_W{1'b0}};
                else cpl_tag_pt <= cpl_tag_pt + 1'b1;
            end
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // Completion management
    //
    // If the cache is serving some I/O requests, the block will manage the
    // ordering because an I/O request can be completed before or after a 
    // consecutive tag. But if the cache is not serving an I/O request, the 
    // block fetcher always serve in order so the read data channel is feeded 
    // directly from the input read data channel, no completion needs to
    // be buffered in RAM
    //
    //////////////////////////////////////////////////////////////////////////
    generate
    if (NO_RDC_BACKPRESSURE) begin
        assign mst_rvalid = (|io_tags) ? tags[2*cpl_tag_pt+CPL] : blk_fetcher_rvalid;
    end else begin
        assign mst_rvalid = tags[2*cpl_tag_pt+CPL];
    end
    endgenerate

    generate

    if (AXI_ID_FIXED) begin
        assign mst_rid = AXI_ID_MASK;
    end else begin
        assign mst_rid = meta_ram[cpl_tag_pt][0+:AXI_ID_W];
    end

    endgenerate

    generate
    if (NO_RDC_BACKPRESSURE) begin
        assign mst_rdata = (|io_tags) ? cpl_ram[cpl_tag_pt][0+:XLEN] : blk_fetcher_rdata;
        assign mst_rresp = (|io_tags) ? cpl_ram[cpl_tag_pt][XLEN+:2] : blk_fetcher_rresp;
    end else begin
        assign mst_rdata = cpl_ram[cpl_tag_pt][0+:XLEN];
        assign mst_rresp = cpl_ram[cpl_tag_pt][XLEN+:2];
    end
    endgenerate

endmodule

`resetall
