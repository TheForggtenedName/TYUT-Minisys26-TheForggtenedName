`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// I/O Read Multiplexer
// Experiment 2: Supports reading from multiple I/O devices (Switch, Digital Tube)

module ioread (
    input			reset,					// reset signal
    input			ior,					// read signal from control
    input			switchctrl,				// switch chip select from memorio
    input			digituberead,			// digital tube read request from memorio
    input	[15:0]	ioread_data_switch,		// switch input data
    input	[15:0]	ioread_data_digitube,	// digital tube display data
    output	[15:0]	ioread_data				// I/O read data multiplexer output
);
    
    reg[15:0] ioread_data;
    
    always @* begin
        if(reset == 1)
            ioread_data = 16'b0000000000000000;
        else if(ior == 1) begin
            if(switchctrl == 1)
                ioread_data = ioread_data_switch;
            else if(digituberead == 1)
                ioread_data = ioread_data_digitube;
            else   
                ioread_data = 16'h0000;
        end
        else
            ioread_data = 16'h0000;
    end
endmodule
