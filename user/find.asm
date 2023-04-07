
user/_find:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <find>:
    提示是看ls.c文件，可以仿照这个文件去读取目录
    如果是文件直接输出，如果是目录就递归find
*/

void find(char* path, char* file)
{
   0:	d9010113          	addi	sp,sp,-624
   4:	26113423          	sd	ra,616(sp)
   8:	26813023          	sd	s0,608(sp)
   c:	24913c23          	sd	s1,600(sp)
  10:	25213823          	sd	s2,592(sp)
  14:	25313423          	sd	s3,584(sp)
  18:	25413023          	sd	s4,576(sp)
  1c:	23513c23          	sd	s5,568(sp)
  20:	23613823          	sd	s6,560(sp)
  24:	1c80                	addi	s0,sp,624
  26:	892a                	mv	s2,a0
  28:	89ae                	mv	s3,a1
    char buf[512];
    char *p;

    // 打开当前的文件或者文件夹,只读打开0只读，1只写，2写读
    int fd;
    if((fd = open(path, 0)) < 0)
  2a:	4581                	li	a1,0
  2c:	00000097          	auipc	ra,0x0
  30:	4ce080e7          	jalr	1230(ra) # 4fa <open>
  34:	06054263          	bltz	a0,98 <find+0x98>
  38:	84aa                	mv	s1,a0
        return;
    }
    // stat结构体获取文件或者目录信息
    // fstat和stat的区别就是一个是用文件描述符做参数，一个是用路径做参数
    struct stat st;
    if(fstat(fd, &st) < 0)
  3a:	da840593          	addi	a1,s0,-600
  3e:	00000097          	auipc	ra,0x0
  42:	4d4080e7          	jalr	1236(ra) # 512 <fstat>
  46:	06054463          	bltz	a0,ae <find+0xae>
        fprintf(2, "find: cannot stat %s\n", path);
        close(fd);
        return;
    }
    // find要做的是查找目录下的文件，所以给的path不是目录就报错
    if(st.type != T_DIR)
  4a:	db041703          	lh	a4,-592(s0)
  4e:	4785                	li	a5,1
  50:	06f70f63          	beq	a4,a5,ce <find+0xce>
    {
        fprintf(2, "find: non dir! %s\n", path);
  54:	864a                	mv	a2,s2
  56:	00001597          	auipc	a1,0x1
  5a:	9b258593          	addi	a1,a1,-1614 # a08 <malloc+0x118>
  5e:	4509                	li	a0,2
  60:	00000097          	auipc	ra,0x0
  64:	7a4080e7          	jalr	1956(ra) # 804 <fprintf>
        close(fd);
  68:	8526                	mv	a0,s1
  6a:	00000097          	auipc	ra,0x0
  6e:	478080e7          	jalr	1144(ra) # 4e2 <close>
        if(T_FILE == st.type && !strcmp(de.name , file))
        {
            printf("%s\n", buf);
        }
    }
}
  72:	26813083          	ld	ra,616(sp)
  76:	26013403          	ld	s0,608(sp)
  7a:	25813483          	ld	s1,600(sp)
  7e:	25013903          	ld	s2,592(sp)
  82:	24813983          	ld	s3,584(sp)
  86:	24013a03          	ld	s4,576(sp)
  8a:	23813a83          	ld	s5,568(sp)
  8e:	23013b03          	ld	s6,560(sp)
  92:	27010113          	addi	sp,sp,624
  96:	8082                	ret
        fprintf(2, "find: cannot open %s\n", path);
  98:	864a                	mv	a2,s2
  9a:	00001597          	auipc	a1,0x1
  9e:	93e58593          	addi	a1,a1,-1730 # 9d8 <malloc+0xe8>
  a2:	4509                	li	a0,2
  a4:	00000097          	auipc	ra,0x0
  a8:	760080e7          	jalr	1888(ra) # 804 <fprintf>
        return;
  ac:	b7d9                	j	72 <find+0x72>
        fprintf(2, "find: cannot stat %s\n", path);
  ae:	864a                	mv	a2,s2
  b0:	00001597          	auipc	a1,0x1
  b4:	94058593          	addi	a1,a1,-1728 # 9f0 <malloc+0x100>
  b8:	4509                	li	a0,2
  ba:	00000097          	auipc	ra,0x0
  be:	74a080e7          	jalr	1866(ra) # 804 <fprintf>
        close(fd);
  c2:	8526                	mv	a0,s1
  c4:	00000097          	auipc	ra,0x0
  c8:	41e080e7          	jalr	1054(ra) # 4e2 <close>
        return;
  cc:	b75d                	j	72 <find+0x72>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof(buf))
  ce:	854a                	mv	a0,s2
  d0:	00000097          	auipc	ra,0x0
  d4:	1c4080e7          	jalr	452(ra) # 294 <strlen>
  d8:	2541                	addiw	a0,a0,16
  da:	20000793          	li	a5,512
  de:	0ea7e363          	bltu	a5,a0,1c4 <find+0x1c4>
    strcpy(buf, path);
  e2:	85ca                	mv	a1,s2
  e4:	dc040513          	addi	a0,s0,-576
  e8:	00000097          	auipc	ra,0x0
  ec:	164080e7          	jalr	356(ra) # 24c <strcpy>
    p = buf + strlen(buf);
  f0:	dc040513          	addi	a0,s0,-576
  f4:	00000097          	auipc	ra,0x0
  f8:	1a0080e7          	jalr	416(ra) # 294 <strlen>
  fc:	02051913          	slli	s2,a0,0x20
 100:	02095913          	srli	s2,s2,0x20
 104:	dc040793          	addi	a5,s0,-576
 108:	993e                	add	s2,s2,a5
    *p++ = '/';
 10a:	00190b13          	addi	s6,s2,1
 10e:	02f00793          	li	a5,47
 112:	00f90023          	sb	a5,0(s2)
        if(!strcmp(de.name, ".") || !strcmp(de.name, ".."))
 116:	00001a17          	auipc	s4,0x1
 11a:	92aa0a13          	addi	s4,s4,-1750 # a40 <malloc+0x150>
 11e:	00001a97          	auipc	s5,0x1
 122:	92aa8a93          	addi	s5,s5,-1750 # a48 <malloc+0x158>
    while(read(fd, &de, sizeof(de)) == sizeof(de))  //相同表示读取成功了
 126:	4641                	li	a2,16
 128:	d9840593          	addi	a1,s0,-616
 12c:	8526                	mv	a0,s1
 12e:	00000097          	auipc	ra,0x0
 132:	3a4080e7          	jalr	932(ra) # 4d2 <read>
 136:	47c1                	li	a5,16
 138:	f2f51de3          	bne	a0,a5,72 <find+0x72>
        if(de.inum == 0)
 13c:	d9845783          	lhu	a5,-616(s0)
 140:	d3fd                	beqz	a5,126 <find+0x126>
        if(!strcmp(de.name, ".") || !strcmp(de.name, ".."))
 142:	85d2                	mv	a1,s4
 144:	d9a40513          	addi	a0,s0,-614
 148:	00000097          	auipc	ra,0x0
 14c:	120080e7          	jalr	288(ra) # 268 <strcmp>
 150:	d979                	beqz	a0,126 <find+0x126>
 152:	85d6                	mv	a1,s5
 154:	d9a40513          	addi	a0,s0,-614
 158:	00000097          	auipc	ra,0x0
 15c:	110080e7          	jalr	272(ra) # 268 <strcmp>
 160:	d179                	beqz	a0,126 <find+0x126>
        memmove(p, de.name, DIRSIZ);
 162:	4639                	li	a2,14
 164:	d9a40593          	addi	a1,s0,-614
 168:	855a                	mv	a0,s6
 16a:	00000097          	auipc	ra,0x0
 16e:	29e080e7          	jalr	670(ra) # 408 <memmove>
        p[DIRSIZ] = 0; // 放'/0'
 172:	000907a3          	sb	zero,15(s2)
        if(stat(buf, &st) < 0)
 176:	da840593          	addi	a1,s0,-600
 17a:	dc040513          	addi	a0,s0,-576
 17e:	00000097          	auipc	ra,0x0
 182:	1fa080e7          	jalr	506(ra) # 378 <stat>
 186:	04054e63          	bltz	a0,1e2 <find+0x1e2>
        if(T_DIR == st.type)
 18a:	db041703          	lh	a4,-592(s0)
 18e:	4785                	li	a5,1
 190:	06f70563          	beq	a4,a5,1fa <find+0x1fa>
        if(T_FILE == st.type && !strcmp(de.name , file))
 194:	db041703          	lh	a4,-592(s0)
 198:	4789                	li	a5,2
 19a:	f8f716e3          	bne	a4,a5,126 <find+0x126>
 19e:	85ce                	mv	a1,s3
 1a0:	d9a40513          	addi	a0,s0,-614
 1a4:	00000097          	auipc	ra,0x0
 1a8:	0c4080e7          	jalr	196(ra) # 268 <strcmp>
 1ac:	fd2d                	bnez	a0,126 <find+0x126>
            printf("%s\n", buf);
 1ae:	dc040593          	addi	a1,s0,-576
 1b2:	00001517          	auipc	a0,0x1
 1b6:	89e50513          	addi	a0,a0,-1890 # a50 <malloc+0x160>
 1ba:	00000097          	auipc	ra,0x0
 1be:	678080e7          	jalr	1656(ra) # 832 <printf>
 1c2:	b795                	j	126 <find+0x126>
        fprintf(2, "find: directory too long\n");
 1c4:	00001597          	auipc	a1,0x1
 1c8:	85c58593          	addi	a1,a1,-1956 # a20 <malloc+0x130>
 1cc:	4509                	li	a0,2
 1ce:	00000097          	auipc	ra,0x0
 1d2:	636080e7          	jalr	1590(ra) # 804 <fprintf>
        close(fd);
 1d6:	8526                	mv	a0,s1
 1d8:	00000097          	auipc	ra,0x0
 1dc:	30a080e7          	jalr	778(ra) # 4e2 <close>
        return;
 1e0:	bd49                	j	72 <find+0x72>
            fprintf(2, "find: cannot stat %s\n", buf);
 1e2:	dc040613          	addi	a2,s0,-576
 1e6:	00001597          	auipc	a1,0x1
 1ea:	80a58593          	addi	a1,a1,-2038 # 9f0 <malloc+0x100>
 1ee:	4509                	li	a0,2
 1f0:	00000097          	auipc	ra,0x0
 1f4:	614080e7          	jalr	1556(ra) # 804 <fprintf>
            continue;
 1f8:	b73d                	j	126 <find+0x126>
            find(buf,file);
 1fa:	85ce                	mv	a1,s3
 1fc:	dc040513          	addi	a0,s0,-576
 200:	00000097          	auipc	ra,0x0
 204:	e00080e7          	jalr	-512(ra) # 0 <find>
 208:	b771                	j	194 <find+0x194>

