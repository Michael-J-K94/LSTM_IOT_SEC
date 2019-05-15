// This is a Top
// Description:
// Author: Michael Kim

module CONVERT_Ct#(
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
	input [2:0] lstm_state,
	input [31:0] inpdt_R_reg,
	input [7:0] bias_buffer,
	output [7:0] Ct_sat


);

	localparam IDLE = 3'd0, SYSTEM = 3'd1, BRANCH = 3'd2, INITIALIZE_W_B = 3'd3, CTXT_CONVERT = 3'd4, ERROR = 3'd7;

	reg [31:0] Ct_real_inpdt_sum1;
	reg [31:0] Ct_real_bias1;
	reg [31:0] Ct_unsat1;


	always@(*) begin
		if(lstm_state == CTXT_CONVERT) begin
			Ct_real_inpdt_sum1 = $signed(inpdt_R_reg)/($signed(SCALE_W));
			Ct_real_bias1 = ($signed({1'b0,bias_buffer})-$signed({1'b0,ZERO_B}))*$signed(SCALE_STATE)/$signed(SCALE_B);
			Ct_unsat1 = $signed(Ct_real_inpdt_sum1) + $signed(Ct_real_bias1) + $signed({1'b0,ZERO_STATE});
		end
		else begin
			Ct_real_inpdt_sum1 = 'd0;
			Ct_real_bias1 = 'd0;
			Ct_unsat1 = 'd0;
		end
	end

	assign Ct_sat = (Ct_unsat1[31]) ? 8'd0 : (|Ct_unsat1[30:8] == 1) ? 8'd255 : Ct_unsat1[7:0];

endmodule
