module Divider(
	input wire clk,		// Clock input
	output wire divided	// Divided output
);

// Parameters for division circuit
parameter divideby = 1;
parameter divide_reg_size;
parameter pulsemode = 1;

reg [divide_reg_size-1:0] div;	// Division counter
reg div_int;							// Internal division result state

assign divided = div_int;			// Assign internal result state to external output

// Division
always @ (posedge clk) begin
	if(div == divideby) begin
		div_int <= pulsemode ? 1'b1 : ~div_int;
		div <= 0;
	end else begin
		if(pulsemode) div_int <= 0;
		div <= div + 1'b1;
	end
end

endmodule
