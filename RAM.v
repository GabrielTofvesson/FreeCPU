module RAM(
	input wire clk,
	output wire [10:0] RAM_addr,		// RAM address buffer
	output wire RAM_A10,
	output wire [1:0] RAM_bank_sel,	// RAM bank selection
	inout wire [15:0] RAM_data,		// RAM data bus
	output wire RAM_clk,					// RAM clock signal
	output wire RAM_clk_enable,		// RAM enable clock
	output wire RAM_enable,				// RAM chip enable
	output wire RAM_strobe_row,		// RAM row strobe
	output wire RAM_strobe_col,		// RAM column strobe
	output wire RAM_write_enable,		// RAM data bus write enable
	input wire read_rq,					// Read request (Internal)
	input wire write_rq,					// Write request (Internal)
	output reg [3:0] RAM_state,		// State information (Internal)
	output wire op_trigger				// Event trigger wire
);

always @(posedge clk) begin
	
end

endmodule
