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

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
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


// trace函数，追踪系统调用，这个函数在syscall.c中被syscall函数调用
uint64
sys_trace(void)
{
  int mask;
  // argint调用argraw取出对应序号的寄存器的值，由第二参数的&int带回。
  // 因为RISCV的C规范是把所有的返回值都放在a0寄存器
  if(argint(0, &mask) < 0)
    return -1;

  // 把寄存器里的mask传给cpu中取出的进程的mask,proc结构体是自己修改过的加上了mask成员
  /*exit:
 li a7, SYS_trace
 ecall  -> syscall() -> sys_trace
 ret  -> 将调用trace函数时的参数保存到a0，所以上面从a0取出的是trace(num)里面的num
 */
  myproc()->mask = mask;
  return 0;
}

// 要使用sysinfo结构体，加入头
#include "sysinfo.h"
// 记录非UNUSED进程和剩余内存量的函数
uint64
sys_sysinfo(void)
{
  // 因为syscall是内核态，所以需要用copyout()在内核中复制一个sysinfo结构体到用户空空间
  // copyout的用法可以看kernel/sysfile.c中的sys_fstat()中调用的filestat函数

  uint64 addr;
  struct sysinfo info;
  struct proc *p = myproc();
  
  // 在寄存器a0中取出用户的虚拟地址。
  // 系统调用的时候会把函数的参数放入a0
  // 也就是在user/sysinfo.c中使用sysinfo(&info)传入的info，要把内核空间的info复制到用户的info
  if(argaddr(0, &addr) < 0)
    return -1;
  
  // 测试下系统调用是不是会把函数的参数放入a0-a6的寄存器上，这里多放了一个参数int
  // 结果证明是这样的，第一个参数放在a0,以此类推，直到a6用完，就用内存。
  // 需要在user/sysinfo.c调用sysinfo()加入三个参数。user/user.h声明也要改
  // int test1, test2;
  // if(argint(1, &test1) < 0)
  //   return -1;
  // else
  //   printf("test  : %d\n", test1);
  
  //  if(argint(2, &test2) < 0)
  //   return -1;
  // else
  //   printf("test  : %d\n", test2);
  
  // 这两个函数在defs.h中声明了
  info.freemem = free_mem();
  info.nproc = nproc();

  // info是在syscall内核空间的数据，要复制到用户空间addr上
  if(copyout(p->pagetable, addr, (char*)&info, sizeof(info)) < 0)
    return -1;
  return 0;
}