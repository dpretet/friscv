// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1ns / 1ps
`default_nettype none
`include "friscv_h.sv"

`define RV32I

module friscv_rv32i

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

    logic [5     -1:0] ctrl_rs1_addr;
    logic [XLEN  -1:0] ctrl_rs1_val;
    logic [5     -1:0] ctrl_rs2_addr;
    logic [XLEN  -1:0] ctrl_rs2_val;
    logic              ctrl_rd_wr;
    logic [5     -1:0] ctrl_rd_addr;
    logic [XLEN  -1:0] ctrl_rd_val;

    logic [5     -1:0] alu_rs1_addr;
    logic [XLEN  -1:0] alu_rs1_val;
    logic [5     -1:0] alu_rs2_addr;
    logic [XLEN  -1:0] alu_rs2_val;
    logic              alu_rd_wr;
    logic [5     -1:0] alu_rd_addr;
    logic [XLEN  -1:0] alu_rd_val;
    logic [XLEN/8-1:0] alu_rd_strb;

    logic [5     -1:0] memfy_rs1_addr;
    logic [XLEN  -1:0] memfy_rs1_val;
    logic [5     -1:0] memfy_rs2_addr;
    logic [XLEN  -1:0] memfy_rs2_val;
    logic              memfy_rd_wr;
    logic [5     -1:0] memfy_rd_addr;
    logic [XLEN  -1:0] memfy_rd_val;
    logic [XLEN/8-1:0] memfy_rd_strb;

    logic [XLEN  -1:0] x0;
    logic [XLEN  -1:0] x1;
    logic [XLEN  -1:0] x2;
    logic [XLEN  -1:0] x3;
    logic [XLEN  -1:0] x4;
    logic [XLEN  -1:0] x5;
    logic [XLEN  -1:0] x6;
    logic [XLEN  -1:0] x7;
    logic [XLEN  -1:0] x8;
    logic [XLEN  -1:0] x9;
    logic [XLEN  -1:0] x10;
    logic [XLEN  -1:0] x11;
    logic [XLEN  -1:0] x12;
    logic [XLEN  -1:0] x13;
    logic [XLEN  -1:0] x14;
    logic [XLEN  -1:0] x15;
    logic [XLEN  -1:0] x16;
    logic [XLEN  -1:0] x17;
    logic [XLEN  -1:0] x18;
    logic [XLEN  -1:0] x19;
    logic [XLEN  -1:0] x20;
    logic [XLEN  -1:0] x21;
    logic [XLEN  -1:0] x22;
    logic [XLEN  -1:0] x23;
    logic [XLEN  -1:0] x24;
    logic [XLEN  -1:0] x25;
    logic [XLEN  -1:0] x26;
    logic [XLEN  -1:0] x27;
    logic [XLEN  -1:0] x28;
    logic [XLEN  -1:0] x29;
    logic [XLEN  -1:0] x30;
    logic [XLEN  -1:0] x31;

    logic                        proc_en;
    logic [`INST_BUS_W     -1:0] proc_instbus;
    logic                        proc_ready;
    logic                        memfy_ready;
    logic                        proc_empty;
    logic [4               -1:0] proc_fenceinfo;

    logic                        mst_en;
    logic                        mst_wr;
    logic [DATA_ADDRW      -1:0] mst_addr;
    logic [XLEN            -1:0] mst_wdata;
    logic [XLEN/8          -1:0] mst_strb;
    logic [XLEN            -1:0] mst_rdata;
    logic                        mst_ready;

    logic                        gpio_en;
    logic                        gpio_wr;
    logic [DATA_ADDRW      -1:0] gpio_addr;
    logic [XLEN            -1:0] gpio_wdata;
    logic [XLEN/8          -1:0] gpio_strb;
    logic [XLEN            -1:0] gpio_rdata;
    logic                        gpio_ready;

    //////////////////////////////////////////////////////////////////////////
    // Module logging internal statistics of the core
    //////////////////////////////////////////////////////////////////////////
    friscv_stats
    #(
        .XLEN (XLEN)
    )
    statistic
    (
        .aclk       (aclk      ),
        .aresetn    (aresetn   ),
        .srst       (srst      ),
        .enable     (enable    ),
        .inst_en    (inst_en   ),
        .inst_ready (inst_ready),
        .debug      (          )
    );


    //////////////////////////////////////////////////////////////////////////
    // ISA Registers x0 -> x31
    //////////////////////////////////////////////////////////////////////////
    friscv_registers
    #(
        .XLEN (XLEN)
    )
    isa_registers
    (
        .aclk            (aclk           ),
        .aresetn         (aresetn        ),
        .srst            (srst           ),
        .ctrl_rs1_addr   (ctrl_rs1_addr  ),
        .ctrl_rs1_val    (ctrl_rs1_val   ),
        .ctrl_rs2_addr   (ctrl_rs2_addr  ),
        .ctrl_rs2_val    (ctrl_rs2_val   ),
        .ctrl_rd_wr      (ctrl_rd_wr     ),
        .ctrl_rd_addr    (ctrl_rd_addr   ),
        .ctrl_rd_val     (ctrl_rd_val    ),
        .alu_rs1_addr    (alu_rs1_addr   ),
        .alu_rs1_val     (alu_rs1_val    ),
        .alu_rs2_addr    (alu_rs2_addr   ),
        .alu_rs2_val     (alu_rs2_val    ),
        .alu_rd_wr       (alu_rd_wr      ),
        .alu_rd_addr     (alu_rd_addr    ),
        .alu_rd_val      (alu_rd_val     ),
        .alu_rd_strb     (alu_rd_strb    ),
        .memfy_rs1_addr  (memfy_rs1_addr ),
        .memfy_rs1_val   (memfy_rs1_val  ),
        .memfy_rs2_addr  (memfy_rs2_addr ),
        .memfy_rs2_val   (memfy_rs2_val  ),
        .memfy_rd_wr     (memfy_rd_wr    ),
        .memfy_rd_addr   (memfy_rd_addr  ),
        .memfy_rd_val    (memfy_rd_val   ),
        .memfy_rd_strb   (memfy_rd_strb  ),
        .x0              (x0             ),
        .x1              (x1             ),
        .x2              (x2             ),
        .x3              (x3             ),
        .x4              (x4             ),
        .x5              (x5             ),
        .x6              (x6             ),
        .x7              (x7             ),
        .x8              (x8             ),
        .x9              (x9             ),
        .x10             (x10            ),
        .x11             (x11            ),
        .x12             (x12            ),
        .x13             (x13            ),
        .x14             (x14            ),
        .x15             (x15            ),
        .x16             (x16            ),
        .x17             (x17            ),
        .x18             (x18            ),
        .x19             (x19            ),
        .x20             (x20            ),
        .x21             (x21            ),
        .x22             (x22            ),
        .x23             (x23            ),
        .x24             (x24            ),
        .x25             (x25            ),
        .x26             (x26            ),
        .x27             (x27            ),
        .x28             (x28            ),
        .x29             (x29            ),
        .x30             (x30            ),
        .x31             (x31            )
    );


    //////////////////////////////////////////////////////////////////////////
    // Central controller sequencing the operations
    //////////////////////////////////////////////////////////////////////////
    friscv_rv32i_control
    #(
        .ADDRW     (INST_ADDRW),
        .BOOT_ADDR (BOOT_ADDR),
        .XLEN      (XLEN)
    )
    control_unit
    (
        .aclk           (aclk          ),
        .aresetn        (aresetn       ),
        .srst           (srst          ),
        .ebreak         (ebreak        ),
        .inst_en        (inst_en       ),
        .inst_addr      (inst_addr     ),
        .inst_rdata     (inst_rdata    ),
        .inst_ready     (inst_ready    ),
        .proc_en        (proc_en       ),
        .proc_ready     (proc_ready    ),
        .proc_empty     (proc_empty    ),
        .proc_fenceinfo (proc_fenceinfo),
        .proc_instbus   (proc_instbus  ),
        .ctrl_rs1_addr  (ctrl_rs1_addr ),
        .ctrl_rs1_val   (ctrl_rs1_val  ),
        .ctrl_rs2_addr  (ctrl_rs2_addr ),
        .ctrl_rs2_val   (ctrl_rs2_val  ),
        .ctrl_rd_wr     (ctrl_rd_wr    ),
        .ctrl_rd_addr   (ctrl_rd_addr  ),
        .ctrl_rd_val    (ctrl_rd_val   )
    );


    //////////////////////////////////////////////////////////////////////////
    // All ISA enxtensions supported: standard arithmetic / memory, ...
    //////////////////////////////////////////////////////////////////////////
    friscv_rv32i_processing
    #(
        .ADDRW              (DATA_ADDRW),
        .XLEN               (XLEN),
        .GPIO_BASE_ADDR     (GPIO_BASE_ADDR),
        .GPIO_BASE_SIZE     (GPIO_BASE_SIZE),
        .DATA_MEM_BASE_ADDR (DATA_MEM_BASE_ADDR),
        .DATA_MEM_BASE_SIZE (DATA_MEM_BASE_SIZE)
    )
    processing
    (
        .aclk           (aclk          ),
        .aresetn        (aresetn       ),
        .srst           (srst          ),
        .proc_en        (proc_en       ),
        .proc_ready     (proc_ready    ),
        .proc_empty     (proc_empty    ),
        .proc_fenceinfo (proc_fenceinfo),
        .proc_instbus   (proc_instbus  ),
        .alu_rs1_addr   (alu_rs1_addr  ),
        .alu_rs1_val    (alu_rs1_val   ),
        .alu_rs2_addr   (alu_rs2_addr  ),
        .alu_rs2_val    (alu_rs2_val   ),
        .alu_rd_wr      (alu_rd_wr     ),
        .alu_rd_addr    (alu_rd_addr   ),
        .alu_rd_val     (alu_rd_val    ),
        .alu_rd_strb    (alu_rd_strb   ),
        .memfy_rs1_addr (memfy_rs1_addr),
        .memfy_rs1_val  (memfy_rs1_val ),
        .memfy_rs2_addr (memfy_rs2_addr),
        .memfy_rs2_val  (memfy_rs2_val ),
        .memfy_rd_wr    (memfy_rd_wr   ),
        .memfy_rd_addr  (memfy_rd_addr ),
        .memfy_rd_val   (memfy_rd_val  ),
        .memfy_rd_strb  (memfy_rd_strb ),
        .mem_en         (mst_en        ),
        .mem_wr         (mst_wr        ),
        .mem_addr       (mst_addr      ),
        .mem_wdata      (mst_wdata     ),
        .mem_strb       (mst_strb      ),
        .mem_rdata      (mst_rdata     ),
        .mem_ready      (mst_ready     )
    );


    //////////////////////////////////////////////////////////////////////////
    // Switching logic to dispatch the IO and data memory access
    //////////////////////////////////////////////////////////////////////////
    friscv_mem_router
    #(
        .ADDRW              (DATA_ADDRW),
        .XLEN               (XLEN),
        .GPIO_BASE_ADDR     (GPIO_BASE_ADDR),
        .GPIO_BASE_SIZE     (GPIO_BASE_SIZE),
        .DATA_MEM_BASE_ADDR (DATA_MEM_BASE_ADDR),
        .DATA_MEM_BASE_SIZE (DATA_MEM_BASE_SIZE)
    )
    mem_router
    (
        .aclk           (aclk          ),
        .aresetn        (aresetn       ),
        .srst           (srst          ),
        .mst_en         (mst_en        ),
        .mst_wr         (mst_wr        ),
        .mst_addr       (mst_addr      ),
        .mst_wdata      (mst_wdata     ),
        .mst_strb       (mst_strb      ),
        .mst_rdata      (mst_rdata     ),
        .mst_ready      (mst_ready     ),
        .gpio_en        (gpio_en       ),
        .gpio_wr        (gpio_wr       ),
        .gpio_addr      (gpio_addr     ),
        .gpio_wdata     (gpio_wdata    ),
        .gpio_strb      (gpio_strb     ),
        .gpio_rdata     (gpio_rdata    ),
        .gpio_ready     (gpio_ready    ),
        .data_mem_en    (mem_en        ),
        .data_mem_wr    (mem_wr        ),
        .data_mem_addr  (mem_addr      ),
        .data_mem_wdata (mem_wdata     ),
        .data_mem_strb  (mem_strb      ),
        .data_mem_rdata (mem_rdata     ),
        .data_mem_ready (mem_ready     )
    );


    //////////////////////////////////////////////////////////////////////////
    // All the IO peripherals: GPIO, UART, ...
    //////////////////////////////////////////////////////////////////////////
    friscv_io_interfaces
    #(
        .ADDRW           (DATA_ADDRW),
        .XLEN            (XLEN),
        .SLV0_ADDR       (GPIO_SLV0_ADDR),
        .SLV0_SIZE       (GPIO_SLV0_SIZE),
        .SLV1_ADDR       (GPIO_SLV1_ADDR),
        .SLV1_SIZE       (GPIO_SLV1_SIZE),
        .UART_FIFO_DEPTH (UART_FIFO_DEPTH)
    )
    ios
    (
        .aclk      (aclk      ),
        .aresetn   (aresetn   ),
        .srst      (srst      ),
        .mst_en    (mst_en    ),
        .mst_wr    (gpio_wr   ),
        .mst_addr  (gpio_addr ),
        .mst_wdata (gpio_wdata),
        .mst_strb  (gpio_strb ),
        .mst_rdata (gpio_rdata),
        .mst_ready (gpio_ready),
        .gpio_in   (gpio_in   ),
        .gpio_out  (gpio_out  ),
        .uart_rx   (uart_rx   ),
        .uart_tx   (uart_tx   ),
        .uart_rts  (uart_rts  ),
        .uart_cts  (uart_cts  )
    );

    endmodule

    `resetall
