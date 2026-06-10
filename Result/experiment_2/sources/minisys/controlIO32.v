`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Experiment 2: Extended control unit with I/O addressing support
// Adds MemRead, IORead, IOWrite signals for I/O interface
// Distinguishes between RAM and I/O based on address high bits

module controlIO32 (
    input	[5:0]   Opcode,				// from ifetc32 instruction[31..26]
    input	[5:0]   Function_opcode,	// from ifetc32 r-type instructions[5..0]
    input	[21:0]	Alu_resultHigh,		// address bits[31:10] to distinguish RAM/IO
    output			Jrn,				// 1: jr instruction
    output			RegDST,				// 1: dest reg is rd, 0: dest reg is rt
    output			ALUSrc,				// 1: second operand is immediate (except beq,bne)
    output			MemorIOtoReg,		// 1: data from memory or IO to register
    output			RegWrite,			// 1: write to register (excluding JR)
    output			MemWrite,			// 1: write to memory
    output			MemRead,			// 1: read from memory
    output			IORead,				// 1: read from IO
    output			IOWrite,			// 1: write to IO
    output			Branch,				// 1: beq instruction
    output			nBranch,			// 1: bne instruction
    output			Jmp,				// 1: j instruction
    output			Jal,				// 1: jal instruction
    output			I_format,			// 1: I-type except beq,bne,LW,SW
    output			Sftmd,				// 1: shift instruction
    output	[1:0]	ALUOp				// bit1: R-type or I_format, bit0: beq or bne
);

    wire R_format;		// 1: R-type instruction
    wire Lw;			// 1: lw instruction
    wire Sw;			// 1: sw instruction
    wire Is_IO_Access;	// 1: address is in I/O range (0xFFFFFC00-0xFFFFFC7F)

    // Address decoding: I/O range is 0xFFFFFC00-0xFFFFFC7F
    // In 32-bit address, this corresponds to bits[31:10] = 22'hFFFFF
    // and bits[9:7] = 3'b110
    assign Is_IO_Access = (Alu_resultHigh[21:0] == 22'b1111111111111111111111) ? 1'b1 : 1'b0;

    assign R_format = (Opcode == 6'b000000) ? 1'b1 : 1'b0;
    assign RegDST = R_format;

    assign I_format = (Opcode[5:3] == 3'b001) ? 1'b1 : 1'b0;
    assign Lw = (Opcode == 6'b100011) ? 1'b1 : 1'b0;
    assign Jal = (Opcode == 6'b000011) ? 1'b1 : 1'b0;
    assign Jrn = (R_format && Function_opcode == 6'b001000) ? 1'b1 : 1'b0;
    
    // RegWrite: exclude JR instruction
    assign RegWrite = ((R_format || I_format || Lw || Jal) && !Jrn) ? 1'b1 : 1'b0;

    assign Sw = (Opcode == 6'b101011) ? 1'b1 : 1'b0;
    assign ALUSrc = (I_format || Lw || Sw) ? 1'b1 : 1'b0;
    assign Branch = (Opcode == 6'b000100) ? 1'b1 : 1'b0;
    assign nBranch = (Opcode == 6'b000101) ? 1'b1 : 1'b0;
    assign Jmp = (Opcode == 6'b000010) ? 1'b1 : 1'b0;

    // I/O control signals
    assign MemWrite = Sw && !Is_IO_Access;	// Only write to memory if address is not I/O
    assign IOWrite = Sw && Is_IO_Access;	// Write to I/O if address is in I/O range
    assign MemRead = Lw && !Is_IO_Access;	// Read from memory if address is not I/O
    assign IORead = Lw && Is_IO_Access;		// Read from I/O if address is in I/O range

    assign MemorIOtoReg = Lw;				// Data from memory or IO to register
    assign Sftmd = (R_format && Function_opcode[5:3] == 3'b000) ? 1'b1 : 1'b0;

    assign ALUOp = {(R_format || I_format),(Branch || nBranch)};
endmodule
