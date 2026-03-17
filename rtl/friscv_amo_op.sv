// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_amo_op

    #(
        parameter SYNC = 0
    )(
        input  wire         aclk,
        input  wire         aresetn,
        input  wire         srst,
        input  wire  [ 4:0] opcode, // amo opcode (func5)
        input  wire  [31:0] op1,    // value read from memory
        input  wire  [31:0] op2,    // rs2
        output logic [31:0] rd,     // rd
        output logic [31:0] mem     // value to write-back in memory
    );

    // local declarations
    logic [31:0] amo_swap, amo_add, amo_xor, amo_and,
                 amo_or, amo_min , amo_max, amo_min_u,
                 amo_max_u, mem_c;

    // atomic operation
    assign amo_swap  = op2;
    assign amo_add   = op1 + op2;
    assign amo_xor   = op1 ^ op2;
    assign amo_and   = op1 & op2;
    assign amo_or    = op1 | op2;
    assign amo_min   = ($signed(op1) < $signed(op2)) ? op1 : op2;
    assign amo_max   = ($signed(op1) > $signed(op2)) ? op1 : op2;
    assign amo_min_u = (op1 < op2) ? op1 : op2;
    assign amo_max_u = (op1 > op2) ? op1 : op2;


    // select the right output
    always @ (*) begin
        case (opcode)
            default    : mem_c = '0;
            `AMOSWAP_W : mem_c = amo_swap;
            `AMOADD_W  : mem_c = amo_add;
            `AMOXOR_W  : mem_c = amo_xor;
            `AMOAND_W  : mem_c = amo_and;
            `AMOOR_W   : mem_c = amo_or;
            `AMOMIN_W  : mem_c = amo_min;
            `AMOMAX_W  : mem_c = amo_max;
            `AMOMINU_W : mem_c = amo_min_u;
            `AMOMAXU_W : mem_c = amo_max_u;
        endcase
    end


    generate
    // register the outputs
    if (SYNC) begin: SYNC_OUTPUT
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd <= '0;
            mem <= '0;
        end else if (srst) begin
            rd <= '0;
            mem <= '0;
        end else begin
            rd <= op1;
            mem <= mem_c;
        end
    end
    // output are not registred
    end else begin: ASYNC_OUTPUT
        assign rd = op1;
        assign mem = mem_c;
    end
    endgenerate

endmodule

`resetall
