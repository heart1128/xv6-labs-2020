
user/_xargs:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

// 先读取xargs后面的参数(第一个是命令)，然后从标准输入，0端口读取命令，和后面的参数,


int main(int argc, char* argv[])
{
   0:	cb010113          	addi	sp,sp,-848
   4:	34113423          	sd	ra,840(sp)
   8:	34813023          	sd	s0,832(sp)
   c:	32913c23          	sd	s1,824(sp)
  10:	33213823          	sd	s2,816(sp)
  14:	33313423          	sd	s3,808(sp)
  18:	33413023          	sd	s4,800(sp)
  1c:	31513c23          	sd	s5,792(sp)
  20:	31613823          	sd	s6,784(sp)
  24:	31713423          	sd	s7,776(sp)
  28:	0e80                	addi	s0,sp,848
    // 必须最少有一个参数
    if(argc < 2)
  2a:	4785                	li	a5,1
  2c:	08a7d363          	bge	a5,a0,b2 <main+0xb2>
  30:	8b2e                	mv	s6,a1
  32:	00858713          	addi	a4,a1,8
  36:	eb040793          	addi	a5,s0,-336
  3a:	00050a9b          	sext.w	s5,a0
  3e:	ffe5069b          	addiw	a3,a0,-2
  42:	1682                	slli	a3,a3,0x20
  44:	9281                	srli	a3,a3,0x20
  46:	068e                	slli	a3,a3,0x3
  48:	eb840613          	addi	a2,s0,-328
  4c:	96b2                	add	a3,a3,a2
    char* argvs[MAXARG]; 
    int count = 0;
    char buf[256];
    // 读取xargs后面的参数
    for(int i = 1; i < argc; ++i)
        argvs[count++] = argv[i];
  4e:	6310                	ld	a2,0(a4)
  50:	e390                	sd	a2,0(a5)
    for(int i = 1; i < argc; ++i)
  52:	0721                	addi	a4,a4,8
  54:	07a1                	addi	a5,a5,8
  56:	fed79ce3          	bne	a5,a3,4e <main+0x4e>
        argvs[count++] = argv[i];
  5a:	3afd                	addiw	s5,s5,-1
    // 可能有多个管道
    while((size = read(0, buf, sizeof(buf))) > 0)
    {
        char temp[256] = {"\0"};
        // 新的参数读取argvs[count] 这个指针绑定了temp,之后temp的操作指针会记录
        argvs[count] = temp;  
  5c:	0a8e                	slli	s5,s5,0x3
  5e:	fb040793          	addi	a5,s0,-80
  62:	9abe                	add	s5,s5,a5
  64:	cb040a13          	addi	s4,s0,-848
    while((size = read(0, buf, sizeof(buf))) > 0)
  68:	10000613          	li	a2,256
  6c:	db040593          	addi	a1,s0,-592
  70:	4501                	li	a0,0
  72:	00000097          	auipc	ra,0x0
  76:	328080e7          	jalr	808(ra) # 39a <read>
  7a:	89aa                	mv	s3,a0
  7c:	08a05763          	blez	a0,10a <main+0x10a>
        char temp[256] = {"\0"};
  80:	ca043823          	sd	zero,-848(s0)
  84:	0f800613          	li	a2,248
  88:	4581                	li	a1,0
  8a:	cb840513          	addi	a0,s0,-840
  8e:	00000097          	auipc	ra,0x0
  92:	0f8080e7          	jalr	248(ra) # 186 <memset>
        argvs[count] = temp;  
  96:	f14ab023          	sd	s4,-256(s5)
        for(int i = 0; i < size; ++i)
  9a:	db040493          	addi	s1,s0,-592
  9e:	8952                	mv	s2,s4
  a0:	39fd                	addiw	s3,s3,-1
  a2:	1982                	slli	s3,s3,0x20
  a4:	0209d993          	srli	s3,s3,0x20
  a8:	db140793          	addi	a5,s0,-591
  ac:	99be                	add	s3,s3,a5
        {
            if(buf[i] == '\n')
  ae:	4ba9                	li	s7,10
  b0:	a82d                	j	ea <main+0xea>
        fprintf(2, "usage: xargs command error!\n");
  b2:	00000597          	auipc	a1,0x0
  b6:	7ee58593          	addi	a1,a1,2030 # 8a0 <malloc+0xe8>
  ba:	4509                	li	a0,2
  bc:	00000097          	auipc	ra,0x0
  c0:	610080e7          	jalr	1552(ra) # 6cc <fprintf>
        exit(1);
  c4:	4505                	li	a0,1
  c6:	00000097          	auipc	ra,0x0
  ca:	2bc080e7          	jalr	700(ra) # 382 <exit>
            {
                // 输入回车就是结束，创建进程exec
                if(0 == fork())
  ce:	00000097          	auipc	ra,0x0
  d2:	2ac080e7          	jalr	684(ra) # 37a <fork>
  d6:	c10d                	beqz	a0,f8 <main+0xf8>
                {
                    exec(argv[1], argvs);
                }
                
                wait(0); //父进程等待
  d8:	4501                	li	a0,0
  da:	00000097          	auipc	ra,0x0
  de:	2b0080e7          	jalr	688(ra) # 38a <wait>
        for(int i = 0; i < size; ++i)
  e2:	0485                	addi	s1,s1,1
  e4:	0905                	addi	s2,s2,1
  e6:	f93481e3          	beq	s1,s3,68 <main+0x68>
            if(buf[i] == '\n')
  ea:	0004c783          	lbu	a5,0(s1)
  ee:	ff7780e3          	beq	a5,s7,ce <main+0xce>
            }
            else // 如果不是则等待。
            {
                temp[i] = buf[i];
  f2:	00f90023          	sb	a5,0(s2)
  f6:	b7f5                	j	e2 <main+0xe2>
                    exec(argv[1], argvs);
  f8:	eb040593          	addi	a1,s0,-336
  fc:	008b3503          	ld	a0,8(s6)
 100:	00000097          	auipc	ra,0x0
 104:	2ba080e7          	jalr	698(ra) # 3ba <exec>
 108:	bfc1                	j	d8 <main+0xd8>
            }
        }
    }
    exit(0);
 10a:	4501                	li	a0,0
 10c:	00000097          	auipc	ra,0x0
 110:	276080e7          	jalr	630(ra) # 382 <exit>

0000000000000114 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 11a:	87aa                	mv	a5,a0
 11c:	0585                	addi	a1,a1,1
 11e:	0785                	addi	a5,a5,1
 120:	fff5c703          	lbu	a4,-1(a1)
 124:	fee78fa3          	sb	a4,-1(a5)
 128:	fb75                	bnez	a4,11c <strcpy+0x8>
    ;
  return os;
}
 12a:	6422                	ld	s0,8(sp)
 12c:	0141                	addi	sp,sp,16
 12e:	8082                	ret

