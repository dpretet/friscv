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
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // RISCV Architecture
        parameter XLEN = 32,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // IO regions for direct read/write access
        parameter IO_REGION_NUMBER = 1,
        // IO address ranges, organized by memory region as END-ADDR_START-ADDR:
        // > 0xEND-MEM2_START-MEM2_END_MEM1-STARr-MEM1_END-MEM0_START-MEM0
        // IO mapping can be contiguous or sparse, no restriction on the number,
        // the size or the range if it fits into the XLEN addressable space
        parameter [XLEN*2*IO_REGION_NUMBER-1:0] IO_MAP = 64'h001000FF_00100000,

        ///////////////////////////////////////////////////////////////////////
        // Interface Setup
        ///////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,
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
        output logic                           pending_wr,
        input  logic                           pending_rd,

        // Master interface
        input  wire                            mst_awvalid,
        output logic                           mst_awready,
        input  wire  [AXI_ADDR_W         -1:0] mst_awaddr,
        input  wire  [3                  -1:0] mst_awprot,
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

    logic                      addr_fifo_empty;
    logic                      addr_fifo_full;
    logic                      data_fifo_empty;
    logic                      data_fifo_full;
    logic                      pending_wr_or;

    logic                      wait_data_channel;
    logic [XLEN          -1:0] mst_wdata_r;
    logic [XLEN/8        -1:0] mst_wstrb_r;
    logic [AXI_ADDR_W    -1:0] cache_raddr_r;
    logic [XLEN          -1:0] cache_wdata_r;
    logic [XLEN/8        -1:0] cache_wstrb_r;
    logic [SCALE_W       -1:0] wr_position;

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

    // Write response channel management
    // Drive write completion once cycle later after address channel handshake. 
    // Doesn't check BREADY because it assumes master is always ready (Memfy is).
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            mst_bvalid <= 1'b0;
            mst_bid <= {AXI_ID_W{1'b0}};
        end else if (srst) begin
            mst_bvalid <= 1'b0;
            mst_bid <= {AXI_ID_W{1'b0}};
        end else if (mst_awvalid && mst_awready) begin
            mst_bvalid <= 1'b1;
            mst_bid <= mst_awid;
        end else
            mst_bvalid <= 1'b0;
    end

    assign mst_bresp = 2'b0;

    // Monitor the write requests and drive the cache block updater. Acts as a pipeline
    // of the incoming write request to check if the data needs to be updated in a cache block
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            cache_ren <= 1'b0;
            cache_raddr <= {AXI_ADDR_W{1'b0}};
            wait_data_channel <= 1'b0;
            mst_wdata_r <= {XLEN{1'b0}};
            mst_wstrb_r <= {XLEN/8{1'b0}};
        end else if (srst) begin
            cache_ren <= 1'b0;
            cache_raddr <= {AXI_ADDR_W{1'b0}};
            wait_data_channel <= 1'b0;
            mst_wdata_r <= {XLEN{1'b0}};
            mst_wstrb_r <= {XLEN/8{1'b0}};
        end else begin
            // Previous cycle grabbed a new cache update but data channel wasn't ready yet
            if (wait_data_channel) begin
                if (mst_wvalid && mst_wready)
                    wait_data_channel <= 1'b0;
                mst_wdata_r <= mst_wdata;
                mst_wstrb_r <= mst_wstrb;
            // Grab a new write request to check if present in the cache to be udpated
            end else begin
                if (mst_awvalid && mst_awready) begin
                    if (!mst_wvalid) wait_data_channel <= 1'b1;
                    else wait_data_channel <= 1'b0;
                    cache_ren <= 1'b1;
                    cache_raddr <= mst_awaddr;
                    mst_wdata_r <= mst_wdata;
                    mst_wstrb_r <= mst_wstrb;
                end else begin
                    cache_ren <= 1'b0;
                    wait_data_channel <= 1'b0;
                end
            end
        end
    end


    // When a cache read triggers a cache hit, the data to write in the memory is also present
    // in the cache block; Grab the read address, the data/strb and target the particular
    // instruction into the cache block offset
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            cache_wen <= 1'b0;
            cache_waddr <= {AXI_ADDR_W{1'b0}};
            cache_wdata <= {CACHE_BLOCK_W{1'b0}};
            cache_wstrb <= {CACHE_BLOCK_W/8{1'b0}};
            cache_wdata_r <= {XLEN{1'b0}};
            cache_wstrb <= {CACHE_BLOCK_W/8{1'b0}};
        end else if (srst) begin
            cache_wen <= 1'b0;
            cache_waddr <= {AXI_ADDR_W{1'b0}};
            cache_wdata <= {CACHE_BLOCK_W{1'b0}};
            cache_wstrb <= {CACHE_BLOCK_W/8{1'b0}};
            cache_wdata_r <= {XLEN{1'b0}};
            cache_wstrb <= {CACHE_BLOCK_W/8{1'b0}};
        end else begin

            cache_raddr_r <= cache_raddr;
            cache_wdata_r <= mst_wdata_r;
            cache_wstrb_r <= mst_wstrb_r;

            // As long a cache hit is received and the data is ready, update the 
            // data in the cache block
            if (cache_hit && !wait_data_channel) begin
                `ifdef TRACE_CACHE
                $fwrite(f, "@ %0t: Update block\n", $realtime);
                $fwrite(f, "  - addr 0x%x\n", cache_raddr_r);
                $fwrite(f, "  - offset 0x%x\n", wr_position);
                $fwrite(f, "  - data 0x%x\n", cache_wdata_r);
                $fwrite(f, "  - strb 0x%x\n", cache_wstrb_r);
                `endif
                cache_wen <= 1'b1;
                cache_waddr <= cache_raddr_r;
                cache_wdata <= {SCALE{cache_wdata_r}};
                for (int i=0;i<SCALE;i=i+1) begin
                    if (wr_position==i[SCALE_W-1:0])
                        cache_wstrb[i*XLEN/8+:XLEN/8] <= cache_wstrb_r;
                    else
                        cache_wstrb[i*XLEN/8+:XLEN/8] <= {XLEN/8{1'b0}};
                end
            // Else wait for a new write request or the data to be ready
            end else begin
                cache_wen <= 1'b0;
                cache_wstrb <= {CACHE_BLOCK_W/8{1'b0}};
            end
        end
    end
    assign wr_position = cache_raddr_r[2+:SCALE_W];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Address and data FIFOs to manage outstanding requests to the memory
    // controller
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
        .data_in  ({mst_awid, mst_awaddr}),
        .push     (mst_awvalid),
        .full     (addr_fifo_full),
        .afull    (),
        .data_out ({memctrl_awid, memctrl_awaddr}),
        .pull     (memctrl_awready & !pending_rd),
        .empty    (addr_fifo_empty),
        .aempty   ()
    );

    assign mst_awready = !addr_fifo_full;
    assign memctrl_awvalid = !addr_fifo_empty & !pending_rd;

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
        .data_in  ({mst_wstrb, mst_wdata}),
        .push     (mst_wvalid),
        .full     (data_fifo_full),
        .afull    (),
        .data_out ({memctrl_wstrb, memctrl_wdata}),
        .pull     (memctrl_wready & !pending_rd),
        .empty    (data_fifo_empty),
        .aempty   ()
    );

    assign mst_wready = !data_fifo_full;
    assign memctrl_wvalid = !data_fifo_empty & !pending_rd;
    assign memctrl_awprot = 3'b0;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Track the current write outstanding request issued in the memory 
    // controller. The flag is used in fetcher stage to inhibit read request
    //
    ///////////////////////////////////////////////////////////////////////////

    friscv_axi_or_tracker 
    #(
        .NAME   ("dCache-Pusher"),
        .MAX_OR (OSTDREQ_NUM)
    )
    outstanding_request_tracker 
    (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .srst           (srst),
        .awvalid        (memctrl_awvalid),
        .awready        (memctrl_awready),
        .bvalid         (memctrl_bvalid),
        .bready         (memctrl_bready),
        .arvalid        (1'b0),
        .arready        (1'b0),
        .rvalid         (1'b0),
        .rready         (1'b0),
        .waiting_wr_cpl (pending_wr_or),
        .waiting_rd_cpl ()
    );

    assign memctrl_bready = 1'b1;
    
    assign pending_wr = pending_wr_or | cache_wen;

endmodule

`resetall
