-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Sat Apr 16 15:20:29 2022
-- Host        : DESKTOP-7K8757E running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top mmcm_disp -prefix
--               mmcm_disp_ mmcm_disp_stub.vhdl
-- Design      : mmcm_disp
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg676-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mmcm_disp is
  Port ( 
    clk_200 : out STD_LOGIC;
    clk_25 : out STD_LOGIC;
    clk_125 : out STD_LOGIC;
    resetn : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end mmcm_disp;

architecture stub of mmcm_disp is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_200,clk_25,clk_125,resetn,locked,clk_in1";
begin
end;
