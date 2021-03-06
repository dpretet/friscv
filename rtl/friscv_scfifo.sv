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
        input  logic                  flush,
        input  logic [DATA_WIDTH-1:0] data_in,
        input  logic                  push,
        output logic                  full,
        output logic [DATA_WIDTH-1:0] data_out,
        input  logic                  pull,
        output logic                  empty
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals declarations
    ///////////////////////////////////////////////////////////////////////////

    logic                wr_en;
    logic [ADDR_WIDTH:0] wrptr;
    logic [ADDR_WIDTH:0] rdptr;


    ///////////////////////////////////////////////////////////////////////////
    // Write Pointer Management
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            wrptr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if (srst || flush) begin
            wrptr <= {(ADDR_WIDTH+1){1'b0}};
        end 
        else begin
            if (push == 1'b1 && full == 1'b0) begin
                wrptr <= wrptr + 1'b1;
            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Read Pointer Management
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            rdptr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if (srst || flush) begin
            rdptr <= {(ADDR_WIDTH+1){1'b0}};
        end 
        else begin
            if (pull == 1'b1 && empty == 1'b0) begin
                rdptr <= rdptr + 1'b1;
            end
        end
    end
    

    ///////////////////////////////////////////////////////////////////////////
    // Full and empty flags
    ///////////////////////////////////////////////////////////////////////////
 
    assign empty = (wrptr == rdptr) ? 1'b1 : 1'b0;
    assign full = ((wrptr - rdptr) == {1'b1,{ADDR_WIDTH{1'b0}}}) ? 1'b1 : 1'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Internal RAM
    ///////////////////////////////////////////////////////////////////////////

    assign wr_en = push & !full;

    friscv_scfifo_ram 
    #( 
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .FFD_EN     (0)
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
