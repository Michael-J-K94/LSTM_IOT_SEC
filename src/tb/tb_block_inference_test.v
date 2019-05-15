`timescale 1ns / 1ps
// Testbench file for block
// Author : Wonjae
// To Do : 190121 Mem initializing added

module tb_block();
    parameter CLK_CYCLE = 2.5;
    parameter CLK_PERIOD = 2*CLK_CYCLE;
    
    parameter NEURON_NUM = 256;
    parameter NEURON_BIT_SIZE = 8; // 2^8 = 256
    
    reg clk;
    reg rstn;

    integer i;
    reg [256*14-1:0] weight [255:0];
    
    //***** Master Input *****
    reg start;
    reg en;
    reg request;
    reg [7:0] data_in;
    
    reg [NEURON_BIT_SIZE*2+4+4-1:0] block_info;
    //reg [2:0] data_in_keep; // in data bit num 1 to 3
    //reg [NEURON_BIT_SIZE-1:0] num_memrow_used;
    //reg [NEURON_BIT_SIZE-1:0] num_output; // number of big neurons

    reg [7:0] input_spike [0:NEURON_NUM-1];
    reg [7:0] input_spike_2 [0:NEURON_NUM-1];
    reg [7:0] input_spike_3 [0:NEURON_NUM-1];
    
    //***** Master Output *****
    wire mem_setup_done;
    wire front_done;
    wire out_spike_valid;
    wire back_done;
    wire out_spike;
    
    initial begin
        clk = 1'b1;
        rstn = 'd0;
    end
    always #CLK_CYCLE clk = ~clk;
    
    initial begin
        //------------------------------------
        //***** Initail value of signals *****
        //------------------------------------
        en = 'd0;
        start = 'd0;
        request = 'd0;
        data_in = 'd0;
        
        block_info = 'd0;
        //data_in_keep = 'd0;
        //num_memrow_used = 'd0;
        //num_output = 'd0;
        
        repeat(10)
            @(posedge clk);
        
        rstn = 1'b1;

        #(10*CLK_PERIOD + 0.01)
            
        $readmemb("input_spike_2048.txt", input_spike);
        $readmemb("input_spike_2048_2.txt", input_spike_2);
        $readmemb("input_spike_2048_3.txt", input_spike_3);
        $display("***** input spike write done *****\n\n");

        $readmemb("weight_value.txt", weight);

        for (i = 0; i < 256; i = i + 1) begin            
                force tb_block.u_block.u_sdfa_sram_256.ADDR_WRITE = i; 
                force tb_block.u_block.u_sdfa_sram_256.WE = 32'h0;
                force tb_block.u_block.u_sdfa_sram_256.DIN = weight[i];
            #(CLK_PERIOD);
        end

        release tb_block.u_block.u_sdfa_sram_256.ADDR;
        release tb_block.u_block.u_sdfa_sram_256.EN_M;
        release tb_block.u_block.u_sdfa_sram_256.WE;
        release tb_block.u_block.u_sdfa_sram_256.DIN;
        #CLK_PERIOD
        
        $display("***** Force write is done *****\n\n");
		#(10*CLK_PERIOD)
		
		
		////////////////////////////////////////////////////////////////////////////////
        // case 1 : 8bit data_in & 256 input neurons as big neuron(2048 feature)
		////////////////////////////////////////////////////////////////////////////////
		
        #(10*CLK_PERIOD + 0.01) block_info = 24'b1_0000_111_11111111_00011111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
            //data_in_keep = 3'b111;
            //num_memrow_used = 8'd255;
            //num_output = 8'd31; // == 256/8 - 1
        #(10*CLK_PERIOD) block_info = 24'b0_0000_111_11111111_00011111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
        #CLK_PERIOD request = 1'b1;
        #CLK_PERIOD request = 1'b0;
			
		wait(out_spike_valid);
		#(2*CLK_PERIOD + 0.01)
		    en = 1'b1;
            start = 1'b1;
            data_in = input_spike[0];
        for (i = 1; i < 256; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(front_done);
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;
        
        wait(back_done);
        $display("***** Case 1 done *****\n\n");
        #(10*CLK_PERIOD + 0.01) rstn = 1'b0;
        #(10*CLK_PERIOD) rstn = 1'b1;
        
		////////////////////////////////////////////////////////////////////////////////
        // case 2 : 4bit data_in & 256 input neurons as big neuron ( 1024 feature)
		////////////////////////////////////////////////////////////////////////////////
		
        #(10*CLK_PERIOD + 0.01) block_info = 24'b1_0000_111_11111111_00011111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
            //data_in_keep = 3'b011;
            //num_memrow_used = 8'd255;
            //num_output = 8'd63; // == 256/4 - 1
        #(10*CLK_PERIOD) block_info = 24'b0_0000_011_11111111_00111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
        #CLK_PERIOD request = 1'b1;
        #CLK_PERIOD request = 1'b0;
			
		wait(out_spike_valid);
		#(2*CLK_PERIOD + 0.01)				
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike[0];
        for (i = 1; i < 256; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(front_done);
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;
        
        wait(back_done);
        $display("***** Case 2 done *****\n\n");
        #(10*CLK_PERIOD + 0.01) rstn = 1'b0;
        #(10*CLK_PERIOD) rstn = 1'b1;
        
		////////////////////////////////////////////////////////////////////////////////
         // case 3 : 2bit data_in & 256 input neurons as big neuron ( 512 feature)
		////////////////////////////////////////////////////////////////////////////////
		
        #(10*CLK_PERIOD + 0.01) block_info = 24'b1_0000_001_11111111_01111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
            //data_in_keep = 3'b001;
            //num_memrow_used = 8'd255;
            //num_output = 8'd127; // == 256/2 - 1
        #(10*CLK_PERIOD) block_info = 24'b0_0000_001_11111111_01111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
        #CLK_PERIOD	request = 1'b1;
        #CLK_PERIOD request = 1'b0;
			
		wait(out_spike_valid);
		#(2*CLK_PERIOD + 0.01)
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike[0];
        for (i = 1; i < 256; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(front_done);
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;
        
        wait(back_done);
        $display("***** Case 3 done *****\n\n");
        #(10*CLK_PERIOD + 0.01) rstn = 1'b0;
        #(10*CLK_PERIOD) rstn = 1'b1;
		
		////////////////////////////////////////////////////////////////////////////////
         // case 4 : 8bit data_in & 256 input neurons as big neuron ( 2048 feature) with multiple images
		////////////////////////////////////////////////////////////////////////////////
		
        #(10*CLK_PERIOD + 0.01) block_info = 24'b1_0000_111_11111111_00011111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
            //data_in_keep = 3'b111;
            //num_memrow_used = 8'd255;
            //num_output = 8'd31; // == 256/8 - 1
        #(10*CLK_PERIOD) block_info = 24'b0_0000_111_11111111_00011111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
        #CLK_PERIOD request = 1'b1;
        #CLK_PERIOD request = 1'b0;
			
		wait(out_spike_valid);
		#(2*CLK_PERIOD + 0.01)		
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike[0];
        for (i = 1; i < 256; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(front_done); // wait until first front done. first image do not need back_done signal
        #(4*CLK_PERIOD + 0.01) request = 1'b1; // if first_done is on, request is on to do back part.
        #CLK_PERIOD request = 1'b0;
        
        wait(out_spike_valid);
        #(2*CLK_PERIOD + 0.01) // after 2 clk about out_spike_valid, insert new image input spike. 
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike_2[0];
        for (i = 1; i < 256; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike_2[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(back_done & front_done); // wait until first back done and second front done.
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;
        
        wait(out_spike_valid);
        #(2*CLK_PERIOD + 0.01)
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike_3[0];
        for (i = 1; i < 256; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike_3[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(back_done & front_done);
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;        
        
        wait(back_done);
        $display("***** Case 4 done *****\n\n");
        #(100*CLK_PERIOD)
        #(10*CLK_PERIOD + 0.01) rstn = 1'b0;
        #(10*CLK_PERIOD) rstn = 1'b1;
		
		////////////////////////////////////////////////////////////////////////////////
         // case 5 : 8bit data_in & 256 input neurons as big neuron ( 2048 feature) with multiple images
		////////////////////////////////////////////////////////////////////////////////
		
        #(10*CLK_PERIOD + 0.01) block_info = 24'b1_0000_011_11000011_00111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
            //data_in_keep = 3'b111;
            //num_memrow_used = 8'd255;
            //num_output = 8'd31; // == 256/8 - 1
        #(10*CLK_PERIOD) block_info = 24'b0_0000_011_11000011_00111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
        #CLK_PERIOD request = 1'b1;
        #CLK_PERIOD request = 1'b0;
			
		wait(out_spike_valid);
		#(2*CLK_PERIOD + 0.01)		
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike[0];
        for (i = 1; i < 196; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(front_done); // wait until first front done. first image do not need back_done signal
        #(4*CLK_PERIOD + 0.01) request = 1'b1; // if first_done is on, request is on to do back part.
        #CLK_PERIOD request = 1'b0;
        
        wait(out_spike_valid);
        #(2*CLK_PERIOD + 0.01) // after 2 clk about out_spike_valid, insert new image input spike. 
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike_2[0];
        for (i = 1; i < 196; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike_2[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(back_done & front_done); // wait until first back done and second front done.
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;
        
        wait(out_spike_valid);
        #(2*CLK_PERIOD + 0.01)
            en = 1'b1;
            start = 1'b1;
            data_in = input_spike_3[0];
        for (i = 1; i < 196; i = i + 1) begin
            #CLK_PERIOD data_in = input_spike_3[i];
            if (i == 1) start = 1'b0;
        end
        #CLK_PERIOD en = 1'b0;
        
        wait(back_done & front_done);
        #(4*CLK_PERIOD + 0.01) request = 1'b1;
        #CLK_PERIOD request = 1'b0;        
        
        wait(back_done);
        $display("***** Case 4 done *****\n\n");
        #(100*CLK_PERIOD)
        #(10*CLK_PERIOD + 0.01) rstn = 1'b0;
        #(10*CLK_PERIOD) rstn = 1'b1;


//************************** YOU CAN MAKE CASE WITH THIS CODE **************************// 
//        // case X : X bit data_in & XXX input neurons as big neuron ( XXX feature)
//        wait(mem_setup_done);
//        #(10*CLK_PERIOD + 0.01)
//            block_info = 23'b1_000_011_11111111_00111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
//            //data_in_keep = 3'b011;
//            //num_memrow_used = 8'd255;
//            //num_output = 8'd63; // == 256/4 - 1
//        #(10*CLK_PERIOD) block_info = 23'b0_000_011_11111111_00111111; // (info_enable)_(blk_num)_(data_in_keep)_(num_memrow_used)_(num_output)
//        #CLK_PERIOD request = 1'b1;
//        #CLK_PERIOD request = 1'b0;
			
//		  wait(out_spike_valid);
//		  #(2*CLK_PERIOD + 0.01)
//            en = 1'b1;
//            start = 1'b1;
//            data_in = input_spike[0];
//        for (i = 1; i < num_memrow_used+1; i = i + 1) begin
//            #CLK_PERIOD data_in = input_spike[i];
//            if (i == 1) start = 1'b0;
//        end
//        #CLK_PERIOD en = 1'b0;
//
//        wait(front_done);
//        #(4*CLK_PERIOD + 0.01) request = 1'b1;
//        #CLK_PERIOD request = 1'b0;
        
//        wait(out_spike_done);
//        $display("***** Case X done *****\n\n");
//        #(10*CLK_PERIOD + 0.01) rstn = 1'b0;
//        #(10*CLK_PERIOD) rstn = 1'b1;
        $finish;
    end
    
    //---------------------------
    //***** Module Instance *****
    //---------------------------
    
    sdfa_block u_block(
    .CLK(clk),
    .RESET_N(rstn),
    // FROM MASTER
    .START(start),
    .EN(en),
    .REQUEST(request),
    .DATA_IN(data_in),
    .BLOCK_INFO(block_info),
    // OUTPUT
    // .MEM_SETUP_DONE(mem_setup_done),
    .FRONT_DONE(front_done),
    .OUT_SPIKE_VALID(out_spike_valid),
    .BACK_DONE(back_done),
    .OUT_SPIKE(out_spike)
    );

endmodule