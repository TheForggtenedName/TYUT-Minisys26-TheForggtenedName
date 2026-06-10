`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module leds (
    input			ledrst,		// reset
    input			led_clk,	// clock
    input			ledwrite,	// write enable
    input			ledcs,		// chip select from memorio
    input	[1:0]	ledaddr,	// LED address offset
    input	[15:0]	ledwdata,	// write data (16-bit)
    output	[23:0]	ledout		// 24-bit LED output
);

    reg [23:0] ledout;

    always@(posedge led_clk or posedge ledrst) begin
        if (ledrst == 1'b1)
            ledout <= 24'h000000;
        else if (ledcs == 1'b1 && ledwrite == 1'b1) begin
            case (ledaddr)
                2'b00: ledout[15:0]  <= ledwdata;
                2'b01: ledout[23:16] <= ledwdata[7:0];
                default: ;
            endcase
        end
    end
endmodule
