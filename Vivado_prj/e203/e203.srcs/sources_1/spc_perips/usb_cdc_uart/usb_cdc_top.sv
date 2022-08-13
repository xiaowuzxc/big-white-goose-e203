`include "e203_defines.v"

module usb_cdc_top (
	// clock and reset
	input  wire        clk,    //全局主时钟16M 
	inout  wire        usbclk, //USB时钟60M
	input  wire        rst_n,       // 低电平复位，高电平正常工作
	// USB signals
	output wire        usb_dp_pull,  // connect to USB D+ by an 1.5k resistor
	inout              usb_dp,       // connect to USB D+
	inout              usb_dn,        // connect to USB D-
	// ICB bus cmd
	input	wire						usb_cdc_icb_cmd_valid,
	output	wire						usb_cdc_icb_cmd_ready,
	input	wire[`E203_ADDR_SIZE-1:0]	usb_cdc_icb_cmd_addr,
	input	wire						usb_cdc_icb_cmd_read,
	input  	wire[`E203_XLEN-1:0]		usb_cdc_icb_cmd_wdata,
	// rsp
	output	reg							usb_cdc_icb_rsp_valid,
	input	wire						usb_cdc_icb_rsp_ready,
	output	wire						usb_cdc_icb_rsp_err,
	output	wire[`E203_XLEN-1:0]		usb_cdc_icb_rsp_rdata
);
/*
offset 功能
0x00:状态查询,[0]接收区有东西为1,[1]发送区未满为1
0x04:接收缓冲区[7:0]只读
0x08:发送缓冲器[7:0]只写
*/
/*-------------USB 60M 时钟域ICB总线-----------------*/


/*-------------USB接收，连接usb_cdc_serial-----------------*/
wire [ 7:0] h2dv_data ;
wire        h2dv_valid;

/*-------------USB 数据收发，连接内部逻辑-----------------*/
reg  [ 7:0] send_data ;//in 发送数据
reg         send_en;//数据有效，高有效
reg         send_valid;//in 数据写入usb core有效，高有效
wire        send_ready;//out高电平可写，低电平写满
wire        send_full_n;//低电平写满，反压

wire [ 7:0] recv_data ;//out接收数据
reg         recv_valid;//当前读出数据有效
reg         recv_en;//in 高电平读出本数据
wire        recv_ready;//out数据有效，高有效

