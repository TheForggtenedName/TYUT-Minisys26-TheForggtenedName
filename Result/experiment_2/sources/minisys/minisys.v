`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module minisys (
    input			fpga_rst,	        // board reset, active high
    input			fpga_clk,	        // board 100MHz clock
    input	[23:0]	switch2N4,	        // switch input
    output	[23:0]	led2N4,		        // LED output
    // UART Programmer Pinouts
    input           start_pg,           // S3 button for programming start
    input           rx,                 // UART receive
    output          tx                  // UART transmit
);

    wire clock;				            // divided clock for CPU
    wire iowrite,ioread;	            // I/O read/write signals
    wire memread;                       // memory read signal
    wire [31:0] write_data;	            // write data to RAM or I/O
    wire [31:0] rdata;		            // read data from RAM or I/O
    wire [15:0] ioread_data;	        // I/O read data
    wire [15:0] ioread_data_digitube;  // digital tube read data
    wire [31:0] pc_plus_4;	            // PC+4
    wire [31:0] read_data_1;
    wire [31:0] read_data_2;
    wire [31:0] sign_extend;	        // sign-extended immediate
    wire [31:0] add_result;
    wire [31:0] alu_result;
    wire [31:0] read_data;	            // data read from RAM
    wire [31:0] address;
    wire alusrc;
    wire branch;
    wire nbranch,jmp,jal,jrn,i_format;
    wire regdst;
    wire regwrite;
    wire zero;
    wire memwrite;
    wire memoriotoreg;
    wire memreg;
    wire sftmd;
    wire[1:0] aluop;
    wire[31:0] instruction;
    wire[31:0] opcplus4;
    wire [13:0] rom_adr;
    wire [31:0] rom_dat;
    wire ledctrl,switchctrl,digituberead;
    wire[15:0] ioread_data_switch;
    wire rst;
    // Digital tube outputs
    wire [7:0] tube_sel;
    wire [1:0] tube_digit_sel;
    // UART Programmer Pinouts
    wire upg_clk, upg_clk_o, upg_wen_o, upg_done_o;
    wire [14:0] upg_adr_o;
    wire [31:0] upg_dat_o;

    wire spg_bufg;
    BUFG U1(.I(start_pg), .O(spg_bufg));

    // Generate UART Programmer reset signal
    reg upg_rst;
    always @ (posedge fpga_clk) begin
        if (spg_bufg)	upg_rst = 0;
        if (fpga_rst)	upg_rst = 1;
    end

    assign rst = fpga_rst | !upg_rst;

    cpuclk cpuclk (
        .clk_in1	(fpga_clk),	    // 100MHz input
        .clk_out1	(clock),    	// CPU Clock (23MHz)
        .clk_out2	(upg_clk)		// UPG Clock (10MHz)
    );

    upg uartpg (
        .upg_clk_i	(upg_clk),
        .upg_rst_i	(upg_rst),
        .upg_clk_o	(upg_clk_o),
        .upg_wen_o	(upg_wen_o),
        .upg_adr_o	(upg_adr_o),
        .upg_dat_o	(upg_dat_o),
        .upg_done_o	(upg_done_o),
        .upg_rx_i	(rx),
        .upg_tx_o	(tx)
    );

    programrom ROM (
        .rom_clk_i	(clock),
        .rom_adr_i	(rom_adr),
        .Jpadr		(rom_dat),
        .upg_rst_i	(upg_rst),
        .upg_clk_i	(upg_clk_o),
        .upg_wen_i	(upg_wen_o & !upg_adr_o[14]),
        .upg_adr_i	(upg_adr_o[13:0]),
        .upg_dat_i	(upg_dat_o),
        .upg_done_i	(upg_done_o)
    );

    Ifetc32 ifetch(
        .Instruction	(instruction),
        .PC_plus_4_out	(pc_plus_4),
        .reset			(rst),
        .clock			(clock),
        .Add_result		(add_result),
        .Read_data_1	(read_data_1),
        .Branch			(branch),
        .nBranch		(nbranch),
        .Jmp			(jmp),
        .Jal			(jal),
        .Jrn			(jrn),
        .Zero			(zero),
        .opcplus4		(opcplus4),
        .rom_adr_o		(rom_adr),
        .Jpadr			(rom_dat)
    );

    Idecode32 idecode(
        .read_data_1	(read_data_1),
        .read_data_2	(read_data_2),
        .reset			(rst),
        .clock			(clock),
        .Instruction	(instruction),
        .read_data		(rdata),
        .ALU_result		(alu_result),
        .Jal			(jal),
        .RegWrite		(regwrite),
        .MemtoReg		(memreg),
        .RegDst			(regdst),
        .Sign_extend	(sign_extend),
        .opcplus4		(opcplus4)
    );

    controlIO32 control(
        .Opcode			(instruction[31:26]),
        .Function_opcode(instruction[5:0]),
        .Alu_resultHigh	(alu_result[31:10]),
        .Jrn			(jrn),
        .RegDST			(regdst),
        .ALUSrc			(alusrc),
        .MemorIOtoReg	(memreg),
        .RegWrite		(regwrite),
        .MemWrite		(memwrite),
        .MemRead		(memread),
        .IORead			(ioread),
        .IOWrite		(iowrite),
        .Branch			(branch),
        .nBranch		(nbranch),
        .Jmp			(jmp),
        .Jal			(jal),
        .I_format		(i_format),
        .Sftmd			(sftmd),
        .ALUOp			(aluop)
    );

    Executs32 execute(
        .Read_data_1	(read_data_1),
        .Read_data_2	(read_data_2),
        .Sign_extend	(sign_extend),
        .Function_opcode(instruction[5:0]),
        .Exe_opcode		(instruction[31:26]),
        .ALUOp			(aluop),
        .Shamt			(instruction[10:6]),
        .Sftmd			(sftmd),
        .ALUSrc			(alusrc),
        .I_format		(i_format),
        .Jrn			(jrn),
        .Zero			(zero),
        .ALU_Result		(alu_result),
        .Add_Result		(add_result),
        .PC_plus_4		(pc_plus_4)
    );

    dmemory32 memory (
        .ram_clk_i	(clock),
        .ram_wen_i	(memwrite),
        .ram_adr_i	(address[15:2]),
        .ram_dat_i	(write_data),
        .ram_dat_o	(read_data),
        .upg_rst_i	(upg_rst),
        .upg_clk_i	(upg_clk_o),
        .upg_wen_i	(upg_wen_o & upg_adr_o[14]),
        .upg_adr_i	(upg_adr_o[13:0]),
        .upg_dat_i	(upg_dat_o),
        .upg_done_i	(upg_done_o)
    );

    memorio memio(
        .caddress		(alu_result),
        .address		(address),
        .memread		(memread),
        .memwrite		(memwrite),
        .ioread			(ioread),
        .iowrite		(iowrite),
        .mread_data		(read_data),
        .ioread_data	(ioread_data),
        .wdata			(read_data_2),
        .rdata			(rdata),
        .write_data		(write_data),
        .LEDCtrl		(ledctrl),
        .SwitchCtrl		(switchctrl),
        .DigitubeCtrl	(digituberead)
    );

    ioread multiioread(
        .reset				(rst),
        .ior				(ioread),
        .switchctrl			(switchctrl),
        .digituberead		(digituberead),
        .ioread_data		(ioread_data),
        .ioread_data_switch	(ioread_data_switch),
        .ioread_data_digitube	(ioread_data_digitube)
    );

    leds led24(
        .ledrst		(rst),
        .led_clk	(clock),
        .ledwrite	(iowrite),
        .ledcs		(ledctrl),
        .ledaddr	(alu_result[3:2]),
        .ledwdata	(write_data[15:0]),
        .ledout		(led2N4)
    );

    switchs switch24(
        .switrst		(rst),
        .switclk		(clock),
        .switchcs		(switchctrl),
        .switchaddr		(alu_result[3:2]),
        .switchread		(ioread),
        .switchrdata	(ioread_data_switch),
        .switch_i		(switch2N4)
    );

    digitube tube(
        .tube_clk		(clock),
        .tube_rst		(rst),
        .tube_write		(iowrite),
        .tube_cs		(digituberead),
        .tube_addr		(alu_result[2:0]),
        .tube_wdata		(write_data[15:0]),
        .tube_sel		(tube_sel),
        .tube_digit_sel	(tube_digit_sel)
    );

    // Placeholder: ioread_data_digitube (can be expanded to read display state)
    assign ioread_data_digitube = 16'h0000;

endmodule
