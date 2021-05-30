// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_io_interfaces

    #(
        parameter ADDRW           = 16,
        parameter XLEN            = 32,
        parameter SLV0_ADDR       = 0,
        parameter SLV0_SIZE       = 8,
        parameter SLV1_ADDR       = 8,
        parameter SLV1_SIZE       = 16,
        parameter UART_FIFO_DEPTH = 4
    )(
        // clock & reset
        input  logic               aclk,
        input  logic               aresetn,
        input  logic               srst,
        // APB Master
        input  logic               mst_en,
        input  logic               mst_wr,
        input  logic [ADDRW  -1:0] mst_addr,
        input  logic [XLEN   -1:0] mst_wdata,
        input  logic [XLEN/8 -1:0] mst_strb,
        output logic [XLEN   -1:0] mst_rdata,
        output logic               mst_ready,
        // GPIO interface
        input  logic [XLEN   -1:0] gpio_in,
        output logic [XLEN   -1:0] gpio_out,
        // UART interface
        input  logic               uart_rx,
        output logic               uart_tx,
        output logic               uart_rts,
        input  logic               uart_cts
    );

    logic              slv0_en;
    logic              slv0_wr;
    logic [ADDRW -1:0] slv0_addr;
    logic [XLEN  -1:0] slv0_wdata;
    logic [XLEN/8-1:0] slv0_strb;
    logic [XLEN  -1:0] slv0_rdata;
    logic              slv0_ready;
    logic              slv1_en;
    logic              slv1_wr;
    logic [ADDRW -1:0] slv1_addr;
    logic [XLEN  -1:0] slv1_wdata;
    logic [XLEN/8-1:0] slv1_strb;
    logic [XLEN  -1:0] slv1_rdata;
    logic              slv1_ready;

    friscv_apb_interconnect
    #(
        .ADDRW     (ADDRW    ),
        .XLEN      (XLEN     ),
        .SLV0_ADDR (SLV0_ADDR),
        .SLV0_SIZE (SLV0_SIZE),
        .SLV1_ADDR (SLV1_ADDR),
        .SLV1_SIZE (SLV1_SIZE)
    )
    apb_interconnect
    (
        .aclk       (aclk      ),
        .aresetn    (aresetn   ),
        .srst       (srst      ),
        .mst_en     (mst_en    ),
        .mst_wr     (mst_wr    ),
        .mst_addr   (mst_addr  ),
        .mst_wdata  (mst_wdata ),
        .mst_strb   (mst_strb  ),
        .mst_rdata  (mst_rdata ),
        .mst_ready  (mst_ready ),
        .slv0_en    (slv0_en   ),
        .slv0_wr    (slv0_wr   ),
        .slv0_addr  (slv0_addr ),
        .slv0_wdata (slv0_wdata),
        .slv0_strb  (slv0_strb ),
        .slv0_rdata (slv0_rdata),
        .slv0_ready (slv0_ready),
        .slv1_en    (slv1_en   ),
        .slv1_wr    (slv1_wr   ),
        .slv1_addr  (slv1_addr ),
        .slv1_wdata (slv1_wdata),
        .slv1_strb  (slv1_strb ),
        .slv1_rdata (slv1_rdata),
        .slv1_ready (slv1_ready)
    );


    friscv_gpios
    #(
        .ADDRW (ADDRW),
        .XLEN  (XLEN )
    )
    gpios
    (
        .aclk      (aclk      ),
        .aresetn   (aresetn   ),
        .srst      (srst      ),
        .mst_en    (slv0_en   ),
        .mst_wr    (slv0_wr   ),
        .mst_addr  (slv0_addr ),
        .mst_wdata (slv0_wdata),
        .mst_strb  (slv0_strb ),
        .mst_rdata (slv0_rdata),
        .mst_ready (slv0_ready),
        .gpio_in   (gpio_in   ),
        .gpio_out  (gpio_out  )
    );

    friscv_uart
    #(
        .ADDRW           (ADDRW),
        .XLEN            (XLEN ),
        .RXTX_FIFO_DEPTH (UART_FIFO_DEPTH)
    )
    uart
    (
        .aclk      (aclk      ),
        .aresetn   (aresetn   ),
        .srst      (srst      ),
        .mst_en    (slv1_en   ),
        .mst_wr    (slv1_wr   ),
        .mst_addr  (slv1_addr ),
        .mst_wdata (slv1_wdata),
        .mst_strb  (slv1_strb ),
        .mst_rdata (slv1_rdata),
        .mst_ready (slv1_ready),
        .uart_rx   (uart_rx   ),
        .uart_tx   (uart_tx   ),
        .uart_rts  (uart_rts  ),
        .uart_cts  (uart_cts  )
    );

    endmodule

    `resetall

