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
        // Early Write Completion in pusher if cache hit, the write response
        // channel is handshaked as soon cache block is updated. To turn OFF
        // when IO_MAP_NB = 0
        parameter EARLY_W_CPL = 0,

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
        output logic                      dmem_awvalid,
        input  wire                       dmem_awready,
        output logic [AXI_ADDR_W    -1:0] dmem_awaddr,
        output logic [8             -1:0] dmem_awlen,
        output logic [3             -1:0] dmem_awsize,
        output logic [2             -1:0] dmem_awburst,
        output logic                      dmem_awlock,
        output logic [4             -1:0] dmem_awcache,
        output logic [3             -1:0] dmem_awprot,
        output logic [4             -1:0] dmem_awqos,
        output logic [4             -1:0] dmem_awregion,
        output logic [AXI_ID_W      -1:0] dmem_awid,
        output logic                      dmem_wvalid,
        input  wire                       dmem_wready,
        output logic                      dmem_wlast,
        output logic [AXI_DATA_W    -1:0] dmem_wdata,
        output logic [AXI_DATA_W/8  -1:0] dmem_wstrb,
        input  wire                       dmem_bvalid,
        output logic                      dmem_bready,
        input  wire  [AXI_ID_W      -1:0] dmem_bid,
        input  wire  [2             -1:0] dmem_bresp,

        // AXI4 read channels interface to central memory
        output logic                      dmem_arvalid,
        input  wire                       dmem_arready,
        output logic [AXI_ADDR_W    -1:0] dmem_araddr,
        output logic [8             -1:0] dmem_arlen,
        output logic [3             -1:0] dmem_arsize,
        output logic [2             -1:0] dmem_arburst,
        output logic                      dmem_arlock,
        output logic [4             -1:0] dmem_arcache,
        output logic [3             -1:0] dmem_arprot,
        output logic [4             -1:0] dmem_arqos,
        output logic [4             -1:0] dmem_arregion,
        output logic [AXI_ID_W      -1:0] dmem_arid,
        input  wire                       dmem_rvalid,
        output logic                      dmem_rready,
        input  wire  [AXI_ID_W      -1:0] dmem_rid,
        input  wire  [2             -1:0] dmem_rresp,
        input  wire  [AXI_DATA_W    -1:0] dmem_rdata,
        input  wire                       dmem_rlast
    );

    ///////////////////////////////////////////////////////////////////////////
    // Internal Signals
    ///////////////////////////////////////////////////////////////////////////


    logic                      cache_s_awvalid;
    logic                      cache_s_awready;
    logic                      cache_s_wvalid;
    logic                      cache_s_wready;
    logic                      cache_s_bvalid;
    logic                      cache_s_bready;
    logic [AXI_ID_W      -1:0] cache_s_bid;
    logic [2             -1:0] cache_s_bresp;
    logic                      cache_s_arvalid;
    logic                      cache_s_arready;
    logic                      cache_s_rvalid;
    logic                      cache_s_rready;
    logic [AXI_ID_W      -1:0] cache_s_rid;
    logic [2             -1:0] cache_s_rresp;
    logic [XLEN          -1:0] cache_s_rdata;

    logic                      cache_m_awvalid;
    logic                      cache_m_awready;
    logic [AXI_ADDR_W    -1:0] cache_m_awaddr;
    logic [8             -1:0] cache_m_awlen;
    logic [3             -1:0] cache_m_awsize;
    logic [2             -1:0] cache_m_awburst;
    logic                      cache_m_awlock;
    logic [4             -1:0] cache_m_awcache;
    logic [3             -1:0] cache_m_awprot;
    logic [4             -1:0] cache_m_awqos;
    logic [4             -1:0] cache_m_awregion;
    logic [AXI_ID_W      -1:0] cache_m_awid;
    logic                      cache_m_wvalid;
    logic                      cache_m_wready;
    logic                      cache_m_wlast;
    logic [AXI_DATA_W    -1:0] cache_m_wdata;
    logic [AXI_DATA_W/8  -1:0] cache_m_wstrb;
    logic                      cache_m_bvalid;
    logic                      cache_m_bready;
    logic [AXI_ID_W      -1:0] cache_m_bid;
    logic [2             -1:0] cache_m_bresp;

    logic                      cache_m_arvalid;
    logic                      cache_m_arready;
    logic [AXI_ADDR_W    -1:0] cache_m_araddr;
    logic [8             -1:0] cache_m_arlen;
    logic [3             -1:0] cache_m_arsize;
    logic [2             -1:0] cache_m_arburst;
    logic                      cache_m_arlock;
    logic [4             -1:0] cache_m_arcache;
    logic [3             -1:0] cache_m_arprot;
    logic [4             -1:0] cache_m_arqos;
    logic [4             -1:0] cache_m_arregion;
    logic [AXI_ID_W      -1:0] cache_m_arid;
    logic                      cache_m_rvalid;
    logic                      cache_m_rready;
    logic [AXI_ID_W      -1:0] cache_m_rid;
    logic [2             -1:0] cache_m_rresp;
    logic [AXI_DATA_W    -1:0] cache_m_rdata;
    logic                      cache_m_rlast;

    localparam OR_NUM_W = $clog2(OSTDREQ_NUM);
    localparam SCALE = AXI_DATA_W / XLEN;
    localparam SCALE_W = $clog2(SCALE);
    localparam OFFSET_IX = (XLEN==32) ? 2 : 3;
    localparam OFFSET_W = $clog2(SCALE);

    localparam [2:0] ASIZE = (XLEN == 64) ? 3'b011 : 3'b010 ;
    localparam [1:0] INCR = 2'b01;


    ///////////////////////////////////////////////////////////////////
    // @strb: AXI STRB from interface to upsize
    // @offset: index to assign the original strobe
    // @returns the WSTRB to assign to the bigger destination WSTRB
    ///////////////////////////////////////////////////////////////////
    function automatic logic [(SCALE*XLEN/8)-1:0] upsized_wstrb
    (
        input logic [XLEN/8      -1:0] strb,
        input logic [SCALE_W     -1:0] offset
    );
        upsized_wstrb = '0;

        if (offset == 0)
            upsized_wstrb = {{3*(XLEN/8){1'b0}}, strb};
        if (offset == 1)
            upsized_wstrb = {{2*(XLEN/8){1'b0}}, strb, {(XLEN/8){1'b0}}};
        if (offset == 2)
            upsized_wstrb = {{(XLEN/8){1'b0}}, strb, {2*(XLEN/8){1'b0}}};
        if (offset == 3)
            upsized_wstrb = {strb, {3*(XLEN/8){1'b0}}};

    endfunction

    logic [OFFSET_W-1:0] aw_offset_i;
    logic [OFFSET_W-1:0] aw_offset_o;
    logic                aw_push;
    logic                aw_pull;
    logic                aw_full;
    logic                aw_empty;

    logic [OFFSET_W-1:0] ar_offset_i;
    logic [OFFSET_W-1:0] ar_offset_o;
    logic                ar_push;
    logic                ar_pull;
    logic                ar_full;
    logic                ar_empty;

    logic [OR_NUM_W-1:0] wr_or;
    logic [OR_NUM_W-1:0] rd_or;

    typedef enum logic {
        IDLE,
        ACTIVE
    } bypass_t;

    bypass_t rd_bypass_state;
    bypass_t wr_bypass_state;

    logic rd_bypass_ready;
    logic wr_bypass_ready;
    logic dcache_ready;
    logic wr_bypass;
    logic rd_bypass;
    logic wr_bypass_nxt;
    logic rd_bypass_nxt;


    //////////////////////////////////////////////////////////////////
    // Combined cache ready: cache ready and bypass idle
    // Used in control flow to start the core or restart after a flush
    //////////////////////////////////////////////////////////////////

    assign wr_bypass_ready = '1;
    assign rd_bypass_ready = '1;

    assign cache_ready = dcache_ready && rd_bypass_ready && wr_bypass_ready;

    ///////////////////////////////////////////////////////////////
    // dCache Core
    // On the instance, IO_MAP_NB is tied to zero, the bypass
    // circuit routes IOs and AMOs directly the memory
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
        .EARLY_W_CPL       (EARLY_W_CPL),
        .IO_MAP_NB         (IO_MAP_NB),
        .FAST_FWD_CPL      (FAST_FWD_CPL),
        .CACHE_PREFETCH_EN (CACHE_PREFETCH_EN),
        .CACHE_BLOCK_W     (CACHE_BLOCK_W),
        .CACHE_DEPTH       (CACHE_DEPTH)
    ) dcache_core (
        .aclk              (aclk),
        .aresetn           (aresetn),
        .srst              (srst),
        .cache_ready       (dcache_ready),
        .memfy_awvalid     (cache_s_awvalid),
        .memfy_awready     (cache_s_awready),
        .memfy_awaddr      (memfy_awaddr),
        .memfy_awprot      (memfy_awprot),
        .memfy_awcache     (memfy_awcache),
        .memfy_awid        (memfy_awid),
        .memfy_awlock      (memfy_awlock),
        .memfy_wvalid      (cache_s_wvalid),
        .memfy_wready      (cache_s_wready),
        .memfy_wdata       (memfy_wdata),
        .memfy_wstrb       (memfy_wstrb),
        .memfy_bvalid      (cache_s_bvalid),
        .memfy_bready      (cache_s_bready),
        .memfy_bid         (cache_s_bid),
        .memfy_bresp       (cache_s_bresp),
        .memfy_arvalid     (cache_s_arvalid),
        .memfy_arready     (cache_s_arready),
        .memfy_araddr      (memfy_araddr),
        .memfy_arprot      (memfy_arprot),
        .memfy_arcache     (memfy_arcache),
        .memfy_arid        (memfy_arid),
        .memfy_arlock      (memfy_arlock),
        .memfy_rvalid      (cache_s_rvalid),
        .memfy_rready      (cache_s_rready),
        .memfy_rid         (cache_s_rid),
        .memfy_rresp       (cache_s_rresp),
        .memfy_rdata       (cache_s_rdata),
        .dcache_awvalid    (cache_m_awvalid),
        .dcache_awready    (cache_m_awready),
        .dcache_awaddr     (cache_m_awaddr),
        .dcache_awlen      (cache_m_awlen),
        .dcache_awsize     (cache_m_awsize),
        .dcache_awburst    (cache_m_awburst),
        .dcache_awlock     (cache_m_awlock),
        .dcache_awcache    (cache_m_awcache),
        .dcache_awprot     (cache_m_awprot),
        .dcache_awqos      (cache_m_awqos),
        .dcache_awregion   (cache_m_awregion),
        .dcache_awid       (cache_m_awid),
        .dcache_wvalid     (cache_m_wvalid),
        .dcache_wready     (cache_m_wready),
        .dcache_wlast      (cache_m_wlast),
        .dcache_wdata      (cache_m_wdata),
        .dcache_wstrb      (cache_m_wstrb),
        .dcache_bvalid     (cache_m_bvalid),
        .dcache_bready     (cache_m_bready),
        .dcache_bid        (cache_m_bid),
        .dcache_bresp      (cache_m_bresp),
        .dcache_arvalid    (cache_m_arvalid),
        .dcache_arready    (cache_m_arready),
        .dcache_araddr     (cache_m_araddr),
        .dcache_arlen      (cache_m_arlen),
        .dcache_arsize     (cache_m_arsize),
        .dcache_arburst    (cache_m_arburst),
        .dcache_arlock     (cache_m_arlock),
        .dcache_arcache    (cache_m_arcache),
        .dcache_arprot     (cache_m_arprot),
        .dcache_arqos      (cache_m_arqos),
        .dcache_arregion   (cache_m_arregion),
        .dcache_arid       (cache_m_arid),
        .dcache_rvalid     (cache_m_rvalid),
        .dcache_rready     (cache_m_rready),
        .dcache_rid        (cache_m_rid),
        .dcache_rresp      (cache_m_rresp),
        .dcache_rdata      (cache_m_rdata),
        .dcache_rlast      (cache_m_rlast)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Bypass state machine and control signals
    //
    // Completly by pass the cache if the request is flagged as un-bufferable
    // Concerns IO and AtomicOp requests
    //
    // CAUTION: This circuit handles correctly the bypass if
    // unbufferable requests use all the same ID. No out-of-order
    // completion is managed
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            wr_or <= '0;
            rd_or <= '0;
        end else if (srst) begin
            wr_or <= '0;
            rd_or <= '0;
        end else begin
            // Tracks write outstanding requests
            if ((memfy_awvalid && memfy_awready) && !(memfy_bvalid && memfy_bready)) begin
                wr_or <= wr_or + 1;
            end else if (!(memfy_awvalid && memfy_awready) && (memfy_bvalid && memfy_bready) && wr_or != '0) begin
                wr_or <= wr_or - 1;
            end
            // Tracks read outstanding requests
            if ((memfy_arvalid && memfy_arready) && !(memfy_rvalid && memfy_rready)) begin
                rd_or <= rd_or + 1;
            end else if (!(memfy_arvalid && memfy_arready) && (memfy_rvalid && memfy_rready) && rd_or != '0) begin
                rd_or <= rd_or - 1;
            end
        end
    end


    // Write Bypass FSM
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            wr_bypass_state <= IDLE;
        end else if (srst) begin
            wr_bypass_state <= IDLE;
        end else begin
            case (wr_bypass_state)
                default: begin
                    if (wr_bypass_nxt)
                        wr_bypass_state <= ACTIVE;
                end
                ACTIVE: begin
                    if ((wr_or == 1) && (memfy_bvalid && memfy_bready && !memfy_awvalid))
                        wr_bypass_state <= IDLE;
                end
            endcase
        end
    end

    assign wr_bypass_nxt = (wr_or == '0) & memfy_awvalid & memfy_awcache[1];

    assign wr_bypass = wr_bypass_nxt | (wr_bypass_state == ACTIVE);

    // Read Bypass FSM
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            rd_bypass_state <= IDLE;
        end else if (srst) begin
            rd_bypass_state <= IDLE;
        end else begin
            case (rd_bypass_state)
                default: begin
                    if (rd_bypass_nxt)
                        rd_bypass_state <= ACTIVE;
                end
                ACTIVE: begin
                    if ((rd_or == 1) && (memfy_rvalid && memfy_rready && !memfy_arvalid))
                        rd_bypass_state <= IDLE;
                end
            endcase
        end
    end

    assign rd_bypass_nxt = (rd_or == '0) & memfy_arvalid & memfy_arcache[1];

    assign rd_bypass = rd_bypass_nxt | (rd_bypass_state == ACTIVE);

    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Demux AXI4: Cache vs Bypass
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    // Write Channels
    ///////////////////////////////////////////////////////////

    // Write Address Channel
    assign cache_s_awvalid = (wr_bypass) ?                       '0 : memfy_awvalid;
    assign cache_m_awready = (wr_bypass) ?                       '0 : dmem_awready;
    // memfy to dmem
    assign dmem_awvalid  =   (wr_bypass) ? memfy_awvalid & !aw_full : cache_m_awvalid;
    assign memfy_awready =   (wr_bypass) ?  dmem_awready & !aw_full : cache_s_awready;
    assign dmem_awaddr   =   (wr_bypass) ?             memfy_awaddr : cache_m_awaddr;
    assign dmem_awlen    =   (wr_bypass) ?                       '0 : cache_m_awlen;
    assign dmem_awsize   =   (wr_bypass) ?                    ASIZE : cache_m_awsize;
    assign dmem_awburst  =   (wr_bypass) ?                     INCR : cache_m_awburst;
    assign dmem_awlock   =   (wr_bypass) ?             memfy_awlock : cache_m_awlock;
    assign dmem_awcache  =   (wr_bypass) ?            memfy_awcache : cache_m_awcache;
    assign dmem_awprot   =   (wr_bypass) ?             memfy_awprot : cache_m_awprot;
    assign dmem_awqos    =   (wr_bypass) ?                       '0 : cache_m_awqos;
    assign dmem_awregion =   (wr_bypass) ?                       '0 : cache_m_awregion;
    assign dmem_awid     =   (wr_bypass) ?               memfy_awid : cache_m_awid;

    assign aw_push = memfy_awvalid & memfy_awready;
    assign aw_offset_i = memfy_awaddr[OFFSET_IX+:OFFSET_W];

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (OFFSET_W)
    )
    awfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    ('0),
        .data_in  (aw_offset_i),
        .push     (aw_push),
        .full     (aw_full),
        .afull    (),
        .data_out (aw_offset_o),
        .pull     (aw_pull),
        .empty    (aw_empty),
        .aempty   ()
    );

    assign aw_pull = dmem_wvalid & dmem_wready;


    // Write Data Channel
    assign cache_s_wvalid = (wr_bypass) ?                                      '0 : memfy_wvalid;
    assign cache_m_wready = (wr_bypass) ?                                      '0 : dmem_wready;
    assign dmem_wvalid =    (wr_bypass) ?                memfy_wvalid & !aw_empty : cache_m_wvalid;
    assign memfy_wready =   (wr_bypass) ?                 dmem_wready & !aw_empty : cache_s_wready;
    assign dmem_wdata  =    (wr_bypass) ?                    {SCALE{memfy_wdata}} : cache_m_wdata;
    assign dmem_wstrb  =    (wr_bypass) ? upsized_wstrb(memfy_wstrb, aw_offset_o) : cache_m_wstrb;
    assign dmem_wlast  =    (wr_bypass) ?                                    1'b1 : cache_m_wlast;

    // Write Response Channel
    assign memfy_bvalid =   (wr_bypass) ?  dmem_bvalid : cache_s_bvalid;
    assign memfy_bid =      (wr_bypass) ?     dmem_bid : cache_s_bid;
    assign memfy_bresp =    (wr_bypass) ?   dmem_bresp : cache_s_bresp;
    assign cache_s_bready = (wr_bypass) ?           '0 : memfy_bready;
    assign cache_m_bvalid = (wr_bypass) ?           '0 : dmem_bvalid;
    assign cache_m_bid =    (wr_bypass) ?           '0 : dmem_bid;
    assign cache_m_bresp =  (wr_bypass) ?           '0 : dmem_bresp;
    assign dmem_bready =    (wr_bypass) ? memfy_bready : cache_m_bready;

    ///////////////////////////////////////////////////////////
    // Read Channels
    ///////////////////////////////////////////////////////////

    assign ar_push = memfy_arvalid & memfy_arready;
    assign ar_offset_i = memfy_araddr[OFFSET_IX+:OFFSET_W];

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (OR_NUM_W),
        .DATA_WIDTH (OFFSET_W)
    )
    arfifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    ('0),
        .data_in  (ar_offset_i),
        .push     (ar_push),
        .full     (ar_full),
        .afull    (),
        .data_out (ar_offset_o),
        .pull     (ar_pull),
        .empty    (ar_empty),
        .aempty   ()
    );

    assign ar_pull = memfy_rvalid & memfy_rready;

    // Read Address Channel
    assign cache_s_arvalid = (rd_bypass) ?                       '0 : memfy_arvalid;
    assign cache_m_arready = (rd_bypass) ?                       '0 : dmem_arready;
    assign dmem_arvalid    = (rd_bypass) ? memfy_arvalid & !ar_full : cache_m_arvalid;
    assign memfy_arready   = (rd_bypass) ?  dmem_arready & !ar_full : cache_s_arready;
    assign dmem_araddr     = (rd_bypass) ?             memfy_araddr : cache_m_araddr;
    assign dmem_arlen      = (rd_bypass) ?                       '0 : cache_m_arlen;
    assign dmem_arsize     = (rd_bypass) ?                    ASIZE : cache_m_arsize;
    assign dmem_arburst    = (rd_bypass) ?                     INCR : cache_m_arburst;
    assign dmem_arlock     = (rd_bypass) ?             memfy_arlock : cache_m_arlock;
    assign dmem_arcache    = (rd_bypass) ?            memfy_arcache : cache_m_arcache;
    assign dmem_arprot     = (rd_bypass) ?             memfy_arprot : cache_m_arprot;
    assign dmem_arqos      = (rd_bypass) ?                       '0 : cache_m_arqos;
    assign dmem_arregion   = (rd_bypass) ?                       '0 : cache_m_arregion;
    assign dmem_arid       = (rd_bypass) ?               memfy_arid : cache_m_arid;

    // Read Data Channel
    assign cache_s_rready  = (rd_bypass) ?                                 '0 : memfy_rready;
    assign cache_m_rvalid  = (rd_bypass) ?                                 '0 : dmem_rvalid;
    assign cache_m_rid     = (rd_bypass) ?                                 '0 : dmem_rid;
    assign cache_m_rresp   = (rd_bypass) ?                                 '0 : dmem_rresp;
    assign cache_m_rdata   = (rd_bypass) ?                                 '0 : dmem_rdata;
    assign cache_m_rlast   = (rd_bypass) ?                                 '0 : dmem_rlast;
    assign memfy_rvalid    = (rd_bypass) ?                        dmem_rvalid : cache_s_rvalid;
    assign dmem_rready     = (rd_bypass) ?                       memfy_rready : cache_m_rready;
    assign memfy_rdata     = (rd_bypass) ? dmem_rdata[ar_offset_o*XLEN+:XLEN] : cache_s_rdata;
    assign memfy_rid       = (rd_bypass) ?                           dmem_rid : cache_s_rid;
    assign memfy_rresp     = (rd_bypass) ?                         dmem_rresp : cache_s_rresp;

endmodule

`resetall
