module dma_fifo(
   input wire clk,
   input wire rst_n,
   input wire w_en,
   input wire[31:0]data_w,
   input wire r_en,
   output reg[31:0]data_r,
   output wire empty,
   output wire full,
   output reg overflow
   );

  reg [31:0]memory[0:511];
  reg [9:0]rd=0,wr=0;
  
  always @(posedge clk or negedge rst_n)//rd
   begin
        if (!rst_n)
           rd<=0;
        else 
           if ((!empty)&&(r_en)&&(!w_en))
              rd<=rd+1;
   end   
  always @(posedge clk or negedge rst_n)//wr
   begin
        if (!rst_n)
           wr<=0;
        else 
           if ((!full)&&(w_en)&&(!r_en))
              wr<=wr+1;
   end  
  always @(*)//data_r
   begin
     if ((!empty)&&(r_en)&&(!w_en)) 
       data_r=memory[rd[8:0]];
   end
  always @(posedge clk)//memory
   begin
        if ((rst_n)&&(!full)&&(w_en)&&(!r_en)) 
           memory[wr]<=data_w;
   end 
  assign empty=(~rst_n)|((rst_n)&(rd==wr));//empty
  assign full=(rst_n)&((wr-rd)==10'b1000000000);//full

  always @(posedge clk or negedge rst_n)//overflow
   begin
        if (!rst_n) overflow<=0;
        else if ((full)&&(w_en)) overflow<=1;
        else if ((!empty)&&(r_en)&&(!w_en)) overflow<=0;  
   end 
endmodule