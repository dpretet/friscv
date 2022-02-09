// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`default_nettype none
`timescale 1 ns / 100 ps

`include "svut_h.sv"
`include "../../rtl/friscv_h.sv"

module tb();

    `SVUT_SETUP

    `ifndef FRISCV_SIM
    `define FRISCV_SIM 1
    `endif

    // Maximum cycle of a simulation run, after that break it
    `ifndef TIMEOUT
    `define TIMEOUT 10000
    `endif

    // Instruction RAM boot address
    `ifndef BOOT_ADDR
    `define BOOT_ADDR 0
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

    // Architecture selection: 32 or 64 bits
    `ifndef TB_CHOICE
    `define TB_CHOICE "CORE"
    `endif

    parameter TB_CHOICE = ``TB_CHOICE;

    // Instruction length
    parameter ILEN = 32;
    // 32 bits architecture
    parameter XLEN = `XLEN;
    // RV32E architecture, limits integer registers to 16, else 32
    parameter RV32E = 0;
    // Boot address used by the control unit
    parameter BOOT_ADDR = `BOOT_ADDR;
    // Number of outstanding requests used by the control unit
    parameter INST_OSTDREQ_NUM = 8;
    // MHART ID CSR register
    parameter MHART_ID = 0;

    // Floating-point extension support
    parameter F_EXTENSION = 0;
    // Multiply/Divide extension support
    parameter M_EXTENSION = 1;
    // Insert a pipeline on instruction bus coming from the controller
    parameter PROCESSING_BUS_PIPELINE = 1;
    // FIFO depth of processing unit, buffering the instruction to execute
    parameter PROCESSING_QUEUE_DEPTH = 0;
    // Express mode track the register usage and avoid wait state in control unit
    parameter EXPRESS_MODE = 0;

    // Address buses width
    parameter AXI_ADDR_W = XLEN;
    // AXI ID width, setup by default to 8 and unused
    parameter AXI_ID_W = 8;
    // AXI4 data width
    parameter AXI_DATA_W = `CACHE_BLOCK_W;
    // AXI4 instruction bus width
    parameter AXI_IMEM_W = `CACHE_BLOCK_W;
    // AXI4 data bus width
    parameter AXI_DMEM_W = (TB_CHOICE=="CORE") ? XLEN : `CACHE_BLOCK_W;
    // ID used by instruction and data buses
    parameter AXI_IMEM_MASK = 'h10;
    parameter AXI_DMEM_MASK = 'h20;

    // Enable Instruction cache
    parameter ICACHE_EN = 1;
    // Enable cache block prefetch
    parameter ICACHE_PREFETCH_EN = 0;
    // Block width defining only the data payload, in bits, must an
    // integer multiple of XLEN
    parameter ICACHE_BLOCK_W = `CACHE_BLOCK_W;
    // Number of blocks in the cache
    parameter ICACHE_DEPTH = 512;

    // Enable data cache
    parameter DCACHE_EN = (TB_CHOICE=="PLATFORM") ? 1 : 0;
    // Enable cache block prefetch
    parameter DCACHE_PREFETCH_EN = 0;
    // Block width defining only the data payload, in bits, must an
    // integer multiple of XLEN
    parameter DCACHE_BLOCK_W = `CACHE_BLOCK_W;
    // Number of blocks in the cache
    parameter DCACHE_DEPTH = 512;

    // timeout used in the testbench to break the simulation
    parameter TIMEOUT = `TIMEOUT;
    // Variable latency setup the AXI4-lite RAM model
    parameter VARIABLE_LATENCY = 0;


    integer                    timer;
    string                     tcname;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      ext_irq;
    logic                      sw_irq;
    logic                      timer_irq;
    logic                      rtc;
    logic [8             -1:0] status;
    logic                      error_status_reg;
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


    // Run the testbench by using only the CPU core
    generate
    if (TB_CHOICE=="CORE") begin

    assign timer_irq = 1'b0;
    assign sw_irq = 1'b0;
    assign ext_irq = 1'b0;

    friscv_rv32i_core
    #(
        .ILEN (ILEN),
        .XLEN (XLEN),
        .BOOT_ADDR (BOOT_ADDR),
        .INST_OSTDREQ_NUM (INST_OSTDREQ_NUM),
        .MHART_ID (MHART_ID),
        .RV32E (RV32E),
        .M_EXTENSION (M_EXTENSION),
        .F_EXTENSION (F_EXTENSION),
        .PROCESSING_QUEUE_DEPTH (PROCESSING_QUEUE_DEPTH),
        .PROCESSING_BUS_PIPELINE (PROCESSING_BUS_PIPELINE),
        .EXPRESS_MODE (EXPRESS_MODE),
        .AXI_ADDR_W (AXI_ADDR_W),
        .AXI_ID_W (AXI_ID_W),
        .AXI_IMEM_W (AXI_IMEM_W),
        .AXI_DMEM_W (AXI_DMEM_W),
        .AXI_IMEM_MASK (AXI_IMEM_MASK),
        .AXI_DMEM_MASK (AXI_DMEM_MASK),
        .ICACHE_EN (ICACHE_EN),
        .ICACHE_BLOCK_W (ICACHE_BLOCK_W),
        .ICACHE_PREFETCH_EN (ICACHE_PREFETCH_EN),
        .ICACHE_DEPTH (ICACHE_DEPTH),
        .DCACHE_EN (DCACHE_EN),
        .DCACHE_BLOCK_W (DCACHE_BLOCK_W),
        .DCACHE_PREFETCH_EN (DCACHE_PREFETCH_EN),
        .DCACHE_DEPTH (DCACHE_DEPTH)
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
        .error        (error_status_reg),
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
        .INIT             ("test.v"),
        .VARIABLE_LATENCY (VARIABLE_LATENCY),
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
    assign ext_irq = 1'b0;
    assign rtc = 1'b0;
    assign uart_rx = 1'b0;
    assign uart_cts = 1'b0;

    friscv_rv32i_platform
        #(
        .ILEN (ILEN),
        .XLEN (XLEN),
        .BOOT_ADDR (BOOT_ADDR),
        .INST_OSTDREQ_NUM (INST_OSTDREQ_NUM),
        .MHART_ID (MHART_ID),
        .RV32E (RV32E),
        .M_EXTENSION (M_EXTENSION),
        .F_EXTENSION (F_EXTENSION),
        .PROCESSING_QUEUE_DEPTH (PROCESSING_QUEUE_DEPTH),
        .PROCESSING_BUS_PIPELINE (PROCESSING_BUS_PIPELINE),
        .EXPRESS_MODE (EXPRESS_MODE),
        .AXI_ADDR_W (AXI_ADDR_W),
        .AXI_ID_W (AXI_ID_W),
        .AXI_DATA_W (AXI_DATA_W),
        .AXI_IMEM_MASK (AXI_IMEM_MASK),
        .AXI_DMEM_MASK (AXI_DMEM_MASK),
        .ICACHE_EN (ICACHE_EN),
        .ICACHE_PREFETCH_EN (ICACHE_PREFETCH_EN),
        .ICACHE_BLOCK_W (ICACHE_BLOCK_W),
        .ICACHE_DEPTH (ICACHE_DEPTH),
        .DCACHE_EN (DCACHE_EN),
        .DCACHE_BLOCK_W (DCACHE_BLOCK_W),
        .DCACHE_PREFETCH_EN (DCACHE_PREFETCH_EN),
        .DCACHE_DEPTH (DCACHE_DEPTH)
    )
    dut
    (
        .aclk        (aclk),
        .aresetn     (aresetn),
        .srst        (srst),
        .rtc         (rtc),
        .ext_irq     (ext_irq),
        .status      (status),
        .error       (error_status_reg),
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
        .INIT             ("test.v"),
        .VARIABLE_LATENCY (VARIABLE_LATENCY),
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

    initial aclk = 0;
    always #1 aclk = ~aclk;

    initial begin
        $dumpfile("friscv_testbench.vcd");
        $dumpvars(0, tb);
    end

    initial begin
        $sformat(tcname, "%s", ``TCNAME);
    end

    initial begin
        $display("Boot address: 0x%x", `BOOT_ADDR);
    end
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        imem_awvalid = 1'b0;
        imem_wvalid = 1'b0;
        imem_bready = 1'b0;
        aresetn = 1'b0;
        srst = 1'b0;
        timer = 0;
        repeat (5) @(posedge aclk);
        aresetn = 1'b1;
        repeat (5) @(posedge aclk);
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("RISCV Compliance Testsuite")

    `UNIT_TEST(tcname)

        // status[1] = EBREAK
        // status[4] = CSR write in read-only register
        while (status[1]==1'b0 && status[4]==1'b0 && timer<TIMEOUT) begin
            timer = timer + 1;
            @(posedge aclk);
        end

        `ASSERT((error_status_reg==0), "TEST FAILED, X31 != 0");

        if (timer<TIMEOUT) begin
            if (status[0])
                `INFO("Testbench: Halt on ECALL");
            if (status[1])
                `INFO("Testbench: Halt on EBREAK");
            if (status[3])
                `INFO("Testbench: Halt on an unsupported instruction");
            if (status[4])
                `INFO("Testbench: Halt on a read-only write register event");
        end else begin
            `ERROR("Testbench: Halt on timeout");
        end

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
