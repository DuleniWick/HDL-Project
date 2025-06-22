module RxController(
    input system_clk,          // 100GHz clock
    input system_reset_n,      // Active-low reset
    input rx_serial_data,      // Serial data input
    output reg [7:0] rx_data,  // Received parallel data
    output reg rx_data_valid,  // Data valid flag
    output reg rx_error        // Error flag (e.g., stop bit error)
);

// Parameters
localparam CLK_FREQ = 100_000_000_000;  // 100GHz
localparam BAUD_RATE = 9600;
localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;  // Clock cycles per bit

// States
localparam STATE_IDLE  = 2'b00;
localparam STATE_START = 2'b01;
localparam STATE_DATA  = 2'b10;
localparam STATE_STOP  = 2'b11;

// Internal registers
reg [1:0] state;
reg [31:0] bit_counter;        // Counter for bit timing
reg [2:0] bit_index;           // Index for current data bit (0-7)
reg rx_sync;                   // Synchronized input

// Double-flop synchronizer for metastability protection
always @(posedge system_clk or negedge system_reset_n) begin
    if (!system_reset_n) begin
        rx_sync <= 1'b1;
    end else begin
        rx_sync <= rx_serial_data;
    end
end

// Main state machine
always @(posedge system_clk or negedge system_reset_n) begin
    if (!system_reset_n) begin
        state <= STATE_IDLE;
        bit_counter <= 0;
        bit_index <= 0;
        rx_data <= 8'h00;
        rx_data_valid <= 1'b0;
        rx_error <= 1'b0;
    end else begin
        // Default outputs
        rx_data_valid <= 1'b0;
        rx_error <= 1'b0;
        
        case (state)
            // IDLE: Wait for start bit (falling edge)
            STATE_IDLE: begin
                bit_counter <= 0;
                bit_index <= 0;
                
                if (rx_sync == 1'b0) begin  // Start bit detected
                    state <= STATE_START;
                    bit_counter <= BIT_PERIOD / 2;  // Sample at middle of bit
                end
            end
            
            // START: Verify start bit and prepare for data bits
            STATE_START: begin
                if (bit_counter == 0) begin
                    if (rx_sync == 1'b0) begin  // Still low (valid start bit)
                        state <= STATE_DATA;
                        bit_counter <= BIT_PERIOD;  // Full bit period for data
                    end else begin
                        state <= STATE_IDLE;  // False start
                        rx_error <= 1'b1;
                    end
                end else begin
                    bit_counter <= bit_counter - 1;
                end
            end
            
            // DATA: Sample 8 data bits
            STATE_DATA: begin
                if (bit_counter == 0) begin
                    rx_data[bit_index] <= rx_sync;  // Sample the bit
                    
                    if (bit_index == 3'b111) begin  // All 8 bits received
                        state <= STATE_STOP;
                        bit_counter <= BIT_PERIOD;  // Full bit period for stop
                    end else begin
                        bit_index <= bit_index + 1;
                        bit_counter <= BIT_PERIOD;  // Reset counter for next bit
                    end
                end else begin
                    bit_counter <= bit_counter - 1;
                end
            end
            
            // STOP: Verify stop bit and complete reception
            STATE_STOP: begin
                if (bit_counter == 0) begin
                    if (rx_sync == 1'b1) begin  // Valid stop bit
                        rx_data_valid <= 1'b1;
                    end else begin
                        rx_error <= 1'b1;  // Stop bit error
                    end
                    state <= STATE_IDLE;
                end else begin
                    bit_counter <= bit_counter - 1;
                end
            end
            
            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule