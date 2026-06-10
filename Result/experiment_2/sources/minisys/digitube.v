`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Digital Tube (Seven-Segment Display) Driver
// Experiment 2: Supports two 4-bit 7-segment displays
// Base address: 0xFFFFFC80
// Implements dynamic scanning for display

module digitube (
    input				tube_clk,		// system clock
    input				tube_rst,		// reset signal (active high)
    input				tube_write,		// write enable from CPU
    input				tube_cs,		// chip select for digital tube from memorio
    input	[2:0]		tube_addr,		// address offset for different write registers
    input	[15:0]		tube_wdata,		// write data (16-bit)
    output	[7:0]		tube_sel,		// segment select (a-g and decimal point) for current digit
    output	[1:0]		tube_digit_sel	// digit select (which of 2 digits is active)
);

    // 7-segment encoding for digits 0-9, A-F
    // bit order: [dp, g, f, e, d, c, b, a] (active high)
    reg [7:0] seg_code [15:0];
    
    // Internal registers for tube display data
    reg [3:0] digit_data_0;  // Digit 0 (low nibble)
    reg [3:0] digit_data_1;  // Digit 1 (high nibble)
    
    // Dynamic scanning control
    reg [19:0] scan_counter;
    wire [1:0] scan_sel;
    
    // Display multiplexer
    reg [3:0] current_digit;
    reg [7:0] current_seg;
    
    // 7-segment code table (active high)
    // Segments: a=bit0, b=bit1, c=bit2, d=bit3, e=bit4, f=bit5, g=bit6, dp=bit7
    initial begin
        seg_code[4'h0] = 8'b00111111;  // 0: abcdef
        seg_code[4'h1] = 8'b00000110;  // 1: bc
        seg_code[4'h2] = 8'b01011011;  // 2: abdeg
        seg_code[4'h3] = 8'b01001111;  // 3: abcdg
        seg_code[4'h4] = 8'b01100110;  // 4: bcfg
        seg_code[4'h5] = 8'b01101101;  // 5: acdfg
        seg_code[4'h6] = 8'b01111101;  // 6: acdefg
        seg_code[4'h7] = 8'b00000111;  // 7: abc
        seg_code[4'h8] = 8'b01111111;  // 8: abcdefg
        seg_code[4'h9] = 8'b01101111;  // 9: abcdfg
        seg_code[4'hA] = 8'b01110111;  // A: abcefg
        seg_code[4'hB] = 8'b01111100;  // B: cdefg
        seg_code[4'hC] = 8'b00111001;  // C: adef
        seg_code[4'hD] = 8'b01011110;  // D: bcdeg
        seg_code[4'hE] = 8'b01111001;  // E: adefg
        seg_code[4'hF] = 8'b01110001;  // F: aefg
    end

    // Write operation: store digit data
    always @(posedge tube_clk or posedge tube_rst) begin
        if (tube_rst == 1'b1) begin
            digit_data_0 <= 4'h0;
            digit_data_1 <= 4'h0;
        end else if (tube_cs == 1'b1 && tube_write == 1'b1) begin
            case (tube_addr)
                3'b000: digit_data_0 <= tube_wdata[3:0];    // Write low digit
                3'b001: digit_data_1 <= tube_wdata[3:0];    // Write high digit
                3'b010: begin
                    digit_data_0 <= tube_wdata[3:0];
                    digit_data_1 <= tube_wdata[7:4];
                end
                default: ;
            endcase
        end
    end

    // Dynamic scanning counter for multiplexing
    always @(posedge tube_clk or posedge tube_rst) begin
        if (tube_rst == 1'b1)
            scan_counter <= 20'h00000;
        else
            scan_counter <= scan_counter + 1'b1;
    end

    // Select scanning digit (approximately every 1ms)
    assign scan_sel = scan_counter[19:18];

    // Output multiplexer for current digit and segments
    always @* begin
        case (scan_sel)
            2'b00: begin
                current_digit <= digit_data_0;
                tube_digit_sel <= 2'b01;  // Select digit 0
            end
            2'b01: begin
                current_digit <= digit_data_1;
                tube_digit_sel <= 2'b10;  // Select digit 1
            end
            default: begin
                current_digit <= 4'h0;
                tube_digit_sel <= 2'b00;
            end
        endcase
    end

    // Convert digit to 7-segment code
    assign tube_sel = seg_code[current_digit];

endmodule
