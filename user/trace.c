#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


// 调用格式 trace 32 grep hello  README  
// 32作为mask 1 << 32 = 5 查看syscall.h是read调用，所以这次追踪的是read
int
main(int argc, char *argv[]) // argv["trace","32","grep","hello","README"]
{
  int i;
  char *nargv[MAXARG];

  if(argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9')){ // 判断数字不是负数
    fprintf(2, "Usage: %s mask command\n", argv[0]);
    exit(1);
  }
  
  // 调用trace会将trace送到a7寄存器，将argv[1]送到a0寄存器，ecall系统调用之后在sysproc.c中的syscall中取出，之后使用对应的trace
  // 的序号（在syscall.h中定义）对应的函数，这里是sys_trace，在这个函数中取出a0也就是存放
  if (trace(atoi(argv[1])) < 0) {
    fprintf(2, "%s: trace failed\n", argv[0]);
    exit(1);
  }
  
  // 复制系统调用和后面的指令 grep hello README
  for(i = 2; i < argc && i < MAXARG; i++){
    nargv[i-2] = argv[i];
  }
  // 会进行fork(),上面进行trace系统调用之后mypoc()的进程mask会设置为argv[1],frok()里面grep指令的进程mask会继承argv[1]
  exec(nargv[0], nargv);
  exit(0);
}
