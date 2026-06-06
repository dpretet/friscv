// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`timescale 1 ns / 100 ps

module dcache_testbench();

    `SVUT_SETUP
    // Maximum request the driver must issue during the execution of a testcase
    `ifdef MAX_TRAFFIC
        parameter MAX_TRAFFIC = `MAX_TRAFFIC;
    `else
        parameter MAX_TRAFFIC = 100;
    `endif
    // Timeout value used for outstanding request monitoring
    `ifdef TIMEOUT
        parameter TIMEOUT = `TIMEOUT;
    `else
        parameter TIMEOUT = 100000;
    `endif
    // LFSR key init
    parameter KEY = 32'h28346450;
    parameter ILEN = 32;
    parameter XLEN = 32;
    parameter OSTDREQ_NUM = 8;
    parameter AXI_ADDR_W = XLEN;
    parameter AXI_ID_W = 8;
    parameter AXI_DATA_W = 128;
    parameter AXI_ID_MASK = 'h20;
    parameter IO_MAP_NB = 0;
    parameter CACHE_PREFETCH_EN = 0;
    parameter CACHE_BLOCK_W = 128;
    parameter CACHE_DEPTH = 512;
    parameter FAST_FWD_CPL = 1;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      cache_ready;
    logic                      memfy_awvalid;
    logic                      memfy_awready;
    logic  [AXI_ADDR_W   -1:0] memfy_awaddr;
    logic  [3            -1:0] memfy_awprot;
    logic  [4            -1:0] memfy_awcache;
    logic  [AXI_ID_W     -1:0] memfy_awid;
    logic                      memfy_wvalid;
    logic                      memfy_wready;
    logic  [XLEN         -1:0] memfy_wdata;
    logic  [XLEN/8       -1:0] memfy_wstrb;
    logic                      memfy_bvalid;
    logic                      memfy_bready;
    logic [AXI_ID_W      -1:0] memfy_bid;
    logic [2             -1:0] memfy_bresp;
    logic                      memfy_arvalid;
    logic                      memfy_arready;
    logic  [AXI_ADDR_W   -1:0] memfy_araddr;
    logic  [3            -1:0] memfy_arprot;
    logic  [4            -1:0] memfy_arcache;
    logic  [AXI_ID_W     -1:0] memfy_arid;
    logic                      memfy_rvalid;
    logic                      memfy_rready;
    logic [AXI_ID_W      -1:0] memfy_rid;
    logic [2             -1:0] memfy_rresp;
    logic [XLEN          -1:0] memfy_rdata;

    logic                      memfy_p_awvalid;
    logic                      memfy_p_awready;
    logic  [AXI_ADDR_W   -1:0] memfy_p_awaddr;
    logic  [3            -1:0] memfy_p_awprot;
    logic  [4            -1:0] memfy_p_awcache;
    logic  [AXI_ID_W     -1:0] memfy_p_awid;
    logic                      memfy_p_wvalid;
    logic                      memfy_p_wready;
    logic  [XLEN         -1:0] memfy_p_wdata;
    logic  [XLEN/8       -1:0] memfy_p_wstrb;
    logic                      memfy_p_bvalid;
    logic                      memfy_p_bready;
    logic [AXI_ID_W      -1:0] memfy_p_bid;
    logic [2             -1:0] memfy_p_bresp;
    logic                      memfy_p_arvalid;
    logic                      memfy_p_arready;
    logic  [AXI_ADDR_W   -1:0] memfy_p_araddr;
    logic  [3            -1:0] memfy_p_arprot;
    logic  [4            -1:0] memfy_p_arcache;
    logic  [AXI_ID_W     -1:0] memfy_p_arid;
    logic                      memfy_p_rvalid;
    logic                      memfy_p_rready;
    logic [AXI_ID_W      -1:0] memfy_p_rid;
    logic [2             -1:0] memfy_p_rresp;
    logic [XLEN          -1:0] memfy_p_rdata;


    logic                      dcache_awvalid;
    logic                      dcache_awready;
    logic [AXI_ADDR_W    -1:0] dcache_awaddr;
    logic [8             -1:0] dcache_awlen;
    logic [3             -1:0] dcache_awsize;
    logic [2             -1:0] dcache_awburst;
    logic                      dcache_awlock;
    logic [4             -1:0] dcache_awcache;
    logic [3             -1:0] dcache_awprot;
    logic [4             -1:0] dcache_awqos;
    logic [4             -1:0] dcache_awregion;
    logic [AXI_ID_W      -1:0] dcache_awid;
    logic                      dcache_wvalid;
    logic                      dcache_wready;
    logic                      dcache_wlast;
    logic [AXI_DATA_W    -1:0] dcache_wdata;
    logic [AXI_DATA_W/8  -1:0] dcache_wstrb;
    logic                      dcache_bvalid;
    logic                      dcache_bready;
    logic  [AXI_ID_W     -1:0] dcache_bid;
    logic  [2            -1:0] dcache_bresp;
    logic                      dcache_arvalid;
    logic                      dcache_arready;
    logic [AXI_ADDR_W    -1:0] dcache_araddr;
    logic [8             -1:0] dcache_arlen;
    logic [3             -1:0] dcache_arsize;
    logic [2             -1:0] dcache_arburst;
    logic                      dcache_arlock;
    logic [4             -1:0] dcache_arcache;
    logic [3             -1:0] dcache_arprot;
    logic [4             -1:0] dcache_arqos;
    logic [4             -1:0] dcache_arregion;
    logic [AXI_ID_W      -1:0] dcache_arid;
    logic                      dcache_rvalid;
    logic                      dcache_rready;
    logic  [AXI_ID_W     -1:0] dcache_rid;
    logic  [2            -1:0] dcache_rresp;
    logic  [AXI_DATA_W   -1:0] dcache_rdata;
    logic                      dcache_rlast;

    logic                      gen_io_req;
    logic                      gen_mem_req;
    logic                      error;
    logic                      error_r;
    string                     tbname;
    integer                    timer;
    integer                    rd_req_num;
    integer                    wr_req_num;
    logic                      en;


    initial begin
        $sformat(tbname, "%s", ``TBNAME);
    end

    driver
    #(
        .OSTDREQ_NUM         (OSTDREQ_NUM),
        .RW_MODE             (1),
        .KEY                 (KEY),
        .TIMEOUT             (TIMEOUT),
        .INIT                ("./ram_32b.txt"),
        .ILEN                (ILEN),
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (ILEN)
    )
    driver
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        .en                 (en),
        .cache_ready        (cache_ready),
        .error              (error),
        .check_flush_reqs   (1'b0),
        .check_flush_blocks (1'b0),
        .flush_reqs         (),
        .flush_blocks       (),
        .flush_ack          (1'b0),
        .gen_io_req         (gen_io_req),
        .gen_mem_req        (gen_mem_req),
        .awvalid            (memfy_awvalid),
        .awready            (memfy_awready),
        .awaddr             (memfy_awaddr),
        .awprot             (memfy_awprot),
        .awcache            (memfy_awcache),
        .awid               (memfy_awid),
        .wvalid             (memfy_wvalid),
        .wready             (memfy_wready),
        .wdata              (memfy_wdata),
        .wstrb              (memfy_wstrb),
        .bvalid             (memfy_bvalid),
        .bready             (memfy_bready),
        .bid                (memfy_bid),
        .bresp              (memfy_bresp),
        .arvalid            (memfy_arvalid),
        .arready            (memfy_arready),
        .araddr             (memfy_araddr),
        .arprot             (memfy_arprot),
        .arcache            (memfy_arcache),
        .arid               (memfy_arid),
        .rvalid             (memfy_rvalid),
        .rready             (memfy_rready),
        .rid                (memfy_rid),
        .rresp              (memfy_rresp),
        .rdata              (memfy_rdata)
    );

    localparam AXI_ACH_W = AXI_ADDR_W + AXI_ID_W + 4 /*ACACHE*/;
    localparam AXI_DCH_W = XLEN + XLEN/8;
    localparam AXI_BCH_W = AXI_ID_W + 2 /* RESP */;
    localparam AXI_RCH_W = XLEN + AXI_ID_W + 2 /* RESP */;


    friscv_axi_pipeline
    #(
    .OSTDREQ_NUM (OSTDREQ_NUM),
    .AXI_ACH_W   (AXI_ACH_W),
    .AXI_DCH_W   (AXI_DCH_W),
    .AXI_BCH_W   (AXI_BCH_W),
    .AXI_RCH_W   (AXI_RCH_W)
    )
    memfy_pipeline
    (
    .aclk      (aclk),
    .aresetn   (aresetn),
    .srst      (srst),
    .flush     ('0),
    .s_awvalid (memfy_awvalid),
    .s_awready (memfy_awready),
    .s_awch    ({memfy_awaddr,memfy_awid,memfy_awcache}),
    .s_wvalid  (memfy_wvalid),
    .s_wready  (memfy_wready),
    .s_wch     ({memfy_wdata,memfy_wstrb}),
    .s_bvalid  (memfy_bvalid),
    .s_bready  (memfy_bready),
    .s_bch     ({memfy_bid, memfy_bresp}),
    .s_arvalid (memfy_arvalid),
    .s_arready (memfy_arready),
    .s_arch    ({memfy_araddr,memfy_arid,memfy_arcache}),
    .s_rvalid  (memfy_rvalid),
    .s_rready  (memfy_rready),
    .s_rch     ({memfy_rid, memfy_rresp, memfy_rdata}),
    .m_awvalid (memfy_p_awvalid),
    .m_awready (memfy_p_awready),
    .m_awch    ({memfy_p_awaddr,memfy_p_awid,memfy_p_awcache}),
    .m_wvalid  (memfy_p_wvalid),
    .m_wready  (memfy_p_wready),
    .m_wch     ({memfy_p_wdata,memfy_p_wstrb}),
    .m_bvalid  (memfy_p_bvalid),
    .m_bready  (memfy_p_bready),
    .m_bch     ({memfy_p_bid, memfy_p_bresp}),
    .m_arvalid (memfy_p_arvalid),
    .m_arready (memfy_p_arready),
    .m_arch    ({memfy_p_araddr,memfy_p_arid,memfy_p_arcache}),
    .m_rvalid  (memfy_p_rvalid),
    .m_rready  (memfy_p_rready),
    .m_rch     ({memfy_p_rid, memfy_p_rresp, memfy_p_rdata})
    );


    friscv_dcache
    #(
        .ILEN                (ILEN),
        .XLEN                (XLEN),
        .OSTDREQ_NUM         (OSTDREQ_NUM),
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (AXI_DATA_W),
        .AXI_ID_MASK         (AXI_ID_MASK),
        .AXI_ID_FIXED        (0),
        .FAST_FWD_CPL        (FAST_FWD_CPL),
        .IO_MAP_NB           (IO_MAP_NB),
        .EARLY_W_CPL         (0),
        .CACHE_PREFETCH_EN   (CACHE_PREFETCH_EN),
        .CACHE_BLOCK_W       (CACHE_BLOCK_W),
        .CACHE_DEPTH         (CACHE_DEPTH)
    )
    dut
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .cache_ready     (cache_ready),
        .memfy_awvalid   (memfy_p_awvalid),
        .memfy_awready   (memfy_p_awready),
        .memfy_awaddr    (memfy_p_awaddr),
        .memfy_awprot    (memfy_p_awprot),
        .memfy_awcache   (memfy_p_awcache),
        .memfy_awid      (memfy_p_awid),
        .memfy_awlock    ('0),
        .memfy_wvalid    (memfy_p_wvalid),
        .memfy_wready    (memfy_p_wready),
        .memfy_wdata     (memfy_p_wdata),
        .memfy_wstrb     (memfy_p_wstrb),
        .memfy_bvalid    (memfy_p_bvalid),
        .memfy_bready    (memfy_p_bready),
        .memfy_bid       (memfy_p_bid),
        .memfy_bresp     (memfy_p_bresp),
        .memfy_arvalid   (memfy_p_arvalid),
        .memfy_arready   (memfy_p_arready),
        .memfy_araddr    (memfy_p_araddr),
        .memfy_arprot    (memfy_p_arprot),
        .memfy_arcache   (memfy_p_arcache),
        .memfy_arid      (memfy_p_arid),
        .memfy_arlock    ('0),
        .memfy_rvalid    (memfy_p_rvalid),
        .memfy_rready    (memfy_p_rready),
        .memfy_rid       (memfy_p_rid),
        .memfy_rresp     (memfy_p_rresp),
        .memfy_rdata     (memfy_p_rdata),
        .dmem_awvalid    (dcache_awvalid),
        .dmem_awready    (dcache_awready),
        .dmem_awaddr     (dcache_awaddr),
        .dmem_awlen      (dcache_awlen),
        .dmem_awsize     (dcache_awsize),
        .dmem_awburst    (dcache_awburst),
        .dmem_awlock     (dcache_awlock),
        .dmem_awcache    (dcache_awcache),
        .dmem_awprot     (dcache_awprot),
        .dmem_awqos      (dcache_awqos),
        .dmem_awregion   (dcache_awregion),
        .dmem_awid       (dcache_awid),
        .dmem_wvalid     (dcache_wvalid),
        .dmem_wready     (dcache_wready),
        .dmem_wlast      (dcache_wlast),
        .dmem_wdata      (dcache_wdata),
        .dmem_wstrb      (dcache_wstrb),
        .dmem_bvalid     (dcache_bvalid),
        .dmem_bready     (dcache_bready),
        .dmem_bid        (dcache_bid),
        .dmem_bresp      (dcache_bresp),
        .dmem_arvalid    (dcache_arvalid),
        .dmem_arready    (dcache_arready),
        .dmem_araddr     (dcache_araddr),
        .dmem_arlen      (dcache_arlen),
        .dmem_arsize     (dcache_arsize),
        .dmem_arburst    (dcache_arburst),
        .dmem_arlock     (dcache_arlock),
        .dmem_arcache    (dcache_arcache),
        .dmem_arprot     (dcache_arprot),
        .dmem_arqos      (dcache_arqos),
        .dmem_arregion   (dcache_arregion),
        .dmem_arid       (dcache_arid),
        .dmem_rvalid     (dcache_rvalid),
        .dmem_rready     (dcache_rready),
        .dmem_rid        (dcache_rid),
        .dmem_rresp      (dcache_rresp),
        .dmem_rdata      (dcache_rdata),
        .dmem_rlast      (dcache_rlast)
    );

    assign dcache_rlast = 1'b0;

    axi4l_ram
    #(
        .INIT             ("./ram_128b.txt"),
        .AXI_ADDR_W       (AXI_ADDR_W),
        .AXI_ID_W         (AXI_ID_W),
        .AXI1_DATA_W      (AXI_DATA_W),
        .AXI2_DATA_W      (AXI_DATA_W),
        .OSTDREQ_NUM      (OSTDREQ_NUM)
    )
    axi4l_ram
    (
        .aclk       (aclk),
        .aresetn    (aresetn),
        .srst       (srst),
        .p1_awvalid (dcache_awvalid),
        .p1_awready (dcache_awready),
        .p1_awaddr  (dcache_awaddr),
        .p1_awprot  (dcache_awprot),
        .p1_awid    (dcache_awid),
        .p1_wvalid  (dcache_wvalid),
        .p1_wready  (dcache_wready),
        .p1_wdata   (dcache_wdata),
        .p1_wstrb   (dcache_wstrb),
        .p1_bid     (dcache_bid),
        .p1_bresp   (dcache_bresp),
        .p1_bvalid  (dcache_bvalid),
        .p1_bready  (dcache_bready),
        .p1_arvalid (dcache_arvalid),
        .p1_arready (dcache_arready),
        .p1_araddr  (dcache_araddr),
        .p1_arprot  (dcache_arprot ),
        .p1_arid    (dcache_arid),
        .p1_rvalid  (dcache_rvalid),
        .p1_rready  (dcache_rready),
        .p1_rid     (dcache_rid),
        .p1_rresp   (dcache_rresp),
        .p1_rdata   (dcache_rdata),
        .p2_awvalid (1'b0),
        .p2_awready (),
        .p2_awaddr  ({AXI_ADDR_W{1'b0}}),
        .p2_awprot  (3'h0),
        .p2_awid    ({AXI_ID_W{1'b0}}),
        .p2_wvalid  (1'b0),
        .p2_wready  (),
        .p2_wdata   ({CACHE_BLOCK_W{1'b0}}),
        .p2_wstrb   ({CACHE_BLOCK_W/8{1'b0}}),
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


    initial aclk = 0;
    always #2 aclk = ~aclk;

    `ifdef TRACE_VCD
    // To dump data for visualization:
    initial begin
        `INFO("Tracing into dcache_testbench.fst");
        $dumpfile("dcache_testbench.fst");
        $dumpvars(0, dcache_testbench);
        `INFO("Model running...");
    end
    `endif

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        en = 1'b0;
        timer = 0;
        rd_req_num = 0;
        wr_req_num = 0;
        srst = 1'b0;
        gen_mem_req = 1'b0;
        gen_io_req = 1'b0;
        aresetn = 1'b0;
        #20;
        @(posedge aclk);
        aresetn = 1'b1;
    end
    endtask

    task teardown(msg="");
    begin
        check_results;
    end
    endtask

    task check_results;

        `INFO("Checking results");

        if (timer >= TIMEOUT)
            `ERROR("Testbench reached timeout");

        if (error_r)
            `ERROR("Driver detected an issue");

        if (rd_req_num==MAX_TRAFFIC)
            `SUCCESS("Maximum read traffic has been issued!");

        if (wr_req_num==MAX_TRAFFIC)
            `SUCCESS("Maximum write traffic has been issued!");
    endtask

    task run_testcase;
        while (timer<TIMEOUT && (rd_req_num<MAX_TRAFFIC && wr_req_num<MAX_TRAFFIC) && error===1'b0) begin
            timer = timer + 1;
            if (memfy_arvalid && memfy_arready) begin
                rd_req_num = rd_req_num + 1;
                timer = 0;
            end
            if (memfy_awvalid && memfy_awready) begin
                wr_req_num = wr_req_num + 1;
                timer = 0;
            end
            @(posedge aclk);
        end
    endtask

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) error_r <= '0;
        else if (error) error_r <= 1;
    end

    `TEST_SUITE(tbname)

    /*
    `UNIT_TEST("Randomized traffic -io_req +blk_req")

        gen_mem_req = 1;
        gen_io_req = 0;
        en = 1'b1;
        run_testcase;
        en = 0;
        #1000;

    `UNIT_TEST_END

    `UNIT_TEST("Randomized traffic +io_req -blk_req")

        en = 1'b1;
        gen_mem_req = 0;
        gen_io_req = 1;
        run_testcase;
        en = 0;
        #1000;

    `UNIT_TEST_END
*/
    `UNIT_TEST("Randomized traffic +io_req +blk_req")

        en = 1'b1;
        gen_mem_req = 1;
        gen_io_req = 1;
        run_testcase;
        en = 0;
        #1000;

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
