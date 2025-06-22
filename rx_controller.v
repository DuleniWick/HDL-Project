module rx_controller #(    
    parameter CLK_FREQ = 100_000_000_000,  // 100GHz clock
    parameter BAUD_RATE = 9600,
    parameter RX_OVERSAMPLE = 16           // Oversampling factor 
)
(
    input wire clk,
    input wire reset_n,
    input wire i_data,
    output  o_done,
    output  [7:0] o_byte 

);

localparam  RX_IDLE = 3'b000,
            RX_START = 3'b001,
            RX_DATA = 3'b010,
            RX_STOP = 3'b011;

// Calculate bit period in clock cycles
localparam BIT_PERIOD = (CLK_FREQ / BAUD_RATE);

reg [7:0] rx_data;
reg [2:0] rx_bit_index;
reg [4:0] rx_clk_count;
reg       rx_done;
reg [2:0] rx_state;

//UART RX LOGIC

always @(posedge clk or negedge reset_n)
begin 
    if(~reset_n) begin
        rx_state <= RX_IDLE;
        rx_bit_index <= 0;
        rx_clk_count <= 1'b0;
        rx_done <= 1'b0;
        rx_data <= 8'b00;
    end

    else begin
        case(rx_state)

            RX_IDLE: begin
                rx_bit_index <= 0; //reset bit_index, clk_count and done flag
                rx_clk_count <= 1'b0;
                rx_done <= 1'b0;

                if(i_data == 1'b0) begin //Start bit is detected as low
                    rx_state <= RX_START; //Go to START state
                end

                else begin
                    rx_state <= RX_IDLE; //If start bit is high then stays at the IDLE state
                end
            end

            RX_START: begin
                if(rx_clk_count == BIT_PERIOD/2)begin //Counts until 16/2 = 7 to check the middle of the oversampled bit
                    if(i_data == 1'b0) begin // Check in the middle of the start bit to verify still it is low.
                        rx_state <= RX_DATA;
                        rx_clk_count <= 1'b0;
                    end

                    else begin
                        rx_state <= RX_IDLE; //False start bit
                    end
                end

                else begin
                    rx_state <= RX_START;
                    rx_clk_count <= rx_clk_count + 1;
                end
            end

            RX_DATA: begin
                if(rx_clk_count < (BIT_PERIOD)) begin 
                    rx_state <= RX_DATA;
                    rx_clk_count <= rx_clk_count + 1; //Until the clock reaches RX_OVERSAMPLE time it waits and cont. counting
                end

                else begin
                    rx_data[rx_bit_index] <= i_data; //At the middle of the bit period it samples and stores input bits in rx_data(RX_OVERSAMPLE time after middle of the Start bit)
                    rx_clk_count <= 1'b0;
                        if(rx_bit_index < 7 ) begin //Final iteration in this line bit_index = 6, therefore this line is true
                            rx_bit_index <= rx_bit_index + 1; //Sample all 8 bits, after the index is 6+1=7 after this line final data bit is sampled.
                            rx_state <= RX_DATA;
                        end

                        else begin
                            rx_bit_index <= 0;
                            rx_state <= RX_STOP; //Goes to STOP state 
                        end    
                end
            end

            RX_STOP: begin
                if(rx_clk_count < (BIT_PERIOD))begin
                    rx_state <= RX_STOP;
                    rx_clk_count <= rx_clk_count + 1;
                end

                else begin
                    rx_state <= RX_IDLE;
                    rx_clk_count <= 1'b0;
                    rx_done <= 1'b1;
                end
            end

            default: begin
                rx_state <= RX_IDLE;
            end
        endcase
    end
end

assign o_done = rx_done; //Tells the outside world when a byte has been received.
assign o_byte = rx_done ? rx_data : 8'h00; //gives the received byte, but only if o_done is true

endmodule
