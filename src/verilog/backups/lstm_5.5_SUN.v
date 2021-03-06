// This is a LSTM
// Description: 

// TODO: 
/*
	*1. Endian Check
	*2. Weight / Bias SRAM Allocation
	
	*3. Quantization 
	*3-1. Bit Width
	3-2. RECHECK BIT_WIDTH
	
	*4. LUT instantiation
	*5. INPDT input allocation
	
	6. Branch Counter CTRL
	7. Might Want to Fix the COMB Logic Structure
*/


// Author: Michael Kim

module LSTM#(

	parameter SCALE_DATA = 10'd128,		// Xt, Ht
	parameter SCALE_STATE =  10'd128,	// Ct
	parameter SCALE_W = 10'd128,
	parameter SCALE_B = 10'd256,

	parameter ZERO_DATA = 8'd128,
	parameter ZERO_STATE = 8'd128,
	parameter ZERO_W = 8'd128,			// 9bit ??????????????? 
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
	input clk,
	input resetn,
	
	input iInit_valid,
	input [7:0] iInit_data,
	input [2:0] iInit_type,
	output reg oInit_done,
	
	input iLoad_valid,	// load ct/ht valid
	input [511:0] iBr_Ct_load,
	input [511:0] iBr_Ht_load,

	input iNext_valid,	// top valid & ready. 
	input iType,		//
	input [511:0] iData,
	
	output reg oLstm_done,	// lstm done & ready to do next task. 
	output reg [511:0] oBr_Ct,	// Wire actually
	output reg [511:0] oBr_Ht,
	output reg [63:0] oSys_Ct,
	output reg [63:0] oSys_Ht
);

	localparam IDLE = 3'd0, SYSTEM = 3'd1, BRANCH = 3'd2, INITIALIZE_W_B = 3'd3, ERROR = 3'd4;
	localparam SYS_type = 1'b0, BR_type = 1'b1; 	
	localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4, B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ = 5'd7, B_TMQ = 5'd8;

	integer i;


////////
//    //
////////
	reg [1:0] lstm_state;
	reg [31:0] counter;
	reg init_valid_buff;

	reg [7:0] init_data_buff1;
	reg [7:0] init_data_buff2;	
	reg [7:0] init_weight_buff [0:15];

////////
//    //
////////
	reg [7:0] Sys_Ct [0:7];
	reg [7:0] Sys_Ht [0:7];
	reg [7:0] Sys_Ht_temp [0:7];
	reg [7:0] Br_Ct [0:63];
	reg [7:0] Br_Ht [0:63];

	reg [16:0] temp_regA_1;
	reg [7:0] temp_regB_1;
	reg [7:0] temp_regC_1;

	reg [16:0] temp_regA_2;
	reg [7:0] temp_regB_2;
	reg [7:0] temp_regC_2;

	reg [23:0] inpdt_R_reg1;		// Can Be Used as signed
	reg [23:0] inpdt_R_reg2;	


//////////////////
// inpdt IN/OUT //
//////////////////
	reg [1:0] inpdt_X_select;
	
	reg inpdt_EN;
	reg [143:0] inpdt_X1;
	reg [143:0] inpdt_X2;
	reg [143:0] inpdt_W1;
	reg [143:0] inpdt_W2;
	
	reg [8:0] TEMP_inpdt_W1 [0:15];
	
	wire [20:0] inpdt_R_wire1;		// Comes Out as Signed
	wire [20:0] inpdt_R_wire2;


