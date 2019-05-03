// This is a LSTM
// Description: 

// TODO: 
/*
	1. Sequence Order Check
	2. Weight / Bias SRAM Allocation
	3. Quantization
	4. LUT instantiation
*/

// Author: Michael Kim

module LSTM#(

	parameter SCALE_DATA = 10'd128,
	parameter SCALE_STATE =  10'd128,
	parameter SCALE_W = 10'd128,
	parameter SCALE_B = 10'd256,

	parameter ZERO_DATA = 10'd128,
	parameter ZERO_STATE = 10'd128,
	parameter ZERO_W = 10'd128,
	parameter ZERO_B = 10'd0,
	
	parameter SCALE_SIGMOID = 10'd24,
	parameter SCALE_TANH = 10'd48,

	parameter ZERO_SIGMOID = 10'd128,
	parameter ZERO_TANH = 10'd128,

	parameter OUT_SCALE_SIGMOID = 10'd256,
	parameter OUT_SCALE_TANH = 10'd128,

	parameter OUT_ZERO_SIGMOID = 10'd0,
	parameter OUT_ZERO_TANH = 10'd128
	
)
(
	input clk,
	input resetn,
	
	input iInit_valid,
	input [7:0] iInit_data,
	output oInit_done,
	
	input iLoad_valid,	// load ct/ht valid
	input [511:0] iBr_Ct_load,
	input [511:0] iBr_Ht_load,

	input iNext_valid,	// top valid & ready. 
	input iType,		// System or Branch mode
	input [511:0] iData,
	
	output reg oLstm_done,	// lstm done & ready to do next task. 
	output reg [511:0] oBr_Ct,	// Wire actually
	output reg [511:0] oBr_Ht,		
)

	localparam IDLE = 3'd0, SYSTEM = 3'd1, BRANCH = 3'd2, INITIALIZE_W_B = 3'd3, ERROR = 3'd4;
	localparam SYS_type = 1'b0, BR_type = 1'b1; 	
	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4, B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ = 5'd7, B_TMQ = 5'd8;

	integer i;

// output oBr_Ct / oBr_Ht ALLOCATION
	always@(*) begin
		for(i=0; i<64; i++) begin
			oBr_Ct[8*i+:8] = Br_Ct[i]	// ????????????????????????????????????????????????? Order OK ???
			oBr_Ht[8*i+:8] = Br_Ht[i]		
		end
	end


////////
//    //
////////
	reg [1:0] lstm_state;
	reg [31:0] counter;

	reg [7:0] init_data_buff1;
	reg [7:0] init_data_buff2;	

////////
//    //
////////
	reg [7:0] Sys_Ct [0:7];
	reg [7:0] Sys_Ht [0:7];
	reg [7:0] Br_Ct [0:63];
	reg [7:0] Br_Ht [0:63];

	reg [15:0] temp_regA_1;
	reg [15:0] temp_regB_1;
	reg [15:0] temp_regC_1;

	reg [15:0] temp_regA_2;
	reg [15:0] temp_regB_2;
	reg [15:0] temp_regC_2;

	reg [20:0] lstm_result_1;
	reg [20:0] lstm_result_2;

	reg signed [22:0] inpdt_R_reg1;	// ?????????????????????????????????????????????????????
	reg signed [22:0] inpdt_R_reg2;	


//////////////////
// inpdt IN/OUT //
//////////////////
	reg [1:0] inpdt_X_select;
	
	reg inpdt_EN;
	reg [127:0] inpdt_X1;
	reg [127:0] inpdt_X2;
	wire [127:0] inpdt_W1;
	wire [127:0] inpdt_W2;
	wire [20:0] inpdt_R_wire1;
	wire [20:0] inpdt_R_wire2;


/////////////////
// Weight BRAM //
/////////////////
	reg [10:0] weight_bram_addr;
	reg weight_bram_EN;
	reg weight_bram_WE;
	reg [255:0] weight_bram_Wdata;
	wire [255:0] weight_bram_Rdata;
	reg [255:0] weight_buffer;


///////////////
// BIAS BRAM //
///////////////
	reg [8:0] bias_bram_addr;
	reg bias_bram_EN;
	reg bias_bram_WE;
	reg [15:0] bias_bram_Wdata;
	wire [15:0] bias_bram_Rdata;
	reg [15:0] bias_buffer;	


