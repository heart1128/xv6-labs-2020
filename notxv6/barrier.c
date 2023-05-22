#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <assert.h>
#include <pthread.h>

static int nthread = 1;
static int round = 0;

struct barrier {
  pthread_mutex_t barrier_mutex;
  pthread_cond_t barrier_cond;
  int nthread;      // Number of threads that have reached this round of the barrier
  int round;     // Barrier round
} bstate;

static void
barrier_init(void)
{
  assert(pthread_mutex_init(&bstate.barrier_mutex, NULL) == 0);
  assert(pthread_cond_init(&bstate.barrier_cond, NULL) == 0);
  bstate.nthread = 0;
}

static void 
barrier()
{
  // YOUR CODE HERE
  //
  // Block until all threads have called barrier() and
  // then increment bstate.round.
  //
  // lab 7-3
  // 保证所有的线程都进入这函数进行睡眠等待，算一轮
  // 保证下一个round的操作不会影响到上一个还没有结束的round
  // 进入一个，如果不是所有线程都进入了，就进行随眠等待，如果是，就全部唤醒，计数清零就行。

  // 1. 申请互斥锁
    pthread_mutex_lock(&bstate.barrier_mutex);

    bstate.nthread++; // 进入barrier的线程计数
    if(bstate.nthread == nthread) //所有线程都进入过barrier，算一个round
    {
        bstate.round++;
        bstate.nthread = 0;
        // 所有线程都进入了barrier之后就进行全部唤醒。
        pthread_cond_broadcast(&bstate.barrier_cond);
    }
    else
    {
        // 不是所有线程都进入了，进行睡眠，等待唤醒
        // barrier_mutex这个锁要提前持有。
        // 等待条件，直到唤醒，加锁是为了防止多个线程同时请求
        pthread_cond_wait(&bstate.barrier_cond, &bstate.barrier_mutex);
    }

    // 释放锁
    pthread_mutex_unlock(&bstate.barrier_mutex);
}

static void *
thread(void *xa)
{
  long n = (long) xa;
  long delay;
  int i;

  for (i = 0; i < 20000; i++) {
    int t = bstate.round;
    assert (i == t);
    barrier(); // 每次进入一个线程
    usleep(random() % 100);
  }

  return 0;
}

int
main(int argc, char *argv[])
{
  pthread_t *tha;
  void *value;
  long i;
  double t1, t0;

  if (argc < 2) {
    fprintf(stderr, "%s: %s nthread\n", argv[0], argv[0]);
    exit(-1);
  }
  nthread = atoi(argv[1]);
  tha = malloc(sizeof(pthread_t) * nthread);
  srandom(0);

  barrier_init();

  for(i = 0; i < nthread; i++) {
    assert(pthread_create(&tha[i], NULL, thread, (void *) i) == 0);
  }
  for(i = 0; i < nthread; i++) {
    assert(pthread_join(tha[i], &value) == 0);
  }
  printf("OK; passed\n");
}
