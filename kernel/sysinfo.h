#include "types.h"

struct sysinfo {
  uint64 freemem;   // amount of free memory (bytes)  空闲内存的字节数。
  uint64 nproc;     // number of process   不是UNUSED的进程数。
};
