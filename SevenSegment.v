module SevenSegment(
   input wire         latch,            // S4
   input wire         next,             // S2
   input wire         value,            // S3
   output reg  [3:0]  select_out,       // LED1-LED4 [0-3]
   input wire         write,            // S1
   input wire         clk,              // 50MHz clock
   output      [3:0]  seg_select,       // Q1-Q4      [0-3]
   output      [7:0]  seg_write,        // a-g + dp   [0-7] + 8
   output reg         beep,             // Buzzer
   output wire [10:0] RAM_addr,         // RAM address buffer
   output wire        RAM_A10,          // RAM A10 precharge/address
   output wire [1:0]  RAM_bank_sel,     // RAM bank selection
   inout  wire [15:0] RAM_data,         // RAM data bus
   output wire        RAM_clk,          // RAM clock signal
   output wire        RAM_clk_enable,   // RAM enable clock
   output wire        RAM_enable,       // RAM chip enable
   output wire        RAM_strobe_row,   // RAM row strobe
   output wire        RAM_strobe_col,   // RAM column strobe
   output wire        RAM_write_enable, // RAM data bus write enable
   output wire        VGA_vsync,        // VGA display vsync trigger
   output wire        VGA_hsync,        // VGA display hsync trigger
   output wire [2:0]  VGA_rgb           // VGA color channels [0]: RED, [1]: GREEN, [2]: BLUE
);

// ----    SETTINGS    ---- //
localparam PLL_SELECT = 1;       // 0: 100MHz, 1: 200MHz, 2: 300MHz, 3: 400MHz, 4: 50MHz
localparam RAM_PLL = 0;          // Must be either 0 or 1. DO NOT SET TO ANY OTHER VALUE AS IT MIGHT FRY THE ONBOARD RAM!!!

// ----    REGISTERS   ---- //
reg        debounce;             // Input debouncer
reg        db_trap;              // Debounce buffer
reg [3:0]  seg_buf_numbers [0:3];// 7-segment binary-number-representation buffer
reg [1:0]  stage;                // Computational stage
reg [7:0]  alu_a;                // ALU (core0) input a
reg [7:0]  alu_b;                // ALU (core0) input b
reg [7:0]  alu_op;               // ALU (core0) opcode
reg [2:0]  gfx_rgb;              // VGA color channels
reg [1:0]  ram_bank_sel;         // Which ram bank to access
reg [11:0] ram_addr;             // RAM address selection
reg        ram_close;            // RAM close-row trigger

// ----     WIRES      ---- //
wire [7:0]  seg_buf[0:3];        // Encoded segment buffer (8-bit expanded 4-bit number buffer)
wire [7:0]  alu_out;             // ALU (core0) output
wire [7:0]  alu_flags;           // ALU (core0) output flags
wire [4:0]  pll;                 // Phase-locked-loop connections (+ source clock)
wire        vga_clk;             // VGA data clock
wire        cb;                  // Callback/timeout
wire [9:0]  vga_coords[0:1];     // Current screen coordinates being drawn to
wire        ram_request_read;    // Trigger a read operation from main memory
wire        ram_request_write;   // Trigger a write operation from main memory
wire        ram_event;           // Event trigger from ram when a r/w operation is ready
wire [1:0]  ram_event_bank;      // Which bank an event is happening on

// ----  WIRE ASSIGNS  ---- //
assign pll[4] = clk;

// ---- INITIAL VALUES ---- //
initial select_out = 4'b1111;
initial debounce = 1'b0;
initial db_trap = 1'b1;

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

// Graphics controller
VGA screen(clk, gfx_rgb, vga_clk, vga_coords[0], vga_coords[1], VGA_rgb, VGA_hsync, VGA_vsync);

// Arithmetic logic unit
ALU #(.BITS(8), .LOG2_BITS(3)) core0(.a(alu_a), .b(alu_b), .op(alu_op), .z(alu_out), .o_flags(alu_flags));

// Clock generator
altpll0 pll_gen(clk, pll[0], pll[1], pll[2], pll[3]);

// Callback module (generate timeouts) (Precision: 1/100M = 10ns) NOTE: 400MHz seems to be unstable, so a precision of 2.5ns comes at the price of stability
Callback #(.ISIZE(32)) timeout(pll[0], 32'd100000000, ~value, cb);

// RAM module
RAM main_memory(
   pll[RAM_PLL],
   RAM_addr,
   RAM_A10,
   RAM_bank_sel,
   RAM_data,
   RAM_clk,
   RAM_clk_enable,
   RAM_enable,
   RAM_strobe_col,
   RAM_strobe_row,
   RAM_write_enable,
   ram_request_read,
   ram_request_write,
   ram_bank_sel,
   ram_event,
   ram_addr,
   ram_close,
   ram_event_bank
);

always @(posedge cb or negedge value) select_out <= cb ? 4'b0000 : 4'b1111;
always @(posedge vga_clk) gfx_rgb <= alu_a[2:0];
always @(posedge pll[PLL_SELECT]) begin
   if(!latch && write && next) begin
      debounce <= 1'b1;
   end
   
   if(write && next && db_trap) begin
      debounce <= 1'b0;
      db_trap <= 1'b0;
   end
   
   if(!write && debounce && !db_trap) begin
      db_trap <= 1'b1;
      if(stage == 2'b0) begin
         alu_a <= alu_a + 8'b1;
      end else if(stage == 2'b1) begin
         alu_b <= alu_b + 8'b1;
      end else if(stage == 2'b10) begin
         alu_op <= alu_op + 8'b1;
      end
   end else if (!next && debounce && !db_trap) begin
      db_trap <= 1'b1;
      stage <= stage + 2'b1;
      
      if(stage == 2'b01) begin
         seg_buf_numbers[0] <= 4'b0;
         seg_buf_numbers[1] <= 4'b0;
         seg_buf_numbers[2] <= 4'b0;
         seg_buf_numbers[3] <= 4'b0;
      end
      else if(stage == 2'b10) begin
         seg_buf_numbers[0] <= alu_out[7:4];
         seg_buf_numbers[1] <= alu_out[3:0];
         seg_buf_numbers[2] <= alu_flags[7:4];
         seg_buf_numbers[3] <= alu_flags[3:0];
      end
      else if(stage == 2'b11) begin
         seg_buf_numbers[0] <= 4'b0;
         seg_buf_numbers[1] <= 4'b0;
         seg_buf_numbers[2] <= 4'b0;
         seg_buf_numbers[3] <= 4'b0;
         alu_a <= 8'b0;
         alu_b <= 8'b0;
         alu_op <= 8'b0;
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
      seg_buf_numbers[2] <= 4'b0;
      seg_buf_numbers[3] <= 4'b0;
   end else if(stage == 2'b11) begin
      seg_buf_numbers[0] <= alu_out[7:4];
      seg_buf_numbers[1] <= alu_out[3:0];
      seg_buf_numbers[2] <= alu_flags[7:4];
      seg_buf_numbers[3] <= alu_flags[3:0];
   end
   
   //select_out[0] <= ~debounce;
   //select_out[1] <= write;
   //select_out[2] <= next;
   //select_out[3] <= latch;
end
endmodule
