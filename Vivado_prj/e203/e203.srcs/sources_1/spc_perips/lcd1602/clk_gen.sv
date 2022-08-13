module clk_gen #(
	parameter CLK_F = 50_000_000
)(
	input logic clk,    // Clock
	input logic rst_n,  // Asynchronous reset active low
	output logic clk_en // Clock Enable
);
localparam clk_div=CLK_F/1_000_000;
logic [9:0]DIV_CNT;
always @(posedge clk) begin
	if(~rst_n) begin
		DIV_CNT<=0;
		end
	else begin
		if(DIV_CNT==clk_div) begin//分频器溢出
			DIV_CNT<=0;
			clk_en<=1'b1;//输出使能信号
			end
		else begin//分频器计数+1
			DIV_CNT<=DIV_CNT+1;//计数器+1
			clk_en<=1'b0;
			end
		end
	end
endmodule