`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// Changed

module Idecode32 (
	input			reset,
    input			clock,
    output	[31:0]	read_data_1,	// first operand
    output	[31:0]	read_data_2,	// second operand
    input	[31:0]	Instruction,	// from ifetc32.v
    input	[31:0]	read_data,		// from DATA RAM or I/O port
    input	[31:0]	ALU_result,		// from executs.v
    input			Jal,			// from control32.v
    input			RegWrite,		// from control32.v
    input			MemtoReg,		// from control32.v
    input			RegDst,			// from control32.v
    output	[31:0]	Sign_extend,	// the 32-bit extended immediate value output from the idecode.v
    input	[31:0]	opcplus4		// from ifetc32.v, used by Jal
);
    
    reg[31:0] register[0:31];			   // register file
    reg[4:0] write_register_address;        // written register number
    reg[31:0] write_data;                   // data for written register

    wire[4:0] read_register_1_address;    // first read register number
    wire[4:0] read_register_2_address;     // second read register number
    wire[4:0] write_register_address_1;   // r-form written register number
    wire[4:0] write_register_address_0;    // i-form written register number
    wire[15:0] Instruction_immediate_value;  // immediate value in Instruction
    wire[5:0] opcode;                       // operation code
    
    // TODO begin decomposition
    assign opcode = Instruction[31:26];	//OP
    assign read_register_1_address = Instruction[25:21];    //rs
    assign read_register_2_address = Instruction[20:16];	//rt
    assign write_register_address_1 = Instruction[15:11];	// rd(r-form)
    assign write_register_address_0 = Instruction[20:16];	//rt(i-form)
    assign Instruction_immediate_value = Instruction[15:0];	//data,rladr(i-form)
    // TODO end

    // TODO begin sign extend
    wire sign;
    assign sign = Instruction[15]; // sign of immediate value
    assign Sign_extend[31:0] = {{16{sign}}, Instruction_immediate_value};
    // TODO end
    
    // TODO begin read data
    assign read_data_1 = register[read_register_1_address];
    assign read_data_2 = register[read_register_2_address];
    // TODO end
     
    // TODO begin write register
    // changed begin implemant the destination register for Jal
    always @* begin
        if (Jal == 1'b1)
            write_register_address = 5'd31;   // ra
        else if (RegDst == 1'b1)
            write_register_address = write_register_address_1;
        else
            write_register_address = write_register_address_0;
    end
    // changed end
    
    always @* begin
        if (Jal == 1'b1)
            write_data = opcplus4;
        else if (MemtoReg == 1'b1)
            write_data = read_data;
        else
            write_data = ALU_result;
    end
    // TODO end
    
    // TODO begin write register
    integer i;
    always @(posedge clock) begin       // write register
        if(reset==1) begin              // register initialization during reset
            for(i=0;i<32;i=i+1) register[i] <= 0;
        end else if(RegWrite==1) begin
            if (write_register_address != 5'b00000) // register 0 cannot be written
                register[write_register_address] <= write_data;
        end
    end
    // TODO end
    
endmodule
