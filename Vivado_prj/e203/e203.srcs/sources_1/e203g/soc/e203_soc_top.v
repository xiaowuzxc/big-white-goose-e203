 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
`include "e203_defines.v"
                                                              
module e203_soc_top(
  //对外接口
	//usb
	output wire        usb_dp_pull,  // connect to USB D+ by an 1.5k resistor
	inout              usb_dp,       // connect to USB D+
	inout              usb_dn,       // connect to USB D-
	//ADDAC
	input              cmp,       // 比较器输出
	output wire [7:0]  DAC_inf,   // DAC逐次逼近反馈
  output wire [2:0]  addach,    //ADC通道选择，输出需翻转
  //-----LCD1602-----
	inout   wire                [7:0]DB,
	output  wire                RS,//高电平数据，低电平指令
	output  wire                RW,//高电平读取，低电平写入
	output  wire                EN,//高电平读出，上升沿写入

  //NN
  input wire[3:0] result_r,//rtl change
  
    // This clock should comes from the crystal pad generated high speed clock (16MHz)
  input  hfextclk,
  output hfxoscen,// The signal to enable the crystal pad generated clock

  // This clock should comes from the crystal pad generated low speed clock (32.768KHz)
  input  lfextclk,
  output lfxoscen,// The signal to enable the crystal pad generated clock
  
  input  usbclk,// 60MHz USB CDC clock

  // The JTAG TCK is input, need to be pull-up
  input   io_pads_jtag_TCK_i_ival,

  // The JTAG TMS is input, need to be pull-up
  input   io_pads_jtag_TMS_i_ival,

  // The JTAG TDI is input, need to be pull-up
  input   io_pads_jtag_TDI_i_ival,

  // The JTAG TDO is output have enable
  output  io_pads_jtag_TDO_o_oval,
  output  io_pads_jtag_TDO_o_oe,

  // The GPIO are all bidir pad have enables
  input  [32-1:0] io_pads_gpioA_i_ival,
  output [32-1:0] io_pads_gpioA_o_oval,
  output [32-1:0] io_pads_gpioA_o_oe,

  input  [32-1:0] io_pads_gpioB_i_ival,
  output [32-1:0] io_pads_gpioB_o_oval,
  output [32-1:0] io_pads_gpioB_o_oe,

  //QSPI0 SCK and CS is output without enable
  output  io_pads_qspi0_sck_o_oval,
  output  io_pads_qspi0_cs_0_o_oval,

  //QSPI0 DQ is bidir I/O with enable, and need pull-up enable
  input   io_pads_qspi0_dq_0_i_ival,
  output  io_pads_qspi0_dq_0_o_oval,
  output  io_pads_qspi0_dq_0_o_oe,
  input   io_pads_qspi0_dq_1_i_ival,
  output  io_pads_qspi0_dq_1_o_oval,
  output  io_pads_qspi0_dq_1_o_oe,
  input   io_pads_qspi0_dq_2_i_ival,
  output  io_pads_qspi0_dq_2_o_oval,
  output  io_pads_qspi0_dq_2_o_oe,
  input   io_pads_qspi0_dq_3_i_ival,
  output  io_pads_qspi0_dq_3_o_oval,
  output  io_pads_qspi0_dq_3_o_oe,
  
  // Erst is input need to be pull-up by default
  input   io_pads_aon_erst_n_i_ival,

  // dbgmode are inputs need to be pull-up by default
  input  io_pads_dbgmode0_n_i_ival,
  input  io_pads_dbgmode1_n_i_ival,
  input  io_pads_dbgmode2_n_i_ival,

  // BootRom is input need to be pull-up by default
  input  io_pads_bootrom_n_i_ival,


  // dwakeup is input need to be pull-up by default
  input  io_pads_aon_pmu_dwakeup_n_i_ival,

      // PMU output is just output without enable
  output io_pads_aon_pmu_padrst_o_oval,
  output io_pads_aon_pmu_vddpaden_o_oval 


);

//rtl change rst
wire main_rst_n;//引出复位信号
assign u_e203_subsys_top.u_e203_subsys_main.u_e203_cpu_top.u_e203_srams.u_e203_dtcm_ram.u_sirv_dp_ram.lfextclk = lfextclk;//ibus存储器时钟
assign u_app_p_top.u_Yduck_SoC.e203_dout = u_e203_subsys_top.u_e203_subsys_main.u_e203_cpu_top.u_e203_srams.u_e203_dtcm_ram.doutb;//ibus端口
assign u_e203_subsys_top.u_e203_subsys_main.u_e203_cpu_top.u_e203_srams.u_e203_dtcm_ram.addrb = u_app_p_top.u_Yduck_SoC.e203_addr;//ibus端口
assign u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_perips.YD_PWM_P = u_app_p_top.u_Yduck_SoC.T0_PWM_P;//T0_PWM_P端口
assign u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_perips.YD_PWM_N = u_app_p_top.u_Yduck_SoC.T0_PWM_N;//T0_PWM_P端口
assign u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_perips.YD_OUT[0] = u_app_p_top.u_Yduck_SoC.gpio_out[0];//gpio_out0端口
assign u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_perips.YD_OUT[1] = u_app_p_top.u_Yduck_SoC.gpio_out[1];//gpio_out1端口
assign u_app_p_top.u_Yduck_SoC.gpio_in[0] = u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_perips.YD_IN[0];//gpio_in0端口
assign u_app_p_top.u_Yduck_SoC.gpio_in[1] = u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_perips.YD_IN[1];//gpio_in1端口
//rtl change,sysfio wire
wire                         sysfio_icb_cmd_valid;
wire                         sysfio_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   sysfio_icb_cmd_addr ;
wire                         sysfio_icb_cmd_read ;
wire [`E203_XLEN-1:0]        sysfio_icb_cmd_wdata;
wire [`E203_XLEN/8-1:0]      sysfio_icb_cmd_wmask;
wire                         sysfio_icb_rsp_valid;
wire                         sysfio_icb_rsp_ready;
wire                         sysfio_icb_rsp_err  ;
wire [`E203_XLEN-1:0]        sysfio_icb_rsp_rdata;
//rtl change,ext2dtcm wire
wire                         ext2dtcm_icb_cmd_valid;
wire                         ext2dtcm_icb_cmd_ready;
wire [`E203_DTCM_ADDR_WIDTH-1:0]ext2dtcm_icb_cmd_addr;
wire                         ext2dtcm_icb_cmd_read ; 
wire [`E203_XLEN-1:0]        ext2dtcm_icb_cmd_wdata;
wire [`E203_XLEN/8-1:0]      ext2dtcm_icb_cmd_wmask;
wire                         ext2dtcm_icb_rsp_valid;
wire                         ext2dtcm_icb_rsp_ready;
wire                         ext2dtcm_icb_rsp_err  ;
wire [`E203_XLEN-1:0]        ext2dtcm_icb_rsp_rdata;
//rtl change


