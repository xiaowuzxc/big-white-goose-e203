//dma_core
`include "e203_defines.v"
module dma_core(
	input 		clk,
	input 		rst_n,
	input 		en,
	input 		start,
	input [31:0]sou_in,
	input [31:0]des_in,
	input [15:0]num_in,
	
	output reg 	done,
	output 		dma_busy,
	
	//DMA访问存储ICB总线 DMA=master
	output reg						dma_icb_cmd_valid,
	input							dma_icb_cmd_ready,
	output reg [`E203_ADDR_SIZE-1:0]dma_icb_cmd_addr,
	output reg						dma_icb_cmd_read,
	output reg [`E203_XLEN-1:0]		dma_icb_cmd_wdata,
	output reg [`E203_XLEN/8-1:0]	dma_icb_cmd_wmask,
	//
	input							dma_icb_rsp_valid,
	output							dma_icb_rsp_ready,
	input							dma_icb_rsp_err,
	input [`E203_XLEN-1:0]			dma_icb_rsp_rdata
	////
);
// statemachine
parameter [1:0] ST_IDLE = 2'b00;
parameter [1:0] ST_READ = 2'b01;
parameter [1:0] ST_WRITE = 2'b10;
reg [1:0] state,next_state;

//fifo信号
reg w_en,r_en;
reg [31:0] fifo_data_i;
wire [31:0] fifo_data_o;
wire empty,full,overflow;

//dma信号
reg [31:0] sou;
reg [31:0] des;
reg [15:0] num;
reg [15:0] cnt_rd,cnt_wr;
wire dma_icb_cmd_hsked;
assign dma_icb_cmd_hsked=(dma_icb_cmd_valid)&(dma_icb_cmd_ready);
wire dma_icb_rsp_hsked;
assign dma_icb_rsp_hsked=(dma_icb_rsp_valid)&(dma_icb_rsp_ready);
reg [15:0] cnt_rsp_rd;//cnt_rd在cmd握手时增，cnt_rsp_rd在rsp握手时增
//

//状态机切换
always @(posedge clk or negedge rst_n)
	if (!rst_n)
		state<=ST_IDLE;
	else
		state<=next_state;
always @(*)
	case (state)
		ST_IDLE:
		if ((start)&&(en))
			next_state=ST_READ;
		else
			next_state=ST_IDLE;
	ST_READ://从sram1读，写入fifo
		if (en)
			if (cnt_rsp_rd==num)
				next_state=ST_WRITE;
			else
				next_state=ST_READ;
		else
			next_state=ST_IDLE;
	ST_WRITE://从fifo读，写入sram2
		if (en)
			if (cnt_wr==num)
				next_state=ST_IDLE;
			else
				next_state=ST_WRITE;
		else
			next_state=ST_IDLE;
	endcase

//dma信号
//done
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	done<=0;
else
	if ((state==ST_WRITE)&&(cnt_wr==num-1)&&(dma_icb_rsp_hsked))
		done<=1;
	else
		done<=0;
//dma_busy
assign dma_busy=(state==ST_READ)|(state==ST_WRITE);
//sou
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	sou<=0;
else
	if ((state==ST_IDLE)&&(start))
		sou<=sou_in;
	else
		sou<=sou;
//des
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	des<=0;
else
	if ((state==ST_IDLE)&&(start))
		des<=des_in;
	else
		des<=des;
//num
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	num<=0;
else
	if ((state==ST_IDLE)&&(start))
		num<=num_in;
	else
		num<=num;
//cnt_rd
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	cnt_rd<=0;
else
	if ((state==ST_IDLE)&&(start==1))
		cnt_rd<=0;
	else if ((state==ST_READ)&&(dma_icb_cmd_hsked))
		cnt_rd<=cnt_rd+1;
	else
		cnt_rd<=cnt_rd;
//cnt_rsp_rd
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	cnt_rsp_rd<=0;
else
	if ((state==ST_IDLE)&&(start==1))
		cnt_rsp_rd<=0;
	else if ((state==ST_READ)&&(dma_icb_rsp_hsked))
		cnt_rsp_rd<=cnt_rsp_rd+1;
	else
		cnt_rsp_rd<=cnt_rsp_rd;
//cnt_wr
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	cnt_wr<=0;
else
	if ((state==ST_IDLE)&&(start==1))
		cnt_wr<=0;
	else if ((state==ST_WRITE)&&(dma_icb_cmd_hsked))
		cnt_wr<=cnt_wr+1;
	else
		cnt_wr<=cnt_wr;

//fifo信号
//w_en
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	w_en<=0;
else
	if ((state==ST_READ)&&(dma_icb_rsp_hsked))
		w_en<=1;
	else
		w_en<=0;
//r_en
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	r_en<=0;
else
	if (r_en==1) 
		r_en<=0;
	else if ((state==ST_WRITE)&&(!dma_icb_cmd_valid))
		r_en<=1;
	else
		r_en<=0;
//fifo_data_i
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	fifo_data_i<=0;
else
	if ((state==ST_READ)&&(dma_icb_rsp_hsked))
		fifo_data_i<=dma_icb_rsp_rdata;
	else
		fifo_data_i<=0;

//fifo例化
dma_fifo u_fifo(.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en),
			.data_w(fifo_data_i),
			.r_en(r_en),
			
			.data_r(fifo_data_o),
			.empty(empty),
			.full(full),
			.overflow(overflow)
			);


//icb接口总线时序的控制
//dma_icb_cmd_valid
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	dma_icb_cmd_valid<=0;
else 
	if (dma_icb_cmd_hsked)
		dma_icb_cmd_valid<=0;
	else if ((state==ST_READ)&&(cnt_rd<=num-1))
		dma_icb_cmd_valid<=1;
	else if ((state==ST_WRITE)&&(r_en))
		dma_icb_cmd_valid<=1;
		else 
		dma_icb_cmd_valid<=dma_icb_cmd_valid;
//dma_icb_cmd_addr
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	dma_icb_cmd_addr<=0;
else
	if (state==ST_READ)
		dma_icb_cmd_addr<=sou+cnt_rd*4;
	else if ((state==ST_WRITE)&&(r_en))
		dma_icb_cmd_addr<=des+cnt_wr*4;
	else
		dma_icb_cmd_addr<=dma_icb_cmd_addr;
//dma_icb_cmd_read
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	dma_icb_cmd_read<=0;
else
	if (state==ST_READ)
		dma_icb_cmd_read<=1;
	else if ((state==ST_WRITE)&&(r_en))
		dma_icb_cmd_read<=0;
	else
		dma_icb_cmd_read<=0;
//dma_icb_cmd_wdata
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	dma_icb_cmd_wdata<=0;
else
	if ((state==ST_WRITE)&&(r_en))
		dma_icb_cmd_wdata<=fifo_data_o;
	else
		dma_icb_cmd_wdata<=dma_icb_cmd_wdata;
//dma_icb_cmd_wmask
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	dma_icb_cmd_wmask<=0;
else
	if ((state==ST_WRITE)&&(r_en))
		dma_icb_cmd_wmask<=4'b1111;
	else
		dma_icb_cmd_wmask<=dma_icb_cmd_wmask;
//dma_icb_rsp_ready
assign dma_icb_rsp_ready=dma_icb_rsp_valid;
endmodule