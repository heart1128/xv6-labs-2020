#include "kernel/types.h"
#include "kernel/stat.h" // T_FILE
#include "kernel/fs.h" // DIRSIZ
#include "user/user.h"


/*编写一个简单的 UNIX find 程序，在目录树中查找包含特定名称的所有文件。 格式：find dirname filename
你的解决方案应放在 user/find.c 。*/

/*
    提示是看ls.c文件，可以仿照这个文件去读取目录
    如果是文件直接输出，如果是目录就递归find
*/

void find(char* path, char* file)
{
    char buf[512];
    char *p;

    // 打开当前的文件或者文件夹,只读打开0只读，1只写，2写读
    int fd;
    if((fd = open(path, 0)) < 0)
    {
        fprintf(2, "find: cannot open %s\n", path);
        return;
    }
    // stat结构体获取文件或者目录信息
    // fstat和stat的区别就是一个是用文件描述符做参数，一个是用路径做参数
    struct stat st;
    if(fstat(fd, &st) < 0)
    {
        fprintf(2, "find: cannot stat %s\n", path);
        close(fd);
        return;
    }
    // find要做的是查找目录下的文件，所以给的path不是目录就报错
    if(st.type != T_DIR)
    {
        fprintf(2, "find: non dir! %s\n", path);
        close(fd);
        return;
    }

    // 不是文件就先打印一级路径的名字，然后取 / 之后的路径递归
    // 路径不能超过buf的大小 + 1是/的
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof(buf))
    {
        fprintf(2, "find: directory too long\n");
        close(fd);
        return;
    }
    // 先复制一份原路径拿来解析
    strcpy(buf, path);
    // path复制给buf了，buf的长度也就是path的长度了  buf是绝对路径
    p = buf + strlen(buf);
    // 此时p的位置是path的h，++之后 = '/', buf就变成了path/ ,下面不断循环目录读取文件名。path/name
    *p++ = '/';

    struct dirent de; // 读取目录下的文件，保存数量和文件名
    while(read(fd, &de, sizeof(de)) == sizeof(de))  //相同表示读取成功了
    {
        // 没有文件
        if(de.inum == 0)
            continue;
        
        // 如果是 . 或者是 .. 就不递归
        if(!strcmp(de.name, ".") || !strcmp(de.name, ".."))
            continue;
        // 前面已经把p的位置定位在path/，这把name复制过来就是 path/name不断拼接。
        memmove(p, de.name, DIRSIZ);
        p[DIRSIZ] = 0; // 放'/0'


        // 读取这个文件名, 出错会返回-1
        if(stat(buf, &st) < 0)
        {
            // 出错则报错
            fprintf(2, "find: cannot stat %s\n", buf);
            continue;
        }

        // 如果是目录就递归
        if(T_DIR == st.type)
        {
            // buf = path/name  这里是不断向文件夹内部递归的
            find(buf,file);
        }
        // 如果是文件名就输出，并且和要找的文件名一样就输出buf，此时的buf就是文件的绝对路径
        if(T_FILE == st.type && !strcmp(de.name , file))
        {
            printf("%s\n", buf);
        }
    }
}

int main(int argc, char* argv[])
{
    // 如果没有给够参数直接给当前文件符号 .find
    if(argc < 3)
    {
        // 输出提示
        fprintf(2, "usage: find dirName fileName\n");
        // 异常退出
        exit(1);
    }
    // find dir filename
    find(argv[1], argv[2]);
    exit(0);
}