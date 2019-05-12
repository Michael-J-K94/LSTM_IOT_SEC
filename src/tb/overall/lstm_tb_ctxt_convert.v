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
	
    wire [7:0] sys_b_data, input_data, sys_w_data, output_data;
	wire [7:0] br_b_data, br_w_data;
	wire [7:0] convert_b_data, convert_w_data;
	
    wire ready_sys_mem_weight, ready_sys_mem_bias;
	wire ready_br_mem_weight, ready_br_mem_bias;
	wire ready_convert_mem_weight, ready_convert_mem_bias;
	
	reg [15:0] input_mem_address, output_mem_address;

	reg clk;
	reg reset_n;
	
	reg set_param;

	reg [`X_SIZE*8 - 1:0] input_buffer;
	reg [`X_SIZE*8 - 1:0] input_array [`DATA_SIZE - 1 : 0];
	reg [`H_SIZE*8 - 1:0] output_array [`DATA_SIZE - 1 : 0];
	reg [2:0] iInit_type;

	reg [31:0] input_counter, output_counter;

    localparam // iInit_dataeter_type
        syscall_w = 3'd0,
        syscall_b = 3'd1,
        // syscall_context = 3'd2,
        idle = 3'd7,

		branch_w = 3'd2,
		branch_b = 3'd3,
		// branch_context = 3'd5, 

		convert_w = 3'd4,
		convert_b = 3'd5;
	
    LSTM UUT(
		.clk(clk),
		.resetn(reset_n),
		
		.iInit_valid(iInit_valid),
		.iInit_data(iInit_data),
		.iInit_type(iInit_type),
		
		.iNext_valid(iNext_valid),	// top valid & ready. 
		.iType(1'b1),		//
		.iData({448'd0,input_buffer}),
		
		.oLstm_done(lstm_done),	// lstm done & ready to do next task. 
		// [511:0].oBr_Ct(),	// Wire actually
		// [511:0].oBr_Ht(),
		// [63:0].oSys_Ct(),
		.oSys_Ht(result)
	);
	
	/*
    top_lstm UUT(
            .iInit_valid(iInit_valid), // initialization_signal
            .iNext_valid(iNext_valid), // input_data(X_t) is ready
            .lstm_done(lstm_done), // output_data(H_t) is ready
            .iInit_type(iInit_type), // parameter_type (weight, bias, init_context)
    
            .clk(clk),
            .rstn(reset_n),
            .syscall_X_data(input_buffer), // input_data(X_t)
            .iInit_data(iInit_data), // parameters(8bit)
            // 
            .syscall_H_out(result) // output_data(H_t)
            );
    */
	
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
        input_counter = 0;
        output_counter = 0;
        
        input_mem_address = 0;
        output_mem_address = 0;
    end
    
    integer k;
    /* main */
    initial begin
        #`PERIOD;
        wait(read_input|read_output == 0) // prepare input & output_dataset
    
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
                input_array[i[0]][7:0] = input_data;               
                input_mem_address = input_mem_address + 1;			
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
                output_array[i[2]][7:0] = output_data;          
                output_mem_address = output_mem_address + 1;
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
    
    // input_data_transfer
    always begin
		#5
        wait(set_param == 1);
        wait(lstm_done == 1);
        #`PERIOD
		#0.01

        if(input_counter < `DATA_SIZE) begin
            input_buffer = input_array[input_counter];
            input_counter = input_counter + 1;
            iNext_valid = 1;
            #`PERIOD;
			#0.01
            iNext_valid = 0;
        end
    end
    
    // output_data_check
    always begin
        wait(iNext_valid);
        #`PERIOD;
		#`PERIOD;
        wait(lstm_done);      
        if(output_counter < `DATA_SIZE) begin
            if(output_array[output_counter] == result) begin
                $display("test %d is passed\n", output_counter);
            end
            else begin
                $display("test %d is failed", output_counter);
                $display("result is 0x%h", result);
                $display("answer is 0x%h\n", output_array[output_counter]);
            end
            output_counter = output_counter + 1;
            if(output_counter == `DATA_SIZE) begin
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
			
			
			
			
    input_data_memory i_mem(
                .address(input_mem_address),
                .data(input_data)
            );
    output_memory o_mem(
                .address(output_mem_address),
                .data(output_data)
            );

endmodule