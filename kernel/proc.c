#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

// 进程数组的定义，保存了所有进程
struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void wakeup1(struct proc *chan);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// initialize the proc table at boot time.
/*
为每个进程分配一个内核栈。它将每个栈映射在 KSTACK 生成的虚拟地址上，
这就为栈守护页(内核栈的边界)留下了空间。kvmmap 将对应的PTE加入到内核页表中，
然后调用 kvminithart 将内核页表重新加载到 satp 中，这样硬件就知道新的 PTE 了。
*/
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
// lab3-2
// 这里是将每个进程的内核栈都映射到同一个全局页表中
// 但是下面要在allocproc中将进程的内核栈都映射到进程自己的内核页中
// 所以这里注释了

      // Allocate a page for the process's kernel stack.
      // Map it high in memory, followed by an invalid
      // guard page.
      // char *pa = kalloc();
      // if(pa == 0)
      //   panic("kalloc");
      // uint64 va = KSTACK((int) (p - proc));
      // // 添加映射到全局的一个内核页表
      // kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
      // p->kstack = va;
  }
  // 设置stap寄存器，刷新TLB
  kvminithart(); 
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc; // cpu取出进程，如果是单cpu就是一个进程，没有进程就是null
  pop_off();
  return p;
}

int
allocpid() {
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
// 查找没有进内核页表的进程，也就是未使用的，如果有就映射内核栈
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  // lab3-2
  // 为用户分配的复制用户页表的成员
  // 出错要释放，模仿上面的页表分配。
  p->kpagetable = proc_kpagetable();
  if(0 == p->kpagetable)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // lab3-2
  // 这块是上面procinit()函数的内容
  // 作用是初始化锁，让后将每个进程的栈映射到全局的内核页表中
  // 本来设计的是只用一个全局的内核页表给所有进程使用  
  // 模仿上面的，将每个进程的的内核栈映射到内核页中，他们是映射到同一个物理地址的。
  // 分配物理内存作为内核栈映射的物理地址
  char *pa = kalloc();
  if(pa == 0)
    panic("kalloc");
  // 栈的虚拟地址位置，栈是内核态独有的
  // (((1L << (9 + 9 + 9 + 12 - 1)) - 4096) - (((int)(p - proc))+1)* 2*4096)
  // 前者是kstack的地址，就是MAXVA-trampoline的位置
  // 后者要跳过p之前的进程内核栈地址大小，也就是p-proc的距离*PGSIZ*2（2是因为kstack中间有Guard page）
  uint64 va = KSTACK((int)(p - proc));
  // 物理地址映射到栈的虚拟地址
  uvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  p->kstack = va;  // 添加到进程的内核栈中。


  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE; // 设置栈顶指针
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)              // 释放寄存器，PGSIZE大小
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)              // 释放页表
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;

  // lab3-2
  // 释放用户页表的内核栈，因为内核栈是在内核中才有的，清除物理内存不影响用户
  // 要先释放栈，不然页表释放了栈就找不到了。
  if(p->kstack)
    uvmunmap(p->kpagetable, p->kstack, 1, 1);
  p->kstack = 0;
  // 释放用户的内核页表
  if(p->kpagetable)
    proc_freekpagetable(p->kpagetable); // 不传p->sz,因为不清除物理内存
  p->kpagetable = 0;


  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
// 分配一个没有使用的页表
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  //取消TRAMPOLINE的映射 1是npages, 最后一个数字表示是否释放物理内存。
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  // 先释放物理内存，然后释放页表。
  // 会调用freewalk释放所有的页表。这里需要改写下，不释放物理内存页面
  // sz表示释放的物理内存的大小，如果不释放物理内存就设置为0
  uvmfree(pagetable, sz);
}

