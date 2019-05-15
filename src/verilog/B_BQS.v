// This is a Top
// Description:
// Author: Michael Kim

module B_BQS#(
	parameter SCALE_DATA = 10'd128,		// Xt, Ht
	parameter SCALE_STATE =  10'd128,	// Ct
	parameter SCALE_W = 10'd128,
	parameter SCALE_B = 10'd256,

	parameter ZERO_DATA = 8'd128,
	parameter ZERO_STATE = 8'd128,
	parameter ZERO_W = 8'd128,			
	parameter ZERO_B = 8'd0,
	
	parameter SCALE_SIGMOID = 10'd24,
	parameter SCALE_TANH = 10'd48,

	parameter ZERO_SIGMOID = 8'd128,
	parameter ZERO_TANH = 8'd128,

	parameter OUT_SCALE_SIGMOID = 10'd256,
	parameter OUT_SCALE_TANH = 10'd128,

	parameter OUT_ZERO_SIGMOID = 8'd0,
	parameter OUT_ZERO_TANH = 8'd128
)
(
	input [4:0] comb_ctrl,
	input [31:0] inpdt_R_reg,
	input [31:0] inpdt_Rtemp1_reg,
	input [31:0] inpdt_Rtemp2_reg,
	input [31:0] inpdt_Rtemp3_reg,
	input [7:0] bias_buffer,
	output [7:0] B_sat_BQS

);

	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4;
	localparam B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ_BQS = 5'd7, B_TMQ_BQS = 5'd8;

	reg [31:0] B_real_inpdt_sumBQS1; 
	reg [31:0] B_real_biasBQS1;			
	reg [31:0] B_unsat_BQS1;

	always@(*) begin
		if((comb_ctrl == B_BQS) || (comb_ctrl == B_MAQ_BQS) || (comb_ctrl == B_TMQ_BQS)) begin
			B_real_inpdt_sumBQS1 = $signed( ( $signed(inpdt_R_reg) + $signed(inpdt_Rtemp1_reg) + $signed(inpdt_Rtemp2_reg) + $signed(inpdt_Rtemp3_reg) )
			*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA)) );
			//+ $signed( $signed(inpdt_R_reg2)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA)) );							// Sumation of X & H
			B_real_biasBQS1 = (($signed({1'b0,bias_buffer})-$signed({1'b0,ZERO_B}))*$signed(SCALE_SIGMOID))/$signed(SCALE_B);
			B_unsat_BQS1 = $signed(B_real_inpdt_sumBQS1) + $signed(B_real_biasBQS1) + $signed({1'b0,ZERO_SIGMOID});			
		end
		else begin
			B_real_inpdt_sumBQS1 = 'd0;
			B_real_biasBQS1 = 'd0;
			B_unsat_BQS1 = 'd0;
		end
	end
	
	assign B_sat_BQS = (B_unsat_BQS1[31]) ? 8'd0 : (|B_unsat_BQS1[30:8] == 1) ? 8'd255 : B_unsat_BQS1[7:0];


endmodule
