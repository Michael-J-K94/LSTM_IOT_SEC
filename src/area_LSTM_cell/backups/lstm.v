// This is a Top
// Description:
// Author: Michael Kim

module LSTM#(
	parameter integer PID_bit = 10
)
(
	input clk,
	input resetn,
	
	input iLoad_valid,	// load ct/ht valid
	input [511:0] iCt_load,
	input [511:0] iHt_load,

	input iNext_valid,	// top valid & ready. 
	input iMode,		// System or Branch mode
	input [511:0] iData,

	output reg oLstm_done,	// lstm done & ready to do next task. 
	output reg [511:0] oCt,	
	output reg [511:0] oHt,	
);

	localparam IDLE = 2'd0, SYSTEM = 2'd1, BRANCH = 2'd2, ERROR = 2'd3;
	localparam SYS_type = 1'b0, BR_type = 1'b1; 
	localparam BR_W_addr_zero = 11'b100_0000_0000;
	localparam BR_B_addr_zero = 9'b1_0000_0000;
	
////////
//    //
////////
	reg [1:0] state;
	reg [10:0] counter;	// up to 2048 cycle. 

	
	reg [511:0] temp_reg1;
	reg [511:0] temp_reg2;

	reg [21:0] inpdt_temp_reg1;
	reg [21:0] inpdt_temp_reg2;

	reg inpdt_En;
	
	reg inpdt_mode;
	
	reg [1:0] inpdt_X_select;
	wire [127:0] inpdt_X1;
	reg [127:0] inpdt_X1_temp;
	wire [127:0] inpdt_W1;
	wire [127:0] inpdt_X2;
	reg [127:0] inpdt_X2_temp;	
	wire [127:0] inpdt_W2;
	wire [20:0] inpdt_R1;
	wire [20:0] inpdt_R2;


///////////////////
// WEIGHT BRAM   //
///////////////////
	reg [10:0] bram_addr;
	reg bram_EN;
	reg bram_WE;
	reg [255:0] bram_write_data;
	wire [255:0] bram_read_data;
	
	reg [255:0] weight_buffer;


///////////////////
// BIAS BRAM   //
///////////////////
	reg [8:0] bias_addr;
	reg bias_EN;
	reg bias_WE;
	reg [15:0] bias_write_data;
	wire [15:0] bias_read_data;
	
	reg [15:0] bias_buffer;	
	
	
///////////////////
//  INPDT Xt/W   //
///////////////////	
	always@(*) begin
		if(inpdt_mode == SYS_type) begin
			inpdt_X1_temp = {iData[63:0],iData[63:0]};
			inpdt_X2_temp = {iData[63:0],iData[63:0]};
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
	assign inpdt_X1 = inpdt_X1_temp;
	assign inpdt_X2 = inpdt_X2_temp;
	assign inpdt_W1 = weight_buffer[255:128];
	assign inpdt_W2 = weight_buffer[127:0];

	inpdt_16 u_inpdt_1(
		iData_X(inpdt_X1),
		iData_W(inpdt_W1),
		iEn(inpdt_En),
		oResult(inpdt_R1)
	);
	
	inpdt_16 u_inpdt_2(
		iData_X(inpdt_X2),
		iData_W(inpdt_W2),
		iEn(inpdt_En),
		oResult(inpdt_R2)
	);	


//////////////
// LSTM FSM //
//////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			state <= IDLE;
			
			oLstm_done <= 1'b1;
			oCt <= 'd0;
			oHt <= 'd0;
			
			counter <= 'd0;
		end
		else begin		
		
			case(state)
			
				IDLE: begin
					if(iLoad_valid) begin			// LOAD only happen in IDLE state, and does not overlap with other calculation state.
						// Ct[511:64] <= Ct[255:64];
						// Ct[63:0] <= iCt_load;
						// Ht[511:64] <= Ht[255:64];
						// Ht[63:0] <= iHt_load;		
						oCt <= iCt_load;
						oHt <= iHt_load;
						
						state <= IDLE;
					end
					else if(iNext_valid) begin
						if(iMode == SYS_type) begin
							state <= SYSTEM;
						end
						else if(iMode == BR_type) begin
							state <= BRANCH;
						end
					end
				end
				
				SYSTEM: begin
					if(counter == /* ???????? */ ) begin 
						state <= IDLE;
						
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end
				
				BRANCH: begin
					if(counter == /* ???????? */ ) begin
						state <= IDLE;
						
						counter <= 'd0;
					end
					else begin					
						counter <= counter + 1;
					end
				end

				ERROR: begin
					state <= ERROR;
				end	

				default: begin
					state <= ERROR;			
					oLstm_done <= 1'b1;
					oCt <= 'd0;
					oHt <= 'd0;					
					counter <= 'd0;				
				end
			
			endcase
		end	
	end