// lab3-2
// 模仿proc_freepagetable释放用户内核页表但是不释放物理内存
// 因为这里是在内核态使用了用户的内核页表，之后还要转换回用户态，。
// 如果把页表映射的物理内存释放了，用户态原本的页表就找不到映射了。
// 但是在内核态申请的内核栈的物理内存可以释放。因为这是内核态独有的
// 注意是内核栈的物理地址，不是内核栈映射的物理地址，因为内核栈映射的物理
// 地址和用户在内核中的内核页表是映射在同一个物理地址的。
// 内核页表释放了，也可以把整个页表都取消映射，包括I/O
void
proc_freekpagetable(pagetable_t kpagetable)
{
  uvmunmap(kpagetable, TRAMPOLINE, 1, 0);
  // uvmunmap(kpagetable, TRAPFRAME, 1, 0);

  // 对应vm.c的proc_kpagetable()取消映射,但是不能释放物理内存
  uvmunmap(kpagetable, UART0, 1, 0);
  uvmunmap(kpagetable, VIRTIO0, 1 , 0);
  uvmunmap(kpagetable, CLINT, 0x10000 / PGSIZE, 0);
  uvmunmap(kpagetable, PLIC, 0x400000 / PGSIZE, 0);
  // 这段是内核页表放text,data，freememory的地方。
  uvmunmap(kpagetable, KERNBASE, (PHYSTOP - KERNBASE) / PGSIZE, 0);

  // 会调用freewalk清除三级页表
  // 设置0在调用uvmunmap中不会将页表对应的物理内存清除。
  uvmfree(kpagetable, 0);

}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;  

  p = allocproc(); 
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // lab3-3 第一个进程的页表也要拷贝到用户内核页表中。
  if(ukvmcopy(p->pagetable, p->kpagetable, 0 , p->sz) < 0)
  {
      panic("ukvmcopy userinit");
      return;
  }

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
//sbrk 是 一 个 进 程 收 缩 或 增 长 内 存 的 系 统 调 用 。 该 系 统 调 用 由 函 数growproc实现
// growproc 调用 uvmalloc 或 uvmdealloc，取决于 n 是正数还是负数
// 由SYS_sbrk系统调用来调用这个函数
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
      // lab3-3
    // 同样kpagetable也要加减
    // 但是根据提示，用户进程页表最大不能超过PLIC
    // 所以加一个判断
    if(sz + n > PLIC)
      return -1;

    // uvmalloc通过 kalloc 分配物理内存，并使用 mappages 将 PTE 添加到用户页表中
    // 返回的是sz + n
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }

    // lab3-3
    // 增长完n的大小之后，要把增长的部分使用自定义的ukvmcopy()复制到用户的内核页表中
    // sz是新p->sz + n , 从p->sz 开始 复制到 p->sz + n
    ukvmcopy(p->pagetable, p->kpagetable, p->sz, sz);

    
  } else if(n < 0){
    // n < 0 表示缩减
    // 使用 walk 来查找 PTE 并使用 kfree 来释放它们所引用的物理内存。
    sz = uvmdealloc(p->pagetable, sz, sz + n);

    // lab3-3
    // 缩减之后也要进行在用户内核页表中缩减，但是不能直接使用uvdealloc,因为这个函数最终会释放物理内存
    // 而用户内核页表不能释放物理内存。
    // 所以这里模仿uvmdealloc取缩减页表项
    uint oldsz = sz;
    uint newsz = sz + n;
      if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
          int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
          // 这里在uvmdealloc是最后设置为1表示释放物理内存，重写就要设置为0
          // uvmunmap(p->kpagetable, PGROUNDUP(newsz), npages, 1);
          uvmunmap(p->kpagetable, PGROUNDUP(newsz), npages, 0);
      }
  }

  p->sz = sz;
  return 0; 
}

