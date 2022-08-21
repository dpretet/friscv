// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_rambe

    #(
        parameter INIT = 0,
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8,
        parameter FFD_EN = 0
    )(
        input  wire                     aclk,
        input  wire                     wr_en,
        input  wire  [DATA_WIDTH/8-1:0] wr_be,
        input  wire  [ADDR_WIDTH  -1:0] addr_in,
        input  wire  [DATA_WIDTH  -1:0] data_in,
        input  wire  [ADDR_WIDTH  -1:0] addr_out,
        output logic [DATA_WIDTH  -1:0] data_out
    );

    logic [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

    initial begin
        if (INIT) begin
            for (int i=0;i<2**ADDR_WIDTH;i=i+1) begin
                ram[i] = {DATA_WIDTH{1'b0}};
            end
        end
    end

    always @ (posedge aclk) begin
    integer i;
        if (wr_en) begin
            for (i=0;i<DATA_WIDTH/8;i=i+1) begin
                if (wr_be[i])
                    ram[addr_in][i*8+:8] <= data_in[i*8+:8];
            end
        end
    end

    generate if (FFD_EN==1) begin
        always @ (posedge aclk) begin
            data_out <= ram[addr_out];
        end
    end else begin
        assign data_out = ram[addr_out];
    end
    endgenerate

endmodule

`resetall
