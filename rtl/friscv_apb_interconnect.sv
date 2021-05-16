// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_apb_interconnect

    #(
        parameter ADDRW     = 16,
        parameter XLEN      = 32,
        parameter SLV0_ADDR = 0,
        parameter SLV0_SIZE = 8,
        parameter SLV1_ADDR = 8,
        parameter SLV1_SIZE = 4
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // APB Master
        input  logic                        mst_en,
        input  logic                        mst_wr,
        input  logic [ADDRW           -1:0] mst_addr,
        input  logic [XLEN            -1:0] mst_wdata,
        input  logic [XLEN/8          -1:0] mst_strb,
        output logic [XLEN            -1:0] mst_rdata,
        output logic                        mst_ready,
        // APB Slave 0
        output logic                        slv0_en,
        output logic                        slv0_wr,
        output logic [ADDRW           -1:0] slv0_addr,
        output logic [XLEN            -1:0] slv0_wdata,
        output logic [XLEN/8          -1:0] slv0_strb,
        input  logic [XLEN            -1:0] slv0_rdata,
        input  logic                        slv0_ready,
        // APB Slave 1
        output logic                        slv1_en,
        output logic                        slv1_wr,
        output logic [ADDRW           -1:0] slv1_addr,
        output logic [XLEN            -1:0] slv1_wdata,
        output logic [XLEN/8          -1:0] slv1_strb,
        input  logic [XLEN            -1:0] slv1_rdata,
        input  logic                        slv1_ready
    );

    localparam SLV0_RANGE = SLV0_ADDR + SLV0_SIZE;
    localparam SLV1_RANGE = SLV1_ADDR + SLV1_SIZE;


    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            slv0_en <= 1'b0;
            slv0_wr <= 1'b0;
            slv0_addr <= {ADDRW{1'b0}};
            slv0_wdata <= {XLEN{1'b0}};
            slv0_strb <= {XLEN/8{1'b0}};
            slv1_en <= 1'b0;
            slv1_wr <= 1'b0;
            slv1_addr <= {ADDRW{1'b0}};
            slv1_wdata <= {XLEN{1'b0}};
            slv1_strb <= {XLEN/8{1'b0}};
            mst_ready <= 1'b0;
            mst_rdata <= {XLEN{1'b0}};
        end else if (srst) begin
            slv0_en <= 1'b0;
            slv0_wr <= 1'b0;
            slv0_addr <= {ADDRW{1'b0}};
            slv0_wdata <= {XLEN{1'b0}};
            slv0_strb <= {XLEN/8{1'b0}};
            slv1_en <= 1'b0;
            slv1_wr <= 1'b0;
            slv1_addr <= {ADDRW{1'b0}};
            slv1_wdata <= {XLEN{1'b0}};
            slv1_strb <= {XLEN/8{1'b0}};
            mst_ready <= 1'b0;
            mst_rdata <= {XLEN{1'b0}};
        end else begin

            if (mst_en && ~mst_ready) begin

                // Slave 0 access
                if (mst_addr >= SLV0_ADDR && mst_addr < SLV0_RANGE) begin

                    slv0_addr <= mst_addr - SLV0_ADDR;
                    slv0_en <= mst_en;
                    slv0_wr <= mst_wr;
                    slv0_wdata <= mst_wdata;
                    slv0_strb <= mst_strb;
                    mst_rdata <= slv0_rdata;
                    mst_ready <= slv0_ready;

                    if (slv0_ready) begin
                        slv0_en <= 1'b0;
                    end

                // Slave 1 access
                end else if (mst_addr >= SLV1_ADDR && mst_addr < SLV1_RANGE) begin

                    slv1_addr <= mst_addr - SLV1_ADDR;
                    slv1_en <= mst_en;
                    slv1_wr <= mst_wr;
                    slv1_wdata <= mst_wdata;
                    slv1_strb <= mst_strb;
                    mst_rdata <= slv1_rdata;
                    mst_ready <= slv1_ready;

                    if (slv1_ready) begin
                        slv1_en <= 1'b0;
                    end

                // Any other address accessed will be completed, whatever
                // it targets.
                end else begin
                    mst_ready <= 1'b1;
                end

            // go back to IDLE to wait for the next access
            end else begin

                slv0_en <= 1'b0;
                slv0_wr <= 1'b0;
                slv0_addr <= {ADDRW{1'b0}};
                slv0_wdata <= {XLEN{1'b0}};
                slv0_strb <= {XLEN/8{1'b0}};

                slv1_en <= 1'b0;
                slv1_wr <= 1'b0;
                slv1_addr <= {ADDRW{1'b0}};
                slv1_wdata <= {XLEN{1'b0}};
                slv1_strb <= {XLEN/8{1'b0}};

                mst_ready <= 1'b0;
                mst_rdata <= {XLEN{1'b0}};
            end
        end

    end

endmodule

`resetall

