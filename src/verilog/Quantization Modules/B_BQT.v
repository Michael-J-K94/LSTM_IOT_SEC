// This is a Top
// Description:
// Author: Michael Kim

module B_BQT#(
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
	output [7:0] B_sat_BQT

);

	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4;
	localparam B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ_BQS = 5'd7, B_TMQ_BQS = 5'd8;

	reg [31:0] B_real_inpdt_sumBQT1; 
	reg [31:0] B_real_biasBQT1;			
	reg [31:0] B_unsat_BQT1;

	always@(*) begin
		if(comb_ctrl == B_BQT) begin
			B_real_inpdt_sumBQT1 = $signed( ( $signed(inpdt_R_reg) + $signed(inpdt_Rtemp1_reg) + $signed(inpdt_Rtemp2_reg) + $signed(inpdt_Rtemp3_reg) )
			*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA)) );
			//+ $signed( $signed(inpdt_R_reg2)*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA)) );								// Sumation of X & H
			B_real_biasBQT1 = (($signed({1'b0,bias_buffer})-$signed({1'b0,ZERO_B}))*$signed(SCALE_TANH))/$signed(SCALE_B);
			B_unsat_BQT1 = $signed(B_real_inpdt_sumBQT1) + $signed(B_real_biasBQT1) + $signed({1'b0,ZERO_TANH});
		end
		else begin
			B_real_inpdt_sumBQT1 = 'd0;
			B_real_biasBQT1 = 'd0;
			B_unsat_BQT1 = 'd0;
		end
	end
	
	assign B_sat_BQT = (B_unsat_BQT1[31]) ? 8'd0 : (|B_unsat_BQT1[30:8] == 1) ? 8'd255 : B_unsat_BQT1[7:0];
	


endmodule
