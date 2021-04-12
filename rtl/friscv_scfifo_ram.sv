// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_scfifo_ram

    #(
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8
    )(
        input  logic                  aclk,
        input  logic                  wr_en,
        input  logic [ADDR_WIDTH-1:0] addr_in,
        input  logic [DATA_WIDTH-1:0] data_in,
        input  logic [ADDR_WIDTH-1:0] addr_out,
        output logic [DATA_WIDTH-1:0] data_out
    );

    logic [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

    always @ (posedge aclk) begin
        if (wr_en) begin
            ram[addr_in] <= data_in;
        end
    end

    assign data_out = ram[addr_out];

endmodule

`resetall
