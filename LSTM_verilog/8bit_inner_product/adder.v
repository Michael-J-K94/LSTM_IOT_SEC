// This is a Adder_Module
// Description:
// Author: Michael Kim

module adder#(
	parameter integer BIT_WIDTH = 15,
	parameter integer SUM_WIDTH = 19 
)
(
	input EN,

	input [BIT_WIDTH-1:0] iAdd1,
	input [BIT_WIDTH-1:0] iAdd2,

	output reg [SUM_WIDTH-1:0] oAddout
);

always@(*) begin
	if( (iAdd1[BIT_WIDTH-1]^iAdd2[BIT_WIDTH-1]) == 1 ) begin
		if( iAdd1[BIT_WIDTH-2:0] > iAdd2[BIT_WIDTH-2:0]  ) begin
			oAddout[SUM_WIDTH-1] = iAdd1[BIT_WIDTH-1];
			oAddout[SUM_WIDTH-2:0] = iAdd1[BIT_WIDTH-2] - iAdd2[BIT_WIDTH-2:0];
		end
		else begin
			oAddout[SUM_WIDTH-1] = iAdd2[BIT_WIDTH-1];
			oAddout[SUM_WIDTH-2:0] = iAdd2[BIT_WIDTH-2] - iAdd1[BIT_WIDTH-2:0];
		end
	end
	else begin
		oAddout[SUM_WIDTH-1] = iAdd1[BIT_WIDTH-1];
		oAddout[SUM_WIDTH-2:0] = iAdd1[BIT_WIDTH-2:0] + iAdd2[BIT_WIDTH-2:0];
	end
end

endmodule
