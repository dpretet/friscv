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
// TODO: Support AXI4 transfer with different width than the cache line width
// TODO: Support width adaptation between ctrl and memory (a5f613f50f861)
// TODO: Support Wrap mode for read channel
// TODO: Manage RRESP
//
///////////////////////////////////////////////////////////////////////////////

module friscv_cache_memctrl

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

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 10,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 128,
        // ID Mask to apply to identify the instruction cache in the AXI4
        // infrastructure
        parameter AXI_ID_MASK = 'h10,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Generate a write channel, 0=read-only, 1=read-write
        parameter RW_MODE = 0,
        // Cache block width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512

    )(
        // Global signals
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Flush interface
        input  wire                       flush_blocks,
        output logic                      flush_ack,
        output logic                      flushing,
        // ctrl read interface
        input  wire                       mst_arvalid,
        output logic                      mst_arready,
        input  wire  [AXI_ADDR_W    -1:0] mst_araddr,
        input  wire  [3             -1:0] mst_arprot,
        input  wire  [AXI_ID_W      -1:0] mst_arid,
        // ctrl write interface
        input  logic                      mst_awvalid,
        output logic                      mst_awready,
        input  logic [AXI_ADDR_W    -1:0] mst_awaddr,
        input  logic [3             -1:0] mst_awprot,
        input  logic [AXI_ID_W      -1:0] mst_awid,
        input  logic                      mst_wvalid,
        output logic                      mst_wready,
        input  logic [XLEN          -1:0] mst_wdata,
        input  logic [XLEN/8        -1:0] mst_wstrb,
        output logic [AXI_ID_W      -1:0] mst_bid,
        output logic [2             -1:0] mst_bresp,
        output logic                      mst_bvalid,
        input  logic                      mst_bready,
        // AXI4 Write channels interface to central memory
        output logic                      mem_awvalid,
        input  wire                       mem_awready,
        output logic [AXI_ADDR_W    -1:0] mem_awaddr,
        output logic [8             -1:0] mem_awlen,
        output logic [3             -1:0] mem_awsize,
        output logic [2             -1:0] mem_awburst,
        output logic [2             -1:0] mem_awlock,
        output logic [4             -1:0] mem_awcache,
        output logic [3             -1:0] mem_awprot,
        output logic [4             -1:0] mem_awqos,
        output logic [4             -1:0] mem_awregion,
        output logic [AXI_ID_W      -1:0] mem_awid,
        output logic                      mem_wvalid,
        input  wire                       mem_wready,
        output logic                      mem_wlast,
        output logic [AXI_DATA_W    -1:0] mem_wdata,
        output logic [AXI_DATA_W/8  -1:0] mem_wstrb,
        input  wire                       mem_bvalid,
        output logic                      mem_bready,
        input  wire  [AXI_ID_W      -1:0] mem_bid,
        input  wire  [2             -1:0] mem_bresp,
        // AXI4 Read channels interface to central memory
        output logic                      mem_arvalid,
        input  wire                       mem_arready,
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
        input  wire                       mem_rvalid,
        output logic                      mem_rready,
        input  wire  [AXI_ID_W      -1:0] mem_rid,
        input  wire  [2             -1:0] mem_rresp,
        input  wire  [AXI_DATA_W    -1:0] mem_rdata,
        input  wire                       mem_rlast,
        // Cache block write interface driven with read data channel
        output logic                      cache_loading,
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

    localparam ADDR_LSB_W = $clog2(AXI_DATA_W/8);
    localparam MAX_CACHE_ADDR = CACHE_DEPTH << $clog2(CACHE_BLOCK_W/8);

    localparam SCALE = AXI_DATA_W / XLEN;
    localparam SCALE_W = $clog2(SCALE);

    // Used on flush request to erase the cache content
    logic                  erase_wen;
    logic [AXI_ADDR_W  :0] erase_addr;

    logic [AXI_ADDR_W-1:0] araddr;
    logic                  rch_full;
    logic                  wch_full;
    logic                  rch_empty;
    logic                  wch_empty;
    logic                  push_wch_fifo;
    logic                  pull_wch_fifo;
    logic                  blocks_zeroed;
    logic [3         -1:0] asize;
    logic [SCALE_W   -1:0] wr_position;
    logic [SCALE_W   -1:0] wr_position_ff;

    ///////////////////////////////////////////////////////////////////////////
    // Fixed ASIZE, narrow transfers are not supported neither necessary
    ///////////////////////////////////////////////////////////////////////////

    assign asize = (AXI_DATA_W/8 ==  1) ? 3'b000:
                   (AXI_DATA_W/8 ==  2) ? 3'b001:
                   (AXI_DATA_W/8 ==  4) ? 3'b010:
                   (AXI_DATA_W/8 ==  8) ? 3'b011:
                   (AXI_DATA_W/8 == 16) ? 3'b100:
                   (AXI_DATA_W/8 == 32) ? 3'b101:
                   (AXI_DATA_W/8 == 64) ? 3'b110:
                                          3'b111;

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

    // Fixed ASIZE, narrow transfers are not supported neither necessary
    assign mem_arsize = asize;


    ///////////////////////////////////////////////////////////////////////////
    // Drive AXI4 read address channel directly from AXI4-lite
    ///////////////////////////////////////////////////////////////////////////

    assign mem_arvalid = mst_arvalid;
    assign mst_arready = mem_arready && !rch_full;

    // TODO: Fetch the address rounded to cache line boundary
    assign mem_araddr = {mst_araddr[AXI_ADDR_W-1:ADDR_LSB_W],{ADDR_LSB_W{1'b0}}};
    assign mem_arprot = mst_arprot;
    assign mem_arid = AXI_ID_MASK;


    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W)
    )
    araddr_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  (mst_araddr),
        .push     (mst_arvalid & mst_arready),
        .full     (rch_full),
        .data_out (araddr),
        .pull     (mem_rvalid),
        .empty    (rch_empty)
    );

    assign mem_rready = !rch_empty;

    ///////////////////////////////////////////////////////////////////////////
    // Cache block write executed with read completion channel
    ///////////////////////////////////////////////////////////////////////////

    assign cache_wen = (cfsm==IDLE) ? mem_rvalid : erase_wen;
    assign cache_waddr = (cfsm==IDLE) ? araddr : erase_addr[AXI_ADDR_W-1:0];
    assign cache_wdata = (cfsm==IDLE) ? mem_rdata : {CACHE_BLOCK_W{1'b0}};


    ///////////////////////////////////////////////////////////////////////////
    // Flag indicating a memory read request is occuring, waiting for a 
    // completion
    // TODO: Check if an OR tracker shouldn't be used
    ///////////////////////////////////////////////////////////////////////////
    
    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cache_loading <= 1'b0;
        end else if (srst == 1'b1) begin
            cache_loading <= 1'b0;
        end else begin
            if (mem_arready && mem_arvalid) cache_loading <= 1'b1;
            else if (mem_rvalid && mem_rready) cache_loading <= 1'b0;
        end
    end
    

    ///////////////////////////////////////////////////////////////////////////
    // Flush support on FENCE.i instruction execution
    //
    // flush_ack is asserted for one cycle once flush_blocks has been asserted 
    // and the entire cache lines have been erased
    ///////////////////////////////////////////////////////////////////////////


    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= IDLE;
            flush_ack <= 1'b0;
            flushing <= 1'b0;
            erase_wen <= 1'b0;
            erase_addr <= {AXI_ADDR_W+1{1'b0}};
            blocks_zeroed <= 1'b0;
        end else if (srst == 1'b1) begin
            cfsm <= IDLE;
            flush_ack <= 1'b0;
            flushing <= 1'b0;
            erase_wen <= 1'b0;
            erase_addr <= {AXI_ADDR_W+1{1'b0}};
            blocks_zeroed <= 1'b0;
        end else begin

            case (cfsm)
                // Wait for flush request
                default: begin
                    flushing <= 1'b0;
                    flush_ack <= 1'b0;
                    if (flush_blocks || RW_MODE && !blocks_zeroed) begin
                        flushing <= 1'b1;
                        erase_wen <= 1'b1;
                        cfsm <= FLUSH;
                    end
                end
                FLUSH: begin
                    flushing <= 1'b1;
                    erase_wen <= 1'b1;
                    // Increment erase address by the number of byte per cache block
                    erase_addr <= erase_addr + CACHE_BLOCK_W/8;
                    if (erase_addr==MAX_CACHE_ADDR) begin
                        blocks_zeroed <= 1'b1;
                        erase_wen <= 1'b0;
                        erase_addr <= {AXI_ADDR_W+1{1'b0}};
                        flushing <= 1'b0;
                        cfsm <= ACK;
                    end
                end
                // Once cache has been erased wait for req deassertion
                ACK: begin
                    flushing <= 1'b0;
                    if (~flush_blocks) begin
                        flush_ack <= 1'b0;
                        cfsm <= IDLE;
                    end else  begin
                        flush_ack <= 1'b1;
                    end
                end
            endcase

        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // Write channels
    ///////////////////////////////////////////////////////////////////////////
    generate if (RW_MODE) begin : WRITE_CHANNELS

        // Write address channel
        assign mem_awvalid = mst_awvalid & !wch_full;
        assign mst_awready = mem_awready & !wch_full;
        assign mem_awaddr = {mst_awaddr[AXI_ADDR_W-1:ADDR_LSB_W],{ADDR_LSB_W{1'b0}}};
        // Single beat request
        assign mem_awlen = 8'b0;
        // No narrow request support
        assign mem_awsize = asize;
        // Always use INCR mode
        assign mem_awburst = 2'b1;
        // Unused features
        assign mem_awlock = 2'b0;
        assign mem_awcache = 4'b0;
        assign mem_awprot = mst_awprot;
        assign mem_awqos = 4'b0;
        assign mem_awregion = 4'b0;
        assign mem_awid = AXI_ID_MASK;

        // Write data channel
        assign mem_wvalid = mst_wvalid & !wch_full;
        assign mst_wready = mem_wready & !wch_full;
        assign mem_wlast = 1'b1;
        assign mem_wdata = {SCALE{mst_wdata}};

        friscv_scfifo
        #(
            .PASS_THRU  (0),
            .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
            .DATA_WIDTH (SCALE_W)
        )
        wroffset_fifo
        (
            .aclk     (aclk),
            .aresetn  (aresetn),
            .srst     (srst),
            .flush    (1'b0),
            .data_in  (mst_awaddr[2+:SCALE_W]),
            .push     (push_wch_fifo),
            .full     (wch_full),
            .data_out (wr_position_ff),
            .pull     (pull_wch_fifo),
            .empty    (wch_empty)
        );

        assign push_wch_fifo = mem_awvalid & mem_awready & mem_wvalid & !mem_wready;
        assign pull_wch_fifo = mem_wvalid & mem_wready;
        assign wr_position = (wch_empty) ? mst_awaddr[2+:SCALE_W] : wr_position_ff;

        always @ (*) begin: GEN_WSTRB
            for (int i=0;i<SCALE;i=i+1) begin
                if (i==wr_position) begin: WSTRB_ON
                    mem_wstrb[i*XLEN/8+:XLEN/8] = mst_wstrb;
                end else begin: WSTRB_OFF
                    mem_wstrb[i*XLEN/8+:XLEN/8] = {XLEN/8{1'b0}};
                end
            end
        end

        // Write response channel
        assign mst_bvalid = mem_bvalid;
        assign mst_bresp = mem_bresp;
        assign mst_bid = mem_bid;
        assign mem_bready = mst_bready;

    end else begin

        assign mem_awvalid = 1'b0;
        assign mem_awaddr = {AXI_ADDR_W{1'b0}};
        assign mem_awlen = 8'b0;
        assign mem_awsize = 3'b0;
        assign mem_awburst = 2'b0;
        assign mem_awlock = 2'b0;
        assign mem_awcache = 4'b0;
        assign mem_awprot = 3'b0;
        assign mem_awqos = 4'b0;
        assign mem_awregion = 4'b0;
        assign mem_awid = {AXI_ID_W{1'b0}};
        assign mem_wvalid = 1'b0;
        assign mem_wlast = 1'b0;
        assign mem_wdata = {AXI_DATA_W{1'b0}};
        assign mem_wstrb = {AXI_DATA_W/8{1'b0}};
        assign mem_bready = 1'b1;

    end
    endgenerate

endmodule

`resetall