// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Mon Apr 25 14:21:51 2022
// Host        : DESKTOP-7K8757E running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/wu/Desktop/gitee/jichuangsai-e203/e203/e203.srcs/sources_1/ip/mmcm/mmcm_stub.v
// Design      : mmcm
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module mmcm(clk_16, clk_60, clk_50, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_16,clk_60,clk_50,resetn,locked,clk_in1" */;
  output clk_16;
  output clk_60;
  output clk_50;
  input resetn;
  output locked;
  input clk_in1;
endmodule