0000000000000130 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 130:	1141                	addi	sp,sp,-16
 132:	e422                	sd	s0,8(sp)
 134:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 136:	00054783          	lbu	a5,0(a0)
 13a:	cb91                	beqz	a5,14e <strcmp+0x1e>
 13c:	0005c703          	lbu	a4,0(a1)
 140:	00f71763          	bne	a4,a5,14e <strcmp+0x1e>
    p++, q++;
 144:	0505                	addi	a0,a0,1
 146:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 148:	00054783          	lbu	a5,0(a0)
 14c:	fbe5                	bnez	a5,13c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 14e:	0005c503          	lbu	a0,0(a1)
}
 152:	40a7853b          	subw	a0,a5,a0
 156:	6422                	ld	s0,8(sp)
 158:	0141                	addi	sp,sp,16
 15a:	8082                	ret

000000000000015c <strlen>:

uint
strlen(const char *s)
{
 15c:	1141                	addi	sp,sp,-16
 15e:	e422                	sd	s0,8(sp)
 160:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 162:	00054783          	lbu	a5,0(a0)
 166:	cf91                	beqz	a5,182 <strlen+0x26>
 168:	0505                	addi	a0,a0,1
 16a:	87aa                	mv	a5,a0
 16c:	4685                	li	a3,1
 16e:	9e89                	subw	a3,a3,a0
 170:	00f6853b          	addw	a0,a3,a5
 174:	0785                	addi	a5,a5,1
 176:	fff7c703          	lbu	a4,-1(a5)
 17a:	fb7d                	bnez	a4,170 <strlen+0x14>
    ;
  return n;
}
 17c:	6422                	ld	s0,8(sp)
 17e:	0141                	addi	sp,sp,16
 180:	8082                	ret
  for(n = 0; s[n]; n++)
 182:	4501                	li	a0,0
 184:	bfe5                	j	17c <strlen+0x20>

0000000000000186 <memset>:

void*
memset(void *dst, int c, uint n)
{
 186:	1141                	addi	sp,sp,-16
 188:	e422                	sd	s0,8(sp)
 18a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 18c:	ca19                	beqz	a2,1a2 <memset+0x1c>
 18e:	87aa                	mv	a5,a0
 190:	1602                	slli	a2,a2,0x20
 192:	9201                	srli	a2,a2,0x20
 194:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 198:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 19c:	0785                	addi	a5,a5,1
 19e:	fee79de3          	bne	a5,a4,198 <memset+0x12>
  }
  return dst;
}
 1a2:	6422                	ld	s0,8(sp)
 1a4:	0141                	addi	sp,sp,16
 1a6:	8082                	ret

00000000000001a8 <strchr>:

char*
strchr(const char *s, char c)
{
 1a8:	1141                	addi	sp,sp,-16
 1aa:	e422                	sd	s0,8(sp)
 1ac:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1ae:	00054783          	lbu	a5,0(a0)
 1b2:	cb99                	beqz	a5,1c8 <strchr+0x20>
    if(*s == c)
 1b4:	00f58763          	beq	a1,a5,1c2 <strchr+0x1a>
  for(; *s; s++)
 1b8:	0505                	addi	a0,a0,1
 1ba:	00054783          	lbu	a5,0(a0)
 1be:	fbfd                	bnez	a5,1b4 <strchr+0xc>
      return (char*)s;
  return 0;
 1c0:	4501                	li	a0,0
}
 1c2:	6422                	ld	s0,8(sp)
 1c4:	0141                	addi	sp,sp,16
 1c6:	8082                	ret
  return 0;
 1c8:	4501                	li	a0,0
 1ca:	bfe5                	j	1c2 <strchr+0x1a>

00000000000001cc <gets>:

