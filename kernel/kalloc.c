// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel. // 用户态的第一个地址
                   // defined by kernel.ld.

// 空闲页的链表节点
struct run {
  struct run *next;
};

struct {
  struct spinlock lock;  // 自旋锁保护
  struct run *freelist;
} kmem;

// 初始化空闲页链表，保存内核地址结束end，到PHYSTOP之间的每一页
void
kinit()
{
  initlock(&kmem.lock, "kmem");
  // 添加内存到空闲页链表
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  // PTE(页表)只能指向按照4096bytes对齐的物理地址，这里就是把它摄制成4096倍数的最大大小。
  // 所以使用PGROUNDUP确保只添加对齐的物理地址到链表中。
  p = (char*)PGROUNDUP((uint64)pa_start);
  // 每次把PGSIZE页大小挂在空闲链表上
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  // 一个页的大小 4096bytes，因为这是被释放的页，要设置1为垃圾内容防止读取旧的有效内容。
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  // 空闲块加入链表中，kmeme是保存最后整个链表的变量
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)  // kmem往下移动一块，r指向了前一块内存，也就是将r指向的内存分配出去,大小是PGSIZE
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}


// 记录申请的内存链表中还有多少空闲内存
// kmem指向空闲的内存页链表，走到NULL就是空闲量了
uint64
free_mem(void)
{
  struct run* p;
  uint64 num = 0;
  // 在kalloc中看到操作内存链表要上锁
  acquire(&kmem.lock);
  p = kmem.freelist;
  while(p)
  {
    num++;
    p = p->next;
  }
  // 释放锁
  release(&kmem.lock);
  // 因为一个链表节点分配的是一个页的大小，所以还要乘上PGSIZE
  return num * PGSIZE;
}