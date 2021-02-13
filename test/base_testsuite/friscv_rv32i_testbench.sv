/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps

module friscv_rv32i_testbench();

    `SVUT_SETUP

    parameter                  INST_ADDRW = 16;
    parameter                  DATA_ADDRW = 16;
    parameter [INST_ADDRW-1:0] BOOT_ADDR  = {INST_ADDRW{1'b0}};
    parameter                  XLEN       = 32;

    logic                   aclk;
    logic                   aresetn;
    logic                   srst;
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

    integer i;
    logic [63:0] prg [127:0];

    friscv_rv32i
    #(
    INST_ADDRW,
    DATA_ADDRW,
    BOOT_ADDR,
    XLEN
    )
    dut
    (
    aclk,
    aresetn,
    srst,
    enable,
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
    mem_ready
    );

    scram
    #(
    .ADDRW (DATA_ADDRW),
    .DATAW (XLEN)
    )
    data_ram
    (
    .aclk     (aclk     ),
    .p1_en    (mem_en   ),
    .p1_wr    (mem_wr   ),
    .p1_addr  (mem_addr ),
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

    task setup(msg="");
    begin
        /// setup() runs when a test begins
        enable = 0;
        aresetn = 1'b0;
        srst = 1'b0;
        inst_rdata = {XLEN{1'b0}};
        inst_ready = 1'b0;
        #20;
        aresetn = 1'b1;
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("Testsuite 1")

    `UNIT_TEST("Run empty C program")

        $readmemh("build/test1.hex", prg);
        for (i=0;i<64;i=i+1) begin
            $display("%x\n", prg[i]);
        end

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
