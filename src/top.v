// This is a Top
// Description:
// Author: Michael Kim

module Top#(
	parameter integer PID_bit = 10
)
(
	input clk,
	input resetn,

	input iBuff_on,
	input [511:0] iBuff_data,
	input iBuff_type,
	input [PID_bit-1:0] iBuff_PID,
	
	output reg oTop_ready, // to notify buffer


);

	localparam IDLE = 4'd0, oPSB = 4'd1, oPSS = 4'd2, oPBB = 4'd3, oPBS = 4'd4, nPSB = 4'd5, nPSS = 4'd6, nPBB = 4'd7, nPBS = 4'd8, init_SYS = 4'd9, init_BR = 4'd10, done_BR = 4'd11, sit_ERR = 4'hf;
	localparam PID_CHECK = 3'd1, LOAD_PCT = 3'd2, SAVE_PCT = 3'd3, CAL_CTXT = 3'd4, SYS_VALID = 3'd5, BR_VALID = 3'd6, top_ERR = 3'd7;
	localparam SYS_type = 1'd0, BR_type = 1'd1;
	
	
	
/////////////
// Top FSM //	
/////////////
	reg [2:0] top_state;
	reg initial_case;
	reg [3:0] situation;

	reg [511:0] idata_is;		
	reg type_is;
	reg type_was;
	reg [PID_bit-1:0] PID_is;
	reg [PID_bit-1:0] PID_was;
	reg [4:0] br_cnt;
	reg br_done_flag;
	
	reg [1:0] top_delay;
	



/////////////////
// LSTM in/out // 	
/////////////////
	reg load_valid;
	reg [63:0] ct_load;
	reg [63:0] ht_load;	
	
	reg next_input_valid;
	reg lstm_Mode;
	reg [511:0] lstm_data;

	wire lstm_done;
	wire [511:0] ct;
	wire [511:0] ht;
	
	

	
///////////////////////////
// Process Context Table //	
///////////////////////////
	reg [PID_bit-1:0] PCT_addr;
	reg PCT_EN;
	reg PCT_WE;
	reg [133:0] PCT_write_data; // 518 bit = 5(br_cnt) + 1(br_done_flag) + 128(SYS_CTXT.   cf. BR_CTXT will be calculated from SYS_CTXT)
	wire [133:0] PCT_read_data;
	