char*
gets(char *buf, int max)
{
 1cc:	711d                	addi	sp,sp,-96
 1ce:	ec86                	sd	ra,88(sp)
 1d0:	e8a2                	sd	s0,80(sp)
 1d2:	e4a6                	sd	s1,72(sp)
 1d4:	e0ca                	sd	s2,64(sp)
 1d6:	fc4e                	sd	s3,56(sp)
 1d8:	f852                	sd	s4,48(sp)
 1da:	f456                	sd	s5,40(sp)
 1dc:	f05a                	sd	s6,32(sp)
 1de:	ec5e                	sd	s7,24(sp)
 1e0:	1080                	addi	s0,sp,96
 1e2:	8baa                	mv	s7,a0
 1e4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1e6:	892a                	mv	s2,a0
 1e8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1ea:	4aa9                	li	s5,10
 1ec:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ee:	89a6                	mv	s3,s1
 1f0:	2485                	addiw	s1,s1,1
 1f2:	0344d863          	bge	s1,s4,222 <gets+0x56>
    cc = read(0, &c, 1);
 1f6:	4605                	li	a2,1
 1f8:	faf40593          	addi	a1,s0,-81
 1fc:	4501                	li	a0,0
 1fe:	00000097          	auipc	ra,0x0
 202:	19c080e7          	jalr	412(ra) # 39a <read>
    if(cc < 1)
 206:	00a05e63          	blez	a0,222 <gets+0x56>
    buf[i++] = c;
 20a:	faf44783          	lbu	a5,-81(s0)
 20e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 212:	01578763          	beq	a5,s5,220 <gets+0x54>
 216:	0905                	addi	s2,s2,1
 218:	fd679be3          	bne	a5,s6,1ee <gets+0x22>
  for(i=0; i+1 < max; ){
 21c:	89a6                	mv	s3,s1
 21e:	a011                	j	222 <gets+0x56>
 220:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 222:	99de                	add	s3,s3,s7
 224:	00098023          	sb	zero,0(s3)
  return buf;
}
 228:	855e                	mv	a0,s7
 22a:	60e6                	ld	ra,88(sp)
 22c:	6446                	ld	s0,80(sp)
 22e:	64a6                	ld	s1,72(sp)
 230:	6906                	ld	s2,64(sp)
 232:	79e2                	ld	s3,56(sp)
 234:	7a42                	ld	s4,48(sp)
 236:	7aa2                	ld	s5,40(sp)
 238:	7b02                	ld	s6,32(sp)
 23a:	6be2                	ld	s7,24(sp)
 23c:	6125                	addi	sp,sp,96
 23e:	8082                	ret

0000000000000240 <stat>:

int
stat(const char *n, struct stat *st)
{
 240:	1101                	addi	sp,sp,-32
 242:	ec06                	sd	ra,24(sp)
 244:	e822                	sd	s0,16(sp)
 246:	e426                	sd	s1,8(sp)
 248:	e04a                	sd	s2,0(sp)
 24a:	1000                	addi	s0,sp,32
 24c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 24e:	4581                	li	a1,0
 250:	00000097          	auipc	ra,0x0
 254:	172080e7          	jalr	370(ra) # 3c2 <open>
  if(fd < 0)
 258:	02054563          	bltz	a0,282 <stat+0x42>
 25c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 25e:	85ca                	mv	a1,s2
 260:	00000097          	auipc	ra,0x0
 264:	17a080e7          	jalr	378(ra) # 3da <fstat>
 268:	892a                	mv	s2,a0
  close(fd);
 26a:	8526                	mv	a0,s1
 26c:	00000097          	auipc	ra,0x0
 270:	13e080e7          	jalr	318(ra) # 3aa <close>
  return r;
}
 274:	854a                	mv	a0,s2
 276:	60e2                	ld	ra,24(sp)
 278:	6442                	ld	s0,16(sp)
 27a:	64a2                	ld	s1,8(sp)
 27c:	6902                	ld	s2,0(sp)
 27e:	6105                	addi	sp,sp,32
 280:	8082                	ret
    return -1;
 282:	597d                	li	s2,-1
 284:	bfc5                	j	274 <stat+0x34>

0000000000000286 <atoi>:

int
atoi(const char *s)
{
 286:	1141                	addi	sp,sp,-16
 288:	e422                	sd	s0,8(sp)
 28a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 28c:	00054603          	lbu	a2,0(a0)
 290:	fd06079b          	addiw	a5,a2,-48
 294:	0ff7f793          	andi	a5,a5,255
 298:	4725                	li	a4,9
 29a:	02f76963          	bltu	a4,a5,2cc <atoi+0x46>
 29e:	86aa                	mv	a3,a0
  n = 0;
 2a0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2a2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2a4:	0685                	addi	a3,a3,1
 2a6:	0025179b          	slliw	a5,a0,0x2
 2aa:	9fa9                	addw	a5,a5,a0
 2ac:	0017979b          	slliw	a5,a5,0x1
 2b0:	9fb1                	addw	a5,a5,a2
 2b2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2b6:	0006c603          	lbu	a2,0(a3)
 2ba:	fd06071b          	addiw	a4,a2,-48
 2be:	0ff77713          	andi	a4,a4,255
 2c2:	fee5f1e3          	bgeu	a1,a4,2a4 <atoi+0x1e>
  return n;
}
 2c6:	6422                	ld	s0,8(sp)
 2c8:	0141                	addi	sp,sp,16
 2ca:	8082                	ret
  n = 0;
 2cc:	4501                	li	a0,0
 2ce:	bfe5                	j	2c6 <atoi+0x40>

00000000000002d0 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2d6:	02b57463          	bgeu	a0,a1,2fe <memmove+0x2e>
    while(n-- > 0)
 2da:	00c05f63          	blez	a2,2f8 <memmove+0x28>
 2de:	1602                	slli	a2,a2,0x20
 2e0:	9201                	srli	a2,a2,0x20
 2e2:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2e6:	872a                	mv	a4,a0
      *dst++ = *src++;
 2e8:	0585                	addi	a1,a1,1
 2ea:	0705                	addi	a4,a4,1
 2ec:	fff5c683          	lbu	a3,-1(a1)
 2f0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2f4:	fee79ae3          	bne	a5,a4,2e8 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2f8:	6422                	ld	s0,8(sp)
 2fa:	0141                	addi	sp,sp,16
 2fc:	8082                	ret
    dst += n;
 2fe:	00c50733          	add	a4,a0,a2
    src += n;
 302:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 304:	fec05ae3          	blez	a2,2f8 <memmove+0x28>
 308:	fff6079b          	addiw	a5,a2,-1
 30c:	1782                	slli	a5,a5,0x20
 30e:	9381                	srli	a5,a5,0x20
 310:	fff7c793          	not	a5,a5
 314:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 316:	15fd                	addi	a1,a1,-1
 318:	177d                	addi	a4,a4,-1
 31a:	0005c683          	lbu	a3,0(a1)
 31e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 322:	fee79ae3          	bne	a5,a4,316 <memmove+0x46>
 326:	bfc9                	j	2f8 <memmove+0x28>

0000000000000328 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 328:	1141                	addi	sp,sp,-16
 32a:	e422                	sd	s0,8(sp)
 32c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 32e:	ca05                	beqz	a2,35e <memcmp+0x36>
 330:	fff6069b          	addiw	a3,a2,-1
 334:	1682                	slli	a3,a3,0x20
 336:	9281                	srli	a3,a3,0x20
 338:	0685                	addi	a3,a3,1
 33a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 33c:	00054783          	lbu	a5,0(a0)
 340:	0005c703          	lbu	a4,0(a1)
 344:	00e79863          	bne	a5,a4,354 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 348:	0505                	addi	a0,a0,1
    p2++;
 34a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 34c:	fed518e3          	bne	a0,a3,33c <memcmp+0x14>
  }
  return 0;
 350:	4501                	li	a0,0
 352:	a019                	j	358 <memcmp+0x30>
      return *p1 - *p2;
 354:	40e7853b          	subw	a0,a5,a4
}
 358:	6422                	ld	s0,8(sp)
 35a:	0141                	addi	sp,sp,16
 35c:	8082                	ret
  return 0;
 35e:	4501                	li	a0,0
 360:	bfe5                	j	358 <memcmp+0x30>

