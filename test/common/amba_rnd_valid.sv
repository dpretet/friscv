// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module amba_rnd_valid

    #(
        parameter SEED = 32'hFFFFFFFF
    )(
        input  wire        aclk,
        input  wire        aresetn,
        input  wire        srst,
        input  wire        valid_i,
        input  wire        ready_i,
        output logic       valid_o
    );

    logic [31:0] valid_lfsr;
    logic [31:0] lfsr;

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            valid_lfsr <= 32'b0;
    end else if (srst) begin
            valid_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (valid_lfsr==32'b0) begin
                valid_lfsr <= lfsr;
            // Used to randomly assert valid
            end else if (!valid_i) begin
                valid_lfsr <= valid_lfsr >> 1;
            end else if (ready_i) begin
                valid_lfsr <= lfsr;
            end
        end
    end

    lfsr32
    #(
        .KEY (SEED)
    )
    lfsr_inst
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (valid_i & ready_i),
        .lfsr    (lfsr)
    );

    assign valid_o = valid_lfsr[0];

endmodule

`resetall

