#include "kernel/types.h" // uint
#include "user/user.h"  //pipe(), fork()， getpid(),write,read

/*
使用 UNIX 系统调用编写一个程序 pingpong ，在一对管道上实现两个进程之间的通信。
父进程应该通过第一个管道给子进程发送一个信息 “ping”，子进程接收父进程的信息后打印 
"<pid>: received ping" ，其中是其进程 ID 。然后子进程通过另一个管道发送一个信息
 “pong” 给父进程，父进程接收子进程的信息然后打印 "<pid>: received pong" ，
 然后退出。
*/

int main()
{

    // 1.创建两个匿名管道,[0]读，[1]写
    int pipe_1[2], pipe_2[2]; 
    pipe(pipe_1);
    pipe(pipe_2);
    char buf[8];

    // 2. fork子进程
    int pid = fork();

    // 3. 子进程是0
    if(pid == 0)
    {
        // 读取ping，如果父进程没写会一直堵塞，正好有顺序
        read(pipe_1[0],buf, strlen("ping"));
        // 打印<pid>: received ping
        printf("<%d>: received %s\n", getpid(), buf);

        // 发送pong
        write(pipe_2[1], "pong", 4);
        // 字进程也要用exit(0)退出，不然会发生错误！
        // exit(0);
    }
    else // 4. 父进程处理
    {
        //发送ping
        write(pipe_1[1], "ping", 4);
        // 结束pong,子进程没有发送会堵塞，正好不用wait可以，也可以防止让子进程变成僵尸进程
        read(pipe_2[0], buf, strlen("pong"));
        printf("<%d>: received %s\n", getpid(), buf);
    }

    exit(0);
}