//////////////////
// Quantization //
//////////////////
	reg [23:0] iQ_bias_to_sig1;
	reg [23:0] iQ_bias_to_sig2;	
	reg [23:0] iQ_bias_to_tanh1;
	reg [23:0] iQ_bias_to_tanh2;	
	reg [16:0] iQ_add_to_ct1;
	reg [16:0] iQ_add_to_ct2;	
	reg [15:0] iQ_calc_to_ht1;
	reg [15:0] iQ_calc_to_ht2;
	
	wire [7:0] oQ_bias_to_sig1;
	wire [7:0] oQ_bias_to_sig2;	
	wire [7:0] oQ_bias_to_tanh1;
	wire [7:0] oQ_bias_to_tanh2;	
	wire [7:0] oQ_add_to_ct1;
	wire [7:0] oQ_add_to_ct2;	
	wire [7:0] oQ_calc_to_ht1;
	wire [7:0] oQ_calc_to_ht2;

//////////////////
// Sig/Tanh LUT //
//////////////////
	reg [7:0] iSigmoid_LUT1;
	reg [7:0] iSigmoid_LUT2;	
	reg [7:0] iTanh_LUT1;
	reg [7:0] iTanh_LUT2;

	wire [7:0] oSigmoid_LUT1;
	wire [7:0] oSigmoid_LUT2;	
	wire [7:0] oTanh_LUT1;
	wire [7:0] oTanh_LUT2;

	
////////////////////////
// Combinational CTRL //
////////////////////////
	reg [4:0] comb_ctrl;
	reg [5:0] TMQ_Ct_select;

	
	
// *****************************************************************************//	
// *****************************************************************************//	
//								Instantiation									//
// *****************************************************************************//	
// *****************************************************************************//
	
	
//////////////////
// LSTM Modules //
//////////////////
	inpdt_16 u_inpdt_1(
		iData_X(inpdt_X1),
		iData_W(inpdt_W1),
		iEn(inpdt_EN),
		oResult(inpdt_R_wire1)
	);

	inpdt_16 u_inpdt_2(
		iData_X(inpdt_X2),
		iData_W(inpdt_W2),
		iEn(inpdt_EN),
		oResult(inpdt_R_wire2)
	);

	always@(*) begin
		if(inpdt_mode == SYS_type) begin
			inpdt_X1 = {iData[63:0],iData[63:0]};
			inpdt_X2 = {iData[63:0],iData[63:0]};
		end
		else if(inpdt_mode == BR_type) begin
			case(inpdt_X_select)
				2'b11: begin
					inpdt_X1_temp = iData[511:384];
					inpdt_X2_temp = iData[511:384];					
				end
				2'b10: begin
					inpdt_X1_temp = iData[383:256];
					inpdt_X2_temp = iData[383:256];					
				end
				2'b01: begin
					inpdt_X1_temp = iData[255:128];
					inpdt_X2_temp = iData[255:128];					
				end
				2'b00: begin
					inpdt_X1_temp = iData[127:0];
					inpdt_X2_temp = iData[127:0];		
				end
			endcase
		end
	end
	assign inpdt_W1 = weight_buffer[255:128];
	assign inpdt_W2 = weight_buffer[127:0];


///////////
// Brams //
///////////
	BRAM_256x2048 WEIGHT_BRAM(
		clka(clk),
		rstna(resetn),
		ea(weight_bram_EN),
		wea(weight_bram_WE),
		addra(weight_bram_addr),
		dina(weight_bram_Wdata),
		douta(weight_bram_Rdata)	
	);

	BRAM_16x512 BIAS_BRAM(
		clka(clk),
		rstna(resetn),
		en(bias_bram_EN),
		wea(bias_bram_WE),
		addra(bias_bram_addr),
		dina(bias_bram_Wdata),
		douta(bias_bram_Rdata)	
	);


///////////////////
// Quantizations //
//////////////////

// 1. BiasADD_to_Sigmoid - Sys

// 2. BiasADD_to_Tanh - Br

// 3. Add_to_Ct - 

// 4. Calc_to_Ht - 


//////////////////
// Sig/Tan LUTs //
//////////////////

// 1. Sigmoid LUT

// 2. Tanh LUT







