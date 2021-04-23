// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module scram

    #(
        parameter ADDRW = 4,
        parameter DATAW = 16
    )(
        input  logic               aclk,
        // Port 1
        input  logic               p1_en,
        input  logic               p1_wr,
        input  logic [ADDRW  -1:0] p1_addr,
        input  logic [DATAW  -1:0] p1_wdata,
        input  logic [DATAW/8-1:0] p1_strb,
        output logic [DATAW  -1:0] p1_rdata,
        output logic               p1_ready,
        // Port 2
        input  logic               p2_en,
        input  logic               p2_wr,
        input  logic [ADDRW  -1:0] p2_addr,
        input  logic [DATAW  -1:0] p2_wdata,
        input  logic [DATAW/8-1:0] p2_strb,
        output logic [DATAW  -1:0] p2_rdata,
        output logic               p2_ready
    );

    logic [DATAW-1:0] ram [2**ADDRW-1:0];


    // Port 1
    always @ (posedge aclk) begin

        if (p1_en) begin
            // Write input
            if (p1_wr) begin
                for (integer i=0;i<(DATAW/8);i=i+1) begin
                    if (p1_strb[i]) begin
                        ram[p1_addr][i*8+:8] <= p1_wdata[i*8+:8];
                    end
                end
            end
            // Read output
            p1_rdata <= ram[p1_addr];
        end
        if (p1_en && ~p1_ready) begin
            p1_ready <= 1'b1;
        end else begin
            p1_ready <= 1'b0;
        end
    end


    // Port 2
    always @ (posedge aclk) begin

        if (p2_en) begin
            // Write input
            if (p2_wr) begin
                for (integer i=0;i<(DATAW/8);i=i+1) begin
                    if (p2_strb[i]) begin
                        ram[p2_addr][i*8+:8] <= p2_wdata[i*8+:8];
                    end
                end
            end
            // Read output
            p2_rdata <= ram[p2_addr];
        end
        if (p2_en && ~p2_ready) begin
            p2_ready <= 1'b1;
        end else begin
            p2_ready <= 1'b0;
        end
    end

endmodule

`resetall
