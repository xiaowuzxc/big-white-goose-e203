`include "e203_defines.v" 
module addac (
	// clock and reset
	input  wire        clk,    //全局主时钟16M 
	input  wire        rst_n,       // 低电平复位，高电平正常工作
	// ADDAC signals
	input cmp,// 比较器输出
	output wire [7:0]DAC_inf,// DAC逐次逼近反馈
    output wire [1:0]addach,//ADC通道选择，输出需翻转
    //Yduck启动控制
	output wire      Yduck_start,
	// ICB bus cmd
	input	wire						addac_icb_cmd_valid,
	output	wire						addac_icb_cmd_ready,
	input	wire[`E203_ADDR_SIZE-1:0]	addac_icb_cmd_addr,
	input	wire						addac_icb_cmd_read,
	input  	wire[`E203_XLEN-1:0]		addac_icb_cmd_wdata,
	// rsp
	output	reg							addac_icb_rsp_valid,
	input	wire						addac_icb_rsp_ready,
	output	wire						addac_icb_rsp_err,
	output	reg [`E203_XLEN-1:0]		addac_icb_rsp_rdata
);
//org_data[15:0]温度，补码，分辨率0.0625，低4位是小数
/*----------------------------------------------------*/
/*                     ICB交互                        */
/*----------------------------------------------------*/
//registers
/* [0]:AD DA模式切换, 0:AD, 1:DA
   [1]:启动转换使能，手动清零
   [2]:转换状态查询，高电平可读
   [10:8]:ADC通道选择，输出需翻转*/
reg addasel;//[0]:AD DA模式切换, 0:AD, 1:DA
reg start;//[1]:启动转换使能，手动清零
reg den;//[2]:转换状态查询，高电平可读
reg [1:0]chsel;//[9:8]:ADC通道选择，输出需翻转
assign addach=~chsel;
//REG1 AD DA数据寄存器0x04
reg [7:0] Dout;//ADC输出[7:0]
reg [7:0] DACo;//DAC输出[15:8]

reg Yduck_CTR;//大黄鸭处理器控制
assign Yduck_start=Yduck_CTR;

wire [7:0] offset;
assign offset=addac_icb_cmd_addr[7:0];

//总线交互
//握手
wire cfg_icb_cmd_hsked=addac_icb_cmd_valid & addac_icb_cmd_ready;
//addac_icb_cmd_ready
assign addac_icb_cmd_ready=(addac_icb_cmd_valid & ~addac_icb_cmd_read) | (addac_icb_cmd_valid & addac_icb_cmd_read & ~addac_icb_rsp_valid);
//addac_icb_rsp_err
assign addac_icb_rsp_err=1'b0;
//addac_icb_rsp_valid
always @(posedge clk or negedge rst_n)
if (~rst_n)
	addac_icb_rsp_valid<=1'b0;
else begin
	if (cfg_icb_cmd_hsked)
		addac_icb_rsp_valid<=1'b1;
	else if ((addac_icb_rsp_valid)&&(addac_icb_rsp_ready))
		addac_icb_rsp_valid<=1'b0;
	else
		addac_icb_rsp_valid<=addac_icb_rsp_valid;
end
//r
always @(posedge clk or negedge rst_n)
if (~rst_n)
	addac_icb_rsp_rdata<=32'b0;
else begin
	if (addac_icb_rsp_valid)
		addac_icb_rsp_rdata<=addac_icb_rsp_rdata;
	else 
		if ((cfg_icb_cmd_hsked)&&(addac_icb_cmd_read))
			case (offset)
			8'h00: addac_icb_rsp_rdata<={22'h0,chsel,5'h0,den,start,addasel};
			8'h04: addac_icb_rsp_rdata<={16'h0,DACo,Dout};
			8'h08: addac_icb_rsp_rdata<={31'h0,Yduck_CTR};
			default: addac_icb_rsp_rdata<=32'b0;
			endcase
		else
	  		addac_icb_rsp_rdata<=32'b0;
  end
//w
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    chsel<=0;
    start<=0;
    addasel<=0;
    DACo<=0;
	Yduck_CTR<=0;