0000000000000362 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 362:	1141                	addi	sp,sp,-16
 364:	e406                	sd	ra,8(sp)
 366:	e022                	sd	s0,0(sp)
 368:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 36a:	00000097          	auipc	ra,0x0
 36e:	f66080e7          	jalr	-154(ra) # 2d0 <memmove>
}
 372:	60a2                	ld	ra,8(sp)
 374:	6402                	ld	s0,0(sp)
 376:	0141                	addi	sp,sp,16
 378:	8082                	ret

000000000000037a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 37a:	4885                	li	a7,1
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <exit>:
.global exit
exit:
 li a7, SYS_exit
 382:	4889                	li	a7,2
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <wait>:
.global wait
wait:
 li a7, SYS_wait
 38a:	488d                	li	a7,3
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 392:	4891                	li	a7,4
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <read>:
.global read
read:
 li a7, SYS_read
 39a:	4895                	li	a7,5
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <write>:
.global write
write:
 li a7, SYS_write
 3a2:	48c1                	li	a7,16
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <close>:
.global close
close:
 li a7, SYS_close
 3aa:	48d5                	li	a7,21
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3b2:	4899                	li	a7,6
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <exec>:
.global exec
exec:
 li a7, SYS_exec
 3ba:	489d                	li	a7,7
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <open>:
.global open
open:
 li a7, SYS_open
 3c2:	48bd                	li	a7,15
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3ca:	48c5                	li	a7,17
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3d2:	48c9                	li	a7,18
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3da:	48a1                	li	a7,8
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <link>:
.global link
link:
 li a7, SYS_link
 3e2:	48cd                	li	a7,19
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3ea:	48d1                	li	a7,20
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3f2:	48a5                	li	a7,9
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <dup>:
.global dup
dup:
 li a7, SYS_dup
 3fa:	48a9                	li	a7,10
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 402:	48ad                	li	a7,11
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 40a:	48b1                	li	a7,12
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 412:	48b5                	li	a7,13
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 41a:	48b9                	li	a7,14
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 422:	1101                	addi	sp,sp,-32
 424:	ec06                	sd	ra,24(sp)
 426:	e822                	sd	s0,16(sp)
 428:	1000                	addi	s0,sp,32
 42a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 42e:	4605                	li	a2,1
 430:	fef40593          	addi	a1,s0,-17
 434:	00000097          	auipc	ra,0x0
 438:	f6e080e7          	jalr	-146(ra) # 3a2 <write>
}
 43c:	60e2                	ld	ra,24(sp)
 43e:	6442                	ld	s0,16(sp)
 440:	6105                	addi	sp,sp,32
 442:	8082                	ret

