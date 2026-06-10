`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Executs32 (
    input	[31:0]	Read_data_1,		// from idecode32 Read_data_1
    input	[31:0]	Read_data_2,		// from idecode32 Read_data_2
    input	[31:0]	Sign_extend,		// from idecode32 sign-extended immediate
    input	[5:0]	Function_opcode,	// from ifetc32 r-type function code, r-form instructions[5:0]
    input	[5:0]	Exe_opcode,			// from ifetc32 opcode
    input	[1:0]	ALUOp,				// from control32 ALU control code
    input	[4:0]	Shamt,				// from ifetc32 instruction[10:6], shift amount
    input			Sftmd,				// from control32, shift instruction flag
    input			ALUSrc,				// from control32, second operand is immediate (except beq,bne)
    input			I_format,			// from control32, I-type except beq,bne,LW,SW
    input			Jrn,				// from control32, JR instruction flag
    output			Zero,				// 1: ALU result is zero
    output	[31:0]	ALU_Result,			// ALU computation result
    output	[31:0]	Add_Result,			// branch target address
    input	[31:0]	PC_plus_4			// from ifetc32 PC+4
);

    reg[31:0] ALU_Result;
    wire[31:0] Ainput,Binput;
    reg[31:0] Cinput,Dinput;
    reg[31:0] Einput,Finput;
    reg[31:0] Ginput,Hinput;
    reg[31:0] Sinput;
    reg[31:0] ALU_output_mux;
    wire[2:0] ALU_ctl;
    wire[5:0] Exe_code;
    wire[2:0] Sftm;

    assign Sftm = Function_opcode[2:0];
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Exe_opcode[2:0]};
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0];
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];

    always @* begin
        if(Sftmd)
            case(Sftm[2:0])
                3'b000:  Sinput = Binput << Shamt;           // SLL  rd,rt,shamt
                3'b010:  Sinput = Binput >> Shamt;           // SRL  rd,rt,shamt
                3'b100:  Sinput = Binput << Ainput[4:0];     // SLLV rd,rt,rs
                3'b110:  Sinput = Binput >> Ainput[4:0];     // SRLV rd,rt,rs
                3'b011:  Sinput = $signed(Binput) >>> Shamt; // SRA  rd,rt,shamt
                3'b111:  Sinput = $signed(Binput) >>> Ainput[4:0]; // SRAV rd,rt,rs
                default: Sinput = Binput;
            endcase
        else Sinput = Binput;
    end

    always @* begin
        if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1)))
            ALU_Result = ($signed(Ainput) < $signed(Binput)) ? 32'd1 : 32'd0; // SLT/SLTI
        else if((ALU_ctl==3'b101) && (I_format==1))
            ALU_Result = {Binput[15:0], 16'b0};     // LUI
        else if(Sftmd==1)
            ALU_Result = Sinput;                    // shift result
        else
            ALU_Result = ALU_output_mux[31:0];      // otherwise
    end

    assign Add_Result = PC_plus_4 + {Sign_extend[29:0],2'b00};

    assign Zero = (ALU_output_mux[31:0] == 32'h00000000) ? 1'b1 : 1'b0;

    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000: ALU_output_mux = Ainput & Binput;       // AND
            3'b001: ALU_output_mux = Ainput | Binput;       // OR
            3'b010: ALU_output_mux = Ainput + Binput;       // ADD/ADDI
            3'b011: ALU_output_mux = Ainput + Binput;       // ADDU (unsigned add)
            3'b100: ALU_output_mux = Ainput ^ Binput;       // XOR
            3'b101: ALU_output_mux = ~(Ainput | Binput);    // NOR
            3'b110: ALU_output_mux = Ainput - Binput;       // SUB
            3'b111: ALU_output_mux = Ainput - Binput;       // SUBU (unsigned sub)
            default: ALU_output_mux = 32'h00000000;
        endcase
    end
endmodule
