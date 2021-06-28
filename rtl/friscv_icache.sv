// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Instruction cache circuit
//
// - Direct-mapped placement policy
// - Parametrizable cache depth
// - Parametrizable cache line width (instruction per line)
// - Transparent operation, no need of user management
// - Software-based flush control with FENCE.i instruction
// - Cache control & status observable by a debug interface
// - Slave AXI4-lite interface to fetch instructions
// - Master AXI4 interface to read central memory
//
///////////////////////////////////////////////////////////////////////////////

module friscv_icache

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

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
        parameter AXI_DATA_W = 8,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Enable automatic prefetch in memory controller
        parameter PREFETCH_EN = 0,
        // Line width defining only the data payload, in bits
        parameter CACHE_LINE_W = 128,
        // Number of lines in the cache
        parameter CACHE_DEPTH = 512,
        // Enable pipeline on cache
        // 0: No pipeline implemented
        // 1: Cache line read insert FFDs on RAM output
        parameter CACHE_PIPELINE = 1

    )(
        // Clock / Reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // Flush control
        input  logic                      flush_req,
        output logic                      flush_ack,
        // Control unit interface
        input  logic                      ctrl_arvalid,
        output logic                      ctrl_arready,
        input  logic [AXI_ADDR_W    -1:0] ctrl_araddr,
        input  logic [3             -1:0] ctrl_arprot,
        input  logic [AXI_ID_W      -1:0] ctrl_arid,
        output logic                      ctrl_rvalid,
        input  logic                      ctrl_rready,
        output logic [AXI_ID_W      -1:0] ctrl_rid,
        output logic [2             -1:0] ctrl_rresp,
        output logic [XLEN          -1:0] ctrl_rdata,
        // AXI4 Read channels interface to central memory
        output logic                      icache_arvalid,
        input  logic                      icache_arready,
        output logic [AXI_ADDR_W    -1:0] icache_araddr,
        output logic [8             -1:0] icache_arlen,
        output logic [3             -1:0] icache_arsize,
        output logic [2             -1:0] icache_arburst,
        output logic [2             -1:0] icache_arlock,
        output logic [4             -1:0] icache_arcache,
        output logic [3             -1:0] icache_arprot,
        output logic [4             -1:0] icache_arqos,
        output logic [4             -1:0] icache_arregion,
        output logic [AXI_ID_W      -1:0] icache_arid,
        input  logic                      icache_rvalid,
        output logic                      icache_rready,
        input  logic [AXI_ID_W      -1:0] icache_rid,
        input  logic [2             -1:0] icache_rresp,
        input  logic [AXI_DATA_W    -1:0] icache_rdata,
        input  logic                      icache_rlast
    );


    ///////////////////////////////////////////////////////////////////////////
    // Logic declarations
    ///////////////////////////////////////////////////////////////////////////

    // Missed-fetch FIFO depth
    localparam MF_FIFO_DEPTH = 2;

    // Control fsm, the sequencer driving the cache read and the memory
    // controller
    typedef enum logic[2:0] {
        IDLE = 0,
        SERVE = 1,
        LOAD = 2,
        MISSED = 3
    } seq_fsm;

    seq_fsm seq;

    // Signals driving the cache lines pool
    logic                     cache_wen;
    logic [AXI_ADDR_W   -1:0] cache_waddr;
    logic [CACHE_LINE_W -1:0] cache_wdata;
    logic                     cache_ren;
    logic [AXI_ADDR_W   -1:0] cache_raddr;
    logic [AXI_ID_W     -1:0] cache_rid;
    logic [XLEN         -1:0] cache_rdata;
    logic                     cache_hit;
    logic                     cache_miss;

    // Signal to control the flush operation
    logic                     flush;
    // cache enable coming back a read request
    logic                     cache_cpl;

    // Signals driving the FIFO buffering the intruction fetch stage request
    logic                     flush_fifo;
    logic                     fifo_full_if;
    logic                     pull_addr_if;
    logic                     fifo_empty_if;
    // Signals driving the cache-missed instruction
    logic                     fifo_full_mf;
    logic                     pull_addr_mf;
    logic                     fifo_empty_mf;
    logic                     push_fifo_mf;

    // instruction fetch address and ID read from the FIFO
    // buffering the instruction fetch stage
    logic [AXI_ADDR_W   -1:0] araddr_if;
    logic [AXI_ID_W     -1:0] arid_if;

    // miss-fetched instruction and address, to read again once the
    // memory controller will fill the cache
    logic [AXI_ADDR_W   -1:0] araddr_mf;
    logic [AXI_ID_W     -1:0] arid_mf;
    logic [AXI_ADDR_W   -1:0] araddr_ffd;
    logic [AXI_ID_W     -1:0] arid_ffd;

    // memory controller control flow, triggered on cache miss
    logic                     memctrl_arvalid;
    logic                     memctrl_arready;
    logic [AXI_ADDR_W   -1:0] memctrl_araddr;
    logic [3            -1:0] memctrl_arprot;
    logic [AXI_ID_W     -1:0] memctrl_arid;

    ///////////////////////////////////////////////////////////////////////////
    // Cache lines Storage
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_lines
    #(
    .XLEN         (XLEN),
    .ADDR_W       (AXI_ADDR_W),
    .CACHE_LINE_W (CACHE_LINE_W),
    .CACHE_DEPTH  (CACHE_DEPTH)
    )
    cache_lines
    (
    .aclk    (aclk),
    .aresetn (aresetn),
    .srst    (srst),
    .flush   (flush),
    .wen     (cache_wen),
    .waddr   (cache_waddr),
    .wdata   (cache_wdata),
    .ren     (cache_ren),
    .raddr   (cache_raddr),
    .rdata   (cache_rdata),
    .hit     (cache_hit),
    .miss    (cache_miss)
    );


    ///////////////////////////////////////////////////////////////////////////
    // AXI4 memory controller to read central memory
    ///////////////////////////////////////////////////////////////////////////

    friscv_icache_memctrl
    #(
    .XLEN         (XLEN),
    .AXI_ADDR_W   (AXI_ADDR_W),
    .AXI_ID_W     (AXI_ID_W),
    .AXI_DATA_W   (AXI_DATA_W),
    .CACHE_LINE_W (CACHE_LINE_W),
    .CACHE_DEPTH  (CACHE_DEPTH)
    )
    mem_ctrl
    (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .srst           (srst),
    .flush_req      (flush_req),
    .flush_ack      (flush_ack),
    .flush          (flush),
    .ctrl_arvalid   (memctrl_arvalid),
    .ctrl_arready   (memctrl_arready),
    .ctrl_araddr    (memctrl_araddr),
    .ctrl_arprot    (memctrl_arprot),
    .ctrl_arid      (memctrl_arid),
    .mem_arvalid    (icache_arvalid),
    .mem_arready    (icache_arready),
    .mem_araddr     (icache_araddr),
    .mem_arlen      (icache_arlen),
    .mem_arsize     (icache_arsize),
    .mem_arburst    (icache_arburst),
    .mem_arlock     (icache_arlock),
    .mem_arcache    (icache_arcache),
    .mem_arprot     (icache_arprot),
    .mem_arqos      (icache_arqos),
    .mem_arregion   (icache_arregion),
    .mem_arid       (icache_arid),
    .mem_rvalid     (icache_rvalid),
    .mem_rready     (icache_rready),
    .mem_rid        (icache_rid),
    .mem_rresp      (icache_rresp),
    .mem_rdata      (icache_rdata),
    .mem_rlast      (icache_rlast),
    .cache_wen      (cache_wen),
    .cache_waddr    (cache_waddr),
    .cache_wdata    (cache_wdata)
    );


    ///////////////////////////////////////////////////////////////////////////
    // Fetcher stage: manages the read request in the cache or issue
    // a read request in central memory
    // Composed by two FIFOs, the first buffers the incoming requests from
    // the fetch stage of the controller, the second buffers the missed
    // entries in the cache.
    // A sequencer drives the cache read and the memory controller
    ///////////////////////////////////////////////////////////////////////////

    assign ctrl_arready = ~fifo_full_if;

    assign flush_fifo = 1'b0;

    // FIFO buffering the instruction to fetch from the controller
    friscv_scfifo
    #(
    .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
    .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    if_fifo
    (
    .aclk     (aclk),
    .aresetn  (aresetn),
    .srst     (srst),
    .flush    (flush_fifo),
    .data_in  ({ctrl_arid, ctrl_araddr}),
    .push     (ctrl_arvalid),
    .full     (fifo_full_if),
    .data_out ({arid_if, araddr_if}),
    .pull     (pull_addr_if),
    .empty    (fifo_empty_if)
    );

    // FFD stage to propagate potential addr/id to fetch
    // later in cache miss
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
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

    // FIFO buffering missed-fetch instructions
    // depth can store up to 4 missed instruction

    assign push_fifo_mf = cache_miss;

    friscv_scfifo
    #(
    .ADDR_WIDTH ($clog2(MF_FIFO_DEPTH)),
    .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    mf_fifo
    (
    .aclk     (aclk),
    .aresetn  (aresetn),
    .srst     (srst),
    .flush    (flush_fifo),
    .data_in  ({arid_ffd, araddr_ffd}),
    .push     (push_fifo_mf),
    .full     (fifo_full_mf),
    .data_out ({arid_mf, araddr_mf}),
    .pull     (pull_addr_mf),
    .empty    (fifo_empty_mf)
    );

    // Read cache when of the FIFO is filled
    assign cache_ren = ((~fifo_empty_if && (seq==IDLE || seq==SERVE)) ||
                        (~fifo_empty_mf && (seq==MISSED))
                       ) ? 1'b1 : 1'b0;

    // Multiplexer stage to drive missed-fetch or to-fetch requests
    assign cache_raddr = (~fifo_empty_mf) ? araddr_mf : araddr_if;
    assign cache_rid = (~fifo_empty_mf) ? arid_mf : arid_if;

    // asserted one cycle after the cache lines have been read
    assign cache_cpl = cache_hit | cache_miss;

    // FSM sequencer controlling the cache lines and the memory controller
    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            pull_addr_if <= 1'b0;
            pull_addr_mf <= 1'b0;
            memctrl_arvalid <= 1'b0;
            memctrl_araddr <= {AXI_ADDR_W{1'b0}};
            memctrl_arid <= {AXI_ID_W{1'b0}};
            seq <= IDLE;
        end else if (srst) begin
            pull_addr_if <= 1'b0;
            pull_addr_mf <= 1'b0;
            memctrl_arvalid <= 1'b0;
            memctrl_araddr <= {AXI_ADDR_W{1'b0}};
            memctrl_arid <= {AXI_ID_W{1'b0}};
            seq <= IDLE;
        end else begin

            case (seq)
                // Wait for the address requests from the instruction fetcher
                default: begin
                    pull_addr_if <= 1'b1;
                    pull_addr_mf <= 1'b0;
                    if (~fifo_empty_if) begin
                        seq <= SERVE;
                    end
                end
                SERVE: begin
                    pull_addr_if <= 1'b1;
                    // As soon a cache miss is detected, stop to pull the
                    // FIFO and move to read the AXI4 interface to grab the
                    // missing instruction
                    if (cache_miss) begin
                        pull_addr_if <= 1'b0;
                        memctrl_arvalid <= 1'b1;
                        memctrl_araddr <= araddr_ffd;
                        memctrl_arid <= arid_ffd;
                        seq <= LOAD;
                    // When empty, go back to IDLE to wait new requests
                    end else if (fifo_empty_if) begin
                        seq <= IDLE;
                    end
                end
                // Fetch a new instruction
                LOAD: begin
                    if (memctrl_arready) begin
                        memctrl_arvalid <= 1'b0;
                    end
                    // Go to read the cache lines once the memory controller
                    // wrote a new cache line
                    if (cache_wen) begin
                        pull_addr_mf <= 1'b1;
                        seq <= MISSED;
                    end
                end
                MISSED: begin
                    // As soon a cache miss is detected, stop to pull the
                    // FIFO and move to read the AXI4 interface to grab the
                    // missing instruction
                    if (cache_miss) begin
                        pull_addr_mf <= 1'b0;
                        memctrl_arvalid <= 1'b1;
                        memctrl_araddr <= araddr_ffd;
                        memctrl_arid <= arid_ffd;
                        seq <= LOAD;
                    // If other instruction fetchs have been issue,
                    // continue to serve the instruction fetch controller
                    end else if (~fifo_empty_if && fifo_empty_mf) begin
                        pull_addr_if <= 1'b1;
                        pull_addr_mf <= 1'b0;
                        seq <= SERVE;
                    // When empty, go back to IDLE to wait new requests
                    end else if (fifo_empty_mf) begin
                        pull_addr_mf <= 1'b0;
                        seq <= IDLE;
                    end
                end
            endcase

        end
    end

    // AXI4-lite completion going back to the intruction fetch controller
    assign ctrl_rvalid = cache_hit;
    assign ctrl_rdata = cache_rdata;
    assign ctrl_rresp = 2'b0;
    assign ctrl_rid = arid_ffd;

    assign memctrl_arprot = ctrl_arprot;

    // TODO: Print state with function and a verbosity level
    // TODO: Support prefetch in memory controller
    // TODO: Bundle fetcher in a module

endmodule

`resetall
