`include "BaudGenerator.v"
`include "rx_controller.v"
`include "TxController.v"


module UART_Controller #(
    parameter CLOCK_RATE = 25000000,
    parameter BAUD_RATE = 115200,
    parameter RX_OVERSAMPLE = 16
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire [1:0]  mode,             // 00 = TX only, 01 = RX only, 10 = both
    input  wire [7:0]  tx_data,
    input  wire        tx_start,
    output wire        tx_busy,
    input  wire        uart_rx,
    output wire        uart_tx,
    output wire [7:0]  rx_data,
    output wire        rx_valid
);

    // Baud clock outputs
    wire tx_baud_clk;
    wire rx_baud_clk;

    // Instantiate Baud Generator
    BaudGenerator #(
        .Clk_Rate(CLOCK_RATE),
        .Baud_Rate(BAUD_RATE),
        .RX_OVERSAMPLE(RX_OVERSAMPLE)
    ) baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .Rx_Clk(rx_baud_clk),
        .Tx_Clk(tx_baud_clk)
    );

    // Enable or disable clocks based on mode
    wire tx_clk_en = (mode == 2'b00 || mode == 2'b10);
    wire rx_clk_en = (mode == 2'b01 || mode == 2'b10);

    // TX Controller Instance
    TxController tx_unit (
        .system_clk(tx_clk_en ? tx_baud_clk : 1'b0),
        .system_reset_n(reset_n),
        .tx_data_byte(tx_data),
        .tx_start_signal(tx_start),
        .tx_complete_flag(),           // You can wire this out if needed
        .tx_busy_flag(tx_busy),
        .tx_serial_data(uart_tx)
    );

    // RX Controller Instance
    rx_controller #(
        .RX_OVERSAMPLE(RX_OVERSAMPLE)
    ) rx_unit (
        .clk(rx_clk_en ? rx_baud_clk : 1'b0),
        .reset_n(reset_n),
        .i_data(uart_rx),
        .o_done(rx_valid),
        .o_byte(rx_data)
    );

endmodule
