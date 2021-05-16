// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_uart

    #(
        parameter ADDRW           = 16,
        parameter XLEN            = 32,
        parameter RXTX_FIFO_DEPTH = 4
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // APB Master
        input  logic                        mst_en,
        input  logic                        mst_wr,
        input  logic [ADDRW           -1:0] mst_addr,
        input  logic [XLEN            -1:0] mst_wdata,
        input  logic [XLEN/8          -1:0] mst_strb,
        output logic [XLEN            -1:0] mst_rdata,
        output logic                        mst_ready,
        // UART interface
        input  logic                        uart_rx,
        output logic                        uart_tx
    );

    logic            enable;
    logic            busy;
    logic            loopback_mode;
    logic [XLEN-1:0] register0;
    logic [XLEN-1:0] register1;
    logic [XLEN-1:0] register2;
    logic [XLEN-1:0] register3;

    logic            tx_push;
    logic            tx_full;
    logic            tx_pull;
    logic            tx_empty;
    logic [XLEN-1:0] tx_data;

    logic            rx_push;
    logic            rx_full;
    logic            rx_pull;
    logic            rx_empty;
    logic [XLEN-1:0] rx_data;

    //////////////////////////////////////////////////////////////////////////
    //
    // # Register Map Description
    //
    // ## Register 0: Control and Status [RW] - Address 0 - 13 bits
    //
    // - bit 0:     Enable the UART engine (RX and TX) [RW]
    // - bit 1:     loopback mode, every received data will be stored in RX
    //              FIFO and send back to TX
    // - bit 7:2:   Reserved
    // - bit 8:     Busy flag, the UART engine is processing (RX or TX) [RO]
    // - bit 9:     TX FIFO is empty [RO]
    // - bit 10:    TX FIFO is full [RO]
    // - bit 11:    RX FIFO is empty [RO]
    // - bit 12:    RX FIFO is full [RO]
    // - bit 31:13: Reserved
    //
    // If a transfer (RX or TX) is active and the enable bit is setup back to
    // 0, the transfer will terminate only after the complete frame transmission
    //
    // ## Register 1: UART Clock Divider [RW] - Address 1 - 32 bits
    //
    // The number of CPU core cycles to divide down to get the UART data bit
    // rate (baud rate).
    //
    // - Bit 31:0: clock divider
    //
    //
    // ## Register 2: TX FIFO [RW] - Address 1 - 8 bits
    //
    // Push data into TX FIFO. Writing into this register will block the APB
    // write request if TX FIFO is full, until the engine transmit a new word.
    //
    // - Bit 7:0: data to write
    // - Bit 31:8: Reserved
    //
    //
    // ## Register 3: RX FIFO [RO] - Address 1 - 8 bits
    //
    // Pull data from RX FIFO. Reading into this register will block the APB
    // read request if FIFO is empty, until the engine receives a new word.
    //
    // - Bit 7:0: data ready to be read
    // - Bit 31:8: Reserved
    //
    //
    // ## Comments
    //
    // Any attempt to write in a read-only [RO] register or a reserved field
    // will be without effect and can't change the register content neither
    // the engine behavior. RW registers can be written partially by setting
    // properly the WSTRB signal.
    //
    // Register 1, setting up the baud rate, can be changed anytime like any
    // register; but an update during an ongoing operation will certainly lead
    // to compromise the transfer integrity and possibly make unstable the
    // UART engine. The user is advised to configure the baud rate during
    // start up and be sure the engine is disabled before changing this value.
    //
    //////////////////////////////////////////////////////////////////////////


    //////////////////////////////////////////////////////////////////////////
    // Registers
    //////////////////////////////////////////////////////////////////////////
 
    assign register0 = {{XLEN-16{1'b0}}, 
                        3'b0, rx_full, rx_empty, tx_full, tx_empty, busy,
                        6'b0, loopback_mode, enable};

    assign busy = 1'b0;

    //////////////////////////////////////////////////////////////////////////
    // APB Control FSM
    //////////////////////////////////////////////////////////////////////////
 
    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            enable <= 1'b0;
            loopback_mode <= 1'b0;
            tx_push <= 1'b0;
            rx_pull <= 1'b0;
            register1 <= {XLEN{1'b0}};
            register2 <= {XLEN{1'b0}};
            mst_rdata <= {XLEN{1'b0}};
            mst_ready <= 1'b0;
        end else if (srst) begin
            enable <= 1'b0;
            loopback_mode <= 1'b0;
            tx_push <= 1'b0;
            rx_pull <= 1'b0;
            register1 <= {XLEN{1'b0}};
            register2 <= {XLEN{1'b0}};
            mst_rdata <= {XLEN{1'b0}};
            mst_ready <= 1'b0;
        end else begin

            // If previously requested, go back to IDLE to serve a new request
            if (mst_ready) begin
                tx_push <= 1'b0;
                rx_pull <= 1'b0;
                mst_ready <= 1'b0;

            // Serve a new request
            end else if (mst_en) begin

                // Register 0: Control and Status
                if (mst_addr=={ADDRW{1'b0}}) begin
                    if (mst_wr) begin
                        if (mst_strb[0]) begin
                            enable <= mst_wdata[0];
                            loopback_mode <= mst_wdata[1];
                        end
                        mst_ready <= 1'b1;
                    end else begin
                        mst_rdata <= register0;
                        mst_ready <= 1'b1;
                    end

                // Register 1: baud rate
                end else if (mst_addr=={{ADDRW-1{1'b0}}, 1'b1}) begin
                    if (mst_wr) begin
                        if (mst_strb[0]) register1[ 0+:8] <= mst_wdata[ 0+:8];
                        if (mst_strb[1]) register1[ 8+:8] <= mst_wdata[ 8+:8];
                        if (mst_strb[2]) register1[16+:8] <= mst_wdata[16+:8];
                        if (mst_strb[3]) register1[24+:8] <= mst_wdata[24+:8];
                        mst_ready <= 1'b1;
                    end else begin
                        mst_rdata <= register1;
                        mst_ready <= 1'b1;
                    end

                // Register 2: TX FIFO
                end else if (mst_addr=={{ADDRW-2{1'b0}}, 2'b10}) begin
                    if (mst_wr) begin
                        // Wait until the FIFO can store a new word
                        if (~tx_full) begin
                            if (mst_strb[0]) register2[ 0+:8] <= mst_wdata[ 0+:8];
                            if (mst_strb[1]) register2[ 8+:8] <= mst_wdata[ 8+:8];
                            if (mst_strb[2]) register2[16+:8] <= mst_wdata[16+:8];
                            if (mst_strb[3]) register2[24+:8] <= mst_wdata[24+:8];
                            tx_push <= 1'b1;
                            mst_ready <= 1'b1;
                        end
                    end else begin
                        mst_rdata <= register2;
                        mst_ready <= 1'b1;
                    end

                // Register 3: RX FIFO
                end else if (mst_addr=={{ADDRW-2{1'b0}}, 2'b11}) begin
                    // Wait until the FIFO is filled
                    if (~rx_empty) begin
                        rx_pull <= 1'b1;
                        mst_rdata <= register3;
                        mst_ready <= 1'b1;
                    end
                end

            // Just wait for the next APB request
            end else begin
                tx_push <= 1'b0;
                rx_pull <= 1'b0;
                mst_ready <= 1'b0;
            end 
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // UART TX Engine
    //////////////////////////////////////////////////////////////////////////

    friscv_scfifo 
    #(
        .ADDR_WIDTH ($clog2(RXTX_FIFO_DEPTH)),
        .DATA_WIDTH (XLEN)
    )
    tx_fifo 
    (
        .aclk     (aclk     ),
        .aresetn  (aresetn  ),
        .srst     (srst     ),
        .data_in  (register2),
        .push     (tx_push  ),
        .full     (tx_full  ),
        .data_out (tx_data  ),
        .pull     (tx_pull  ),
        .empty    (tx_empty )
    );


    assign uart_tx = 1'b1;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            tx_pull <= 1'b0;
        end else if (srst) begin
            tx_pull <= 1'b0;
        end else begin
            if (~tx_empty) tx_pull <= 1'b1;
            else tx_pull <= 1'b0;
        end
    end


    //////////////////////////////////////////////////////////////////////////
    // UART RX Engine
    //////////////////////////////////////////////////////////////////////////

    friscv_scfifo 
    #(
        .ADDR_WIDTH ($clog2(RXTX_FIFO_DEPTH)),
        .DATA_WIDTH (XLEN)
    )
    rx_fifo 
    (
        .aclk     (aclk     ),
        .aresetn  (aresetn  ),
        .srst     (srst     ),
        .data_in  (rx_data  ),
        .push     (rx_push  ),
        .full     (rx_full  ),
        .data_out (register3),
        .pull     (rx_pull  ),
        .empty    (rx_empty )
    );

    assign rx_data = {XLEN{1'b0}};

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
             rx_push <= 1'b0;
        end else if (srst) begin
             rx_push <= 1'b0;
        end else begin
            if (rx_empty) rx_push <= 1'b1;
            else rx_push <= 1'b0;
        end
    end

endmodule

`resetall
