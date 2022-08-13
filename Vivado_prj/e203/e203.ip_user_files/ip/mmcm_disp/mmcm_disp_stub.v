// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Apr 16 15:20:29 2022
// Host        : DESKTOP-7K8757E running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top mmcm_disp -prefix
//               mmcm_disp_ mmcm_disp_stub.v
// Design      : mmcm_disp
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module mmcm_disp(clk_200, clk_25, clk_125, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_200,clk_25,clk_125,resetn,locked,clk_in1" */;
  output clk_200;
  output clk_25;
  output clk_125;
  input resetn;
  output locked;
  input clk_in1;
endmodule
