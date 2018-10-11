module VDivider(
	input wire clk,		// Clock input
	input wire [divide_reg_size-1:0] compare_to,
	output wire divided	// Divided output
);

// Parameters for division circuit
parameter divide_reg_size;
parameter pulsemode = 1;

reg [divide_reg_size-1:0] div;	// Division counter
reg div_int;							// Internal division result state

assign divided = div_int;			// Assign internal result state to external output

// Division
always @ (posedge clk) begin
	if(div >= compare_to) begin
		div_int <= pulsemode ? 1 : ~div_int;
		div <= 0;
	end else begin
		if(pulsemode) div_int <= 0;
		div <= div + 1;
	end
end

endmodule
