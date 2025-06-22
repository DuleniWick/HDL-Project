module TxController(
input system_clk,
input system_reset_n,
input [7:0] tx_data_byte,
input tx_start_signal,
output tx_complete_flag,
output tx_busy_flag,
output tx_serial_data
);

localparam TX_STATE_IDLE = 3'b000;
localparam TX_STATE_START_BIT = 3'b001;
localparam TX_STATE_DATA_BITS = 3'b010;
localparam TX_STATE_STOP_BIT = 3'b011;

reg [2:0] data_bit_counter;
reg       tx_complete_reg;
reg       tx_data_reg;
reg [2:0] tx_state_machine;
reg       tx_busy_reg;

// UART TX Logic Implementation

always @(posedge system_clk or negedge system_reset_n) begin
    if(!system_reset_n) begin
        tx_state_machine <= TX_STATE_IDLE;
        data_bit_counter <= 0;
        tx_complete_reg <= 1'b0;
        tx_data_reg <= 1'b1;
        tx_busy_reg <= 1'b0;
    end
    else begin
        case(tx_state_machine)
        TX_STATE_IDLE: begin
            data_bit_counter <= 0;
            tx_complete_reg <= 1'b0;
            tx_data_reg <= 1'b1;
            if(tx_start_signal == 1'b1) //this is just a signal to indicate to start transmitting
            begin
                tx_state_machine <= TX_STATE_START_BIT;
                tx_busy_reg <= 1'b1;
            end
            else begin
                tx_state_machine <= TX_STATE_IDLE;
            end
        end

        TX_STATE_START_BIT: begin
            tx_data_reg <= 1'b0;
            tx_state_machine <= TX_STATE_DATA_BITS;
        end

        TX_STATE_DATA_BITS: begin
            tx_data_reg <= tx_data_byte[data_bit_counter];
            if (data_bit_counter < 7) begin
                data_bit_counter <= data_bit_counter + 1;
                tx_state_machine <= TX_STATE_DATA_BITS;
            end
            else begin
                data_bit_counter <= 0;
                tx_state_machine <= TX_STATE_STOP_BIT;
            end
        end

        TX_STATE_STOP_BIT: begin
            tx_state_machine <= TX_STATE_IDLE;
            tx_complete_reg <= 1'b1;
            tx_busy_reg <= 1'b0;
            tx_data_reg <= 1'b1;
        end

        default: begin
            tx_state_machine <= TX_STATE_IDLE;
        end
    endcase
    end
end

assign tx_complete_flag = tx_complete_reg;
assign tx_serial_data = tx_data_reg;
assign tx_busy_flag = tx_busy_reg;

endmodule
