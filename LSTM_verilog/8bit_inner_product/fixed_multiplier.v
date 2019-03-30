// This is a Adder_Module
// Description: 1bit sign, 1bit integer, 6bit fraction.
// Author: Michael Kim

module fixed_multiplier#(
	parameter integer BIT_WIDTH = 8,
	parameter integer OUT_WIDTH = 15
)
(
	input [BIT_WIDTH-1:0] iMul1,
	input [BIT_WIDTH-1:0] iMul2,

	output [OUT_WIDTH-1:0] oMulout
);

assign oMulout[OUT_WIDTH-1] = iMul1[BIT_WIDTH-1]^iMul2[BIT_WIDTH-1];
assign oMulout[OUT_WIDTH-2:0] = iMul1[BIT_WIDTH-2:0]*iMul2[BIT_WIDTH-2:0];

endmodule
