module RAM(
	input  wire         clk,
	output wire [10:0]  RAM_addr,         // RAM address buffer
	output wire         RAM_A10,          // RAM address/auto-precharge
	output wire [1:0]   RAM_bank_sel,     // RAM bank selection
	inout  wire [15:0]  RAM_data,         // RAM data bus
	output wire         RAM_clk,          // RAM clock signal
	output wire         RAM_clk_enable,   // RAM enable clock
	output wire         RAM_enable,       // RAM chip enable
	output wire         RAM_strobe_row,   // RAM row strobe
	output wire         RAM_strobe_col,   // RAM column strobe
	output wire         RAM_write_enable, // RAM data bus write enable
	input  wire         read_rq,          // Read request (Internal)
	input  wire         write_rq,         // Write request (Internal)
	input  wire [1:0]   access_bank,      // Which bank to access
	output reg  [15:0]  RAM_state,        // State information (Internal)
	output wire [3:0]   op_trigger        // Event trigger wire (per bank)
);

reg [2:0] read_init[0:3];                // Whether or not a read operation has been initiated
reg       trigger_low;                   // If trigger should be pulled low on next clock cycle

genvar k;
generate
   for(k = 0; k<4; k = k + 1) begin : trigger_gen
      assign op_trigger[k] = read_init[k] == 3'b011;
   end
endgenerate

assign RAM_enable = read_init[0] == 3'b000 && read_init[1] == 3'b000 && read_init[2] == 3'b000 && read_init[3] == 3'b000;
assign RAM_clk_enable = read_init[0] != 3'b000 && read_init[1] != 3'b000 && read_init[2] != 3'b000 && read_init[3] != 3'b000;

assign RAM_clk = clk;                    // RAM clock tracks processor input clock

integer i;

always @(posedge clk or posedge read_rq) begin
   if(read_rq) begin
      if(!read_init[access_bank] && !write_rq) begin
         read_init[access_bank] <= 3'b001;
      end
	end
   else begin
		if(read_init[0]) begin
         read_init[0] <= read_init[0] + 3'b001; // Increment read
         RAM_state[3:0] <= 4'b0001;   // STATE: read
      end
		if(read_init[1]) begin
         read_init[1] <= read_init[1] + 3'b001; // Increment read
         RAM_state[7:4] <= 4'b0001;   // STATE: read
      end
		if(read_init[2]) begin
         read_init[2] <= read_init[2] + 3'b001; // Increment read
         RAM_state[11:8] <= 4'b0001;   // STATE: read
      end
		if(read_init[3]) begin
         read_init[3] <= read_init[3] + 3'b001; // Increment read
         RAM_state[15:12] <= 4'b0001;   // STATE: read
      end
	end
end

always @(posedge write_rq) begin
	if(!read_init[access_bank] && !read_rq) begin
      //TODO: Implement read
	end
end

endmodule
