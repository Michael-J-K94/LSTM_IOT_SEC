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
	input [255:0] iBuff_data,
	input iBuff_type,
	input [PID_bit-1:0] iBuff_PID,
	
	output


);

	localparam oPiSwB = 4'd1, oPiSwS = 4'd2, oPiBwB = 4'd3, oPiBwS = 4'd4, nPiSwB = 4'd5, nPiSwS = 4'd6, nPiBwB = 4'd7, nPiBwS = 4'd8, IDLE = 4'd0, ERR = 4'hf; // orig/new PID , input Sys/Branch , was Sys/Branch
	localparam PID_CHECK = 3'd1, LOAD_CTXT = 3'd2, SAVE_CTXT = 3'd3, CALC_CTXT = 3'd4. LSTM_RUN = 3'd5;
	localparam Sys_type = 1'd1, Br_type = 1'd0;



	reg [2:0] top_state;
	reg [3:0] situation;
	
	reg lstm_type;
	reg [PID_bit-1:0] curr_PID;
	reg [4:0] branch_cnt;
	reg [1:0] top_delay;
	
	
	
	reg ctxt_load_done;
	
	
	bram_134x1024 u_bram_134x1024(
	  .addra(PID[i]),
	  .clka(clk),
	  .dina(bram_wdata[i]),
	 .douta(bram_rdata[i]),
	 .ena(bram_en[i]),
	 .wea(bram_we[i])
	);	
	
	

	bram_512x128 u_bram_512x128(
	  .addra(bram_addr[i]),
	  .clka(clk),
	  .dina(bram_wdata[i]),
	 .douta(bram_rdata[i]),
	 .ena(bram_en[i]),
	 .wea(bram_we[i])
	);
	
	
	


/////////////
// TOP FSM //
/////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			top_state <= IDLE;
			
			lstm_type <= IDLE;  
			curr_PID <= 'd0;
			branch_cnt <= 'd0;
			
			top_delay <= 'd0;
		end
		else begin
			
			case(top_state)
			
				IDLE: begin
					if(buff_on) begin
						top_state <= PID_CHECK;
					end
					else begin
						top_state <= IDLE;
					end
					
					lstm_type <= lstm_type;
					curr_PID <= curr_PID;
					branch_cnt <= branch_cnt;
				end
				
				PID_CHECK: begin
					if(top_state == PID_CHECK) begin
						if(situation == IDLE) begin	// IDLE CASE
							situation <= oPiSwS		// is not oPiSwS, but same situation. Nothing done, straight to LSTM_RUN.
						end
						else begin					// NORMAL CASE
							if(curr_PID == iBuff_PID) begin
								if(iBuff_type == Sys_type) begin
									if(lstm_type == Sys_type) begin
										situation <= oPiSwS;
									end
									else begin
										situation <= oPiSwB;
									end
								end
								else begin
									if(lstm_type == Sys_type) begin
										situation <= oPiBwS;
									end
									else begin
										situation <= oPiBwB;
									end
								end
							end
							else begin
								if(iBuff_type == Sys_type) begin
									if(lstm_type == Sys_type) begin
										situation <= nPiSwS;
									end
									else begin
										situation <= nPiSwB;
									end
								end
								else begin
									if(lstm_type == Sys_type) begin
										situation <= nPiBwS;
									end
									else if(lstm_type == Br_type) begin
										situation <= nPiBwB;
									end
									else begin	// IDLE CASE. ????????????????????????????????? OK to do this??
										situation <= IDLE;
									end
								end
							end		
						end
					end				
				
					if(top_delay) begin	// 1 cycle delay to evaluate the 'situation'
						case(situation)
							oPiSwB:	top_state <= LOAD_CTXT; 							// -> LSTM_RUN
							oPiSwS: top_state <= LSTM_RUN;								// 
							oPiBwB: top_state <= LSTM_RUN, branch_cnt <= branch_cnt+1;	// 
							oPiBwS: top_state <= SAVE_CTXT;								// -> CALC_CTXT, branch_cnt++, LSTM_RUN
							
							nPiSwB: top_state <= LOAD_CTXT;								// -> LSTM_RUN 
							nPiSwS: top_state <= SAVE_CTXT;								// -> LOAD_CTXT, LSTM_RUN
							nPiBwB: top_state <= LOAD_CTXT;								// -> CALC_CTXT, branch_cnt++, LSTM_RUN
							nPiBwS: top_state <= SAVE_CTXT;								// -> LOAD_CTXT, CALC_CTXT, branch_cnt++, LSTM_RUN
							
							default: top_state <= ERR;
						endcase
						
						lstm_type <= iBuff_type;
						curr_PID <= curr_PID;
						branch_cnt <= branch_cnt;
						top_delay <= 'd0;						
					end
					else begin
						top_state <= top_state;
						lstm_type = lstm_type;
						curr_PID <= curr_PID;
						branch_cnt <= branch_cnt;
						
						top_delay <= top_delay + 1;
					end
				end 
			
				LOAD_CTXT: begin
					if(top_delay) begin	// 1 cycle delay for loading the new SYS CTXT
						case(situation) begin
							oPiSwB: top_state <= LSTM_RUN;	// instead of saving SYS CTXT in reg and recovering, decided to load it again. // Less Area, 1cycle less Performance
							
							nPiSwB: top_state <= LSTM_RUN;
							nPiSwS: top_state <= LSTM_RUN;
							nPiBwB: top_state <= CALC_CTXT;
							nPiBwS: top_state <= CALC_CTXT;
							
							default: top_state <= ERR;
						endcase
						top_delay <= 'd0;
					end
					else begin
						top_state <= top_state;
						top_delay <= top_delay + 1;
					end
					
					lstm_type <= lstm_type;
					curr_PID <= curr_PID;
					branch_cnt <= branch_cnt;
				end
				
				SAVE_CTXT: begin
					case(situation) begin
						oPiBwS: top_state <= CALC_CTXT;
						
						nPiSwS: top_state <= LOAD_CTXT;
						nPiBwS: top_state <= LOAD_CTXT;
						
						default: top_state <= ERR;
					endcase
					
					lstm_type <= lstm_type;
					curr_PID <= curr_PID;
					branch_cnt <= branch_cnt;					
					top_delay <= top_delay;
				end
			
				CALC_CTXT: begin
					if() begin
					
					end
					else begin
					
					end
				end
			
				
				ERR: begin
					top_state <= ERR;
				end
			
				default: begin
				
				end
			
			endcase
		
		end
	end
	




if(top_delay == 0) begin
		PCT_EN <= 1'b1;
		PCT_WE <= 1'b1;
		PCT_addr <= PID_was;
		PCT_write_data <= {br_cnt, br_done_flag, ct, ht};
		
		top_delay <= top_delay + 1;
	end
	else if(top_delay == 1) begin
		PCT_EN <= 1'b1;
		PCT_WE <= 1'b0;
		PCT_addr <= PID_is;
		
		top_delay <= top_delay + 1;
	end
	else if(top_delay == 2) begin
		PCT_EN <= 1'b0;
		PCT_WE <= 1'b0;
		
		br_cnt <= PCT_read_data[133-:5];
		br_done_flag <= PCT_read_data[128];
		ct_sys_is <= PCT_read_data[127:64];
		ht_sys_is <= PCT_read_data[63:0];

		top_delay <= top_delay + 1;
	end
	else if(top_delay == 3) begin
		if(br_done_flag == 1) begin
			top_state <= IDLE;
		end
		else begin
			if(type_is == SYS_type) begin
				if(type_was == 
			end
			else if(type_is == BR_type) begin
			
			end
		end
	end












endmodule
