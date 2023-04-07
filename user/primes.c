#include "kernel/types.h"
#include "user/user.h"

/*

使用管道将 2 至 35 中的素数筛选出来，这个想法归功于 Unix 管道的发明者 Doug McIlroy 。
链接中间的图片和周围的文字解释了如何操作。最后的解决方案应该放在 user/primes.c 文件中。
你的目标是使用 pipe 和 fork 来创建管道。第一个进程将数字 2 到 35 送入管道中。
对于每个质数，你要安排创建一个进程，从其左邻通过管道读取，并在另一条管道上写给右邻。
由于 xv6 的文件描述符和进程数量有限，第一个进程可以停止在 35 

*/

/*
    1. 循环除，每次第一个数保存，其他数对他取余，不为0输出，为0就往管道送。直到结束没有数字
    2. 不能过多的开文件描述符和进程，应该，每次使用管道之后用dup重新绑定到0，1文件描述符进行读写
    3. 使用一个mapping函数进行dup的重新绑定。
*/

void mapping(int fd, int pd[])
{
    // 关闭0/1的fd，新的pd[fd]进行dup自然会使用最小的文件描述符
    close(fd);
    dup(pd[fd]);

    // 关闭管道fd，使用0,1描述符进行通信
    close(pd[0]);
    close(pd[1]);
}
// 求素数
void primes()
{
    int pd[2];
    int first = 0, next = 0;


    // 读出第一个保存,如果管道没有了就失败了，就结束这个函数
    if(read(0, &first, sizeof(int)))
    {
        pipe(pd);
        // 第一个肯定是素数，不然不会进入到下一层，每次的第一个肯定都是素数
        printf("prime %d\n", first);

        // 使用子进程进行循环读取
        if(fork() == 0)
        {
            mapping(1, pd);
            while(read(0, &next, sizeof(int)))
            {
                if(next % first != 0)
                {
                    // 不是素数接着写入，不过使用的是局部管道
                    write(1, &next, sizeof(int));
                }
            }
        }
        else
        {
            // 父进程负责改dup和递归
            wait(0);
            mapping(0, pd);
            primes();
        }
    }
}

int main()
{

    int pd[2];
    pipe(pd);

    // 要写，改映射为1写段
    //  mapping(1, pd); 没有写在子进程里面，父进程的pd[1]也会被映射，之后的mapping(0)，就会被覆盖

    // 首先写入2 - 35的数，用子线程写
    if(fork() == 0)
    {
        // 要写，改映射为1写段
        mapping(1, pd);
        // 此时的1就是pd[1]
        for(int i = 2; i <= 35; ++i)
            write(1, &i, sizeof(int));
    }
    else
    {
        // 等待子进程写入完毕
        wait(0);
        // 后面要读，改下读端0，不然局部的管道就读不到数据了
        mapping(0, pd);
        // 开始循环求素数
        primes();
    }
    exit(0);
}