reg [`E203_XLEN-1:0]r_usb_cdc_icb_rsp_rdata;//ICB数据输出选择
//registers
reg [31:0] USB_STA;//状态查询,[0]接收区有东西为1,[1]发送区未满为1
reg [31:0] USB_REV;//接收缓冲区[7:0]只读
reg [31:0] USB_SED;//发送缓冲器[7:0]只写

wire [7:0] offset;//地址偏移量
assign offset=usb_cdc_icb_cmd_addr[7:0];
//总线交互
//握手
wire cfg_icb_cmd_hsked=usb_cdc_icb_cmd_valid & usb_cdc_icb_cmd_ready;
//usb_cdc_icb_cmd_ready
assign usb_cdc_icb_cmd_ready=(usb_cdc_icb_cmd_valid & ~usb_cdc_icb_cmd_read) | (usb_cdc_icb_cmd_valid & usb_cdc_icb_cmd_read & ~usb_cdc_icb_rsp_valid);
//usb_cdc_icb_rsp_err
assign usb_cdc_icb_rsp_err=1'b0;
//usb_cdc_icb_rsp_valid
always @(posedge clk or negedge rst_n)
if (~rst_n)
	usb_cdc_icb_rsp_valid<=1'b0;
else begin
	if (cfg_icb_cmd_hsked)
		usb_cdc_icb_rsp_valid<=1'b1;
	else if ((usb_cdc_icb_rsp_valid)&&(usb_cdc_icb_rsp_ready))
		usb_cdc_icb_rsp_valid<=1'b0;
	else
		usb_cdc_icb_rsp_valid<=usb_cdc_icb_rsp_valid;
end
//r
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	r_usb_cdc_icb_rsp_rdata<=32'b0;
	recv_valid<=0;
	end
else begin
	if (usb_cdc_icb_rsp_valid) begin
		r_usb_cdc_icb_rsp_rdata<=r_usb_cdc_icb_rsp_rdata;
		recv_valid<=recv_valid;
		end
	else 
		if ((cfg_icb_cmd_hsked)&&(usb_cdc_icb_cmd_read))
			case (offset)
				8'h00: r_usb_cdc_icb_rsp_rdata<=USB_STA;
				8'h04: begin 
					r_usb_cdc_icb_rsp_rdata<=32'hffaabbcc;
					recv_valid<=1;
					end
				8'h08: r_usb_cdc_icb_rsp_rdata<=32'h1f2c3b9a;
				default: r_usb_cdc_icb_rsp_rdata<=32'b0;
			endcase
		else begin
	  		r_usb_cdc_icb_rsp_rdata<=32'b0;
			recv_valid<=0;
			end
	end
assign usb_cdc_icb_rsp_rdata=recv_valid?USB_REV:r_usb_cdc_icb_rsp_rdata;
//w
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	send_data <=0;
	send_valid<=0;
end
else begin
	if((cfg_icb_cmd_hsked)&&(~usb_cdc_icb_cmd_read)&&(offset==8'h08)) begin 
		send_data <=usb_cdc_icb_cmd_wdata[7:0];
		send_valid<=1;
	end
	else begin 
		send_data <=0;
		send_valid<=0;
	end
end

//USB
always @(*) begin
	USB_STA[0]=~recv_ready;
	USB_STA[1]=~send_ready;
	USB_STA[31:2]=30'h0;

	USB_REV[7:0]=recv_data;
	USB_REV[31:8]=0;
end

assign recv_en=((cfg_icb_cmd_hsked)&&(usb_cdc_icb_cmd_read)&&(offset==8'h04))?1:0;
// usb60 -> clk
dc_fifo #(
	.DSIZE(8),
	.ASIZE(9)
) dc_fifo_rx (
	.rst_n   (rst_n),
	.wclk    (usbclk),
	.wdata   (h2dv_data ),
	.w_en    (h2dv_valid),
	.w_full  (),
	.rclk    (clk),
	.rdata   (recv_data),
	.r_empty (recv_ready),
	.r_en    (recv_en)
);
// clk -> usb60
wire send_empty;
wire [7:0]send_data_u;
always @(posedge usbclk or negedge rst_n) begin
	if(~rst_n)
		send_en<=0;
	else
		send_en<= ~send_empty && send_full_n;
end
dc_fifo #(
	.DSIZE(8),
	.ASIZE(8)
) dc_fifo_tx (
	.rst_n   (rst_n),
	.wclk    (clk),
	.wdata   (send_data),
	.w_en    (send_valid),
	.w_full  (send_ready),
	.rclk    (usbclk),
	.rdata   (send_data_u),
	.r_empty (send_empty),
	.r_en    (~send_empty && send_full_n)
);




usb_cdc_serial usb_cdc_serial_i (
	.rstn            (  rst_n ),
	.clk             ( usbclk            ),
	// USB signals
	.usb_dp_pull     ( usb_dp_pull         ),
	.usb_dp          ( usb_dp              ),
	.usb_dn          ( usb_dn              ),
	// CDC receive data (host-to-device)
	.recv_data       ( h2dv_data           ),   // received data byte
	.recv_valid      ( h2dv_valid          ),   // when recv_valid=1 pulses, a data byte is received on recv_data
	// CDC send data (device-to-host)
	.send_data       ( send_data_u           ),   // connect recv_data to send_data to achieve loopback 
	.send_valid      ( send_en          ),   // connect recv_valid to send_valid to achieve loopback 
	.send_ready      ( send_full_n   )    // ignore send_ready, ignore the situation that the send buffer is full (send_ready=0)
);

//sim

always @(posedge clk or negedge rst_n) begin
	if (send_valid & rst_n)
		$write( "%c", send_data);
end

endmodule
