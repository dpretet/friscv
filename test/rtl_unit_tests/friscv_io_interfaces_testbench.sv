/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps

module friscv_io_interfaces_testbench();

    `SVUT_SETUP

    parameter ADDRW     = 15;
    parameter XLEN      = 32;
    parameter SLV0_ADDR = 0;
    parameter SLV0_SIZE = 8;
    parameter SLV1_ADDR = 8;
    parameter SLV1_SIZE = 16;

    logic               aclk;
    logic               aresetn;
    logic               srst;
    logic               mst_en;
    logic               mst_wr;
    logic [ADDRW  -1:0] mst_addr;
    logic [XLEN   -1:0] mst_wdata;
    logic [XLEN/8 -1:0] mst_strb;
    logic [XLEN   -1:0] mst_rdata;
    logic               mst_ready;
    logic [XLEN   -1:0] gpio_in;
    logic [XLEN   -1:0] gpio_out;
    logic               uart_data;
    logic               uart_rts;
    logic               uart_cts;

    integer timeout;

    friscv_io_interfaces
    #(
    ADDRW,
    XLEN,
    SLV0_ADDR,
    SLV0_SIZE,
    SLV1_ADDR,
    SLV1_SIZE
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    mst_en,
    mst_wr,
    mst_addr,
    mst_wdata,
    mst_strb,
    mst_rdata,
    mst_ready,
    gpio_in,
    gpio_out,
    uart_data,
    uart_data,
    uart_rts,
    uart_rts
    );

    /// to create a clock:
    initial aclk = 0;
    always #2 aclk = ~aclk;

    /// to dump data for visualization:
    initial begin
        $dumpfile("friscv_io_interfaces_testbench.vcd");
        $dumpvars(0, friscv_io_interfaces_testbench);
    end

    task setup(msg="");
    begin
        aresetn <= 1'b0;
        srst <= 1'b0;
        #20;
        aresetn <= 1'b1;
        gpio_in = 32'h00000000;
        @(posedge aclk);
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("APB IO Interfaces")

    `UNIT_TEST("GPIOs Write Testcase")

        `MSG("Write GPIOs");
        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 0;
        mst_wdata = 32'h9876543;
        mst_strb = 4'hF;
        while (~mst_ready) @(posedge aclk);
        `ASSERT((gpio_out==mst_wdata), "GPIO out is not driven with correct value");
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (3) @(posedge aclk);
    `UNIT_TEST_END

    `UNIT_TEST("GPIOs Read Testcase")

        `MSG("Read GPIOs");
        gpio_in = 32'ha5a5a5a5;
        mst_en = 1'b1;
        mst_wr = 1'b0;
        mst_addr = 1;
        mst_wdata = 32'h0;
        mst_strb = 4'h0;
        while (~mst_ready) @(posedge aclk);
        `ASSERT((gpio_in==mst_rdata), "GPIO out is not driven with correct value");
        mst_en = 1'b0;
        repeat (3) @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("UART Configure Testcase")

        `MSG("Write UART");
        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 'h8;
        mst_wdata = 32'h1;
        mst_strb = 4'hF;
        @(posedge aclk);
        while (~mst_ready) @(posedge aclk);
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (3) @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("UART Write Testcase")

        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 'h8;
        mst_wdata = 32'h1;
        mst_strb = 4'hF;
        @(posedge aclk);
        while (~mst_ready) @(posedge aclk);
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (3) @(posedge aclk);

        `MSG("Write UART");
        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 'hA;
        mst_wdata = 32'ha5;
        mst_strb = 4'hF;
        @(posedge aclk);
        while (~mst_ready) @(posedge aclk);
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (50) @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("UART Read Testcase")

        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 'h8;
        mst_wdata = 32'h1;
        mst_strb = 4'hF;
        @(posedge aclk);
        while (~mst_ready) @(posedge aclk);
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (3) @(posedge aclk);

        `MSG("Write UART");
        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 'hA;
        mst_wdata = 32'ha5;
        mst_strb = 4'hF;
        @(posedge aclk);
        while (~mst_ready) @(posedge aclk);
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (50) @(posedge aclk);

        `MSG("Read UART");
        mst_en = 1'b1;
        mst_wr = 1'b0;
        mst_addr = 'hB;
        mst_wdata = 32'ha5;
        mst_strb = 4'h0;
        @(posedge aclk);
        while (~mst_ready) @(posedge aclk);
        mst_en = 1'b0;
        `ASSERT((mst_rdata==mst_wdata), "Wrong value read back from UART")
        repeat (50) @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("Interconnect Testcase: Write in undefined space")

        `MSG("Write out of defined memory space");
        timeout = 0;
        mst_en = 1'b1;
        mst_wr = 1'b1;
        mst_addr = 'h1000;
        mst_wdata = 32'h9876543;
        mst_strb = 4'hF;
        @(posedge aclk);

        while (~mst_ready && timeout<100) begin
            timeout = timeout + 1;
            @(posedge aclk);
        end

        `ASSERT((timeout<100), "Write access led to timeout");
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (3) @(posedge aclk);

    `UNIT_TEST_END

    `UNIT_TEST("Interconnect Testcase: Read in undefined space")

        `MSG("Read out of defined memory space");
        timeout = 0;
        mst_en = 1'b1;
        mst_wr = 1'b0;
        mst_addr = 'h1000;
        mst_wdata = 32'h0;
        mst_strb = 4'h0;
        @(posedge aclk);

        while (~mst_ready && timeout<100) begin
            timeout = timeout + 1;
            @(posedge aclk);
        end

        `ASSERT((timeout<100), "Read access led to timeout");
        mst_en = 1'b0;
        mst_wr = 1'b0;
        repeat (3) @(posedge aclk);

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
