#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"

/*
核心数据结构是 pagetable_t，它实际上是一个指向 RISC-V 根页表页的指针；pagetable_t可以是内核页表，也可以是进程的页表。
核心函数是 walk 和 mappages，前者通过虚拟地址得到 PTE，后者将虚拟地址映射到物理地址。以 kvm 开头的函数操作内核页表；
以 uvm 开头的函数操作用户页表；其他函数同时用于这两种页表。copyout和copyin将数据复制到或复制出被作为系统调用参数的用户虚拟地址；
它们在 vm.c 中，因为它们需要显式转换用户空间的地址，以便找到相应的物理内存
*/

/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

/*
 * create a direct-map page table for the kernel.
    kvm开头的函数操作内核页表
    // 创建内核页表，发生在启用分页之前，所以地址直接指向物理内存
    kvminit 首先分配一页物理内存来存放根页表页。然后调用 kvmmap 将内核所需要的硬件资源映射到物理地址
 */
void
kvminit()
{
  kernel_pagetable = (pagetable_t) kalloc();
  memset(kernel_pagetable, 0, PGSIZE);

  // uart registers
  // 映射I/O设备，UARETO = 0x10000000L，看book中就是设备的起点
  // 因为设备是虚拟地址和物理地址直接映射的，所以开始和结束都是UART0
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // vmprint(kernel_pagetable);

  // virtio mmio disk interface
  // 同样
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // CLINT
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // PLIC
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
/*
映射内核页表。它将根页表页的物理地址写入寄存器 satp 中。在这之后，CPU 将使用内核页表翻译地址。
由于内核使用唯一映射，所以指令的虚拟地址将映射到正确的物理内存地址。

satp:
  每个 CPU 都有自己的 satp 寄存器。一个 CPU 将使用自己的 satp 所指向的页表来翻译后续指令产生的所有地址。
  每个 CPU 都有自己的 satp，这样不同的 CPU 可以运行不同的进程，每个进程都有自己的页表所描述的私有地址空间。
*/
void
kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));  // 设置了这条指令之后，地址翻译就开始了，MMU到satp中拿顶级PTE
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
// 核心函数, 通过虚拟地址得到PTE(页表)
/*
模仿 RISC-V 分页硬件查找虚拟地址的 PTE（见图 3.2）。walk 每次降低 9 位来查找三级页表。
它使用每一级的 9 位虚拟地址来查找下一级页表或最后一级（kernel/vm.c:78）的 PTE。
如果 PTE 无效，那么所需的物理页还没有被分配；如果 alloc 参数被设置，walk 会分配一个新的页表页，
并把它的物理地址放在 PTE 中。它返回 树中最低层PTE的地址（三级页表的地址）

模拟了MMU，返回最低级的PTE
*/
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  // 虚拟地址不能超过虚拟地址的最大值
  if(va >= MAXVA)
    panic("walk");

  // 最高级页表向下循环找
  for(int level = 2; level > 0; level--) {
    // 找下一个页表
    pte_t *pte = &pagetable[PX(level, va)];
    // 找到了，并且PTE_V有效标志设置了（没有越界）
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      // 如果三级页表中的某个页表不存在，就创建一个临时的页表，初始化为0
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  // 返回最后一级的页表
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  // 虚拟地址超过范围了
  if(va >= MAXVA)
    return 0;
  // 找到虚拟地址的最后一级页表
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0) // 页无效
    return 0;
  if((*pte & PTE_U) == 0) // 用户不可用
    return 0;
  pa = PTE2PA(*pte); //转换为物理地址
  return pa;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
