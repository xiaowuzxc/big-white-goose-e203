module io
#(
	parameter DW = 16,
	parameter AW = 12 
)(
	input			clk, //时钟
	input 			rst,  //同步复位，高电平有效
	input [DW-1:0]	din, //数据输入
	input [AW-1:0]	addr, //地址输入
	input			we, //高电平写使能
	output reg[DW-1:0] dout, //数据输出
	input wire [DW-1:0]gpio_in,//输入端口
	output wire [DW-1:0]gpio_out//输出端口
);

localparam GPI_A = 12'h000;
localparam GPO_A = 12'h001;
reg [DW-1:0]gpio_in_reg;
reg [DW-1:0]gpio_out_reg;
always @(posedge clk) begin
	gpio_in_reg <= gpio_in;
end
assign gpio_out=gpio_out_reg;

always @(posedge clk) begin
if(rst) begin
	gpio_out_reg <= 16'h0;
	dout <= 16'h0;
end	
else
	if(we)
		case (addr)
			GPO_A: gpio_out_reg <= din;
			default: ;
		endcase
	else
		case (addr)
			GPI_A: dout <= gpio_in_reg;
			default: dout <= 0;
		endcase
end

endmodule