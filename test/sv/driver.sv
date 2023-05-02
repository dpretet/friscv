// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`ifndef NODEBUG
`include "svlogger.sv"
`endif

module driver

    #(
        // Maximum read/write requests the driver will issue
        parameter OSTDREQ_NUM = 8,
        // Enable or not the write channels
        parameter RW_MODE = 0,
        // LFSR key init
        parameter KEY = 32'h28346450,
        // Timeout value used outstanding request monitoring
        parameter TIMEOUT = 100,
        parameter INIT  = "init.v",
        // Instruction length
        parameter ILEN = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = ILEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = ILEN
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Testbench interface
        input  wire                       en,
        input  wire                       cache_ready,
        input  wire                       check_flush_reqs,
        input  wire                       check_flush_blocks,
        output logic                      error,
        // Flush control
        output logic                      flush_reqs,
        output logic                      flush_blocks,
        input  wire                       flush_ack,
        input  wire                       gen_io_req,
        input  wire                       gen_mem_req,
        // write channels
        output logic                      awvalid,
        input  wire                       awready,
        output logic [AXI_ADDR_W    -1:0] awaddr,
        output logic [3             -1:0] awprot,
        output logic [4             -1:0] awcache,
        output logic [AXI_ID_W      -1:0] awid,
        output logic                      wvalid,
        input  wire                       wready,
        output logic [AXI_DATA_W    -1:0] wdata,
        output logic [AXI_DATA_W/8  -1:0] wstrb,
        input  wire                       bvalid,
        output logic                      bready,
        input  wire  [AXI_ID_W      -1:0] bid,
        input  wire  [2             -1:0] bresp,
        // read channels
        output logic                      arvalid,
        input  wire                       arready,
        output logic [AXI_ADDR_W    -1:0] araddr,
        output logic [3             -1:0] arprot,
        output logic [4             -1:0] arcache,
        output logic [AXI_ID_W      -1:0] arid,
        input  wire                       rvalid,
        output logic                      rready,
        input  wire  [AXI_ID_W      -1:0] rid,
        input  wire  [2             -1:0] rresp,
        input  wire  [AXI_DATA_W    -1:0] rdata
    );

    `ifndef NODEBUG
    // Logger setup

    svlogger log;
    string svlogger_name;
    string msg;

    initial begin
        log = new("log_driver",
                  `SVL_VERBOSE_DEBUG,
                  `SVL_ROUTE_ALL);
    end
    `endif

    // TODO: Adjust RAM depth and address vector from a parameter
    localparam DEPTH = 262144;
    logic [AXI_DATA_W-1:0] mem [DEPTH:0];
    initial $readmemh(INIT, mem, 0, DEPTH);

    localparam MAX_OR = 64;

    integer                                  arbeat_cnt;
    integer                                  rbatch_len;
    integer                                  nb_rd_inst;
    logic [32                          -1:0] arvalid_lfsr;
    logic [32                          -1:0] rready_lfsr;
    logic [32                          -1:0] ar_lfsr;
    logic [32                          -1:0] r_lfsr;
    logic [AXI_ID_W                    -1:0] rid_cnt;
    logic [MAX_OR                      -1:0] rd_orreq;
    logic [MAX_OR*AXI_ID_W             -1:0] rd_orreq_id;
    logic [MAX_OR*AXI_DATA_W           -1:0] rd_orreq_rdata;
    logic [MAX_OR*AXI_DATA_W           -1:0] rd_orreq_araddr;

    logic [MAX_OR                      -1:0] ror_error;
    logic [MAX_OR                      -1:0] rid_error;
    logic [MAX_OR                      -1:0] rdata_error;
    integer                                  rd_orreq_timer[MAX_OR-1:0];
    logic                                    artimeout;
    integer                                  artimer;
    integer                                  rreq_or_cnt;
    integer                                  rcpl_or_cnt;
    logic                                    block_rch;
    logic                                    rvalid_s;
    logic [AXI_ID_W                    -1:0] next_rid;

    logic [32                          -1:0] awvalid_lfsr;
    logic [32                          -1:0] wvalid_lfsr;
    logic [32                          -1:0] bready_lfsr;
    logic [32                          -1:0] aw_lfsr;
    logic [32                          -1:0] w_lfsr;
    logic [32                          -1:0] b_lfsr;
    logic [AXI_ID_W                    -1:0] bid_cnt;

    logic                                    rden;
    logic                                    wren;

    logic [AXI_ADDR_W                  -1:0] awaddr_ff;
    logic [AXI_DATA_W                  -1:0] wdata_ff;
    logic [AXI_DATA_W/8                -1:0] wstrb_ff;
    logic                                    pull_wfifos;
    logic                                    awempty;
    logic                                    wempty;
    integer                                  awbeat_cnt;
    integer                                  wbeat_cnt;
    integer                                  wbatch_len;
    integer                                  wreq_or_cnt;
    logic [MAX_OR                      -1:0] wr_orreq;
    logic [MAX_OR*AXI_ID_W             -1:0] wr_orreq_id;
    integer                                  wr_orreq_timer[MAX_OR-1:0];
    integer                                  wcpl_or_cnt;
    logic [MAX_OR                      -1:0] bid_error;
    logic [MAX_OR                      -1:0] bor_error;
    logic                                    awtimeout;
    integer                                  awtimer;
    logic                                    wtimeout;
    integer                                  wtimer;
    logic                                    seq;


    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Central sequencer managing read then write controllers
    ///////////////////////////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rden <= 1'b0;
            wren <= 1'b0;
            seq <= 1'b0;
        end else if (srst) begin
            rden <= 1'b0;
            wren <= 1'b0;
            seq <= 1'b0;
        end else begin
            if (cache_ready) begin
                // Boot driver
                if (!seq) begin
                    // end of read batch, move to write
                    if ((arbeat_cnt==(rbatch_len-1) || rbatch_len==0) && RW_MODE && arvalid && arready) begin
                        rden <= 1'b0;
                        seq <= 1'b1;
                    end else begin
                        rden <= !(|wr_orreq);
                    end
                end else begin
                    // end of write batch, mve to read
                    if ((awbeat_cnt==(wbatch_len-1) || wbatch_len==0) && awvalid && awready) begin
                        wren <= 1'b0;
                        seq <= 1'b0;
                    end else begin
                        wren <= !(|rd_orreq);
                    end
                end
            end else begin
                rden <= 1'b0;
                wren <= 1'b0;
                seq <= 1'b0;
            end
        end
    end


    // Error report to the testbench
    assign error = en & (|ror_error | rid_error | rdata_error | 
                          artimeout | awtimeout | wtimeout |
                         |bor_error | bid_error);


    ///////////////////////////////////////////////////////////////////////////////////////////////
    //
    // Read channels
    //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Read address channels
    ///////////////////////////////////////////////////////////////////////////////////////////////

    assign arprot = 3'b0;
    assign arcache = {2'b0,gen_io_req & rbatch_len[2],1'b0};

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            arid <= {AXI_ID_W{1'b0}};
            next_rid <= {AXI_ID_W{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            arbeat_cnt <= 0;
            rbatch_len <= 8;
            rreq_or_cnt <= 0;
            flush_reqs <= 1'b0;
            flush_blocks <= 1'b0;
        end else if (srst) begin
            arid <= {AXI_ID_W{1'b0}};
            next_rid <= {AXI_ID_W{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            arbeat_cnt <= 0;
            rbatch_len <= 8;
            rreq_or_cnt <= 0;
            flush_reqs <= 1'b0;
            flush_blocks <= 1'b0;
        end else begin

            if (flush_reqs) begin
                flush_reqs <= 1'b0;
                rreq_or_cnt <= 0;
            end

            if (flush_blocks && flush_ack) begin
                flush_blocks <= 1'b0;
                rreq_or_cnt <= 0;
            end

            if (arvalid && arready) begin

                if (rreq_or_cnt==(MAX_OR-1)) begin
                    rreq_or_cnt <= 0;
                end else begin
                    rreq_or_cnt <= rreq_or_cnt + 1;
                end

                if (arbeat_cnt==(rbatch_len-1) || rbatch_len==0) begin

                    arid <= arid + 1;
                    if (ar_lfsr[3:0] > OSTDREQ_NUM)
                        rbatch_len <= OSTDREQ_NUM;
                    else
                        rbatch_len <= ar_lfsr[3:0];
                    // Add two LSB because the AXI interface is byte oriented
                    araddr <= {ar_lfsr[19:2], 2'b00};
                    arbeat_cnt <= 0;

                    if (araddr[10+:3]==3'b101 && check_flush_reqs) begin
                        flush_reqs <= 1'b1;
                        next_rid <= arid + 1;
                    end

                    if (araddr[10+:8]==8'b1 && check_flush_blocks) begin
                        flush_blocks <= 1'b1;
                        next_rid <= arid + 1;
                    end

                end else begin
                    arbeat_cnt <= arbeat_cnt + 1;
                    araddr <= araddr + 4;
                end
            end
        end
    end

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            arvalid_lfsr <= 32'b0;
        end else if (srst) begin
            arvalid_lfsr <= 32'b0;
        end else begin

            // At startup init with LFSR d
            // efault value
            if (arvalid_lfsr==32'b0) begin
                arvalid_lfsr <= ar_lfsr;
            // Use to randomly assert arvalid/wvalid
            end else if (!arvalid_lfsr[0]) begin
                arvalid_lfsr <= arvalid_lfsr >> 1;
            end else if (arready) begin
                arvalid_lfsr <= ar_lfsr;
            end

        end
    end

    // LFSR to generate valid of AR channel
    lfsr32
    #(
        .KEY (KEY)
    )
    arch_lfsr
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (arvalid & arready),
        .lfsr    (ar_lfsr)
    );

    assign arvalid = arvalid_lfsr[0] & !rd_orreq[rreq_or_cnt] & en & rden & 
                     !(flush_reqs | flush_blocks | flush_ack | |wr_orreq);

    ///////////////////////////////////////////////////////////////////////////
    // Monitor AR channel to detect timeout
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            artimer <= 0;
            artimeout <= 1'b0;
        end else if (srst) begin
            artimer <= 0;
            artimeout <= 1'b0;
        end else if (en) begin
            if (arvalid && !arready) begin
                artimer <= artimer + 1;
            end else begin
                artimer <= 0;
            end
            if (artimer >= TIMEOUT) begin
                artimeout <= 1'b1;
                `ifndef NODEBUG
                log.error("AR Channel reached timeout");
                `endif
            end else begin
                artimeout <= 1'b0;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Read Response channel
    ///////////////////////////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            block_rch <= 1'b0;
        end else if (srst) begin
            block_rch <= 1'b0;
        end else begin
            if (flush_reqs) 
                block_rch <= 1'b1;
            else if (rid==next_rid) 
                block_rch <= 1'b0;
        end
    end

    assign rvalid_s = (!check_flush_reqs         ) ? rvalid :
                      (block_rch && rid==next_rid) ? rvalid :
                      (block_rch && rid!=next_rid) ? 1'b0 :
                                                     rvalid;

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            rready_lfsr <= 32'b0;
        end else if (srst) begin
            rready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (rready_lfsr==32'b0) begin
                rready_lfsr <= r_lfsr;
            // Use to randomly assert arready
            end else if (!rready) begin
                rready_lfsr <= rready_lfsr >> 1;
            end else if (rvalid_s) begin
                rready_lfsr <= r_lfsr;
            end
        end
    end

    assign rready = rready_lfsr[0];

    // LFSR to generate valid of R channel
    lfsr32
    #(
        .KEY (KEY)
    )
    rch_lfsr
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (rvalid_s & rready),
        .lfsr    (r_lfsr)
    );


    ///////////////////////////////////////////////////////////////////////////////
    // Read Oustanding Requests Management
    ///////////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin

            rd_orreq <= {MAX_OR{1'b0}};
            rd_orreq_id <= {MAX_OR*AXI_ID_W{1'b0}};
            rd_orreq_rdata <= {MAX_OR*AXI_DATA_W{1'b0}};
            rd_orreq_araddr <= {MAX_OR*AXI_ADDR_W{1'b0}};
            ror_error <= {MAX_OR{1'b0}};
            rid_error <= {MAX_OR{1'b0}};
            rcpl_or_cnt <= 0;
            rid_error <= 1'b0;
            rdata_error = 1'b0;

            for (int i=0;i<MAX_OR;i++) begin
                rd_orreq_timer[i] <= 0;
            end

        end else if (srst) begin

            rd_orreq <= {MAX_OR{1'b0}};
            rd_orreq_id <= {MAX_OR*AXI_ID_W{1'b0}};
            rd_orreq_rdata <= {MAX_OR*AXI_DATA_W{1'b0}};
            rd_orreq_araddr <= {MAX_OR*AXI_ADDR_W{1'b0}};
            ror_error <= {MAX_OR{1'b0}};
            rid_error <= {MAX_OR{1'b0}};
            rcpl_or_cnt <= 0;
            rid_error <= 1'b0;
            rdata_error = 1'b0;

            for (int i=0;i<MAX_OR;i++) begin
                rd_orreq_timer[i] <= 0;
            end

        end else if (en) begin

            if (flush_reqs || flush_blocks) begin
                rcpl_or_cnt <= 0;
            end else if (rvalid_s && rready) begin
                if (rcpl_or_cnt==(MAX_OR-1))
                    rcpl_or_cnt <= 0;
                else
                    rcpl_or_cnt <= rcpl_or_cnt + 1;
            end

            for (int i=0;i<MAX_OR;i++) begin

                // Clear all OR stored if flushing either the requests or the blocks
                if (flush_reqs || flush_blocks) begin
                    rd_orreq[i] <= 1'b0;
                // Store the OR request on address channel handshake
                end else if (arvalid && arready && i==rreq_or_cnt) begin
                    rd_orreq[i] <= 1'b1;
                    rd_orreq_id[i*AXI_ID_W+:AXI_ID_W] <= arid;
                    rd_orreq_araddr[i*AXI_ADDR_W+:AXI_ADDR_W] <= araddr;
                    // Divide by 4 the address because the cache is addressed with byte granularity
                    // over AXI but the RAM used here is DWORD oriented
                    rd_orreq_rdata[i*AXI_DATA_W+:AXI_DATA_W] <= mem[araddr/4];
                end

                // And release the OR when handshaking with RLAST
                if (rvalid_s && rready && rcpl_or_cnt==i && !flush_reqs) begin

                    rd_orreq[i] <= 1'b0;

                    if (rd_orreq_id[rcpl_or_cnt*AXI_ID_W+:AXI_ID_W]!==rid) begin
                        rid_error <= 1'b1;
                        `ifndef NODEBUG
                        $sformat(msg, "Read ID is wrong:");
                        log.error(msg);
                        $sformat(msg, "  - completion nb: %0d",  rcpl_or_cnt);
                        log.error(msg);
                        $sformat(msg, "  - addr: %x",  rd_orreq_araddr[rcpl_or_cnt*AXI_ADDR_W+:AXI_ADDR_W]);
                        log.error(msg);
                        $sformat(msg, "  - rid: %x",  rid);
                        log.error(msg);
                        $sformat(msg, "  - rdata: %x",  rdata);
                        log.error(msg);
                        $sformat(msg, "  - expected: %x", rd_orreq_id[rcpl_or_cnt*AXI_ID_W+:AXI_ID_W]);
                        log.error(msg);
                        `endif
                    end

                    if (rd_orreq_rdata[rcpl_or_cnt*AXI_DATA_W+:AXI_DATA_W] !== rdata) begin
                        rdata_error = 1'b1;
                        `ifndef NODEBUG
                        $sformat(msg, "Read data is wrong:");
                        log.error(msg);
                        $sformat(msg, "  - completion nb: %0d",  rcpl_or_cnt);
                        log.error(msg);
                        $sformat(msg, "  - addr: %x",  rd_orreq_araddr[rcpl_or_cnt*AXI_ADDR_W+:AXI_ADDR_W]);
                        log.error(msg);
                        $sformat(msg, "  - rid: %x",  rid);
                        log.error(msg);
                        $sformat(msg, "  - rdata: %x",  rdata);
                        log.error(msg);
                        $sformat(msg, "  - expected: %x", rd_orreq_rdata[rcpl_or_cnt*AXI_DATA_W+:AXI_DATA_W]);
                        log.error(msg);
                        `endif
                    end
                end

                // Manage OR timeout
                if (rd_orreq[i]) begin
                    if (rd_orreq_timer[i]==TIMEOUT) begin
                        `ifndef NODEBUG
                        $sformat(msg, "Read OR %0x reached timeout (@ %g ns)", i, $realtime);
                        log.error(msg);
                        `endif
                        ror_error[i] <= 1'b1;
                    end else if (rd_orreq_timer[i]<=TIMEOUT) begin
                        rd_orreq_timer[i] <= rd_orreq_timer[i] + 1;
                    end
                end else begin
                    rd_orreq_timer[i] <= 0;
                    ror_error[i] <= 1'b0;
                end

            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////////////////////////
    //
    // Write address, data & response channels
    //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    generate if (RW_MODE>0) begin

        assign awprot = 3'b0;
        assign awcache = {2'b0,gen_io_req & wbatch_len[2],1'b0};

        always @ (posedge aclk or negedge aresetn) begin

            if (!aresetn) begin
                awid <= {AXI_ID_W{1'b0}};
                awaddr <= {AXI_ADDR_W{1'b0}};
                awbeat_cnt <= 0;
                wbatch_len <= 8;
                wreq_or_cnt <= 0;
            end else if (srst) begin
                awid <= {AXI_ID_W{1'b0}};
                awaddr <= {AXI_ADDR_W{1'b0}};
                awbeat_cnt <= 0;
                wbatch_len <= 8;
                wreq_or_cnt <= 0;
            end else begin

                if (awvalid && awready) begin

                    if (wreq_or_cnt==(MAX_OR-1)) begin
                        wreq_or_cnt <= 0;
                    end else begin
                        wreq_or_cnt <= wreq_or_cnt + 1;
                    end

                    if (awbeat_cnt==(wbatch_len-1) || wbatch_len==0) begin
                        // Ensure write data channel finalized its last transaction
                        awid <= awid + 1;
                        if (aw_lfsr[3:0] > OSTDREQ_NUM)
                            wbatch_len <= OSTDREQ_NUM;
                        else
                            wbatch_len <= aw_lfsr[3:0];
                        // Add two LSB because the AXI interface is byte oriented
                        awaddr <= {aw_lfsr[19:2], 2'b00};
                        awbeat_cnt <= 0;

                        if (awaddr[10+:3]==3'b101) begin
                            awid <= awid + 1;
                        end
                    end else begin
                        awbeat_cnt <= awbeat_cnt + 1;
                        awaddr <= awaddr + 4;
                    end
                end
            end
        end

        always @ (posedge aclk or negedge aresetn) begin

            if (!aresetn) begin
                awvalid_lfsr <= 32'b0;
            end else if (srst) begin
                awvalid_lfsr <= 32'b0;
            end else begin

                // At startup init with LFSR default value
                if (awvalid_lfsr==32'b0) begin
                    awvalid_lfsr <= aw_lfsr;
                // Use to randomly assert awvalid
                end else if (~awvalid_lfsr[0]) begin
                    awvalid_lfsr <= awvalid_lfsr >> 1;
                end else if (awready) begin
                    awvalid_lfsr <= aw_lfsr;
                end

            end
        end

        // LFSR to generate valid of AW / W channels
        lfsr32
        #(
            .KEY (KEY)
        )
        awch_lfsr
        (
            .aclk    (aclk),
            .aresetn (aresetn),
            .srst    (srst),
            .en      (awvalid & awready),
            .lfsr    (aw_lfsr)
        );

        // LFSR to generate valid of AW / W channels
        lfsr32
        #(
            .KEY ({KEY[0+:16], KEY[16+:16]})
        )
        wch_lfsr
        (
            .aclk    (aclk),
            .aresetn (aresetn),
            .srst    (srst),
            .en      (wvalid & wready),
            .lfsr    (w_lfsr)
        );

        ///////////////////////////////////////////////////////////////////////////
        // Monitor AW channel to detect timeout
        ///////////////////////////////////////////////////////////////////////////

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                awtimer <= 0;
                awtimeout <= 1'b0;
            end else if (srst) begin
                awtimer <= 0;
                awtimeout <= 1'b0;
            end else if (en) begin
                if (awvalid && !awready) begin
                    awtimer <= awtimer + 1;
                end else begin
                    awtimer <= 0;
                end
                if (awtimer >= TIMEOUT) begin
                    awtimeout <= 1'b1;
                    `ifndef NODEBUG
                    log.error("AW Channel reached timeout");
                    `endif
                end else begin
                    awtimeout <= 1'b0;
                end
            end
        end

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                wtimer <= 0;
                wtimeout <= 1'b0;
            end else if (srst) begin
                wtimer <= 0;
                wtimeout <= 1'b0;
            end else if (en) begin
                if (wvalid && !wready) begin
                    wtimer <= wtimer + 1;
                end else begin
                    wtimer <= 0;
                end
                if (wtimer >= TIMEOUT) begin
                    wtimeout <= 1'b1;
                    `ifndef NODEBUG
                    log.error("W Channel reached timeout");
                    `endif
                end else begin
                    wtimeout <= 1'b0;
                end
            end
        end

        assign awvalid = awvalid_lfsr[0] & !wr_orreq[wreq_or_cnt] & en & wren & !(|rd_orreq);
        assign wvalid = awvalid;
        assign wdata = w_lfsr[0+:AXI_DATA_W];
        assign wstrb = w_lfsr[0+:AXI_DATA_W/8];


        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                wr_orreq <= {MAX_OR{1'b0}};
                wr_orreq_id <= {MAX_OR*AXI_ID_W{1'b0}};
                for (int i=0;i<MAX_OR;i++) begin
                    wr_orreq_timer[i] <= 0;
                end
                wcpl_or_cnt <= 0;
                bid_error <= 1'b0;
                bor_error <= {MAX_OR{1'b0}};
            end else if (srst) begin
                wr_orreq <= {MAX_OR{1'b0}};
                wr_orreq_id <= {MAX_OR*AXI_ID_W{1'b0}};
                for (int i=0;i<MAX_OR;i++) begin
                    wr_orreq_timer[i] <= 0;
                end
                wcpl_or_cnt <= 0;
                bid_error <= 1'b0;
                bor_error <= {MAX_OR{1'b0}};
            end else begin

                if (bvalid & bready) begin
                    if (wcpl_or_cnt==(MAX_OR-1))
                        wcpl_or_cnt <= 0;
                    else
                        wcpl_or_cnt <= wcpl_or_cnt + 1;
                end
                    
                for (int i=0;i<MAX_OR;i++) begin

                    if (awvalid && awready && i==wreq_or_cnt) begin
                        wr_orreq[i] <= 1'b1;
                        wr_orreq_id[i*AXI_ID_W+:AXI_ID_W] <= awid;
                    end

                    if (bvalid && bready && wcpl_or_cnt==i) begin

                        wr_orreq[i] <= 1'b0;

                        if (wr_orreq_id[wcpl_or_cnt*AXI_ID_W+:AXI_ID_W]!==bid) begin
                            bid_error <= 1'b1;
                            `ifndef NODEBUG
                            $sformat(msg, "Write ID is wrong:");
                            log.error(msg);
                            $sformat(msg, "  - completion nb: %0d",  wcpl_or_cnt);
                            log.error(msg);
                            $sformat(msg, "  - bid: %x",  bid);
                            log.error(msg);
                            $sformat(msg, "  - expected: %x", wr_orreq_id[wcpl_or_cnt*AXI_ID_W+:AXI_ID_W]);
                            log.error(msg);
                            `endif
                        end

                    end
                    // Manage OR timeout
                    if (wr_orreq[i]) begin
                        if (wr_orreq_timer[i]==TIMEOUT) begin
                            `ifndef NODEBUG
                            $sformat(msg, "WR OR %0x reached timeout (@ %g ns)", i, $realtime);
                            log.error(msg);
                            `endif
                            bor_error[i] <= 1'b1;
                        end else if (wr_orreq_timer[i]<=TIMEOUT) begin
                            wr_orreq_timer[i] <= wr_orreq_timer[i] + 1;
                        end
                    end else begin
                        wr_orreq_timer[i] <= 0;
                        bor_error[i] <= 1'b0;
                    end
                end
            end
        end

        always @ (posedge aclk or negedge aresetn) begin

            if (!aresetn) begin
                bready_lfsr <= 32'b0;
            end else if (srst) begin
                bready_lfsr <= 32'b0;
            end else begin
                // At startup init with LFSR default value
                if (bready_lfsr==32'b0) begin
                    bready_lfsr <= b_lfsr;
                // Use to randomly assert arready
                end else if (!bready) begin
                    bready_lfsr <= bready_lfsr >> 1;
                end else if (bvalid) begin
                    bready_lfsr <= b_lfsr;
                end
            end
        end

        assign bready = bready_lfsr[0];

        // LFSR to generate valid of R channel
        lfsr32
        #(
            .KEY (KEY)
        )
        bch_lfsr
        (
            .aclk    (aclk),
            .aresetn (aresetn),
            .srst    (srst),
            .en      (bvalid & bready),
            .lfsr    (b_lfsr)
        );

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Manage local RAM update when writing cache
    ///////////////////////////////////////////////////////////////////////////////////////////////

    logic [AXI_ADDR_W  -1:0] awaddr_w;
    logic                    awchfull;
    logic                    awchempty;
    logic [AXI_DATA_W  -1:0] wdata_w;
    logic [AXI_DATA_W/8-1:0] wstrb_w;
    logic                    wchfull;
    logic                    wchempty;
    logic                    pull_wfifos;

    friscv_scfifo 
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (8),
        .DATA_WIDTH (AXI_ADDR_W)
    )
    awfifo_w 
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  (awaddr),
        .push     (awvalid & awready),
        .full     (awchfull),
        .afull    (),
        .data_out (awaddr_w),
        .pull     (pull_wfifos & !wchempty),
        .empty    (awchempty),
        .aempty   ()
    );

    friscv_scfifo 
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (8),
        .DATA_WIDTH (AXI_DATA_W+AXI_DATA_W/8)
    )
    wfifo_w 
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({wstrb,wdata}),
        .push     (wvalid & wready),
        .full     (wchfull),
        .afull    (),
        .data_out ({wstrb_w,wdata_w}),
        .pull     (pull_wfifos & !awchempty),
        .empty    (wchempty),
        .aempty   ()
    );

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            pull_wfifos <= 1'b0;
        end if (srst) begin
            pull_wfifos <= 1'b0;
        end else begin

            if (!awchempty && !wchempty) begin
                pull_wfifos <= 1'b1;
            end else begin
                pull_wfifos <= 1'b0;
            end

            if (!awchempty && !wchempty) begin
                for (integer i=0;i<AXI_DATA_W/8;i++)
                    if (wstrb_w[i])
                        mem[awaddr_w/4][8*i+:8] <= wdata_w[8*i+:8];
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // No Write channels
    ///////////////////////////////////////////////////////////////////////////////////////////////
    end else begin

        assign awbeat_cnt = 0;
        assign awvalid = 1'b0;
        assign awaddr = {AXI_ADDR_W{1'b0}};
        assign awprot = 3'b0;
        assign awcache = 4'b0;
        assign awid = {AXI_ID_W{1'b0}};
        assign wvalid = 1'b0;
        assign wdata = {AXI_DATA_W{1'b0}};
        assign wstrb = {AXI_DATA_W/8{1'b0}};
        assign bready = 1'b0;
        assign wr_orreq = {MAX_OR{1'b0}};
        assign wr_orreq_id = {MAX_OR*AXI_ID_W{1'b0}};
        for (genvar i=0;i<MAX_OR;i++) begin
            assign wr_orreq_timer[i] = 0;
        end
        assign wcpl_or_cnt = 0;
        assign bid_error = 1'b0;
        assign bor_error = {MAX_OR{1'b0}};
        assign awtimeout = 1'b0;
        assign wtimeout = 1'b0;
    end

    endgenerate

endmodule

`resetall
