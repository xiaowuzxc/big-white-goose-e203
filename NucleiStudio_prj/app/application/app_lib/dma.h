#ifndef _HBIRD_DMA_H
#define _HBIRD_DMA_H
#include <stdio.h>
#include "hbirdv2.h"
//DMA func
void dma_init();
void dma_ctrl(uint32_t addr1, uint32_t addr2, uint32_t num);//addr1----->addr2
uint32_t dma_check();
uint32_t dma_test();
//DMA base
#define DMA_BASE 0xf0000200
//DMA offset
#define DMA_REG_SOU_ADDR        0X20
#define DMA_REG_DES_ADDR        0X24
#define DMA_REG_NUM             0X28
#define DMA_REG_CTR             0X00
#define DMA_REG_CR              0X04
#define DMA_REG_SR              0X08
//DMA reg
#define DMA_CTR_EN              (1 << 7)
#define DMA_CTR_IE              (1 << 6)
#define DMA_CR_STA              (1 << 7)
#define DMA_CR_STO              (1 << 6)
#define DMA_CR_RD               (1 << 5)
#define DMA_CR_WR               (1 << 4)
#define DMA_CR_ACK              (1 << 3)
#define DMA_CR_IACK             (1 << 0)
#define DMA_SR_RXACK            (1 << 7)
#define DMA_SR_BUSY             (1 << 6)
#define DMA_SR_AL               (1 << 5)
#define DMA_SR_TIP              (1 << 1)
#define DMA_SR_IF               (1 << 0)
//MAP
#define DMA_REGISTER(addr) (*((volatile uint32_t *)(DMA_BASE+(addr))))
#endif /* _HBIRD_DMA_H */