// *****************************************************************************//
// *****************************************************************************//	
//									FSM / CTRL									//
// *****************************************************************************//	
// *****************************************************************************//


//////////////
// LSTM FSM //
////////'/////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			lstm_state <= IDLE;
			oLstm_done <= 1'b1;
			oInit_done <= 1'b0;
			counter <= 'd0;
		end
		else begin		
		
			case(lstm_state)
			
				IDLE: begin
					if(iInit_valid && !oInit_done) begin
						lstm_state <= INITIALIZE_W_B;
					end
					else begin
						if(iNext_valid) begin
							if(iType == SYS_type) begin
								lstm_state <= SYSTEM;
								oLstm_done <= 1'b0;
							end
							else if(iType == BR_type) begin
								lstm_state <= BRANCH;
								oLstm_done <= 1'b0;
							end
						end
					end
				end
				
				SYSTEM: begin
					if(counter == 26) begin 
						lstm_state <= IDLE;
						oLstm_done <= 1'b1;
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end
				
				BRANCH: begin
					if(counter == /* ???????? */ ) begin
						lstm_state <= IDLE;
						oLstm_done <= 1'b1;
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end

				INITIALIZE_W_B: begin
					if(!iInit_valid) begin
						lstm_state <= IDLE;
						oInit_done <= 1'b1;
						counter <= 'd0;
					end
					else begin
						counter <= counter + 1;
					end
				end

				ERROR: begin
					lstm_state <= ERROR;
					oLstm_done <= 1'b0;			
					counter <= 'd0;							
				end	

				default: begin
					lstm_state <= ERROR;			
					oLstm_done <= 1'b0;			
					counter <= 'd0;				
				end
			
			endcase
		end	
	end

