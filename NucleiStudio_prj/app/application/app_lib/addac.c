#include "addac.h"
#include "dma.h"
#include "Yduck_bin.h"
/* [0]:AD DA模式切换, 0:AD, 1:DA
   [1]:启动转换使能，手动清零
   [2]:转换状态查询，高电平可读
   [9:8]:ADC通道选择，输出需翻转*/
//模式选择
//参数0：ADC模式，参数1：DAC模式
void addac_model_sel(uint32_t model_sel)
{
    uint32_t tmp;
    tmp = ADDA_REGISTER(ADDA_CTR);
    if(model_sel)//DAC
        ADDA_REGISTER(ADDA_CTR) = tmp | 0x00000001;
    else//ADC
        ADDA_REGISTER(ADDA_CTR) = tmp & 0xfffffffe;
}

//ADC通道选择，ch3为2.5v基准
void addac_ch_sel(uint32_t ch_sel)
{
    uint32_t tmp;
    tmp = ADDA_REGISTER(ADDA_CTR) & 0x000000ff;
    ADDA_REGISTER(ADDA_CTR) = tmp+(ch_sel<<8);
}

//ADC启动转换
void addac_start()
{
    ADDA_REGISTER(ADDA_CTR) = ADDA_REGISTER(ADDA_CTR) | 0x00000002;
    ADDA_REGISTER(ADDA_CTR) = ADDA_REGISTER(ADDA_CTR) & 0xfffffffd;
}

//ADC查看状态，4完成
uint32_t addac_state()
{
    return (ADDA_REGISTER(ADDA_CTR) & 0x00000004);
}

//ADC执行转换
uint32_t addac_get_value()
{
    addac_start();
    if(ADDA_REGISTER(ADDA_CTR) & 0x00000001)
    {
        printf("addac in DAC model, get ADC value");
        return 0xffffffff;
    }
    else
    {
        while(!addac_state());
        return (ADDA_REGISTER(ADDA_DAT) & 0x000000ff);
    }
}
/* ADC输出[7:0]
   DAC输出[15:8] */
//DAC输出
void addac_dac_out(uint32_t dac_value)
{
    ADDA_REGISTER(ADDA_DAT) = dac_value<<8;
}

//ctr等于0，关闭Yduck
//ctr非0，启动Yduck
void Yduck_CTR(uint32_t ctr)
{
	if(ctr)
		ADDA_REGISTER(YDUCK)=0x01;
	else
		ADDA_REGISTER(YDUCK)=0;
}

//为Yduck编程，写入Yduck_bin.h
void Yduck_prog()
{
	printf("\r\n-----Program Yduck core-----\r\n");
	dma_ctrl((uint32_t)(&ydk[0]),0x90010000,10);
	while (dma_check());//等待搬运结束
	printf("Program Yduck core end\r\n");
}