// kvmmap将内核需要的硬件资源映射到物理地址
// kvmmap调用 mappages，它将指定范围的虚拟地址映射到一段物理地址。
void
kvmmap(uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// translate a kernel virtual address to
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
// 虚拟内核地址转换为物理地址。
// lab3-2
// 要改动一下，调用的时候传入一个页表,把用户的内核页表传入，否则会出现panic(kvmpa)
// 因为之前在procinit()把映射到全局的内核页表注释了，所以不会有这个操作
// 也要在defs.h改下声明
uint64
kvmpa(pagetable_t kernel_pagetable, uint64 va)
{
  uint64 off = va % PGSIZE;
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
  if(pte == 0)
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    panic("kvmpa");
  pa = PTE2PA(*pte);
  return pa+off;
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
// 核心映射函数，虚拟地址映射到物理地址
/*
它将范围内地址分割成多页（忽略余数），每次映射一页的起始地址。对于每个要映射的虚拟地址（页的起始地址），
mapages 调用 walk 找到该地址的最后一级 PTE 的地址（三级页表）。然后，它配置 PTE，使其持有相关的物理页号、
所需的权限（PTE_W、PTE_X和/或PTE_R），以及PTE_V来标记 PTE 为有效

PTE是每个页表中的一块
*/
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  // 调整到4096的倍数，因为每页是这么大
  a = PGROUNDDOWN(va);
  // size是范围地址大小，从a到last
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    // 找到虚拟地址的最后一个PTE
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    // 这里是设置映射，如果找到的这个PTE地址已经被设置过了，说明不能分配这个地址映射，报错
    if(*pte & PTE_V)
      panic("remap");
    // 初始化PTE的相关页号，权限perm和标记PTE有效的PTE_V
    *pte = PA2PTE(pa) | perm | PTE_V;
    // 地址分配完了
    if(a == last)
      break;
    // 每次分配一个页的大小
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
// 取消虚拟地址的映
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)  // 必须是PGSIZE的倍数
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)//取出三级页表
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)     //判断有效
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)  
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte); // 页表映射到物理地址
      kfree((void*)pa);     // 释放。
    }
    *pte = 0;  // 取消最后一级的映射
  }
}

// create an empty user page table.
// returns 0 if out of memory.
// uvm开头的函数操作用户页表
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}

// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
// uvmalloc通过 kalloc 分配物理内存，并使用 mappages 将 PTE 添加到用户页表中
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
//使用 walk 来查找 PTE 并使用 kfree 来释放它们所引用的物理内存。
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
// 必须要虚拟到物理地址的映射都解除了才全部丢弃页表。
void
freewalk(pagetable_t pagetable)
{
  // vmprint(pagetable);
  // there are 2^9 = 512 PTEs in a page table.
  // 遍历页表每个项
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    // 如果不是最后一个页表，最后一层是防止越界的，PTE_V不设置
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      // 找到下一级页表
      uint64 child = PTE2PA(pte);
      // 递归
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    // 一个用户虚拟地址是从0开始的
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// lab3-3，模拟uvmcopy函数，将用户页表复制到用户内核页表中
int
ukvmcopy(pagetable_t upagetable, pagetable_t kpagetable, uint64 begin, uint64 end)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // 向上取整开始为4096倍数，不向下是因为低地址已经被使用了
  uint64 begin_page = PGROUNDUP(begin);
  for(i = begin_page; i < end; i += PGSIZE)
  {
    // 找到用户页表的三级页表
    if((pte = walk(upagetable, i, 0)) == 0)
      panic("ukvmcopy: pte should exist");
    // 判断有效性
    if((*pte & PTE_V) == 0)
      panic("ukvmcopy: page not present");
    // 取出真实地址和标志位
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    // 因为在内核中，带有PTE_U标志不能访问，所以这里复制过来的标志要把PTE_U标志去掉
    // PTE_U只有一位是1,其他全部是0,只要取反在与就能去掉这个标志位
    flags &= (~PTE_U);
    // uvmcopy这里是分配了一个页，但是这里kpagetable已经存在了，直接映射
    // 映射用户页表指向的物理地址到用户内核页表
    if(mappages(kpagetable, i, PGSIZE, pa, flags) != 0)
      goto err;
  }
  return 0;

err:
  // 映射错误要取消前面映射的所有PTE
  uvmunmap(kpagetable, begin_page, (i - begin_page) / PGSIZE, 0);
  return -1;
}



// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
// 读取用户指针指向的内存，通过这个指针转换为内核可以直接解引用的物理地址
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{

  // lab3-3
  // 使用vmcopyin.c/copyin_new替代copy，将用户进程的页表复制到lab3-2的创建的用户内核页表中，就可以直接解引用物理地址。
  return copyin_new(pagetable,dst,srcva,len);
  // uint64 n, va0, pa0;

  // while(len > 0){
  //   va0 = PGROUNDDOWN(srcva);      //需要4096倍数,向下取整
  //   pa0 = walkaddr(pagetable, va0);//里面调用walk找到最后一级页表。并且在最后一级页表中找到映射的物理地址。
  //   if(pa0 == 0)
  //     return -1;
    
  //   // PGSIZE - 向下取整的数， 
  //   n = PGSIZE - (srcva - va0); 
  //   if(n > len)
  //     n = len;
  //   // 复制从(pa0 + (srcva - va0))开始复制长度为n的内存到dst
  //   // 最开始srcva-va0 = 0，之后每次srcva + PGSIZE,也就是每次移动一个PGSIZE一个PTE
  //   memmove(dst, (void *)(pa0 + (srcva - va0)), n);

  //   len -= n;
  //   dst += n;
  //   // 每次走一个PGSIZE
  //   srcva = va0 + PGSIZE;
  // }
  // return 0;
}



// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    // lab3-3使用vmcopyin.c/copyinstr_new替代
    return copyinstr_new(pagetable, dst, srcva, max);
//  uint64 n, va0, pa0;
//  int got_null = 0;

//  while(got_null == 0 && max > 0){
//    va0 = PGROUNDDOWN(srcva);
//    pa0 = walkaddr(pagetable, va0);
//    if(pa0 == 0)
//      return -1;
//    n = PGSIZE - (srcva - va0);
//    if(n > max)
//      n = max;

//    char *p = (char *) (pa0 + (srcva - va0));
//    while(n > 0){
//      if(*p == '\0'){
//        *dst = '\0';
//        got_null = 1;
//        break;
//      } else {
//        *dst = *p;
//      }
//      --n;
//      --max;
//      p++;
//      dst++;
//    }

//    srcva = va0 + PGSIZE;
//  }
//  if(got_null){
//    return 0;
//  } else {
//    return -1;
//  }
}


// lab3打印页表信息
/*
格式：
  page table 0x0000000087fff000                                 // 一级页表自己本身的地址
    ..0: pte 0x0000000021fff801 pa 0x0000000087ffe000 fl 0×1        // 存放的下一级页表的地址
    .. ..128: pte 0x0000000021fff40l pa 0x0000000087ffd000 fl 0x1   二级页表存放的三级页表的地址
    .. .. ..0: pte 0x0000000004000007 pa 0x0000000010000000 fl 0x7  三级页表存放的物理地址
*/

// 借鉴freewalk的做法进行遍历 ,在exec.c的exec函数中调用。
void
_vmprint_helper(pagetable_t pagetable, int level)
{
  // 一个页表中有512个PTE，遍历每一个
  for(int i = 0; i < 512; ++i)
  {
    // 取出每个PTE
    pte_t pte = pagetable[i];
    // 页表项设置了有效标志，进行打印
    if((pte & PTE_V))
    {
      // 一级打印一个点，以此类推
      for(int j = 0; j < level; ++j)
      {
        if(j == 0)
          printf("..");
        else 
          printf(" ..");
      }

      // PTE存放的地址pte转换为物理地址寻找下一级页表
      uint64 child = PTE2PA(pte);

      // 打印地址,第一个数字是目前的PTE在页表中的位置
      // 第一个地址是pte本身的地址，pa下一个地址是指向的地址
      // fl是标志位pte的后几位
      // 测试要求不打印flags
      // printf("%d: pte %p pa %p fl 0x%x\n", i, pte, child, PTE_FLAGS(pte));
      printf("%d: pte %p pa %p\n", i, pte, child);

      // 不是最后一层就递归
      if(((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X))) == 0)
        _vmprint_helper((pagetable_t)child, level + 1);
    }
  }
}
void
vmprint(pagetable_t pagetable)
{
  // 先打印一级页表的地址
  printf("page table %p\n",pagetable);
  // 递归打印每层存的地址,一级页表开始
  // 系统初始化会分配两个page，一个是text段，一个是data段，具体看book
  _vmprint_helper(pagetable, 1);
}


/*
lab3-2: A kernel pagetable per process (hard)
*/


//也实现自己的uvmmap，在出错的时候可以定位
void
uvmmap(pagetable_t pt, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(pt, va, sz, pa, perm) != 0)
    panic("uvmmap");
}
// 修改版本的kvminit，创建一个新的页表，而不是修改kernel_pagetable
// 在proc.c中调用它
// 模仿那个最上面的kvminit()
pagetable_t
proc_kpagetable()
{
  // 自己创建一个页表
  pagetable_t kpagetable = uvmcreate();
  if(kpagetable == 0)
    return 0;

  // 添加基本的设备映射。
  // uart registers
  // 映射I/O设备，UARETO = 0x10000000L，看book中就是设备的起点
  // 因为设备是虚拟地址和物理地址直接映射的，所以开始和结束都是UART0
  uvmmap(kpagetable,UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // vmprint(kernel_pagetable);

  // virtio mmio disk interface
  // 同样
  uvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // CLINT
  uvmmap(kpagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // PLIC
  uvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  uvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  uvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  uvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);


  // 返回创建的页表
  return kpagetable;
}
