// This is a Top
// Description:
// Author: Michael Kim

module B_TMQ#(
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
	input [7:0] Br_Ct,
	input [16:0] temp_regA,
	input [7:0] oTanh_LUT,
	
	output [7:0] B_sat_ct_TMQ,
	output [7:0] B_sat_ht_TMQ
	


);

	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4;
	localparam B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ = 5'd7, B_TMQ = 5'd8;

	reg [31:0] B_unsat_ct_TMQ1;
	reg [31:0] B_unscale_ht_TMQ1;
	reg [31:0] B_unsat_ht_TMQ1;	
	reg [31:0] B_unsat_Z_ht_TMQ1;

	always@(*) begin
		if(comb_ctrl == B_TMQ) begin
			B_unsat_ct_TMQ1 = (($signed({1'b0,Br_Ct})-$signed({1'b0,ZERO_STATE}))*$signed(SCALE_TANH))/$signed(SCALE_STATE) + $signed({1'b0,ZERO_TANH});		
			B_unscale_ht_TMQ1 = ($signed({1'b0,temp_regA})-$signed({1'b0,OUT_ZERO_SIGMOID}))*($signed({1'b0,oTanh_LUT})-{1'b0,ZERO_TANH});
			B_unsat_ht_TMQ1 = ($signed(B_unscale_ht_TMQ1)*$signed(SCALE_DATA))/($signed(OUT_SCALE_TANH)*$signed(OUT_SCALE_SIGMOID));
			B_unsat_Z_ht_TMQ1 = $signed(B_unsat_ht_TMQ1) + $signed({1'b0,ZERO_DATA});
		end
		else begin
			B_unsat_ct_TMQ1 = 'd0;
			B_unscale_ht_TMQ1 = 'd0;
			B_unsat_ht_TMQ1 = 'd0;
			B_unsat_Z_ht_TMQ1 = 'd0;	
		end
	end
	
	assign B_sat_ct_TMQ = (B_unsat_ct_TMQ1[31]) ? 8'd0 : (|B_unsat_ct_TMQ1[30:8] == 1) ? 8'd255 : B_unsat_ct_TMQ1[7:0];
	assign B_sat_ht_TMQ = (B_unsat_Z_ht_TMQ1[31]) ? 8'd0 : (|B_unsat_Z_ht_TMQ1[30:8] == 1) ? 8'd255 : B_unsat_Z_ht_TMQ1[7:0];	


endmodule
