`timescale 1 ns / 1 ps
`default_nettype none

`include "svut_h.sv"

module uart_vpi

    #(
        parameter ADDRW           = 16,
        parameter XLEN            = 32,
        parameter RXTX_FIFO_DEPTH = 4,
        parameter CLK_DIVIDER     = 4
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // UART interface
        input  logic                        uart_rx,
        output logic                        uart_tx,
        output logic                        uart_rts,
        input  logic                        uart_cts
    );

    logic                        mst_en;
    logic                        mst_wr;
    logic [ADDRW           -1:0] mst_addr;
    logic [XLEN            -1:0] mst_wdata;
    logic [XLEN/8          -1:0] mst_strb;
    logic [XLEN            -1:0] mst_rdata;
    logic                        mst_ready;

    initial begin
        mst_en = 1'b0;
        mst_wr = 1'b0;
        mst_addr = 16'h0;
        mst_wdata = 32'h0;
        mst_strb = 4'h0;
        while (aresetn==1'b0) @(posedge aclk);
        init();
        // Commented, for the moment the socket creation
        // block the simulation which can't stop
        $uart_init;
    end 

    task init;
        `INFO("Initialize UART VPI core");
        mst_en = 1;
        mst_addr = 0;
        mst_wr = 1;
        mst_wdata = 1;
        mst_strb = 1;
        while (~mst_ready) @ (posedge aclk);
        mst_en = 0;
    endtask


    friscv_uart 
    #(
        .ADDRW           (ADDRW),
        .XLEN            (XLEN),
        .RXTX_FIFO_DEPTH (RXTX_FIFO_DEPTH),
        .CLK_DIVIDER     (CLK_DIVIDER)
    )
    uart 
    (
        .aclk      (aclk     ),
        .aresetn   (aresetn  ),
        .srst      (srst     ),
        .mst_en    (mst_en   ),
        .mst_wr    (mst_wr   ),
        .mst_addr  (mst_addr ),
        .mst_wdata (mst_wdata),
        .mst_strb  (mst_strb ),
        .mst_rdata (mst_rdata),
        .mst_ready (mst_ready),
        .uart_rx   (uart_rx  ),
        .uart_tx   (uart_tx  ),
        .uart_rts  (uart_rts ),
        .uart_cts  (uart_cts )
    );

endmodule

`resetall

