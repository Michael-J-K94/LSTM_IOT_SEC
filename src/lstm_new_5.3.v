// This is a Top
// Description:
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
	
	input iLoad_valid,	// load ct/ht valid
	input [511:0] iBr_Ct_load,
	input [511:0] iBr_Ht_load,

	input iNext_valid,	// top valid & ready. 
	input iType,		// System or Branch mode
	input [511:0] iData,
	
	output reg oLstm_done,	// lstm done & ready to do next task. 
	output reg [511:0] oBr_Ct,	
	output reg [511:0] oBr_Ht,		
)

	localparam IDLE = 2'd0, SYSTEM = 2'd1, BRANCH = 2'd2, ERROR = 2'd3;
	localparam SYS_type = 1'b0, BR_type = 1'b1; 	

////////
//    //
////////
	reg [1:0] lstm_state;
	reg [10:0] counter;


////////
//    //
////////
	reg [63:0] Sys_Ct;
	reg [63:0] Sys_Ht;


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
	wire [7:0] sigmoid_LUT_result1;
	wire [7:0] sigmoid_LUT_result2;
	wire [7:0] tanh_LUT_result1;
	wire [7:0] tanh_LUT_result2;	
	
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
					inpdt_X1 = iData[511:384];
					inpdt_X2 = iData[511:384];					
				end
				2'b10: begin
					inpdt_X1 = iData[383:256];
					inpdt_X2 = iData[383:256];					
				end
				2'b01: begin
					inpdt_X1 = iData[255:128];
					inpdt_X2 = iData[255:128];					
				end
				2'b00: begin
					inpdt_X1 = iData[127:0];
					inpdt_X2 = iData[127:0];					
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
		clka(),
		rstna(),
		wea(),
		addra(),
		dina(),
		douta()	
	);

	BRAM_16x512 BIAS_BRAM(
		clka(),
		rstna(),
		wea(),
		addra(),
		dina(),
		douta()	
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


/////////////////////////////////////
// INITIALIZATION of WEIGHT / BIAS //
/////////////////////////////////////




//////////////
// LSTM FSM //
////////'/////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			state <= IDLE;
			oLstm_done <= 1'b1;
			
			counter <= 'd0;
		end
		else begin		
		
			case(state)
			
				IDLE: begin
					if(iNext_valid) begin
						if(iType == SYS_type) begin
							state <= SYSTEM;
							oLstm_done <= 1'b0;
						end
						else if(iType == BR_type) begin
							state <= BRANCH;
							oLstm_done <= 1'b0;
						end
					end
				end
				
				SYSTEM: begin
					if(counter == /* ???????? */ ) begin 
						state <= IDLE;
						oLstm_done <= 1'b1;
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end
				
				BRANCH: begin
					if(counter == /* ???????? */ ) begin
						state <= IDLE;
						oLstm_done <= 1'b1;
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end

				ERROR: begin
					state <= ERROR;
					oLstm_done <= 1'b0;			
					counter <= 'd0;							
				end	

				default: begin
					state <= ERROR;			
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

			oBr_Ct <= 'd0;
			oBr_Ht <= 'd0;
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
		
		end
		else begin
			
			weight_buffer <= weight_bram_Rdata;
			bias_buffer <= bias_bram_Rdata;
			
			case(state)
				IDLE: begin
					if(iLoad_valid) begin
						oBr_Ct <= iBr_Ct_load;
						oBr_Ht <= iBr_Ht_load;
					end
				
				end
				INITIALIZE_W_B: begin
				
				
				
				end
				SYSTEM: begin
				
					//** 1. WEIGHT BRAM CTRL
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

					//** 2. BIAS BRAM CTRL
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

					//** 3. INPDT CTRL
					if( counter <= 26) begin	// Exception. Getting Last Ht.
						inpdt_EN <= 1'b0;
					end
					else if( (2 <= counter%6) && (counter%6 <= 5) ) begin
						inpdt_EN <= 1'b1;
						inpdt_R_reg1 <= inpdt_R_wire1;	// ????????????????????????????????????????????????????? signed OK?
						inpdt_R_reg2 <= inpdt_R_wire2;		
					end
					else if( (0 <= counter%6) && (counter%6 <= 1) ) begin	// WAIT
						inpdt_EN <= 1'b0;
					end
					
					//** 4. Register CTRL
					if( (0<=counter) && (counter<=2) ) begin
						// Nothing
					end
					else if(counter%6 == 4) begin
						temp_regA_1 <= sigmoid_LUT_result1;	// ?????????????????????????????????????????????????? signed OK?
						temp_regA_2 <= sigmoid_LUT_result2;
					end
					else if(counter%6 == 5) begin
						temp_regA_1 <= Sys_Ct[2*(counter/6)]*temp_regA_1;
						temp_regA_2 <= Sys_Ct[2*(counter/6)+1]*temp_regA_2;
						
						temp_regB_1 <= sigmoid_LUT_result1;
						temp_regB_2 <= sigmoid_LUT_result2;						
					end
					else if(counter%6 == 0) begin
						temp_regC_1 <= tanh_LUT_result1;
						temp_regC_2 <= tanh_LUT_result2;						
					end
					else if(counter%6 == 1) begin
						temp_regA_1 <= sigmoid_LUT_result1;
						temp_regA_2 <= sigmoid_LUT_result2;
						
						Sys_Ct[2*( (counter/6)-1 )] <= oQ_add_to_ct1;
						Sys_Ct[2*( (counter/6)-1 )+1] <= oQ_add_to_ct2;						
					end
					else if(counter%6 == 2) begin
						Sys_Ht[2*( (counter/6)-1 )] <= oQ_calc_to_ht1;
						Sys_Ht[2*( (counter/6)-1 )+1] <= oQ_calc_to_ht2;						
					end
					
					//** 5. Combinational CTRL
					
					
					
					
				end
			
				BRANCH: begin
				
				end
		
		
				default: begin
				
				end
		
			endcase
			
		end
	end





//////////////////////////////
// Ctrl Combinational Logic //
//////////////////////////////







endmodule
