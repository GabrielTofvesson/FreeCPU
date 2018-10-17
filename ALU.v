module ALU(
   input wire [BITS-1:0] a,
   input wire [BITS-1:0] b,
   input wire [BITS-1:0] op,
   output wire [BITS-1:0] z,
   output wire [7:0] o_flags
);

parameter BITS;
parameter LOG2_BITS;

/*
FLAGS:

8'bHGFEDCBA

A: Overflow
B: Underflow
C: CMP_GT
D: CMP_EQ
E: DIV_BY_0
F: UNKNWN
G: N/A
H: N/A

*/

reg [(BITS*2)-1:0] i_z;
reg [7:0]  i_flg;
reg        shift_rotate;

wire [BITS:0]      add_out;
wire [BITS-1:0]    lshift [0:LOG2_BITS];
wire [LOG2_BITS-1:0] lshift_overflow;
wire [BITS-1:0]    rshift [0:LOG2_BITS];
wire [LOG2_BITS-1:0] rshift_underflow;

assign z = i_z[7:0];
assign o_flags = i_flg;

FastAdder8 fa8(.cin(), .a(a), .b(b), .out(add_out[BITS-1:0]), .cout(add_out[BITS]));

genvar i;
generate
   for(i = 0; i<LOG2_BITS; i = i + 1) begin : shifters
      LeftBitShifter #(.bits(BITS), .shiftby(2**i)) lsh(i==0 ? a : lshift[i-1], b[i], shift_rotate, lshift[i], lshift_overflow[i]);
      RightBitShifter #(.bits(BITS), .shiftby(2**i)) rsh(i==0 ? a : rshift[i-1], b[i], shift_rotate, rshift[i], rshift_underflow[i]);
   end
endgenerate

integer j, k;

always @* begin
   case(op & 8'b00011111) // 5-bit instructions: 3 flag bits
      // ADD
      0: begin
         i_z <= add_out;
         i_flg <= add_out[BITS] ? 8'b1 : 8'b0; // Set overflow flag if necessary
      end
      
      // SUB
      1: begin
         i_z <= a-b;
         i_flg <= {i_z[BITS*2 - 1], 1'b0};
      end
      
      // MUL
      2: begin
         i_z <= a*b;
         i_flg <= i_z[BITS*2 - 1:BITS] != {BITS{1'b0}} ? 8'b1 : 8'b0;
      end
      
      // DIV
      3: begin
         if(b != {BITS{1'b0}}) begin
            i_z <= a/b;
            i_flg <= 8'b0;
         end else begin
            i_z <= {{BITS{1'b0}}, {BITS{1'b0}}};
            i_flg <= 8'b10000;
         end
      end
      
      // CMP
      4: begin
         /*
         Flag bits:
         
         000 -> No output
         001 -> a > b
         010 -> a < b
         011 -> No output
         100 -> a == b
         101 -> a >= b
         110 -> a <= b
         111 -> No output
         
         */
         i_z <= (op[7:5] == 3'b000) || (op[7:5] == 3'b011) || (op[7:5] == 3'b111) ? 16'b0 : (op[5] && a > b) || (op[6] && a < b ) || (op[7] && a == b) ? 16'b1 : 16'b0;
         i_flg <=
               (a > b ? 8'b100 : 8'b0) | // a > b
               (a == b ? 8'b1000 : 8'b0); // a == b
      end
      
      // AND
      5: begin
         i_z <= a & b;
         i_flg <= 8'b0;
      end
      
      // OR
      6: begin
         i_z <= a | b;
         i_flg <= 8'b0;
      end
      
      // XOR
      7: begin
         i_z <= a ^ b;
         i_flg <= 8'b0;
      end
      
      // NOT
      8: begin
         i_z <= ~a;
         i_flg <= 8'b0;
      end
      
      // NAND
      9: begin
         i_z <= ~(a & b);
         i_flg <= 8'b0;
      end
      
      // NOR
      10: begin
         i_z <= ~(a | b);
         i_flg <= 8'b0;
      end
      
      // XNOR
      11: begin
         i_z <= ~(a ^ b);
         i_flg <= 8'b0;
      end
      
      // CL_MUL
      /*
      12: begin
         i_z <=
            (a[7] ? b << 7 : 16'b0) ^
            (a[6] ? b << 6 : 16'b0) ^
            (a[5] ? b << 5 : 16'b0) ^
            (a[4] ? b << 4 : 16'b0) ^
            (a[3] ? b << 3 : 16'b0) ^
            (a[2] ? b << 2 : 16'b0) ^
            (a[1] ? b << 1 : 16'b0) ^
            (a[0] ? b      : 16'b0);
         
         i_flg <=
            (a[7] && (b[1] || b[2] || b[3] || b[4] || b[5] || b[6] || b[7])) ||
            (a[6] && (b[2] || b[3] || b[4] || b[5] || b[6] || b[7])) ||
            (a[5] && (b[3] || b[4] || b[5] || b[6] || b[7])) ||
            (a[4] && (b[4] || b[5] || b[6] || b[7])) ||
            (a[3] && (b[5] || b[6] || b[7])) ||
            (a[2] && (b[6] || b[7])) ||
            (a[1] && b[7])
            ? 8'b1 : 8'b0;
      end
      */
      
      // SHR (flag: rotate)
      13: begin
         shift_rotate <= op[5];
         i_z   <= b >= BITS ? {BITS{1'b0}} : rshift[LOG2_BITS-1];
         i_flg <= rshift_underflow || (b >= BITS) ? 8'b10: 8'b0;
      end
      
      // SHL (flag: rotate)
      14: begin
         shift_rotate <= op[5];
         i_z   <= b >= BITS ? {BITS{1'b0}} : lshift[LOG2_BITS-1];
         i_flg <= lshift_overflow || (b >= BITS) ? 8'b1 : 8'b0;
      end
      default: begin
         i_z <= {BITS{1'b0}};
         i_flg <= 8'b100000; // Unknown opcode
      end
   endcase
end

endmodule


// Bit shifters
module LeftBitShifter(
    input  wire [bits-1:0] data,
    input  wire            doshift,
    input  wire            rotate,
    output wire [bits-1:0] out,
    output wire            overflow
);
parameter bits;
parameter shiftby;

assign overflow = doshift && data[bits-1:shiftby] ? 1'b1 : 1'b0;
assign out = doshift ? {data[bits-1-shiftby:0], rotate ? data[bits-1:bits-shiftby] : {shiftby{1'b0}}} : data;

endmodule

module RightBitShifter(
    input  wire [bits-1:0] data,
    input  wire            doshift,
    input  wire            rotate,
    output wire [bits-1:0] out,
    output wire            underflow
);
parameter bits;
parameter shiftby;

assign underflow = doshift && data[shiftby:0] ? 1'b1 : 1'b0;
assign out = doshift ? {rotate ? data[shiftby-1:0] : {shiftby{1'b0}}, data[bits-1:shiftby]} : data;

endmodule

module Combine(
    input wire  i1,
    input wire  i2,
    output wire o
);

assign o = i1 | i2;

endmodule
