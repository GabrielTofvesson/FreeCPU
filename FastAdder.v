module FastAdder4(
	input wire c_in,
	input wire [3:0] a,
	input wire [3:0] b,
	output wire [3:0] out,
	output wire c_out
);

wire [3:0] gen = a & b; // Generator
wire [3:0] prp = a ^ b;	// Propogator

assign out = a ^ b ^ {
	gen[2] | (prp[2] & gen[1]) | (prp[2] & prp[1] & gen[0]) | (prp[2] & prp[1] & prp[0] & c_in),	// Carry 2
	gen[1] | (prp[1] & gen[0]) | (prp[1] & prp[0] & c_in),													// Carry 1
	gen[0] | (prp[0] & c_in),																							// Carry 0
	c_in																														// Carry -1 (in)
};
assign c_out = gen[3] | (prp[3] & gen[2]) | (prp[3] & prp[2] & gen[1]) | (prp[3] & prp[2] & prp[1] & gen[0]) | (prp[3] & prp[2] & prp[1] & prp[0] & c_in);
endmodule

module FastAdder8(
	input wire c_in,
	input wire [7:0] a,
	input wire [7:0] b,
	output wire [7:0] out,
	output wire c_out
);

wire [7:0] gen = a & b; // Generator
wire [7:0] prp = a ^ b;	// Propogator

assign out = a ^ b ^ {
	gen[2] | (prp[2] & gen[1]) | (prp[2] & prp[1] & gen[0]) | (prp[2] & prp[1] & prp[0] & c_in),	// Carry 2
	gen[1] | (prp[1] & gen[0]) | (prp[1] & prp[0] & c_in),													// Carry 1
	gen[0] | (prp[0] & c_in),																							// Carry 0
	c_in																														// Carry -1 (in)
};
assign c_out = gen[3] | (prp[3] & gen[2]) | (prp[3] & prp[2] & gen[1]) | (prp[3] & prp[2] & prp[1] & gen[0]) | (prp[3] & prp[2] & prp[1] & prp[0] & c_in);

endmodule

module FastAdder2(
        input wire cin,
        input wire [1:0] a,
        input wire [1:0] b,
        output wire [1:0] out,
        output wire cout
);
wire [1:0] g = a & b;
wire [1:0] p = a ^ b;
assign out = a ^ b ^ {
        (g[0]) | (p[0] & cin),
        (cin)
};
assign cout = (g[1]) | (p[1] & g[0]) | (p[1] & p[0] & cin);
endmodule