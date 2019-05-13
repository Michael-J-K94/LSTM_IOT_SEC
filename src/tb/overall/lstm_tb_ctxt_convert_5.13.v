`timescale 1ns/100ps

`define INTERVAL 1
`define PERIOD 10
`define DELAY 100

`define DATA_SIZE 10
`define X_SIZE 8
`define H_SIZE 8
`define W_SIZE 512
`define B_SIZE 32
`define CONTEXT_SIZE 16

`define BR_W_SIZE 32768
`define BR_B_SIZE 256
`define BR_CONTEXT_SIZE 128
`define CONVERT_W_SIZE 1024
`define CONVERT_B_SIZE 128


/*
iInit_type
0 = syscall_w
1 = syscall_b
2 = syscall_context

7 = idle
*/

module lstm_tb_ctxt_convert();

	reg iInit_valid;
	reg iNext_valid;

	wire lstm_done;
	wire [`H_SIZE*8 - 1:0] result;
	
	reg [7:0] iInit_data;

	reg read_input, read_output, read_sys_b, read_sys_w;
	reg read_br_b, read_br_w;
	reg read_convert_w, read_convert_b;
	
    wire [7:0] sys_b_data, sys_input_data, sys_w_data, sys_output_data;
	wire [7:0] br_b_data, br_w_data, br_input_data, br_output_data;
	wire [7:0] convert_b_data, convert_w_data;
	
    wire ready_sys_mem_weight, ready_sys_mem_bias;
	wire ready_br_mem_weight, ready_br_mem_bias;
	wire ready_convert_mem_weight, ready_convert_mem_bias;
	
	reg [15:0] sys_input_mem_address, sys_output_mem_address;
	reg [15:0] br_input_mem_address, br_output_mem_address;

	reg clk;
	reg reset_n;
	
	reg set_param;

	reg [`X_SIZE*8 - 1:0] input_buffer;
	reg [`X_SIZE*8 - 1:0] input_array [`DATA_SIZE - 1 : 0];
	reg [`H_SIZE*8 - 1:0] output_array [`DATA_SIZE - 1 : 0];
	
	reg [64*8 - 1:0] br_input_buffer;
	reg [64*8 - 1:0] br_input_array [3 - 1 : 0];
	reg [64*8 - 1:0] br_output_array [3 - 1 : 0];	
	
	reg [2:0] iInit_type;

	reg [31:0] sys_input_counter, sys_output_counter;
	reg [31:0] br_input_counter, br_output_counter;


	wire [511:0] br_ht;
	wire [63:0] sys_ht;
	reg data_type;
	reg [511:0] lstm_data;

    localparam
        syscall_w = 3'd0,
        syscall_b = 3'd1,
        idle = 3'd7,
		branch_w = 3'd2,
		branch_b = 3'd3,
		convert_w = 3'd4,
		convert_b = 3'd5;
	
    LSTM UUT(
		.clk(clk),
		.resetn(reset_n),
		
		.iInit_valid(iInit_valid),
		.iInit_data(iInit_data),
		.iInit_type(iInit_type),
		
		.iNext_valid(iNext_valid),	// top valid & ready. 
		.iType(data_type),		//
		.iData(lstm_data),
		
		.oLstm_done(lstm_done),	// lstm done & ready to do next task. 
		
		// [511:0].oBr_Ct(),	// Wire actually
		.oBr_Ht(br_ht),
		// [63:0].oSys_Ct(),
		.oSys_Ht(sys_ht)
	);
	
	
    /*initialization*/
    initial begin
        clk = 0;
        reset_n = 1;
    
        iNext_valid = 0;
        iInit_valid = 0;
        iInit_type = idle;
    
        read_sys_b = 0;
        // read_sys_context = 0;
        read_sys_w = 0;
 
        read_br_b = 0;
        // read_br_context = 0;
        read_br_w = 0;
		
        read_convert_b = 0;
        read_convert_w = 0;
 
        set_param = 0;
        sys_input_counter = 0;
        sys_output_counter = 0;
		br_input_counter = 0;
		br_output_counter = 0;
        
        sys_input_mem_address = 0;
        sys_output_mem_address = 0;
		br_input_mem_address = 0;
		br_output_mem_address = 0;
		
		data_type = 'd0;
		lstm_data = 'd0;
    end
    
    integer k;
    /* main */
    initial begin
        #`PERIOD;
        wait(read_input|read_output == 0) // prepare input & sys_output_dataset
    
        #`PERIOD reset_n = 0;
        #`PERIOD reset_n = 1;
        #`DELAY 
		
		//******* sys weight ******//
        iInit_valid = 1;
        /* weight_param_transfer */
        iInit_type = syscall_w;
        read_sys_w = 1;
        for(k = 0 ;k < `W_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_sys_w = 0;
        iInit_valid = 0;
        #`DELAY
    
		//******* sys bias ******//
        iInit_valid = 1;
        /* bias_param_transfer */
        iInit_type = syscall_b;
        read_sys_b = 1;
        for(k = 0 ;k < `B_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_sys_b = 0;
        iInit_valid = 0;
        #`DELAY
    
		// ******* sys ctxt ******//
        // iInit_valid = 1;
        // /* context_param_transfer */
        // iInit_type = syscall_context;
        // read_sys_context = 1;
        // for(k = 0 ;k < `CONTEXT_SIZE; k = k+1) begin
               // #`PERIOD;
        // end
        // read_sys_context = 0;
        // iInit_valid = 0;
        // #`DELAY
 
		//******* br weight ******//
        iInit_valid = 1;
        /* context_param_transfer */
        iInit_type = branch_w;
        read_br_w = 1;
        for(k = 0 ;k < `BR_W_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_br_w = 0;
        iInit_valid = 0;
        #`DELAY

		//******* br bias ******//
        iInit_valid = 1;
        /* context_param_transfer */
        iInit_type = branch_b;
        read_br_b = 1;
        for(k = 0 ;k < `BR_B_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_br_b = 0;
        iInit_valid = 0;
        #`DELAY
		
		// ******* br ctxt ******//
        // iInit_valid = 1;
        // /* context_param_transfer */
        // iInit_type = branch_context;
        // read_br_context = 1;
        // for(k = 0 ;k < `BR_CONTEXT_SIZE; k = k+1) begin
               // #`PERIOD;
        // end
        // read_br_context = 0;
        // iInit_valid = 0;
        // #`DELAY

		//******* converter weight ******//
        iInit_valid = 1;
        /* context_param_transfer */
        iInit_type = convert_w;
        read_convert_w = 1;
        for(k = 0 ;k < `CONVERT_W_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_convert_w = 0;
        iInit_valid = 0;
        #`DELAY
		
		//******* converter bias ******//
        iInit_valid = 1;
        /* context_param_transfer */
        iInit_type = convert_b;
        read_convert_b = 1;
        for(k = 0 ;k < `CONVERT_B_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_convert_b = 0;
        iInit_valid = 0;
        #`DELAY		


 
        set_param = 1;
    end
    integer i[3:0];
    /* setting input data_array */
    initial begin
        read_input = 1;
        for(i[0] = 0; i[0] < `DATA_SIZE; i[0] = i[0]+1) begin
            for(i[1] = 0; i[1] < `X_SIZE; i[1] = i[1]+1) begin
                #`INTERVAL;
                input_array[i[0]] = input_array[i[0]] << 8;
                input_array[i[0]][7:0] = sys_input_data;               
                sys_input_mem_address = sys_input_mem_address + 1;			
            end
        end
		
        for(i[0] = 0; i[0] < 3; i[0] = i[0]+1) begin
            for(i[1] = 0; i[1] < 64; i[1] = i[1]+1) begin
                #`INTERVAL;
                br_input_array[i[0]] = br_input_array[i[0]] << 8;
                br_input_array[i[0]][7:0] = br_input_data;               
                br_input_mem_address = br_input_mem_address + 1;			
            end
        end		
		
        read_input = 0;
    end
	
	
    /* setting output data_array */
    initial begin
        read_output = 1;
        for(i[2] = 0; i[2] < `DATA_SIZE; i[2] = i[2]+1) begin
            for(i[3] = 0; i[3] < `H_SIZE; i[3] = i[3]+1) begin
                #`INTERVAL;
                output_array[i[2]] = output_array[i[2]] << 8;
                output_array[i[2]][7:0] = sys_output_data;          
                sys_output_mem_address = sys_output_mem_address + 1;
            end
        end
		
        for(i[2] = 0; i[2] < 3; i[2] = i[2]+1) begin
            for(i[3] = 0; i[3] < 64; i[3] = i[3]+1) begin
                #`INTERVAL;
                br_output_array[i[2]] = br_output_array[i[2]] << 8;
                br_output_array[i[2]][7:0] = br_output_data;          
                br_output_mem_address = br_output_mem_address + 1;
            end
        end		
        read_output = 0;
    end
    
    // clk generation
    always #(`PERIOD/2) clk = ~clk;
    
    // iInit_dataeter_transfer
    always @(negedge clk) begin
        if(ready_sys_mem_weight| ready_sys_mem_bias|
		ready_br_mem_weight| ready_br_mem_bias| ready_convert_mem_weight| ready_convert_mem_bias) begin
            case(iInit_type)
                syscall_w : iInit_data <= sys_w_data;
                syscall_b : iInit_data <= sys_b_data;
                // syscall_context : iInit_data <= sys_context_data;
				
				branch_w : iInit_data <= br_w_data;
				branch_b : iInit_data <= br_b_data;
				// branch_context : iInit_data <= br_context_data;
				
				convert_w : iInit_data <= convert_w_data;
				convert_b : iInit_data <= convert_b_data;
                default : iInit_data <= 0;
            endcase
        end
    end
    
	integer q;
	
    // sys_input_data_transfer
    always begin
		#5
        wait(set_param == 1);
        wait(lstm_done == 1);
        #`PERIOD
		#0.01

        if(sys_input_counter < `DATA_SIZE) begin
			// if(sys_input_counter == 0) begin
				// force lstm_tb_ctxt_convert.UUT.Sys_Ht = 16'h1234;
				// release lstm_tb_ctxt_convert.UUT.Sys_Ht;
			// end

            input_buffer = input_array[sys_input_counter];
			lstm_data = {448'd0,input_buffer};
            sys_input_counter = sys_input_counter + 1;
			data_type = 1'b1;
            iNext_valid = 1;
            #`PERIOD;
			#0.01
            iNext_valid = 0;
        end
		else if(br_input_counter < (3)) begin
			if(br_input_counter == 0) begin
				force lstm_tb_ctxt_convert.UUT.Br_Ht = 512'h8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080;
				force lstm_tb_ctxt_convert.UUT.Br_Ct = 512'h8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080_8080;				
				release lstm_tb_ctxt_convert.UUT.Br_Ht;
				release lstm_tb_ctxt_convert.UUT.Br_Ct;
			end

			
			
		
            br_input_buffer = br_input_array[br_input_counter];
			lstm_data = br_input_buffer;
            br_input_counter = br_input_counter + 1;
			data_type = 1'b0;
            iNext_valid = 1;
            #`PERIOD;
			#0.01
            iNext_valid = 0;	
		end
    end
    
    // sys_output_data_check
    always begin
        wait(iNext_valid);
        #`PERIOD;
		#`PERIOD;
        wait(lstm_done);      
        if(sys_output_counter < `DATA_SIZE) begin
            if(output_array[sys_output_counter] == sys_ht) begin
                $display("test %d is passed\n", sys_output_counter);
            end
            else begin
                $display("test %d is failed", sys_output_counter);
                $display("result is 0x%h", sys_ht);
                $display("answer is 0x%h\n", output_array[sys_output_counter]);
            end
            sys_output_counter = sys_output_counter + 1;
            if(sys_output_counter == `DATA_SIZE) begin
                //$finish;
            end           
        end
		else if(br_output_counter < (3)) begin
            if(br_output_array[br_output_counter] == br_ht) begin
                $display("test %d is passed\n", br_output_counter);
            end
            else begin
                $display("test %d is failed", br_output_counter);
                $display("result is 0x%h", br_ht);
                $display("answer is 0x%h\n", br_output_array[br_output_counter]);
            end
            br_output_counter = br_output_counter + 1;
            if(br_output_counter == 3) begin
                $finish;
            end  		
		end
    end   
	
	//**** SYSTEM ****//
    weight_memory w_mem(
                .readM(clk & read_sys_w),
                .ready(ready_sys_mem_weight),
                .data(sys_w_data)        
            ); 
    bias_memory b_mem(
                .readM(clk & read_sys_b),
                .ready(ready_sys_mem_bias),
                .data(sys_b_data)
            );
    // context_memory c_mem(
                // .readM(clk & read_sys_context),
                // .ready(ready_sys_mem_context),
                // .data(sys_context_data)
            // );
			
	//**** BRANCH ****//			
    br_weight_memory br_w_mem(
                .readM(clk & read_br_w),
                .ready(ready_br_mem_weight),
                .data(br_w_data)        
            ); 			
    br_bias_memory br_b_mem(
                .readM(clk & read_br_b),
                .ready(ready_br_mem_bias),
                .data(br_b_data)
            );
    // br_context_memory br_c_mem(
                // .readM(clk & read_br_context),
                // .ready(ready_br_mem_context),
                // .data(br_context_data)
            // );			
			
			
	//**** CONTEXT CONVERT ****//			
    br_weight_memory convert_w_mem(
                .readM(clk & read_convert_w),
                .ready(ready_convert_mem_weight),
                .data(convert_w_data)        
            ); 			
    br_bias_memory convert_b_mem(
                .readM(clk & read_convert_b),
                .ready(ready_convert_mem_bias),
                .data(convert_b_data)
            );			
			
			
			
	//**** sys in/out ****//		
    input_data_memory i_mem(
                .address(sys_input_mem_address),
                .data(sys_input_data)
            );
    output_memory o_mem(
                .address(sys_output_mem_address),
                .data(sys_output_data)
            );

	//**** branch in/out ****//
    br_input_data_memory br_i_mem(
                .address(br_input_mem_address),
                .data(br_input_data)
            );

    br_output_memory br_o_mem(
                .address(br_output_mem_address),
                .data(br_output_data)
            );
endmodule