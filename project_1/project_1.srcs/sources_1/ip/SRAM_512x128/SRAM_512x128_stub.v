// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Wed May 15 02:07:20 2019
// Host        : DESKTOP-6F07SNM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/User/Desktop/LSTM_IOT_SEC/project_1/project_1.srcs/sources_1/ip/SRAM_512x128/SRAM_512x128_stub.v
// Design      : SRAM_512x128
// Purpose     : Stub declaration of top-level module interface
// Device      : xa7a12tcpg238-2I
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module SRAM_512x128(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[6:0],dina[511:0],douta[511:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [6:0]addra;
  input [511:0]dina;
  output [511:0]douta;
endmodule