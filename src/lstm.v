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
	input [255:0] iCt_load,
	input [255:0] iHt_load,

	input iNext_valid,	// top valid & ready. 
	input iMode,		// System or Branch mode
	input [255:0] iData,

	output reg oLstm_done,	// lstm done & ready to do next task. 
	output reg [255:0] oCt,	
	output reg [255:0] oHt,	
);

	localparam IDLE = 2'd0, SYSTEM = 2'd1, BRANCH = 2'd2;
	localparam SYS_type = 1'b0, BR_type = 1'b1; 
	localparam BR_addr_zero = 11'b100_0000_0000;
	
////////
//    //
////////
	reg [1:0] state;

	reg [10:0] counter;	// up to 2048 cycle. 
	
	reg [255:0] temp_reg1;
	reg [255:0] temp_reg2;
	

///////////////////
// WEIGHT BRAM   //
///////////////////
	reg [10:0] bram_addr;
	reg bram_EN;
	reg bram_WE;
	reg [255:0] bram_write_data;
	wire [255:0] bram_read_data;
	

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
					oCt[255:64] <= oCt[255:64];
					oCt[63:0] <= iCt_load;
					oHt[255:64] <= oHt[255:64];
					oHt[63:0] <= iHt_load;		
					
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
				if(counter == ) begin
					state <= IDLE;
					
					counter <= 'd0;
				end
				else begin
					counter <= counter + 1;
				end
			end
			
			BRANCH: begin
				if(counter == ) begin
					state <= IDLE;
					
					counter <= 'd0;
				end
				else begin
					counter <= counter + 1;
				end
			end

			default: begin
			
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
			
			bram_addr <= 'd0;
			bram_EN <= 1'b0;
			bram_WE <= 1'b0;
			bram_write_data <= 'd0;
		end
		else begin
			if(state == SYSTEM) begin
				
				//// 1. BRAM CONTROL ////
				if(counter <= 4) begin
					bram_addr <= bram_addr + 1;
					bram_EN <= 1'b1;
				end
				else if(counter <= 9) begin
			
				end
				else if(counter <= 17) begin
					bram_addr <= bram_addr + 1;
				end
				else if(counter <= 18) begin
				
				end
				else if(counter <= 21) begin
					bram_addr <= bram_addr + 1;
				end
				
				//// 2. INNER PRODUCT CONTROL ////
				if(counter <= 1) begin
					
				end
				else if(counter <= 5) begin
					// CALCULATE f x2
				end
				else if(counter <= 10) begin

				end
				else if(counter <= 18) begin
					// CALCULATE i/g -> in order to utilize Sigmoid LUT. 				
				end
				else if(counter <= 19) begin
				
				end
				else if(counter <= 23) begin
					// CACULATE o x2
				end
			
			
				//// 3. Base ADD & Sigmoid CONTROL ////
				if(counter <= 2) begin
				
				end
				else if(counter <= 10) begin
					// CALCULATE B/S of f
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
				
			end
			
			/////////////////////////////////////////////////////////////////////////
			
			else if(state == BRANCH) begin
			
				//// 1. BRAM CONTROL ////
				if(
			
			
				//// 2. INNER PRODUCT CONTROL ////
				if(counter <= 1) begin
					
				end
				else if(counter <= 257) begin
					// CALCULATE f
				end
				else if(counter <= 513) begin // 2+256+255
					// CACULATE i
				end
				else if(counter <= 769) begin // 2+256+256+255
					// CALCULATE g
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
