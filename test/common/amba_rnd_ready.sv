// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module amba_rnd_ready

    #(
        parameter SEED = 32'hFFFFFFFF
    )(
        input  wire        aclk,
        input  wire        aresetn,
        input  wire        srst,
        input  wire        valid_i,
        input  wire        ready_i,
        output logic       ready_o
    );

    logic [31:0] ready_lfsr;
    logic [31:0] lfsr;

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            ready_lfsr <= 32'b0;
        end else if (srst) begin
            ready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (ready_lfsr==32'b0) begin
                ready_lfsr <= lfsr;
                // Used to randomly assert ready
            end else if (!ready_i) begin
                ready_lfsr <= ready_lfsr >> 1;
            end else if (valid_i) begin
                ready_lfsr <= lfsr;
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

    assign ready_o = ready_lfsr[0];

endmodule

`resetall
