`timescale 1ns/100ps

`define INTERVAL 1
`define PERIOD 10
`define DELAY 100

`define DATA_SIZE 3
`define X_SIZE 64
`define H_SIZE 64
`define W_SIZE 32768
`define B_SIZE 256
`define CONTEXT_SIZE 128

/*
iInit_type
0 = syscall_w
1 = syscall_b
2 = syscall_context

7 = idle
*/

module lstm_tb_br();

	reg iInit_valid;
	reg iNext_valid;

	wire oLstm_done;
	wire [`H_SIZE*8 - 1:0] result;
	
	reg [7:0] iInit_data;

	reg read_input, read_output, read_b, read_w, read_context;
    wire [7:0] b_data, context_data, input_data, w_data, output_data;
    wire ready_mem_weight, ready_mem_context, ready_mem_bias;
	reg [15:0] input_mem_address, output_mem_address;

	reg clk;
	reg [31:0] clk_cnt;
	reg reset_n;
	
	reg set_param;

	reg [`X_SIZE*8 - 1:0] iData;
	reg [`X_SIZE*8 - 1:0] input_array [`DATA_SIZE - 1 : 0];
	reg [`H_SIZE*8 - 1:0] output_array [`DATA_SIZE - 1 : 0];
	reg [2:0] iInit_type;

	reg [31:0] input_counter, output_counter;

    localparam // iInit_dataeter_type
        syscall_w = 3'd0,
        syscall_b = 3'd1,
        syscall_context = 3'd2,
        idle = 3'd7,
		
		branch_w = 3'd3,
		branch_b = 3'd4,
		branch_context = 3'd5; 
	
	
    LSTM UUT(
		.clk(clk),
		.resetn(reset_n),
		
		.iInit_valid(iInit_valid),
		.iInit_data(iInit_data),
		.iInit_type(iInit_type),
		
		.iLoad_valid(1'b0),	// load ct/ht valid
		.iBr_Ct_load('d100),
		.iBr_Ht_load('d100),

		.iNext_valid(iNext_valid),	// top valid & ready. 
		.iType(1'b0),		//
		.iData(iData),
		
		.oLstm_done(oLstm_done),	// lstm done & ready to do next task. 
		// [511:0].oBr_Ct(),	// Wire actually
		.oBr_Ht(result)
		// [63:0].oSys_Ct(),
		//.oSys_Ht(result)
	);
	
	/*
    top_lstm UUT(
            .iInit_valid(iInit_valid), // initialization_signal
            .iNext_valid(iNext_valid), // input_data(X_t) is ready
            .oLstm_done(oLstm_done), // output_data(H_t) is ready
            .iInit_type(iInit_type), // parameter_type (weight, bias, init_context)
    
            .clk(clk),
            .rstn(reset_n),
            .syscall_X_data(iData), // input_data(X_t)
            .iInit_data(iInit_data), // parameters(8bit)
            // 
            .syscall_H_out(result) // output_data(H_t)
            );
    */
	
    /*initialization*/
    initial begin
        clk = 0;
		clk_cnt = 0;
        reset_n = 1;
    
        iNext_valid = 0;
        iInit_valid = 0;
        iInit_type = idle;
    
        read_b = 0;
        read_context = 0;
        read_w = 0;
    
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
        iInit_valid = 1;
        /* weight_param_transfer */
        iInit_type = branch_w;
        read_w = 1;
        for(k = 0 ;k < `W_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_w = 0;
        iInit_valid = 0;
        #`DELAY
    
        iInit_valid = 1;
        /* bias_param_transfer */
        iInit_type = branch_b;
        read_b = 1;
        for(k = 0 ;k < `B_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_b = 0;
        iInit_valid = 0;
        #`DELAY
    
        iInit_valid = 1;
        /* context_param_transfer */
        iInit_type = branch_context;
        read_context = 1;
        for(k = 0 ;k < `CONTEXT_SIZE; k = k+1) begin
               #`PERIOD;
        end
        read_context = 0;
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
    always #(`PERIOD/2) begin
		clk = ~clk;
		if(clk==1) begin
			clk_cnt = clk_cnt + 1;
		end
	end
    
    // iInit_dataeter_transfer
    always @(negedge clk) begin
        if(ready_mem_weight| ready_mem_context| ready_mem_bias) begin
            case(iInit_type)
                branch_w : iInit_data <= w_data;
                branch_b : iInit_data <= b_data;
                branch_context : iInit_data <= context_data;
                default : iInit_data <= 0;
            endcase
        end
    end
    
    // input_data_transfer
    always begin
        wait(set_param == 1);
        wait(oLstm_done == 1);
        #`PERIOD

        if(input_counter < `DATA_SIZE) begin
            iData = input_array[input_counter];
            input_counter = input_counter + 1;
            iNext_valid = 1;
            #`PERIOD;
            iNext_valid = 0;
        end
    end
    
    // output_data_check
    always begin
        wait(iNext_valid);
        #`PERIOD;
        wait(oLstm_done);      
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
    br_weight_memory w_mem(
                .readM(clk & read_w),
                .ready(ready_mem_weight),
                .data(w_data)        
            ); 
    br_bias_memory b_mem(
                .readM(clk & read_b),
                .ready(ready_mem_bias),
                .data(b_data)
            );
    br_context_memory c_mem(
                .readM(clk & read_context),
                .ready(ready_mem_context),
                .data(context_data)
            );
    br_input_data_memory i_mem(
                .address(input_mem_address),
                .data(input_data)
            );
    br_output_memory o_mem(
                .address(output_mem_address),
                .data(output_data)
            );

endmodule