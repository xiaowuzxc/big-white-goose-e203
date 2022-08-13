`timescale 1ns/1ps

module system
(
  input wire CLK50M,//GCLK-W19
  output wire LED,
  input wire bootrom,
  input wire ck_rst,//MCU_RESET-P20

  //对外接口
  //对外接口
	//usb
	output wire        usb_dp_pull,  // connect to USB D+ by an 1.5k resistor
	inout              usb_dp,       // connect to USB D+
	inout              usb_dn,       // connect to USB D-
	//ADDAC
	input              cmp,       // 比较器输出
	output wire [7:0]  DAC_inf,   // DAC逐次逼近反馈
  output wire [1:0]  addach,    //ADC通道选择，输出需翻转
  //-----LCD1602-----
	inout   wire                [7:0]DB,
	output  wire                RS,//高电平数据，低电平指令
	output  wire                RW,//高电平读取，低电平写入
	output  wire                EN,//高电平读出，上升沿写入
  //dvp
  input                 cam_pclk     ,  //cmos 数据像素时钟
  input                 cam_vsync    ,  //cmos 场同步信号
  input                 cam_href     ,  //cmos 行同步信号
  input   [7:0]         cam_data     ,  //cmos 数据
  output                cam_rst_n    ,  //cmos 复位信号，低电平有效
  output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
  output                cam_scl      ,  //cmos SCCB_SCL线
  inout                 cam_sda      ,  //cmos SCCB_SDA线       
  // DDR3                            
  inout   [15:0]        ddr3_dq      ,  //DDR3 数据
  inout   [1:0]         ddr3_dqs_n   ,  //DDR3 dqs负
  inout   [1:0]         ddr3_dqs_p   ,  //DDR3 dqs正  
  output  [14:0]        ddr3_addr    ,  //DDR3 地址   
  output  [2:0]         ddr3_ba      ,  //DDR3 banck 选择
  output                ddr3_ras_n   ,  //DDR3 行选择
  output                ddr3_cas_n   ,  //DDR3 列选择
  output                ddr3_we_n    ,  //DDR3 读写选择
  output                ddr3_reset_n ,  //DDR3 复位
  output  [0:0]         ddr3_ck_p    ,  //DDR3 时钟正
  output  [0:0]         ddr3_ck_n    ,  //DDR3 时钟负
  output  [0:0]         ddr3_cke     ,  //DDR3 时钟使能
  output  [0:0]         ddr3_cs_n    ,  //DDR3 片选
  output  [1:0]         ddr3_dm      ,  //DDR3_dm
  output  [0:0]         ddr3_odt     ,  //DDR3_odt									                            
  //hdmi接口                           
  output                tmds_clk_p   ,  // TMDS 时钟通道
  output                tmds_clk_n   ,
  output  [2:0]         tmds_data_p  ,  // TMDS 数据通道
  output  [2:0]         tmds_data_n  ,
  output                tmds_oen     , // TMDS 输出使能

  // Dedicated QSPI interface
  output wire qspi0_cs,
  output wire qspi0_sck,
  inout wire [3:0] qspi0_dq,
                           
  //gpioA
  inout wire [31:0] gpioA,//GPIOA00~GPIOA31

  //gpioB
  inout wire [31:0] gpioB,//GPIOB00~GPIOB31

  // JD (used for JTAG connection)
  inout wire mcu_TDO,//MCU_TDO-N17
  inout wire mcu_TCK,//MCU_TCK-P15 
  inout wire mcu_TDI,//MCU_TDI-T18
  inout wire mcu_TMS,//MCU_TMS-P17

  //pmu_wakeup

  inout wire pmu_paden,  //PMU_VDDPADEN-U15
  inout wire pmu_padrst, //PMU_VADDPARST_V15
  inout wire mcu_wakeup  //MCU_WAKE-N15


);

  wire clk_out1;
  wire mmcm_locked;
  wire usbclk;
  //wire reset_periph;

  // All wires connected to the chip top
  wire dut_clock;
  wire dut_reset;

  wire dut_io_pads_jtag_TCK_i_ival;
  wire dut_io_pads_jtag_TMS_i_ival;
  wire dut_io_pads_jtag_TMS_o_oval;
  wire dut_io_pads_jtag_TMS_o_oe;
  wire dut_io_pads_jtag_TMS_o_ie;
  wire dut_io_pads_jtag_TMS_o_pue;
  wire dut_io_pads_jtag_TMS_o_ds;
  wire dut_io_pads_jtag_TDI_i_ival;
  wire dut_io_pads_jtag_TDO_o_oval;
  wire dut_io_pads_jtag_TDO_o_oe;

  wire [32-1:0] dut_io_pads_gpioA_i_ival;
  wire [32-1:0] dut_io_pads_gpioA_o_oval;
  wire [32-1:0] dut_io_pads_gpioA_o_oe;

  wire [32-1:0] dut_io_pads_gpioB_i_ival;
  wire [32-1:0] dut_io_pads_gpioB_o_oval;
  wire [32-1:0] dut_io_pads_gpioB_o_oe;

  wire dut_io_pads_qspi0_sck_o_oval;
  wire dut_io_pads_qspi0_cs_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_i_ival;
  wire dut_io_pads_qspi0_dq_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_o_oe;
  wire dut_io_pads_qspi0_dq_1_i_ival;
  wire dut_io_pads_qspi0_dq_1_o_oval;
  wire dut_io_pads_qspi0_dq_1_o_oe;
  wire dut_io_pads_qspi0_dq_2_i_ival;
  wire dut_io_pads_qspi0_dq_2_o_oval;
  wire dut_io_pads_qspi0_dq_2_o_oe;
  wire dut_io_pads_qspi0_dq_3_i_ival;
  wire dut_io_pads_qspi0_dq_3_o_oval;
  wire dut_io_pads_qspi0_dq_3_o_oe;


  wire dut_io_pads_aon_erst_n_i_ival;
  wire dut_io_pads_aon_pmu_dwakeup_n_i_ival;
  wire dut_io_pads_aon_pmu_vddpaden_o_oval;
  wire dut_io_pads_aon_pmu_padrst_o_oval ;
  wire dut_io_pads_bootrom_n_i_ival;
  wire dut_io_pads_dbgmode0_n_i_ival;
  wire dut_io_pads_dbgmode1_n_i_ival;
  wire dut_io_pads_dbgmode2_n_i_ival;
  //NN rtl change
  reg [3:0]result_r,result_rr;
  wire [3:0]result;
  //=================================================
  // Clock & Reset
  wire vrst_n= ck_rst&mmcm_locked;
  wire clk_16;//处理器主时钟
  wire clk_60;//USB时钟
  wire clk_50;//级联50M时钟
  mmcm ip_mmcm
   (
  // Status and control signals
    .resetn(ck_rst), // input resetn
    .locked(mmcm_locked),       // output locked
   // Clock in ports
    .clk_in1(CLK50M),
    // Clock out ports
    .clk_16(clk_16),     // output clk_16
    .clk_60(clk_60),     // output clk_60
    .clk_50(clk_50)     // output clk_50
  );      // input clk_in1

  wire CLK32768HZ;
  divide #(//32768Hz clk div
    .WIDTH(16), 
    .N(500)) 
  div32 (
    .clk(clk_16), 
    .rst_n(ck_rst), 
    .clkout(CLK32768KHZ)
    );


  divide #(//1Hz
    .WIDTH(64), 
    .N(16_000_000)) 
  divled (
    .clk(clk_16), 
    .rst_n(ck_rst), 
    .clkout(LED)
    );


  //=================================================
  // SPI0 Interface

  wire [3:0] qspi0_ui_dq_o; 
  wire [3:0] qspi0_ui_dq_oe;
  wire [3:0] qspi0_ui_dq_i;

  PULLUP qspi0_pullup[3:0]
  (
    .O(qspi0_dq)
  );

  IOBUF qspi0_iobuf[3:0]
  (
    .IO(qspi0_dq),
    .O(qspi0_ui_dq_i),
    .I(qspi0_ui_dq_o),
    .T(~qspi0_ui_dq_oe)
  );


  //=================================================
  // IOBUF instantiation for GPIOs

  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_iobuf[31:0]
  (
    .O(dut_io_pads_gpioA_i_ival),
    .IO(gpioA),
    .I(dut_io_pads_gpioA_o_oval),
    .T(~dut_io_pads_gpioA_o_oe)
  );

  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioB_iobuf[31:0]
  (
    .O(dut_io_pads_gpioB_i_ival),
    .IO(gpioB),
    .I(dut_io_pads_gpioB_o_oval),
    .T(~dut_io_pads_gpioB_o_oe)
  );
  //=================================================
  // JTAG IOBUFs

  wire iobuf_jtag_TCK_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TCK
  (
    .O(iobuf_jtag_TCK_o),
    .IO(mcu_TCK),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TCK_i_ival = iobuf_jtag_TCK_o ;
  PULLUP pullup_TCK (.O(mcu_TCK));

  wire iobuf_jtag_TMS_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TMS
  (
    .O(iobuf_jtag_TMS_o),
    .IO(mcu_TMS),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TMS_i_ival = iobuf_jtag_TMS_o;
  PULLUP pullup_TMS (.O(mcu_TMS));

  wire iobuf_jtag_TDI_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDI
  (
    .O(iobuf_jtag_TDI_o),
    .IO(mcu_TDI),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TDI_i_ival = iobuf_jtag_TDI_o;
  PULLUP pullup_TDI (.O(mcu_TDI));

  wire iobuf_jtag_TDO_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDO
  (
    .O(iobuf_jtag_TDO_o),
    .IO(mcu_TDO),
    .I(dut_io_pads_jtag_TDO_o_oval),
    .T(~dut_io_pads_jtag_TDO_o_oe)
  );

  //=================================================
  // Assignment of IOBUF "IO" pins to package pins

  // Pins IO0-IO13
  // Shield header row 0: PD0-PD7

  // Use the LEDs for some more useful debugging things.
  assign pmu_paden  = dut_io_pads_aon_pmu_vddpaden_o_oval;  
  assign pmu_padrst = dut_io_pads_aon_pmu_padrst_o_oval;		

  // model select
  assign dut_io_pads_bootrom_n_i_ival  = bootrom;   //
  assign dut_io_pads_dbgmode0_n_i_ival = 1'b1;
  assign dut_io_pads_dbgmode1_n_i_ival = 1'b1;
  assign dut_io_pads_dbgmode2_n_i_ival = 1'b1;
  //
  //rtl change
  always @(posedge clk_16) begin
    result_r<=result;
    result_rr<=result_r;
  end

  //rtl change
  e203_soc_top dut
  (
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
//公共接口
    .hfextclk(clk_16),
    .hfxoscen(),
    .lfextclk(CLK32768KHZ), 
    .lfxoscen(),
    .usbclk(clk_60),
    .result_r        (result_rr),//rtl change
       // Note: this is the real SoC top AON domain slow clock
    .io_pads_jtag_TCK_i_ival(dut_io_pads_jtag_TCK_i_ival),
    .io_pads_jtag_TMS_i_ival(dut_io_pads_jtag_TMS_i_ival),
    .io_pads_jtag_TDI_i_ival(dut_io_pads_jtag_TDI_i_ival),
    .io_pads_jtag_TDO_o_oval(dut_io_pads_jtag_TDO_o_oval),
    .io_pads_jtag_TDO_o_oe  (dut_io_pads_jtag_TDO_o_oe),

    .io_pads_gpioA_i_ival(dut_io_pads_gpioA_i_ival),
    .io_pads_gpioA_o_oval(dut_io_pads_gpioA_o_oval),
    .io_pads_gpioA_o_oe  (dut_io_pads_gpioA_o_oe),

    .io_pads_gpioB_i_ival(dut_io_pads_gpioB_i_ival),
    .io_pads_gpioB_o_oval(dut_io_pads_gpioB_o_oval),
    .io_pads_gpioB_o_oe  (dut_io_pads_gpioB_o_oe),

    .io_pads_qspi0_sck_o_oval (dut_io_pads_qspi0_sck_o_oval),
    .io_pads_qspi0_cs_0_o_oval(dut_io_pads_qspi0_cs_0_o_oval),

    .io_pads_qspi0_dq_0_i_ival(dut_io_pads_qspi0_dq_0_i_ival),
    .io_pads_qspi0_dq_0_o_oval(dut_io_pads_qspi0_dq_0_o_oval),
    .io_pads_qspi0_dq_0_o_oe  (dut_io_pads_qspi0_dq_0_o_oe),
    .io_pads_qspi0_dq_1_i_ival(dut_io_pads_qspi0_dq_1_i_ival),
    .io_pads_qspi0_dq_1_o_oval(dut_io_pads_qspi0_dq_1_o_oval),
    .io_pads_qspi0_dq_1_o_oe  (dut_io_pads_qspi0_dq_1_o_oe),
    .io_pads_qspi0_dq_2_i_ival(dut_io_pads_qspi0_dq_2_i_ival),
    .io_pads_qspi0_dq_2_o_oval(dut_io_pads_qspi0_dq_2_o_oval),
    .io_pads_qspi0_dq_2_o_oe  (dut_io_pads_qspi0_dq_2_o_oe),
    .io_pads_qspi0_dq_3_i_ival(dut_io_pads_qspi0_dq_3_i_ival),
    .io_pads_qspi0_dq_3_o_oval(dut_io_pads_qspi0_dq_3_o_oval),
    .io_pads_qspi0_dq_3_o_oe  (dut_io_pads_qspi0_dq_3_o_oe),


       // Note: this is the real SoC top level reset signal
    .io_pads_aon_erst_n_i_ival(ck_rst),
    .io_pads_aon_pmu_dwakeup_n_i_ival(dut_io_pads_aon_pmu_dwakeup_n_i_ival),
    .io_pads_aon_pmu_vddpaden_o_oval(dut_io_pads_aon_pmu_vddpaden_o_oval),

    .io_pads_aon_pmu_padrst_o_oval    (dut_io_pads_aon_pmu_padrst_o_oval ),

    .io_pads_bootrom_n_i_ival        (dut_io_pads_bootrom_n_i_ival),

    .io_pads_dbgmode0_n_i_ival       (dut_io_pads_dbgmode0_n_i_ival),
    .io_pads_dbgmode1_n_i_ival       (dut_io_pads_dbgmode1_n_i_ival),
    .io_pads_dbgmode2_n_i_ival       (dut_io_pads_dbgmode2_n_i_ival) 
  );

  // Assign reasonable values to otherwise unconnected inputs to chip top

  wire iobuf_dwakeup_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_dwakeup_n
  (
    .O(iobuf_dwakeup_o),
    .IO(mcu_wakeup),
    .I(1'b1),
    .T(1'b1)
  );
  assign dut_io_pads_aon_pmu_dwakeup_n_i_ival = (~iobuf_dwakeup_o);
  assign dut_io_pads_aon_pmu_vddpaden_i_ival = 1'b1;

  assign qspi0_sck = dut_io_pads_qspi0_sck_o_oval;
  assign qspi0_cs  = dut_io_pads_qspi0_cs_0_o_oval;
  assign qspi0_ui_dq_o = {
    dut_io_pads_qspi0_dq_3_o_oval,
    dut_io_pads_qspi0_dq_2_o_oval,
    dut_io_pads_qspi0_dq_1_o_oval,
    dut_io_pads_qspi0_dq_0_o_oval
  };
  assign qspi0_ui_dq_oe = {
    dut_io_pads_qspi0_dq_3_o_oe,
    dut_io_pads_qspi0_dq_2_o_oe,
    dut_io_pads_qspi0_dq_1_o_oe,
    dut_io_pads_qspi0_dq_0_o_oe
  };
  assign dut_io_pads_qspi0_dq_0_i_ival = qspi0_ui_dq_i[0];
  assign dut_io_pads_qspi0_dq_1_i_ival = qspi0_ui_dq_i[1];
  assign dut_io_pads_qspi0_dq_2_i_ival = qspi0_ui_dq_i[2];
  assign dut_io_pads_qspi0_dq_3_i_ival = qspi0_ui_dq_i[3];
/*rtl change*/
	ov5640_hdmi u_ov5640_hdmi (
			.sys_clk      (clk_50),
			.sys_rst_n    (ck_rst),

			.cam_pclk     (cam_pclk),
			.cam_vsync    (cam_vsync),
			.cam_href     (cam_href),
			.cam_data     (cam_data),
			.cam_rst_n    (cam_rst_n),
			.cam_pwdn     (cam_pwdn),
			.cam_scl      (cam_scl),
			.cam_sda      (cam_sda),

			.ddr3_dq      (ddr3_dq),
			.ddr3_dqs_n   (ddr3_dqs_n),
			.ddr3_dqs_p   (ddr3_dqs_p),
			.ddr3_addr    (ddr3_addr),
			.ddr3_ba      (ddr3_ba),
			.ddr3_ras_n   (ddr3_ras_n),
			.ddr3_cas_n   (ddr3_cas_n),
			.ddr3_we_n    (ddr3_we_n),
			.ddr3_reset_n (ddr3_reset_n),
			.ddr3_ck_p    (ddr3_ck_p),
			.ddr3_ck_n    (ddr3_ck_n),
			.ddr3_cke     (ddr3_cke),
			.ddr3_cs_n    (ddr3_cs_n),
			.ddr3_dm      (ddr3_dm),
			.ddr3_odt     (ddr3_odt),

			.tmds_clk_p   (tmds_clk_p),
			.tmds_clk_n   (tmds_clk_n),
			.tmds_data_p  (tmds_data_p),
			.tmds_data_n  (tmds_data_n),
			.tmds_oen     (tmds_oen),

			.result_r     (result)
		);
/*rtl change*/

endmodule


