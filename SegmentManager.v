module SegmentManager(
	input wire clk,						// 50MHz clock signal
	input wire [7:0] segment_data0,	// Segment data for segment 0 (D1)
	input wire [7:0] segment_data1,	// Segment data for segment 1 (D2)
	input wire [7:0] segment_data2,	// Segment data for segment 2 (D3)
	input wire [7:0] segment_data3,	// Segment data for segment 3 (D4)
	output reg [3:0] segment_select,	// 7-segment display selector
	output reg [7:0] segments			// Segment display bus
);

initial segment_select = 4'b1110;

reg [1:0] seg_sel_track;	// Active display tracker

wire clk_graphics;			// Internal clock divider output

// Clock division circuit
Divider #(.divideby(25000), .divide_reg_size(17)) divider_audio(clk, clk_graphics);	// Frequency: 50MHz/25k = 2kHz	TriggerType: Pulse

// Change the active segment data
always @(posedge clk_graphics) begin
	segment_select <=(segment_select << 1) | segment_select[3];
	seg_sel_track <= seg_sel_track + 1'b1;
end

// Assign the active segment data to the segment bus
always @*
	case(seg_sel_track)
		0: 		segments <= segment_data0;
		1: 		segments <= segment_data1;
		2: 		segments <= segment_data2;
		default: segments <= segment_data3;
	endcase
endmodule