000000000000020a <main>:

int main(int argc, char* argv[])
{
 20a:	1141                	addi	sp,sp,-16
 20c:	e406                	sd	ra,8(sp)
 20e:	e022                	sd	s0,0(sp)
 210:	0800                	addi	s0,sp,16
    // 如果没有给够参数直接给当前文件符号 .find
    if(argc < 3)
 212:	4709                	li	a4,2
 214:	02a74063          	blt	a4,a0,234 <main+0x2a>
    {
        // 输出提示
        fprintf(2, "usage: find dirName fileName\n");
 218:	00001597          	auipc	a1,0x1
 21c:	84058593          	addi	a1,a1,-1984 # a58 <malloc+0x168>
 220:	4509                	li	a0,2
 222:	00000097          	auipc	ra,0x0
 226:	5e2080e7          	jalr	1506(ra) # 804 <fprintf>
        // 异常退出
        exit(1);
 22a:	4505                	li	a0,1
 22c:	00000097          	auipc	ra,0x0
 230:	28e080e7          	jalr	654(ra) # 4ba <exit>
 234:	87ae                	mv	a5,a1
    }
    // find dir filename
    find(argv[1], argv[2]);
 236:	698c                	ld	a1,16(a1)
 238:	6788                	ld	a0,8(a5)
 23a:	00000097          	auipc	ra,0x0
 23e:	dc6080e7          	jalr	-570(ra) # 0 <find>
    exit(0);
 242:	4501                	li	a0,0
 244:	00000097          	auipc	ra,0x0
 248:	276080e7          	jalr	630(ra) # 4ba <exit>

000000000000024c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 24c:	1141                	addi	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 252:	87aa                	mv	a5,a0
 254:	0585                	addi	a1,a1,1
 256:	0785                	addi	a5,a5,1
 258:	fff5c703          	lbu	a4,-1(a1)
 25c:	fee78fa3          	sb	a4,-1(a5)
 260:	fb75                	bnez	a4,254 <strcpy+0x8>
    ;
  return os;
}
 262:	6422                	ld	s0,8(sp)
 264:	0141                	addi	sp,sp,16
 266:	8082                	ret

