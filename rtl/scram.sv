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
        input  wire                aclk,
        // Port 1
        input  wire                p1_en,
        input  wire                p1_wr,
        input  wire  [ADDRW  -1:0] p1_addr,
        input  wire  [DATAW  -1:0] p1_wdata,
        input  wire  [DATAW/8-1:0] p1_strb,
        output logic [DATAW  -1:0] p1_rdata,
        output logic               p1_ready,
        // Port 2
        input  wire                p2_en,
        input  wire                p2_wr,
        input  wire  [ADDRW  -1:0] p2_addr,
        input  wire  [DATAW  -1:0] p2_wdata,
        input  wire  [DATAW/8-1:0] p2_strb,
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
        p1_ready <= p1_en;
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
        p2_ready <= p2_en;
    end

endmodule

`resetall
