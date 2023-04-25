//
// formatted console output -- printf, panic.
//

#include <stdarg.h>

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "proc.h"

volatile int panicked = 0;

// lock to avoid interleaving concurrent printf's.
static struct {
  struct spinlock lock;
  int locking;
} pr;

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    x = -xx;
  else
    x = xx;

  i = 0;
  do {
    buf[i++] = digits[x % base];
  } while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
    consputc(buf[i]);
}

static void
printptr(uint64 x)
{
  int i;
  consputc('0');
  consputc('x');
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
}

// Print to the console. only understands %d, %x, %p, %s.
void
printf(char *fmt, ...)
{
  va_list ap;
  int i, c, locking;
  char *s;

  locking = pr.locking;
  if(locking)
    acquire(&pr.lock);

  if (fmt == 0)
    panic("null fmt");

  va_start(ap, fmt);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    if(c != '%'){
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    case 'd':
      printint(va_arg(ap, int), 10, 1);
      break;
    case 'x':
      printint(va_arg(ap, int), 16, 1);
      break;
    case 'p':
      printptr(va_arg(ap, uint64));
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
      break;
    case '%':
      consputc('%');
      break;
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
      consputc(c);
      break;
    }
  }

  if(locking)
    release(&pr.lock);
}

void
panic(char *s)
{
  pr.locking = 0;
  printf("panic: ");
  printf(s);
  printf("\n");

  // lab 4-2
  // 调用打印函数的返回地址
  // 出错的时候就会打印
  backtrace();

  panicked = 1; // freeze uart output from other CPUs
  for(;;)
    ;
}

void
printfinit(void)
{
  initlock(&pr.lock, "pr");
  pr.locking = 1;
}



// lab4-2
// backtrece()，不断循环输出当前函数的返回地址，直到到达该页表的起始地址。
// lab4-2 添加backtrace函数打印
void
backtrace(void)
{
    // 取出存在s0寄存器的fp
    uint64 fp = r_fp();
    // printf("fp = %p\n", fp);
    // 栈的地址是负的，因为栈是从高地址到低地址的，所以栈顶的的地址比栈底更小，所以栈地址是负的
    // 向上调整到PGSIZE大小的倍数。栈最多一个PGSIZE，所以上调到PGSIZE的倍数肯定是PGSIZE
    // RISC-V 的用户栈空间占一个页面，这里得到最高地址
    uint64 top = PGROUNDUP(fp);
    // printf("top = %p\n", top); 是负值，所以每次往下减会不超过top
    printf("backtrace:\n");

    // 不断循环直到顶
    // 每次往栈里面读16字节，也就是下一个函数的fp
    for(; fp < top; fp = *((uint64*)(fp-16)))
    {
        // 打印返回地址，存在fp-8的位置。
        printf("%p\n", *((uint64*)(fp-8)));
    }
}