0000000000000268 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 268:	1141                	addi	sp,sp,-16
 26a:	e422                	sd	s0,8(sp)
 26c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 26e:	00054783          	lbu	a5,0(a0)
 272:	cb91                	beqz	a5,286 <strcmp+0x1e>
 274:	0005c703          	lbu	a4,0(a1)
 278:	00f71763          	bne	a4,a5,286 <strcmp+0x1e>
    p++, q++;
 27c:	0505                	addi	a0,a0,1
 27e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 280:	00054783          	lbu	a5,0(a0)
 284:	fbe5                	bnez	a5,274 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 286:	0005c503          	lbu	a0,0(a1)
}
 28a:	40a7853b          	subw	a0,a5,a0
 28e:	6422                	ld	s0,8(sp)
 290:	0141                	addi	sp,sp,16
 292:	8082                	ret

0000000000000294 <strlen>:

uint
strlen(const char *s)
{
 294:	1141                	addi	sp,sp,-16
 296:	e422                	sd	s0,8(sp)
 298:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 29a:	00054783          	lbu	a5,0(a0)
 29e:	cf91                	beqz	a5,2ba <strlen+0x26>
 2a0:	0505                	addi	a0,a0,1
 2a2:	87aa                	mv	a5,a0
 2a4:	4685                	li	a3,1
 2a6:	9e89                	subw	a3,a3,a0
 2a8:	00f6853b          	addw	a0,a3,a5
 2ac:	0785                	addi	a5,a5,1
 2ae:	fff7c703          	lbu	a4,-1(a5)
 2b2:	fb7d                	bnez	a4,2a8 <strlen+0x14>
    ;
  return n;
}
 2b4:	6422                	ld	s0,8(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret
  for(n = 0; s[n]; n++)
 2ba:	4501                	li	a0,0
 2bc:	bfe5                	j	2b4 <strlen+0x20>

00000000000002be <memset>:

void*
memset(void *dst, int c, uint n)
{
 2be:	1141                	addi	sp,sp,-16
 2c0:	e422                	sd	s0,8(sp)
 2c2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2c4:	ca19                	beqz	a2,2da <memset+0x1c>
 2c6:	87aa                	mv	a5,a0
 2c8:	1602                	slli	a2,a2,0x20
 2ca:	9201                	srli	a2,a2,0x20
 2cc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 2d0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2d4:	0785                	addi	a5,a5,1
 2d6:	fee79de3          	bne	a5,a4,2d0 <memset+0x12>
  }
  return dst;
}
 2da:	6422                	ld	s0,8(sp)
 2dc:	0141                	addi	sp,sp,16
 2de:	8082                	ret

00000000000002e0 <strchr>:

char*
strchr(const char *s, char c)
{
 2e0:	1141                	addi	sp,sp,-16
 2e2:	e422                	sd	s0,8(sp)
 2e4:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2e6:	00054783          	lbu	a5,0(a0)
 2ea:	cb99                	beqz	a5,300 <strchr+0x20>
    if(*s == c)
 2ec:	00f58763          	beq	a1,a5,2fa <strchr+0x1a>
  for(; *s; s++)
 2f0:	0505                	addi	a0,a0,1
 2f2:	00054783          	lbu	a5,0(a0)
 2f6:	fbfd                	bnez	a5,2ec <strchr+0xc>
      return (char*)s;
  return 0;
 2f8:	4501                	li	a0,0
}
 2fa:	6422                	ld	s0,8(sp)
 2fc:	0141                	addi	sp,sp,16
 2fe:	8082                	ret
  return 0;
 300:	4501                	li	a0,0
 302:	bfe5                	j	2fa <strchr+0x1a>

0000000000000304 <gets>:

char*
gets(char *buf, int max)
{
 304:	711d                	addi	sp,sp,-96
 306:	ec86                	sd	ra,88(sp)
 308:	e8a2                	sd	s0,80(sp)
 30a:	e4a6                	sd	s1,72(sp)
 30c:	e0ca                	sd	s2,64(sp)
 30e:	fc4e                	sd	s3,56(sp)
 310:	f852                	sd	s4,48(sp)
 312:	f456                	sd	s5,40(sp)
 314:	f05a                	sd	s6,32(sp)
 316:	ec5e                	sd	s7,24(sp)
 318:	1080                	addi	s0,sp,96
 31a:	8baa                	mv	s7,a0
 31c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 31e:	892a                	mv	s2,a0
 320:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 322:	4aa9                	li	s5,10
 324:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 326:	89a6                	mv	s3,s1
 328:	2485                	addiw	s1,s1,1
 32a:	0344d863          	bge	s1,s4,35a <gets+0x56>
    cc = read(0, &c, 1);
 32e:	4605                	li	a2,1
 330:	faf40593          	addi	a1,s0,-81
 334:	4501                	li	a0,0
 336:	00000097          	auipc	ra,0x0
 33a:	19c080e7          	jalr	412(ra) # 4d2 <read>
    if(cc < 1)
 33e:	00a05e63          	blez	a0,35a <gets+0x56>
    buf[i++] = c;
 342:	faf44783          	lbu	a5,-81(s0)
 346:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 34a:	01578763          	beq	a5,s5,358 <gets+0x54>
 34e:	0905                	addi	s2,s2,1
 350:	fd679be3          	bne	a5,s6,326 <gets+0x22>
  for(i=0; i+1 < max; ){
 354:	89a6                	mv	s3,s1
 356:	a011                	j	35a <gets+0x56>
 358:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 35a:	99de                	add	s3,s3,s7
 35c:	00098023          	sb	zero,0(s3)
  return buf;
}
 360:	855e                	mv	a0,s7
 362:	60e6                	ld	ra,88(sp)
 364:	6446                	ld	s0,80(sp)
 366:	64a6                	ld	s1,72(sp)
 368:	6906                	ld	s2,64(sp)
 36a:	79e2                	ld	s3,56(sp)
 36c:	7a42                	ld	s4,48(sp)
 36e:	7aa2                	ld	s5,40(sp)
 370:	7b02                	ld	s6,32(sp)
 372:	6be2                	ld	s7,24(sp)
 374:	6125                	addi	sp,sp,96
 376:	8082                	ret

0000000000000378 <stat>:

int
stat(const char *n, struct stat *st)
{
 378:	1101                	addi	sp,sp,-32
 37a:	ec06                	sd	ra,24(sp)
 37c:	e822                	sd	s0,16(sp)
 37e:	e426                	sd	s1,8(sp)
 380:	e04a                	sd	s2,0(sp)
 382:	1000                	addi	s0,sp,32
 384:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 386:	4581                	li	a1,0
 388:	00000097          	auipc	ra,0x0
 38c:	172080e7          	jalr	370(ra) # 4fa <open>
  if(fd < 0)
 390:	02054563          	bltz	a0,3ba <stat+0x42>
 394:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 396:	85ca                	mv	a1,s2
 398:	00000097          	auipc	ra,0x0
 39c:	17a080e7          	jalr	378(ra) # 512 <fstat>
 3a0:	892a                	mv	s2,a0
  close(fd);
 3a2:	8526                	mv	a0,s1
 3a4:	00000097          	auipc	ra,0x0
 3a8:	13e080e7          	jalr	318(ra) # 4e2 <close>
  return r;
}
 3ac:	854a                	mv	a0,s2
 3ae:	60e2                	ld	ra,24(sp)
 3b0:	6442                	ld	s0,16(sp)
 3b2:	64a2                	ld	s1,8(sp)
 3b4:	6902                	ld	s2,0(sp)
 3b6:	6105                	addi	sp,sp,32
 3b8:	8082                	ret
    return -1;
 3ba:	597d                	li	s2,-1
 3bc:	bfc5                	j	3ac <stat+0x34>

00000000000003be <atoi>:

int
atoi(const char *s)
{
 3be:	1141                	addi	sp,sp,-16
 3c0:	e422                	sd	s0,8(sp)
 3c2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3c4:	00054603          	lbu	a2,0(a0)
 3c8:	fd06079b          	addiw	a5,a2,-48
 3cc:	0ff7f793          	andi	a5,a5,255
 3d0:	4725                	li	a4,9
 3d2:	02f76963          	bltu	a4,a5,404 <atoi+0x46>
 3d6:	86aa                	mv	a3,a0
  n = 0;
 3d8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3da:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3dc:	0685                	addi	a3,a3,1
 3de:	0025179b          	slliw	a5,a0,0x2
 3e2:	9fa9                	addw	a5,a5,a0
 3e4:	0017979b          	slliw	a5,a5,0x1
 3e8:	9fb1                	addw	a5,a5,a2
 3ea:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3ee:	0006c603          	lbu	a2,0(a3)
 3f2:	fd06071b          	addiw	a4,a2,-48
 3f6:	0ff77713          	andi	a4,a4,255
 3fa:	fee5f1e3          	bgeu	a1,a4,3dc <atoi+0x1e>
  return n;
}
 3fe:	6422                	ld	s0,8(sp)
 400:	0141                	addi	sp,sp,16
 402:	8082                	ret
  n = 0;
 404:	4501                	li	a0,0
 406:	bfe5                	j	3fe <atoi+0x40>

0000000000000408 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 408:	1141                	addi	sp,sp,-16
 40a:	e422                	sd	s0,8(sp)
 40c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 40e:	02b57463          	bgeu	a0,a1,436 <memmove+0x2e>
    while(n-- > 0)
 412:	00c05f63          	blez	a2,430 <memmove+0x28>
 416:	1602                	slli	a2,a2,0x20
 418:	9201                	srli	a2,a2,0x20
 41a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 41e:	872a                	mv	a4,a0
      *dst++ = *src++;
 420:	0585                	addi	a1,a1,1
 422:	0705                	addi	a4,a4,1
 424:	fff5c683          	lbu	a3,-1(a1)
 428:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 42c:	fee79ae3          	bne	a5,a4,420 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 430:	6422                	ld	s0,8(sp)
 432:	0141                	addi	sp,sp,16
 434:	8082                	ret
    dst += n;
 436:	00c50733          	add	a4,a0,a2
    src += n;
 43a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 43c:	fec05ae3          	blez	a2,430 <memmove+0x28>
 440:	fff6079b          	addiw	a5,a2,-1
 444:	1782                	slli	a5,a5,0x20
 446:	9381                	srli	a5,a5,0x20
 448:	fff7c793          	not	a5,a5
 44c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 44e:	15fd                	addi	a1,a1,-1
 450:	177d                	addi	a4,a4,-1
 452:	0005c683          	lbu	a3,0(a1)
 456:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 45a:	fee79ae3          	bne	a5,a4,44e <memmove+0x46>
 45e:	bfc9                	j	430 <memmove+0x28>

0000000000000460 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 460:	1141                	addi	sp,sp,-16
 462:	e422                	sd	s0,8(sp)
 464:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 466:	ca05                	beqz	a2,496 <memcmp+0x36>
 468:	fff6069b          	addiw	a3,a2,-1
 46c:	1682                	slli	a3,a3,0x20
 46e:	9281                	srli	a3,a3,0x20
 470:	0685                	addi	a3,a3,1
 472:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 474:	00054783          	lbu	a5,0(a0)
 478:	0005c703          	lbu	a4,0(a1)
 47c:	00e79863          	bne	a5,a4,48c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 480:	0505                	addi	a0,a0,1
    p2++;
 482:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 484:	fed518e3          	bne	a0,a3,474 <memcmp+0x14>
  }
  return 0;
 488:	4501                	li	a0,0
 48a:	a019                	j	490 <memcmp+0x30>
      return *p1 - *p2;
 48c:	40e7853b          	subw	a0,a5,a4
}
 490:	6422                	ld	s0,8(sp)
 492:	0141                	addi	sp,sp,16
 494:	8082                	ret
  return 0;
 496:	4501                	li	a0,0
 498:	bfe5                	j	490 <memcmp+0x30>