/////////////////////////////////
// SYSTEM & BRANCH CALCULATION //
/////////////////////////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			temp_reg1 <= 'd0;
			temp_reg2 <= 'd0;
			inpdt_temp_reg1 <= 'd0;
			inpdt_temp_reg2 <= 'd0;
			
			inpdt_En <= 'd0;
			inpdt_mode <= 'd0;
			inpdt_X_select <= 2'b11;
			
			bram_addr <= 'd0;
			bram_EN <= 1'b0;
			bram_WE <= 1'b0;
			bram_write_data <= 'd0;
			weight_buffer <= 'd0;
			
			bias_addr <= 'd0;
			bias_EN <= 1'b0;
			bias_WE <= 1'b0;
			bias_write_data;
			bias_buffer <= 'd0;;				
		end
		else begin
			/////////////////////////////////////////////////////////////////////////
			if(state == SYSTEM) begin
				inpdt_mode <= SYS_type;
				
				//// 1. BRAM CONTROL ////
				if(counter <
				
				
				
				
				
				
				
				
				
				//// 1. BRAM CONTROL ////
				if(counter <= 4) begin
					bram_EN <= 1'b1;
					if(counter == 0) bram_addr <= 'd0;
					else bram_addr <= bram_addr + 1;
					weight_buffer <= bram_read_data;
				end
				else if(counter <= 9) begin
			
				end
				else if(counter <= 17) begin
					bram_addr <= bram_addr + 1;
					weight_buffer <= bram_read_data;
				end
				else if(counter <= 18) begin
				
				end
				else if(counter <= 21) begin
					bram_addr <= bram_addr + 1;
					weight_buffer <= bram_read_data;
				end
				else begin
					bram_EN <= 1'b0;
					bram_addr <= 'd0;
					weight_buffer <= weight_buffer;
				end
				
				//// 2. INNER PRODUCT CONTROL ////
				if(counter <= 1) begin
					inpdt_En <= 1'b0;					
				end
				else if(counter <= 5) begin
					// CALCULATE f x2
					inpdt_En <= 1'b1;
					
					inpdt_temp_reg1[21] <= inpdt_temp_reg1[21];
					inpdt_temp_reg1[20:0] <= inpdt_R1;
					inpdt_temp_reg2[21] <= inpdt_temp_reg2[21];
					inpdt_temp_reg2[20:0] <= inpdt_R2;					
				end
				else if(counter <= 10) begin
					inpdt_En <= 1'b0;
				end
				else if(counter <= 18) begin
					// CALCULATE i/g -> in order to utilize Sigmoid LUT. 		
					inpdt_En <= 1'b1;

					inpdt_temp_reg1[21] <= inpdt_temp_reg1[21];
					inpdt_temp_reg1[20:0] <= inpdt_R1;
					inpdt_temp_reg2[21] <= inpdt_temp_reg2[21];
					inpdt_temp_reg2[20:0] <= inpdt_R2;					
				end
				else if(counter <= 19) begin
					inpdt_En <= 1'b0;
				end
				else if(counter <= 23) begin
					// CACULATE o x2
					inpdt_En <= 1'b1;

					inpdt_temp_reg1[21] <= inpdt_temp_reg1[21];
					inpdt_temp_reg1[20:0] <= inpdt_R1;
					inpdt_temp_reg2[21] <= inpdt_temp_reg2[21];
					inpdt_temp_reg2[20:0] <= inpdt_R2;							
				end
				else begin
					inpdt_En <= 1'b0;
				end
			
			
				//// 3. Base ADD & Quantization & Sigmoid CONTROL ////
				if(counter <= 2-1) begin
					//
				end
				else if(counter <= 10-1) begin
					// f bias
					bias_EN <= 1'b1;
					bias_addr <= bias_addr + 1;					
					bias_buffer <= bias_read_data;
				end
				else if(counter <= 11-1) begin
					//
				end
				else if(counter <= 19-1) begin
					// 
					bias_addr <= bias_addr + 1;
					bias_buffer <= bias_read_data;					
				end
				else if(counter <= 20-1) begin
					//
				end
				else if(counter <= 28-1) begin
					bias_addr <= bias_addr + 1;
					bias_buffer <= bias_read_data;					
				end
				else begin
					bias_EN <= 1'b0;
					bias_addr <= 'd0;
					bias_buffer <= bias_buffer;
				end

				if(counter <= 2) begin
					
				end
				else if(counter <= 10-1) begin
					// CALCULATE B/S of f
					temp_reg1[63 + 8*(counter-3)-1 -: 8] <= sigmoid(  )
					
				end
				else if(counter <= 11) begin
				
				end
				else if(counter <= 19) begin
					// CALCULATE B/S of i
				end
				else if(counter <= 20) begin
				
				end
				else if(counter <= 28) begin
					// CALCULATE B/S of o
				end
				else begin
				
				end
				
				//// 4. Base ADD & Tanh CONTROL ////
				if(counter <= 11) begin
					
				end
				else if(counter <= 19) begin
					// CALCULATE B/T of g
				end
				else if(counter <= 20) begin
				
				end
				else if(counter <= 28) begin
					// CALCULATE B/T of Ct
				end
				else begin
				
				end
				
				//// 5. HM & ADD CONTORL ////
				if(counter <= 10) begin
				
				end
				else if(counter <= 11) begin
					// CALCULATE HM of Ct & f
				end
				else if(counter <= 19) begin
				
				end
				else if(counter <= 20) begin
					// CALCULATE HM & ADD of Ct_temp & i,g
				end
				else if(counter <= 28) begin
				
				end
				else if(counter <= 29) begin
					// CALCULATE HM of tanh(Ct_temp) & o
				end
				else begin
				
				end				
			end
			
			/////////////////////////////////////////////////////////////////////////
			
			else if(state == BRANCH) begin
				inpdt_mode <= BR_type;
				
				//// 1. BRAM CONTROL ////
				if(
			
			
				//// 2. INNER PRODUCT CONTROL ////
				if(counter <= 1) begin
					inpdt_En <= 1'b0;
				end
				else if(counter <= 257) begin
					// CALCULATE f
					inpdt_En <= 1'b1;
					
					inpdt_X_select <= inpdt_X_select - 1;					
				end
				else if(counter <= 513) begin // 2+256+255
					// CACULATE i
					inpdt_En <= 1'b1;
					
					inpdt_X_select <= inpdt_X_select - 1;					
				end
				else if(counter <= 769) begin // 2+256+256+255
					// CALCULATE g
					inpdt_En <= 1'b1;
					
					inpdt_X_select <= inpdt_X_select - 1;					
				end
				else if(counter <= 770) begin // 2+256+256+255+1
					
				end
				else if(counter <= 1026) begin // 2+256+256+256+1+255
					// CACULATE o
				end
				
				//// 3. Base ADD & Sigmoid CONTORL ////
				if(counter <= (2+256) ) begin
					if( (counter-2)%4 == 0) begin
						// CALCULATE B/S of f
					end
				end
				else if(counter <= (2+256*2) ) begin
					if( (counter-2)%4 == 0) begin
						// CALCULATE B/S of i
					end
				end
				else if(counter <= (2+256*3+1) ) begin
				
				end
				else if(counter <= (2+256*3+1+256) ) begin
					if( (counter-3)%4 == 0) begin
						// CALCULATE B/S of o
					end
				end
				
				//// 4. Base ADD & Tanh CONTORL ////
				if(counter <= (2+256*2) )begin
				
				end
				else if(counter <= (2+256*3) ) begin
					if( (counter-2)&4 == 0) begin
						// CALCULATE B/T of g
					end
				end
				else if(counter <= 772) begin
				
				end
				else if(counter <= 836) begin
					// CALCULATE Tanh of Ct
				end
				
				//// 5. HM & ADD CONTORL ////
				
				
				
			end
			

			else begin	// Exception. Error.
				bram_EN <= 1'b0;
			end
		end	
	end









endmodule
