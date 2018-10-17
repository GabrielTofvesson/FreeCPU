/* 
 *  DEVICE INFORMATION:
 *     HY57V641620FTP-7:
 *        RAS latency: 2 or 3 cycles
 *        RCD latency: 2 or 3 cycles
 *        full address_select available for row selection
 *        address_select[7:0] available for col selection
 */

module RAM(
   input  wire         clk,              // Clock signal
   output reg  [10:0]  RAM_addr,         // RAM address buffer
   output reg          RAM_A10,          // RAM address/auto-precharge
   output reg  [1:0]   RAM_bank_sel,     // RAM bank selection
   inout  wire [15:0]  RAM_data,         // RAM data bus
   output wire         RAM_clk,          // RAM clock signal
   output wire         RAM_clk_enable,   // RAM enable clock
   output reg          RAM_enable,       // RAM chip enable
   output reg          RAM_strobe_row,   // RAM row strobe
   output reg          RAM_strobe_col,   // RAM column strobe
   output reg          RAM_write_enable, // RAM data bus write enable
   input  wire         read_rq,          // Read request (Internal)
   input  wire         write_rq,         // Write request (Internal)
   input  wire [1:0]   access_bank,      // Which bank to access
   output wire         op_trigger,       // Event trigger wire
   input  wire [11:0]  address_select,   // Address selection when accessing RAM,
	input  wire         stop_access,      // Close a row
	output reg  [1:0]   op_bank           // Bank being accessed when op_trigger is pulled high
);

parameter CPB = 4;                       // Specifies in bit length how many cycles a bank burst can allocate for itself before other banks are checked
parameter tRCD = 3 + 1;                  // Assume RCD latency of 3 cycles
parameter tRAS = 3 + 1;                  // Assume CAS latency of 3 cycles

reg  [CPB-1:0] acc_cycles;               // Cycles used on current bank
reg  [1:0]     acc_bank;                 // Which bank is allocating read cycles
reg  [1:0]     acc_close[0:3];           // Requests a close of the current row
reg  [3:0]     acc_type;                 // The current access type of the bank (0: READ, 1: WRITE)
reg  [3:0]     acc_state [0:3];			  // Current access state for each bank (0: READY, 1: OPENING, 2: tRCD, 3: READ, 4: STOPPING)
reg  [3:0]     acc_init_callback;        // Pull this high to initiate a callback
reg  [1:0]     event_trigger;            // Event triggers drive op_trigger

wire [3:0]     acc_event;					  // Event update callback wire
wire [2:0]     callback_timeout[0:3];    // Callback clock cycle definition

Callback #(.ISIZE(3)) cb0(clk, callback_timeout[0], acc_init_callback[0], acc_event[0]);
Callback #(.ISIZE(3)) cb1(clk, callback_timeout[1], acc_init_callback[1], acc_event[1]);
Callback #(.ISIZE(3)) cb2(clk, callback_timeout[2], acc_init_callback[2], acc_event[2]);
Callback #(.ISIZE(3)) cb3(clk, callback_timeout[3], acc_init_callback[3], acc_event[3]);


// Initialize the ram in an inactive state
initial RAM_enable       = 1'b1;
initial RAM_strobe_row   = 1'b1;
initial RAM_strobe_col   = 1'b1;
initial RAM_write_enable = 1'b1;
initial acc_bank         = 1'b1;

assign op_trigger = event_trigger[0] ^ event_trigger[1];
assign RAM_clk = clk;
assign RAM_clk_enable = (acc_state[0] | acc_state[1] | acc_state[2] | acc_state[3]) ? 1'b1 : 1'b0;

genvar n;
generate
	for(n = 0; n < 4; n = n + 1) begin : gen_callback_timing
		assign callback_timeout[n] = acc_state[n][1] ? tRAS : tRCD;
	end
endgenerate

integer i;

