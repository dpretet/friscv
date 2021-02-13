// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_scfifo

    #(
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8
    )(
        input  wire                  aclk,
        input  wire                  aresetn,
        input  wire                  srst,
        input  wire [DATA_WIDTH-1:0] data_in,
        input  wire                  push,
        output wire                  full,
        output wire [DATA_WIDTH-1:0] data_out,
        input  wire                  pull,
        output wire                  empty
    );

    localparam DEPTH = $clog2(ADDR_WIDTH);

    wire           wr_en;
    reg  [DEPTH:0] wrptr;
    reg  [DEPTH:0] rdptr;

    // Write Pointer Management
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            wrptr <= {(DEPTH+1){1'b0}};
        end
        else if (srst) begin
            wrptr <= {(DEPTH+1){1'b0}};
        end 
        else begin
            if (push == 1'b1 && full == 1'b0) begin
                wrptr <= wrptr + 1'b1;
            end
        end
    end

    // Read Pointer Management
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            rdptr <= {(DEPTH+1){1'b0}};
        end
        else if (srst) begin
            rdptr <= {(DEPTH+1){1'b0}};
        end 
        else begin
            if (pull == 1'b1 && empty == 1'b0) begin
                rdptr <= rdptr + 1'b1;
            end
        end
    end

    assign wr_en = push & !full;

    assign empty = (wrptr == rdptr) ? 1'b1 : 1'b0;
    assign full = ((wrptr - rdptr) == {1'b1,{DEPTH{1'b0}}}) ? 1'b1 : 1'b0;

    friscv_scfifo_ram 
    #( 
        .ADDR_WIDTH     (DEPTH+1),
        .DATA_WIDTH     (ADDR_WIDTH)
    ) 
        fifo_ram 
    (
        .aclk     (aclk    ),
        .wr_en    (wr_en   ),
        .addr_in  (wrptr   ),
        .data_in  (data_in ),
        .addr_out (rdptr   ),
        .data_out (data_out)
    );

endmodule

`resetall
