// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

/*
* Used to transform a signal like an interrupt which spans over several
* clock cycles into a single pulse.
*/
module friscv_pulser

    (
        input  wire        aclk,
        input  wire        aresetn,
        input  wire        srst,
        input  wire        intp,
        output logic       pulse
    );

    logic intp_reg;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            intp_reg <= 1'b0;
            pulse <= 1'b0;
        end else if (srst) begin
            intp_reg <= 1'b0;
            pulse <= 1'b0;
        end else begin
            intp_reg <= intp;
            pulse <= intp & !intp_reg;
        end
    end


endmodule

`resetall

