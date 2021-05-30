// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_scfifo

    #(
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8
    )(
        input  logic                  aclk,
        input  logic                  aresetn,
        input  logic                  srst,
        input  logic [DATA_WIDTH-1:0] data_in,
        input  logic                  push,
        output logic                  full,
        output logic [DATA_WIDTH-1:0] data_out,
        input  logic                  pull,
        output logic                  empty
    );

    logic                wr_en;
    logic [ADDR_WIDTH:0] wrptr;
    logic [ADDR_WIDTH:0] rdptr;
    logic                empty_w;
    logic                empty_r;

    // Write Pointer Management
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            wrptr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if (srst) begin
            wrptr <= {(ADDR_WIDTH+1){1'b0}};
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
            rdptr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if (srst) begin
            rdptr <= {(ADDR_WIDTH+1){1'b0}};
        end 
        else begin
            if (pull == 1'b1 && empty_w == 1'b0) begin
                rdptr <= rdptr + 1'b1;
            end
        end
    end
    
    assign wr_en = push & !full;

    assign empty_w = (wrptr == rdptr) ? 1'b1 : 1'b0;
    assign full = ((wrptr - rdptr) == {1'b1,{ADDR_WIDTH{1'b0}}}) ? 1'b1 : 1'b0;

    // manages the empty flag, asserted once read reached last word and 
    // empty has been asserted. Else the last word doesn't output
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            empty_r <= 1'b1;
        end else if (srst == 1'b1) begin
            empty_r <= 1'b1;
        end else begin
            if (~empty_w) begin
                empty_r <= 1'b0;
            end else if (empty_w && pull) begin
                empty_r <= 1'b1;
            end
        end
    end

    assign empty = empty_w;
    // assign empty = empty_r & empty_w;

    friscv_scfifo_ram 
    #( 
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH)
    ) 
        fifo_ram 
    (
        .aclk     (aclk                 ),
        .wr_en    (wr_en                ),
        .addr_in  (wrptr[ADDR_WIDTH-1:0]),
        .data_in  (data_in              ),
        .addr_out (rdptr[ADDR_WIDTH-1:0]),
        .data_out (data_out             )
    );

endmodule

`resetall