000000000000049a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 49a:	1141                	addi	sp,sp,-16
 49c:	e406                	sd	ra,8(sp)
 49e:	e022                	sd	s0,0(sp)
 4a0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4a2:	00000097          	auipc	ra,0x0
 4a6:	f66080e7          	jalr	-154(ra) # 408 <memmove>
}
 4aa:	60a2                	ld	ra,8(sp)
 4ac:	6402                	ld	s0,0(sp)
 4ae:	0141                	addi	sp,sp,16
 4b0:	8082                	ret

00000000000004b2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4b2:	4885                	li	a7,1
 ecall
 4b4:	00000073          	ecall
 ret
 4b8:	8082                	ret

00000000000004ba <exit>:
.global exit
exit:
 li a7, SYS_exit
 4ba:	4889                	li	a7,2
 ecall
 4bc:	00000073          	ecall
 ret
 4c0:	8082                	ret

00000000000004c2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4c2:	488d                	li	a7,3
 ecall
 4c4:	00000073          	ecall
 ret
 4c8:	8082                	ret

00000000000004ca <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4ca:	4891                	li	a7,4
 ecall
 4cc:	00000073          	ecall
 ret
 4d0:	8082                	ret

00000000000004d2 <read>:
.global read
read:
 li a7, SYS_read
 4d2:	4895                	li	a7,5
 ecall
 4d4:	00000073          	ecall
 ret
 4d8:	8082                	ret

00000000000004da <write>:
.global write
write:
 li a7, SYS_write
 4da:	48c1                	li	a7,16
 ecall
 4dc:	00000073          	ecall
 ret
 4e0:	8082                	ret

00000000000004e2 <close>:
.global close
close:
 li a7, SYS_close
 4e2:	48d5                	li	a7,21
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <kill>:
.global kill
kill:
 li a7, SYS_kill
 4ea:	4899                	li	a7,6
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 4f2:	489d                	li	a7,7
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <open>:
.global open
open:
 li a7, SYS_open
 4fa:	48bd                	li	a7,15
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 502:	48c5                	li	a7,17
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 50a:	48c9                	li	a7,18
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 512:	48a1                	li	a7,8
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <link>:
.global link
link:
 li a7, SYS_link
 51a:	48cd                	li	a7,19
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 522:	48d1                	li	a7,20
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 52a:	48a5                	li	a7,9
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <dup>:
.global dup
dup:
 li a7, SYS_dup
 532:	48a9                	li	a7,10
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 53a:	48ad                	li	a7,11
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 542:	48b1                	li	a7,12
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 54a:	48b5                	li	a7,13
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 552:	48b9                	li	a7,14
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 55a:	1101                	addi	sp,sp,-32
 55c:	ec06                	sd	ra,24(sp)
 55e:	e822                	sd	s0,16(sp)
 560:	1000                	addi	s0,sp,32
 562:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 566:	4605                	li	a2,1
 568:	fef40593          	addi	a1,s0,-17
 56c:	00000097          	auipc	ra,0x0
 570:	f6e080e7          	jalr	-146(ra) # 4da <write>
}
 574:	60e2                	ld	ra,24(sp)
 576:	6442                	ld	s0,16(sp)
 578:	6105                	addi	sp,sp,32
 57a:	8082                	ret

000000000000057c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 57c:	7139                	addi	sp,sp,-64
 57e:	fc06                	sd	ra,56(sp)
 580:	f822                	sd	s0,48(sp)
 582:	f426                	sd	s1,40(sp)
 584:	f04a                	sd	s2,32(sp)
 586:	ec4e                	sd	s3,24(sp)
 588:	0080                	addi	s0,sp,64
 58a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 58c:	c299                	beqz	a3,592 <printint+0x16>
 58e:	0805c863          	bltz	a1,61e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 592:	2581                	sext.w	a1,a1
  neg = 0;
 594:	4881                	li	a7,0
 596:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 59a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 59c:	2601                	sext.w	a2,a2
 59e:	00000517          	auipc	a0,0x0
 5a2:	4e250513          	addi	a0,a0,1250 # a80 <digits>
 5a6:	883a                	mv	a6,a4
 5a8:	2705                	addiw	a4,a4,1
 5aa:	02c5f7bb          	remuw	a5,a1,a2
 5ae:	1782                	slli	a5,a5,0x20
 5b0:	9381                	srli	a5,a5,0x20
 5b2:	97aa                	add	a5,a5,a0
 5b4:	0007c783          	lbu	a5,0(a5)
 5b8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5bc:	0005879b          	sext.w	a5,a1
 5c0:	02c5d5bb          	divuw	a1,a1,a2
 5c4:	0685                	addi	a3,a3,1
 5c6:	fec7f0e3          	bgeu	a5,a2,5a6 <printint+0x2a>
  if(neg)
 5ca:	00088b63          	beqz	a7,5e0 <printint+0x64>
    buf[i++] = '-';
 5ce:	fd040793          	addi	a5,s0,-48
 5d2:	973e                	add	a4,a4,a5
 5d4:	02d00793          	li	a5,45
 5d8:	fef70823          	sb	a5,-16(a4)
 5dc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5e0:	02e05863          	blez	a4,610 <printint+0x94>
 5e4:	fc040793          	addi	a5,s0,-64
 5e8:	00e78933          	add	s2,a5,a4
 5ec:	fff78993          	addi	s3,a5,-1
 5f0:	99ba                	add	s3,s3,a4
 5f2:	377d                	addiw	a4,a4,-1
 5f4:	1702                	slli	a4,a4,0x20
 5f6:	9301                	srli	a4,a4,0x20
 5f8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5fc:	fff94583          	lbu	a1,-1(s2)
 600:	8526                	mv	a0,s1
 602:	00000097          	auipc	ra,0x0
 606:	f58080e7          	jalr	-168(ra) # 55a <putc>
  while(--i >= 0)
 60a:	197d                	addi	s2,s2,-1
 60c:	ff3918e3          	bne	s2,s3,5fc <printint+0x80>
}
 610:	70e2                	ld	ra,56(sp)
 612:	7442                	ld	s0,48(sp)
 614:	74a2                	ld	s1,40(sp)
 616:	7902                	ld	s2,32(sp)
 618:	69e2                	ld	s3,24(sp)
 61a:	6121                	addi	sp,sp,64
 61c:	8082                	ret
    x = -xx;
 61e:	40b005bb          	negw	a1,a1
    neg = 1;
 622:	4885                	li	a7,1
    x = -xx;
 624:	bf8d                	j	596 <printint+0x1a>