always @(posedge read_rq or posedge write_rq or posedge acc_event or posedge stop_access or posedge clk) begin
	if(read_rq || write_rq) begin
		if(acc_state[access_bank] == 4'b0000) begin
			RAM_enable <= 1'b0;
			RAM_strobe_row <= 1'b0;
			RAM_strobe_col <= 1'b1;
			RAM_write_enable <= 1'b1;
	
			RAM_bank_sel <= access_bank;
			RAM_addr <= {address_select[11], address_select[9:0]};
			RAM_A10 <= address_select[10];
			acc_type[access_bank] <= read_rq ? 1'b0 : 1'b1;
			acc_state[access_bank] <= 4'b0001;
			acc_init_callback[access_bank] <= 1'b1;
			acc_close[access_bank] <= 1'b0;
		end
	end
	else if(stop_access) begin
		if(acc_state[access_bank])
			acc_close[access_bank] <= 1'b1;
	end
	else if(clk) begin
		for(i = 0; i < 4; i = i + 1)
			if(acc_state[i] == 4'b0010)
				acc_init_callback[i] <= 1'b1;
		
		if(~(acc_state[0] | acc_state[1] | acc_state[2] | acc_state[3]))
			RAM_enable <= 1'b1;
		
		// Bank access management
		acc_cycles[acc_bank] <= acc_cycles[acc_bank] + 1'b1;
		if(acc_cycles[acc_bank] == {CPB{1'b1}}) begin
			
			// Close banks as needed
			if(acc_close[0]) begin
				acc_close[0] <= 1'b0;
				RAM_bank_sel <= 2'b00;
				acc_state[0] <= 4'b0000;
			end
			else if(acc_close[1]) begin
				acc_close[1] <= 1'b0;
				RAM_bank_sel <= 2'b01;
				acc_state[1] <= 4'b0000;
			end
			else if(acc_close[2]) begin
				acc_close[2] <= 1'b0;
				RAM_bank_sel <= 2'b10;
				acc_state[2] <= 4'b0000;
			end
			else if(acc_close[3]) begin
				acc_close[3] <= 1'b0;
				RAM_bank_sel <= 2'b11;
				acc_state[3] <= 4'b0000;
			end
			
			// Increment bank tracker
			if(~(acc_close[0] | acc_close[1] | acc_close[2] | acc_close[3])) begin
				acc_bank <= acc_bank + 1;
				acc_cycles <= {CPB{1'b0}};
			end
			else begin
				// Trigger RAM row-close event
				RAM_enable <= 1'b0;
				RAM_strobe_row <= 1'b1;
				RAM_strobe_col <= 1'b1;
				RAM_write_enable <= 1'b0;
			end
		end
		else begin
			// Access bank
			for(i = 0; i < 4; i = i + 1) begin
				// Bank_{i} active and not closing and...
				// Enough cycles left or when no other bank is active or...
				// Bank_{i+1} at cycle limit and next banks inactive or bank is closing or...
				// Bank_{i+2} at cycle limit and next bank inactive or bank is closing or...
				// Bank_{i+3} at cycle limit or closing
				if(!acc_close[i] && acc_state[i] == 4'b0100 && (                                                                                            
					(acc_bank == i && (acc_cycles != {CPB{1'b1}} || (acc_state[(i+1)%4] != 4'b0100 && acc_state[(i+2)%4] != 4'b0100 && acc_state[(i+3)%4] != 4'b0100))) ||
					(acc_bank == (i+1)%4 && ((acc_close[(i+1)%4] || acc_cycles == {CPB{1'b1}}) && acc_state[(i+2)%4] != 4'b0100 && acc_state[(i+3)%4] != 4'b0100)) ||
					(acc_bank == (i+2)%4 && ((acc_close[(i+2)%4] || acc_cycles == {CPB{1'b1}}) && acc_state[(i+3)%4] != 4'b0100)) ||
					(acc_bank == (i+3)%4 && (acc_close[(i+3)%4] || acc_cycles == {CPB{1'b1}}))
				)) begin
					RAM_bank_sel <= i;
					RAM_addr <= {2'b0, RAM_addr[7:0]};
					RAM_A10 <= 1'b1;
					RAM_strobe_row <= 1'b1;
					RAM_strobe_col <= 1'b0;
					RAM_write_enable <= ~acc_type[i];
					op_bank <= i;
					event_trigger[0] <= event_trigger[1] ? 1'b0 : 1'b1;
				end
			end
		end
	end
	else if(acc_event) begin
		for(i = 0; i < 4; i = i + 1) begin
			if(acc_state[i] == 4'b0001) begin
				RAM_bank_sel <= i;
				RAM_strobe_row <= 1'b1;
				RAM_strobe_col <= 1'b0;
				RAM_write_enable <= ~acc_type[i];
				RAM_A10 <= 1;
				acc_state[i] <= 4'b0010;
				acc_init_callback[i] <= 1'b0;
			end
			else if(acc_state[i] == 4'b0010) begin
				acc_init_callback[i] <= 1'b0;
				acc_state[i] <= 4'b0100;
			end
		end
	end
end

// Reset op_trigger by tracking posedge-driven event_trigger
always @(negedge clk) event_trigger[1] <= event_trigger[0] ? 1'b1 : 1'b0;

endmodule
