`include "e203_defines.v" 
module app_p_top (
	//时钟
	input hfextclk,//16M
	input lfextclk,//32768Hz
	input usbclk,// 60MHz USB CDC clock
	input rst_n,

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

	//ext2dtcm M
	output wire                        ext2dtcm_icb_cmd_valid,
	input  wire                        ext2dtcm_icb_cmd_ready,
	output wire[`E203_DTCM_ADDR_WIDTH-1:0]ext2dtcm_icb_cmd_addr, 
	output wire                        ext2dtcm_icb_cmd_read, 
	output wire[`E203_XLEN-1:0]        ext2dtcm_icb_cmd_wdata,
	output wire[`E203_XLEN/8-1:0]      ext2dtcm_icb_cmd_wmask,
	input  wire                        ext2dtcm_icb_rsp_valid,
	output wire                        ext2dtcm_icb_rsp_ready,
	input  wire                        ext2dtcm_icb_rsp_err  ,
	input  wire[`E203_XLEN-1:0]        ext2dtcm_icb_rsp_rdata,
	//sysfio S
	input                          sysfio_icb_cmd_valid,
	output                         sysfio_icb_cmd_ready,
	input  [`E203_ADDR_SIZE-1:0]   sysfio_icb_cmd_addr, 
	input                          sysfio_icb_cmd_read, 
	input  [`E203_XLEN-1:0]        sysfio_icb_cmd_wdata,
	input  [`E203_XLEN/8-1:0]      sysfio_icb_cmd_wmask,
	output                         sysfio_icb_rsp_valid,
	input                          sysfio_icb_rsp_ready,
	output                         sysfio_icb_rsp_err  ,
	output [`E203_XLEN-1:0]        sysfio_icb_rsp_rdata
);

/*-----------ICB 1M->8S------------------
来自sysfio
app基地址: 0xF000_0000
地址范围: 0xF000_0000 --- 0xFFFF_FFFF
可用空间: 2^28 Byte = 268M Byte
	
外设列表：
**********0 ADDAC+大黄鸭控制 **********
地址范围：0xF000_0000 - 0xF000_00FF
地址宽度：8
**********1 USB CDC UART k**********
地址范围：0xF000_0100 - 0xF000_01FF
地址宽度：8
**********2 DMA k**********
地址范围：0xF000_0200 - 0xF000_02FF
地址宽度：8
**********3 1602 k **********
地址范围：0xF000_0300 - 0xF000_03FF
地址宽度：8

----------------------------------------*/

//addac
wire                         addac_icb_cmd_valid;
wire                         addac_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   addac_icb_cmd_addr ;
wire                         addac_icb_cmd_read ;
wire [`E203_XLEN-1:0]        addac_icb_cmd_wdata;
wire                         addac_icb_rsp_valid;
wire                         addac_icb_rsp_ready;
wire                         addac_icb_rsp_err  ;
wire [`E203_XLEN-1:0]        addac_icb_rsp_rdata;
//usb cdc
wire                         usb_cdc_icb_cmd_valid;
wire                         usb_cdc_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   usb_cdc_icb_cmd_addr ;
wire                         usb_cdc_icb_cmd_read ;
wire [`E203_XLEN-1:0]        usb_cdc_icb_cmd_wdata;
wire                         usb_cdc_icb_rsp_valid;
wire                         usb_cdc_icb_rsp_ready;
wire                         usb_cdc_icb_rsp_err  ;
wire [`E203_XLEN-1:0]        usb_cdc_icb_rsp_rdata;
//dma_cfg
wire                         dma_cfg_icb_cmd_valid;
wire                         dma_cfg_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   dma_cfg_icb_cmd_addr ;
wire                         dma_cfg_icb_cmd_read ;
wire [`E203_XLEN-1:0]        dma_cfg_icb_cmd_wdata;
wire                         dma_cfg_icb_rsp_valid;
wire                         dma_cfg_icb_rsp_ready;
wire                         dma_cfg_icb_rsp_err  ;
wire [`E203_XLEN-1:0]        dma_cfg_icb_rsp_rdata;
//lcd1602
wire                         lcd_icb_cmd_valid;
wire                         lcd_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   lcd_icb_cmd_addr ;
wire                         lcd_icb_cmd_read ;
wire [`E203_XLEN-1:0]        lcd_icb_cmd_wdata;
wire                         lcd_icb_rsp_valid;
wire                         lcd_icb_rsp_ready;
wire                         lcd_icb_rsp_err  ;
wire [`E203_XLEN-1:0]        lcd_icb_rsp_rdata;

//连线
wire Yduck_start;

addac u_addac (
	.clk                 (hfextclk),
	.rst_n               (rst_n),
	.cmp                 (cmp),
	.DAC_inf             (DAC_inf),
	.addach              (addach),
	.Yduck_start         (Yduck_start),
	.addac_icb_cmd_valid (addac_icb_cmd_valid),
	.addac_icb_cmd_ready (addac_icb_cmd_ready),
	.addac_icb_cmd_addr  (addac_icb_cmd_addr ),
	.addac_icb_cmd_read  (addac_icb_cmd_read ),
	.addac_icb_cmd_wdata (addac_icb_cmd_wdata),
	.addac_icb_rsp_valid (addac_icb_rsp_valid),
	.addac_icb_rsp_ready (addac_icb_rsp_ready),
	.addac_icb_rsp_err   (addac_icb_rsp_err  ),
	.addac_icb_rsp_rdata (addac_icb_rsp_rdata)
);


e203_dma u_e203_dma
(
	.clk                   (hfextclk),
	.rst_n                 (rst_n),
	.dma_irq               (),
	//DMA访存ICB总线 DMA=master
	.dma_icb_cmd_valid     (ext2dtcm_icb_cmd_valid),
	.dma_icb_cmd_ready     (ext2dtcm_icb_cmd_ready),
	.dma_icb_cmd_addr      (ext2dtcm_icb_cmd_addr ),
	.dma_icb_cmd_read      (ext2dtcm_icb_cmd_read ),
	.dma_icb_cmd_wdata     (ext2dtcm_icb_cmd_wdata),
	.dma_icb_cmd_wmask     (ext2dtcm_icb_cmd_wmask),
	.dma_icb_rsp_valid     (ext2dtcm_icb_rsp_valid),
	.dma_icb_rsp_ready     (ext2dtcm_icb_rsp_ready),
	.dma_icb_rsp_err       (ext2dtcm_icb_rsp_err  ),
	.dma_icb_rsp_rdata     (ext2dtcm_icb_rsp_rdata),
	//DMA配置接口 DMA=slave
	.dma_cfg_icb_cmd_valid (dma_cfg_icb_cmd_valid ),
	.dma_cfg_icb_cmd_ready (dma_cfg_icb_cmd_ready ),
	.dma_cfg_icb_cmd_addr  (dma_cfg_icb_cmd_addr  ),
	.dma_cfg_icb_cmd_read  (dma_cfg_icb_cmd_read  ),
	.dma_cfg_icb_cmd_wdata (dma_cfg_icb_cmd_wdata ),
	.dma_cfg_icb_rsp_valid (dma_cfg_icb_rsp_valid ),
	.dma_cfg_icb_rsp_ready (dma_cfg_icb_rsp_ready ),
	.dma_cfg_icb_rsp_err   (dma_cfg_icb_rsp_err   ),
	.dma_cfg_icb_rsp_rdata (dma_cfg_icb_rsp_rdata )
);

usb_cdc_top u_usb_cdc_top
(
	.clk                   (hfextclk),
	.usbclk                (usbclk),
	.rst_n                 (rst_n),
	.usb_dp_pull           (usb_dp_pull),
	.usb_dp                (usb_dp),
	.usb_dn                (usb_dn),
	.usb_cdc_icb_cmd_valid (usb_cdc_icb_cmd_valid),
	.usb_cdc_icb_cmd_ready (usb_cdc_icb_cmd_ready),
	.usb_cdc_icb_cmd_addr  (usb_cdc_icb_cmd_addr),
	.usb_cdc_icb_cmd_read  (usb_cdc_icb_cmd_read),
	.usb_cdc_icb_cmd_wdata (usb_cdc_icb_cmd_wdata),
	.usb_cdc_icb_rsp_valid (usb_cdc_icb_rsp_valid),
	.usb_cdc_icb_rsp_ready (usb_cdc_icb_rsp_ready),
	.usb_cdc_icb_rsp_err   (usb_cdc_icb_rsp_err),
	.usb_cdc_icb_rsp_rdata (usb_cdc_icb_rsp_rdata)
);

lcd1602_top u_lcd1602_top
(
	.clk               (hfextclk),
	.rst_n             (rst_n),
	.lcd_icb_cmd_valid (lcd_icb_cmd_valid),
	.lcd_icb_cmd_ready (lcd_icb_cmd_ready),
	.lcd_icb_cmd_addr  (lcd_icb_cmd_addr ),
	.lcd_icb_cmd_read  (lcd_icb_cmd_read ),
	.lcd_icb_cmd_wdata (lcd_icb_cmd_wdata),
	.lcd_icb_rsp_valid (lcd_icb_rsp_valid),
	.lcd_icb_rsp_ready (lcd_icb_rsp_ready),
	.lcd_icb_rsp_err   (lcd_icb_rsp_err  ),
	.lcd_icb_rsp_rdata (lcd_icb_rsp_rdata),
	.DB                (DB),
	.RS                (RS),
	.RW                (RW),
	.EN                (EN)
);

sirv_icb1to8_bus #(
	.ICB_FIFO_DP        (2),//乒乓缓冲
	.ICB_FIFO_CUT_READY (1),//0
	.AW                 (32),
	.DW                 (`E203_XLEN),
	.SPLT_FIFO_OUTS_NUM (1),//1次滞外交易
	.SPLT_FIFO_CUT_READY(1),//0

	.O0_BASE_ADDR(32'hf000_0000),
	.O0_BASE_REGION_LSB(8),
	.O1_BASE_ADDR(32'hf000_0100),
	.O1_BASE_REGION_LSB(8),
	.O2_BASE_ADDR(32'hf000_0200),
	.O2_BASE_REGION_LSB(8),
	.O3_BASE_ADDR(32'hf000_0300),
	.O3_BASE_REGION_LSB(8),
	.O4_BASE_ADDR(32'hf000_0400),
	.O4_BASE_REGION_LSB(8),
	.O5_BASE_ADDR(32'hf100_0000),
	.O5_BASE_REGION_LSB(24),
	.O6_BASE_ADDR(32'hf200_0000),
	.O6_BASE_REGION_LSB(24),
	.O7_BASE_ADDR(32'hf300_0000),
	.O7_BASE_REGION_LSB(24)
) app_sirv_icb1to8_bus (
	//总线使能
	.o0_icb_enable      (1'b1),
	.o1_icb_enable      (1'b1),
	.o2_icb_enable      (1'b1),
	.o3_icb_enable      (1'b1),
	.o4_icb_enable      (1'b0),
	.o5_icb_enable      (1'b0),
	.o6_icb_enable      (1'b0),
	.o7_icb_enable      (1'b0),
	//主端口
	.i_icb_cmd_valid    (sysfio_icb_cmd_valid),
	.i_icb_cmd_ready    (sysfio_icb_cmd_ready),
	.i_icb_cmd_addr     (sysfio_icb_cmd_addr ),
	.i_icb_cmd_read     (sysfio_icb_cmd_read ),
	.i_icb_cmd_burst    (1'b0),
	.i_icb_cmd_beat     (1'b0),
	.i_icb_cmd_wdata    (sysfio_icb_cmd_wdata),
	.i_icb_cmd_wmask    (sysfio_icb_cmd_wmask),
	.i_icb_cmd_lock     (1'b0),
	.i_icb_cmd_excl     (1'b0),
	.i_icb_cmd_size     (1'b0),
	.i_icb_rsp_valid    (sysfio_icb_rsp_valid),
	.i_icb_rsp_ready    (sysfio_icb_rsp_ready),
	.i_icb_rsp_err      (sysfio_icb_rsp_err  ),
	.i_icb_rsp_excl_ok  (),
	.i_icb_rsp_rdata    (sysfio_icb_rsp_rdata),
	//扩展口
	.o0_icb_cmd_valid   (addac_icb_cmd_valid  ),
	.o0_icb_cmd_ready   (addac_icb_cmd_ready  ),
	.o0_icb_cmd_addr    (addac_icb_cmd_addr   ),
	.o0_icb_cmd_read    (addac_icb_cmd_read   ),
	.o0_icb_cmd_wdata   (addac_icb_cmd_wdata  ),
	.o0_icb_rsp_valid   (addac_icb_rsp_valid  ),
	.o0_icb_rsp_ready   (addac_icb_rsp_ready  ),
	.o0_icb_rsp_err     (addac_icb_rsp_err    ),
	.o0_icb_rsp_rdata   (addac_icb_rsp_rdata  ),

	.o1_icb_cmd_valid   (usb_cdc_icb_cmd_valid),
	.o1_icb_cmd_ready   (usb_cdc_icb_cmd_ready),
	.o1_icb_cmd_addr    (usb_cdc_icb_cmd_addr ),
	.o1_icb_cmd_read    (usb_cdc_icb_cmd_read ),
	.o1_icb_cmd_wdata   (usb_cdc_icb_cmd_wdata),
	.o1_icb_rsp_valid   (usb_cdc_icb_rsp_valid),
	.o1_icb_rsp_ready   (usb_cdc_icb_rsp_ready),
	.o1_icb_rsp_err     (usb_cdc_icb_rsp_err  ),
	.o1_icb_rsp_rdata   (usb_cdc_icb_rsp_rdata),

	.o2_icb_cmd_valid   (dma_cfg_icb_cmd_valid),
	.o2_icb_cmd_ready   (dma_cfg_icb_cmd_ready),
	.o2_icb_cmd_addr    (dma_cfg_icb_cmd_addr ),
	.o2_icb_cmd_read    (dma_cfg_icb_cmd_read ),
	.o2_icb_cmd_wdata   (dma_cfg_icb_cmd_wdata),
	.o2_icb_rsp_valid   (dma_cfg_icb_rsp_valid),
	.o2_icb_rsp_ready   (dma_cfg_icb_rsp_ready),
	.o2_icb_rsp_err     (dma_cfg_icb_rsp_err  ),
	.o2_icb_rsp_rdata   (dma_cfg_icb_rsp_rdata),

	.o3_icb_cmd_valid   (lcd_icb_cmd_valid    ),
	.o3_icb_cmd_ready   (lcd_icb_cmd_ready    ),
	.o3_icb_cmd_addr    (lcd_icb_cmd_addr     ),
	.o3_icb_cmd_read    (lcd_icb_cmd_read     ),
	.o3_icb_cmd_wdata   (lcd_icb_cmd_wdata    ),
	.o3_icb_rsp_valid   (lcd_icb_rsp_valid    ),
	.o3_icb_rsp_ready   (lcd_icb_rsp_ready    ),
	.o3_icb_rsp_err     (lcd_icb_rsp_err      ),
	.o3_icb_rsp_rdata   (lcd_icb_rsp_rdata    ),

	.o4_icb_cmd_valid   (),
	.o4_icb_cmd_ready   (),
	.o4_icb_cmd_addr    (),
	.o4_icb_cmd_read    (),
	.o4_icb_cmd_wdata   (),
	.o4_icb_rsp_valid   (),
	.o4_icb_rsp_ready   (),
	.o4_icb_rsp_err     (),
	.o4_icb_rsp_rdata   (),

	.o5_icb_cmd_valid   (),
	.o5_icb_cmd_ready   (),
	.o5_icb_cmd_addr    (),
	.o5_icb_cmd_read    (),
	.o5_icb_cmd_wdata   (),
	.o5_icb_rsp_valid   (),
	.o5_icb_rsp_ready   (),
	.o5_icb_rsp_err     (),
	.o5_icb_rsp_rdata   (),

	.o6_icb_cmd_valid   (),
	.o6_icb_cmd_ready   (),
	.o6_icb_cmd_addr    (),
	.o6_icb_cmd_read    (),
	.o6_icb_cmd_wdata   (),
	.o6_icb_rsp_valid   (),
	.o6_icb_rsp_ready   (),
	.o6_icb_rsp_err     (),
	.o6_icb_rsp_rdata   (),

	.o7_icb_cmd_valid   (),
	.o7_icb_cmd_ready   (),
	.o7_icb_cmd_addr    (),
	.o7_icb_cmd_read    (),
	.o7_icb_cmd_wdata   (),
	.o7_icb_rsp_valid   (),
	.o7_icb_rsp_ready   (),
	.o7_icb_rsp_err     (),
	.o7_icb_rsp_rdata   (),
//无用端口
	.o0_icb_rsp_excl_ok (1'b0),
	.o1_icb_rsp_excl_ok (1'b0),
	.o2_icb_rsp_excl_ok (1'b0),
	.o3_icb_rsp_excl_ok (1'b0),
	.o4_icb_rsp_excl_ok (1'b0),
	.o5_icb_rsp_excl_ok (1'b0),
	.o6_icb_rsp_excl_ok (1'b0),
	.o7_icb_rsp_excl_ok (1'b0),
	.o0_icb_cmd_wmask   (),
	.o1_icb_cmd_wmask   (),
	.o2_icb_cmd_wmask   (),
	.o3_icb_cmd_wmask   (),
	.o4_icb_cmd_wmask   (),
	.o5_icb_cmd_wmask   (),
	.o6_icb_cmd_wmask   (),
	.o7_icb_cmd_wmask   (),

	.clk                (hfextclk),
	.rst_n              (rst_n)
);
//Yduck

reg Yrst,Yrst_r;//高电平复位

always @(posedge lfextclk) begin
		Yrst<=~Yduck_start;
		Yrst_r<=Yrst;
end

Yduck_SoC #(
	.RAM_AW(7),
	.ROM_AW(7)
) u_Yduck_SoC (
	.clk      (lfextclk),
	.rst      (Yrst_r),
	.gpio_in  (gpio_in),
	.gpio_out (gpio_out),
	.T0_PWM_P (T0_PWM_P),
	.T0_PWM_N (T0_PWM_N),
	.T1_PWM_P (T1_PWM_P),
	.T1_PWM_N (T1_PWM_N),
	.intp_ext (0),
	.intp_s   (0)
);

endmodule  //app_p_top