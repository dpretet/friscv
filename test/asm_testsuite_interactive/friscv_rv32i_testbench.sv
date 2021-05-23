/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps
`include "../../rtl/friscv_h.sv"

module friscv_rv32i_testbench();

    `SVUT_SETUP

    // 32 bits architecture
    parameter XLEN               = 32;
    // Address buses width
    parameter INST_ADDRW         = 16;
    parameter DATA_ADDRW         = 16;
    // Boot address used by the control unit
    parameter BOOT_ADDR          = 0;
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
    parameter UART_FIFO_DEPTH = 4;
    
    // timeout used in the testbench to break the simulation
    parameter TIMEOUT    = 1000000;

    logic                   aclk;
    logic                   aresetn;
    logic                   srst;
    logic                   ebreak;
    logic                   enable;
    logic                   inst_en;
    logic [INST_ADDRW -1:0] inst_addr;
    logic [XLEN       -1:0] inst_rdata;
    logic                   inst_ready;
    logic                   mem_en;
    logic                   mem_wr;
    logic [DATA_ADDRW -1:0] mem_addr;
    logic [XLEN       -1:0] mem_wdata;
    logic [XLEN/8     -1:0] mem_strb;
    logic [XLEN       -1:0] mem_rdata;
    logic                   mem_ready;
    logic [XLEN       -1:0] gpio_in;
    logic [XLEN       -1:0] gpio_out;
    logic                   uart_tx;
    logic                   uart_rx;
    logic                   uart_rts;
    logic                   uart_cts;
    integer                 inst_counter;
    integer                 timer;

    friscv_rv32i
    #(
        XLEN,
        INST_ADDRW,
        DATA_ADDRW,
        BOOT_ADDR,
        GPIO_SLV0_ADDR,
        GPIO_SLV0_SIZE,
        GPIO_SLV1_ADDR,
        GPIO_SLV1_SIZE,
        GPIO_BASE_ADDR,
        GPIO_BASE_SIZE,
        DATA_MEM_BASE_ADDR,
        DATA_MEM_BASE_SIZE,
        UART_FIFO_DEPTH
    )
    dut
    (
        aclk,
        aresetn,
        srst,
        enable,
        ebreak,
        inst_en,
        inst_addr,
        inst_rdata,
        inst_ready,
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

    scram
    #(
        .INIT  ("test.v"),
        .ADDRW (INST_ADDRW),
        .DATAW (XLEN)
    )
    instruction_ram
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .p1_en    (inst_en),
        .p1_wr    (1'b0),
        .p1_addr  (inst_addr),
        .p1_wdata ('h0),
        .p1_strb  (4'h0),
        .p1_rdata (inst_rdata),
        .p2_en    (1'b0),
        .p2_wr    (1'b0),
        .p2_addr  ({DATA_ADDRW{1'b0}}),
        .p2_wdata ({XLEN{1'b0}}),
        .p2_strb  ({XLEN/8{1'b0}}),
        .p2_rdata (/*unused*/)
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


    uart_vpi
    #(
        .ADDRW           (DATA_ADDRW),
        .XLEN            (XLEN),
        .RXTX_FIFO_DEPTH (UART_FIFO_DEPTH),
        .CLK_DIVIDER     (8)
    )
    uart_vpi
    (
        .aclk     (aclk    ),
        .aresetn  (aresetn ),
        .srst     (srst    ),
        .ebreak   (ebreak  ),
        .uart_rx  (uart_tx ),
        .uart_tx  (uart_rx ),
        .uart_rts (uart_cts),
        .uart_cts (uart_rts)
    );

    initial aclk = 0;
    always #1 aclk = ~aclk;

    initial begin
        $dumpfile("friscv_rv32i_testbench.vcd");
        $dumpvars(0, friscv_rv32i_testbench);
    end

    task setup(msg="");
    begin
        /// setup() runs when a test begins
        enable = 0;
        inst_counter = 0;
        aresetn = 1'b0;
        srst = 1'b0;
        inst_ready = 1'b1;
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
        $uart_close;
        repeat(5) @(posedge aclk);
        `ASSERT((dut.x31==0), "TEST FAILED");
        if (timer<TIMEOUT) begin
            $display("Testcase errors: %0d", dut.x31);
        end
        `ASSERT((timer<100), "Reached timeout");
        `INFO("Stop test");

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