////////////////////////
// Counter Based Ctrl //
////////////////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin

			init_data_buff1 <= 'd0;
			init_data_buff2 <= 'd0;

			Br_Ct <= 'd0;
			Br_Ht <= 'd0;
			Sys_Ct <= 'd0;
			Sys_Ht <= 'd0;

			temp_regA_1 <= 'd0;
			temp_regB_1 <= 'd0;
			temp_regC_1 <= 'd0;
			temp_regA_2 <= 'd0;
			temp_regB_2 <= 'd0;
			temp_regC_2 <= 'd0;
			lstm_result_1 <= 'd0;
			lstm_result_2 <= 'd0;
			inpdt_R_reg1 <= 'd0;
			inpdt_R_reg2 <= 'd0;				

			inpdt_X_select <= 'd0;
			inpdt_EN <= 'd0;
			
			weight_bram_addr <= 'd0;
			weight_bram_EN <= 'd0;
			weight_bram_WE <= 'd0;
			weight_bram_Wdata <= 'd0;
			weight_buffer <= 'd0;

			bias_bram_addr <= 'd0;
			bias_bram_EN <= 'd0;
			bias_bram_WE <= 'd0;
			bias_bram_Wdata <= 'd0;
			bias_bram_Rdata <= 'd0;
			bias_buffer <= 'd0;			
		
			comb_ctrl <= comb_IDLE;
			TMQ_Ct_select <= 'd0;
		end
		else begin
			
			weight_buffer <= weight_bram_Rdata;
			bias_buffer <= bias_bram_Rdata;
			
			if(iInit_valid) begin
				init_data_buff1 <= iInit_data;
				init_data_buff2 <= init_data_buff1;
			end

			//** CTRL by lstm_state **//
			case(lstm_state)
			
				IDLE: begin
					if(iLoad_valid) begin
						for(i=0; i<64; i++) begin
							Br_Ct[i] <= iBr_Ct_load[8*i+:8];
							Br_Ht[i] <= iBr_Ht_load[8*i+:8];							
						end
					end
				end
				
				INITIALIZE_W_B: begin	// ??????????????????????????????????????????????????????????? IMPLEMENTED Only for SYS Case.
				
					if(counter <= 511) begin
						weight_bram_Wdata[counter%4] init_data_buff2
						



					end				
				end
				
				SYSTEM: begin
				
					//**** 1. WEIGHT BRAM CTRL ****//
					if( (24 <= counter) && (counter <= 26) ) begin	// Exception.
						weight_bram_EN <= 1'b0;
					end
					else if( counter == 0 ) begin					// Initialize addr.
						weight_bram_EN <= 1'b1;
						weight_bram_addr <= 'd0; 
					end
					
					else if( (0 <= counter%6) && (counter%6 <= 3) ) begin
						weight_bram_EN <= 1'b1;
						weight_bram_addr <= weight_bram_addr + 1;
					end
					else if( (4 <= counter%6) && (counter%6 <= 5) ) begin	// WAIT
						weight_bram_EN <= 1'b0;
					end

					//**** 2. BIAS BRAM CTRL ****//
					if( (24 <= counter) && (counter <= 26) ) begin	// Exception
						weight_bram_EN <= 1'b0;
					end
					else if( counter == 1 ) begin					// Initialize addr.
						bias_bram_EN <= 1'b1;
						bias_bram_addr <= 'd0;						
					end
					
					else if( (1 <= counter%6) && (counter%6 <= 4) ) begin
						bias_bram_EN <= 1'b1;
						bias_bram_addr <= bias_bram_addr + 1;
					end
					else if( (counter%6 == 0) || (counter%6 == 5) ) begin
						bias_bram_EN <= 1'b0;
					end

					//**** 3. INPDT CTRL ****//
					if(counter == 26) begin	// Exception. Getting Last Ht.
						inpdt_EN <= 1'b0;
					end
					else if( (2 <= counter%6) && (counter%6 <= 5) ) begin
						inpdt_EN <= 1'b1;
						inpdt_R_reg1[22:0] <= inpdt_R_wire1[20:0];	// ????????????????????????????????????????????????????? signed OK?
						inpdt_R_reg2[22:0] <= inpdt_R_wire2[20:0];		
					end
					else if( (0 <= counter%6) && (counter%6 <= 1) ) begin	// WAIT
						inpdt_EN <= 1'b0;
					end
					
					//**** 4. Register CTRL ****//
					if( (0<=counter) && (counter<=2) ) begin
						// Nothing
					end
					else if(counter%6 == 4) begin
						temp_regA_1[7:0] <= oSigmoid_LUT1[7:0];	// ?????????????????????????????????????????????????? signed OK?
						temp_regA_2[7:0] <= oSigmoid_LUT2[7:0];
					end
					else if(counter%6 == 5) begin
						temp_regA_1[15:0] <= Sys_Ct[2*(counter/6)]*temp_regA_1;
						temp_regA_2[15:0] <= Sys_Ct[2*(counter/6)+1]*temp_regA_2;
						
						temp_regB_1[7:0] <= oSigmoid_LUT1[7:0];
						temp_regB_2[7:0] <= oSigmoid_LUT2[7:0];						
					end
					else if(counter%6 == 0) begin
						temp_regC_1[7:0] <= oTanh_LUT1[7:0];
						temp_regC_2[7:0] <= oTanh_LUT2[7:0];						
					end
					else if(counter%6 == 1) begin
						temp_regA_1[7:0] <= oSigmoid_LUT1[7:0];
						temp_regA_2[7:0] <= oSigmoid_LUT2[7:0];
						
						Sys_Ct[2*( (counter/6)-1 )] <= oQ_add_to_ct1[7:0];
						Sys_Ct[2*( (counter/6)-1 )+1] <= oQ_add_to_ct2[7:0];						
					end
					else if(counter%6 == 2) begin
						Sys_Ht[2*( (counter/6)-1 )] <= oQ_calc_to_ht1[7:0];
						Sys_Ht[2*( (counter/6)-1 )+1] <= oQ_calc_to_ht2[7:0];						
					end
					
					//**** 5. Combinational CTRL ****//
					if(counter <= 2) begin
						comb_ctrl <= comb_IDLE;
					end
					else if( (counter%6 == 3) || (counter%6 == 4)) begin
						comb_ctrl <= BQS;
					end
					else if(counter%6 == 5) begin
						comb_ctrl <= BQT;
					end
					else if(counter%6 == 0) begin
						comb_ctrl <= MAQ_BQS;
					end
					else if(counter%6 == 1) begin
						comb_ctrl <= TMQ;
						TMQ_Ct_select <= (counter/6)-1;
					end
					else if(counter%6 == 2) begin
						comb_ctrl <= comb_IDLE;
					end
				end
			
				BRANCH: begin
					//**** 1. WEIGHT BRAM CTRL ****//
					
					
					//**** 2. BIAS BRAM CTRL ****//
					
					
					//**** 3. INPDT CTRL ****//
					if(counter <= 1) begin
						inpdt_EN <= 1'b0;
					end
					else if(2 <= counter%18) begin
						inpdt_EN <= 1'b1;
							
					end
					else if(counter%18 <= 1) begin
						inpdt_EN <= 1'b0;
						
					end
					
					
					//**** 4. Register CTRL ****//
					
				
					//**** 5. Combinational CTRL ****//					
					
					
				end
		
		
				default: begin
				
				end
		
			endcase
			
		end
	end


