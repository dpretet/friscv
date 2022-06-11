// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`ifndef NODEBUG
`include "svlogger.sv"
`endif

module driver

    #(
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
        output wire                       error,
        // Flush control
        output logic                      flush_reqs,
        input  wire                       flush_ack,
        // instruction memory interface
        output logic                      arvalid,
        input  wire                       arready,
        output logic [AXI_ADDR_W    -1:0] araddr,
        output logic [3             -1:0] arprot,
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
        log = new("driver_logger",
                  `SVL_VERBOSE_DEBUG,
                  `SVL_ROUTE_ALL);
    end
    `endif

    // TODO: Adjust RAM depth and address vector from a parameter
    localparam DEPTH = 262144;
    logic [AXI_DATA_W-1:0] mem [DEPTH:0];
    initial $readmemh(INIT, mem, 0, DEPTH);

    localparam MAX_OR = 64;

    integer                                  beat_cnt;
    integer                                  batch_len;
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
    integer                                  req_or_cnt;
    integer                                  cpl_or_cnt;

    assign flush_reqs = 1'b0;
    assign arprot = 3'b0;


    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            arid <= {AXI_ID_W{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            beat_cnt <= 0;
            batch_len <= 8;
            req_or_cnt <= 0;
        end else if (srst) begin
            arid <= {AXI_ID_W{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            beat_cnt <= 0;
            batch_len <= 8;
            req_or_cnt <= 0;
        end else if (arvalid && arready) begin

            if (req_or_cnt==(MAX_OR-1)) begin
                req_or_cnt <= 0;
            end else begin
                req_or_cnt <= req_or_cnt + 1;
            end

            if (beat_cnt==batch_len) begin
                arid <= arid + 1;
                batch_len <= ar_lfsr[3:0];
                // Add two LSB because the AXI interface is byte oriented
                araddr <= {ar_lfsr[19:2], 2'b00};
                beat_cnt <= 0;
            end else begin
                beat_cnt <= beat_cnt + 1;
                araddr <= araddr + 4;
            end
        end
    end

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            arvalid_lfsr <= 32'b0;
        end else if (srst) begin
            arvalid_lfsr <= 32'b0;
        end else begin

            // At startup init with LFSR default value
            if (arvalid_lfsr==32'b0) begin
                arvalid_lfsr <= ar_lfsr;
            // Use to randomly assert arvalid/wvalid
            end else if (~arvalid) begin
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

    assign arvalid = arvalid_lfsr[0] & ~rd_orreq[req_or_cnt] & en;

    ///////////////////////////////////////////////////////////////////////////
    // Monitor AR channel to detect timeout
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            artimer <= 0;
            artimeout <= 1'b0;
        end else if (srst) begin
            artimer <= 0;
            artimeout <= 1'b0;
        end else if (en) begin
            if (arvalid && ~arready) begin
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

    ///////////////////////////////////////////////////////////////////////////
    // Read Response channel
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            rready_lfsr <= 32'b0;
        end else if (srst) begin
            rready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (rready_lfsr==32'b0) begin
                rready_lfsr <= r_lfsr;
            // Use to randomly assert arready
            end else if (~rready) begin
                rready_lfsr <= rready_lfsr >> 1;
            end else if (rvalid) begin
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
        .en      (rvalid & rready),
        .lfsr    (r_lfsr)
    );


    ///////////////////////////////////////////////////////////////////////////////
    // Read Oustanding Requests Management
    ///////////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin

            rd_orreq <= {MAX_OR{1'b0}};
            rd_orreq_id <= {MAX_OR*AXI_ID_W{1'b0}};
            rd_orreq_rdata <= {MAX_OR*AXI_DATA_W{1'b0}};
            rd_orreq_araddr <= {MAX_OR*AXI_ADDR_W{1'b0}};
            ror_error <= {MAX_OR{1'b0}};
            rid_error <= {MAX_OR{1'b0}};
            cpl_or_cnt <= 0;
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
            cpl_or_cnt <= 0;
            rid_error <= 1'b0;
            rdata_error = 1'b0;

            for (int i=0;i<MAX_OR;i++) begin
                rd_orreq_timer[i] <= 0;
            end

        end else if (en) begin

            if (rvalid && rready) begin
                if (cpl_or_cnt==(MAX_OR-1))
                    cpl_or_cnt <= 0;
                else
                    cpl_or_cnt <= cpl_or_cnt + 1;
            end

            for (int i=0;i<MAX_OR;i++) begin

                // Store the OR request on address channel handshake
                if (arvalid && arready && i==req_or_cnt) begin
                    rd_orreq[i] <= 1'b1;
                    rd_orreq_id[i*AXI_ID_W+:AXI_ID_W] <= arid;
                    rd_orreq_araddr[i*AXI_ADDR_W+:AXI_ADDR_W] <= araddr;
                    // Divide by 4 the address because the cache is addressed with byte granularity
                    // over AXI but the RAM used here is DWORD oriented
                    rd_orreq_rdata[i*AXI_DATA_W+:AXI_DATA_W] <= mem[araddr/4];
                end

                // And release the OR when handshaking with RLAST
                if (rvalid && rready && cpl_or_cnt==i) begin

                    rd_orreq[i] <= 1'b0;

                    if (rd_orreq_id[cpl_or_cnt*AXI_ID_W+:AXI_ID_W]!==rid) begin
                        rid_error <= 1'b1;
                        `ifndef NODEBUG
                        $sformat(msg, "Read ID is wrong:");
                        log.error(msg);
                        $sformat(msg, "  - completion nb: %0x",  cpl_or_cnt);
                        log.error(msg);
                        $sformat(msg, "  - addr: %x",  rd_orreq_araddr[cpl_or_cnt*AXI_ADDR_W+:AXI_ADDR_W]);
                        log.error(msg);
                        $sformat(msg, "  - rid: %x",  rid);
                        log.error(msg);
                        $sformat(msg, "  - expected: %x", rd_orreq_id[cpl_or_cnt*AXI_ID_W+:AXI_ID_W]);
                        log.error(msg);
                        `endif
                    end

                    if (rd_orreq_rdata[cpl_or_cnt*AXI_DATA_W+:AXI_DATA_W] !== rdata) begin
                        rdata_error = 1'b1;
                        `ifndef NODEBUG
                        $sformat(msg, "Read data is wrong:");
                        log.error(msg);
                        $sformat(msg, "  - completion nb: %0x",  cpl_or_cnt);
                        log.error(msg);
                        $sformat(msg, "  - addr: %x",  rd_orreq_araddr[cpl_or_cnt*AXI_ADDR_W+:AXI_ADDR_W]);
                        log.error(msg);
                        $sformat(msg, "  - rdata: %x",  rdata);
                        log.error(msg);
                        $sformat(msg, "  - expected: %x", rd_orreq_rdata[cpl_or_cnt*AXI_DATA_W+:AXI_DATA_W]);
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

    // Error report to the testbench
    assign error = (en) ? (|ror_error | rid_error | rdata_error | artimeout) : 1'b0;

endmodule

`resetall
