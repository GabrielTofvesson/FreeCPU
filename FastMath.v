// 2-bit fast adder
module FastAdder2(
        input wire cin,
        input wire [1:0] a,
        input wire [1:0] b,
        output wire [1:0] out,
        output wire cout
);
wire [1:0] g = a & b;
wire [1:0] p = a ^ b;
assign out = a ^ b ^ {
        (g[0]) | (p[0] & cin),
        (cin)
};
assign cout = (g[1]) | (p[1] & g[0]) | (p[1] & p[0] & cin);
endmodule

// 4-bit fast adder
module FastAdder4(
        input wire cin,
        input wire [3:0] a,
        input wire [3:0] b,
        output wire [3:0] out,
        output wire cout
);
wire [3:0] g = a & b;
wire [3:0] p = a ^ b;
assign out = a ^ b ^ {
        (g[2]) | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin),
        (g[1]) | (p[1] & g[0]) | (p[1] & p[0] & cin),
        (g[0]) | (p[0] & cin),
        (cin)
};
assign cout = (g[3]) | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
endmodule

// 8-bit fast adder
module FastAdder8(
        input wire cin,
        input wire [7:0] a,
        input wire [7:0] b,
        output wire [7:0] out,
        output wire cout
);
wire [7:0] g = a & b;
wire [7:0] p = a ^ b;
assign out = a ^ b ^ {
        (g[6]) | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin),
        (g[5]) | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin),
        (g[4]) | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & cin),
        (g[3]) | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin),
        (g[2]) | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin),
        (g[1]) | (p[1] & g[0]) | (p[1] & p[0] & cin),
        (g[0]) | (p[0] & cin),
        (cin)
};
assign cout = (g[7]) | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
endmodule
