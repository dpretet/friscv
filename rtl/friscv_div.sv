// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

/////////////////////////////////////////////////////////////////////////////////
//
// Integer division, explanation from: 
//   - https://www.wikihow.com/Divide-Binary-Numbers
//   - https://projectf.io/posts/division-in-verilog/
//
// AXI4-stream support, back-pressure, flag for division by zero to handle trap, 
// support signed division.
//
// TODO: Save bandwidth by avoiding moving back and forth IDLE/OP if valid is 
// already asserted when division is finished
// TODO: manage pow2 division with a simple mux
// TODO: save computation time by check the first MSB to use different than 0
//
/////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
`default_nettype none


module friscv_div

    #(
        parameter WIDTH  = 32
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // Input interface
        input  wire                       i_valid,      // AMBA-like handshake
        output logic                      i_ready,
        input  wire                       signed_div,   // 1: signed, 0: unsigned division
        input  wire  [WIDTH         -1:0] divd,         // dividend
        input  wire  [WIDTH         -1:0] divs,         // divisor
        // Output interface
        output logic                      o_valid,
        input  wire                       o_ready,
        output logic                      zero_div,     // division by zero exception
        output logic [WIDTH         -1:0] quot,         // quotient
        output logic [WIDTH         -1:0] rem           // reminder
    );


    ///////////////////////////////////////////////////////////////////////////
    // Parameters, variables and functions declaration
    ///////////////////////////////////////////////////////////////////////////

    logic [WIDTH         -1:0] _divs;                   // divisor
    logic [WIDTH         -1:0] quot_next;               // intermediate quotient
    logic [WIDTH           :0] acc, acc_next, rem_sub;  // accumulator (1 bit wider)
    logic                      computing;

    localparam                 CWIDTH = $clog2(WIDTH);
    logic [CWIDTH        -1:0] step_cnt;                   // iteration counter
    logic                      quot_sign;
    logic                      rem_sign;

    function automatic [WIDTH-1:0] inv_sign(
        input logic  [WIDTH-1:0] number
    );
        inv_sign = ~number + 1;
    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Division
    ///////////////////////////////////////////////////////////////////////////

    // assign rem = acc[WIDTH-1:0];

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            zero_div <= 1'b0;
            quot_sign <= 1'b0;
            rem_sign <= 1'b0;
            _divs <= {WIDTH{1'b0}};
            quot <= {WIDTH{1'b0}};
            rem <= {WIDTH{1'b0}};
            acc <= {WIDTH+1{1'b0}};
            i_ready <= 1'b0;
            o_valid <= 1'b0;
            computing <= 1'b0;
            step_cnt <= {CWIDTH{1'b0}};
        end else if (srst) begin
            zero_div <= 1'b0;
            quot_sign <= 1'b0;
            rem_sign <= 1'b0;
            _divs <= {WIDTH{1'b0}};
            quot <= {WIDTH{1'b0}};
            rem <= {WIDTH{1'b0}};
            acc <= {WIDTH+1{1'b0}};
            i_ready <= 1'b0;
            o_valid <= 1'b0;
            computing <= 1'b0;
            step_cnt <= {CWIDTH{1'b0}};
        end else begin

            /////////////////////////////////
            // Operating, division is ongoing
            /////////////////////////////////
            if (computing) begin

                // Division is done
                if (step_cnt==(WIDTH-1)) begin

                    o_valid <= 1'b1;
                    if (quot_sign) quot <= inv_sign(quot_next);
                    else quot <= quot_next;
                    if (rem_sign) rem <= inv_sign(acc_next[WIDTH:1]);
                    else rem <= acc_next[WIDTH:1];
                    // if slave is ready, move to the next operation from IDLE state
                    if (o_ready) begin
                        computing <= 1'b0;
                        step_cnt <= {CWIDTH{1'b0}};
                    end

                // Else continue the division
                end else begin
                    step_cnt <= step_cnt + 1;
                    acc <= acc_next;
                    quot <= quot_next;
                end

            ////////////////////////////////
            // IDLE, wait for next operation
            ////////////////////////////////
            end else if (i_valid) begin

                // Flag used to convert the quotient to negative if only
                // division is supposed to be signed and quotient or divisor is negative
                quot_sign <= signed_div & (divd[WIDTH-1] ^ divs[WIDTH-1]);
                rem_sign <= signed_div & divd[WIDTH-1];

                // Convert dividend to positive
                if (signed_div & divd[WIDTH-1]) begin
                    {acc, quot} <= {{WIDTH{1'b0}}, inv_sign(divd), 1'b0};
                end else begin
                    {acc, quot} <= {{WIDTH{1'b0}}, divd, 1'b0};
                end

                // Convert divisor to positive
                if (signed_div & divs[WIDTH-1]) _divs <= inv_sign(divs);
                else _divs <= divs;

                o_valid <= 1'b0;
                i_ready <= 1'b1;
                step_cnt <= {CWIDTH{1'b0}};

                // Complete ASAP if trying to divide by zero
                if (divs=={WIDTH{1'b0}}) begin
                    zero_div <= 1'b1;
                    o_valid <= 1'b1;
                    i_ready <= 1'b1;
                    quot <= {WIDTH{1'b1}};
                    rem <= divd;
                // Move to compute the division
                end else begin
                    zero_div <= 1'b0;
                    o_valid <= 1'b0;
                    i_ready <= 1'b0;
                    computing <= 1'b1;
                end

            end else begin
                i_ready <= 1'b1;
                o_valid <= 1'b0;
            end
        end
    end

    always @ (*) begin
        rem_sub = acc - _divs;
        if (acc >= {1'b0,_divs}) begin
            {acc_next, quot_next} = {rem_sub[WIDTH-1:0], quot, 1'b1};
        end else begin
            {acc_next, quot_next} = {acc, quot} << 1;
        end
    end

endmodule

`resetall
