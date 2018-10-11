module SegmentHexEncoder(
	input wire [3:0] number,	// Binary number
	output reg [7:0] encoded	// Encoded hex output
);
always @*
	case(number)
		0: encoded <= 8'hC0;
		1: encoded <= 8'hF9;
		2: encoded <= 8'hA4;
		3: encoded <= 8'hB0;
		4: encoded <= 8'h99;
		5: encoded <= 8'h92;
		6: encoded <= 8'h82;
		7: encoded <= 8'hF8;
		8: encoded <= 8'h80;
		9: encoded <= 8'h98;
		10: encoded <= 8'h88;
		11: encoded <= 8'h83;
		12: encoded <= 8'hC6;
		13: encoded <= 8'hA1;
		14: encoded <= 8'h86;
		default: encoded <= 8'h8E;
	endcase
endmodule
