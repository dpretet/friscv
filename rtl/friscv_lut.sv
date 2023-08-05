// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

///////////////////////////////////////////////////////////////////////////////
//
// A look-up table built around a FIFO to search for token into a list
// of values. 
// Values stored in the list are stored / erased (push/pull) in order
//
///////////////////////////////////////////////////////////////////////////////

module friscv_lut

    #(
        // Number of tokens the LUT can store (power of 2 only)
        parameter NB_TOKEN = 4,
        // Token width
        parameter TOKEN_W = 8
    )(
        input  wire                    aclk,
        input  wire                    aresetn,
        input  wire                    srst,
        input  wire                    flush,
        // Token to seek in the list
        input  wire  [TOKEN_W    -1:0] seek,
        output logic                   hit,
        // Push / pull interface
        input  wire  [TOKEN_W    -1:0] token,
        input  wire                    push,
        input  wire                    pull,
        // Status flags
        output logic                   full,
        output logic                   afull,
        output logic                   empty,
        output logic                   aempty
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals declarations
    ///////////////////////////////////////////////////////////////////////////

    localparam ADDR_WIDTH = $clog2(NB_TOKEN);

    logic                      wr_en;
    logic                      rd_en;
    logic [ADDR_WIDTH      :0] wrptr;
    logic [ADDR_WIDTH      :0] rdptr;
    logic [ADDR_WIDTH      :0] ptr_diff;

    logic [NB_TOKEN*TOKEN_W-1:0] ram;
    logic [NB_TOKEN        -1:0] used;
    logic [NB_TOKEN        -1:0] hits;


    ///////////////////////////////////////////////////////////////////////////
    // Write Pointer Management
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            wrptr <= '0;
        end
        else if (srst || flush) begin
            wrptr <= '0;
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
            rdptr <= '0;
        end
        else if (srst || flush) begin
            rdptr <= '0;
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

    assign ptr_diff = wrptr - rdptr;
    assign empty = (wrptr == rdptr) ? 1'b1 : 1'b0;
    assign full = (ptr_diff == {1'b1,{ADDR_WIDTH{1'b0}}}) ? 1'b1 : 1'b0;

    assign aempty = (ptr_diff == {{ADDR_WIDTH{1'b0}}, 1'b1}) ? 1'b1 : 1'b0;
    assign afull = (ptr_diff == {1'b0,{ADDR_WIDTH{1'b1}}}) ? 1'b1 : 1'b0;

    ///////////////////////////////////////////////////////////////////////////
    // Internal RAM
    ///////////////////////////////////////////////////////////////////////////

    assign wr_en = push & !full & !flush;
    assign rd_en = pull == 1'b1 && empty == 1'b0;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ram <= '0;
            used <= '0;
        end else if (srst) begin
            ram <= '0;
            used <= '0;
        end else begin
            if (wr_en) begin
                ram[wrptr[ADDR_WIDTH-1:0]*TOKEN_W+:TOKEN_W] <= token;
                used[wrptr[ADDR_WIDTH-1:0]] <= 1'b1;
            end
            if (rd_en) begin
                ram[rdptr[ADDR_WIDTH-1:0]*TOKEN_W+:TOKEN_W] <= '0;
                used[rdptr[ADDR_WIDTH-1:0]] <= 1'b0;
            end
        end
    end

    generate
    for (genvar i = 0; i<NB_TOKEN; i++) begin
        assign hits[i] = (ram[i*TOKEN_W+:TOKEN_W] == seek) && (used[i]);
    end
    endgenerate

    assign hit = |hits;

endmodule

`resetall
