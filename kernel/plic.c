#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

//
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    // PLIC和外设一样也占用了一个I/O地址（0xC000_0000）。
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;   // 使能UART中断，设置为1生效。就是设置了PLIC会接受哪些中断，进而将中断路由到CPU
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1; // 设置接受IO磁盘的中断
}

void
plicinithart(void)
{
  int hart = cpuid(); // 找到所属的cpuId
  
  // set uart's enable bit for this hart's S-mode.
  // 设置对UART和IO磁盘中断感兴趣
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);

  // set this hart's S-mode priority threshold to 0.
  // 忽略中断的优先级，将优先级设置为0
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
}

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
  int hart = cpuid();
  int irq = *(uint32*)PLIC_SCLAIM(hart);
  return irq;
}

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
  int hart = cpuid();
  *(uint32*)PLIC_SCLAIM(hart) = irq;
}
