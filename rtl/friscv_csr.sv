// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_csr
    
    #(
        parameter CSR_DEPTH = 12,
        parameter XLEN = 32
    )(
        input  logic                  aclk,
        input  logic                  aresetn,
        input  logic                  srst,
        input  logic                  valid,
        output logic                  ready,
        input  logic [`FUNCT3_W -1:0] funct3,
        input  logic [`CSR_W    -1:0] csr,
        input  logic [`ZIMM_W   -1:0] zimm,
        input  logic [5         -1:0] rs1_addr,
        input  logic [XLEN      -1:0] rs1_val,
        input  logic [5         -1:0] rd_addr,
        output logic [XLEN      -1:0] rd_val
    );

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE, 
        STORE
    } fsm;

    fsm cfsm;

    logic wren;
    logic rden;
    logic [XLEN-1:0] oldval;
    logic [XLEN-1:0] newval;
    logic [XLEN-1:0] csrs [2**CSR_DEPTH-1:0];

    `ifdef FRISCV_SIM
    initial begin
        for(int i=0; i<2**CSR_DEPTH; i=i+1)
            csrs[i] = 32'h0;
    end
    `endif

    always @ (posedge aclk) begin
        if (wren) begin
            csrs[csr] <= newval;
        end
        if (rden) begin
            oldval <= csrs[csr];
        end
    end

    assign rden = (cfsm==IDLE && valid) ? 1'b1 : 1'b0;

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn==1'b0) begin
            rd_val <= {XLEN{1'b0}};
            ready <= 1'b0;
            wren <= 1'b0;
            newval <= {XLEN{1'b0}};
            cfsm <= IDLE;
        end else if (srst) begin
            rd_val <= {XLEN{1'b0}};
            ready <= 1'b0;
            wren <= 1'b0;
            newval <= {XLEN{1'b0}};
            cfsm <= IDLE;
        end else begin
            case(cfsm)

                // Wait for a new instruction
                default: begin
                    if (valid) begin
                        ready <= 1'b0;
                        cfsm <= COMPUTE;
                    end else begin
                        ready <= 1'b1;
                    end
                end

                // Compute the new CSR value and drive
                // the ISA register
                COMPUTE: begin

                    cfsm <= STORE;

                    // Swap RS1 and CSR
                    if (funct3==`CSRRW) begin
                        if (rd_addr!=5'b0) begin 
                            wren <= 1'b1;
                            rd_val <= oldval;
                        end
                        newval <= rs1_val;
                    // Save CSR and apply a set mask
                    end else if (funct3==`CSRRS) begin
                        rd_val <= oldval;
                        if (rs1_addr!=5'b0) begin 
                            wren <= 1'b1;
                            newval <= oldval | rs1_val;
                        end
                    
                    // Save CSR then apply a set mask
                    end else if (funct3==`CSRRC) begin
                        rd_val <= oldval;
                        if (rs1_addr!=5'b0) begin 
                            wren <= 1'b1;
                            newval <= oldval & rs1_val;
                        end

                    // Save CSR then apply a clear mask
                    end else if (funct3==`CSRRWI) begin
                        if (rd_addr!=5'b0) begin 
                            wren <= 1'b1;
                            rd_val <= oldval;
                        end
                        newval <= {{XLEN-5{1'b0}}, zimm};

                    end else if (funct3==`CSRRSI) begin
                        rd_val <= oldval;
                        if (zimm!=5'b0) begin 
                            wren <= 1'b1;
                            newval <= oldval | {{XLEN-`ZIMM_W{1'b0}}, zimm};
                        end

                    end else if (funct3==`CSRRCI) begin
                        rd_val <= oldval;
                        if (zimm!=5'b0) begin 
                            wren <= 1'b1;
                            newval <= oldval & {{XLEN-`ZIMM_W{1'b0}}, zimm};
                        end
                        
                    end
                end

                // Take time to store new CSR value, handles the 
                // RAM behavior according the RAM technology which
                // may be write first / read first. Avoid consecutive 
                // CSR instructions to fail
                STORE: begin
                    wren <= 1'b0;
                    ready <= 1'b1;
                    cfsm <= IDLE;
                end
            endcase
        end
    end


endmodule

`resetall

