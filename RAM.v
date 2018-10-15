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
	output reg  [3:0]   RAM_state,        // State information (Internal)
	output wire         op_trigger        // Event trigger wire
);

reg [2:0] read_init;                     // Whether or not a read operation has been initiated
reg       trigger_low;                   // If trigger should be pulled low on next clock cycle

assign op_trigger = read_init == 3'b011;
assign RAM_enable = ~(read_init != 3'b000);
assign RAM_clk_enable = read_init != 3'b000;

assign RAM_clk = clk;                    // RAM clock tracks processor input clock

always @(posedge clk or posedge read_rq) begin
   if(read_rq) begin
      if(!read_init && !write_rq) begin
         read_init <= 3'b001;
      end
	end
   else if(read_init) begin
      read_init <= read_init + 3'b001;
      RAM_state <= 4'b0001;              // STATE: read
   end
end

always @(posedge write_rq) begin
	if(!read_init && !read_rq) begin
      //TODO: Implement read
	end
end

endmodule
