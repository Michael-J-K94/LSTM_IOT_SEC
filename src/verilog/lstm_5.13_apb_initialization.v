// This is a LSTM
// Description: 

// TODO: 
/*
	1. Optimize bit width
	2. Parameterize whole design
	3. Make inpdt#4 version
	4. CTXT CONVERT TB&DATA
*/


// Author: Michael Kim

module LSTM#(

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
	input clk,
	input resetn,
	
	input iInit_valid,
	input [7:0] iInit_data,
	input [2:0] iInit_type,

	input iNext_valid,	// top valid & ready. 
	input iType,		//
	input [511:0] iData,
	
	output reg oLstm_done,	// lstm done & ready to do next task. 
	output reg [511:0] oBr_Ct,	// Wire actually
	output reg [511:0] oBr_Ht,
	output reg [63:0] oSys_Ct,
	output reg [63:0] oSys_Ht
);

	/* iInit_type */	localparam INIT_S_W = 3'd0, INIT_S_B = 3'd1, INIT_B_W = 3'd2, INIT_B_B = 3'd3;
						localparam INIT_C_W = 3'd4, INIT_C_B = 3'd5, INIT_IDLE = 3'd7;
	
	/* lstm_state */	localparam IDLE = 3'd0, SYSTEM = 3'd1, BRANCH = 3'd2, INITIALIZE_W_B = 3'd3, CTXT_CONVERT = 3'd4, ERROR = 3'd7;
	/* iType */			localparam SYS_type = 1'b1, BR_type = 1'b0;
	/* ctxt_type */		localparam Ct_type = 1'b1, Ht_type = 1'b0;
		
	/* comb_ctrl */		localparam comb_IDLE = 5'd0, S_BQS = 5'd1, S_BQT = 5'd2, S_MAQ_BQS = 5'd3, S_TMQ = 5'd4;
						localparam B_BQS = 5'd5, B_BQT = 5'd6, B_MAQ = 5'd7, B_TMQ = 5'd8;

	/* ADDR */			localparam CTXT_W_ADDR = 11'd16;
	/**/				localparam CTXT_B_ADDR = 9'd16;	
	/**/				localparam BR_W_ADDR = 11'd48;
	/**/				localparam BR_B_ADDR = 9'd48;

	// /* APB ADDR */		localparam
						// localparam
						// localparam
						// localparam
						// localparam
						// localparam
						// localparam
						// localparam
						// localparam
						// localparam
						
	integer i;


////////
//    //
////////
	reg [2:0] lstm_state;
	reg [31:0] counter;
	reg [31:0] ctxt_counter;
	reg lstm_done;
	reg init_new;
	
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
	reg [7:0] Br_Ht_temp [0:63];

	reg [16:0] temp_regA_1;
	reg [7:0] temp_regB_1;
	reg [7:0] temp_regC_1;

	reg [16:0] temp_regA_2;
	reg [7:0] temp_regB_2;
	reg [7:0] temp_regC_2;

	reg [31:0] inpdt_R_reg1;		// Can Be Used as signed
	reg [31:0] inpdt_R_reg2;	
	
	reg [31:0] inpdt_Rtemp_reg1;
	reg [31:0] inpdt_Rtemp_reg2;


//////////////////
// inpdt IN/OUT //
//////////////////	
	reg inpdt_EN;
	reg [143:0] inpdt_X1;
	reg [143:0] inpdt_X2;
	reg [143:0] inpdt_W1;
	reg [143:0] inpdt_W2;
		
	wire [20:0] inpdt_R_wire1;		// Comes Out as Signed
	wire [20:0] inpdt_R_wire2;
	
	wire [19:0] inpdt_Rmid1_wire1;
	wire [19:0] inpdt_Rmid2_wire1;
	wire [19:0] inpdt_Rmid1_wire2;
	wire [19:0] inpdt_Rmid2_wire2;

/////////////////
// Weight BRAM //
/////////////////
	reg weight_bram_EN;
	reg weight_bram_EN_buff;

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
	reg bias_bram_EN;
	reg bias_bram_EN_buff;

	reg [8:0] bias_bram_addr;
	reg bias_bram_WE;
	reg [31:0] bias_bram_Wdata;
	wire [31:0] bias_bram_Rdata;
	reg [31:0] bias_buffer;	


//////////////////
// Quantization //
//////////////////
/***** Quantization MEANS Saturating & 8bit Quantizing (After scale/zero operation) *****/

	reg [31:0] S_real_inpdt_sumBQS1; 
	reg [31:0] S_real_inpdt_sumBQS2; 
	reg [31:0] S_real_biasBQS1;			
	reg [31:0] S_real_biasBQS2;			
	reg [31:0] S_unsat_BQS1;
	reg [31:0] S_unsat_BQS2;
	wire [7:0] S_sat_BQS1;
	wire [7:0] S_sat_BQS2;
	
	reg [31:0] S_real_inpdt_sumBQT1; 
	reg [31:0] S_real_inpdt_sumBQT2; 
	reg [31:0] S_real_biasBQT1;			
	reg [31:0] S_real_biasBQT2;			
	reg [31:0] S_unsat_BQT1;
	reg [31:0] S_unsat_BQT2;
	wire [7:0] S_sat_BQT1;
	wire [7:0] S_sat_BQT2;
	
	reg [31:0] S_real_ctf_MAQ1;
	reg [31:0] S_real_ctf_MAQ2;
	reg [31:0] S_real_ig_MAQ1;
	reg [31:0] S_real_ig_MAQ2;
	reg [31:0] S_real_sum_MAQ1;
	reg [31:0] S_real_sum_MAQ2;
	reg [31:0] S_unsat_MAQ1;
	reg [31:0] S_unsat_MAQ2;
	wire [7:0] S_sat_MAQ1;
	wire [7:0] S_sat_MAQ2;
	
	reg [31:0] S_unsat_ct_TMQ1;
	reg [31:0] S_unsat_ct_TMQ2;
	wire [7:0] S_sat_ct_TMQ1;
	wire [7:0] S_sat_ct_TMQ2;
	reg [31:0] S_unscale_ht_TMQ1;
	reg [31:0] S_unscale_ht_TMQ2;
	reg [31:0] S_unsat_ht_TMQ1;	
	reg [31:0] S_unsat_ht_TMQ2;	
	reg [31:0] S_unsat_Z_ht_TMQ1;
	reg [31:0] S_unsat_Z_ht_TMQ2;
	wire [7:0] S_sat_ht_TMQ1;
	wire [7:0] S_sat_ht_TMQ2;


	reg [31:0] B_real_inpdt_sumBQS1; 
	//reg [31:0] B_real_inpdt_sumBQS2; 
	reg [31:0] B_real_biasBQS1;			
	//reg [31:0] B_real_biasBQS2;			
	reg [31:0] B_unsat_BQS1;
	// reg [31:0] B_unsat_BQS2;
	wire [7:0] B_sat_BQS1;
	// wire [7:0] B_sat_BQS2;
	
	reg [31:0] B_real_inpdt_sumBQT1; 
	// reg [31:0] B_real_inpdt_sumBQT2; 
	reg [31:0] B_real_biasBQT1;			
	// reg [31:0] B_real_biasBQT2;			
	reg [31:0] B_unsat_BQT1;
	// reg [31:0] B_unsat_BQT2;
	wire [7:0] B_sat_BQT1;
	// wire [7:0] B_sat_BQT2;
	
	reg [31:0] B_real_ctf_MAQ1;
	// reg [31:0] B_real_ctf_MAQ2;
	reg [31:0] B_real_ig_MAQ1;
	// reg [31:0] B_real_ig_MAQ2;
	reg [31:0] B_real_sum_MAQ1;
	// reg [31:0] B_real_sum_MAQ2;
	reg [31:0] B_unsat_MAQ1;
	// reg [31:0] B_unsat_MAQ2;
	wire [7:0] B_sat_MAQ1;
	// wire [7:0] B_sat_MAQ2;
	
	reg [31:0] B_unsat_ct_TMQ1;
	// reg [31:0] B_unsat_ct_TMQ2;
	wire [7:0] B_sat_ct_TMQ1;
	// wire [7:0] B_sat_ct_TMQ2;
	reg [31:0] B_unscale_ht_TMQ1;
	// reg [31:0] B_unscale_ht_TMQ2;
	reg [31:0] B_unsat_ht_TMQ1;	
	// reg [31:0] B_unsat_ht_TMQ2;	
	reg [31:0] B_unsat_Z_ht_TMQ1;
	// reg [31:0] B_unsat_Z_ht_TMQ2;
	wire [7:0] B_sat_ht_TMQ1;
	// wire [7:0] B_sat_ht_TMQ2;

	reg [31:0] Ct_real_inpdt_sum1;
	reg [31:0] Ct_real_inpdt_sum2;	
	reg [31:0] Ct_real_bias1;
	reg [31:0] Ct_real_bias2;	
	reg [31:0] Ct_unsat1;
	reg [31:0] Ct_unsat2;
	wire [7:0] Ct_sat1;
	wire [7:0] Ct_sat2;	

	reg [31:0] Ht_real_inpdt_sum1;
	reg [31:0] Ht_real_inpdt_sum2;	
	reg [31:0] Ht_real_bias1;
	reg [31:0] Ht_real_bias2;	
	reg [31:0] Ht_unsat1;
	reg [31:0] Ht_unsat2;
	wire [7:0] Ht_sat1;
	wire [7:0] Ht_sat2;		
	
	
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
	reg [5:0] tanh_Ct_select;
	reg ctxt_type;

	
	
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
	
	always@(*) begin
		oLstm_done = lstm_done;
	end
	