0000000000000626 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 626:	7119                	addi	sp,sp,-128
 628:	fc86                	sd	ra,120(sp)
 62a:	f8a2                	sd	s0,112(sp)
 62c:	f4a6                	sd	s1,104(sp)
 62e:	f0ca                	sd	s2,96(sp)
 630:	ecce                	sd	s3,88(sp)
 632:	e8d2                	sd	s4,80(sp)
 634:	e4d6                	sd	s5,72(sp)
 636:	e0da                	sd	s6,64(sp)
 638:	fc5e                	sd	s7,56(sp)
 63a:	f862                	sd	s8,48(sp)
 63c:	f466                	sd	s9,40(sp)
 63e:	f06a                	sd	s10,32(sp)
 640:	ec6e                	sd	s11,24(sp)
 642:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 644:	0005c903          	lbu	s2,0(a1)
 648:	18090f63          	beqz	s2,7e6 <vprintf+0x1c0>
 64c:	8aaa                	mv	s5,a0
 64e:	8b32                	mv	s6,a2
 650:	00158493          	addi	s1,a1,1
  state = 0;
 654:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 656:	02500a13          	li	s4,37
      if(c == 'd'){
 65a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 65e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 662:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 666:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 66a:	00000b97          	auipc	s7,0x0
 66e:	416b8b93          	addi	s7,s7,1046 # a80 <digits>
 672:	a839                	j	690 <vprintf+0x6a>
        putc(fd, c);
 674:	85ca                	mv	a1,s2
 676:	8556                	mv	a0,s5
 678:	00000097          	auipc	ra,0x0
 67c:	ee2080e7          	jalr	-286(ra) # 55a <putc>
 680:	a019                	j	686 <vprintf+0x60>
    } else if(state == '%'){
 682:	01498f63          	beq	s3,s4,6a0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 686:	0485                	addi	s1,s1,1
 688:	fff4c903          	lbu	s2,-1(s1)
 68c:	14090d63          	beqz	s2,7e6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 690:	0009079b          	sext.w	a5,s2
    if(state == 0){
 694:	fe0997e3          	bnez	s3,682 <vprintf+0x5c>
      if(c == '%'){
 698:	fd479ee3          	bne	a5,s4,674 <vprintf+0x4e>
        state = '%';
 69c:	89be                	mv	s3,a5
 69e:	b7e5                	j	686 <vprintf+0x60>
      if(c == 'd'){
 6a0:	05878063          	beq	a5,s8,6e0 <vprintf+0xba>
      } else if(c == 'l') {
 6a4:	05978c63          	beq	a5,s9,6fc <vprintf+0xd6>
      } else if(c == 'x') {
 6a8:	07a78863          	beq	a5,s10,718 <vprintf+0xf2>
      } else if(c == 'p') {
 6ac:	09b78463          	beq	a5,s11,734 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6b0:	07300713          	li	a4,115
 6b4:	0ce78663          	beq	a5,a4,780 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6b8:	06300713          	li	a4,99
 6bc:	0ee78e63          	beq	a5,a4,7b8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6c0:	11478863          	beq	a5,s4,7d0 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6c4:	85d2                	mv	a1,s4
 6c6:	8556                	mv	a0,s5
 6c8:	00000097          	auipc	ra,0x0
 6cc:	e92080e7          	jalr	-366(ra) # 55a <putc>
        putc(fd, c);
 6d0:	85ca                	mv	a1,s2
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e86080e7          	jalr	-378(ra) # 55a <putc>
      }
      state = 0;
 6dc:	4981                	li	s3,0
 6de:	b765                	j	686 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6e0:	008b0913          	addi	s2,s6,8
 6e4:	4685                	li	a3,1
 6e6:	4629                	li	a2,10
 6e8:	000b2583          	lw	a1,0(s6)
 6ec:	8556                	mv	a0,s5
 6ee:	00000097          	auipc	ra,0x0
 6f2:	e8e080e7          	jalr	-370(ra) # 57c <printint>
 6f6:	8b4a                	mv	s6,s2
      state = 0;
 6f8:	4981                	li	s3,0
 6fa:	b771                	j	686 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6fc:	008b0913          	addi	s2,s6,8
 700:	4681                	li	a3,0
 702:	4629                	li	a2,10
 704:	000b2583          	lw	a1,0(s6)
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	e72080e7          	jalr	-398(ra) # 57c <printint>
 712:	8b4a                	mv	s6,s2
      state = 0;
 714:	4981                	li	s3,0
 716:	bf85                	j	686 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 718:	008b0913          	addi	s2,s6,8
 71c:	4681                	li	a3,0
 71e:	4641                	li	a2,16
 720:	000b2583          	lw	a1,0(s6)
 724:	8556                	mv	a0,s5
 726:	00000097          	auipc	ra,0x0
 72a:	e56080e7          	jalr	-426(ra) # 57c <printint>
 72e:	8b4a                	mv	s6,s2
      state = 0;
 730:	4981                	li	s3,0
 732:	bf91                	j	686 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 734:	008b0793          	addi	a5,s6,8
 738:	f8f43423          	sd	a5,-120(s0)
 73c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 740:	03000593          	li	a1,48
 744:	8556                	mv	a0,s5
 746:	00000097          	auipc	ra,0x0
 74a:	e14080e7          	jalr	-492(ra) # 55a <putc>
  putc(fd, 'x');
 74e:	85ea                	mv	a1,s10
 750:	8556                	mv	a0,s5
 752:	00000097          	auipc	ra,0x0
 756:	e08080e7          	jalr	-504(ra) # 55a <putc>
 75a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 75c:	03c9d793          	srli	a5,s3,0x3c
 760:	97de                	add	a5,a5,s7
 762:	0007c583          	lbu	a1,0(a5)
 766:	8556                	mv	a0,s5
 768:	00000097          	auipc	ra,0x0
 76c:	df2080e7          	jalr	-526(ra) # 55a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 770:	0992                	slli	s3,s3,0x4
 772:	397d                	addiw	s2,s2,-1
 774:	fe0914e3          	bnez	s2,75c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 778:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 77c:	4981                	li	s3,0
 77e:	b721                	j	686 <vprintf+0x60>
        s = va_arg(ap, char*);
 780:	008b0993          	addi	s3,s6,8
 784:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 788:	02090163          	beqz	s2,7aa <vprintf+0x184>
        while(*s != 0){
 78c:	00094583          	lbu	a1,0(s2)
 790:	c9a1                	beqz	a1,7e0 <vprintf+0x1ba>
          putc(fd, *s);
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	dc6080e7          	jalr	-570(ra) # 55a <putc>
          s++;
 79c:	0905                	addi	s2,s2,1
        while(*s != 0){
 79e:	00094583          	lbu	a1,0(s2)
 7a2:	f9e5                	bnez	a1,792 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7a4:	8b4e                	mv	s6,s3
      state = 0;
 7a6:	4981                	li	s3,0
 7a8:	bdf9                	j	686 <vprintf+0x60>
          s = "(null)";
 7aa:	00000917          	auipc	s2,0x0
 7ae:	2ce90913          	addi	s2,s2,718 # a78 <malloc+0x188>
        while(*s != 0){
 7b2:	02800593          	li	a1,40
 7b6:	bff1                	j	792 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7b8:	008b0913          	addi	s2,s6,8
 7bc:	000b4583          	lbu	a1,0(s6)
 7c0:	8556                	mv	a0,s5
 7c2:	00000097          	auipc	ra,0x0
 7c6:	d98080e7          	jalr	-616(ra) # 55a <putc>
 7ca:	8b4a                	mv	s6,s2
      state = 0;
 7cc:	4981                	li	s3,0
 7ce:	bd65                	j	686 <vprintf+0x60>
        putc(fd, c);
 7d0:	85d2                	mv	a1,s4
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	d86080e7          	jalr	-634(ra) # 55a <putc>
      state = 0;
 7dc:	4981                	li	s3,0
 7de:	b565                	j	686 <vprintf+0x60>
        s = va_arg(ap, char*);
 7e0:	8b4e                	mv	s6,s3
      state = 0;
 7e2:	4981                	li	s3,0
 7e4:	b54d                	j	686 <vprintf+0x60>
    }
  }
}
 7e6:	70e6                	ld	ra,120(sp)
 7e8:	7446                	ld	s0,112(sp)
 7ea:	74a6                	ld	s1,104(sp)
 7ec:	7906                	ld	s2,96(sp)
 7ee:	69e6                	ld	s3,88(sp)
 7f0:	6a46                	ld	s4,80(sp)
 7f2:	6aa6                	ld	s5,72(sp)
 7f4:	6b06                	ld	s6,64(sp)
 7f6:	7be2                	ld	s7,56(sp)
 7f8:	7c42                	ld	s8,48(sp)
 7fa:	7ca2                	ld	s9,40(sp)
 7fc:	7d02                	ld	s10,32(sp)
 7fe:	6de2                	ld	s11,24(sp)
 800:	6109                	addi	sp,sp,128
 802:	8082                	ret

0000000000000804 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 804:	715d                	addi	sp,sp,-80
 806:	ec06                	sd	ra,24(sp)
 808:	e822                	sd	s0,16(sp)
 80a:	1000                	addi	s0,sp,32
 80c:	e010                	sd	a2,0(s0)
 80e:	e414                	sd	a3,8(s0)
 810:	e818                	sd	a4,16(s0)
 812:	ec1c                	sd	a5,24(s0)
 814:	03043023          	sd	a6,32(s0)
 818:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 81c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 820:	8622                	mv	a2,s0
 822:	00000097          	auipc	ra,0x0
 826:	e04080e7          	jalr	-508(ra) # 626 <vprintf>
}
 82a:	60e2                	ld	ra,24(sp)
 82c:	6442                	ld	s0,16(sp)
 82e:	6161                	addi	sp,sp,80
 830:	8082                	ret

0000000000000832 <printf>:

void
printf(const char *fmt, ...)
{
 832:	711d                	addi	sp,sp,-96
 834:	ec06                	sd	ra,24(sp)
 836:	e822                	sd	s0,16(sp)
 838:	1000                	addi	s0,sp,32
 83a:	e40c                	sd	a1,8(s0)
 83c:	e810                	sd	a2,16(s0)
 83e:	ec14                	sd	a3,24(s0)
 840:	f018                	sd	a4,32(s0)
 842:	f41c                	sd	a5,40(s0)
 844:	03043823          	sd	a6,48(s0)
 848:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 84c:	00840613          	addi	a2,s0,8
 850:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 854:	85aa                	mv	a1,a0
 856:	4505                	li	a0,1
 858:	00000097          	auipc	ra,0x0
 85c:	dce080e7          	jalr	-562(ra) # 626 <vprintf>
}
 860:	60e2                	ld	ra,24(sp)
 862:	6442                	ld	s0,16(sp)
 864:	6125                	addi	sp,sp,96
 866:	8082                	ret

0000000000000868 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 868:	1141                	addi	sp,sp,-16
 86a:	e422                	sd	s0,8(sp)
 86c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 86e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 872:	00000797          	auipc	a5,0x0
 876:	2267b783          	ld	a5,550(a5) # a98 <freep>
 87a:	a805                	j	8aa <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 87c:	4618                	lw	a4,8(a2)
 87e:	9db9                	addw	a1,a1,a4
 880:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 884:	6398                	ld	a4,0(a5)
 886:	6318                	ld	a4,0(a4)
 888:	fee53823          	sd	a4,-16(a0)
 88c:	a091                	j	8d0 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 88e:	ff852703          	lw	a4,-8(a0)
 892:	9e39                	addw	a2,a2,a4
 894:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 896:	ff053703          	ld	a4,-16(a0)
 89a:	e398                	sd	a4,0(a5)
 89c:	a099                	j	8e2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 89e:	6398                	ld	a4,0(a5)
 8a0:	00e7e463          	bltu	a5,a4,8a8 <free+0x40>
 8a4:	00e6ea63          	bltu	a3,a4,8b8 <free+0x50>
{
 8a8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8aa:	fed7fae3          	bgeu	a5,a3,89e <free+0x36>
 8ae:	6398                	ld	a4,0(a5)
 8b0:	00e6e463          	bltu	a3,a4,8b8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8b4:	fee7eae3          	bltu	a5,a4,8a8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8b8:	ff852583          	lw	a1,-8(a0)
 8bc:	6390                	ld	a2,0(a5)
 8be:	02059713          	slli	a4,a1,0x20
 8c2:	9301                	srli	a4,a4,0x20
 8c4:	0712                	slli	a4,a4,0x4
 8c6:	9736                	add	a4,a4,a3
 8c8:	fae60ae3          	beq	a2,a4,87c <free+0x14>
    bp->s.ptr = p->s.ptr;
 8cc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8d0:	4790                	lw	a2,8(a5)
 8d2:	02061713          	slli	a4,a2,0x20
 8d6:	9301                	srli	a4,a4,0x20
 8d8:	0712                	slli	a4,a4,0x4
 8da:	973e                	add	a4,a4,a5
 8dc:	fae689e3          	beq	a3,a4,88e <free+0x26>
  } else
    p->s.ptr = bp;
 8e0:	e394                	sd	a3,0(a5)
  freep = p;
 8e2:	00000717          	auipc	a4,0x0
 8e6:	1af73b23          	sd	a5,438(a4) # a98 <freep>
}
 8ea:	6422                	ld	s0,8(sp)
 8ec:	0141                	addi	sp,sp,16
 8ee:	8082                	ret

00000000000008f0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8f0:	7139                	addi	sp,sp,-64
 8f2:	fc06                	sd	ra,56(sp)
 8f4:	f822                	sd	s0,48(sp)
 8f6:	f426                	sd	s1,40(sp)
 8f8:	f04a                	sd	s2,32(sp)
 8fa:	ec4e                	sd	s3,24(sp)
 8fc:	e852                	sd	s4,16(sp)
 8fe:	e456                	sd	s5,8(sp)
 900:	e05a                	sd	s6,0(sp)
 902:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 904:	02051493          	slli	s1,a0,0x20
 908:	9081                	srli	s1,s1,0x20
 90a:	04bd                	addi	s1,s1,15
 90c:	8091                	srli	s1,s1,0x4
 90e:	0014899b          	addiw	s3,s1,1
 912:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 914:	00000517          	auipc	a0,0x0
 918:	18453503          	ld	a0,388(a0) # a98 <freep>
 91c:	c515                	beqz	a0,948 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 91e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 920:	4798                	lw	a4,8(a5)
 922:	02977f63          	bgeu	a4,s1,960 <malloc+0x70>
 926:	8a4e                	mv	s4,s3
 928:	0009871b          	sext.w	a4,s3
 92c:	6685                	lui	a3,0x1
 92e:	00d77363          	bgeu	a4,a3,934 <malloc+0x44>
 932:	6a05                	lui	s4,0x1
 934:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 938:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 93c:	00000917          	auipc	s2,0x0
 940:	15c90913          	addi	s2,s2,348 # a98 <freep>
  if(p == (char*)-1)
 944:	5afd                	li	s5,-1
 946:	a88d                	j	9b8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 948:	00000797          	auipc	a5,0x0
 94c:	15878793          	addi	a5,a5,344 # aa0 <base>
 950:	00000717          	auipc	a4,0x0
 954:	14f73423          	sd	a5,328(a4) # a98 <freep>
 958:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 95a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 95e:	b7e1                	j	926 <malloc+0x36>
      if(p->s.size == nunits)
 960:	02e48b63          	beq	s1,a4,996 <malloc+0xa6>
        p->s.size -= nunits;
 964:	4137073b          	subw	a4,a4,s3
 968:	c798                	sw	a4,8(a5)
        p += p->s.size;
 96a:	1702                	slli	a4,a4,0x20
 96c:	9301                	srli	a4,a4,0x20
 96e:	0712                	slli	a4,a4,0x4
 970:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 972:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 976:	00000717          	auipc	a4,0x0
 97a:	12a73123          	sd	a0,290(a4) # a98 <freep>
      return (void*)(p + 1);
 97e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 982:	70e2                	ld	ra,56(sp)
 984:	7442                	ld	s0,48(sp)
 986:	74a2                	ld	s1,40(sp)
 988:	7902                	ld	s2,32(sp)
 98a:	69e2                	ld	s3,24(sp)
 98c:	6a42                	ld	s4,16(sp)
 98e:	6aa2                	ld	s5,8(sp)
 990:	6b02                	ld	s6,0(sp)
 992:	6121                	addi	sp,sp,64
 994:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 996:	6398                	ld	a4,0(a5)
 998:	e118                	sd	a4,0(a0)
 99a:	bff1                	j	976 <malloc+0x86>
  hp->s.size = nu;
 99c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9a0:	0541                	addi	a0,a0,16
 9a2:	00000097          	auipc	ra,0x0
 9a6:	ec6080e7          	jalr	-314(ra) # 868 <free>
  return freep;
 9aa:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9ae:	d971                	beqz	a0,982 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9b0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9b2:	4798                	lw	a4,8(a5)
 9b4:	fa9776e3          	bgeu	a4,s1,960 <malloc+0x70>
    if(p == freep)
 9b8:	00093703          	ld	a4,0(s2)
 9bc:	853e                	mv	a0,a5
 9be:	fef719e3          	bne	a4,a5,9b0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9c2:	8552                	mv	a0,s4
 9c4:	00000097          	auipc	ra,0x0
 9c8:	b7e080e7          	jalr	-1154(ra) # 542 <sbrk>
  if(p == (char*)-1)
 9cc:	fd5518e3          	bne	a0,s5,99c <malloc+0xac>
        return 0;
 9d0:	4501                	li	a0,0
 9d2:	bf45                	j	982 <malloc+0x92>
