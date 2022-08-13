//-------------------------------------------------------------------------------------------------------------------------------------
// a generic sync fifo
//-------------------------------------------------------------------------------------------------------------------------------------
module usb_fifo #(
    parameter   DSIZE = 8,
    parameter   ASIZE = 10
)(
    input  wire             rstn,
    input  wire             clk,
    input  wire             itvalid,//高电平数据有效
    output wire             itready,//高电平可写
    input  wire [DSIZE-1:0] itdata,//输入数据
    output reg              otvalid,//高电平数据有效
    input  wire             otready,//高电平数据读出
    output wire [DSIZE-1:0] otdata//读出数据
);

reg  [DSIZE-1:0] buffer [1<<ASIZE];  // may automatically synthesize to BRAM

logic [ASIZE:0] wptr, rptr;

wire full  = wptr == {~rptr[ASIZE], rptr[ASIZE-1:0]};
wire empty = wptr == rptr;

assign itready = rstn & ~full;

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        wptr <= '0;
    end else begin
        if(itvalid & ~full)
            wptr <= wptr + (1+ASIZE)'(1);
    end

always @ (posedge clk)
    if(itvalid & ~full)
        buffer[wptr[ASIZE-1:0]] <= itdata;

wire            rdready = ~otvalid | otready;
reg             rdack;
reg [DSIZE-1:0] rddata;
reg [DSIZE-1:0] keepdata;
assign otdata = rdack ? rddata : keepdata;

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        otvalid <= 1'b0;
        rdack <= 1'b0;
        rptr <= '0;
        keepdata <= '0;
    end else begin
        otvalid <= ~empty | ~rdready;
        rdack <= ~empty & rdready;
        if(~empty & rdready)
            rptr <= rptr + (1+ASIZE)'(1);
        if(rdack)
            keepdata <= rddata;
    end

always @ (posedge clk)
    rddata <= buffer[rptr[ASIZE-1:0]];

endmodule