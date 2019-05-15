// This is a Top
// Description:
// Author: Michael Kim

module S_BQT#(
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
	input [7:0] bias_buffer,
	
	output [7:0] S_sat_BQT
);

	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4;
	localparam B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ = 5'd7, B_TMQ = 5'd8;
	
	

	reg [31:0] S_real_inpdt_sumBQT1; 
	reg [31:0] S_real_biasBQT1;			
	reg [31:0] S_unsat_BQT1;

	always@(*) begin
		if(comb_ctrl == S_BQT) begin
			S_real_inpdt_sumBQT1 =  $signed(inpdt_R_reg)*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQT1 = (($signed({1'b0,bias_buffer})-$signed({1'b0,ZERO_B}))*$signed(SCALE_TANH))/$signed(SCALE_B);
			S_unsat_BQT1 = $signed(S_real_inpdt_sumBQT1) + $signed(S_real_biasBQT1) + $signed({1'b0,ZERO_TANH});
		end
		else begin
			S_real_inpdt_sumBQT1 = 'd0; 
			S_real_biasBQT1 = 'd0;			
			S_unsat_BQT1 = 'd0;
		end
	end


	assign S_sat_BQT = (S_unsat_BQT1[31]) ? 8'd0 : (|S_unsat_BQT1[30:8] == 1) ? 8'd255 : S_unsat_BQT1[7:0];

endmodule
