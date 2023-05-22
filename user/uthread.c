#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// lab7-1 添加上下文结构体，模仿kernel/proc.h的context结构体
// Saved registers for kernel context switches.
struct ucontext{ // 调度器线程切换的时候保存的寄存器值。
    uint64 ra;
    uint64 sp;

    // callee-saved
    uint64 s0;
    uint64 s1;
    uint64 s2;
    uint64 s3;
    uint64 s4;
    uint64 s5;
    uint64 s6;
    uint64 s7;
    uint64 s8;
    uint64 s9;
    uint64 s10;
    uint64 s11;
};


/* Possible states of a thread: */
#define FREE        0x0
#define RUNNING     0x1
#define RUNNABLE    0x2

#define STACK_SIZE  8192
#define MAX_THREAD  4


struct thread {
  char       stack[STACK_SIZE]; /* the thread's stack */
  int        state;             /* FREE, RUNNING, RUNNABLE */
  // lab7-1 添加上文切换保存寄存器的结构体字段
  struct ucontext context;
};
struct thread all_thread[MAX_THREAD];
struct thread *current_thread;
extern void thread_switch(uint64, uint64);
              
void 
thread_init(void)
{
  // main() is thread 0, which will make the first invocation to
  // thread_schedule().  it needs a stack so that the first thread_switch() can
  // save thread 0's state.  thread_schedule() won't run the main thread ever
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.
  current_thread = &all_thread[0];
  current_thread->state = RUNNING;
}

void 
thread_schedule(void)
{
  struct thread *t, *next_thread;

  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  for(int i = 0; i < MAX_THREAD; i++){
      // all_thread是数组
    if(t >= all_thread + MAX_THREAD)
      t = all_thread;
    if(t->state == RUNNABLE) {
        // 将下一个线程设置为t的物理位置的下一个线程，上面的current_thread + 1就是这样设置的。
        // 所以线程t成了下一个线程，current_thread变成了t
      next_thread = t;
      break;
    }
    t = t + 1;
  }

  // 没有可执行的线程，也就是没有状态为RUNNABLE的线程
  if (next_thread == 0) {
    printf("thread_schedule: no runnable threads\n");
    exit(-1);
  }
  // 当前线程不是上面设置的下一个线程，说明找到了可以切换的线程，这里进行状态的改变和线程的切换。
  if (current_thread != next_thread) {         /* switch threads?  */
    next_thread->state = RUNNING;
    t = current_thread;
    current_thread = next_thread;
    /* YOUR CODE HERE
     * Invoke thread_switch to switch from t to next_thread:
     * thread_switch(??, ??);
     */
    // lab7-1 切换进程
    // 需要调用thread_switch函数，并且进行一些传参。
    // 传入上下文寄存器，进行保存和切换。
    // 目标是t进程 -> next_thread进程的切换。
    // 此时的t是下一个线程，current_thread是当前的进程，进行线程切换。
    thread_switch((uint64)&t->context, (uint64)&current_thread->context);
  } else
    next_thread = 0;
}

void 
thread_create(void (*func)())
{
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
    if (t->state == FREE) break;
  }
  t->state = RUNNABLE;
  // YOUR CODE HERE
  // lab 7-1
  // 在线程创建中是对线程做一些初始化，根据课程中讲的，需要定义ra和sp
  // ra确保进程切换能够返回到切换的进行的地址，
  // sp初始化栈，确保能够在自己的栈中运行线程
  t->context.ra = (uint64)func; // 传入的就是ra函数，使用线程也就是传入回调函数，进行线程执行。
  t->context.sp = (uint64)t->stack + STACK_SIZE; // 设置栈指定，初始化栈。
}

void 
thread_yield(void)
{
    // 当前线程可执行
  current_thread->state = RUNNABLE;
  thread_schedule();
}

volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
  int i;
  printf("thread_a started\n");
  a_started = 1;
  // 询问式抢占
  while(b_started == 0 || c_started == 0)
      // 没人用就占用线程
    thread_yield();
  
  for (i = 0; i < 100; i++) {
    printf("thread_a %d\n", i);
    a_n += 1;
    thread_yield();
  }
  printf("thread_a: exit after %d\n", a_n);

  current_thread->state = FREE;
  thread_schedule();
}

void 
thread_b(void)
{
  int i;
  printf("thread_b started\n");
  b_started = 1;
  while(a_started == 0 || c_started == 0)
    thread_yield();
  
  for (i = 0; i < 100; i++) {
    printf("thread_b %d\n", i);
    b_n += 1;
    thread_yield();
  }
  printf("thread_b: exit after %d\n", b_n);

  current_thread->state = FREE;
  thread_schedule();
}

void 
thread_c(void)
{
  int i;
  printf("thread_c started\n");
  c_started = 1;
  while(a_started == 0 || b_started == 0)
    thread_yield();
  
  for (i = 0; i < 100; i++) {
    printf("thread_c %d\n", i);
    c_n += 1;
    thread_yield();
  }
  printf("thread_c: exit after %d\n", c_n);

  current_thread->state = FREE;
  thread_schedule();
}

int 
main(int argc, char *argv[]) 
{
  a_started = b_started = c_started = 0;
  a_n = b_n = c_n = 0;
  thread_init();
  thread_create(thread_a);
  thread_create(thread_b);
  thread_create(thread_c);
  thread_schedule();
  exit(0);
}
