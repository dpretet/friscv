// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_cache_pusher

    #(
        ///////////////////////////////////////////////////////////////////////
        // General Setup
        ///////////////////////////////////////////////////////////////////////

        // Name used for tracer file name
        parameter NAME = "pusher",
        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // ID Mask to apply to identify the instruction cache in the AXI4
        // infrastructure
        parameter AXI_ID_MASK = 'h20,

        ///////////////////////////////////////////////////////////////////////
        // Cache Setup
        ///////////////////////////////////////////////////////////////////////

        // Block width defining only the data payload, in bits
        parameter CACHE_BLOCK_W = 128
    )(
        // Global interface
        input  wire                            aclk,
        input  wire                            aresetn,
        input  wire                            srst,

        // Master interface
        input  wire                            mst_awvalid,
        output logic                           mst_awready,
        input  wire  [AXI_ADDR_W         -1:0] mst_awaddr,
        input  wire  [3                  -1:0] mst_awprot,
        input  wire  [4                  -1:0] mst_awcache,
        input  wire  [AXI_ID_W           -1:0] mst_awid,
        input  wire                            mst_wvalid,
        output logic                           mst_wready,
        input  wire  [XLEN               -1:0] mst_wdata,
        input  wire  [XLEN/8             -1:0] mst_wstrb,
        output logic                           mst_bvalid,
        input  wire                            mst_bready,
        output logic [AXI_ID_W           -1:0] mst_bid,
        output logic [2                  -1:0] mst_bresp,

        // Data memory interface
        output logic                           memctrl_awvalid,
        input  wire                            memctrl_awready,
        output logic [AXI_ADDR_W         -1:0] memctrl_awaddr,
        output logic [3                  -1:0] memctrl_awprot,
        output logic [AXI_ID_W           -1:0] memctrl_awid,
        output logic                           memctrl_wvalid,
        input  wire                            memctrl_wready,
        output logic [XLEN               -1:0] memctrl_wdata,
        output logic [XLEN/8             -1:0] memctrl_wstrb,
        input  wire                            memctrl_bvalid,
        output logic                           memctrl_bready,
        input  wire  [AXI_ID_W           -1:0] memctrl_bid,
        input  logic [2                  -1:0] memctrl_bresp, 

        // Cache block interface
        output logic                           cache_ren,
        output logic [AXI_ADDR_W         -1:0] cache_raddr,
        input  wire                            cache_hit,
        input  wire                            cache_miss,
        output logic                           cache_wen,
        output logic [AXI_ADDR_W         -1:0] cache_waddr,
        output logic [CACHE_BLOCK_W      -1:0] cache_wdata,
        output logic [CACHE_BLOCK_W/8    -1:0] cache_wstrb
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    parameter SCALE = CACHE_BLOCK_W / XLEN;
    parameter SCALE_W = $clog2(SCALE);
    parameter OSTDREQ_W = $clog2(OSTDREQ_NUM);

    logic                       addr_fifo_empty;
    logic                       addr_fifo_full;
    logic                       addr_fifo_afull;
    logic                       data_fifo_empty;
    logic                       data_fifo_full;
    logic                       data_fifo_afull;
    logic                       resp_fifo_full;
    logic                       resp_fifo_empty;
    logic                       wrbf_fifo_full;
    logic                       wrbf_fifo_afull;
    logic                       wrbf_fifo_empty;

    // Write-through path signals
    logic [AXI_ID_W       -1:0] cpl_bid;
    logic [2              -1:0] cpl_bresp;
    logic                       push_addr_data;
    logic                       push_resp;
    logic                       pull_resp;
    logic [OSTDREQ_NUM    -1:0] id_ram;
    logic [AXI_ID_W       -1:0] cpl_id_m;
    logic [AXI_ID_W       -1:0] req_id_m;
    logic                       to_cpl;
    logic                       wt_awready;
    logic                       wt_wready;

    // Write path signals
    logic [XLEN/8         -1:0] wstrb;
    logic [XLEN           -1:0] wdata;
    logic [AXI_ID_W       -1:0] cache_rid_r;
    logic [AXI_ADDR_W     -1:0] cache_waddr_r;
    logic [XLEN           -1:0] cache_wdata_r;
    logic [XLEN/8         -1:0] cache_wstrb_r;
    logic [AXI_ID_W       -1:0] cache_rid;
    logic                       pull_wrbf;
    logic                       is_io_req;

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
    //
    // Write request pipeline checking if a new write request needs to update
    // the cache blocks
    //
    ///////////////////////////////////////////////////////////////////////////
    
    assign mst_awready = wt_awready & wt_wready & !wrbf_fifo_afull & !wrbf_fifo_full;
    assign mst_wready = wt_awready & wt_wready & !wrbf_fifo_afull & !wrbf_fifo_full;

    assign cache_ren = mst_awvalid && mst_awready && mst_wvalid && mst_wready && !mst_awcache[1];
    assign cache_raddr = mst_awaddr;

    // Monitor the write requests and drive the cache block updater. Acts as a pipeline
    // of the incoming write request to check if the data needs to be updated in a cache block
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            cache_waddr_r <= '0;
            cache_rid_r <= '0;
            cache_wdata_r <= '0;
            cache_wstrb_r <= '0;
            push_addr_data <= '0;
            is_io_req <= '0;
        end else if (srst) begin
            cache_waddr_r <= '0;
            cache_rid_r <= '0;
            cache_wdata_r <= '0;
            cache_wstrb_r <= '0;
            push_addr_data <= '0;
            is_io_req <= '0;
        end else begin
            push_addr_data <= mst_awvalid && mst_awready && mst_wvalid && mst_wready;
            cache_waddr_r <= mst_awaddr;
            cache_rid_r <= mst_awid;
            cache_wdata_r <= mst_wdata;
            cache_wstrb_r <= mst_wstrb;
            is_io_req <= mst_awcache[1] & mst_awvalid && mst_awready && mst_wvalid && mst_wready;
        end
    end

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W+XLEN+XLEN/8)
    )
    wr_buffer
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({cache_wstrb_r, cache_wdata_r, cache_rid_r, cache_waddr_r}),
        .push     (cache_hit),
        .full     (wrbf_fifo_full),
        .afull    (wrbf_fifo_afull),
        .data_out ({wstrb, wdata, cache_rid, cache_waddr}),
        .pull     (pull_wrbf),
        .empty    (wrbf_fifo_empty),
        .aempty   ()
    );

    always @ (*) begin

        for (int i=0;i<SCALE;i=i+1) begin
            if (cache_waddr[2+:SCALE_W]==i[SCALE_W-1:0]) begin
                cache_wstrb[i*XLEN/8+:XLEN/8] = wstrb;
            end else begin
                cache_wstrb[i*XLEN/8+:XLEN/8] = {XLEN/8{1'b0}};
            end
        end

        pull_wrbf = !cache_ren;
        cache_wen = !wrbf_fifo_empty & !cache_ren;
        cache_wdata = {SCALE{wdata}};

    end

    `ifdef TRACE_CACHE
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn && cache_wen) begin
            $fwrite(f, "@ %0t: Update block\n", $realtime);
            $fwrite(f, "  - addr: 0x%x\n", cache_waddr);
            $fwrite(f, "  - data: 0x%x\n", cache_wdata);
            $fwrite(f, "  - strb: 0x%x\n", cache_wstrb);
            $fwrite(f, "  - id:   0x%x\n", cache_rid);
        end
    end
    `endif


    ///////////////////////////////////////////////////////////////////////////
    //
    // Address, data & resp FIFOs to manage outstanding requests to the memory
    // controller. Apply a strict write-through policy, any access in cache
    // blocks is transmitted to the main memory.
    //
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    addr_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({cache_rid_r, cache_waddr_r}),
        .push     (push_addr_data),
        .full     (addr_fifo_full),
        .afull    (addr_fifo_afull),
        .data_out ({memctrl_awid, memctrl_awaddr}),
        .pull     (memctrl_awready),
        .empty    (addr_fifo_empty),
        .aempty   ()
    );

    assign wt_awready = !addr_fifo_full && !addr_fifo_afull;
    assign memctrl_awvalid = !addr_fifo_empty;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (XLEN + XLEN/8)
    )
    data_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({cache_wstrb_r, cache_wdata_r}),
        .push     (push_addr_data),
        .full     (data_fifo_full),
        .afull    (data_fifo_afull),
        .data_out ({memctrl_wstrb, memctrl_wdata}),
        .pull     (memctrl_wready),
        .empty    (data_fifo_empty),
        .aempty   ()
    );

    assign wt_wready = !data_fifo_full & !data_fifo_afull;
    assign memctrl_wvalid = !data_fifo_empty;

    assign memctrl_awprot = 3'b0;

    /////////////////////////////////////////////////////////////////////////////////
    //
    // Write response channel management, complete from the cache block if 
    // the request hitted a block, or from the write response channel if the xfer
    // experienced a cache miss
    //
    /////////////////////////////////////////////////////////////////////////////////

    assign push_resp = memctrl_bvalid & to_cpl;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ID_W + 2)
    )
    resp_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({memctrl_bid, memctrl_bresp}),
        .push     (push_resp),
        .full     (resp_fifo_full),
        .afull    (),
        .data_out ({cpl_bid, cpl_bresp}),
        .pull     (pull_resp),
        .empty    (resp_fifo_empty),
        .aempty   ()
    );

    assign memctrl_bready = !resp_fifo_full;

    // Used to address the RAM storing the flag indicating a completion needs to 
    // be driven back the application to complete a request
    assign req_id_m = cache_rid_r ^ AXI_ID_MASK;
    // Used to check if the completion needs to be stored and then driven back
    assign cpl_id_m = memctrl_bid ^ AXI_ID_MASK;
    assign to_cpl = id_ram[cpl_id_m[OSTDREQ_W-1:0]];

    // Track the outstanding request to drive back completion to the application
    for (genvar i=0; i<OSTDREQ_NUM; i=i+1) begin : ID_TRACKER

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                id_ram[i] <= '0;
            end else if (srst) begin
                id_ram[i] <= '0;
            end else begin
                if ((cache_miss || is_io_req) && req_id_m[OSTDREQ_W-1:0]==i[OSTDREQ_W-1:0]) 
                begin
                    id_ram[i] <= 1'b1;
                end else if (memctrl_bvalid && memctrl_bready && cpl_id_m[OSTDREQ_W-1:0]==i[OSTDREQ_W-1:0]) begin
                    id_ram[i] <= 1'b0;
                end
            end
        end
    end
    
    // TODO: manage back-pressure of completion channel readiness
    // Today OoO or memfy are always ready
    always @ (*) begin
        if (cache_wen) begin
            mst_bvalid = 1'b1;
            mst_bresp = 2'b0;
            mst_bid = cache_rid;
            pull_resp = 1'b0;
        end else begin
            mst_bvalid = !resp_fifo_empty;
            mst_bresp = cpl_bresp;
            mst_bid = cpl_bid;
            pull_resp = 1'b1;
        end
    end

endmodule

`resetall
