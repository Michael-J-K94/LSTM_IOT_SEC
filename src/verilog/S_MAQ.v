// This is a Top
// Description:
// Author: Michael Kim

module S_MAQ#(
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
	input [16:0] temp_regA,
	input [7:0] temp_regB,
	input [7:0] temp_regC,	
	
	output [7:0] S_sat_MAQ
);

	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4;
	localparam B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ_BQS = 5'd7, B_TMQ_BQS = 5'd8;
	
	reg [31:0] S_real_ctf_MAQ1;
	reg [31:0] S_real_ig_MAQ1;
	reg [31:0] S_real_sum_MAQ1;
	reg [31:0] S_unsat_MAQ1;

	always@(*) begin
		if(comb_ctrl == S_MAQ_BQS) begin
			S_real_ctf_MAQ1 = $signed(temp_regA)/$signed(OUT_SCALE_SIGMOID);
			S_real_ig_MAQ1 = (($signed({1'b0,temp_regB})-$signed({1'b0,OUT_ZERO_SIGMOID})) * ($signed({1'b0,temp_regC})-$signed({1'b0,OUT_ZERO_TANH}))
			*$signed(SCALE_STATE))/($signed(OUT_SCALE_SIGMOID)*$signed(OUT_SCALE_TANH));
			S_real_sum_MAQ1 = $signed(S_real_ctf_MAQ1) + $signed(S_real_ig_MAQ1);
			S_unsat_MAQ1 = $signed(S_real_sum_MAQ1) + $signed({1'b0,ZERO_STATE});			
		end
		else begin
			S_real_ctf_MAQ1 = 'd0;
			S_real_ig_MAQ1 = 'd0;
			S_real_sum_MAQ1 = 'd0;
			S_unsat_MAQ1 = 'd0;
		end
	end

	assign S_sat_MAQ = (S_unsat_MAQ1[31]) ? 8'd0 : (|S_unsat_MAQ1[30:8] == 1) ? 8'd255 : S_unsat_MAQ1[7:0];


endmodule
