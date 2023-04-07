#include "kernel/param.h"
#include "kernel/sysinfo.h"  // struct sysinfo
#include "kernel/types.h"   // uintxx
#include "user/user.h"      // 系统调用声明sysinfo(struct sysinfo*)


int
main(int argc, char *argv[])
{
    // 不能带参数
    if(argc != 1)
    {
        fprintf(2, "Usage: %s need not param\n", argv[0]);
        exit(1);
    }

    struct sysinfo info;
    sysinfo(&info);
    
    printf("free space: %d\nused process: %d\n", info.freemem, info.nproc);
    exit(0);
}