// This is a Adder_Module
// Description:
// Author: Michael Kim

module inner_product#(
	parameter integer BIT_WIDTH = 8,
	parameter integer NUM_OF_INPUT = 16,
	parameter integer MUL_OUT_WIDTH = 15,
	parameter integer SUM_WIDTH = 19
)
(
	input clk,
	input resetn,

	input [BIT_WIDTH-1:0] iW1,
	input [BIT_WIDTH-1:0] iW2,
	input [BIT_WIDTH-1:0] iW3,
	input [BIT_WIDTH-1:0] iW4,
	input [BIT_WIDTH-1:0] iW5,
	input [BIT_WIDTH-1:0] iW6,
	input [BIT_WIDTH-1:0] iW7,
	input [BIT_WIDTH-1:0] iW8,
	input [BIT_WIDTH-1:0] iW9,
	input [BIT_WIDTH-1:0] iW10,
	input [BIT_WIDTH-1:0] iW11,
	input [BIT_WIDTH-1:0] iW12,
	input [BIT_WIDTH-1:0] iW13,
	input [BIT_WIDTH-1:0] iW14,
	input [BIT_WIDTH-1:0] iW15,
	input [BIT_WIDTH-1:0] iW16,

	input [BIT_WIDTH-1:0] iX1,
	input [BIT_WIDTH-1:0] iX2,
	input [BIT_WIDTH-1:0] iX3,
	input [BIT_WIDTH-1:0] iX4,
	input [BIT_WIDTH-1:0] iX5,
	input [BIT_WIDTH-1:0] iX6,
	input [BIT_WIDTH-1:0] iX7,
	input [BIT_WIDTH-1:0] iX8,
	input [BIT_WIDTH-1:0] iX9,
	input [BIT_WIDTH-1:0] iX10,
	input [BIT_WIDTH-1:0] iX11,
	input [BIT_WIDTH-1:0] iX12,
	input [BIT_WIDTH-1:0] iX13,
	input [BIT_WIDTH-1:0] iX14,
	input [BIT_WIDTH-1:0] iX15,
	input [BIT_WIDTH-1:0] iX16,

	output reg [BIT_WIDTH-1:0] oInnerout
);

	genvar i;
	integer q;

	wire [BIT_WIDTH-1:0] weight [NUM_OF_INPUT-1:0];
	wire [BIT_WIDTH-1:0] input_x [NUM_OF_INPUT-1:0];
	wire [MUL_OUT_WIDTH-1:0] mul_out [NUM_OF_INPUT-1:0];

// ADDER TREE //
	wire [16-1:0] addout_stg1 [8-1:0];
	wire [17-1:0] addout_stg2 [4-1:0];
	wire [18-1:0] addout_stg3 [2-1:0];
	wire [19-1:0] addout_last;

// INPUT assign to WIRE //
	assign weight[0] = iW1;
	assign weight[1] = iW2;
	assign weight[2] = iW3;
	assign weight[3] = iW4;
	assign weight[4] = iW5;
	assign weight[5] = iW6;
	assign weight[6] = iW7;
	assign weight[7] = iW8;
	assign weight[8] = iW9;
	assign weight[9] = iW10;
	assign weight[10] = iW11;
	assign weight[11] = iW12;
	assign weight[12] = iW13;
	assign weight[13] = iW14;
	assign weight[14] = iW15;
	assign weight[15] = iW16;

	assign input_x[0] = iX1;
	assign input_x[1] = iX2;
	assign input_x[2] = iX3;
	assign input_x[3] = iX4;
	assign input_x[4] = iX5;
	assign input_x[5] = iX6;
	assign input_x[6] = iX7;
	assign input_x[7] = iX8;
	assign input_x[8] = iX9;
	assign input_x[9] = iX10;
	assign input_x[10] = iX11;
	assign input_x[11] = iX12;
	assign input_x[12] = iX13;
	assign input_x[13] = iX14;
	assign input_x[14] = iX15;
	assign input_x[15] = iX16;

// 16 Multipliers //
generate
for(i=0; i<NUM_OF_INPUT; i=i+1) begin : Fixed_Multiplier
	fixed_multiplier u_fixed_multiplier
	(
	.iMul1(weight[i]),
	.iMul2(input_x[i]),
	.oMulout(mul_out[i])
	);
end
endgenerate

// Adder Stage 1 (8 of them) //
generate
for(i=0; i<8; i=i+1) begin : Adder_Stage_1
	adder#(
	.BIT_WIDTH(15),
	.SUM_WIDTH(16)
	)
	u_adder(
	.iAdd1(mul_out[2*i]),
	.iAdd2(mul_out[2*i+1]),
	.oAddout(addout_stg1[i])
	);
end
endgenerate

// Adder Stage 2 (4 of them) //
generate
for(i=0; i<4; i=i+1) begin : Adder_Stage_2
	adder#(
	.BIT_WIDTH(16),
	.SUM_WIDTH(17)
	)
	u_adder(
	.iAdd1(addout_stg1[2*i]),
	.iAdd2(addout_stg1[2*i+1]),
	.oAddout(addout_stg2[i])
	);
end
endgenerate

// Adder Stage 3 (2 of them) //
generate
for(i=0; i<2; i=i+1) begin : Adder_Stage_3
	adder#(
	.BIT_WIDTH(17),
	.SUM_WIDTH(18)
	)
	u_adder(
	.iAdd1(addout_stg2[2*i]),
	.iAdd2(addout_stg2[2*i+1]),
	.oAddout(addout_stg3[i])
	);
end
endgenerate

	adder#(
	.BIT_WIDTH(18),
	.SUM_WIDTH(19)
	)
	last_adder(
	.iAdd1(addout_stg3[0]),
	.iAdd2(addout_stg3[1]),
	.oAddout(addout_last)
	);

always@(posedge clk or negedge resetn) begin 
	if(!resetn) begin
		oInnerout <= 'd0;
	end
	else begin
		oInnerout[BIT_WIDTH-1] <= addout_last[19-1];
		oInnerout[BIT_WIDTH-2:0] <= addout_last[12:6];
	end
end
endmodule