wire sysper_icb_cmd_valid;
wire sysper_icb_cmd_ready;
wire sysmem_icb_cmd_valid;
wire sysmem_icb_cmd_ready;

 e203_subsys_top u_e203_subsys_top(
    .core_mhartid      (1'b0),
    .result_r        (result_r),//rtl change
  `ifdef E203_HAS_ITCM_EXTITF //{
    .ext2itcm_icb_cmd_valid  (1'b0),
    .ext2itcm_icb_cmd_ready  (),
    .ext2itcm_icb_cmd_addr   (`E203_ITCM_ADDR_WIDTH'b0 ),
    .ext2itcm_icb_cmd_read   (1'b0 ),
    .ext2itcm_icb_cmd_wdata  (32'b0),
    .ext2itcm_icb_cmd_wmask  (4'b0),
    
    .ext2itcm_icb_rsp_valid  (),
    .ext2itcm_icb_rsp_ready  (1'b0),
    .ext2itcm_icb_rsp_err    (),
    .ext2itcm_icb_rsp_rdata  (),
  `endif//}

  `ifdef E203_HAS_DTCM_EXTITF //{
//rtl change-ext2dtcm port
    .ext2dtcm_icb_cmd_valid  (ext2dtcm_icb_cmd_valid),
    .ext2dtcm_icb_cmd_ready  (ext2dtcm_icb_cmd_ready),
    .ext2dtcm_icb_cmd_addr   (ext2dtcm_icb_cmd_addr ),
    .ext2dtcm_icb_cmd_read   (ext2dtcm_icb_cmd_read ),
    .ext2dtcm_icb_cmd_wdata  (ext2dtcm_icb_cmd_wdata),
    .ext2dtcm_icb_cmd_wmask  (ext2dtcm_icb_cmd_wmask),
    
    .ext2dtcm_icb_rsp_valid  (ext2dtcm_icb_rsp_valid),
    .ext2dtcm_icb_rsp_ready  (ext2dtcm_icb_rsp_ready),
    .ext2dtcm_icb_rsp_err    (ext2dtcm_icb_rsp_err  ),
    .ext2dtcm_icb_rsp_rdata  (ext2dtcm_icb_rsp_rdata),
//rtl change-ext2dtcm port
  `endif//}

  .sysper_icb_cmd_valid (sysper_icb_cmd_valid),
  .sysper_icb_cmd_ready (sysper_icb_cmd_ready),
  .sysper_icb_cmd_read  (), 
  .sysper_icb_cmd_addr  (), 
  .sysper_icb_cmd_wdata (), 
  .sysper_icb_cmd_wmask (), 
  
  .sysper_icb_rsp_valid (sysper_icb_cmd_valid),
  .sysper_icb_rsp_ready (sysper_icb_cmd_ready),
  .sysper_icb_rsp_err   (1'b0  ),
  .sysper_icb_rsp_rdata (32'b0),
//rtl change-sysfio port
  .sysfio_icb_cmd_valid(sysfio_icb_cmd_valid),
  .sysfio_icb_cmd_ready(sysfio_icb_cmd_ready),
  .sysfio_icb_cmd_read (sysfio_icb_cmd_read ),
  .sysfio_icb_cmd_addr (sysfio_icb_cmd_addr ),
  .sysfio_icb_cmd_wdata(sysfio_icb_cmd_wdata),
  .sysfio_icb_cmd_wmask(sysfio_icb_cmd_wmask),
   
  .sysfio_icb_rsp_valid(sysfio_icb_rsp_valid),
  .sysfio_icb_rsp_ready(sysfio_icb_rsp_ready),
  .sysfio_icb_rsp_err  (sysfio_icb_rsp_err  ),
  .sysfio_icb_rsp_rdata(sysfio_icb_rsp_rdata),
//rtl change-sysfio port
  .sysmem_icb_cmd_valid(sysmem_icb_cmd_valid),
  .sysmem_icb_cmd_ready(sysmem_icb_cmd_ready),
  .sysmem_icb_cmd_read (), 
  .sysmem_icb_cmd_addr (), 
  .sysmem_icb_cmd_wdata(), 
  .sysmem_icb_cmd_wmask(), 

  .sysmem_icb_rsp_valid(sysmem_icb_cmd_valid),
  .sysmem_icb_rsp_ready(sysmem_icb_cmd_ready),
  .sysmem_icb_rsp_err  (1'b0  ),
  .sysmem_icb_rsp_rdata(32'b0),

  .io_pads_jtag_TCK_i_ival    (io_pads_jtag_TCK_i_ival    ),
  .io_pads_jtag_TCK_o_oval    (),
  .io_pads_jtag_TCK_o_oe      (),
  .io_pads_jtag_TCK_o_ie      (),
  .io_pads_jtag_TCK_o_pue     (),
  .io_pads_jtag_TCK_o_ds      (),

  .io_pads_jtag_TMS_i_ival    (io_pads_jtag_TMS_i_ival    ),
  .io_pads_jtag_TMS_o_oval    (),
  .io_pads_jtag_TMS_o_oe      (),
  .io_pads_jtag_TMS_o_ie      (),
  .io_pads_jtag_TMS_o_pue     (),
  .io_pads_jtag_TMS_o_ds      (),

  .io_pads_jtag_TDI_i_ival    (io_pads_jtag_TDI_i_ival    ),
  .io_pads_jtag_TDI_o_oval    (),
  .io_pads_jtag_TDI_o_oe      (),
  .io_pads_jtag_TDI_o_ie      (),
  .io_pads_jtag_TDI_o_pue     (),
  .io_pads_jtag_TDI_o_ds      (),

  .io_pads_jtag_TDO_i_ival    (1'b1    ),
  .io_pads_jtag_TDO_o_oval    (io_pads_jtag_TDO_o_oval    ),
  .io_pads_jtag_TDO_o_oe      (io_pads_jtag_TDO_o_oe      ),
  .io_pads_jtag_TDO_o_ie      (),
  .io_pads_jtag_TDO_o_pue     (),
  .io_pads_jtag_TDO_o_ds      (),

  .io_pads_jtag_TRST_n_i_ival (1'b1 ),
  .io_pads_jtag_TRST_n_o_oval (),
  .io_pads_jtag_TRST_n_o_oe   (),
  .io_pads_jtag_TRST_n_o_ie   (),
  .io_pads_jtag_TRST_n_o_pue  (),
  .io_pads_jtag_TRST_n_o_ds   (),

  .test_mode(1'b0),
  .test_iso_override(1'b0),

  .io_pads_gpioA_i_ival       (io_pads_gpioA_i_ival),
  .io_pads_gpioA_o_oval       (io_pads_gpioA_o_oval),
  .io_pads_gpioA_o_oe         (io_pads_gpioA_o_oe), 

  .io_pads_gpioB_i_ival       (io_pads_gpioB_i_ival),
  .io_pads_gpioB_o_oval       (io_pads_gpioB_o_oval),
  .io_pads_gpioB_o_oe         (io_pads_gpioB_o_oe), 

  .io_pads_qspi0_sck_i_ival   (1'b1),
  .io_pads_qspi0_sck_o_oval   (io_pads_qspi0_sck_o_oval),
  .io_pads_qspi0_sck_o_oe     (),
  .io_pads_qspi0_dq_0_i_ival  (io_pads_qspi0_dq_0_i_ival),
  .io_pads_qspi0_dq_0_o_oval  (io_pads_qspi0_dq_0_o_oval),
  .io_pads_qspi0_dq_0_o_oe    (io_pads_qspi0_dq_0_o_oe),
  .io_pads_qspi0_dq_1_i_ival  (io_pads_qspi0_dq_1_i_ival),
  .io_pads_qspi0_dq_1_o_oval  (io_pads_qspi0_dq_1_o_oval),
  .io_pads_qspi0_dq_1_o_oe    (io_pads_qspi0_dq_1_o_oe),
  .io_pads_qspi0_dq_2_i_ival  (io_pads_qspi0_dq_2_i_ival),
  .io_pads_qspi0_dq_2_o_oval  (io_pads_qspi0_dq_2_o_oval),
  .io_pads_qspi0_dq_2_o_oe    (io_pads_qspi0_dq_2_o_oe),
  .io_pads_qspi0_dq_3_i_ival  (io_pads_qspi0_dq_3_i_ival),
  .io_pads_qspi0_dq_3_o_oval  (io_pads_qspi0_dq_3_o_oval),
  .io_pads_qspi0_dq_3_o_oe    (io_pads_qspi0_dq_3_o_oe),
  .io_pads_qspi0_cs_0_i_ival  (1'b1),
  .io_pads_qspi0_cs_0_o_oval  (io_pads_qspi0_cs_0_o_oval),
  .io_pads_qspi0_cs_0_o_oe    (), 

    .hfextclk        (hfextclk),
    .hfxoscen        (hfxoscen),
    .lfextclk        (lfextclk),
    .lfxoscen        (lfxoscen),
    .main_rst_n      (main_rst_n),//rtl change

  .io_pads_aon_erst_n_i_ival        (io_pads_aon_erst_n_i_ival       ), 
  .io_pads_aon_erst_n_o_oval        (),
  .io_pads_aon_erst_n_o_oe          (),
  .io_pads_aon_erst_n_o_ie          (),
  .io_pads_aon_erst_n_o_pue         (),
  .io_pads_aon_erst_n_o_ds          (),
  .io_pads_aon_pmu_dwakeup_n_i_ival (io_pads_aon_pmu_dwakeup_n_i_ival),
  .io_pads_aon_pmu_dwakeup_n_o_oval (),
  .io_pads_aon_pmu_dwakeup_n_o_oe   (),
  .io_pads_aon_pmu_dwakeup_n_o_ie   (),
  .io_pads_aon_pmu_dwakeup_n_o_pue  (),
  .io_pads_aon_pmu_dwakeup_n_o_ds   (),
  .io_pads_aon_pmu_vddpaden_i_ival  (1'b1 ),
  .io_pads_aon_pmu_vddpaden_o_oval  (io_pads_aon_pmu_vddpaden_o_oval ),
  .io_pads_aon_pmu_vddpaden_o_oe    (),
  .io_pads_aon_pmu_vddpaden_o_ie    (),
  .io_pads_aon_pmu_vddpaden_o_pue   (),
  .io_pads_aon_pmu_vddpaden_o_ds    (),

  
    .io_pads_aon_pmu_padrst_i_ival    (1'b1 ),
    .io_pads_aon_pmu_padrst_o_oval    (io_pads_aon_pmu_padrst_o_oval ),
    .io_pads_aon_pmu_padrst_o_oe      (),
    .io_pads_aon_pmu_padrst_o_ie      (),
    .io_pads_aon_pmu_padrst_o_pue     (),
    .io_pads_aon_pmu_padrst_o_ds      (),

    .io_pads_bootrom_n_i_ival       (io_pads_bootrom_n_i_ival),
    .io_pads_bootrom_n_o_oval       (),
    .io_pads_bootrom_n_o_oe         (),
    .io_pads_bootrom_n_o_ie         (),
    .io_pads_bootrom_n_o_pue        (),
    .io_pads_bootrom_n_o_ds         (),

    .io_pads_dbgmode0_n_i_ival       (io_pads_dbgmode0_n_i_ival),

    .io_pads_dbgmode1_n_i_ival       (io_pads_dbgmode1_n_i_ival),

    .io_pads_dbgmode2_n_i_ival       (io_pads_dbgmode2_n_i_ival) 


  );

app_p_top u_app_p_top
(
  //公共
  .hfextclk               (hfextclk),
  .lfextclk               (lfextclk),
  .usbclk                 (usbclk),
  .rst_n                  (main_rst_n),
  //对外接口
	.usb_dp_pull            (usb_dp_pull),
	.usb_dp                 (usb_dp),
	.usb_dn                 (usb_dn),
  .cmp                    (cmp),
	.DAC_inf                (DAC_inf),
	.addach                 (addach),
	.DB                     (DB),
	.RS                     (RS),
	.RW                     (RW),
	.EN                     (EN),
  //ICB
  .ext2dtcm_icb_cmd_valid (ext2dtcm_icb_cmd_valid),
  .ext2dtcm_icb_cmd_ready (ext2dtcm_icb_cmd_ready),
  .ext2dtcm_icb_cmd_addr  (ext2dtcm_icb_cmd_addr ),
  .ext2dtcm_icb_cmd_read  (ext2dtcm_icb_cmd_read ),
  .ext2dtcm_icb_cmd_wdata (ext2dtcm_icb_cmd_wdata),
  .ext2dtcm_icb_cmd_wmask (ext2dtcm_icb_cmd_wmask),
  .ext2dtcm_icb_rsp_valid (ext2dtcm_icb_rsp_valid),
  .ext2dtcm_icb_rsp_ready (ext2dtcm_icb_rsp_ready),
  .ext2dtcm_icb_rsp_err   (ext2dtcm_icb_rsp_err  ),
  .ext2dtcm_icb_rsp_rdata (ext2dtcm_icb_rsp_rdata),

  .sysfio_icb_cmd_valid   (sysfio_icb_cmd_valid),
  .sysfio_icb_cmd_ready   (sysfio_icb_cmd_ready),
  .sysfio_icb_cmd_addr    (sysfio_icb_cmd_addr ),
  .sysfio_icb_cmd_read    (sysfio_icb_cmd_read ),
  .sysfio_icb_cmd_wdata   (sysfio_icb_cmd_wdata),
  .sysfio_icb_cmd_wmask   (sysfio_icb_cmd_wmask),
  .sysfio_icb_rsp_valid   (sysfio_icb_rsp_valid),
  .sysfio_icb_rsp_ready   (sysfio_icb_rsp_ready),
  .sysfio_icb_rsp_err     (sysfio_icb_rsp_err  ),
  .sysfio_icb_rsp_rdata   (sysfio_icb_rsp_rdata)
);


endmodule
