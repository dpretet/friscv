// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_bit_sync

    #(
        parameter DEFAULT_LEVEL = 0,
        parameter DEPTH = 2
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // bit to synch & synched
        input  wire                       bit_i,
        output logic                      bit_o
    );

    logic [DEPTH-1:0] sync;

    generate

    if (DEPTH<=2) begin: DEPTH_EQ_2
        always @ (posedge aclk or negedge aresetn) begin
            if (~aresetn) sync <= {DEPTH{DEFAULT_LEVEL[0]}};
            else if (srst) sync <= {DEPTH{DEFAULT_LEVEL[0]}};
            else sync <= {sync[0],bit_i};
        end
    end else begin: DEPTH_GT_2
        always @ (posedge aclk or negedge aresetn) begin

            if (~aresetn) sync <= {DEPTH{DEFAULT_LEVEL[0]}};
            else if (srst) sync <= {DEPTH{DEFAULT_LEVEL[0]}};
            else sync <= {sync[DEPTH-2:0],bit_i};
        end
    end
    endgenerate

    assign bit_o = sync[DEPTH-1];

endmodule

`resetall
