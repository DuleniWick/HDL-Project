`timescale 1ns / 1ps

`include "controller.v"

module UART_Controller_tb;

    // Clock & baud parameters
    parameter CLOCK_RATE = 25000000;
    parameter BAUD_RATE = 115200;
    parameter RX_OVERSAMPLE = 16;
    parameter CLK_PERIOD = 40; // 25 MHz → 40 ns

    // DUT inputs
    reg clk = 0;
    reg reset_n = 0;
    reg [1:0] mode = 2'b00;
    reg [7:0] tx_data = 8'h00;
    reg tx_start = 0;
    wire tx_busy;
    wire uart_tx;
    wire uart_rx;
    wire [7:0] rx_data;
    wire rx_valid;

    // DUT instance
    UART_Controller #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE),
        .RX_OVERSAMPLE(RX_OVERSAMPLE)
    ) uut (
        .clk(clk),
        .reset_n(reset_n),
        .mode(mode),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // Clock generation (25 MHz)
    always #(CLK_PERIOD/2) clk = ~clk;

    // UART loopback (connect tx to rx when both TX+RX mode)
    assign uart_rx = uart_tx;

    // Task to send a byte via UART TX
    task send_uart_byte(input [7:0] data);
    begin
        @(posedge clk);
        tx_data <= data;
        tx_start <= 1;
        @(posedge clk);
        tx_start <= 0;
        wait (tx_busy == 0);
        $display("TX Sent: %c (%h)", data, data);
    end
    endtask

    initial begin
        $display("=== UART Controller Testbench Start ===");
        // Reset
        reset_n = 0;
        @(posedge clk); @(posedge clk);
        reset_n = 1;

        // -------- TX Only Mode --------
        mode = 2'b00;
        $display("Mode 00: TX only");
        send_uart_byte(8'h41); // Send 'A'

        repeat(1000) @(posedge clk); // Wait

        // -------- RX Only Mode --------
        mode = 2'b01;
        $display("Mode 01: RX only");

        // TX again (controller doesn't TX in this mode, so we simulate)
        mode = 2'b10; // Temporarily allow TX for loopback test
        send_uart_byte(8'h42); // Send 'B'
        mode = 2'b01; // Back to RX only

        wait(rx_valid);
        $display("RX received (RX only mode): %c (%h)", rx_data, rx_data);

        // -------- TX + RX Mode --------
        mode = 2'b10;
        $display("Mode 10: TX + RX loopback");
        send_uart_byte(8'h43); // Send 'C'
        wait(rx_valid);
        $display("RX received (loopback): %c (%h)", rx_data, rx_data);

        $display("=== Testbench Complete ===");
        $stop;
    end

endmodule