0000000000000444 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 444:	7139                	addi	sp,sp,-64
 446:	fc06                	sd	ra,56(sp)
 448:	f822                	sd	s0,48(sp)
 44a:	f426                	sd	s1,40(sp)
 44c:	f04a                	sd	s2,32(sp)
 44e:	ec4e                	sd	s3,24(sp)
 450:	0080                	addi	s0,sp,64
 452:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 454:	c299                	beqz	a3,45a <printint+0x16>
 456:	0805c863          	bltz	a1,4e6 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 45a:	2581                	sext.w	a1,a1
  neg = 0;
 45c:	4881                	li	a7,0
 45e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 462:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 464:	2601                	sext.w	a2,a2
 466:	00000517          	auipc	a0,0x0
 46a:	46250513          	addi	a0,a0,1122 # 8c8 <digits>
 46e:	883a                	mv	a6,a4
 470:	2705                	addiw	a4,a4,1
 472:	02c5f7bb          	remuw	a5,a1,a2
 476:	1782                	slli	a5,a5,0x20
 478:	9381                	srli	a5,a5,0x20
 47a:	97aa                	add	a5,a5,a0
 47c:	0007c783          	lbu	a5,0(a5)
 480:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 484:	0005879b          	sext.w	a5,a1
 488:	02c5d5bb          	divuw	a1,a1,a2
 48c:	0685                	addi	a3,a3,1
 48e:	fec7f0e3          	bgeu	a5,a2,46e <printint+0x2a>
  if(neg)
 492:	00088b63          	beqz	a7,4a8 <printint+0x64>
    buf[i++] = '-';
 496:	fd040793          	addi	a5,s0,-48
 49a:	973e                	add	a4,a4,a5
 49c:	02d00793          	li	a5,45
 4a0:	fef70823          	sb	a5,-16(a4)
 4a4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4a8:	02e05863          	blez	a4,4d8 <printint+0x94>
 4ac:	fc040793          	addi	a5,s0,-64
 4b0:	00e78933          	add	s2,a5,a4
 4b4:	fff78993          	addi	s3,a5,-1
 4b8:	99ba                	add	s3,s3,a4
 4ba:	377d                	addiw	a4,a4,-1
 4bc:	1702                	slli	a4,a4,0x20
 4be:	9301                	srli	a4,a4,0x20
 4c0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4c4:	fff94583          	lbu	a1,-1(s2)
 4c8:	8526                	mv	a0,s1
 4ca:	00000097          	auipc	ra,0x0
 4ce:	f58080e7          	jalr	-168(ra) # 422 <putc>
  while(--i >= 0)
 4d2:	197d                	addi	s2,s2,-1
 4d4:	ff3918e3          	bne	s2,s3,4c4 <printint+0x80>
}
 4d8:	70e2                	ld	ra,56(sp)
 4da:	7442                	ld	s0,48(sp)
 4dc:	74a2                	ld	s1,40(sp)
 4de:	7902                	ld	s2,32(sp)
 4e0:	69e2                	ld	s3,24(sp)
 4e2:	6121                	addi	sp,sp,64
 4e4:	8082                	ret
    x = -xx;
 4e6:	40b005bb          	negw	a1,a1
    neg = 1;
 4ea:	4885                	li	a7,1
    x = -xx;
 4ec:	bf8d                	j	45e <printint+0x1a>

