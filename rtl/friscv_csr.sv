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
        output logic                  rd_wr_en,
        output logic [5         -1:0] rd_wr_addr,
        output logic [XLEN      -1:0] rd_wr_val
    );

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        STORE
    } fsm;

    fsm cfsm;

    logic csr_wr;
    logic csr_rd;
    logic [XLEN-1:0] oldval;
    logic [XLEN-1:0] newval;
    logic [XLEN-1:0] csrs [2**CSR_DEPTH-1:0];

    logic [`FUNCT3_W -1:0] funct3_r;
    logic [`CSR_W    -1:0] csr_r;
    logic [`ZIMM_W   -1:0] zimm_r;
    logic [5         -1:0] rs1_addr_r;
    logic [XLEN      -1:0] rs1_val_r;

    `ifdef FRISCV_SIM
    initial begin
        for(int i=0; i<2**CSR_DEPTH; i=i+1)
            csrs[i] = 32'h0;
    end
    `endif

    always @ (posedge aclk) begin
        if (csr_wr) begin
            csrs[csr_r] <= newval;
        end
        if (csr_rd) begin
            oldval <= csrs[csr];
        end
    end

    assign csr_rd = (cfsm==IDLE && valid) ? 1'b1 : 1'b0;

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn==1'b0) begin
            rd_wr_en <= 1'b0;
            rd_wr_val <= {XLEN{1'b0}};
            ready <= 1'b0;
            csr_wr <= 1'b0;
            newval <= {XLEN{1'b0}};
            funct3_r <= {`FUNCT3_W{1'b0}};
            csr_r <= {`CSR_W{1'b0}};
            zimm_r <= {`ZIMM_W{1'b0}};
            rs1_addr_r <= 5'b0;
            rs1_val_r <= {XLEN{1'b0}};
            rd_wr_addr <= 5'b0;
            cfsm <= IDLE;
        end else if (srst) begin
            rd_wr_en <= 1'b0;
            rd_wr_val <= {XLEN{1'b0}};
            ready <= 1'b0;
            csr_wr <= 1'b0;
            newval <= {XLEN{1'b0}};
            funct3_r <= {`FUNCT3_W{1'b0}};
            csr_r <= {`CSR_W{1'b0}};
            zimm_r <= {`ZIMM_W{1'b0}};
            rs1_addr_r <= 5'b0;
            rs1_val_r <= {XLEN{1'b0}};
            rd_wr_addr <= 5'b0;
            cfsm <= IDLE;
        end else begin

            // Wait for a new instruction
            case(cfsm)

                default: begin

                    csr_wr <= 1'b0;
                    rd_wr_en <= 1'b0;
                    ready <= 1'b1;

                    if (valid) begin
                        ready <= 1'b0;
                        funct3_r <= funct3;
                        csr_r <= csr;
                        zimm_r <= zimm;
                        rs1_addr_r <= rs1_addr;
                        rs1_val_r <= rs1_val;
                        rd_wr_addr <= rd_addr;
                        cfsm <= COMPUTE;
                    end
                end

                // Compute the new CSR value and drive
                // the ISA register
                COMPUTE: begin

                    cfsm <= STORE;

                    // Swap RS1 and CSR
                    if (funct3_r==`CSRRW) begin
                        if (rd_wr_addr!=5'b0) begin
                            csr_wr <= 1'b1;
                            rd_wr_en <= 1'b1;
                            rd_wr_val <= oldval;
                        end
                        newval <= rs1_val_r;
                    // Save CSR in RS1 and apply a set mask with rs1
                    end else if (funct3_r==`CSRRS) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (rs1_addr_r!=5'b0) begin
                            csr_wr <= 1'b1;
                            newval <= oldval | rs1_val_r;
                        end

                    // Save CSR in RS1 then apply a clear mask fwith rs1
                    end else if (funct3_r==`CSRRC) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (rs1_addr!=5'b0) begin
                            csr_wr <= 1'b1;
                            newval <= oldval & rs1_val_r;
                        end

                    // Store CSR in RS1 then set CSR to Zimm
                    end else if (funct3_r==`CSRRWI) begin
                        if (rd_wr_addr!=5'b0) begin
                            csr_wr <= 1'b1;
                            rd_wr_en <= 1'b1;
                            rd_wr_val <= oldval;
                        end
                        newval <= {{XLEN-5{1'b0}}, zimm};

                    // Save CSR in RS1 and apply a set mask with Zimm
                    end else if (funct3_r==`CSRRSI) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (zimm_r!=5'b0) begin
                            csr_wr <= 1'b1;
                            newval <= oldval | {{XLEN-`ZIMM_W{1'b0}}, zimm_r};
                        end

                    // Save CSR in RS1 and apply a clear mask with Zimm
                    end else if (funct3_r==`CSRRCI) begin
                        rd_wr_en <= 1'b1;
                        rd_wr_val <= oldval;
                        if (zimm_r!=5'b0) begin
                            csr_wr <= 1'b1;
                            newval <= oldval & {{XLEN-`ZIMM_W{1'b0}}, zimm_r};
                        end

                    end
                end

                // Take time to store new CSR value, handles the
                // RAM behavior according the RAM technology which
                // may be write first / read first. Avoid consecutive
                // CSR instructions to fail
                STORE: begin
                    csr_wr <= 1'b0;
                    rd_wr_en <= 1'b0;
                    if (rd_wr_en==1'b0) begin
                        ready <= 1'b1;
                        cfsm <= IDLE;
                    end
                end
            endcase
        end
    end


endmodule

`resetall

