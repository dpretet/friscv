// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_dprambe

    #(
        parameter INIT = 0,
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8,
        parameter FFD_EN = 0
    )(
        input  wire                     aclk,
        input  wire                     p1_wren,
        input  wire  [DATA_WIDTH/8-1:0] p1_wbe,
        input  wire  [ADDR_WIDTH  -1:0] p1_addr,
        input  wire  [DATA_WIDTH  -1:0] p1_data_in,
        output logic [DATA_WIDTH  -1:0] p1_data_out,
        input  wire                     p2_wren,
        input  wire  [DATA_WIDTH/8-1:0] p2_wbe,
        input  wire  [ADDR_WIDTH  -1:0] p2_addr,
        input  wire  [DATA_WIDTH  -1:0] p2_data_in,
        output logic [DATA_WIDTH  -1:0] p2_data_out
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
        if (p1_wren) begin
            for (int i=0;i<DATA_WIDTH/8;i++)
                if (p1_wbe[i])
                    ram[p1_addr][i*8+:8] <= p1_data_in[i*8+:8];
        end
    end

    generate if (FFD_EN==1) begin : SYNC_P1_RD
        always @ (posedge aclk) begin
            p1_data_out <= ram[p1_addr];
        end
    end else begin : ASYNC_P1_RD
        assign p1_data_out = ram[p1_addr];
    end
    endgenerate

    always @ (posedge aclk) begin
        if (p2_wren) begin
            for (int i=0;i<DATA_WIDTH/8;i++)
                if (p2_wbe[i])
                    ram[p2_addr][i*8+:8] <= p2_data_in[i*8+:8];
        end
    end

    generate if (FFD_EN==1) begin : SYNC_P2_RD
        always @ (posedge aclk) begin
            p2_data_out <= ram[p2_addr];
        end
    end else begin : ASYNC_P2_RD
        assign p2_data_out = ram[p2_addr];
    end
    endgenerate

endmodule

`resetall
