// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none


module axi_ram
    #(
        // Width of address bus in bits
        parameter ADDR_WIDTH = 16,
        // Width of data bus in bits
        parameter DATA_WIDTH = 32,
        // Width of wstrb (width of data bus in words)
        parameter STRB_WIDTH = (DATA_WIDTH/8),
        // Width of ID signal
        parameter ID_WIDTH = 8
    ) (
        input  logic                   aclk,
        input  logic                   aresetn,
        input  logic [ID_WIDTH-1:0]    s_axi_awid,
        input  logic [ADDR_WIDTH-1:0]  s_axi_awaddr,
        input  logic [7:0]             s_axi_awlen,
        input  logic [2:0]             s_axi_awsize,
        input  logic [1:0]             s_axi_awburst,
        input  logic [1:0]             s_axi_awlock,
        input  logic [3:0]             s_axi_awcache,
        input  logic [2:0]             s_axi_awprot,
        input  logic                   s_axi_awvalid,
        output logic                   s_axi_awready,
        input  logic [DATA_WIDTH-1:0]  s_axi_wdata,
        input  logic [STRB_WIDTH-1:0]  s_axi_wstrb,
        input  logic                   s_axi_wlast,
        input  logic                   s_axi_wvalid,
        output logic                   s_axi_wready,
        output logic [ID_WIDTH-1:0]    s_axi_bid,
        output logic [1:0]             s_axi_bresp,
        output logic                   s_axi_bvalid,
        input  logic                   s_axi_bready,
        input  logic [ID_WIDTH-1:0]    s_axi_arid,
        input  logic [ADDR_WIDTH-1:0]  s_axi_araddr,
        input  logic [7:0]             s_axi_arlen,
        input  logic [2:0]             s_axi_arsize,
        input  logic [1:0]             s_axi_arburst,
        input  logic [1:0]             s_axi_arlock,
        input  logic [3:0]             s_axi_arcache,
        input  logic [2:0]             s_axi_arprot,
        input  logic                   s_axi_arvalid,
        output logic                   s_axi_arready,
        output logic [ID_WIDTH-1:0]    s_axi_rid,
        output logic [DATA_WIDTH-1:0]  s_axi_rdata,
        output logic [1:0]             s_axi_rresp,
        output logic                   s_axi_rlast,
        output logic                   s_axi_rvalid,
        input  logic                   s_axi_rready
    );

        logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
        logic wait_wdata;

        assign s_axi_awready = ~wait_wdata;
        assign s_axi_wready = 1'b1;
        assign s_axi_arready = ~s_axi_rvalid;
        assign s_axi_bvalid = 1'b0;
        assign s_axi_rlast = 1'b1;
        assign s_axi_bresp = 2'b0;
        assign s_axi_rresp = 2'b0;

        // Simple AXI RAM, supported basic write
        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn ==  1'b0) begin
                wait_wdata <= 1'b0;
            end else begin
                if (s_axi_awvalid && s_axi_awready) begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        mem[s_axi_awaddr] <= s_axi_wdata;
                    end else begin
                        wait_wdata <= 1'b1;
                    end
                end else if (wait_wdata) begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        mem[s_axi_awaddr] <= s_axi_wdata;
                        wait_wdata <= 1'b0;
                    end
                end
            end
        end

        // TODO: Manage BRESP completion, based on number of write issued

        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn ==  1'b0) begin
                s_axi_rvalid <= 1'b0;
                s_axi_rdata <= {DATA_WIDTH{1'b0}};
            end else begin
                // Manage one by one the read request, block new read
                // until completion is not passed
                if (s_axi_rvalid == 1'b0 && s_axi_arvalid && s_axi_arready) begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rdata <= mem[s_axi_araddr];
                end else if (s_axi_rvalid) begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end

            end
        end


        assign s_axi_rid = {ID_WIDTH{1'b0}};

endmodule

`resetall
