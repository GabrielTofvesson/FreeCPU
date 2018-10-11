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
	input wire [WIRE_SIZE-1:0] a,
	input wire [WIRE_SIZE-1:0] b,
	output wire [WIRE_SIZE-1:0] out,
	output wire c_out
);

parameter WIRE_SIZE;

genvar i;
generate
	for(i=0; i<WIRE_SIZE; i = i + 1) begin
		
	end
endgenerate

endmodule
