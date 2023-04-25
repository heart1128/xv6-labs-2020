#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void
trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
// 用户空间trap处理路径 trampoline.S(16:uservec) -> usertrap()
// 上面进行处理之后，来到这里确定trap的原因，并且处理它
void
usertrap(void)
{
  int which_dev = 0;

  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  // cpu从用户空间进入内核时，改变stvec也就是加载处理trap的地址到pc
  // 也就是由kernelvec处理trap，kernelvec是内核空间trap处理代码的位置，不是用户空间处理代码的位置。
  w_stvec((uint64)kernelvec);

  // 根据cpu当前的核的编号，也就是tp寄存器，去找当前的进程
  struct proc *p = myproc();
  
  // save user program counter.保存用户pc
  // 保存sepc寄存器。在之前已经把用户进入trap的代码段的地址保存在这里，
  // 可能在内核执行时，可能切换到另一个进程，进入程序空间，这时候sepc就会被覆盖，所以要保存在trapframe中
  p->trapframe->epc = r_sepc();
  // 上面保存了用户pc，因为在usertrap中可能有一个进程切换，导致sepc被覆盖

  // 如果trap是系统调用,syscall处理
  // scause寄存器保存了中断的原因
  if(r_scause() == 8){
    // system call

    // 先检查进程是否已经被杀死
    if(p->killed)
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    // 系统调用会留下指向ecall指令的程序指针4字节，所以用户pc要+4
    p->trapframe->epc += 4;

    // an interrupt will change sstatus &c registers,
    // so don't enable until done with those registers.
    // 系统调用的时候可以中断，这里打开中断，前面进入中断会自动关中断防止破坏保护现场的过程。
    intr_on();
    // 进行系统调用。也就是找调用号进行sys_xxx()函数进行处理
    syscall();
  } else if((which_dev = devintr()) != 0){ // 如果是设备中断，devintr进行处理
  } else {  // 否则就是异常，内核直接杀死故障进程
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    p->killed = 1;
  }

  // 再次判断进程有没有被杀掉，不能恢复一个被杀掉的的进程。
  if(p->killed)
    exit(-1);

    /*
   * lab 4-3
   *
   *  时钟中断会进入usertrap中
   *  首先判断interval==0，如果是0表示终止时钟调用，
   *  再判断passedticks是不是等于interval，如果相等表示时间间隔到了，要执行handler()
   *
   *  因为在trampoline.S的server中已经完成了页表的切换，现在的页表是内核页表，而
   *  handler是用户空间下的函数虚拟地址，不能直接调用，所以利用p->trapfram->epc设置为p->handler，epc寄存器是保存用户PC的寄存器
   *  这样在返回用户空间的时候，程序计数器被设置为handler的地址，就会执行函数。
   *
   */
    // start lab 4-3 test0

    // 判断是设备的时钟中断
    if(which_dev == 2)
    {
        // 增加passed ticks
        ++p->passedticks;
        // 判断不为0和时间到
        if(p->interval != 0 && p->passedticks == p->interval)
        {
            // lab 4-3 test1/test2
            // 进行修改寄存器之前保存
            // trapframe分配了一个页的大小(4096)，trapframe只用了288，所以后续还有空间可以使用。
            // 后续的空间可以存副本，就不用浪费一个页的大小存放副本了
            // 这里加上超过288，小于4096 - 288就行
            p->trapframecopy = p->trapframe + 512;
            // 进行字节流的复制
            memmove(p->trapframecopy, p->trapframe, sizeof(struct trapframe));
            // end test1/test2

            p->passedticks = 0;
            p->trapframe->epc = p->handler; // 存到用户空间的PC
        }
    }

    // end lab 4-3

  // give up the CPU if this is a timer interrupt.
  // 2是cpu的时钟中断
  if(which_dev == 2)
    yield();

  usertrapret();
}

//
// return to user space
// 设置RISC-V控制寄存器，为以后用户空间trap做准备
//
void
usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  // 先关闭中断，因为要恢复现场，不能被破坏。
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  // 修改stvec为trampoline代码，里面的最后代码会执行sret指令重新打开中断，回到用户空间。
  w_stvec(TRAMPOLINE + (uservec - trampoline));

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  // 准备uservec所依赖的trapframe字段
  // 恢复现场
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap; // 存储usertrap的指针，下次还能跳转到这个函数处理
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  /*
   * 接下来我们要设置SSTATUS寄存器，这是一个控制寄存器。这个寄存器的SPP bit位控制了sret指令的行为，
   * 该bit为0表示下次执行sret的时候，我们想要返回user mode而不是supervisor mode。这个寄存器的SPIE bit位控制了，
   * 在执行完sret之后，是否打开中断。因为我们在返回到用户空间之后，我们的确希望打开中断，所以这里将SPIE bit位设置为1。
   * 修改完这些bit位之后，我们会把新的值写回到SSTATUS寄存器。
   * */
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  // 将sepc设置为先前在usertrap()保存的用户程序计数器
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  // satp寄存器切换回用户页表
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  // 在用户页表和内核页表中映射的trampoline页上调用userret,因为userret中的汇编代码会切换页表。
  // 用户页表和内核页表的同一个虚拟地址上映射着同一个trampoline
  // fn就是对应trampoline.S的返回代码段
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
// 来着内核空间的trap处理函数，在保护程序现场之后被调用。
// kerneltrap是为两种类型的陷阱准备的：设备中断和异常
void 
kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();
  
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");
    // 调用devintr() 处理设备中断
  if((which_dev = devintr()) == 0){
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  // 如果由于计时器中断而调用了kerneltrap，并且进程的内核线程正在运行（
  // 而不是调度程序线程），kerneltrap调用yield让出CPU
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  // 内核trap结束，因为yield可能破坏保存的sepc和在sstatus中保存的之前的模式，所以要还原
  w_sepc(sepc);
  w_sstatus(sstatus);
  // 之后返回到kernelvec（kernel/kernelvec.S:48）,恢复现场栈堆
}

void
clockintr()
{
  acquire(&tickslock);
  ticks++;
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
     (scause & 0xff) == 9){
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if(cpuid() == 0){
      clockintr();
    }
    
    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
  }
}

