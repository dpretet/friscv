// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`default_nettype none
`timescale 1 ns / 100 ps

`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"
`include "../../rtl/friscv_debug_h.sv"

module friscv_testbench(
`ifdef VERILATOR
    // Interface to UART to communicate with the processor
    `ifdef INTERACTIVE
    input  wire                     slv_en,
    input  wire                     slv_wr,
    input  wire  [8           -1:0] slv_addr,
    input  wire  [XLEN        -1:0] slv_wdata,
    input  wire  [XLEN/8      -1:0] slv_strb,
    output logic [XLEN        -1:0] slv_rdata,
    output logic                    slv_ready,
    `endif
    // clock & reset
    input  wire                     aclk,
    input  wire                     aresetn,
    input  wire                     srst,
    // testbench status
    output logic [64          -1:0] pc,
    output logic                    error_status_reg
`endif
);

    `SVUT_SETUP

    `ifndef FRISCV_SIM
    `define FRISCV_SIM 1
    `endif

    // Maximum cycle of a simulation run, after that break it
    `ifndef TIMEOUT
    `define TIMEOUT 10000
    `endif

    // Minimum program counter value a test needs to reach, in bytes
    `ifndef MIN_PC
    `define MIN_PC 65904
    `endif

    // Instruction RAM boot address
    `ifndef BOOT_ADDR
    `define BOOT_ADDR 0
    `endif

    // Instruction/data cache enable
    `ifndef CACHE_EN
    `define CACHE_EN 1
    `endif

    // Cache block width in bits
    `ifndef CACHE_BLOCK_W
    `define CACHE_BLOCK_W 128
    `endif

    // Architecture selection: 32 or 64 bits
    `ifndef XLEN
    `define XLEN 32
    `endif

    // Testcase name to print before execution
    `ifndef TCNAME
    `define TCNAME "program"
    `endif

    // Top level selection: 0="CORE", 1="PLATFORM"
    `ifndef TB_CHOICE
    `define TB_CHOICE 0
    `endif

    `ifndef USER_MODE
    `define USER_MODE 0
    `endif

    parameter TB_CHOICE = (`TB_CHOICE==0) ? "CORE" : "PLATFORM";

    // Instruction length
    parameter ILEN = 32;
    // 32 bits architecture
    parameter XLEN = `XLEN;
    // RV32E architecture, limits integer registers to 16, else 32
    parameter RV32E = 0;
    // Boot address used by the control unit
    parameter BOOT_ADDR = `BOOT_ADDR;
    // Number of outstanding requests used by the control unit and icache
    parameter INST_OSTDREQ_NUM  = 8;
    // Number of outstanding requests used by the LOAD/STORE unit and dcache
    parameter DATA_OSTDREQ_NUM  = 32;
    // MHART ID CSR register
    parameter HART_ID = 0;

    // Floating-point extension support
    parameter F_EXTENSION = 0;
    // Multiply/Divide extension support
    parameter M_EXTENSION = 1;
    // Support hypervisor mode
    parameter HYPERVISOR_MODE = 0;
    // Support supervisor mode
    parameter SUPERVISOR_MODE = 0;
    // Support user mode
    parameter USER_MODE = `USER_MODE;
    // Insert a pipeline on instruction bus coming from the controller
    parameter PROCESSING_BUS_PIPELINE = 1;

    // Address buses width
    parameter AXI_ADDR_W = XLEN;
    // AXI ID width, setup by default to 8 and unused
    parameter AXI_ID_W = 8;
    // AXI4 data width
    parameter AXI_DATA_W = `CACHE_BLOCK_W;
    // AXI4 instruction bus width
    parameter AXI_IMEM_W = `CACHE_BLOCK_W;
    // AXI4 data bus width
    parameter AXI_DMEM_W = `CACHE_BLOCK_W;
    // ID used by instruction and data buses
    parameter AXI_IMEM_MASK = 'h80;
    parameter AXI_DMEM_MASK = 'h40;

    // Enable Instruction & data caches
    parameter CACHE_EN = `CACHE_EN;

    // Enable cache block prefetch
    parameter ICACHE_PREFETCH_EN = 1;
    // Block width defining only the data payload, in bits, must an
    // integer multiple of XLEN
    parameter ICACHE_BLOCK_W = `CACHE_BLOCK_W;
    // Number of blocks in the cache
    parameter ICACHE_DEPTH = 512;

    // Enable cache block prefetch
    parameter DCACHE_PREFETCH_EN = 1;
    // Block width defining only the data payload, in bits, must an
    // integer multiple of XLEN
    parameter DCACHE_BLOCK_W = `CACHE_BLOCK_W;
    // Number of blocks in the cache
    parameter DCACHE_DEPTH = 512;

    // Timeout used in the testbench to break the simulation
    parameter TIMEOUT = `TIMEOUT;
    // Minimum program counter value a test needs to reach
    parameter MIN_PC = `MIN_PC;

    `ifdef RAM_MODE_PERF
    parameter RAM_MODE = 1;
    `else
    parameter RAM_MODE = 0;
    `endif

`ifndef VERILATOR
    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic [XLEN          -1:0] pc;
    logic                      error_status_reg;
`endif
    logic                      tc_error_flag;
    logic [XLEN*32       -1:0] dbg_regs;
    logic [8             -1:0] status;
    logic                      ext_irq;
    logic                      sw_irq;
    logic                      timer_irq;
    logic                      rtc;
    logic                      imem_awvalid;
    logic                      imem_awready;
    logic [AXI_ADDR_W    -1:0] imem_awaddr;
    logic [3             -1:0] imem_awprot;
    logic [AXI_ID_W      -1:0] imem_awid;
    logic                      imem_wvalid;
    logic                      imem_wready;
    logic [AXI_IMEM_W    -1:0] imem_wdata;
    logic [AXI_IMEM_W/8  -1:0] imem_wstrb;
    logic                      imem_bvalid;
    logic                      imem_bready;
    logic [AXI_ID_W      -1:0] imem_bid;
    logic [2             -1:0] imem_bresp;
    logic                      imem_arvalid;
    logic                      imem_arready;
    logic [AXI_ADDR_W    -1:0] imem_araddr;
    logic [3             -1:0] imem_arprot;
    logic [AXI_ID_W      -1:0] imem_arid;
    logic                      imem_rvalid;
    logic                      imem_rready;
    logic [AXI_ID_W      -1:0] imem_rid;
    logic [2             -1:0] imem_rresp;
    logic [AXI_IMEM_W    -1:0] imem_rdata;
    logic                      dmem_awvalid;
    logic                      dmem_awready;
    logic [AXI_ADDR_W    -1:0] dmem_awaddr;
    logic [3             -1:0] dmem_awprot;
    logic [AXI_ID_W      -1:0] dmem_awid;
    logic                      dmem_wvalid;
    logic                      dmem_wready;
    logic [AXI_DMEM_W    -1:0] dmem_wdata;
    logic [AXI_DMEM_W/8  -1:0] dmem_wstrb;
    logic                      dmem_bvalid;
    logic                      dmem_bready;
    logic [AXI_ID_W      -1:0] dmem_bid;
    logic [2             -1:0] dmem_bresp;
    logic                      dmem_arvalid;
    logic                      dmem_arready;
    logic [AXI_ADDR_W    -1:0] dmem_araddr;
    logic [3             -1:0] dmem_arprot;
    logic [AXI_ID_W      -1:0] dmem_arid;
    logic                      dmem_rvalid;
    logic                      dmem_rready;
    logic [AXI_ID_W      -1:0] dmem_rid;
    logic [2             -1:0] dmem_rresp;
    logic [AXI_DMEM_W    -1:0] dmem_rdata;

    logic                      mem_awvalid;
    logic                      mem_awready;
    logic [AXI_ADDR_W    -1:0] mem_awaddr;
    logic [3             -1:0] mem_awprot;
    logic [AXI_ID_W      -1:0] mem_awid;
    logic                      mem_wvalid;
    logic                      mem_wready;
    logic [AXI_DATA_W    -1:0] mem_wdata;
    logic [AXI_DATA_W/8  -1:0] mem_wstrb;
    logic                      mem_bvalid;
    logic                      mem_bready;
    logic [AXI_ID_W      -1:0] mem_bid;
    logic [2             -1:0] mem_bresp;
    logic                      mem_arvalid;
    logic                      mem_arready;
    logic [AXI_ADDR_W    -1:0] mem_araddr;
    logic [3             -1:0] mem_arprot;
    logic [AXI_ID_W      -1:0] mem_arid;
    logic                      mem_rvalid;
    logic                      mem_rready;
    logic [AXI_ID_W      -1:0] mem_rid;
    logic [2             -1:0] mem_rresp;
    logic [AXI_DATA_W    -1:0] mem_rdata;

    logic [XLEN          -1:0] gpio_in;
    logic [XLEN          -1:0] gpio_out;
    logic                      uart_rx;
    logic                      uart_tx;
    logic                      uart_rts;
    logic                      uart_cts;
    string                     stop_msg;
    integer                    timer;
    string                     tcname;


    // iCache write channels driven to 0 while unused
    assign imem_awvalid = 1'b0;
    assign imem_wvalid = 1'b0;
    assign imem_bready = 1'b1;

    initial ext_irq = 1'b0;

    `ifdef GEN_EIRQ
        generate
        if (`GEN_EIRQ>0) begin
            always @ (posedge aclk or negedge aresetn) begin
                integer cnt;
                if (!aresetn) begin
                    ext_irq <= 1'b0;
                    cnt <= 0;
                end else if (srst) begin
                    ext_irq <= 1'b0;
                    cnt <= 0;
                end else begin
                    if (cnt == 100) begin
                        cnt <= 0;
                        ext_irq <= 1'b1;
                    end else begin
                        cnt <= cnt + 1;
                        ext_irq <= 1'b0;
                    end
                end
            end
        end
        endgenerate
    `endif

    // Run the testbench by using only the CPU core
    generate

    if (TB_CHOICE=="CORE") begin

        assign timer_irq = 1'b0;
        assign sw_irq = 1'b0;

        friscv_rv32i_core
        #(
            .ILEN                       (ILEN),
            .XLEN                       (XLEN),
            .BOOT_ADDR                  (BOOT_ADDR),
            .INST_OSTDREQ_NUM           (INST_OSTDREQ_NUM),
            .DATA_OSTDREQ_NUM           (DATA_OSTDREQ_NUM),
            .HART_ID                    (HART_ID),
            .RV32E                      (RV32E),
            .M_EXTENSION                (M_EXTENSION),
            .F_EXTENSION                (F_EXTENSION),
            .HYPERVISOR_MODE            (HYPERVISOR_MODE),
            .SUPERVISOR_MODE            (SUPERVISOR_MODE),
            .USER_MODE                  (USER_MODE),
            .PROCESSING_BUS_PIPELINE    (PROCESSING_BUS_PIPELINE),
            .AXI_ADDR_W                 (AXI_ADDR_W),
            .AXI_ID_W                   (AXI_ID_W),
            .AXI_IMEM_W                 (AXI_IMEM_W),
            .AXI_DMEM_W                 (AXI_DMEM_W),
            .AXI_IMEM_MASK              (AXI_IMEM_MASK),
            .AXI_DMEM_MASK              (AXI_DMEM_MASK),
            .CACHE_EN                   (CACHE_EN),
            .ICACHE_BLOCK_W             (ICACHE_BLOCK_W),
            .ICACHE_PREFETCH_EN         (ICACHE_PREFETCH_EN),
            .ICACHE_DEPTH               (ICACHE_DEPTH),
            .DCACHE_BLOCK_W             (DCACHE_BLOCK_W),
            .DCACHE_PREFETCH_EN         (DCACHE_PREFETCH_EN),
            .DCACHE_DEPTH               (DCACHE_DEPTH)
        )
        dut
        (
            .aclk         (aclk),
            .aresetn      (aresetn),
            .srst         (srst),
            .timer_irq    (timer_irq),
            .ext_irq      (ext_irq),
            .sw_irq       (sw_irq),
            .status       (status),
            .dbg_regs     (dbg_regs),
            .imem_arvalid (imem_arvalid),
            .imem_arready (imem_arready),
            .imem_araddr  (imem_araddr),
            .imem_arprot  (imem_arprot),
            .imem_arid    (imem_arid),
            .imem_rvalid  (imem_rvalid),
            .imem_rready  (imem_rready),
            .imem_rid     (imem_rid),
            .imem_rresp   (imem_rresp),
            .imem_rdata   (imem_rdata),
            .dmem_awvalid (dmem_awvalid),
            .dmem_awready (dmem_awready),
            .dmem_awaddr  (dmem_awaddr),
            .dmem_awprot  (dmem_awprot),
            .dmem_awid    (dmem_awid),
            .dmem_wvalid  (dmem_wvalid),
            .dmem_wready  (dmem_wready),
            .dmem_wdata   (dmem_wdata),
            .dmem_wstrb   (dmem_wstrb),
            .dmem_bvalid  (dmem_bvalid),
            .dmem_bready  (dmem_bready),
            .dmem_bid     (dmem_bid),
            .dmem_bresp   (dmem_bresp),
            .dmem_arvalid (dmem_arvalid),
            .dmem_arready (dmem_arready),
            .dmem_araddr  (dmem_araddr),
            .dmem_arprot  (dmem_arprot),
            .dmem_arid    (dmem_arid),
            .dmem_rvalid  (dmem_rvalid),
            .dmem_rready  (dmem_rready),
            .dmem_rid     (dmem_rid),
            .dmem_rresp   (dmem_rresp),
            .dmem_rdata   (dmem_rdata)
        );


        axi4l_ram
        #(
            `ifdef RAM_MODE_PERF
                .MODE ("performance"),
            `else
                .MODE ("compliance"),
            `endif
            .INIT             ("test.v"),
            .AXI_ADDR_W       (AXI_ADDR_W),
            .AXI_ID_W         (AXI_ID_W),
            .AXI1_DATA_W      (AXI_IMEM_W),
            .AXI2_DATA_W      (AXI_DMEM_W),
            .OSTDREQ_NUM      (INST_OSTDREQ_NUM)
        )
        axi4l_ram
        (
            .aclk       (aclk        ),
            .aresetn    (aresetn     ),
            .srst       (srst        ),
            .p1_awvalid (imem_awvalid),
            .p1_awready (imem_awready),
            .p1_awaddr  (imem_awaddr ),
            .p1_awprot  (imem_awprot ),
            .p1_awid    (imem_awid   ),
            .p1_wvalid  (imem_wvalid ),
            .p1_wready  (imem_wready ),
            .p1_wdata   (imem_wdata  ),
            .p1_wstrb   (imem_wstrb  ),
            .p1_bid     (imem_bid    ),
            .p1_bresp   (imem_bresp  ),
            .p1_bvalid  (imem_bvalid ),
            .p1_bready  (imem_bready ),
            .p1_arvalid (imem_arvalid),
            .p1_arready (imem_arready),
            .p1_araddr  (imem_araddr ),
            .p1_arprot  (imem_arprot ),
            .p1_arid    (imem_arid   ),
            .p1_rvalid  (imem_rvalid ),
            .p1_rready  (imem_rready ),
            .p1_rid     (imem_rid    ),
            .p1_rresp   (imem_rresp  ),
            .p1_rdata   (imem_rdata  ),
            .p2_awvalid (dmem_awvalid),
            .p2_awready (dmem_awready),
            .p2_awaddr  (dmem_awaddr ),
            .p2_awprot  (dmem_awprot ),
            .p2_awid    (dmem_awid   ),
            .p2_wvalid  (dmem_wvalid ),
            .p2_wready  (dmem_wready ),
            .p2_wdata   (dmem_wdata  ),
            .p2_wstrb   (dmem_wstrb  ),
            .p2_bid     (dmem_bid    ),
            .p2_bresp   (dmem_bresp  ),
            .p2_bvalid  (dmem_bvalid ),
            .p2_bready  (dmem_bready ),
            .p2_arvalid (dmem_arvalid),
            .p2_arready (dmem_arready),
            .p2_araddr  (dmem_araddr ),
            .p2_arprot  (dmem_arprot ),
            .p2_arid    (dmem_arid   ),
            .p2_rvalid  (dmem_rvalid ),
            .p2_rready  (dmem_rready ),
            .p2_rid     (dmem_rid    ),
            .p2_rresp   (dmem_rresp  ),
            .p2_rdata   (dmem_rdata  )
        );

    end else if (TB_CHOICE=="PLATFORM") begin

        assign timer_irq = 1'b0;
        assign sw_irq = 1'b0;
        assign rtc = aclk;

        // Can't use interactive mode with Verilator
        `ifndef VERILATOR

        assign uart_rx = 1'b0;
        assign uart_cts = 1'b0;

        `else

        `ifdef INTERACTIVE

        friscv_uart
        #(
        .ADDRW           (8),
        .XLEN            (XLEN),
        .RXTX_FIFO_DEPTH (128),
        .CLK_DIVIDER     (4)
        )
        uartlink
        (
        .aclk      (aclk),
        .aresetn   (aresetn),
        .srst      (srst),
        .slv_en    (slv_en),
        .slv_wr    (slv_wr),
        .slv_addr  (slv_addr),
        .slv_wdata (slv_wdata),
        .slv_strb  (slv_strb),
        .slv_rdata (slv_rdata),
        .slv_ready (slv_ready),
        .uart_rx   (uart_tx),
        .uart_tx   (uart_rx),
        .uart_rts  (uart_cts),
        .uart_cts  (uart_rts)
        );

        `else
        assign uart_rx = 1'b0;
        assign uart_cts = 1'b0;
        `endif
        `endif

        friscv_rv32i_platform
        #(
            .ILEN                       (ILEN),
            .XLEN                       (XLEN),
            .BOOT_ADDR                  (BOOT_ADDR),
            .INST_OSTDREQ_NUM           (INST_OSTDREQ_NUM),
            .DATA_OSTDREQ_NUM           (DATA_OSTDREQ_NUM),
            .HART_ID                    (HART_ID),
            .RV32E                      (RV32E),
            .M_EXTENSION                (M_EXTENSION),
            .F_EXTENSION                (F_EXTENSION),
            .HYPERVISOR_MODE            (HYPERVISOR_MODE),
            .SUPERVISOR_MODE            (SUPERVISOR_MODE),
            .USER_MODE                  (USER_MODE),
            .PROCESSING_BUS_PIPELINE    (PROCESSING_BUS_PIPELINE),
            .AXI_ADDR_W                 (AXI_ADDR_W),
            .AXI_ID_W                   (AXI_ID_W),
            .AXI_DATA_W                 (AXI_DATA_W),
            .AXI_IMEM_MASK              (AXI_IMEM_MASK),
            .AXI_DMEM_MASK              (AXI_DMEM_MASK),
            .CACHE_EN                   (CACHE_EN),
            .ICACHE_PREFETCH_EN         (ICACHE_PREFETCH_EN),
            .ICACHE_BLOCK_W             (ICACHE_BLOCK_W),
            .ICACHE_DEPTH               (ICACHE_DEPTH),
            .DCACHE_BLOCK_W             (DCACHE_BLOCK_W),
            .DCACHE_PREFETCH_EN         (DCACHE_PREFETCH_EN),
            .DCACHE_DEPTH               (DCACHE_DEPTH)
        )
        dut
        (
            .aclk        (aclk),
            .aresetn     (aresetn),
            .srst        (srst),
            .rtc         (rtc),
            .ext_irq     (ext_irq),
            .status      (status),
            .dbg_regs    (dbg_regs),
            .mem_awvalid (mem_awvalid),
            .mem_awready (mem_awready),
            .mem_awaddr  (mem_awaddr),
            .mem_awprot  (mem_awprot),
            .mem_awid    (mem_awid),
            .mem_wvalid  (mem_wvalid),
            .mem_wready  (mem_wready),
            .mem_wdata   (mem_wdata),
            .mem_wstrb   (mem_wstrb),
            .mem_bvalid  (mem_bvalid),
            .mem_bready  (mem_bready),
            .mem_bid     (mem_bid),
            .mem_bresp   (mem_bresp),
            .mem_arvalid (mem_arvalid),
            .mem_arready (mem_arready),
            .mem_araddr  (mem_araddr),
            .mem_arprot  (mem_arprot),
            .mem_arid    (mem_arid),
            .mem_rvalid  (mem_rvalid),
            .mem_rready  (mem_rready),
            .mem_rid     (mem_rid),
            .mem_rresp   (mem_rresp),
            .mem_rdata   (mem_rdata),
            .gpio_in     (gpio_in),
            .gpio_out    (gpio_out),
            .uart_rx     (uart_rx),
            .uart_tx     (uart_tx),
            .uart_rts    (uart_rts),
            .uart_cts    (uart_cts)
        );

        axi4l_ram
        #(
            `ifdef RAM_MODE_PERF
                .MODE ("performance"),
            `else
                .MODE ("compliance"),
            `endif
            .INIT             ("test.v"),
            .AXI_ADDR_W       (AXI_ADDR_W),
            .AXI_ID_W         (AXI_ID_W),
            .AXI1_DATA_W      (AXI_DATA_W),
            .AXI2_DATA_W      (AXI_DATA_W),
            .OSTDREQ_NUM      (INST_OSTDREQ_NUM)
        )
        axi4l_ram
        (
            .aclk       (aclk       ),
            .aresetn    (aresetn    ),
            .srst       (srst       ),
            .p1_awvalid (mem_awvalid),
            .p1_awready (mem_awready),
            .p1_awaddr  (mem_awaddr ),
            .p1_awprot  (mem_awprot ),
            .p1_awid    (mem_awid   ),
            .p1_wvalid  (mem_wvalid ),
            .p1_wready  (mem_wready ),
            .p1_wdata   (mem_wdata  ),
            .p1_wstrb   (mem_wstrb  ),
            .p1_bid     (mem_bid    ),
            .p1_bresp   (mem_bresp  ),
            .p1_bvalid  (mem_bvalid ),
            .p1_bready  (mem_bready ),
            .p1_arvalid (mem_arvalid),
            .p1_arready (mem_arready),
            .p1_araddr  (mem_araddr ),
            .p1_arprot  (mem_arprot ),
            .p1_arid    (mem_arid   ),
            .p1_rvalid  (mem_rvalid ),
            .p1_rready  (mem_rready ),
            .p1_rid     (mem_rid    ),
            .p1_rresp   (mem_rresp  ),
            .p1_rdata   (mem_rdata  ),
            .p2_awvalid (1'b0),
            .p2_awready (),
            .p2_awaddr  ({AXI_ADDR_W{1'b0}}),
            .p2_awprot  (3'h0),
            .p2_awid    ({AXI_ID_W{1'b0}}),
            .p2_wvalid  (1'b0),
            .p2_wready  (),
            .p2_wdata   ({AXI_DATA_W{1'b0}}),
            .p2_wstrb   ({AXI_DATA_W/8{1'b0}}),
            .p2_bid     (),
            .p2_bresp   (),
            .p2_bvalid  (),
            .p2_bready  (1'h0),
            .p2_arvalid (1'b0),
            .p2_arready (),
            .p2_araddr  ({AXI_ADDR_W{1'b0}}),
            .p2_arprot  (3'h0),
            .p2_arid    ({AXI_ID_W{1'b0}}),
            .p2_rvalid  (),
            .p2_rready  (1'h0),
            .p2_rid     (),
            .p2_rresp   (),
            .p2_rdata   ()
        );
    end
    endgenerate


    `ifdef NO_VCD
    initial begin
        `INFO("No VCD trace will be created");
    end
    `else
    // Dump VCD, for both Verilator and Icarus
    initial begin
        `INFO("Tracing to friscv_testbench.vcd");
        $dumpfile("friscv_testbench.vcd");
        $dumpvars(0, friscv_testbench);
        `INFO("Model running...");
    end
    `endif


    // Time format for $time / $realtime printing
    `ifndef VERILATOR
    initial $timeformat(-9, 1, "ns", 8);
    `else
    initial $timeformat(-12, 1, "ps", 8);
    `endif


    // Boot address, passed from bash flow
    initial begin
        string msg;
        $sformat(msg, "Boot address: 0x%x", `BOOT_ADDR);
        `INFO(msg);
    end


    // Task checking the testcase results and prints its status
    task check_test(input logic [63:0] testcase_start_addr);

        // Check program hasn't been aborted to early
        $sformat(stop_msg, "PC=0x%0x", pc);
        `INFO(stop_msg);
        `ASSERT((pc>testcase_start_addr), "Program counter stopped too early");
        if (pc<testcase_start_addr) tc_error_flag = 1'b1;

        // Detect errors with X31
        $sformat(stop_msg, "X31=0x%0x", error_status_reg);
        `INFO(stop_msg);
        `ifdef ERROR_STATUS_X31
        `ASSERT((error_status_reg==0), "X31 != 0");
        `endif

        if (status[0]) `INFO("Halt on ECALL");
        if (status[1]) `INFO("Halt on EBREAK");
        if (status[2]) `INFO("Halt on MRET");
        if (status[3]) `INFO("Halt on trap");
        if (status[4]) `INFO("Halt on WFI");
        // Timeout occured
        if (TIMEOUT>0 && timer>=TIMEOUT) begin
            tc_error_flag = 1'b1;
            `ERROR("Halt on timeout");
        end

    endtask

    assign pc = dbg_regs[`PC*XLEN+:XLEN];

    `ifdef ERROR_STATUS_X31
        if (`ERROR_STATUS_X31)
            assign error_status_reg = (dbg_regs[`X31*XLEN+:XLEN] > 0) ? 1'b1 : 1'b0;
        else
            assign error_status_reg = 1'b0;
    `else
        assign error_status_reg = 1'b0;
    `endif

    task print_isa_regs;
    begin
        $display("pc:       %x\tx16/a6:   %x", dbg_regs[ 0*XLEN+:XLEN], dbg_regs[16*XLEN+:XLEN]);
        $display("x1/ra:    %x\tx17/a7:   %x", dbg_regs[ 1*XLEN+:XLEN], dbg_regs[17*XLEN+:XLEN]);
        $display("x2/sp:    %x\tx18/s2:   %x", dbg_regs[ 2*XLEN+:XLEN], dbg_regs[18*XLEN+:XLEN]);
        $display("x3/gp:    %x\tx19/s3:   %x", dbg_regs[ 3*XLEN+:XLEN], dbg_regs[19*XLEN+:XLEN]);
        $display("x4/tp:    %x\tx20/s4:   %x", dbg_regs[ 4*XLEN+:XLEN], dbg_regs[20*XLEN+:XLEN]);
        $display("x5/t0:    %x\tx21/s5:   %x", dbg_regs[ 5*XLEN+:XLEN], dbg_regs[21*XLEN+:XLEN]);
        $display("x6/t1:    %x\tx22/s6:   %x", dbg_regs[ 6*XLEN+:XLEN], dbg_regs[22*XLEN+:XLEN]);
        $display("x7/t2:    %x\tx23/s7:   %x", dbg_regs[ 7*XLEN+:XLEN], dbg_regs[23*XLEN+:XLEN]);
        $display("x8/s0/fp: %x\tx24/s8:   %x", dbg_regs[ 8*XLEN+:XLEN], dbg_regs[24*XLEN+:XLEN]);
        $display("x9/s1:    %x\tx25/s9:   %x", dbg_regs[ 9*XLEN+:XLEN], dbg_regs[25*XLEN+:XLEN]);
        $display("x10/a0:   %x\tx26/s10:  %x", dbg_regs[10*XLEN+:XLEN], dbg_regs[26*XLEN+:XLEN]);
        $display("x11/a1:   %x\tx27/s11:  %x", dbg_regs[11*XLEN+:XLEN], dbg_regs[27*XLEN+:XLEN]);
        $display("x12/a2:   %x\tx28/t3:   %x", dbg_regs[12*XLEN+:XLEN], dbg_regs[28*XLEN+:XLEN]);
        $display("x13/a3:   %x\tx29/t4:   %x", dbg_regs[13*XLEN+:XLEN], dbg_regs[29*XLEN+:XLEN]);
        $display("x14/a4:   %x\tx30/t5:   %x", dbg_regs[14*XLEN+:XLEN], dbg_regs[30*XLEN+:XLEN]);
        $display("x15/a5:   %x\tx31/t6:   %x", dbg_regs[15*XLEN+:XLEN], dbg_regs[31*XLEN+:XLEN]);
    end
    endtask


    //----------------------------------------------------------------------------------------------
    // This sections is used for Icarus Verilog based simulation, relying on SVUT system verilog
    // framework. The structure is minimal while we only assert/deassert reset and wait for the end
    // of execution
    //----------------------------------------------------------------------------------------------
    `ifndef VERILATOR

        initial aclk = 0;
        always #1 aclk = ~aclk;

        initial begin
            $sformat(tcname, "%s", ``TCNAME);
        end

        task setup(msg="");
        begin
            aresetn = 1'b0;
            tc_error_flag = 1'b0;
            srst = 1'b0;
            timer = 0;
            repeat (5) @(posedge aclk);
            aresetn = 1'b1;
            repeat (5) @(posedge aclk);
        end
        endtask

        task teardown(msg="");
        begin
            $display("");
            check_test(MIN_PC);
            print_isa_regs;
        end
        endtask


        `TEST_SUITE("FRISCV Testbench")

        `UNIT_TEST(tcname)

            // Stop the simulation if executing EBREAK or if reached the timeout
            while (status[1]==1'b0 && timer<TIMEOUT) begin
                timer = timer + 1;
                @(posedge aclk);
            end

        `UNIT_TEST_END

        `TEST_SUITE_END

    `endif


    //----------------------------------------------------------------------------------------------
    // This sections is used for Verilator based simulation, and simply implements a timer to
    // detect any timeout. The simulation is finished here to trig Verilator context, testcase
    // is also checked here.
    //----------------------------------------------------------------------------------------------
    `ifdef VERILATOR

        initial begin
            tc_error_flag = 1'b0;
        end

        always @ (posedge aclk or negedge aresetn) begin

            if (!aresetn) begin
                timer <= 0;
            end else if (srst) begin
                timer <= 0;
            end else begin
                timer <= timer + 1;
            end

            if (timer>10) begin
                // Stop the simulation if executing EBREAK
                // With Verilator only, the testbench can run infinitly with TIMEOUT=0
                if (status[1]!=1'b0 || (TIMEOUT>0 && timer>TIMEOUT)) begin

                    check_test(MIN_PC);
                    print_isa_regs;

                    `ifdef ERROR_STATUS_X31
                    if (error_status_reg==1'b0 && tc_error_flag==1'b0) begin
                    `else
                    if (tc_error_flag==1'b0) begin
                    `endif
                        `SUCCESS("Test passed");
                    end else begin
                        `ERROR("Test failed");
                    end

                    $finish();
                end
            end
        end

    `endif

endmodule
