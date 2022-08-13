`include "e203_defines.v"
module lcd1602_top (
	input	wire				clk,
	input	wire				rst_n,

	input	wire				lcd_icb_cmd_valid,
	output	wire				lcd_icb_cmd_ready,
	input	wire[`E203_ADDR_SIZE-1:0]lcd_icb_cmd_addr,
	input	wire				lcd_icb_cmd_read,
	input  	wire[`E203_XLEN-1:0]lcd_icb_cmd_wdata,

	output	reg					lcd_icb_rsp_valid,
	input	wire				lcd_icb_rsp_ready,
	output	wire				lcd_icb_rsp_err,
	output	reg [`E203_XLEN-1:0]lcd_icb_rsp_rdata,
	//-----LCD1602-----
	inout   wire                [7:0]DB,
	output  wire                RS,//高电平数据，低电平指令
	output  wire                RW,//高电平读取，低电平写入
	output  wire                EN//高电平读出，上升沿写入

);

reg  [4:0]addr;//显示存储器地址
reg  [7:0]din; //显示存储器数据输入
wire [7:0]dout;//显示存储器数据输出
reg  we;       //显示存储器写入使能，高电平有效


wire [4:0] offset;
assign offset=lcd_icb_cmd_addr[6:2];

//总线交互
//握手
wire cfg_icb_cmd_hsked=lcd_icb_cmd_valid & lcd_icb_cmd_ready;
//lcd_icb_cmd_ready
assign lcd_icb_cmd_ready=(lcd_icb_cmd_valid & ~lcd_icb_cmd_read) | (lcd_icb_cmd_valid & lcd_icb_cmd_read & ~lcd_icb_rsp_valid);
//lcd_icb_rsp_err
assign lcd_icb_rsp_err=1'b0;
//lcd_icb_rsp_valid
always @(posedge clk or negedge rst_n)
if (~rst_n)
	lcd_icb_rsp_valid<=1'b0;
else begin
	if (cfg_icb_cmd_hsked)
		lcd_icb_rsp_valid<=1'b1;
	else if ((lcd_icb_rsp_valid)&&(lcd_icb_rsp_ready))
		lcd_icb_rsp_valid<=1'b0;
	else
		lcd_icb_rsp_valid<=lcd_icb_rsp_valid;
end
//r
always @(posedge clk or negedge rst_n)
if (~rst_n)
	lcd_icb_rsp_rdata<=32'b0;
else begin
	if (lcd_icb_rsp_valid)
		lcd_icb_rsp_rdata<=lcd_icb_rsp_rdata;
	else 
		if ((cfg_icb_cmd_hsked)&&(lcd_icb_cmd_read))
            lcd_icb_rsp_rdata<={24'h0,dout};
		else
	  		lcd_icb_rsp_rdata<=32'b0;
    end
//w
always @(*) begin
    if (!rst_n) begin
        addr=0;
        din =0;
        we  =0;     
        end
    else begin
        if((cfg_icb_cmd_hsked)&&(~lcd_icb_cmd_read)) begin //w
            addr=offset;
            din=lcd_icb_cmd_wdata[7:0];
            we =1;
        end
        else begin 
            if ((cfg_icb_cmd_hsked)&&(lcd_icb_cmd_read)) begin//r
                addr=offset;
                din=0;
                we =0;
                end
            else begin//idle
                addr=0;
                din=0;
                we =0;
                end
            end
        end
    end

lcd1602 #(
    .CLK_F(16_000_000)
) inst_lcd1602 (
    .clk   (clk),
    .rst_n (rst_n),
    .addr  (addr),
    .din   (din),
    .dout  (dout),
    .we    (we),
    .DB    (DB),
    .RS    (RS),
    .RW    (RW),
    .EN    (EN)
);

endmodule