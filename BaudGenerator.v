module BaudGenerator #(
    parameter Clk_Rate = 25000000,
    parameter Baud_Rate = 115200,
    parameter RX_OVERSAMPLE = 16
)(
    input wire clk,
    input reset_n, //active low reset(when reset_n=0 then the system resets)

    output reg Rx_Clk,
    output reg Tx_Clk

);

parameter Tx_Count = Clk_Rate/(2*Baud_Rate);
parameter Rx_Count = Clk_Rate/(2*Baud_Rate*RX_OVERSAMPLE);
parameter Tx_Count_Width = $clog2(Tx_Count);
parameter Rx_Count_Width = $clog2(Rx_Count);

reg [Tx_Count_Width - 1:0]Tx_Counter;
reg [Rx_Count_Width - 1:0]Rx_Counter;

//Rx Baud Rate
always @(posedge clk or negedge reset_n)begin
    if(~reset_n) begin
        Rx_Clk <= 1'b0;
        Rx_Counter <= 0;

    end

    else if(Rx_Counter == Rx_Count - 1)begin
        Rx_Clk <= ~Rx_Clk;
        Rx_Counter <= 0;

    end

    else begin
        Rx_Counter <= Rx_Counter + 1;
    end
end

//Tx Baud Rate
always @(posedge clk or negedge reset_n)begin
    if(~reset_n) begin
        Tx_Clk <= 1'b0;
        Tx_Counter <= 0;

    end

    else if(Tx_Counter == Tx_Count - 1)begin
        Tx_Clk <= ~Tx_Clk;
        Tx_Counter <= 0;

    end

    else begin
        Tx_Counter <= Tx_Counter + 1;
    end
end

endmodule