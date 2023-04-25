
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	ca478793          	addi	a5,a5,-860 # 80005d00 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e7c78793          	addi	a5,a5,-388 # 80000f22 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b68080e7          	jalr	-1176(ra) # 80000c74 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3f0080e7          	jalr	1008(ra) # 80002516 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	80e080e7          	jalr	-2034(ra) # 80000944 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bda080e7          	jalr	-1062(ra) # 80000d28 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	ad6080e7          	jalr	-1322(ra) # 80000c74 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	874080e7          	jalr	-1932(ra) # 80001a42 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	080080e7          	jalr	128(ra) # 8000225e <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	2a6080e7          	jalr	678(ra) # 800024c0 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	af2080e7          	jalr	-1294(ra) # 80000d28 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	adc080e7          	jalr	-1316(ra) # 80000d28 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	5c8080e7          	jalr	1480(ra) # 8000085e <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5b6080e7          	jalr	1462(ra) # 8000085e <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5aa080e7          	jalr	1450(ra) # 8000085e <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	5a0080e7          	jalr	1440(ra) # 8000085e <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	996080e7          	jalr	-1642(ra) # 80000c74 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	270080e7          	jalr	624(ra) # 8000256c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a1c080e7          	jalr	-1508(ra) # 80000d28 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f94080e7          	jalr	-108(ra) # 800023e4 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	772080e7          	jalr	1906(ra) # 80000be4 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	394080e7          	jalr	916(ra) # 8000080e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	d2e78793          	addi	a5,a5,-722 # 800221b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b9460613          	addi	a2,a2,-1132 # 80008058 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000552:	00011497          	auipc	s1,0x11
    80000556:	38648493          	addi	s1,s1,902 # 800118d8 <pr>
    8000055a:	00008597          	auipc	a1,0x8
    8000055e:	abe58593          	addi	a1,a1,-1346 # 80008018 <etext+0x18>
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	680080e7          	jalr	1664(ra) # 80000be4 <initlock>
  pr.locking = 1;
    8000056c:	4785                	li	a5,1
    8000056e:	cc9c                	sw	a5,24(s1)
}
    80000570:	60e2                	ld	ra,24(sp)
    80000572:	6442                	ld	s0,16(sp)
    80000574:	64a2                	ld	s1,8(sp)
    80000576:	6105                	addi	sp,sp,32
    80000578:	8082                	ret

000000008000057a <backtrace>:
// lab4-2
// backtrece()，不断循环输出当前函数的返回地址，直到到达该页表的起始地址。
// lab4-2 添加backtrace函数打印
void
backtrace(void)
{
    8000057a:	7179                	addi	sp,sp,-48
    8000057c:	f406                	sd	ra,40(sp)
    8000057e:	f022                	sd	s0,32(sp)
    80000580:	ec26                	sd	s1,24(sp)
    80000582:	e84a                	sd	s2,16(sp)
    80000584:	e44e                	sd	s3,8(sp)
    80000586:	1800                	addi	s0,sp,48
static inline uint64
r_fp()
{
    uint64 x;
    // 拿s0到x中
    asm volatile("mv %0, s0" : "=r" (x) );
    80000588:	84a2                	mv	s1,s0
    uint64 fp = r_fp();
    // printf("fp = %p\n", fp);
    // 栈的地址是负的，因为栈是从高地址到低地址的，所以栈顶的的地址比栈底更小，所以栈地址是负的
    // 向上调整到PGSIZE大小的倍数。栈最多一个PGSIZE，所以上调到PGSIZE的倍数肯定是PGSIZE
    // RISC-V 的用户栈空间占一个页面，这里得到最高地址
    uint64 top = PGROUNDUP(fp);
    8000058a:	6905                	lui	s2,0x1
    8000058c:	197d                	addi	s2,s2,-1
    8000058e:	9926                	add	s2,s2,s1
    80000590:	77fd                	lui	a5,0xfffff
    80000592:	00f97933          	and	s2,s2,a5
    // printf("top = %p\n", top); 是负值，所以每次往下减会不超过top
    printf("backtrace:\n");
    80000596:	00008517          	auipc	a0,0x8
    8000059a:	a8a50513          	addi	a0,a0,-1398 # 80008020 <etext+0x20>
    8000059e:	00000097          	auipc	ra,0x0
    800005a2:	08a080e7          	jalr	138(ra) # 80000628 <printf>

    // 不断循环直到顶
    // 每次往栈里面读16字节，也就是下一个函数的fp
    for(; fp < top; fp = *((uint64*)(fp-16)))
    800005a6:	0324f163          	bgeu	s1,s2,800005c8 <backtrace+0x4e>
    {
        // 打印返回地址，存在fp-8的位置。
        printf("%p\n", *((uint64*)(fp-8)));
    800005aa:	00008997          	auipc	s3,0x8
    800005ae:	a8698993          	addi	s3,s3,-1402 # 80008030 <etext+0x30>
    800005b2:	ff84b583          	ld	a1,-8(s1)
    800005b6:	854e                	mv	a0,s3
    800005b8:	00000097          	auipc	ra,0x0
    800005bc:	070080e7          	jalr	112(ra) # 80000628 <printf>
    for(; fp < top; fp = *((uint64*)(fp-16)))
    800005c0:	ff04b483          	ld	s1,-16(s1)
    800005c4:	ff24e7e3          	bltu	s1,s2,800005b2 <backtrace+0x38>
    }
}
    800005c8:	70a2                	ld	ra,40(sp)
    800005ca:	7402                	ld	s0,32(sp)
    800005cc:	64e2                	ld	s1,24(sp)
    800005ce:	6942                	ld	s2,16(sp)
    800005d0:	69a2                	ld	s3,8(sp)
    800005d2:	6145                	addi	sp,sp,48
    800005d4:	8082                	ret

00000000800005d6 <panic>:
{
    800005d6:	1101                	addi	sp,sp,-32
    800005d8:	ec06                	sd	ra,24(sp)
    800005da:	e822                	sd	s0,16(sp)
    800005dc:	e426                	sd	s1,8(sp)
    800005de:	1000                	addi	s0,sp,32
    800005e0:	84aa                	mv	s1,a0
  pr.locking = 0;
    800005e2:	00011797          	auipc	a5,0x11
    800005e6:	3007a723          	sw	zero,782(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    800005ea:	00008517          	auipc	a0,0x8
    800005ee:	a4e50513          	addi	a0,a0,-1458 # 80008038 <etext+0x38>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	036080e7          	jalr	54(ra) # 80000628 <printf>
  printf(s);
    800005fa:	8526                	mv	a0,s1
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	02c080e7          	jalr	44(ra) # 80000628 <printf>
  printf("\n");
    80000604:	00008517          	auipc	a0,0x8
    80000608:	adc50513          	addi	a0,a0,-1316 # 800080e0 <digits+0x88>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	01c080e7          	jalr	28(ra) # 80000628 <printf>
  backtrace();
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f66080e7          	jalr	-154(ra) # 8000057a <backtrace>
  panicked = 1; // freeze uart output from other CPUs
    8000061c:	4785                	li	a5,1
    8000061e:	00009717          	auipc	a4,0x9
    80000622:	9ef72123          	sw	a5,-1566(a4) # 80009000 <panicked>
  for(;;)
    80000626:	a001                	j	80000626 <panic+0x50>

0000000080000628 <printf>:
{
    80000628:	7131                	addi	sp,sp,-192
    8000062a:	fc86                	sd	ra,120(sp)
    8000062c:	f8a2                	sd	s0,112(sp)
    8000062e:	f4a6                	sd	s1,104(sp)
    80000630:	f0ca                	sd	s2,96(sp)
    80000632:	ecce                	sd	s3,88(sp)
    80000634:	e8d2                	sd	s4,80(sp)
    80000636:	e4d6                	sd	s5,72(sp)
    80000638:	e0da                	sd	s6,64(sp)
    8000063a:	fc5e                	sd	s7,56(sp)
    8000063c:	f862                	sd	s8,48(sp)
    8000063e:	f466                	sd	s9,40(sp)
    80000640:	f06a                	sd	s10,32(sp)
    80000642:	ec6e                	sd	s11,24(sp)
    80000644:	0100                	addi	s0,sp,128
    80000646:	8a2a                	mv	s4,a0
    80000648:	e40c                	sd	a1,8(s0)
    8000064a:	e810                	sd	a2,16(s0)
    8000064c:	ec14                	sd	a3,24(s0)
    8000064e:	f018                	sd	a4,32(s0)
    80000650:	f41c                	sd	a5,40(s0)
    80000652:	03043823          	sd	a6,48(s0)
    80000656:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000065a:	00011d97          	auipc	s11,0x11
    8000065e:	296dad83          	lw	s11,662(s11) # 800118f0 <pr+0x18>
  if(locking)
    80000662:	020d9b63          	bnez	s11,80000698 <printf+0x70>
  if (fmt == 0)
    80000666:	040a0263          	beqz	s4,800006aa <printf+0x82>
  va_start(ap, fmt);
    8000066a:	00840793          	addi	a5,s0,8
    8000066e:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000672:	000a4503          	lbu	a0,0(s4)
    80000676:	16050263          	beqz	a0,800007da <printf+0x1b2>
    8000067a:	4481                	li	s1,0
    if(c != '%'){
    8000067c:	02500a93          	li	s5,37
    switch(c){
    80000680:	07000b13          	li	s6,112
  consputc('x');
    80000684:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000686:	00008b97          	auipc	s7,0x8
    8000068a:	9d2b8b93          	addi	s7,s7,-1582 # 80008058 <digits>
    switch(c){
    8000068e:	07300c93          	li	s9,115
    80000692:	06400c13          	li	s8,100
    80000696:	a82d                	j	800006d0 <printf+0xa8>
    acquire(&pr.lock);
    80000698:	00011517          	auipc	a0,0x11
    8000069c:	24050513          	addi	a0,a0,576 # 800118d8 <pr>
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	5d4080e7          	jalr	1492(ra) # 80000c74 <acquire>
    800006a8:	bf7d                	j	80000666 <printf+0x3e>
    panic("null fmt");
    800006aa:	00008517          	auipc	a0,0x8
    800006ae:	99e50513          	addi	a0,a0,-1634 # 80008048 <etext+0x48>
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	f24080e7          	jalr	-220(ra) # 800005d6 <panic>
      consputc(c);
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bcc080e7          	jalr	-1076(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006c2:	2485                	addiw	s1,s1,1
    800006c4:	009a07b3          	add	a5,s4,s1
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	10050763          	beqz	a0,800007da <printf+0x1b2>
    if(c != '%'){
    800006d0:	ff5515e3          	bne	a0,s5,800006ba <printf+0x92>
    c = fmt[++i] & 0xff;
    800006d4:	2485                	addiw	s1,s1,1
    800006d6:	009a07b3          	add	a5,s4,s1
    800006da:	0007c783          	lbu	a5,0(a5)
    800006de:	0007891b          	sext.w	s2,a5
    if(c == 0)
    800006e2:	cfe5                	beqz	a5,800007da <printf+0x1b2>
    switch(c){
    800006e4:	05678a63          	beq	a5,s6,80000738 <printf+0x110>
    800006e8:	02fb7663          	bgeu	s6,a5,80000714 <printf+0xec>
    800006ec:	09978963          	beq	a5,s9,8000077e <printf+0x156>
    800006f0:	07800713          	li	a4,120
    800006f4:	0ce79863          	bne	a5,a4,800007c4 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    800006f8:	f8843783          	ld	a5,-120(s0)
    800006fc:	00878713          	addi	a4,a5,8
    80000700:	f8e43423          	sd	a4,-120(s0)
    80000704:	4605                	li	a2,1
    80000706:	85ea                	mv	a1,s10
    80000708:	4388                	lw	a0,0(a5)
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	d9c080e7          	jalr	-612(ra) # 800004a6 <printint>
      break;
    80000712:	bf45                	j	800006c2 <printf+0x9a>
    switch(c){
    80000714:	0b578263          	beq	a5,s5,800007b8 <printf+0x190>
    80000718:	0b879663          	bne	a5,s8,800007c4 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000071c:	f8843783          	ld	a5,-120(s0)
    80000720:	00878713          	addi	a4,a5,8
    80000724:	f8e43423          	sd	a4,-120(s0)
    80000728:	4605                	li	a2,1
    8000072a:	45a9                	li	a1,10
    8000072c:	4388                	lw	a0,0(a5)
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	d78080e7          	jalr	-648(ra) # 800004a6 <printint>
      break;
    80000736:	b771                	j	800006c2 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000738:	f8843783          	ld	a5,-120(s0)
    8000073c:	00878713          	addi	a4,a5,8
    80000740:	f8e43423          	sd	a4,-120(s0)
    80000744:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000748:	03000513          	li	a0,48
    8000074c:	00000097          	auipc	ra,0x0
    80000750:	b3a080e7          	jalr	-1222(ra) # 80000286 <consputc>
  consputc('x');
    80000754:	07800513          	li	a0,120
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	b2e080e7          	jalr	-1234(ra) # 80000286 <consputc>
    80000760:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000762:	03c9d793          	srli	a5,s3,0x3c
    80000766:	97de                	add	a5,a5,s7
    80000768:	0007c503          	lbu	a0,0(a5)
    8000076c:	00000097          	auipc	ra,0x0
    80000770:	b1a080e7          	jalr	-1254(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000774:	0992                	slli	s3,s3,0x4
    80000776:	397d                	addiw	s2,s2,-1
    80000778:	fe0915e3          	bnez	s2,80000762 <printf+0x13a>
    8000077c:	b799                	j	800006c2 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    8000077e:	f8843783          	ld	a5,-120(s0)
    80000782:	00878713          	addi	a4,a5,8
    80000786:	f8e43423          	sd	a4,-120(s0)
    8000078a:	0007b903          	ld	s2,0(a5)
    8000078e:	00090e63          	beqz	s2,800007aa <printf+0x182>
      for(; *s; s++)
    80000792:	00094503          	lbu	a0,0(s2) # 1000 <_entry-0x7ffff000>
    80000796:	d515                	beqz	a0,800006c2 <printf+0x9a>
        consputc(*s);
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	aee080e7          	jalr	-1298(ra) # 80000286 <consputc>
      for(; *s; s++)
    800007a0:	0905                	addi	s2,s2,1
    800007a2:	00094503          	lbu	a0,0(s2)
    800007a6:	f96d                	bnez	a0,80000798 <printf+0x170>
    800007a8:	bf29                	j	800006c2 <printf+0x9a>
        s = "(null)";
    800007aa:	00008917          	auipc	s2,0x8
    800007ae:	89690913          	addi	s2,s2,-1898 # 80008040 <etext+0x40>
      for(; *s; s++)
    800007b2:	02800513          	li	a0,40
    800007b6:	b7cd                	j	80000798 <printf+0x170>
      consputc('%');
    800007b8:	8556                	mv	a0,s5
    800007ba:	00000097          	auipc	ra,0x0
    800007be:	acc080e7          	jalr	-1332(ra) # 80000286 <consputc>
      break;
    800007c2:	b701                	j	800006c2 <printf+0x9a>
      consputc('%');
    800007c4:	8556                	mv	a0,s5
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	ac0080e7          	jalr	-1344(ra) # 80000286 <consputc>
      consputc(c);
    800007ce:	854a                	mv	a0,s2
    800007d0:	00000097          	auipc	ra,0x0
    800007d4:	ab6080e7          	jalr	-1354(ra) # 80000286 <consputc>
      break;
    800007d8:	b5ed                	j	800006c2 <printf+0x9a>
  if(locking)
    800007da:	020d9163          	bnez	s11,800007fc <printf+0x1d4>
}
    800007de:	70e6                	ld	ra,120(sp)
    800007e0:	7446                	ld	s0,112(sp)
    800007e2:	74a6                	ld	s1,104(sp)
    800007e4:	7906                	ld	s2,96(sp)
    800007e6:	69e6                	ld	s3,88(sp)
    800007e8:	6a46                	ld	s4,80(sp)
    800007ea:	6aa6                	ld	s5,72(sp)
    800007ec:	6b06                	ld	s6,64(sp)
    800007ee:	7be2                	ld	s7,56(sp)
    800007f0:	7c42                	ld	s8,48(sp)
    800007f2:	7ca2                	ld	s9,40(sp)
    800007f4:	7d02                	ld	s10,32(sp)
    800007f6:	6de2                	ld	s11,24(sp)
    800007f8:	6129                	addi	sp,sp,192
    800007fa:	8082                	ret
    release(&pr.lock);
    800007fc:	00011517          	auipc	a0,0x11
    80000800:	0dc50513          	addi	a0,a0,220 # 800118d8 <pr>
    80000804:	00000097          	auipc	ra,0x0
    80000808:	524080e7          	jalr	1316(ra) # 80000d28 <release>
}
    8000080c:	bfc9                	j	800007de <printf+0x1b6>

000000008000080e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000080e:	1141                	addi	sp,sp,-16
    80000810:	e406                	sd	ra,8(sp)
    80000812:	e022                	sd	s0,0(sp)
    80000814:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000081e:	f8000713          	li	a4,-128
    80000822:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000826:	470d                	li	a4,3
    80000828:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000082c:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000830:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000834:	469d                	li	a3,7
    80000836:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000083a:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000083e:	00008597          	auipc	a1,0x8
    80000842:	83258593          	addi	a1,a1,-1998 # 80008070 <digits+0x18>
    80000846:	00011517          	auipc	a0,0x11
    8000084a:	0b250513          	addi	a0,a0,178 # 800118f8 <uart_tx_lock>
    8000084e:	00000097          	auipc	ra,0x0
    80000852:	396080e7          	jalr	918(ra) # 80000be4 <initlock>
}
    80000856:	60a2                	ld	ra,8(sp)
    80000858:	6402                	ld	s0,0(sp)
    8000085a:	0141                	addi	sp,sp,16
    8000085c:	8082                	ret

000000008000085e <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000085e:	1101                	addi	sp,sp,-32
    80000860:	ec06                	sd	ra,24(sp)
    80000862:	e822                	sd	s0,16(sp)
    80000864:	e426                	sd	s1,8(sp)
    80000866:	1000                	addi	s0,sp,32
    80000868:	84aa                	mv	s1,a0
  push_off();
    8000086a:	00000097          	auipc	ra,0x0
    8000086e:	3be080e7          	jalr	958(ra) # 80000c28 <push_off>

  if(panicked){
    80000872:	00008797          	auipc	a5,0x8
    80000876:	78e7a783          	lw	a5,1934(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000087e:	c391                	beqz	a5,80000882 <uartputc_sync+0x24>
    for(;;)
    80000880:	a001                	j	80000880 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	dbf5                	beqz	a5,80000882 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000890:	0ff4f793          	andi	a5,s1,255
    80000894:	10000737          	lui	a4,0x10000
    80000898:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000089c:	00000097          	auipc	ra,0x0
    800008a0:	42c080e7          	jalr	1068(ra) # 80000cc8 <pop_off>
}
    800008a4:	60e2                	ld	ra,24(sp)
    800008a6:	6442                	ld	s0,16(sp)
    800008a8:	64a2                	ld	s1,8(sp)
    800008aa:	6105                	addi	sp,sp,32
    800008ac:	8082                	ret

00000000800008ae <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008ae:	00008797          	auipc	a5,0x8
    800008b2:	7567a783          	lw	a5,1878(a5) # 80009004 <uart_tx_r>
    800008b6:	00008717          	auipc	a4,0x8
    800008ba:	75272703          	lw	a4,1874(a4) # 80009008 <uart_tx_w>
    800008be:	08f70263          	beq	a4,a5,80000942 <uartstart+0x94>
{
    800008c2:	7139                	addi	sp,sp,-64
    800008c4:	fc06                	sd	ra,56(sp)
    800008c6:	f822                	sd	s0,48(sp)
    800008c8:	f426                	sd	s1,40(sp)
    800008ca:	f04a                	sd	s2,32(sp)
    800008cc:	ec4e                	sd	s3,24(sp)
    800008ce:	e852                	sd	s4,16(sp)
    800008d0:	e456                	sd	s5,8(sp)
    800008d2:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008d8:	00011a17          	auipc	s4,0x11
    800008dc:	020a0a13          	addi	s4,s4,32 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008e0:	00008497          	auipc	s1,0x8
    800008e4:	72448493          	addi	s1,s1,1828 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e8:	00008997          	auipc	s3,0x8
    800008ec:	72098993          	addi	s3,s3,1824 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008f0:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f4:	0ff77713          	andi	a4,a4,255
    800008f8:	02077713          	andi	a4,a4,32
    800008fc:	cb15                	beqz	a4,80000930 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008fe:	00fa0733          	add	a4,s4,a5
    80000902:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000906:	2785                	addiw	a5,a5,1
    80000908:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090c:	01b7571b          	srliw	a4,a4,0x1b
    80000910:	9fb9                	addw	a5,a5,a4
    80000912:	8bfd                	andi	a5,a5,31
    80000914:	9f99                	subw	a5,a5,a4
    80000916:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	aca080e7          	jalr	-1334(ra) # 800023e4 <wakeup>
    
    WriteReg(THR, c);
    80000922:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000926:	409c                	lw	a5,0(s1)
    80000928:	0009a703          	lw	a4,0(s3)
    8000092c:	fcf712e3          	bne	a4,a5,800008f0 <uartstart+0x42>
  }
}
    80000930:	70e2                	ld	ra,56(sp)
    80000932:	7442                	ld	s0,48(sp)
    80000934:	74a2                	ld	s1,40(sp)
    80000936:	7902                	ld	s2,32(sp)
    80000938:	69e2                	ld	s3,24(sp)
    8000093a:	6a42                	ld	s4,16(sp)
    8000093c:	6aa2                	ld	s5,8(sp)
    8000093e:	6121                	addi	sp,sp,64
    80000940:	8082                	ret
    80000942:	8082                	ret

0000000080000944 <uartputc>:
{
    80000944:	7179                	addi	sp,sp,-48
    80000946:	f406                	sd	ra,40(sp)
    80000948:	f022                	sd	s0,32(sp)
    8000094a:	ec26                	sd	s1,24(sp)
    8000094c:	e84a                	sd	s2,16(sp)
    8000094e:	e44e                	sd	s3,8(sp)
    80000950:	e052                	sd	s4,0(sp)
    80000952:	1800                	addi	s0,sp,48
    80000954:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000956:	00011517          	auipc	a0,0x11
    8000095a:	fa250513          	addi	a0,a0,-94 # 800118f8 <uart_tx_lock>
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	316080e7          	jalr	790(ra) # 80000c74 <acquire>
  if(panicked){
    80000966:	00008797          	auipc	a5,0x8
    8000096a:	69a7a783          	lw	a5,1690(a5) # 80009000 <panicked>
    8000096e:	c391                	beqz	a5,80000972 <uartputc+0x2e>
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000972:	00008717          	auipc	a4,0x8
    80000976:	69672703          	lw	a4,1686(a4) # 80009008 <uart_tx_w>
    8000097a:	0017079b          	addiw	a5,a4,1
    8000097e:	41f7d69b          	sraiw	a3,a5,0x1f
    80000982:	01b6d69b          	srliw	a3,a3,0x1b
    80000986:	9fb5                	addw	a5,a5,a3
    80000988:	8bfd                	andi	a5,a5,31
    8000098a:	9f95                	subw	a5,a5,a3
    8000098c:	00008697          	auipc	a3,0x8
    80000990:	6786a683          	lw	a3,1656(a3) # 80009004 <uart_tx_r>
    80000994:	04f69263          	bne	a3,a5,800009d8 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000998:	00011a17          	auipc	s4,0x11
    8000099c:	f60a0a13          	addi	s4,s4,-160 # 800118f8 <uart_tx_lock>
    800009a0:	00008497          	auipc	s1,0x8
    800009a4:	66448493          	addi	s1,s1,1636 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a8:	00008917          	auipc	s2,0x8
    800009ac:	66090913          	addi	s2,s2,1632 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009b0:	85d2                	mv	a1,s4
    800009b2:	8526                	mv	a0,s1
    800009b4:	00002097          	auipc	ra,0x2
    800009b8:	8aa080e7          	jalr	-1878(ra) # 8000225e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009bc:	00092703          	lw	a4,0(s2)
    800009c0:	0017079b          	addiw	a5,a4,1
    800009c4:	41f7d69b          	sraiw	a3,a5,0x1f
    800009c8:	01b6d69b          	srliw	a3,a3,0x1b
    800009cc:	9fb5                	addw	a5,a5,a3
    800009ce:	8bfd                	andi	a5,a5,31
    800009d0:	9f95                	subw	a5,a5,a3
    800009d2:	4094                	lw	a3,0(s1)
    800009d4:	fcf68ee3          	beq	a3,a5,800009b0 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009d8:	00011497          	auipc	s1,0x11
    800009dc:	f2048493          	addi	s1,s1,-224 # 800118f8 <uart_tx_lock>
    800009e0:	9726                	add	a4,a4,s1
    800009e2:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009e6:	00008717          	auipc	a4,0x8
    800009ea:	62f72123          	sw	a5,1570(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	ec0080e7          	jalr	-320(ra) # 800008ae <uartstart>
      release(&uart_tx_lock);
    800009f6:	8526                	mv	a0,s1
    800009f8:	00000097          	auipc	ra,0x0
    800009fc:	330080e7          	jalr	816(ra) # 80000d28 <release>
}
    80000a00:	70a2                	ld	ra,40(sp)
    80000a02:	7402                	ld	s0,32(sp)
    80000a04:	64e2                	ld	s1,24(sp)
    80000a06:	6942                	ld	s2,16(sp)
    80000a08:	69a2                	ld	s3,8(sp)
    80000a0a:	6a02                	ld	s4,0(sp)
    80000a0c:	6145                	addi	sp,sp,48
    80000a0e:	8082                	ret

0000000080000a10 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a10:	1141                	addi	sp,sp,-16
    80000a12:	e422                	sd	s0,8(sp)
    80000a14:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a16:	100007b7          	lui	a5,0x10000
    80000a1a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a1e:	8b85                	andi	a5,a5,1
    80000a20:	cb91                	beqz	a5,80000a34 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a22:	100007b7          	lui	a5,0x10000
    80000a26:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a2a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a2e:	6422                	ld	s0,8(sp)
    80000a30:	0141                	addi	sp,sp,16
    80000a32:	8082                	ret
    return -1;
    80000a34:	557d                	li	a0,-1
    80000a36:	bfe5                	j	80000a2e <uartgetc+0x1e>

0000000080000a38 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a38:	1101                	addi	sp,sp,-32
    80000a3a:	ec06                	sd	ra,24(sp)
    80000a3c:	e822                	sd	s0,16(sp)
    80000a3e:	e426                	sd	s1,8(sp)
    80000a40:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a42:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	fcc080e7          	jalr	-52(ra) # 80000a10 <uartgetc>
    if(c == -1)
    80000a4c:	00950763          	beq	a0,s1,80000a5a <uartintr+0x22>
      break;
    consoleintr(c);
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	878080e7          	jalr	-1928(ra) # 800002c8 <consoleintr>
  while(1){
    80000a58:	b7f5                	j	80000a44 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a5a:	00011497          	auipc	s1,0x11
    80000a5e:	e9e48493          	addi	s1,s1,-354 # 800118f8 <uart_tx_lock>
    80000a62:	8526                	mv	a0,s1
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	210080e7          	jalr	528(ra) # 80000c74 <acquire>
  uartstart();
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	e42080e7          	jalr	-446(ra) # 800008ae <uartstart>
  release(&uart_tx_lock);
    80000a74:	8526                	mv	a0,s1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2b2080e7          	jalr	690(ra) # 80000d28 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6105                	addi	sp,sp,32
    80000a86:	8082                	ret

0000000080000a88 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a88:	1101                	addi	sp,sp,-32
    80000a8a:	ec06                	sd	ra,24(sp)
    80000a8c:	e822                	sd	s0,16(sp)
    80000a8e:	e426                	sd	s1,8(sp)
    80000a90:	e04a                	sd	s2,0(sp)
    80000a92:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a94:	03451793          	slli	a5,a0,0x34
    80000a98:	ebb9                	bnez	a5,80000aee <kfree+0x66>
    80000a9a:	84aa                	mv	s1,a0
    80000a9c:	00026797          	auipc	a5,0x26
    80000aa0:	56478793          	addi	a5,a5,1380 # 80027000 <end>
    80000aa4:	04f56563          	bltu	a0,a5,80000aee <kfree+0x66>
    80000aa8:	47c5                	li	a5,17
    80000aaa:	07ee                	slli	a5,a5,0x1b
    80000aac:	04f57163          	bgeu	a0,a5,80000aee <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ab0:	6605                	lui	a2,0x1
    80000ab2:	4585                	li	a1,1
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	2bc080e7          	jalr	700(ra) # 80000d70 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000abc:	00011917          	auipc	s2,0x11
    80000ac0:	e7490913          	addi	s2,s2,-396 # 80011930 <kmem>
    80000ac4:	854a                	mv	a0,s2
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	1ae080e7          	jalr	430(ra) # 80000c74 <acquire>
  r->next = kmem.freelist;
    80000ace:	01893783          	ld	a5,24(s2)
    80000ad2:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ad4:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ad8:	854a                	mv	a0,s2
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	24e080e7          	jalr	590(ra) # 80000d28 <release>
}
    80000ae2:	60e2                	ld	ra,24(sp)
    80000ae4:	6442                	ld	s0,16(sp)
    80000ae6:	64a2                	ld	s1,8(sp)
    80000ae8:	6902                	ld	s2,0(sp)
    80000aea:	6105                	addi	sp,sp,32
    80000aec:	8082                	ret
    panic("kfree");
    80000aee:	00007517          	auipc	a0,0x7
    80000af2:	58a50513          	addi	a0,a0,1418 # 80008078 <digits+0x20>
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	ae0080e7          	jalr	-1312(ra) # 800005d6 <panic>

0000000080000afe <freerange>:
{
    80000afe:	7179                	addi	sp,sp,-48
    80000b00:	f406                	sd	ra,40(sp)
    80000b02:	f022                	sd	s0,32(sp)
    80000b04:	ec26                	sd	s1,24(sp)
    80000b06:	e84a                	sd	s2,16(sp)
    80000b08:	e44e                	sd	s3,8(sp)
    80000b0a:	e052                	sd	s4,0(sp)
    80000b0c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b0e:	6785                	lui	a5,0x1
    80000b10:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b14:	94aa                	add	s1,s1,a0
    80000b16:	757d                	lui	a0,0xfffff
    80000b18:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1a:	94be                	add	s1,s1,a5
    80000b1c:	0095ee63          	bltu	a1,s1,80000b38 <freerange+0x3a>
    80000b20:	892e                	mv	s2,a1
    kfree(p);
    80000b22:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b24:	6985                	lui	s3,0x1
    kfree(p);
    80000b26:	01448533          	add	a0,s1,s4
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	f5e080e7          	jalr	-162(ra) # 80000a88 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b32:	94ce                	add	s1,s1,s3
    80000b34:	fe9979e3          	bgeu	s2,s1,80000b26 <freerange+0x28>
}
    80000b38:	70a2                	ld	ra,40(sp)
    80000b3a:	7402                	ld	s0,32(sp)
    80000b3c:	64e2                	ld	s1,24(sp)
    80000b3e:	6942                	ld	s2,16(sp)
    80000b40:	69a2                	ld	s3,8(sp)
    80000b42:	6a02                	ld	s4,0(sp)
    80000b44:	6145                	addi	sp,sp,48
    80000b46:	8082                	ret

0000000080000b48 <kinit>:
{
    80000b48:	1141                	addi	sp,sp,-16
    80000b4a:	e406                	sd	ra,8(sp)
    80000b4c:	e022                	sd	s0,0(sp)
    80000b4e:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b50:	00007597          	auipc	a1,0x7
    80000b54:	53058593          	addi	a1,a1,1328 # 80008080 <digits+0x28>
    80000b58:	00011517          	auipc	a0,0x11
    80000b5c:	dd850513          	addi	a0,a0,-552 # 80011930 <kmem>
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	084080e7          	jalr	132(ra) # 80000be4 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b68:	45c5                	li	a1,17
    80000b6a:	05ee                	slli	a1,a1,0x1b
    80000b6c:	00026517          	auipc	a0,0x26
    80000b70:	49450513          	addi	a0,a0,1172 # 80027000 <end>
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	f8a080e7          	jalr	-118(ra) # 80000afe <freerange>
}
    80000b7c:	60a2                	ld	ra,8(sp)
    80000b7e:	6402                	ld	s0,0(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b8e:	00011497          	auipc	s1,0x11
    80000b92:	da248493          	addi	s1,s1,-606 # 80011930 <kmem>
    80000b96:	8526                	mv	a0,s1
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	0dc080e7          	jalr	220(ra) # 80000c74 <acquire>
  r = kmem.freelist;
    80000ba0:	6c84                	ld	s1,24(s1)
  if(r)
    80000ba2:	c885                	beqz	s1,80000bd2 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000ba4:	609c                	ld	a5,0(s1)
    80000ba6:	00011517          	auipc	a0,0x11
    80000baa:	d8a50513          	addi	a0,a0,-630 # 80011930 <kmem>
    80000bae:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	178080e7          	jalr	376(ra) # 80000d28 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bb8:	6605                	lui	a2,0x1
    80000bba:	4595                	li	a1,5
    80000bbc:	8526                	mv	a0,s1
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	1b2080e7          	jalr	434(ra) # 80000d70 <memset>
  return (void*)r;
}
    80000bc6:	8526                	mv	a0,s1
    80000bc8:	60e2                	ld	ra,24(sp)
    80000bca:	6442                	ld	s0,16(sp)
    80000bcc:	64a2                	ld	s1,8(sp)
    80000bce:	6105                	addi	sp,sp,32
    80000bd0:	8082                	ret
  release(&kmem.lock);
    80000bd2:	00011517          	auipc	a0,0x11
    80000bd6:	d5e50513          	addi	a0,a0,-674 # 80011930 <kmem>
    80000bda:	00000097          	auipc	ra,0x0
    80000bde:	14e080e7          	jalr	334(ra) # 80000d28 <release>
  if(r)
    80000be2:	b7d5                	j	80000bc6 <kalloc+0x42>

0000000080000be4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000be4:	1141                	addi	sp,sp,-16
    80000be6:	e422                	sd	s0,8(sp)
    80000be8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bea:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bec:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bf0:	00053823          	sd	zero,16(a0)
}
    80000bf4:	6422                	ld	s0,8(sp)
    80000bf6:	0141                	addi	sp,sp,16
    80000bf8:	8082                	ret

0000000080000bfa <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bfa:	411c                	lw	a5,0(a0)
    80000bfc:	e399                	bnez	a5,80000c02 <holding+0x8>
    80000bfe:	4501                	li	a0,0
  return r;
}
    80000c00:	8082                	ret
{
    80000c02:	1101                	addi	sp,sp,-32
    80000c04:	ec06                	sd	ra,24(sp)
    80000c06:	e822                	sd	s0,16(sp)
    80000c08:	e426                	sd	s1,8(sp)
    80000c0a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c0c:	6904                	ld	s1,16(a0)
    80000c0e:	00001097          	auipc	ra,0x1
    80000c12:	e18080e7          	jalr	-488(ra) # 80001a26 <mycpu>
    80000c16:	40a48533          	sub	a0,s1,a0
    80000c1a:	00153513          	seqz	a0,a0
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret

0000000080000c28 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c28:	1101                	addi	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c32:	100024f3          	csrr	s1,sstatus
    80000c36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c3a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c3c:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	de6080e7          	jalr	-538(ra) # 80001a26 <mycpu>
    80000c48:	5d3c                	lw	a5,120(a0)
    80000c4a:	cf89                	beqz	a5,80000c64 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c4c:	00001097          	auipc	ra,0x1
    80000c50:	dda080e7          	jalr	-550(ra) # 80001a26 <mycpu>
    80000c54:	5d3c                	lw	a5,120(a0)
    80000c56:	2785                	addiw	a5,a5,1
    80000c58:	dd3c                	sw	a5,120(a0)
}
    80000c5a:	60e2                	ld	ra,24(sp)
    80000c5c:	6442                	ld	s0,16(sp)
    80000c5e:	64a2                	ld	s1,8(sp)
    80000c60:	6105                	addi	sp,sp,32
    80000c62:	8082                	ret
    mycpu()->intena = old;
    80000c64:	00001097          	auipc	ra,0x1
    80000c68:	dc2080e7          	jalr	-574(ra) # 80001a26 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c6c:	8085                	srli	s1,s1,0x1
    80000c6e:	8885                	andi	s1,s1,1
    80000c70:	dd64                	sw	s1,124(a0)
    80000c72:	bfe9                	j	80000c4c <push_off+0x24>

0000000080000c74 <acquire>:
{
    80000c74:	1101                	addi	sp,sp,-32
    80000c76:	ec06                	sd	ra,24(sp)
    80000c78:	e822                	sd	s0,16(sp)
    80000c7a:	e426                	sd	s1,8(sp)
    80000c7c:	1000                	addi	s0,sp,32
    80000c7e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	fa8080e7          	jalr	-88(ra) # 80000c28 <push_off>
  if(holding(lk))
    80000c88:	8526                	mv	a0,s1
    80000c8a:	00000097          	auipc	ra,0x0
    80000c8e:	f70080e7          	jalr	-144(ra) # 80000bfa <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c92:	4705                	li	a4,1
  if(holding(lk))
    80000c94:	e115                	bnez	a0,80000cb8 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c96:	87ba                	mv	a5,a4
    80000c98:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c9c:	2781                	sext.w	a5,a5
    80000c9e:	ffe5                	bnez	a5,80000c96 <acquire+0x22>
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d82080e7          	jalr	-638(ra) # 80001a26 <mycpu>
    80000cac:	e888                	sd	a0,16(s1)
}
    80000cae:	60e2                	ld	ra,24(sp)
    80000cb0:	6442                	ld	s0,16(sp)
    80000cb2:	64a2                	ld	s1,8(sp)
    80000cb4:	6105                	addi	sp,sp,32
    80000cb6:	8082                	ret
    panic("acquire");
    80000cb8:	00007517          	auipc	a0,0x7
    80000cbc:	3d050513          	addi	a0,a0,976 # 80008088 <digits+0x30>
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	916080e7          	jalr	-1770(ra) # 800005d6 <panic>

0000000080000cc8 <pop_off>:

void
pop_off(void)
{
    80000cc8:	1141                	addi	sp,sp,-16
    80000cca:	e406                	sd	ra,8(sp)
    80000ccc:	e022                	sd	s0,0(sp)
    80000cce:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cd0:	00001097          	auipc	ra,0x1
    80000cd4:	d56080e7          	jalr	-682(ra) # 80001a26 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cdc:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cde:	e78d                	bnez	a5,80000d08 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ce0:	5d3c                	lw	a5,120(a0)
    80000ce2:	02f05b63          	blez	a5,80000d18 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ce6:	37fd                	addiw	a5,a5,-1
    80000ce8:	0007871b          	sext.w	a4,a5
    80000cec:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cee:	eb09                	bnez	a4,80000d00 <pop_off+0x38>
    80000cf0:	5d7c                	lw	a5,124(a0)
    80000cf2:	c799                	beqz	a5,80000d00 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cf4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cf8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cfc:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d00:	60a2                	ld	ra,8(sp)
    80000d02:	6402                	ld	s0,0(sp)
    80000d04:	0141                	addi	sp,sp,16
    80000d06:	8082                	ret
    panic("pop_off - interruptible");
    80000d08:	00007517          	auipc	a0,0x7
    80000d0c:	38850513          	addi	a0,a0,904 # 80008090 <digits+0x38>
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	8c6080e7          	jalr	-1850(ra) # 800005d6 <panic>
    panic("pop_off");
    80000d18:	00007517          	auipc	a0,0x7
    80000d1c:	39050513          	addi	a0,a0,912 # 800080a8 <digits+0x50>
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	8b6080e7          	jalr	-1866(ra) # 800005d6 <panic>

0000000080000d28 <release>:
{
    80000d28:	1101                	addi	sp,sp,-32
    80000d2a:	ec06                	sd	ra,24(sp)
    80000d2c:	e822                	sd	s0,16(sp)
    80000d2e:	e426                	sd	s1,8(sp)
    80000d30:	1000                	addi	s0,sp,32
    80000d32:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	ec6080e7          	jalr	-314(ra) # 80000bfa <holding>
    80000d3c:	c115                	beqz	a0,80000d60 <release+0x38>
  lk->cpu = 0;
    80000d3e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d42:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d46:	0f50000f          	fence	iorw,ow
    80000d4a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d4e:	00000097          	auipc	ra,0x0
    80000d52:	f7a080e7          	jalr	-134(ra) # 80000cc8 <pop_off>
}
    80000d56:	60e2                	ld	ra,24(sp)
    80000d58:	6442                	ld	s0,16(sp)
    80000d5a:	64a2                	ld	s1,8(sp)
    80000d5c:	6105                	addi	sp,sp,32
    80000d5e:	8082                	ret
    panic("release");
    80000d60:	00007517          	auipc	a0,0x7
    80000d64:	35050513          	addi	a0,a0,848 # 800080b0 <digits+0x58>
    80000d68:	00000097          	auipc	ra,0x0
    80000d6c:	86e080e7          	jalr	-1938(ra) # 800005d6 <panic>

0000000080000d70 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d70:	1141                	addi	sp,sp,-16
    80000d72:	e422                	sd	s0,8(sp)
    80000d74:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d76:	ce09                	beqz	a2,80000d90 <memset+0x20>
    80000d78:	87aa                	mv	a5,a0
    80000d7a:	fff6071b          	addiw	a4,a2,-1
    80000d7e:	1702                	slli	a4,a4,0x20
    80000d80:	9301                	srli	a4,a4,0x20
    80000d82:	0705                	addi	a4,a4,1
    80000d84:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d86:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d8a:	0785                	addi	a5,a5,1
    80000d8c:	fee79de3          	bne	a5,a4,80000d86 <memset+0x16>
  }
  return dst;
}
    80000d90:	6422                	ld	s0,8(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d9c:	ca05                	beqz	a2,80000dcc <memcmp+0x36>
    80000d9e:	fff6069b          	addiw	a3,a2,-1
    80000da2:	1682                	slli	a3,a3,0x20
    80000da4:	9281                	srli	a3,a3,0x20
    80000da6:	0685                	addi	a3,a3,1
    80000da8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	0005c703          	lbu	a4,0(a1)
    80000db2:	00e79863          	bne	a5,a4,80000dc2 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dba:	fed518e3          	bne	a0,a3,80000daa <memcmp+0x14>
  }

  return 0;
    80000dbe:	4501                	li	a0,0
    80000dc0:	a019                	j	80000dc6 <memcmp+0x30>
      return *s1 - *s2;
    80000dc2:	40e7853b          	subw	a0,a5,a4
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	bfe5                	j	80000dc6 <memcmp+0x30>

0000000080000dd0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dd6:	00a5f963          	bgeu	a1,a0,80000de8 <memmove+0x18>
    80000dda:	02061713          	slli	a4,a2,0x20
    80000dde:	9301                	srli	a4,a4,0x20
    80000de0:	00e587b3          	add	a5,a1,a4
    80000de4:	02f56563          	bltu	a0,a5,80000e0e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000de8:	fff6069b          	addiw	a3,a2,-1
    80000dec:	ce11                	beqz	a2,80000e08 <memmove+0x38>
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	0685                	addi	a3,a3,1
    80000df4:	96ae                	add	a3,a3,a1
    80000df6:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	0785                	addi	a5,a5,1
    80000dfc:	fff5c703          	lbu	a4,-1(a1)
    80000e00:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e04:	fed59ae3          	bne	a1,a3,80000df8 <memmove+0x28>

  return dst;
}
    80000e08:	6422                	ld	s0,8(sp)
    80000e0a:	0141                	addi	sp,sp,16
    80000e0c:	8082                	ret
    d += n;
    80000e0e:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e10:	fff6069b          	addiw	a3,a2,-1
    80000e14:	da75                	beqz	a2,80000e08 <memmove+0x38>
    80000e16:	02069613          	slli	a2,a3,0x20
    80000e1a:	9201                	srli	a2,a2,0x20
    80000e1c:	fff64613          	not	a2,a2
    80000e20:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e22:	17fd                	addi	a5,a5,-1
    80000e24:	177d                	addi	a4,a4,-1
    80000e26:	0007c683          	lbu	a3,0(a5)
    80000e2a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e2e:	fec79ae3          	bne	a5,a2,80000e22 <memmove+0x52>
    80000e32:	bfd9                	j	80000e08 <memmove+0x38>

0000000080000e34 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e34:	1141                	addi	sp,sp,-16
    80000e36:	e406                	sd	ra,8(sp)
    80000e38:	e022                	sd	s0,0(sp)
    80000e3a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e3c:	00000097          	auipc	ra,0x0
    80000e40:	f94080e7          	jalr	-108(ra) # 80000dd0 <memmove>
}
    80000e44:	60a2                	ld	ra,8(sp)
    80000e46:	6402                	ld	s0,0(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e52:	ce11                	beqz	a2,80000e6e <strncmp+0x22>
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf89                	beqz	a5,80000e72 <strncmp+0x26>
    80000e5a:	0005c703          	lbu	a4,0(a1)
    80000e5e:	00f71a63          	bne	a4,a5,80000e72 <strncmp+0x26>
    n--, p++, q++;
    80000e62:	367d                	addiw	a2,a2,-1
    80000e64:	0505                	addi	a0,a0,1
    80000e66:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e68:	f675                	bnez	a2,80000e54 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	a809                	j	80000e7e <strncmp+0x32>
    80000e6e:	4501                	li	a0,0
    80000e70:	a039                	j	80000e7e <strncmp+0x32>
  if(n == 0)
    80000e72:	ca09                	beqz	a2,80000e84 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e74:	00054503          	lbu	a0,0(a0)
    80000e78:	0005c783          	lbu	a5,0(a1)
    80000e7c:	9d1d                	subw	a0,a0,a5
}
    80000e7e:	6422                	ld	s0,8(sp)
    80000e80:	0141                	addi	sp,sp,16
    80000e82:	8082                	ret
    return 0;
    80000e84:	4501                	li	a0,0
    80000e86:	bfe5                	j	80000e7e <strncmp+0x32>

0000000080000e88 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e88:	1141                	addi	sp,sp,-16
    80000e8a:	e422                	sd	s0,8(sp)
    80000e8c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e8e:	872a                	mv	a4,a0
    80000e90:	8832                	mv	a6,a2
    80000e92:	367d                	addiw	a2,a2,-1
    80000e94:	01005963          	blez	a6,80000ea6 <strncpy+0x1e>
    80000e98:	0705                	addi	a4,a4,1
    80000e9a:	0005c783          	lbu	a5,0(a1)
    80000e9e:	fef70fa3          	sb	a5,-1(a4)
    80000ea2:	0585                	addi	a1,a1,1
    80000ea4:	f7f5                	bnez	a5,80000e90 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ea6:	00c05d63          	blez	a2,80000ec0 <strncpy+0x38>
    80000eaa:	86ba                	mv	a3,a4
    *s++ = 0;
    80000eac:	0685                	addi	a3,a3,1
    80000eae:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eb2:	fff6c793          	not	a5,a3
    80000eb6:	9fb9                	addw	a5,a5,a4
    80000eb8:	010787bb          	addw	a5,a5,a6
    80000ebc:	fef048e3          	bgtz	a5,80000eac <strncpy+0x24>
  return os;
}
    80000ec0:	6422                	ld	s0,8(sp)
    80000ec2:	0141                	addi	sp,sp,16
    80000ec4:	8082                	ret

0000000080000ec6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ec6:	1141                	addi	sp,sp,-16
    80000ec8:	e422                	sd	s0,8(sp)
    80000eca:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ecc:	02c05363          	blez	a2,80000ef2 <safestrcpy+0x2c>
    80000ed0:	fff6069b          	addiw	a3,a2,-1
    80000ed4:	1682                	slli	a3,a3,0x20
    80000ed6:	9281                	srli	a3,a3,0x20
    80000ed8:	96ae                	add	a3,a3,a1
    80000eda:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000edc:	00d58963          	beq	a1,a3,80000eee <safestrcpy+0x28>
    80000ee0:	0585                	addi	a1,a1,1
    80000ee2:	0785                	addi	a5,a5,1
    80000ee4:	fff5c703          	lbu	a4,-1(a1)
    80000ee8:	fee78fa3          	sb	a4,-1(a5)
    80000eec:	fb65                	bnez	a4,80000edc <safestrcpy+0x16>
    ;
  *s = 0;
    80000eee:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ef2:	6422                	ld	s0,8(sp)
    80000ef4:	0141                	addi	sp,sp,16
    80000ef6:	8082                	ret

0000000080000ef8 <strlen>:

int
strlen(const char *s)
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e422                	sd	s0,8(sp)
    80000efc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000efe:	00054783          	lbu	a5,0(a0)
    80000f02:	cf91                	beqz	a5,80000f1e <strlen+0x26>
    80000f04:	0505                	addi	a0,a0,1
    80000f06:	87aa                	mv	a5,a0
    80000f08:	4685                	li	a3,1
    80000f0a:	9e89                	subw	a3,a3,a0
    80000f0c:	00f6853b          	addw	a0,a3,a5
    80000f10:	0785                	addi	a5,a5,1
    80000f12:	fff7c703          	lbu	a4,-1(a5)
    80000f16:	fb7d                	bnez	a4,80000f0c <strlen+0x14>
    ;
  return n;
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f1e:	4501                	li	a0,0
    80000f20:	bfe5                	j	80000f18 <strlen+0x20>

0000000080000f22 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e406                	sd	ra,8(sp)
    80000f26:	e022                	sd	s0,0(sp)
    80000f28:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	aec080e7          	jalr	-1300(ra) # 80001a16 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f32:	00008717          	auipc	a4,0x8
    80000f36:	0da70713          	addi	a4,a4,218 # 8000900c <started>
  if(cpuid() == 0){
    80000f3a:	c139                	beqz	a0,80000f80 <main+0x5e>
    while(started == 0)
    80000f3c:	431c                	lw	a5,0(a4)
    80000f3e:	2781                	sext.w	a5,a5
    80000f40:	dff5                	beqz	a5,80000f3c <main+0x1a>
      ;
    __sync_synchronize();
    80000f42:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f46:	00001097          	auipc	ra,0x1
    80000f4a:	ad0080e7          	jalr	-1328(ra) # 80001a16 <cpuid>
    80000f4e:	85aa                	mv	a1,a0
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	18050513          	addi	a0,a0,384 # 800080d0 <digits+0x78>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	6d0080e7          	jalr	1744(ra) # 80000628 <printf>
    kvminithart();    // turn on paging
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	0d8080e7          	jalr	216(ra) # 80001038 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	744080e7          	jalr	1860(ra) # 800026ac <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f70:	00005097          	auipc	ra,0x5
    80000f74:	dd0080e7          	jalr	-560(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	00a080e7          	jalr	10(ra) # 80001f82 <scheduler>
    consoleinit();
    80000f80:	fffff097          	auipc	ra,0xfffff
    80000f84:	4da080e7          	jalr	1242(ra) # 8000045a <consoleinit>
    printfinit();
    80000f88:	fffff097          	auipc	ra,0xfffff
    80000f8c:	5c0080e7          	jalr	1472(ra) # 80000548 <printfinit>
    printf("\n");
    80000f90:	00007517          	auipc	a0,0x7
    80000f94:	15050513          	addi	a0,a0,336 # 800080e0 <digits+0x88>
    80000f98:	fffff097          	auipc	ra,0xfffff
    80000f9c:	690080e7          	jalr	1680(ra) # 80000628 <printf>
    printf("xv6 kernel is booting\n");
    80000fa0:	00007517          	auipc	a0,0x7
    80000fa4:	11850513          	addi	a0,a0,280 # 800080b8 <digits+0x60>
    80000fa8:	fffff097          	auipc	ra,0xfffff
    80000fac:	680080e7          	jalr	1664(ra) # 80000628 <printf>
    printf("\n");
    80000fb0:	00007517          	auipc	a0,0x7
    80000fb4:	13050513          	addi	a0,a0,304 # 800080e0 <digits+0x88>
    80000fb8:	fffff097          	auipc	ra,0xfffff
    80000fbc:	670080e7          	jalr	1648(ra) # 80000628 <printf>
    kinit();         // physical page allocator
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	b88080e7          	jalr	-1144(ra) # 80000b48 <kinit>
    kvminit();       // create kernel page table
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	2a0080e7          	jalr	672(ra) # 80001268 <kvminit>
    kvminithart();   // turn on paging
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	068080e7          	jalr	104(ra) # 80001038 <kvminithart>
    procinit();      // process table
    80000fd8:	00001097          	auipc	ra,0x1
    80000fdc:	96e080e7          	jalr	-1682(ra) # 80001946 <procinit>
    trapinit();      // trap vectors
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	6a4080e7          	jalr	1700(ra) # 80002684 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	6c4080e7          	jalr	1732(ra) # 800026ac <trapinithart>
    plicinit();      // set up interrupt controller
    80000ff0:	00005097          	auipc	ra,0x5
    80000ff4:	d3a080e7          	jalr	-710(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ff8:	00005097          	auipc	ra,0x5
    80000ffc:	d48080e7          	jalr	-696(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80001000:	00002097          	auipc	ra,0x2
    80001004:	ee2080e7          	jalr	-286(ra) # 80002ee2 <binit>
    iinit();         // inode cache
    80001008:	00002097          	auipc	ra,0x2
    8000100c:	572080e7          	jalr	1394(ra) # 8000357a <iinit>
    fileinit();      // file table
    80001010:	00003097          	auipc	ra,0x3
    80001014:	50c080e7          	jalr	1292(ra) # 8000451c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001018:	00005097          	auipc	ra,0x5
    8000101c:	e30080e7          	jalr	-464(ra) # 80005e48 <virtio_disk_init>
    userinit();      // first user process
    80001020:	00001097          	auipc	ra,0x1
    80001024:	cfc080e7          	jalr	-772(ra) # 80001d1c <userinit>
    __sync_synchronize();
    80001028:	0ff0000f          	fence
    started = 1;
    8000102c:	4785                	li	a5,1
    8000102e:	00008717          	auipc	a4,0x8
    80001032:	fcf72f23          	sw	a5,-34(a4) # 8000900c <started>
    80001036:	b789                	j	80000f78 <main+0x56>

0000000080001038 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001038:	1141                	addi	sp,sp,-16
    8000103a:	e422                	sd	s0,8(sp)
    8000103c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000103e:	00008797          	auipc	a5,0x8
    80001042:	fd27b783          	ld	a5,-46(a5) # 80009010 <kernel_pagetable>
    80001046:	83b1                	srli	a5,a5,0xc
    80001048:	577d                	li	a4,-1
    8000104a:	177e                	slli	a4,a4,0x3f
    8000104c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000104e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001052:	12000073          	sfence.vma
  sfence_vma();
}
    80001056:	6422                	ld	s0,8(sp)
    80001058:	0141                	addi	sp,sp,16
    8000105a:	8082                	ret

000000008000105c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000105c:	7139                	addi	sp,sp,-64
    8000105e:	fc06                	sd	ra,56(sp)
    80001060:	f822                	sd	s0,48(sp)
    80001062:	f426                	sd	s1,40(sp)
    80001064:	f04a                	sd	s2,32(sp)
    80001066:	ec4e                	sd	s3,24(sp)
    80001068:	e852                	sd	s4,16(sp)
    8000106a:	e456                	sd	s5,8(sp)
    8000106c:	e05a                	sd	s6,0(sp)
    8000106e:	0080                	addi	s0,sp,64
    80001070:	84aa                	mv	s1,a0
    80001072:	89ae                	mv	s3,a1
    80001074:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000107c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000107e:	04b7f263          	bgeu	a5,a1,800010c2 <walk+0x66>
    panic("walk");
    80001082:	00007517          	auipc	a0,0x7
    80001086:	06650513          	addi	a0,a0,102 # 800080e8 <digits+0x90>
    8000108a:	fffff097          	auipc	ra,0xfffff
    8000108e:	54c080e7          	jalr	1356(ra) # 800005d6 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001092:	060a8663          	beqz	s5,800010fe <walk+0xa2>
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	aee080e7          	jalr	-1298(ra) # 80000b84 <kalloc>
    8000109e:	84aa                	mv	s1,a0
    800010a0:	c529                	beqz	a0,800010ea <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010a2:	6605                	lui	a2,0x1
    800010a4:	4581                	li	a1,0
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	cca080e7          	jalr	-822(ra) # 80000d70 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ae:	00c4d793          	srli	a5,s1,0xc
    800010b2:	07aa                	slli	a5,a5,0xa
    800010b4:	0017e793          	ori	a5,a5,1
    800010b8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010bc:	3a5d                	addiw	s4,s4,-9
    800010be:	036a0063          	beq	s4,s6,800010de <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010c2:	0149d933          	srl	s2,s3,s4
    800010c6:	1ff97913          	andi	s2,s2,511
    800010ca:	090e                	slli	s2,s2,0x3
    800010cc:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ce:	00093483          	ld	s1,0(s2)
    800010d2:	0014f793          	andi	a5,s1,1
    800010d6:	dfd5                	beqz	a5,80001092 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010d8:	80a9                	srli	s1,s1,0xa
    800010da:	04b2                	slli	s1,s1,0xc
    800010dc:	b7c5                	j	800010bc <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010de:	00c9d513          	srli	a0,s3,0xc
    800010e2:	1ff57513          	andi	a0,a0,511
    800010e6:	050e                	slli	a0,a0,0x3
    800010e8:	9526                	add	a0,a0,s1
}
    800010ea:	70e2                	ld	ra,56(sp)
    800010ec:	7442                	ld	s0,48(sp)
    800010ee:	74a2                	ld	s1,40(sp)
    800010f0:	7902                	ld	s2,32(sp)
    800010f2:	69e2                	ld	s3,24(sp)
    800010f4:	6a42                	ld	s4,16(sp)
    800010f6:	6aa2                	ld	s5,8(sp)
    800010f8:	6b02                	ld	s6,0(sp)
    800010fa:	6121                	addi	sp,sp,64
    800010fc:	8082                	ret
        return 0;
    800010fe:	4501                	li	a0,0
    80001100:	b7ed                	j	800010ea <walk+0x8e>

0000000080001102 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001102:	57fd                	li	a5,-1
    80001104:	83e9                	srli	a5,a5,0x1a
    80001106:	00b7f463          	bgeu	a5,a1,8000110e <walkaddr+0xc>
    return 0;
    8000110a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000110c:	8082                	ret
{
    8000110e:	1141                	addi	sp,sp,-16
    80001110:	e406                	sd	ra,8(sp)
    80001112:	e022                	sd	s0,0(sp)
    80001114:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001116:	4601                	li	a2,0
    80001118:	00000097          	auipc	ra,0x0
    8000111c:	f44080e7          	jalr	-188(ra) # 8000105c <walk>
  if(pte == 0)
    80001120:	c105                	beqz	a0,80001140 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001122:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001124:	0117f693          	andi	a3,a5,17
    80001128:	4745                	li	a4,17
    return 0;
    8000112a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000112c:	00e68663          	beq	a3,a4,80001138 <walkaddr+0x36>
}
    80001130:	60a2                	ld	ra,8(sp)
    80001132:	6402                	ld	s0,0(sp)
    80001134:	0141                	addi	sp,sp,16
    80001136:	8082                	ret
  pa = PTE2PA(*pte);
    80001138:	00a7d513          	srli	a0,a5,0xa
    8000113c:	0532                	slli	a0,a0,0xc
  return pa;
    8000113e:	bfcd                	j	80001130 <walkaddr+0x2e>
    return 0;
    80001140:	4501                	li	a0,0
    80001142:	b7fd                	j	80001130 <walkaddr+0x2e>

0000000080001144 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001144:	1101                	addi	sp,sp,-32
    80001146:	ec06                	sd	ra,24(sp)
    80001148:	e822                	sd	s0,16(sp)
    8000114a:	e426                	sd	s1,8(sp)
    8000114c:	1000                	addi	s0,sp,32
    8000114e:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001150:	1552                	slli	a0,a0,0x34
    80001152:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001156:	4601                	li	a2,0
    80001158:	00008517          	auipc	a0,0x8
    8000115c:	eb853503          	ld	a0,-328(a0) # 80009010 <kernel_pagetable>
    80001160:	00000097          	auipc	ra,0x0
    80001164:	efc080e7          	jalr	-260(ra) # 8000105c <walk>
  if(pte == 0)
    80001168:	cd09                	beqz	a0,80001182 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000116a:	6108                	ld	a0,0(a0)
    8000116c:	00157793          	andi	a5,a0,1
    80001170:	c38d                	beqz	a5,80001192 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001172:	8129                	srli	a0,a0,0xa
    80001174:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001176:	9526                	add	a0,a0,s1
    80001178:	60e2                	ld	ra,24(sp)
    8000117a:	6442                	ld	s0,16(sp)
    8000117c:	64a2                	ld	s1,8(sp)
    8000117e:	6105                	addi	sp,sp,32
    80001180:	8082                	ret
    panic("kvmpa");
    80001182:	00007517          	auipc	a0,0x7
    80001186:	f6e50513          	addi	a0,a0,-146 # 800080f0 <digits+0x98>
    8000118a:	fffff097          	auipc	ra,0xfffff
    8000118e:	44c080e7          	jalr	1100(ra) # 800005d6 <panic>
    panic("kvmpa");
    80001192:	00007517          	auipc	a0,0x7
    80001196:	f5e50513          	addi	a0,a0,-162 # 800080f0 <digits+0x98>
    8000119a:	fffff097          	auipc	ra,0xfffff
    8000119e:	43c080e7          	jalr	1084(ra) # 800005d6 <panic>

00000000800011a2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011a2:	715d                	addi	sp,sp,-80
    800011a4:	e486                	sd	ra,72(sp)
    800011a6:	e0a2                	sd	s0,64(sp)
    800011a8:	fc26                	sd	s1,56(sp)
    800011aa:	f84a                	sd	s2,48(sp)
    800011ac:	f44e                	sd	s3,40(sp)
    800011ae:	f052                	sd	s4,32(sp)
    800011b0:	ec56                	sd	s5,24(sp)
    800011b2:	e85a                	sd	s6,16(sp)
    800011b4:	e45e                	sd	s7,8(sp)
    800011b6:	0880                	addi	s0,sp,80
    800011b8:	8aaa                	mv	s5,a0
    800011ba:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011bc:	777d                	lui	a4,0xfffff
    800011be:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011c2:	167d                	addi	a2,a2,-1
    800011c4:	00b609b3          	add	s3,a2,a1
    800011c8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011cc:	893e                	mv	s2,a5
    800011ce:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011d2:	6b85                	lui	s7,0x1
    800011d4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011d8:	4605                	li	a2,1
    800011da:	85ca                	mv	a1,s2
    800011dc:	8556                	mv	a0,s5
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	e7e080e7          	jalr	-386(ra) # 8000105c <walk>
    800011e6:	c51d                	beqz	a0,80001214 <mappages+0x72>
    if(*pte & PTE_V)
    800011e8:	611c                	ld	a5,0(a0)
    800011ea:	8b85                	andi	a5,a5,1
    800011ec:	ef81                	bnez	a5,80001204 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ee:	80b1                	srli	s1,s1,0xc
    800011f0:	04aa                	slli	s1,s1,0xa
    800011f2:	0164e4b3          	or	s1,s1,s6
    800011f6:	0014e493          	ori	s1,s1,1
    800011fa:	e104                	sd	s1,0(a0)
    if(a == last)
    800011fc:	03390863          	beq	s2,s3,8000122c <mappages+0x8a>
    a += PGSIZE;
    80001200:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001202:	bfc9                	j	800011d4 <mappages+0x32>
      panic("remap");
    80001204:	00007517          	auipc	a0,0x7
    80001208:	ef450513          	addi	a0,a0,-268 # 800080f8 <digits+0xa0>
    8000120c:	fffff097          	auipc	ra,0xfffff
    80001210:	3ca080e7          	jalr	970(ra) # 800005d6 <panic>
      return -1;
    80001214:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001216:	60a6                	ld	ra,72(sp)
    80001218:	6406                	ld	s0,64(sp)
    8000121a:	74e2                	ld	s1,56(sp)
    8000121c:	7942                	ld	s2,48(sp)
    8000121e:	79a2                	ld	s3,40(sp)
    80001220:	7a02                	ld	s4,32(sp)
    80001222:	6ae2                	ld	s5,24(sp)
    80001224:	6b42                	ld	s6,16(sp)
    80001226:	6ba2                	ld	s7,8(sp)
    80001228:	6161                	addi	sp,sp,80
    8000122a:	8082                	ret
  return 0;
    8000122c:	4501                	li	a0,0
    8000122e:	b7e5                	j	80001216 <mappages+0x74>

0000000080001230 <kvmmap>:
{
    80001230:	1141                	addi	sp,sp,-16
    80001232:	e406                	sd	ra,8(sp)
    80001234:	e022                	sd	s0,0(sp)
    80001236:	0800                	addi	s0,sp,16
    80001238:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000123a:	86ae                	mv	a3,a1
    8000123c:	85aa                	mv	a1,a0
    8000123e:	00008517          	auipc	a0,0x8
    80001242:	dd253503          	ld	a0,-558(a0) # 80009010 <kernel_pagetable>
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f5c080e7          	jalr	-164(ra) # 800011a2 <mappages>
    8000124e:	e509                	bnez	a0,80001258 <kvmmap+0x28>
}
    80001250:	60a2                	ld	ra,8(sp)
    80001252:	6402                	ld	s0,0(sp)
    80001254:	0141                	addi	sp,sp,16
    80001256:	8082                	ret
    panic("kvmmap");
    80001258:	00007517          	auipc	a0,0x7
    8000125c:	ea850513          	addi	a0,a0,-344 # 80008100 <digits+0xa8>
    80001260:	fffff097          	auipc	ra,0xfffff
    80001264:	376080e7          	jalr	886(ra) # 800005d6 <panic>

0000000080001268 <kvminit>:
{
    80001268:	1101                	addi	sp,sp,-32
    8000126a:	ec06                	sd	ra,24(sp)
    8000126c:	e822                	sd	s0,16(sp)
    8000126e:	e426                	sd	s1,8(sp)
    80001270:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001272:	00000097          	auipc	ra,0x0
    80001276:	912080e7          	jalr	-1774(ra) # 80000b84 <kalloc>
    8000127a:	00008797          	auipc	a5,0x8
    8000127e:	d8a7bb23          	sd	a0,-618(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001282:	6605                	lui	a2,0x1
    80001284:	4581                	li	a1,0
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	aea080e7          	jalr	-1302(ra) # 80000d70 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000128e:	4699                	li	a3,6
    80001290:	6605                	lui	a2,0x1
    80001292:	100005b7          	lui	a1,0x10000
    80001296:	10000537          	lui	a0,0x10000
    8000129a:	00000097          	auipc	ra,0x0
    8000129e:	f96080e7          	jalr	-106(ra) # 80001230 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012a2:	4699                	li	a3,6
    800012a4:	6605                	lui	a2,0x1
    800012a6:	100015b7          	lui	a1,0x10001
    800012aa:	10001537          	lui	a0,0x10001
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	f82080e7          	jalr	-126(ra) # 80001230 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012b6:	4699                	li	a3,6
    800012b8:	6641                	lui	a2,0x10
    800012ba:	020005b7          	lui	a1,0x2000
    800012be:	02000537          	lui	a0,0x2000
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f6e080e7          	jalr	-146(ra) # 80001230 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ca:	4699                	li	a3,6
    800012cc:	00400637          	lui	a2,0x400
    800012d0:	0c0005b7          	lui	a1,0xc000
    800012d4:	0c000537          	lui	a0,0xc000
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f58080e7          	jalr	-168(ra) # 80001230 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e0:	00007497          	auipc	s1,0x7
    800012e4:	d2048493          	addi	s1,s1,-736 # 80008000 <etext>
    800012e8:	46a9                	li	a3,10
    800012ea:	80007617          	auipc	a2,0x80007
    800012ee:	d1660613          	addi	a2,a2,-746 # 8000 <_entry-0x7fff8000>
    800012f2:	4585                	li	a1,1
    800012f4:	05fe                	slli	a1,a1,0x1f
    800012f6:	852e                	mv	a0,a1
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	f38080e7          	jalr	-200(ra) # 80001230 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001300:	4699                	li	a3,6
    80001302:	4645                	li	a2,17
    80001304:	066e                	slli	a2,a2,0x1b
    80001306:	8e05                	sub	a2,a2,s1
    80001308:	85a6                	mv	a1,s1
    8000130a:	8526                	mv	a0,s1
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	f24080e7          	jalr	-220(ra) # 80001230 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001314:	46a9                	li	a3,10
    80001316:	6605                	lui	a2,0x1
    80001318:	00006597          	auipc	a1,0x6
    8000131c:	ce858593          	addi	a1,a1,-792 # 80007000 <_trampoline>
    80001320:	04000537          	lui	a0,0x4000
    80001324:	157d                	addi	a0,a0,-1
    80001326:	0532                	slli	a0,a0,0xc
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	f08080e7          	jalr	-248(ra) # 80001230 <kvmmap>
}
    80001330:	60e2                	ld	ra,24(sp)
    80001332:	6442                	ld	s0,16(sp)
    80001334:	64a2                	ld	s1,8(sp)
    80001336:	6105                	addi	sp,sp,32
    80001338:	8082                	ret

000000008000133a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000133a:	715d                	addi	sp,sp,-80
    8000133c:	e486                	sd	ra,72(sp)
    8000133e:	e0a2                	sd	s0,64(sp)
    80001340:	fc26                	sd	s1,56(sp)
    80001342:	f84a                	sd	s2,48(sp)
    80001344:	f44e                	sd	s3,40(sp)
    80001346:	f052                	sd	s4,32(sp)
    80001348:	ec56                	sd	s5,24(sp)
    8000134a:	e85a                	sd	s6,16(sp)
    8000134c:	e45e                	sd	s7,8(sp)
    8000134e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001350:	03459793          	slli	a5,a1,0x34
    80001354:	e795                	bnez	a5,80001380 <uvmunmap+0x46>
    80001356:	8a2a                	mv	s4,a0
    80001358:	892e                	mv	s2,a1
    8000135a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135c:	0632                	slli	a2,a2,0xc
    8000135e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001362:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001364:	6b05                	lui	s6,0x1
    80001366:	0735e863          	bltu	a1,s3,800013d6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000136a:	60a6                	ld	ra,72(sp)
    8000136c:	6406                	ld	s0,64(sp)
    8000136e:	74e2                	ld	s1,56(sp)
    80001370:	7942                	ld	s2,48(sp)
    80001372:	79a2                	ld	s3,40(sp)
    80001374:	7a02                	ld	s4,32(sp)
    80001376:	6ae2                	ld	s5,24(sp)
    80001378:	6b42                	ld	s6,16(sp)
    8000137a:	6ba2                	ld	s7,8(sp)
    8000137c:	6161                	addi	sp,sp,80
    8000137e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001380:	00007517          	auipc	a0,0x7
    80001384:	d8850513          	addi	a0,a0,-632 # 80008108 <digits+0xb0>
    80001388:	fffff097          	auipc	ra,0xfffff
    8000138c:	24e080e7          	jalr	590(ra) # 800005d6 <panic>
      panic("uvmunmap: walk");
    80001390:	00007517          	auipc	a0,0x7
    80001394:	d9050513          	addi	a0,a0,-624 # 80008120 <digits+0xc8>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	23e080e7          	jalr	574(ra) # 800005d6 <panic>
      panic("uvmunmap: not mapped");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d9050513          	addi	a0,a0,-624 # 80008130 <digits+0xd8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	22e080e7          	jalr	558(ra) # 800005d6 <panic>
      panic("uvmunmap: not a leaf");
    800013b0:	00007517          	auipc	a0,0x7
    800013b4:	d9850513          	addi	a0,a0,-616 # 80008148 <digits+0xf0>
    800013b8:	fffff097          	auipc	ra,0xfffff
    800013bc:	21e080e7          	jalr	542(ra) # 800005d6 <panic>
      uint64 pa = PTE2PA(*pte);
    800013c0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013c2:	0532                	slli	a0,a0,0xc
    800013c4:	fffff097          	auipc	ra,0xfffff
    800013c8:	6c4080e7          	jalr	1732(ra) # 80000a88 <kfree>
    *pte = 0;
    800013cc:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d0:	995a                	add	s2,s2,s6
    800013d2:	f9397ce3          	bgeu	s2,s3,8000136a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013d6:	4601                	li	a2,0
    800013d8:	85ca                	mv	a1,s2
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	c80080e7          	jalr	-896(ra) # 8000105c <walk>
    800013e4:	84aa                	mv	s1,a0
    800013e6:	d54d                	beqz	a0,80001390 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013e8:	6108                	ld	a0,0(a0)
    800013ea:	00157793          	andi	a5,a0,1
    800013ee:	dbcd                	beqz	a5,800013a0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013f0:	3ff57793          	andi	a5,a0,1023
    800013f4:	fb778ee3          	beq	a5,s7,800013b0 <uvmunmap+0x76>
    if(do_free){
    800013f8:	fc0a8ae3          	beqz	s5,800013cc <uvmunmap+0x92>
    800013fc:	b7d1                	j	800013c0 <uvmunmap+0x86>

00000000800013fe <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	77c080e7          	jalr	1916(ra) # 80000b84 <kalloc>
    80001410:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001412:	c519                	beqz	a0,80001420 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001414:	6605                	lui	a2,0x1
    80001416:	4581                	li	a1,0
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	958080e7          	jalr	-1704(ra) # 80000d70 <memset>
  return pagetable;
}
    80001420:	8526                	mv	a0,s1
    80001422:	60e2                	ld	ra,24(sp)
    80001424:	6442                	ld	s0,16(sp)
    80001426:	64a2                	ld	s1,8(sp)
    80001428:	6105                	addi	sp,sp,32
    8000142a:	8082                	ret

000000008000142c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000142c:	7179                	addi	sp,sp,-48
    8000142e:	f406                	sd	ra,40(sp)
    80001430:	f022                	sd	s0,32(sp)
    80001432:	ec26                	sd	s1,24(sp)
    80001434:	e84a                	sd	s2,16(sp)
    80001436:	e44e                	sd	s3,8(sp)
    80001438:	e052                	sd	s4,0(sp)
    8000143a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000143c:	6785                	lui	a5,0x1
    8000143e:	04f67863          	bgeu	a2,a5,8000148e <uvminit+0x62>
    80001442:	8a2a                	mv	s4,a0
    80001444:	89ae                	mv	s3,a1
    80001446:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	73c080e7          	jalr	1852(ra) # 80000b84 <kalloc>
    80001450:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001452:	6605                	lui	a2,0x1
    80001454:	4581                	li	a1,0
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	91a080e7          	jalr	-1766(ra) # 80000d70 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000145e:	4779                	li	a4,30
    80001460:	86ca                	mv	a3,s2
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	8552                	mv	a0,s4
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	d3a080e7          	jalr	-710(ra) # 800011a2 <mappages>
  memmove(mem, src, sz);
    80001470:	8626                	mv	a2,s1
    80001472:	85ce                	mv	a1,s3
    80001474:	854a                	mv	a0,s2
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	95a080e7          	jalr	-1702(ra) # 80000dd0 <memmove>
}
    8000147e:	70a2                	ld	ra,40(sp)
    80001480:	7402                	ld	s0,32(sp)
    80001482:	64e2                	ld	s1,24(sp)
    80001484:	6942                	ld	s2,16(sp)
    80001486:	69a2                	ld	s3,8(sp)
    80001488:	6a02                	ld	s4,0(sp)
    8000148a:	6145                	addi	sp,sp,48
    8000148c:	8082                	ret
    panic("inituvm: more than a page");
    8000148e:	00007517          	auipc	a0,0x7
    80001492:	cd250513          	addi	a0,a0,-814 # 80008160 <digits+0x108>
    80001496:	fffff097          	auipc	ra,0xfffff
    8000149a:	140080e7          	jalr	320(ra) # 800005d6 <panic>

000000008000149e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000149e:	1101                	addi	sp,sp,-32
    800014a0:	ec06                	sd	ra,24(sp)
    800014a2:	e822                	sd	s0,16(sp)
    800014a4:	e426                	sd	s1,8(sp)
    800014a6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014aa:	00b67d63          	bgeu	a2,a1,800014c4 <uvmdealloc+0x26>
    800014ae:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014b0:	6785                	lui	a5,0x1
    800014b2:	17fd                	addi	a5,a5,-1
    800014b4:	00f60733          	add	a4,a2,a5
    800014b8:	767d                	lui	a2,0xfffff
    800014ba:	8f71                	and	a4,a4,a2
    800014bc:	97ae                	add	a5,a5,a1
    800014be:	8ff1                	and	a5,a5,a2
    800014c0:	00f76863          	bltu	a4,a5,800014d0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014c4:	8526                	mv	a0,s1
    800014c6:	60e2                	ld	ra,24(sp)
    800014c8:	6442                	ld	s0,16(sp)
    800014ca:	64a2                	ld	s1,8(sp)
    800014cc:	6105                	addi	sp,sp,32
    800014ce:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014d0:	8f99                	sub	a5,a5,a4
    800014d2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014d4:	4685                	li	a3,1
    800014d6:	0007861b          	sext.w	a2,a5
    800014da:	85ba                	mv	a1,a4
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	e5e080e7          	jalr	-418(ra) # 8000133a <uvmunmap>
    800014e4:	b7c5                	j	800014c4 <uvmdealloc+0x26>

00000000800014e6 <uvmalloc>:
  if(newsz < oldsz)
    800014e6:	0ab66163          	bltu	a2,a1,80001588 <uvmalloc+0xa2>
{
    800014ea:	7139                	addi	sp,sp,-64
    800014ec:	fc06                	sd	ra,56(sp)
    800014ee:	f822                	sd	s0,48(sp)
    800014f0:	f426                	sd	s1,40(sp)
    800014f2:	f04a                	sd	s2,32(sp)
    800014f4:	ec4e                	sd	s3,24(sp)
    800014f6:	e852                	sd	s4,16(sp)
    800014f8:	e456                	sd	s5,8(sp)
    800014fa:	0080                	addi	s0,sp,64
    800014fc:	8aaa                	mv	s5,a0
    800014fe:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001500:	6985                	lui	s3,0x1
    80001502:	19fd                	addi	s3,s3,-1
    80001504:	95ce                	add	a1,a1,s3
    80001506:	79fd                	lui	s3,0xfffff
    80001508:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000150c:	08c9f063          	bgeu	s3,a2,8000158c <uvmalloc+0xa6>
    80001510:	894e                	mv	s2,s3
    mem = kalloc();
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	672080e7          	jalr	1650(ra) # 80000b84 <kalloc>
    8000151a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000151c:	c51d                	beqz	a0,8000154a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000151e:	6605                	lui	a2,0x1
    80001520:	4581                	li	a1,0
    80001522:	00000097          	auipc	ra,0x0
    80001526:	84e080e7          	jalr	-1970(ra) # 80000d70 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000152a:	4779                	li	a4,30
    8000152c:	86a6                	mv	a3,s1
    8000152e:	6605                	lui	a2,0x1
    80001530:	85ca                	mv	a1,s2
    80001532:	8556                	mv	a0,s5
    80001534:	00000097          	auipc	ra,0x0
    80001538:	c6e080e7          	jalr	-914(ra) # 800011a2 <mappages>
    8000153c:	e905                	bnez	a0,8000156c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000153e:	6785                	lui	a5,0x1
    80001540:	993e                	add	s2,s2,a5
    80001542:	fd4968e3          	bltu	s2,s4,80001512 <uvmalloc+0x2c>
  return newsz;
    80001546:	8552                	mv	a0,s4
    80001548:	a809                	j	8000155a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000154a:	864e                	mv	a2,s3
    8000154c:	85ca                	mv	a1,s2
    8000154e:	8556                	mv	a0,s5
    80001550:	00000097          	auipc	ra,0x0
    80001554:	f4e080e7          	jalr	-178(ra) # 8000149e <uvmdealloc>
      return 0;
    80001558:	4501                	li	a0,0
}
    8000155a:	70e2                	ld	ra,56(sp)
    8000155c:	7442                	ld	s0,48(sp)
    8000155e:	74a2                	ld	s1,40(sp)
    80001560:	7902                	ld	s2,32(sp)
    80001562:	69e2                	ld	s3,24(sp)
    80001564:	6a42                	ld	s4,16(sp)
    80001566:	6aa2                	ld	s5,8(sp)
    80001568:	6121                	addi	sp,sp,64
    8000156a:	8082                	ret
      kfree(mem);
    8000156c:	8526                	mv	a0,s1
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	51a080e7          	jalr	1306(ra) # 80000a88 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001576:	864e                	mv	a2,s3
    80001578:	85ca                	mv	a1,s2
    8000157a:	8556                	mv	a0,s5
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	f22080e7          	jalr	-222(ra) # 8000149e <uvmdealloc>
      return 0;
    80001584:	4501                	li	a0,0
    80001586:	bfd1                	j	8000155a <uvmalloc+0x74>
    return oldsz;
    80001588:	852e                	mv	a0,a1
}
    8000158a:	8082                	ret
  return newsz;
    8000158c:	8532                	mv	a0,a2
    8000158e:	b7f1                	j	8000155a <uvmalloc+0x74>

0000000080001590 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001590:	7179                	addi	sp,sp,-48
    80001592:	f406                	sd	ra,40(sp)
    80001594:	f022                	sd	s0,32(sp)
    80001596:	ec26                	sd	s1,24(sp)
    80001598:	e84a                	sd	s2,16(sp)
    8000159a:	e44e                	sd	s3,8(sp)
    8000159c:	e052                	sd	s4,0(sp)
    8000159e:	1800                	addi	s0,sp,48
    800015a0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015a2:	84aa                	mv	s1,a0
    800015a4:	6905                	lui	s2,0x1
    800015a6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a8:	4985                	li	s3,1
    800015aa:	a821                	j	800015c2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ac:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015ae:	0532                	slli	a0,a0,0xc
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	fe0080e7          	jalr	-32(ra) # 80001590 <freewalk>
      pagetable[i] = 0;
    800015b8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015bc:	04a1                	addi	s1,s1,8
    800015be:	03248163          	beq	s1,s2,800015e0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015c2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c4:	00f57793          	andi	a5,a0,15
    800015c8:	ff3782e3          	beq	a5,s3,800015ac <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015cc:	8905                	andi	a0,a0,1
    800015ce:	d57d                	beqz	a0,800015bc <freewalk+0x2c>
      panic("freewalk: leaf");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb050513          	addi	a0,a0,-1104 # 80008180 <digits+0x128>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	ffe080e7          	jalr	-2(ra) # 800005d6 <panic>
    }
  }
  kfree((void*)pagetable);
    800015e0:	8552                	mv	a0,s4
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	4a6080e7          	jalr	1190(ra) # 80000a88 <kfree>
}
    800015ea:	70a2                	ld	ra,40(sp)
    800015ec:	7402                	ld	s0,32(sp)
    800015ee:	64e2                	ld	s1,24(sp)
    800015f0:	6942                	ld	s2,16(sp)
    800015f2:	69a2                	ld	s3,8(sp)
    800015f4:	6a02                	ld	s4,0(sp)
    800015f6:	6145                	addi	sp,sp,48
    800015f8:	8082                	ret

00000000800015fa <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015fa:	1101                	addi	sp,sp,-32
    800015fc:	ec06                	sd	ra,24(sp)
    800015fe:	e822                	sd	s0,16(sp)
    80001600:	e426                	sd	s1,8(sp)
    80001602:	1000                	addi	s0,sp,32
    80001604:	84aa                	mv	s1,a0
  if(sz > 0)
    80001606:	e999                	bnez	a1,8000161c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001608:	8526                	mv	a0,s1
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	f86080e7          	jalr	-122(ra) # 80001590 <freewalk>
}
    80001612:	60e2                	ld	ra,24(sp)
    80001614:	6442                	ld	s0,16(sp)
    80001616:	64a2                	ld	s1,8(sp)
    80001618:	6105                	addi	sp,sp,32
    8000161a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	167d                	addi	a2,a2,-1
    80001620:	962e                	add	a2,a2,a1
    80001622:	4685                	li	a3,1
    80001624:	8231                	srli	a2,a2,0xc
    80001626:	4581                	li	a1,0
    80001628:	00000097          	auipc	ra,0x0
    8000162c:	d12080e7          	jalr	-750(ra) # 8000133a <uvmunmap>
    80001630:	bfe1                	j	80001608 <uvmfree+0xe>

0000000080001632 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001632:	c679                	beqz	a2,80001700 <uvmcopy+0xce>
{
    80001634:	715d                	addi	sp,sp,-80
    80001636:	e486                	sd	ra,72(sp)
    80001638:	e0a2                	sd	s0,64(sp)
    8000163a:	fc26                	sd	s1,56(sp)
    8000163c:	f84a                	sd	s2,48(sp)
    8000163e:	f44e                	sd	s3,40(sp)
    80001640:	f052                	sd	s4,32(sp)
    80001642:	ec56                	sd	s5,24(sp)
    80001644:	e85a                	sd	s6,16(sp)
    80001646:	e45e                	sd	s7,8(sp)
    80001648:	0880                	addi	s0,sp,80
    8000164a:	8b2a                	mv	s6,a0
    8000164c:	8aae                	mv	s5,a1
    8000164e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001652:	4601                	li	a2,0
    80001654:	85ce                	mv	a1,s3
    80001656:	855a                	mv	a0,s6
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	a04080e7          	jalr	-1532(ra) # 8000105c <walk>
    80001660:	c531                	beqz	a0,800016ac <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001662:	6118                	ld	a4,0(a0)
    80001664:	00177793          	andi	a5,a4,1
    80001668:	cbb1                	beqz	a5,800016bc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000166a:	00a75593          	srli	a1,a4,0xa
    8000166e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001672:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	50e080e7          	jalr	1294(ra) # 80000b84 <kalloc>
    8000167e:	892a                	mv	s2,a0
    80001680:	c939                	beqz	a0,800016d6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001682:	6605                	lui	a2,0x1
    80001684:	85de                	mv	a1,s7
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	74a080e7          	jalr	1866(ra) # 80000dd0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000168e:	8726                	mv	a4,s1
    80001690:	86ca                	mv	a3,s2
    80001692:	6605                	lui	a2,0x1
    80001694:	85ce                	mv	a1,s3
    80001696:	8556                	mv	a0,s5
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	b0a080e7          	jalr	-1270(ra) # 800011a2 <mappages>
    800016a0:	e515                	bnez	a0,800016cc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016a2:	6785                	lui	a5,0x1
    800016a4:	99be                	add	s3,s3,a5
    800016a6:	fb49e6e3          	bltu	s3,s4,80001652 <uvmcopy+0x20>
    800016aa:	a081                	j	800016ea <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016ac:	00007517          	auipc	a0,0x7
    800016b0:	ae450513          	addi	a0,a0,-1308 # 80008190 <digits+0x138>
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	f22080e7          	jalr	-222(ra) # 800005d6 <panic>
      panic("uvmcopy: page not present");
    800016bc:	00007517          	auipc	a0,0x7
    800016c0:	af450513          	addi	a0,a0,-1292 # 800081b0 <digits+0x158>
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	f12080e7          	jalr	-238(ra) # 800005d6 <panic>
      kfree(mem);
    800016cc:	854a                	mv	a0,s2
    800016ce:	fffff097          	auipc	ra,0xfffff
    800016d2:	3ba080e7          	jalr	954(ra) # 80000a88 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016d6:	4685                	li	a3,1
    800016d8:	00c9d613          	srli	a2,s3,0xc
    800016dc:	4581                	li	a1,0
    800016de:	8556                	mv	a0,s5
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	c5a080e7          	jalr	-934(ra) # 8000133a <uvmunmap>
  return -1;
    800016e8:	557d                	li	a0,-1
}
    800016ea:	60a6                	ld	ra,72(sp)
    800016ec:	6406                	ld	s0,64(sp)
    800016ee:	74e2                	ld	s1,56(sp)
    800016f0:	7942                	ld	s2,48(sp)
    800016f2:	79a2                	ld	s3,40(sp)
    800016f4:	7a02                	ld	s4,32(sp)
    800016f6:	6ae2                	ld	s5,24(sp)
    800016f8:	6b42                	ld	s6,16(sp)
    800016fa:	6ba2                	ld	s7,8(sp)
    800016fc:	6161                	addi	sp,sp,80
    800016fe:	8082                	ret
  return 0;
    80001700:	4501                	li	a0,0
}
    80001702:	8082                	ret

0000000080001704 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001704:	1141                	addi	sp,sp,-16
    80001706:	e406                	sd	ra,8(sp)
    80001708:	e022                	sd	s0,0(sp)
    8000170a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000170c:	4601                	li	a2,0
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	94e080e7          	jalr	-1714(ra) # 8000105c <walk>
  if(pte == 0)
    80001716:	c901                	beqz	a0,80001726 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001718:	611c                	ld	a5,0(a0)
    8000171a:	9bbd                	andi	a5,a5,-17
    8000171c:	e11c                	sd	a5,0(a0)
}
    8000171e:	60a2                	ld	ra,8(sp)
    80001720:	6402                	ld	s0,0(sp)
    80001722:	0141                	addi	sp,sp,16
    80001724:	8082                	ret
    panic("uvmclear");
    80001726:	00007517          	auipc	a0,0x7
    8000172a:	aaa50513          	addi	a0,a0,-1366 # 800081d0 <digits+0x178>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	ea8080e7          	jalr	-344(ra) # 800005d6 <panic>

0000000080001736 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	c6bd                	beqz	a3,800017a4 <copyout+0x6e>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8c2e                	mv	s8,a1
    80001754:	8a32                	mv	s4,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001758:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000175a:	6a85                	lui	s5,0x1
    8000175c:	a015                	j	80001780 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000175e:	9562                	add	a0,a0,s8
    80001760:	0004861b          	sext.w	a2,s1
    80001764:	85d2                	mv	a1,s4
    80001766:	41250533          	sub	a0,a0,s2
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	666080e7          	jalr	1638(ra) # 80000dd0 <memmove>

    len -= n;
    80001772:	409989b3          	sub	s3,s3,s1
    src += n;
    80001776:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001778:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177c:	02098263          	beqz	s3,800017a0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001780:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001784:	85ca                	mv	a1,s2
    80001786:	855a                	mv	a0,s6
    80001788:	00000097          	auipc	ra,0x0
    8000178c:	97a080e7          	jalr	-1670(ra) # 80001102 <walkaddr>
    if(pa0 == 0)
    80001790:	cd01                	beqz	a0,800017a8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001792:	418904b3          	sub	s1,s2,s8
    80001796:	94d6                	add	s1,s1,s5
    if(n > len)
    80001798:	fc99f3e3          	bgeu	s3,s1,8000175e <copyout+0x28>
    8000179c:	84ce                	mv	s1,s3
    8000179e:	b7c1                	j	8000175e <copyout+0x28>
  }
  return 0;
    800017a0:	4501                	li	a0,0
    800017a2:	a021                	j	800017aa <copyout+0x74>
    800017a4:	4501                	li	a0,0
}
    800017a6:	8082                	ret
      return -1;
    800017a8:	557d                	li	a0,-1
}
    800017aa:	60a6                	ld	ra,72(sp)
    800017ac:	6406                	ld	s0,64(sp)
    800017ae:	74e2                	ld	s1,56(sp)
    800017b0:	7942                	ld	s2,48(sp)
    800017b2:	79a2                	ld	s3,40(sp)
    800017b4:	7a02                	ld	s4,32(sp)
    800017b6:	6ae2                	ld	s5,24(sp)
    800017b8:	6b42                	ld	s6,16(sp)
    800017ba:	6ba2                	ld	s7,8(sp)
    800017bc:	6c02                	ld	s8,0(sp)
    800017be:	6161                	addi	sp,sp,80
    800017c0:	8082                	ret

00000000800017c2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017c2:	c6bd                	beqz	a3,80001830 <copyin+0x6e>
{
    800017c4:	715d                	addi	sp,sp,-80
    800017c6:	e486                	sd	ra,72(sp)
    800017c8:	e0a2                	sd	s0,64(sp)
    800017ca:	fc26                	sd	s1,56(sp)
    800017cc:	f84a                	sd	s2,48(sp)
    800017ce:	f44e                	sd	s3,40(sp)
    800017d0:	f052                	sd	s4,32(sp)
    800017d2:	ec56                	sd	s5,24(sp)
    800017d4:	e85a                	sd	s6,16(sp)
    800017d6:	e45e                	sd	s7,8(sp)
    800017d8:	e062                	sd	s8,0(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8b2a                	mv	s6,a0
    800017de:	8a2e                	mv	s4,a1
    800017e0:	8c32                	mv	s8,a2
    800017e2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6a85                	lui	s5,0x1
    800017e8:	a015                	j	8000180c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017ea:	9562                	add	a0,a0,s8
    800017ec:	0004861b          	sext.w	a2,s1
    800017f0:	412505b3          	sub	a1,a0,s2
    800017f4:	8552                	mv	a0,s4
    800017f6:	fffff097          	auipc	ra,0xfffff
    800017fa:	5da080e7          	jalr	1498(ra) # 80000dd0 <memmove>

    len -= n;
    800017fe:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001802:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001804:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001808:	02098263          	beqz	s3,8000182c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000180c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001810:	85ca                	mv	a1,s2
    80001812:	855a                	mv	a0,s6
    80001814:	00000097          	auipc	ra,0x0
    80001818:	8ee080e7          	jalr	-1810(ra) # 80001102 <walkaddr>
    if(pa0 == 0)
    8000181c:	cd01                	beqz	a0,80001834 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000181e:	418904b3          	sub	s1,s2,s8
    80001822:	94d6                	add	s1,s1,s5
    if(n > len)
    80001824:	fc99f3e3          	bgeu	s3,s1,800017ea <copyin+0x28>
    80001828:	84ce                	mv	s1,s3
    8000182a:	b7c1                	j	800017ea <copyin+0x28>
  }
  return 0;
    8000182c:	4501                	li	a0,0
    8000182e:	a021                	j	80001836 <copyin+0x74>
    80001830:	4501                	li	a0,0
}
    80001832:	8082                	ret
      return -1;
    80001834:	557d                	li	a0,-1
}
    80001836:	60a6                	ld	ra,72(sp)
    80001838:	6406                	ld	s0,64(sp)
    8000183a:	74e2                	ld	s1,56(sp)
    8000183c:	7942                	ld	s2,48(sp)
    8000183e:	79a2                	ld	s3,40(sp)
    80001840:	7a02                	ld	s4,32(sp)
    80001842:	6ae2                	ld	s5,24(sp)
    80001844:	6b42                	ld	s6,16(sp)
    80001846:	6ba2                	ld	s7,8(sp)
    80001848:	6c02                	ld	s8,0(sp)
    8000184a:	6161                	addi	sp,sp,80
    8000184c:	8082                	ret

000000008000184e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000184e:	c6c5                	beqz	a3,800018f6 <copyinstr+0xa8>
{
    80001850:	715d                	addi	sp,sp,-80
    80001852:	e486                	sd	ra,72(sp)
    80001854:	e0a2                	sd	s0,64(sp)
    80001856:	fc26                	sd	s1,56(sp)
    80001858:	f84a                	sd	s2,48(sp)
    8000185a:	f44e                	sd	s3,40(sp)
    8000185c:	f052                	sd	s4,32(sp)
    8000185e:	ec56                	sd	s5,24(sp)
    80001860:	e85a                	sd	s6,16(sp)
    80001862:	e45e                	sd	s7,8(sp)
    80001864:	0880                	addi	s0,sp,80
    80001866:	8a2a                	mv	s4,a0
    80001868:	8b2e                	mv	s6,a1
    8000186a:	8bb2                	mv	s7,a2
    8000186c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000186e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001870:	6985                	lui	s3,0x1
    80001872:	a035                	j	8000189e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001874:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001878:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000187a:	0017b793          	seqz	a5,a5
    8000187e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001882:	60a6                	ld	ra,72(sp)
    80001884:	6406                	ld	s0,64(sp)
    80001886:	74e2                	ld	s1,56(sp)
    80001888:	7942                	ld	s2,48(sp)
    8000188a:	79a2                	ld	s3,40(sp)
    8000188c:	7a02                	ld	s4,32(sp)
    8000188e:	6ae2                	ld	s5,24(sp)
    80001890:	6b42                	ld	s6,16(sp)
    80001892:	6ba2                	ld	s7,8(sp)
    80001894:	6161                	addi	sp,sp,80
    80001896:	8082                	ret
    srcva = va0 + PGSIZE;
    80001898:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000189c:	c8a9                	beqz	s1,800018ee <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000189e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018a2:	85ca                	mv	a1,s2
    800018a4:	8552                	mv	a0,s4
    800018a6:	00000097          	auipc	ra,0x0
    800018aa:	85c080e7          	jalr	-1956(ra) # 80001102 <walkaddr>
    if(pa0 == 0)
    800018ae:	c131                	beqz	a0,800018f2 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018b0:	41790833          	sub	a6,s2,s7
    800018b4:	984e                	add	a6,a6,s3
    if(n > max)
    800018b6:	0104f363          	bgeu	s1,a6,800018bc <copyinstr+0x6e>
    800018ba:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018bc:	955e                	add	a0,a0,s7
    800018be:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018c2:	fc080be3          	beqz	a6,80001898 <copyinstr+0x4a>
    800018c6:	985a                	add	a6,a6,s6
    800018c8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ca:	41650633          	sub	a2,a0,s6
    800018ce:	14fd                	addi	s1,s1,-1
    800018d0:	9b26                	add	s6,s6,s1
    800018d2:	00f60733          	add	a4,a2,a5
    800018d6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018da:	df49                	beqz	a4,80001874 <copyinstr+0x26>
        *dst = *p;
    800018dc:	00e78023          	sb	a4,0(a5)
      --max;
    800018e0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018e4:	0785                	addi	a5,a5,1
    while(n > 0){
    800018e6:	ff0796e3          	bne	a5,a6,800018d2 <copyinstr+0x84>
      dst++;
    800018ea:	8b42                	mv	s6,a6
    800018ec:	b775                	j	80001898 <copyinstr+0x4a>
    800018ee:	4781                	li	a5,0
    800018f0:	b769                	j	8000187a <copyinstr+0x2c>
      return -1;
    800018f2:	557d                	li	a0,-1
    800018f4:	b779                	j	80001882 <copyinstr+0x34>
  int got_null = 0;
    800018f6:	4781                	li	a5,0
  if(got_null){
    800018f8:	0017b793          	seqz	a5,a5
    800018fc:	40f00533          	neg	a0,a5
}
    80001900:	8082                	ret

0000000080001902 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001902:	1101                	addi	sp,sp,-32
    80001904:	ec06                	sd	ra,24(sp)
    80001906:	e822                	sd	s0,16(sp)
    80001908:	e426                	sd	s1,8(sp)
    8000190a:	1000                	addi	s0,sp,32
    8000190c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	2ec080e7          	jalr	748(ra) # 80000bfa <holding>
    80001916:	c909                	beqz	a0,80001928 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001918:	749c                	ld	a5,40(s1)
    8000191a:	00978f63          	beq	a5,s1,80001938 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000191e:	60e2                	ld	ra,24(sp)
    80001920:	6442                	ld	s0,16(sp)
    80001922:	64a2                	ld	s1,8(sp)
    80001924:	6105                	addi	sp,sp,32
    80001926:	8082                	ret
    panic("wakeup1");
    80001928:	00007517          	auipc	a0,0x7
    8000192c:	8b850513          	addi	a0,a0,-1864 # 800081e0 <digits+0x188>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	ca6080e7          	jalr	-858(ra) # 800005d6 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001938:	4c98                	lw	a4,24(s1)
    8000193a:	4785                	li	a5,1
    8000193c:	fef711e3          	bne	a4,a5,8000191e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001940:	4789                	li	a5,2
    80001942:	cc9c                	sw	a5,24(s1)
}
    80001944:	bfe9                	j	8000191e <wakeup1+0x1c>

0000000080001946 <procinit>:
{
    80001946:	715d                	addi	sp,sp,-80
    80001948:	e486                	sd	ra,72(sp)
    8000194a:	e0a2                	sd	s0,64(sp)
    8000194c:	fc26                	sd	s1,56(sp)
    8000194e:	f84a                	sd	s2,48(sp)
    80001950:	f44e                	sd	s3,40(sp)
    80001952:	f052                	sd	s4,32(sp)
    80001954:	ec56                	sd	s5,24(sp)
    80001956:	e85a                	sd	s6,16(sp)
    80001958:	e45e                	sd	s7,8(sp)
    8000195a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000195c:	00007597          	auipc	a1,0x7
    80001960:	88c58593          	addi	a1,a1,-1908 # 800081e8 <digits+0x190>
    80001964:	00010517          	auipc	a0,0x10
    80001968:	fec50513          	addi	a0,a0,-20 # 80011950 <pid_lock>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	278080e7          	jalr	632(ra) # 80000be4 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001974:	00010917          	auipc	s2,0x10
    80001978:	3f490913          	addi	s2,s2,1012 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000197c:	00007b97          	auipc	s7,0x7
    80001980:	874b8b93          	addi	s7,s7,-1932 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001984:	8b4a                	mv	s6,s2
    80001986:	00006a97          	auipc	s5,0x6
    8000198a:	67aa8a93          	addi	s5,s5,1658 # 80008000 <etext>
    8000198e:	040009b7          	lui	s3,0x4000
    80001992:	19fd                	addi	s3,s3,-1
    80001994:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001996:	00016a17          	auipc	s4,0x16
    8000199a:	5d2a0a13          	addi	s4,s4,1490 # 80017f68 <tickslock>
      initlock(&p->lock, "proc");
    8000199e:	85de                	mv	a1,s7
    800019a0:	854a                	mv	a0,s2
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	242080e7          	jalr	578(ra) # 80000be4 <initlock>
      char *pa = kalloc();
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1da080e7          	jalr	474(ra) # 80000b84 <kalloc>
    800019b2:	85aa                	mv	a1,a0
      if(pa == 0)
    800019b4:	c929                	beqz	a0,80001a06 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019b6:	416904b3          	sub	s1,s2,s6
    800019ba:	848d                	srai	s1,s1,0x3
    800019bc:	000ab783          	ld	a5,0(s5)
    800019c0:	02f484b3          	mul	s1,s1,a5
    800019c4:	2485                	addiw	s1,s1,1
    800019c6:	00d4949b          	slliw	s1,s1,0xd
    800019ca:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ce:	4699                	li	a3,6
    800019d0:	6605                	lui	a2,0x1
    800019d2:	8526                	mv	a0,s1
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	85c080e7          	jalr	-1956(ra) # 80001230 <kvmmap>
      p->kstack = va;
    800019dc:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e0:	18890913          	addi	s2,s2,392
    800019e4:	fb491de3          	bne	s2,s4,8000199e <procinit+0x58>
  kvminithart();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	650080e7          	jalr	1616(ra) # 80001038 <kvminithart>
}
    800019f0:	60a6                	ld	ra,72(sp)
    800019f2:	6406                	ld	s0,64(sp)
    800019f4:	74e2                	ld	s1,56(sp)
    800019f6:	7942                	ld	s2,48(sp)
    800019f8:	79a2                	ld	s3,40(sp)
    800019fa:	7a02                	ld	s4,32(sp)
    800019fc:	6ae2                	ld	s5,24(sp)
    800019fe:	6b42                	ld	s6,16(sp)
    80001a00:	6ba2                	ld	s7,8(sp)
    80001a02:	6161                	addi	sp,sp,80
    80001a04:	8082                	ret
        panic("kalloc");
    80001a06:	00006517          	auipc	a0,0x6
    80001a0a:	7f250513          	addi	a0,a0,2034 # 800081f8 <digits+0x1a0>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	bc8080e7          	jalr	-1080(ra) # 800005d6 <panic>

0000000080001a16 <cpuid>:
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e422                	sd	s0,8(sp)
    80001a1a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a1c:	8512                	mv	a0,tp
}
    80001a1e:	2501                	sext.w	a0,a0
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <mycpu>:
mycpu(void) {
    80001a26:	1141                	addi	sp,sp,-16
    80001a28:	e422                	sd	s0,8(sp)
    80001a2a:	0800                	addi	s0,sp,16
    80001a2c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a2e:	2781                	sext.w	a5,a5
    80001a30:	079e                	slli	a5,a5,0x7
}
    80001a32:	00010517          	auipc	a0,0x10
    80001a36:	f3650513          	addi	a0,a0,-202 # 80011968 <cpus>
    80001a3a:	953e                	add	a0,a0,a5
    80001a3c:	6422                	ld	s0,8(sp)
    80001a3e:	0141                	addi	sp,sp,16
    80001a40:	8082                	ret

0000000080001a42 <myproc>:
myproc(void) {
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	1000                	addi	s0,sp,32
  push_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	1dc080e7          	jalr	476(ra) # 80000c28 <push_off>
    80001a54:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a56:	2781                	sext.w	a5,a5
    80001a58:	079e                	slli	a5,a5,0x7
    80001a5a:	00010717          	auipc	a4,0x10
    80001a5e:	ef670713          	addi	a4,a4,-266 # 80011950 <pid_lock>
    80001a62:	97ba                	add	a5,a5,a4
    80001a64:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	262080e7          	jalr	610(ra) # 80000cc8 <pop_off>
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6105                	addi	sp,sp,32
    80001a78:	8082                	ret

0000000080001a7a <forkret>:
{
    80001a7a:	1141                	addi	sp,sp,-16
    80001a7c:	e406                	sd	ra,8(sp)
    80001a7e:	e022                	sd	s0,0(sp)
    80001a80:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	fc0080e7          	jalr	-64(ra) # 80001a42 <myproc>
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	29e080e7          	jalr	670(ra) # 80000d28 <release>
  if (first) {
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	dae7a783          	lw	a5,-594(a5) # 80008840 <first.1671>
    80001a9a:	eb89                	bnez	a5,80001aac <forkret+0x32>
  usertrapret();
    80001a9c:	00001097          	auipc	ra,0x1
    80001aa0:	c28080e7          	jalr	-984(ra) # 800026c4 <usertrapret>
}
    80001aa4:	60a2                	ld	ra,8(sp)
    80001aa6:	6402                	ld	s0,0(sp)
    80001aa8:	0141                	addi	sp,sp,16
    80001aaa:	8082                	ret
    first = 0;
    80001aac:	00007797          	auipc	a5,0x7
    80001ab0:	d807aa23          	sw	zero,-620(a5) # 80008840 <first.1671>
    fsinit(ROOTDEV);
    80001ab4:	4505                	li	a0,1
    80001ab6:	00002097          	auipc	ra,0x2
    80001aba:	a44080e7          	jalr	-1468(ra) # 800034fa <fsinit>
    80001abe:	bff9                	j	80001a9c <forkret+0x22>

0000000080001ac0 <allocpid>:
allocpid() {
    80001ac0:	1101                	addi	sp,sp,-32
    80001ac2:	ec06                	sd	ra,24(sp)
    80001ac4:	e822                	sd	s0,16(sp)
    80001ac6:	e426                	sd	s1,8(sp)
    80001ac8:	e04a                	sd	s2,0(sp)
    80001aca:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001acc:	00010917          	auipc	s2,0x10
    80001ad0:	e8490913          	addi	s2,s2,-380 # 80011950 <pid_lock>
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	19e080e7          	jalr	414(ra) # 80000c74 <acquire>
  pid = nextpid;
    80001ade:	00007797          	auipc	a5,0x7
    80001ae2:	d6678793          	addi	a5,a5,-666 # 80008844 <nextpid>
    80001ae6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae8:	0014871b          	addiw	a4,s1,1
    80001aec:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aee:	854a                	mv	a0,s2
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	238080e7          	jalr	568(ra) # 80000d28 <release>
}
    80001af8:	8526                	mv	a0,s1
    80001afa:	60e2                	ld	ra,24(sp)
    80001afc:	6442                	ld	s0,16(sp)
    80001afe:	64a2                	ld	s1,8(sp)
    80001b00:	6902                	ld	s2,0(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret

0000000080001b06 <proc_pagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	8ea080e7          	jalr	-1814(ra) # 800013fe <uvmcreate>
    80001b1c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1e:	c121                	beqz	a0,80001b5e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b20:	4729                	li	a4,10
    80001b22:	00005697          	auipc	a3,0x5
    80001b26:	4de68693          	addi	a3,a3,1246 # 80007000 <_trampoline>
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	66e080e7          	jalr	1646(ra) # 800011a2 <mappages>
    80001b3c:	02054863          	bltz	a0,80001b6c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b40:	4719                	li	a4,6
    80001b42:	05893683          	ld	a3,88(s2)
    80001b46:	6605                	lui	a2,0x1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	650080e7          	jalr	1616(ra) # 800011a2 <mappages>
    80001b5a:	02054163          	bltz	a0,80001b7c <proc_pagetable+0x76>
}
    80001b5e:	8526                	mv	a0,s1
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6902                	ld	s2,0(sp)
    80001b68:	6105                	addi	sp,sp,32
    80001b6a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b6c:	4581                	li	a1,0
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	a8a080e7          	jalr	-1398(ra) # 800015fa <uvmfree>
    return 0;
    80001b78:	4481                	li	s1,0
    80001b7a:	b7d5                	j	80001b5e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7c:	4681                	li	a3,0
    80001b7e:	4605                	li	a2,1
    80001b80:	040005b7          	lui	a1,0x4000
    80001b84:	15fd                	addi	a1,a1,-1
    80001b86:	05b2                	slli	a1,a1,0xc
    80001b88:	8526                	mv	a0,s1
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	7b0080e7          	jalr	1968(ra) # 8000133a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b92:	4581                	li	a1,0
    80001b94:	8526                	mv	a0,s1
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	a64080e7          	jalr	-1436(ra) # 800015fa <uvmfree>
    return 0;
    80001b9e:	4481                	li	s1,0
    80001ba0:	bf7d                	j	80001b5e <proc_pagetable+0x58>

0000000080001ba2 <proc_freepagetable>:
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
    80001bb0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb2:	4681                	li	a3,0
    80001bb4:	4605                	li	a2,1
    80001bb6:	040005b7          	lui	a1,0x4000
    80001bba:	15fd                	addi	a1,a1,-1
    80001bbc:	05b2                	slli	a1,a1,0xc
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	77c080e7          	jalr	1916(ra) # 8000133a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc6:	4681                	li	a3,0
    80001bc8:	4605                	li	a2,1
    80001bca:	020005b7          	lui	a1,0x2000
    80001bce:	15fd                	addi	a1,a1,-1
    80001bd0:	05b6                	slli	a1,a1,0xd
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	766080e7          	jalr	1894(ra) # 8000133a <uvmunmap>
  uvmfree(pagetable, sz);
    80001bdc:	85ca                	mv	a1,s2
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	a1a080e7          	jalr	-1510(ra) # 800015fa <uvmfree>
}
    80001be8:	60e2                	ld	ra,24(sp)
    80001bea:	6442                	ld	s0,16(sp)
    80001bec:	64a2                	ld	s1,8(sp)
    80001bee:	6902                	ld	s2,0(sp)
    80001bf0:	6105                	addi	sp,sp,32
    80001bf2:	8082                	ret

0000000080001bf4 <freeproc>:
{
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c00:	6d28                	ld	a0,88(a0)
    80001c02:	c509                	beqz	a0,80001c0c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	e84080e7          	jalr	-380(ra) # 80000a88 <kfree>
  p->trapframe = 0;
    80001c0c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c10:	68a8                	ld	a0,80(s1)
    80001c12:	c511                	beqz	a0,80001c1e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c14:	64ac                	ld	a1,72(s1)
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	f8c080e7          	jalr	-116(ra) # 80001ba2 <proc_freepagetable>
  p->pagetable = 0;
    80001c1e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c22:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c26:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c2a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c2e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c32:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c36:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c3a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c3e:	0004ac23          	sw	zero,24(s1)
}
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6105                	addi	sp,sp,32
    80001c4a:	8082                	ret

0000000080001c4c <allocproc>:
{
    80001c4c:	1101                	addi	sp,sp,-32
    80001c4e:	ec06                	sd	ra,24(sp)
    80001c50:	e822                	sd	s0,16(sp)
    80001c52:	e426                	sd	s1,8(sp)
    80001c54:	e04a                	sd	s2,0(sp)
    80001c56:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00010497          	auipc	s1,0x10
    80001c5c:	11048493          	addi	s1,s1,272 # 80011d68 <proc>
    80001c60:	00016917          	auipc	s2,0x16
    80001c64:	30890913          	addi	s2,s2,776 # 80017f68 <tickslock>
    acquire(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	00a080e7          	jalr	10(ra) # 80000c74 <acquire>
    if(p->state == UNUSED) {
    80001c72:	4c9c                	lw	a5,24(s1)
    80001c74:	cf81                	beqz	a5,80001c8c <allocproc+0x40>
      release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	0b0080e7          	jalr	176(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c80:	18848493          	addi	s1,s1,392
    80001c84:	ff2492e3          	bne	s1,s2,80001c68 <allocproc+0x1c>
  return 0;
    80001c88:	4481                	li	s1,0
    80001c8a:	a8b9                	j	80001ce8 <allocproc+0x9c>
  p->pid = allocpid();
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e34080e7          	jalr	-460(ra) # 80001ac0 <allocpid>
    80001c94:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	eee080e7          	jalr	-274(ra) # 80000b84 <kalloc>
    80001c9e:	892a                	mv	s2,a0
    80001ca0:	eca8                	sd	a0,88(s1)
    80001ca2:	c931                	beqz	a0,80001cf6 <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e60080e7          	jalr	-416(ra) # 80001b06 <proc_pagetable>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb2:	c929                	beqz	a0,80001d04 <allocproc+0xb8>
  memset(&p->context, 0, sizeof(p->context));
    80001cb4:	07000613          	li	a2,112
    80001cb8:	4581                	li	a1,0
    80001cba:	06048513          	addi	a0,s1,96
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	0b2080e7          	jalr	178(ra) # 80000d70 <memset>
  p->context.ra = (uint64)forkret;
    80001cc6:	00000797          	auipc	a5,0x0
    80001cca:	db478793          	addi	a5,a5,-588 # 80001a7a <forkret>
    80001cce:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cd0:	60bc                	ld	a5,64(s1)
    80001cd2:	6705                	lui	a4,0x1
    80001cd4:	97ba                	add	a5,a5,a4
    80001cd6:	f4bc                	sd	a5,104(s1)
  p->interval = 0;
    80001cd8:	1604a423          	sw	zero,360(s1)
  p->handler = 0;
    80001cdc:	1604b823          	sd	zero,368(s1)
  p->passedticks = 0;
    80001ce0:	1604ac23          	sw	zero,376(s1)
  p->trapframecopy = 0;
    80001ce4:	1804b023          	sd	zero,384(s1)
}
    80001ce8:	8526                	mv	a0,s1
    80001cea:	60e2                	ld	ra,24(sp)
    80001cec:	6442                	ld	s0,16(sp)
    80001cee:	64a2                	ld	s1,8(sp)
    80001cf0:	6902                	ld	s2,0(sp)
    80001cf2:	6105                	addi	sp,sp,32
    80001cf4:	8082                	ret
    release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	030080e7          	jalr	48(ra) # 80000d28 <release>
    return 0;
    80001d00:	84ca                	mv	s1,s2
    80001d02:	b7dd                	j	80001ce8 <allocproc+0x9c>
    freeproc(p);
    80001d04:	8526                	mv	a0,s1
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	eee080e7          	jalr	-274(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	018080e7          	jalr	24(ra) # 80000d28 <release>
    return 0;
    80001d18:	84ca                	mv	s1,s2
    80001d1a:	b7f9                	j	80001ce8 <allocproc+0x9c>

0000000080001d1c <userinit>:
{
    80001d1c:	1101                	addi	sp,sp,-32
    80001d1e:	ec06                	sd	ra,24(sp)
    80001d20:	e822                	sd	s0,16(sp)
    80001d22:	e426                	sd	s1,8(sp)
    80001d24:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d26:	00000097          	auipc	ra,0x0
    80001d2a:	f26080e7          	jalr	-218(ra) # 80001c4c <allocproc>
    80001d2e:	84aa                	mv	s1,a0
  initproc = p;
    80001d30:	00007797          	auipc	a5,0x7
    80001d34:	2ea7b423          	sd	a0,744(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d38:	03400613          	li	a2,52
    80001d3c:	00007597          	auipc	a1,0x7
    80001d40:	b1458593          	addi	a1,a1,-1260 # 80008850 <initcode>
    80001d44:	6928                	ld	a0,80(a0)
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	6e6080e7          	jalr	1766(ra) # 8000142c <uvminit>
  p->sz = PGSIZE;
    80001d4e:	6785                	lui	a5,0x1
    80001d50:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d52:	6cb8                	ld	a4,88(s1)
    80001d54:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d58:	6cb8                	ld	a4,88(s1)
    80001d5a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d5c:	4641                	li	a2,16
    80001d5e:	00006597          	auipc	a1,0x6
    80001d62:	4a258593          	addi	a1,a1,1186 # 80008200 <digits+0x1a8>
    80001d66:	15848513          	addi	a0,s1,344
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	15c080e7          	jalr	348(ra) # 80000ec6 <safestrcpy>
  p->cwd = namei("/");
    80001d72:	00006517          	auipc	a0,0x6
    80001d76:	49e50513          	addi	a0,a0,1182 # 80008210 <digits+0x1b8>
    80001d7a:	00002097          	auipc	ra,0x2
    80001d7e:	1a8080e7          	jalr	424(ra) # 80003f22 <namei>
    80001d82:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d86:	4789                	li	a5,2
    80001d88:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <release>
}
    80001d94:	60e2                	ld	ra,24(sp)
    80001d96:	6442                	ld	s0,16(sp)
    80001d98:	64a2                	ld	s1,8(sp)
    80001d9a:	6105                	addi	sp,sp,32
    80001d9c:	8082                	ret

0000000080001d9e <growproc>:
{
    80001d9e:	1101                	addi	sp,sp,-32
    80001da0:	ec06                	sd	ra,24(sp)
    80001da2:	e822                	sd	s0,16(sp)
    80001da4:	e426                	sd	s1,8(sp)
    80001da6:	e04a                	sd	s2,0(sp)
    80001da8:	1000                	addi	s0,sp,32
    80001daa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	c96080e7          	jalr	-874(ra) # 80001a42 <myproc>
    80001db4:	892a                	mv	s2,a0
  sz = p->sz;
    80001db6:	652c                	ld	a1,72(a0)
    80001db8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dbc:	00904f63          	bgtz	s1,80001dda <growproc+0x3c>
  } else if(n < 0){
    80001dc0:	0204cc63          	bltz	s1,80001df8 <growproc+0x5a>
  p->sz = sz;
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dcc:	4501                	li	a0,0
}
    80001dce:	60e2                	ld	ra,24(sp)
    80001dd0:	6442                	ld	s0,16(sp)
    80001dd2:	64a2                	ld	s1,8(sp)
    80001dd4:	6902                	ld	s2,0(sp)
    80001dd6:	6105                	addi	sp,sp,32
    80001dd8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dda:	9e25                	addw	a2,a2,s1
    80001ddc:	1602                	slli	a2,a2,0x20
    80001dde:	9201                	srli	a2,a2,0x20
    80001de0:	1582                	slli	a1,a1,0x20
    80001de2:	9181                	srli	a1,a1,0x20
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	700080e7          	jalr	1792(ra) # 800014e6 <uvmalloc>
    80001dee:	0005061b          	sext.w	a2,a0
    80001df2:	fa69                	bnez	a2,80001dc4 <growproc+0x26>
      return -1;
    80001df4:	557d                	li	a0,-1
    80001df6:	bfe1                	j	80001dce <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df8:	9e25                	addw	a2,a2,s1
    80001dfa:	1602                	slli	a2,a2,0x20
    80001dfc:	9201                	srli	a2,a2,0x20
    80001dfe:	1582                	slli	a1,a1,0x20
    80001e00:	9181                	srli	a1,a1,0x20
    80001e02:	6928                	ld	a0,80(a0)
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	69a080e7          	jalr	1690(ra) # 8000149e <uvmdealloc>
    80001e0c:	0005061b          	sext.w	a2,a0
    80001e10:	bf55                	j	80001dc4 <growproc+0x26>

0000000080001e12 <fork>:
{
    80001e12:	7179                	addi	sp,sp,-48
    80001e14:	f406                	sd	ra,40(sp)
    80001e16:	f022                	sd	s0,32(sp)
    80001e18:	ec26                	sd	s1,24(sp)
    80001e1a:	e84a                	sd	s2,16(sp)
    80001e1c:	e44e                	sd	s3,8(sp)
    80001e1e:	e052                	sd	s4,0(sp)
    80001e20:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	c20080e7          	jalr	-992(ra) # 80001a42 <myproc>
    80001e2a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	e20080e7          	jalr	-480(ra) # 80001c4c <allocproc>
    80001e34:	c175                	beqz	a0,80001f18 <fork+0x106>
    80001e36:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e38:	04893603          	ld	a2,72(s2)
    80001e3c:	692c                	ld	a1,80(a0)
    80001e3e:	05093503          	ld	a0,80(s2)
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	7f0080e7          	jalr	2032(ra) # 80001632 <uvmcopy>
    80001e4a:	04054863          	bltz	a0,80001e9a <fork+0x88>
  np->sz = p->sz;
    80001e4e:	04893783          	ld	a5,72(s2)
    80001e52:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e56:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e5a:	05893683          	ld	a3,88(s2)
    80001e5e:	87b6                	mv	a5,a3
    80001e60:	0589b703          	ld	a4,88(s3)
    80001e64:	12068693          	addi	a3,a3,288
    80001e68:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e6c:	6788                	ld	a0,8(a5)
    80001e6e:	6b8c                	ld	a1,16(a5)
    80001e70:	6f90                	ld	a2,24(a5)
    80001e72:	01073023          	sd	a6,0(a4)
    80001e76:	e708                	sd	a0,8(a4)
    80001e78:	eb0c                	sd	a1,16(a4)
    80001e7a:	ef10                	sd	a2,24(a4)
    80001e7c:	02078793          	addi	a5,a5,32
    80001e80:	02070713          	addi	a4,a4,32
    80001e84:	fed792e3          	bne	a5,a3,80001e68 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e88:	0589b783          	ld	a5,88(s3)
    80001e8c:	0607b823          	sd	zero,112(a5)
    80001e90:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e94:	15000a13          	li	s4,336
    80001e98:	a03d                	j	80001ec6 <fork+0xb4>
    freeproc(np);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	d58080e7          	jalr	-680(ra) # 80001bf4 <freeproc>
    release(&np->lock);
    80001ea4:	854e                	mv	a0,s3
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	e82080e7          	jalr	-382(ra) # 80000d28 <release>
    return -1;
    80001eae:	54fd                	li	s1,-1
    80001eb0:	a899                	j	80001f06 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb2:	00002097          	auipc	ra,0x2
    80001eb6:	6fc080e7          	jalr	1788(ra) # 800045ae <filedup>
    80001eba:	009987b3          	add	a5,s3,s1
    80001ebe:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ec0:	04a1                	addi	s1,s1,8
    80001ec2:	01448763          	beq	s1,s4,80001ed0 <fork+0xbe>
    if(p->ofile[i])
    80001ec6:	009907b3          	add	a5,s2,s1
    80001eca:	6388                	ld	a0,0(a5)
    80001ecc:	f17d                	bnez	a0,80001eb2 <fork+0xa0>
    80001ece:	bfcd                	j	80001ec0 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ed0:	15093503          	ld	a0,336(s2)
    80001ed4:	00002097          	auipc	ra,0x2
    80001ed8:	860080e7          	jalr	-1952(ra) # 80003734 <idup>
    80001edc:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ee0:	4641                	li	a2,16
    80001ee2:	15890593          	addi	a1,s2,344
    80001ee6:	15898513          	addi	a0,s3,344
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	fdc080e7          	jalr	-36(ra) # 80000ec6 <safestrcpy>
  pid = np->pid;
    80001ef2:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ef6:	4789                	li	a5,2
    80001ef8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001efc:	854e                	mv	a0,s3
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	e2a080e7          	jalr	-470(ra) # 80000d28 <release>
}
    80001f06:	8526                	mv	a0,s1
    80001f08:	70a2                	ld	ra,40(sp)
    80001f0a:	7402                	ld	s0,32(sp)
    80001f0c:	64e2                	ld	s1,24(sp)
    80001f0e:	6942                	ld	s2,16(sp)
    80001f10:	69a2                	ld	s3,8(sp)
    80001f12:	6a02                	ld	s4,0(sp)
    80001f14:	6145                	addi	sp,sp,48
    80001f16:	8082                	ret
    return -1;
    80001f18:	54fd                	li	s1,-1
    80001f1a:	b7f5                	j	80001f06 <fork+0xf4>

0000000080001f1c <reparent>:
{
    80001f1c:	7179                	addi	sp,sp,-48
    80001f1e:	f406                	sd	ra,40(sp)
    80001f20:	f022                	sd	s0,32(sp)
    80001f22:	ec26                	sd	s1,24(sp)
    80001f24:	e84a                	sd	s2,16(sp)
    80001f26:	e44e                	sd	s3,8(sp)
    80001f28:	e052                	sd	s4,0(sp)
    80001f2a:	1800                	addi	s0,sp,48
    80001f2c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f2e:	00010497          	auipc	s1,0x10
    80001f32:	e3a48493          	addi	s1,s1,-454 # 80011d68 <proc>
      pp->parent = initproc;
    80001f36:	00007a17          	auipc	s4,0x7
    80001f3a:	0e2a0a13          	addi	s4,s4,226 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f3e:	00016997          	auipc	s3,0x16
    80001f42:	02a98993          	addi	s3,s3,42 # 80017f68 <tickslock>
    80001f46:	a029                	j	80001f50 <reparent+0x34>
    80001f48:	18848493          	addi	s1,s1,392
    80001f4c:	03348363          	beq	s1,s3,80001f72 <reparent+0x56>
    if(pp->parent == p){
    80001f50:	709c                	ld	a5,32(s1)
    80001f52:	ff279be3          	bne	a5,s2,80001f48 <reparent+0x2c>
      acquire(&pp->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	d1c080e7          	jalr	-740(ra) # 80000c74 <acquire>
      pp->parent = initproc;
    80001f60:	000a3783          	ld	a5,0(s4)
    80001f64:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	dc0080e7          	jalr	-576(ra) # 80000d28 <release>
    80001f70:	bfe1                	j	80001f48 <reparent+0x2c>
}
    80001f72:	70a2                	ld	ra,40(sp)
    80001f74:	7402                	ld	s0,32(sp)
    80001f76:	64e2                	ld	s1,24(sp)
    80001f78:	6942                	ld	s2,16(sp)
    80001f7a:	69a2                	ld	s3,8(sp)
    80001f7c:	6a02                	ld	s4,0(sp)
    80001f7e:	6145                	addi	sp,sp,48
    80001f80:	8082                	ret

0000000080001f82 <scheduler>:
{
    80001f82:	715d                	addi	sp,sp,-80
    80001f84:	e486                	sd	ra,72(sp)
    80001f86:	e0a2                	sd	s0,64(sp)
    80001f88:	fc26                	sd	s1,56(sp)
    80001f8a:	f84a                	sd	s2,48(sp)
    80001f8c:	f44e                	sd	s3,40(sp)
    80001f8e:	f052                	sd	s4,32(sp)
    80001f90:	ec56                	sd	s5,24(sp)
    80001f92:	e85a                	sd	s6,16(sp)
    80001f94:	e45e                	sd	s7,8(sp)
    80001f96:	e062                	sd	s8,0(sp)
    80001f98:	0880                	addi	s0,sp,80
    80001f9a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f9c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f9e:	00779b13          	slli	s6,a5,0x7
    80001fa2:	00010717          	auipc	a4,0x10
    80001fa6:	9ae70713          	addi	a4,a4,-1618 # 80011950 <pid_lock>
    80001faa:	975a                	add	a4,a4,s6
    80001fac:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fb0:	00010717          	auipc	a4,0x10
    80001fb4:	9c070713          	addi	a4,a4,-1600 # 80011970 <cpus+0x8>
    80001fb8:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fba:	4c0d                	li	s8,3
        c->proc = p;
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	00010a17          	auipc	s4,0x10
    80001fc2:	992a0a13          	addi	s4,s4,-1646 # 80011950 <pid_lock>
    80001fc6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc8:	00016997          	auipc	s3,0x16
    80001fcc:	fa098993          	addi	s3,s3,-96 # 80017f68 <tickslock>
        found = 1;
    80001fd0:	4b85                	li	s7,1
    80001fd2:	a899                	j	80002028 <scheduler+0xa6>
        p->state = RUNNING;
    80001fd4:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fd8:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fdc:	06048593          	addi	a1,s1,96
    80001fe0:	855a                	mv	a0,s6
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	638080e7          	jalr	1592(ra) # 8000261a <swtch>
        c->proc = 0;
    80001fea:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fee:	8ade                	mv	s5,s7
      release(&p->lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	d36080e7          	jalr	-714(ra) # 80000d28 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ffa:	18848493          	addi	s1,s1,392
    80001ffe:	01348b63          	beq	s1,s3,80002014 <scheduler+0x92>
      acquire(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	c70080e7          	jalr	-912(ra) # 80000c74 <acquire>
      if(p->state == RUNNABLE) {
    8000200c:	4c9c                	lw	a5,24(s1)
    8000200e:	ff2791e3          	bne	a5,s2,80001ff0 <scheduler+0x6e>
    80002012:	b7c9                	j	80001fd4 <scheduler+0x52>
    if(found == 0) {
    80002014:	000a9a63          	bnez	s5,80002028 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002018:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002020:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002024:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002028:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002030:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002034:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002036:	00010497          	auipc	s1,0x10
    8000203a:	d3248493          	addi	s1,s1,-718 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000203e:	4909                	li	s2,2
    80002040:	b7c9                	j	80002002 <scheduler+0x80>

0000000080002042 <sched>:
{
    80002042:	7179                	addi	sp,sp,-48
    80002044:	f406                	sd	ra,40(sp)
    80002046:	f022                	sd	s0,32(sp)
    80002048:	ec26                	sd	s1,24(sp)
    8000204a:	e84a                	sd	s2,16(sp)
    8000204c:	e44e                	sd	s3,8(sp)
    8000204e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	9f2080e7          	jalr	-1550(ra) # 80001a42 <myproc>
    80002058:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	ba0080e7          	jalr	-1120(ra) # 80000bfa <holding>
    80002062:	c93d                	beqz	a0,800020d8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002064:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	00010717          	auipc	a4,0x10
    8000206e:	8e670713          	addi	a4,a4,-1818 # 80011950 <pid_lock>
    80002072:	97ba                	add	a5,a5,a4
    80002074:	0907a703          	lw	a4,144(a5)
    80002078:	4785                	li	a5,1
    8000207a:	06f71763          	bne	a4,a5,800020e8 <sched+0xa6>
  if(p->state == RUNNING)
    8000207e:	4c98                	lw	a4,24(s1)
    80002080:	478d                	li	a5,3
    80002082:	06f70b63          	beq	a4,a5,800020f8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002086:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000208c:	efb5                	bnez	a5,80002108 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002090:	00010917          	auipc	s2,0x10
    80002094:	8c090913          	addi	s2,s2,-1856 # 80011950 <pid_lock>
    80002098:	2781                	sext.w	a5,a5
    8000209a:	079e                	slli	a5,a5,0x7
    8000209c:	97ca                	add	a5,a5,s2
    8000209e:	0947a983          	lw	s3,148(a5)
    800020a2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a4:	2781                	sext.w	a5,a5
    800020a6:	079e                	slli	a5,a5,0x7
    800020a8:	00010597          	auipc	a1,0x10
    800020ac:	8c858593          	addi	a1,a1,-1848 # 80011970 <cpus+0x8>
    800020b0:	95be                	add	a1,a1,a5
    800020b2:	06048513          	addi	a0,s1,96
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	564080e7          	jalr	1380(ra) # 8000261a <swtch>
    800020be:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c0:	2781                	sext.w	a5,a5
    800020c2:	079e                	slli	a5,a5,0x7
    800020c4:	97ca                	add	a5,a5,s2
    800020c6:	0937aa23          	sw	s3,148(a5)
}
    800020ca:	70a2                	ld	ra,40(sp)
    800020cc:	7402                	ld	s0,32(sp)
    800020ce:	64e2                	ld	s1,24(sp)
    800020d0:	6942                	ld	s2,16(sp)
    800020d2:	69a2                	ld	s3,8(sp)
    800020d4:	6145                	addi	sp,sp,48
    800020d6:	8082                	ret
    panic("sched p->lock");
    800020d8:	00006517          	auipc	a0,0x6
    800020dc:	14050513          	addi	a0,a0,320 # 80008218 <digits+0x1c0>
    800020e0:	ffffe097          	auipc	ra,0xffffe
    800020e4:	4f6080e7          	jalr	1270(ra) # 800005d6 <panic>
    panic("sched locks");
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	14050513          	addi	a0,a0,320 # 80008228 <digits+0x1d0>
    800020f0:	ffffe097          	auipc	ra,0xffffe
    800020f4:	4e6080e7          	jalr	1254(ra) # 800005d6 <panic>
    panic("sched running");
    800020f8:	00006517          	auipc	a0,0x6
    800020fc:	14050513          	addi	a0,a0,320 # 80008238 <digits+0x1e0>
    80002100:	ffffe097          	auipc	ra,0xffffe
    80002104:	4d6080e7          	jalr	1238(ra) # 800005d6 <panic>
    panic("sched interruptible");
    80002108:	00006517          	auipc	a0,0x6
    8000210c:	14050513          	addi	a0,a0,320 # 80008248 <digits+0x1f0>
    80002110:	ffffe097          	auipc	ra,0xffffe
    80002114:	4c6080e7          	jalr	1222(ra) # 800005d6 <panic>

0000000080002118 <exit>:
{
    80002118:	7179                	addi	sp,sp,-48
    8000211a:	f406                	sd	ra,40(sp)
    8000211c:	f022                	sd	s0,32(sp)
    8000211e:	ec26                	sd	s1,24(sp)
    80002120:	e84a                	sd	s2,16(sp)
    80002122:	e44e                	sd	s3,8(sp)
    80002124:	e052                	sd	s4,0(sp)
    80002126:	1800                	addi	s0,sp,48
    80002128:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	918080e7          	jalr	-1768(ra) # 80001a42 <myproc>
    80002132:	89aa                	mv	s3,a0
  if(p == initproc)
    80002134:	00007797          	auipc	a5,0x7
    80002138:	ee47b783          	ld	a5,-284(a5) # 80009018 <initproc>
    8000213c:	0d050493          	addi	s1,a0,208
    80002140:	15050913          	addi	s2,a0,336
    80002144:	02a79363          	bne	a5,a0,8000216a <exit+0x52>
    panic("init exiting");
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	11850513          	addi	a0,a0,280 # 80008260 <digits+0x208>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	486080e7          	jalr	1158(ra) # 800005d6 <panic>
      fileclose(f);
    80002158:	00002097          	auipc	ra,0x2
    8000215c:	4a8080e7          	jalr	1192(ra) # 80004600 <fileclose>
      p->ofile[fd] = 0;
    80002160:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002164:	04a1                	addi	s1,s1,8
    80002166:	01248563          	beq	s1,s2,80002170 <exit+0x58>
    if(p->ofile[fd]){
    8000216a:	6088                	ld	a0,0(s1)
    8000216c:	f575                	bnez	a0,80002158 <exit+0x40>
    8000216e:	bfdd                	j	80002164 <exit+0x4c>
  begin_op();
    80002170:	00002097          	auipc	ra,0x2
    80002174:	fbe080e7          	jalr	-66(ra) # 8000412e <begin_op>
  iput(p->cwd);
    80002178:	1509b503          	ld	a0,336(s3)
    8000217c:	00001097          	auipc	ra,0x1
    80002180:	7b0080e7          	jalr	1968(ra) # 8000392c <iput>
  end_op();
    80002184:	00002097          	auipc	ra,0x2
    80002188:	02a080e7          	jalr	42(ra) # 800041ae <end_op>
  p->cwd = 0;
    8000218c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002190:	00007497          	auipc	s1,0x7
    80002194:	e8848493          	addi	s1,s1,-376 # 80009018 <initproc>
    80002198:	6088                	ld	a0,0(s1)
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	ada080e7          	jalr	-1318(ra) # 80000c74 <acquire>
  wakeup1(initproc);
    800021a2:	6088                	ld	a0,0(s1)
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	75e080e7          	jalr	1886(ra) # 80001902 <wakeup1>
  release(&initproc->lock);
    800021ac:	6088                	ld	a0,0(s1)
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	b7a080e7          	jalr	-1158(ra) # 80000d28 <release>
  acquire(&p->lock);
    800021b6:	854e                	mv	a0,s3
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	abc080e7          	jalr	-1348(ra) # 80000c74 <acquire>
  struct proc *original_parent = p->parent;
    800021c0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021c4:	854e                	mv	a0,s3
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	b62080e7          	jalr	-1182(ra) # 80000d28 <release>
  acquire(&original_parent->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	aa4080e7          	jalr	-1372(ra) # 80000c74 <acquire>
  acquire(&p->lock);
    800021d8:	854e                	mv	a0,s3
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	a9a080e7          	jalr	-1382(ra) # 80000c74 <acquire>
  reparent(p);
    800021e2:	854e                	mv	a0,s3
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	d38080e7          	jalr	-712(ra) # 80001f1c <reparent>
  wakeup1(original_parent);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	714080e7          	jalr	1812(ra) # 80001902 <wakeup1>
  p->xstate = status;
    800021f6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021fa:	4791                	li	a5,4
    800021fc:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	b26080e7          	jalr	-1242(ra) # 80000d28 <release>
  sched();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	e38080e7          	jalr	-456(ra) # 80002042 <sched>
  panic("zombie exit");
    80002212:	00006517          	auipc	a0,0x6
    80002216:	05e50513          	addi	a0,a0,94 # 80008270 <digits+0x218>
    8000221a:	ffffe097          	auipc	ra,0xffffe
    8000221e:	3bc080e7          	jalr	956(ra) # 800005d6 <panic>

0000000080002222 <yield>:
{
    80002222:	1101                	addi	sp,sp,-32
    80002224:	ec06                	sd	ra,24(sp)
    80002226:	e822                	sd	s0,16(sp)
    80002228:	e426                	sd	s1,8(sp)
    8000222a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	816080e7          	jalr	-2026(ra) # 80001a42 <myproc>
    80002234:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a3e080e7          	jalr	-1474(ra) # 80000c74 <acquire>
  p->state = RUNNABLE;
    8000223e:	4789                	li	a5,2
    80002240:	cc9c                	sw	a5,24(s1)
  sched();
    80002242:	00000097          	auipc	ra,0x0
    80002246:	e00080e7          	jalr	-512(ra) # 80002042 <sched>
  release(&p->lock);
    8000224a:	8526                	mv	a0,s1
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	adc080e7          	jalr	-1316(ra) # 80000d28 <release>
}
    80002254:	60e2                	ld	ra,24(sp)
    80002256:	6442                	ld	s0,16(sp)
    80002258:	64a2                	ld	s1,8(sp)
    8000225a:	6105                	addi	sp,sp,32
    8000225c:	8082                	ret

000000008000225e <sleep>:
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	89aa                	mv	s3,a0
    8000226e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	7d2080e7          	jalr	2002(ra) # 80001a42 <myproc>
    80002278:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000227a:	05250663          	beq	a0,s2,800022c6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	9f6080e7          	jalr	-1546(ra) # 80000c74 <acquire>
    release(lk);
    80002286:	854a                	mv	a0,s2
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	aa0080e7          	jalr	-1376(ra) # 80000d28 <release>
  p->chan = chan;
    80002290:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002294:	4785                	li	a5,1
    80002296:	cc9c                	sw	a5,24(s1)
  sched();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	daa080e7          	jalr	-598(ra) # 80002042 <sched>
  p->chan = 0;
    800022a0:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	a82080e7          	jalr	-1406(ra) # 80000d28 <release>
    acquire(lk);
    800022ae:	854a                	mv	a0,s2
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9c4080e7          	jalr	-1596(ra) # 80000c74 <acquire>
}
    800022b8:	70a2                	ld	ra,40(sp)
    800022ba:	7402                	ld	s0,32(sp)
    800022bc:	64e2                	ld	s1,24(sp)
    800022be:	6942                	ld	s2,16(sp)
    800022c0:	69a2                	ld	s3,8(sp)
    800022c2:	6145                	addi	sp,sp,48
    800022c4:	8082                	ret
  p->chan = chan;
    800022c6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022ca:	4785                	li	a5,1
    800022cc:	cd1c                	sw	a5,24(a0)
  sched();
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	d74080e7          	jalr	-652(ra) # 80002042 <sched>
  p->chan = 0;
    800022d6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022da:	bff9                	j	800022b8 <sleep+0x5a>

00000000800022dc <wait>:
{
    800022dc:	715d                	addi	sp,sp,-80
    800022de:	e486                	sd	ra,72(sp)
    800022e0:	e0a2                	sd	s0,64(sp)
    800022e2:	fc26                	sd	s1,56(sp)
    800022e4:	f84a                	sd	s2,48(sp)
    800022e6:	f44e                	sd	s3,40(sp)
    800022e8:	f052                	sd	s4,32(sp)
    800022ea:	ec56                	sd	s5,24(sp)
    800022ec:	e85a                	sd	s6,16(sp)
    800022ee:	e45e                	sd	s7,8(sp)
    800022f0:	e062                	sd	s8,0(sp)
    800022f2:	0880                	addi	s0,sp,80
    800022f4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	74c080e7          	jalr	1868(ra) # 80001a42 <myproc>
    800022fe:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002300:	8c2a                	mv	s8,a0
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	972080e7          	jalr	-1678(ra) # 80000c74 <acquire>
    havekids = 0;
    8000230a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000230c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000230e:	00016997          	auipc	s3,0x16
    80002312:	c5a98993          	addi	s3,s3,-934 # 80017f68 <tickslock>
        havekids = 1;
    80002316:	4a85                	li	s5,1
    havekids = 0;
    80002318:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000231a:	00010497          	auipc	s1,0x10
    8000231e:	a4e48493          	addi	s1,s1,-1458 # 80011d68 <proc>
    80002322:	a08d                	j	80002384 <wait+0xa8>
          pid = np->pid;
    80002324:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002328:	000b0e63          	beqz	s6,80002344 <wait+0x68>
    8000232c:	4691                	li	a3,4
    8000232e:	03448613          	addi	a2,s1,52
    80002332:	85da                	mv	a1,s6
    80002334:	05093503          	ld	a0,80(s2)
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	3fe080e7          	jalr	1022(ra) # 80001736 <copyout>
    80002340:	02054263          	bltz	a0,80002364 <wait+0x88>
          freeproc(np);
    80002344:	8526                	mv	a0,s1
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	8ae080e7          	jalr	-1874(ra) # 80001bf4 <freeproc>
          release(&np->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	9d8080e7          	jalr	-1576(ra) # 80000d28 <release>
          release(&p->lock);
    80002358:	854a                	mv	a0,s2
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	9ce080e7          	jalr	-1586(ra) # 80000d28 <release>
          return pid;
    80002362:	a8a9                	j	800023bc <wait+0xe0>
            release(&np->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	9c2080e7          	jalr	-1598(ra) # 80000d28 <release>
            release(&p->lock);
    8000236e:	854a                	mv	a0,s2
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	9b8080e7          	jalr	-1608(ra) # 80000d28 <release>
            return -1;
    80002378:	59fd                	li	s3,-1
    8000237a:	a089                	j	800023bc <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000237c:	18848493          	addi	s1,s1,392
    80002380:	03348463          	beq	s1,s3,800023a8 <wait+0xcc>
      if(np->parent == p){
    80002384:	709c                	ld	a5,32(s1)
    80002386:	ff279be3          	bne	a5,s2,8000237c <wait+0xa0>
        acquire(&np->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8e8080e7          	jalr	-1816(ra) # 80000c74 <acquire>
        if(np->state == ZOMBIE){
    80002394:	4c9c                	lw	a5,24(s1)
    80002396:	f94787e3          	beq	a5,s4,80002324 <wait+0x48>
        release(&np->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	98c080e7          	jalr	-1652(ra) # 80000d28 <release>
        havekids = 1;
    800023a4:	8756                	mv	a4,s5
    800023a6:	bfd9                	j	8000237c <wait+0xa0>
    if(!havekids || p->killed){
    800023a8:	c701                	beqz	a4,800023b0 <wait+0xd4>
    800023aa:	03092783          	lw	a5,48(s2)
    800023ae:	c785                	beqz	a5,800023d6 <wait+0xfa>
      release(&p->lock);
    800023b0:	854a                	mv	a0,s2
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	976080e7          	jalr	-1674(ra) # 80000d28 <release>
      return -1;
    800023ba:	59fd                	li	s3,-1
}
    800023bc:	854e                	mv	a0,s3
    800023be:	60a6                	ld	ra,72(sp)
    800023c0:	6406                	ld	s0,64(sp)
    800023c2:	74e2                	ld	s1,56(sp)
    800023c4:	7942                	ld	s2,48(sp)
    800023c6:	79a2                	ld	s3,40(sp)
    800023c8:	7a02                	ld	s4,32(sp)
    800023ca:	6ae2                	ld	s5,24(sp)
    800023cc:	6b42                	ld	s6,16(sp)
    800023ce:	6ba2                	ld	s7,8(sp)
    800023d0:	6c02                	ld	s8,0(sp)
    800023d2:	6161                	addi	sp,sp,80
    800023d4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023d6:	85e2                	mv	a1,s8
    800023d8:	854a                	mv	a0,s2
    800023da:	00000097          	auipc	ra,0x0
    800023de:	e84080e7          	jalr	-380(ra) # 8000225e <sleep>
    havekids = 0;
    800023e2:	bf1d                	j	80002318 <wait+0x3c>

00000000800023e4 <wakeup>:
{
    800023e4:	7139                	addi	sp,sp,-64
    800023e6:	fc06                	sd	ra,56(sp)
    800023e8:	f822                	sd	s0,48(sp)
    800023ea:	f426                	sd	s1,40(sp)
    800023ec:	f04a                	sd	s2,32(sp)
    800023ee:	ec4e                	sd	s3,24(sp)
    800023f0:	e852                	sd	s4,16(sp)
    800023f2:	e456                	sd	s5,8(sp)
    800023f4:	0080                	addi	s0,sp,64
    800023f6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f8:	00010497          	auipc	s1,0x10
    800023fc:	97048493          	addi	s1,s1,-1680 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002400:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002402:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002404:	00016917          	auipc	s2,0x16
    80002408:	b6490913          	addi	s2,s2,-1180 # 80017f68 <tickslock>
    8000240c:	a821                	j	80002424 <wakeup+0x40>
      p->state = RUNNABLE;
    8000240e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	914080e7          	jalr	-1772(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241c:	18848493          	addi	s1,s1,392
    80002420:	01248e63          	beq	s1,s2,8000243c <wakeup+0x58>
    acquire(&p->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	84e080e7          	jalr	-1970(ra) # 80000c74 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000242e:	4c9c                	lw	a5,24(s1)
    80002430:	ff3791e3          	bne	a5,s3,80002412 <wakeup+0x2e>
    80002434:	749c                	ld	a5,40(s1)
    80002436:	fd479ee3          	bne	a5,s4,80002412 <wakeup+0x2e>
    8000243a:	bfd1                	j	8000240e <wakeup+0x2a>
}
    8000243c:	70e2                	ld	ra,56(sp)
    8000243e:	7442                	ld	s0,48(sp)
    80002440:	74a2                	ld	s1,40(sp)
    80002442:	7902                	ld	s2,32(sp)
    80002444:	69e2                	ld	s3,24(sp)
    80002446:	6a42                	ld	s4,16(sp)
    80002448:	6aa2                	ld	s5,8(sp)
    8000244a:	6121                	addi	sp,sp,64
    8000244c:	8082                	ret

000000008000244e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000244e:	7179                	addi	sp,sp,-48
    80002450:	f406                	sd	ra,40(sp)
    80002452:	f022                	sd	s0,32(sp)
    80002454:	ec26                	sd	s1,24(sp)
    80002456:	e84a                	sd	s2,16(sp)
    80002458:	e44e                	sd	s3,8(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000245e:	00010497          	auipc	s1,0x10
    80002462:	90a48493          	addi	s1,s1,-1782 # 80011d68 <proc>
    80002466:	00016997          	auipc	s3,0x16
    8000246a:	b0298993          	addi	s3,s3,-1278 # 80017f68 <tickslock>
    acquire(&p->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	804080e7          	jalr	-2044(ra) # 80000c74 <acquire>
    if(p->pid == pid){
    80002478:	5c9c                	lw	a5,56(s1)
    8000247a:	01278d63          	beq	a5,s2,80002494 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	8a8080e7          	jalr	-1880(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002488:	18848493          	addi	s1,s1,392
    8000248c:	ff3491e3          	bne	s1,s3,8000246e <kill+0x20>
  }
  return -1;
    80002490:	557d                	li	a0,-1
    80002492:	a829                	j	800024ac <kill+0x5e>
      p->killed = 1;
    80002494:	4785                	li	a5,1
    80002496:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002498:	4c98                	lw	a4,24(s1)
    8000249a:	4785                	li	a5,1
    8000249c:	00f70f63          	beq	a4,a5,800024ba <kill+0x6c>
      release(&p->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	886080e7          	jalr	-1914(ra) # 80000d28 <release>
      return 0;
    800024aa:	4501                	li	a0,0
}
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6145                	addi	sp,sp,48
    800024b8:	8082                	ret
        p->state = RUNNABLE;
    800024ba:	4789                	li	a5,2
    800024bc:	cc9c                	sw	a5,24(s1)
    800024be:	b7cd                	j	800024a0 <kill+0x52>

00000000800024c0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	84aa                	mv	s1,a0
    800024d2:	892e                	mv	s2,a1
    800024d4:	89b2                	mv	s3,a2
    800024d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	56a080e7          	jalr	1386(ra) # 80001a42 <myproc>
  if(user_dst){
    800024e0:	c08d                	beqz	s1,80002502 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e2:	86d2                	mv	a3,s4
    800024e4:	864e                	mv	a2,s3
    800024e6:	85ca                	mv	a1,s2
    800024e8:	6928                	ld	a0,80(a0)
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	24c080e7          	jalr	588(ra) # 80001736 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f2:	70a2                	ld	ra,40(sp)
    800024f4:	7402                	ld	s0,32(sp)
    800024f6:	64e2                	ld	s1,24(sp)
    800024f8:	6942                	ld	s2,16(sp)
    800024fa:	69a2                	ld	s3,8(sp)
    800024fc:	6a02                	ld	s4,0(sp)
    800024fe:	6145                	addi	sp,sp,48
    80002500:	8082                	ret
    memmove((char *)dst, src, len);
    80002502:	000a061b          	sext.w	a2,s4
    80002506:	85ce                	mv	a1,s3
    80002508:	854a                	mv	a0,s2
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	8c6080e7          	jalr	-1850(ra) # 80000dd0 <memmove>
    return 0;
    80002512:	8526                	mv	a0,s1
    80002514:	bff9                	j	800024f2 <either_copyout+0x32>

0000000080002516 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002516:	7179                	addi	sp,sp,-48
    80002518:	f406                	sd	ra,40(sp)
    8000251a:	f022                	sd	s0,32(sp)
    8000251c:	ec26                	sd	s1,24(sp)
    8000251e:	e84a                	sd	s2,16(sp)
    80002520:	e44e                	sd	s3,8(sp)
    80002522:	e052                	sd	s4,0(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	892a                	mv	s2,a0
    80002528:	84ae                	mv	s1,a1
    8000252a:	89b2                	mv	s3,a2
    8000252c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	514080e7          	jalr	1300(ra) # 80001a42 <myproc>
  if(user_src){
    80002536:	c08d                	beqz	s1,80002558 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002538:	86d2                	mv	a3,s4
    8000253a:	864e                	mv	a2,s3
    8000253c:	85ca                	mv	a1,s2
    8000253e:	6928                	ld	a0,80(a0)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	282080e7          	jalr	642(ra) # 800017c2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6a02                	ld	s4,0(sp)
    80002554:	6145                	addi	sp,sp,48
    80002556:	8082                	ret
    memmove(dst, (char*)src, len);
    80002558:	000a061b          	sext.w	a2,s4
    8000255c:	85ce                	mv	a1,s3
    8000255e:	854a                	mv	a0,s2
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	870080e7          	jalr	-1936(ra) # 80000dd0 <memmove>
    return 0;
    80002568:	8526                	mv	a0,s1
    8000256a:	bff9                	j	80002548 <either_copyin+0x32>

000000008000256c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256c:	715d                	addi	sp,sp,-80
    8000256e:	e486                	sd	ra,72(sp)
    80002570:	e0a2                	sd	s0,64(sp)
    80002572:	fc26                	sd	s1,56(sp)
    80002574:	f84a                	sd	s2,48(sp)
    80002576:	f44e                	sd	s3,40(sp)
    80002578:	f052                	sd	s4,32(sp)
    8000257a:	ec56                	sd	s5,24(sp)
    8000257c:	e85a                	sd	s6,16(sp)
    8000257e:	e45e                	sd	s7,8(sp)
    80002580:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	b5e50513          	addi	a0,a0,-1186 # 800080e0 <digits+0x88>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	09e080e7          	jalr	158(ra) # 80000628 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002592:	00010497          	auipc	s1,0x10
    80002596:	92e48493          	addi	s1,s1,-1746 # 80011ec0 <proc+0x158>
    8000259a:	00016917          	auipc	s2,0x16
    8000259e:	b2690913          	addi	s2,s2,-1242 # 800180c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025a4:	00006997          	auipc	s3,0x6
    800025a8:	cdc98993          	addi	s3,s3,-804 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025ac:	00006a97          	auipc	s5,0x6
    800025b0:	cdca8a93          	addi	s5,s5,-804 # 80008288 <digits+0x230>
    printf("\n");
    800025b4:	00006a17          	auipc	s4,0x6
    800025b8:	b2ca0a13          	addi	s4,s4,-1236 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	00006b97          	auipc	s7,0x6
    800025c0:	d04b8b93          	addi	s7,s7,-764 # 800082c0 <states.1711>
    800025c4:	a00d                	j	800025e6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c6:	ee06a583          	lw	a1,-288(a3)
    800025ca:	8556                	mv	a0,s5
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	05c080e7          	jalr	92(ra) # 80000628 <printf>
    printf("\n");
    800025d4:	8552                	mv	a0,s4
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	052080e7          	jalr	82(ra) # 80000628 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	18848493          	addi	s1,s1,392
    800025e2:	03248163          	beq	s1,s2,80002604 <procdump+0x98>
    if(p->state == UNUSED)
    800025e6:	86a6                	mv	a3,s1
    800025e8:	ec04a783          	lw	a5,-320(s1)
    800025ec:	dbed                	beqz	a5,800025de <procdump+0x72>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	fcfb6be3          	bltu	s6,a5,800025c6 <procdump+0x5a>
    800025f4:	1782                	slli	a5,a5,0x20
    800025f6:	9381                	srli	a5,a5,0x20
    800025f8:	078e                	slli	a5,a5,0x3
    800025fa:	97de                	add	a5,a5,s7
    800025fc:	6390                	ld	a2,0(a5)
    800025fe:	f661                	bnez	a2,800025c6 <procdump+0x5a>
      state = "???";
    80002600:	864e                	mv	a2,s3
    80002602:	b7d1                	j	800025c6 <procdump+0x5a>
  }
}
    80002604:	60a6                	ld	ra,72(sp)
    80002606:	6406                	ld	s0,64(sp)
    80002608:	74e2                	ld	s1,56(sp)
    8000260a:	7942                	ld	s2,48(sp)
    8000260c:	79a2                	ld	s3,40(sp)
    8000260e:	7a02                	ld	s4,32(sp)
    80002610:	6ae2                	ld	s5,24(sp)
    80002612:	6b42                	ld	s6,16(sp)
    80002614:	6ba2                	ld	s7,8(sp)
    80002616:	6161                	addi	sp,sp,80
    80002618:	8082                	ret

000000008000261a <swtch>:
    8000261a:	00153023          	sd	ra,0(a0)
    8000261e:	00253423          	sd	sp,8(a0)
    80002622:	e900                	sd	s0,16(a0)
    80002624:	ed04                	sd	s1,24(a0)
    80002626:	03253023          	sd	s2,32(a0)
    8000262a:	03353423          	sd	s3,40(a0)
    8000262e:	03453823          	sd	s4,48(a0)
    80002632:	03553c23          	sd	s5,56(a0)
    80002636:	05653023          	sd	s6,64(a0)
    8000263a:	05753423          	sd	s7,72(a0)
    8000263e:	05853823          	sd	s8,80(a0)
    80002642:	05953c23          	sd	s9,88(a0)
    80002646:	07a53023          	sd	s10,96(a0)
    8000264a:	07b53423          	sd	s11,104(a0)
    8000264e:	0005b083          	ld	ra,0(a1)
    80002652:	0085b103          	ld	sp,8(a1)
    80002656:	6980                	ld	s0,16(a1)
    80002658:	6d84                	ld	s1,24(a1)
    8000265a:	0205b903          	ld	s2,32(a1)
    8000265e:	0285b983          	ld	s3,40(a1)
    80002662:	0305ba03          	ld	s4,48(a1)
    80002666:	0385ba83          	ld	s5,56(a1)
    8000266a:	0405bb03          	ld	s6,64(a1)
    8000266e:	0485bb83          	ld	s7,72(a1)
    80002672:	0505bc03          	ld	s8,80(a1)
    80002676:	0585bc83          	ld	s9,88(a1)
    8000267a:	0605bd03          	ld	s10,96(a1)
    8000267e:	0685bd83          	ld	s11,104(a1)
    80002682:	8082                	ret

0000000080002684 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e406                	sd	ra,8(sp)
    80002688:	e022                	sd	s0,0(sp)
    8000268a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000268c:	00006597          	auipc	a1,0x6
    80002690:	c5c58593          	addi	a1,a1,-932 # 800082e8 <states.1711+0x28>
    80002694:	00016517          	auipc	a0,0x16
    80002698:	8d450513          	addi	a0,a0,-1836 # 80017f68 <tickslock>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	548080e7          	jalr	1352(ra) # 80000be4 <initlock>
}
    800026a4:	60a2                	ld	ra,8(sp)
    800026a6:	6402                	ld	s0,0(sp)
    800026a8:	0141                	addi	sp,sp,16
    800026aa:	8082                	ret

00000000800026ac <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ac:	1141                	addi	sp,sp,-16
    800026ae:	e422                	sd	s0,8(sp)
    800026b0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b2:	00003797          	auipc	a5,0x3
    800026b6:	5be78793          	addi	a5,a5,1470 # 80005c70 <kernelvec>
    800026ba:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026be:	6422                	ld	s0,8(sp)
    800026c0:	0141                	addi	sp,sp,16
    800026c2:	8082                	ret

00000000800026c4 <usertrapret>:
// return to user space
// 设置RISC-V控制寄存器，为以后用户空间trap做准备
//
void
usertrapret(void)
{
    800026c4:	1141                	addi	sp,sp,-16
    800026c6:	e406                	sd	ra,8(sp)
    800026c8:	e022                	sd	s0,0(sp)
    800026ca:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	376080e7          	jalr	886(ra) # 80001a42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026d8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026da:	10079073          	csrw	sstatus,a5
  // 先关闭中断，因为要恢复现场，不能被破坏。
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  // 修改stvec为trampoline代码，里面的最后代码会执行sret指令重新打开中断，回到用户空间。
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026de:	00005617          	auipc	a2,0x5
    800026e2:	92260613          	addi	a2,a2,-1758 # 80007000 <_trampoline>
    800026e6:	00005697          	auipc	a3,0x5
    800026ea:	91a68693          	addi	a3,a3,-1766 # 80007000 <_trampoline>
    800026ee:	8e91                	sub	a3,a3,a2
    800026f0:	040007b7          	lui	a5,0x4000
    800026f4:	17fd                	addi	a5,a5,-1
    800026f6:	07b2                	slli	a5,a5,0xc
    800026f8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fa:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  // 准备uservec所依赖的trapframe字段
  // 恢复现场
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026fe:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002700:	180026f3          	csrr	a3,satp
    80002704:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002706:	6d38                	ld	a4,88(a0)
    80002708:	6134                	ld	a3,64(a0)
    8000270a:	6585                	lui	a1,0x1
    8000270c:	96ae                	add	a3,a3,a1
    8000270e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap; // 存储usertrap的指针，下次还能跳转到这个函数处理
    80002710:	6d38                	ld	a4,88(a0)
    80002712:	00000697          	auipc	a3,0x0
    80002716:	13868693          	addi	a3,a3,312 # 8000284a <usertrap>
    8000271a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000271c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000271e:	8692                	mv	a3,tp
    80002720:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002722:	100026f3          	csrr	a3,sstatus
   * 接下来我们要设置SSTATUS寄存器，这是一个控制寄存器。这个寄存器的SPP bit位控制了sret指令的行为，
   * 该bit为0表示下次执行sret的时候，我们想要返回user mode而不是supervisor mode。这个寄存器的SPIE bit位控制了，
   * 在执行完sret之后，是否打开中断。因为我们在返回到用户空间之后，我们的确希望打开中断，所以这里将SPIE bit位设置为1。
   * 修改完这些bit位之后，我们会把新的值写回到SSTATUS寄存器。
   * */
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002726:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000272a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  // 将sepc设置为先前在usertrap()保存的用户程序计数器
  w_sepc(p->trapframe->epc);
    80002732:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002734:	6f18                	ld	a4,24(a4)
    80002736:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  // satp寄存器切换回用户页表
  uint64 satp = MAKE_SATP(p->pagetable);
    8000273a:	692c                	ld	a1,80(a0)
    8000273c:	81b1                	srli	a1,a1,0xc
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  // 在用户页表和内核页表中映射的trampoline页上调用userret,因为userret中的汇编代码会切换页表。
  // 用户页表和内核页表的同一个虚拟地址上映射着同一个trampoline
  // fn就是对应trampoline.S的返回代码段
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000273e:	00005717          	auipc	a4,0x5
    80002742:	95270713          	addi	a4,a4,-1710 # 80007090 <userret>
    80002746:	8f11                	sub	a4,a4,a2
    80002748:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000274a:	577d                	li	a4,-1
    8000274c:	177e                	slli	a4,a4,0x3f
    8000274e:	8dd9                	or	a1,a1,a4
    80002750:	02000537          	lui	a0,0x2000
    80002754:	157d                	addi	a0,a0,-1
    80002756:	0536                	slli	a0,a0,0xd
    80002758:	9782                	jalr	a5
}
    8000275a:	60a2                	ld	ra,8(sp)
    8000275c:	6402                	ld	s0,0(sp)
    8000275e:	0141                	addi	sp,sp,16
    80002760:	8082                	ret

0000000080002762 <clockintr>:
  // 之后返回到kernelvec（kernel/kernelvec.S:48）,恢复现场栈堆
}

void
clockintr()
{
    80002762:	1101                	addi	sp,sp,-32
    80002764:	ec06                	sd	ra,24(sp)
    80002766:	e822                	sd	s0,16(sp)
    80002768:	e426                	sd	s1,8(sp)
    8000276a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000276c:	00015497          	auipc	s1,0x15
    80002770:	7fc48493          	addi	s1,s1,2044 # 80017f68 <tickslock>
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	4fe080e7          	jalr	1278(ra) # 80000c74 <acquire>
  ticks++;
    8000277e:	00007517          	auipc	a0,0x7
    80002782:	8a250513          	addi	a0,a0,-1886 # 80009020 <ticks>
    80002786:	411c                	lw	a5,0(a0)
    80002788:	2785                	addiw	a5,a5,1
    8000278a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000278c:	00000097          	auipc	ra,0x0
    80002790:	c58080e7          	jalr	-936(ra) # 800023e4 <wakeup>
  release(&tickslock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	592080e7          	jalr	1426(ra) # 80000d28 <release>
}
    8000279e:	60e2                	ld	ra,24(sp)
    800027a0:	6442                	ld	s0,16(sp)
    800027a2:	64a2                	ld	s1,8(sp)
    800027a4:	6105                	addi	sp,sp,32
    800027a6:	8082                	ret

00000000800027a8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027a8:	1101                	addi	sp,sp,-32
    800027aa:	ec06                	sd	ra,24(sp)
    800027ac:	e822                	sd	s0,16(sp)
    800027ae:	e426                	sd	s1,8(sp)
    800027b0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027b6:	00074d63          	bltz	a4,800027d0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ba:	57fd                	li	a5,-1
    800027bc:	17fe                	slli	a5,a5,0x3f
    800027be:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027c0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027c2:	06f70363          	beq	a4,a5,80002828 <devintr+0x80>
  }
}
    800027c6:	60e2                	ld	ra,24(sp)
    800027c8:	6442                	ld	s0,16(sp)
    800027ca:	64a2                	ld	s1,8(sp)
    800027cc:	6105                	addi	sp,sp,32
    800027ce:	8082                	ret
     (scause & 0xff) == 9){
    800027d0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027d4:	46a5                	li	a3,9
    800027d6:	fed792e3          	bne	a5,a3,800027ba <devintr+0x12>
    int irq = plic_claim();
    800027da:	00003097          	auipc	ra,0x3
    800027de:	59e080e7          	jalr	1438(ra) # 80005d78 <plic_claim>
    800027e2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e4:	47a9                	li	a5,10
    800027e6:	02f50763          	beq	a0,a5,80002814 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ea:	4785                	li	a5,1
    800027ec:	02f50963          	beq	a0,a5,8000281e <devintr+0x76>
    return 1;
    800027f0:	4505                	li	a0,1
    } else if(irq){
    800027f2:	d8f1                	beqz	s1,800027c6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f4:	85a6                	mv	a1,s1
    800027f6:	00006517          	auipc	a0,0x6
    800027fa:	afa50513          	addi	a0,a0,-1286 # 800082f0 <states.1711+0x30>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	e2a080e7          	jalr	-470(ra) # 80000628 <printf>
      plic_complete(irq);
    80002806:	8526                	mv	a0,s1
    80002808:	00003097          	auipc	ra,0x3
    8000280c:	594080e7          	jalr	1428(ra) # 80005d9c <plic_complete>
    return 1;
    80002810:	4505                	li	a0,1
    80002812:	bf55                	j	800027c6 <devintr+0x1e>
      uartintr();
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	224080e7          	jalr	548(ra) # 80000a38 <uartintr>
    8000281c:	b7ed                	j	80002806 <devintr+0x5e>
      virtio_disk_intr();
    8000281e:	00004097          	auipc	ra,0x4
    80002822:	a18080e7          	jalr	-1512(ra) # 80006236 <virtio_disk_intr>
    80002826:	b7c5                	j	80002806 <devintr+0x5e>
    if(cpuid() == 0){
    80002828:	fffff097          	auipc	ra,0xfffff
    8000282c:	1ee080e7          	jalr	494(ra) # 80001a16 <cpuid>
    80002830:	c901                	beqz	a0,80002840 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002832:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002836:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002838:	14479073          	csrw	sip,a5
    return 2;
    8000283c:	4509                	li	a0,2
    8000283e:	b761                	j	800027c6 <devintr+0x1e>
      clockintr();
    80002840:	00000097          	auipc	ra,0x0
    80002844:	f22080e7          	jalr	-222(ra) # 80002762 <clockintr>
    80002848:	b7ed                	j	80002832 <devintr+0x8a>

000000008000284a <usertrap>:
{
    8000284a:	1101                	addi	sp,sp,-32
    8000284c:	ec06                	sd	ra,24(sp)
    8000284e:	e822                	sd	s0,16(sp)
    80002850:	e426                	sd	s1,8(sp)
    80002852:	e04a                	sd	s2,0(sp)
    80002854:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002856:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000285a:	1007f793          	andi	a5,a5,256
    8000285e:	e3ad                	bnez	a5,800028c0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002860:	00003797          	auipc	a5,0x3
    80002864:	41078793          	addi	a5,a5,1040 # 80005c70 <kernelvec>
    80002868:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	1d6080e7          	jalr	470(ra) # 80001a42 <myproc>
    80002874:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002876:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002878:	14102773          	csrr	a4,sepc
    8000287c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002882:	47a1                	li	a5,8
    80002884:	04f71c63          	bne	a4,a5,800028dc <usertrap+0x92>
    if(p->killed)
    80002888:	591c                	lw	a5,48(a0)
    8000288a:	e3b9                	bnez	a5,800028d0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000288c:	6cb8                	ld	a4,88(s1)
    8000288e:	6f1c                	ld	a5,24(a4)
    80002890:	0791                	addi	a5,a5,4
    80002892:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002894:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002898:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289c:	10079073          	csrw	sstatus,a5
    syscall();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	31e080e7          	jalr	798(ra) # 80002bbe <syscall>
  if(p->killed)
    800028a8:	589c                	lw	a5,48(s1)
    800028aa:	e7c5                	bnez	a5,80002952 <usertrap+0x108>
  usertrapret();
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	e18080e7          	jalr	-488(ra) # 800026c4 <usertrapret>
}
    800028b4:	60e2                	ld	ra,24(sp)
    800028b6:	6442                	ld	s0,16(sp)
    800028b8:	64a2                	ld	s1,8(sp)
    800028ba:	6902                	ld	s2,0(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret
    panic("usertrap: not from user mode");
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a5050513          	addi	a0,a0,-1456 # 80008310 <states.1711+0x50>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	d0e080e7          	jalr	-754(ra) # 800005d6 <panic>
      exit(-1);
    800028d0:	557d                	li	a0,-1
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	846080e7          	jalr	-1978(ra) # 80002118 <exit>
    800028da:	bf4d                	j	8000288c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){ // 如果是设备中断，devintr进行处理
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	ecc080e7          	jalr	-308(ra) # 800027a8 <devintr>
    800028e4:	892a                	mv	s2,a0
    800028e6:	c501                	beqz	a0,800028ee <usertrap+0xa4>
  if(p->killed)
    800028e8:	589c                	lw	a5,48(s1)
    800028ea:	c3a1                	beqz	a5,8000292a <usertrap+0xe0>
    800028ec:	a815                	j	80002920 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ee:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028f2:	5c90                	lw	a2,56(s1)
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a3c50513          	addi	a0,a0,-1476 # 80008330 <states.1711+0x70>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	d2c080e7          	jalr	-724(ra) # 80000628 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002904:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002908:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	a5450513          	addi	a0,a0,-1452 # 80008360 <states.1711+0xa0>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	d14080e7          	jalr	-748(ra) # 80000628 <printf>
    p->killed = 1;
    8000291c:	4785                	li	a5,1
    8000291e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002920:	557d                	li	a0,-1
    80002922:	fffff097          	auipc	ra,0xfffff
    80002926:	7f6080e7          	jalr	2038(ra) # 80002118 <exit>
    if(which_dev == 2)
    8000292a:	4789                	li	a5,2
    8000292c:	f8f910e3          	bne	s2,a5,800028ac <usertrap+0x62>
        ++p->passedticks;
    80002930:	1784a783          	lw	a5,376(s1)
    80002934:	2785                	addiw	a5,a5,1
    80002936:	0007871b          	sext.w	a4,a5
    8000293a:	16f4ac23          	sw	a5,376(s1)
        if(p->interval != 0 && p->passedticks == p->interval)
    8000293e:	1684a783          	lw	a5,360(s1)
    80002942:	c399                	beqz	a5,80002948 <usertrap+0xfe>
    80002944:	00f70963          	beq	a4,a5,80002956 <usertrap+0x10c>
    yield();
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	8da080e7          	jalr	-1830(ra) # 80002222 <yield>
    80002950:	bfb1                	j	800028ac <usertrap+0x62>
  int which_dev = 0;
    80002952:	4901                	li	s2,0
    80002954:	b7f1                	j	80002920 <usertrap+0xd6>
            p->trapframecopy = p->trapframe + 512;
    80002956:	6cac                	ld	a1,88(s1)
    80002958:	00024537          	lui	a0,0x24
    8000295c:	952e                	add	a0,a0,a1
    8000295e:	18a4b023          	sd	a0,384(s1)
            memmove(p->trapframecopy, p->trapframe, sizeof(struct trapframe));
    80002962:	12000613          	li	a2,288
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	46a080e7          	jalr	1130(ra) # 80000dd0 <memmove>
            p->passedticks = 0;
    8000296e:	1604ac23          	sw	zero,376(s1)
            p->trapframe->epc = p->handler; // 存到用户空间的PC
    80002972:	6cbc                	ld	a5,88(s1)
    80002974:	1704b703          	ld	a4,368(s1)
    80002978:	ef98                	sd	a4,24(a5)
    8000297a:	b7f9                	j	80002948 <usertrap+0xfe>

000000008000297c <kerneltrap>:
{
    8000297c:	7179                	addi	sp,sp,-48
    8000297e:	f406                	sd	ra,40(sp)
    80002980:	f022                	sd	s0,32(sp)
    80002982:	ec26                	sd	s1,24(sp)
    80002984:	e84a                	sd	s2,16(sp)
    80002986:	e44e                	sd	s3,8(sp)
    80002988:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000298e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002992:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002996:	1004f793          	andi	a5,s1,256
    8000299a:	cb85                	beqz	a5,800029ca <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029a0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029a2:	ef85                	bnez	a5,800029da <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	e04080e7          	jalr	-508(ra) # 800027a8 <devintr>
    800029ac:	cd1d                	beqz	a0,800029ea <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ae:	4789                	li	a5,2
    800029b0:	06f50a63          	beq	a0,a5,80002a24 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10049073          	csrw	sstatus,s1
}
    800029bc:	70a2                	ld	ra,40(sp)
    800029be:	7402                	ld	s0,32(sp)
    800029c0:	64e2                	ld	s1,24(sp)
    800029c2:	6942                	ld	s2,16(sp)
    800029c4:	69a2                	ld	s3,8(sp)
    800029c6:	6145                	addi	sp,sp,48
    800029c8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9b650513          	addi	a0,a0,-1610 # 80008380 <states.1711+0xc0>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	c04080e7          	jalr	-1020(ra) # 800005d6 <panic>
    panic("kerneltrap: interrupts enabled");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	9ce50513          	addi	a0,a0,-1586 # 800083a8 <states.1711+0xe8>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	bf4080e7          	jalr	-1036(ra) # 800005d6 <panic>
    printf("scause %p\n", scause);
    800029ea:	85ce                	mv	a1,s3
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9dc50513          	addi	a0,a0,-1572 # 800083c8 <states.1711+0x108>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	c34080e7          	jalr	-972(ra) # 80000628 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a00:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	9d450513          	addi	a0,a0,-1580 # 800083d8 <states.1711+0x118>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	c1c080e7          	jalr	-996(ra) # 80000628 <printf>
    panic("kerneltrap");
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	9dc50513          	addi	a0,a0,-1572 # 800083f0 <states.1711+0x130>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	bba080e7          	jalr	-1094(ra) # 800005d6 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	01e080e7          	jalr	30(ra) # 80001a42 <myproc>
    80002a2c:	d541                	beqz	a0,800029b4 <kerneltrap+0x38>
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	014080e7          	jalr	20(ra) # 80001a42 <myproc>
    80002a36:	4d18                	lw	a4,24(a0)
    80002a38:	478d                	li	a5,3
    80002a3a:	f6f71de3          	bne	a4,a5,800029b4 <kerneltrap+0x38>
    yield();
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	7e4080e7          	jalr	2020(ra) # 80002222 <yield>
    80002a46:	b7bd                	j	800029b4 <kerneltrap+0x38>

0000000080002a48 <argraw>:

// 在寄存器中拿出参数
// called argint()、argaddr()、argfd()
static uint64
argraw(int n)
{
    80002a48:	1101                	addi	sp,sp,-32
    80002a4a:	ec06                	sd	ra,24(sp)
    80002a4c:	e822                	sd	s0,16(sp)
    80002a4e:	e426                	sd	s1,8(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	fee080e7          	jalr	-18(ra) # 80001a42 <myproc>
  switch (n) {
    80002a5c:	4795                	li	a5,5
    80002a5e:	0497e163          	bltu	a5,s1,80002aa0 <argraw+0x58>
    80002a62:	048a                	slli	s1,s1,0x2
    80002a64:	00006717          	auipc	a4,0x6
    80002a68:	9c470713          	addi	a4,a4,-1596 # 80008428 <states.1711+0x168>
    80002a6c:	94ba                	add	s1,s1,a4
    80002a6e:	409c                	lw	a5,0(s1)
    80002a70:	97ba                	add	a5,a5,a4
    80002a72:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a74:	6d3c                	ld	a5,88(a0)
    80002a76:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a78:	60e2                	ld	ra,24(sp)
    80002a7a:	6442                	ld	s0,16(sp)
    80002a7c:	64a2                	ld	s1,8(sp)
    80002a7e:	6105                	addi	sp,sp,32
    80002a80:	8082                	ret
    return p->trapframe->a1;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	7fa8                	ld	a0,120(a5)
    80002a86:	bfcd                	j	80002a78 <argraw+0x30>
    return p->trapframe->a2;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	63c8                	ld	a0,128(a5)
    80002a8c:	b7f5                	j	80002a78 <argraw+0x30>
    return p->trapframe->a3;
    80002a8e:	6d3c                	ld	a5,88(a0)
    80002a90:	67c8                	ld	a0,136(a5)
    80002a92:	b7dd                	j	80002a78 <argraw+0x30>
    return p->trapframe->a4;
    80002a94:	6d3c                	ld	a5,88(a0)
    80002a96:	6bc8                	ld	a0,144(a5)
    80002a98:	b7c5                	j	80002a78 <argraw+0x30>
    return p->trapframe->a5;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	6fc8                	ld	a0,152(a5)
    80002a9e:	bfe9                	j	80002a78 <argraw+0x30>
  panic("argraw");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	96050513          	addi	a0,a0,-1696 # 80008400 <states.1711+0x140>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	b2e080e7          	jalr	-1234(ra) # 800005d6 <panic>

0000000080002ab0 <fetchaddr>:
{
    80002ab0:	1101                	addi	sp,sp,-32
    80002ab2:	ec06                	sd	ra,24(sp)
    80002ab4:	e822                	sd	s0,16(sp)
    80002ab6:	e426                	sd	s1,8(sp)
    80002ab8:	e04a                	sd	s2,0(sp)
    80002aba:	1000                	addi	s0,sp,32
    80002abc:	84aa                	mv	s1,a0
    80002abe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	f82080e7          	jalr	-126(ra) # 80001a42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ac8:	653c                	ld	a5,72(a0)
    80002aca:	02f4f863          	bgeu	s1,a5,80002afa <fetchaddr+0x4a>
    80002ace:	00848713          	addi	a4,s1,8
    80002ad2:	02e7e663          	bltu	a5,a4,80002afe <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ad6:	46a1                	li	a3,8
    80002ad8:	8626                	mv	a2,s1
    80002ada:	85ca                	mv	a1,s2
    80002adc:	6928                	ld	a0,80(a0)
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	ce4080e7          	jalr	-796(ra) # 800017c2 <copyin>
    80002ae6:	00a03533          	snez	a0,a0
    80002aea:	40a00533          	neg	a0,a0
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6902                	ld	s2,0(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret
    return -1;
    80002afa:	557d                	li	a0,-1
    80002afc:	bfcd                	j	80002aee <fetchaddr+0x3e>
    80002afe:	557d                	li	a0,-1
    80002b00:	b7fd                	j	80002aee <fetchaddr+0x3e>

0000000080002b02 <fetchstr>:
{
    80002b02:	7179                	addi	sp,sp,-48
    80002b04:	f406                	sd	ra,40(sp)
    80002b06:	f022                	sd	s0,32(sp)
    80002b08:	ec26                	sd	s1,24(sp)
    80002b0a:	e84a                	sd	s2,16(sp)
    80002b0c:	e44e                	sd	s3,8(sp)
    80002b0e:	1800                	addi	s0,sp,48
    80002b10:	892a                	mv	s2,a0
    80002b12:	84ae                	mv	s1,a1
    80002b14:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	f2c080e7          	jalr	-212(ra) # 80001a42 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b1e:	86ce                	mv	a3,s3
    80002b20:	864a                	mv	a2,s2
    80002b22:	85a6                	mv	a1,s1
    80002b24:	6928                	ld	a0,80(a0)
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	d28080e7          	jalr	-728(ra) # 8000184e <copyinstr>
  if(err < 0)
    80002b2e:	00054763          	bltz	a0,80002b3c <fetchstr+0x3a>
  return strlen(buf);
    80002b32:	8526                	mv	a0,s1
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	3c4080e7          	jalr	964(ra) # 80000ef8 <strlen>
}
    80002b3c:	70a2                	ld	ra,40(sp)
    80002b3e:	7402                	ld	s0,32(sp)
    80002b40:	64e2                	ld	s1,24(sp)
    80002b42:	6942                	ld	s2,16(sp)
    80002b44:	69a2                	ld	s3,8(sp)
    80002b46:	6145                	addi	sp,sp,48
    80002b48:	8082                	ret

0000000080002b4a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	1000                	addi	s0,sp,32
    80002b54:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	ef2080e7          	jalr	-270(ra) # 80002a48 <argraw>
    80002b5e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b60:	4501                	li	a0,0
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6105                	addi	sp,sp,32
    80002b6a:	8082                	ret

0000000080002b6c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	1000                	addi	s0,sp,32
    80002b76:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	ed0080e7          	jalr	-304(ra) # 80002a48 <argraw>
    80002b80:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b82:	4501                	li	a0,0
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret

0000000080002b8e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b8e:	1101                	addi	sp,sp,-32
    80002b90:	ec06                	sd	ra,24(sp)
    80002b92:	e822                	sd	s0,16(sp)
    80002b94:	e426                	sd	s1,8(sp)
    80002b96:	e04a                	sd	s2,0(sp)
    80002b98:	1000                	addi	s0,sp,32
    80002b9a:	84ae                	mv	s1,a1
    80002b9c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	eaa080e7          	jalr	-342(ra) # 80002a48 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ba6:	864a                	mv	a2,s2
    80002ba8:	85a6                	mv	a1,s1
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	f58080e7          	jalr	-168(ra) # 80002b02 <fetchstr>
}
    80002bb2:	60e2                	ld	ra,24(sp)
    80002bb4:	6442                	ld	s0,16(sp)
    80002bb6:	64a2                	ld	s1,8(sp)
    80002bb8:	6902                	ld	s2,0(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret

0000000080002bbe <syscall>:
[SYS_sigreturn] sys_sigreturn
};

void
syscall(void)
{
    80002bbe:	1101                	addi	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	e426                	sd	s1,8(sp)
    80002bc6:	e04a                	sd	s2,0(sp)
    80002bc8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	e78080e7          	jalr	-392(ra) # 80001a42 <myproc>
    80002bd2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bd4:	05853903          	ld	s2,88(a0)
    80002bd8:	0a893783          	ld	a5,168(s2)
    80002bdc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002be0:	37fd                	addiw	a5,a5,-1
    80002be2:	4759                	li	a4,22
    80002be4:	00f76f63          	bltu	a4,a5,80002c02 <syscall+0x44>
    80002be8:	00369713          	slli	a4,a3,0x3
    80002bec:	00006797          	auipc	a5,0x6
    80002bf0:	85478793          	addi	a5,a5,-1964 # 80008440 <syscalls>
    80002bf4:	97ba                	add	a5,a5,a4
    80002bf6:	639c                	ld	a5,0(a5)
    80002bf8:	c789                	beqz	a5,80002c02 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bfa:	9782                	jalr	a5
    80002bfc:	06a93823          	sd	a0,112(s2)
    80002c00:	a839                	j	80002c1e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c02:	15848613          	addi	a2,s1,344
    80002c06:	5c8c                	lw	a1,56(s1)
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	80050513          	addi	a0,a0,-2048 # 80008408 <states.1711+0x148>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	a18080e7          	jalr	-1512(ra) # 80000628 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c18:	6cbc                	ld	a5,88(s1)
    80002c1a:	577d                	li	a4,-1
    80002c1c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6902                	ld	s2,0(sp)
    80002c26:	6105                	addi	sp,sp,32
    80002c28:	8082                	ret

0000000080002c2a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c32:	fec40593          	addi	a1,s0,-20
    80002c36:	4501                	li	a0,0
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	f12080e7          	jalr	-238(ra) # 80002b4a <argint>
    return -1;
    80002c40:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c42:	00054963          	bltz	a0,80002c54 <sys_exit+0x2a>
  exit(n);
    80002c46:	fec42503          	lw	a0,-20(s0)
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	4ce080e7          	jalr	1230(ra) # 80002118 <exit>
  return 0;  // not reached
    80002c52:	4781                	li	a5,0
}
    80002c54:	853e                	mv	a0,a5
    80002c56:	60e2                	ld	ra,24(sp)
    80002c58:	6442                	ld	s0,16(sp)
    80002c5a:	6105                	addi	sp,sp,32
    80002c5c:	8082                	ret

0000000080002c5e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c5e:	1141                	addi	sp,sp,-16
    80002c60:	e406                	sd	ra,8(sp)
    80002c62:	e022                	sd	s0,0(sp)
    80002c64:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	ddc080e7          	jalr	-548(ra) # 80001a42 <myproc>
}
    80002c6e:	5d08                	lw	a0,56(a0)
    80002c70:	60a2                	ld	ra,8(sp)
    80002c72:	6402                	ld	s0,0(sp)
    80002c74:	0141                	addi	sp,sp,16
    80002c76:	8082                	ret

0000000080002c78 <sys_fork>:

uint64
sys_fork(void)
{
    80002c78:	1141                	addi	sp,sp,-16
    80002c7a:	e406                	sd	ra,8(sp)
    80002c7c:	e022                	sd	s0,0(sp)
    80002c7e:	0800                	addi	s0,sp,16
  return fork();
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	192080e7          	jalr	402(ra) # 80001e12 <fork>
}
    80002c88:	60a2                	ld	ra,8(sp)
    80002c8a:	6402                	ld	s0,0(sp)
    80002c8c:	0141                	addi	sp,sp,16
    80002c8e:	8082                	ret

0000000080002c90 <sys_wait>:

uint64
sys_wait(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c98:	fe840593          	addi	a1,s0,-24
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	ece080e7          	jalr	-306(ra) # 80002b6c <argaddr>
    80002ca6:	87aa                	mv	a5,a0
    return -1;
    80002ca8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002caa:	0007c863          	bltz	a5,80002cba <sys_wait+0x2a>
  return wait(p);
    80002cae:	fe843503          	ld	a0,-24(s0)
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	62a080e7          	jalr	1578(ra) # 800022dc <wait>
}
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret

0000000080002cc2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cc2:	7179                	addi	sp,sp,-48
    80002cc4:	f406                	sd	ra,40(sp)
    80002cc6:	f022                	sd	s0,32(sp)
    80002cc8:	ec26                	sd	s1,24(sp)
    80002cca:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ccc:	fdc40593          	addi	a1,s0,-36
    80002cd0:	4501                	li	a0,0
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	e78080e7          	jalr	-392(ra) # 80002b4a <argint>
    80002cda:	87aa                	mv	a5,a0
    return -1;
    80002cdc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cde:	0207c063          	bltz	a5,80002cfe <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	d60080e7          	jalr	-672(ra) # 80001a42 <myproc>
    80002cea:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cec:	fdc42503          	lw	a0,-36(s0)
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	0ae080e7          	jalr	174(ra) # 80001d9e <growproc>
    80002cf8:	00054863          	bltz	a0,80002d08 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cfc:	8526                	mv	a0,s1
}
    80002cfe:	70a2                	ld	ra,40(sp)
    80002d00:	7402                	ld	s0,32(sp)
    80002d02:	64e2                	ld	s1,24(sp)
    80002d04:	6145                	addi	sp,sp,48
    80002d06:	8082                	ret
    return -1;
    80002d08:	557d                	li	a0,-1
    80002d0a:	bfd5                	j	80002cfe <sys_sbrk+0x3c>

0000000080002d0c <sys_sleep>:


uint64
sys_sleep(void)
{
    80002d0c:	7139                	addi	sp,sp,-64
    80002d0e:	fc06                	sd	ra,56(sp)
    80002d10:	f822                	sd	s0,48(sp)
    80002d12:	f426                	sd	s1,40(sp)
    80002d14:	f04a                	sd	s2,32(sp)
    80002d16:	ec4e                	sd	s3,24(sp)
    80002d18:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d1a:	fcc40593          	addi	a1,s0,-52
    80002d1e:	4501                	li	a0,0
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	e2a080e7          	jalr	-470(ra) # 80002b4a <argint>
    return -1;
    80002d28:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d2a:	06054963          	bltz	a0,80002d9c <sys_sleep+0x90>
  acquire(&tickslock);
    80002d2e:	00015517          	auipc	a0,0x15
    80002d32:	23a50513          	addi	a0,a0,570 # 80017f68 <tickslock>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	f3e080e7          	jalr	-194(ra) # 80000c74 <acquire>
  ticks0 = ticks;
    80002d3e:	00006917          	auipc	s2,0x6
    80002d42:	2e292903          	lw	s2,738(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d46:	fcc42783          	lw	a5,-52(s0)
    80002d4a:	cf85                	beqz	a5,80002d82 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d4c:	00015997          	auipc	s3,0x15
    80002d50:	21c98993          	addi	s3,s3,540 # 80017f68 <tickslock>
    80002d54:	00006497          	auipc	s1,0x6
    80002d58:	2cc48493          	addi	s1,s1,716 # 80009020 <ticks>
    if(myproc()->killed){
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	ce6080e7          	jalr	-794(ra) # 80001a42 <myproc>
    80002d64:	591c                	lw	a5,48(a0)
    80002d66:	e3b9                	bnez	a5,80002dac <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002d68:	85ce                	mv	a1,s3
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	4f2080e7          	jalr	1266(ra) # 8000225e <sleep>
  while(ticks - ticks0 < n){
    80002d74:	409c                	lw	a5,0(s1)
    80002d76:	412787bb          	subw	a5,a5,s2
    80002d7a:	fcc42703          	lw	a4,-52(s0)
    80002d7e:	fce7efe3          	bltu	a5,a4,80002d5c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d82:	00015517          	auipc	a0,0x15
    80002d86:	1e650513          	addi	a0,a0,486 # 80017f68 <tickslock>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	f9e080e7          	jalr	-98(ra) # 80000d28 <release>

  // lab4-2
  // 测试是用sleep()系统调用测试的，所以在这里也打印
  backtrace();
    80002d92:	ffffd097          	auipc	ra,0xffffd
    80002d96:	7e8080e7          	jalr	2024(ra) # 8000057a <backtrace>

  return 0;
    80002d9a:	4781                	li	a5,0
}
    80002d9c:	853e                	mv	a0,a5
    80002d9e:	70e2                	ld	ra,56(sp)
    80002da0:	7442                	ld	s0,48(sp)
    80002da2:	74a2                	ld	s1,40(sp)
    80002da4:	7902                	ld	s2,32(sp)
    80002da6:	69e2                	ld	s3,24(sp)
    80002da8:	6121                	addi	sp,sp,64
    80002daa:	8082                	ret
      release(&tickslock);
    80002dac:	00015517          	auipc	a0,0x15
    80002db0:	1bc50513          	addi	a0,a0,444 # 80017f68 <tickslock>
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	f74080e7          	jalr	-140(ra) # 80000d28 <release>
      return -1;
    80002dbc:	57fd                	li	a5,-1
    80002dbe:	bff9                	j	80002d9c <sys_sleep+0x90>

0000000080002dc0 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dc8:	fec40593          	addi	a1,s0,-20
    80002dcc:	4501                	li	a0,0
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	d7c080e7          	jalr	-644(ra) # 80002b4a <argint>
    80002dd6:	87aa                	mv	a5,a0
    return -1;
    80002dd8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dda:	0007c863          	bltz	a5,80002dea <sys_kill+0x2a>
  return kill(pid);
    80002dde:	fec42503          	lw	a0,-20(s0)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	66c080e7          	jalr	1644(ra) # 8000244e <kill>
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dfc:	00015517          	auipc	a0,0x15
    80002e00:	16c50513          	addi	a0,a0,364 # 80017f68 <tickslock>
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	e70080e7          	jalr	-400(ra) # 80000c74 <acquire>
  xticks = ticks;
    80002e0c:	00006497          	auipc	s1,0x6
    80002e10:	2144a483          	lw	s1,532(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e14:	00015517          	auipc	a0,0x15
    80002e18:	15450513          	addi	a0,a0,340 # 80017f68 <tickslock>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	f0c080e7          	jalr	-244(ra) # 80000d28 <release>
  return xticks;
}
    80002e24:	02049513          	slli	a0,s1,0x20
    80002e28:	9101                	srli	a0,a0,0x20
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <sys_sigalarm>:


// lab4-3添加对系统调用的实际函数实现
uint64
sys_sigalarm(void)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	1000                	addi	s0,sp,32
    uint64 handler; // 函数指针就是个地址
    struct proc *p;

    // 取出时间间隔，要求时间间隔非负,时间间隔为0是可以的，表示取消调用
    // 取出0号寄存器和1号寄存器的地址
    if(argint(0, &interval) < 0 || argaddr(1, &handler) < 0 || interval < 0)
    80002e3c:	fec40593          	addi	a1,s0,-20
    80002e40:	4501                	li	a0,0
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	d08080e7          	jalr	-760(ra) # 80002b4a <argint>
    {
        return -1;
    80002e4a:	57fd                	li	a5,-1
    if(argint(0, &interval) < 0 || argaddr(1, &handler) < 0 || interval < 0)
    80002e4c:	02054f63          	bltz	a0,80002e8a <sys_sigalarm+0x56>
    80002e50:	fe040593          	addi	a1,s0,-32
    80002e54:	4505                	li	a0,1
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	d16080e7          	jalr	-746(ra) # 80002b6c <argaddr>
    80002e5e:	02054b63          	bltz	a0,80002e94 <sys_sigalarm+0x60>
    80002e62:	fec42703          	lw	a4,-20(s0)
        return -1;
    80002e66:	57fd                	li	a5,-1
    if(argint(0, &interval) < 0 || argaddr(1, &handler) < 0 || interval < 0)
    80002e68:	02074163          	bltz	a4,80002e8a <sys_sigalarm+0x56>
    }

    // 取出当前进程结构体，进行赋值
    p = myproc();
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	bd6080e7          	jalr	-1066(ra) # 80001a42 <myproc>
    p->interval = interval;
    80002e74:	fec42783          	lw	a5,-20(s0)
    80002e78:	16f52423          	sw	a5,360(a0)
    p->handler = handler;
    80002e7c:	fe043783          	ld	a5,-32(s0)
    80002e80:	16f53823          	sd	a5,368(a0)
    p->passedticks = 0; // 重置时钟
    80002e84:	16052c23          	sw	zero,376(a0)

    return 0;
    80002e88:	4781                	li	a5,0
}
    80002e8a:	853e                	mv	a0,a5
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret
        return -1;
    80002e94:	57fd                	li	a5,-1
    80002e96:	bfd5                	j	80002e8a <sys_sigalarm+0x56>

0000000080002e98 <sys_sigreturn>:
// lab4-3 test1/test2
// 在trap.c的usertrap中保存了函数调用之前的寄存器，现在要返回用户空间的时候进行复原
uint64
sys_sigreturn(void)
{
    80002e98:	1101                	addi	sp,sp,-32
    80002e9a:	ec06                	sd	ra,24(sp)
    80002e9c:	e822                	sd	s0,16(sp)
    80002e9e:	e426                	sd	s1,8(sp)
    80002ea0:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	ba0080e7          	jalr	-1120(ra) # 80001a42 <myproc>
    80002eaa:	84aa                	mv	s1,a0
    // 判断下地址，防止在没有进行复制副本之前调用这个系统调用
    if(p->trapframecopy != p->trapframe + 512)
    80002eac:	18053583          	ld	a1,384(a0)
    80002eb0:	6d38                	ld	a4,88(a0)
    80002eb2:	000247b7          	lui	a5,0x24
    80002eb6:	97ba                	add	a5,a5,a4
    {
        return -1;
    80002eb8:	557d                	li	a0,-1
    if(p->trapframecopy != p->trapframe + 512)
    80002eba:	00f58763          	beq	a1,a5,80002ec8 <sys_sigreturn+0x30>
    memmove(p->trapframe, p->trapframecopy, sizeof(struct trapframe));
    p->passedticks = 0;
    p->trapframecopy = 0;

    return 0;
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret
    memmove(p->trapframe, p->trapframecopy, sizeof(struct trapframe));
    80002ec8:	12000613          	li	a2,288
    80002ecc:	853a                	mv	a0,a4
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	f02080e7          	jalr	-254(ra) # 80000dd0 <memmove>
    p->passedticks = 0;
    80002ed6:	1604ac23          	sw	zero,376(s1)
    p->trapframecopy = 0;
    80002eda:	1804b023          	sd	zero,384(s1)
    return 0;
    80002ede:	4501                	li	a0,0
    80002ee0:	bff9                	j	80002ebe <sys_sigreturn+0x26>

0000000080002ee2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ee2:	7179                	addi	sp,sp,-48
    80002ee4:	f406                	sd	ra,40(sp)
    80002ee6:	f022                	sd	s0,32(sp)
    80002ee8:	ec26                	sd	s1,24(sp)
    80002eea:	e84a                	sd	s2,16(sp)
    80002eec:	e44e                	sd	s3,8(sp)
    80002eee:	e052                	sd	s4,0(sp)
    80002ef0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ef2:	00005597          	auipc	a1,0x5
    80002ef6:	60e58593          	addi	a1,a1,1550 # 80008500 <syscalls+0xc0>
    80002efa:	00015517          	auipc	a0,0x15
    80002efe:	08650513          	addi	a0,a0,134 # 80017f80 <bcache>
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	ce2080e7          	jalr	-798(ra) # 80000be4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f0a:	0001d797          	auipc	a5,0x1d
    80002f0e:	07678793          	addi	a5,a5,118 # 8001ff80 <bcache+0x8000>
    80002f12:	0001d717          	auipc	a4,0x1d
    80002f16:	2d670713          	addi	a4,a4,726 # 800201e8 <bcache+0x8268>
    80002f1a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f1e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f22:	00015497          	auipc	s1,0x15
    80002f26:	07648493          	addi	s1,s1,118 # 80017f98 <bcache+0x18>
    b->next = bcache.head.next;
    80002f2a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f2c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f2e:	00005a17          	auipc	s4,0x5
    80002f32:	5daa0a13          	addi	s4,s4,1498 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f36:	2b893783          	ld	a5,696(s2)
    80002f3a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f3c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f40:	85d2                	mv	a1,s4
    80002f42:	01048513          	addi	a0,s1,16
    80002f46:	00001097          	auipc	ra,0x1
    80002f4a:	4ac080e7          	jalr	1196(ra) # 800043f2 <initsleeplock>
    bcache.head.next->prev = b;
    80002f4e:	2b893783          	ld	a5,696(s2)
    80002f52:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f54:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f58:	45848493          	addi	s1,s1,1112
    80002f5c:	fd349de3          	bne	s1,s3,80002f36 <binit+0x54>
  }
}
    80002f60:	70a2                	ld	ra,40(sp)
    80002f62:	7402                	ld	s0,32(sp)
    80002f64:	64e2                	ld	s1,24(sp)
    80002f66:	6942                	ld	s2,16(sp)
    80002f68:	69a2                	ld	s3,8(sp)
    80002f6a:	6a02                	ld	s4,0(sp)
    80002f6c:	6145                	addi	sp,sp,48
    80002f6e:	8082                	ret

0000000080002f70 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f70:	7179                	addi	sp,sp,-48
    80002f72:	f406                	sd	ra,40(sp)
    80002f74:	f022                	sd	s0,32(sp)
    80002f76:	ec26                	sd	s1,24(sp)
    80002f78:	e84a                	sd	s2,16(sp)
    80002f7a:	e44e                	sd	s3,8(sp)
    80002f7c:	1800                	addi	s0,sp,48
    80002f7e:	89aa                	mv	s3,a0
    80002f80:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f82:	00015517          	auipc	a0,0x15
    80002f86:	ffe50513          	addi	a0,a0,-2 # 80017f80 <bcache>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	cea080e7          	jalr	-790(ra) # 80000c74 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f92:	0001d497          	auipc	s1,0x1d
    80002f96:	2a64b483          	ld	s1,678(s1) # 80020238 <bcache+0x82b8>
    80002f9a:	0001d797          	auipc	a5,0x1d
    80002f9e:	24e78793          	addi	a5,a5,590 # 800201e8 <bcache+0x8268>
    80002fa2:	02f48f63          	beq	s1,a5,80002fe0 <bread+0x70>
    80002fa6:	873e                	mv	a4,a5
    80002fa8:	a021                	j	80002fb0 <bread+0x40>
    80002faa:	68a4                	ld	s1,80(s1)
    80002fac:	02e48a63          	beq	s1,a4,80002fe0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fb0:	449c                	lw	a5,8(s1)
    80002fb2:	ff379ce3          	bne	a5,s3,80002faa <bread+0x3a>
    80002fb6:	44dc                	lw	a5,12(s1)
    80002fb8:	ff2799e3          	bne	a5,s2,80002faa <bread+0x3a>
      b->refcnt++;
    80002fbc:	40bc                	lw	a5,64(s1)
    80002fbe:	2785                	addiw	a5,a5,1
    80002fc0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc2:	00015517          	auipc	a0,0x15
    80002fc6:	fbe50513          	addi	a0,a0,-66 # 80017f80 <bcache>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	d5e080e7          	jalr	-674(ra) # 80000d28 <release>
      acquiresleep(&b->lock);
    80002fd2:	01048513          	addi	a0,s1,16
    80002fd6:	00001097          	auipc	ra,0x1
    80002fda:	456080e7          	jalr	1110(ra) # 8000442c <acquiresleep>
      return b;
    80002fde:	a8b9                	j	8000303c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe0:	0001d497          	auipc	s1,0x1d
    80002fe4:	2504b483          	ld	s1,592(s1) # 80020230 <bcache+0x82b0>
    80002fe8:	0001d797          	auipc	a5,0x1d
    80002fec:	20078793          	addi	a5,a5,512 # 800201e8 <bcache+0x8268>
    80002ff0:	00f48863          	beq	s1,a5,80003000 <bread+0x90>
    80002ff4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ff6:	40bc                	lw	a5,64(s1)
    80002ff8:	cf81                	beqz	a5,80003010 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ffa:	64a4                	ld	s1,72(s1)
    80002ffc:	fee49de3          	bne	s1,a4,80002ff6 <bread+0x86>
  panic("bget: no buffers");
    80003000:	00005517          	auipc	a0,0x5
    80003004:	51050513          	addi	a0,a0,1296 # 80008510 <syscalls+0xd0>
    80003008:	ffffd097          	auipc	ra,0xffffd
    8000300c:	5ce080e7          	jalr	1486(ra) # 800005d6 <panic>
      b->dev = dev;
    80003010:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003014:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003018:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000301c:	4785                	li	a5,1
    8000301e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003020:	00015517          	auipc	a0,0x15
    80003024:	f6050513          	addi	a0,a0,-160 # 80017f80 <bcache>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	d00080e7          	jalr	-768(ra) # 80000d28 <release>
      acquiresleep(&b->lock);
    80003030:	01048513          	addi	a0,s1,16
    80003034:	00001097          	auipc	ra,0x1
    80003038:	3f8080e7          	jalr	1016(ra) # 8000442c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000303c:	409c                	lw	a5,0(s1)
    8000303e:	cb89                	beqz	a5,80003050 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003040:	8526                	mv	a0,s1
    80003042:	70a2                	ld	ra,40(sp)
    80003044:	7402                	ld	s0,32(sp)
    80003046:	64e2                	ld	s1,24(sp)
    80003048:	6942                	ld	s2,16(sp)
    8000304a:	69a2                	ld	s3,8(sp)
    8000304c:	6145                	addi	sp,sp,48
    8000304e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003050:	4581                	li	a1,0
    80003052:	8526                	mv	a0,s1
    80003054:	00003097          	auipc	ra,0x3
    80003058:	f38080e7          	jalr	-200(ra) # 80005f8c <virtio_disk_rw>
    b->valid = 1;
    8000305c:	4785                	li	a5,1
    8000305e:	c09c                	sw	a5,0(s1)
  return b;
    80003060:	b7c5                	j	80003040 <bread+0xd0>

0000000080003062 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	e426                	sd	s1,8(sp)
    8000306a:	1000                	addi	s0,sp,32
    8000306c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000306e:	0541                	addi	a0,a0,16
    80003070:	00001097          	auipc	ra,0x1
    80003074:	456080e7          	jalr	1110(ra) # 800044c6 <holdingsleep>
    80003078:	cd01                	beqz	a0,80003090 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000307a:	4585                	li	a1,1
    8000307c:	8526                	mv	a0,s1
    8000307e:	00003097          	auipc	ra,0x3
    80003082:	f0e080e7          	jalr	-242(ra) # 80005f8c <virtio_disk_rw>
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret
    panic("bwrite");
    80003090:	00005517          	auipc	a0,0x5
    80003094:	49850513          	addi	a0,a0,1176 # 80008528 <syscalls+0xe8>
    80003098:	ffffd097          	auipc	ra,0xffffd
    8000309c:	53e080e7          	jalr	1342(ra) # 800005d6 <panic>

00000000800030a0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	e04a                	sd	s2,0(sp)
    800030aa:	1000                	addi	s0,sp,32
    800030ac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ae:	01050913          	addi	s2,a0,16
    800030b2:	854a                	mv	a0,s2
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	412080e7          	jalr	1042(ra) # 800044c6 <holdingsleep>
    800030bc:	c92d                	beqz	a0,8000312e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030be:	854a                	mv	a0,s2
    800030c0:	00001097          	auipc	ra,0x1
    800030c4:	3c2080e7          	jalr	962(ra) # 80004482 <releasesleep>

  acquire(&bcache.lock);
    800030c8:	00015517          	auipc	a0,0x15
    800030cc:	eb850513          	addi	a0,a0,-328 # 80017f80 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	ba4080e7          	jalr	-1116(ra) # 80000c74 <acquire>
  b->refcnt--;
    800030d8:	40bc                	lw	a5,64(s1)
    800030da:	37fd                	addiw	a5,a5,-1
    800030dc:	0007871b          	sext.w	a4,a5
    800030e0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030e2:	eb05                	bnez	a4,80003112 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030e4:	68bc                	ld	a5,80(s1)
    800030e6:	64b8                	ld	a4,72(s1)
    800030e8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030ea:	64bc                	ld	a5,72(s1)
    800030ec:	68b8                	ld	a4,80(s1)
    800030ee:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030f0:	0001d797          	auipc	a5,0x1d
    800030f4:	e9078793          	addi	a5,a5,-368 # 8001ff80 <bcache+0x8000>
    800030f8:	2b87b703          	ld	a4,696(a5)
    800030fc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030fe:	0001d717          	auipc	a4,0x1d
    80003102:	0ea70713          	addi	a4,a4,234 # 800201e8 <bcache+0x8268>
    80003106:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003108:	2b87b703          	ld	a4,696(a5)
    8000310c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000310e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003112:	00015517          	auipc	a0,0x15
    80003116:	e6e50513          	addi	a0,a0,-402 # 80017f80 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	c0e080e7          	jalr	-1010(ra) # 80000d28 <release>
}
    80003122:	60e2                	ld	ra,24(sp)
    80003124:	6442                	ld	s0,16(sp)
    80003126:	64a2                	ld	s1,8(sp)
    80003128:	6902                	ld	s2,0(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret
    panic("brelse");
    8000312e:	00005517          	auipc	a0,0x5
    80003132:	40250513          	addi	a0,a0,1026 # 80008530 <syscalls+0xf0>
    80003136:	ffffd097          	auipc	ra,0xffffd
    8000313a:	4a0080e7          	jalr	1184(ra) # 800005d6 <panic>

000000008000313e <bpin>:

void
bpin(struct buf *b) {
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	1000                	addi	s0,sp,32
    80003148:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314a:	00015517          	auipc	a0,0x15
    8000314e:	e3650513          	addi	a0,a0,-458 # 80017f80 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b22080e7          	jalr	-1246(ra) # 80000c74 <acquire>
  b->refcnt++;
    8000315a:	40bc                	lw	a5,64(s1)
    8000315c:	2785                	addiw	a5,a5,1
    8000315e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003160:	00015517          	auipc	a0,0x15
    80003164:	e2050513          	addi	a0,a0,-480 # 80017f80 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	bc0080e7          	jalr	-1088(ra) # 80000d28 <release>
}
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	64a2                	ld	s1,8(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret

000000008000317a <bunpin>:

void
bunpin(struct buf *b) {
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	e426                	sd	s1,8(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003186:	00015517          	auipc	a0,0x15
    8000318a:	dfa50513          	addi	a0,a0,-518 # 80017f80 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	ae6080e7          	jalr	-1306(ra) # 80000c74 <acquire>
  b->refcnt--;
    80003196:	40bc                	lw	a5,64(s1)
    80003198:	37fd                	addiw	a5,a5,-1
    8000319a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000319c:	00015517          	auipc	a0,0x15
    800031a0:	de450513          	addi	a0,a0,-540 # 80017f80 <bcache>
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	b84080e7          	jalr	-1148(ra) # 80000d28 <release>
}
    800031ac:	60e2                	ld	ra,24(sp)
    800031ae:	6442                	ld	s0,16(sp)
    800031b0:	64a2                	ld	s1,8(sp)
    800031b2:	6105                	addi	sp,sp,32
    800031b4:	8082                	ret

00000000800031b6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	e426                	sd	s1,8(sp)
    800031be:	e04a                	sd	s2,0(sp)
    800031c0:	1000                	addi	s0,sp,32
    800031c2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031c4:	00d5d59b          	srliw	a1,a1,0xd
    800031c8:	0001d797          	auipc	a5,0x1d
    800031cc:	4947a783          	lw	a5,1172(a5) # 8002065c <sb+0x1c>
    800031d0:	9dbd                	addw	a1,a1,a5
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	d9e080e7          	jalr	-610(ra) # 80002f70 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031da:	0074f713          	andi	a4,s1,7
    800031de:	4785                	li	a5,1
    800031e0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031e4:	14ce                	slli	s1,s1,0x33
    800031e6:	90d9                	srli	s1,s1,0x36
    800031e8:	00950733          	add	a4,a0,s1
    800031ec:	05874703          	lbu	a4,88(a4)
    800031f0:	00e7f6b3          	and	a3,a5,a4
    800031f4:	c69d                	beqz	a3,80003222 <bfree+0x6c>
    800031f6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031f8:	94aa                	add	s1,s1,a0
    800031fa:	fff7c793          	not	a5,a5
    800031fe:	8ff9                	and	a5,a5,a4
    80003200:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003204:	00001097          	auipc	ra,0x1
    80003208:	100080e7          	jalr	256(ra) # 80004304 <log_write>
  brelse(bp);
    8000320c:	854a                	mv	a0,s2
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	e92080e7          	jalr	-366(ra) # 800030a0 <brelse>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6902                	ld	s2,0(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret
    panic("freeing free block");
    80003222:	00005517          	auipc	a0,0x5
    80003226:	31650513          	addi	a0,a0,790 # 80008538 <syscalls+0xf8>
    8000322a:	ffffd097          	auipc	ra,0xffffd
    8000322e:	3ac080e7          	jalr	940(ra) # 800005d6 <panic>

0000000080003232 <balloc>:
{
    80003232:	711d                	addi	sp,sp,-96
    80003234:	ec86                	sd	ra,88(sp)
    80003236:	e8a2                	sd	s0,80(sp)
    80003238:	e4a6                	sd	s1,72(sp)
    8000323a:	e0ca                	sd	s2,64(sp)
    8000323c:	fc4e                	sd	s3,56(sp)
    8000323e:	f852                	sd	s4,48(sp)
    80003240:	f456                	sd	s5,40(sp)
    80003242:	f05a                	sd	s6,32(sp)
    80003244:	ec5e                	sd	s7,24(sp)
    80003246:	e862                	sd	s8,16(sp)
    80003248:	e466                	sd	s9,8(sp)
    8000324a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000324c:	0001d797          	auipc	a5,0x1d
    80003250:	3f87a783          	lw	a5,1016(a5) # 80020644 <sb+0x4>
    80003254:	cbd1                	beqz	a5,800032e8 <balloc+0xb6>
    80003256:	8baa                	mv	s7,a0
    80003258:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000325a:	0001db17          	auipc	s6,0x1d
    8000325e:	3e6b0b13          	addi	s6,s6,998 # 80020640 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003262:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003264:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003266:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003268:	6c89                	lui	s9,0x2
    8000326a:	a831                	j	80003286 <balloc+0x54>
    brelse(bp);
    8000326c:	854a                	mv	a0,s2
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	e32080e7          	jalr	-462(ra) # 800030a0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003276:	015c87bb          	addw	a5,s9,s5
    8000327a:	00078a9b          	sext.w	s5,a5
    8000327e:	004b2703          	lw	a4,4(s6)
    80003282:	06eaf363          	bgeu	s5,a4,800032e8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003286:	41fad79b          	sraiw	a5,s5,0x1f
    8000328a:	0137d79b          	srliw	a5,a5,0x13
    8000328e:	015787bb          	addw	a5,a5,s5
    80003292:	40d7d79b          	sraiw	a5,a5,0xd
    80003296:	01cb2583          	lw	a1,28(s6)
    8000329a:	9dbd                	addw	a1,a1,a5
    8000329c:	855e                	mv	a0,s7
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	cd2080e7          	jalr	-814(ra) # 80002f70 <bread>
    800032a6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a8:	004b2503          	lw	a0,4(s6)
    800032ac:	000a849b          	sext.w	s1,s5
    800032b0:	8662                	mv	a2,s8
    800032b2:	faa4fde3          	bgeu	s1,a0,8000326c <balloc+0x3a>
      m = 1 << (bi % 8);
    800032b6:	41f6579b          	sraiw	a5,a2,0x1f
    800032ba:	01d7d69b          	srliw	a3,a5,0x1d
    800032be:	00c6873b          	addw	a4,a3,a2
    800032c2:	00777793          	andi	a5,a4,7
    800032c6:	9f95                	subw	a5,a5,a3
    800032c8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032cc:	4037571b          	sraiw	a4,a4,0x3
    800032d0:	00e906b3          	add	a3,s2,a4
    800032d4:	0586c683          	lbu	a3,88(a3)
    800032d8:	00d7f5b3          	and	a1,a5,a3
    800032dc:	cd91                	beqz	a1,800032f8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032de:	2605                	addiw	a2,a2,1
    800032e0:	2485                	addiw	s1,s1,1
    800032e2:	fd4618e3          	bne	a2,s4,800032b2 <balloc+0x80>
    800032e6:	b759                	j	8000326c <balloc+0x3a>
  panic("balloc: out of blocks");
    800032e8:	00005517          	auipc	a0,0x5
    800032ec:	26850513          	addi	a0,a0,616 # 80008550 <syscalls+0x110>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	2e6080e7          	jalr	742(ra) # 800005d6 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032f8:	974a                	add	a4,a4,s2
    800032fa:	8fd5                	or	a5,a5,a3
    800032fc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00001097          	auipc	ra,0x1
    80003306:	002080e7          	jalr	2(ra) # 80004304 <log_write>
        brelse(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	d94080e7          	jalr	-620(ra) # 800030a0 <brelse>
  bp = bread(dev, bno);
    80003314:	85a6                	mv	a1,s1
    80003316:	855e                	mv	a0,s7
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	c58080e7          	jalr	-936(ra) # 80002f70 <bread>
    80003320:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003322:	40000613          	li	a2,1024
    80003326:	4581                	li	a1,0
    80003328:	05850513          	addi	a0,a0,88
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	a44080e7          	jalr	-1468(ra) # 80000d70 <memset>
  log_write(bp);
    80003334:	854a                	mv	a0,s2
    80003336:	00001097          	auipc	ra,0x1
    8000333a:	fce080e7          	jalr	-50(ra) # 80004304 <log_write>
  brelse(bp);
    8000333e:	854a                	mv	a0,s2
    80003340:	00000097          	auipc	ra,0x0
    80003344:	d60080e7          	jalr	-672(ra) # 800030a0 <brelse>
}
    80003348:	8526                	mv	a0,s1
    8000334a:	60e6                	ld	ra,88(sp)
    8000334c:	6446                	ld	s0,80(sp)
    8000334e:	64a6                	ld	s1,72(sp)
    80003350:	6906                	ld	s2,64(sp)
    80003352:	79e2                	ld	s3,56(sp)
    80003354:	7a42                	ld	s4,48(sp)
    80003356:	7aa2                	ld	s5,40(sp)
    80003358:	7b02                	ld	s6,32(sp)
    8000335a:	6be2                	ld	s7,24(sp)
    8000335c:	6c42                	ld	s8,16(sp)
    8000335e:	6ca2                	ld	s9,8(sp)
    80003360:	6125                	addi	sp,sp,96
    80003362:	8082                	ret

0000000080003364 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003364:	7179                	addi	sp,sp,-48
    80003366:	f406                	sd	ra,40(sp)
    80003368:	f022                	sd	s0,32(sp)
    8000336a:	ec26                	sd	s1,24(sp)
    8000336c:	e84a                	sd	s2,16(sp)
    8000336e:	e44e                	sd	s3,8(sp)
    80003370:	e052                	sd	s4,0(sp)
    80003372:	1800                	addi	s0,sp,48
    80003374:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003376:	47ad                	li	a5,11
    80003378:	04b7fe63          	bgeu	a5,a1,800033d4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000337c:	ff45849b          	addiw	s1,a1,-12
    80003380:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003384:	0ff00793          	li	a5,255
    80003388:	0ae7e363          	bltu	a5,a4,8000342e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000338c:	08052583          	lw	a1,128(a0)
    80003390:	c5ad                	beqz	a1,800033fa <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003392:	00092503          	lw	a0,0(s2)
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	bda080e7          	jalr	-1062(ra) # 80002f70 <bread>
    8000339e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033a0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033a4:	02049593          	slli	a1,s1,0x20
    800033a8:	9181                	srli	a1,a1,0x20
    800033aa:	058a                	slli	a1,a1,0x2
    800033ac:	00b784b3          	add	s1,a5,a1
    800033b0:	0004a983          	lw	s3,0(s1)
    800033b4:	04098d63          	beqz	s3,8000340e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033b8:	8552                	mv	a0,s4
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	ce6080e7          	jalr	-794(ra) # 800030a0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033c2:	854e                	mv	a0,s3
    800033c4:	70a2                	ld	ra,40(sp)
    800033c6:	7402                	ld	s0,32(sp)
    800033c8:	64e2                	ld	s1,24(sp)
    800033ca:	6942                	ld	s2,16(sp)
    800033cc:	69a2                	ld	s3,8(sp)
    800033ce:	6a02                	ld	s4,0(sp)
    800033d0:	6145                	addi	sp,sp,48
    800033d2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033d4:	02059493          	slli	s1,a1,0x20
    800033d8:	9081                	srli	s1,s1,0x20
    800033da:	048a                	slli	s1,s1,0x2
    800033dc:	94aa                	add	s1,s1,a0
    800033de:	0504a983          	lw	s3,80(s1)
    800033e2:	fe0990e3          	bnez	s3,800033c2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033e6:	4108                	lw	a0,0(a0)
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	e4a080e7          	jalr	-438(ra) # 80003232 <balloc>
    800033f0:	0005099b          	sext.w	s3,a0
    800033f4:	0534a823          	sw	s3,80(s1)
    800033f8:	b7e9                	j	800033c2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033fa:	4108                	lw	a0,0(a0)
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	e36080e7          	jalr	-458(ra) # 80003232 <balloc>
    80003404:	0005059b          	sext.w	a1,a0
    80003408:	08b92023          	sw	a1,128(s2)
    8000340c:	b759                	j	80003392 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000340e:	00092503          	lw	a0,0(s2)
    80003412:	00000097          	auipc	ra,0x0
    80003416:	e20080e7          	jalr	-480(ra) # 80003232 <balloc>
    8000341a:	0005099b          	sext.w	s3,a0
    8000341e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003422:	8552                	mv	a0,s4
    80003424:	00001097          	auipc	ra,0x1
    80003428:	ee0080e7          	jalr	-288(ra) # 80004304 <log_write>
    8000342c:	b771                	j	800033b8 <bmap+0x54>
  panic("bmap: out of range");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	13a50513          	addi	a0,a0,314 # 80008568 <syscalls+0x128>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	1a0080e7          	jalr	416(ra) # 800005d6 <panic>

000000008000343e <iget>:
{
    8000343e:	7179                	addi	sp,sp,-48
    80003440:	f406                	sd	ra,40(sp)
    80003442:	f022                	sd	s0,32(sp)
    80003444:	ec26                	sd	s1,24(sp)
    80003446:	e84a                	sd	s2,16(sp)
    80003448:	e44e                	sd	s3,8(sp)
    8000344a:	e052                	sd	s4,0(sp)
    8000344c:	1800                	addi	s0,sp,48
    8000344e:	89aa                	mv	s3,a0
    80003450:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003452:	0001d517          	auipc	a0,0x1d
    80003456:	20e50513          	addi	a0,a0,526 # 80020660 <icache>
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	81a080e7          	jalr	-2022(ra) # 80000c74 <acquire>
  empty = 0;
    80003462:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003464:	0001d497          	auipc	s1,0x1d
    80003468:	21448493          	addi	s1,s1,532 # 80020678 <icache+0x18>
    8000346c:	0001f697          	auipc	a3,0x1f
    80003470:	c9c68693          	addi	a3,a3,-868 # 80022108 <log>
    80003474:	a039                	j	80003482 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003476:	02090b63          	beqz	s2,800034ac <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000347a:	08848493          	addi	s1,s1,136
    8000347e:	02d48a63          	beq	s1,a3,800034b2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003482:	449c                	lw	a5,8(s1)
    80003484:	fef059e3          	blez	a5,80003476 <iget+0x38>
    80003488:	4098                	lw	a4,0(s1)
    8000348a:	ff3716e3          	bne	a4,s3,80003476 <iget+0x38>
    8000348e:	40d8                	lw	a4,4(s1)
    80003490:	ff4713e3          	bne	a4,s4,80003476 <iget+0x38>
      ip->ref++;
    80003494:	2785                	addiw	a5,a5,1
    80003496:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003498:	0001d517          	auipc	a0,0x1d
    8000349c:	1c850513          	addi	a0,a0,456 # 80020660 <icache>
    800034a0:	ffffe097          	auipc	ra,0xffffe
    800034a4:	888080e7          	jalr	-1912(ra) # 80000d28 <release>
      return ip;
    800034a8:	8926                	mv	s2,s1
    800034aa:	a03d                	j	800034d8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ac:	f7f9                	bnez	a5,8000347a <iget+0x3c>
    800034ae:	8926                	mv	s2,s1
    800034b0:	b7e9                	j	8000347a <iget+0x3c>
  if(empty == 0)
    800034b2:	02090c63          	beqz	s2,800034ea <iget+0xac>
  ip->dev = dev;
    800034b6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034ba:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034be:	4785                	li	a5,1
    800034c0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034c4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034c8:	0001d517          	auipc	a0,0x1d
    800034cc:	19850513          	addi	a0,a0,408 # 80020660 <icache>
    800034d0:	ffffe097          	auipc	ra,0xffffe
    800034d4:	858080e7          	jalr	-1960(ra) # 80000d28 <release>
}
    800034d8:	854a                	mv	a0,s2
    800034da:	70a2                	ld	ra,40(sp)
    800034dc:	7402                	ld	s0,32(sp)
    800034de:	64e2                	ld	s1,24(sp)
    800034e0:	6942                	ld	s2,16(sp)
    800034e2:	69a2                	ld	s3,8(sp)
    800034e4:	6a02                	ld	s4,0(sp)
    800034e6:	6145                	addi	sp,sp,48
    800034e8:	8082                	ret
    panic("iget: no inodes");
    800034ea:	00005517          	auipc	a0,0x5
    800034ee:	09650513          	addi	a0,a0,150 # 80008580 <syscalls+0x140>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	0e4080e7          	jalr	228(ra) # 800005d6 <panic>

00000000800034fa <fsinit>:
fsinit(int dev) {
    800034fa:	7179                	addi	sp,sp,-48
    800034fc:	f406                	sd	ra,40(sp)
    800034fe:	f022                	sd	s0,32(sp)
    80003500:	ec26                	sd	s1,24(sp)
    80003502:	e84a                	sd	s2,16(sp)
    80003504:	e44e                	sd	s3,8(sp)
    80003506:	1800                	addi	s0,sp,48
    80003508:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000350a:	4585                	li	a1,1
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	a64080e7          	jalr	-1436(ra) # 80002f70 <bread>
    80003514:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003516:	0001d997          	auipc	s3,0x1d
    8000351a:	12a98993          	addi	s3,s3,298 # 80020640 <sb>
    8000351e:	02000613          	li	a2,32
    80003522:	05850593          	addi	a1,a0,88
    80003526:	854e                	mv	a0,s3
    80003528:	ffffe097          	auipc	ra,0xffffe
    8000352c:	8a8080e7          	jalr	-1880(ra) # 80000dd0 <memmove>
  brelse(bp);
    80003530:	8526                	mv	a0,s1
    80003532:	00000097          	auipc	ra,0x0
    80003536:	b6e080e7          	jalr	-1170(ra) # 800030a0 <brelse>
  if(sb.magic != FSMAGIC)
    8000353a:	0009a703          	lw	a4,0(s3)
    8000353e:	102037b7          	lui	a5,0x10203
    80003542:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003546:	02f71263          	bne	a4,a5,8000356a <fsinit+0x70>
  initlog(dev, &sb);
    8000354a:	0001d597          	auipc	a1,0x1d
    8000354e:	0f658593          	addi	a1,a1,246 # 80020640 <sb>
    80003552:	854a                	mv	a0,s2
    80003554:	00001097          	auipc	ra,0x1
    80003558:	b38080e7          	jalr	-1224(ra) # 8000408c <initlog>
}
    8000355c:	70a2                	ld	ra,40(sp)
    8000355e:	7402                	ld	s0,32(sp)
    80003560:	64e2                	ld	s1,24(sp)
    80003562:	6942                	ld	s2,16(sp)
    80003564:	69a2                	ld	s3,8(sp)
    80003566:	6145                	addi	sp,sp,48
    80003568:	8082                	ret
    panic("invalid file system");
    8000356a:	00005517          	auipc	a0,0x5
    8000356e:	02650513          	addi	a0,a0,38 # 80008590 <syscalls+0x150>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	064080e7          	jalr	100(ra) # 800005d6 <panic>

000000008000357a <iinit>:
{
    8000357a:	7179                	addi	sp,sp,-48
    8000357c:	f406                	sd	ra,40(sp)
    8000357e:	f022                	sd	s0,32(sp)
    80003580:	ec26                	sd	s1,24(sp)
    80003582:	e84a                	sd	s2,16(sp)
    80003584:	e44e                	sd	s3,8(sp)
    80003586:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003588:	00005597          	auipc	a1,0x5
    8000358c:	02058593          	addi	a1,a1,32 # 800085a8 <syscalls+0x168>
    80003590:	0001d517          	auipc	a0,0x1d
    80003594:	0d050513          	addi	a0,a0,208 # 80020660 <icache>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	64c080e7          	jalr	1612(ra) # 80000be4 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035a0:	0001d497          	auipc	s1,0x1d
    800035a4:	0e848493          	addi	s1,s1,232 # 80020688 <icache+0x28>
    800035a8:	0001f997          	auipc	s3,0x1f
    800035ac:	b7098993          	addi	s3,s3,-1168 # 80022118 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035b0:	00005917          	auipc	s2,0x5
    800035b4:	00090913          	mv	s2,s2
    800035b8:	85ca                	mv	a1,s2
    800035ba:	8526                	mv	a0,s1
    800035bc:	00001097          	auipc	ra,0x1
    800035c0:	e36080e7          	jalr	-458(ra) # 800043f2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035c4:	08848493          	addi	s1,s1,136
    800035c8:	ff3498e3          	bne	s1,s3,800035b8 <iinit+0x3e>
}
    800035cc:	70a2                	ld	ra,40(sp)
    800035ce:	7402                	ld	s0,32(sp)
    800035d0:	64e2                	ld	s1,24(sp)
    800035d2:	6942                	ld	s2,16(sp)
    800035d4:	69a2                	ld	s3,8(sp)
    800035d6:	6145                	addi	sp,sp,48
    800035d8:	8082                	ret

00000000800035da <ialloc>:
{
    800035da:	715d                	addi	sp,sp,-80
    800035dc:	e486                	sd	ra,72(sp)
    800035de:	e0a2                	sd	s0,64(sp)
    800035e0:	fc26                	sd	s1,56(sp)
    800035e2:	f84a                	sd	s2,48(sp)
    800035e4:	f44e                	sd	s3,40(sp)
    800035e6:	f052                	sd	s4,32(sp)
    800035e8:	ec56                	sd	s5,24(sp)
    800035ea:	e85a                	sd	s6,16(sp)
    800035ec:	e45e                	sd	s7,8(sp)
    800035ee:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f0:	0001d717          	auipc	a4,0x1d
    800035f4:	05c72703          	lw	a4,92(a4) # 8002064c <sb+0xc>
    800035f8:	4785                	li	a5,1
    800035fa:	04e7fa63          	bgeu	a5,a4,8000364e <ialloc+0x74>
    800035fe:	8aaa                	mv	s5,a0
    80003600:	8bae                	mv	s7,a1
    80003602:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003604:	0001da17          	auipc	s4,0x1d
    80003608:	03ca0a13          	addi	s4,s4,60 # 80020640 <sb>
    8000360c:	00048b1b          	sext.w	s6,s1
    80003610:	0044d593          	srli	a1,s1,0x4
    80003614:	018a2783          	lw	a5,24(s4)
    80003618:	9dbd                	addw	a1,a1,a5
    8000361a:	8556                	mv	a0,s5
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	954080e7          	jalr	-1708(ra) # 80002f70 <bread>
    80003624:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003626:	05850993          	addi	s3,a0,88
    8000362a:	00f4f793          	andi	a5,s1,15
    8000362e:	079a                	slli	a5,a5,0x6
    80003630:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003632:	00099783          	lh	a5,0(s3)
    80003636:	c785                	beqz	a5,8000365e <ialloc+0x84>
    brelse(bp);
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	a68080e7          	jalr	-1432(ra) # 800030a0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003640:	0485                	addi	s1,s1,1
    80003642:	00ca2703          	lw	a4,12(s4)
    80003646:	0004879b          	sext.w	a5,s1
    8000364a:	fce7e1e3          	bltu	a5,a4,8000360c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000364e:	00005517          	auipc	a0,0x5
    80003652:	f6a50513          	addi	a0,a0,-150 # 800085b8 <syscalls+0x178>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	f80080e7          	jalr	-128(ra) # 800005d6 <panic>
      memset(dip, 0, sizeof(*dip));
    8000365e:	04000613          	li	a2,64
    80003662:	4581                	li	a1,0
    80003664:	854e                	mv	a0,s3
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	70a080e7          	jalr	1802(ra) # 80000d70 <memset>
      dip->type = type;
    8000366e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003672:	854a                	mv	a0,s2
    80003674:	00001097          	auipc	ra,0x1
    80003678:	c90080e7          	jalr	-880(ra) # 80004304 <log_write>
      brelse(bp);
    8000367c:	854a                	mv	a0,s2
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	a22080e7          	jalr	-1502(ra) # 800030a0 <brelse>
      return iget(dev, inum);
    80003686:	85da                	mv	a1,s6
    80003688:	8556                	mv	a0,s5
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	db4080e7          	jalr	-588(ra) # 8000343e <iget>
}
    80003692:	60a6                	ld	ra,72(sp)
    80003694:	6406                	ld	s0,64(sp)
    80003696:	74e2                	ld	s1,56(sp)
    80003698:	7942                	ld	s2,48(sp)
    8000369a:	79a2                	ld	s3,40(sp)
    8000369c:	7a02                	ld	s4,32(sp)
    8000369e:	6ae2                	ld	s5,24(sp)
    800036a0:	6b42                	ld	s6,16(sp)
    800036a2:	6ba2                	ld	s7,8(sp)
    800036a4:	6161                	addi	sp,sp,80
    800036a6:	8082                	ret

00000000800036a8 <iupdate>:
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	e04a                	sd	s2,0(sp)
    800036b2:	1000                	addi	s0,sp,32
    800036b4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036b6:	415c                	lw	a5,4(a0)
    800036b8:	0047d79b          	srliw	a5,a5,0x4
    800036bc:	0001d597          	auipc	a1,0x1d
    800036c0:	f9c5a583          	lw	a1,-100(a1) # 80020658 <sb+0x18>
    800036c4:	9dbd                	addw	a1,a1,a5
    800036c6:	4108                	lw	a0,0(a0)
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	8a8080e7          	jalr	-1880(ra) # 80002f70 <bread>
    800036d0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d2:	05850793          	addi	a5,a0,88
    800036d6:	40c8                	lw	a0,4(s1)
    800036d8:	893d                	andi	a0,a0,15
    800036da:	051a                	slli	a0,a0,0x6
    800036dc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036de:	04449703          	lh	a4,68(s1)
    800036e2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036e6:	04649703          	lh	a4,70(s1)
    800036ea:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036ee:	04849703          	lh	a4,72(s1)
    800036f2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036f6:	04a49703          	lh	a4,74(s1)
    800036fa:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036fe:	44f8                	lw	a4,76(s1)
    80003700:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003702:	03400613          	li	a2,52
    80003706:	05048593          	addi	a1,s1,80
    8000370a:	0531                	addi	a0,a0,12
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	6c4080e7          	jalr	1732(ra) # 80000dd0 <memmove>
  log_write(bp);
    80003714:	854a                	mv	a0,s2
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	bee080e7          	jalr	-1042(ra) # 80004304 <log_write>
  brelse(bp);
    8000371e:	854a                	mv	a0,s2
    80003720:	00000097          	auipc	ra,0x0
    80003724:	980080e7          	jalr	-1664(ra) # 800030a0 <brelse>
}
    80003728:	60e2                	ld	ra,24(sp)
    8000372a:	6442                	ld	s0,16(sp)
    8000372c:	64a2                	ld	s1,8(sp)
    8000372e:	6902                	ld	s2,0(sp)
    80003730:	6105                	addi	sp,sp,32
    80003732:	8082                	ret

0000000080003734 <idup>:
{
    80003734:	1101                	addi	sp,sp,-32
    80003736:	ec06                	sd	ra,24(sp)
    80003738:	e822                	sd	s0,16(sp)
    8000373a:	e426                	sd	s1,8(sp)
    8000373c:	1000                	addi	s0,sp,32
    8000373e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003740:	0001d517          	auipc	a0,0x1d
    80003744:	f2050513          	addi	a0,a0,-224 # 80020660 <icache>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	52c080e7          	jalr	1324(ra) # 80000c74 <acquire>
  ip->ref++;
    80003750:	449c                	lw	a5,8(s1)
    80003752:	2785                	addiw	a5,a5,1
    80003754:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003756:	0001d517          	auipc	a0,0x1d
    8000375a:	f0a50513          	addi	a0,a0,-246 # 80020660 <icache>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	5ca080e7          	jalr	1482(ra) # 80000d28 <release>
}
    80003766:	8526                	mv	a0,s1
    80003768:	60e2                	ld	ra,24(sp)
    8000376a:	6442                	ld	s0,16(sp)
    8000376c:	64a2                	ld	s1,8(sp)
    8000376e:	6105                	addi	sp,sp,32
    80003770:	8082                	ret

0000000080003772 <ilock>:
{
    80003772:	1101                	addi	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	e426                	sd	s1,8(sp)
    8000377a:	e04a                	sd	s2,0(sp)
    8000377c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000377e:	c115                	beqz	a0,800037a2 <ilock+0x30>
    80003780:	84aa                	mv	s1,a0
    80003782:	451c                	lw	a5,8(a0)
    80003784:	00f05f63          	blez	a5,800037a2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003788:	0541                	addi	a0,a0,16
    8000378a:	00001097          	auipc	ra,0x1
    8000378e:	ca2080e7          	jalr	-862(ra) # 8000442c <acquiresleep>
  if(ip->valid == 0){
    80003792:	40bc                	lw	a5,64(s1)
    80003794:	cf99                	beqz	a5,800037b2 <ilock+0x40>
}
    80003796:	60e2                	ld	ra,24(sp)
    80003798:	6442                	ld	s0,16(sp)
    8000379a:	64a2                	ld	s1,8(sp)
    8000379c:	6902                	ld	s2,0(sp)
    8000379e:	6105                	addi	sp,sp,32
    800037a0:	8082                	ret
    panic("ilock");
    800037a2:	00005517          	auipc	a0,0x5
    800037a6:	e2e50513          	addi	a0,a0,-466 # 800085d0 <syscalls+0x190>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	e2c080e7          	jalr	-468(ra) # 800005d6 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037b2:	40dc                	lw	a5,4(s1)
    800037b4:	0047d79b          	srliw	a5,a5,0x4
    800037b8:	0001d597          	auipc	a1,0x1d
    800037bc:	ea05a583          	lw	a1,-352(a1) # 80020658 <sb+0x18>
    800037c0:	9dbd                	addw	a1,a1,a5
    800037c2:	4088                	lw	a0,0(s1)
    800037c4:	fffff097          	auipc	ra,0xfffff
    800037c8:	7ac080e7          	jalr	1964(ra) # 80002f70 <bread>
    800037cc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ce:	05850593          	addi	a1,a0,88
    800037d2:	40dc                	lw	a5,4(s1)
    800037d4:	8bbd                	andi	a5,a5,15
    800037d6:	079a                	slli	a5,a5,0x6
    800037d8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037da:	00059783          	lh	a5,0(a1)
    800037de:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037e2:	00259783          	lh	a5,2(a1)
    800037e6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037ea:	00459783          	lh	a5,4(a1)
    800037ee:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037f2:	00659783          	lh	a5,6(a1)
    800037f6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037fa:	459c                	lw	a5,8(a1)
    800037fc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037fe:	03400613          	li	a2,52
    80003802:	05b1                	addi	a1,a1,12
    80003804:	05048513          	addi	a0,s1,80
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	5c8080e7          	jalr	1480(ra) # 80000dd0 <memmove>
    brelse(bp);
    80003810:	854a                	mv	a0,s2
    80003812:	00000097          	auipc	ra,0x0
    80003816:	88e080e7          	jalr	-1906(ra) # 800030a0 <brelse>
    ip->valid = 1;
    8000381a:	4785                	li	a5,1
    8000381c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000381e:	04449783          	lh	a5,68(s1)
    80003822:	fbb5                	bnez	a5,80003796 <ilock+0x24>
      panic("ilock: no type");
    80003824:	00005517          	auipc	a0,0x5
    80003828:	db450513          	addi	a0,a0,-588 # 800085d8 <syscalls+0x198>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	daa080e7          	jalr	-598(ra) # 800005d6 <panic>

0000000080003834 <iunlock>:
{
    80003834:	1101                	addi	sp,sp,-32
    80003836:	ec06                	sd	ra,24(sp)
    80003838:	e822                	sd	s0,16(sp)
    8000383a:	e426                	sd	s1,8(sp)
    8000383c:	e04a                	sd	s2,0(sp)
    8000383e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003840:	c905                	beqz	a0,80003870 <iunlock+0x3c>
    80003842:	84aa                	mv	s1,a0
    80003844:	01050913          	addi	s2,a0,16
    80003848:	854a                	mv	a0,s2
    8000384a:	00001097          	auipc	ra,0x1
    8000384e:	c7c080e7          	jalr	-900(ra) # 800044c6 <holdingsleep>
    80003852:	cd19                	beqz	a0,80003870 <iunlock+0x3c>
    80003854:	449c                	lw	a5,8(s1)
    80003856:	00f05d63          	blez	a5,80003870 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	c26080e7          	jalr	-986(ra) # 80004482 <releasesleep>
}
    80003864:	60e2                	ld	ra,24(sp)
    80003866:	6442                	ld	s0,16(sp)
    80003868:	64a2                	ld	s1,8(sp)
    8000386a:	6902                	ld	s2,0(sp)
    8000386c:	6105                	addi	sp,sp,32
    8000386e:	8082                	ret
    panic("iunlock");
    80003870:	00005517          	auipc	a0,0x5
    80003874:	d7850513          	addi	a0,a0,-648 # 800085e8 <syscalls+0x1a8>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	d5e080e7          	jalr	-674(ra) # 800005d6 <panic>

0000000080003880 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003880:	7179                	addi	sp,sp,-48
    80003882:	f406                	sd	ra,40(sp)
    80003884:	f022                	sd	s0,32(sp)
    80003886:	ec26                	sd	s1,24(sp)
    80003888:	e84a                	sd	s2,16(sp)
    8000388a:	e44e                	sd	s3,8(sp)
    8000388c:	e052                	sd	s4,0(sp)
    8000388e:	1800                	addi	s0,sp,48
    80003890:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003892:	05050493          	addi	s1,a0,80
    80003896:	08050913          	addi	s2,a0,128
    8000389a:	a021                	j	800038a2 <itrunc+0x22>
    8000389c:	0491                	addi	s1,s1,4
    8000389e:	01248d63          	beq	s1,s2,800038b8 <itrunc+0x38>
    if(ip->addrs[i]){
    800038a2:	408c                	lw	a1,0(s1)
    800038a4:	dde5                	beqz	a1,8000389c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038a6:	0009a503          	lw	a0,0(s3)
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	90c080e7          	jalr	-1780(ra) # 800031b6 <bfree>
      ip->addrs[i] = 0;
    800038b2:	0004a023          	sw	zero,0(s1)
    800038b6:	b7dd                	j	8000389c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038b8:	0809a583          	lw	a1,128(s3)
    800038bc:	e185                	bnez	a1,800038dc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038be:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038c2:	854e                	mv	a0,s3
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	de4080e7          	jalr	-540(ra) # 800036a8 <iupdate>
}
    800038cc:	70a2                	ld	ra,40(sp)
    800038ce:	7402                	ld	s0,32(sp)
    800038d0:	64e2                	ld	s1,24(sp)
    800038d2:	6942                	ld	s2,16(sp)
    800038d4:	69a2                	ld	s3,8(sp)
    800038d6:	6a02                	ld	s4,0(sp)
    800038d8:	6145                	addi	sp,sp,48
    800038da:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038dc:	0009a503          	lw	a0,0(s3)
    800038e0:	fffff097          	auipc	ra,0xfffff
    800038e4:	690080e7          	jalr	1680(ra) # 80002f70 <bread>
    800038e8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038ea:	05850493          	addi	s1,a0,88
    800038ee:	45850913          	addi	s2,a0,1112
    800038f2:	a811                	j	80003906 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038f4:	0009a503          	lw	a0,0(s3)
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	8be080e7          	jalr	-1858(ra) # 800031b6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003900:	0491                	addi	s1,s1,4
    80003902:	01248563          	beq	s1,s2,8000390c <itrunc+0x8c>
      if(a[j])
    80003906:	408c                	lw	a1,0(s1)
    80003908:	dde5                	beqz	a1,80003900 <itrunc+0x80>
    8000390a:	b7ed                	j	800038f4 <itrunc+0x74>
    brelse(bp);
    8000390c:	8552                	mv	a0,s4
    8000390e:	fffff097          	auipc	ra,0xfffff
    80003912:	792080e7          	jalr	1938(ra) # 800030a0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003916:	0809a583          	lw	a1,128(s3)
    8000391a:	0009a503          	lw	a0,0(s3)
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	898080e7          	jalr	-1896(ra) # 800031b6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003926:	0809a023          	sw	zero,128(s3)
    8000392a:	bf51                	j	800038be <itrunc+0x3e>

000000008000392c <iput>:
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	e426                	sd	s1,8(sp)
    80003934:	e04a                	sd	s2,0(sp)
    80003936:	1000                	addi	s0,sp,32
    80003938:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000393a:	0001d517          	auipc	a0,0x1d
    8000393e:	d2650513          	addi	a0,a0,-730 # 80020660 <icache>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	332080e7          	jalr	818(ra) # 80000c74 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394a:	4498                	lw	a4,8(s1)
    8000394c:	4785                	li	a5,1
    8000394e:	02f70363          	beq	a4,a5,80003974 <iput+0x48>
  ip->ref--;
    80003952:	449c                	lw	a5,8(s1)
    80003954:	37fd                	addiw	a5,a5,-1
    80003956:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003958:	0001d517          	auipc	a0,0x1d
    8000395c:	d0850513          	addi	a0,a0,-760 # 80020660 <icache>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	3c8080e7          	jalr	968(ra) # 80000d28 <release>
}
    80003968:	60e2                	ld	ra,24(sp)
    8000396a:	6442                	ld	s0,16(sp)
    8000396c:	64a2                	ld	s1,8(sp)
    8000396e:	6902                	ld	s2,0(sp)
    80003970:	6105                	addi	sp,sp,32
    80003972:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003974:	40bc                	lw	a5,64(s1)
    80003976:	dff1                	beqz	a5,80003952 <iput+0x26>
    80003978:	04a49783          	lh	a5,74(s1)
    8000397c:	fbf9                	bnez	a5,80003952 <iput+0x26>
    acquiresleep(&ip->lock);
    8000397e:	01048913          	addi	s2,s1,16
    80003982:	854a                	mv	a0,s2
    80003984:	00001097          	auipc	ra,0x1
    80003988:	aa8080e7          	jalr	-1368(ra) # 8000442c <acquiresleep>
    release(&icache.lock);
    8000398c:	0001d517          	auipc	a0,0x1d
    80003990:	cd450513          	addi	a0,a0,-812 # 80020660 <icache>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	394080e7          	jalr	916(ra) # 80000d28 <release>
    itrunc(ip);
    8000399c:	8526                	mv	a0,s1
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	ee2080e7          	jalr	-286(ra) # 80003880 <itrunc>
    ip->type = 0;
    800039a6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039aa:	8526                	mv	a0,s1
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	cfc080e7          	jalr	-772(ra) # 800036a8 <iupdate>
    ip->valid = 0;
    800039b4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	ac8080e7          	jalr	-1336(ra) # 80004482 <releasesleep>
    acquire(&icache.lock);
    800039c2:	0001d517          	auipc	a0,0x1d
    800039c6:	c9e50513          	addi	a0,a0,-866 # 80020660 <icache>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	2aa080e7          	jalr	682(ra) # 80000c74 <acquire>
    800039d2:	b741                	j	80003952 <iput+0x26>

00000000800039d4 <iunlockput>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	1000                	addi	s0,sp,32
    800039de:	84aa                	mv	s1,a0
  iunlock(ip);
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	e54080e7          	jalr	-428(ra) # 80003834 <iunlock>
  iput(ip);
    800039e8:	8526                	mv	a0,s1
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	f42080e7          	jalr	-190(ra) # 8000392c <iput>
}
    800039f2:	60e2                	ld	ra,24(sp)
    800039f4:	6442                	ld	s0,16(sp)
    800039f6:	64a2                	ld	s1,8(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret

00000000800039fc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039fc:	1141                	addi	sp,sp,-16
    800039fe:	e422                	sd	s0,8(sp)
    80003a00:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a02:	411c                	lw	a5,0(a0)
    80003a04:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a06:	415c                	lw	a5,4(a0)
    80003a08:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a0a:	04451783          	lh	a5,68(a0)
    80003a0e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a12:	04a51783          	lh	a5,74(a0)
    80003a16:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a1a:	04c56783          	lwu	a5,76(a0)
    80003a1e:	e99c                	sd	a5,16(a1)
}
    80003a20:	6422                	ld	s0,8(sp)
    80003a22:	0141                	addi	sp,sp,16
    80003a24:	8082                	ret

0000000080003a26 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a26:	457c                	lw	a5,76(a0)
    80003a28:	0ed7e863          	bltu	a5,a3,80003b18 <readi+0xf2>
{
    80003a2c:	7159                	addi	sp,sp,-112
    80003a2e:	f486                	sd	ra,104(sp)
    80003a30:	f0a2                	sd	s0,96(sp)
    80003a32:	eca6                	sd	s1,88(sp)
    80003a34:	e8ca                	sd	s2,80(sp)
    80003a36:	e4ce                	sd	s3,72(sp)
    80003a38:	e0d2                	sd	s4,64(sp)
    80003a3a:	fc56                	sd	s5,56(sp)
    80003a3c:	f85a                	sd	s6,48(sp)
    80003a3e:	f45e                	sd	s7,40(sp)
    80003a40:	f062                	sd	s8,32(sp)
    80003a42:	ec66                	sd	s9,24(sp)
    80003a44:	e86a                	sd	s10,16(sp)
    80003a46:	e46e                	sd	s11,8(sp)
    80003a48:	1880                	addi	s0,sp,112
    80003a4a:	8baa                	mv	s7,a0
    80003a4c:	8c2e                	mv	s8,a1
    80003a4e:	8ab2                	mv	s5,a2
    80003a50:	84b6                	mv	s1,a3
    80003a52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a54:	9f35                	addw	a4,a4,a3
    return 0;
    80003a56:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a58:	08d76f63          	bltu	a4,a3,80003af6 <readi+0xd0>
  if(off + n > ip->size)
    80003a5c:	00e7f463          	bgeu	a5,a4,80003a64 <readi+0x3e>
    n = ip->size - off;
    80003a60:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a64:	0a0b0863          	beqz	s6,80003b14 <readi+0xee>
    80003a68:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a6e:	5cfd                	li	s9,-1
    80003a70:	a82d                	j	80003aaa <readi+0x84>
    80003a72:	020a1d93          	slli	s11,s4,0x20
    80003a76:	020ddd93          	srli	s11,s11,0x20
    80003a7a:	05890613          	addi	a2,s2,88 # 80008608 <syscalls+0x1c8>
    80003a7e:	86ee                	mv	a3,s11
    80003a80:	963a                	add	a2,a2,a4
    80003a82:	85d6                	mv	a1,s5
    80003a84:	8562                	mv	a0,s8
    80003a86:	fffff097          	auipc	ra,0xfffff
    80003a8a:	a3a080e7          	jalr	-1478(ra) # 800024c0 <either_copyout>
    80003a8e:	05950d63          	beq	a0,s9,80003ae8 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a92:	854a                	mv	a0,s2
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	60c080e7          	jalr	1548(ra) # 800030a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9c:	013a09bb          	addw	s3,s4,s3
    80003aa0:	009a04bb          	addw	s1,s4,s1
    80003aa4:	9aee                	add	s5,s5,s11
    80003aa6:	0569f663          	bgeu	s3,s6,80003af2 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aaa:	000ba903          	lw	s2,0(s7)
    80003aae:	00a4d59b          	srliw	a1,s1,0xa
    80003ab2:	855e                	mv	a0,s7
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	8b0080e7          	jalr	-1872(ra) # 80003364 <bmap>
    80003abc:	0005059b          	sext.w	a1,a0
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	4ae080e7          	jalr	1198(ra) # 80002f70 <bread>
    80003aca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003acc:	3ff4f713          	andi	a4,s1,1023
    80003ad0:	40ed07bb          	subw	a5,s10,a4
    80003ad4:	413b06bb          	subw	a3,s6,s3
    80003ad8:	8a3e                	mv	s4,a5
    80003ada:	2781                	sext.w	a5,a5
    80003adc:	0006861b          	sext.w	a2,a3
    80003ae0:	f8f679e3          	bgeu	a2,a5,80003a72 <readi+0x4c>
    80003ae4:	8a36                	mv	s4,a3
    80003ae6:	b771                	j	80003a72 <readi+0x4c>
      brelse(bp);
    80003ae8:	854a                	mv	a0,s2
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	5b6080e7          	jalr	1462(ra) # 800030a0 <brelse>
  }
  return tot;
    80003af2:	0009851b          	sext.w	a0,s3
}
    80003af6:	70a6                	ld	ra,104(sp)
    80003af8:	7406                	ld	s0,96(sp)
    80003afa:	64e6                	ld	s1,88(sp)
    80003afc:	6946                	ld	s2,80(sp)
    80003afe:	69a6                	ld	s3,72(sp)
    80003b00:	6a06                	ld	s4,64(sp)
    80003b02:	7ae2                	ld	s5,56(sp)
    80003b04:	7b42                	ld	s6,48(sp)
    80003b06:	7ba2                	ld	s7,40(sp)
    80003b08:	7c02                	ld	s8,32(sp)
    80003b0a:	6ce2                	ld	s9,24(sp)
    80003b0c:	6d42                	ld	s10,16(sp)
    80003b0e:	6da2                	ld	s11,8(sp)
    80003b10:	6165                	addi	sp,sp,112
    80003b12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b14:	89da                	mv	s3,s6
    80003b16:	bff1                	j	80003af2 <readi+0xcc>
    return 0;
    80003b18:	4501                	li	a0,0
}
    80003b1a:	8082                	ret

0000000080003b1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b1c:	457c                	lw	a5,76(a0)
    80003b1e:	10d7e663          	bltu	a5,a3,80003c2a <writei+0x10e>
{
    80003b22:	7159                	addi	sp,sp,-112
    80003b24:	f486                	sd	ra,104(sp)
    80003b26:	f0a2                	sd	s0,96(sp)
    80003b28:	eca6                	sd	s1,88(sp)
    80003b2a:	e8ca                	sd	s2,80(sp)
    80003b2c:	e4ce                	sd	s3,72(sp)
    80003b2e:	e0d2                	sd	s4,64(sp)
    80003b30:	fc56                	sd	s5,56(sp)
    80003b32:	f85a                	sd	s6,48(sp)
    80003b34:	f45e                	sd	s7,40(sp)
    80003b36:	f062                	sd	s8,32(sp)
    80003b38:	ec66                	sd	s9,24(sp)
    80003b3a:	e86a                	sd	s10,16(sp)
    80003b3c:	e46e                	sd	s11,8(sp)
    80003b3e:	1880                	addi	s0,sp,112
    80003b40:	8baa                	mv	s7,a0
    80003b42:	8c2e                	mv	s8,a1
    80003b44:	8ab2                	mv	s5,a2
    80003b46:	8936                	mv	s2,a3
    80003b48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b4a:	00e687bb          	addw	a5,a3,a4
    80003b4e:	0ed7e063          	bltu	a5,a3,80003c2e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b52:	00043737          	lui	a4,0x43
    80003b56:	0cf76e63          	bltu	a4,a5,80003c32 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5a:	0a0b0763          	beqz	s6,80003c08 <writei+0xec>
    80003b5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b64:	5cfd                	li	s9,-1
    80003b66:	a091                	j	80003baa <writei+0x8e>
    80003b68:	02099d93          	slli	s11,s3,0x20
    80003b6c:	020ddd93          	srli	s11,s11,0x20
    80003b70:	05848513          	addi	a0,s1,88
    80003b74:	86ee                	mv	a3,s11
    80003b76:	8656                	mv	a2,s5
    80003b78:	85e2                	mv	a1,s8
    80003b7a:	953a                	add	a0,a0,a4
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	99a080e7          	jalr	-1638(ra) # 80002516 <either_copyin>
    80003b84:	07950263          	beq	a0,s9,80003be8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	77a080e7          	jalr	1914(ra) # 80004304 <log_write>
    brelse(bp);
    80003b92:	8526                	mv	a0,s1
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	50c080e7          	jalr	1292(ra) # 800030a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9c:	01498a3b          	addw	s4,s3,s4
    80003ba0:	0129893b          	addw	s2,s3,s2
    80003ba4:	9aee                	add	s5,s5,s11
    80003ba6:	056a7663          	bgeu	s4,s6,80003bf2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003baa:	000ba483          	lw	s1,0(s7)
    80003bae:	00a9559b          	srliw	a1,s2,0xa
    80003bb2:	855e                	mv	a0,s7
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	7b0080e7          	jalr	1968(ra) # 80003364 <bmap>
    80003bbc:	0005059b          	sext.w	a1,a0
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	3ae080e7          	jalr	942(ra) # 80002f70 <bread>
    80003bca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bcc:	3ff97713          	andi	a4,s2,1023
    80003bd0:	40ed07bb          	subw	a5,s10,a4
    80003bd4:	414b06bb          	subw	a3,s6,s4
    80003bd8:	89be                	mv	s3,a5
    80003bda:	2781                	sext.w	a5,a5
    80003bdc:	0006861b          	sext.w	a2,a3
    80003be0:	f8f674e3          	bgeu	a2,a5,80003b68 <writei+0x4c>
    80003be4:	89b6                	mv	s3,a3
    80003be6:	b749                	j	80003b68 <writei+0x4c>
      brelse(bp);
    80003be8:	8526                	mv	a0,s1
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	4b6080e7          	jalr	1206(ra) # 800030a0 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bf2:	04cba783          	lw	a5,76(s7)
    80003bf6:	0127f463          	bgeu	a5,s2,80003bfe <writei+0xe2>
      ip->size = off;
    80003bfa:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bfe:	855e                	mv	a0,s7
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	aa8080e7          	jalr	-1368(ra) # 800036a8 <iupdate>
  }

  return n;
    80003c08:	000b051b          	sext.w	a0,s6
}
    80003c0c:	70a6                	ld	ra,104(sp)
    80003c0e:	7406                	ld	s0,96(sp)
    80003c10:	64e6                	ld	s1,88(sp)
    80003c12:	6946                	ld	s2,80(sp)
    80003c14:	69a6                	ld	s3,72(sp)
    80003c16:	6a06                	ld	s4,64(sp)
    80003c18:	7ae2                	ld	s5,56(sp)
    80003c1a:	7b42                	ld	s6,48(sp)
    80003c1c:	7ba2                	ld	s7,40(sp)
    80003c1e:	7c02                	ld	s8,32(sp)
    80003c20:	6ce2                	ld	s9,24(sp)
    80003c22:	6d42                	ld	s10,16(sp)
    80003c24:	6da2                	ld	s11,8(sp)
    80003c26:	6165                	addi	sp,sp,112
    80003c28:	8082                	ret
    return -1;
    80003c2a:	557d                	li	a0,-1
}
    80003c2c:	8082                	ret
    return -1;
    80003c2e:	557d                	li	a0,-1
    80003c30:	bff1                	j	80003c0c <writei+0xf0>
    return -1;
    80003c32:	557d                	li	a0,-1
    80003c34:	bfe1                	j	80003c0c <writei+0xf0>

0000000080003c36 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c36:	1141                	addi	sp,sp,-16
    80003c38:	e406                	sd	ra,8(sp)
    80003c3a:	e022                	sd	s0,0(sp)
    80003c3c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c3e:	4639                	li	a2,14
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	20c080e7          	jalr	524(ra) # 80000e4c <strncmp>
}
    80003c48:	60a2                	ld	ra,8(sp)
    80003c4a:	6402                	ld	s0,0(sp)
    80003c4c:	0141                	addi	sp,sp,16
    80003c4e:	8082                	ret

0000000080003c50 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c50:	7139                	addi	sp,sp,-64
    80003c52:	fc06                	sd	ra,56(sp)
    80003c54:	f822                	sd	s0,48(sp)
    80003c56:	f426                	sd	s1,40(sp)
    80003c58:	f04a                	sd	s2,32(sp)
    80003c5a:	ec4e                	sd	s3,24(sp)
    80003c5c:	e852                	sd	s4,16(sp)
    80003c5e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c60:	04451703          	lh	a4,68(a0)
    80003c64:	4785                	li	a5,1
    80003c66:	00f71a63          	bne	a4,a5,80003c7a <dirlookup+0x2a>
    80003c6a:	892a                	mv	s2,a0
    80003c6c:	89ae                	mv	s3,a1
    80003c6e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c70:	457c                	lw	a5,76(a0)
    80003c72:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c74:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c76:	e79d                	bnez	a5,80003ca4 <dirlookup+0x54>
    80003c78:	a8a5                	j	80003cf0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c7a:	00005517          	auipc	a0,0x5
    80003c7e:	97650513          	addi	a0,a0,-1674 # 800085f0 <syscalls+0x1b0>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	954080e7          	jalr	-1708(ra) # 800005d6 <panic>
      panic("dirlookup read");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	97e50513          	addi	a0,a0,-1666 # 80008608 <syscalls+0x1c8>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	944080e7          	jalr	-1724(ra) # 800005d6 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9a:	24c1                	addiw	s1,s1,16
    80003c9c:	04c92783          	lw	a5,76(s2)
    80003ca0:	04f4f763          	bgeu	s1,a5,80003cee <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca4:	4741                	li	a4,16
    80003ca6:	86a6                	mv	a3,s1
    80003ca8:	fc040613          	addi	a2,s0,-64
    80003cac:	4581                	li	a1,0
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	d76080e7          	jalr	-650(ra) # 80003a26 <readi>
    80003cb8:	47c1                	li	a5,16
    80003cba:	fcf518e3          	bne	a0,a5,80003c8a <dirlookup+0x3a>
    if(de.inum == 0)
    80003cbe:	fc045783          	lhu	a5,-64(s0)
    80003cc2:	dfe1                	beqz	a5,80003c9a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc4:	fc240593          	addi	a1,s0,-62
    80003cc8:	854e                	mv	a0,s3
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	f6c080e7          	jalr	-148(ra) # 80003c36 <namecmp>
    80003cd2:	f561                	bnez	a0,80003c9a <dirlookup+0x4a>
      if(poff)
    80003cd4:	000a0463          	beqz	s4,80003cdc <dirlookup+0x8c>
        *poff = off;
    80003cd8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cdc:	fc045583          	lhu	a1,-64(s0)
    80003ce0:	00092503          	lw	a0,0(s2)
    80003ce4:	fffff097          	auipc	ra,0xfffff
    80003ce8:	75a080e7          	jalr	1882(ra) # 8000343e <iget>
    80003cec:	a011                	j	80003cf0 <dirlookup+0xa0>
  return 0;
    80003cee:	4501                	li	a0,0
}
    80003cf0:	70e2                	ld	ra,56(sp)
    80003cf2:	7442                	ld	s0,48(sp)
    80003cf4:	74a2                	ld	s1,40(sp)
    80003cf6:	7902                	ld	s2,32(sp)
    80003cf8:	69e2                	ld	s3,24(sp)
    80003cfa:	6a42                	ld	s4,16(sp)
    80003cfc:	6121                	addi	sp,sp,64
    80003cfe:	8082                	ret

0000000080003d00 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d00:	711d                	addi	sp,sp,-96
    80003d02:	ec86                	sd	ra,88(sp)
    80003d04:	e8a2                	sd	s0,80(sp)
    80003d06:	e4a6                	sd	s1,72(sp)
    80003d08:	e0ca                	sd	s2,64(sp)
    80003d0a:	fc4e                	sd	s3,56(sp)
    80003d0c:	f852                	sd	s4,48(sp)
    80003d0e:	f456                	sd	s5,40(sp)
    80003d10:	f05a                	sd	s6,32(sp)
    80003d12:	ec5e                	sd	s7,24(sp)
    80003d14:	e862                	sd	s8,16(sp)
    80003d16:	e466                	sd	s9,8(sp)
    80003d18:	1080                	addi	s0,sp,96
    80003d1a:	84aa                	mv	s1,a0
    80003d1c:	8b2e                	mv	s6,a1
    80003d1e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d20:	00054703          	lbu	a4,0(a0)
    80003d24:	02f00793          	li	a5,47
    80003d28:	02f70363          	beq	a4,a5,80003d4e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d2c:	ffffe097          	auipc	ra,0xffffe
    80003d30:	d16080e7          	jalr	-746(ra) # 80001a42 <myproc>
    80003d34:	15053503          	ld	a0,336(a0)
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	9fc080e7          	jalr	-1540(ra) # 80003734 <idup>
    80003d40:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d42:	02f00913          	li	s2,47
  len = path - s;
    80003d46:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d48:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d4a:	4c05                	li	s8,1
    80003d4c:	a865                	j	80003e04 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d4e:	4585                	li	a1,1
    80003d50:	4505                	li	a0,1
    80003d52:	fffff097          	auipc	ra,0xfffff
    80003d56:	6ec080e7          	jalr	1772(ra) # 8000343e <iget>
    80003d5a:	89aa                	mv	s3,a0
    80003d5c:	b7dd                	j	80003d42 <namex+0x42>
      iunlockput(ip);
    80003d5e:	854e                	mv	a0,s3
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	c74080e7          	jalr	-908(ra) # 800039d4 <iunlockput>
      return 0;
    80003d68:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d6a:	854e                	mv	a0,s3
    80003d6c:	60e6                	ld	ra,88(sp)
    80003d6e:	6446                	ld	s0,80(sp)
    80003d70:	64a6                	ld	s1,72(sp)
    80003d72:	6906                	ld	s2,64(sp)
    80003d74:	79e2                	ld	s3,56(sp)
    80003d76:	7a42                	ld	s4,48(sp)
    80003d78:	7aa2                	ld	s5,40(sp)
    80003d7a:	7b02                	ld	s6,32(sp)
    80003d7c:	6be2                	ld	s7,24(sp)
    80003d7e:	6c42                	ld	s8,16(sp)
    80003d80:	6ca2                	ld	s9,8(sp)
    80003d82:	6125                	addi	sp,sp,96
    80003d84:	8082                	ret
      iunlock(ip);
    80003d86:	854e                	mv	a0,s3
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	aac080e7          	jalr	-1364(ra) # 80003834 <iunlock>
      return ip;
    80003d90:	bfe9                	j	80003d6a <namex+0x6a>
      iunlockput(ip);
    80003d92:	854e                	mv	a0,s3
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	c40080e7          	jalr	-960(ra) # 800039d4 <iunlockput>
      return 0;
    80003d9c:	89d2                	mv	s3,s4
    80003d9e:	b7f1                	j	80003d6a <namex+0x6a>
  len = path - s;
    80003da0:	40b48633          	sub	a2,s1,a1
    80003da4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003da8:	094cd463          	bge	s9,s4,80003e30 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dac:	4639                	li	a2,14
    80003dae:	8556                	mv	a0,s5
    80003db0:	ffffd097          	auipc	ra,0xffffd
    80003db4:	020080e7          	jalr	32(ra) # 80000dd0 <memmove>
  while(*path == '/')
    80003db8:	0004c783          	lbu	a5,0(s1)
    80003dbc:	01279763          	bne	a5,s2,80003dca <namex+0xca>
    path++;
    80003dc0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc2:	0004c783          	lbu	a5,0(s1)
    80003dc6:	ff278de3          	beq	a5,s2,80003dc0 <namex+0xc0>
    ilock(ip);
    80003dca:	854e                	mv	a0,s3
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	9a6080e7          	jalr	-1626(ra) # 80003772 <ilock>
    if(ip->type != T_DIR){
    80003dd4:	04499783          	lh	a5,68(s3)
    80003dd8:	f98793e3          	bne	a5,s8,80003d5e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ddc:	000b0563          	beqz	s6,80003de6 <namex+0xe6>
    80003de0:	0004c783          	lbu	a5,0(s1)
    80003de4:	d3cd                	beqz	a5,80003d86 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003de6:	865e                	mv	a2,s7
    80003de8:	85d6                	mv	a1,s5
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	e64080e7          	jalr	-412(ra) # 80003c50 <dirlookup>
    80003df4:	8a2a                	mv	s4,a0
    80003df6:	dd51                	beqz	a0,80003d92 <namex+0x92>
    iunlockput(ip);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	bda080e7          	jalr	-1062(ra) # 800039d4 <iunlockput>
    ip = next;
    80003e02:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	05279763          	bne	a5,s2,80003e56 <namex+0x156>
    path++;
    80003e0c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	ff278de3          	beq	a5,s2,80003e0c <namex+0x10c>
  if(*path == 0)
    80003e16:	c79d                	beqz	a5,80003e44 <namex+0x144>
    path++;
    80003e18:	85a6                	mv	a1,s1
  len = path - s;
    80003e1a:	8a5e                	mv	s4,s7
    80003e1c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e1e:	01278963          	beq	a5,s2,80003e30 <namex+0x130>
    80003e22:	dfbd                	beqz	a5,80003da0 <namex+0xa0>
    path++;
    80003e24:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	ff279ce3          	bne	a5,s2,80003e22 <namex+0x122>
    80003e2e:	bf8d                	j	80003da0 <namex+0xa0>
    memmove(name, s, len);
    80003e30:	2601                	sext.w	a2,a2
    80003e32:	8556                	mv	a0,s5
    80003e34:	ffffd097          	auipc	ra,0xffffd
    80003e38:	f9c080e7          	jalr	-100(ra) # 80000dd0 <memmove>
    name[len] = 0;
    80003e3c:	9a56                	add	s4,s4,s5
    80003e3e:	000a0023          	sb	zero,0(s4)
    80003e42:	bf9d                	j	80003db8 <namex+0xb8>
  if(nameiparent){
    80003e44:	f20b03e3          	beqz	s6,80003d6a <namex+0x6a>
    iput(ip);
    80003e48:	854e                	mv	a0,s3
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	ae2080e7          	jalr	-1310(ra) # 8000392c <iput>
    return 0;
    80003e52:	4981                	li	s3,0
    80003e54:	bf19                	j	80003d6a <namex+0x6a>
  if(*path == 0)
    80003e56:	d7fd                	beqz	a5,80003e44 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	85a6                	mv	a1,s1
    80003e5e:	b7d1                	j	80003e22 <namex+0x122>

0000000080003e60 <dirlink>:
{
    80003e60:	7139                	addi	sp,sp,-64
    80003e62:	fc06                	sd	ra,56(sp)
    80003e64:	f822                	sd	s0,48(sp)
    80003e66:	f426                	sd	s1,40(sp)
    80003e68:	f04a                	sd	s2,32(sp)
    80003e6a:	ec4e                	sd	s3,24(sp)
    80003e6c:	e852                	sd	s4,16(sp)
    80003e6e:	0080                	addi	s0,sp,64
    80003e70:	892a                	mv	s2,a0
    80003e72:	8a2e                	mv	s4,a1
    80003e74:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e76:	4601                	li	a2,0
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	dd8080e7          	jalr	-552(ra) # 80003c50 <dirlookup>
    80003e80:	e93d                	bnez	a0,80003ef6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e82:	04c92483          	lw	s1,76(s2)
    80003e86:	c49d                	beqz	s1,80003eb4 <dirlink+0x54>
    80003e88:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8a:	4741                	li	a4,16
    80003e8c:	86a6                	mv	a3,s1
    80003e8e:	fc040613          	addi	a2,s0,-64
    80003e92:	4581                	li	a1,0
    80003e94:	854a                	mv	a0,s2
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	b90080e7          	jalr	-1136(ra) # 80003a26 <readi>
    80003e9e:	47c1                	li	a5,16
    80003ea0:	06f51163          	bne	a0,a5,80003f02 <dirlink+0xa2>
    if(de.inum == 0)
    80003ea4:	fc045783          	lhu	a5,-64(s0)
    80003ea8:	c791                	beqz	a5,80003eb4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eaa:	24c1                	addiw	s1,s1,16
    80003eac:	04c92783          	lw	a5,76(s2)
    80003eb0:	fcf4ede3          	bltu	s1,a5,80003e8a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eb4:	4639                	li	a2,14
    80003eb6:	85d2                	mv	a1,s4
    80003eb8:	fc240513          	addi	a0,s0,-62
    80003ebc:	ffffd097          	auipc	ra,0xffffd
    80003ec0:	fcc080e7          	jalr	-52(ra) # 80000e88 <strncpy>
  de.inum = inum;
    80003ec4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec8:	4741                	li	a4,16
    80003eca:	86a6                	mv	a3,s1
    80003ecc:	fc040613          	addi	a2,s0,-64
    80003ed0:	4581                	li	a1,0
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	c48080e7          	jalr	-952(ra) # 80003b1c <writei>
    80003edc:	872a                	mv	a4,a0
    80003ede:	47c1                	li	a5,16
  return 0;
    80003ee0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee2:	02f71863          	bne	a4,a5,80003f12 <dirlink+0xb2>
}
    80003ee6:	70e2                	ld	ra,56(sp)
    80003ee8:	7442                	ld	s0,48(sp)
    80003eea:	74a2                	ld	s1,40(sp)
    80003eec:	7902                	ld	s2,32(sp)
    80003eee:	69e2                	ld	s3,24(sp)
    80003ef0:	6a42                	ld	s4,16(sp)
    80003ef2:	6121                	addi	sp,sp,64
    80003ef4:	8082                	ret
    iput(ip);
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	a36080e7          	jalr	-1482(ra) # 8000392c <iput>
    return -1;
    80003efe:	557d                	li	a0,-1
    80003f00:	b7dd                	j	80003ee6 <dirlink+0x86>
      panic("dirlink read");
    80003f02:	00004517          	auipc	a0,0x4
    80003f06:	71650513          	addi	a0,a0,1814 # 80008618 <syscalls+0x1d8>
    80003f0a:	ffffc097          	auipc	ra,0xffffc
    80003f0e:	6cc080e7          	jalr	1740(ra) # 800005d6 <panic>
    panic("dirlink");
    80003f12:	00005517          	auipc	a0,0x5
    80003f16:	82650513          	addi	a0,a0,-2010 # 80008738 <syscalls+0x2f8>
    80003f1a:	ffffc097          	auipc	ra,0xffffc
    80003f1e:	6bc080e7          	jalr	1724(ra) # 800005d6 <panic>

0000000080003f22 <namei>:

struct inode*
namei(char *path)
{
    80003f22:	1101                	addi	sp,sp,-32
    80003f24:	ec06                	sd	ra,24(sp)
    80003f26:	e822                	sd	s0,16(sp)
    80003f28:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f2a:	fe040613          	addi	a2,s0,-32
    80003f2e:	4581                	li	a1,0
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	dd0080e7          	jalr	-560(ra) # 80003d00 <namex>
}
    80003f38:	60e2                	ld	ra,24(sp)
    80003f3a:	6442                	ld	s0,16(sp)
    80003f3c:	6105                	addi	sp,sp,32
    80003f3e:	8082                	ret

0000000080003f40 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f40:	1141                	addi	sp,sp,-16
    80003f42:	e406                	sd	ra,8(sp)
    80003f44:	e022                	sd	s0,0(sp)
    80003f46:	0800                	addi	s0,sp,16
    80003f48:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f4a:	4585                	li	a1,1
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	db4080e7          	jalr	-588(ra) # 80003d00 <namex>
}
    80003f54:	60a2                	ld	ra,8(sp)
    80003f56:	6402                	ld	s0,0(sp)
    80003f58:	0141                	addi	sp,sp,16
    80003f5a:	8082                	ret

0000000080003f5c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f5c:	1101                	addi	sp,sp,-32
    80003f5e:	ec06                	sd	ra,24(sp)
    80003f60:	e822                	sd	s0,16(sp)
    80003f62:	e426                	sd	s1,8(sp)
    80003f64:	e04a                	sd	s2,0(sp)
    80003f66:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f68:	0001e917          	auipc	s2,0x1e
    80003f6c:	1a090913          	addi	s2,s2,416 # 80022108 <log>
    80003f70:	01892583          	lw	a1,24(s2)
    80003f74:	02892503          	lw	a0,40(s2)
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	ff8080e7          	jalr	-8(ra) # 80002f70 <bread>
    80003f80:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f82:	02c92683          	lw	a3,44(s2)
    80003f86:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f88:	02d05763          	blez	a3,80003fb6 <write_head+0x5a>
    80003f8c:	0001e797          	auipc	a5,0x1e
    80003f90:	1ac78793          	addi	a5,a5,428 # 80022138 <log+0x30>
    80003f94:	05c50713          	addi	a4,a0,92
    80003f98:	36fd                	addiw	a3,a3,-1
    80003f9a:	1682                	slli	a3,a3,0x20
    80003f9c:	9281                	srli	a3,a3,0x20
    80003f9e:	068a                	slli	a3,a3,0x2
    80003fa0:	0001e617          	auipc	a2,0x1e
    80003fa4:	19c60613          	addi	a2,a2,412 # 8002213c <log+0x34>
    80003fa8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003faa:	4390                	lw	a2,0(a5)
    80003fac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fae:	0791                	addi	a5,a5,4
    80003fb0:	0711                	addi	a4,a4,4
    80003fb2:	fed79ce3          	bne	a5,a3,80003faa <write_head+0x4e>
  }
  bwrite(buf);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	0aa080e7          	jalr	170(ra) # 80003062 <bwrite>
  brelse(buf);
    80003fc0:	8526                	mv	a0,s1
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	0de080e7          	jalr	222(ra) # 800030a0 <brelse>
}
    80003fca:	60e2                	ld	ra,24(sp)
    80003fcc:	6442                	ld	s0,16(sp)
    80003fce:	64a2                	ld	s1,8(sp)
    80003fd0:	6902                	ld	s2,0(sp)
    80003fd2:	6105                	addi	sp,sp,32
    80003fd4:	8082                	ret

0000000080003fd6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd6:	0001e797          	auipc	a5,0x1e
    80003fda:	15e7a783          	lw	a5,350(a5) # 80022134 <log+0x2c>
    80003fde:	0af05663          	blez	a5,8000408a <install_trans+0xb4>
{
    80003fe2:	7139                	addi	sp,sp,-64
    80003fe4:	fc06                	sd	ra,56(sp)
    80003fe6:	f822                	sd	s0,48(sp)
    80003fe8:	f426                	sd	s1,40(sp)
    80003fea:	f04a                	sd	s2,32(sp)
    80003fec:	ec4e                	sd	s3,24(sp)
    80003fee:	e852                	sd	s4,16(sp)
    80003ff0:	e456                	sd	s5,8(sp)
    80003ff2:	0080                	addi	s0,sp,64
    80003ff4:	0001ea97          	auipc	s5,0x1e
    80003ff8:	144a8a93          	addi	s5,s5,324 # 80022138 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ffe:	0001e997          	auipc	s3,0x1e
    80004002:	10a98993          	addi	s3,s3,266 # 80022108 <log>
    80004006:	0189a583          	lw	a1,24(s3)
    8000400a:	014585bb          	addw	a1,a1,s4
    8000400e:	2585                	addiw	a1,a1,1
    80004010:	0289a503          	lw	a0,40(s3)
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	f5c080e7          	jalr	-164(ra) # 80002f70 <bread>
    8000401c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401e:	000aa583          	lw	a1,0(s5)
    80004022:	0289a503          	lw	a0,40(s3)
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	f4a080e7          	jalr	-182(ra) # 80002f70 <bread>
    8000402e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004030:	40000613          	li	a2,1024
    80004034:	05890593          	addi	a1,s2,88
    80004038:	05850513          	addi	a0,a0,88
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	d94080e7          	jalr	-620(ra) # 80000dd0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004044:	8526                	mv	a0,s1
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	01c080e7          	jalr	28(ra) # 80003062 <bwrite>
    bunpin(dbuf);
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	12a080e7          	jalr	298(ra) # 8000317a <bunpin>
    brelse(lbuf);
    80004058:	854a                	mv	a0,s2
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	046080e7          	jalr	70(ra) # 800030a0 <brelse>
    brelse(dbuf);
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	03c080e7          	jalr	60(ra) # 800030a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000406c:	2a05                	addiw	s4,s4,1
    8000406e:	0a91                	addi	s5,s5,4
    80004070:	02c9a783          	lw	a5,44(s3)
    80004074:	f8fa49e3          	blt	s4,a5,80004006 <install_trans+0x30>
}
    80004078:	70e2                	ld	ra,56(sp)
    8000407a:	7442                	ld	s0,48(sp)
    8000407c:	74a2                	ld	s1,40(sp)
    8000407e:	7902                	ld	s2,32(sp)
    80004080:	69e2                	ld	s3,24(sp)
    80004082:	6a42                	ld	s4,16(sp)
    80004084:	6aa2                	ld	s5,8(sp)
    80004086:	6121                	addi	sp,sp,64
    80004088:	8082                	ret
    8000408a:	8082                	ret

000000008000408c <initlog>:
{
    8000408c:	7179                	addi	sp,sp,-48
    8000408e:	f406                	sd	ra,40(sp)
    80004090:	f022                	sd	s0,32(sp)
    80004092:	ec26                	sd	s1,24(sp)
    80004094:	e84a                	sd	s2,16(sp)
    80004096:	e44e                	sd	s3,8(sp)
    80004098:	1800                	addi	s0,sp,48
    8000409a:	892a                	mv	s2,a0
    8000409c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000409e:	0001e497          	auipc	s1,0x1e
    800040a2:	06a48493          	addi	s1,s1,106 # 80022108 <log>
    800040a6:	00004597          	auipc	a1,0x4
    800040aa:	58258593          	addi	a1,a1,1410 # 80008628 <syscalls+0x1e8>
    800040ae:	8526                	mv	a0,s1
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	b34080e7          	jalr	-1228(ra) # 80000be4 <initlock>
  log.start = sb->logstart;
    800040b8:	0149a583          	lw	a1,20(s3)
    800040bc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040be:	0109a783          	lw	a5,16(s3)
    800040c2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040c4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040c8:	854a                	mv	a0,s2
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	ea6080e7          	jalr	-346(ra) # 80002f70 <bread>
  log.lh.n = lh->n;
    800040d2:	4d3c                	lw	a5,88(a0)
    800040d4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040d6:	02f05563          	blez	a5,80004100 <initlog+0x74>
    800040da:	05c50713          	addi	a4,a0,92
    800040de:	0001e697          	auipc	a3,0x1e
    800040e2:	05a68693          	addi	a3,a3,90 # 80022138 <log+0x30>
    800040e6:	37fd                	addiw	a5,a5,-1
    800040e8:	1782                	slli	a5,a5,0x20
    800040ea:	9381                	srli	a5,a5,0x20
    800040ec:	078a                	slli	a5,a5,0x2
    800040ee:	06050613          	addi	a2,a0,96
    800040f2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040f4:	4310                	lw	a2,0(a4)
    800040f6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040f8:	0711                	addi	a4,a4,4
    800040fa:	0691                	addi	a3,a3,4
    800040fc:	fef71ce3          	bne	a4,a5,800040f4 <initlog+0x68>
  brelse(buf);
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	fa0080e7          	jalr	-96(ra) # 800030a0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	ece080e7          	jalr	-306(ra) # 80003fd6 <install_trans>
  log.lh.n = 0;
    80004110:	0001e797          	auipc	a5,0x1e
    80004114:	0207a223          	sw	zero,36(a5) # 80022134 <log+0x2c>
  write_head(); // clear the log
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	e44080e7          	jalr	-444(ra) # 80003f5c <write_head>
}
    80004120:	70a2                	ld	ra,40(sp)
    80004122:	7402                	ld	s0,32(sp)
    80004124:	64e2                	ld	s1,24(sp)
    80004126:	6942                	ld	s2,16(sp)
    80004128:	69a2                	ld	s3,8(sp)
    8000412a:	6145                	addi	sp,sp,48
    8000412c:	8082                	ret

000000008000412e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000412e:	1101                	addi	sp,sp,-32
    80004130:	ec06                	sd	ra,24(sp)
    80004132:	e822                	sd	s0,16(sp)
    80004134:	e426                	sd	s1,8(sp)
    80004136:	e04a                	sd	s2,0(sp)
    80004138:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000413a:	0001e517          	auipc	a0,0x1e
    8000413e:	fce50513          	addi	a0,a0,-50 # 80022108 <log>
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	b32080e7          	jalr	-1230(ra) # 80000c74 <acquire>
  while(1){
    if(log.committing){
    8000414a:	0001e497          	auipc	s1,0x1e
    8000414e:	fbe48493          	addi	s1,s1,-66 # 80022108 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004152:	4979                	li	s2,30
    80004154:	a039                	j	80004162 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004156:	85a6                	mv	a1,s1
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffe097          	auipc	ra,0xffffe
    8000415e:	104080e7          	jalr	260(ra) # 8000225e <sleep>
    if(log.committing){
    80004162:	50dc                	lw	a5,36(s1)
    80004164:	fbed                	bnez	a5,80004156 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004166:	509c                	lw	a5,32(s1)
    80004168:	0017871b          	addiw	a4,a5,1
    8000416c:	0007069b          	sext.w	a3,a4
    80004170:	0027179b          	slliw	a5,a4,0x2
    80004174:	9fb9                	addw	a5,a5,a4
    80004176:	0017979b          	slliw	a5,a5,0x1
    8000417a:	54d8                	lw	a4,44(s1)
    8000417c:	9fb9                	addw	a5,a5,a4
    8000417e:	00f95963          	bge	s2,a5,80004190 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004182:	85a6                	mv	a1,s1
    80004184:	8526                	mv	a0,s1
    80004186:	ffffe097          	auipc	ra,0xffffe
    8000418a:	0d8080e7          	jalr	216(ra) # 8000225e <sleep>
    8000418e:	bfd1                	j	80004162 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004190:	0001e517          	auipc	a0,0x1e
    80004194:	f7850513          	addi	a0,a0,-136 # 80022108 <log>
    80004198:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	b8e080e7          	jalr	-1138(ra) # 80000d28 <release>
      break;
    }
  }
}
    800041a2:	60e2                	ld	ra,24(sp)
    800041a4:	6442                	ld	s0,16(sp)
    800041a6:	64a2                	ld	s1,8(sp)
    800041a8:	6902                	ld	s2,0(sp)
    800041aa:	6105                	addi	sp,sp,32
    800041ac:	8082                	ret

00000000800041ae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041ae:	7139                	addi	sp,sp,-64
    800041b0:	fc06                	sd	ra,56(sp)
    800041b2:	f822                	sd	s0,48(sp)
    800041b4:	f426                	sd	s1,40(sp)
    800041b6:	f04a                	sd	s2,32(sp)
    800041b8:	ec4e                	sd	s3,24(sp)
    800041ba:	e852                	sd	s4,16(sp)
    800041bc:	e456                	sd	s5,8(sp)
    800041be:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041c0:	0001e497          	auipc	s1,0x1e
    800041c4:	f4848493          	addi	s1,s1,-184 # 80022108 <log>
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffd097          	auipc	ra,0xffffd
    800041ce:	aaa080e7          	jalr	-1366(ra) # 80000c74 <acquire>
  log.outstanding -= 1;
    800041d2:	509c                	lw	a5,32(s1)
    800041d4:	37fd                	addiw	a5,a5,-1
    800041d6:	0007891b          	sext.w	s2,a5
    800041da:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041dc:	50dc                	lw	a5,36(s1)
    800041de:	efb9                	bnez	a5,8000423c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041e0:	06091663          	bnez	s2,8000424c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041e4:	0001e497          	auipc	s1,0x1e
    800041e8:	f2448493          	addi	s1,s1,-220 # 80022108 <log>
    800041ec:	4785                	li	a5,1
    800041ee:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041f0:	8526                	mv	a0,s1
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	b36080e7          	jalr	-1226(ra) # 80000d28 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041fa:	54dc                	lw	a5,44(s1)
    800041fc:	06f04763          	bgtz	a5,8000426a <end_op+0xbc>
    acquire(&log.lock);
    80004200:	0001e497          	auipc	s1,0x1e
    80004204:	f0848493          	addi	s1,s1,-248 # 80022108 <log>
    80004208:	8526                	mv	a0,s1
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	a6a080e7          	jalr	-1430(ra) # 80000c74 <acquire>
    log.committing = 0;
    80004212:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004216:	8526                	mv	a0,s1
    80004218:	ffffe097          	auipc	ra,0xffffe
    8000421c:	1cc080e7          	jalr	460(ra) # 800023e4 <wakeup>
    release(&log.lock);
    80004220:	8526                	mv	a0,s1
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	b06080e7          	jalr	-1274(ra) # 80000d28 <release>
}
    8000422a:	70e2                	ld	ra,56(sp)
    8000422c:	7442                	ld	s0,48(sp)
    8000422e:	74a2                	ld	s1,40(sp)
    80004230:	7902                	ld	s2,32(sp)
    80004232:	69e2                	ld	s3,24(sp)
    80004234:	6a42                	ld	s4,16(sp)
    80004236:	6aa2                	ld	s5,8(sp)
    80004238:	6121                	addi	sp,sp,64
    8000423a:	8082                	ret
    panic("log.committing");
    8000423c:	00004517          	auipc	a0,0x4
    80004240:	3f450513          	addi	a0,a0,1012 # 80008630 <syscalls+0x1f0>
    80004244:	ffffc097          	auipc	ra,0xffffc
    80004248:	392080e7          	jalr	914(ra) # 800005d6 <panic>
    wakeup(&log);
    8000424c:	0001e497          	auipc	s1,0x1e
    80004250:	ebc48493          	addi	s1,s1,-324 # 80022108 <log>
    80004254:	8526                	mv	a0,s1
    80004256:	ffffe097          	auipc	ra,0xffffe
    8000425a:	18e080e7          	jalr	398(ra) # 800023e4 <wakeup>
  release(&log.lock);
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	ac8080e7          	jalr	-1336(ra) # 80000d28 <release>
  if(do_commit){
    80004268:	b7c9                	j	8000422a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426a:	0001ea97          	auipc	s5,0x1e
    8000426e:	ecea8a93          	addi	s5,s5,-306 # 80022138 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004272:	0001ea17          	auipc	s4,0x1e
    80004276:	e96a0a13          	addi	s4,s4,-362 # 80022108 <log>
    8000427a:	018a2583          	lw	a1,24(s4)
    8000427e:	012585bb          	addw	a1,a1,s2
    80004282:	2585                	addiw	a1,a1,1
    80004284:	028a2503          	lw	a0,40(s4)
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	ce8080e7          	jalr	-792(ra) # 80002f70 <bread>
    80004290:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004292:	000aa583          	lw	a1,0(s5)
    80004296:	028a2503          	lw	a0,40(s4)
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	cd6080e7          	jalr	-810(ra) # 80002f70 <bread>
    800042a2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042a4:	40000613          	li	a2,1024
    800042a8:	05850593          	addi	a1,a0,88
    800042ac:	05848513          	addi	a0,s1,88
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	b20080e7          	jalr	-1248(ra) # 80000dd0 <memmove>
    bwrite(to);  // write the log
    800042b8:	8526                	mv	a0,s1
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	da8080e7          	jalr	-600(ra) # 80003062 <bwrite>
    brelse(from);
    800042c2:	854e                	mv	a0,s3
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	ddc080e7          	jalr	-548(ra) # 800030a0 <brelse>
    brelse(to);
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	dd2080e7          	jalr	-558(ra) # 800030a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d6:	2905                	addiw	s2,s2,1
    800042d8:	0a91                	addi	s5,s5,4
    800042da:	02ca2783          	lw	a5,44(s4)
    800042de:	f8f94ee3          	blt	s2,a5,8000427a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	c7a080e7          	jalr	-902(ra) # 80003f5c <write_head>
    install_trans(); // Now install writes to home locations
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	cec080e7          	jalr	-788(ra) # 80003fd6 <install_trans>
    log.lh.n = 0;
    800042f2:	0001e797          	auipc	a5,0x1e
    800042f6:	e407a123          	sw	zero,-446(a5) # 80022134 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	c62080e7          	jalr	-926(ra) # 80003f5c <write_head>
    80004302:	bdfd                	j	80004200 <end_op+0x52>

0000000080004304 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004304:	1101                	addi	sp,sp,-32
    80004306:	ec06                	sd	ra,24(sp)
    80004308:	e822                	sd	s0,16(sp)
    8000430a:	e426                	sd	s1,8(sp)
    8000430c:	e04a                	sd	s2,0(sp)
    8000430e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004310:	0001e717          	auipc	a4,0x1e
    80004314:	e2472703          	lw	a4,-476(a4) # 80022134 <log+0x2c>
    80004318:	47f5                	li	a5,29
    8000431a:	08e7c063          	blt	a5,a4,8000439a <log_write+0x96>
    8000431e:	84aa                	mv	s1,a0
    80004320:	0001e797          	auipc	a5,0x1e
    80004324:	e047a783          	lw	a5,-508(a5) # 80022124 <log+0x1c>
    80004328:	37fd                	addiw	a5,a5,-1
    8000432a:	06f75863          	bge	a4,a5,8000439a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000432e:	0001e797          	auipc	a5,0x1e
    80004332:	dfa7a783          	lw	a5,-518(a5) # 80022128 <log+0x20>
    80004336:	06f05a63          	blez	a5,800043aa <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000433a:	0001e917          	auipc	s2,0x1e
    8000433e:	dce90913          	addi	s2,s2,-562 # 80022108 <log>
    80004342:	854a                	mv	a0,s2
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	930080e7          	jalr	-1744(ra) # 80000c74 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000434c:	02c92603          	lw	a2,44(s2)
    80004350:	06c05563          	blez	a2,800043ba <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004354:	44cc                	lw	a1,12(s1)
    80004356:	0001e717          	auipc	a4,0x1e
    8000435a:	de270713          	addi	a4,a4,-542 # 80022138 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000435e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004360:	4314                	lw	a3,0(a4)
    80004362:	04b68d63          	beq	a3,a1,800043bc <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004366:	2785                	addiw	a5,a5,1
    80004368:	0711                	addi	a4,a4,4
    8000436a:	fec79be3          	bne	a5,a2,80004360 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000436e:	0621                	addi	a2,a2,8
    80004370:	060a                	slli	a2,a2,0x2
    80004372:	0001e797          	auipc	a5,0x1e
    80004376:	d9678793          	addi	a5,a5,-618 # 80022108 <log>
    8000437a:	963e                	add	a2,a2,a5
    8000437c:	44dc                	lw	a5,12(s1)
    8000437e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004380:	8526                	mv	a0,s1
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	dbc080e7          	jalr	-580(ra) # 8000313e <bpin>
    log.lh.n++;
    8000438a:	0001e717          	auipc	a4,0x1e
    8000438e:	d7e70713          	addi	a4,a4,-642 # 80022108 <log>
    80004392:	575c                	lw	a5,44(a4)
    80004394:	2785                	addiw	a5,a5,1
    80004396:	d75c                	sw	a5,44(a4)
    80004398:	a83d                	j	800043d6 <log_write+0xd2>
    panic("too big a transaction");
    8000439a:	00004517          	auipc	a0,0x4
    8000439e:	2a650513          	addi	a0,a0,678 # 80008640 <syscalls+0x200>
    800043a2:	ffffc097          	auipc	ra,0xffffc
    800043a6:	234080e7          	jalr	564(ra) # 800005d6 <panic>
    panic("log_write outside of trans");
    800043aa:	00004517          	auipc	a0,0x4
    800043ae:	2ae50513          	addi	a0,a0,686 # 80008658 <syscalls+0x218>
    800043b2:	ffffc097          	auipc	ra,0xffffc
    800043b6:	224080e7          	jalr	548(ra) # 800005d6 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043ba:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043bc:	00878713          	addi	a4,a5,8
    800043c0:	00271693          	slli	a3,a4,0x2
    800043c4:	0001e717          	auipc	a4,0x1e
    800043c8:	d4470713          	addi	a4,a4,-700 # 80022108 <log>
    800043cc:	9736                	add	a4,a4,a3
    800043ce:	44d4                	lw	a3,12(s1)
    800043d0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043d2:	faf607e3          	beq	a2,a5,80004380 <log_write+0x7c>
  }
  release(&log.lock);
    800043d6:	0001e517          	auipc	a0,0x1e
    800043da:	d3250513          	addi	a0,a0,-718 # 80022108 <log>
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	94a080e7          	jalr	-1718(ra) # 80000d28 <release>
}
    800043e6:	60e2                	ld	ra,24(sp)
    800043e8:	6442                	ld	s0,16(sp)
    800043ea:	64a2                	ld	s1,8(sp)
    800043ec:	6902                	ld	s2,0(sp)
    800043ee:	6105                	addi	sp,sp,32
    800043f0:	8082                	ret

00000000800043f2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043f2:	1101                	addi	sp,sp,-32
    800043f4:	ec06                	sd	ra,24(sp)
    800043f6:	e822                	sd	s0,16(sp)
    800043f8:	e426                	sd	s1,8(sp)
    800043fa:	e04a                	sd	s2,0(sp)
    800043fc:	1000                	addi	s0,sp,32
    800043fe:	84aa                	mv	s1,a0
    80004400:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004402:	00004597          	auipc	a1,0x4
    80004406:	27658593          	addi	a1,a1,630 # 80008678 <syscalls+0x238>
    8000440a:	0521                	addi	a0,a0,8
    8000440c:	ffffc097          	auipc	ra,0xffffc
    80004410:	7d8080e7          	jalr	2008(ra) # 80000be4 <initlock>
  lk->name = name;
    80004414:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004418:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000441c:	0204a423          	sw	zero,40(s1)
}
    80004420:	60e2                	ld	ra,24(sp)
    80004422:	6442                	ld	s0,16(sp)
    80004424:	64a2                	ld	s1,8(sp)
    80004426:	6902                	ld	s2,0(sp)
    80004428:	6105                	addi	sp,sp,32
    8000442a:	8082                	ret

000000008000442c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000442c:	1101                	addi	sp,sp,-32
    8000442e:	ec06                	sd	ra,24(sp)
    80004430:	e822                	sd	s0,16(sp)
    80004432:	e426                	sd	s1,8(sp)
    80004434:	e04a                	sd	s2,0(sp)
    80004436:	1000                	addi	s0,sp,32
    80004438:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000443a:	00850913          	addi	s2,a0,8
    8000443e:	854a                	mv	a0,s2
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	834080e7          	jalr	-1996(ra) # 80000c74 <acquire>
  while (lk->locked) {
    80004448:	409c                	lw	a5,0(s1)
    8000444a:	cb89                	beqz	a5,8000445c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000444c:	85ca                	mv	a1,s2
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffe097          	auipc	ra,0xffffe
    80004454:	e0e080e7          	jalr	-498(ra) # 8000225e <sleep>
  while (lk->locked) {
    80004458:	409c                	lw	a5,0(s1)
    8000445a:	fbed                	bnez	a5,8000444c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000445c:	4785                	li	a5,1
    8000445e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	5e2080e7          	jalr	1506(ra) # 80001a42 <myproc>
    80004468:	5d1c                	lw	a5,56(a0)
    8000446a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000446c:	854a                	mv	a0,s2
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	8ba080e7          	jalr	-1862(ra) # 80000d28 <release>
}
    80004476:	60e2                	ld	ra,24(sp)
    80004478:	6442                	ld	s0,16(sp)
    8000447a:	64a2                	ld	s1,8(sp)
    8000447c:	6902                	ld	s2,0(sp)
    8000447e:	6105                	addi	sp,sp,32
    80004480:	8082                	ret

0000000080004482 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004482:	1101                	addi	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	e426                	sd	s1,8(sp)
    8000448a:	e04a                	sd	s2,0(sp)
    8000448c:	1000                	addi	s0,sp,32
    8000448e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004490:	00850913          	addi	s2,a0,8
    80004494:	854a                	mv	a0,s2
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	7de080e7          	jalr	2014(ra) # 80000c74 <acquire>
  lk->locked = 0;
    8000449e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffe097          	auipc	ra,0xffffe
    800044ac:	f3c080e7          	jalr	-196(ra) # 800023e4 <wakeup>
  release(&lk->lk);
    800044b0:	854a                	mv	a0,s2
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	876080e7          	jalr	-1930(ra) # 80000d28 <release>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	64a2                	ld	s1,8(sp)
    800044c0:	6902                	ld	s2,0(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044c6:	7179                	addi	sp,sp,-48
    800044c8:	f406                	sd	ra,40(sp)
    800044ca:	f022                	sd	s0,32(sp)
    800044cc:	ec26                	sd	s1,24(sp)
    800044ce:	e84a                	sd	s2,16(sp)
    800044d0:	e44e                	sd	s3,8(sp)
    800044d2:	1800                	addi	s0,sp,48
    800044d4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044d6:	00850913          	addi	s2,a0,8
    800044da:	854a                	mv	a0,s2
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	798080e7          	jalr	1944(ra) # 80000c74 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e4:	409c                	lw	a5,0(s1)
    800044e6:	ef99                	bnez	a5,80004504 <holdingsleep+0x3e>
    800044e8:	4481                	li	s1,0
  release(&lk->lk);
    800044ea:	854a                	mv	a0,s2
    800044ec:	ffffd097          	auipc	ra,0xffffd
    800044f0:	83c080e7          	jalr	-1988(ra) # 80000d28 <release>
  return r;
}
    800044f4:	8526                	mv	a0,s1
    800044f6:	70a2                	ld	ra,40(sp)
    800044f8:	7402                	ld	s0,32(sp)
    800044fa:	64e2                	ld	s1,24(sp)
    800044fc:	6942                	ld	s2,16(sp)
    800044fe:	69a2                	ld	s3,8(sp)
    80004500:	6145                	addi	sp,sp,48
    80004502:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004504:	0284a983          	lw	s3,40(s1)
    80004508:	ffffd097          	auipc	ra,0xffffd
    8000450c:	53a080e7          	jalr	1338(ra) # 80001a42 <myproc>
    80004510:	5d04                	lw	s1,56(a0)
    80004512:	413484b3          	sub	s1,s1,s3
    80004516:	0014b493          	seqz	s1,s1
    8000451a:	bfc1                	j	800044ea <holdingsleep+0x24>

000000008000451c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000451c:	1141                	addi	sp,sp,-16
    8000451e:	e406                	sd	ra,8(sp)
    80004520:	e022                	sd	s0,0(sp)
    80004522:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004524:	00004597          	auipc	a1,0x4
    80004528:	16458593          	addi	a1,a1,356 # 80008688 <syscalls+0x248>
    8000452c:	0001e517          	auipc	a0,0x1e
    80004530:	d2450513          	addi	a0,a0,-732 # 80022250 <ftable>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	6b0080e7          	jalr	1712(ra) # 80000be4 <initlock>
}
    8000453c:	60a2                	ld	ra,8(sp)
    8000453e:	6402                	ld	s0,0(sp)
    80004540:	0141                	addi	sp,sp,16
    80004542:	8082                	ret

0000000080004544 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004544:	1101                	addi	sp,sp,-32
    80004546:	ec06                	sd	ra,24(sp)
    80004548:	e822                	sd	s0,16(sp)
    8000454a:	e426                	sd	s1,8(sp)
    8000454c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000454e:	0001e517          	auipc	a0,0x1e
    80004552:	d0250513          	addi	a0,a0,-766 # 80022250 <ftable>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	71e080e7          	jalr	1822(ra) # 80000c74 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000455e:	0001e497          	auipc	s1,0x1e
    80004562:	d0a48493          	addi	s1,s1,-758 # 80022268 <ftable+0x18>
    80004566:	0001f717          	auipc	a4,0x1f
    8000456a:	ca270713          	addi	a4,a4,-862 # 80023208 <ftable+0xfb8>
    if(f->ref == 0){
    8000456e:	40dc                	lw	a5,4(s1)
    80004570:	cf99                	beqz	a5,8000458e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004572:	02848493          	addi	s1,s1,40
    80004576:	fee49ce3          	bne	s1,a4,8000456e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000457a:	0001e517          	auipc	a0,0x1e
    8000457e:	cd650513          	addi	a0,a0,-810 # 80022250 <ftable>
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	7a6080e7          	jalr	1958(ra) # 80000d28 <release>
  return 0;
    8000458a:	4481                	li	s1,0
    8000458c:	a819                	j	800045a2 <filealloc+0x5e>
      f->ref = 1;
    8000458e:	4785                	li	a5,1
    80004590:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004592:	0001e517          	auipc	a0,0x1e
    80004596:	cbe50513          	addi	a0,a0,-834 # 80022250 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	78e080e7          	jalr	1934(ra) # 80000d28 <release>
}
    800045a2:	8526                	mv	a0,s1
    800045a4:	60e2                	ld	ra,24(sp)
    800045a6:	6442                	ld	s0,16(sp)
    800045a8:	64a2                	ld	s1,8(sp)
    800045aa:	6105                	addi	sp,sp,32
    800045ac:	8082                	ret

00000000800045ae <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec06                	sd	ra,24(sp)
    800045b2:	e822                	sd	s0,16(sp)
    800045b4:	e426                	sd	s1,8(sp)
    800045b6:	1000                	addi	s0,sp,32
    800045b8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ba:	0001e517          	auipc	a0,0x1e
    800045be:	c9650513          	addi	a0,a0,-874 # 80022250 <ftable>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	6b2080e7          	jalr	1714(ra) # 80000c74 <acquire>
  if(f->ref < 1)
    800045ca:	40dc                	lw	a5,4(s1)
    800045cc:	02f05263          	blez	a5,800045f0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045d0:	2785                	addiw	a5,a5,1
    800045d2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045d4:	0001e517          	auipc	a0,0x1e
    800045d8:	c7c50513          	addi	a0,a0,-900 # 80022250 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	74c080e7          	jalr	1868(ra) # 80000d28 <release>
  return f;
}
    800045e4:	8526                	mv	a0,s1
    800045e6:	60e2                	ld	ra,24(sp)
    800045e8:	6442                	ld	s0,16(sp)
    800045ea:	64a2                	ld	s1,8(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret
    panic("filedup");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	0a050513          	addi	a0,a0,160 # 80008690 <syscalls+0x250>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	fde080e7          	jalr	-34(ra) # 800005d6 <panic>

0000000080004600 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004600:	7139                	addi	sp,sp,-64
    80004602:	fc06                	sd	ra,56(sp)
    80004604:	f822                	sd	s0,48(sp)
    80004606:	f426                	sd	s1,40(sp)
    80004608:	f04a                	sd	s2,32(sp)
    8000460a:	ec4e                	sd	s3,24(sp)
    8000460c:	e852                	sd	s4,16(sp)
    8000460e:	e456                	sd	s5,8(sp)
    80004610:	0080                	addi	s0,sp,64
    80004612:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004614:	0001e517          	auipc	a0,0x1e
    80004618:	c3c50513          	addi	a0,a0,-964 # 80022250 <ftable>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	658080e7          	jalr	1624(ra) # 80000c74 <acquire>
  if(f->ref < 1)
    80004624:	40dc                	lw	a5,4(s1)
    80004626:	06f05163          	blez	a5,80004688 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000462a:	37fd                	addiw	a5,a5,-1
    8000462c:	0007871b          	sext.w	a4,a5
    80004630:	c0dc                	sw	a5,4(s1)
    80004632:	06e04363          	bgtz	a4,80004698 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004636:	0004a903          	lw	s2,0(s1)
    8000463a:	0094ca83          	lbu	s5,9(s1)
    8000463e:	0104ba03          	ld	s4,16(s1)
    80004642:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004646:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000464a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000464e:	0001e517          	auipc	a0,0x1e
    80004652:	c0250513          	addi	a0,a0,-1022 # 80022250 <ftable>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	6d2080e7          	jalr	1746(ra) # 80000d28 <release>

  if(ff.type == FD_PIPE){
    8000465e:	4785                	li	a5,1
    80004660:	04f90d63          	beq	s2,a5,800046ba <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004664:	3979                	addiw	s2,s2,-2
    80004666:	4785                	li	a5,1
    80004668:	0527e063          	bltu	a5,s2,800046a8 <fileclose+0xa8>
    begin_op();
    8000466c:	00000097          	auipc	ra,0x0
    80004670:	ac2080e7          	jalr	-1342(ra) # 8000412e <begin_op>
    iput(ff.ip);
    80004674:	854e                	mv	a0,s3
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	2b6080e7          	jalr	694(ra) # 8000392c <iput>
    end_op();
    8000467e:	00000097          	auipc	ra,0x0
    80004682:	b30080e7          	jalr	-1232(ra) # 800041ae <end_op>
    80004686:	a00d                	j	800046a8 <fileclose+0xa8>
    panic("fileclose");
    80004688:	00004517          	auipc	a0,0x4
    8000468c:	01050513          	addi	a0,a0,16 # 80008698 <syscalls+0x258>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	f46080e7          	jalr	-186(ra) # 800005d6 <panic>
    release(&ftable.lock);
    80004698:	0001e517          	auipc	a0,0x1e
    8000469c:	bb850513          	addi	a0,a0,-1096 # 80022250 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	688080e7          	jalr	1672(ra) # 80000d28 <release>
  }
}
    800046a8:	70e2                	ld	ra,56(sp)
    800046aa:	7442                	ld	s0,48(sp)
    800046ac:	74a2                	ld	s1,40(sp)
    800046ae:	7902                	ld	s2,32(sp)
    800046b0:	69e2                	ld	s3,24(sp)
    800046b2:	6a42                	ld	s4,16(sp)
    800046b4:	6aa2                	ld	s5,8(sp)
    800046b6:	6121                	addi	sp,sp,64
    800046b8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ba:	85d6                	mv	a1,s5
    800046bc:	8552                	mv	a0,s4
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	372080e7          	jalr	882(ra) # 80004a30 <pipeclose>
    800046c6:	b7cd                	j	800046a8 <fileclose+0xa8>

00000000800046c8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046c8:	715d                	addi	sp,sp,-80
    800046ca:	e486                	sd	ra,72(sp)
    800046cc:	e0a2                	sd	s0,64(sp)
    800046ce:	fc26                	sd	s1,56(sp)
    800046d0:	f84a                	sd	s2,48(sp)
    800046d2:	f44e                	sd	s3,40(sp)
    800046d4:	0880                	addi	s0,sp,80
    800046d6:	84aa                	mv	s1,a0
    800046d8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046da:	ffffd097          	auipc	ra,0xffffd
    800046de:	368080e7          	jalr	872(ra) # 80001a42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046e2:	409c                	lw	a5,0(s1)
    800046e4:	37f9                	addiw	a5,a5,-2
    800046e6:	4705                	li	a4,1
    800046e8:	04f76763          	bltu	a4,a5,80004736 <filestat+0x6e>
    800046ec:	892a                	mv	s2,a0
    ilock(f->ip);
    800046ee:	6c88                	ld	a0,24(s1)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	082080e7          	jalr	130(ra) # 80003772 <ilock>
    stati(f->ip, &st);
    800046f8:	fb840593          	addi	a1,s0,-72
    800046fc:	6c88                	ld	a0,24(s1)
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	2fe080e7          	jalr	766(ra) # 800039fc <stati>
    iunlock(f->ip);
    80004706:	6c88                	ld	a0,24(s1)
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	12c080e7          	jalr	300(ra) # 80003834 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004710:	46e1                	li	a3,24
    80004712:	fb840613          	addi	a2,s0,-72
    80004716:	85ce                	mv	a1,s3
    80004718:	05093503          	ld	a0,80(s2)
    8000471c:	ffffd097          	auipc	ra,0xffffd
    80004720:	01a080e7          	jalr	26(ra) # 80001736 <copyout>
    80004724:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004728:	60a6                	ld	ra,72(sp)
    8000472a:	6406                	ld	s0,64(sp)
    8000472c:	74e2                	ld	s1,56(sp)
    8000472e:	7942                	ld	s2,48(sp)
    80004730:	79a2                	ld	s3,40(sp)
    80004732:	6161                	addi	sp,sp,80
    80004734:	8082                	ret
  return -1;
    80004736:	557d                	li	a0,-1
    80004738:	bfc5                	j	80004728 <filestat+0x60>

000000008000473a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000473a:	7179                	addi	sp,sp,-48
    8000473c:	f406                	sd	ra,40(sp)
    8000473e:	f022                	sd	s0,32(sp)
    80004740:	ec26                	sd	s1,24(sp)
    80004742:	e84a                	sd	s2,16(sp)
    80004744:	e44e                	sd	s3,8(sp)
    80004746:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004748:	00854783          	lbu	a5,8(a0)
    8000474c:	c3d5                	beqz	a5,800047f0 <fileread+0xb6>
    8000474e:	84aa                	mv	s1,a0
    80004750:	89ae                	mv	s3,a1
    80004752:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004754:	411c                	lw	a5,0(a0)
    80004756:	4705                	li	a4,1
    80004758:	04e78963          	beq	a5,a4,800047aa <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000475c:	470d                	li	a4,3
    8000475e:	04e78d63          	beq	a5,a4,800047b8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004762:	4709                	li	a4,2
    80004764:	06e79e63          	bne	a5,a4,800047e0 <fileread+0xa6>
    ilock(f->ip);
    80004768:	6d08                	ld	a0,24(a0)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	008080e7          	jalr	8(ra) # 80003772 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004772:	874a                	mv	a4,s2
    80004774:	5094                	lw	a3,32(s1)
    80004776:	864e                	mv	a2,s3
    80004778:	4585                	li	a1,1
    8000477a:	6c88                	ld	a0,24(s1)
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	2aa080e7          	jalr	682(ra) # 80003a26 <readi>
    80004784:	892a                	mv	s2,a0
    80004786:	00a05563          	blez	a0,80004790 <fileread+0x56>
      f->off += r;
    8000478a:	509c                	lw	a5,32(s1)
    8000478c:	9fa9                	addw	a5,a5,a0
    8000478e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004790:	6c88                	ld	a0,24(s1)
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	0a2080e7          	jalr	162(ra) # 80003834 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000479a:	854a                	mv	a0,s2
    8000479c:	70a2                	ld	ra,40(sp)
    8000479e:	7402                	ld	s0,32(sp)
    800047a0:	64e2                	ld	s1,24(sp)
    800047a2:	6942                	ld	s2,16(sp)
    800047a4:	69a2                	ld	s3,8(sp)
    800047a6:	6145                	addi	sp,sp,48
    800047a8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047aa:	6908                	ld	a0,16(a0)
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	418080e7          	jalr	1048(ra) # 80004bc4 <piperead>
    800047b4:	892a                	mv	s2,a0
    800047b6:	b7d5                	j	8000479a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047b8:	02451783          	lh	a5,36(a0)
    800047bc:	03079693          	slli	a3,a5,0x30
    800047c0:	92c1                	srli	a3,a3,0x30
    800047c2:	4725                	li	a4,9
    800047c4:	02d76863          	bltu	a4,a3,800047f4 <fileread+0xba>
    800047c8:	0792                	slli	a5,a5,0x4
    800047ca:	0001e717          	auipc	a4,0x1e
    800047ce:	9e670713          	addi	a4,a4,-1562 # 800221b0 <devsw>
    800047d2:	97ba                	add	a5,a5,a4
    800047d4:	639c                	ld	a5,0(a5)
    800047d6:	c38d                	beqz	a5,800047f8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047d8:	4505                	li	a0,1
    800047da:	9782                	jalr	a5
    800047dc:	892a                	mv	s2,a0
    800047de:	bf75                	j	8000479a <fileread+0x60>
    panic("fileread");
    800047e0:	00004517          	auipc	a0,0x4
    800047e4:	ec850513          	addi	a0,a0,-312 # 800086a8 <syscalls+0x268>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	dee080e7          	jalr	-530(ra) # 800005d6 <panic>
    return -1;
    800047f0:	597d                	li	s2,-1
    800047f2:	b765                	j	8000479a <fileread+0x60>
      return -1;
    800047f4:	597d                	li	s2,-1
    800047f6:	b755                	j	8000479a <fileread+0x60>
    800047f8:	597d                	li	s2,-1
    800047fa:	b745                	j	8000479a <fileread+0x60>

00000000800047fc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047fc:	00954783          	lbu	a5,9(a0)
    80004800:	14078563          	beqz	a5,8000494a <filewrite+0x14e>
{
    80004804:	715d                	addi	sp,sp,-80
    80004806:	e486                	sd	ra,72(sp)
    80004808:	e0a2                	sd	s0,64(sp)
    8000480a:	fc26                	sd	s1,56(sp)
    8000480c:	f84a                	sd	s2,48(sp)
    8000480e:	f44e                	sd	s3,40(sp)
    80004810:	f052                	sd	s4,32(sp)
    80004812:	ec56                	sd	s5,24(sp)
    80004814:	e85a                	sd	s6,16(sp)
    80004816:	e45e                	sd	s7,8(sp)
    80004818:	e062                	sd	s8,0(sp)
    8000481a:	0880                	addi	s0,sp,80
    8000481c:	892a                	mv	s2,a0
    8000481e:	8aae                	mv	s5,a1
    80004820:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004822:	411c                	lw	a5,0(a0)
    80004824:	4705                	li	a4,1
    80004826:	02e78263          	beq	a5,a4,8000484a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000482a:	470d                	li	a4,3
    8000482c:	02e78563          	beq	a5,a4,80004856 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004830:	4709                	li	a4,2
    80004832:	10e79463          	bne	a5,a4,8000493a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004836:	0ec05e63          	blez	a2,80004932 <filewrite+0x136>
    int i = 0;
    8000483a:	4981                	li	s3,0
    8000483c:	6b05                	lui	s6,0x1
    8000483e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004842:	6b85                	lui	s7,0x1
    80004844:	c00b8b9b          	addiw	s7,s7,-1024
    80004848:	a851                	j	800048dc <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000484a:	6908                	ld	a0,16(a0)
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	254080e7          	jalr	596(ra) # 80004aa0 <pipewrite>
    80004854:	a85d                	j	8000490a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004856:	02451783          	lh	a5,36(a0)
    8000485a:	03079693          	slli	a3,a5,0x30
    8000485e:	92c1                	srli	a3,a3,0x30
    80004860:	4725                	li	a4,9
    80004862:	0ed76663          	bltu	a4,a3,8000494e <filewrite+0x152>
    80004866:	0792                	slli	a5,a5,0x4
    80004868:	0001e717          	auipc	a4,0x1e
    8000486c:	94870713          	addi	a4,a4,-1720 # 800221b0 <devsw>
    80004870:	97ba                	add	a5,a5,a4
    80004872:	679c                	ld	a5,8(a5)
    80004874:	cff9                	beqz	a5,80004952 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004876:	4505                	li	a0,1
    80004878:	9782                	jalr	a5
    8000487a:	a841                	j	8000490a <filewrite+0x10e>
    8000487c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004880:	00000097          	auipc	ra,0x0
    80004884:	8ae080e7          	jalr	-1874(ra) # 8000412e <begin_op>
      ilock(f->ip);
    80004888:	01893503          	ld	a0,24(s2)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	ee6080e7          	jalr	-282(ra) # 80003772 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004894:	8762                	mv	a4,s8
    80004896:	02092683          	lw	a3,32(s2)
    8000489a:	01598633          	add	a2,s3,s5
    8000489e:	4585                	li	a1,1
    800048a0:	01893503          	ld	a0,24(s2)
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	278080e7          	jalr	632(ra) # 80003b1c <writei>
    800048ac:	84aa                	mv	s1,a0
    800048ae:	02a05f63          	blez	a0,800048ec <filewrite+0xf0>
        f->off += r;
    800048b2:	02092783          	lw	a5,32(s2)
    800048b6:	9fa9                	addw	a5,a5,a0
    800048b8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048bc:	01893503          	ld	a0,24(s2)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	f74080e7          	jalr	-140(ra) # 80003834 <iunlock>
      end_op();
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	8e6080e7          	jalr	-1818(ra) # 800041ae <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048d0:	049c1963          	bne	s8,s1,80004922 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048d4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048d8:	0349d663          	bge	s3,s4,80004904 <filewrite+0x108>
      int n1 = n - i;
    800048dc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048e0:	84be                	mv	s1,a5
    800048e2:	2781                	sext.w	a5,a5
    800048e4:	f8fb5ce3          	bge	s6,a5,8000487c <filewrite+0x80>
    800048e8:	84de                	mv	s1,s7
    800048ea:	bf49                	j	8000487c <filewrite+0x80>
      iunlock(f->ip);
    800048ec:	01893503          	ld	a0,24(s2)
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	f44080e7          	jalr	-188(ra) # 80003834 <iunlock>
      end_op();
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	8b6080e7          	jalr	-1866(ra) # 800041ae <end_op>
      if(r < 0)
    80004900:	fc04d8e3          	bgez	s1,800048d0 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004904:	8552                	mv	a0,s4
    80004906:	033a1863          	bne	s4,s3,80004936 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000490a:	60a6                	ld	ra,72(sp)
    8000490c:	6406                	ld	s0,64(sp)
    8000490e:	74e2                	ld	s1,56(sp)
    80004910:	7942                	ld	s2,48(sp)
    80004912:	79a2                	ld	s3,40(sp)
    80004914:	7a02                	ld	s4,32(sp)
    80004916:	6ae2                	ld	s5,24(sp)
    80004918:	6b42                	ld	s6,16(sp)
    8000491a:	6ba2                	ld	s7,8(sp)
    8000491c:	6c02                	ld	s8,0(sp)
    8000491e:	6161                	addi	sp,sp,80
    80004920:	8082                	ret
        panic("short filewrite");
    80004922:	00004517          	auipc	a0,0x4
    80004926:	d9650513          	addi	a0,a0,-618 # 800086b8 <syscalls+0x278>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	cac080e7          	jalr	-852(ra) # 800005d6 <panic>
    int i = 0;
    80004932:	4981                	li	s3,0
    80004934:	bfc1                	j	80004904 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004936:	557d                	li	a0,-1
    80004938:	bfc9                	j	8000490a <filewrite+0x10e>
    panic("filewrite");
    8000493a:	00004517          	auipc	a0,0x4
    8000493e:	d8e50513          	addi	a0,a0,-626 # 800086c8 <syscalls+0x288>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	c94080e7          	jalr	-876(ra) # 800005d6 <panic>
    return -1;
    8000494a:	557d                	li	a0,-1
}
    8000494c:	8082                	ret
      return -1;
    8000494e:	557d                	li	a0,-1
    80004950:	bf6d                	j	8000490a <filewrite+0x10e>
    80004952:	557d                	li	a0,-1
    80004954:	bf5d                	j	8000490a <filewrite+0x10e>

0000000080004956 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004956:	7179                	addi	sp,sp,-48
    80004958:	f406                	sd	ra,40(sp)
    8000495a:	f022                	sd	s0,32(sp)
    8000495c:	ec26                	sd	s1,24(sp)
    8000495e:	e84a                	sd	s2,16(sp)
    80004960:	e44e                	sd	s3,8(sp)
    80004962:	e052                	sd	s4,0(sp)
    80004964:	1800                	addi	s0,sp,48
    80004966:	84aa                	mv	s1,a0
    80004968:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000496a:	0005b023          	sd	zero,0(a1)
    8000496e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004972:	00000097          	auipc	ra,0x0
    80004976:	bd2080e7          	jalr	-1070(ra) # 80004544 <filealloc>
    8000497a:	e088                	sd	a0,0(s1)
    8000497c:	c551                	beqz	a0,80004a08 <pipealloc+0xb2>
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	bc6080e7          	jalr	-1082(ra) # 80004544 <filealloc>
    80004986:	00aa3023          	sd	a0,0(s4)
    8000498a:	c92d                	beqz	a0,800049fc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	1f8080e7          	jalr	504(ra) # 80000b84 <kalloc>
    80004994:	892a                	mv	s2,a0
    80004996:	c125                	beqz	a0,800049f6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004998:	4985                	li	s3,1
    8000499a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000499e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049a6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049aa:	00004597          	auipc	a1,0x4
    800049ae:	d2e58593          	addi	a1,a1,-722 # 800086d8 <syscalls+0x298>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	232080e7          	jalr	562(ra) # 80000be4 <initlock>
  (*f0)->type = FD_PIPE;
    800049ba:	609c                	ld	a5,0(s1)
    800049bc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c0:	609c                	ld	a5,0(s1)
    800049c2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049c6:	609c                	ld	a5,0(s1)
    800049c8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049cc:	609c                	ld	a5,0(s1)
    800049ce:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d2:	000a3783          	ld	a5,0(s4)
    800049d6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049da:	000a3783          	ld	a5,0(s4)
    800049de:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e2:	000a3783          	ld	a5,0(s4)
    800049e6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ea:	000a3783          	ld	a5,0(s4)
    800049ee:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f2:	4501                	li	a0,0
    800049f4:	a025                	j	80004a1c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049f6:	6088                	ld	a0,0(s1)
    800049f8:	e501                	bnez	a0,80004a00 <pipealloc+0xaa>
    800049fa:	a039                	j	80004a08 <pipealloc+0xb2>
    800049fc:	6088                	ld	a0,0(s1)
    800049fe:	c51d                	beqz	a0,80004a2c <pipealloc+0xd6>
    fileclose(*f0);
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	c00080e7          	jalr	-1024(ra) # 80004600 <fileclose>
  if(*f1)
    80004a08:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a0c:	557d                	li	a0,-1
  if(*f1)
    80004a0e:	c799                	beqz	a5,80004a1c <pipealloc+0xc6>
    fileclose(*f1);
    80004a10:	853e                	mv	a0,a5
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	bee080e7          	jalr	-1042(ra) # 80004600 <fileclose>
  return -1;
    80004a1a:	557d                	li	a0,-1
}
    80004a1c:	70a2                	ld	ra,40(sp)
    80004a1e:	7402                	ld	s0,32(sp)
    80004a20:	64e2                	ld	s1,24(sp)
    80004a22:	6942                	ld	s2,16(sp)
    80004a24:	69a2                	ld	s3,8(sp)
    80004a26:	6a02                	ld	s4,0(sp)
    80004a28:	6145                	addi	sp,sp,48
    80004a2a:	8082                	ret
  return -1;
    80004a2c:	557d                	li	a0,-1
    80004a2e:	b7fd                	j	80004a1c <pipealloc+0xc6>

0000000080004a30 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a30:	1101                	addi	sp,sp,-32
    80004a32:	ec06                	sd	ra,24(sp)
    80004a34:	e822                	sd	s0,16(sp)
    80004a36:	e426                	sd	s1,8(sp)
    80004a38:	e04a                	sd	s2,0(sp)
    80004a3a:	1000                	addi	s0,sp,32
    80004a3c:	84aa                	mv	s1,a0
    80004a3e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	234080e7          	jalr	564(ra) # 80000c74 <acquire>
  if(writable){
    80004a48:	02090d63          	beqz	s2,80004a82 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a4c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a50:	21848513          	addi	a0,s1,536
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	990080e7          	jalr	-1648(ra) # 800023e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a5c:	2204b783          	ld	a5,544(s1)
    80004a60:	eb95                	bnez	a5,80004a94 <pipeclose+0x64>
    release(&pi->lock);
    80004a62:	8526                	mv	a0,s1
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	2c4080e7          	jalr	708(ra) # 80000d28 <release>
    kfree((char*)pi);
    80004a6c:	8526                	mv	a0,s1
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	01a080e7          	jalr	26(ra) # 80000a88 <kfree>
  } else
    release(&pi->lock);
}
    80004a76:	60e2                	ld	ra,24(sp)
    80004a78:	6442                	ld	s0,16(sp)
    80004a7a:	64a2                	ld	s1,8(sp)
    80004a7c:	6902                	ld	s2,0(sp)
    80004a7e:	6105                	addi	sp,sp,32
    80004a80:	8082                	ret
    pi->readopen = 0;
    80004a82:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a86:	21c48513          	addi	a0,s1,540
    80004a8a:	ffffe097          	auipc	ra,0xffffe
    80004a8e:	95a080e7          	jalr	-1702(ra) # 800023e4 <wakeup>
    80004a92:	b7e9                	j	80004a5c <pipeclose+0x2c>
    release(&pi->lock);
    80004a94:	8526                	mv	a0,s1
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	292080e7          	jalr	658(ra) # 80000d28 <release>
}
    80004a9e:	bfe1                	j	80004a76 <pipeclose+0x46>

0000000080004aa0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa0:	7119                	addi	sp,sp,-128
    80004aa2:	fc86                	sd	ra,120(sp)
    80004aa4:	f8a2                	sd	s0,112(sp)
    80004aa6:	f4a6                	sd	s1,104(sp)
    80004aa8:	f0ca                	sd	s2,96(sp)
    80004aaa:	ecce                	sd	s3,88(sp)
    80004aac:	e8d2                	sd	s4,80(sp)
    80004aae:	e4d6                	sd	s5,72(sp)
    80004ab0:	e0da                	sd	s6,64(sp)
    80004ab2:	fc5e                	sd	s7,56(sp)
    80004ab4:	f862                	sd	s8,48(sp)
    80004ab6:	f466                	sd	s9,40(sp)
    80004ab8:	f06a                	sd	s10,32(sp)
    80004aba:	ec6e                	sd	s11,24(sp)
    80004abc:	0100                	addi	s0,sp,128
    80004abe:	84aa                	mv	s1,a0
    80004ac0:	8cae                	mv	s9,a1
    80004ac2:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	f7e080e7          	jalr	-130(ra) # 80001a42 <myproc>
    80004acc:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	1a4080e7          	jalr	420(ra) # 80000c74 <acquire>
  for(i = 0; i < n; i++){
    80004ad8:	0d605963          	blez	s6,80004baa <pipewrite+0x10a>
    80004adc:	89a6                	mv	s3,s1
    80004ade:	3b7d                	addiw	s6,s6,-1
    80004ae0:	1b02                	slli	s6,s6,0x20
    80004ae2:	020b5b13          	srli	s6,s6,0x20
    80004ae6:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ae8:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aec:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af0:	5dfd                	li	s11,-1
    80004af2:	000b8d1b          	sext.w	s10,s7
    80004af6:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004af8:	2184a783          	lw	a5,536(s1)
    80004afc:	21c4a703          	lw	a4,540(s1)
    80004b00:	2007879b          	addiw	a5,a5,512
    80004b04:	02f71b63          	bne	a4,a5,80004b3a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b08:	2204a783          	lw	a5,544(s1)
    80004b0c:	cbad                	beqz	a5,80004b7e <pipewrite+0xde>
    80004b0e:	03092783          	lw	a5,48(s2)
    80004b12:	e7b5                	bnez	a5,80004b7e <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b14:	8556                	mv	a0,s5
    80004b16:	ffffe097          	auipc	ra,0xffffe
    80004b1a:	8ce080e7          	jalr	-1842(ra) # 800023e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b1e:	85ce                	mv	a1,s3
    80004b20:	8552                	mv	a0,s4
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	73c080e7          	jalr	1852(ra) # 8000225e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b2a:	2184a783          	lw	a5,536(s1)
    80004b2e:	21c4a703          	lw	a4,540(s1)
    80004b32:	2007879b          	addiw	a5,a5,512
    80004b36:	fcf709e3          	beq	a4,a5,80004b08 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3a:	4685                	li	a3,1
    80004b3c:	019b8633          	add	a2,s7,s9
    80004b40:	f8f40593          	addi	a1,s0,-113
    80004b44:	05093503          	ld	a0,80(s2)
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	c7a080e7          	jalr	-902(ra) # 800017c2 <copyin>
    80004b50:	05b50e63          	beq	a0,s11,80004bac <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b54:	21c4a783          	lw	a5,540(s1)
    80004b58:	0017871b          	addiw	a4,a5,1
    80004b5c:	20e4ae23          	sw	a4,540(s1)
    80004b60:	1ff7f793          	andi	a5,a5,511
    80004b64:	97a6                	add	a5,a5,s1
    80004b66:	f8f44703          	lbu	a4,-113(s0)
    80004b6a:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b6e:	001d0c1b          	addiw	s8,s10,1
    80004b72:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b76:	036b8b63          	beq	s7,s6,80004bac <pipewrite+0x10c>
    80004b7a:	8bbe                	mv	s7,a5
    80004b7c:	bf9d                	j	80004af2 <pipewrite+0x52>
        release(&pi->lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	1a8080e7          	jalr	424(ra) # 80000d28 <release>
        return -1;
    80004b88:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b8a:	8562                	mv	a0,s8
    80004b8c:	70e6                	ld	ra,120(sp)
    80004b8e:	7446                	ld	s0,112(sp)
    80004b90:	74a6                	ld	s1,104(sp)
    80004b92:	7906                	ld	s2,96(sp)
    80004b94:	69e6                	ld	s3,88(sp)
    80004b96:	6a46                	ld	s4,80(sp)
    80004b98:	6aa6                	ld	s5,72(sp)
    80004b9a:	6b06                	ld	s6,64(sp)
    80004b9c:	7be2                	ld	s7,56(sp)
    80004b9e:	7c42                	ld	s8,48(sp)
    80004ba0:	7ca2                	ld	s9,40(sp)
    80004ba2:	7d02                	ld	s10,32(sp)
    80004ba4:	6de2                	ld	s11,24(sp)
    80004ba6:	6109                	addi	sp,sp,128
    80004ba8:	8082                	ret
  for(i = 0; i < n; i++){
    80004baa:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bac:	21848513          	addi	a0,s1,536
    80004bb0:	ffffe097          	auipc	ra,0xffffe
    80004bb4:	834080e7          	jalr	-1996(ra) # 800023e4 <wakeup>
  release(&pi->lock);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	16e080e7          	jalr	366(ra) # 80000d28 <release>
  return i;
    80004bc2:	b7e1                	j	80004b8a <pipewrite+0xea>

0000000080004bc4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bc4:	715d                	addi	sp,sp,-80
    80004bc6:	e486                	sd	ra,72(sp)
    80004bc8:	e0a2                	sd	s0,64(sp)
    80004bca:	fc26                	sd	s1,56(sp)
    80004bcc:	f84a                	sd	s2,48(sp)
    80004bce:	f44e                	sd	s3,40(sp)
    80004bd0:	f052                	sd	s4,32(sp)
    80004bd2:	ec56                	sd	s5,24(sp)
    80004bd4:	e85a                	sd	s6,16(sp)
    80004bd6:	0880                	addi	s0,sp,80
    80004bd8:	84aa                	mv	s1,a0
    80004bda:	892e                	mv	s2,a1
    80004bdc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	e64080e7          	jalr	-412(ra) # 80001a42 <myproc>
    80004be6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004be8:	8b26                	mv	s6,s1
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	088080e7          	jalr	136(ra) # 80000c74 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf4:	2184a703          	lw	a4,536(s1)
    80004bf8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bfc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c00:	02f71463          	bne	a4,a5,80004c28 <piperead+0x64>
    80004c04:	2244a783          	lw	a5,548(s1)
    80004c08:	c385                	beqz	a5,80004c28 <piperead+0x64>
    if(pr->killed){
    80004c0a:	030a2783          	lw	a5,48(s4)
    80004c0e:	ebc1                	bnez	a5,80004c9e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c10:	85da                	mv	a1,s6
    80004c12:	854e                	mv	a0,s3
    80004c14:	ffffd097          	auipc	ra,0xffffd
    80004c18:	64a080e7          	jalr	1610(ra) # 8000225e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1c:	2184a703          	lw	a4,536(s1)
    80004c20:	21c4a783          	lw	a5,540(s1)
    80004c24:	fef700e3          	beq	a4,a5,80004c04 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c28:	09505263          	blez	s5,80004cac <piperead+0xe8>
    80004c2c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c2e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c30:	2184a783          	lw	a5,536(s1)
    80004c34:	21c4a703          	lw	a4,540(s1)
    80004c38:	02f70d63          	beq	a4,a5,80004c72 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c3c:	0017871b          	addiw	a4,a5,1
    80004c40:	20e4ac23          	sw	a4,536(s1)
    80004c44:	1ff7f793          	andi	a5,a5,511
    80004c48:	97a6                	add	a5,a5,s1
    80004c4a:	0187c783          	lbu	a5,24(a5)
    80004c4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c52:	4685                	li	a3,1
    80004c54:	fbf40613          	addi	a2,s0,-65
    80004c58:	85ca                	mv	a1,s2
    80004c5a:	050a3503          	ld	a0,80(s4)
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	ad8080e7          	jalr	-1320(ra) # 80001736 <copyout>
    80004c66:	01650663          	beq	a0,s6,80004c72 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6a:	2985                	addiw	s3,s3,1
    80004c6c:	0905                	addi	s2,s2,1
    80004c6e:	fd3a91e3          	bne	s5,s3,80004c30 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c72:	21c48513          	addi	a0,s1,540
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	76e080e7          	jalr	1902(ra) # 800023e4 <wakeup>
  release(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	0a8080e7          	jalr	168(ra) # 80000d28 <release>
  return i;
}
    80004c88:	854e                	mv	a0,s3
    80004c8a:	60a6                	ld	ra,72(sp)
    80004c8c:	6406                	ld	s0,64(sp)
    80004c8e:	74e2                	ld	s1,56(sp)
    80004c90:	7942                	ld	s2,48(sp)
    80004c92:	79a2                	ld	s3,40(sp)
    80004c94:	7a02                	ld	s4,32(sp)
    80004c96:	6ae2                	ld	s5,24(sp)
    80004c98:	6b42                	ld	s6,16(sp)
    80004c9a:	6161                	addi	sp,sp,80
    80004c9c:	8082                	ret
      release(&pi->lock);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	088080e7          	jalr	136(ra) # 80000d28 <release>
      return -1;
    80004ca8:	59fd                	li	s3,-1
    80004caa:	bff9                	j	80004c88 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cac:	4981                	li	s3,0
    80004cae:	b7d1                	j	80004c72 <piperead+0xae>

0000000080004cb0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cb0:	df010113          	addi	sp,sp,-528
    80004cb4:	20113423          	sd	ra,520(sp)
    80004cb8:	20813023          	sd	s0,512(sp)
    80004cbc:	ffa6                	sd	s1,504(sp)
    80004cbe:	fbca                	sd	s2,496(sp)
    80004cc0:	f7ce                	sd	s3,488(sp)
    80004cc2:	f3d2                	sd	s4,480(sp)
    80004cc4:	efd6                	sd	s5,472(sp)
    80004cc6:	ebda                	sd	s6,464(sp)
    80004cc8:	e7de                	sd	s7,456(sp)
    80004cca:	e3e2                	sd	s8,448(sp)
    80004ccc:	ff66                	sd	s9,440(sp)
    80004cce:	fb6a                	sd	s10,432(sp)
    80004cd0:	f76e                	sd	s11,424(sp)
    80004cd2:	0c00                	addi	s0,sp,528
    80004cd4:	84aa                	mv	s1,a0
    80004cd6:	dea43c23          	sd	a0,-520(s0)
    80004cda:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	d64080e7          	jalr	-668(ra) # 80001a42 <myproc>
    80004ce6:	892a                	mv	s2,a0

  begin_op();
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	446080e7          	jalr	1094(ra) # 8000412e <begin_op>

  if((ip = namei(path)) == 0){
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	230080e7          	jalr	560(ra) # 80003f22 <namei>
    80004cfa:	c92d                	beqz	a0,80004d6c <exec+0xbc>
    80004cfc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	a74080e7          	jalr	-1420(ra) # 80003772 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d06:	04000713          	li	a4,64
    80004d0a:	4681                	li	a3,0
    80004d0c:	e4840613          	addi	a2,s0,-440
    80004d10:	4581                	li	a1,0
    80004d12:	8526                	mv	a0,s1
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	d12080e7          	jalr	-750(ra) # 80003a26 <readi>
    80004d1c:	04000793          	li	a5,64
    80004d20:	00f51a63          	bne	a0,a5,80004d34 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d24:	e4842703          	lw	a4,-440(s0)
    80004d28:	464c47b7          	lui	a5,0x464c4
    80004d2c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d30:	04f70463          	beq	a4,a5,80004d78 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d34:	8526                	mv	a0,s1
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	c9e080e7          	jalr	-866(ra) # 800039d4 <iunlockput>
    end_op();
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	470080e7          	jalr	1136(ra) # 800041ae <end_op>
  }
  return -1;
    80004d46:	557d                	li	a0,-1
}
    80004d48:	20813083          	ld	ra,520(sp)
    80004d4c:	20013403          	ld	s0,512(sp)
    80004d50:	74fe                	ld	s1,504(sp)
    80004d52:	795e                	ld	s2,496(sp)
    80004d54:	79be                	ld	s3,488(sp)
    80004d56:	7a1e                	ld	s4,480(sp)
    80004d58:	6afe                	ld	s5,472(sp)
    80004d5a:	6b5e                	ld	s6,464(sp)
    80004d5c:	6bbe                	ld	s7,456(sp)
    80004d5e:	6c1e                	ld	s8,448(sp)
    80004d60:	7cfa                	ld	s9,440(sp)
    80004d62:	7d5a                	ld	s10,432(sp)
    80004d64:	7dba                	ld	s11,424(sp)
    80004d66:	21010113          	addi	sp,sp,528
    80004d6a:	8082                	ret
    end_op();
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	442080e7          	jalr	1090(ra) # 800041ae <end_op>
    return -1;
    80004d74:	557d                	li	a0,-1
    80004d76:	bfc9                	j	80004d48 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d78:	854a                	mv	a0,s2
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	d8c080e7          	jalr	-628(ra) # 80001b06 <proc_pagetable>
    80004d82:	8baa                	mv	s7,a0
    80004d84:	d945                	beqz	a0,80004d34 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d86:	e6842983          	lw	s3,-408(s0)
    80004d8a:	e8045783          	lhu	a5,-384(s0)
    80004d8e:	c7ad                	beqz	a5,80004df8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d90:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d92:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d94:	6c85                	lui	s9,0x1
    80004d96:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d9a:	def43823          	sd	a5,-528(s0)
    80004d9e:	a42d                	j	80004fc8 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da0:	00004517          	auipc	a0,0x4
    80004da4:	94050513          	addi	a0,a0,-1728 # 800086e0 <syscalls+0x2a0>
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	82e080e7          	jalr	-2002(ra) # 800005d6 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db0:	8756                	mv	a4,s5
    80004db2:	012d86bb          	addw	a3,s11,s2
    80004db6:	4581                	li	a1,0
    80004db8:	8526                	mv	a0,s1
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	c6c080e7          	jalr	-916(ra) # 80003a26 <readi>
    80004dc2:	2501                	sext.w	a0,a0
    80004dc4:	1aaa9963          	bne	s5,a0,80004f76 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dc8:	6785                	lui	a5,0x1
    80004dca:	0127893b          	addw	s2,a5,s2
    80004dce:	77fd                	lui	a5,0xfffff
    80004dd0:	01478a3b          	addw	s4,a5,s4
    80004dd4:	1f897163          	bgeu	s2,s8,80004fb6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dd8:	02091593          	slli	a1,s2,0x20
    80004ddc:	9181                	srli	a1,a1,0x20
    80004dde:	95ea                	add	a1,a1,s10
    80004de0:	855e                	mv	a0,s7
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	320080e7          	jalr	800(ra) # 80001102 <walkaddr>
    80004dea:	862a                	mv	a2,a0
    if(pa == 0)
    80004dec:	d955                	beqz	a0,80004da0 <exec+0xf0>
      n = PGSIZE;
    80004dee:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004df0:	fd9a70e3          	bgeu	s4,s9,80004db0 <exec+0x100>
      n = sz - i;
    80004df4:	8ad2                	mv	s5,s4
    80004df6:	bf6d                	j	80004db0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004df8:	4901                	li	s2,0
  iunlockput(ip);
    80004dfa:	8526                	mv	a0,s1
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	bd8080e7          	jalr	-1064(ra) # 800039d4 <iunlockput>
  end_op();
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	3aa080e7          	jalr	938(ra) # 800041ae <end_op>
  p = myproc();
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	c36080e7          	jalr	-970(ra) # 80001a42 <myproc>
    80004e14:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e16:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e1a:	6785                	lui	a5,0x1
    80004e1c:	17fd                	addi	a5,a5,-1
    80004e1e:	993e                	add	s2,s2,a5
    80004e20:	757d                	lui	a0,0xfffff
    80004e22:	00a977b3          	and	a5,s2,a0
    80004e26:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e2a:	6609                	lui	a2,0x2
    80004e2c:	963e                	add	a2,a2,a5
    80004e2e:	85be                	mv	a1,a5
    80004e30:	855e                	mv	a0,s7
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	6b4080e7          	jalr	1716(ra) # 800014e6 <uvmalloc>
    80004e3a:	8b2a                	mv	s6,a0
  ip = 0;
    80004e3c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e3e:	12050c63          	beqz	a0,80004f76 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e42:	75f9                	lui	a1,0xffffe
    80004e44:	95aa                	add	a1,a1,a0
    80004e46:	855e                	mv	a0,s7
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	8bc080e7          	jalr	-1860(ra) # 80001704 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e50:	7c7d                	lui	s8,0xfffff
    80004e52:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e54:	e0043783          	ld	a5,-512(s0)
    80004e58:	6388                	ld	a0,0(a5)
    80004e5a:	c535                	beqz	a0,80004ec6 <exec+0x216>
    80004e5c:	e8840993          	addi	s3,s0,-376
    80004e60:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e64:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	092080e7          	jalr	146(ra) # 80000ef8 <strlen>
    80004e6e:	2505                	addiw	a0,a0,1
    80004e70:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e74:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e78:	13896363          	bltu	s2,s8,80004f9e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e7c:	e0043d83          	ld	s11,-512(s0)
    80004e80:	000dba03          	ld	s4,0(s11)
    80004e84:	8552                	mv	a0,s4
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	072080e7          	jalr	114(ra) # 80000ef8 <strlen>
    80004e8e:	0015069b          	addiw	a3,a0,1
    80004e92:	8652                	mv	a2,s4
    80004e94:	85ca                	mv	a1,s2
    80004e96:	855e                	mv	a0,s7
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	89e080e7          	jalr	-1890(ra) # 80001736 <copyout>
    80004ea0:	10054363          	bltz	a0,80004fa6 <exec+0x2f6>
    ustack[argc] = sp;
    80004ea4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ea8:	0485                	addi	s1,s1,1
    80004eaa:	008d8793          	addi	a5,s11,8
    80004eae:	e0f43023          	sd	a5,-512(s0)
    80004eb2:	008db503          	ld	a0,8(s11)
    80004eb6:	c911                	beqz	a0,80004eca <exec+0x21a>
    if(argc >= MAXARG)
    80004eb8:	09a1                	addi	s3,s3,8
    80004eba:	fb3c96e3          	bne	s9,s3,80004e66 <exec+0x1b6>
  sz = sz1;
    80004ebe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec2:	4481                	li	s1,0
    80004ec4:	a84d                	j	80004f76 <exec+0x2c6>
  sp = sz;
    80004ec6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ec8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eca:	00349793          	slli	a5,s1,0x3
    80004ece:	f9040713          	addi	a4,s0,-112
    80004ed2:	97ba                	add	a5,a5,a4
    80004ed4:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ed8:	00148693          	addi	a3,s1,1
    80004edc:	068e                	slli	a3,a3,0x3
    80004ede:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee6:	01897663          	bgeu	s2,s8,80004ef2 <exec+0x242>
  sz = sz1;
    80004eea:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eee:	4481                	li	s1,0
    80004ef0:	a059                	j	80004f76 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef2:	e8840613          	addi	a2,s0,-376
    80004ef6:	85ca                	mv	a1,s2
    80004ef8:	855e                	mv	a0,s7
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	83c080e7          	jalr	-1988(ra) # 80001736 <copyout>
    80004f02:	0a054663          	bltz	a0,80004fae <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f06:	058ab783          	ld	a5,88(s5)
    80004f0a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f0e:	df843783          	ld	a5,-520(s0)
    80004f12:	0007c703          	lbu	a4,0(a5)
    80004f16:	cf11                	beqz	a4,80004f32 <exec+0x282>
    80004f18:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f1a:	02f00693          	li	a3,47
    80004f1e:	a029                	j	80004f28 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f20:	0785                	addi	a5,a5,1
    80004f22:	fff7c703          	lbu	a4,-1(a5)
    80004f26:	c711                	beqz	a4,80004f32 <exec+0x282>
    if(*s == '/')
    80004f28:	fed71ce3          	bne	a4,a3,80004f20 <exec+0x270>
      last = s+1;
    80004f2c:	def43c23          	sd	a5,-520(s0)
    80004f30:	bfc5                	j	80004f20 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f32:	4641                	li	a2,16
    80004f34:	df843583          	ld	a1,-520(s0)
    80004f38:	158a8513          	addi	a0,s5,344
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	f8a080e7          	jalr	-118(ra) # 80000ec6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f44:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f48:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f4c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f50:	058ab783          	ld	a5,88(s5)
    80004f54:	e6043703          	ld	a4,-416(s0)
    80004f58:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5a:	058ab783          	ld	a5,88(s5)
    80004f5e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f62:	85ea                	mv	a1,s10
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	c3e080e7          	jalr	-962(ra) # 80001ba2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f6c:	0004851b          	sext.w	a0,s1
    80004f70:	bbe1                	j	80004d48 <exec+0x98>
    80004f72:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f76:	e0843583          	ld	a1,-504(s0)
    80004f7a:	855e                	mv	a0,s7
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	c26080e7          	jalr	-986(ra) # 80001ba2 <proc_freepagetable>
  if(ip){
    80004f84:	da0498e3          	bnez	s1,80004d34 <exec+0x84>
  return -1;
    80004f88:	557d                	li	a0,-1
    80004f8a:	bb7d                	j	80004d48 <exec+0x98>
    80004f8c:	e1243423          	sd	s2,-504(s0)
    80004f90:	b7dd                	j	80004f76 <exec+0x2c6>
    80004f92:	e1243423          	sd	s2,-504(s0)
    80004f96:	b7c5                	j	80004f76 <exec+0x2c6>
    80004f98:	e1243423          	sd	s2,-504(s0)
    80004f9c:	bfe9                	j	80004f76 <exec+0x2c6>
  sz = sz1;
    80004f9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa2:	4481                	li	s1,0
    80004fa4:	bfc9                	j	80004f76 <exec+0x2c6>
  sz = sz1;
    80004fa6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004faa:	4481                	li	s1,0
    80004fac:	b7e9                	j	80004f76 <exec+0x2c6>
  sz = sz1;
    80004fae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb2:	4481                	li	s1,0
    80004fb4:	b7c9                	j	80004f76 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fb6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fba:	2b05                	addiw	s6,s6,1
    80004fbc:	0389899b          	addiw	s3,s3,56
    80004fc0:	e8045783          	lhu	a5,-384(s0)
    80004fc4:	e2fb5be3          	bge	s6,a5,80004dfa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fc8:	2981                	sext.w	s3,s3
    80004fca:	03800713          	li	a4,56
    80004fce:	86ce                	mv	a3,s3
    80004fd0:	e1040613          	addi	a2,s0,-496
    80004fd4:	4581                	li	a1,0
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	a4e080e7          	jalr	-1458(ra) # 80003a26 <readi>
    80004fe0:	03800793          	li	a5,56
    80004fe4:	f8f517e3          	bne	a0,a5,80004f72 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fe8:	e1042783          	lw	a5,-496(s0)
    80004fec:	4705                	li	a4,1
    80004fee:	fce796e3          	bne	a5,a4,80004fba <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ff2:	e3843603          	ld	a2,-456(s0)
    80004ff6:	e3043783          	ld	a5,-464(s0)
    80004ffa:	f8f669e3          	bltu	a2,a5,80004f8c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ffe:	e2043783          	ld	a5,-480(s0)
    80005002:	963e                	add	a2,a2,a5
    80005004:	f8f667e3          	bltu	a2,a5,80004f92 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005008:	85ca                	mv	a1,s2
    8000500a:	855e                	mv	a0,s7
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	4da080e7          	jalr	1242(ra) # 800014e6 <uvmalloc>
    80005014:	e0a43423          	sd	a0,-504(s0)
    80005018:	d141                	beqz	a0,80004f98 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000501a:	e2043d03          	ld	s10,-480(s0)
    8000501e:	df043783          	ld	a5,-528(s0)
    80005022:	00fd77b3          	and	a5,s10,a5
    80005026:	fba1                	bnez	a5,80004f76 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005028:	e1842d83          	lw	s11,-488(s0)
    8000502c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005030:	f80c03e3          	beqz	s8,80004fb6 <exec+0x306>
    80005034:	8a62                	mv	s4,s8
    80005036:	4901                	li	s2,0
    80005038:	b345                	j	80004dd8 <exec+0x128>

000000008000503a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000503a:	7179                	addi	sp,sp,-48
    8000503c:	f406                	sd	ra,40(sp)
    8000503e:	f022                	sd	s0,32(sp)
    80005040:	ec26                	sd	s1,24(sp)
    80005042:	e84a                	sd	s2,16(sp)
    80005044:	1800                	addi	s0,sp,48
    80005046:	892e                	mv	s2,a1
    80005048:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000504a:	fdc40593          	addi	a1,s0,-36
    8000504e:	ffffe097          	auipc	ra,0xffffe
    80005052:	afc080e7          	jalr	-1284(ra) # 80002b4a <argint>
    80005056:	04054063          	bltz	a0,80005096 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000505a:	fdc42703          	lw	a4,-36(s0)
    8000505e:	47bd                	li	a5,15
    80005060:	02e7ed63          	bltu	a5,a4,8000509a <argfd+0x60>
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	9de080e7          	jalr	-1570(ra) # 80001a42 <myproc>
    8000506c:	fdc42703          	lw	a4,-36(s0)
    80005070:	01a70793          	addi	a5,a4,26
    80005074:	078e                	slli	a5,a5,0x3
    80005076:	953e                	add	a0,a0,a5
    80005078:	611c                	ld	a5,0(a0)
    8000507a:	c395                	beqz	a5,8000509e <argfd+0x64>
    return -1;
  if(pfd)
    8000507c:	00090463          	beqz	s2,80005084 <argfd+0x4a>
    *pfd = fd;
    80005080:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005084:	4501                	li	a0,0
  if(pf)
    80005086:	c091                	beqz	s1,8000508a <argfd+0x50>
    *pf = f;
    80005088:	e09c                	sd	a5,0(s1)
}
    8000508a:	70a2                	ld	ra,40(sp)
    8000508c:	7402                	ld	s0,32(sp)
    8000508e:	64e2                	ld	s1,24(sp)
    80005090:	6942                	ld	s2,16(sp)
    80005092:	6145                	addi	sp,sp,48
    80005094:	8082                	ret
    return -1;
    80005096:	557d                	li	a0,-1
    80005098:	bfcd                	j	8000508a <argfd+0x50>
    return -1;
    8000509a:	557d                	li	a0,-1
    8000509c:	b7fd                	j	8000508a <argfd+0x50>
    8000509e:	557d                	li	a0,-1
    800050a0:	b7ed                	j	8000508a <argfd+0x50>

00000000800050a2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a2:	1101                	addi	sp,sp,-32
    800050a4:	ec06                	sd	ra,24(sp)
    800050a6:	e822                	sd	s0,16(sp)
    800050a8:	e426                	sd	s1,8(sp)
    800050aa:	1000                	addi	s0,sp,32
    800050ac:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	994080e7          	jalr	-1644(ra) # 80001a42 <myproc>
    800050b6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050b8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    800050bc:	4501                	li	a0,0
    800050be:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050c0:	6398                	ld	a4,0(a5)
    800050c2:	cb19                	beqz	a4,800050d8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c4:	2505                	addiw	a0,a0,1
    800050c6:	07a1                	addi	a5,a5,8
    800050c8:	fed51ce3          	bne	a0,a3,800050c0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050cc:	557d                	li	a0,-1
}
    800050ce:	60e2                	ld	ra,24(sp)
    800050d0:	6442                	ld	s0,16(sp)
    800050d2:	64a2                	ld	s1,8(sp)
    800050d4:	6105                	addi	sp,sp,32
    800050d6:	8082                	ret
      p->ofile[fd] = f;
    800050d8:	01a50793          	addi	a5,a0,26
    800050dc:	078e                	slli	a5,a5,0x3
    800050de:	963e                	add	a2,a2,a5
    800050e0:	e204                	sd	s1,0(a2)
      return fd;
    800050e2:	b7f5                	j	800050ce <fdalloc+0x2c>

00000000800050e4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e4:	715d                	addi	sp,sp,-80
    800050e6:	e486                	sd	ra,72(sp)
    800050e8:	e0a2                	sd	s0,64(sp)
    800050ea:	fc26                	sd	s1,56(sp)
    800050ec:	f84a                	sd	s2,48(sp)
    800050ee:	f44e                	sd	s3,40(sp)
    800050f0:	f052                	sd	s4,32(sp)
    800050f2:	ec56                	sd	s5,24(sp)
    800050f4:	0880                	addi	s0,sp,80
    800050f6:	89ae                	mv	s3,a1
    800050f8:	8ab2                	mv	s5,a2
    800050fa:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050fc:	fb040593          	addi	a1,s0,-80
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	e40080e7          	jalr	-448(ra) # 80003f40 <nameiparent>
    80005108:	892a                	mv	s2,a0
    8000510a:	12050f63          	beqz	a0,80005248 <create+0x164>
    return 0;

  ilock(dp);
    8000510e:	ffffe097          	auipc	ra,0xffffe
    80005112:	664080e7          	jalr	1636(ra) # 80003772 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005116:	4601                	li	a2,0
    80005118:	fb040593          	addi	a1,s0,-80
    8000511c:	854a                	mv	a0,s2
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	b32080e7          	jalr	-1230(ra) # 80003c50 <dirlookup>
    80005126:	84aa                	mv	s1,a0
    80005128:	c921                	beqz	a0,80005178 <create+0x94>
    iunlockput(dp);
    8000512a:	854a                	mv	a0,s2
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	8a8080e7          	jalr	-1880(ra) # 800039d4 <iunlockput>
    ilock(ip);
    80005134:	8526                	mv	a0,s1
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	63c080e7          	jalr	1596(ra) # 80003772 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000513e:	2981                	sext.w	s3,s3
    80005140:	4789                	li	a5,2
    80005142:	02f99463          	bne	s3,a5,8000516a <create+0x86>
    80005146:	0444d783          	lhu	a5,68(s1)
    8000514a:	37f9                	addiw	a5,a5,-2
    8000514c:	17c2                	slli	a5,a5,0x30
    8000514e:	93c1                	srli	a5,a5,0x30
    80005150:	4705                	li	a4,1
    80005152:	00f76c63          	bltu	a4,a5,8000516a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005156:	8526                	mv	a0,s1
    80005158:	60a6                	ld	ra,72(sp)
    8000515a:	6406                	ld	s0,64(sp)
    8000515c:	74e2                	ld	s1,56(sp)
    8000515e:	7942                	ld	s2,48(sp)
    80005160:	79a2                	ld	s3,40(sp)
    80005162:	7a02                	ld	s4,32(sp)
    80005164:	6ae2                	ld	s5,24(sp)
    80005166:	6161                	addi	sp,sp,80
    80005168:	8082                	ret
    iunlockput(ip);
    8000516a:	8526                	mv	a0,s1
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	868080e7          	jalr	-1944(ra) # 800039d4 <iunlockput>
    return 0;
    80005174:	4481                	li	s1,0
    80005176:	b7c5                	j	80005156 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005178:	85ce                	mv	a1,s3
    8000517a:	00092503          	lw	a0,0(s2)
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	45c080e7          	jalr	1116(ra) # 800035da <ialloc>
    80005186:	84aa                	mv	s1,a0
    80005188:	c529                	beqz	a0,800051d2 <create+0xee>
  ilock(ip);
    8000518a:	ffffe097          	auipc	ra,0xffffe
    8000518e:	5e8080e7          	jalr	1512(ra) # 80003772 <ilock>
  ip->major = major;
    80005192:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005196:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000519a:	4785                	li	a5,1
    8000519c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051a0:	8526                	mv	a0,s1
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	506080e7          	jalr	1286(ra) # 800036a8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051aa:	2981                	sext.w	s3,s3
    800051ac:	4785                	li	a5,1
    800051ae:	02f98a63          	beq	s3,a5,800051e2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051b2:	40d0                	lw	a2,4(s1)
    800051b4:	fb040593          	addi	a1,s0,-80
    800051b8:	854a                	mv	a0,s2
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	ca6080e7          	jalr	-858(ra) # 80003e60 <dirlink>
    800051c2:	06054b63          	bltz	a0,80005238 <create+0x154>
  iunlockput(dp);
    800051c6:	854a                	mv	a0,s2
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	80c080e7          	jalr	-2036(ra) # 800039d4 <iunlockput>
  return ip;
    800051d0:	b759                	j	80005156 <create+0x72>
    panic("create: ialloc");
    800051d2:	00003517          	auipc	a0,0x3
    800051d6:	52e50513          	addi	a0,a0,1326 # 80008700 <syscalls+0x2c0>
    800051da:	ffffb097          	auipc	ra,0xffffb
    800051de:	3fc080e7          	jalr	1020(ra) # 800005d6 <panic>
    dp->nlink++;  // for ".."
    800051e2:	04a95783          	lhu	a5,74(s2)
    800051e6:	2785                	addiw	a5,a5,1
    800051e8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051ec:	854a                	mv	a0,s2
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	4ba080e7          	jalr	1210(ra) # 800036a8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f6:	40d0                	lw	a2,4(s1)
    800051f8:	00003597          	auipc	a1,0x3
    800051fc:	51858593          	addi	a1,a1,1304 # 80008710 <syscalls+0x2d0>
    80005200:	8526                	mv	a0,s1
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	c5e080e7          	jalr	-930(ra) # 80003e60 <dirlink>
    8000520a:	00054f63          	bltz	a0,80005228 <create+0x144>
    8000520e:	00492603          	lw	a2,4(s2)
    80005212:	00003597          	auipc	a1,0x3
    80005216:	50658593          	addi	a1,a1,1286 # 80008718 <syscalls+0x2d8>
    8000521a:	8526                	mv	a0,s1
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	c44080e7          	jalr	-956(ra) # 80003e60 <dirlink>
    80005224:	f80557e3          	bgez	a0,800051b2 <create+0xce>
      panic("create dots");
    80005228:	00003517          	auipc	a0,0x3
    8000522c:	4f850513          	addi	a0,a0,1272 # 80008720 <syscalls+0x2e0>
    80005230:	ffffb097          	auipc	ra,0xffffb
    80005234:	3a6080e7          	jalr	934(ra) # 800005d6 <panic>
    panic("create: dirlink");
    80005238:	00003517          	auipc	a0,0x3
    8000523c:	4f850513          	addi	a0,a0,1272 # 80008730 <syscalls+0x2f0>
    80005240:	ffffb097          	auipc	ra,0xffffb
    80005244:	396080e7          	jalr	918(ra) # 800005d6 <panic>
    return 0;
    80005248:	84aa                	mv	s1,a0
    8000524a:	b731                	j	80005156 <create+0x72>

000000008000524c <sys_dup>:
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	ec26                	sd	s1,24(sp)
    80005254:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005256:	fd840613          	addi	a2,s0,-40
    8000525a:	4581                	li	a1,0
    8000525c:	4501                	li	a0,0
    8000525e:	00000097          	auipc	ra,0x0
    80005262:	ddc080e7          	jalr	-548(ra) # 8000503a <argfd>
    return -1;
    80005266:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005268:	02054363          	bltz	a0,8000528e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000526c:	fd843503          	ld	a0,-40(s0)
    80005270:	00000097          	auipc	ra,0x0
    80005274:	e32080e7          	jalr	-462(ra) # 800050a2 <fdalloc>
    80005278:	84aa                	mv	s1,a0
    return -1;
    8000527a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000527c:	00054963          	bltz	a0,8000528e <sys_dup+0x42>
  filedup(f);
    80005280:	fd843503          	ld	a0,-40(s0)
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	32a080e7          	jalr	810(ra) # 800045ae <filedup>
  return fd;
    8000528c:	87a6                	mv	a5,s1
}
    8000528e:	853e                	mv	a0,a5
    80005290:	70a2                	ld	ra,40(sp)
    80005292:	7402                	ld	s0,32(sp)
    80005294:	64e2                	ld	s1,24(sp)
    80005296:	6145                	addi	sp,sp,48
    80005298:	8082                	ret

000000008000529a <sys_read>:
{
    8000529a:	7179                	addi	sp,sp,-48
    8000529c:	f406                	sd	ra,40(sp)
    8000529e:	f022                	sd	s0,32(sp)
    800052a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	fe840613          	addi	a2,s0,-24
    800052a6:	4581                	li	a1,0
    800052a8:	4501                	li	a0,0
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	d90080e7          	jalr	-624(ra) # 8000503a <argfd>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b4:	04054163          	bltz	a0,800052f6 <sys_read+0x5c>
    800052b8:	fe440593          	addi	a1,s0,-28
    800052bc:	4509                	li	a0,2
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	88c080e7          	jalr	-1908(ra) # 80002b4a <argint>
    return -1;
    800052c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c8:	02054763          	bltz	a0,800052f6 <sys_read+0x5c>
    800052cc:	fd840593          	addi	a1,s0,-40
    800052d0:	4505                	li	a0,1
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	89a080e7          	jalr	-1894(ra) # 80002b6c <argaddr>
    return -1;
    800052da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052dc:	00054d63          	bltz	a0,800052f6 <sys_read+0x5c>
  return fileread(f, p, n);
    800052e0:	fe442603          	lw	a2,-28(s0)
    800052e4:	fd843583          	ld	a1,-40(s0)
    800052e8:	fe843503          	ld	a0,-24(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	44e080e7          	jalr	1102(ra) # 8000473a <fileread>
    800052f4:	87aa                	mv	a5,a0
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	6145                	addi	sp,sp,48
    800052fe:	8082                	ret

0000000080005300 <sys_write>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005308:	fe840613          	addi	a2,s0,-24
    8000530c:	4581                	li	a1,0
    8000530e:	4501                	li	a0,0
    80005310:	00000097          	auipc	ra,0x0
    80005314:	d2a080e7          	jalr	-726(ra) # 8000503a <argfd>
    return -1;
    80005318:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531a:	04054163          	bltz	a0,8000535c <sys_write+0x5c>
    8000531e:	fe440593          	addi	a1,s0,-28
    80005322:	4509                	li	a0,2
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	826080e7          	jalr	-2010(ra) # 80002b4a <argint>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532e:	02054763          	bltz	a0,8000535c <sys_write+0x5c>
    80005332:	fd840593          	addi	a1,s0,-40
    80005336:	4505                	li	a0,1
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	834080e7          	jalr	-1996(ra) # 80002b6c <argaddr>
    return -1;
    80005340:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005342:	00054d63          	bltz	a0,8000535c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005346:	fe442603          	lw	a2,-28(s0)
    8000534a:	fd843583          	ld	a1,-40(s0)
    8000534e:	fe843503          	ld	a0,-24(s0)
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	4aa080e7          	jalr	1194(ra) # 800047fc <filewrite>
    8000535a:	87aa                	mv	a5,a0
}
    8000535c:	853e                	mv	a0,a5
    8000535e:	70a2                	ld	ra,40(sp)
    80005360:	7402                	ld	s0,32(sp)
    80005362:	6145                	addi	sp,sp,48
    80005364:	8082                	ret

0000000080005366 <sys_close>:
{
    80005366:	1101                	addi	sp,sp,-32
    80005368:	ec06                	sd	ra,24(sp)
    8000536a:	e822                	sd	s0,16(sp)
    8000536c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000536e:	fe040613          	addi	a2,s0,-32
    80005372:	fec40593          	addi	a1,s0,-20
    80005376:	4501                	li	a0,0
    80005378:	00000097          	auipc	ra,0x0
    8000537c:	cc2080e7          	jalr	-830(ra) # 8000503a <argfd>
    return -1;
    80005380:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005382:	02054463          	bltz	a0,800053aa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	6bc080e7          	jalr	1724(ra) # 80001a42 <myproc>
    8000538e:	fec42783          	lw	a5,-20(s0)
    80005392:	07e9                	addi	a5,a5,26
    80005394:	078e                	slli	a5,a5,0x3
    80005396:	97aa                	add	a5,a5,a0
    80005398:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000539c:	fe043503          	ld	a0,-32(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	260080e7          	jalr	608(ra) # 80004600 <fileclose>
  return 0;
    800053a8:	4781                	li	a5,0
}
    800053aa:	853e                	mv	a0,a5
    800053ac:	60e2                	ld	ra,24(sp)
    800053ae:	6442                	ld	s0,16(sp)
    800053b0:	6105                	addi	sp,sp,32
    800053b2:	8082                	ret

00000000800053b4 <sys_fstat>:
{
    800053b4:	1101                	addi	sp,sp,-32
    800053b6:	ec06                	sd	ra,24(sp)
    800053b8:	e822                	sd	s0,16(sp)
    800053ba:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053bc:	fe840613          	addi	a2,s0,-24
    800053c0:	4581                	li	a1,0
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	c76080e7          	jalr	-906(ra) # 8000503a <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ce:	02054563          	bltz	a0,800053f8 <sys_fstat+0x44>
    800053d2:	fe040593          	addi	a1,s0,-32
    800053d6:	4505                	li	a0,1
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	794080e7          	jalr	1940(ra) # 80002b6c <argaddr>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e2:	00054b63          	bltz	a0,800053f8 <sys_fstat+0x44>
  return filestat(f, st);
    800053e6:	fe043583          	ld	a1,-32(s0)
    800053ea:	fe843503          	ld	a0,-24(s0)
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	2da080e7          	jalr	730(ra) # 800046c8 <filestat>
    800053f6:	87aa                	mv	a5,a0
}
    800053f8:	853e                	mv	a0,a5
    800053fa:	60e2                	ld	ra,24(sp)
    800053fc:	6442                	ld	s0,16(sp)
    800053fe:	6105                	addi	sp,sp,32
    80005400:	8082                	ret

0000000080005402 <sys_link>:
{
    80005402:	7169                	addi	sp,sp,-304
    80005404:	f606                	sd	ra,296(sp)
    80005406:	f222                	sd	s0,288(sp)
    80005408:	ee26                	sd	s1,280(sp)
    8000540a:	ea4a                	sd	s2,272(sp)
    8000540c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000540e:	08000613          	li	a2,128
    80005412:	ed040593          	addi	a1,s0,-304
    80005416:	4501                	li	a0,0
    80005418:	ffffd097          	auipc	ra,0xffffd
    8000541c:	776080e7          	jalr	1910(ra) # 80002b8e <argstr>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005422:	10054e63          	bltz	a0,8000553e <sys_link+0x13c>
    80005426:	08000613          	li	a2,128
    8000542a:	f5040593          	addi	a1,s0,-176
    8000542e:	4505                	li	a0,1
    80005430:	ffffd097          	auipc	ra,0xffffd
    80005434:	75e080e7          	jalr	1886(ra) # 80002b8e <argstr>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543a:	10054263          	bltz	a0,8000553e <sys_link+0x13c>
  begin_op();
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	cf0080e7          	jalr	-784(ra) # 8000412e <begin_op>
  if((ip = namei(old)) == 0){
    80005446:	ed040513          	addi	a0,s0,-304
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	ad8080e7          	jalr	-1320(ra) # 80003f22 <namei>
    80005452:	84aa                	mv	s1,a0
    80005454:	c551                	beqz	a0,800054e0 <sys_link+0xde>
  ilock(ip);
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	31c080e7          	jalr	796(ra) # 80003772 <ilock>
  if(ip->type == T_DIR){
    8000545e:	04449703          	lh	a4,68(s1)
    80005462:	4785                	li	a5,1
    80005464:	08f70463          	beq	a4,a5,800054ec <sys_link+0xea>
  ip->nlink++;
    80005468:	04a4d783          	lhu	a5,74(s1)
    8000546c:	2785                	addiw	a5,a5,1
    8000546e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	234080e7          	jalr	564(ra) # 800036a8 <iupdate>
  iunlock(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	3b6080e7          	jalr	950(ra) # 80003834 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005486:	fd040593          	addi	a1,s0,-48
    8000548a:	f5040513          	addi	a0,s0,-176
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	ab2080e7          	jalr	-1358(ra) # 80003f40 <nameiparent>
    80005496:	892a                	mv	s2,a0
    80005498:	c935                	beqz	a0,8000550c <sys_link+0x10a>
  ilock(dp);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	2d8080e7          	jalr	728(ra) # 80003772 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a2:	00092703          	lw	a4,0(s2)
    800054a6:	409c                	lw	a5,0(s1)
    800054a8:	04f71d63          	bne	a4,a5,80005502 <sys_link+0x100>
    800054ac:	40d0                	lw	a2,4(s1)
    800054ae:	fd040593          	addi	a1,s0,-48
    800054b2:	854a                	mv	a0,s2
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	9ac080e7          	jalr	-1620(ra) # 80003e60 <dirlink>
    800054bc:	04054363          	bltz	a0,80005502 <sys_link+0x100>
  iunlockput(dp);
    800054c0:	854a                	mv	a0,s2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	512080e7          	jalr	1298(ra) # 800039d4 <iunlockput>
  iput(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	460080e7          	jalr	1120(ra) # 8000392c <iput>
  end_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	cda080e7          	jalr	-806(ra) # 800041ae <end_op>
  return 0;
    800054dc:	4781                	li	a5,0
    800054de:	a085                	j	8000553e <sys_link+0x13c>
    end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	cce080e7          	jalr	-818(ra) # 800041ae <end_op>
    return -1;
    800054e8:	57fd                	li	a5,-1
    800054ea:	a891                	j	8000553e <sys_link+0x13c>
    iunlockput(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	4e6080e7          	jalr	1254(ra) # 800039d4 <iunlockput>
    end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	cb8080e7          	jalr	-840(ra) # 800041ae <end_op>
    return -1;
    800054fe:	57fd                	li	a5,-1
    80005500:	a83d                	j	8000553e <sys_link+0x13c>
    iunlockput(dp);
    80005502:	854a                	mv	a0,s2
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	4d0080e7          	jalr	1232(ra) # 800039d4 <iunlockput>
  ilock(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	264080e7          	jalr	612(ra) # 80003772 <ilock>
  ip->nlink--;
    80005516:	04a4d783          	lhu	a5,74(s1)
    8000551a:	37fd                	addiw	a5,a5,-1
    8000551c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	186080e7          	jalr	390(ra) # 800036a8 <iupdate>
  iunlockput(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	4a8080e7          	jalr	1192(ra) # 800039d4 <iunlockput>
  end_op();
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	c7a080e7          	jalr	-902(ra) # 800041ae <end_op>
  return -1;
    8000553c:	57fd                	li	a5,-1
}
    8000553e:	853e                	mv	a0,a5
    80005540:	70b2                	ld	ra,296(sp)
    80005542:	7412                	ld	s0,288(sp)
    80005544:	64f2                	ld	s1,280(sp)
    80005546:	6952                	ld	s2,272(sp)
    80005548:	6155                	addi	sp,sp,304
    8000554a:	8082                	ret

000000008000554c <sys_unlink>:
{
    8000554c:	7151                	addi	sp,sp,-240
    8000554e:	f586                	sd	ra,232(sp)
    80005550:	f1a2                	sd	s0,224(sp)
    80005552:	eda6                	sd	s1,216(sp)
    80005554:	e9ca                	sd	s2,208(sp)
    80005556:	e5ce                	sd	s3,200(sp)
    80005558:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000555a:	08000613          	li	a2,128
    8000555e:	f3040593          	addi	a1,s0,-208
    80005562:	4501                	li	a0,0
    80005564:	ffffd097          	auipc	ra,0xffffd
    80005568:	62a080e7          	jalr	1578(ra) # 80002b8e <argstr>
    8000556c:	18054163          	bltz	a0,800056ee <sys_unlink+0x1a2>
  begin_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	bbe080e7          	jalr	-1090(ra) # 8000412e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005578:	fb040593          	addi	a1,s0,-80
    8000557c:	f3040513          	addi	a0,s0,-208
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	9c0080e7          	jalr	-1600(ra) # 80003f40 <nameiparent>
    80005588:	84aa                	mv	s1,a0
    8000558a:	c979                	beqz	a0,80005660 <sys_unlink+0x114>
  ilock(dp);
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	1e6080e7          	jalr	486(ra) # 80003772 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005594:	00003597          	auipc	a1,0x3
    80005598:	17c58593          	addi	a1,a1,380 # 80008710 <syscalls+0x2d0>
    8000559c:	fb040513          	addi	a0,s0,-80
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	696080e7          	jalr	1686(ra) # 80003c36 <namecmp>
    800055a8:	14050a63          	beqz	a0,800056fc <sys_unlink+0x1b0>
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	16c58593          	addi	a1,a1,364 # 80008718 <syscalls+0x2d8>
    800055b4:	fb040513          	addi	a0,s0,-80
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	67e080e7          	jalr	1662(ra) # 80003c36 <namecmp>
    800055c0:	12050e63          	beqz	a0,800056fc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055c4:	f2c40613          	addi	a2,s0,-212
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	682080e7          	jalr	1666(ra) # 80003c50 <dirlookup>
    800055d6:	892a                	mv	s2,a0
    800055d8:	12050263          	beqz	a0,800056fc <sys_unlink+0x1b0>
  ilock(ip);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	196080e7          	jalr	406(ra) # 80003772 <ilock>
  if(ip->nlink < 1)
    800055e4:	04a91783          	lh	a5,74(s2)
    800055e8:	08f05263          	blez	a5,8000566c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	4785                	li	a5,1
    800055f2:	08f70563          	beq	a4,a5,8000567c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055f6:	4641                	li	a2,16
    800055f8:	4581                	li	a1,0
    800055fa:	fc040513          	addi	a0,s0,-64
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	772080e7          	jalr	1906(ra) # 80000d70 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005606:	4741                	li	a4,16
    80005608:	f2c42683          	lw	a3,-212(s0)
    8000560c:	fc040613          	addi	a2,s0,-64
    80005610:	4581                	li	a1,0
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	508080e7          	jalr	1288(ra) # 80003b1c <writei>
    8000561c:	47c1                	li	a5,16
    8000561e:	0af51563          	bne	a0,a5,800056c8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005622:	04491703          	lh	a4,68(s2)
    80005626:	4785                	li	a5,1
    80005628:	0af70863          	beq	a4,a5,800056d8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	3a6080e7          	jalr	934(ra) # 800039d4 <iunlockput>
  ip->nlink--;
    80005636:	04a95783          	lhu	a5,74(s2)
    8000563a:	37fd                	addiw	a5,a5,-1
    8000563c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005640:	854a                	mv	a0,s2
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	066080e7          	jalr	102(ra) # 800036a8 <iupdate>
  iunlockput(ip);
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	388080e7          	jalr	904(ra) # 800039d4 <iunlockput>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	b5a080e7          	jalr	-1190(ra) # 800041ae <end_op>
  return 0;
    8000565c:	4501                	li	a0,0
    8000565e:	a84d                	j	80005710 <sys_unlink+0x1c4>
    end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	b4e080e7          	jalr	-1202(ra) # 800041ae <end_op>
    return -1;
    80005668:	557d                	li	a0,-1
    8000566a:	a05d                	j	80005710 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000566c:	00003517          	auipc	a0,0x3
    80005670:	0d450513          	addi	a0,a0,212 # 80008740 <syscalls+0x300>
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	f62080e7          	jalr	-158(ra) # 800005d6 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000567c:	04c92703          	lw	a4,76(s2)
    80005680:	02000793          	li	a5,32
    80005684:	f6e7f9e3          	bgeu	a5,a4,800055f6 <sys_unlink+0xaa>
    80005688:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000568c:	4741                	li	a4,16
    8000568e:	86ce                	mv	a3,s3
    80005690:	f1840613          	addi	a2,s0,-232
    80005694:	4581                	li	a1,0
    80005696:	854a                	mv	a0,s2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	38e080e7          	jalr	910(ra) # 80003a26 <readi>
    800056a0:	47c1                	li	a5,16
    800056a2:	00f51b63          	bne	a0,a5,800056b8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056a6:	f1845783          	lhu	a5,-232(s0)
    800056aa:	e7a1                	bnez	a5,800056f2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ac:	29c1                	addiw	s3,s3,16
    800056ae:	04c92783          	lw	a5,76(s2)
    800056b2:	fcf9ede3          	bltu	s3,a5,8000568c <sys_unlink+0x140>
    800056b6:	b781                	j	800055f6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056b8:	00003517          	auipc	a0,0x3
    800056bc:	0a050513          	addi	a0,a0,160 # 80008758 <syscalls+0x318>
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	f16080e7          	jalr	-234(ra) # 800005d6 <panic>
    panic("unlink: writei");
    800056c8:	00003517          	auipc	a0,0x3
    800056cc:	0a850513          	addi	a0,a0,168 # 80008770 <syscalls+0x330>
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	f06080e7          	jalr	-250(ra) # 800005d6 <panic>
    dp->nlink--;
    800056d8:	04a4d783          	lhu	a5,74(s1)
    800056dc:	37fd                	addiw	a5,a5,-1
    800056de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	fc4080e7          	jalr	-60(ra) # 800036a8 <iupdate>
    800056ec:	b781                	j	8000562c <sys_unlink+0xe0>
    return -1;
    800056ee:	557d                	li	a0,-1
    800056f0:	a005                	j	80005710 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f2:	854a                	mv	a0,s2
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	2e0080e7          	jalr	736(ra) # 800039d4 <iunlockput>
  iunlockput(dp);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	2d6080e7          	jalr	726(ra) # 800039d4 <iunlockput>
  end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	aa8080e7          	jalr	-1368(ra) # 800041ae <end_op>
  return -1;
    8000570e:	557d                	li	a0,-1
}
    80005710:	70ae                	ld	ra,232(sp)
    80005712:	740e                	ld	s0,224(sp)
    80005714:	64ee                	ld	s1,216(sp)
    80005716:	694e                	ld	s2,208(sp)
    80005718:	69ae                	ld	s3,200(sp)
    8000571a:	616d                	addi	sp,sp,240
    8000571c:	8082                	ret

000000008000571e <sys_open>:

uint64
sys_open(void)
{
    8000571e:	7131                	addi	sp,sp,-192
    80005720:	fd06                	sd	ra,184(sp)
    80005722:	f922                	sd	s0,176(sp)
    80005724:	f526                	sd	s1,168(sp)
    80005726:	f14a                	sd	s2,160(sp)
    80005728:	ed4e                	sd	s3,152(sp)
    8000572a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000572c:	08000613          	li	a2,128
    80005730:	f5040593          	addi	a1,s0,-176
    80005734:	4501                	li	a0,0
    80005736:	ffffd097          	auipc	ra,0xffffd
    8000573a:	458080e7          	jalr	1112(ra) # 80002b8e <argstr>
    return -1;
    8000573e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005740:	0c054163          	bltz	a0,80005802 <sys_open+0xe4>
    80005744:	f4c40593          	addi	a1,s0,-180
    80005748:	4505                	li	a0,1
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	400080e7          	jalr	1024(ra) # 80002b4a <argint>
    80005752:	0a054863          	bltz	a0,80005802 <sys_open+0xe4>

  begin_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	9d8080e7          	jalr	-1576(ra) # 8000412e <begin_op>

  if(omode & O_CREATE){
    8000575e:	f4c42783          	lw	a5,-180(s0)
    80005762:	2007f793          	andi	a5,a5,512
    80005766:	cbdd                	beqz	a5,8000581c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005768:	4681                	li	a3,0
    8000576a:	4601                	li	a2,0
    8000576c:	4589                	li	a1,2
    8000576e:	f5040513          	addi	a0,s0,-176
    80005772:	00000097          	auipc	ra,0x0
    80005776:	972080e7          	jalr	-1678(ra) # 800050e4 <create>
    8000577a:	892a                	mv	s2,a0
    if(ip == 0){
    8000577c:	c959                	beqz	a0,80005812 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000577e:	04491703          	lh	a4,68(s2)
    80005782:	478d                	li	a5,3
    80005784:	00f71763          	bne	a4,a5,80005792 <sys_open+0x74>
    80005788:	04695703          	lhu	a4,70(s2)
    8000578c:	47a5                	li	a5,9
    8000578e:	0ce7ec63          	bltu	a5,a4,80005866 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	db2080e7          	jalr	-590(ra) # 80004544 <filealloc>
    8000579a:	89aa                	mv	s3,a0
    8000579c:	10050263          	beqz	a0,800058a0 <sys_open+0x182>
    800057a0:	00000097          	auipc	ra,0x0
    800057a4:	902080e7          	jalr	-1790(ra) # 800050a2 <fdalloc>
    800057a8:	84aa                	mv	s1,a0
    800057aa:	0e054663          	bltz	a0,80005896 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ae:	04491703          	lh	a4,68(s2)
    800057b2:	478d                	li	a5,3
    800057b4:	0cf70463          	beq	a4,a5,8000587c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057b8:	4789                	li	a5,2
    800057ba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057be:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057c6:	f4c42783          	lw	a5,-180(s0)
    800057ca:	0017c713          	xori	a4,a5,1
    800057ce:	8b05                	andi	a4,a4,1
    800057d0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057d4:	0037f713          	andi	a4,a5,3
    800057d8:	00e03733          	snez	a4,a4
    800057dc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e0:	4007f793          	andi	a5,a5,1024
    800057e4:	c791                	beqz	a5,800057f0 <sys_open+0xd2>
    800057e6:	04491703          	lh	a4,68(s2)
    800057ea:	4789                	li	a5,2
    800057ec:	08f70f63          	beq	a4,a5,8000588a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	042080e7          	jalr	66(ra) # 80003834 <iunlock>
  end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	9b4080e7          	jalr	-1612(ra) # 800041ae <end_op>

  return fd;
}
    80005802:	8526                	mv	a0,s1
    80005804:	70ea                	ld	ra,184(sp)
    80005806:	744a                	ld	s0,176(sp)
    80005808:	74aa                	ld	s1,168(sp)
    8000580a:	790a                	ld	s2,160(sp)
    8000580c:	69ea                	ld	s3,152(sp)
    8000580e:	6129                	addi	sp,sp,192
    80005810:	8082                	ret
      end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	99c080e7          	jalr	-1636(ra) # 800041ae <end_op>
      return -1;
    8000581a:	b7e5                	j	80005802 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000581c:	f5040513          	addi	a0,s0,-176
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	702080e7          	jalr	1794(ra) # 80003f22 <namei>
    80005828:	892a                	mv	s2,a0
    8000582a:	c905                	beqz	a0,8000585a <sys_open+0x13c>
    ilock(ip);
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	f46080e7          	jalr	-186(ra) # 80003772 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005834:	04491703          	lh	a4,68(s2)
    80005838:	4785                	li	a5,1
    8000583a:	f4f712e3          	bne	a4,a5,8000577e <sys_open+0x60>
    8000583e:	f4c42783          	lw	a5,-180(s0)
    80005842:	dba1                	beqz	a5,80005792 <sys_open+0x74>
      iunlockput(ip);
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	18e080e7          	jalr	398(ra) # 800039d4 <iunlockput>
      end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	960080e7          	jalr	-1696(ra) # 800041ae <end_op>
      return -1;
    80005856:	54fd                	li	s1,-1
    80005858:	b76d                	j	80005802 <sys_open+0xe4>
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	954080e7          	jalr	-1708(ra) # 800041ae <end_op>
      return -1;
    80005862:	54fd                	li	s1,-1
    80005864:	bf79                	j	80005802 <sys_open+0xe4>
    iunlockput(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	16c080e7          	jalr	364(ra) # 800039d4 <iunlockput>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	93e080e7          	jalr	-1730(ra) # 800041ae <end_op>
    return -1;
    80005878:	54fd                	li	s1,-1
    8000587a:	b761                	j	80005802 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000587c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005880:	04691783          	lh	a5,70(s2)
    80005884:	02f99223          	sh	a5,36(s3)
    80005888:	bf2d                	j	800057c2 <sys_open+0xa4>
    itrunc(ip);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	ff4080e7          	jalr	-12(ra) # 80003880 <itrunc>
    80005894:	bfb1                	j	800057f0 <sys_open+0xd2>
      fileclose(f);
    80005896:	854e                	mv	a0,s3
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	d68080e7          	jalr	-664(ra) # 80004600 <fileclose>
    iunlockput(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	132080e7          	jalr	306(ra) # 800039d4 <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	904080e7          	jalr	-1788(ra) # 800041ae <end_op>
    return -1;
    800058b2:	54fd                	li	s1,-1
    800058b4:	b7b9                	j	80005802 <sys_open+0xe4>

00000000800058b6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058b6:	7175                	addi	sp,sp,-144
    800058b8:	e506                	sd	ra,136(sp)
    800058ba:	e122                	sd	s0,128(sp)
    800058bc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	870080e7          	jalr	-1936(ra) # 8000412e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058c6:	08000613          	li	a2,128
    800058ca:	f7040593          	addi	a1,s0,-144
    800058ce:	4501                	li	a0,0
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	2be080e7          	jalr	702(ra) # 80002b8e <argstr>
    800058d8:	02054963          	bltz	a0,8000590a <sys_mkdir+0x54>
    800058dc:	4681                	li	a3,0
    800058de:	4601                	li	a2,0
    800058e0:	4585                	li	a1,1
    800058e2:	f7040513          	addi	a0,s0,-144
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	7fe080e7          	jalr	2046(ra) # 800050e4 <create>
    800058ee:	cd11                	beqz	a0,8000590a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	0e4080e7          	jalr	228(ra) # 800039d4 <iunlockput>
  end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	8b6080e7          	jalr	-1866(ra) # 800041ae <end_op>
  return 0;
    80005900:	4501                	li	a0,0
}
    80005902:	60aa                	ld	ra,136(sp)
    80005904:	640a                	ld	s0,128(sp)
    80005906:	6149                	addi	sp,sp,144
    80005908:	8082                	ret
    end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	8a4080e7          	jalr	-1884(ra) # 800041ae <end_op>
    return -1;
    80005912:	557d                	li	a0,-1
    80005914:	b7fd                	j	80005902 <sys_mkdir+0x4c>

0000000080005916 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005916:	7135                	addi	sp,sp,-160
    80005918:	ed06                	sd	ra,152(sp)
    8000591a:	e922                	sd	s0,144(sp)
    8000591c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	810080e7          	jalr	-2032(ra) # 8000412e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005926:	08000613          	li	a2,128
    8000592a:	f7040593          	addi	a1,s0,-144
    8000592e:	4501                	li	a0,0
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	25e080e7          	jalr	606(ra) # 80002b8e <argstr>
    80005938:	04054a63          	bltz	a0,8000598c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000593c:	f6c40593          	addi	a1,s0,-148
    80005940:	4505                	li	a0,1
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	208080e7          	jalr	520(ra) # 80002b4a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594a:	04054163          	bltz	a0,8000598c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000594e:	f6840593          	addi	a1,s0,-152
    80005952:	4509                	li	a0,2
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	1f6080e7          	jalr	502(ra) # 80002b4a <argint>
     argint(1, &major) < 0 ||
    8000595c:	02054863          	bltz	a0,8000598c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005960:	f6841683          	lh	a3,-152(s0)
    80005964:	f6c41603          	lh	a2,-148(s0)
    80005968:	458d                	li	a1,3
    8000596a:	f7040513          	addi	a0,s0,-144
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	776080e7          	jalr	1910(ra) # 800050e4 <create>
     argint(2, &minor) < 0 ||
    80005976:	c919                	beqz	a0,8000598c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	05c080e7          	jalr	92(ra) # 800039d4 <iunlockput>
  end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	82e080e7          	jalr	-2002(ra) # 800041ae <end_op>
  return 0;
    80005988:	4501                	li	a0,0
    8000598a:	a031                	j	80005996 <sys_mknod+0x80>
    end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	822080e7          	jalr	-2014(ra) # 800041ae <end_op>
    return -1;
    80005994:	557d                	li	a0,-1
}
    80005996:	60ea                	ld	ra,152(sp)
    80005998:	644a                	ld	s0,144(sp)
    8000599a:	610d                	addi	sp,sp,160
    8000599c:	8082                	ret

000000008000599e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000599e:	7135                	addi	sp,sp,-160
    800059a0:	ed06                	sd	ra,152(sp)
    800059a2:	e922                	sd	s0,144(sp)
    800059a4:	e526                	sd	s1,136(sp)
    800059a6:	e14a                	sd	s2,128(sp)
    800059a8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059aa:	ffffc097          	auipc	ra,0xffffc
    800059ae:	098080e7          	jalr	152(ra) # 80001a42 <myproc>
    800059b2:	892a                	mv	s2,a0
  
  begin_op();
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	77a080e7          	jalr	1914(ra) # 8000412e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059bc:	08000613          	li	a2,128
    800059c0:	f6040593          	addi	a1,s0,-160
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	1c8080e7          	jalr	456(ra) # 80002b8e <argstr>
    800059ce:	04054b63          	bltz	a0,80005a24 <sys_chdir+0x86>
    800059d2:	f6040513          	addi	a0,s0,-160
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	54c080e7          	jalr	1356(ra) # 80003f22 <namei>
    800059de:	84aa                	mv	s1,a0
    800059e0:	c131                	beqz	a0,80005a24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	d90080e7          	jalr	-624(ra) # 80003772 <ilock>
  if(ip->type != T_DIR){
    800059ea:	04449703          	lh	a4,68(s1)
    800059ee:	4785                	li	a5,1
    800059f0:	04f71063          	bne	a4,a5,80005a30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	e3e080e7          	jalr	-450(ra) # 80003834 <iunlock>
  iput(p->cwd);
    800059fe:	15093503          	ld	a0,336(s2)
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	f2a080e7          	jalr	-214(ra) # 8000392c <iput>
  end_op();
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	7a4080e7          	jalr	1956(ra) # 800041ae <end_op>
  p->cwd = ip;
    80005a12:	14993823          	sd	s1,336(s2)
  return 0;
    80005a16:	4501                	li	a0,0
}
    80005a18:	60ea                	ld	ra,152(sp)
    80005a1a:	644a                	ld	s0,144(sp)
    80005a1c:	64aa                	ld	s1,136(sp)
    80005a1e:	690a                	ld	s2,128(sp)
    80005a20:	610d                	addi	sp,sp,160
    80005a22:	8082                	ret
    end_op();
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	78a080e7          	jalr	1930(ra) # 800041ae <end_op>
    return -1;
    80005a2c:	557d                	li	a0,-1
    80005a2e:	b7ed                	j	80005a18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	fa2080e7          	jalr	-94(ra) # 800039d4 <iunlockput>
    end_op();
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	774080e7          	jalr	1908(ra) # 800041ae <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	bfd1                	j	80005a18 <sys_chdir+0x7a>

0000000080005a46 <sys_exec>:

uint64
sys_exec(void)
{
    80005a46:	7145                	addi	sp,sp,-464
    80005a48:	e786                	sd	ra,456(sp)
    80005a4a:	e3a2                	sd	s0,448(sp)
    80005a4c:	ff26                	sd	s1,440(sp)
    80005a4e:	fb4a                	sd	s2,432(sp)
    80005a50:	f74e                	sd	s3,424(sp)
    80005a52:	f352                	sd	s4,416(sp)
    80005a54:	ef56                	sd	s5,408(sp)
    80005a56:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a58:	08000613          	li	a2,128
    80005a5c:	f4040593          	addi	a1,s0,-192
    80005a60:	4501                	li	a0,0
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	12c080e7          	jalr	300(ra) # 80002b8e <argstr>
    return -1;
    80005a6a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a6c:	0c054a63          	bltz	a0,80005b40 <sys_exec+0xfa>
    80005a70:	e3840593          	addi	a1,s0,-456
    80005a74:	4505                	li	a0,1
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	0f6080e7          	jalr	246(ra) # 80002b6c <argaddr>
    80005a7e:	0c054163          	bltz	a0,80005b40 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a82:	10000613          	li	a2,256
    80005a86:	4581                	li	a1,0
    80005a88:	e4040513          	addi	a0,s0,-448
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	2e4080e7          	jalr	740(ra) # 80000d70 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a94:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a98:	89a6                	mv	s3,s1
    80005a9a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a9c:	02000a13          	li	s4,32
    80005aa0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa4:	00391513          	slli	a0,s2,0x3
    80005aa8:	e3040593          	addi	a1,s0,-464
    80005aac:	e3843783          	ld	a5,-456(s0)
    80005ab0:	953e                	add	a0,a0,a5
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	ffe080e7          	jalr	-2(ra) # 80002ab0 <fetchaddr>
    80005aba:	02054a63          	bltz	a0,80005aee <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005abe:	e3043783          	ld	a5,-464(s0)
    80005ac2:	c3b9                	beqz	a5,80005b08 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	0c0080e7          	jalr	192(ra) # 80000b84 <kalloc>
    80005acc:	85aa                	mv	a1,a0
    80005ace:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad2:	cd11                	beqz	a0,80005aee <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad4:	6605                	lui	a2,0x1
    80005ad6:	e3043503          	ld	a0,-464(s0)
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	028080e7          	jalr	40(ra) # 80002b02 <fetchstr>
    80005ae2:	00054663          	bltz	a0,80005aee <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ae6:	0905                	addi	s2,s2,1
    80005ae8:	09a1                	addi	s3,s3,8
    80005aea:	fb491be3          	bne	s2,s4,80005aa0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aee:	10048913          	addi	s2,s1,256
    80005af2:	6088                	ld	a0,0(s1)
    80005af4:	c529                	beqz	a0,80005b3e <sys_exec+0xf8>
    kfree(argv[i]);
    80005af6:	ffffb097          	auipc	ra,0xffffb
    80005afa:	f92080e7          	jalr	-110(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afe:	04a1                	addi	s1,s1,8
    80005b00:	ff2499e3          	bne	s1,s2,80005af2 <sys_exec+0xac>
  return -1;
    80005b04:	597d                	li	s2,-1
    80005b06:	a82d                	j	80005b40 <sys_exec+0xfa>
      argv[i] = 0;
    80005b08:	0a8e                	slli	s5,s5,0x3
    80005b0a:	fc040793          	addi	a5,s0,-64
    80005b0e:	9abe                	add	s5,s5,a5
    80005b10:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b14:	e4040593          	addi	a1,s0,-448
    80005b18:	f4040513          	addi	a0,s0,-192
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	194080e7          	jalr	404(ra) # 80004cb0 <exec>
    80005b24:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b26:	10048993          	addi	s3,s1,256
    80005b2a:	6088                	ld	a0,0(s1)
    80005b2c:	c911                	beqz	a0,80005b40 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b2e:	ffffb097          	auipc	ra,0xffffb
    80005b32:	f5a080e7          	jalr	-166(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b36:	04a1                	addi	s1,s1,8
    80005b38:	ff3499e3          	bne	s1,s3,80005b2a <sys_exec+0xe4>
    80005b3c:	a011                	j	80005b40 <sys_exec+0xfa>
  return -1;
    80005b3e:	597d                	li	s2,-1
}
    80005b40:	854a                	mv	a0,s2
    80005b42:	60be                	ld	ra,456(sp)
    80005b44:	641e                	ld	s0,448(sp)
    80005b46:	74fa                	ld	s1,440(sp)
    80005b48:	795a                	ld	s2,432(sp)
    80005b4a:	79ba                	ld	s3,424(sp)
    80005b4c:	7a1a                	ld	s4,416(sp)
    80005b4e:	6afa                	ld	s5,408(sp)
    80005b50:	6179                	addi	sp,sp,464
    80005b52:	8082                	ret

0000000080005b54 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b54:	7139                	addi	sp,sp,-64
    80005b56:	fc06                	sd	ra,56(sp)
    80005b58:	f822                	sd	s0,48(sp)
    80005b5a:	f426                	sd	s1,40(sp)
    80005b5c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b5e:	ffffc097          	auipc	ra,0xffffc
    80005b62:	ee4080e7          	jalr	-284(ra) # 80001a42 <myproc>
    80005b66:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b68:	fd840593          	addi	a1,s0,-40
    80005b6c:	4501                	li	a0,0
    80005b6e:	ffffd097          	auipc	ra,0xffffd
    80005b72:	ffe080e7          	jalr	-2(ra) # 80002b6c <argaddr>
    return -1;
    80005b76:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b78:	0e054063          	bltz	a0,80005c58 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b7c:	fc840593          	addi	a1,s0,-56
    80005b80:	fd040513          	addi	a0,s0,-48
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	dd2080e7          	jalr	-558(ra) # 80004956 <pipealloc>
    return -1;
    80005b8c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b8e:	0c054563          	bltz	a0,80005c58 <sys_pipe+0x104>
  fd0 = -1;
    80005b92:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b96:	fd043503          	ld	a0,-48(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	508080e7          	jalr	1288(ra) # 800050a2 <fdalloc>
    80005ba2:	fca42223          	sw	a0,-60(s0)
    80005ba6:	08054c63          	bltz	a0,80005c3e <sys_pipe+0xea>
    80005baa:	fc843503          	ld	a0,-56(s0)
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	4f4080e7          	jalr	1268(ra) # 800050a2 <fdalloc>
    80005bb6:	fca42023          	sw	a0,-64(s0)
    80005bba:	06054863          	bltz	a0,80005c2a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bbe:	4691                	li	a3,4
    80005bc0:	fc440613          	addi	a2,s0,-60
    80005bc4:	fd843583          	ld	a1,-40(s0)
    80005bc8:	68a8                	ld	a0,80(s1)
    80005bca:	ffffc097          	auipc	ra,0xffffc
    80005bce:	b6c080e7          	jalr	-1172(ra) # 80001736 <copyout>
    80005bd2:	02054063          	bltz	a0,80005bf2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd6:	4691                	li	a3,4
    80005bd8:	fc040613          	addi	a2,s0,-64
    80005bdc:	fd843583          	ld	a1,-40(s0)
    80005be0:	0591                	addi	a1,a1,4
    80005be2:	68a8                	ld	a0,80(s1)
    80005be4:	ffffc097          	auipc	ra,0xffffc
    80005be8:	b52080e7          	jalr	-1198(ra) # 80001736 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bec:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bee:	06055563          	bgez	a0,80005c58 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf2:	fc442783          	lw	a5,-60(s0)
    80005bf6:	07e9                	addi	a5,a5,26
    80005bf8:	078e                	slli	a5,a5,0x3
    80005bfa:	97a6                	add	a5,a5,s1
    80005bfc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c00:	fc042503          	lw	a0,-64(s0)
    80005c04:	0569                	addi	a0,a0,26
    80005c06:	050e                	slli	a0,a0,0x3
    80005c08:	9526                	add	a0,a0,s1
    80005c0a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c0e:	fd043503          	ld	a0,-48(s0)
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	9ee080e7          	jalr	-1554(ra) # 80004600 <fileclose>
    fileclose(wf);
    80005c1a:	fc843503          	ld	a0,-56(s0)
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	9e2080e7          	jalr	-1566(ra) # 80004600 <fileclose>
    return -1;
    80005c26:	57fd                	li	a5,-1
    80005c28:	a805                	j	80005c58 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c2a:	fc442783          	lw	a5,-60(s0)
    80005c2e:	0007c863          	bltz	a5,80005c3e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c32:	01a78513          	addi	a0,a5,26
    80005c36:	050e                	slli	a0,a0,0x3
    80005c38:	9526                	add	a0,a0,s1
    80005c3a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c3e:	fd043503          	ld	a0,-48(s0)
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	9be080e7          	jalr	-1602(ra) # 80004600 <fileclose>
    fileclose(wf);
    80005c4a:	fc843503          	ld	a0,-56(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	9b2080e7          	jalr	-1614(ra) # 80004600 <fileclose>
    return -1;
    80005c56:	57fd                	li	a5,-1
}
    80005c58:	853e                	mv	a0,a5
    80005c5a:	70e2                	ld	ra,56(sp)
    80005c5c:	7442                	ld	s0,48(sp)
    80005c5e:	74a2                	ld	s1,40(sp)
    80005c60:	6121                	addi	sp,sp,64
    80005c62:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	ccdfc0ef          	jal	ra,8000297c <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	710c                	ld	a1,32(a0)
    80005d0c:	7510                	ld	a2,40(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	cce080e7          	jalr	-818(ra) # 80001a16 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	c96080e7          	jalr	-874(ra) # 80001a16 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c6e080e7          	jalr	-914(ra) # 80001a16 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	04a7cc63          	blt	a5,a0,80005e28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005dd4:	0001e797          	auipc	a5,0x1e
    80005dd8:	22c78793          	addi	a5,a5,556 # 80024000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	eba1                	bnez	a5,80005e38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dea:	00451713          	slli	a4,a0,0x4
    80005dee:	00020797          	auipc	a5,0x20
    80005df2:	2127b783          	ld	a5,530(a5) # 80026000 <disk+0x2000>
    80005df6:	97ba                	add	a5,a5,a4
    80005df8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dfc:	0001e797          	auipc	a5,0x1e
    80005e00:	20478793          	addi	a5,a5,516 # 80024000 <disk>
    80005e04:	97aa                	add	a5,a5,a0
    80005e06:	6509                	lui	a0,0x2
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	4785                	li	a5,1
    80005e0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e10:	00020517          	auipc	a0,0x20
    80005e14:	20850513          	addi	a0,a0,520 # 80026018 <disk+0x2018>
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	5cc080e7          	jalr	1484(ra) # 800023e4 <wakeup>
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	95850513          	addi	a0,a0,-1704 # 80008780 <syscalls+0x340>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	7a6080e7          	jalr	1958(ra) # 800005d6 <panic>
    panic("virtio_disk_intr 2");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	96050513          	addi	a0,a0,-1696 # 80008798 <syscalls+0x358>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	796080e7          	jalr	1942(ra) # 800005d6 <panic>

0000000080005e48 <virtio_disk_init>:
{
    80005e48:	1101                	addi	sp,sp,-32
    80005e4a:	ec06                	sd	ra,24(sp)
    80005e4c:	e822                	sd	s0,16(sp)
    80005e4e:	e426                	sd	s1,8(sp)
    80005e50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e52:	00003597          	auipc	a1,0x3
    80005e56:	95e58593          	addi	a1,a1,-1698 # 800087b0 <syscalls+0x370>
    80005e5a:	00020517          	auipc	a0,0x20
    80005e5e:	24e50513          	addi	a0,a0,590 # 800260a8 <disk+0x20a8>
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	d82080e7          	jalr	-638(ra) # 80000be4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	4398                	lw	a4,0(a5)
    80005e70:	2701                	sext.w	a4,a4
    80005e72:	747277b7          	lui	a5,0x74727
    80005e76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e7a:	0ef71163          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	43dc                	lw	a5,4(a5)
    80005e84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e86:	4705                	li	a4,1
    80005e88:	0ce79a63          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	479c                	lw	a5,8(a5)
    80005e92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e94:	4709                	li	a4,2
    80005e96:	0ce79363          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	47d8                	lw	a4,12(a5)
    80005ea0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea2:	554d47b7          	lui	a5,0x554d4
    80005ea6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eaa:	0af71963          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	4705                	li	a4,1
    80005eb4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb6:	470d                	li	a4,3
    80005eb8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ebc:	c7ffe737          	lui	a4,0xc7ffe
    80005ec0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005ec4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec6:	2701                	sext.w	a4,a4
    80005ec8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	472d                	li	a4,11
    80005ecc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	473d                	li	a4,15
    80005ed0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ed2:	6705                	lui	a4,0x1
    80005ed4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eda:	5bdc                	lw	a5,52(a5)
    80005edc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ede:	c7d9                	beqz	a5,80005f6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ee0:	471d                	li	a4,7
    80005ee2:	08f77d63          	bgeu	a4,a5,80005f7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ee6:	100014b7          	lui	s1,0x10001
    80005eea:	47a1                	li	a5,8
    80005eec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eee:	6609                	lui	a2,0x2
    80005ef0:	4581                	li	a1,0
    80005ef2:	0001e517          	auipc	a0,0x1e
    80005ef6:	10e50513          	addi	a0,a0,270 # 80024000 <disk>
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e76080e7          	jalr	-394(ra) # 80000d70 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f02:	0001e717          	auipc	a4,0x1e
    80005f06:	0fe70713          	addi	a4,a4,254 # 80024000 <disk>
    80005f0a:	00c75793          	srli	a5,a4,0xc
    80005f0e:	2781                	sext.w	a5,a5
    80005f10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f12:	00020797          	auipc	a5,0x20
    80005f16:	0ee78793          	addi	a5,a5,238 # 80026000 <disk+0x2000>
    80005f1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f1c:	0001e717          	auipc	a4,0x1e
    80005f20:	16470713          	addi	a4,a4,356 # 80024080 <disk+0x80>
    80005f24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f26:	0001f717          	auipc	a4,0x1f
    80005f2a:	0da70713          	addi	a4,a4,218 # 80025000 <disk+0x1000>
    80005f2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f30:	4705                	li	a4,1
    80005f32:	00e78c23          	sb	a4,24(a5)
    80005f36:	00e78ca3          	sb	a4,25(a5)
    80005f3a:	00e78d23          	sb	a4,26(a5)
    80005f3e:	00e78da3          	sb	a4,27(a5)
    80005f42:	00e78e23          	sb	a4,28(a5)
    80005f46:	00e78ea3          	sb	a4,29(a5)
    80005f4a:	00e78f23          	sb	a4,30(a5)
    80005f4e:	00e78fa3          	sb	a4,31(a5)
}
    80005f52:	60e2                	ld	ra,24(sp)
    80005f54:	6442                	ld	s0,16(sp)
    80005f56:	64a2                	ld	s1,8(sp)
    80005f58:	6105                	addi	sp,sp,32
    80005f5a:	8082                	ret
    panic("could not find virtio disk");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	86450513          	addi	a0,a0,-1948 # 800087c0 <syscalls+0x380>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	672080e7          	jalr	1650(ra) # 800005d6 <panic>
    panic("virtio disk has no queue 0");
    80005f6c:	00003517          	auipc	a0,0x3
    80005f70:	87450513          	addi	a0,a0,-1932 # 800087e0 <syscalls+0x3a0>
    80005f74:	ffffa097          	auipc	ra,0xffffa
    80005f78:	662080e7          	jalr	1634(ra) # 800005d6 <panic>
    panic("virtio disk max queue too short");
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	88450513          	addi	a0,a0,-1916 # 80008800 <syscalls+0x3c0>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	652080e7          	jalr	1618(ra) # 800005d6 <panic>

0000000080005f8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f8c:	7119                	addi	sp,sp,-128
    80005f8e:	fc86                	sd	ra,120(sp)
    80005f90:	f8a2                	sd	s0,112(sp)
    80005f92:	f4a6                	sd	s1,104(sp)
    80005f94:	f0ca                	sd	s2,96(sp)
    80005f96:	ecce                	sd	s3,88(sp)
    80005f98:	e8d2                	sd	s4,80(sp)
    80005f9a:	e4d6                	sd	s5,72(sp)
    80005f9c:	e0da                	sd	s6,64(sp)
    80005f9e:	fc5e                	sd	s7,56(sp)
    80005fa0:	f862                	sd	s8,48(sp)
    80005fa2:	f466                	sd	s9,40(sp)
    80005fa4:	f06a                	sd	s10,32(sp)
    80005fa6:	0100                	addi	s0,sp,128
    80005fa8:	892a                	mv	s2,a0
    80005faa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fac:	00c52c83          	lw	s9,12(a0)
    80005fb0:	001c9c9b          	slliw	s9,s9,0x1
    80005fb4:	1c82                	slli	s9,s9,0x20
    80005fb6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fba:	00020517          	auipc	a0,0x20
    80005fbe:	0ee50513          	addi	a0,a0,238 # 800260a8 <disk+0x20a8>
    80005fc2:	ffffb097          	auipc	ra,0xffffb
    80005fc6:	cb2080e7          	jalr	-846(ra) # 80000c74 <acquire>
  for(int i = 0; i < 3; i++){
    80005fca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fcc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fce:	0001eb97          	auipc	s7,0x1e
    80005fd2:	032b8b93          	addi	s7,s7,50 # 80024000 <disk>
    80005fd6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fd8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fda:	8a4e                	mv	s4,s3
    80005fdc:	a051                	j	80006060 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fde:	00fb86b3          	add	a3,s7,a5
    80005fe2:	96da                	add	a3,a3,s6
    80005fe4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fe8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fea:	0207c563          	bltz	a5,80006014 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fee:	2485                	addiw	s1,s1,1
    80005ff0:	0711                	addi	a4,a4,4
    80005ff2:	23548d63          	beq	s1,s5,8000622c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005ff6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ff8:	00020697          	auipc	a3,0x20
    80005ffc:	02068693          	addi	a3,a3,32 # 80026018 <disk+0x2018>
    80006000:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006002:	0006c583          	lbu	a1,0(a3)
    80006006:	fde1                	bnez	a1,80005fde <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006008:	2785                	addiw	a5,a5,1
    8000600a:	0685                	addi	a3,a3,1
    8000600c:	ff879be3          	bne	a5,s8,80006002 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006010:	57fd                	li	a5,-1
    80006012:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006014:	02905a63          	blez	s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006018:	f9042503          	lw	a0,-112(s0)
    8000601c:	00000097          	auipc	ra,0x0
    80006020:	daa080e7          	jalr	-598(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006024:	4785                	li	a5,1
    80006026:	0297d163          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000602a:	f9442503          	lw	a0,-108(s0)
    8000602e:	00000097          	auipc	ra,0x0
    80006032:	d98080e7          	jalr	-616(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006036:	4789                	li	a5,2
    80006038:	0097d863          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000603c:	f9842503          	lw	a0,-104(s0)
    80006040:	00000097          	auipc	ra,0x0
    80006044:	d86080e7          	jalr	-634(ra) # 80005dc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006048:	00020597          	auipc	a1,0x20
    8000604c:	06058593          	addi	a1,a1,96 # 800260a8 <disk+0x20a8>
    80006050:	00020517          	auipc	a0,0x20
    80006054:	fc850513          	addi	a0,a0,-56 # 80026018 <disk+0x2018>
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	206080e7          	jalr	518(ra) # 8000225e <sleep>
  for(int i = 0; i < 3; i++){
    80006060:	f9040713          	addi	a4,s0,-112
    80006064:	84ce                	mv	s1,s3
    80006066:	bf41                	j	80005ff6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006068:	4785                	li	a5,1
    8000606a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000606e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006072:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006076:	f9042983          	lw	s3,-112(s0)
    8000607a:	00499493          	slli	s1,s3,0x4
    8000607e:	00020a17          	auipc	s4,0x20
    80006082:	f82a0a13          	addi	s4,s4,-126 # 80026000 <disk+0x2000>
    80006086:	000a3a83          	ld	s5,0(s4)
    8000608a:	9aa6                	add	s5,s5,s1
    8000608c:	f8040513          	addi	a0,s0,-128
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	0b4080e7          	jalr	180(ra) # 80001144 <kvmpa>
    80006098:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000609c:	000a3783          	ld	a5,0(s4)
    800060a0:	97a6                	add	a5,a5,s1
    800060a2:	4741                	li	a4,16
    800060a4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060a6:	000a3783          	ld	a5,0(s4)
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	4705                	li	a4,1
    800060ae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060b2:	f9442703          	lw	a4,-108(s0)
    800060b6:	000a3783          	ld	a5,0(s4)
    800060ba:	97a6                	add	a5,a5,s1
    800060bc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060c0:	0712                	slli	a4,a4,0x4
    800060c2:	000a3783          	ld	a5,0(s4)
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	05890693          	addi	a3,s2,88
    800060cc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ce:	000a3783          	ld	a5,0(s4)
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	40000693          	li	a3,1024
    800060d8:	c794                	sw	a3,8(a5)
  if(write)
    800060da:	100d0a63          	beqz	s10,800061ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060de:	00020797          	auipc	a5,0x20
    800060e2:	f227b783          	ld	a5,-222(a5) # 80026000 <disk+0x2000>
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ec:	0001e517          	auipc	a0,0x1e
    800060f0:	f1450513          	addi	a0,a0,-236 # 80024000 <disk>
    800060f4:	00020797          	auipc	a5,0x20
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80026000 <disk+0x2000>
    800060fc:	6394                	ld	a3,0(a5)
    800060fe:	96ba                	add	a3,a3,a4
    80006100:	00c6d603          	lhu	a2,12(a3)
    80006104:	00166613          	ori	a2,a2,1
    80006108:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000610c:	f9842683          	lw	a3,-104(s0)
    80006110:	6390                	ld	a2,0(a5)
    80006112:	9732                	add	a4,a4,a2
    80006114:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006118:	20098613          	addi	a2,s3,512
    8000611c:	0612                	slli	a2,a2,0x4
    8000611e:	962a                	add	a2,a2,a0
    80006120:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006124:	00469713          	slli	a4,a3,0x4
    80006128:	6394                	ld	a3,0(a5)
    8000612a:	96ba                	add	a3,a3,a4
    8000612c:	6589                	lui	a1,0x2
    8000612e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006132:	94ae                	add	s1,s1,a1
    80006134:	94aa                	add	s1,s1,a0
    80006136:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006138:	6394                	ld	a3,0(a5)
    8000613a:	96ba                	add	a3,a3,a4
    8000613c:	4585                	li	a1,1
    8000613e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006140:	6394                	ld	a3,0(a5)
    80006142:	96ba                	add	a3,a3,a4
    80006144:	4509                	li	a0,2
    80006146:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000614a:	6394                	ld	a3,0(a5)
    8000614c:	9736                	add	a4,a4,a3
    8000614e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006152:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006156:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000615a:	6794                	ld	a3,8(a5)
    8000615c:	0026d703          	lhu	a4,2(a3)
    80006160:	8b1d                	andi	a4,a4,7
    80006162:	2709                	addiw	a4,a4,2
    80006164:	0706                	slli	a4,a4,0x1
    80006166:	9736                	add	a4,a4,a3
    80006168:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000616c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006170:	6798                	ld	a4,8(a5)
    80006172:	00275783          	lhu	a5,2(a4)
    80006176:	2785                	addiw	a5,a5,1
    80006178:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006184:	00492703          	lw	a4,4(s2)
    80006188:	4785                	li	a5,1
    8000618a:	02f71163          	bne	a4,a5,800061ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000618e:	00020997          	auipc	s3,0x20
    80006192:	f1a98993          	addi	s3,s3,-230 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006196:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006198:	85ce                	mv	a1,s3
    8000619a:	854a                	mv	a0,s2
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	0c2080e7          	jalr	194(ra) # 8000225e <sleep>
  while(b->disk == 1) {
    800061a4:	00492783          	lw	a5,4(s2)
    800061a8:	fe9788e3          	beq	a5,s1,80006198 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061ac:	f9042483          	lw	s1,-112(s0)
    800061b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061b4:	00479713          	slli	a4,a5,0x4
    800061b8:	0001e797          	auipc	a5,0x1e
    800061bc:	e4878793          	addi	a5,a5,-440 # 80024000 <disk>
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061c6:	00020917          	auipc	s2,0x20
    800061ca:	e3a90913          	addi	s2,s2,-454 # 80026000 <disk+0x2000>
    free_desc(i);
    800061ce:	8526                	mv	a0,s1
    800061d0:	00000097          	auipc	ra,0x0
    800061d4:	bf6080e7          	jalr	-1034(ra) # 80005dc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061d8:	0492                	slli	s1,s1,0x4
    800061da:	00093783          	ld	a5,0(s2)
    800061de:	94be                	add	s1,s1,a5
    800061e0:	00c4d783          	lhu	a5,12(s1)
    800061e4:	8b85                	andi	a5,a5,1
    800061e6:	cf89                	beqz	a5,80006200 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ec:	b7cd                	j	800061ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ee:	00020797          	auipc	a5,0x20
    800061f2:	e127b783          	ld	a5,-494(a5) # 80026000 <disk+0x2000>
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	4689                	li	a3,2
    800061fa:	00d79623          	sh	a3,12(a5)
    800061fe:	b5fd                	j	800060ec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006200:	00020517          	auipc	a0,0x20
    80006204:	ea850513          	addi	a0,a0,-344 # 800260a8 <disk+0x20a8>
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	b20080e7          	jalr	-1248(ra) # 80000d28 <release>
}
    80006210:	70e6                	ld	ra,120(sp)
    80006212:	7446                	ld	s0,112(sp)
    80006214:	74a6                	ld	s1,104(sp)
    80006216:	7906                	ld	s2,96(sp)
    80006218:	69e6                	ld	s3,88(sp)
    8000621a:	6a46                	ld	s4,80(sp)
    8000621c:	6aa6                	ld	s5,72(sp)
    8000621e:	6b06                	ld	s6,64(sp)
    80006220:	7be2                	ld	s7,56(sp)
    80006222:	7c42                	ld	s8,48(sp)
    80006224:	7ca2                	ld	s9,40(sp)
    80006226:	7d02                	ld	s10,32(sp)
    80006228:	6109                	addi	sp,sp,128
    8000622a:	8082                	ret
  if(write)
    8000622c:	e20d1ee3          	bnez	s10,80006068 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006230:	f8042023          	sw	zero,-128(s0)
    80006234:	bd2d                	j	8000606e <virtio_disk_rw+0xe2>

0000000080006236 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006236:	1101                	addi	sp,sp,-32
    80006238:	ec06                	sd	ra,24(sp)
    8000623a:	e822                	sd	s0,16(sp)
    8000623c:	e426                	sd	s1,8(sp)
    8000623e:	e04a                	sd	s2,0(sp)
    80006240:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006242:	00020517          	auipc	a0,0x20
    80006246:	e6650513          	addi	a0,a0,-410 # 800260a8 <disk+0x20a8>
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	a2a080e7          	jalr	-1494(ra) # 80000c74 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006252:	00020717          	auipc	a4,0x20
    80006256:	dae70713          	addi	a4,a4,-594 # 80026000 <disk+0x2000>
    8000625a:	02075783          	lhu	a5,32(a4)
    8000625e:	6b18                	ld	a4,16(a4)
    80006260:	00275683          	lhu	a3,2(a4)
    80006264:	8ebd                	xor	a3,a3,a5
    80006266:	8a9d                	andi	a3,a3,7
    80006268:	cab9                	beqz	a3,800062be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000626a:	0001e917          	auipc	s2,0x1e
    8000626e:	d9690913          	addi	s2,s2,-618 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006272:	00020497          	auipc	s1,0x20
    80006276:	d8e48493          	addi	s1,s1,-626 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000627a:	078e                	slli	a5,a5,0x3
    8000627c:	97ba                	add	a5,a5,a4
    8000627e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006280:	20078713          	addi	a4,a5,512
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	974a                	add	a4,a4,s2
    80006288:	03074703          	lbu	a4,48(a4)
    8000628c:	ef21                	bnez	a4,800062e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000628e:	20078793          	addi	a5,a5,512
    80006292:	0792                	slli	a5,a5,0x4
    80006294:	97ca                	add	a5,a5,s2
    80006296:	7798                	ld	a4,40(a5)
    80006298:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000629c:	7788                	ld	a0,40(a5)
    8000629e:	ffffc097          	auipc	ra,0xffffc
    800062a2:	146080e7          	jalr	326(ra) # 800023e4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062a6:	0204d783          	lhu	a5,32(s1)
    800062aa:	2785                	addiw	a5,a5,1
    800062ac:	8b9d                	andi	a5,a5,7
    800062ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062b2:	6898                	ld	a4,16(s1)
    800062b4:	00275683          	lhu	a3,2(a4)
    800062b8:	8a9d                	andi	a3,a3,7
    800062ba:	fcf690e3          	bne	a3,a5,8000627a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062be:	10001737          	lui	a4,0x10001
    800062c2:	533c                	lw	a5,96(a4)
    800062c4:	8b8d                	andi	a5,a5,3
    800062c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062c8:	00020517          	auipc	a0,0x20
    800062cc:	de050513          	addi	a0,a0,-544 # 800260a8 <disk+0x20a8>
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	a58080e7          	jalr	-1448(ra) # 80000d28 <release>
}
    800062d8:	60e2                	ld	ra,24(sp)
    800062da:	6442                	ld	s0,16(sp)
    800062dc:	64a2                	ld	s1,8(sp)
    800062de:	6902                	ld	s2,0(sp)
    800062e0:	6105                	addi	sp,sp,32
    800062e2:	8082                	ret
      panic("virtio_disk_intr status");
    800062e4:	00002517          	auipc	a0,0x2
    800062e8:	53c50513          	addi	a0,a0,1340 # 80008820 <syscalls+0x3e0>
    800062ec:	ffffa097          	auipc	ra,0xffffa
    800062f0:	2ea080e7          	jalr	746(ra) # 800005d6 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
