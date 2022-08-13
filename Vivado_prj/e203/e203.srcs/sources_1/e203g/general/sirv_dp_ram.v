// 双端口RAM
module sirv_dp_ram #(
	parameter DP = 512,
	parameter DW = 32,
	parameter MW = 4,
	parameter AW = 32 
)(
	input             clk, 
//ICB
	input  [DW-1  :0] dina, 
	input  [AW-1  :0] addra,
	input             csa,
	input             wea,
	input  [MW-1:0]   wema,
	output [DW-1:0]   douta,
//Yduck
	input  [AW-1  :0] addrb,
	output [DW-1:0]   doutb
);
wire lfextclk;
reg [DW-1:0] mem_r [0:DP-1];
reg [AW-1:0] addra_r,addrb_r;
wire [MW-1:0] wen;
wire ren;

assign ren = csa & (~wea);
assign wen = ({MW{csa & wea}} & wema);


always @(posedge clk) begin
	addra_r <= addra;
end

always @(posedge lfextclk) begin
	addrb_r <= addrb;
end

genvar i;

generate
	for (i = 0; i < MW; i = i+1) begin :mem
		if((8*i+8) > DW ) begin: last
			always @(posedge clk) begin
				if (wen[i]) begin
					mem_r[addra][DW-1:8*i] <= dina[DW-1:8*i];
					end
				end
			end
		else begin: non_last
			always @(posedge clk) begin
				if (wen[i]) begin
					mem_r[addra][8*i+7:8*i] <= dina[8*i+7:8*i];
					end
				end
			end
		end
endgenerate

wire [DW-1:0] dout_prea,dout_preb;
assign dout_prea = mem_r[addra_r];
assign dout_preb = mem_r[addrb_r];
assign douta = dout_prea;
assign doutb = dout_preb;


 
endmodule
