#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

/*
 * lab5-1
 * 对sbrk实行lazy分配，也就是在进行sbrk的时候
 *  只改变sz大小，不实际分配物理内存，直到出现page fault的时候
 *  进行处理分配
 * */
uint64
sys_sbrk(void)
{
  int addr;
  int n;

  // 执行系统调用函数sbrk(n)
  // 取出a0寄存器中的n参数
  if(argint(0, &n) < 0)
    return -1;
  // 取出sz
  addr = myproc()->sz;

    //lab 5-3
    // 如果需要分配的数量超过了MAXVA也就是堆大小，也不能减去n小于0。否则就直接返回原大小，分配失败
    if(addr + n >= MAXVA || addr + n <= 0)
        return addr;

  // lab5-1这里就是改的地方，不需要分配，直接改大小就行。
  struct proc *p = myproc();
  p->sz += n;
//  if(growproc(n) < 0)
//    return -1;

    // lab5-3
    // 如果传入的n是负数，那就需要直接释放空间
    if(n < 0)
    {
        uvmdealloc(p->pagetable, addr, p->sz);
    }
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
