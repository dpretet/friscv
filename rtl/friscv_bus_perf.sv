// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

/*
* This module measures the activity of a bus and returns the results into
* three registers:
*    - active time: number of cycles both valid and ready were asserted high
*    - sleep time: number of cycles both valid and ready were asserted low
*    - stall time: number of cycles valid was asserted high but ready low
*/

module friscv_bus_perf

    #(
        parameter REG_W  = 32,
        parameter NB_BUS = 1
    )(
        input  wire                        aclk,
        input  wire                        aresetn,
        input  wire                        srst,
        input  wire  [NB_BUS         -1:0] valid,
        input  wire  [NB_BUS         -1:0] ready,
        output logic [NB_BUS*REG_W*3 -1:0] perfs
    );

    for (genvar i=0;i<NB_BUS;i++) begin

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                perfs[i*REG_W*3+:3*REG_W] <= '0;
            end else if (srst) begin
                perfs[i*REG_W*3+:3*REG_W] <= '0;
            end else begin
                // active register
                if (valid[i] && ready[i])
                    perfs[i*REG_W*3+0*REG_W+:REG_W] <= perfs[i*REG_W*3+0*REG_W+:REG_W] + 1;
                // sleep register
                if (!valid[i] && ready[i] && perfs[i*REG_W*3+0*REG_W+:REG_W] > 0)
                    perfs[i*REG_W*3+1*REG_W+:REG_W] <= perfs[i*REG_W*3+1*REG_W+:REG_W] + 1;
                // stall register
                if (valid[i] && !ready[i])
                    perfs[i*REG_W*3+2*REG_W+:REG_W] <= perfs[i*REG_W*3+2*REG_W+:REG_W] + 1;
            end
        end
    end

endmodule

`resetall

