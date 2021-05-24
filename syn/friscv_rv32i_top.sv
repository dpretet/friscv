// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1ns / 1ps
`default_nettype none

module friscv_rv32i_top

    #(
        // 32 bits architecture
        parameter XLEN               = 32,
        // Address buses width
        parameter INST_ADDRW         = 16,
        parameter DATA_ADDRW         = 16,
        // Boot address used by the control unit
        parameter BOOT_ADDR          = 0,
        // Define the address of GPIO peripheral in APB interconnect
        parameter GPIO_SLV0_ADDR     = 0,
        parameter GPIO_SLV0_SIZE     = 8,
        parameter GPIO_SLV1_ADDR     = 8,
        parameter GPIO_SLV1_SIZE     = 16,
        // Define the memory map of GPIO and data memory
        // in the global memory space
        parameter GPIO_BASE_ADDR     = 0,
        parameter GPIO_BASE_SIZE     = 2048,
        parameter DATA_MEM_BASE_ADDR = 2048,
        parameter DATA_MEM_BASE_SIZE = 16384,
        // UART FIFO Depth
        parameter UART_FIFO_DEPTH = 4
    )(
        // clock/reset interface
        input  logic                  aclk,
        input  logic                  aresetn,
        input  logic                  srst,
        // enable signal to activate the core
        input  logic                  enable,
        // Flag asserted when reaching a EBREAK
        output logic                  ebreak,
        // instruction memory interface
        output logic                  inst_en,
        output logic [INST_ADDRW-1:0] inst_addr,
        input  logic [XLEN      -1:0] inst_rdata,
        input  logic                  inst_ready,
        // data memory interface
        output logic                  mem_en,
        output logic                  mem_wr,
        output logic [DATA_ADDRW-1:0] mem_addr,
        output logic [XLEN      -1:0] mem_wdata,
        output logic [XLEN/8    -1:0] mem_strb,
        input  logic [XLEN      -1:0] mem_rdata,
        input  logic                  mem_ready,
        // GPIO interface
        input  logic [XLEN      -1:0] gpio_in,
        output logic [XLEN      -1:0] gpio_out,
        // UART interface
        input  logic                  uart_rx,
        output logic                  uart_tx,
        output logic                  uart_rts,
        input  logic                  uart_cts
    );


    friscv_rv32i
    #(
    .XLEN               (XLEN),
    .INST_ADDRW         (INST_ADDRW),
    .DATA_ADDRW         (DATA_ADDRW),
    .BOOT_ADDR          (BOOT_ADDR),
    .GPIO_SLV0_ADDR     (GPIO_SLV0_ADDR),
    .GPIO_SLV0_SIZE     (GPIO_SLV0_SIZE),
    .GPIO_SLV1_ADDR     (GPIO_SLV1_ADDR),
    .GPIO_SLV1_SIZE     (GPIO_SLV1_SIZE),
    .GPIO_BASE_ADDR     (GPIO_BASE_ADDR),
    .GPIO_BASE_SIZE     (GPIO_BASE_SIZE),
    .DATA_MEM_BASE_ADDR (DATA_MEM_BASE_ADDR),
    .DATA_MEM_BASE_SIZE (DATA_MEM_BASE_SIZE),
    .UART_FIFO_DEPTH    (UART_FIFO_DEPTH)
    )
    dut
    (
    .aclk       (aclk      ),
    .aresetn    (aresetn   ),
    .srst       (1'b0      ),
    .enable     (enable    ),
    .ebreak     (ebreak    ),
    .inst_en    (inst_en   ),
    .inst_addr  (inst_addr ),
    .inst_rdata (inst_rdata),
    .inst_ready (inst_ready),
    .mem_en     (mem_en    ),
    .mem_wr     (mem_wr    ),
    .mem_addr   (mem_addr  ),
    .mem_wdata  (mem_wdata ),
    .mem_strb   (mem_strb  ),
    .mem_rdata  (mem_rdata ),
    .mem_ready  (mem_ready ),
    .gpio_in    (gpio_in   ),
    .gpio_out   (gpio_out  ),
    .uart_rx    (uart_rx   ),
    .uart_tx    (uart_tx   ),
    .uart_rts   (uart_rts  ),
    .uart_cts   (uart_cts  )
    );

endmodule

`resetall

