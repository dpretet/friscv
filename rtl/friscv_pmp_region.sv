// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_pmp_region

    #(
        // Region address length
        // The Sv32 page-based virtual-memory supports 34-bit physical addresses for RV32
        // The Sv39 and Sv48 page-based virtual-memory schemes support a 56-bit physical address space, 
        // so the RV64 PMP address registers impose the same limit.
        parameter RLEN = 34,
        // Registers width, 32 bits for RV32
        parameter XLEN = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = XLEN
    )(
        // CSR registers
        input  wire  [XLEN         -1:0] pmp_addr,
        input  wire  [XLEN         -1:0] pmp_cfg,
        // Region base addres and mask for NAPOT/NA4
        output logic [RLEN         -1:0] pmp_base,
        output logic [RLEN         -1:0] pmp_mask
    );

    //////////////////////////////////////////////////////////////////////////
    // Functions, parameters and variables
    //////////////////////////////////////////////////////////////////////////

    // Address matching A field encoding
    typedef enum logic[1:0] {
        OFF    = 0,
        TOR    = 1,
        NA4    = 2,
        NAPOT  = 3
    } ADDR_MATCH;


    //////////////////////////////////////////////////////////////////////////
    // Returns the last zero into the encoded address to decode a NAPOT
    // memory region
    //
    // @address: the value from a PMPADDR register
    // @returns the index of the last zero bit in the address
    //////////////////////////////////////////////////////////////////////////
    function automatic int unsigned get_last_zero(input logic [XLEN-1:0] csr_addr);
        int unsigned ix;
    begin
        ix = 32;
        for (int i=31;i>-1;i--)
            if (csr_addr[i] == 1'b0) ix = i;
        get_last_zero = ix;
    end
    endfunction


    /////////////////////////////////////////////////////////////////////////////
    // Returns size and the base address of NA4 region to check matches
    //
    // @address: the value from a PMPADDR register
    // @returns a 2*34 bits concatenation of the mask and base address
    /////////////////////////////////////////////////////////////////////////////
    function automatic [2*RLEN-1:0] get_na4(input logic [XLEN-1:0] csr_addr);
        logic [RLEN-1:0] base;
        logic [RLEN-1:0] mask;
        logic [XLEN-1:0] size;
    begin
        size = 3;
        mask = '1 << size;
        base = {csr_addr, 2'b0} & mask;
        get_na4 = {mask, base};
    end
    endfunction


    /////////////////////////////////////////////////////////////////////////////
    // Returns size and the base address of NAPOT region to check matches
    //
    // @address: the value from a PMPADDR register
    // @returns a 2*34 bits concatenation of the mask and base address
    /////////////////////////////////////////////////////////////////////////////
    function automatic [2*RLEN-1:0] get_napot(input logic [XLEN-1:0] csr_addr);
        logic [RLEN-1:0] base;
        logic [RLEN-1:0] mask;
        logic [XLEN-1:0] size;
        int unsigned last_zero;
    begin
        last_zero = get_last_zero(csr_addr);
        size = last_zero + 3;
        mask = '1 << size;
        base = {csr_addr, 2'b0} & mask;
        get_napot = {mask, base};
    end
    endfunction


    /////////////////////////////////////////////////////////////////////////////
    // Address matching process
    /////////////////////////////////////////////////////////////////////////////
    always @ (*) begin

        case (pmp_cfg[4:3])

            default: begin
                {pmp_mask, pmp_base} = {{RLEN{1'b0}}, {{(RLEN-32){1'b0}},pmp_addr<<2}};
            end

            NA4: begin
                {pmp_mask, pmp_base} = get_na4(pmp_addr);
            end

            NAPOT: begin
                {pmp_mask, pmp_base} = get_napot(pmp_addr);
            end

        endcase
    end

endmodule

`resetall
