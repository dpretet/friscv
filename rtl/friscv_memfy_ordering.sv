// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_memfy_ordering

    #(
        // Select the ordering scheme:
        //   - 0: ongoing reads block write request, ongoing writes block read request
        //   - 1: concurrent r/w requests can be issued if don't target cache block under access
        parameter AXI_ORDERING = 0,
        // Maximum outstanding request supported
        parameter MAX_OR = 8,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 32,
        // Cache block width in bits
        parameter MEM_BLOCK_W = 128
    )(
        input  wire                        aclk,
        input  wire                        aresetn,
        input  wire                        srst,
        // Processing bus
        input  wire                        memfy_valid,
        input  wire                        memfy_ready,
        input  wire [`OPCODE_W       -1:0] memfy_opcode,
        input  wire [AXI_ADDR_W      -1:0] memfy_addr,
        input  wire                        memfy_rd_wr,
        // AXI interface
        input  wire                        bvalid,
        input  wire                        bready,
        input  wire                        rvalid,
        input  wire                        rready,
        // Status flag
        output logic                       wr_coll,
        output logic                       rd_coll,
        output logic                       max_wr_or,
        output logic                       max_rd_or,
        output logic                       pending_wr,
        output logic                       pending_rd
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    localparam MAX_OR_W = $clog2(MAX_OR) + 1;
    localparam ADDR_LSB = $clog2(MEM_BLOCK_W / 8);

    logic [MAX_OR_W    -1:0] wr_or_cnt;
    logic [MAX_OR_W    -1:0] rd_or_cnt;

    logic                    rd_req_full;
    logic                    rd_req_afull;
    logic                    rd_req_empty;
    logic                    rd_req_aempty;
    logic                    wr_req_full;
    logic                    wr_req_afull;
    logic                    wr_req_empty;
    logic                    wr_req_aempty;
    logic                    push_rd;
    logic                    push_wr;
    logic                    pull_rd;
    logic                    pull_wr;


    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else if (srst) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else begin

            // Write xfers tracker
            if (memfy_valid && memfy_ready && memfy_opcode==`STORE && !bvalid && !max_wr_or) begin
                wr_or_cnt <= wr_or_cnt + 1'b1;
            end else if (!(memfy_valid && memfy_ready && memfy_opcode==`STORE) && bvalid && bready && wr_or_cnt!={MAX_OR_W{1'b0}}) begin
                wr_or_cnt <= wr_or_cnt - 1'b1;
            end

            // Read xfers tracker
            if (memfy_valid && memfy_ready && memfy_opcode==`LOAD && !memfy_rd_wr && !max_rd_or) begin
                rd_or_cnt <= rd_or_cnt + 1'b1;
            end else if (!(memfy_valid && memfy_ready && memfy_opcode==`LOAD) && memfy_rd_wr && rd_or_cnt!={MAX_OR_W{1'b0}}) begin
                rd_or_cnt <= rd_or_cnt - 1'b1;
            end

            `ifdef FRISCV_SIM
            //synthesis translate_off
            //synopsys translate_off
            if (memfy_valid && memfy_ready && memfy_opcode==`STORE && !bvalid && max_wr_or) begin
                $display("ERROR: (@%0t) %s: Reached maximum write OR number but continue to issue requests", $realtime, "Memfy");
            end else if (!(memfy_valid && memfy_ready && memfy_opcode==`STORE) && bvalid && bready && wr_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: (@%0t) %s: Freeing a write OR but counter is already 0", $realtime, "Memfy");
            end

            if (memfy_valid && memfy_ready && memfy_opcode==`LOAD && !memfy_rd_wr && max_rd_or) begin
                $display("ERROR: (@%0t) %s: Reached maximum read OR number but continue to issue requests", $realtime, "Memfy");
            end else if (!(memfy_valid && memfy_ready && memfy_opcode==`LOAD) && memfy_rd_wr && rd_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: (@%0t) %s: Freeing a read OR but counter is already 0", $realtime, "Memfy");
            end
            //synopsys translate_on
            //synthesis translate_on
            `endif
        end
    end

    assign max_wr_or = (wr_or_cnt==MAX_OR[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;
    assign max_rd_or = (rd_or_cnt==MAX_OR[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Basic read/write requests tracking by using counters
    ///////////////////////////////////////////////////////////////////////////

    generate 

    if (AXI_ORDERING == 0) begin : STRICT_ORDERING

        assign pending_wr = (wr_or_cnt!={MAX_OR_W{1'b0}} && !(wr_or_cnt=={{(MAX_OR_W-1){1'b0}}, 1'b1} & bvalid)) ? 1'b1 : 1'b0;
        assign pending_rd = (rd_or_cnt!={MAX_OR_W{1'b0}} && !(rd_or_cnt=={{(MAX_OR_W-1){1'b0}}, 1'b1} & rvalid)) ? 1'b1 : 1'b0;

        // In this mode, no concurrent transfer can be done, ongoing requests block the other channel
        assign wr_coll = pending_wr;
        assign rd_coll = pending_rd;

        assign push_rd = 0;
        assign push_wr = 0;
        assign pull_rd = 0;
        assign pull_wr = 0;
        assign rd_req_full = 0;
        assign wr_req_full = 0;
        assign rd_req_afull = 0;
        assign wr_req_afull = 0;
        assign rd_req_empty = 0;
        assign wr_req_empty = 0;
        assign rd_req_aempty = 0;
        assign wr_req_aempty = 0;

    //////////////////////////////////////////////////////////////////////// 
    // Advanced mode, using LUT for read / write request tracking, providing
    // better performance
    //////////////////////////////////////////////////////////////////////// 
    end else begin: WEAK_ORDERING

        assign push_wr = memfy_valid && memfy_ready && memfy_opcode==`STORE;
        assign pull_wr = bvalid & bready;

        friscv_lut
        #(
            .NB_TOKEN     (MAX_OR),
            .TOKEN_W      (AXI_ADDR_W-ADDR_LSB)
        ) wr_req (
            .aclk           (aclk),
            .aresetn        (aresetn),
            .srst           (srst),
            .flush          ('0),
            .seek           (memfy_addr[AXI_ADDR_W-1:ADDR_LSB]),
            .hit            (wr_coll),
            .push           (push_wr), 
            .pull           (pull_wr),
            .token          (memfy_addr[AXI_ADDR_W-1:ADDR_LSB]),
            .full           (wr_req_full),
            .afull          (wr_req_afull),
            .empty          (wr_req_empty),
            .aempty         (wr_req_aempty)
        );

        assign push_rd = memfy_valid && memfy_ready && memfy_opcode==`LOAD;
        assign pull_rd = rvalid & rready;

        friscv_lut
        #(
            .NB_TOKEN     (MAX_OR),
            .TOKEN_W      (AXI_ADDR_W-ADDR_LSB)
        ) rd_req (
            .aclk           (aclk),
            .aresetn        (aresetn),
            .srst           (srst),
            .flush          ('0),
            .seek           (memfy_addr[AXI_ADDR_W-1:ADDR_LSB]),
            .hit            (rd_coll),
            .push           (push_rd), 
            .pull           (pull_rd),
            .token          (memfy_addr[AXI_ADDR_W-1:ADDR_LSB]),
            .full           (rd_req_full),
            .afull          (rd_req_afull),
            .empty          (rd_req_empty),
            .aempty         (rd_req_aempty)
        );

        assign pending_wr = !wr_req_empty;
        assign pending_rd = !rd_req_empty;

    end
    endgenerate

endmodule

`resetall
