// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_bit_sync

    #(
        parameter DEPTH  = 32
    )(
        // clock & reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // bit to synch & synched
        input  logic                      bit_i,
        output logic                      bit_o
    );

    logic [1:0] sync;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) sync <= 2'b0;
        else if (srst) sync <= 2'b0;
        else sync <= {sync[0],bit_i};
    end

    assign bit_o = sync[1];

endmodule

`resetall
