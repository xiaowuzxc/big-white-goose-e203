#include "dma.h"

void dma_init();
void dma_ctrl(uint32_t addr1, uint32_t addr2, uint32_t num);//addr1----->addr2
uint32_t dma_check();
uint32_t dma_test();


//初始化
void dma_init()
{
  printf("dma init\r\n"); 
  DMA_REGISTER(DMA_REG_CTR) = 0x000000c0;
}


//配置寄存器
void dma_ctrl(uint32_t addr1, uint32_t addr2, uint32_t num)
{
	//s addr
	while ((DMA_REGISTER(DMA_REG_SR)&0x00000080)!=0x00000080);//确定写入配置
	printf("move addr1 : %x to addr2:%x \r\n",addr1,addr2);
	printf("number of data: %d \r\n",num);
	DMA_REGISTER(DMA_REG_SOU_ADDR)=addr1;//源地址
	while ((DMA_REGISTER(DMA_REG_SR)&0x00000080)!=0x00000080);//确定写入配置
	printf("SOU_ADDR completed\r\n");
	//d addr
	DMA_REGISTER(DMA_REG_DES_ADDR)=addr2;//目的地址
	while ((DMA_REGISTER(DMA_REG_SR)&0x00000080)!=0x00000080);//确定写入配置
	printf("DES_ADDR completed\r\n");
	DMA_REGISTER(DMA_REG_NUM)=num;//数据长度
	while ((DMA_REGISTER(DMA_REG_SR)&0x00000080)!=0x00000080);//确定写入配置
	printf("NUM completed\r\n");
	printf("configuration completed!\r\n");
	//START
	DMA_REGISTER(DMA_REG_CR)=0x00000080;//发送start标志
	while ((DMA_REGISTER(DMA_REG_SR)&0x00000080)!=0x00000080);//确定写入配置
	printf("Now start moving!\r\n");
}
//查询状态，1工作中，0空闲
uint32_t dma_check()
{
	return ((DMA_REGISTER(DMA_REG_SR)&0x00000040)!=0x00000000);
}
//dma功能测试，返回1表示正常
uint32_t dma_test()
{
	printf("\r\n-----Test DMA move string-----\r\n");
	uint32_t str_chk=1;
	uint32_t i;
	__volatile__ char s_string[32]="DMA DEBUG CICC1233:<@,.!$&*()>";
	s_string[31]=0x00;
	__volatile__ char d_string[32];
	dma_init();
	printf("source str=\r\n%s\r\n",s_string);
	dma_ctrl((uint32_t)(&s_string[0]),(uint32_t)(&d_string[0]),8);
	while (dma_check());//等待搬运结束
	printf("dma moved str=\r\n%s\r\n",d_string);
	for(i=0;i<32;i++)
	{
		if(s_string[i]!=d_string[i])
			str_chk=0;
	}
	printf("-----Test DMA move string end-----\r\n");
	return str_chk;
}