/////////////////
// Weight BRAM //
/////////////////
	reg weight_bram_EN;

	reg [10:0] weight_bram_addr1;	
	reg [10:0] weight_bram_addr2;	
	reg weight_bram_WE1;
	reg weight_bram_WE2;	
	reg [127:0] weight_bram_Wdata1;
	reg [127:0] weight_bram_Wdata2;	
	wire [127:0] weight_bram_Rdata1;
	wire [127:0] weight_bram_Rdata2;	

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
/***** Quantization MEANS Saturating & 8bit Quantizing (After scale/zero operation) *****/
	reg [23:0] iQ_sum_to_sig1;		
	reg [23:0] iQ_sum_to_sig2;	
	reg [23:0] iQ_sum_to_tanh1;
	reg [23:0] iQ_sum_to_tanh2;	
	reg [31:0] iQ_add_to_ct1;
	reg [31:0] iQ_add_to_ct2;	
	reg [31:0] iQ_mul_to_ht1;
	reg [31:0] iQ_mul_to_ht2;
	reg [31:0] iQ_ct_to_tanh1;
	reg [31:0] iQ_ct_to_tanh2;	
		
	reg [31:0] temp_sum_to_sig1;	
	wire [31:0] sum_to_sig1_realsum;
	wire [31:0] sum_to_sig1_realbias;
	reg [31:0] temp_sum_to_sig2;
	reg [31:0] temp_sum_to_tanh1;
	reg [31:0] temp_sum_to_tanh2;
	reg [31:0] temp_add_to_ct1;
	reg [31:0] temp_add_to_ct2;	
	reg [31:0] temp_mul_to_ht1;
	reg [31:0] temp_mul_to_ht2;
	reg [31:0] temp_ct_to_tanh1;
	reg [31:0] temp_ct_to_tanh2;	
		
	reg [7:0] oQ_sum_to_sig1;
	reg [7:0] oQ_sum_to_sig2;	
	reg [7:0] oQ_sum_to_tanh1;
	reg [7:0] oQ_sum_to_tanh2;	
	reg [7:0] oQ_add_to_ct1;
	reg [7:0] oQ_add_to_ct2;	
	reg [7:0] oQ_mul_to_ht1;
	reg [7:0] oQ_mul_to_ht2;
	reg [7:0] oQ_ct_to_tanh1;
	reg [7:0] oQ_ct_to_tanh2;	

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
	reg [5:0] inpdt_element_select;
	reg [5:0] tanh_Ct_select;

	
	
// *****************************************************************************//	
// *****************************************************************************//	
//								Instantiation									//
// *****************************************************************************//	
// *****************************************************************************//

// output oBr_Ct / oBr_Ht ALLOCATION
	always@(*) begin
		for(i=0; i<64; i=i+1) begin
			oBr_Ct[512-8*(i+1)+:8] = Br_Ct[i];
			oBr_Ht[512-8*(i+1)+:8] = Br_Ht[i];		
		end
	end	
	always@(*) begin
		for(i=0; i<8; i=i+1) begin
			oSys_Ct[64-8*(i+1)+:8] = Sys_Ct[i];
			oSys_Ht[64-8*(i+1)+:8] = Sys_Ht[i];			
		end
	end	
	
