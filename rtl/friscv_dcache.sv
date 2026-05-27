// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"
`include "friscv_checkers.sv"

///////////////////////////////////////////////////////////////////////////////
//
// Data cache circuit
//
// - Direct-mapped (1-way) placement policy
// - Write-through policy, updating central memory when updating cache blocks
// - Parametrizable cache depth
// - Parametrizable cache line width
// - Transparent operation, no need of user management
// - IO mapping for direct read/write access to GPIOs and IO peripherals
// - Slave AXI4-lite interface to fetch instructions
// - Master AXI4 interface to read/write the  central memory
//
///////////////////////////////////////////////////////////////////////////////

module friscv_dcache

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
        parameter AXI_ADDR_W = 32,
        // AXI ID width
        parameter AXI_ID_W = 8,
        // AXI4 data width, to setup to cache block width
        parameter AXI_DATA_W = 128,
        // ID Mask used to identify the data cache in the AXI4 infrastructure
        parameter AXI_ID_MASK = 'h40,
        // AXI ID issued on slave interface is fixed, save some logic
        parameter AXI_ID_FIXED = 1,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // IO regions for direct read/write access
        parameter IO_MAP_NB = 1,
        // Bypass if possible the OoO output RAM stage. Imply the completion path
        // will be combinatorial but reduce the latency, increase the bandwidth
        parameter FAST_FWD_CPL = 1,
        // Enable automatic prefetch in memory controller
        parameter CACHE_PREFETCH_EN = 0,
        // Block width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128,
        // Number of blocks in the cache
        parameter CACHE_DEPTH = 512
    )(
        // Global interface
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        output logic                      cache_ready,

        // memfy memory interface
        input  wire                       memfy_awvalid,
        output logic                      memfy_awready,
        input  wire  [AXI_ADDR_W    -1:0] memfy_awaddr,
        input  wire  [3             -1:0] memfy_awprot,
        input  wire  [4             -1:0] memfy_awcache,
        input  wire  [AXI_ID_W      -1:0] memfy_awid,
        input  wire                       memfy_awlock,
        input  wire                       memfy_wvalid,
        output logic                      memfy_wready,
        input  wire  [XLEN          -1:0] memfy_wdata,
        input  wire  [XLEN/8        -1:0] memfy_wstrb,
        output logic                      memfy_bvalid,
        input  wire                       memfy_bready,
        output logic [AXI_ID_W      -1:0] memfy_bid,
        output logic [2             -1:0] memfy_bresp,
        input  wire                       memfy_arvalid,
        output logic                      memfy_arready,
        input  wire  [AXI_ADDR_W    -1:0] memfy_araddr,
        input  wire  [3             -1:0] memfy_arprot,
        input  wire  [4             -1:0] memfy_arcache,
        input  wire  [AXI_ID_W      -1:0] memfy_arid,
        input  wire                       memfy_arlock,
        output logic                      memfy_rvalid,
        input  wire                       memfy_rready,
        output logic [AXI_ID_W      -1:0] memfy_rid,
        output logic [2             -1:0] memfy_rresp,
        output logic [XLEN          -1:0] memfy_rdata,

        // AXI4 write channels interface to central memory
        output logic                      dcache_awvalid,
        input  wire                       dcache_awready,
        output logic [AXI_ADDR_W    -1:0] dcache_awaddr,
        output logic [8             -1:0] dcache_awlen,
        output logic [3             -1:0] dcache_awsize,
        output logic [2             -1:0] dcache_awburst,
        output logic                      dcache_awlock,
        output logic [4             -1:0] dcache_awcache,
        output logic [3             -1:0] dcache_awprot,
        output logic [4             -1:0] dcache_awqos,
        output logic [4             -1:0] dcache_awregion,
        output logic [AXI_ID_W      -1:0] dcache_awid,
        output logic                      dcache_wvalid,
        input  wire                       dcache_wready,
        output logic                      dcache_wlast,
        output logic [AXI_DATA_W    -1:0] dcache_wdata,
        output logic [AXI_DATA_W/8  -1:0] dcache_wstrb,
        input  wire                       dcache_bvalid,
        output logic                      dcache_bready,
        input  wire  [AXI_ID_W      -1:0] dcache_bid,
        input  wire  [2             -1:0] dcache_bresp,

        // AXI4 read channels interface to central memory
        output logic                      dcache_arvalid,
        input  wire                       dcache_arready,
        output logic [AXI_ADDR_W    -1:0] dcache_araddr,
        output logic [8             -1:0] dcache_arlen,
        output logic [3             -1:0] dcache_arsize,
        output logic [2             -1:0] dcache_arburst,
        output logic                      dcache_arlock,
        output logic [4             -1:0] dcache_arcache,
        output logic [3             -1:0] dcache_arprot,
        output logic [4             -1:0] dcache_arqos,
        output logic [4             -1:0] dcache_arregion,
        output logic [AXI_ID_W      -1:0] dcache_arid,
        input  wire                       dcache_rvalid,
        output logic                      dcache_rready,
        input  wire  [AXI_ID_W      -1:0] dcache_rid,
        input  wire  [2             -1:0] dcache_rresp,
        input  wire  [AXI_DATA_W    -1:0] dcache_rdata,
        input  wire                       dcache_rlast
    );


    ///////////////////////////////////////////////////////////////////////////
    // Internal Signals
    ///////////////////////////////////////////////////////////////////////////

    logic                      cache_awvalid;
    logic                      cache_awready;
    logic [AXI_ADDR_W    -1:0] cache_awaddr;
    logic [8             -1:0] cache_awlen;
    logic [3             -1:0] cache_awsize;
    logic [2             -1:0] cache_awburst;
    logic                      cache_awlock;
    logic [4             -1:0] cache_awcache;
    logic [3             -1:0] cache_awprot;
    logic [4             -1:0] cache_awqos;
    logic [4             -1:0] cache_awregion;
    logic [AXI_ID_W      -1:0] cache_awid;
    logic                      cache_wvalid;
    logic                      cache_wready;
    logic                      cache_wlast;
    logic [AXI_DATA_W    -1:0] cache_wdata;
    logic [AXI_DATA_W/8  -1:0] cache_wstrb;
    logic                      cache_bvalid;
    logic                      cache_bready;
    logic [AXI_ID_W      -1:0] cache_bid;
    logic [2             -1:0] cache_bresp;

    logic                      cache_arvalid;
    logic                      cache_arready;
    logic [AXI_ADDR_W    -1:0] cache_araddr;
    logic [8             -1:0] cache_arlen;
    logic [3             -1:0] cache_arsize;
    logic [2             -1:0] cache_arburst;
    logic                      cache_arlock;
    logic [4             -1:0] cache_arcache;
    logic [3             -1:0] cache_arprot;
    logic [4             -1:0] cache_arqos;
    logic [4             -1:0] cache_arregion;
    logic [AXI_ID_W      -1:0] cache_arid;
    logic                      cache_rvalid;
    logic                      cache_rready;
    logic [AXI_ID_W      -1:0] cache_rid;
    logic [2             -1:0] cache_rresp;
    logic [AXI_DATA_W    -1:0] cache_rdata;
    logic                      cache_rlast;

    typedef enum logic [1:0] {
        BYPASS_IDLE,
        BYPASS_READ_ACTIVE,
        BYPASS_WRITE_ACTIVE
    } bypass_state_t;

    bypass_state_t rd_bypass_state, rd_bypass_state_nxt;
    bypass_state_t wr_bypass_state, wr_bypass_state_nxt;

    logic rd_bypass_ready;
    logic wr_bypass_ready;
    logic dcache_ready ;
    logic use_bypass_aw;
    logic use_bypass_ar;


    ///////////////////////////////////////////////////////////////
    // Combined cache ready: cache ready AND bypass idle
    ///////////////////////////////////////////////////////////////

    assign cache_ready = dcache_ready && rd_bypass_ready && wr_bypass_ready;

    ///////////////////////////////////////////////////////////////
    // dCache Core
    ///////////////////////////////////////////////////////////////

    friscv_dcache_core #(
        .ILEN              (ILEN),
        .XLEN              (XLEN),
        .OSTDREQ_NUM       (OSTDREQ_NUM),
        .AXI_ADDR_W        (AXI_ADDR_W),
        .AXI_ID_W          (AXI_ID_W),
        .AXI_DATA_W        (AXI_DATA_W),
        .AXI_ID_MASK       (AXI_ID_MASK),
        .AXI_ID_FIXED      (AXI_ID_FIXED),
        .IO_MAP_NB         (IO_MAP_NB),
        .FAST_FWD_CPL      (FAST_FWD_CPL),
        .CACHE_PREFETCH_EN (CACHE_PREFETCH_EN),
        .CACHE_BLOCK_W     (CACHE_BLOCK_W),
        .CACHE_DEPTH       (CACHE_DEPTH)
    ) dcache_core (
        // Global
        .aclk              (aclk),
        .aresetn           (aresetn),
        .srst              (srst),
        .cache_ready       (dcache_ready),

        // Memfy interface (inchangée)
        .memfy_awvalid     (memfy_awvalid),
        .memfy_awready     (memfy_awready),
        .memfy_awaddr      (memfy_awaddr),
        .memfy_awprot      (memfy_awprot),
        .memfy_awcache     (memfy_awcache),
        .memfy_awid        (memfy_awid),
        .memfy_awlock      (memfy_awlock),
        .memfy_wvalid      (memfy_wvalid),
        .memfy_wready      (memfy_wready),
        .memfy_wdata       (memfy_wdata),
        .memfy_wstrb       (memfy_wstrb),
        .memfy_bvalid      (memfy_bvalid),
        .memfy_bready      (memfy_bready),
        .memfy_bid         (memfy_bid),
        .memfy_bresp       (memfy_bresp),
        .memfy_arvalid     (memfy_arvalid),
        .memfy_arready     (memfy_arready),
        .memfy_araddr      (memfy_araddr),
        .memfy_arprot      (memfy_arprot),
        .memfy_arcache     (memfy_arcache),
        .memfy_arid        (memfy_arid),
        .memfy_arlock      (memfy_arlock),
        .memfy_rvalid      (memfy_rvalid),
        .memfy_rready      (memfy_rready),
        .memfy_rid         (memfy_rid),
        .memfy_rresp       (memfy_rresp),
        .memfy_rdata       (memfy_rdata),

        // AXI4 vers cache (signaux internes)
        .dcache_awvalid    (cache_awvalid),
        .dcache_awready    (cache_awready),
        .dcache_awaddr     (cache_awaddr),
        .dcache_awlen      (cache_awlen),
        .dcache_awsize     (cache_awsize),
        .dcache_awburst    (cache_awburst),
        .dcache_awlock     (cache_awlock),
        .dcache_awcache    (cache_awcache),
        .dcache_awprot     (cache_awprot),
        .dcache_awqos      (cache_awqos),
        .dcache_awregion   (cache_awregion),
        .dcache_awid       (cache_awid),
        .dcache_wvalid     (cache_wvalid),
        .dcache_wready     (cache_wready),
        .dcache_wlast      (cache_wlast),
        .dcache_wdata      (cache_wdata),
        .dcache_wstrb      (cache_wstrb),
        .dcache_bvalid     (cache_bvalid),
        .dcache_bready     (cache_bready),
        .dcache_bid        (cache_bid),
        .dcache_bresp      (cache_bresp),
        .dcache_arvalid    (cache_arvalid),
        .dcache_arready    (cache_arready),
        .dcache_araddr     (cache_araddr),
        .dcache_arlen      (cache_arlen),
        .dcache_arsize     (cache_arsize),
        .dcache_arburst    (cache_arburst),
        .dcache_arlock     (cache_arlock),
        .dcache_arcache    (cache_arcache),
        .dcache_arprot     (cache_arprot),
        .dcache_arqos      (cache_arqos),
        .dcache_arregion   (cache_arregion),
        .dcache_arid       (cache_arid),
        .dcache_rvalid     (cache_rvalid),
        .dcache_rready     (cache_rready),
        .dcache_rid        (cache_rid),
        .dcache_rresp      (cache_rresp),
        .dcache_rdata      (cache_rdata),
        .dcache_rlast      (cache_rlast)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Bypass state machine and control signals
    ///////////////////////////////////////////////////////////////////////////

    // Bypass FSM: locks bypass path during atomic transactions
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd_bypass_state <= BYPASS_IDLE;
        end else if (srst) begin
            rd_bypass_state <= BYPASS_IDLE;
        end else begin
            rd_bypass_state <= rd_bypass_state_nxt;
        end
    end

    always_comb begin
        rd_bypass_state_nxt = rd_bypass_state;

        case (rd_bypass_state)
            BYPASS_IDLE: begin
                // Detect atomic transaction (lock asserted)
                if (memfy_arvalid && memfy_arcache[1]) begin
                    rd_bypass_state_nxt = BYPASS_WRITE_ACTIVE;
                end
            end

            BYPASS_READ_ACTIVE: begin
                // Return to IDLE when read response completes
                if (dcache_rvalid && memfy_rready) begin
                    rd_bypass_state_nxt = BYPASS_IDLE;
                end
            end

            default: rd_bypass_state_nxt = BYPASS_IDLE;
        endcase
    end

    always_comb begin
        wr_bypass_state_nxt = wr_bypass_state;

        case (wr_bypass_state)
            BYPASS_IDLE: begin
                // Detect atomic transaction (lock asserted)
                if (memfy_awvalid && memfy_awcache[1]) begin
                    wr_bypass_state_nxt = BYPASS_WRITE_ACTIVE;
                end
            end

            BYPASS_WRITE_ACTIVE: begin
                // Return to IDLE when write response completes
                if (dcache_bvalid && memfy_bready) begin
                    wr_bypass_state_nxt = BYPASS_IDLE;
                end
            end

            default: wr_bypass_state_nxt = BYPASS_IDLE;
        endcase
    end

    // Bypass control signals
    assign use_bypass_ar = (rd_bypass_state == BYPASS_READ_ACTIVE);
    assign use_bypass_aw = (wr_bypass_state == BYPASS_WRITE_ACTIVE);
    assign wr_bypass_ready  = (wr_bypass_state == BYPASS_IDLE);
    assign rd_bypass_ready  = (rd_bypass_state == BYPASS_IDLE);

    ///////////////////////////////////////////////////////////////////////////
    // Demux AXI4: Cache vs Bypass
    ///////////////////////////////////////////////////////////////////////////

    // Write Address Channel
    always_comb begin
        if (use_bypass_aw) begin
            // Bypass: forward directement memfy → dcache
            dcache_awvalid  = memfy_awvalid;
            dcache_awaddr   = memfy_awaddr;
            dcache_awlen    = 8'd0;
            dcache_awsize   = (XLEN == 64) ? 3'b011 : 3'b010;
            dcache_awburst  = 2'b01; // INCR
            dcache_awlock   = memfy_awlock;
            dcache_awcache  = memfy_awcache;
            dcache_awprot   = memfy_awprot;
            dcache_awqos    = 4'b0;
            dcache_awregion = 4'b0;
            dcache_awid     = memfy_awid;
            cache_awready   = 1'b0;
        end else begin
            // Via cache
            dcache_awvalid  = cache_awvalid;
            dcache_awaddr   = cache_awaddr;
            dcache_awlen    = cache_awlen;
            dcache_awsize   = cache_awsize;
            dcache_awburst  = cache_awburst;
            dcache_awlock   = cache_awlock;
            dcache_awcache  = cache_awcache;
            dcache_awprot   = cache_awprot;
            dcache_awqos    = cache_awqos;
            dcache_awregion = cache_awregion;
            dcache_awid     = cache_awid;
            cache_awready   = dcache_awready;
        end
    end

    // Write Data Channel
    always_comb begin
        if (use_bypass_aw) begin
            // Bypass
            dcache_wvalid = memfy_wvalid;
            dcache_wdata  = memfy_wdata;
            dcache_wstrb  = memfy_wstrb;
            dcache_wlast  = 1'b1;

            cache_wready  = 1'b0;
        end else begin
            // Via cache
            dcache_wvalid = cache_wvalid;
            dcache_wdata  = cache_wdata;
            dcache_wstrb  = cache_wstrb;
            dcache_wlast  = cache_wlast;

            cache_wready  = dcache_wready;
        end
    end

    // Write Response Channel
    always_comb begin
        if (use_bypass_aw) begin
            // Bypass
            dcache_bready = memfy_bready;
            cache_bvalid  = '0;
            cache_bid     = '0;
            cache_bresp   = '0;
        end else begin
            // Via cache
            dcache_bready = cache_bready;
            cache_bvalid  = dcache_bvalid;
            cache_bid     = dcache_bid;
            cache_bresp   = dcache_bresp;
        end
    end

    // Read Address Channel
    always_comb begin
        if (use_bypass_ar) begin
            // Bypass
            dcache_arvalid  = memfy_arvalid;
            dcache_araddr   = memfy_araddr;
            dcache_arlen    = '0;
            dcache_arsize   = (XLEN == 64) ? 3'b011 : 3'b010;
            dcache_arburst  = 2'b01;
            dcache_arlock   = memfy_arlock;
            dcache_arcache  = memfy_arcache;
            dcache_arprot   = memfy_arprot;
            dcache_arqos    = '0;
            dcache_arregion = '0;
            dcache_arid     = memfy_arid;

            cache_arready   = '0;
        end else begin
            // Via cache
            dcache_arvalid  = cache_arvalid;
            dcache_araddr   = cache_araddr;
            dcache_arlen    = cache_arlen;
            dcache_arsize   = cache_arsize;
            dcache_arburst  = cache_arburst;
            dcache_arlock   = cache_arlock;
            dcache_arcache  = cache_arcache;
            dcache_arprot   = cache_arprot;
            dcache_arqos    = cache_arqos;
            dcache_arregion = cache_arregion;
            dcache_arid     = cache_arid;

            cache_arready   = dcache_arready;
        end
    end

    // Read Data Channel
    always_comb begin
        if (use_bypass_ar) begin
            dcache_rready = memfy_rready;
            cache_rvalid  = '0;
            cache_rid     = '0;
            cache_rresp   = '0;
            cache_rdata   = '0;
            cache_rlast   = '0;
        end else begin
            // Via cache
            dcache_rready = cache_rready;
            cache_rvalid  = dcache_rvalid;
            cache_rid     = dcache_rid;
            cache_rresp   = dcache_rresp;
            cache_rdata   = dcache_rdata;
            cache_rlast   = dcache_rlast;
        end
    end

endmodule

`resetall
