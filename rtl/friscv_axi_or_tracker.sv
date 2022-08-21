// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_axi_or_tracker

    #(
        // Module name where the tracker is included
        parameter NAME = "OR_Tracker",
        // Maximum outstanding request supported
        parameter MAX_OR = 8
    )(
        // clock & reset
        input  wire                         aclk,
        input  wire                         aresetn,
        input  wire                         srst,
        // AXI4 interface to monitor
        input  wire                         awvalid,
        input  wire                         awready,
        input  wire                         bvalid,
        input  wire                         bready,
        input  wire                         arvalid,
        input  wire                         arready,
        input  wire                         rvalid,
        input  wire                         rready,
        // Status
        output logic                        waiting_wr_cpl,
        output logic                        waiting_rd_cpl
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    localparam MAX_OR_CMP = MAX_OR - 1;
    localparam MAX_OR_W = $clog2(MAX_OR);

    logic [MAX_OR_W    -1:0] wr_or_cnt;
    logic                    max_wr_or;
    logic [MAX_OR_W    -1:0] rd_or_cnt;
    logic                    max_rd_or;

   // Track the current read/write outstanding requests waiting completions
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else if (srst) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else begin

            // Write xfers tracker
            if (awvalid && awready && !bvalid && !max_wr_or) begin
                wr_or_cnt <= wr_or_cnt + 1'b1;
            end else if (!(awvalid & awready) && bvalid && bready && wr_or_cnt!={MAX_OR_W{1'b0}}) begin
                wr_or_cnt <= wr_or_cnt - 1'b1;
            end

            // Read xfers tracker
            if (arvalid && arready && !rvalid && !max_rd_or) begin
                rd_or_cnt <= rd_or_cnt + 1'b1;
            end else if (!(arvalid & arready) && rvalid && rready && rd_or_cnt!={MAX_OR_W{1'b0}}) begin
                rd_or_cnt <= rd_or_cnt - 1'b1;
            end

            //synthesis translate_off
            //synopsys translate_off
            if (awvalid && awready && !bvalid && max_wr_or) begin
                $display("ERROR: %s: Reached maximum write OR number but continue to issue requests", NAME);
            end else if (!awvalid && bvalid && bready && wr_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: %s: Freeing a write OR but counter is already 0", NAME);
            end

            if (arvalid && arready && !rvalid && max_rd_or) begin
                $display("ERROR: %s: Reached maximum write OR number but continue to issue requests", NAME);
            end else if (!arvalid && rvalid && rready && rd_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: %s: Freeing a write OR but counter is already 0", NAME);
            end
            //synopsys translate_on
            //synthesis translate_on
        end
    end

    assign max_wr_or = (wr_or_cnt==MAX_OR_CMP[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;
    assign max_rd_or = (rd_or_cnt==MAX_OR_CMP[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;

    assign waiting_wr_cpl = (wr_or_cnt!={MAX_OR_W{1'b0}}) ? 1'b1 : 1'b0;
    assign waiting_rd_cpl = (rd_or_cnt!={MAX_OR_W{1'b0}}) ? 1'b1 : 1'b0;

endmodule

`resetall
