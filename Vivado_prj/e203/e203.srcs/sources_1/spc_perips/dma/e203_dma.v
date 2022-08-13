`include "e203_defines.v"
module e203_dma (
	input	wire				clk,
	input	wire				rst_n,
	output	reg					dma_irq,

	//DMA访问存储ICB总线 DMA=master
	output	wire					dma_icb_cmd_valid,
	input	wire					dma_icb_cmd_ready,
	output  wire[`E203_ADDR_SIZE-1:0]dma_icb_cmd_addr,
	output	wire					dma_icb_cmd_read,
	output  wire[`E203_XLEN-1:0]	dma_icb_cmd_wdata,
	output  wire[`E203_XLEN/8-1:0]	dma_icb_cmd_wmask,
	//
	input	wire					dma_icb_rsp_valid,
	output	wire					dma_icb_rsp_ready,
	input	wire					dma_icb_rsp_err,
	input 	wire[`E203_XLEN-1:0]	dma_icb_rsp_rdata,
	////

	//DMA configuration DMA=slave
	input	wire				dma_cfg_icb_cmd_valid,
	output	wire				dma_cfg_icb_cmd_ready,
	input	wire[`E203_ADDR_SIZE-1:0]dma_cfg_icb_cmd_addr,
	input	wire				dma_cfg_icb_cmd_read,
	input  	wire[`E203_XLEN-1:0]dma_cfg_icb_cmd_wdata,
	//
	output	reg					dma_cfg_icb_rsp_valid,
	input	wire				dma_cfg_icb_rsp_ready,
	output	wire				dma_cfg_icb_rsp_err,
	output	reg [`E203_XLEN-1:0]dma_cfg_icb_rsp_rdata
	//// 

);


//握手信号
wire cfg_icb_cmd_hsked=dma_cfg_icb_cmd_valid & dma_cfg_icb_cmd_ready;

//registers
reg [31:0] SOU_ADDR;
reg [31:0] DES_ADDR;
reg [15:0] NUM;
wire [7:0] SR;
reg [7:0] CR;
reg [7:0] CTR;

//CTR信号
wire core_en;
wire ien;

//CR信号
wire sta;
wire iack;

//SR信号
reg cfg_done;	// 配置完成
wire dma_busy;	// bus busy (start signal detected)
wire done;		// done signal: command completed, clear command register
reg  irq_flag;	// interrupt pending flag

//cfg接口总线时序的编写
//dma_cfg_icb_cmd_ready
assign dma_cfg_icb_cmd_ready=(dma_cfg_icb_cmd_valid & ~dma_cfg_icb_cmd_read)|(dma_cfg_icb_cmd_valid & dma_cfg_icb_cmd_read & ~dma_cfg_icb_rsp_valid);
//dma_cfg_icb_rsp_err
assign dma_cfg_icb_rsp_err=1'b0;

wire [7:0] offset;
assign offset=dma_cfg_icb_cmd_addr[7:0];

//dma_cfg_icb_rsp_rdata
always @(posedge clk or negedge rst_n)
if (!rst_n)
  dma_cfg_icb_rsp_rdata<=32'b0;
else
  begin
	if (dma_cfg_icb_rsp_valid)
	  dma_cfg_icb_rsp_rdata<=dma_cfg_icb_rsp_rdata;
	else if ((cfg_icb_cmd_hsked)&&(dma_cfg_icb_cmd_read))
	  case (offset)
		8'h20: dma_cfg_icb_rsp_rdata<=SOU_ADDR;
		8'h24: dma_cfg_icb_rsp_rdata<=DES_ADDR;
		8'h28: begin 
				 dma_cfg_icb_rsp_rdata[15:0]<=NUM;
				 dma_cfg_icb_rsp_rdata[31:16]<=16'b0;
			   end
		8'h08: begin
				 dma_cfg_icb_rsp_rdata[7:0]<=SR;
				 dma_cfg_icb_rsp_rdata[31:8]<=24'b0;
			   end
		8'h00: begin
				 dma_cfg_icb_rsp_rdata[7:0]<=CTR;
				 dma_cfg_icb_rsp_rdata[31:8]<=24'b0;
			   end
		default: dma_cfg_icb_rsp_rdata<=32'b0;
	  endcase
	else
	  dma_cfg_icb_rsp_rdata<=32'b0;
  end