//////////////////
// LSTM Modules //
//////////////////
	inpdt_16_mid u_inpdt_1(
		.iData_XH(inpdt_X1),
		.iData_W(inpdt_W1),
		.iEn(inpdt_EN),
		.oResult_mid1(inpdt_Rmid1_wire1),
		.oResult_mid2(inpdt_Rmid2_wire1),
		.oResult(inpdt_R_wire1)
	);
	
	inpdt_16_mid u_inpdt_2(
		.iData_XH(inpdt_X2),
		.iData_W(inpdt_W2),
		.iEn(inpdt_EN),
		.oResult_mid1(inpdt_Rmid1_wire2),
		.oResult_mid2(inpdt_Rmid2_wire2),		
		.oResult(inpdt_R_wire2)
	);

/*
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
*/
	
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
			if( ((counter-2)%16)%4 == 1 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0, iData[512-8*(i+1)+:8]}) - $signed({1'b0,ZERO_DATA});
				end				
			end
			else if( ((counter-2)%16)%4 == 2 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0, iData[384-8*(i+1)+:8]}) - $signed({1'b0,ZERO_DATA});
				end				
			end		
			else if( ((counter-2)%16)%4 == 3 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0, iData[256-8*(i+1)+:8]}) - $signed({1'b0,ZERO_DATA});
				end				
			end				
			else if( ((counter-2)%16)%4 == 0 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0, iData[128-8*(i+1)+:8]}) - $signed({1'b0,ZERO_DATA});
				end				
			end				
		
			if( ((counter-2)%16)%4 == 1 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0, Br_Ht[i]}) - $signed({1'b0,ZERO_DATA});
				end
			end
			else if( ((counter-2)%16)%4 == 2 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0, Br_Ht[i+16]}) - $signed({1'b0,ZERO_DATA});
				end
			end		
			else if( ((counter-2)%16)%4 == 3 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0, Br_Ht[i+32]}) - $signed({1'b0,ZERO_DATA});
				end
			end		
			else if( ((counter-2)%16)%4 == 0 ) begin
				for(i=0; i<16; i=i+1) begin
					inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0, Br_Ht[i+48]}) - $signed({1'b0,ZERO_DATA});
				end
			end					
		end	
		
		else if(lstm_state == CTXT_CONVERT) begin							
			for(i=0; i<8; i=i+1) begin
				inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0, Sys_Ct[i]}) - $signed({1'b0,ZERO_STATE});
			end
			for(i=8; i<16; i=i+1) begin
				inpdt_X1[144-9*(i+1)+:9] = $signed({1'b0, Sys_Ct[i-8]}) - $signed({1'b0,ZERO_STATE});
			end
			
			for(i=0; i<8; i=i+1) begin
				inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0, Sys_Ht[i]}) - $signed({1'b0,ZERO_DATA});
			end
			for(i=8; i<16; i=i+1) begin
				inpdt_X2[144-9*(i+1)+:9] = $signed({1'b0, Sys_Ht[i-8]}) - $signed({1'b0,ZERO_DATA});
			end			
		end
		
		else begin	// Default
			inpdt_X1 = 'd0;
			inpdt_X2 = 'd0;
		end
	end

	always@(*) begin
		for(i=0; i<16; i=i+1) begin
			inpdt_W1[144-9*(i+1)+:9] = $signed({1'b0,weight_buffer[256-8*(i+1)+:8]}) - $signed({1'b0,ZERO_W});			
			inpdt_W2[144-9*(i+1)+:9] = $signed({1'b0,weight_buffer[128-8*(i+1)+:8]}) - $signed({1'b0,ZERO_W});
		end	
	end


///////////
// Brams //
///////////
/*
	// SRAM_128x2048 WEIGHT_BRAM1(
		// .addra(weight_bram_addr1),
		// .clka(clk),
		// .dina(weight_bram_Wdata1),
		// .douta(weight_bram_Rdata1),
		// .ena(weight_bram_EN),
		// .wea(weight_bram_WE1)	
	// );

	// SRAM_128x2048 WEIGHT_BRAM2(
		// .addra(weight_bram_addr2),
		// .clka(clk),
		// .dina(weight_bram_Wdata2),
		// .douta(weight_bram_Rdata2),
		// .ena(weight_bram_EN),
		// .wea(weight_bram_WE2)	
	// );
	
	// SRAM_32x512 BIAS_BRAM(
		// .addra(bias_bram_addr),
		// .clka(clk),
		// .dina(bias_bram_Wdata),
		// .douta(bias_bram_Rdata),
		// .ena(bias_bram_EN),
		// .wea(bias_bram_WE)	
	// );
*/

	//****SIMULATED BRAM MODULE**** 

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
	
	SRAM_32x512 BIAS_BRAM(
		.CLK(clk),
		.EN_M(bias_bram_EN),
		.WE(bias_bram_WE),
		.ADDR(bias_bram_addr),
		.ADDR_WRITE(bias_bram_addr),		
		.DIN(bias_bram_Wdata),
		.DOUT(bias_bram_Rdata)	
	);



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
			lstm_done <= 1'b1;
			counter <= 'd0;
			ctxt_counter <= 'd0;
		end
		else begin		
			init_valid_buff <= iInit_valid;
			case(lstm_state)
			
				IDLE: begin
					if(iInit_valid) begin
						lstm_state <= INITIALIZE_W_B;
						lstm_done <= 1'b0;
					end
					else begin
						if(iNext_valid) begin
							if(iType == SYS_type) begin
								lstm_state <= SYSTEM;
								lstm_done <= 1'b0;
							end
							else if(iType == BR_type) begin
								lstm_state <= BRANCH;
								lstm_done <= 1'b0;
							end
						end
					end
				end
				
				SYSTEM: begin
					if(counter == 26) begin 
						lstm_state <= CTXT_CONVERT;
						//lstm_done <= 1'b1;
						counter <= 'd0;					
					end
					else begin					
						counter <= counter + 1;
					end
				end
				
				BRANCH: begin
					if(counter == 1028 ) begin
						lstm_state <= IDLE;
						lstm_done <= 1'b1;
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
						lstm_done <= 1'b1;
						counter <= 'd0;
					end
				end
				
				CTXT_CONVERT: begin
					if(ctxt_counter == 35) begin
						lstm_state <= IDLE;
						lstm_done <= 1'b1;
						ctxt_counter <= 'd0;
					end
					else begin
						ctxt_counter <= ctxt_counter + 1;
					end
				end

				ERROR: begin
					lstm_state <= ERROR;
					lstm_done <= 1'b0;			
					counter <= 'd0;							
				end	

				default: begin
					lstm_state <= ERROR;			
					lstm_done <= 1'b0;			
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
				Br_Ct[i] <= 'h80;
				Br_Ht[i] <= 'h80;
				Br_Ht_temp[i] <= 'h80;
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
			inpdt_Rtemp_reg1 <= 'd0;
			inpdt_Rtemp_reg2 <= 'd0;

			inpdt_EN <= 'd0;

			weight_bram_EN <= 'd0;			
			weight_bram_EN_buff <= 'd0;
			weight_bram_addr1 <= 'd0;
			weight_bram_addr2 <= 'd0;
			weight_bram_WE1 <= 'd0;
			weight_bram_WE2 <= 'd0;			
			weight_bram_Wdata1 <= 'd0;
			weight_bram_Wdata2 <= 'd0;			
			weight_buffer <= 'd0;

			bias_bram_EN <= 'd0;
			bias_bram_EN_buff <= 'd0;
			bias_bram_addr <= 'd0;
			bias_bram_WE <= 'd0;
			bias_bram_Wdata <= 'd0;
			bias_buffer <= 'd0;			
		
			comb_ctrl <= comb_IDLE;
			tanh_Ct_select <= 'd0;
			ctxt_type <= Ct_type;
		end
		else begin
			weight_bram_EN_buff <= weight_bram_EN;
			bias_bram_EN_buff <= bias_bram_EN;
			
			/*if(weight_bram_EN_buff)*/ weight_buffer <= {weight_bram_Rdata1 , weight_bram_Rdata2};
			/*if(bias_bram_EN_buff)*/ bias_buffer <= bias_bram_Rdata;
			
			if(iInit_valid) begin
				init_data_buff1 <= iInit_data;
				init_data_buff2 <= init_data_buff1;
			end

			//** CTRL by lstm_state **//
			case(lstm_state)
			
				IDLE: begin
				
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
					tanh_Ct_select <= 'd0;					
				end
				// *****************************************************************************//	
				//									INITIALIZE									//
				// *****************************************************************************//							
				INITIALIZE_W_B: begin
				
					for(i=0; i<15; i=i+1) begin
						init_weight_buff[i] <= init_weight_buff[i+1];
					end
					init_weight_buff[15] <= iInit_data;
				
					//****	1. SYSTEM WEIGHT INITIALIZE	****//
					if(iInit_type == INIT_S_W) begin
						if( (counter%16 == 0) && ( !(counter==0)) ) begin								// everytime 16 element is stacked. (in init_weight_buff)			
							weight_bram_EN <= 1'b1;
							
							// Even Row & BRAM1
							if( ((counter-1)/64)%2 == 0 ) begin								
								
								weight_bram_WE1 <= 1'b1;
								weight_bram_WE2 <= 1'b0;
					
								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata1[128-8*(i+1)+:8] <= init_weight_buff[i];
								end
								
								case( ((counter)%64)/16 ) 
									1: begin
										if(counter == 16) weight_bram_addr1 <= weight_bram_addr1 + 1;	// initial case
										else weight_bram_addr1 <= weight_bram_addr1 + 2;				// i
									end
									2: begin
										weight_bram_addr1 <= weight_bram_addr1 + 1;						// g
									end
									3: begin
										weight_bram_addr1 <= weight_bram_addr1 - 2;						// f
									end
									0: begin	
										weight_bram_addr1 <= weight_bram_addr1 + 3;						// o
									end						
								endcase
							end
							
							// Odd Row & BRAM2
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
					
					//****	2. SYSTEM BIAS INITIALIZE	****//
					if(iInit_type == INIT_S_B) begin
						if( !(counter==0) && (counter%2 == 0) ) begin
							bias_bram_EN <= 1'b1;
							bias_bram_WE <= 1'b1;
							bias_bram_Wdata[31:0] = 'd0;
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
					
					//****	3. BRANCH WEIGHT INITIALIZE	****//
					if(iInit_type == INIT_B_W) begin					
						if( (counter%16 == 0) && (!(counter==0)) ) begin								// everytime 16 element is stacked. (in init_weight_buff)
							weight_bram_EN <= 1'b1;
						
							// BRAM1
							if( ((counter-1)/64)%2 == 0 ) begin
								weight_bram_WE1 <= 1'b1;
								weight_bram_WE2 <= 1'b0;
								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata1[128-8*(i+1)+:8] <= init_weight_buff[i];
								end
								
								if( (counter%512)/16 <= 4 ) begin												
									if(counter == 16) weight_bram_addr1 <= BR_W_ADDR + 4;						// initial cae
									else if( (counter%512)/16 == 1 ) weight_bram_addr1 <= weight_bram_addr1 + 5;
									else weight_bram_addr1 <= weight_bram_addr1 + 1;							// i
								end
								else if( (9<=(counter%512)/16) && ((counter%512)/16<=12) ) begin
									weight_bram_addr1 <= weight_bram_addr1 + 1;									// g
								end
								else if( (17<=(counter%512)/16) && ((counter%512)/16<=20) ) begin
									if( (counter%512)/16 == 17) weight_bram_addr1 <= weight_bram_addr1 - 11;	// f
									else weight_bram_addr1 <= weight_bram_addr1 + 1;
								end
								else if( (25<=(counter%512)/16) && ((counter%512)/16<=28) ) begin
									if( (counter%512)/16 == 25 ) weight_bram_addr1 <= weight_bram_addr1 + 9;	// o
									else weight_bram_addr1 <= weight_bram_addr1 + 1;
								end
							end
						
							// BRAM2
							else if( ((counter-1)/64)%2 == 1 ) begin
								weight_bram_WE1 <= 1'b0;
								weight_bram_WE2 <= 1'b1;
								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata2[128-8*(i+1)+:8] <= init_weight_buff[i];
								end

								if( (5<=(counter%512)/16) && ((counter%512)/16<=8) ) begin
									if(counter == 80) weight_bram_addr2 <= BR_W_ADDR + 4;
									else if( (counter%512)/16 == 5 ) weight_bram_addr2 <= weight_bram_addr2 + 5;
									else weight_bram_addr2 <= weight_bram_addr2 + 1;
								end
								else if( (13<=(counter%512)/16) && ((counter%512)/16<=16) ) begin
									weight_bram_addr2 <= weight_bram_addr2 + 1;
								end
								else if( (21<=(counter%512)/16) && ((counter%512)/16<=24) ) begin
									if( (counter%512)/16 == 21 ) weight_bram_addr2 <= weight_bram_addr2 - 11;
									else weight_bram_addr2 <= weight_bram_addr2 + 1;
								end
								else if( ( (29<=(counter%512)/16) && ((counter%512)/16<=31) )||(counter%512==0) ) begin
									if( (counter%512)/16 == 29 ) weight_bram_addr2 <= weight_bram_addr2 + 9;
									else weight_bram_addr2 <= weight_bram_addr2 + 1;
								end
							end
						end
						else begin
							weight_bram_EN <= 1'b0;
							weight_bram_WE1 <= 1'b0;
							weight_bram_WE2 <= 1'b0;
						end
					end
					
					//****	4. BRANCH BIAS INITIALIZE	****//
					if(iInit_type == INIT_B_B) begin					
						if(!(counter==0)) begin
							bias_bram_EN <= 1'b1;
							bias_bram_WE <= 1'b1;
							bias_bram_Wdata[31:0] = 'd0;
							bias_bram_Wdata[15:8] = 8'd0;
							bias_bram_Wdata[7:0] = init_weight_buff[15];
							
							case(counter%4) 
								1: begin 												// i
									if(counter==1) bias_bram_addr <= BR_B_ADDR + 1;
									else bias_bram_addr <= bias_bram_addr + 2;
								end
								2: begin												// g
									bias_bram_addr <= bias_bram_addr + 1;
								end
								3: begin
									bias_bram_addr <= bias_bram_addr - 2;				// f
								end
								0: begin
									bias_bram_addr <= bias_bram_addr + 3;				// o
								end
							endcase
						end
						else begin
							bias_bram_EN <= 1'b0;
							bias_bram_WE <= 1'b0;
						end
					end
				
				
					//****	5. CTXT WEIGHT INITIALIZE	****//
					if(iInit_type == INIT_C_W) begin
						if( (counter%16 == 0) && (!(counter==0)) ) begin
							weight_bram_EN <= 1'b1;
							
							// BRAM1
							if(counter <= 512) begin
								weight_bram_WE1 <= 1'b1;
								weight_bram_WE2 <= 1'b0;
								
								if(counter == 16) weight_bram_addr1 <= CTXT_W_ADDR;
								else weight_bram_addr1 <= weight_bram_addr1 + 1;
								
								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata1[128-8*(i+1)+:8] <= init_weight_buff[i];
								end
							end
							// BRAM2
							else if(counter<= 1024) begin 
								weight_bram_WE1 <= 1'b0;
								weight_bram_WE2 <= 1'b1;
								
								if(counter == 528) weight_bram_addr2 <= CTXT_W_ADDR;
								else weight_bram_addr2 <= weight_bram_addr2 + 1;
								
								for(i=0; i<16; i=i+1) begin
									weight_bram_Wdata2[128-8*(i+1)+:8] <= init_weight_buff[i];
								end									
							end
							
							else begin
								weight_bram_WE1 <= 1'b0;
								weight_bram_WE2 <= 1'b0;
							end
						end
						else begin
							weight_bram_EN <= 1'b0;
							weight_bram_WE1 <= 1'b0;
							weight_bram_WE2 <= 1'b0;
						end
					end
				
					//****	6. BRANCH BIAS INITIALIZE	****//
					if(iInit_type == INIT_C_B) begin
						if( (counter%4 == 0) && (!(counter==0)) ) begin
							bias_bram_EN <= 1'b1;
							bias_bram_WE <= 1'b1;
							
							if(counter == 4) bias_bram_addr <= CTXT_B_ADDR;
							else bias_bram_addr <= bias_bram_addr + 1;
							
							for(i=0; i<4; i=i+1) begin
								bias_bram_Wdata[32-8*(i+1)+:8] <= init_weight_buff[12+i];
							end
						end
						else begin
							bias_bram_EN <= 1'b0;
							bias_bram_WE <= 1'b0;
						end
					end
				end
				
				// *****************************************************************************//	
				//									SYSTEM										//
				// *****************************************************************************//	
		
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
						temp_regA_1 <= ($signed({1'b0,Sys_Ct[2*(counter/6)]}) - $signed({1'b0,ZERO_STATE}))*($signed({1'b0,temp_regA_1[7:0]}) - $signed({1'b0,OUT_ZERO_SIGMOID}));
						temp_regA_2 <= ($signed({1'b0,Sys_Ct[2*(counter/6)+1]}) - $signed({1'b0,ZERO_STATE}))*($signed({1'b0,temp_regA_2[7:0]}) - $signed({1'b0,OUT_ZERO_SIGMOID}));
						
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
						temp_regA_1[16:8] <= 'd0;
						temp_regA_2[16:8] <= 'd0;
					
						temp_regA_1[7:0] <= oSigmoid_LUT1;
						temp_regA_2[7:0] <= oSigmoid_LUT2;
						
						Sys_Ct[2*( (counter/6)-1 )] <= S_sat_MAQ1;
						Sys_Ct[2*( (counter/6)-1 )+1] <= S_sat_MAQ2;						
					end
					else if(counter%6 == 2) begin
						Sys_Ht_temp[2*( (counter/6)-1 )] <= S_sat_ht_TMQ1;
						Sys_Ht_temp[2*( (counter/6)-1 )+1] <= S_sat_ht_TMQ2;	
						
						if(counter == 26) begin
							Sys_Ht[6] <= S_sat_ht_TMQ1;
							Sys_Ht[7] <= S_sat_ht_TMQ2;
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
				
				// *****************************************************************************//	
				//									BRANCH										//
				// *****************************************************************************//	
				BRANCH: begin
				
					//**** 1. WEIGHT BRAM CTRL ****//					
					if( counter == 0 ) begin
						weight_bram_EN <= 1'b1;
						weight_bram_addr1 <= BR_W_ADDR;			// Initialize addr.
						weight_bram_addr2 <= BR_W_ADDR;						
					end
					else if( counter < 1028) begin			
						weight_bram_addr1 <= weight_bram_addr1 + 1;
						weight_bram_addr2 <= weight_bram_addr2 + 1;					
					end
					else begin									
						weight_bram_EN <= 1'b0;
					end
					
					//**** 2. BIAS BRAM CTRL ****//
					if( (counter-2)%16 == 2 ) begin
						bias_bram_EN <= 1'b1;									
						if(counter == 4) bias_bram_addr <= BR_B_ADDR;	// Initialize addr.
						else bias_bram_addr <= bias_bram_addr + 1;
					end
					else if( (counter-2)%16 == 6 ) begin
						bias_bram_EN <= 1'b1;
						bias_bram_addr <= bias_bram_addr + 1;
					end
					else if( (counter-2)%16 == 10 ) begin
						bias_bram_EN <= 1'b1;
						bias_bram_addr <= bias_bram_addr + 1;
					end
					else if( (counter-2)%16 == 14 ) begin
						if(!(counter==0)) begin
							bias_bram_EN <= 1'b1;
							bias_bram_addr <= bias_bram_addr + 1;					
						end
					end
					else begin
						bias_bram_EN <= 1'b0;
					end
				
					//**** 3. INPDT CTRL ****//
					if( (2<=counter) && (counter<1028) ) begin
						inpdt_EN <= 1'b1;
					end
					else begin
						inpdt_EN <= 1'b0;
					end
					
					//**** 4. Register CTRL ****//
					// inpdt_R_reg1 ,2
					if( ((counter-2)%16)%4 == 1 ) begin
						inpdt_R_reg1 <= $signed(inpdt_R_wire1);	// Initialize the inpdt_R_reg1 ,2 & put in inpdt result.
						inpdt_R_reg2 <= $signed(inpdt_R_wire2);
					end
					else if( ((counter-2)%16)%4 >= 2 ) begin
						inpdt_R_reg1 <= $signed(inpdt_R_reg1) + $signed(inpdt_R_wire1);	// keep adding temp inpdt results. ( 1/4 each ). 
						inpdt_R_reg2 <= $signed(inpdt_R_reg2) + $signed(inpdt_R_wire2);						
					end
					else if( ((counter-2)%16)%4 == 0 ) begin
						inpdt_R_reg1 <= $signed(inpdt_R_reg1) + $signed(inpdt_R_reg2) + $signed(inpdt_R_wire1) + $signed(inpdt_R_wire2);
					end
					// temp_regA_1
					if ( (counter-2)%16 == 5 ) begin
						temp_regA_1[7:0] <= oSigmoid_LUT1;		// capture oSigmoid_LUT1.
					end
					else if( (counter-2)%16 == 6 ) begin					
						temp_regA_1 <= ($signed({1'b0,Br_Ct[ (counter-3)/16 ]}) - $signed({1'b0,ZERO_STATE}))*($signed({1'b0,temp_regA_1[7:0]}) - $signed({1'b0,OUT_ZERO_SIGMOID}));
					end
					else if( (counter-2)%16 == 1 /*actually 17*/ ) begin
						if(!(counter==3)) begin
							temp_regA_1[16:8] <= 'd0;			// capture oSigmoid_LUT1 & initialize [16:8].
							temp_regA_1[7:0] <= oSigmoid_LUT1;
						end
					end
					// temp_regB_1
					if ( (counter-2)%16 == 9 ) begin
						temp_regB_1 <= oSigmoid_LUT1;
					end
					// temp_regC_1
					if ( (counter-2)%16 == 13) begin
						temp_regC_1 <= oTanh_LUT1;
					end
					// Br_Ct.
					if ( (counter-2)%16 == 14 ) begin
						Br_Ct[ (counter-3)/16 ] <= B_sat_MAQ1;					
					end
					// Br_Ht_temp
					if ( (counter-2)%16 == 2 /*actually 18*/) begin
						if(!(counter==4)) begin
							if(!(counter==1028)) begin
								Br_Ht_temp[ (counter-3)/16 -1 ] <= B_sat_ht_TMQ1;	
							end
							else begin
								for(i=0; i<63; i=i+1) begin
									Br_Ht[i] <= Br_Ht_temp[i];
								end
								Br_Ht[63] <= B_sat_ht_TMQ1;							
							end
						end
					end

					//**** 5. Combinational CTRL ****//					
					if( (counter-2)%16 == 4 ) begin
						comb_ctrl <= B_BQS;
					end
					else if( (counter-2)%16 == 8 ) begin
						comb_ctrl <= B_BQS;
					end					
					else if( (counter-2)%16 == 12 ) begin
						comb_ctrl <= B_BQT;
					end					
					else if( (counter-2)%16 == 13 ) begin
						comb_ctrl <= B_MAQ;
					end										
					else if( (counter-2)%16 == 0 /*acutally 17*/ ) begin
						if(!(counter==2)) begin
							comb_ctrl <= B_BQS;
						end
					end							
					else if( (counter-2)%16 == 1 /*acutally 17*/) begin
						if(!(counter==3)) begin
							comb_ctrl <= B_TMQ;
							tanh_Ct_select <= (counter-4)/16;
						end
					end										
				end

				// *****************************************************************************//	
				//									CTXT_CONVERT								//
				// *****************************************************************************//	
				CTXT_CONVERT: begin
				
					//**** 1. WEIGHT BRAM CTRL ****//	
					if(ctxt_counter == 0) begin
						weight_bram_EN <= 1'b1;
						weight_bram_addr1 <= CTXT_W_ADDR;
						weight_bram_addr2 <= CTXT_W_ADDR;
					end
					else if( (1<=ctxt_counter) && (ctxt_counter<=31) ) begin
						weight_bram_addr1 <= weight_bram_addr1 + 1;
						weight_bram_addr2 <= weight_bram_addr2 + 1;
					end
					else begin
						weight_bram_EN <= 1'b0;
					end
					
					//**** 2. BIAS BRAM CTRL ****//
					if(ctxt_counter == 1) begin
						bias_bram_EN <= 1'b1;
						bias_bram_addr <= CTXT_B_ADDR;
					end
					else if( (2<=ctxt_counter) && (ctxt_counter<=32) ) begin
						bias_bram_addr <= bias_bram_addr + 1;
					end
					else begin
						bias_bram_EN <= 1'b0;
					end
					
					//**** 3. INPDT CTRL ****//
					if( (2<=ctxt_counter) && (ctxt_counter<=33) ) begin
						inpdt_EN <= 1'b1;
					end
					else begin
						inpdt_EN <= 1'b0;
					end
				
					//**** 4. Register CTRL ****//
					// inpdt_R_reg1 & inpdt_Rtemp_reg1
					if( (3<=ctxt_counter) && (ctxt_counter<=34) ) begin				
						inpdt_R_reg1 <= $signed(inpdt_Rmid1_wire1);
						inpdt_Rtemp_reg1 <= $signed(inpdt_Rmid2_wire1);
						
						inpdt_R_reg2 <= $signed(inpdt_Rmid1_wire2);
						inpdt_Rtemp_reg2 <= $signed(inpdt_Rmid2_wire2);
					end
					// Br_Ct & Br_Ht
					if( (4<=ctxt_counter) && (ctxt_counter<=35) ) begin
						Br_Ct[2*(ctxt_counter-4)] <= Ct_sat1;
						Br_Ct[2*(ctxt_counter-4)+1] <= Ct_sat2;			

						Br_Ht[2*(ctxt_counter-4)] <= Ht_sat1;
						Br_Ht[2*(ctxt_counter-4)+1] <= Ht_sat2;						
					end
				end	
					
		
				default: begin
				
				end
		
			endcase
			
		end
	end


// *****************************************************************************//	
// *****************************************************************************//	
//							CTRL COMBINATIONAL LOGIC							//
// *****************************************************************************//	
// *****************************************************************************//

	//************ Sigmoid / Tanh ************//
	always@(*) begin
		case(comb_ctrl)
			comb_IDLE: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;			
			end
			
			S_BQS: begin
				iSigmoid_LUT1 = S_sat_BQS1;
				iSigmoid_LUT2 = S_sat_BQS2;			
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;				
			end
			S_BQT: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = S_sat_BQT1;
				iTanh_LUT2 = S_sat_BQT2;				
			end
			S_MAQ_BQS: begin
				iSigmoid_LUT1 = S_sat_BQS1;
				iSigmoid_LUT2 = S_sat_BQS2;			
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;				
			end
			S_TMQ: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = S_sat_ct_TMQ1;
				iTanh_LUT2 = S_sat_ct_TMQ2;			
			end
			
			B_BQS: begin
				iSigmoid_LUT1 = B_sat_BQS1;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;				
			end
			B_BQT: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = B_sat_BQT1;
				iTanh_LUT2 = 'd0;				
			end
			B_MAQ: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;				
			end
			B_TMQ: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = B_sat_ct_TMQ1;
				iTanh_LUT2 = 'd0;				
			end
			default: begin
				iSigmoid_LUT1 = 'd0;
				iSigmoid_LUT2 = 'd0;			
				iTanh_LUT1 = 'd0;
				iTanh_LUT2 = 'd0;				
			end
		endcase
	end

	
	always@(*) begin
	
		//************ S_BQS || S_MAQ_BQS ************//	
		if(comb_ctrl == S_BQS) begin
			//S_real_inpdt_sumBQS1 = $signed( $signed(($signed(inpdt_R_reg1)*SCALE_SIGMOID))/(SCALE_W*SCALE_DATA) );
			S_real_inpdt_sumBQS1 = $signed(inpdt_R_reg1)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQS1 = (($signed({1'b0,bias_buffer[15:8]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_SIGMOID))/$signed(SCALE_B);
			S_unsat_BQS1 = $signed(S_real_inpdt_sumBQS1) + $signed(S_real_biasBQS1) + $signed({1'b0,ZERO_SIGMOID});
			
			//S_real_inpdt_sumBQS2 = ($signed(inpdt_R_reg2)*SCALE_SIGMOID)/(SCALE_W*SCALE_DATA);
			S_real_inpdt_sumBQS2 = $signed(inpdt_R_reg2)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQS2 = (($signed({1'b0,bias_buffer[7:0]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_SIGMOID))/$signed(SCALE_B);
			S_unsat_BQS2 = $signed(S_real_inpdt_sumBQS2) + $signed(S_real_biasBQS2) + $signed({1'b0,ZERO_SIGMOID});
			
			S_real_ctf_MAQ1 = 'd0;
			S_real_ctf_MAQ2 = 'd0;
			S_real_ig_MAQ1 = 'd0;
			S_real_ig_MAQ2 = 'd0;
			S_real_sum_MAQ1 = 'd0;
			S_real_sum_MAQ2 = 'd0;
			S_unsat_MAQ1 = 'd0;
			S_unsat_MAQ2 = 'd0;				
		end
		else if(comb_ctrl == S_MAQ_BQS) begin
			S_real_inpdt_sumBQS1 = $signed(inpdt_R_reg1)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQS1 = (($signed({1'b0,bias_buffer[15:8]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_SIGMOID))/$signed(SCALE_B);
			S_unsat_BQS1 = $signed(S_real_inpdt_sumBQS1) + $signed(S_real_biasBQS1) + $signed({1'b0,ZERO_SIGMOID});

			S_real_inpdt_sumBQS2 = $signed(inpdt_R_reg2)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQS2 = (($signed({1'b0,bias_buffer[7:0]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_SIGMOID))/$signed(SCALE_B);
			S_unsat_BQS2 = $signed(S_real_inpdt_sumBQS2) + $signed(S_real_biasBQS2) + $signed({1'b0,ZERO_SIGMOID});
			
			S_real_ctf_MAQ1 = $signed(temp_regA_1)/$signed(OUT_SCALE_SIGMOID);
			S_real_ig_MAQ1 = (($signed({1'b0,temp_regB_1})-$signed({1'b0,OUT_ZERO_SIGMOID})) * ($signed({1'b0,temp_regC_1})-$signed({1'b0,OUT_ZERO_TANH}))
			*$signed(SCALE_STATE))/($signed(OUT_SCALE_SIGMOID)*$signed(OUT_SCALE_TANH));
			S_real_sum_MAQ1 = $signed(S_real_ctf_MAQ1) + $signed(S_real_ig_MAQ1);
			S_unsat_MAQ1 = $signed(S_real_sum_MAQ1) + $signed({1'b0,ZERO_STATE});
			
			S_real_ctf_MAQ2 = $signed(temp_regA_2)/$signed(OUT_SCALE_SIGMOID);
			S_real_ig_MAQ2 = (($signed({1'b0,temp_regB_2})-$signed({1'b0,OUT_ZERO_SIGMOID})) * ($signed({1'b0,temp_regC_2})-$signed({1'b0,OUT_ZERO_TANH}))
			*$signed(SCALE_STATE))/($signed(OUT_SCALE_SIGMOID)*$signed(OUT_SCALE_TANH));
			S_real_sum_MAQ2 = $signed(S_real_ctf_MAQ2) + $signed(S_real_ig_MAQ2);
			S_unsat_MAQ2 = $signed(S_real_sum_MAQ2) + $signed({1'b0,ZERO_STATE});			
		end
		else begin
			S_real_inpdt_sumBQS1 = 'd0; 
			S_real_inpdt_sumBQS2 = 'd0; 
			S_real_biasBQS1 = 'd0;			
			S_real_biasBQS2 = 'd0;			
			S_unsat_BQS1 = 'd0;
			S_unsat_BQS2 = 'd0;		
			
			S_real_ctf_MAQ1 = 'd0;
			S_real_ctf_MAQ2 = 'd0;
			S_real_ig_MAQ1 = 'd0;
			S_real_ig_MAQ2 = 'd0;
			S_real_sum_MAQ1 = 'd0;
			S_real_sum_MAQ2 = 'd0;
			S_unsat_MAQ1 = 'd0;
			S_unsat_MAQ2 = 'd0;				
		end
		
		//************ S_BQT ************//			
		if(comb_ctrl == S_BQT) begin
			S_real_inpdt_sumBQT1 =  $signed(inpdt_R_reg1)*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQT1 = (($signed({1'b0,bias_buffer[15:8]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_TANH))/$signed(SCALE_B);
			S_unsat_BQT1 = $signed(S_real_inpdt_sumBQT1) + $signed(S_real_biasBQT1) + $signed({1'b0,ZERO_TANH});
			
			S_real_inpdt_sumBQT2 = $signed(inpdt_R_reg2)*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA));
			S_real_biasBQT2 = (($signed({1'b0,bias_buffer[7:0]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_TANH))/$signed(SCALE_B);
			S_unsat_BQT2 = $signed(S_real_inpdt_sumBQT2) + $signed(S_real_biasBQT2) + $signed({1'b0,ZERO_TANH});
		end
		else begin
			S_real_inpdt_sumBQT1 = 'd0; 
			S_real_inpdt_sumBQT2 = 'd0; 
			S_real_biasBQT1 = 'd0;			
			S_real_biasBQT2 = 'd0;			
			S_unsat_BQT1 = 'd0;
			S_unsat_BQT2 = 'd0;		
		end

		//************ S_TMQ ************//						
		if(comb_ctrl == S_TMQ) begin
			S_unsat_ct_TMQ1 = (($signed({1'b0,Sys_Ct[2*tanh_Ct_select]})-$signed({1'b0,ZERO_STATE}))*$signed(SCALE_TANH))/$signed(SCALE_STATE) + $signed({1'b0,ZERO_TANH});			
			S_unscale_ht_TMQ1 = ($signed({1'b0,temp_regA_1})-$signed({1'b0,OUT_ZERO_SIGMOID}))*($signed({1'b0,oTanh_LUT1})-{1'b0,ZERO_TANH});
			S_unsat_ht_TMQ1 = ($signed(S_unscale_ht_TMQ1)*$signed(SCALE_DATA))/($signed(OUT_SCALE_TANH)*$signed(OUT_SCALE_SIGMOID));
			S_unsat_Z_ht_TMQ1 = $signed(S_unsat_ht_TMQ1) + $signed({1'b0,ZERO_DATA});
			
			S_unsat_ct_TMQ2 = (($signed({1'b0,Sys_Ct[2*tanh_Ct_select+1]})-$signed({1'b0,ZERO_STATE}))*$signed(SCALE_TANH))/$signed(SCALE_STATE) + $signed({1'b0,ZERO_TANH});			
			S_unscale_ht_TMQ2 = ($signed({1'b0,temp_regA_2})-$signed({1'b0,OUT_ZERO_SIGMOID}))*($signed({1'b0,oTanh_LUT2})-{1'b0,ZERO_TANH});
			S_unsat_ht_TMQ2 = ($signed(S_unscale_ht_TMQ2)*$signed(SCALE_DATA))/($signed(OUT_SCALE_TANH)*$signed(OUT_SCALE_SIGMOID));
			S_unsat_Z_ht_TMQ2 = $signed(S_unsat_ht_TMQ2) + $signed({1'b0,ZERO_DATA});			
		end
		else begin
			S_unsat_ct_TMQ1 = 'd0;
			S_unsat_ct_TMQ2 = 'd0;
			S_unscale_ht_TMQ1 = 'd0;
			S_unscale_ht_TMQ2 = 'd0;
			S_unsat_ht_TMQ1 = 'd0;	
			S_unsat_ht_TMQ2 = 'd0;	
			S_unsat_Z_ht_TMQ1 = 'd0;
			S_unsat_Z_ht_TMQ2 = 'd0;			
		end
		
		//************ B_BQS ************//		
		if(comb_ctrl == B_BQS) begin
			B_real_inpdt_sumBQS1 = $signed( $signed(inpdt_R_reg1)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA)) );
			//+ $signed( $signed(inpdt_R_reg2)*$signed(SCALE_SIGMOID)/($signed(SCALE_W)*$signed(SCALE_DATA)) );							// Sumation of X & H
			B_real_biasBQS1 = (($signed({1'b0,bias_buffer[7:0]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_SIGMOID))/$signed(SCALE_B);
			B_unsat_BQS1 = $signed(B_real_inpdt_sumBQS1) + $signed(B_real_biasBQS1) + $signed({1'b0,ZERO_SIGMOID});
		end
		else begin
			B_real_inpdt_sumBQS1 = 'd0;
			B_real_biasBQS1 = 'd0;
			B_unsat_BQS1 = 'd0;
		end
		
		//************ B_BQT ************//	
		if(comb_ctrl == B_BQT) begin
			B_real_inpdt_sumBQT1 = $signed( $signed(inpdt_R_reg1)*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA)) );
			//+ $signed( $signed(inpdt_R_reg2)*$signed(SCALE_TANH)/($signed(SCALE_W)*$signed(SCALE_DATA)) );								// Sumation of X & H
			B_real_biasBQT1 = (($signed({1'b0,bias_buffer[7:0]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_TANH))/$signed(SCALE_B);
			B_unsat_BQT1 = $signed(B_real_inpdt_sumBQT1) + $signed(B_real_biasBQT1) + $signed({1'b0,ZERO_TANH});
		end
		else begin
			B_real_inpdt_sumBQT1 = 'd0;
			B_real_biasBQT1 = 'd0;
			B_unsat_BQT1 = 'd0;
		end
		
		//************ B_MAQ ************//		
		if(comb_ctrl == B_MAQ) begin
			B_real_ctf_MAQ1 = $signed(temp_regA_1)/$signed(OUT_SCALE_SIGMOID);
			B_real_ig_MAQ1 = (($signed({1'b0,temp_regB_1})-$signed({1'b0,OUT_ZERO_SIGMOID})) * ($signed({1'b0,temp_regC_1})-$signed({1'b0,OUT_ZERO_TANH}))
			*$signed(SCALE_STATE))/($signed(OUT_SCALE_SIGMOID)*$signed(OUT_SCALE_TANH));
			B_real_sum_MAQ1 = $signed(B_real_ctf_MAQ1) + $signed(B_real_ig_MAQ1);
			B_unsat_MAQ1 = $signed(B_real_sum_MAQ1) + $signed({1'b0,ZERO_STATE});
		end
		else begin
			B_real_ctf_MAQ1 = 'd0;
			B_real_ig_MAQ1 = 'd0;
			B_real_sum_MAQ1 = 'd0;
			B_unsat_MAQ1 = 'd0;
		end
		
		//************ B_TMQ ************//		
		if(comb_ctrl == B_TMQ) begin
			B_unsat_ct_TMQ1 = (($signed({1'b0,Br_Ct[tanh_Ct_select]})-$signed({1'b0,ZERO_STATE}))*$signed(SCALE_TANH))/$signed(SCALE_STATE) + $signed({1'b0,ZERO_TANH});		
			B_unscale_ht_TMQ1 = ($signed({1'b0,temp_regA_1})-$signed({1'b0,OUT_ZERO_SIGMOID}))*($signed({1'b0,oTanh_LUT1})-{1'b0,ZERO_TANH});
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

	//************ CTXT Quantization ************//
	always@(*) begin
		if(lstm_state == CTXT_CONVERT) begin
			Ct_real_inpdt_sum1 = $signed(inpdt_R_reg1)/($signed(SCALE_W));
			Ct_real_inpdt_sum2 = $signed(inpdt_Rtemp_reg1)/($signed(SCALE_W));
			Ct_real_bias1 = ($signed({1'b0,bias_buffer[31:24]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_STATE)/$signed(SCALE_B);
			Ct_real_bias2 = ($signed({1'b0,bias_buffer[23:16]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_STATE)/$signed(SCALE_B);
			Ct_unsat1 = $signed(Ct_real_inpdt_sum1) + $signed(Ct_real_bias1) + $signed({1'b0,ZERO_STATE});
			Ct_unsat2 = $signed(Ct_real_inpdt_sum2) + $signed(Ct_real_bias2) + $signed({1'b0,ZERO_STATE});				

			Ht_real_inpdt_sum1 = $signed(inpdt_R_reg2)/($signed(SCALE_W));
			Ht_real_inpdt_sum2 = $signed(inpdt_Rtemp_reg2)/($signed(SCALE_W));
			Ht_real_bias1 = ($signed({1'b0,bias_buffer[15:8]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_DATA)/$signed(SCALE_B);		
			Ht_real_bias2 = ($signed({1'b0,bias_buffer[7:0]})-$signed({1'b0,ZERO_B}))*$signed(SCALE_DATA)/$signed(SCALE_B);
			Ht_unsat1 = $signed(Ht_real_inpdt_sum1) + $signed(Ht_real_bias1) + $signed({1'b0,ZERO_DATA});	
			Ht_unsat2 = $signed(Ht_real_inpdt_sum2) + $signed(Ht_real_bias2) + $signed({1'b0,ZERO_DATA});
		end
		else begin
			Ct_real_inpdt_sum1 = 'd0;
			Ct_real_inpdt_sum2 = 'd0;	
			Ct_real_bias1 = 'd0;
			Ct_real_bias2 = 'd0;	
			Ct_unsat1 = 'd0;
			Ct_unsat2 = 'd0;	

			Ht_real_inpdt_sum1 = 'd0;
			Ht_real_inpdt_sum2 = 'd0;	
			Ht_real_bias1 = 'd0;
			Ht_real_bias2 = 'd0;	
			Ht_unsat1 = 'd0;
			Ht_unsat2 = 'd0;				
		end
	end
	
	assign S_sat_BQS1 = (S_unsat_BQS1[31]) ? 8'd0 : (|S_unsat_BQS1[30:8] == 1) ? 8'd255 : S_unsat_BQS1[7:0];
	assign S_sat_BQS2 = (S_unsat_BQS2[31]) ? 8'd0 : (|S_unsat_BQS2[30:8] == 1) ? 8'd255 : S_unsat_BQS2[7:0];
	assign S_sat_BQT1 = (S_unsat_BQT1[31]) ? 8'd0 : (|S_unsat_BQT1[30:8] == 1) ? 8'd255 : S_unsat_BQT1[7:0];
	assign S_sat_BQT2 = (S_unsat_BQT2[31]) ? 8'd0 : (|S_unsat_BQT2[30:8] == 1) ? 8'd255 : S_unsat_BQT2[7:0];
	assign S_sat_MAQ1 = (S_unsat_MAQ1[31]) ? 8'd0 : (|S_unsat_MAQ1[30:8] == 1) ? 8'd255 : S_unsat_MAQ1[7:0];
	assign S_sat_MAQ2 = (S_unsat_MAQ2[31]) ? 8'd0 : (|S_unsat_MAQ2[30:8] == 1) ? 8'd255 : S_unsat_MAQ2[7:0];
	assign S_sat_ct_TMQ1 = (S_unsat_ct_TMQ1[31]) ? 8'd0 : (|S_unsat_ct_TMQ1[30:8] == 1) ? 8'd255 : S_unsat_ct_TMQ1[7:0];
	assign S_sat_ct_TMQ2 = (S_unsat_ct_TMQ2[31]) ? 8'd0 : (|S_unsat_ct_TMQ2[30:8] == 1) ? 8'd255 : S_unsat_ct_TMQ2[7:0];
	assign S_sat_ht_TMQ1 = (S_unsat_Z_ht_TMQ1[31]) ? 8'd0 : (|S_unsat_Z_ht_TMQ1[30:8] == 1) ? 8'd255 : S_unsat_Z_ht_TMQ1[7:0];
	assign S_sat_ht_TMQ2 = (S_unsat_Z_ht_TMQ2[31]) ? 8'd0 : (|S_unsat_Z_ht_TMQ2[30:8] == 1) ? 8'd255 : S_unsat_Z_ht_TMQ2[7:0];
	
	assign B_sat_BQS1 = (B_unsat_BQS1[31]) ? 8'd0 : (|B_unsat_BQS1[30:8] == 1) ? 8'd255 : B_unsat_BQS1[7:0];
	assign B_sat_BQT1 = (B_unsat_BQT1[31]) ? 8'd0 : (|B_unsat_BQT1[30:8] == 1) ? 8'd255 : B_unsat_BQT1[7:0];
	assign B_sat_MAQ1 = (B_unsat_MAQ1[31]) ? 8'd0 : (|B_unsat_MAQ1[30:8] == 1) ? 8'd255 : B_unsat_MAQ1[7:0];
	assign B_sat_ct_TMQ1 = (B_unsat_ct_TMQ1[31]) ? 8'd0 : (|B_unsat_ct_TMQ1[30:8] == 1) ? 8'd255 : B_unsat_ct_TMQ1[7:0];
	assign B_sat_ht_TMQ1 = (B_unsat_Z_ht_TMQ1[31]) ? 8'd0 : (|B_unsat_Z_ht_TMQ1[30:8] == 1) ? 8'd255 : B_unsat_Z_ht_TMQ1[7:0];	

	assign Ct_sat1 = (Ct_unsat1[31]) ? 8'd0 : (|Ct_unsat1[30:8] == 1) ? 8'd255 : Ct_unsat1[7:0];
	assign Ct_sat2 = (Ct_unsat2[31]) ? 8'd0 : (|Ct_unsat2[30:8] == 1) ? 8'd255 : Ct_unsat2[7:0];
	assign Ht_sat1 = (Ht_unsat1[31]) ? 8'd0 : (|Ht_unsat1[30:8] == 1) ? 8'd255 : Ht_unsat1[7:0];
	assign Ht_sat2 = (Ht_unsat2[31]) ? 8'd0 : (|Ht_unsat2[30:8] == 1) ? 8'd255 : Ht_unsat2[7:0];
	
endmodule
