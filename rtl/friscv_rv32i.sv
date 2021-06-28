// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1ns / 1ps
`default_nettype none
`include "friscv_h.sv"

`define RV32I

module friscv_rv32i

    #(
        ///////////////////////////////////////////////////////////////////////////
        // Global setup
        ///////////////////////////////////////////////////////////////////////////

        // RISCV Architecture
        parameter XLEN               = 32,
        // Boot address used by the control unit
        parameter BOOT_ADDR          = 0,
        // Number of outstanding requests used by the control unit
        parameter INST_OSTDREQ_NUM   = 8,
        // CSR registers depth
        parameter CSR_DEPTH          = 12,

        ///////////////////////////////////////////////////////////////////////////
        // AXI4 / AXI4-lite interface setup
        ///////////////////////////////////////////////////////////////////////////

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W         = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W           = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W         = XLEN,

        ///////////////////////////////////////////////////////////////////////////
        // Data interface and GPIO / peripherals setup
        ///////////////////////////////////////////////////////////////////////////

        // Data address bus width
        parameter DATA_ADDRW         = 16,

        // Define the address of GPIO peripheral in APB interconnect
        parameter GPIO_SLV0_ADDR     = 0,
        parameter GPIO_SLV0_SIZE     = 8,
        parameter GPIO_SLV1_ADDR     = 8,
        parameter GPIO_SLV1_SIZE     = 16,

        // Define the memory map of GPIO and data memory
        // in the global memory space. Used to route the requests between
        // data controller and GPIOs
        parameter GPIO_BASE_ADDR     = 0,
        parameter GPIO_BASE_SIZE     = 2048,
        parameter DATA_MEM_BASE_ADDR = 2048,
        parameter DATA_MEM_BASE_SIZE = 16384,

        // UART FIFO Depth
        parameter UART_FIFO_DEPTH    = 4,

        ///////////////////////////////////////////////////////////////////////////
        // Instruction cache setup
        ///////////////////////////////////////////////////////////////////////////

        // Enable Instruction cache
        parameter ICACHE_EN          = 0,
        // Line width defining only the data payload, in bits, must an
        // integer multiple of XLEN
        parameter CACHE_LINE_W       = XLEN*4,
        // Number of lines in the cache
        parameter CACHE_DEPTH        = 512

    )(
        // clock/reset interface
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // enable signal to activate the core
        input  logic                      enable,
        // Flag asserted when reaching a EBREAK
        output logic                      ebreak,
        // instruction memory interface
        output logic                      inst_arvalid,
        input  logic                      inst_arready,
        output logic [AXI_ADDR_W    -1:0] inst_araddr,
        output logic [3             -1:0] inst_arprot,
        output logic [AXI_ID_W      -1:0] inst_arid,
        input  logic                      inst_rvalid,
        output logic                      inst_rready,
        input  logic [AXI_ID_W      -1:0] inst_rid,
        input  logic [2             -1:0] inst_rresp,
        input  logic [AXI_DATA_W    -1:0] inst_rdata,
        // data memory interface
        output logic                      mem_en,
        output logic                      mem_wr,
        output logic [DATA_ADDRW    -1:0] mem_addr,
        output logic [XLEN          -1:0] mem_wdata,
        output logic [XLEN/8        -1:0] mem_strb,
        input  logic [XLEN          -1:0] mem_rdata,
        input  logic                      mem_ready,
        // GPIO interface
        input  logic [XLEN          -1:0] gpio_in,
        output logic [XLEN          -1:0] gpio_out,
        // UART interface
        input  logic                      uart_rx,
        output logic                      uart_tx,
        output logic                      uart_rts,
        input  logic                      uart_cts
    );


    //////////////////////////////////////////////////////////////////////////
    // Parameters and signals
    //////////////////////////////////////////////////////////////////////////

    logic [5               -1:0] ctrl_rs1_addr;
    logic [XLEN            -1:0] ctrl_rs1_val;
    logic [5               -1:0] ctrl_rs2_addr;
    logic [XLEN            -1:0] ctrl_rs2_val;
    logic                        ctrl_rd_wr;
    logic [5               -1:0] ctrl_rd_addr;
    logic [XLEN            -1:0] ctrl_rd_val;

    logic [5               -1:0] alu_rs1_addr;
    logic [XLEN            -1:0] alu_rs1_val;
    logic [5               -1:0] alu_rs2_addr;
    logic [XLEN            -1:0] alu_rs2_val;
    logic                        alu_rd_wr;
    logic [5               -1:0] alu_rd_addr;
    logic [XLEN            -1:0] alu_rd_val;
    logic [XLEN/8          -1:0] alu_rd_strb;

    logic [5               -1:0] memfy_rs1_addr;
    logic [XLEN            -1:0] memfy_rs1_val;
    logic [5               -1:0] memfy_rs2_addr;
    logic [XLEN            -1:0] memfy_rs2_val;
    logic                        memfy_rd_wr;
    logic [5               -1:0] memfy_rd_addr;
    logic [XLEN            -1:0] memfy_rd_val;
    logic [XLEN/8          -1:0] memfy_rd_strb;

    logic [5               -1:0] csr_rs1_addr;
    logic [XLEN            -1:0] csr_rs1_val;
    logic                        csr_rd_wr;
    logic [5               -1:0] csr_rd_addr;
    logic [XLEN            -1:0] csr_rd_val;
    logic [XLEN/8          -1:0] csr_rd_strb;

    logic                        proc_en;
    logic [`INST_BUS_W     -1:0] proc_instbus;
    logic                        proc_ready;
    logic                        memfy_ready;
    logic                        proc_empty;
    logic [4               -1:0] proc_fenceinfo;

    logic                        csr_en;
    logic [`INST_BUS_W     -1:0] csr_instbus;
    logic                        csr_ready;

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

    logic                        inst_arvalid_s;
    logic                        inst_arready_s;
    logic [AXI_ADDR_W      -1:0] inst_araddr_s;
    logic [3               -1:0] inst_arprot_s;
    logic [AXI_ID_W        -1:0] inst_arid_s;
    logic                        inst_rvalid_s;
    logic                        inst_rready_s;
    logic [AXI_ID_W        -1:0] inst_rid_s;
    logic [2               -1:0] inst_rresp_s;
    logic [XLEN            -1:0] inst_rdata_s;

    logic                        flush_req;
    logic                        flush_ack;

    //////////////////////////////////////////////////////////////////////////
    // Module logging internal statistics of the core
    //////////////////////////////////////////////////////////////////////////

    friscv_stats
    #(
        .XLEN (XLEN)
    )
    statistic
    (
        .aclk       (aclk        ),
        .aresetn    (aresetn     ),
        .srst       (srst        ),
        .enable     (enable      ),
        .inst_en    (inst_arvalid),
        .inst_ready (inst_arready),
        .debug      (            )
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
        .csr_rs1_addr    (csr_rs1_addr   ),
        .csr_rs1_val     (csr_rs1_val    ),
        .csr_rd_wr       (csr_rd_wr      ),
        .csr_rd_addr     (csr_rd_addr    ),
        .csr_rd_val      (csr_rd_val     )
    );


    //////////////////////////////////////////////////////////////////////////
    // Central controller sequencing the operations
    //////////////////////////////////////////////////////////////////////////

    friscv_rv32i_control
    #(
        .XLEN        (XLEN),
        .AXI_ADDR_W  (AXI_ADDR_W),
        .AXI_ID_W    (AXI_ID_W),
        .AXI_DATA_W  (XLEN),
        .OSTDREQ_NUM (INST_OSTDREQ_NUM),
        .BOOT_ADDR   (BOOT_ADDR)
    )
    control
    (
        .aclk           (aclk          ),
        .aresetn        (aresetn       ),
        .srst           (srst          ),
        .ebreak         (ebreak        ),
        .flush_req      (flush_req     ),
        .flush_ack      (flush_ack     ),
        .arvalid        (inst_arvalid_s),
        .arready        (inst_arready_s),
        .araddr         (inst_araddr_s ),
        .arprot         (inst_arprot_s ),
        .arid           (inst_arid_s   ),
        .rvalid         (inst_rvalid_s ),
        .rready         (inst_rready_s ),
        .rid            (inst_rid_s    ),
        .rresp          (inst_rresp_s  ),
        .rdata          (inst_rdata_s  ),
        .proc_en        (proc_en       ),
        .proc_ready     (proc_ready    ),
        .proc_empty     (proc_empty    ),
        .proc_fenceinfo (proc_fenceinfo),
        .proc_instbus   (proc_instbus  ),
        .csr_en         (csr_en        ),
        .csr_ready      (csr_ready     ),
        .csr_instbus    (csr_instbus   ),
        .ctrl_rs1_addr  (ctrl_rs1_addr ),
        .ctrl_rs1_val   (ctrl_rs1_val  ),
        .ctrl_rs2_addr  (ctrl_rs2_addr ),
        .ctrl_rs2_val   (ctrl_rs2_val  ),
        .ctrl_rd_wr     (ctrl_rd_wr    ),
        .ctrl_rd_addr   (ctrl_rd_addr  ),
        .ctrl_rd_val    (ctrl_rd_val   )
    );


    generate
    if (ICACHE_EN) begin :  USE_ICACHE

    friscv_icache
    #(
        .XLEN         (XLEN),
        .OSTDREQ_NUM  (INST_OSTDREQ_NUM),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_DATA_W   (AXI_DATA_W),
        .CACHE_LINE_W (CACHE_LINE_W),
        .CACHE_DEPTH  (CACHE_DEPTH)
    )
    icache
    (
        .aclk              (aclk             ),
        .aresetn           (aresetn          ),
        .srst              (srst             ),
        .flush_req         (flush_req        ),
        .flush_ack         (flush_ack        ),
        .ctrl_arvalid      (inst_arvalid_s   ),
        .ctrl_arready      (inst_arready_s   ),
        .ctrl_araddr       (inst_araddr_s    ),
        .ctrl_arprot       (inst_arprot_s    ),
        .ctrl_arid         (inst_arid_s      ),
        .ctrl_rvalid       (inst_rvalid_s    ),
        .ctrl_rready       (inst_rready_s    ),
        .ctrl_rid          (inst_rid_s       ),
        .ctrl_rresp        (inst_rresp_s     ),
        .ctrl_rdata        (inst_rdata_s     ),
        .icache_arvalid    (inst_arvalid     ),
        .icache_arready    (inst_arready     ),
        .icache_araddr     (inst_araddr      ),
        .icache_arlen      (                 ),
        .icache_arsize     (                 ),
        .icache_arburst    (                 ),
        .icache_arlock     (                 ),
        .icache_arcache    (                 ),
        .icache_arprot     (                 ),
        .icache_arqos      (                 ),
        .icache_arregion   (                 ),
        .icache_arid       (inst_arid        ),
        .icache_arprot     (inst_arprot      ),
        .icache_rvalid     (inst_rvalid      ),
        .icache_rready     (inst_rready      ),
        .icache_rid        (inst_rid         ),
        .icache_rresp      (inst_rresp       ),
        .icache_rdata      (inst_rdata       ),
        .icache_rlast      (1'b1             )
    );

    end else begin : NO_ICACHE

    // Connect controller directly to top interface
    assign inst_arvalid = inst_arvalid_s;
    assign inst_arready_s = inst_arready;
    assign inst_araddr = inst_araddr_s;
    assign inst_arprot = inst_arprot_s;
    assign inst_arid = inst_arid_s;
    assign inst_rvalid_s = inst_rvalid;
    assign inst_rready = inst_rready_s;
    assign inst_rid_s = inst_rid;
    assign inst_rresp_s = inst_rresp;
    assign inst_rdata_s = inst_rdata;

    // Always assert ack if requesting cache flush to avoid deadlock
    assign flush_ack = 1'b1;

    end
    endgenerate

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

    //////////////////////////////////////////////////////////////////////////
    // Module managing the ISA CSR
    //////////////////////////////////////////////////////////////////////////

    friscv_csr
    #(
        .CSR_DEPTH (CSR_DEPTH),
        .XLEN      (XLEN)
    )
    csrs
    (
        .aclk       (aclk        ),
        .aresetn    (aresetn     ),
        .srst       (srst        ),
        .valid      (csr_en      ),
        .ready      (csr_ready   ),
        .instbus    (csr_instbus ),
        .rs1_addr   (csr_rs1_addr),
        .rs1_val    (csr_rs1_val ),
        .rd_wr_en   (csr_rd_wr   ),
        .rd_wr_addr (csr_rd_addr ),
        .rd_wr_val  (csr_rd_val  )
    );

endmodule
`resetall
