// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_mem_router

    #(
        parameter ADDRW = 16,
        parameter XLEN  = 32,
        parameter GPIO_BASE_ADDR = 0,
        parameter GPIO_BASE_SIZE = 2048,
        parameter DATA_MEM_BASE_ADDR = 2048,
        parameter DATA_MEM_BASE_SIZE = 16384
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // Master interface
        input  logic                        mst_en,
        input  logic                        mst_wr,
        input  logic [ADDRW           -1:0] mst_addr,
        input  logic [XLEN            -1:0] mst_wdata,
        input  logic [XLEN/8          -1:0] mst_strb,
        output logic [XLEN            -1:0] mst_rdata,
        output logic                        mst_ready,
        // GPIOs subsystem interface
        output logic                        gpio_en,
        output logic                        gpio_wr,
        output logic [ADDRW           -1:0] gpio_addr,
        output logic [XLEN            -1:0] gpio_wdata,
        output logic [XLEN/8          -1:0] gpio_strb,
        input  logic [XLEN            -1:0] gpio_rdata,
        input  logic                        gpio_ready,
        // data memory interface
        output logic                        data_mem_en,
        output logic                        data_mem_wr,
        output logic [ADDRW           -1:0] data_mem_addr,
        output logic [XLEN            -1:0] data_mem_wdata,
        output logic [XLEN/8          -1:0] data_mem_strb,
        input  logic [XLEN            -1:0] data_mem_rdata,
        input  logic                        data_mem_ready
    );

    // Switching logic to drive GPIO or data memory based on address targeted
    always @ (*) begin


        if (mst_addr >= GPIO_BASE_ADDR && mst_addr < (GPIO_BASE_SIZE+GPIO_BASE_SIZE)) begin

            gpio_en = mst_en;
            gpio_wr = mst_wr;
            gpio_addr = mst_addr;
            gpio_wdata = mst_wdata;
            gpio_strb = mst_strb;
            mst_rdata = gpio_rdata;
            mst_ready = gpio_ready;

            data_mem_en = 1'b0;
            data_mem_wr = 1'b0;
            data_mem_addr = {ADDRW{1'b0}};
            data_mem_wdata = {XLEN{1'b0}};
            data_mem_strb = {XLEN/8{1'b0}};

        end else if (mst_addr >= DATA_MEM_BASE_ADDR && mst_addr < (DATA_MEM_BASE_SIZE+DATA_MEM_BASE_SIZE)) begin

            gpio_en = 1'b0;
            gpio_wr = 1'b0;
            gpio_addr = {ADDRW{1'b0}};
            gpio_wdata = {XLEN{1'b0}};
            gpio_strb = {XLEN/8{1'b0}};

            data_mem_en = mst_en;
            data_mem_wr = mst_wr;
            data_mem_addr = mst_addr;
            data_mem_wdata = mst_wdata;
            data_mem_strb = mst_strb;
            mst_rdata = data_mem_rdata;
            mst_ready = data_mem_ready;

        end else begin

            gpio_en = 1'b0;
            gpio_wr = 1'b0;
            gpio_addr = {ADDRW{1'b0}};
            gpio_wdata = {XLEN{1'b0}};
            gpio_strb = {XLEN/8{1'b0}};

            data_mem_en = 1'b0;
            data_mem_wr = 1'b0;
            data_mem_addr = {ADDRW{1'b0}};
            data_mem_wdata = {XLEN{1'b0}};
            data_mem_strb = {XLEN/8{1'b0}};

            mst_rdata = {XLEN{1'b0}};
            mst_ready = 1'b1;

        end
    end


endmodule

`resetall

