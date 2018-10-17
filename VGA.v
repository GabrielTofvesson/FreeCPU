module VGA(
   input  wire       clk,
   input wire [2:0]  rgb_data,
   output reg        graphics_clk,
   output wire [9:0] graphics_coords_x,
   output wire [9:0] graphics_coords_y,
   output wire [2:0] VGA_rgb,
   output wire       VGA_hsync,
   output wire       VGA_vsync
);

parameter
  hsync_end  = 10'd95,
  hdat_begin = 10'd143,
  hdat_end   = 10'd783,
  hpixel_end = 10'd799,
  vsync_end  = 10'd1,
  vdat_begin = 10'd34,
  vdat_end   = 10'd514,
  vline_end  = 10'd524;

reg [9:0] hcount;
reg [9:0] vcount;

wire hcount_ov = (hcount == hpixel_end);
wire vcount_ov = (vcount == vline_end);
wire dat_act = ((hcount >= hdat_begin) && (hcount < hdat_end)) && ((vcount >= vdat_begin) && (vcount < vdat_end));

assign VGA_hsync = (hcount > hsync_end);
assign VGA_vsync = (vcount > vsync_end);
assign VGA_rgb = (dat_act) ?  rgb_data : 3'b0;
assign graphics_coords_x = vcount;
assign graphics_coords_y = hcount;

// Clock divider
always @(posedge clk) graphics_clk = ~graphics_clk;

// Graphics boundary calculation
always @(posedge graphics_clk) begin
  if(hcount_ov && vcount_ov) vcount <= 10'b0;
  else if(hcount_ov) vcount <= vcount + 10'b1;
  if (hcount_ov) hcount <= 10'd0;
  else hcount <= hcount + 10'd1;
end
endmodule