00000000000004ee <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ee:	7119                	addi	sp,sp,-128
 4f0:	fc86                	sd	ra,120(sp)
 4f2:	f8a2                	sd	s0,112(sp)
 4f4:	f4a6                	sd	s1,104(sp)
 4f6:	f0ca                	sd	s2,96(sp)
 4f8:	ecce                	sd	s3,88(sp)
 4fa:	e8d2                	sd	s4,80(sp)
 4fc:	e4d6                	sd	s5,72(sp)
 4fe:	e0da                	sd	s6,64(sp)
 500:	fc5e                	sd	s7,56(sp)
 502:	f862                	sd	s8,48(sp)
 504:	f466                	sd	s9,40(sp)
 506:	f06a                	sd	s10,32(sp)
 508:	ec6e                	sd	s11,24(sp)
 50a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 50c:	0005c903          	lbu	s2,0(a1)
 510:	18090f63          	beqz	s2,6ae <vprintf+0x1c0>
 514:	8aaa                	mv	s5,a0
 516:	8b32                	mv	s6,a2
 518:	00158493          	addi	s1,a1,1
  state = 0;
 51c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 51e:	02500a13          	li	s4,37
      if(c == 'd'){
 522:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 526:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 52a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 52e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 532:	00000b97          	auipc	s7,0x0
 536:	396b8b93          	addi	s7,s7,918 # 8c8 <digits>
 53a:	a839                	j	558 <vprintf+0x6a>
        putc(fd, c);
 53c:	85ca                	mv	a1,s2
 53e:	8556                	mv	a0,s5
 540:	00000097          	auipc	ra,0x0
 544:	ee2080e7          	jalr	-286(ra) # 422 <putc>
 548:	a019                	j	54e <vprintf+0x60>
    } else if(state == '%'){
 54a:	01498f63          	beq	s3,s4,568 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 54e:	0485                	addi	s1,s1,1
 550:	fff4c903          	lbu	s2,-1(s1)
 554:	14090d63          	beqz	s2,6ae <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 558:	0009079b          	sext.w	a5,s2
    if(state == 0){
 55c:	fe0997e3          	bnez	s3,54a <vprintf+0x5c>
      if(c == '%'){
 560:	fd479ee3          	bne	a5,s4,53c <vprintf+0x4e>
        state = '%';
 564:	89be                	mv	s3,a5
 566:	b7e5                	j	54e <vprintf+0x60>
      if(c == 'd'){
 568:	05878063          	beq	a5,s8,5a8 <vprintf+0xba>
      } else if(c == 'l') {
 56c:	05978c63          	beq	a5,s9,5c4 <vprintf+0xd6>
      } else if(c == 'x') {
 570:	07a78863          	beq	a5,s10,5e0 <vprintf+0xf2>
      } else if(c == 'p') {
 574:	09b78463          	beq	a5,s11,5fc <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 578:	07300713          	li	a4,115
 57c:	0ce78663          	beq	a5,a4,648 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 580:	06300713          	li	a4,99
 584:	0ee78e63          	beq	a5,a4,680 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 588:	11478863          	beq	a5,s4,698 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 58c:	85d2                	mv	a1,s4
 58e:	8556                	mv	a0,s5
 590:	00000097          	auipc	ra,0x0
 594:	e92080e7          	jalr	-366(ra) # 422 <putc>
        putc(fd, c);
 598:	85ca                	mv	a1,s2
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	e86080e7          	jalr	-378(ra) # 422 <putc>
      }
      state = 0;
 5a4:	4981                	li	s3,0
 5a6:	b765                	j	54e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5a8:	008b0913          	addi	s2,s6,8
 5ac:	4685                	li	a3,1
 5ae:	4629                	li	a2,10
 5b0:	000b2583          	lw	a1,0(s6)
 5b4:	8556                	mv	a0,s5
 5b6:	00000097          	auipc	ra,0x0
 5ba:	e8e080e7          	jalr	-370(ra) # 444 <printint>
 5be:	8b4a                	mv	s6,s2
      state = 0;
 5c0:	4981                	li	s3,0
 5c2:	b771                	j	54e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5c4:	008b0913          	addi	s2,s6,8
 5c8:	4681                	li	a3,0
 5ca:	4629                	li	a2,10
 5cc:	000b2583          	lw	a1,0(s6)
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	e72080e7          	jalr	-398(ra) # 444 <printint>
 5da:	8b4a                	mv	s6,s2
      state = 0;
 5dc:	4981                	li	s3,0
 5de:	bf85                	j	54e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5e0:	008b0913          	addi	s2,s6,8
 5e4:	4681                	li	a3,0
 5e6:	4641                	li	a2,16
 5e8:	000b2583          	lw	a1,0(s6)
 5ec:	8556                	mv	a0,s5
 5ee:	00000097          	auipc	ra,0x0
 5f2:	e56080e7          	jalr	-426(ra) # 444 <printint>
 5f6:	8b4a                	mv	s6,s2
      state = 0;
 5f8:	4981                	li	s3,0
 5fa:	bf91                	j	54e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5fc:	008b0793          	addi	a5,s6,8
 600:	f8f43423          	sd	a5,-120(s0)
 604:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 608:	03000593          	li	a1,48
 60c:	8556                	mv	a0,s5
 60e:	00000097          	auipc	ra,0x0
 612:	e14080e7          	jalr	-492(ra) # 422 <putc>
  putc(fd, 'x');
 616:	85ea                	mv	a1,s10
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	e08080e7          	jalr	-504(ra) # 422 <putc>
 622:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 624:	03c9d793          	srli	a5,s3,0x3c
 628:	97de                	add	a5,a5,s7
 62a:	0007c583          	lbu	a1,0(a5)
 62e:	8556                	mv	a0,s5
 630:	00000097          	auipc	ra,0x0
 634:	df2080e7          	jalr	-526(ra) # 422 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 638:	0992                	slli	s3,s3,0x4
 63a:	397d                	addiw	s2,s2,-1
 63c:	fe0914e3          	bnez	s2,624 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 640:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 644:	4981                	li	s3,0
 646:	b721                	j	54e <vprintf+0x60>
        s = va_arg(ap, char*);
 648:	008b0993          	addi	s3,s6,8
 64c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 650:	02090163          	beqz	s2,672 <vprintf+0x184>
        while(*s != 0){
 654:	00094583          	lbu	a1,0(s2)
 658:	c9a1                	beqz	a1,6a8 <vprintf+0x1ba>
          putc(fd, *s);
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	dc6080e7          	jalr	-570(ra) # 422 <putc>
          s++;
 664:	0905                	addi	s2,s2,1
        while(*s != 0){
 666:	00094583          	lbu	a1,0(s2)
 66a:	f9e5                	bnez	a1,65a <vprintf+0x16c>
        s = va_arg(ap, char*);
 66c:	8b4e                	mv	s6,s3
      state = 0;
 66e:	4981                	li	s3,0
 670:	bdf9                	j	54e <vprintf+0x60>
          s = "(null)";
 672:	00000917          	auipc	s2,0x0
 676:	24e90913          	addi	s2,s2,590 # 8c0 <malloc+0x108>
        while(*s != 0){
 67a:	02800593          	li	a1,40
 67e:	bff1                	j	65a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 680:	008b0913          	addi	s2,s6,8
 684:	000b4583          	lbu	a1,0(s6)
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	d98080e7          	jalr	-616(ra) # 422 <putc>
 692:	8b4a                	mv	s6,s2
      state = 0;
 694:	4981                	li	s3,0
 696:	bd65                	j	54e <vprintf+0x60>
        putc(fd, c);
 698:	85d2                	mv	a1,s4
 69a:	8556                	mv	a0,s5
 69c:	00000097          	auipc	ra,0x0
 6a0:	d86080e7          	jalr	-634(ra) # 422 <putc>
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	b565                	j	54e <vprintf+0x60>
        s = va_arg(ap, char*);
 6a8:	8b4e                	mv	s6,s3
      state = 0;
 6aa:	4981                	li	s3,0
 6ac:	b54d                	j	54e <vprintf+0x60>
    }
  }
}
 6ae:	70e6                	ld	ra,120(sp)
 6b0:	7446                	ld	s0,112(sp)
 6b2:	74a6                	ld	s1,104(sp)
 6b4:	7906                	ld	s2,96(sp)
 6b6:	69e6                	ld	s3,88(sp)
 6b8:	6a46                	ld	s4,80(sp)
 6ba:	6aa6                	ld	s5,72(sp)
 6bc:	6b06                	ld	s6,64(sp)
 6be:	7be2                	ld	s7,56(sp)
 6c0:	7c42                	ld	s8,48(sp)
 6c2:	7ca2                	ld	s9,40(sp)
 6c4:	7d02                	ld	s10,32(sp)
 6c6:	6de2                	ld	s11,24(sp)
 6c8:	6109                	addi	sp,sp,128
 6ca:	8082                	ret

00000000000006cc <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6cc:	715d                	addi	sp,sp,-80
 6ce:	ec06                	sd	ra,24(sp)
 6d0:	e822                	sd	s0,16(sp)
 6d2:	1000                	addi	s0,sp,32
 6d4:	e010                	sd	a2,0(s0)
 6d6:	e414                	sd	a3,8(s0)
 6d8:	e818                	sd	a4,16(s0)
 6da:	ec1c                	sd	a5,24(s0)
 6dc:	03043023          	sd	a6,32(s0)
 6e0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6e4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6e8:	8622                	mv	a2,s0
 6ea:	00000097          	auipc	ra,0x0
 6ee:	e04080e7          	jalr	-508(ra) # 4ee <vprintf>
}
 6f2:	60e2                	ld	ra,24(sp)
 6f4:	6442                	ld	s0,16(sp)
 6f6:	6161                	addi	sp,sp,80
 6f8:	8082                	ret

00000000000006fa <printf>:

void
printf(const char *fmt, ...)
{
 6fa:	711d                	addi	sp,sp,-96
 6fc:	ec06                	sd	ra,24(sp)
 6fe:	e822                	sd	s0,16(sp)
 700:	1000                	addi	s0,sp,32
 702:	e40c                	sd	a1,8(s0)
 704:	e810                	sd	a2,16(s0)
 706:	ec14                	sd	a3,24(s0)
 708:	f018                	sd	a4,32(s0)
 70a:	f41c                	sd	a5,40(s0)
 70c:	03043823          	sd	a6,48(s0)
 710:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 714:	00840613          	addi	a2,s0,8
 718:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 71c:	85aa                	mv	a1,a0
 71e:	4505                	li	a0,1
 720:	00000097          	auipc	ra,0x0
 724:	dce080e7          	jalr	-562(ra) # 4ee <vprintf>
}
 728:	60e2                	ld	ra,24(sp)
 72a:	6442                	ld	s0,16(sp)
 72c:	6125                	addi	sp,sp,96
 72e:	8082                	ret

0000000000000730 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 730:	1141                	addi	sp,sp,-16
 732:	e422                	sd	s0,8(sp)
 734:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 736:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 73a:	00000797          	auipc	a5,0x0
 73e:	1a67b783          	ld	a5,422(a5) # 8e0 <freep>
 742:	a805                	j	772 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 744:	4618                	lw	a4,8(a2)
 746:	9db9                	addw	a1,a1,a4
 748:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 74c:	6398                	ld	a4,0(a5)
 74e:	6318                	ld	a4,0(a4)
 750:	fee53823          	sd	a4,-16(a0)
 754:	a091                	j	798 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 756:	ff852703          	lw	a4,-8(a0)
 75a:	9e39                	addw	a2,a2,a4
 75c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 75e:	ff053703          	ld	a4,-16(a0)
 762:	e398                	sd	a4,0(a5)
 764:	a099                	j	7aa <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 766:	6398                	ld	a4,0(a5)
 768:	00e7e463          	bltu	a5,a4,770 <free+0x40>
 76c:	00e6ea63          	bltu	a3,a4,780 <free+0x50>
{
 770:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 772:	fed7fae3          	bgeu	a5,a3,766 <free+0x36>
 776:	6398                	ld	a4,0(a5)
 778:	00e6e463          	bltu	a3,a4,780 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 77c:	fee7eae3          	bltu	a5,a4,770 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 780:	ff852583          	lw	a1,-8(a0)
 784:	6390                	ld	a2,0(a5)
 786:	02059713          	slli	a4,a1,0x20
 78a:	9301                	srli	a4,a4,0x20
 78c:	0712                	slli	a4,a4,0x4
 78e:	9736                	add	a4,a4,a3
 790:	fae60ae3          	beq	a2,a4,744 <free+0x14>
    bp->s.ptr = p->s.ptr;
 794:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 798:	4790                	lw	a2,8(a5)
 79a:	02061713          	slli	a4,a2,0x20
 79e:	9301                	srli	a4,a4,0x20
 7a0:	0712                	slli	a4,a4,0x4
 7a2:	973e                	add	a4,a4,a5
 7a4:	fae689e3          	beq	a3,a4,756 <free+0x26>
  } else
    p->s.ptr = bp;
 7a8:	e394                	sd	a3,0(a5)
  freep = p;
 7aa:	00000717          	auipc	a4,0x0
 7ae:	12f73b23          	sd	a5,310(a4) # 8e0 <freep>
}
 7b2:	6422                	ld	s0,8(sp)
 7b4:	0141                	addi	sp,sp,16
 7b6:	8082                	ret

00000000000007b8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7b8:	7139                	addi	sp,sp,-64
 7ba:	fc06                	sd	ra,56(sp)
 7bc:	f822                	sd	s0,48(sp)
 7be:	f426                	sd	s1,40(sp)
 7c0:	f04a                	sd	s2,32(sp)
 7c2:	ec4e                	sd	s3,24(sp)
 7c4:	e852                	sd	s4,16(sp)
 7c6:	e456                	sd	s5,8(sp)
 7c8:	e05a                	sd	s6,0(sp)
 7ca:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7cc:	02051493          	slli	s1,a0,0x20
 7d0:	9081                	srli	s1,s1,0x20
 7d2:	04bd                	addi	s1,s1,15
 7d4:	8091                	srli	s1,s1,0x4
 7d6:	0014899b          	addiw	s3,s1,1
 7da:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7dc:	00000517          	auipc	a0,0x0
 7e0:	10453503          	ld	a0,260(a0) # 8e0 <freep>
 7e4:	c515                	beqz	a0,810 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e8:	4798                	lw	a4,8(a5)
 7ea:	02977f63          	bgeu	a4,s1,828 <malloc+0x70>
 7ee:	8a4e                	mv	s4,s3
 7f0:	0009871b          	sext.w	a4,s3
 7f4:	6685                	lui	a3,0x1
 7f6:	00d77363          	bgeu	a4,a3,7fc <malloc+0x44>
 7fa:	6a05                	lui	s4,0x1
 7fc:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 800:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 804:	00000917          	auipc	s2,0x0
 808:	0dc90913          	addi	s2,s2,220 # 8e0 <freep>
  if(p == (char*)-1)
 80c:	5afd                	li	s5,-1
 80e:	a88d                	j	880 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 810:	00000797          	auipc	a5,0x0
 814:	0d878793          	addi	a5,a5,216 # 8e8 <base>
 818:	00000717          	auipc	a4,0x0
 81c:	0cf73423          	sd	a5,200(a4) # 8e0 <freep>
 820:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 822:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 826:	b7e1                	j	7ee <malloc+0x36>
      if(p->s.size == nunits)
 828:	02e48b63          	beq	s1,a4,85e <malloc+0xa6>
        p->s.size -= nunits;
 82c:	4137073b          	subw	a4,a4,s3
 830:	c798                	sw	a4,8(a5)
        p += p->s.size;
 832:	1702                	slli	a4,a4,0x20
 834:	9301                	srli	a4,a4,0x20
 836:	0712                	slli	a4,a4,0x4
 838:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 83a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 83e:	00000717          	auipc	a4,0x0
 842:	0aa73123          	sd	a0,162(a4) # 8e0 <freep>
      return (void*)(p + 1);
 846:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 84a:	70e2                	ld	ra,56(sp)
 84c:	7442                	ld	s0,48(sp)
 84e:	74a2                	ld	s1,40(sp)
 850:	7902                	ld	s2,32(sp)
 852:	69e2                	ld	s3,24(sp)
 854:	6a42                	ld	s4,16(sp)
 856:	6aa2                	ld	s5,8(sp)
 858:	6b02                	ld	s6,0(sp)
 85a:	6121                	addi	sp,sp,64
 85c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 85e:	6398                	ld	a4,0(a5)
 860:	e118                	sd	a4,0(a0)
 862:	bff1                	j	83e <malloc+0x86>
  hp->s.size = nu;
 864:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 868:	0541                	addi	a0,a0,16
 86a:	00000097          	auipc	ra,0x0
 86e:	ec6080e7          	jalr	-314(ra) # 730 <free>
  return freep;
 872:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 876:	d971                	beqz	a0,84a <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 878:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 87a:	4798                	lw	a4,8(a5)
 87c:	fa9776e3          	bgeu	a4,s1,828 <malloc+0x70>
    if(p == freep)
 880:	00093703          	ld	a4,0(s2)
 884:	853e                	mv	a0,a5
 886:	fef719e3          	bne	a4,a5,878 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 88a:	8552                	mv	a0,s4
 88c:	00000097          	auipc	ra,0x0
 890:	b7e080e7          	jalr	-1154(ra) # 40a <sbrk>
  if(p == (char*)-1)
 894:	fd5518e3          	bne	a0,s5,864 <malloc+0xac>
        return 0;
 898:	4501                	li	a0,0
 89a:	bf45                	j	84a <malloc+0x92>
