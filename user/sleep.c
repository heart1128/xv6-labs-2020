#include "kernel/types.h" //
#include "user/user.h"    // atoi, strlen, write, 系统的sleep


int main(int argc, char* argv[])
{
    // 1. 判断参数个数，参数第一个是文件名，第二个是用户参数，如果参数不是两个就报错
    // sleep time
    // 方法： 借鉴user/echo.c, 使用write函数写入标准输出1，xv6没有指定标准错误2
    if(argc != 2)
    {
        const char* errno = "please input 'sleep time' format!\n";
        write(1, errno, strlen(errno));
        exit(1);
    }

    // 2.参数个数没错，判断第二个参数是不是大于0
    int second = atoi(argv[1]);
    if(second < 0)
    {
        const char* errno = "time setting error! please input positive integer!\n";
        write(1, errno, strlen(errno));
        exit(1);
    }

    // 3. 参数没问题，调用系统的sleep
    sleep(second);
    exit(0); // 调用正常
}