// Create a new process, copying the parent. 
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }

  np->sz = p->sz;

  // lab3-3
  // 复制子进程的用户页表到用户内核页表。
  if(ukvmcopy(np->pagetable, np->kpagetable, 0, np->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }

  np->parent = p;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.

  // 这里就是mask的初始值，每个系统调用都会fork一个进程执行，所以这个初值一定会设置。
  // np就是创建的孩子进程
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  np->state = RUNNABLE;
  // lab 2-2
  // 这里是自己加的部分，为了用trace追踪fork系统调用，设置mask
  // 系统调用都要经过fork, 继承父进程的mask
  // trace执行的时候已经是系统fork()出来的进程在运行了。
  // 所以trace的mask就是系统的mask
  np->mask = p->mask;

  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold p->lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    // this code uses pp->parent without holding pp->lock.
    // acquiring the lock first could cause a deadlock
    // if pp or a child of pp were also in exit()
    // and about to try to lock p.
    if(pp->parent == p){
      // pp->parent can't change between the check and the acquire()
      // because only the parent changes it, and we're the parent.
      acquire(&pp->lock);
      pp->parent = initproc;
      // we should wake up init here, but that would require
      // initproc->lock, which would be a deadlock, since we hold
      // the lock on one of init's children (pp). this is why
      // exit() always wakes init (before acquiring any locks).
      release(&pp->lock);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  // we might re-parent a child to init. we can't be precise about
  // waking up init, since we can't acquire its lock once we've
  // acquired any other proc lock. so wake up init whether that's
  // necessary or not. init may miss this wakeup, but that seems
  // harmless.
  acquire(&initproc->lock);
  wakeup1(initproc);
  release(&initproc->lock);

  // grab a copy of p->parent, to ensure that we unlock the same
  // parent we locked. in case our parent gives us away to init while
  // we're waiting for the parent lock. we may then race with an
  // exiting parent, but the result will be a harmless spurious wakeup
  // to a dead or wrong process; proc structs are never re-allocated
  // as anything else.
  acquire(&p->lock);
  struct proc *original_parent = p->parent;
  release(&p->lock);
  
  // we need the parent's lock in order to wake it up from wait().
  // the parent-then-child rule says we have to lock it first.
  acquire(&original_parent->lock);

  acquire(&p->lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup1(original_parent);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&original_parent->lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  // hold p->lock for the whole time to avoid lost
  // wakeups from a child's exit().
  acquire(&p->lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      // this code uses np->parent without holding np->lock.
      // acquiring the lock first would cause a deadlock,
      // since np might be an ancestor, and we already hold p->lock.
      if(np->parent == p){
        // np->parent can't change between the check and the acquire()
        // because only the parent changes it, and we're the parent.
        acquire(&np->lock);
        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&p->lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&p->lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&p->lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &p->lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  
  c->proc = 0;
  // 死循环找可运行的进程运行。
  for(;;){ 
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    
    int found = 0;
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;

        // lab3-2
        // swtch之后进程就已经执行完了。
        // 在执行之前需要把用户在内核中的内核表加载到stap寄存器
        // 在执行的时候就会加载这个用户的内核页表进行地址映射
        // 模仿kvminithart()就行
        w_satp(MAKE_SATP(p->kpagetable));
        sfence_vma(); // 刷新TLB使得上面有效。


      // # Context switch
      // #
      // #   void swtch(struct context *old, struct context *new);
      // # 
      // # Save current registers in old. Load from new.	
        swtch(&c->context, &p->context);

        // 进程运行完了
        // lab3-2
        // 没有进程运行的时候要切换回全局的内核页表。
        kvminithart();

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;

        found = 1;
      }
      release(&p->lock);
    }
#if !defined(LAB_FS)
    if(found == 0)
    {
      intr_on();
      asm volatile("wfi");
    }
#else
    ;
#endif

  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  if(lk != &p->lock){  //DOC: sleeplock0
    acquire(&p->lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  if(lk != &p->lock){
    release(&p->lock);
    acquire(lk);
  }
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == SLEEPING && p->chan == chan) {
      p->state = RUNNABLE;
    }
    release(&p->lock);
  }
}

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
  if(!holding(&p->lock))
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    p->state = RUNNABLE;
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}


// 统计当前非UNUSED的进程个数
uint64
nproc(void)
{
  // 定义临时进程结构体，用来循环查找proc[]的进程
  struct proc *p;
  // 记录个数
  uint64 num = 0;
  // 循环遍历进程数组,proc就是最上面的进程数组
  // 从起始地址到最后地址
  for(p = proc; p < &proc[NPROC]; ++p)
  {
    // 使用进程状态前要上锁，在上面的wakeup函数可以看出来
    acquire(&p->lock);
    if(p->state != UNUSED)
      ++num;    
    // 用完释放锁
    release(&p->lock);  
  }
  return num;
}