/////////////
// Top FSM //	
/////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			oTop_ready <= 1'b1;	// ????????????????????????????????????????????????????????????????????
		
			top_state <= IDLE;
			initial_case <= 1'b1;
			situation <= IDLE;
			
			next_input_valid <= 'd0;
			
			idata_is <= 'd0;
			type_is <= 'd0;
			type_was <= 'd0;
			PID_is <= 'd0;
			PID_was <= 'd0;
			br_cnt <= 'd0;
			br_done_flag <= 'd0;
			load_valid <= 'd0;
			
			top_delay <= 'd0;
			
			ct_load <= 'd0;
			ht_load <= 'd0;

			PCT_addr <= 'd0;
			PCT_EN <= 'd0;
			PCT_WE <= 'd0;
			PCT_write_data <= 'd0;
			
			iMode <= 'd0;
		end
		else begin
			case(top_state)
			
				IDLE: begin
					if(iBuff_on) begin
						oTop_ready <= 1'b0;
					
						top_state <= PID_CHECK;
						
						idata_is <= iBuff_data;
						type_is <= iBuff_type;
						PID_is <= iBuff_PID;
						
					end
					else top_state <= IDLE;
				end
				
				PID_CHECK: begin	// IDENTIFY THE CASE, and choose the correct 'situation' and 'next state'.
					if(initial_case) begin	// first PID to come in. -> ct, ht is initialy zero. 
						if(type_is == BR_type) begin				// init_BR
							oTop_ready <= 1'b1;
						
							top_state <= IDLE;
							situation <= init_BR;
						end
						else if(type_is == SYS_type) begin
							top_state <= SYS_VALID;					// init_SYS
							initial_case <= 1'b0;
							next_input_valid <= 1'b1;
							situation <= init_SYS;
						end
					end
					
					else begin
						if(PID_is == PID_was) begin	// orig same PID
							if(type_is == SYS_type) begin
								if(type_was == BR_type) begin		// oPSB
									top_state <= LOAD_PCT;
									situation <= oPSB;
								end
								else if(type_was == SYS_type) begin	// oPSS
									top_state <= SYS_VALID;
									next_input_valid <= 1'b1;
									situation <= oPSS;
								end
							end
							else if(type_is == BR_type) begin
							
								if(br_done_flag == 1) begin			// Branch received more than 30 times.
									oTop_ready <= 1'b1;
								
									top_state <= IDLE;
									situation <= done_BR;
								end
							
								else if(type_was == BR_type) begin
									top_state <= BR_VALID;			// oPBB
									next_input_valid <= 1'b1;
									situation <= oPBB;
								end
								else if(type_was == SYS_type) begin
									top_state <= SAVE_PCT;			// oPBS
									situation <= oPBS;
								end
							end
						end
						else begin	// new PID
							if(type_is == SYS_type) begin
								if(type_was == BR_type) begin
									top_state <= LOAD_PCT;			// nPSB
									situation <= nPSB;
								end
								else if(type_was == SYS_type) begin
									top_state <= SAVE_PCT;			// nPSS
									situation <= nPSS;
								end
							end
							else if(type_is == BR_type) begin
								if(type_was == BR_type) begin
									top_state <= LOAD_PCT;			// nPBB
									situation <= nPBB;
								end
								else if(type_was == SYS_type) begin
									top_state <= SAVE_PCT;			// nPBS
									situation <= nPBS;
								end
							end
						end
					end
				end
				
				LOAD_PCT: begin
					if(lstm_done == 1) begin	// LOAD New PCT & ct / ht, only when lstm is done. 
						if(top_delay == 0) begin
							PCT_EN <= 1'b1;
							PCT_WE <= 1'b0;
							PCT_addr <= PID_is;
							
							top_delay <= top_delay + 1;
						end
						else if(top_delay == 1) begin
							PCT_EN <= 1'b0;
							PCT_WE <= 1'b0;
							
							br_cnt <= PCT_read_data[133-:5];
							br_done_flag <= PCT_read_data[128];
							ct_load[63:0] <= PCT_read_data[127:64];
							ht_load[63:0] <= PCT_read_data[63:0];
							load_valid <= 1'b1;
						
							top_delay <= top_delay + 1;
						end
						else if(top_delay == 2) begin
							load_valid <= 1'b0;
							
							case(situation)
								oPSB: begin
									top_state <= SYS_VALID;
									next_input_valid <= 1'b1;
								end
								nPSB: begin
									top_state <= SYS_VALID;
									next_input_valid <= 1'b1;
								end
								nPSS: begin
									top_state <= SYS_VALID;
									next_input_valid <= 1'b1;
								end
								nPBB: begin
									if(br_done_flag == 1) begin
										oTop_ready <= 1'b1;
									
										top_state <= IDLE;
										situation <= done_BR;
									end
									else begin
										top_state <= CAL_CTXT;
									end
								end
								nPBS: begin
									if(br_done_flag == 1) begin
										oTop_ready <= 1'b1;
										
										top_state <= IDLE;
										situation <= done_BR;
									end
									else begin
										top_state <= CAL_CTXT;
									end
								end
								default: begin
									top_state <= top_ERR;
									situation <= sit_ERR;
								end
							endcase

							top_delay <= 'd0;
						end
					end					
				end
				
				SAVE_PCT: begin
					if(lstm_done == 1) begin
						if(top_delay == 0) begin
							PCT_EN <= 1'b1;
							PCT_WE <= 1'b1;
							PCT_addr <= PID_was;
							PCT_write_data <= {br_cnt, br_done_flag, ct[63:0], ht[63:0]};
							
							top_delay <= top_delay + 1;
						end
						else if(top_delay == 1) begin
							PCT_EN <= 1'b0;
							PCT_WE <= 1'b0;
							
							case(situation) begin
								oPBS: top_state <= CAL_CTXT;
								nPSS: top_state <= LOAD_PCT;
								nPBS: top_state <= LOAD_PCT;
								default: begin
									top_state <= top_ERR;
									situation <= sit_ERR;
								end
							end
							
							top_delay <= 'd0;
						end
					end
				end
				
				CAL_CTXT: begin
				// TO DO //
					
					
					
					
					
					
					
				end
				
				SYS_VALID: begin
					if(lstm_done) begin
						oTop_ready <= 1'b1;
						
						top_state <= IDLE;
						
						next_input_valid <= 'd0;
						lstm_Mode <= type_is;
						lstm_data <= idata_is;
						
						type_was <= type_was;
						PID_was <= PID_is;
					end
				end
				
				BR_VALID: begin
					if(lstm_done) begin
						oTop_ready <= 1'b1;
						
						top_state <= IDLE;
						
						next_input_valid <= 'd0;
						lstm_Mode <= type_is;
						lstm_data <= idata_is;
						
						type_was <= type_was;
						PID_was <= PID_is;
						
						br_cnt <= br_cnt + 1;
					end
				end
			
				top_ERR: begin
					top_state <= top_ERR;
				end
				
				default: begin
					top_state <= top_ERR;
				end
				
			endcase
		end
	end




endmodule