//dma_cfg_icb_rsp_valid
always @(posedge clk or negedge rst_n)
if (!rst_n)
  dma_cfg_icb_rsp_valid<=1'b0;
else
  begin
	if (cfg_icb_cmd_hsked)
	  dma_cfg_icb_rsp_valid<=1'b1;
	else if ((dma_cfg_icb_rsp_valid)&&(dma_cfg_icb_rsp_ready))
	  dma_cfg_icb_rsp_valid<=1'b0;
	else
	  dma_cfg_icb_rsp_valid<=dma_cfg_icb_rsp_valid;
  end

//
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	SOU_ADDR<=32'b0;
	DES_ADDR<=32'b0;
	NUM<=16'b0;
	CTR<=8'b0;
end
else begin
	if((cfg_icb_cmd_hsked)&&(~dma_cfg_icb_cmd_read)) begin 
		case (offset)
			8'h20:SOU_ADDR<=dma_cfg_icb_cmd_wdata;
			8'h24:DES_ADDR<=dma_cfg_icb_cmd_wdata;
			8'h28:NUM<=dma_cfg_icb_cmd_wdata[15:0];
			8'h00:CTR<=dma_cfg_icb_cmd_wdata[7:0];
			default :;
		endcase
	end
	else begin 
		SOU_ADDR<=SOU_ADDR;
		DES_ADDR<=DES_ADDR;
		NUM<=NUM;
		CTR<=CTR;
	end
end

always @(posedge clk or negedge rst_n)
if (!rst_n)
  CR<=8'b0;
else if ((cfg_icb_cmd_hsked)&&(~dma_cfg_icb_cmd_read))
  begin
	if ((offset==8'h04)&&(core_en))
	  CR<=dma_cfg_icb_cmd_wdata[7:0];
	else
	  CR<=CR;
  end
else
  begin
	if (done)
	  CR[7]<=1'b0;		// clear command bits when done
	CR[6:1]<=2'b0;		// reserved bits
	CR[0]<=1'b0;			 // clear IRQ_ACK bit
  end

// decode command register
assign sta=CR[7];
assign iack=CR[0];

// decode control register
assign core_en=CTR[7];
assign ien=CTR[6];

// 例化core
dma_core u_dma_core(.clk(clk),
				  .rst_n(rst_n),
				  .en(core_en),
				  .start(sta),
				  .sou_in(SOU_ADDR),
				  .des_in(DES_ADDR),
				  .num_in(NUM),
				  .dma_icb_cmd_ready(dma_icb_cmd_ready),
				  .dma_icb_rsp_valid(dma_icb_rsp_valid),
				  .dma_icb_rsp_err(dma_icb_rsp_err),
				  .dma_icb_rsp_rdata(dma_icb_rsp_rdata),
	
				  .done(done),
				  .dma_busy(dma_busy),
				  .dma_icb_cmd_valid(dma_icb_cmd_valid),
				  .dma_icb_cmd_addr(dma_icb_cmd_addr),
				  .dma_icb_cmd_read(dma_icb_cmd_read),
				  .dma_icb_cmd_wdata(dma_icb_cmd_wdata),
				  .dma_icb_cmd_wmask(dma_icb_cmd_wmask),
				  .dma_icb_rsp_ready(dma_icb_rsp_ready)
				  );

//irq_flag
always @(posedge clk or negedge rst_n)
if (!rst_n)
  irq_flag<=1'b0;
else
  irq_flag<=(done | irq_flag) & ~iack; // interrupt request flag is always generated

//cfg_done
always @(posedge clk or negedge rst_n)
if (!rst_n)
  cfg_done<=1'b0;
else
  begin
	if ((cfg_icb_cmd_hsked)&&(~dma_cfg_icb_cmd_read))
	  if ((offset==8'h20)||(offset==8'h24)||(offset==8'h28)||(offset==8'h00)||(offset==8'h04))
		cfg_done<=1'b1;
	  else
		cfg_done<=1'b0;
	else
	  cfg_done<=cfg_done;
  end

// assign status register bits
assign SR[7]   = cfg_done;
assign SR[6]   = dma_busy;
assign SR[5:2] = 4'b0; // reserved
assign SR[1]   = done;
assign SR[0]   = irq_flag;

//中断
//dma_irq
always @(posedge clk or negedge rst_n)
if (!rst_n)
  dma_irq<=1'b0;
else
  dma_irq<=irq_flag & ien;
endmodule
