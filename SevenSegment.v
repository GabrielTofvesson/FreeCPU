module SevenSegment (
	input wire latch, 					// S4
	input wire next,						// S2
	input wire value,						// S3
	output reg [3:0] select_out, 		// LED1-LED4 [0-3]
	input wire write,						// S1
	input wire clk,						// 50MHz clock
	output [3:0] seg_select,			// Q1-Q4      [0-3]
	output [7:0] seg_write,				// a-g + dp   [0-7] + 8
	output reg beep,						// Buzzer
	output wire [10:0] RAM_addr,		// RAM address buffer
	output wire RAM_A10,
	output wire [1:0] RAM_bank_sel,	// RAM bank selection
	inout wire [15:0] RAM_data,		// RAM data bus
	output wire RAM_clk,					// RAM clock signal
	output wire RAM_clk_enable,		// RAM enable clock
	output wire RAM_enable,				// RAM chip enable
	output wire RAM_strobe_row,		// RAM row strobe
	output wire RAM_strobe_col,		// RAM column strobe
	output wire RAM_write_enable		// RAM data bus write enable
);

// ----    SETTINGS    ---- //
localparam PLL_SELECT = 4; // 0: 100MHz, 1: 200MHz, 2: 300MHz, 3: 400MHz, 4: 50MHz

// ----    REGISTERS   ---- //
reg debounce;							// Input debouncer
reg db_trap;
reg [3:0] seg_buf_numbers [0:3];	// 7-segment binary-number-representation buffer
reg [1:0] stage;						// Computational stage
reg [7:0] alu_a;
reg [7:0] alu_b;
reg [7:0] alu_op;

// ----     WIRES      ---- //
wire [7:0] seg_buf[0:3];			// Encoded segment buffer (8-bit expanded 4-bit number buffer)
wire [7:0] alu_out;
wire [7:0] alu_flags;
wire [4:0] pll;

assign pll[4] = clk;

// ---- INITIAL VALUES ---- //
initial select_out = 4'b1111;
initial seg_buf_numbers[0] = 4'b0000;
initial seg_buf_numbers[1] = 4'b0000;
initial seg_buf_numbers[2] = 4'b0000;
initial seg_buf_numbers[3] = 4'b0000;
initial debounce = 0;

// Hex encoders for each 4-bit input set. Generates an 8-bit hex output
SegmentHexEncoder enc0(.number (seg_buf_numbers[0]), .encoded (seg_buf[0]));
SegmentHexEncoder enc1(.number (seg_buf_numbers[1]), .encoded (seg_buf[1]));
SegmentHexEncoder enc2(.number (seg_buf_numbers[2]), .encoded (seg_buf[2]));
SegmentHexEncoder enc3(.number (seg_buf_numbers[3]), .encoded (seg_buf[3]));

// A segment display manager to handle rendering data to the 7-segment displays
SegmentManager seg_display(
	.clk (clk), 
	.segment_data0 (seg_buf[0]),
	.segment_data1 (seg_buf[1]),
	.segment_data2 (seg_buf[2]),
	.segment_data3 (seg_buf[3]),
	.segment_select (seg_select),
	.segments (seg_write)
);

ALU core0(.a(alu_a), .b(alu_b), .op(alu_op), .z(alu_out), .o_flags(alu_flags));
altpll0 pll_gen(clk, pll[0], pll[1], pll[2], pll[3]);

always @(posedge pll[PLL_SELECT]) begin
	if(!latch && write && next) begin
		debounce <= 1;
	end
	
	if(write && next && db_trap) begin
		debounce <= 0;
		db_trap <= 0;
	end
	
	if(!write && debounce && !db_trap) begin
		db_trap <= 1;
		if(stage == 0) begin
			alu_a <= alu_a + 1;
		end else if(stage == 1) begin
			alu_b <= alu_b + 1;
		end else if(stage == 2) begin
			alu_op <= alu_op + 1;
		end
	end else if (!next && debounce && !db_trap) begin
		db_trap <= 1;
		stage <= stage + 1;
		
		if(stage == 2'b01) begin
			seg_buf_numbers[0] <= 0;
			seg_buf_numbers[1] <= 0;
			seg_buf_numbers[2] <= 0;
			seg_buf_numbers[3] <= 0;
		end
		else if(stage == 2'b10) begin
			seg_buf_numbers[0] <= alu_out[7:4];
			seg_buf_numbers[1] <= alu_out[3:0];
			seg_buf_numbers[2] <= alu_flags[7:4];
			seg_buf_numbers[3] <= alu_flags[3:0];
		end
		else if(stage == 2'b11) begin
			seg_buf_numbers[0] <= alu_a[7:4];
			seg_buf_numbers[1] <= alu_a[3:0];
			seg_buf_numbers[2] <= alu_b[7:4];
			seg_buf_numbers[3] <= alu_b[3:0];
			alu_a <= 0;
			alu_b <= 0;
			alu_op <= 0;
		end
	end
	
	if(stage == 2'b00 || stage == 2'b01) begin
		seg_buf_numbers[0] <= alu_a[7:4];
		seg_buf_numbers[1] <= alu_a[3:0];
		seg_buf_numbers[2] <= alu_b[7:4];
		seg_buf_numbers[3] <= alu_b[3:0];
	end else if(stage == 2'b10) begin
		seg_buf_numbers[0] <= alu_op[7:4];
		seg_buf_numbers[1] <= alu_op[3:0];
		seg_buf_numbers[2] <= 0;
		seg_buf_numbers[3] <= 0;
	end else if(stage == 2'b11) begin
		seg_buf_numbers[0] <= alu_out[7:4];
		seg_buf_numbers[1] <= alu_out[3:0];
		seg_buf_numbers[2] <= alu_flags[7:4];
		seg_buf_numbers[3] <= alu_flags[3:0];
	end
	
	select_out[0] <= ~debounce;
	select_out[1] <= write;
	select_out[2] <= next;
	select_out[3] <= latch;
end
endmodule
