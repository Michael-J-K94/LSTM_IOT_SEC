// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Sat May  4 22:16:17 2019
// Host        : ECE-B03 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/ECE/project_1/project_1.srcs/sources_1/ip/BRAM_16x512_1/BRAM_16x512_stub.v
// Design      : BRAM_16x512
// Purpose     : Stub declaration of top-level module interface
// Device      : xa7a12tcpg238-2I
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module BRAM_16x512(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[8:0],dina[15:0],douta[15:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [8:0]addra;
  input [15:0]dina;
  output [15:0]douta;
endmodule