//////////////////////////////
// Ctrl Combinational Logic //
//////////////////////////////
	always@(*) begin
		case(comb_ctrl)
			comb_IDLE: begin
				iQ_bias_to_sig1 = 'd0;
				iQ_bias_to_sig2 = 'd0;	
				iQ_bias_to_tanh1 = 'd0;
				iQ_bias_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_calc_to_ht1 = 'd0;
				iQ_calc_to_ht2 = 'd0;

				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;	
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;			
			end
		
			S_BQS: begin
				iQ_bias_to_sig1[23:0] = inpdt_R_reg1[22:0] + bias_bram_Rdata[15:8];	// ??????????????????????????????????????????????????? Signed ? 
				iQ_bias_to_sig2[23:0] = inpdt_R_reg2[22:0] + bias_bram_Rdata[7:0];	
				iQ_bias_to_tanh1 = 'd0;
				iQ_bias_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_calc_to_ht1 = 'd0;
				iQ_calc_to_ht2 = 'd0;

				iSigmoid_LUT1[7:0] = oQ_bias_to_sig1[7:0];
				iSigmoid_LUT2[7:0] = oQ_bias_to_sig2[7:0];	
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;								
			end
			
			S_BQT: begin
				iQ_bias_to_sig1 = 'd0;
				iQ_bias_to_sig2 = 'd0;	
				iQ_bias_to_tanh1[23:0] = inpdt_R_reg1[22:0] + bias_bram_Rdata[15:8];
				iQ_bias_to_tanh2[23:0] = inpdt_R_reg2[22:0] + bias_bram_Rdata[7:0];	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_calc_to_ht1 = 'd0;
				iQ_calc_to_ht2 = 'd0;

				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;	
				iTanh_LUT1 = oQ_bias_to_tanh1;
				iTanh_LUT2 = oQ_bias_to_tanh2;						
			end
		
			S_MAQ_BQS: begin
				iQ_bias_to_sig1[23:0] = inpdt_R_reg1[22:0] + bias_bram_Rdata[15:8];
				iQ_bias_to_sig2[23:0] = inpdt_R_reg2[22:0] + bias_bram_Rdata[7:0];	
				iQ_bias_to_tanh1 = 'd0;
				iQ_bias_to_tanh2 = 'd0;	
				iQ_add_to_ct1[16:0] = (temp_regB_1[15:0]*temp_regC_1[15:0]) + temp_regA_1[15:0];
				iQ_add_to_ct2[16:0] = (temp_regB_2[15:0]*temp_regC_2[15:0]) + temp_regA_2[15:0];	
				iQ_calc_to_ht1 = 'd0;
				iQ_calc_to_ht2 = 'd0;

				iSigmoid_LUT1[7:0] = oQ_bias_to_sig1[7:0];
				iSigmoid_LUT2[7:0] = oQ_bias_to_sig2[7:0];	
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;					
			end
		
			S_TMQ: begin
				iQ_bias_to_sig1 = 'd0;
				iQ_bias_to_sig2 = 'd0;	
				iQ_bias_to_tanh1 = 'd0;
				iQ_bias_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_calc_to_ht1[15:0] = oTanh_LUT1[7:0]*temp_regA_1[7:0];
				iQ_calc_to_ht2[15:0] = oTanh_LUT2[7:0]*temp_regA_2[7:0];

				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;
				iTanh_LUT1 = Sys_Ct[TMQ_Ct_select];
				iTanh_LUT2 = Sys_Ct[TMQ_Ct_select+1];					
			end
			B_BQS:
			B_BQT:
			B_MAQ:
			B_TMQ:
			
			default: 
		
		endcase
	end






endmodule
