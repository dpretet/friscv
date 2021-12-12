// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_gpios

    #(
        parameter ADDRW     = 16,
        parameter XLEN      = 32
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // APB slave interface
        input  logic                        slv_en,
        input  logic                        slv_wr,
        input  logic [ADDRW           -1:0] slv_addr,
        input  logic [XLEN            -1:0] slv_wdata,
        input  logic [XLEN/8          -1:0] slv_strb,
        output logic [XLEN            -1:0] slv_rdata,
        output logic                        slv_ready,
        // GPIO interface
        input  logic [XLEN            -1:0] gpio_in,
        output logic [XLEN            -1:0] gpio_out
    );

    // input pins
    logic [XLEN-1:0] register0;
    // output pins 
    logic [XLEN-1:0] register1;


    assign gpio_out = register0;
    assign register1 = gpio_in;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            register0 <= {XLEN{1'b0}};
            slv_rdata <= {XLEN{1'b0}};
            slv_ready <= 1'b0;
        end else if (srst) begin
            register0 <= {XLEN{1'b0}};
            slv_rdata <= {XLEN{1'b0}};
            slv_ready <= 1'b0;
        end else begin
            // READY assertion
            if (slv_en && ~slv_ready) begin
                slv_ready <= 1'b1;
            end else begin
                slv_ready <= 1'b0;
            end
            // Register operation
            if (slv_en) begin
                if (slv_addr=={ADDRW{1'b0}}) begin
                    if (slv_wr) begin
                        if (slv_strb[0]) register0[ 0+:8] <= slv_wdata[ 0+:8];
                        if (slv_strb[1]) register0[ 8+:8] <= slv_wdata[ 8+:8];
                        if (slv_strb[2]) register0[16+:8] <= slv_wdata[16+:8];
                        if (slv_strb[3]) register0[24+:8] <= slv_wdata[24+:8];
                    end else begin
                        slv_rdata <= register0;
                    end
                end else if (slv_addr=={{ADDRW-1{1'b0}}, 1'b1}) begin
                    slv_rdata <= register1;
                end
            end
        end
    end

endmodule

`resetall

