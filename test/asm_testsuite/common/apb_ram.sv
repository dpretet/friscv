// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module apb_ram

    #(
        parameter INIT  = "init.v",
        parameter LATENCY = 1,
        parameter ADDRW = 4,
        parameter DATAW = 16
    )(
        input  logic               aclk,
        input  logic               aresetn,
        input  logic               srst,
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

    scram
    #(
    .INIT  (INIT),
    .ADDRW (ADDRW),
    .DATAW (DATAW)
    )
    ram
    (
    .aclk     (aclk    ),
    .aresetn  (aresetn ),
    .srst     (srst    ),
    .p1_en    (p1_en   ),
    .p1_wr    (p1_wr   ),
    .p1_addr  (p1_addr ),
    .p1_wdata (p1_wdata),
    .p1_strb  (p1_strb ),
    .p1_rdata (p1_rdata),
    .p2_en    (p2_en   ),
    .p2_wr    (p2_wr   ),
    .p2_addr  (p2_addr ),
    .p2_wdata (p2_wdata),
    .p2_strb  (p2_strb ),
    .p2_rdata (p2_rdata)
    );

    generate

    if (LATENCY==1) begin: LATENCY1

        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn==1'b0) begin
                p1_ready <= 1'b0;
            end else if (srst==1'b1) begin
                p1_ready <= 1'b0;
            end else begin
                p1_ready <= p1_en;
            end
        end

        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn==1'b0) begin
                p2_ready <= 1'b0;
            end else if (srst==1'b1) begin
                p2_ready <= 1'b0;
            end else begin
                p2_ready <= p2_en;
            end
        end

    end
    endgenerate

endmodule

`resetall
