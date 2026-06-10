`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module switchs (
    input			switrst,		// reset
    input			switclk,		// clock
    input			switchcs,		// chip select from memorio
    input	[1:0]	switchaddr,		// switch address offset
    input			switchread,		// read enable
    output	[15:0]	switchrdata,	// switch data to CPU (16-bit)
    input	[23:0]	switch_i		// 24-bit switch input from board
);

    reg [15:0] switchrdata;

    always@(negedge switclk or posedge switrst) begin
        if (switrst == 1'b1)
            switchrdata <= 16'h0000;
        else if (switchcs == 1'b1 && switchread == 1'b1) begin
            case (switchaddr)
                2'b00: switchrdata <= switch_i[15:0];
                2'b01: switchrdata <= {8'b00000000, switch_i[23:16]};
                default: switchrdata <= 16'h0000;
            endcase
        end
    end
endmodule
