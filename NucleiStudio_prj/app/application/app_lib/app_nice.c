#include "app_nice.h"
//.insn r opcode, func3, func7, rd, rs1, rs2
uint32_t nice_cordic(uint32_t phase)//cordic
{
	uint32_t cossin;
	__asm__ __volatile__ (
		".insn r 0x7b, 6, 2, %[rd], %[rs1], x0"
    	:[rd]"=r"(cossin)
    	:[rs1]"r"(phase)
	);

	return cossin;
}

uint32_t nice_cnn()//cnn
{
	uint32_t cnn_result;
	__asm__ __volatile__ (
		".insn r 0x7b, 4, 4, %[rd], x0, x0"
    	:[rd]"=r"(cnn_result)
	);

	return cnn_result;
}

void nice_test()
{
	float sin,cos;
	uint32_t cossin;
	printf("\r\n-----Test CNN and Cordic of NICE-----\r\n");
	cossin=nice_cordic(1*65535/4);//1/4 pi
	cos=(float)((int16_t)(cossin>>16))/32768;
	sin=(float)((int16_t)(cossin & 0x0000ffff))/32768;
	printf("phase=1/4 pi,cos=%f,sin=%f\r\n",cos,sin);

	cossin=nice_cordic(0);//0 pi
	cos=(float)((int16_t)(cossin>>16))/32768;
	sin=(float)((int16_t)(cossin & 0x0000ffff))/32768;
	printf("phase=0 pi,cos=%f,sin=%f\r\n",cos,sin);

	cossin=nice_cordic(5*65535/8);//5/8 pi
	cos=(float)((int16_t)(cossin>>16))/32768;
	sin=(float)((int16_t)(cossin & 0x0000ffff))/32768;
	printf("phase=5/8 pi,cos=%f,sin=%f\r\n",cos,sin);

	cossin=nice_cordic(5*65535/6);//5/6 pi
	cos=(float)((int16_t)(cossin>>16))/32768;
	sin=(float)((int16_t)(cossin & 0x0000ffff))/32768;
	printf("phase=5/6 pi,cos=%f,sin=%f\r\n",cos,sin);

	cossin=nice_cordic(3*65535/4);//3/4 pi
	cos=(float)((int16_t)(cossin>>16))/32768;
	sin=(float)((int16_t)(cossin & 0x0000ffff))/32768;
	printf("phase=3/4 pi,cos=%f,sin=%f\r\n",cos,sin);

	cossin=nice_cnn();
	printf("read NN nice=%d\r\n",cossin);

	printf("-----Test CNN and Cordic of NICE end-----\r\n");
}
