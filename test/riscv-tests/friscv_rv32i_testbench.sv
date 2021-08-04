/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps
`include "../../rtl/friscv_h.sv"

module friscv_rv32i_testbench();

    `SVUT_SETUP

    // Instruction length
    parameter ILEN               = 32;
    // 32 bits architecture
    parameter XLEN               = 32;
    // RV32E architecture, limites integer registers to 16, else 32
    parameter RV32E              = 0;
    // Boot address used by the control unit
    parameter BOOT_ADDR          = `BOOT_ADDR;
    // Number of outstanding requests used by the control unit
    parameter INST_OSTDREQ_NUM   = 8;
    // MHART ID CSR register
    parameter MHART_ID           = 0;
    // Address buses width
    parameter AXI_ADDR_W         = 24;
    // AXI ID width, setup by default to 8 and unused
    parameter AXI_ID_W           = 8;
    // AXI4 data width, independant of control unit width
    parameter AXI_DATA_W         = `CACHE_LINE_W;
    // Address buses width
    parameter DATA_ADDRW         = 16;
    // Define the address of GPIO peripheral in APB interconnect
    parameter GPIO_SLV0_ADDR     = 0;
    parameter GPIO_SLV0_SIZE     = 2;
    parameter GPIO_SLV1_ADDR     = 2;
    parameter GPIO_SLV1_SIZE     = 4;
    // Define the memory map of GPIO and data memory
    // in the global memory space
    parameter GPIO_BASE_ADDR     = 0;
    parameter GPIO_BASE_SIZE     = 2048;
    parameter DATA_MEM_BASE_ADDR = 2048;
    parameter DATA_MEM_BASE_SIZE = 16384;
    // UART FIFO Depth
    parameter UART_FIFO_DEPTH    = 4;
    // Enable Instruction cache
    parameter ICACHE_EN          = 1;
    // Line width defining only the data payload, in bits, must an
    // integer multiple of XLEN
    parameter CACHE_LINE_W       = `CACHE_LINE_W;
    // Number of lines in the cache
    parameter CACHE_DEPTH        = 512;

    // timeout used in the testbench to break the simulation
    parameter TIMEOUT = 10000;
    // Variable latency setup the AXI4-lite RAM model
    parameter VARIABLE_LATENCY = 0;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      ebreak;
    logic                      enable;

    logic                      inst_arvalid;
    logic                      inst_arready;
    logic [AXI_ADDR_W    -1:0] inst_araddr;
    logic [3             -1:0] inst_arprot;
    logic [AXI_ID_W      -1:0] inst_arid;
    logic                      inst_rvalid;
    logic                      inst_rready;
    logic [AXI_ID_W      -1:0] inst_rid;
    logic [2             -1:0] inst_rresp;
    logic [AXI_DATA_W    -1:0] inst_rdata;
    logic                      inst_awvalid;
    logic                      inst_awready;
    logic [AXI_ADDR_W    -1:0] inst_awaddr;
    logic [3             -1:0] inst_awprot;
    logic [AXI_ID_W      -1:0] inst_awid;
    logic                      inst_wvalid;
    logic                      inst_wready;
    logic [AXI_DATA_W    -1:0] inst_wdata;
    logic [AXI_ID_W      -1:0] inst_wid;
    logic [2             -1:0] inst_bresp;
    logic                      inst_bvalid;
    logic                      inst_bready;

    logic                      mem_en;
    logic                      mem_wr;
    logic [DATA_ADDRW    -1:0] mem_addr;
    logic [XLEN          -1:0] mem_wdata;
    logic [XLEN/8        -1:0] mem_strb;
    logic [XLEN          -1:0] mem_rdata;
    logic                      mem_ready;
    logic [XLEN          -1:0] gpio_in;
    logic [XLEN          -1:0] gpio_out;
    logic                      uart_tx;
    logic                      uart_rx;
    logic                      uart_rts;
    logic                      uart_cts;
    integer                    inst_counter;
    integer                    timer;

    friscv_rv32i
    #(
        ILEN,
        XLEN,
        BOOT_ADDR,
        INST_OSTDREQ_NUM,
        MHART_ID,
        RV32E,
        AXI_ADDR_W,
        AXI_ID_W,
        AXI_DATA_W,
        DATA_ADDRW,
        GPIO_SLV0_ADDR,
        GPIO_SLV0_SIZE,
        GPIO_SLV1_ADDR,
        GPIO_SLV1_SIZE,
        GPIO_BASE_ADDR,
        GPIO_BASE_SIZE,
        DATA_MEM_BASE_ADDR,
        DATA_MEM_BASE_SIZE,
        UART_FIFO_DEPTH,
        ICACHE_EN,
        CACHE_LINE_W,
        CACHE_DEPTH
    )
    dut
    (
        aclk,
        aresetn,
        srst,
        enable,
        ebreak,
        inst_arvalid,
        inst_arready,
        inst_araddr,
        inst_arprot,
        inst_arid,
        inst_rvalid,
        inst_rready,
        inst_rid,
        inst_rresp,
        inst_rdata,
        mem_en,
        mem_wr,
        mem_addr,
        mem_wdata,
        mem_strb,
        mem_rdata,
        mem_ready,
        gpio_in,
        gpio_out,
        uart_rx,
        uart_tx,
        uart_rts,
        uart_cts
    );

    assign uart_rx = uart_tx;
    assign uart_cts = uart_rts;


    axi4l_ram
    #(
        .INIT             ("test.v"),
        .VARIABLE_LATENCY (VARIABLE_LATENCY),
        .AXI_ADDR_W       (AXI_ADDR_W),
        .AXI_ID_W         (AXI_ID_W),
        .AXI_DATA_W       (AXI_DATA_W),
        .OSTDREQ_NUM      (INST_OSTDREQ_NUM)
    )
    inst_axi4l_ram
    (
        .aclk    (aclk        ),
        .aresetn (aresetn     ),
        .srst    (srst        ),
        .awvalid (inst_awvalid),
        .awready (inst_awready),
        .awaddr  (inst_awaddr ),
        .awprot  (inst_awprot ),
        .awid    (inst_awid   ),
        .wvalid  (inst_wvalid ),
        .wready  (inst_wready ),
        .wdata   (inst_wdata  ),
        .wid     (inst_wid    ),
        .bresp   (inst_bresp  ),
        .bvalid  (inst_bvalid ),
        .bready  (inst_bready ),
        .arvalid (inst_arvalid),
        .arready (inst_arready),
        .araddr  (inst_araddr ),
        .arprot  (inst_arprot ),
        .arid    (inst_arid   ),
        .rvalid  (inst_rvalid ),
        .rready  (inst_rready ),
        .rid     (inst_rid    ),
        .rresp   (inst_rresp  ),
        .rdata   (inst_rdata  )
    );

    apb_ram
    #(
        .INIT  ("zero.v"),
        .LATENCY (1),
        .ADDRW (DATA_ADDRW),
        .DATAW (XLEN)
    )
    data_ram
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .p1_en    (mem_en),
        .p1_wr    (mem_wr),
        .p1_addr  (mem_addr),
        .p1_wdata (mem_wdata),
        .p1_strb  (mem_strb ),
        .p1_rdata (mem_rdata),
        .p1_ready (mem_ready),
        .p2_en    (1'b0),
        .p2_wr    (1'b0),
        .p2_addr  ({DATA_ADDRW{1'b0}}),
        .p2_wdata ({XLEN{1'b0}}),
        .p2_strb  ({XLEN/8{1'b0}}),
        .p2_rdata (/*unused*/),
        .p2_ready (/*unused*/)
    );


    initial aclk = 0;
    always #1 aclk = ~aclk;

    initial begin
        $dumpfile("friscv_rv32i_testbench.vcd");
        $dumpvars(0, friscv_rv32i_testbench);
    end

    initial begin
        $display("Boot address: 0x%x", `BOOT_ADDR);
    end
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        inst_awvalid = 1'b0;
        inst_wvalid = 1'b0;
        inst_bready = 1'b0;
        enable = 0;
        inst_counter = 0;
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

    `TEST_SUITE("ASM Testsuite")

    `UNIT_TEST("Run program")

        `INFO("Start test");
        @(posedge aclk);
        while (ebreak==1'b0 && timer<TIMEOUT) begin
            timer = timer + 1;
            @(posedge aclk);
        end
        repeat(5) @(posedge aclk);
        `ASSERT((dut.isa_registers.regs[31]==0), "TEST FAILED");
        if (timer<TIMEOUT) begin
            $display("Testcase errors: %0d", dut.isa_registers.regs[31]);
        end
        `ASSERT((timer<TIMEOUT), "Reached timeout");
        `INFO("Stop test");

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
