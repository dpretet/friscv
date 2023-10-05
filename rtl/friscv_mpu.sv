// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_mpu

    #(
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // Registers width, 32 bits for RV32i
        parameter XLEN = 32,
        // PMP / PMA supported
        parameter MPU_SUPPORT = 0,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = ILEN
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // instruction memory interface
        input  wire [AXI_ADDR_W    -1:0] imem_araddr,
        output logic                     imem_allow,
        // data memory interface
        input  wire [AXI_ADDR_W    -1:0] dmem_araddr,
        output logic                     dmem_allow,
        // CSR shared bus
        input  wire [`CSR_SB_W     -1:0] csr_sb
    );

    //////////////////////////////////////////////////////////////////////////
    // Returns the last zero into the encoded address to decode a NAPOT
    // memory region
    //
    // @address: the value from a PMPADDR register
    // @returns the index of the last zero bit in the address
    //////////////////////////////////////////////////////////////////////////
    function automatic int unsigned get_last_zero(input logic [XLEN-1:0] addr);
        int unsigned ix;
    begin
        ix = 31;
        for (int i=31;i>-1;i--)
            if (addr[i] == 1'b0) ix = i;
        get_last_zero = ix;
    end
    endfunction

    //////////////////////////////////////////////////////////////////////////
    // Returns size and the base address of NAPOT region to check matches
    //
    // @address: the value from a PMPADDR register
    // @ returns a 34 + 32 bits concatenation of the size and base address
    //////////////////////////////////////////////////////////////////////////
    function automatic [2*XLEN+1:0] get_napot_attr(input logic [XLEN-1:0] addr);
        logic [XLEN+1:0] base;
        logic [XLEN+1:0] mask;
        int unsigned size;
        int unsigned last_zero;
    begin
        last_zero = get_last_zero(addr);
        size = 2 ** (last_zero + 3);
        mask = '1 << size;
        base = {addr, 2'b0} & mask;

        get_napot_attr = {size,base};
    end
    endfunction

    generate if (MPU_SUPPORT==0) begin: NO_MPU

    assign imem_allow = 1'b1;
    assign dmem_allow = 1'b1;

    end else begin

    end
    endgenerate

endmodule

`resetall
