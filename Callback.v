module Callback(
	input wire clk,
	input wire [ISIZE-1:0] countdown,
	input wire reset,
	output wire callback
);

parameter ISIZE;

reg [ISIZE-1:0] counter;
reg [1:0] ctr_trigger = 2'b10;

assign callback = !counter & ctr_trigger;

always @(posedge clk or posedge reset) begin
	if(reset) begin
		counter <= countdown;
		ctr_trigger <= 2'b10;
	end
	else if(counter) counter <= counter - 1'b1;
	else if(ctr_trigger) ctr_trigger = ctr_trigger - 2'b01; // pull trigger high for 2 clock cycles to correct for 2.5ns pulse issues
end

endmodule
