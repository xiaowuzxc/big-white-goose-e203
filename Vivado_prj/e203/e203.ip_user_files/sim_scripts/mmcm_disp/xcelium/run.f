-makelib xcelium_lib/xpm -sv \
  "I:/vivado/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "I:/vivado/Vivado/2019.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "I:/vivado/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../e203.srcs/sources_1/ip/mmcm_disp/mmcm_disp_clk_wiz.v" \
  "../../../../e203.srcs/sources_1/ip/mmcm_disp/mmcm_disp.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

