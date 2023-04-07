#include "kernel/types.h"
#include "kernel/param.h"
#include "user/user.h"


/*
    编写一个简单的 UNIX xargs 程序，从标准输入中读取行并为每一行运行一个命令，将该行作为命令的参数提供。你的解决方案应该放在 user/xargs.c 中。
    不能直接使用xargs，比如echo hello | xargs bey, 表示xargs读入输入流的东西，让后使用echo输出参数bey，hello都是从管道读取
*/

// 先读取xargs后面的参数(第一个是命令)，然后从标准输入，0端口读取命令，和后面的参数,


int main(int argc, char* argv[])
{
    // 必须最少有一个参数
    if(argc < 2)
    {
        fprintf(2, "usage: xargs command error!\n");
        // 异常退出
        exit(1);
    }

    char* argvs[MAXARG]; 
    int count = 0;
    char buf[256];
    // 读取xargs后面的参数
    for(int i = 1; i < argc; ++i)
        argvs[count++] = argv[i];
    
    // 标准输入读取
    int size = 0;
    // 可能有多个管道
    while((size = read(0, buf, sizeof(buf))) > 0)
    {
        char temp[256] = {"\0"};
        // 新的参数读取argvs[count] 这个指针绑定了temp,之后temp的操作指针会记录
        argvs[count] = temp;  
        for(int i = 0; i < size; ++i)
        {
            if(buf[i] == '\n')
            {
                // 输入回车就是结束，创建进程exec
                if(0 == fork())
                {
                    exec(argv[1], argvs);
                }
                
                wait(0); //父进程等待
            }
            else // 如果不是则等待。
            {
                temp[i] = buf[i];
            }
        }
    }
    exit(0);
}