end
else begin
	if((cfg_icb_cmd_hsked)&&(~addac_icb_cmd_read)) begin 
		case (offset)
			8'h00:{chsel,start,addasel}<={addac_icb_cmd_wdata[9:8],addac_icb_cmd_wdata[1:0]};
			8'h04:DACo<=addac_icb_cmd_wdata[15:8];
			8'h08:Yduck_CTR<= addac_icb_cmd_wdata[0];
			default :;
		endcase
	end
	else begin 
//????
	end
end
/*----------------------------------------------------*/
/*                     AD/DAC                         */
/*----------------------------------------------------*/
/*
module SAR_ADC #(
	parameter ADC_WIDTH = 8 //ADC位宽，单位bit，和DAC匹配，最大不超过255
)(
	input clk,// 时钟
	input rst_n,// 低电平复位，异步复位同步释放
	input cmp,// 比较器输出
	input start,// 启动信号，上升沿触发
	output reg [ADC_WIDTH-1:0]DACF,// DAC逐次逼近反馈
	output reg eoc,// 转换结束，高电平脉冲
	output reg den,// 结果有效，高电平有效
	output reg [ADC_WIDTH-1:0]Dout// 结果输出
);*/
//*************************************************
// 寄存器、连线、状态机等定义
//*************************************************
//****reg***
reg [7:0]DACF;
assign DAC_inf=addasel?DACo:DACF;
reg start_r;//启动信号打一拍
reg ADCI_en;//高电平转换进行中
reg [7:0]adc_cnt;//逐次逼近计数器
//***wire***
wire start_w;//高电平一周期表示检测到上升沿
localparam ADC_WIDTH=8;
//*************************************************
// 启动信号打一拍
//*************************************************
always @(posedge clk or negedge rst_n) 
begin
	if(~rst_n)
		start_r <= 1'b0;
	else 
		start_r <= start;
end
assign start_w = start==1'b1 && start_r==1'b0;

//*************************************************
// 转换状态机
//*************************************************
//***状态机参数***
reg [1:0]nst;//下一状态
reg [1:0]cst;//当前状态

localparam IDLE =2'd0;//空闲状态
localparam ADCI =2'd1;//转换中

//***状态转移***
always @(posedge clk or negedge rst_n) 
begin
	if(~rst_n)
		cst <= IDLE;
	else
		cst <= nst;
end

//***下一状态切换***
always @(*) begin
	case (cst)
		IDLE: 
			if(start_w)//等待上升沿
				nst = ADCI;
			else
				nst = IDLE;
		ADCI:
			if(ADCI_en)
				nst = ADCI;
			else
				nst = IDLE;
		default: nst = IDLE;
	endcase
end

//***状态机输出***
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) 
	begin
		adc_cnt <= 0;
		DACF <= 0;
		Dout <= 0;
		den <= 1'b0;
		ADCI_en <= 1'b0;
	end 
	else 
	begin
		case (cst)
			IDLE: 
				begin
					DACF <= {1'b1,{7{1'b0}}};
					adc_cnt <= 0;
					if(start_w)
						ADCI_en <= 1'b1;//进入转换
				end
			ADCI:
				begin
					den <= 1'b0;
					Dout <= Dout;
					adc_cnt <= adc_cnt+1;
					case (adc_cnt)
						ADC_WIDTH-1:
							begin//转换最后一位，结束后输出，回归IDLE状态
								den <= 1'b1;//结果有效
								Dout <= {DACF[ADC_WIDTH-1:1],cmp};//结果缓存
							end
					
						default: 
							begin
								DACF[ADC_WIDTH-2-adc_cnt] <= 1'b1;
								DACF[ADC_WIDTH-1-adc_cnt] <= cmp;
								if(adc_cnt==ADC_WIDTH-2)
									ADCI_en <= 1'b0;//提前一周期转换结束，因为状态转移需要一个周期
							end
					endcase
				end

			default: 
				begin
					DACF <= {1'b1,{7{1'b0}}};
					adc_cnt <= 0;
					if(start_w)
						ADCI_en <= 1'b1;//进入转换
				end
		endcase
	end
end


    
endmodule