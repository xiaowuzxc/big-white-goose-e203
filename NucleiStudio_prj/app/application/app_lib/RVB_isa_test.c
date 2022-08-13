#include "RVB_isa_test.h"

void RVB_isa_test()
{
    printf("\r\n-----Test Bit-Manipulation ISA-extensions-----\r\n");
    uint32_t r1=0x11111111;
    uint32_t r2=0x8421;
    uint32_t dout;
    uint64_t clmul;
    __asm__ __volatile__ (
    "sh1add %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,sh1add=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "sh2add %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,sh2add=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "sh3add %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,sh3add=0x%x\r\n",r1,r2, dout);

    r2=0xfe7;

    __asm__ __volatile__ (
    "andn %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,andn=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "orn %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,orn=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "xnor %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,xnor=0x%x\r\n",r1,r2, dout);

    r1=0x0002380;
    __asm__ __volatile__ (
    "clz %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,clz=%d\r\n",r1, dout);

    __asm__ __volatile__ (
    "ctz %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,ctz=%d\r\n",r1, dout);

    __asm__ __volatile__ (
    "cpop %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,cpop=0x%x\r\n",r1, dout);

    r2=0xf1fafcf8;

    __asm__ __volatile__ (
    "max %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=%u,rd2=%u,max=%u\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "min %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=%u,rd2=%u,min=%u\r\n",r1,r2, dout);

    r1=(int32_t)-9;
    r2=(int32_t)6;

    __asm__ __volatile__ (
    "maxu %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=%d,rd2=%d,maxu=%d\r\n",(int32_t)r1,(int32_t)r2, dout);

    __asm__ __volatile__ (
    "minu %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=%d,rd2=%d,minu=%d\r\n",(int32_t)r1,(int32_t)r2, dout);

    r1=0xfab1828a;

    __asm__ __volatile__ (
    "sext.b %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,sext.b=0x%x\r\n",r1, dout);

    __asm__ __volatile__ (
    "sext.h %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,sext.h=0x%x\r\n",r1, dout);

    __asm__ __volatile__ (
    "zext.h %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,zext.h=0x%x\r\n",r1, dout);

    r1=0x12480f37;
    r2=30;

    __asm__ __volatile__ (
    "rol %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=%d,rol=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "ror %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=%d,ror=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "rori %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"i"(4));
    printf("rd1=0x%x,rd2=%d,rori=0x%x\r\n",r1,4, dout);

    r1=0x0021003f;
    __asm__ __volatile__ (
    "orc.b %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,orc.b=0x%x\r\n",r1, dout);

    __asm__ __volatile__ (
    "rev8 %[rd], %[rs1]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1));
    printf("rd1=0x%x,rev8=0x%x\r\n",r1, dout);

    r1=0xd5fec45d;
    r2=0xf15a458b;

    __asm__ __volatile__ (
    "clmul %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,clmul=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "clmulh %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,clmulh=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "clmulr %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,clmulr=0x%x\r\n",r1,r2, dout);

    r1=0xfa;
    r2=4;
    __asm__ __volatile__ (
    "bclr %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,bclr=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "bclri %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"i"(1));
    printf("rd1=0x%x,rd2=0x%x,bclri=0x%x\r\n",r1,1, dout);

    __asm__ __volatile__ (
    "bext %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,bext=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "bexti %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"i"(2));
    printf("rd1=0x%x,rd2=0x%x,bexti=0x%x\r\n",r1,2, dout);

    r2=5;
    __asm__ __volatile__ (
    "binv %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,binv=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "binvi %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"i"(3));
    printf("rd1=0x%x,rd2=0x%x,binvi=0x%x\r\n",r1,3, dout);

    r2=8;
    __asm__ __volatile__ (
    "bset %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"r"(r2));
    printf("rd1=0x%x,rd2=0x%x,bset=0x%x\r\n",r1,r2, dout);

    __asm__ __volatile__ (
    "bseti %[rd], %[rs1], %[rs2]"
    :[rd]"=r"(dout)
    :[rs1]"r"(r1),[rs2]"i"(9));
    printf("rd1=0x%x,rd2=0x%x,bseti=0x%x\r\n",r1,9, dout);

    printf("-----Test Bit-Manipulation ISA-extensions end-----\r\n");
}


void Show_misa()
{
	printf("\r\n-----CICC1233 E203v2 ISA-----\r\n");
    CSR_MISA_Type misa_bits = (CSR_MISA_Type) __RV_CSR_READ(CSR_MISA);
    static char misa_chars[30];
    uint8_t index = 0;
    if (misa_bits.b.mxl == 1) {
        misa_chars[index++] = '3';
        misa_chars[index++] = '2';
    } else if (misa_bits.b.mxl == 2) {
        misa_chars[index++] = '6';
        misa_chars[index++] = '4';
    } else if (misa_bits.b.mxl == 3) {
        misa_chars[index++] = '1';
        misa_chars[index++] = '2';
        misa_chars[index++] = '8';
    }
    if (misa_bits.b.i) {
        misa_chars[index++] = 'I';
    }
    if (misa_bits.b.m) {
        misa_chars[index++] = 'M';
    }
    if (misa_bits.b.a) {
        misa_chars[index++] = 'A';
    }
    if (misa_bits.b.b) {
        misa_chars[index++] = 'B';
    }
    if (misa_bits.b.c) {
        misa_chars[index++] = 'C';
    }
    if (misa_bits.b.e) {
        misa_chars[index++] = 'E';
    }
    if (misa_bits.b.f) {
        misa_chars[index++] = 'F';
    }
    if (misa_bits.b.d) {
        misa_chars[index++] = 'D';
    }
    if (misa_bits.b.q) {
        misa_chars[index++] = 'Q';
    }
    if (misa_bits.b.h) {
        misa_chars[index++] = 'H';
    }
    if (misa_bits.b.j) {
        misa_chars[index++] = 'J';
    }
    if (misa_bits.b.l) {
        misa_chars[index++] = 'L';
    }
    if (misa_bits.b.n) {
        misa_chars[index++] = 'N';
    }
    if (misa_bits.b.s) {
        misa_chars[index++] = 'S';
    }
    if (misa_bits.b.p) {
        misa_chars[index++] = 'P';
    }
    if (misa_bits.b.t) {
        misa_chars[index++] = 'T';
    }
    if (misa_bits.b.u) {
        misa_chars[index++] = 'U';
    }
    if (misa_bits.b.x) {
        misa_chars[index++] = 'X';
    }

    misa_chars[index++] = '\0';

    printf("MISA: RV%s\r\n", misa_chars);
}
