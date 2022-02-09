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
        parameter SLV1_SIZE = 4,
        parameter SLV2_ADDR = 8,
        parameter SLV2_SIZE = 4
    )(
        // clock & reset 
        input  wire                         aclk, 
        input  wire                         aresetn, 
        input  wire                         srst,
        // APB Master
        input  wire                         slv_en,
        input  wire                         slv_wr,
        input  wire  [ADDRW           -1:0] slv_addr,
        input  wire  [XLEN            -1:0] slv_wdata,
        input  wire  [XLEN/8          -1:0] slv_strb,
        output logic [XLEN            -1:0] slv_rdata,
        output logic                        slv_ready,
        // APB Slave 0
        output logic                        mst0_en,
        output logic                        mst0_wr,
        output logic [ADDRW           -1:0] mst0_addr,
        output logic [XLEN            -1:0] mst0_wdata,
        output logic [XLEN/8          -1:0] mst0_strb,
        input  wire  [XLEN            -1:0] mst0_rdata,
        input  wire                         mst0_ready,
        // APB Slave 1
        output logic                        mst1_en,
        output logic                        mst1_wr,
        output logic [ADDRW           -1:0] mst1_addr,
        output logic [XLEN            -1:0] mst1_wdata,
        output logic [XLEN/8          -1:0] mst1_strb,
        input  wire  [XLEN            -1:0] mst1_rdata,
        input  wire                         mst1_ready,
        // APB Slave 2
        output logic                        mst2_en,
        output logic                        mst2_wr,
        output logic [ADDRW           -1:0] mst2_addr,
        output logic [XLEN            -1:0] mst2_wdata,
        output logic [XLEN/8          -1:0] mst2_strb,
        input  wire  [XLEN            -1:0] mst2_rdata,
        input  wire                         mst2_ready
    );


    localparam SLV0_RANGE = SLV0_ADDR + SLV0_SIZE;
    localparam SLV1_RANGE = SLV1_ADDR + SLV1_SIZE;
    localparam SLV2_RANGE = SLV2_ADDR + SLV2_SIZE;


    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            mst0_en <= 1'b0;
            mst0_wr <= 1'b0;
            mst0_addr <= {ADDRW{1'b0}};
            mst0_wdata <= {XLEN{1'b0}};
            mst0_strb <= {XLEN/8{1'b0}};
            mst1_en <= 1'b0;
            mst1_wr <= 1'b0;
            mst1_addr <= {ADDRW{1'b0}};
            mst1_wdata <= {XLEN{1'b0}};
            mst1_strb <= {XLEN/8{1'b0}};
            mst2_en <= 1'b0;
            mst2_wr <= 1'b0;
            mst2_addr <= {ADDRW{1'b0}};
            mst2_wdata <= {XLEN{1'b0}};
            mst2_strb <= {XLEN/8{1'b0}};
            slv_ready <= 1'b0;
            slv_rdata <= {XLEN{1'b0}};
        end else if (srst) begin
            mst0_en <= 1'b0;
            mst0_wr <= 1'b0;
            mst0_addr <= {ADDRW{1'b0}};
            mst0_wdata <= {XLEN{1'b0}};
            mst0_strb <= {XLEN/8{1'b0}};
            mst1_en <= 1'b0;
            mst1_wr <= 1'b0;
            mst1_addr <= {ADDRW{1'b0}};
            mst1_wdata <= {XLEN{1'b0}};
            mst1_strb <= {XLEN/8{1'b0}};
            mst2_en <= 1'b0;
            mst2_wr <= 1'b0;
            mst2_addr <= {ADDRW{1'b0}};
            mst2_wdata <= {XLEN{1'b0}};
            mst2_strb <= {XLEN/8{1'b0}};
            slv_ready <= 1'b0;
            slv_rdata <= {XLEN{1'b0}};
        end else begin

            if (slv_en && !slv_ready) begin

                // Slave 0 access
                if (slv_addr >= SLV0_ADDR && slv_addr < SLV0_RANGE) begin

                    mst0_addr <= slv_addr - SLV0_ADDR;
                    mst0_en <= slv_en;
                    mst0_wr <= slv_wr;
                    mst0_wdata <= slv_wdata;
                    mst0_strb <= slv_strb;
                    slv_rdata <= mst0_rdata;
                    slv_ready <= mst0_ready;

                    if (mst0_ready) begin
                        mst0_en <= 1'b0;
                    end

                // Slave 1 access
                end else if (slv_addr >= SLV1_ADDR && slv_addr < SLV1_RANGE) begin

                    mst1_addr <= slv_addr - SLV1_ADDR;
                    mst1_en <= slv_en;
                    mst1_wr <= slv_wr;
                    mst1_wdata <= slv_wdata;
                    mst1_strb <= slv_strb;
                    slv_rdata <= mst1_rdata;
                    slv_ready <= mst1_ready;

                    if (mst1_ready) begin
                        mst1_en <= 1'b0;
                    end

                // Slave 1 access
                end else if (slv_addr >= SLV2_ADDR && slv_addr < SLV2_RANGE) begin

                    mst2_addr <= slv_addr - SLV2_ADDR;
                    mst2_en <= slv_en;
                    mst2_wr <= slv_wr;
                    mst2_wdata <= slv_wdata;
                    mst2_strb <= slv_strb;
                    slv_rdata <= mst2_rdata;
                    slv_ready <= mst2_ready;

                    if (mst2_ready) begin
                        mst2_en <= 1'b0;
                    end


                // Any other address accessed will be completed, whatever
                // it targets.
                end else begin
                    slv_ready <= 1'b1;
                end

            // Go back to IDLE to wait for the next access
            end else begin

                mst0_en <= 1'b0;
                mst0_wr <= 1'b0;
                mst0_addr <= {ADDRW{1'b0}};
                mst0_wdata <= {XLEN{1'b0}};
                mst0_strb <= {XLEN/8{1'b0}};

                mst1_en <= 1'b0;
                mst1_wr <= 1'b0;
                mst1_addr <= {ADDRW{1'b0}};
                mst1_wdata <= {XLEN{1'b0}};
                mst1_strb <= {XLEN/8{1'b0}};

                mst2_en <= 2'b0;
                mst2_wr <= 2'b0;
                mst2_addr <= {ADDRW{1'b0}};
                mst2_wdata <= {XLEN{1'b0}};
                mst2_strb <= {XLEN/8{1'b0}};

                slv_ready <= 1'b0;
                slv_rdata <= {XLEN{1'b0}};
            end
        end

    end

endmodule

`resetall