//////////////////
// LSTM Modules //
//////////////////
	inpdt_16 u_inpdt_1(
		.iData_XH(inpdt_X1),
		.iData_W(inpdt_W1),
		.iEn(inpdt_EN),
		.oResult(inpdt_R_wire1)
	);

	inpdt_16 u_inpdt_2(
		.iData_XH(inpdt_X2),
		.iData_W(inpdt_W2),
		.iEn(inpdt_EN),
		.oResult(inpdt_R_wire2)
	);
	always@(*) begin
		if(lstm_state == SYSTEM) begin			
			for(i=0; i<8; i=i+1) begin
				inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0,iData[64-8*(i+1)+:8]}) - $signed({1'b0,ZERO_DATA});
			end
			for(i=0; i<8; i=i+1) begin
				inpdt_X1[72-9*(i+1)+:9] = $signed({1'b0,Sys_Ht[i]} - {1'b0,ZERO_DATA});
			end
			for(i=0; i<8; i=i+1) begin
				inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0,iData[64-8*(i+1)+:8]} - {1'b0,ZERO_DATA});
			end
			for(i=0; i<8; i=i+1) begin
				inpdt_X2[72-9*(i+1)+:9] = $signed({1'b0,Sys_Ht[i]} - {1'b0,ZERO_DATA});
			end			
		end
		else if(lstm_state == BRANCH) begin
			inpdt_X1[127:0] = iData[512-(inpdt_element_select+1)*128+:128];	// ???????????????????????????????????????????			
			for(i=0; i<16; i=i+1) begin
				inpdt_X2[128-(i+1)*8+:8] = Br_Ht[inpdt_element_select*16 + i];
			end
		end	
		else begin
			inpdt_X1 = 'd0;
			inpdt_X2 = 'd0;
		end
	end
	
	
	
	always@(*) begin
		for(i=0; i<16; i=i+1) begin
			TEMP_inpdt_W1[i] = $signed({1'b0,weight_buffer[256-8*(i+1)+:8]}) - $signed({1'b0,ZERO_W});
		end
		for(i=0; i<16; i=i+1) begin
			//inpdt_W1[144-9*(i+1)+:9] = $signed({1'b0,weight_buffer[256-8*(i+1)+:8]}) - $signed({1'b0,ZERO_W});
			inpdt_W1[144-9*(i+1)+:9] = TEMP_inpdt_W1[i];			
			inpdt_W2[144-9*(i+1)+:9] = $signed({1'b0,weight_buffer[128-8*(i+1)+:8]}) - $signed({1'b0,ZERO_W});
		end	
	end


///////////
// Brams //
///////////
	SRAM_128x2048 WEIGHT_BRAM1(
		.CLK(clk),
		.EN_M(weight_bram_EN),
		.WE(weight_bram_WE1),
		.ADDR(weight_bram_addr1),
		.ADDR_WRITE(weight_bram_addr1),
		.DIN(weight_bram_Wdata1),
		.DOUT(weight_bram_Rdata1)	
	);

	SRAM_128x2048 WEIGHT_BRAM2(
		.CLK(clk),
		.EN_M(weight_bram_EN),
		.WE(weight_bram_WE2),
		.ADDR(weight_bram_addr2),
		.ADDR_WRITE(weight_bram_addr2),
		.DIN(weight_bram_Wdata2),
		.DOUT(weight_bram_Rdata2)	
	);
	
	SRAM_16x512 BIAS_BRAM(
		.CLK(clk),
		.EN_M(bias_bram_EN),
		.WE(bias_bram_WE),
		.ADDR(bias_bram_addr),
		.ADDR_WRITE(bias_bram_addr),		
		.DIN(bias_bram_Wdata),
		.DOUT(bias_bram_Rdata)	
	);


///////////////////
// Quantizations //
//////////////////

// 1. ADD_to_Sigmoid - 
	assign sum_to_sig1_realsum = ($signed(iQ_sum_to_sig1)*SCALE_SIGMOID)/(SCALE_DATA*SCALE_W);
	assign sum_to_sig1_realbias = (($signed({1'b0,bias_bram_Rdata[15:8]})-$signed({1'b0,ZERO_B}))*SCALE_SIGMOID)/(SCALE_B);

	always@(*) begin
		// Q_sum_to_sig1
		temp_sum_to_sig1 = $signed(sum_to_sig1_realsum) + $signed(sum_to_sig1_realbias) + $signed({1'b0,ZERO_SIGMOID});
			
		if(temp_sum_to_sig1[31] == 1) begin
			oQ_sum_to_sig1 = 8'd0;
		end
		else begin
			if(|temp_sum_to_sig1[30:8] == 1) begin
				oQ_sum_to_sig1 = 8'd255;
			end
			else begin
				oQ_sum_to_sig1 = temp_sum_to_sig1[7:0];
			end
		end
		
		// Q_sum_to_sig2
		temp_sum_to_sig2 = ( ($signed(iQ_sum_to_sig2)*SCALE_SIGMOID)/(SCALE_DATA*SCALE_W) 
		+ (($signed({1'b0,bias_bram_Rdata[7:0]})-$signed({1'b0,ZERO_B}))*SCALE_SIGMOID)/SCALE_B + $signed({1'b0,ZERO_SIGMOID}) );	
		
		if(temp_sum_to_sig2[31] == 1) begin
			oQ_sum_to_sig2 = 8'd0;
		end
		else begin
			if(|temp_sum_to_sig2[30:8] == 1) begin
				oQ_sum_to_sig2 = 8'd255;
			end
			else begin
				oQ_sum_to_sig2 = temp_sum_to_sig2[7:0];
			end
		end		
	end

// 2. ADD_to_Tanh - 
	always@(*) begin
		// Q_sum_to_sig1
		temp_sum_to_tanh1 = ( ($signed(iQ_sum_to_tanh1)*SCALE_TANH)/(SCALE_DATA*SCALE_W) 
		+ (($signed({1'b0,bias_bram_Rdata[15:8]})-$signed({1'b0,ZERO_B}))*SCALE_TANH)/SCALE_B + $signed({1'b0,ZERO_TANH}) );
		
		if(temp_sum_to_tanh1[31] == 1) begin
			oQ_sum_to_tanh1 = 8'd0;
		end
		else begin
			if(|temp_sum_to_tanh1[30:8] == 1) begin
				oQ_sum_to_tanh1 = 8'd255;
			end
			else begin
				oQ_sum_to_tanh1 = temp_sum_to_tanh1[7:0];
			end
		end
		
		// Q_sum_to_sig2
		temp_sum_to_tanh2 = ( ($signed(iQ_sum_to_tanh2)*SCALE_TANH)/(SCALE_DATA*SCALE_W) 
		+ (($signed({1'b0,bias_bram_Rdata[7:0]})-$signed({1'b0,ZERO_B}))*SCALE_TANH)/SCALE_B + $signed({1'b0,ZERO_TANH}) );	
		
		if(temp_sum_to_tanh2[31] == 1) begin
			oQ_sum_to_tanh2 = 8'd0;
		end
		else begin
			if(|temp_sum_to_tanh2[30:8] == 1) begin
				oQ_sum_to_tanh2 = 8'd255;
			end
			else begin
				oQ_sum_to_tanh2 = temp_sum_to_tanh2[7:0];
			end
		end		
	end

// 3. Add_to_Ct - 
	always@(*) begin
		// Q_add_to_ct1
		temp_add_to_ct1 = $signed(iQ_add_to_ct1) + ZERO_STATE;
		if(temp_add_to_ct1[31] == 1) begin
			oQ_add_to_ct1 = 8'd0;
		end
		else begin
			if(|temp_add_to_ct1[30:8] == 1) begin
				oQ_add_to_ct1 = 8'd255;
			end
			else begin
				oQ_add_to_ct1 = temp_add_to_ct1[7:0];
			end
		end
	
		// Q_add_to_ct2
		temp_add_to_ct2 = $signed(iQ_add_to_ct2) + ZERO_STATE;
		if(temp_add_to_ct2[31] == 1) begin
			oQ_add_to_ct2 = 8'd0;
		end
		else begin
			if(|temp_add_to_ct2[30:8] == 1) begin
				oQ_add_to_ct2 = 8'd255;
			end
			else begin
				oQ_add_to_ct2 = temp_add_to_ct2[7:0];
			end
		end	
	end

// 4. Calc_to_Ht - 
	always@(*) begin
		// Q_mul_to_ht1
		temp_mul_to_ht1 = $signed(iQ_mul_to_ht1) + ZERO_DATA;
		if(temp_mul_to_ht1[31] == 1) begin
			oQ_mul_to_ht1 = 8'd0;
		end
		else begin
			if(|temp_mul_to_ht1[30:8] == 1) begin
				oQ_mul_to_ht1 = 8'd255;
			end
			else begin
				oQ_mul_to_ht1 = temp_mul_to_ht1[7:0];
			end
		end
	
		// Q_mul_to_ht1
		temp_mul_to_ht2 = $signed(iQ_mul_to_ht2) + ZERO_DATA;
		if(temp_mul_to_ht2[31] == 1) begin
			oQ_mul_to_ht2 = 8'd0;
		end
		else begin
			if(|temp_mul_to_ht2[30:8] == 1) begin
				oQ_mul_to_ht2 = 8'd255;
			end
			else begin
				oQ_mul_to_ht2 = temp_mul_to_ht2[7:0];
			end
		end
	end

// 5. Ct_to_Tanh - 
	always@(*) begin
		// Q_ct_to_tanh1
		temp_ct_to_tanh1 = $signed(iQ_ct_to_tanh1);
		if(temp_ct_to_tanh1[31] == 1) begin
			oQ_ct_to_tanh1 = 8'd0;
		end
		else begin
			if(|temp_ct_to_tanh1[30:8] == 1) begin
				oQ_ct_to_tanh1 = 8'd255;
			end
			else begin
				oQ_ct_to_tanh1 = temp_ct_to_tanh1[7:0];
			end
		end
	
		// Q_ct_to_tanh2
		temp_ct_to_tanh2 = $signed(iQ_ct_to_tanh2);
		if(temp_ct_to_tanh2[31] == 1) begin
			oQ_ct_to_tanh2 = 8'd0;
		end
		else begin
			if(|temp_ct_to_tanh2[30:8] == 1) begin
				oQ_ct_to_tanh2 = 8'd255;
			end
			else begin
				oQ_ct_to_tanh2 = temp_ct_to_tanh2[7:0];
			end
		end	
	end


//////////////////
// Sig/Tan LUTs //
//////////////////
	sigmoid_LUT u_sig_LUT1(
		.addr(iSigmoid_LUT1),
		.dout(oSigmoid_LUT1)
	);

	sigmoid_LUT u_sig_LUT2(
		.addr(iSigmoid_LUT2),
		.dout(oSigmoid_LUT2)
	);

	tanh_LUT u_tanh_LUT1(
		.addr(iTanh_LUT1),
		.dout(oTanh_LUT1)
	);

	tanh_LUT u_tanh_LUT2(
		.addr(iTanh_LUT2),
		.dout(oTanh_LUT2)
	);


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
			init_valid_buff <= 'd0;
			oLstm_done <= 1'b1;
			oInit_done <= 1'b0;
			counter <= 'd0;
		end
		else begin		
			init_valid_buff <= iInit_valid;
			case(lstm_state)
			
				IDLE: begin
					if(iInit_valid) begin
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
					if(counter == 1000 ) begin // ????????????????????????????????????????????????????????????
						lstm_state <= IDLE;
						oLstm_done <= 1'b1;
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end

				INITIALIZE_W_B: begin
					if(init_valid_buff) begin
						counter <= counter + 1;
					end
					else begin
						lstm_state <= IDLE;
						counter <= 'd0;
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
			for(i=0; i<16; i=i+1) begin
				init_weight_buff[i] <= 'd0;
			end
			
			for(i=0; i<64; i=i+1) begin
				Br_Ct[i] <= 'd0;
				Br_Ht[i] <= 'd0;
			end
			for(i=0; i<8; i=i+1) begin
				Sys_Ct[i] <= 8'h80;
				Sys_Ht[i] <= 8'h80;
				Sys_Ht_temp[i] <= 8'h80;
			end

			temp_regA_1 <= 'd0;
			temp_regB_1 <= 'd0;
			temp_regC_1 <= 'd0;
			temp_regA_2 <= 'd0;
			temp_regB_2 <= 'd0;
			temp_regC_2 <= 'd0;
			inpdt_R_reg1 <= 'd0;
			inpdt_R_reg2 <= 'd0;				

			inpdt_X_select <= 'd0;
			inpdt_EN <= 'd0;

			weight_bram_EN <= 'd0;			
			weight_bram_addr1 <= 'd0;
			weight_bram_addr2 <= 'd0;
			weight_bram_WE1 <= 'd0;
			weight_bram_WE2 <= 'd0;			
			weight_bram_Wdata1 <= 'd0;
			weight_bram_Wdata2 <= 'd0;			
			weight_buffer <= 'd0;

			bias_bram_addr <= 'd0;
			bias_bram_EN <= 'd0;
			bias_bram_WE <= 'd0;
			bias_bram_Wdata <= 'd0;
			bias_buffer <= 'd0;			
		
			comb_ctrl <= comb_IDLE;
			inpdt_element_select <= 'd0;
			tanh_Ct_select <= 'd0;
		end
		else begin
			
			weight_buffer <= {weight_bram_Rdata1 , weight_bram_Rdata2};
			bias_buffer <= bias_bram_Rdata;
			
			if(iInit_valid) begin
				init_data_buff1 <= iInit_data;
				init_data_buff2 <= init_data_buff1;
			end

			//** CTRL by lstm_state **//
			case(lstm_state)
			
				IDLE: begin
					if(iLoad_valid) begin
						for(i=0; i<64; i=i+1) begin
							Br_Ct[i] <= iBr_Ct_load[8*i+:8];
							Br_Ht[i] <= iBr_Ht_load[8*i+:8];							
						end
					end
					
					for(i=0; i<16; i=i+1) begin
						init_weight_buff[i] <= 'd0;
					end

					temp_regA_1 <= 'd0;
					temp_regB_1 <= 'd0;
					temp_regC_1 <= 'd0;
					temp_regA_2 <= 'd0;
					temp_regB_2 <= 'd0;
					temp_regC_2 <= 'd0;
					inpdt_R_reg1 <= 'd0;
					inpdt_R_reg2 <= 'd0;				

					inpdt_X_select <= 'd0;
					inpdt_EN <= 'd0;

					weight_bram_EN <= 'd0;			
					weight_bram_addr1 <= 'd0;
					weight_bram_addr2 <= 'd0;
					weight_bram_WE1 <= 'd0;
					weight_bram_WE2 <= 'd0;			
					weight_bram_Wdata1 <= 'd0;
					weight_bram_Wdata2 <= 'd0;			

					bias_bram_addr <= 'd0;
					bias_bram_EN <= 'd0;
					bias_bram_WE <= 'd0;
					bias_bram_Wdata <= 'd0;		
				
					comb_ctrl <= comb_IDLE;
					inpdt_element_select <= 'd0;
					tanh_Ct_select <= 'd0;					
				end
				
				INITIALIZE_W_B: begin
				
					for(i=0; i<15; i=i+1) begin
						init_weight_buff[i] <= init_weight_buff[i+1];
					end
					init_weight_buff[15] <= iInit_data;
				
					// SYSTEM WEIGHT INITIALIZE
					if(iInit_type == 3'd0) begin
						if( (counter%16 == 0) && ( !(counter==0)) ) begin
							weight_bram_EN <= 1'b1;
							
							// Even Row
							if( ((counter-1)/64)%2 == 0 ) begin	
								
								weight_bram_WE1 <= 1'b1;
								weight_bram_WE2 <= 1'b0;
					
								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata1[128-8*(i+1)+:8] <= init_weight_buff[i];
								end
								
								case( ((counter)%64)/16 ) 
									1: begin
										if(counter == 16) weight_bram_addr1 <= weight_bram_addr1 + 1;
										else weight_bram_addr1 <= weight_bram_addr1 + 2;
									end
									2: begin
										weight_bram_addr1 <= weight_bram_addr1 + 1;
									end
									3: begin
										weight_bram_addr1 <= weight_bram_addr1 - 2;
									end
									0: begin
										weight_bram_addr1 <= weight_bram_addr1 + 3;
									end						
								endcase
							end
							
							// Odd Row
							else begin						
								weight_bram_WE1 <= 1'b0;
								weight_bram_WE2 <= 1'b1;

								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata2[128-8*(i+1)+:8] <= init_weight_buff[i];
								end
								
								case( ((counter)%64)/16 ) 
									1: begin
										if(counter == 80) weight_bram_addr2 <= weight_bram_addr2 + 1;
										else weight_bram_addr2 <= weight_bram_addr2 + 2;
									end
									2: begin
										weight_bram_addr2 <= weight_bram_addr2 + 1;
									end
									3: begin
										weight_bram_addr2 <= weight_bram_addr2 - 2;
									end
									0: begin
										weight_bram_addr2 <= weight_bram_addr2 + 3;
									end						
								endcase						
							end				
						end
						// Turn on WE only when init_weight_buff is full. every 16 cycle.
						else begin
							weight_bram_EN <= 1'b0;
							weight_bram_WE1 <= 1'b0;
							weight_bram_WE2 <= 1'b0;
						end
					end
					
					// SYSTEM BIAS INITIALIZE 
					if(iInit_type == 3'd1) begin
						if( !(counter==0) && (counter%2 == 0) ) begin
							bias_bram_EN <= 1'b1;
							bias_bram_WE <= 1'b1;
							bias_bram_Wdata[15:8] = init_weight_buff[14];
							bias_bram_Wdata[7:0] = init_weight_buff[15];
							case(counter%8) 
								2: begin
									if(counter == 2) bias_bram_addr <= bias_bram_addr + 1;
									else bias_bram_addr <= bias_bram_addr + 2;
								end
								4: begin
									bias_bram_addr <= bias_bram_addr + 1;
								end
								6: begin
									bias_bram_addr <= bias_bram_addr - 2;
								end
								0: begin
									bias_bram_addr <= bias_bram_addr + 3;
								end						
							endcase								
						end		
						else begin
							bias_bram_EN <= 1'b0;
							bias_bram_WE <= 1'b0;
						end
					end
					
					
					
				end
				
				SYSTEM: begin
				
					//**** 1. WEIGHT BRAM CTRL ****//
					if( (24 <= counter) && (counter <= 26) ) begin	// Exception.
						weight_bram_EN <= 1'b0;
					end
					else if( counter == 0 ) begin					// Initialize addr.
						weight_bram_EN <= 1'b1;
						weight_bram_addr1 <= 'd0; 
						weight_bram_addr2 <= 'd0; 						
					end
					
					else if( (0 <= counter%6) && (counter%6 <= 3) ) begin
						weight_bram_EN <= 1'b1;
						weight_bram_addr1 <= weight_bram_addr1 + 1;
						weight_bram_addr2 <= weight_bram_addr2 + 1;						
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
					end
					else if( (0 <= counter%6) && (counter%6 <= 1) ) begin	// WAIT
						inpdt_EN <= 1'b0;
					end
					
					//**** 4. Register CTRL ****//
					if( (0<=counter) && (counter<=2) ) begin
						// Nothing
					end
					else if(counter%6 == 4) begin
						temp_regA_1[7:0] <= oSigmoid_LUT1;	// Integer (temp_regA_1 is considered as signed)
						temp_regA_2[7:0] <= oSigmoid_LUT2;
						
						inpdt_R_reg1 <= $signed(inpdt_R_wire1);	// inpdt_R_wire1 is Signed Value from INPDT.	
						inpdt_R_reg2 <= $signed(inpdt_R_wire2);							
					end
					else if(counter%6 == 5) begin
						temp_regA_1 <= ($signed({1'b0,Sys_Ct[2*(counter/6)]}) - $signed({1'b0,ZERO_STATE}))*($signed({1'b0,temp_regA_1[7:0]}) - $signed({1'b0,OUT_ZERO_SIGMOID}))/OUT_SCALE_SIGMOID;
						temp_regA_2 <= ($signed({1'b0,Sys_Ct[2*(counter/6)+1]}) - $signed({1'b0,ZERO_STATE}))*($signed({1'b0,temp_regA_2[7:0]}) - $signed({1'b0,OUT_ZERO_SIGMOID}))/OUT_SCALE_SIGMOID;
						
						temp_regB_1 <= oSigmoid_LUT1;
						temp_regB_2 <= oSigmoid_LUT2;					

						inpdt_R_reg1 <= $signed(inpdt_R_wire1);	
						inpdt_R_reg2 <= $signed(inpdt_R_wire2);							
					end
					else if(counter%6 == 0) begin
						temp_regC_1 <= oTanh_LUT1;
						temp_regC_2 <= oTanh_LUT2;	

						inpdt_R_reg1 <= $signed(inpdt_R_wire1);	
						inpdt_R_reg2 <= $signed(inpdt_R_wire2);							
					end
					else if(counter%6 == 1) begin
						temp_regA_1[7:0] <= oSigmoid_LUT1;
						temp_regA_2[7:0] <= oSigmoid_LUT2;
						
						Sys_Ct[2*( (counter/6)-1 )] <= oQ_add_to_ct1;
						Sys_Ct[2*( (counter/6)-1 )+1] <= oQ_add_to_ct2;						
					end
					else if(counter%6 == 2) begin
						Sys_Ht_temp[2*( (counter/6)-1 )] <= oQ_mul_to_ht1;
						Sys_Ht_temp[2*( (counter/6)-1 )+1] <= oQ_mul_to_ht2;	
						
						if(counter == 26) begin
							Sys_Ht[6] <= oQ_mul_to_ht1;
							Sys_Ht[7] <= oQ_mul_to_ht2;
							for(i=0; i<6; i=i+1) begin
								Sys_Ht[i] <= Sys_Ht_temp[i];
							end
						end
						
					end
					else if(counter%6 == 3) begin
						inpdt_R_reg1 <= $signed(inpdt_R_wire1);
						inpdt_R_reg2 <= $signed(inpdt_R_wire2);							
					end
					
					//**** 5. Combinational CTRL ****//
					if(counter <= 2) begin
						comb_ctrl <= comb_IDLE;
					end
					else if( (counter%6 == 3) || (counter%6 == 4)) begin
						comb_ctrl <= S_BQS;
					end
					else if(counter%6 == 5) begin
						comb_ctrl <= S_BQT;
					end
					else if(counter%6 == 0) begin
						comb_ctrl <= S_MAQ_BQS;
					end
					else if(counter%6 == 1) begin
						comb_ctrl <= S_TMQ;
						tanh_Ct_select <= (counter/6)-1;
					end
					else if(counter%6 == 2) begin
						comb_ctrl <= comb_IDLE;
					end
				end
			
				BRANCH: begin
				
					//**** 1. WEIGHT BRAM CTRL ****//
					
					
					//**** 2. BIAS BRAM CTRL ****//
					
					
					//**** 3. INPDT CTRL ****//
					/*
					if(counter <= 1) begin
						inpdt_EN <= 1'b0;
					end
					else if(2 <= counter%18) begin
						inpdt_EN <= 1'b1;
						inpdt_element_select <= counter/18;
					end
					else if(counter%18 <= 1) begin
						inpdt_EN <= 1'b0;
						
					end
					*/
					
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
				iQ_sum_to_sig1 = 'd0;
				iQ_sum_to_sig2 = 'd0;	
				iQ_sum_to_tanh1 = 'd0;
				iQ_sum_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_mul_to_ht1 = 'd0;
				iQ_mul_to_ht2 = 'd0;
				iQ_ct_to_tanh1 = 'd0;
				iQ_ct_to_tanh2 = 'd0;

				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;	
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;			
			end
		
			S_BQS: begin	
				iQ_sum_to_sig1 = $signed(inpdt_R_reg1);
				iQ_sum_to_sig2 = $signed(inpdt_R_reg2);
				iQ_sum_to_tanh1 = 'd0;
				iQ_sum_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_mul_to_ht1 = 'd0;
				iQ_mul_to_ht2 = 'd0;
				iQ_ct_to_tanh1 = 'd0;
				iQ_ct_to_tanh2 = 'd0;

				iSigmoid_LUT1 = oQ_sum_to_sig1;
				iSigmoid_LUT2 = oQ_sum_to_sig2;	
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;								
			end
			
			S_BQT: begin
				iQ_sum_to_sig1 = 'd0;
				iQ_sum_to_sig2 = 'd0;					
				iQ_sum_to_tanh1 = $signed(inpdt_R_reg1);
				iQ_sum_to_tanh2 = $signed(inpdt_R_reg2);
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_mul_to_ht1 = 'd0;
				iQ_mul_to_ht2 = 'd0;
				iQ_ct_to_tanh1 = 'd0;
				iQ_ct_to_tanh2 = 'd0;				

				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;	
				iTanh_LUT1 = oQ_sum_to_tanh1;
				iTanh_LUT2 = oQ_sum_to_tanh2;						
			end
		
			S_MAQ_BQS: begin
				iQ_sum_to_sig1 = $signed(inpdt_R_reg1);
				iQ_sum_to_sig2 = $signed(inpdt_R_reg2);	
				iQ_sum_to_tanh1 = 'd0;
				iQ_sum_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = $signed(temp_regA_1)
				+ ( ($signed({1'b0,temp_regB_1}) - $signed({1'b0,OUT_ZERO_SIGMOID}) ) * ($signed({1'b0,temp_regC_1}) - $signed({1'b0,OUT_ZERO_TANH})) * SCALE_STATE )
				/ (OUT_SCALE_SIGMOID*OUT_SCALE_TANH);
				iQ_add_to_ct2 = $signed(temp_regA_2)
				+ ( ($signed({1'b0,temp_regB_2}) - $signed({1'b0,OUT_ZERO_SIGMOID}) ) * ($signed({1'b0,temp_regC_2}) - $signed({1'b0,OUT_ZERO_TANH})) * SCALE_STATE )
				/ (OUT_SCALE_SIGMOID*OUT_SCALE_TANH);				
				iQ_mul_to_ht1 = 'd0;
				iQ_mul_to_ht2 = 'd0;
				iQ_ct_to_tanh1 = 'd0;
				iQ_ct_to_tanh2 = 'd0;				

				iSigmoid_LUT1 = oQ_sum_to_sig1;
				iSigmoid_LUT2 = oQ_sum_to_sig2;	
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;					
			end
		
			S_TMQ: begin
				iQ_sum_to_sig1 = 'd0;
				iQ_sum_to_sig2 = 'd0;	
				iQ_sum_to_tanh1 = 'd0;
				iQ_sum_to_tanh2 = 'd0;	
				iQ_add_to_ct1 = 'd0;
				iQ_add_to_ct2 = 'd0;	
				iQ_mul_to_ht1 = ( ( $signed(temp_regA_1) - $signed({1'b0,OUT_ZERO_SIGMOID}) )*( $signed({1'b0,oTanh_LUT1}) - $signed({1'b0,OUT_ZERO_TANH}) )*SCALE_DATA)
				/(OUT_SCALE_TANH*OUT_SCALE_SIGMOID);
				iQ_mul_to_ht2 = ( ( $signed(temp_regA_2) - $signed({1'b0,OUT_ZERO_SIGMOID}) )*( $signed({1'b0,oTanh_LUT2}) - $signed({1'b0,OUT_ZERO_TANH}) )*SCALE_DATA)
				/(OUT_SCALE_TANH*OUT_SCALE_SIGMOID);
				iQ_ct_to_tanh1 = (($signed(Sys_Ct[tanh_Ct_select]) - $signed({1'b0,ZERO_STATE}))*SCALE_TANH)/SCALE_STATE + ZERO_TANH;
				iQ_ct_to_tanh2 = (($signed(Sys_Ct[tanh_Ct_select+1]) - $signed({1'b0,ZERO_STATE}))*SCALE_TANH)/SCALE_STATE + ZERO_TANH;				
				
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;
				iTanh_LUT1 = oQ_ct_to_tanh1;
				iTanh_LUT2 = oQ_ct_to_tanh2;
			end
			
			B_BQS: begin
			
			end
			B_BQT: begin
			
			end
			B_MAQ: begin
			
			end
			B_TMQ: begin
			
			end
			
			default: begin
			
			end 
		
		endcase
	end






endmodule
