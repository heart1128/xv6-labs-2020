
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
    80000060:	ba478793          	addi	a5,a5,-1116 # 80005c00 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    8000012a:	3e0080e7          	jalr	992(ra) # 80002506 <either_copyin>
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
    800001e2:	070080e7          	jalr	112(ra) # 8000224e <sleep>
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
    8000021e:	296080e7          	jalr	662(ra) # 800024b0 <either_copyout>
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
    80000300:	260080e7          	jalr	608(ra) # 8000255c <procdump>
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
    80000454:	f84080e7          	jalr	-124(ra) # 800023d4 <wakeup>
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
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
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
    8000091e:	aba080e7          	jalr	-1350(ra) # 800023d4 <wakeup>
    
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
    800009b8:	89a080e7          	jalr	-1894(ra) # 8000224e <sleep>
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
    80000a9c:	00025797          	auipc	a5,0x25
    80000aa0:	56478793          	addi	a5,a5,1380 # 80026000 <end>
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
    80000b6c:	00025517          	auipc	a0,0x25
    80000b70:	49450513          	addi	a0,a0,1172 # 80026000 <end>
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
    80000f6c:	734080e7          	jalr	1844(ra) # 8000269c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f70:	00005097          	auipc	ra,0x5
    80000f74:	cd0080e7          	jalr	-816(ra) # 80005c40 <plicinithart>
  }

  scheduler();        
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	ffa080e7          	jalr	-6(ra) # 80001f72 <scheduler>
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
    80000fe4:	694080e7          	jalr	1684(ra) # 80002674 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	6b4080e7          	jalr	1716(ra) # 8000269c <trapinithart>
    plicinit();      // set up interrupt controller
    80000ff0:	00005097          	auipc	ra,0x5
    80000ff4:	c3a080e7          	jalr	-966(ra) # 80005c2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ff8:	00005097          	auipc	ra,0x5
    80000ffc:	c48080e7          	jalr	-952(ra) # 80005c40 <plicinithart>
    binit();         // buffer cache
    80001000:	00002097          	auipc	ra,0x2
    80001004:	de6080e7          	jalr	-538(ra) # 80002de6 <binit>
    iinit();         // inode cache
    80001008:	00002097          	auipc	ra,0x2
    8000100c:	476080e7          	jalr	1142(ra) # 8000347e <iinit>
    fileinit();      // file table
    80001010:	00003097          	auipc	ra,0x3
    80001014:	410080e7          	jalr	1040(ra) # 80004420 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001018:	00005097          	auipc	ra,0x5
    8000101c:	d30080e7          	jalr	-720(ra) # 80005d48 <virtio_disk_init>
    userinit();      // first user process
    80001020:	00001097          	auipc	ra,0x1
    80001024:	cec080e7          	jalr	-788(ra) # 80001d0c <userinit>
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
    800018d6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
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
    8000199a:	dd2a0a13          	addi	s4,s4,-558 # 80017768 <tickslock>
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
    800019e0:	16890913          	addi	s2,s2,360
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
    80001a96:	d9e7a783          	lw	a5,-610(a5) # 80008830 <first.1667>
    80001a9a:	eb89                	bnez	a5,80001aac <forkret+0x32>
  usertrapret();
    80001a9c:	00001097          	auipc	ra,0x1
    80001aa0:	c18080e7          	jalr	-1000(ra) # 800026b4 <usertrapret>
}
    80001aa4:	60a2                	ld	ra,8(sp)
    80001aa6:	6402                	ld	s0,0(sp)
    80001aa8:	0141                	addi	sp,sp,16
    80001aaa:	8082                	ret
    first = 0;
    80001aac:	00007797          	auipc	a5,0x7
    80001ab0:	d807a223          	sw	zero,-636(a5) # 80008830 <first.1667>
    fsinit(ROOTDEV);
    80001ab4:	4505                	li	a0,1
    80001ab6:	00002097          	auipc	ra,0x2
    80001aba:	948080e7          	jalr	-1720(ra) # 800033fe <fsinit>
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
    80001ae2:	d5678793          	addi	a5,a5,-682 # 80008834 <nextpid>
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
    80001c64:	b0890913          	addi	s2,s2,-1272 # 80017768 <tickslock>
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
    80001c80:	16848493          	addi	s1,s1,360
    80001c84:	ff2492e3          	bne	s1,s2,80001c68 <allocproc+0x1c>
  return 0;
    80001c88:	4481                	li	s1,0
    80001c8a:	a0b9                	j	80001cd8 <allocproc+0x8c>
  p->pid = allocpid();
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e34080e7          	jalr	-460(ra) # 80001ac0 <allocpid>
    80001c94:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	eee080e7          	jalr	-274(ra) # 80000b84 <kalloc>
    80001c9e:	892a                	mv	s2,a0
    80001ca0:	eca8                	sd	a0,88(s1)
    80001ca2:	c131                	beqz	a0,80001ce6 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e60080e7          	jalr	-416(ra) # 80001b06 <proc_pagetable>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb2:	c129                	beqz	a0,80001cf4 <allocproc+0xa8>
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
}
    80001cd8:	8526                	mv	a0,s1
    80001cda:	60e2                	ld	ra,24(sp)
    80001cdc:	6442                	ld	s0,16(sp)
    80001cde:	64a2                	ld	s1,8(sp)
    80001ce0:	6902                	ld	s2,0(sp)
    80001ce2:	6105                	addi	sp,sp,32
    80001ce4:	8082                	ret
    release(&p->lock);
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	040080e7          	jalr	64(ra) # 80000d28 <release>
    return 0;
    80001cf0:	84ca                	mv	s1,s2
    80001cf2:	b7dd                	j	80001cd8 <allocproc+0x8c>
    freeproc(p);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	efe080e7          	jalr	-258(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	028080e7          	jalr	40(ra) # 80000d28 <release>
    return 0;
    80001d08:	84ca                	mv	s1,s2
    80001d0a:	b7f9                	j	80001cd8 <allocproc+0x8c>

0000000080001d0c <userinit>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	f36080e7          	jalr	-202(ra) # 80001c4c <allocproc>
    80001d1e:	84aa                	mv	s1,a0
  initproc = p;
    80001d20:	00007797          	auipc	a5,0x7
    80001d24:	2ea7bc23          	sd	a0,760(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d28:	03400613          	li	a2,52
    80001d2c:	00007597          	auipc	a1,0x7
    80001d30:	b1458593          	addi	a1,a1,-1260 # 80008840 <initcode>
    80001d34:	6928                	ld	a0,80(a0)
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	6f6080e7          	jalr	1782(ra) # 8000142c <uvminit>
  p->sz = PGSIZE;
    80001d3e:	6785                	lui	a5,0x1
    80001d40:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d42:	6cb8                	ld	a4,88(s1)
    80001d44:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d48:	6cb8                	ld	a4,88(s1)
    80001d4a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d4c:	4641                	li	a2,16
    80001d4e:	00006597          	auipc	a1,0x6
    80001d52:	4b258593          	addi	a1,a1,1202 # 80008200 <digits+0x1a8>
    80001d56:	15848513          	addi	a0,s1,344
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	16c080e7          	jalr	364(ra) # 80000ec6 <safestrcpy>
  p->cwd = namei("/");
    80001d62:	00006517          	auipc	a0,0x6
    80001d66:	4ae50513          	addi	a0,a0,1198 # 80008210 <digits+0x1b8>
    80001d6a:	00002097          	auipc	ra,0x2
    80001d6e:	0bc080e7          	jalr	188(ra) # 80003e26 <namei>
    80001d72:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d76:	4789                	li	a5,2
    80001d78:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	fac080e7          	jalr	-84(ra) # 80000d28 <release>
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <growproc>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
    80001d9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	ca6080e7          	jalr	-858(ra) # 80001a42 <myproc>
    80001da4:	892a                	mv	s2,a0
  sz = p->sz;
    80001da6:	652c                	ld	a1,72(a0)
    80001da8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dac:	00904f63          	bgtz	s1,80001dca <growproc+0x3c>
  } else if(n < 0){
    80001db0:	0204cc63          	bltz	s1,80001de8 <growproc+0x5a>
  p->sz = sz;
    80001db4:	1602                	slli	a2,a2,0x20
    80001db6:	9201                	srli	a2,a2,0x20
    80001db8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dbc:	4501                	li	a0,0
}
    80001dbe:	60e2                	ld	ra,24(sp)
    80001dc0:	6442                	ld	s0,16(sp)
    80001dc2:	64a2                	ld	s1,8(sp)
    80001dc4:	6902                	ld	s2,0(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dca:	9e25                	addw	a2,a2,s1
    80001dcc:	1602                	slli	a2,a2,0x20
    80001dce:	9201                	srli	a2,a2,0x20
    80001dd0:	1582                	slli	a1,a1,0x20
    80001dd2:	9181                	srli	a1,a1,0x20
    80001dd4:	6928                	ld	a0,80(a0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	710080e7          	jalr	1808(ra) # 800014e6 <uvmalloc>
    80001dde:	0005061b          	sext.w	a2,a0
    80001de2:	fa69                	bnez	a2,80001db4 <growproc+0x26>
      return -1;
    80001de4:	557d                	li	a0,-1
    80001de6:	bfe1                	j	80001dbe <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de8:	9e25                	addw	a2,a2,s1
    80001dea:	1602                	slli	a2,a2,0x20
    80001dec:	9201                	srli	a2,a2,0x20
    80001dee:	1582                	slli	a1,a1,0x20
    80001df0:	9181                	srli	a1,a1,0x20
    80001df2:	6928                	ld	a0,80(a0)
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	6aa080e7          	jalr	1706(ra) # 8000149e <uvmdealloc>
    80001dfc:	0005061b          	sext.w	a2,a0
    80001e00:	bf55                	j	80001db4 <growproc+0x26>

0000000080001e02 <fork>:
{
    80001e02:	7179                	addi	sp,sp,-48
    80001e04:	f406                	sd	ra,40(sp)
    80001e06:	f022                	sd	s0,32(sp)
    80001e08:	ec26                	sd	s1,24(sp)
    80001e0a:	e84a                	sd	s2,16(sp)
    80001e0c:	e44e                	sd	s3,8(sp)
    80001e0e:	e052                	sd	s4,0(sp)
    80001e10:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	c30080e7          	jalr	-976(ra) # 80001a42 <myproc>
    80001e1a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	e30080e7          	jalr	-464(ra) # 80001c4c <allocproc>
    80001e24:	c175                	beqz	a0,80001f08 <fork+0x106>
    80001e26:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e28:	04893603          	ld	a2,72(s2)
    80001e2c:	692c                	ld	a1,80(a0)
    80001e2e:	05093503          	ld	a0,80(s2)
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	800080e7          	jalr	-2048(ra) # 80001632 <uvmcopy>
    80001e3a:	04054863          	bltz	a0,80001e8a <fork+0x88>
  np->sz = p->sz;
    80001e3e:	04893783          	ld	a5,72(s2)
    80001e42:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e46:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e4a:	05893683          	ld	a3,88(s2)
    80001e4e:	87b6                	mv	a5,a3
    80001e50:	0589b703          	ld	a4,88(s3)
    80001e54:	12068693          	addi	a3,a3,288
    80001e58:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e5c:	6788                	ld	a0,8(a5)
    80001e5e:	6b8c                	ld	a1,16(a5)
    80001e60:	6f90                	ld	a2,24(a5)
    80001e62:	01073023          	sd	a6,0(a4)
    80001e66:	e708                	sd	a0,8(a4)
    80001e68:	eb0c                	sd	a1,16(a4)
    80001e6a:	ef10                	sd	a2,24(a4)
    80001e6c:	02078793          	addi	a5,a5,32
    80001e70:	02070713          	addi	a4,a4,32
    80001e74:	fed792e3          	bne	a5,a3,80001e58 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e78:	0589b783          	ld	a5,88(s3)
    80001e7c:	0607b823          	sd	zero,112(a5)
    80001e80:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e84:	15000a13          	li	s4,336
    80001e88:	a03d                	j	80001eb6 <fork+0xb4>
    freeproc(np);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	d68080e7          	jalr	-664(ra) # 80001bf4 <freeproc>
    release(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e92080e7          	jalr	-366(ra) # 80000d28 <release>
    return -1;
    80001e9e:	54fd                	li	s1,-1
    80001ea0:	a899                	j	80001ef6 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ea2:	00002097          	auipc	ra,0x2
    80001ea6:	610080e7          	jalr	1552(ra) # 800044b2 <filedup>
    80001eaa:	009987b3          	add	a5,s3,s1
    80001eae:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001eb0:	04a1                	addi	s1,s1,8
    80001eb2:	01448763          	beq	s1,s4,80001ec0 <fork+0xbe>
    if(p->ofile[i])
    80001eb6:	009907b3          	add	a5,s2,s1
    80001eba:	6388                	ld	a0,0(a5)
    80001ebc:	f17d                	bnez	a0,80001ea2 <fork+0xa0>
    80001ebe:	bfcd                	j	80001eb0 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ec0:	15093503          	ld	a0,336(s2)
    80001ec4:	00001097          	auipc	ra,0x1
    80001ec8:	774080e7          	jalr	1908(ra) # 80003638 <idup>
    80001ecc:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed0:	4641                	li	a2,16
    80001ed2:	15890593          	addi	a1,s2,344
    80001ed6:	15898513          	addi	a0,s3,344
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	fec080e7          	jalr	-20(ra) # 80000ec6 <safestrcpy>
  pid = np->pid;
    80001ee2:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ee6:	4789                	li	a5,2
    80001ee8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eec:	854e                	mv	a0,s3
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e3a080e7          	jalr	-454(ra) # 80000d28 <release>
}
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	70a2                	ld	ra,40(sp)
    80001efa:	7402                	ld	s0,32(sp)
    80001efc:	64e2                	ld	s1,24(sp)
    80001efe:	6942                	ld	s2,16(sp)
    80001f00:	69a2                	ld	s3,8(sp)
    80001f02:	6a02                	ld	s4,0(sp)
    80001f04:	6145                	addi	sp,sp,48
    80001f06:	8082                	ret
    return -1;
    80001f08:	54fd                	li	s1,-1
    80001f0a:	b7f5                	j	80001ef6 <fork+0xf4>

0000000080001f0c <reparent>:
{
    80001f0c:	7179                	addi	sp,sp,-48
    80001f0e:	f406                	sd	ra,40(sp)
    80001f10:	f022                	sd	s0,32(sp)
    80001f12:	ec26                	sd	s1,24(sp)
    80001f14:	e84a                	sd	s2,16(sp)
    80001f16:	e44e                	sd	s3,8(sp)
    80001f18:	e052                	sd	s4,0(sp)
    80001f1a:	1800                	addi	s0,sp,48
    80001f1c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f1e:	00010497          	auipc	s1,0x10
    80001f22:	e4a48493          	addi	s1,s1,-438 # 80011d68 <proc>
      pp->parent = initproc;
    80001f26:	00007a17          	auipc	s4,0x7
    80001f2a:	0f2a0a13          	addi	s4,s4,242 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f2e:	00016997          	auipc	s3,0x16
    80001f32:	83a98993          	addi	s3,s3,-1990 # 80017768 <tickslock>
    80001f36:	a029                	j	80001f40 <reparent+0x34>
    80001f38:	16848493          	addi	s1,s1,360
    80001f3c:	03348363          	beq	s1,s3,80001f62 <reparent+0x56>
    if(pp->parent == p){
    80001f40:	709c                	ld	a5,32(s1)
    80001f42:	ff279be3          	bne	a5,s2,80001f38 <reparent+0x2c>
      acquire(&pp->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	d2c080e7          	jalr	-724(ra) # 80000c74 <acquire>
      pp->parent = initproc;
    80001f50:	000a3783          	ld	a5,0(s4)
    80001f54:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	dd0080e7          	jalr	-560(ra) # 80000d28 <release>
    80001f60:	bfe1                	j	80001f38 <reparent+0x2c>
}
    80001f62:	70a2                	ld	ra,40(sp)
    80001f64:	7402                	ld	s0,32(sp)
    80001f66:	64e2                	ld	s1,24(sp)
    80001f68:	6942                	ld	s2,16(sp)
    80001f6a:	69a2                	ld	s3,8(sp)
    80001f6c:	6a02                	ld	s4,0(sp)
    80001f6e:	6145                	addi	sp,sp,48
    80001f70:	8082                	ret

0000000080001f72 <scheduler>:
{
    80001f72:	715d                	addi	sp,sp,-80
    80001f74:	e486                	sd	ra,72(sp)
    80001f76:	e0a2                	sd	s0,64(sp)
    80001f78:	fc26                	sd	s1,56(sp)
    80001f7a:	f84a                	sd	s2,48(sp)
    80001f7c:	f44e                	sd	s3,40(sp)
    80001f7e:	f052                	sd	s4,32(sp)
    80001f80:	ec56                	sd	s5,24(sp)
    80001f82:	e85a                	sd	s6,16(sp)
    80001f84:	e45e                	sd	s7,8(sp)
    80001f86:	e062                	sd	s8,0(sp)
    80001f88:	0880                	addi	s0,sp,80
    80001f8a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f8c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f8e:	00779b13          	slli	s6,a5,0x7
    80001f92:	00010717          	auipc	a4,0x10
    80001f96:	9be70713          	addi	a4,a4,-1602 # 80011950 <pid_lock>
    80001f9a:	975a                	add	a4,a4,s6
    80001f9c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fa0:	00010717          	auipc	a4,0x10
    80001fa4:	9d070713          	addi	a4,a4,-1584 # 80011970 <cpus+0x8>
    80001fa8:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001faa:	4c0d                	li	s8,3
        c->proc = p;
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	00010a17          	auipc	s4,0x10
    80001fb2:	9a2a0a13          	addi	s4,s4,-1630 # 80011950 <pid_lock>
    80001fb6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb8:	00015997          	auipc	s3,0x15
    80001fbc:	7b098993          	addi	s3,s3,1968 # 80017768 <tickslock>
        found = 1;
    80001fc0:	4b85                	li	s7,1
    80001fc2:	a899                	j	80002018 <scheduler+0xa6>
        p->state = RUNNING;
    80001fc4:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fc8:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fcc:	06048593          	addi	a1,s1,96
    80001fd0:	855a                	mv	a0,s6
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	638080e7          	jalr	1592(ra) # 8000260a <swtch>
        c->proc = 0;
    80001fda:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fde:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	d46080e7          	jalr	-698(ra) # 80000d28 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fea:	16848493          	addi	s1,s1,360
    80001fee:	01348b63          	beq	s1,s3,80002004 <scheduler+0x92>
      acquire(&p->lock);
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	c80080e7          	jalr	-896(ra) # 80000c74 <acquire>
      if(p->state == RUNNABLE) {
    80001ffc:	4c9c                	lw	a5,24(s1)
    80001ffe:	ff2791e3          	bne	a5,s2,80001fe0 <scheduler+0x6e>
    80002002:	b7c9                	j	80001fc4 <scheduler+0x52>
    if(found == 0) {
    80002004:	000a9a63          	bnez	s5,80002018 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002008:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002010:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002014:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002018:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002020:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002024:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002026:	00010497          	auipc	s1,0x10
    8000202a:	d4248493          	addi	s1,s1,-702 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000202e:	4909                	li	s2,2
    80002030:	b7c9                	j	80001ff2 <scheduler+0x80>

0000000080002032 <sched>:
{
    80002032:	7179                	addi	sp,sp,-48
    80002034:	f406                	sd	ra,40(sp)
    80002036:	f022                	sd	s0,32(sp)
    80002038:	ec26                	sd	s1,24(sp)
    8000203a:	e84a                	sd	s2,16(sp)
    8000203c:	e44e                	sd	s3,8(sp)
    8000203e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002040:	00000097          	auipc	ra,0x0
    80002044:	a02080e7          	jalr	-1534(ra) # 80001a42 <myproc>
    80002048:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	bb0080e7          	jalr	-1104(ra) # 80000bfa <holding>
    80002052:	c93d                	beqz	a0,800020c8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002054:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002056:	2781                	sext.w	a5,a5
    80002058:	079e                	slli	a5,a5,0x7
    8000205a:	00010717          	auipc	a4,0x10
    8000205e:	8f670713          	addi	a4,a4,-1802 # 80011950 <pid_lock>
    80002062:	97ba                	add	a5,a5,a4
    80002064:	0907a703          	lw	a4,144(a5)
    80002068:	4785                	li	a5,1
    8000206a:	06f71763          	bne	a4,a5,800020d8 <sched+0xa6>
  if(p->state == RUNNING)
    8000206e:	4c98                	lw	a4,24(s1)
    80002070:	478d                	li	a5,3
    80002072:	06f70b63          	beq	a4,a5,800020e8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002076:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000207a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000207c:	efb5                	bnez	a5,800020f8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000207e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002080:	00010917          	auipc	s2,0x10
    80002084:	8d090913          	addi	s2,s2,-1840 # 80011950 <pid_lock>
    80002088:	2781                	sext.w	a5,a5
    8000208a:	079e                	slli	a5,a5,0x7
    8000208c:	97ca                	add	a5,a5,s2
    8000208e:	0947a983          	lw	s3,148(a5)
    80002092:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002094:	2781                	sext.w	a5,a5
    80002096:	079e                	slli	a5,a5,0x7
    80002098:	00010597          	auipc	a1,0x10
    8000209c:	8d858593          	addi	a1,a1,-1832 # 80011970 <cpus+0x8>
    800020a0:	95be                	add	a1,a1,a5
    800020a2:	06048513          	addi	a0,s1,96
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	564080e7          	jalr	1380(ra) # 8000260a <swtch>
    800020ae:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020b0:	2781                	sext.w	a5,a5
    800020b2:	079e                	slli	a5,a5,0x7
    800020b4:	97ca                	add	a5,a5,s2
    800020b6:	0937aa23          	sw	s3,148(a5)
}
    800020ba:	70a2                	ld	ra,40(sp)
    800020bc:	7402                	ld	s0,32(sp)
    800020be:	64e2                	ld	s1,24(sp)
    800020c0:	6942                	ld	s2,16(sp)
    800020c2:	69a2                	ld	s3,8(sp)
    800020c4:	6145                	addi	sp,sp,48
    800020c6:	8082                	ret
    panic("sched p->lock");
    800020c8:	00006517          	auipc	a0,0x6
    800020cc:	15050513          	addi	a0,a0,336 # 80008218 <digits+0x1c0>
    800020d0:	ffffe097          	auipc	ra,0xffffe
    800020d4:	506080e7          	jalr	1286(ra) # 800005d6 <panic>
    panic("sched locks");
    800020d8:	00006517          	auipc	a0,0x6
    800020dc:	15050513          	addi	a0,a0,336 # 80008228 <digits+0x1d0>
    800020e0:	ffffe097          	auipc	ra,0xffffe
    800020e4:	4f6080e7          	jalr	1270(ra) # 800005d6 <panic>
    panic("sched running");
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	15050513          	addi	a0,a0,336 # 80008238 <digits+0x1e0>
    800020f0:	ffffe097          	auipc	ra,0xffffe
    800020f4:	4e6080e7          	jalr	1254(ra) # 800005d6 <panic>
    panic("sched interruptible");
    800020f8:	00006517          	auipc	a0,0x6
    800020fc:	15050513          	addi	a0,a0,336 # 80008248 <digits+0x1f0>
    80002100:	ffffe097          	auipc	ra,0xffffe
    80002104:	4d6080e7          	jalr	1238(ra) # 800005d6 <panic>

0000000080002108 <exit>:
{
    80002108:	7179                	addi	sp,sp,-48
    8000210a:	f406                	sd	ra,40(sp)
    8000210c:	f022                	sd	s0,32(sp)
    8000210e:	ec26                	sd	s1,24(sp)
    80002110:	e84a                	sd	s2,16(sp)
    80002112:	e44e                	sd	s3,8(sp)
    80002114:	e052                	sd	s4,0(sp)
    80002116:	1800                	addi	s0,sp,48
    80002118:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	928080e7          	jalr	-1752(ra) # 80001a42 <myproc>
    80002122:	89aa                	mv	s3,a0
  if(p == initproc)
    80002124:	00007797          	auipc	a5,0x7
    80002128:	ef47b783          	ld	a5,-268(a5) # 80009018 <initproc>
    8000212c:	0d050493          	addi	s1,a0,208
    80002130:	15050913          	addi	s2,a0,336
    80002134:	02a79363          	bne	a5,a0,8000215a <exit+0x52>
    panic("init exiting");
    80002138:	00006517          	auipc	a0,0x6
    8000213c:	12850513          	addi	a0,a0,296 # 80008260 <digits+0x208>
    80002140:	ffffe097          	auipc	ra,0xffffe
    80002144:	496080e7          	jalr	1174(ra) # 800005d6 <panic>
      fileclose(f);
    80002148:	00002097          	auipc	ra,0x2
    8000214c:	3bc080e7          	jalr	956(ra) # 80004504 <fileclose>
      p->ofile[fd] = 0;
    80002150:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002154:	04a1                	addi	s1,s1,8
    80002156:	01248563          	beq	s1,s2,80002160 <exit+0x58>
    if(p->ofile[fd]){
    8000215a:	6088                	ld	a0,0(s1)
    8000215c:	f575                	bnez	a0,80002148 <exit+0x40>
    8000215e:	bfdd                	j	80002154 <exit+0x4c>
  begin_op();
    80002160:	00002097          	auipc	ra,0x2
    80002164:	ed2080e7          	jalr	-302(ra) # 80004032 <begin_op>
  iput(p->cwd);
    80002168:	1509b503          	ld	a0,336(s3)
    8000216c:	00001097          	auipc	ra,0x1
    80002170:	6c4080e7          	jalr	1732(ra) # 80003830 <iput>
  end_op();
    80002174:	00002097          	auipc	ra,0x2
    80002178:	f3e080e7          	jalr	-194(ra) # 800040b2 <end_op>
  p->cwd = 0;
    8000217c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002180:	00007497          	auipc	s1,0x7
    80002184:	e9848493          	addi	s1,s1,-360 # 80009018 <initproc>
    80002188:	6088                	ld	a0,0(s1)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	aea080e7          	jalr	-1302(ra) # 80000c74 <acquire>
  wakeup1(initproc);
    80002192:	6088                	ld	a0,0(s1)
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	76e080e7          	jalr	1902(ra) # 80001902 <wakeup1>
  release(&initproc->lock);
    8000219c:	6088                	ld	a0,0(s1)
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	b8a080e7          	jalr	-1142(ra) # 80000d28 <release>
  acquire(&p->lock);
    800021a6:	854e                	mv	a0,s3
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	acc080e7          	jalr	-1332(ra) # 80000c74 <acquire>
  struct proc *original_parent = p->parent;
    800021b0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021b4:	854e                	mv	a0,s3
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	b72080e7          	jalr	-1166(ra) # 80000d28 <release>
  acquire(&original_parent->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ab4080e7          	jalr	-1356(ra) # 80000c74 <acquire>
  acquire(&p->lock);
    800021c8:	854e                	mv	a0,s3
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	aaa080e7          	jalr	-1366(ra) # 80000c74 <acquire>
  reparent(p);
    800021d2:	854e                	mv	a0,s3
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	d38080e7          	jalr	-712(ra) # 80001f0c <reparent>
  wakeup1(original_parent);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	724080e7          	jalr	1828(ra) # 80001902 <wakeup1>
  p->xstate = status;
    800021e6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021ea:	4791                	li	a5,4
    800021ec:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	b36080e7          	jalr	-1226(ra) # 80000d28 <release>
  sched();
    800021fa:	00000097          	auipc	ra,0x0
    800021fe:	e38080e7          	jalr	-456(ra) # 80002032 <sched>
  panic("zombie exit");
    80002202:	00006517          	auipc	a0,0x6
    80002206:	06e50513          	addi	a0,a0,110 # 80008270 <digits+0x218>
    8000220a:	ffffe097          	auipc	ra,0xffffe
    8000220e:	3cc080e7          	jalr	972(ra) # 800005d6 <panic>

0000000080002212 <yield>:
{
    80002212:	1101                	addi	sp,sp,-32
    80002214:	ec06                	sd	ra,24(sp)
    80002216:	e822                	sd	s0,16(sp)
    80002218:	e426                	sd	s1,8(sp)
    8000221a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	826080e7          	jalr	-2010(ra) # 80001a42 <myproc>
    80002224:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a4e080e7          	jalr	-1458(ra) # 80000c74 <acquire>
  p->state = RUNNABLE;
    8000222e:	4789                	li	a5,2
    80002230:	cc9c                	sw	a5,24(s1)
  sched();
    80002232:	00000097          	auipc	ra,0x0
    80002236:	e00080e7          	jalr	-512(ra) # 80002032 <sched>
  release(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	aec080e7          	jalr	-1300(ra) # 80000d28 <release>
}
    80002244:	60e2                	ld	ra,24(sp)
    80002246:	6442                	ld	s0,16(sp)
    80002248:	64a2                	ld	s1,8(sp)
    8000224a:	6105                	addi	sp,sp,32
    8000224c:	8082                	ret

000000008000224e <sleep>:
{
    8000224e:	7179                	addi	sp,sp,-48
    80002250:	f406                	sd	ra,40(sp)
    80002252:	f022                	sd	s0,32(sp)
    80002254:	ec26                	sd	s1,24(sp)
    80002256:	e84a                	sd	s2,16(sp)
    80002258:	e44e                	sd	s3,8(sp)
    8000225a:	1800                	addi	s0,sp,48
    8000225c:	89aa                	mv	s3,a0
    8000225e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	7e2080e7          	jalr	2018(ra) # 80001a42 <myproc>
    80002268:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000226a:	05250663          	beq	a0,s2,800022b6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a06080e7          	jalr	-1530(ra) # 80000c74 <acquire>
    release(lk);
    80002276:	854a                	mv	a0,s2
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	ab0080e7          	jalr	-1360(ra) # 80000d28 <release>
  p->chan = chan;
    80002280:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002284:	4785                	li	a5,1
    80002286:	cc9c                	sw	a5,24(s1)
  sched();
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	daa080e7          	jalr	-598(ra) # 80002032 <sched>
  p->chan = 0;
    80002290:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	a92080e7          	jalr	-1390(ra) # 80000d28 <release>
    acquire(lk);
    8000229e:	854a                	mv	a0,s2
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9d4080e7          	jalr	-1580(ra) # 80000c74 <acquire>
}
    800022a8:	70a2                	ld	ra,40(sp)
    800022aa:	7402                	ld	s0,32(sp)
    800022ac:	64e2                	ld	s1,24(sp)
    800022ae:	6942                	ld	s2,16(sp)
    800022b0:	69a2                	ld	s3,8(sp)
    800022b2:	6145                	addi	sp,sp,48
    800022b4:	8082                	ret
  p->chan = chan;
    800022b6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022ba:	4785                	li	a5,1
    800022bc:	cd1c                	sw	a5,24(a0)
  sched();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	d74080e7          	jalr	-652(ra) # 80002032 <sched>
  p->chan = 0;
    800022c6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022ca:	bff9                	j	800022a8 <sleep+0x5a>

00000000800022cc <wait>:
{
    800022cc:	715d                	addi	sp,sp,-80
    800022ce:	e486                	sd	ra,72(sp)
    800022d0:	e0a2                	sd	s0,64(sp)
    800022d2:	fc26                	sd	s1,56(sp)
    800022d4:	f84a                	sd	s2,48(sp)
    800022d6:	f44e                	sd	s3,40(sp)
    800022d8:	f052                	sd	s4,32(sp)
    800022da:	ec56                	sd	s5,24(sp)
    800022dc:	e85a                	sd	s6,16(sp)
    800022de:	e45e                	sd	s7,8(sp)
    800022e0:	e062                	sd	s8,0(sp)
    800022e2:	0880                	addi	s0,sp,80
    800022e4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	75c080e7          	jalr	1884(ra) # 80001a42 <myproc>
    800022ee:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022f0:	8c2a                	mv	s8,a0
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	982080e7          	jalr	-1662(ra) # 80000c74 <acquire>
    havekids = 0;
    800022fa:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022fc:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022fe:	00015997          	auipc	s3,0x15
    80002302:	46a98993          	addi	s3,s3,1130 # 80017768 <tickslock>
        havekids = 1;
    80002306:	4a85                	li	s5,1
    havekids = 0;
    80002308:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000230a:	00010497          	auipc	s1,0x10
    8000230e:	a5e48493          	addi	s1,s1,-1442 # 80011d68 <proc>
    80002312:	a08d                	j	80002374 <wait+0xa8>
          pid = np->pid;
    80002314:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002318:	000b0e63          	beqz	s6,80002334 <wait+0x68>
    8000231c:	4691                	li	a3,4
    8000231e:	03448613          	addi	a2,s1,52
    80002322:	85da                	mv	a1,s6
    80002324:	05093503          	ld	a0,80(s2)
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	40e080e7          	jalr	1038(ra) # 80001736 <copyout>
    80002330:	02054263          	bltz	a0,80002354 <wait+0x88>
          freeproc(np);
    80002334:	8526                	mv	a0,s1
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	8be080e7          	jalr	-1858(ra) # 80001bf4 <freeproc>
          release(&np->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	9e8080e7          	jalr	-1560(ra) # 80000d28 <release>
          release(&p->lock);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	9de080e7          	jalr	-1570(ra) # 80000d28 <release>
          return pid;
    80002352:	a8a9                	j	800023ac <wait+0xe0>
            release(&np->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	9d2080e7          	jalr	-1582(ra) # 80000d28 <release>
            release(&p->lock);
    8000235e:	854a                	mv	a0,s2
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	9c8080e7          	jalr	-1592(ra) # 80000d28 <release>
            return -1;
    80002368:	59fd                	li	s3,-1
    8000236a:	a089                	j	800023ac <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000236c:	16848493          	addi	s1,s1,360
    80002370:	03348463          	beq	s1,s3,80002398 <wait+0xcc>
      if(np->parent == p){
    80002374:	709c                	ld	a5,32(s1)
    80002376:	ff279be3          	bne	a5,s2,8000236c <wait+0xa0>
        acquire(&np->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	8f8080e7          	jalr	-1800(ra) # 80000c74 <acquire>
        if(np->state == ZOMBIE){
    80002384:	4c9c                	lw	a5,24(s1)
    80002386:	f94787e3          	beq	a5,s4,80002314 <wait+0x48>
        release(&np->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	99c080e7          	jalr	-1636(ra) # 80000d28 <release>
        havekids = 1;
    80002394:	8756                	mv	a4,s5
    80002396:	bfd9                	j	8000236c <wait+0xa0>
    if(!havekids || p->killed){
    80002398:	c701                	beqz	a4,800023a0 <wait+0xd4>
    8000239a:	03092783          	lw	a5,48(s2)
    8000239e:	c785                	beqz	a5,800023c6 <wait+0xfa>
      release(&p->lock);
    800023a0:	854a                	mv	a0,s2
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	986080e7          	jalr	-1658(ra) # 80000d28 <release>
      return -1;
    800023aa:	59fd                	li	s3,-1
}
    800023ac:	854e                	mv	a0,s3
    800023ae:	60a6                	ld	ra,72(sp)
    800023b0:	6406                	ld	s0,64(sp)
    800023b2:	74e2                	ld	s1,56(sp)
    800023b4:	7942                	ld	s2,48(sp)
    800023b6:	79a2                	ld	s3,40(sp)
    800023b8:	7a02                	ld	s4,32(sp)
    800023ba:	6ae2                	ld	s5,24(sp)
    800023bc:	6b42                	ld	s6,16(sp)
    800023be:	6ba2                	ld	s7,8(sp)
    800023c0:	6c02                	ld	s8,0(sp)
    800023c2:	6161                	addi	sp,sp,80
    800023c4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023c6:	85e2                	mv	a1,s8
    800023c8:	854a                	mv	a0,s2
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	e84080e7          	jalr	-380(ra) # 8000224e <sleep>
    havekids = 0;
    800023d2:	bf1d                	j	80002308 <wait+0x3c>

00000000800023d4 <wakeup>:
{
    800023d4:	7139                	addi	sp,sp,-64
    800023d6:	fc06                	sd	ra,56(sp)
    800023d8:	f822                	sd	s0,48(sp)
    800023da:	f426                	sd	s1,40(sp)
    800023dc:	f04a                	sd	s2,32(sp)
    800023de:	ec4e                	sd	s3,24(sp)
    800023e0:	e852                	sd	s4,16(sp)
    800023e2:	e456                	sd	s5,8(sp)
    800023e4:	0080                	addi	s0,sp,64
    800023e6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e8:	00010497          	auipc	s1,0x10
    800023ec:	98048493          	addi	s1,s1,-1664 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023f0:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023f2:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f4:	00015917          	auipc	s2,0x15
    800023f8:	37490913          	addi	s2,s2,884 # 80017768 <tickslock>
    800023fc:	a821                	j	80002414 <wakeup+0x40>
      p->state = RUNNABLE;
    800023fe:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	924080e7          	jalr	-1756(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240c:	16848493          	addi	s1,s1,360
    80002410:	01248e63          	beq	s1,s2,8000242c <wakeup+0x58>
    acquire(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	85e080e7          	jalr	-1954(ra) # 80000c74 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000241e:	4c9c                	lw	a5,24(s1)
    80002420:	ff3791e3          	bne	a5,s3,80002402 <wakeup+0x2e>
    80002424:	749c                	ld	a5,40(s1)
    80002426:	fd479ee3          	bne	a5,s4,80002402 <wakeup+0x2e>
    8000242a:	bfd1                	j	800023fe <wakeup+0x2a>
}
    8000242c:	70e2                	ld	ra,56(sp)
    8000242e:	7442                	ld	s0,48(sp)
    80002430:	74a2                	ld	s1,40(sp)
    80002432:	7902                	ld	s2,32(sp)
    80002434:	69e2                	ld	s3,24(sp)
    80002436:	6a42                	ld	s4,16(sp)
    80002438:	6aa2                	ld	s5,8(sp)
    8000243a:	6121                	addi	sp,sp,64
    8000243c:	8082                	ret

000000008000243e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000243e:	7179                	addi	sp,sp,-48
    80002440:	f406                	sd	ra,40(sp)
    80002442:	f022                	sd	s0,32(sp)
    80002444:	ec26                	sd	s1,24(sp)
    80002446:	e84a                	sd	s2,16(sp)
    80002448:	e44e                	sd	s3,8(sp)
    8000244a:	1800                	addi	s0,sp,48
    8000244c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000244e:	00010497          	auipc	s1,0x10
    80002452:	91a48493          	addi	s1,s1,-1766 # 80011d68 <proc>
    80002456:	00015997          	auipc	s3,0x15
    8000245a:	31298993          	addi	s3,s3,786 # 80017768 <tickslock>
    acquire(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	814080e7          	jalr	-2028(ra) # 80000c74 <acquire>
    if(p->pid == pid){
    80002468:	5c9c                	lw	a5,56(s1)
    8000246a:	01278d63          	beq	a5,s2,80002484 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	8b8080e7          	jalr	-1864(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002478:	16848493          	addi	s1,s1,360
    8000247c:	ff3491e3          	bne	s1,s3,8000245e <kill+0x20>
  }
  return -1;
    80002480:	557d                	li	a0,-1
    80002482:	a829                	j	8000249c <kill+0x5e>
      p->killed = 1;
    80002484:	4785                	li	a5,1
    80002486:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002488:	4c98                	lw	a4,24(s1)
    8000248a:	4785                	li	a5,1
    8000248c:	00f70f63          	beq	a4,a5,800024aa <kill+0x6c>
      release(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	896080e7          	jalr	-1898(ra) # 80000d28 <release>
      return 0;
    8000249a:	4501                	li	a0,0
}
    8000249c:	70a2                	ld	ra,40(sp)
    8000249e:	7402                	ld	s0,32(sp)
    800024a0:	64e2                	ld	s1,24(sp)
    800024a2:	6942                	ld	s2,16(sp)
    800024a4:	69a2                	ld	s3,8(sp)
    800024a6:	6145                	addi	sp,sp,48
    800024a8:	8082                	ret
        p->state = RUNNABLE;
    800024aa:	4789                	li	a5,2
    800024ac:	cc9c                	sw	a5,24(s1)
    800024ae:	b7cd                	j	80002490 <kill+0x52>

00000000800024b0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024b0:	7179                	addi	sp,sp,-48
    800024b2:	f406                	sd	ra,40(sp)
    800024b4:	f022                	sd	s0,32(sp)
    800024b6:	ec26                	sd	s1,24(sp)
    800024b8:	e84a                	sd	s2,16(sp)
    800024ba:	e44e                	sd	s3,8(sp)
    800024bc:	e052                	sd	s4,0(sp)
    800024be:	1800                	addi	s0,sp,48
    800024c0:	84aa                	mv	s1,a0
    800024c2:	892e                	mv	s2,a1
    800024c4:	89b2                	mv	s3,a2
    800024c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	57a080e7          	jalr	1402(ra) # 80001a42 <myproc>
  if(user_dst){
    800024d0:	c08d                	beqz	s1,800024f2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024d2:	86d2                	mv	a3,s4
    800024d4:	864e                	mv	a2,s3
    800024d6:	85ca                	mv	a1,s2
    800024d8:	6928                	ld	a0,80(a0)
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	25c080e7          	jalr	604(ra) # 80001736 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e2:	70a2                	ld	ra,40(sp)
    800024e4:	7402                	ld	s0,32(sp)
    800024e6:	64e2                	ld	s1,24(sp)
    800024e8:	6942                	ld	s2,16(sp)
    800024ea:	69a2                	ld	s3,8(sp)
    800024ec:	6a02                	ld	s4,0(sp)
    800024ee:	6145                	addi	sp,sp,48
    800024f0:	8082                	ret
    memmove((char *)dst, src, len);
    800024f2:	000a061b          	sext.w	a2,s4
    800024f6:	85ce                	mv	a1,s3
    800024f8:	854a                	mv	a0,s2
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	8d6080e7          	jalr	-1834(ra) # 80000dd0 <memmove>
    return 0;
    80002502:	8526                	mv	a0,s1
    80002504:	bff9                	j	800024e2 <either_copyout+0x32>

0000000080002506 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002506:	7179                	addi	sp,sp,-48
    80002508:	f406                	sd	ra,40(sp)
    8000250a:	f022                	sd	s0,32(sp)
    8000250c:	ec26                	sd	s1,24(sp)
    8000250e:	e84a                	sd	s2,16(sp)
    80002510:	e44e                	sd	s3,8(sp)
    80002512:	e052                	sd	s4,0(sp)
    80002514:	1800                	addi	s0,sp,48
    80002516:	892a                	mv	s2,a0
    80002518:	84ae                	mv	s1,a1
    8000251a:	89b2                	mv	s3,a2
    8000251c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	524080e7          	jalr	1316(ra) # 80001a42 <myproc>
  if(user_src){
    80002526:	c08d                	beqz	s1,80002548 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002528:	86d2                	mv	a3,s4
    8000252a:	864e                	mv	a2,s3
    8000252c:	85ca                	mv	a1,s2
    8000252e:	6928                	ld	a0,80(a0)
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	292080e7          	jalr	658(ra) # 800017c2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002538:	70a2                	ld	ra,40(sp)
    8000253a:	7402                	ld	s0,32(sp)
    8000253c:	64e2                	ld	s1,24(sp)
    8000253e:	6942                	ld	s2,16(sp)
    80002540:	69a2                	ld	s3,8(sp)
    80002542:	6a02                	ld	s4,0(sp)
    80002544:	6145                	addi	sp,sp,48
    80002546:	8082                	ret
    memmove(dst, (char*)src, len);
    80002548:	000a061b          	sext.w	a2,s4
    8000254c:	85ce                	mv	a1,s3
    8000254e:	854a                	mv	a0,s2
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	880080e7          	jalr	-1920(ra) # 80000dd0 <memmove>
    return 0;
    80002558:	8526                	mv	a0,s1
    8000255a:	bff9                	j	80002538 <either_copyin+0x32>

000000008000255c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000255c:	715d                	addi	sp,sp,-80
    8000255e:	e486                	sd	ra,72(sp)
    80002560:	e0a2                	sd	s0,64(sp)
    80002562:	fc26                	sd	s1,56(sp)
    80002564:	f84a                	sd	s2,48(sp)
    80002566:	f44e                	sd	s3,40(sp)
    80002568:	f052                	sd	s4,32(sp)
    8000256a:	ec56                	sd	s5,24(sp)
    8000256c:	e85a                	sd	s6,16(sp)
    8000256e:	e45e                	sd	s7,8(sp)
    80002570:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002572:	00006517          	auipc	a0,0x6
    80002576:	b6e50513          	addi	a0,a0,-1170 # 800080e0 <digits+0x88>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	0ae080e7          	jalr	174(ra) # 80000628 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002582:	00010497          	auipc	s1,0x10
    80002586:	93e48493          	addi	s1,s1,-1730 # 80011ec0 <proc+0x158>
    8000258a:	00015917          	auipc	s2,0x15
    8000258e:	33690913          	addi	s2,s2,822 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002592:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002594:	00006997          	auipc	s3,0x6
    80002598:	cec98993          	addi	s3,s3,-788 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000259c:	00006a97          	auipc	s5,0x6
    800025a0:	ceca8a93          	addi	s5,s5,-788 # 80008288 <digits+0x230>
    printf("\n");
    800025a4:	00006a17          	auipc	s4,0x6
    800025a8:	b3ca0a13          	addi	s4,s4,-1220 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ac:	00006b97          	auipc	s7,0x6
    800025b0:	d14b8b93          	addi	s7,s7,-748 # 800082c0 <states.1707>
    800025b4:	a00d                	j	800025d6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b6:	ee06a583          	lw	a1,-288(a3)
    800025ba:	8556                	mv	a0,s5
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	06c080e7          	jalr	108(ra) # 80000628 <printf>
    printf("\n");
    800025c4:	8552                	mv	a0,s4
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	062080e7          	jalr	98(ra) # 80000628 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ce:	16848493          	addi	s1,s1,360
    800025d2:	03248163          	beq	s1,s2,800025f4 <procdump+0x98>
    if(p->state == UNUSED)
    800025d6:	86a6                	mv	a3,s1
    800025d8:	ec04a783          	lw	a5,-320(s1)
    800025dc:	dbed                	beqz	a5,800025ce <procdump+0x72>
      state = "???";
    800025de:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e0:	fcfb6be3          	bltu	s6,a5,800025b6 <procdump+0x5a>
    800025e4:	1782                	slli	a5,a5,0x20
    800025e6:	9381                	srli	a5,a5,0x20
    800025e8:	078e                	slli	a5,a5,0x3
    800025ea:	97de                	add	a5,a5,s7
    800025ec:	6390                	ld	a2,0(a5)
    800025ee:	f661                	bnez	a2,800025b6 <procdump+0x5a>
      state = "???";
    800025f0:	864e                	mv	a2,s3
    800025f2:	b7d1                	j	800025b6 <procdump+0x5a>
  }
}
    800025f4:	60a6                	ld	ra,72(sp)
    800025f6:	6406                	ld	s0,64(sp)
    800025f8:	74e2                	ld	s1,56(sp)
    800025fa:	7942                	ld	s2,48(sp)
    800025fc:	79a2                	ld	s3,40(sp)
    800025fe:	7a02                	ld	s4,32(sp)
    80002600:	6ae2                	ld	s5,24(sp)
    80002602:	6b42                	ld	s6,16(sp)
    80002604:	6ba2                	ld	s7,8(sp)
    80002606:	6161                	addi	sp,sp,80
    80002608:	8082                	ret

000000008000260a <swtch>:
    8000260a:	00153023          	sd	ra,0(a0)
    8000260e:	00253423          	sd	sp,8(a0)
    80002612:	e900                	sd	s0,16(a0)
    80002614:	ed04                	sd	s1,24(a0)
    80002616:	03253023          	sd	s2,32(a0)
    8000261a:	03353423          	sd	s3,40(a0)
    8000261e:	03453823          	sd	s4,48(a0)
    80002622:	03553c23          	sd	s5,56(a0)
    80002626:	05653023          	sd	s6,64(a0)
    8000262a:	05753423          	sd	s7,72(a0)
    8000262e:	05853823          	sd	s8,80(a0)
    80002632:	05953c23          	sd	s9,88(a0)
    80002636:	07a53023          	sd	s10,96(a0)
    8000263a:	07b53423          	sd	s11,104(a0)
    8000263e:	0005b083          	ld	ra,0(a1)
    80002642:	0085b103          	ld	sp,8(a1)
    80002646:	6980                	ld	s0,16(a1)
    80002648:	6d84                	ld	s1,24(a1)
    8000264a:	0205b903          	ld	s2,32(a1)
    8000264e:	0285b983          	ld	s3,40(a1)
    80002652:	0305ba03          	ld	s4,48(a1)
    80002656:	0385ba83          	ld	s5,56(a1)
    8000265a:	0405bb03          	ld	s6,64(a1)
    8000265e:	0485bb83          	ld	s7,72(a1)
    80002662:	0505bc03          	ld	s8,80(a1)
    80002666:	0585bc83          	ld	s9,88(a1)
    8000266a:	0605bd03          	ld	s10,96(a1)
    8000266e:	0685bd83          	ld	s11,104(a1)
    80002672:	8082                	ret

0000000080002674 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002674:	1141                	addi	sp,sp,-16
    80002676:	e406                	sd	ra,8(sp)
    80002678:	e022                	sd	s0,0(sp)
    8000267a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000267c:	00006597          	auipc	a1,0x6
    80002680:	c6c58593          	addi	a1,a1,-916 # 800082e8 <states.1707+0x28>
    80002684:	00015517          	auipc	a0,0x15
    80002688:	0e450513          	addi	a0,a0,228 # 80017768 <tickslock>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	558080e7          	jalr	1368(ra) # 80000be4 <initlock>
}
    80002694:	60a2                	ld	ra,8(sp)
    80002696:	6402                	ld	s0,0(sp)
    80002698:	0141                	addi	sp,sp,16
    8000269a:	8082                	ret

000000008000269c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000269c:	1141                	addi	sp,sp,-16
    8000269e:	e422                	sd	s0,8(sp)
    800026a0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a2:	00003797          	auipc	a5,0x3
    800026a6:	4ce78793          	addi	a5,a5,1230 # 80005b70 <kernelvec>
    800026aa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ae:	6422                	ld	s0,8(sp)
    800026b0:	0141                	addi	sp,sp,16
    800026b2:	8082                	ret

00000000800026b4 <usertrapret>:
// return to user space
// 设置RISC-V控制寄存器，为以后用户空间trap做准备
//
void
usertrapret(void)
{
    800026b4:	1141                	addi	sp,sp,-16
    800026b6:	e406                	sd	ra,8(sp)
    800026b8:	e022                	sd	s0,0(sp)
    800026ba:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	386080e7          	jalr	902(ra) # 80001a42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ca:	10079073          	csrw	sstatus,a5
  // 先关闭中断，因为要恢复现场，不能被破坏。
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  // 修改stvec为trampoline代码，里面的最后代码会执行sret指令重新打开中断，回到用户空间。
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026ce:	00005617          	auipc	a2,0x5
    800026d2:	93260613          	addi	a2,a2,-1742 # 80007000 <_trampoline>
    800026d6:	00005697          	auipc	a3,0x5
    800026da:	92a68693          	addi	a3,a3,-1750 # 80007000 <_trampoline>
    800026de:	8e91                	sub	a3,a3,a2
    800026e0:	040007b7          	lui	a5,0x4000
    800026e4:	17fd                	addi	a5,a5,-1
    800026e6:	07b2                	slli	a5,a5,0xc
    800026e8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ea:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  // 准备uservec所依赖的trapframe字段
  // 恢复现场
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ee:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026f0:	180026f3          	csrr	a3,satp
    800026f4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026f6:	6d38                	ld	a4,88(a0)
    800026f8:	6134                	ld	a3,64(a0)
    800026fa:	6585                	lui	a1,0x1
    800026fc:	96ae                	add	a3,a3,a1
    800026fe:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap; // 存储usertrap的指针，下次还能跳转到这个函数处理
    80002700:	6d38                	ld	a4,88(a0)
    80002702:	00000697          	auipc	a3,0x0
    80002706:	13868693          	addi	a3,a3,312 # 8000283a <usertrap>
    8000270a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000270c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000270e:	8692                	mv	a3,tp
    80002710:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002712:	100026f3          	csrr	a3,sstatus
   * 接下来我们要设置SSTATUS寄存器，这是一个控制寄存器。这个寄存器的SPP bit位控制了sret指令的行为，
   * 该bit为0表示下次执行sret的时候，我们想要返回user mode而不是supervisor mode。这个寄存器的SPIE bit位控制了，
   * 在执行完sret之后，是否打开中断。因为我们在返回到用户空间之后，我们的确希望打开中断，所以这里将SPIE bit位设置为1。
   * 修改完这些bit位之后，我们会把新的值写回到SSTATUS寄存器。
   * */
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002716:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000271a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  // 将sepc设置为先前在usertrap()保存的用户程序计数器
  w_sepc(p->trapframe->epc);
    80002722:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002724:	6f18                	ld	a4,24(a4)
    80002726:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  // satp寄存器切换回用户页表
  uint64 satp = MAKE_SATP(p->pagetable);
    8000272a:	692c                	ld	a1,80(a0)
    8000272c:	81b1                	srli	a1,a1,0xc
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  // 在用户页表和内核页表中映射的trampoline页上调用userret,因为userret中的汇编代码会切换页表。
  // 用户页表和内核页表的同一个虚拟地址上映射着同一个trampoline
  // fn就是对应trampoline.S的返回代码段
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000272e:	00005717          	auipc	a4,0x5
    80002732:	96270713          	addi	a4,a4,-1694 # 80007090 <userret>
    80002736:	8f11                	sub	a4,a4,a2
    80002738:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000273a:	577d                	li	a4,-1
    8000273c:	177e                	slli	a4,a4,0x3f
    8000273e:	8dd9                	or	a1,a1,a4
    80002740:	02000537          	lui	a0,0x2000
    80002744:	157d                	addi	a0,a0,-1
    80002746:	0536                	slli	a0,a0,0xd
    80002748:	9782                	jalr	a5
}
    8000274a:	60a2                	ld	ra,8(sp)
    8000274c:	6402                	ld	s0,0(sp)
    8000274e:	0141                	addi	sp,sp,16
    80002750:	8082                	ret

0000000080002752 <clockintr>:
  // 之后返回到kernelvec（kernel/kernelvec.S:48）,恢复现场栈堆
}

void
clockintr()
{
    80002752:	1101                	addi	sp,sp,-32
    80002754:	ec06                	sd	ra,24(sp)
    80002756:	e822                	sd	s0,16(sp)
    80002758:	e426                	sd	s1,8(sp)
    8000275a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000275c:	00015497          	auipc	s1,0x15
    80002760:	00c48493          	addi	s1,s1,12 # 80017768 <tickslock>
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	50e080e7          	jalr	1294(ra) # 80000c74 <acquire>
  ticks++;
    8000276e:	00007517          	auipc	a0,0x7
    80002772:	8b250513          	addi	a0,a0,-1870 # 80009020 <ticks>
    80002776:	411c                	lw	a5,0(a0)
    80002778:	2785                	addiw	a5,a5,1
    8000277a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000277c:	00000097          	auipc	ra,0x0
    80002780:	c58080e7          	jalr	-936(ra) # 800023d4 <wakeup>
  release(&tickslock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	5a2080e7          	jalr	1442(ra) # 80000d28 <release>
}
    8000278e:	60e2                	ld	ra,24(sp)
    80002790:	6442                	ld	s0,16(sp)
    80002792:	64a2                	ld	s1,8(sp)
    80002794:	6105                	addi	sp,sp,32
    80002796:	8082                	ret

0000000080002798 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002798:	1101                	addi	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027a6:	00074d63          	bltz	a4,800027c0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027aa:	57fd                	li	a5,-1
    800027ac:	17fe                	slli	a5,a5,0x3f
    800027ae:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027b0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027b2:	06f70363          	beq	a4,a5,80002818 <devintr+0x80>
  }
}
    800027b6:	60e2                	ld	ra,24(sp)
    800027b8:	6442                	ld	s0,16(sp)
    800027ba:	64a2                	ld	s1,8(sp)
    800027bc:	6105                	addi	sp,sp,32
    800027be:	8082                	ret
     (scause & 0xff) == 9){
    800027c0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027c4:	46a5                	li	a3,9
    800027c6:	fed792e3          	bne	a5,a3,800027aa <devintr+0x12>
    int irq = plic_claim();
    800027ca:	00003097          	auipc	ra,0x3
    800027ce:	4ae080e7          	jalr	1198(ra) # 80005c78 <plic_claim>
    800027d2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027d4:	47a9                	li	a5,10
    800027d6:	02f50763          	beq	a0,a5,80002804 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027da:	4785                	li	a5,1
    800027dc:	02f50963          	beq	a0,a5,8000280e <devintr+0x76>
    return 1;
    800027e0:	4505                	li	a0,1
    } else if(irq){
    800027e2:	d8f1                	beqz	s1,800027b6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027e4:	85a6                	mv	a1,s1
    800027e6:	00006517          	auipc	a0,0x6
    800027ea:	b0a50513          	addi	a0,a0,-1270 # 800082f0 <states.1707+0x30>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	e3a080e7          	jalr	-454(ra) # 80000628 <printf>
      plic_complete(irq);
    800027f6:	8526                	mv	a0,s1
    800027f8:	00003097          	auipc	ra,0x3
    800027fc:	4a4080e7          	jalr	1188(ra) # 80005c9c <plic_complete>
    return 1;
    80002800:	4505                	li	a0,1
    80002802:	bf55                	j	800027b6 <devintr+0x1e>
      uartintr();
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	234080e7          	jalr	564(ra) # 80000a38 <uartintr>
    8000280c:	b7ed                	j	800027f6 <devintr+0x5e>
      virtio_disk_intr();
    8000280e:	00004097          	auipc	ra,0x4
    80002812:	928080e7          	jalr	-1752(ra) # 80006136 <virtio_disk_intr>
    80002816:	b7c5                	j	800027f6 <devintr+0x5e>
    if(cpuid() == 0){
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	1fe080e7          	jalr	510(ra) # 80001a16 <cpuid>
    80002820:	c901                	beqz	a0,80002830 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002822:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002826:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002828:	14479073          	csrw	sip,a5
    return 2;
    8000282c:	4509                	li	a0,2
    8000282e:	b761                	j	800027b6 <devintr+0x1e>
      clockintr();
    80002830:	00000097          	auipc	ra,0x0
    80002834:	f22080e7          	jalr	-222(ra) # 80002752 <clockintr>
    80002838:	b7ed                	j	80002822 <devintr+0x8a>

000000008000283a <usertrap>:
{
    8000283a:	1101                	addi	sp,sp,-32
    8000283c:	ec06                	sd	ra,24(sp)
    8000283e:	e822                	sd	s0,16(sp)
    80002840:	e426                	sd	s1,8(sp)
    80002842:	e04a                	sd	s2,0(sp)
    80002844:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002846:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000284a:	1007f793          	andi	a5,a5,256
    8000284e:	e3ad                	bnez	a5,800028b0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002850:	00003797          	auipc	a5,0x3
    80002854:	32078793          	addi	a5,a5,800 # 80005b70 <kernelvec>
    80002858:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	1e6080e7          	jalr	486(ra) # 80001a42 <myproc>
    80002864:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002866:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002868:	14102773          	csrr	a4,sepc
    8000286c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000286e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002872:	47a1                	li	a5,8
    80002874:	04f71c63          	bne	a4,a5,800028cc <usertrap+0x92>
    if(p->killed)
    80002878:	591c                	lw	a5,48(a0)
    8000287a:	e3b9                	bnez	a5,800028c0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000287c:	6cb8                	ld	a4,88(s1)
    8000287e:	6f1c                	ld	a5,24(a4)
    80002880:	0791                	addi	a5,a5,4
    80002882:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002884:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002888:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000288c:	10079073          	csrw	sstatus,a5
    syscall();
    80002890:	00000097          	auipc	ra,0x0
    80002894:	2e0080e7          	jalr	736(ra) # 80002b70 <syscall>
  if(p->killed)
    80002898:	589c                	lw	a5,48(s1)
    8000289a:	ebc1                	bnez	a5,8000292a <usertrap+0xf0>
  usertrapret();
    8000289c:	00000097          	auipc	ra,0x0
    800028a0:	e18080e7          	jalr	-488(ra) # 800026b4 <usertrapret>
}
    800028a4:	60e2                	ld	ra,24(sp)
    800028a6:	6442                	ld	s0,16(sp)
    800028a8:	64a2                	ld	s1,8(sp)
    800028aa:	6902                	ld	s2,0(sp)
    800028ac:	6105                	addi	sp,sp,32
    800028ae:	8082                	ret
    panic("usertrap: not from user mode");
    800028b0:	00006517          	auipc	a0,0x6
    800028b4:	a6050513          	addi	a0,a0,-1440 # 80008310 <states.1707+0x50>
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	d1e080e7          	jalr	-738(ra) # 800005d6 <panic>
      exit(-1);
    800028c0:	557d                	li	a0,-1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	846080e7          	jalr	-1978(ra) # 80002108 <exit>
    800028ca:	bf4d                	j	8000287c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){ // 如果是设备中断，devintr进行处理
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	ecc080e7          	jalr	-308(ra) # 80002798 <devintr>
    800028d4:	892a                	mv	s2,a0
    800028d6:	c501                	beqz	a0,800028de <usertrap+0xa4>
  if(p->killed)
    800028d8:	589c                	lw	a5,48(s1)
    800028da:	c3a1                	beqz	a5,8000291a <usertrap+0xe0>
    800028dc:	a815                	j	80002910 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028de:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028e2:	5c90                	lw	a2,56(s1)
    800028e4:	00006517          	auipc	a0,0x6
    800028e8:	a4c50513          	addi	a0,a0,-1460 # 80008330 <states.1707+0x70>
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	d3c080e7          	jalr	-708(ra) # 80000628 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a6450513          	addi	a0,a0,-1436 # 80008360 <states.1707+0xa0>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	d24080e7          	jalr	-732(ra) # 80000628 <printf>
    p->killed = 1;
    8000290c:	4785                	li	a5,1
    8000290e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002910:	557d                	li	a0,-1
    80002912:	fffff097          	auipc	ra,0xfffff
    80002916:	7f6080e7          	jalr	2038(ra) # 80002108 <exit>
  if(which_dev == 2)
    8000291a:	4789                	li	a5,2
    8000291c:	f8f910e3          	bne	s2,a5,8000289c <usertrap+0x62>
    yield();
    80002920:	00000097          	auipc	ra,0x0
    80002924:	8f2080e7          	jalr	-1806(ra) # 80002212 <yield>
    80002928:	bf95                	j	8000289c <usertrap+0x62>
  int which_dev = 0;
    8000292a:	4901                	li	s2,0
    8000292c:	b7d5                	j	80002910 <usertrap+0xd6>

000000008000292e <kerneltrap>:
{
    8000292e:	7179                	addi	sp,sp,-48
    80002930:	f406                	sd	ra,40(sp)
    80002932:	f022                	sd	s0,32(sp)
    80002934:	ec26                	sd	s1,24(sp)
    80002936:	e84a                	sd	s2,16(sp)
    80002938:	e44e                	sd	s3,8(sp)
    8000293a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002940:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002944:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002948:	1004f793          	andi	a5,s1,256
    8000294c:	cb85                	beqz	a5,8000297c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002952:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002954:	ef85                	bnez	a5,8000298c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	e42080e7          	jalr	-446(ra) # 80002798 <devintr>
    8000295e:	cd1d                	beqz	a0,8000299c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002960:	4789                	li	a5,2
    80002962:	06f50a63          	beq	a0,a5,800029d6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002966:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296a:	10049073          	csrw	sstatus,s1
}
    8000296e:	70a2                	ld	ra,40(sp)
    80002970:	7402                	ld	s0,32(sp)
    80002972:	64e2                	ld	s1,24(sp)
    80002974:	6942                	ld	s2,16(sp)
    80002976:	69a2                	ld	s3,8(sp)
    80002978:	6145                	addi	sp,sp,48
    8000297a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000297c:	00006517          	auipc	a0,0x6
    80002980:	a0450513          	addi	a0,a0,-1532 # 80008380 <states.1707+0xc0>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	c52080e7          	jalr	-942(ra) # 800005d6 <panic>
    panic("kerneltrap: interrupts enabled");
    8000298c:	00006517          	auipc	a0,0x6
    80002990:	a1c50513          	addi	a0,a0,-1508 # 800083a8 <states.1707+0xe8>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	c42080e7          	jalr	-958(ra) # 800005d6 <panic>
    printf("scause %p\n", scause);
    8000299c:	85ce                	mv	a1,s3
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	a2a50513          	addi	a0,a0,-1494 # 800083c8 <states.1707+0x108>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	c82080e7          	jalr	-894(ra) # 80000628 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	a2250513          	addi	a0,a0,-1502 # 800083d8 <states.1707+0x118>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	c6a080e7          	jalr	-918(ra) # 80000628 <printf>
    panic("kerneltrap");
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	a2a50513          	addi	a0,a0,-1494 # 800083f0 <states.1707+0x130>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	c08080e7          	jalr	-1016(ra) # 800005d6 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	06c080e7          	jalr	108(ra) # 80001a42 <myproc>
    800029de:	d541                	beqz	a0,80002966 <kerneltrap+0x38>
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	062080e7          	jalr	98(ra) # 80001a42 <myproc>
    800029e8:	4d18                	lw	a4,24(a0)
    800029ea:	478d                	li	a5,3
    800029ec:	f6f71de3          	bne	a4,a5,80002966 <kerneltrap+0x38>
    yield();
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	822080e7          	jalr	-2014(ra) # 80002212 <yield>
    800029f8:	b7bd                	j	80002966 <kerneltrap+0x38>

00000000800029fa <argraw>:

// 在寄存器中拿出参数
// called argint()、argaddr()、argfd()
static uint64
argraw(int n)
{
    800029fa:	1101                	addi	sp,sp,-32
    800029fc:	ec06                	sd	ra,24(sp)
    800029fe:	e822                	sd	s0,16(sp)
    80002a00:	e426                	sd	s1,8(sp)
    80002a02:	1000                	addi	s0,sp,32
    80002a04:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	03c080e7          	jalr	60(ra) # 80001a42 <myproc>
  switch (n) {
    80002a0e:	4795                	li	a5,5
    80002a10:	0497e163          	bltu	a5,s1,80002a52 <argraw+0x58>
    80002a14:	048a                	slli	s1,s1,0x2
    80002a16:	00006717          	auipc	a4,0x6
    80002a1a:	a1270713          	addi	a4,a4,-1518 # 80008428 <states.1707+0x168>
    80002a1e:	94ba                	add	s1,s1,a4
    80002a20:	409c                	lw	a5,0(s1)
    80002a22:	97ba                	add	a5,a5,a4
    80002a24:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a26:	6d3c                	ld	a5,88(a0)
    80002a28:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a2a:	60e2                	ld	ra,24(sp)
    80002a2c:	6442                	ld	s0,16(sp)
    80002a2e:	64a2                	ld	s1,8(sp)
    80002a30:	6105                	addi	sp,sp,32
    80002a32:	8082                	ret
    return p->trapframe->a1;
    80002a34:	6d3c                	ld	a5,88(a0)
    80002a36:	7fa8                	ld	a0,120(a5)
    80002a38:	bfcd                	j	80002a2a <argraw+0x30>
    return p->trapframe->a2;
    80002a3a:	6d3c                	ld	a5,88(a0)
    80002a3c:	63c8                	ld	a0,128(a5)
    80002a3e:	b7f5                	j	80002a2a <argraw+0x30>
    return p->trapframe->a3;
    80002a40:	6d3c                	ld	a5,88(a0)
    80002a42:	67c8                	ld	a0,136(a5)
    80002a44:	b7dd                	j	80002a2a <argraw+0x30>
    return p->trapframe->a4;
    80002a46:	6d3c                	ld	a5,88(a0)
    80002a48:	6bc8                	ld	a0,144(a5)
    80002a4a:	b7c5                	j	80002a2a <argraw+0x30>
    return p->trapframe->a5;
    80002a4c:	6d3c                	ld	a5,88(a0)
    80002a4e:	6fc8                	ld	a0,152(a5)
    80002a50:	bfe9                	j	80002a2a <argraw+0x30>
  panic("argraw");
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	9ae50513          	addi	a0,a0,-1618 # 80008400 <states.1707+0x140>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b7c080e7          	jalr	-1156(ra) # 800005d6 <panic>

0000000080002a62 <fetchaddr>:
{
    80002a62:	1101                	addi	sp,sp,-32
    80002a64:	ec06                	sd	ra,24(sp)
    80002a66:	e822                	sd	s0,16(sp)
    80002a68:	e426                	sd	s1,8(sp)
    80002a6a:	e04a                	sd	s2,0(sp)
    80002a6c:	1000                	addi	s0,sp,32
    80002a6e:	84aa                	mv	s1,a0
    80002a70:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	fd0080e7          	jalr	-48(ra) # 80001a42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a7a:	653c                	ld	a5,72(a0)
    80002a7c:	02f4f863          	bgeu	s1,a5,80002aac <fetchaddr+0x4a>
    80002a80:	00848713          	addi	a4,s1,8
    80002a84:	02e7e663          	bltu	a5,a4,80002ab0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a88:	46a1                	li	a3,8
    80002a8a:	8626                	mv	a2,s1
    80002a8c:	85ca                	mv	a1,s2
    80002a8e:	6928                	ld	a0,80(a0)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	d32080e7          	jalr	-718(ra) # 800017c2 <copyin>
    80002a98:	00a03533          	snez	a0,a0
    80002a9c:	40a00533          	neg	a0,a0
}
    80002aa0:	60e2                	ld	ra,24(sp)
    80002aa2:	6442                	ld	s0,16(sp)
    80002aa4:	64a2                	ld	s1,8(sp)
    80002aa6:	6902                	ld	s2,0(sp)
    80002aa8:	6105                	addi	sp,sp,32
    80002aaa:	8082                	ret
    return -1;
    80002aac:	557d                	li	a0,-1
    80002aae:	bfcd                	j	80002aa0 <fetchaddr+0x3e>
    80002ab0:	557d                	li	a0,-1
    80002ab2:	b7fd                	j	80002aa0 <fetchaddr+0x3e>

0000000080002ab4 <fetchstr>:
{
    80002ab4:	7179                	addi	sp,sp,-48
    80002ab6:	f406                	sd	ra,40(sp)
    80002ab8:	f022                	sd	s0,32(sp)
    80002aba:	ec26                	sd	s1,24(sp)
    80002abc:	e84a                	sd	s2,16(sp)
    80002abe:	e44e                	sd	s3,8(sp)
    80002ac0:	1800                	addi	s0,sp,48
    80002ac2:	892a                	mv	s2,a0
    80002ac4:	84ae                	mv	s1,a1
    80002ac6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	f7a080e7          	jalr	-134(ra) # 80001a42 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ad0:	86ce                	mv	a3,s3
    80002ad2:	864a                	mv	a2,s2
    80002ad4:	85a6                	mv	a1,s1
    80002ad6:	6928                	ld	a0,80(a0)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	d76080e7          	jalr	-650(ra) # 8000184e <copyinstr>
  if(err < 0)
    80002ae0:	00054763          	bltz	a0,80002aee <fetchstr+0x3a>
  return strlen(buf);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	412080e7          	jalr	1042(ra) # 80000ef8 <strlen>
}
    80002aee:	70a2                	ld	ra,40(sp)
    80002af0:	7402                	ld	s0,32(sp)
    80002af2:	64e2                	ld	s1,24(sp)
    80002af4:	6942                	ld	s2,16(sp)
    80002af6:	69a2                	ld	s3,8(sp)
    80002af8:	6145                	addi	sp,sp,48
    80002afa:	8082                	ret

0000000080002afc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002afc:	1101                	addi	sp,sp,-32
    80002afe:	ec06                	sd	ra,24(sp)
    80002b00:	e822                	sd	s0,16(sp)
    80002b02:	e426                	sd	s1,8(sp)
    80002b04:	1000                	addi	s0,sp,32
    80002b06:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	ef2080e7          	jalr	-270(ra) # 800029fa <argraw>
    80002b10:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b12:	4501                	li	a0,0
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret

0000000080002b1e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b1e:	1101                	addi	sp,sp,-32
    80002b20:	ec06                	sd	ra,24(sp)
    80002b22:	e822                	sd	s0,16(sp)
    80002b24:	e426                	sd	s1,8(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	ed0080e7          	jalr	-304(ra) # 800029fa <argraw>
    80002b32:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b34:	4501                	li	a0,0
    80002b36:	60e2                	ld	ra,24(sp)
    80002b38:	6442                	ld	s0,16(sp)
    80002b3a:	64a2                	ld	s1,8(sp)
    80002b3c:	6105                	addi	sp,sp,32
    80002b3e:	8082                	ret

0000000080002b40 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	e04a                	sd	s2,0(sp)
    80002b4a:	1000                	addi	s0,sp,32
    80002b4c:	84ae                	mv	s1,a1
    80002b4e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	eaa080e7          	jalr	-342(ra) # 800029fa <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b58:	864a                	mv	a2,s2
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	f58080e7          	jalr	-168(ra) # 80002ab4 <fetchstr>
}
    80002b64:	60e2                	ld	ra,24(sp)
    80002b66:	6442                	ld	s0,16(sp)
    80002b68:	64a2                	ld	s1,8(sp)
    80002b6a:	6902                	ld	s2,0(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	e04a                	sd	s2,0(sp)
    80002b7a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	ec6080e7          	jalr	-314(ra) # 80001a42 <myproc>
    80002b84:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b86:	05853903          	ld	s2,88(a0)
    80002b8a:	0a893783          	ld	a5,168(s2)
    80002b8e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b92:	37fd                	addiw	a5,a5,-1
    80002b94:	4751                	li	a4,20
    80002b96:	00f76f63          	bltu	a4,a5,80002bb4 <syscall+0x44>
    80002b9a:	00369713          	slli	a4,a3,0x3
    80002b9e:	00006797          	auipc	a5,0x6
    80002ba2:	8a278793          	addi	a5,a5,-1886 # 80008440 <syscalls>
    80002ba6:	97ba                	add	a5,a5,a4
    80002ba8:	639c                	ld	a5,0(a5)
    80002baa:	c789                	beqz	a5,80002bb4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bac:	9782                	jalr	a5
    80002bae:	06a93823          	sd	a0,112(s2)
    80002bb2:	a839                	j	80002bd0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bb4:	15848613          	addi	a2,s1,344
    80002bb8:	5c8c                	lw	a1,56(s1)
    80002bba:	00006517          	auipc	a0,0x6
    80002bbe:	84e50513          	addi	a0,a0,-1970 # 80008408 <states.1707+0x148>
    80002bc2:	ffffe097          	auipc	ra,0xffffe
    80002bc6:	a66080e7          	jalr	-1434(ra) # 80000628 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bca:	6cbc                	ld	a5,88(s1)
    80002bcc:	577d                	li	a4,-1
    80002bce:	fbb8                	sd	a4,112(a5)
  }
}
    80002bd0:	60e2                	ld	ra,24(sp)
    80002bd2:	6442                	ld	s0,16(sp)
    80002bd4:	64a2                	ld	s1,8(sp)
    80002bd6:	6902                	ld	s2,0(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002be4:	fec40593          	addi	a1,s0,-20
    80002be8:	4501                	li	a0,0
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	f12080e7          	jalr	-238(ra) # 80002afc <argint>
    return -1;
    80002bf2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bf4:	00054963          	bltz	a0,80002c06 <sys_exit+0x2a>
  exit(n);
    80002bf8:	fec42503          	lw	a0,-20(s0)
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	50c080e7          	jalr	1292(ra) # 80002108 <exit>
  return 0;  // not reached
    80002c04:	4781                	li	a5,0
}
    80002c06:	853e                	mv	a0,a5
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	6105                	addi	sp,sp,32
    80002c0e:	8082                	ret

0000000080002c10 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c10:	1141                	addi	sp,sp,-16
    80002c12:	e406                	sd	ra,8(sp)
    80002c14:	e022                	sd	s0,0(sp)
    80002c16:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	e2a080e7          	jalr	-470(ra) # 80001a42 <myproc>
}
    80002c20:	5d08                	lw	a0,56(a0)
    80002c22:	60a2                	ld	ra,8(sp)
    80002c24:	6402                	ld	s0,0(sp)
    80002c26:	0141                	addi	sp,sp,16
    80002c28:	8082                	ret

0000000080002c2a <sys_fork>:

uint64
sys_fork(void)
{
    80002c2a:	1141                	addi	sp,sp,-16
    80002c2c:	e406                	sd	ra,8(sp)
    80002c2e:	e022                	sd	s0,0(sp)
    80002c30:	0800                	addi	s0,sp,16
  return fork();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	1d0080e7          	jalr	464(ra) # 80001e02 <fork>
}
    80002c3a:	60a2                	ld	ra,8(sp)
    80002c3c:	6402                	ld	s0,0(sp)
    80002c3e:	0141                	addi	sp,sp,16
    80002c40:	8082                	ret

0000000080002c42 <sys_wait>:

uint64
sys_wait(void)
{
    80002c42:	1101                	addi	sp,sp,-32
    80002c44:	ec06                	sd	ra,24(sp)
    80002c46:	e822                	sd	s0,16(sp)
    80002c48:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c4a:	fe840593          	addi	a1,s0,-24
    80002c4e:	4501                	li	a0,0
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	ece080e7          	jalr	-306(ra) # 80002b1e <argaddr>
    80002c58:	87aa                	mv	a5,a0
    return -1;
    80002c5a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c5c:	0007c863          	bltz	a5,80002c6c <sys_wait+0x2a>
  return wait(p);
    80002c60:	fe843503          	ld	a0,-24(s0)
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	668080e7          	jalr	1640(ra) # 800022cc <wait>
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret

0000000080002c74 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c74:	7179                	addi	sp,sp,-48
    80002c76:	f406                	sd	ra,40(sp)
    80002c78:	f022                	sd	s0,32(sp)
    80002c7a:	ec26                	sd	s1,24(sp)
    80002c7c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c7e:	fdc40593          	addi	a1,s0,-36
    80002c82:	4501                	li	a0,0
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	e78080e7          	jalr	-392(ra) # 80002afc <argint>
    80002c8c:	87aa                	mv	a5,a0
    return -1;
    80002c8e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c90:	0207c063          	bltz	a5,80002cb0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	dae080e7          	jalr	-594(ra) # 80001a42 <myproc>
    80002c9c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c9e:	fdc42503          	lw	a0,-36(s0)
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	0ec080e7          	jalr	236(ra) # 80001d8e <growproc>
    80002caa:	00054863          	bltz	a0,80002cba <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cae:	8526                	mv	a0,s1
}
    80002cb0:	70a2                	ld	ra,40(sp)
    80002cb2:	7402                	ld	s0,32(sp)
    80002cb4:	64e2                	ld	s1,24(sp)
    80002cb6:	6145                	addi	sp,sp,48
    80002cb8:	8082                	ret
    return -1;
    80002cba:	557d                	li	a0,-1
    80002cbc:	bfd5                	j	80002cb0 <sys_sbrk+0x3c>

0000000080002cbe <sys_sleep>:


uint64
sys_sleep(void)
{
    80002cbe:	7139                	addi	sp,sp,-64
    80002cc0:	fc06                	sd	ra,56(sp)
    80002cc2:	f822                	sd	s0,48(sp)
    80002cc4:	f426                	sd	s1,40(sp)
    80002cc6:	f04a                	sd	s2,32(sp)
    80002cc8:	ec4e                	sd	s3,24(sp)
    80002cca:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ccc:	fcc40593          	addi	a1,s0,-52
    80002cd0:	4501                	li	a0,0
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	e2a080e7          	jalr	-470(ra) # 80002afc <argint>
    return -1;
    80002cda:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cdc:	06054963          	bltz	a0,80002d4e <sys_sleep+0x90>
  acquire(&tickslock);
    80002ce0:	00015517          	auipc	a0,0x15
    80002ce4:	a8850513          	addi	a0,a0,-1400 # 80017768 <tickslock>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	f8c080e7          	jalr	-116(ra) # 80000c74 <acquire>
  ticks0 = ticks;
    80002cf0:	00006917          	auipc	s2,0x6
    80002cf4:	33092903          	lw	s2,816(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002cf8:	fcc42783          	lw	a5,-52(s0)
    80002cfc:	cf85                	beqz	a5,80002d34 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cfe:	00015997          	auipc	s3,0x15
    80002d02:	a6a98993          	addi	s3,s3,-1430 # 80017768 <tickslock>
    80002d06:	00006497          	auipc	s1,0x6
    80002d0a:	31a48493          	addi	s1,s1,794 # 80009020 <ticks>
    if(myproc()->killed){
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	d34080e7          	jalr	-716(ra) # 80001a42 <myproc>
    80002d16:	591c                	lw	a5,48(a0)
    80002d18:	e3b9                	bnez	a5,80002d5e <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002d1a:	85ce                	mv	a1,s3
    80002d1c:	8526                	mv	a0,s1
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	530080e7          	jalr	1328(ra) # 8000224e <sleep>
  while(ticks - ticks0 < n){
    80002d26:	409c                	lw	a5,0(s1)
    80002d28:	412787bb          	subw	a5,a5,s2
    80002d2c:	fcc42703          	lw	a4,-52(s0)
    80002d30:	fce7efe3          	bltu	a5,a4,80002d0e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d34:	00015517          	auipc	a0,0x15
    80002d38:	a3450513          	addi	a0,a0,-1484 # 80017768 <tickslock>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	fec080e7          	jalr	-20(ra) # 80000d28 <release>

  // lab4-2
  // 测试是用sleep()系统调用测试的，所以在这里也打印
  backtrace();
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	836080e7          	jalr	-1994(ra) # 8000057a <backtrace>

  return 0;
    80002d4c:	4781                	li	a5,0
}
    80002d4e:	853e                	mv	a0,a5
    80002d50:	70e2                	ld	ra,56(sp)
    80002d52:	7442                	ld	s0,48(sp)
    80002d54:	74a2                	ld	s1,40(sp)
    80002d56:	7902                	ld	s2,32(sp)
    80002d58:	69e2                	ld	s3,24(sp)
    80002d5a:	6121                	addi	sp,sp,64
    80002d5c:	8082                	ret
      release(&tickslock);
    80002d5e:	00015517          	auipc	a0,0x15
    80002d62:	a0a50513          	addi	a0,a0,-1526 # 80017768 <tickslock>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	fc2080e7          	jalr	-62(ra) # 80000d28 <release>
      return -1;
    80002d6e:	57fd                	li	a5,-1
    80002d70:	bff9                	j	80002d4e <sys_sleep+0x90>

0000000080002d72 <sys_kill>:

uint64
sys_kill(void)
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d7a:	fec40593          	addi	a1,s0,-20
    80002d7e:	4501                	li	a0,0
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	d7c080e7          	jalr	-644(ra) # 80002afc <argint>
    80002d88:	87aa                	mv	a5,a0
    return -1;
    80002d8a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d8c:	0007c863          	bltz	a5,80002d9c <sys_kill+0x2a>
  return kill(pid);
    80002d90:	fec42503          	lw	a0,-20(s0)
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	6aa080e7          	jalr	1706(ra) # 8000243e <kill>
}
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret

0000000080002da4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	e426                	sd	s1,8(sp)
    80002dac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dae:	00015517          	auipc	a0,0x15
    80002db2:	9ba50513          	addi	a0,a0,-1606 # 80017768 <tickslock>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	ebe080e7          	jalr	-322(ra) # 80000c74 <acquire>
  xticks = ticks;
    80002dbe:	00006497          	auipc	s1,0x6
    80002dc2:	2624a483          	lw	s1,610(s1) # 80009020 <ticks>
  release(&tickslock);
    80002dc6:	00015517          	auipc	a0,0x15
    80002dca:	9a250513          	addi	a0,a0,-1630 # 80017768 <tickslock>
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	f5a080e7          	jalr	-166(ra) # 80000d28 <release>
  return xticks;
}
    80002dd6:	02049513          	slli	a0,s1,0x20
    80002dda:	9101                	srli	a0,a0,0x20
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002de6:	7179                	addi	sp,sp,-48
    80002de8:	f406                	sd	ra,40(sp)
    80002dea:	f022                	sd	s0,32(sp)
    80002dec:	ec26                	sd	s1,24(sp)
    80002dee:	e84a                	sd	s2,16(sp)
    80002df0:	e44e                	sd	s3,8(sp)
    80002df2:	e052                	sd	s4,0(sp)
    80002df4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002df6:	00005597          	auipc	a1,0x5
    80002dfa:	6fa58593          	addi	a1,a1,1786 # 800084f0 <syscalls+0xb0>
    80002dfe:	00015517          	auipc	a0,0x15
    80002e02:	98250513          	addi	a0,a0,-1662 # 80017780 <bcache>
    80002e06:	ffffe097          	auipc	ra,0xffffe
    80002e0a:	dde080e7          	jalr	-546(ra) # 80000be4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e0e:	0001d797          	auipc	a5,0x1d
    80002e12:	97278793          	addi	a5,a5,-1678 # 8001f780 <bcache+0x8000>
    80002e16:	0001d717          	auipc	a4,0x1d
    80002e1a:	bd270713          	addi	a4,a4,-1070 # 8001f9e8 <bcache+0x8268>
    80002e1e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e22:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e26:	00015497          	auipc	s1,0x15
    80002e2a:	97248493          	addi	s1,s1,-1678 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002e2e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e30:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e32:	00005a17          	auipc	s4,0x5
    80002e36:	6c6a0a13          	addi	s4,s4,1734 # 800084f8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002e3a:	2b893783          	ld	a5,696(s2)
    80002e3e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e40:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e44:	85d2                	mv	a1,s4
    80002e46:	01048513          	addi	a0,s1,16
    80002e4a:	00001097          	auipc	ra,0x1
    80002e4e:	4ac080e7          	jalr	1196(ra) # 800042f6 <initsleeplock>
    bcache.head.next->prev = b;
    80002e52:	2b893783          	ld	a5,696(s2)
    80002e56:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e58:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e5c:	45848493          	addi	s1,s1,1112
    80002e60:	fd349de3          	bne	s1,s3,80002e3a <binit+0x54>
  }
}
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6942                	ld	s2,16(sp)
    80002e6c:	69a2                	ld	s3,8(sp)
    80002e6e:	6a02                	ld	s4,0(sp)
    80002e70:	6145                	addi	sp,sp,48
    80002e72:	8082                	ret

0000000080002e74 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e74:	7179                	addi	sp,sp,-48
    80002e76:	f406                	sd	ra,40(sp)
    80002e78:	f022                	sd	s0,32(sp)
    80002e7a:	ec26                	sd	s1,24(sp)
    80002e7c:	e84a                	sd	s2,16(sp)
    80002e7e:	e44e                	sd	s3,8(sp)
    80002e80:	1800                	addi	s0,sp,48
    80002e82:	89aa                	mv	s3,a0
    80002e84:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e86:	00015517          	auipc	a0,0x15
    80002e8a:	8fa50513          	addi	a0,a0,-1798 # 80017780 <bcache>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	de6080e7          	jalr	-538(ra) # 80000c74 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e96:	0001d497          	auipc	s1,0x1d
    80002e9a:	ba24b483          	ld	s1,-1118(s1) # 8001fa38 <bcache+0x82b8>
    80002e9e:	0001d797          	auipc	a5,0x1d
    80002ea2:	b4a78793          	addi	a5,a5,-1206 # 8001f9e8 <bcache+0x8268>
    80002ea6:	02f48f63          	beq	s1,a5,80002ee4 <bread+0x70>
    80002eaa:	873e                	mv	a4,a5
    80002eac:	a021                	j	80002eb4 <bread+0x40>
    80002eae:	68a4                	ld	s1,80(s1)
    80002eb0:	02e48a63          	beq	s1,a4,80002ee4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002eb4:	449c                	lw	a5,8(s1)
    80002eb6:	ff379ce3          	bne	a5,s3,80002eae <bread+0x3a>
    80002eba:	44dc                	lw	a5,12(s1)
    80002ebc:	ff2799e3          	bne	a5,s2,80002eae <bread+0x3a>
      b->refcnt++;
    80002ec0:	40bc                	lw	a5,64(s1)
    80002ec2:	2785                	addiw	a5,a5,1
    80002ec4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec6:	00015517          	auipc	a0,0x15
    80002eca:	8ba50513          	addi	a0,a0,-1862 # 80017780 <bcache>
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	e5a080e7          	jalr	-422(ra) # 80000d28 <release>
      acquiresleep(&b->lock);
    80002ed6:	01048513          	addi	a0,s1,16
    80002eda:	00001097          	auipc	ra,0x1
    80002ede:	456080e7          	jalr	1110(ra) # 80004330 <acquiresleep>
      return b;
    80002ee2:	a8b9                	j	80002f40 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ee4:	0001d497          	auipc	s1,0x1d
    80002ee8:	b4c4b483          	ld	s1,-1204(s1) # 8001fa30 <bcache+0x82b0>
    80002eec:	0001d797          	auipc	a5,0x1d
    80002ef0:	afc78793          	addi	a5,a5,-1284 # 8001f9e8 <bcache+0x8268>
    80002ef4:	00f48863          	beq	s1,a5,80002f04 <bread+0x90>
    80002ef8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002efa:	40bc                	lw	a5,64(s1)
    80002efc:	cf81                	beqz	a5,80002f14 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002efe:	64a4                	ld	s1,72(s1)
    80002f00:	fee49de3          	bne	s1,a4,80002efa <bread+0x86>
  panic("bget: no buffers");
    80002f04:	00005517          	auipc	a0,0x5
    80002f08:	5fc50513          	addi	a0,a0,1532 # 80008500 <syscalls+0xc0>
    80002f0c:	ffffd097          	auipc	ra,0xffffd
    80002f10:	6ca080e7          	jalr	1738(ra) # 800005d6 <panic>
      b->dev = dev;
    80002f14:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f18:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f1c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f20:	4785                	li	a5,1
    80002f22:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f24:	00015517          	auipc	a0,0x15
    80002f28:	85c50513          	addi	a0,a0,-1956 # 80017780 <bcache>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	dfc080e7          	jalr	-516(ra) # 80000d28 <release>
      acquiresleep(&b->lock);
    80002f34:	01048513          	addi	a0,s1,16
    80002f38:	00001097          	auipc	ra,0x1
    80002f3c:	3f8080e7          	jalr	1016(ra) # 80004330 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f40:	409c                	lw	a5,0(s1)
    80002f42:	cb89                	beqz	a5,80002f54 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f44:	8526                	mv	a0,s1
    80002f46:	70a2                	ld	ra,40(sp)
    80002f48:	7402                	ld	s0,32(sp)
    80002f4a:	64e2                	ld	s1,24(sp)
    80002f4c:	6942                	ld	s2,16(sp)
    80002f4e:	69a2                	ld	s3,8(sp)
    80002f50:	6145                	addi	sp,sp,48
    80002f52:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f54:	4581                	li	a1,0
    80002f56:	8526                	mv	a0,s1
    80002f58:	00003097          	auipc	ra,0x3
    80002f5c:	f34080e7          	jalr	-204(ra) # 80005e8c <virtio_disk_rw>
    b->valid = 1;
    80002f60:	4785                	li	a5,1
    80002f62:	c09c                	sw	a5,0(s1)
  return b;
    80002f64:	b7c5                	j	80002f44 <bread+0xd0>

0000000080002f66 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f66:	1101                	addi	sp,sp,-32
    80002f68:	ec06                	sd	ra,24(sp)
    80002f6a:	e822                	sd	s0,16(sp)
    80002f6c:	e426                	sd	s1,8(sp)
    80002f6e:	1000                	addi	s0,sp,32
    80002f70:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f72:	0541                	addi	a0,a0,16
    80002f74:	00001097          	auipc	ra,0x1
    80002f78:	456080e7          	jalr	1110(ra) # 800043ca <holdingsleep>
    80002f7c:	cd01                	beqz	a0,80002f94 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f7e:	4585                	li	a1,1
    80002f80:	8526                	mv	a0,s1
    80002f82:	00003097          	auipc	ra,0x3
    80002f86:	f0a080e7          	jalr	-246(ra) # 80005e8c <virtio_disk_rw>
}
    80002f8a:	60e2                	ld	ra,24(sp)
    80002f8c:	6442                	ld	s0,16(sp)
    80002f8e:	64a2                	ld	s1,8(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret
    panic("bwrite");
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	58450513          	addi	a0,a0,1412 # 80008518 <syscalls+0xd8>
    80002f9c:	ffffd097          	auipc	ra,0xffffd
    80002fa0:	63a080e7          	jalr	1594(ra) # 800005d6 <panic>

0000000080002fa4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fa4:	1101                	addi	sp,sp,-32
    80002fa6:	ec06                	sd	ra,24(sp)
    80002fa8:	e822                	sd	s0,16(sp)
    80002faa:	e426                	sd	s1,8(sp)
    80002fac:	e04a                	sd	s2,0(sp)
    80002fae:	1000                	addi	s0,sp,32
    80002fb0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fb2:	01050913          	addi	s2,a0,16
    80002fb6:	854a                	mv	a0,s2
    80002fb8:	00001097          	auipc	ra,0x1
    80002fbc:	412080e7          	jalr	1042(ra) # 800043ca <holdingsleep>
    80002fc0:	c92d                	beqz	a0,80003032 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fc2:	854a                	mv	a0,s2
    80002fc4:	00001097          	auipc	ra,0x1
    80002fc8:	3c2080e7          	jalr	962(ra) # 80004386 <releasesleep>

  acquire(&bcache.lock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	7b450513          	addi	a0,a0,1972 # 80017780 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	ca0080e7          	jalr	-864(ra) # 80000c74 <acquire>
  b->refcnt--;
    80002fdc:	40bc                	lw	a5,64(s1)
    80002fde:	37fd                	addiw	a5,a5,-1
    80002fe0:	0007871b          	sext.w	a4,a5
    80002fe4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fe6:	eb05                	bnez	a4,80003016 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fe8:	68bc                	ld	a5,80(s1)
    80002fea:	64b8                	ld	a4,72(s1)
    80002fec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fee:	64bc                	ld	a5,72(s1)
    80002ff0:	68b8                	ld	a4,80(s1)
    80002ff2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002ff4:	0001c797          	auipc	a5,0x1c
    80002ff8:	78c78793          	addi	a5,a5,1932 # 8001f780 <bcache+0x8000>
    80002ffc:	2b87b703          	ld	a4,696(a5)
    80003000:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003002:	0001d717          	auipc	a4,0x1d
    80003006:	9e670713          	addi	a4,a4,-1562 # 8001f9e8 <bcache+0x8268>
    8000300a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000300c:	2b87b703          	ld	a4,696(a5)
    80003010:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003012:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003016:	00014517          	auipc	a0,0x14
    8000301a:	76a50513          	addi	a0,a0,1898 # 80017780 <bcache>
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	d0a080e7          	jalr	-758(ra) # 80000d28 <release>
}
    80003026:	60e2                	ld	ra,24(sp)
    80003028:	6442                	ld	s0,16(sp)
    8000302a:	64a2                	ld	s1,8(sp)
    8000302c:	6902                	ld	s2,0(sp)
    8000302e:	6105                	addi	sp,sp,32
    80003030:	8082                	ret
    panic("brelse");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	4ee50513          	addi	a0,a0,1262 # 80008520 <syscalls+0xe0>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	59c080e7          	jalr	1436(ra) # 800005d6 <panic>

0000000080003042 <bpin>:

void
bpin(struct buf *b) {
    80003042:	1101                	addi	sp,sp,-32
    80003044:	ec06                	sd	ra,24(sp)
    80003046:	e822                	sd	s0,16(sp)
    80003048:	e426                	sd	s1,8(sp)
    8000304a:	1000                	addi	s0,sp,32
    8000304c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000304e:	00014517          	auipc	a0,0x14
    80003052:	73250513          	addi	a0,a0,1842 # 80017780 <bcache>
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	c1e080e7          	jalr	-994(ra) # 80000c74 <acquire>
  b->refcnt++;
    8000305e:	40bc                	lw	a5,64(s1)
    80003060:	2785                	addiw	a5,a5,1
    80003062:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003064:	00014517          	auipc	a0,0x14
    80003068:	71c50513          	addi	a0,a0,1820 # 80017780 <bcache>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	cbc080e7          	jalr	-836(ra) # 80000d28 <release>
}
    80003074:	60e2                	ld	ra,24(sp)
    80003076:	6442                	ld	s0,16(sp)
    80003078:	64a2                	ld	s1,8(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret

000000008000307e <bunpin>:

void
bunpin(struct buf *b) {
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	e426                	sd	s1,8(sp)
    80003086:	1000                	addi	s0,sp,32
    80003088:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000308a:	00014517          	auipc	a0,0x14
    8000308e:	6f650513          	addi	a0,a0,1782 # 80017780 <bcache>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	be2080e7          	jalr	-1054(ra) # 80000c74 <acquire>
  b->refcnt--;
    8000309a:	40bc                	lw	a5,64(s1)
    8000309c:	37fd                	addiw	a5,a5,-1
    8000309e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030a0:	00014517          	auipc	a0,0x14
    800030a4:	6e050513          	addi	a0,a0,1760 # 80017780 <bcache>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	c80080e7          	jalr	-896(ra) # 80000d28 <release>
}
    800030b0:	60e2                	ld	ra,24(sp)
    800030b2:	6442                	ld	s0,16(sp)
    800030b4:	64a2                	ld	s1,8(sp)
    800030b6:	6105                	addi	sp,sp,32
    800030b8:	8082                	ret

00000000800030ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030ba:	1101                	addi	sp,sp,-32
    800030bc:	ec06                	sd	ra,24(sp)
    800030be:	e822                	sd	s0,16(sp)
    800030c0:	e426                	sd	s1,8(sp)
    800030c2:	e04a                	sd	s2,0(sp)
    800030c4:	1000                	addi	s0,sp,32
    800030c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030c8:	00d5d59b          	srliw	a1,a1,0xd
    800030cc:	0001d797          	auipc	a5,0x1d
    800030d0:	d907a783          	lw	a5,-624(a5) # 8001fe5c <sb+0x1c>
    800030d4:	9dbd                	addw	a1,a1,a5
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	d9e080e7          	jalr	-610(ra) # 80002e74 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030de:	0074f713          	andi	a4,s1,7
    800030e2:	4785                	li	a5,1
    800030e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030e8:	14ce                	slli	s1,s1,0x33
    800030ea:	90d9                	srli	s1,s1,0x36
    800030ec:	00950733          	add	a4,a0,s1
    800030f0:	05874703          	lbu	a4,88(a4)
    800030f4:	00e7f6b3          	and	a3,a5,a4
    800030f8:	c69d                	beqz	a3,80003126 <bfree+0x6c>
    800030fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030fc:	94aa                	add	s1,s1,a0
    800030fe:	fff7c793          	not	a5,a5
    80003102:	8ff9                	and	a5,a5,a4
    80003104:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003108:	00001097          	auipc	ra,0x1
    8000310c:	100080e7          	jalr	256(ra) # 80004208 <log_write>
  brelse(bp);
    80003110:	854a                	mv	a0,s2
    80003112:	00000097          	auipc	ra,0x0
    80003116:	e92080e7          	jalr	-366(ra) # 80002fa4 <brelse>
}
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	64a2                	ld	s1,8(sp)
    80003120:	6902                	ld	s2,0(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret
    panic("freeing free block");
    80003126:	00005517          	auipc	a0,0x5
    8000312a:	40250513          	addi	a0,a0,1026 # 80008528 <syscalls+0xe8>
    8000312e:	ffffd097          	auipc	ra,0xffffd
    80003132:	4a8080e7          	jalr	1192(ra) # 800005d6 <panic>

0000000080003136 <balloc>:
{
    80003136:	711d                	addi	sp,sp,-96
    80003138:	ec86                	sd	ra,88(sp)
    8000313a:	e8a2                	sd	s0,80(sp)
    8000313c:	e4a6                	sd	s1,72(sp)
    8000313e:	e0ca                	sd	s2,64(sp)
    80003140:	fc4e                	sd	s3,56(sp)
    80003142:	f852                	sd	s4,48(sp)
    80003144:	f456                	sd	s5,40(sp)
    80003146:	f05a                	sd	s6,32(sp)
    80003148:	ec5e                	sd	s7,24(sp)
    8000314a:	e862                	sd	s8,16(sp)
    8000314c:	e466                	sd	s9,8(sp)
    8000314e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003150:	0001d797          	auipc	a5,0x1d
    80003154:	cf47a783          	lw	a5,-780(a5) # 8001fe44 <sb+0x4>
    80003158:	cbd1                	beqz	a5,800031ec <balloc+0xb6>
    8000315a:	8baa                	mv	s7,a0
    8000315c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000315e:	0001db17          	auipc	s6,0x1d
    80003162:	ce2b0b13          	addi	s6,s6,-798 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003166:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003168:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000316a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000316c:	6c89                	lui	s9,0x2
    8000316e:	a831                	j	8000318a <balloc+0x54>
    brelse(bp);
    80003170:	854a                	mv	a0,s2
    80003172:	00000097          	auipc	ra,0x0
    80003176:	e32080e7          	jalr	-462(ra) # 80002fa4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000317a:	015c87bb          	addw	a5,s9,s5
    8000317e:	00078a9b          	sext.w	s5,a5
    80003182:	004b2703          	lw	a4,4(s6)
    80003186:	06eaf363          	bgeu	s5,a4,800031ec <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000318a:	41fad79b          	sraiw	a5,s5,0x1f
    8000318e:	0137d79b          	srliw	a5,a5,0x13
    80003192:	015787bb          	addw	a5,a5,s5
    80003196:	40d7d79b          	sraiw	a5,a5,0xd
    8000319a:	01cb2583          	lw	a1,28(s6)
    8000319e:	9dbd                	addw	a1,a1,a5
    800031a0:	855e                	mv	a0,s7
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	cd2080e7          	jalr	-814(ra) # 80002e74 <bread>
    800031aa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ac:	004b2503          	lw	a0,4(s6)
    800031b0:	000a849b          	sext.w	s1,s5
    800031b4:	8662                	mv	a2,s8
    800031b6:	faa4fde3          	bgeu	s1,a0,80003170 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031ba:	41f6579b          	sraiw	a5,a2,0x1f
    800031be:	01d7d69b          	srliw	a3,a5,0x1d
    800031c2:	00c6873b          	addw	a4,a3,a2
    800031c6:	00777793          	andi	a5,a4,7
    800031ca:	9f95                	subw	a5,a5,a3
    800031cc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031d0:	4037571b          	sraiw	a4,a4,0x3
    800031d4:	00e906b3          	add	a3,s2,a4
    800031d8:	0586c683          	lbu	a3,88(a3)
    800031dc:	00d7f5b3          	and	a1,a5,a3
    800031e0:	cd91                	beqz	a1,800031fc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e2:	2605                	addiw	a2,a2,1
    800031e4:	2485                	addiw	s1,s1,1
    800031e6:	fd4618e3          	bne	a2,s4,800031b6 <balloc+0x80>
    800031ea:	b759                	j	80003170 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	35450513          	addi	a0,a0,852 # 80008540 <syscalls+0x100>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	3e2080e7          	jalr	994(ra) # 800005d6 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031fc:	974a                	add	a4,a4,s2
    800031fe:	8fd5                	or	a5,a5,a3
    80003200:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00001097          	auipc	ra,0x1
    8000320a:	002080e7          	jalr	2(ra) # 80004208 <log_write>
        brelse(bp);
    8000320e:	854a                	mv	a0,s2
    80003210:	00000097          	auipc	ra,0x0
    80003214:	d94080e7          	jalr	-620(ra) # 80002fa4 <brelse>
  bp = bread(dev, bno);
    80003218:	85a6                	mv	a1,s1
    8000321a:	855e                	mv	a0,s7
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	c58080e7          	jalr	-936(ra) # 80002e74 <bread>
    80003224:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003226:	40000613          	li	a2,1024
    8000322a:	4581                	li	a1,0
    8000322c:	05850513          	addi	a0,a0,88
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	b40080e7          	jalr	-1216(ra) # 80000d70 <memset>
  log_write(bp);
    80003238:	854a                	mv	a0,s2
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	fce080e7          	jalr	-50(ra) # 80004208 <log_write>
  brelse(bp);
    80003242:	854a                	mv	a0,s2
    80003244:	00000097          	auipc	ra,0x0
    80003248:	d60080e7          	jalr	-672(ra) # 80002fa4 <brelse>
}
    8000324c:	8526                	mv	a0,s1
    8000324e:	60e6                	ld	ra,88(sp)
    80003250:	6446                	ld	s0,80(sp)
    80003252:	64a6                	ld	s1,72(sp)
    80003254:	6906                	ld	s2,64(sp)
    80003256:	79e2                	ld	s3,56(sp)
    80003258:	7a42                	ld	s4,48(sp)
    8000325a:	7aa2                	ld	s5,40(sp)
    8000325c:	7b02                	ld	s6,32(sp)
    8000325e:	6be2                	ld	s7,24(sp)
    80003260:	6c42                	ld	s8,16(sp)
    80003262:	6ca2                	ld	s9,8(sp)
    80003264:	6125                	addi	sp,sp,96
    80003266:	8082                	ret

0000000080003268 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003268:	7179                	addi	sp,sp,-48
    8000326a:	f406                	sd	ra,40(sp)
    8000326c:	f022                	sd	s0,32(sp)
    8000326e:	ec26                	sd	s1,24(sp)
    80003270:	e84a                	sd	s2,16(sp)
    80003272:	e44e                	sd	s3,8(sp)
    80003274:	e052                	sd	s4,0(sp)
    80003276:	1800                	addi	s0,sp,48
    80003278:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000327a:	47ad                	li	a5,11
    8000327c:	04b7fe63          	bgeu	a5,a1,800032d8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003280:	ff45849b          	addiw	s1,a1,-12
    80003284:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003288:	0ff00793          	li	a5,255
    8000328c:	0ae7e363          	bltu	a5,a4,80003332 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003290:	08052583          	lw	a1,128(a0)
    80003294:	c5ad                	beqz	a1,800032fe <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003296:	00092503          	lw	a0,0(s2)
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	bda080e7          	jalr	-1062(ra) # 80002e74 <bread>
    800032a2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032a4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032a8:	02049593          	slli	a1,s1,0x20
    800032ac:	9181                	srli	a1,a1,0x20
    800032ae:	058a                	slli	a1,a1,0x2
    800032b0:	00b784b3          	add	s1,a5,a1
    800032b4:	0004a983          	lw	s3,0(s1)
    800032b8:	04098d63          	beqz	s3,80003312 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032bc:	8552                	mv	a0,s4
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	ce6080e7          	jalr	-794(ra) # 80002fa4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032c6:	854e                	mv	a0,s3
    800032c8:	70a2                	ld	ra,40(sp)
    800032ca:	7402                	ld	s0,32(sp)
    800032cc:	64e2                	ld	s1,24(sp)
    800032ce:	6942                	ld	s2,16(sp)
    800032d0:	69a2                	ld	s3,8(sp)
    800032d2:	6a02                	ld	s4,0(sp)
    800032d4:	6145                	addi	sp,sp,48
    800032d6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032d8:	02059493          	slli	s1,a1,0x20
    800032dc:	9081                	srli	s1,s1,0x20
    800032de:	048a                	slli	s1,s1,0x2
    800032e0:	94aa                	add	s1,s1,a0
    800032e2:	0504a983          	lw	s3,80(s1)
    800032e6:	fe0990e3          	bnez	s3,800032c6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032ea:	4108                	lw	a0,0(a0)
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	e4a080e7          	jalr	-438(ra) # 80003136 <balloc>
    800032f4:	0005099b          	sext.w	s3,a0
    800032f8:	0534a823          	sw	s3,80(s1)
    800032fc:	b7e9                	j	800032c6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032fe:	4108                	lw	a0,0(a0)
    80003300:	00000097          	auipc	ra,0x0
    80003304:	e36080e7          	jalr	-458(ra) # 80003136 <balloc>
    80003308:	0005059b          	sext.w	a1,a0
    8000330c:	08b92023          	sw	a1,128(s2)
    80003310:	b759                	j	80003296 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003312:	00092503          	lw	a0,0(s2)
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	e20080e7          	jalr	-480(ra) # 80003136 <balloc>
    8000331e:	0005099b          	sext.w	s3,a0
    80003322:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003326:	8552                	mv	a0,s4
    80003328:	00001097          	auipc	ra,0x1
    8000332c:	ee0080e7          	jalr	-288(ra) # 80004208 <log_write>
    80003330:	b771                	j	800032bc <bmap+0x54>
  panic("bmap: out of range");
    80003332:	00005517          	auipc	a0,0x5
    80003336:	22650513          	addi	a0,a0,550 # 80008558 <syscalls+0x118>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	29c080e7          	jalr	668(ra) # 800005d6 <panic>

0000000080003342 <iget>:
{
    80003342:	7179                	addi	sp,sp,-48
    80003344:	f406                	sd	ra,40(sp)
    80003346:	f022                	sd	s0,32(sp)
    80003348:	ec26                	sd	s1,24(sp)
    8000334a:	e84a                	sd	s2,16(sp)
    8000334c:	e44e                	sd	s3,8(sp)
    8000334e:	e052                	sd	s4,0(sp)
    80003350:	1800                	addi	s0,sp,48
    80003352:	89aa                	mv	s3,a0
    80003354:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003356:	0001d517          	auipc	a0,0x1d
    8000335a:	b0a50513          	addi	a0,a0,-1270 # 8001fe60 <icache>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	916080e7          	jalr	-1770(ra) # 80000c74 <acquire>
  empty = 0;
    80003366:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003368:	0001d497          	auipc	s1,0x1d
    8000336c:	b1048493          	addi	s1,s1,-1264 # 8001fe78 <icache+0x18>
    80003370:	0001e697          	auipc	a3,0x1e
    80003374:	59868693          	addi	a3,a3,1432 # 80021908 <log>
    80003378:	a039                	j	80003386 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000337a:	02090b63          	beqz	s2,800033b0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000337e:	08848493          	addi	s1,s1,136
    80003382:	02d48a63          	beq	s1,a3,800033b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003386:	449c                	lw	a5,8(s1)
    80003388:	fef059e3          	blez	a5,8000337a <iget+0x38>
    8000338c:	4098                	lw	a4,0(s1)
    8000338e:	ff3716e3          	bne	a4,s3,8000337a <iget+0x38>
    80003392:	40d8                	lw	a4,4(s1)
    80003394:	ff4713e3          	bne	a4,s4,8000337a <iget+0x38>
      ip->ref++;
    80003398:	2785                	addiw	a5,a5,1
    8000339a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000339c:	0001d517          	auipc	a0,0x1d
    800033a0:	ac450513          	addi	a0,a0,-1340 # 8001fe60 <icache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	984080e7          	jalr	-1660(ra) # 80000d28 <release>
      return ip;
    800033ac:	8926                	mv	s2,s1
    800033ae:	a03d                	j	800033dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033b0:	f7f9                	bnez	a5,8000337e <iget+0x3c>
    800033b2:	8926                	mv	s2,s1
    800033b4:	b7e9                	j	8000337e <iget+0x3c>
  if(empty == 0)
    800033b6:	02090c63          	beqz	s2,800033ee <iget+0xac>
  ip->dev = dev;
    800033ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033c2:	4785                	li	a5,1
    800033c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033c8:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800033cc:	0001d517          	auipc	a0,0x1d
    800033d0:	a9450513          	addi	a0,a0,-1388 # 8001fe60 <icache>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	954080e7          	jalr	-1708(ra) # 80000d28 <release>
}
    800033dc:	854a                	mv	a0,s2
    800033de:	70a2                	ld	ra,40(sp)
    800033e0:	7402                	ld	s0,32(sp)
    800033e2:	64e2                	ld	s1,24(sp)
    800033e4:	6942                	ld	s2,16(sp)
    800033e6:	69a2                	ld	s3,8(sp)
    800033e8:	6a02                	ld	s4,0(sp)
    800033ea:	6145                	addi	sp,sp,48
    800033ec:	8082                	ret
    panic("iget: no inodes");
    800033ee:	00005517          	auipc	a0,0x5
    800033f2:	18250513          	addi	a0,a0,386 # 80008570 <syscalls+0x130>
    800033f6:	ffffd097          	auipc	ra,0xffffd
    800033fa:	1e0080e7          	jalr	480(ra) # 800005d6 <panic>

00000000800033fe <fsinit>:
fsinit(int dev) {
    800033fe:	7179                	addi	sp,sp,-48
    80003400:	f406                	sd	ra,40(sp)
    80003402:	f022                	sd	s0,32(sp)
    80003404:	ec26                	sd	s1,24(sp)
    80003406:	e84a                	sd	s2,16(sp)
    80003408:	e44e                	sd	s3,8(sp)
    8000340a:	1800                	addi	s0,sp,48
    8000340c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000340e:	4585                	li	a1,1
    80003410:	00000097          	auipc	ra,0x0
    80003414:	a64080e7          	jalr	-1436(ra) # 80002e74 <bread>
    80003418:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000341a:	0001d997          	auipc	s3,0x1d
    8000341e:	a2698993          	addi	s3,s3,-1498 # 8001fe40 <sb>
    80003422:	02000613          	li	a2,32
    80003426:	05850593          	addi	a1,a0,88
    8000342a:	854e                	mv	a0,s3
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	9a4080e7          	jalr	-1628(ra) # 80000dd0 <memmove>
  brelse(bp);
    80003434:	8526                	mv	a0,s1
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	b6e080e7          	jalr	-1170(ra) # 80002fa4 <brelse>
  if(sb.magic != FSMAGIC)
    8000343e:	0009a703          	lw	a4,0(s3)
    80003442:	102037b7          	lui	a5,0x10203
    80003446:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000344a:	02f71263          	bne	a4,a5,8000346e <fsinit+0x70>
  initlog(dev, &sb);
    8000344e:	0001d597          	auipc	a1,0x1d
    80003452:	9f258593          	addi	a1,a1,-1550 # 8001fe40 <sb>
    80003456:	854a                	mv	a0,s2
    80003458:	00001097          	auipc	ra,0x1
    8000345c:	b38080e7          	jalr	-1224(ra) # 80003f90 <initlog>
}
    80003460:	70a2                	ld	ra,40(sp)
    80003462:	7402                	ld	s0,32(sp)
    80003464:	64e2                	ld	s1,24(sp)
    80003466:	6942                	ld	s2,16(sp)
    80003468:	69a2                	ld	s3,8(sp)
    8000346a:	6145                	addi	sp,sp,48
    8000346c:	8082                	ret
    panic("invalid file system");
    8000346e:	00005517          	auipc	a0,0x5
    80003472:	11250513          	addi	a0,a0,274 # 80008580 <syscalls+0x140>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	160080e7          	jalr	352(ra) # 800005d6 <panic>

000000008000347e <iinit>:
{
    8000347e:	7179                	addi	sp,sp,-48
    80003480:	f406                	sd	ra,40(sp)
    80003482:	f022                	sd	s0,32(sp)
    80003484:	ec26                	sd	s1,24(sp)
    80003486:	e84a                	sd	s2,16(sp)
    80003488:	e44e                	sd	s3,8(sp)
    8000348a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000348c:	00005597          	auipc	a1,0x5
    80003490:	10c58593          	addi	a1,a1,268 # 80008598 <syscalls+0x158>
    80003494:	0001d517          	auipc	a0,0x1d
    80003498:	9cc50513          	addi	a0,a0,-1588 # 8001fe60 <icache>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	748080e7          	jalr	1864(ra) # 80000be4 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034a4:	0001d497          	auipc	s1,0x1d
    800034a8:	9e448493          	addi	s1,s1,-1564 # 8001fe88 <icache+0x28>
    800034ac:	0001e997          	auipc	s3,0x1e
    800034b0:	46c98993          	addi	s3,s3,1132 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034b4:	00005917          	auipc	s2,0x5
    800034b8:	0ec90913          	addi	s2,s2,236 # 800085a0 <syscalls+0x160>
    800034bc:	85ca                	mv	a1,s2
    800034be:	8526                	mv	a0,s1
    800034c0:	00001097          	auipc	ra,0x1
    800034c4:	e36080e7          	jalr	-458(ra) # 800042f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034c8:	08848493          	addi	s1,s1,136
    800034cc:	ff3498e3          	bne	s1,s3,800034bc <iinit+0x3e>
}
    800034d0:	70a2                	ld	ra,40(sp)
    800034d2:	7402                	ld	s0,32(sp)
    800034d4:	64e2                	ld	s1,24(sp)
    800034d6:	6942                	ld	s2,16(sp)
    800034d8:	69a2                	ld	s3,8(sp)
    800034da:	6145                	addi	sp,sp,48
    800034dc:	8082                	ret

00000000800034de <ialloc>:
{
    800034de:	715d                	addi	sp,sp,-80
    800034e0:	e486                	sd	ra,72(sp)
    800034e2:	e0a2                	sd	s0,64(sp)
    800034e4:	fc26                	sd	s1,56(sp)
    800034e6:	f84a                	sd	s2,48(sp)
    800034e8:	f44e                	sd	s3,40(sp)
    800034ea:	f052                	sd	s4,32(sp)
    800034ec:	ec56                	sd	s5,24(sp)
    800034ee:	e85a                	sd	s6,16(sp)
    800034f0:	e45e                	sd	s7,8(sp)
    800034f2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034f4:	0001d717          	auipc	a4,0x1d
    800034f8:	95872703          	lw	a4,-1704(a4) # 8001fe4c <sb+0xc>
    800034fc:	4785                	li	a5,1
    800034fe:	04e7fa63          	bgeu	a5,a4,80003552 <ialloc+0x74>
    80003502:	8aaa                	mv	s5,a0
    80003504:	8bae                	mv	s7,a1
    80003506:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003508:	0001da17          	auipc	s4,0x1d
    8000350c:	938a0a13          	addi	s4,s4,-1736 # 8001fe40 <sb>
    80003510:	00048b1b          	sext.w	s6,s1
    80003514:	0044d593          	srli	a1,s1,0x4
    80003518:	018a2783          	lw	a5,24(s4)
    8000351c:	9dbd                	addw	a1,a1,a5
    8000351e:	8556                	mv	a0,s5
    80003520:	00000097          	auipc	ra,0x0
    80003524:	954080e7          	jalr	-1708(ra) # 80002e74 <bread>
    80003528:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000352a:	05850993          	addi	s3,a0,88
    8000352e:	00f4f793          	andi	a5,s1,15
    80003532:	079a                	slli	a5,a5,0x6
    80003534:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003536:	00099783          	lh	a5,0(s3)
    8000353a:	c785                	beqz	a5,80003562 <ialloc+0x84>
    brelse(bp);
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	a68080e7          	jalr	-1432(ra) # 80002fa4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003544:	0485                	addi	s1,s1,1
    80003546:	00ca2703          	lw	a4,12(s4)
    8000354a:	0004879b          	sext.w	a5,s1
    8000354e:	fce7e1e3          	bltu	a5,a4,80003510 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003552:	00005517          	auipc	a0,0x5
    80003556:	05650513          	addi	a0,a0,86 # 800085a8 <syscalls+0x168>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	07c080e7          	jalr	124(ra) # 800005d6 <panic>
      memset(dip, 0, sizeof(*dip));
    80003562:	04000613          	li	a2,64
    80003566:	4581                	li	a1,0
    80003568:	854e                	mv	a0,s3
    8000356a:	ffffe097          	auipc	ra,0xffffe
    8000356e:	806080e7          	jalr	-2042(ra) # 80000d70 <memset>
      dip->type = type;
    80003572:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003576:	854a                	mv	a0,s2
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	c90080e7          	jalr	-880(ra) # 80004208 <log_write>
      brelse(bp);
    80003580:	854a                	mv	a0,s2
    80003582:	00000097          	auipc	ra,0x0
    80003586:	a22080e7          	jalr	-1502(ra) # 80002fa4 <brelse>
      return iget(dev, inum);
    8000358a:	85da                	mv	a1,s6
    8000358c:	8556                	mv	a0,s5
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	db4080e7          	jalr	-588(ra) # 80003342 <iget>
}
    80003596:	60a6                	ld	ra,72(sp)
    80003598:	6406                	ld	s0,64(sp)
    8000359a:	74e2                	ld	s1,56(sp)
    8000359c:	7942                	ld	s2,48(sp)
    8000359e:	79a2                	ld	s3,40(sp)
    800035a0:	7a02                	ld	s4,32(sp)
    800035a2:	6ae2                	ld	s5,24(sp)
    800035a4:	6b42                	ld	s6,16(sp)
    800035a6:	6ba2                	ld	s7,8(sp)
    800035a8:	6161                	addi	sp,sp,80
    800035aa:	8082                	ret

00000000800035ac <iupdate>:
{
    800035ac:	1101                	addi	sp,sp,-32
    800035ae:	ec06                	sd	ra,24(sp)
    800035b0:	e822                	sd	s0,16(sp)
    800035b2:	e426                	sd	s1,8(sp)
    800035b4:	e04a                	sd	s2,0(sp)
    800035b6:	1000                	addi	s0,sp,32
    800035b8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035ba:	415c                	lw	a5,4(a0)
    800035bc:	0047d79b          	srliw	a5,a5,0x4
    800035c0:	0001d597          	auipc	a1,0x1d
    800035c4:	8985a583          	lw	a1,-1896(a1) # 8001fe58 <sb+0x18>
    800035c8:	9dbd                	addw	a1,a1,a5
    800035ca:	4108                	lw	a0,0(a0)
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	8a8080e7          	jalr	-1880(ra) # 80002e74 <bread>
    800035d4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035d6:	05850793          	addi	a5,a0,88
    800035da:	40c8                	lw	a0,4(s1)
    800035dc:	893d                	andi	a0,a0,15
    800035de:	051a                	slli	a0,a0,0x6
    800035e0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035e2:	04449703          	lh	a4,68(s1)
    800035e6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035ea:	04649703          	lh	a4,70(s1)
    800035ee:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035f2:	04849703          	lh	a4,72(s1)
    800035f6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035fa:	04a49703          	lh	a4,74(s1)
    800035fe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003602:	44f8                	lw	a4,76(s1)
    80003604:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003606:	03400613          	li	a2,52
    8000360a:	05048593          	addi	a1,s1,80
    8000360e:	0531                	addi	a0,a0,12
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	7c0080e7          	jalr	1984(ra) # 80000dd0 <memmove>
  log_write(bp);
    80003618:	854a                	mv	a0,s2
    8000361a:	00001097          	auipc	ra,0x1
    8000361e:	bee080e7          	jalr	-1042(ra) # 80004208 <log_write>
  brelse(bp);
    80003622:	854a                	mv	a0,s2
    80003624:	00000097          	auipc	ra,0x0
    80003628:	980080e7          	jalr	-1664(ra) # 80002fa4 <brelse>
}
    8000362c:	60e2                	ld	ra,24(sp)
    8000362e:	6442                	ld	s0,16(sp)
    80003630:	64a2                	ld	s1,8(sp)
    80003632:	6902                	ld	s2,0(sp)
    80003634:	6105                	addi	sp,sp,32
    80003636:	8082                	ret

0000000080003638 <idup>:
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	e426                	sd	s1,8(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003644:	0001d517          	auipc	a0,0x1d
    80003648:	81c50513          	addi	a0,a0,-2020 # 8001fe60 <icache>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	628080e7          	jalr	1576(ra) # 80000c74 <acquire>
  ip->ref++;
    80003654:	449c                	lw	a5,8(s1)
    80003656:	2785                	addiw	a5,a5,1
    80003658:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000365a:	0001d517          	auipc	a0,0x1d
    8000365e:	80650513          	addi	a0,a0,-2042 # 8001fe60 <icache>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	6c6080e7          	jalr	1734(ra) # 80000d28 <release>
}
    8000366a:	8526                	mv	a0,s1
    8000366c:	60e2                	ld	ra,24(sp)
    8000366e:	6442                	ld	s0,16(sp)
    80003670:	64a2                	ld	s1,8(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret

0000000080003676 <ilock>:
{
    80003676:	1101                	addi	sp,sp,-32
    80003678:	ec06                	sd	ra,24(sp)
    8000367a:	e822                	sd	s0,16(sp)
    8000367c:	e426                	sd	s1,8(sp)
    8000367e:	e04a                	sd	s2,0(sp)
    80003680:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003682:	c115                	beqz	a0,800036a6 <ilock+0x30>
    80003684:	84aa                	mv	s1,a0
    80003686:	451c                	lw	a5,8(a0)
    80003688:	00f05f63          	blez	a5,800036a6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000368c:	0541                	addi	a0,a0,16
    8000368e:	00001097          	auipc	ra,0x1
    80003692:	ca2080e7          	jalr	-862(ra) # 80004330 <acquiresleep>
  if(ip->valid == 0){
    80003696:	40bc                	lw	a5,64(s1)
    80003698:	cf99                	beqz	a5,800036b6 <ilock+0x40>
}
    8000369a:	60e2                	ld	ra,24(sp)
    8000369c:	6442                	ld	s0,16(sp)
    8000369e:	64a2                	ld	s1,8(sp)
    800036a0:	6902                	ld	s2,0(sp)
    800036a2:	6105                	addi	sp,sp,32
    800036a4:	8082                	ret
    panic("ilock");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	f1a50513          	addi	a0,a0,-230 # 800085c0 <syscalls+0x180>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	f28080e7          	jalr	-216(ra) # 800005d6 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036b6:	40dc                	lw	a5,4(s1)
    800036b8:	0047d79b          	srliw	a5,a5,0x4
    800036bc:	0001c597          	auipc	a1,0x1c
    800036c0:	79c5a583          	lw	a1,1948(a1) # 8001fe58 <sb+0x18>
    800036c4:	9dbd                	addw	a1,a1,a5
    800036c6:	4088                	lw	a0,0(s1)
    800036c8:	fffff097          	auipc	ra,0xfffff
    800036cc:	7ac080e7          	jalr	1964(ra) # 80002e74 <bread>
    800036d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d2:	05850593          	addi	a1,a0,88
    800036d6:	40dc                	lw	a5,4(s1)
    800036d8:	8bbd                	andi	a5,a5,15
    800036da:	079a                	slli	a5,a5,0x6
    800036dc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036de:	00059783          	lh	a5,0(a1)
    800036e2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036e6:	00259783          	lh	a5,2(a1)
    800036ea:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036ee:	00459783          	lh	a5,4(a1)
    800036f2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036f6:	00659783          	lh	a5,6(a1)
    800036fa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036fe:	459c                	lw	a5,8(a1)
    80003700:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003702:	03400613          	li	a2,52
    80003706:	05b1                	addi	a1,a1,12
    80003708:	05048513          	addi	a0,s1,80
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	6c4080e7          	jalr	1732(ra) # 80000dd0 <memmove>
    brelse(bp);
    80003714:	854a                	mv	a0,s2
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	88e080e7          	jalr	-1906(ra) # 80002fa4 <brelse>
    ip->valid = 1;
    8000371e:	4785                	li	a5,1
    80003720:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003722:	04449783          	lh	a5,68(s1)
    80003726:	fbb5                	bnez	a5,8000369a <ilock+0x24>
      panic("ilock: no type");
    80003728:	00005517          	auipc	a0,0x5
    8000372c:	ea050513          	addi	a0,a0,-352 # 800085c8 <syscalls+0x188>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	ea6080e7          	jalr	-346(ra) # 800005d6 <panic>

0000000080003738 <iunlock>:
{
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	e04a                	sd	s2,0(sp)
    80003742:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003744:	c905                	beqz	a0,80003774 <iunlock+0x3c>
    80003746:	84aa                	mv	s1,a0
    80003748:	01050913          	addi	s2,a0,16
    8000374c:	854a                	mv	a0,s2
    8000374e:	00001097          	auipc	ra,0x1
    80003752:	c7c080e7          	jalr	-900(ra) # 800043ca <holdingsleep>
    80003756:	cd19                	beqz	a0,80003774 <iunlock+0x3c>
    80003758:	449c                	lw	a5,8(s1)
    8000375a:	00f05d63          	blez	a5,80003774 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	c26080e7          	jalr	-986(ra) # 80004386 <releasesleep>
}
    80003768:	60e2                	ld	ra,24(sp)
    8000376a:	6442                	ld	s0,16(sp)
    8000376c:	64a2                	ld	s1,8(sp)
    8000376e:	6902                	ld	s2,0(sp)
    80003770:	6105                	addi	sp,sp,32
    80003772:	8082                	ret
    panic("iunlock");
    80003774:	00005517          	auipc	a0,0x5
    80003778:	e6450513          	addi	a0,a0,-412 # 800085d8 <syscalls+0x198>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	e5a080e7          	jalr	-422(ra) # 800005d6 <panic>

0000000080003784 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003784:	7179                	addi	sp,sp,-48
    80003786:	f406                	sd	ra,40(sp)
    80003788:	f022                	sd	s0,32(sp)
    8000378a:	ec26                	sd	s1,24(sp)
    8000378c:	e84a                	sd	s2,16(sp)
    8000378e:	e44e                	sd	s3,8(sp)
    80003790:	e052                	sd	s4,0(sp)
    80003792:	1800                	addi	s0,sp,48
    80003794:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003796:	05050493          	addi	s1,a0,80
    8000379a:	08050913          	addi	s2,a0,128
    8000379e:	a021                	j	800037a6 <itrunc+0x22>
    800037a0:	0491                	addi	s1,s1,4
    800037a2:	01248d63          	beq	s1,s2,800037bc <itrunc+0x38>
    if(ip->addrs[i]){
    800037a6:	408c                	lw	a1,0(s1)
    800037a8:	dde5                	beqz	a1,800037a0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037aa:	0009a503          	lw	a0,0(s3)
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	90c080e7          	jalr	-1780(ra) # 800030ba <bfree>
      ip->addrs[i] = 0;
    800037b6:	0004a023          	sw	zero,0(s1)
    800037ba:	b7dd                	j	800037a0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037bc:	0809a583          	lw	a1,128(s3)
    800037c0:	e185                	bnez	a1,800037e0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037c2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037c6:	854e                	mv	a0,s3
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	de4080e7          	jalr	-540(ra) # 800035ac <iupdate>
}
    800037d0:	70a2                	ld	ra,40(sp)
    800037d2:	7402                	ld	s0,32(sp)
    800037d4:	64e2                	ld	s1,24(sp)
    800037d6:	6942                	ld	s2,16(sp)
    800037d8:	69a2                	ld	s3,8(sp)
    800037da:	6a02                	ld	s4,0(sp)
    800037dc:	6145                	addi	sp,sp,48
    800037de:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037e0:	0009a503          	lw	a0,0(s3)
    800037e4:	fffff097          	auipc	ra,0xfffff
    800037e8:	690080e7          	jalr	1680(ra) # 80002e74 <bread>
    800037ec:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037ee:	05850493          	addi	s1,a0,88
    800037f2:	45850913          	addi	s2,a0,1112
    800037f6:	a811                	j	8000380a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037f8:	0009a503          	lw	a0,0(s3)
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	8be080e7          	jalr	-1858(ra) # 800030ba <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003804:	0491                	addi	s1,s1,4
    80003806:	01248563          	beq	s1,s2,80003810 <itrunc+0x8c>
      if(a[j])
    8000380a:	408c                	lw	a1,0(s1)
    8000380c:	dde5                	beqz	a1,80003804 <itrunc+0x80>
    8000380e:	b7ed                	j	800037f8 <itrunc+0x74>
    brelse(bp);
    80003810:	8552                	mv	a0,s4
    80003812:	fffff097          	auipc	ra,0xfffff
    80003816:	792080e7          	jalr	1938(ra) # 80002fa4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000381a:	0809a583          	lw	a1,128(s3)
    8000381e:	0009a503          	lw	a0,0(s3)
    80003822:	00000097          	auipc	ra,0x0
    80003826:	898080e7          	jalr	-1896(ra) # 800030ba <bfree>
    ip->addrs[NDIRECT] = 0;
    8000382a:	0809a023          	sw	zero,128(s3)
    8000382e:	bf51                	j	800037c2 <itrunc+0x3e>

0000000080003830 <iput>:
{
    80003830:	1101                	addi	sp,sp,-32
    80003832:	ec06                	sd	ra,24(sp)
    80003834:	e822                	sd	s0,16(sp)
    80003836:	e426                	sd	s1,8(sp)
    80003838:	e04a                	sd	s2,0(sp)
    8000383a:	1000                	addi	s0,sp,32
    8000383c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000383e:	0001c517          	auipc	a0,0x1c
    80003842:	62250513          	addi	a0,a0,1570 # 8001fe60 <icache>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	42e080e7          	jalr	1070(ra) # 80000c74 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384e:	4498                	lw	a4,8(s1)
    80003850:	4785                	li	a5,1
    80003852:	02f70363          	beq	a4,a5,80003878 <iput+0x48>
  ip->ref--;
    80003856:	449c                	lw	a5,8(s1)
    80003858:	37fd                	addiw	a5,a5,-1
    8000385a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000385c:	0001c517          	auipc	a0,0x1c
    80003860:	60450513          	addi	a0,a0,1540 # 8001fe60 <icache>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	4c4080e7          	jalr	1220(ra) # 80000d28 <release>
}
    8000386c:	60e2                	ld	ra,24(sp)
    8000386e:	6442                	ld	s0,16(sp)
    80003870:	64a2                	ld	s1,8(sp)
    80003872:	6902                	ld	s2,0(sp)
    80003874:	6105                	addi	sp,sp,32
    80003876:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003878:	40bc                	lw	a5,64(s1)
    8000387a:	dff1                	beqz	a5,80003856 <iput+0x26>
    8000387c:	04a49783          	lh	a5,74(s1)
    80003880:	fbf9                	bnez	a5,80003856 <iput+0x26>
    acquiresleep(&ip->lock);
    80003882:	01048913          	addi	s2,s1,16
    80003886:	854a                	mv	a0,s2
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	aa8080e7          	jalr	-1368(ra) # 80004330 <acquiresleep>
    release(&icache.lock);
    80003890:	0001c517          	auipc	a0,0x1c
    80003894:	5d050513          	addi	a0,a0,1488 # 8001fe60 <icache>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	490080e7          	jalr	1168(ra) # 80000d28 <release>
    itrunc(ip);
    800038a0:	8526                	mv	a0,s1
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	ee2080e7          	jalr	-286(ra) # 80003784 <itrunc>
    ip->type = 0;
    800038aa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038ae:	8526                	mv	a0,s1
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	cfc080e7          	jalr	-772(ra) # 800035ac <iupdate>
    ip->valid = 0;
    800038b8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038bc:	854a                	mv	a0,s2
    800038be:	00001097          	auipc	ra,0x1
    800038c2:	ac8080e7          	jalr	-1336(ra) # 80004386 <releasesleep>
    acquire(&icache.lock);
    800038c6:	0001c517          	auipc	a0,0x1c
    800038ca:	59a50513          	addi	a0,a0,1434 # 8001fe60 <icache>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	3a6080e7          	jalr	934(ra) # 80000c74 <acquire>
    800038d6:	b741                	j	80003856 <iput+0x26>

00000000800038d8 <iunlockput>:
{
    800038d8:	1101                	addi	sp,sp,-32
    800038da:	ec06                	sd	ra,24(sp)
    800038dc:	e822                	sd	s0,16(sp)
    800038de:	e426                	sd	s1,8(sp)
    800038e0:	1000                	addi	s0,sp,32
    800038e2:	84aa                	mv	s1,a0
  iunlock(ip);
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	e54080e7          	jalr	-428(ra) # 80003738 <iunlock>
  iput(ip);
    800038ec:	8526                	mv	a0,s1
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	f42080e7          	jalr	-190(ra) # 80003830 <iput>
}
    800038f6:	60e2                	ld	ra,24(sp)
    800038f8:	6442                	ld	s0,16(sp)
    800038fa:	64a2                	ld	s1,8(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret

0000000080003900 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003900:	1141                	addi	sp,sp,-16
    80003902:	e422                	sd	s0,8(sp)
    80003904:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003906:	411c                	lw	a5,0(a0)
    80003908:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000390a:	415c                	lw	a5,4(a0)
    8000390c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000390e:	04451783          	lh	a5,68(a0)
    80003912:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003916:	04a51783          	lh	a5,74(a0)
    8000391a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000391e:	04c56783          	lwu	a5,76(a0)
    80003922:	e99c                	sd	a5,16(a1)
}
    80003924:	6422                	ld	s0,8(sp)
    80003926:	0141                	addi	sp,sp,16
    80003928:	8082                	ret

000000008000392a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000392a:	457c                	lw	a5,76(a0)
    8000392c:	0ed7e863          	bltu	a5,a3,80003a1c <readi+0xf2>
{
    80003930:	7159                	addi	sp,sp,-112
    80003932:	f486                	sd	ra,104(sp)
    80003934:	f0a2                	sd	s0,96(sp)
    80003936:	eca6                	sd	s1,88(sp)
    80003938:	e8ca                	sd	s2,80(sp)
    8000393a:	e4ce                	sd	s3,72(sp)
    8000393c:	e0d2                	sd	s4,64(sp)
    8000393e:	fc56                	sd	s5,56(sp)
    80003940:	f85a                	sd	s6,48(sp)
    80003942:	f45e                	sd	s7,40(sp)
    80003944:	f062                	sd	s8,32(sp)
    80003946:	ec66                	sd	s9,24(sp)
    80003948:	e86a                	sd	s10,16(sp)
    8000394a:	e46e                	sd	s11,8(sp)
    8000394c:	1880                	addi	s0,sp,112
    8000394e:	8baa                	mv	s7,a0
    80003950:	8c2e                	mv	s8,a1
    80003952:	8ab2                	mv	s5,a2
    80003954:	84b6                	mv	s1,a3
    80003956:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003958:	9f35                	addw	a4,a4,a3
    return 0;
    8000395a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000395c:	08d76f63          	bltu	a4,a3,800039fa <readi+0xd0>
  if(off + n > ip->size)
    80003960:	00e7f463          	bgeu	a5,a4,80003968 <readi+0x3e>
    n = ip->size - off;
    80003964:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003968:	0a0b0863          	beqz	s6,80003a18 <readi+0xee>
    8000396c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000396e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003972:	5cfd                	li	s9,-1
    80003974:	a82d                	j	800039ae <readi+0x84>
    80003976:	020a1d93          	slli	s11,s4,0x20
    8000397a:	020ddd93          	srli	s11,s11,0x20
    8000397e:	05890613          	addi	a2,s2,88
    80003982:	86ee                	mv	a3,s11
    80003984:	963a                	add	a2,a2,a4
    80003986:	85d6                	mv	a1,s5
    80003988:	8562                	mv	a0,s8
    8000398a:	fffff097          	auipc	ra,0xfffff
    8000398e:	b26080e7          	jalr	-1242(ra) # 800024b0 <either_copyout>
    80003992:	05950d63          	beq	a0,s9,800039ec <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003996:	854a                	mv	a0,s2
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	60c080e7          	jalr	1548(ra) # 80002fa4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a0:	013a09bb          	addw	s3,s4,s3
    800039a4:	009a04bb          	addw	s1,s4,s1
    800039a8:	9aee                	add	s5,s5,s11
    800039aa:	0569f663          	bgeu	s3,s6,800039f6 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039ae:	000ba903          	lw	s2,0(s7)
    800039b2:	00a4d59b          	srliw	a1,s1,0xa
    800039b6:	855e                	mv	a0,s7
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	8b0080e7          	jalr	-1872(ra) # 80003268 <bmap>
    800039c0:	0005059b          	sext.w	a1,a0
    800039c4:	854a                	mv	a0,s2
    800039c6:	fffff097          	auipc	ra,0xfffff
    800039ca:	4ae080e7          	jalr	1198(ra) # 80002e74 <bread>
    800039ce:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039d0:	3ff4f713          	andi	a4,s1,1023
    800039d4:	40ed07bb          	subw	a5,s10,a4
    800039d8:	413b06bb          	subw	a3,s6,s3
    800039dc:	8a3e                	mv	s4,a5
    800039de:	2781                	sext.w	a5,a5
    800039e0:	0006861b          	sext.w	a2,a3
    800039e4:	f8f679e3          	bgeu	a2,a5,80003976 <readi+0x4c>
    800039e8:	8a36                	mv	s4,a3
    800039ea:	b771                	j	80003976 <readi+0x4c>
      brelse(bp);
    800039ec:	854a                	mv	a0,s2
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	5b6080e7          	jalr	1462(ra) # 80002fa4 <brelse>
  }
  return tot;
    800039f6:	0009851b          	sext.w	a0,s3
}
    800039fa:	70a6                	ld	ra,104(sp)
    800039fc:	7406                	ld	s0,96(sp)
    800039fe:	64e6                	ld	s1,88(sp)
    80003a00:	6946                	ld	s2,80(sp)
    80003a02:	69a6                	ld	s3,72(sp)
    80003a04:	6a06                	ld	s4,64(sp)
    80003a06:	7ae2                	ld	s5,56(sp)
    80003a08:	7b42                	ld	s6,48(sp)
    80003a0a:	7ba2                	ld	s7,40(sp)
    80003a0c:	7c02                	ld	s8,32(sp)
    80003a0e:	6ce2                	ld	s9,24(sp)
    80003a10:	6d42                	ld	s10,16(sp)
    80003a12:	6da2                	ld	s11,8(sp)
    80003a14:	6165                	addi	sp,sp,112
    80003a16:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a18:	89da                	mv	s3,s6
    80003a1a:	bff1                	j	800039f6 <readi+0xcc>
    return 0;
    80003a1c:	4501                	li	a0,0
}
    80003a1e:	8082                	ret

0000000080003a20 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a20:	457c                	lw	a5,76(a0)
    80003a22:	10d7e663          	bltu	a5,a3,80003b2e <writei+0x10e>
{
    80003a26:	7159                	addi	sp,sp,-112
    80003a28:	f486                	sd	ra,104(sp)
    80003a2a:	f0a2                	sd	s0,96(sp)
    80003a2c:	eca6                	sd	s1,88(sp)
    80003a2e:	e8ca                	sd	s2,80(sp)
    80003a30:	e4ce                	sd	s3,72(sp)
    80003a32:	e0d2                	sd	s4,64(sp)
    80003a34:	fc56                	sd	s5,56(sp)
    80003a36:	f85a                	sd	s6,48(sp)
    80003a38:	f45e                	sd	s7,40(sp)
    80003a3a:	f062                	sd	s8,32(sp)
    80003a3c:	ec66                	sd	s9,24(sp)
    80003a3e:	e86a                	sd	s10,16(sp)
    80003a40:	e46e                	sd	s11,8(sp)
    80003a42:	1880                	addi	s0,sp,112
    80003a44:	8baa                	mv	s7,a0
    80003a46:	8c2e                	mv	s8,a1
    80003a48:	8ab2                	mv	s5,a2
    80003a4a:	8936                	mv	s2,a3
    80003a4c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a4e:	00e687bb          	addw	a5,a3,a4
    80003a52:	0ed7e063          	bltu	a5,a3,80003b32 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a56:	00043737          	lui	a4,0x43
    80003a5a:	0cf76e63          	bltu	a4,a5,80003b36 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a5e:	0a0b0763          	beqz	s6,80003b0c <writei+0xec>
    80003a62:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a64:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a68:	5cfd                	li	s9,-1
    80003a6a:	a091                	j	80003aae <writei+0x8e>
    80003a6c:	02099d93          	slli	s11,s3,0x20
    80003a70:	020ddd93          	srli	s11,s11,0x20
    80003a74:	05848513          	addi	a0,s1,88
    80003a78:	86ee                	mv	a3,s11
    80003a7a:	8656                	mv	a2,s5
    80003a7c:	85e2                	mv	a1,s8
    80003a7e:	953a                	add	a0,a0,a4
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	a86080e7          	jalr	-1402(ra) # 80002506 <either_copyin>
    80003a88:	07950263          	beq	a0,s9,80003aec <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a8c:	8526                	mv	a0,s1
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	77a080e7          	jalr	1914(ra) # 80004208 <log_write>
    brelse(bp);
    80003a96:	8526                	mv	a0,s1
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	50c080e7          	jalr	1292(ra) # 80002fa4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa0:	01498a3b          	addw	s4,s3,s4
    80003aa4:	0129893b          	addw	s2,s3,s2
    80003aa8:	9aee                	add	s5,s5,s11
    80003aaa:	056a7663          	bgeu	s4,s6,80003af6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aae:	000ba483          	lw	s1,0(s7)
    80003ab2:	00a9559b          	srliw	a1,s2,0xa
    80003ab6:	855e                	mv	a0,s7
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	7b0080e7          	jalr	1968(ra) # 80003268 <bmap>
    80003ac0:	0005059b          	sext.w	a1,a0
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	3ae080e7          	jalr	942(ra) # 80002e74 <bread>
    80003ace:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad0:	3ff97713          	andi	a4,s2,1023
    80003ad4:	40ed07bb          	subw	a5,s10,a4
    80003ad8:	414b06bb          	subw	a3,s6,s4
    80003adc:	89be                	mv	s3,a5
    80003ade:	2781                	sext.w	a5,a5
    80003ae0:	0006861b          	sext.w	a2,a3
    80003ae4:	f8f674e3          	bgeu	a2,a5,80003a6c <writei+0x4c>
    80003ae8:	89b6                	mv	s3,a3
    80003aea:	b749                	j	80003a6c <writei+0x4c>
      brelse(bp);
    80003aec:	8526                	mv	a0,s1
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	4b6080e7          	jalr	1206(ra) # 80002fa4 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003af6:	04cba783          	lw	a5,76(s7)
    80003afa:	0127f463          	bgeu	a5,s2,80003b02 <writei+0xe2>
      ip->size = off;
    80003afe:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b02:	855e                	mv	a0,s7
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	aa8080e7          	jalr	-1368(ra) # 800035ac <iupdate>
  }

  return n;
    80003b0c:	000b051b          	sext.w	a0,s6
}
    80003b10:	70a6                	ld	ra,104(sp)
    80003b12:	7406                	ld	s0,96(sp)
    80003b14:	64e6                	ld	s1,88(sp)
    80003b16:	6946                	ld	s2,80(sp)
    80003b18:	69a6                	ld	s3,72(sp)
    80003b1a:	6a06                	ld	s4,64(sp)
    80003b1c:	7ae2                	ld	s5,56(sp)
    80003b1e:	7b42                	ld	s6,48(sp)
    80003b20:	7ba2                	ld	s7,40(sp)
    80003b22:	7c02                	ld	s8,32(sp)
    80003b24:	6ce2                	ld	s9,24(sp)
    80003b26:	6d42                	ld	s10,16(sp)
    80003b28:	6da2                	ld	s11,8(sp)
    80003b2a:	6165                	addi	sp,sp,112
    80003b2c:	8082                	ret
    return -1;
    80003b2e:	557d                	li	a0,-1
}
    80003b30:	8082                	ret
    return -1;
    80003b32:	557d                	li	a0,-1
    80003b34:	bff1                	j	80003b10 <writei+0xf0>
    return -1;
    80003b36:	557d                	li	a0,-1
    80003b38:	bfe1                	j	80003b10 <writei+0xf0>

0000000080003b3a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b3a:	1141                	addi	sp,sp,-16
    80003b3c:	e406                	sd	ra,8(sp)
    80003b3e:	e022                	sd	s0,0(sp)
    80003b40:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b42:	4639                	li	a2,14
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	308080e7          	jalr	776(ra) # 80000e4c <strncmp>
}
    80003b4c:	60a2                	ld	ra,8(sp)
    80003b4e:	6402                	ld	s0,0(sp)
    80003b50:	0141                	addi	sp,sp,16
    80003b52:	8082                	ret

0000000080003b54 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b54:	7139                	addi	sp,sp,-64
    80003b56:	fc06                	sd	ra,56(sp)
    80003b58:	f822                	sd	s0,48(sp)
    80003b5a:	f426                	sd	s1,40(sp)
    80003b5c:	f04a                	sd	s2,32(sp)
    80003b5e:	ec4e                	sd	s3,24(sp)
    80003b60:	e852                	sd	s4,16(sp)
    80003b62:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b64:	04451703          	lh	a4,68(a0)
    80003b68:	4785                	li	a5,1
    80003b6a:	00f71a63          	bne	a4,a5,80003b7e <dirlookup+0x2a>
    80003b6e:	892a                	mv	s2,a0
    80003b70:	89ae                	mv	s3,a1
    80003b72:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b74:	457c                	lw	a5,76(a0)
    80003b76:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b78:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7a:	e79d                	bnez	a5,80003ba8 <dirlookup+0x54>
    80003b7c:	a8a5                	j	80003bf4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b7e:	00005517          	auipc	a0,0x5
    80003b82:	a6250513          	addi	a0,a0,-1438 # 800085e0 <syscalls+0x1a0>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	a50080e7          	jalr	-1456(ra) # 800005d6 <panic>
      panic("dirlookup read");
    80003b8e:	00005517          	auipc	a0,0x5
    80003b92:	a6a50513          	addi	a0,a0,-1430 # 800085f8 <syscalls+0x1b8>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	a40080e7          	jalr	-1472(ra) # 800005d6 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9e:	24c1                	addiw	s1,s1,16
    80003ba0:	04c92783          	lw	a5,76(s2)
    80003ba4:	04f4f763          	bgeu	s1,a5,80003bf2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ba8:	4741                	li	a4,16
    80003baa:	86a6                	mv	a3,s1
    80003bac:	fc040613          	addi	a2,s0,-64
    80003bb0:	4581                	li	a1,0
    80003bb2:	854a                	mv	a0,s2
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	d76080e7          	jalr	-650(ra) # 8000392a <readi>
    80003bbc:	47c1                	li	a5,16
    80003bbe:	fcf518e3          	bne	a0,a5,80003b8e <dirlookup+0x3a>
    if(de.inum == 0)
    80003bc2:	fc045783          	lhu	a5,-64(s0)
    80003bc6:	dfe1                	beqz	a5,80003b9e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bc8:	fc240593          	addi	a1,s0,-62
    80003bcc:	854e                	mv	a0,s3
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	f6c080e7          	jalr	-148(ra) # 80003b3a <namecmp>
    80003bd6:	f561                	bnez	a0,80003b9e <dirlookup+0x4a>
      if(poff)
    80003bd8:	000a0463          	beqz	s4,80003be0 <dirlookup+0x8c>
        *poff = off;
    80003bdc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003be0:	fc045583          	lhu	a1,-64(s0)
    80003be4:	00092503          	lw	a0,0(s2)
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	75a080e7          	jalr	1882(ra) # 80003342 <iget>
    80003bf0:	a011                	j	80003bf4 <dirlookup+0xa0>
  return 0;
    80003bf2:	4501                	li	a0,0
}
    80003bf4:	70e2                	ld	ra,56(sp)
    80003bf6:	7442                	ld	s0,48(sp)
    80003bf8:	74a2                	ld	s1,40(sp)
    80003bfa:	7902                	ld	s2,32(sp)
    80003bfc:	69e2                	ld	s3,24(sp)
    80003bfe:	6a42                	ld	s4,16(sp)
    80003c00:	6121                	addi	sp,sp,64
    80003c02:	8082                	ret

0000000080003c04 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c04:	711d                	addi	sp,sp,-96
    80003c06:	ec86                	sd	ra,88(sp)
    80003c08:	e8a2                	sd	s0,80(sp)
    80003c0a:	e4a6                	sd	s1,72(sp)
    80003c0c:	e0ca                	sd	s2,64(sp)
    80003c0e:	fc4e                	sd	s3,56(sp)
    80003c10:	f852                	sd	s4,48(sp)
    80003c12:	f456                	sd	s5,40(sp)
    80003c14:	f05a                	sd	s6,32(sp)
    80003c16:	ec5e                	sd	s7,24(sp)
    80003c18:	e862                	sd	s8,16(sp)
    80003c1a:	e466                	sd	s9,8(sp)
    80003c1c:	1080                	addi	s0,sp,96
    80003c1e:	84aa                	mv	s1,a0
    80003c20:	8b2e                	mv	s6,a1
    80003c22:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c24:	00054703          	lbu	a4,0(a0)
    80003c28:	02f00793          	li	a5,47
    80003c2c:	02f70363          	beq	a4,a5,80003c52 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c30:	ffffe097          	auipc	ra,0xffffe
    80003c34:	e12080e7          	jalr	-494(ra) # 80001a42 <myproc>
    80003c38:	15053503          	ld	a0,336(a0)
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	9fc080e7          	jalr	-1540(ra) # 80003638 <idup>
    80003c44:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c46:	02f00913          	li	s2,47
  len = path - s;
    80003c4a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c4c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c4e:	4c05                	li	s8,1
    80003c50:	a865                	j	80003d08 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c52:	4585                	li	a1,1
    80003c54:	4505                	li	a0,1
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	6ec080e7          	jalr	1772(ra) # 80003342 <iget>
    80003c5e:	89aa                	mv	s3,a0
    80003c60:	b7dd                	j	80003c46 <namex+0x42>
      iunlockput(ip);
    80003c62:	854e                	mv	a0,s3
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	c74080e7          	jalr	-908(ra) # 800038d8 <iunlockput>
      return 0;
    80003c6c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c6e:	854e                	mv	a0,s3
    80003c70:	60e6                	ld	ra,88(sp)
    80003c72:	6446                	ld	s0,80(sp)
    80003c74:	64a6                	ld	s1,72(sp)
    80003c76:	6906                	ld	s2,64(sp)
    80003c78:	79e2                	ld	s3,56(sp)
    80003c7a:	7a42                	ld	s4,48(sp)
    80003c7c:	7aa2                	ld	s5,40(sp)
    80003c7e:	7b02                	ld	s6,32(sp)
    80003c80:	6be2                	ld	s7,24(sp)
    80003c82:	6c42                	ld	s8,16(sp)
    80003c84:	6ca2                	ld	s9,8(sp)
    80003c86:	6125                	addi	sp,sp,96
    80003c88:	8082                	ret
      iunlock(ip);
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	aac080e7          	jalr	-1364(ra) # 80003738 <iunlock>
      return ip;
    80003c94:	bfe9                	j	80003c6e <namex+0x6a>
      iunlockput(ip);
    80003c96:	854e                	mv	a0,s3
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	c40080e7          	jalr	-960(ra) # 800038d8 <iunlockput>
      return 0;
    80003ca0:	89d2                	mv	s3,s4
    80003ca2:	b7f1                	j	80003c6e <namex+0x6a>
  len = path - s;
    80003ca4:	40b48633          	sub	a2,s1,a1
    80003ca8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003cac:	094cd463          	bge	s9,s4,80003d34 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cb0:	4639                	li	a2,14
    80003cb2:	8556                	mv	a0,s5
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	11c080e7          	jalr	284(ra) # 80000dd0 <memmove>
  while(*path == '/')
    80003cbc:	0004c783          	lbu	a5,0(s1)
    80003cc0:	01279763          	bne	a5,s2,80003cce <namex+0xca>
    path++;
    80003cc4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cc6:	0004c783          	lbu	a5,0(s1)
    80003cca:	ff278de3          	beq	a5,s2,80003cc4 <namex+0xc0>
    ilock(ip);
    80003cce:	854e                	mv	a0,s3
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	9a6080e7          	jalr	-1626(ra) # 80003676 <ilock>
    if(ip->type != T_DIR){
    80003cd8:	04499783          	lh	a5,68(s3)
    80003cdc:	f98793e3          	bne	a5,s8,80003c62 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ce0:	000b0563          	beqz	s6,80003cea <namex+0xe6>
    80003ce4:	0004c783          	lbu	a5,0(s1)
    80003ce8:	d3cd                	beqz	a5,80003c8a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cea:	865e                	mv	a2,s7
    80003cec:	85d6                	mv	a1,s5
    80003cee:	854e                	mv	a0,s3
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	e64080e7          	jalr	-412(ra) # 80003b54 <dirlookup>
    80003cf8:	8a2a                	mv	s4,a0
    80003cfa:	dd51                	beqz	a0,80003c96 <namex+0x92>
    iunlockput(ip);
    80003cfc:	854e                	mv	a0,s3
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	bda080e7          	jalr	-1062(ra) # 800038d8 <iunlockput>
    ip = next;
    80003d06:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d08:	0004c783          	lbu	a5,0(s1)
    80003d0c:	05279763          	bne	a5,s2,80003d5a <namex+0x156>
    path++;
    80003d10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d12:	0004c783          	lbu	a5,0(s1)
    80003d16:	ff278de3          	beq	a5,s2,80003d10 <namex+0x10c>
  if(*path == 0)
    80003d1a:	c79d                	beqz	a5,80003d48 <namex+0x144>
    path++;
    80003d1c:	85a6                	mv	a1,s1
  len = path - s;
    80003d1e:	8a5e                	mv	s4,s7
    80003d20:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d22:	01278963          	beq	a5,s2,80003d34 <namex+0x130>
    80003d26:	dfbd                	beqz	a5,80003ca4 <namex+0xa0>
    path++;
    80003d28:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d2a:	0004c783          	lbu	a5,0(s1)
    80003d2e:	ff279ce3          	bne	a5,s2,80003d26 <namex+0x122>
    80003d32:	bf8d                	j	80003ca4 <namex+0xa0>
    memmove(name, s, len);
    80003d34:	2601                	sext.w	a2,a2
    80003d36:	8556                	mv	a0,s5
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	098080e7          	jalr	152(ra) # 80000dd0 <memmove>
    name[len] = 0;
    80003d40:	9a56                	add	s4,s4,s5
    80003d42:	000a0023          	sb	zero,0(s4)
    80003d46:	bf9d                	j	80003cbc <namex+0xb8>
  if(nameiparent){
    80003d48:	f20b03e3          	beqz	s6,80003c6e <namex+0x6a>
    iput(ip);
    80003d4c:	854e                	mv	a0,s3
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	ae2080e7          	jalr	-1310(ra) # 80003830 <iput>
    return 0;
    80003d56:	4981                	li	s3,0
    80003d58:	bf19                	j	80003c6e <namex+0x6a>
  if(*path == 0)
    80003d5a:	d7fd                	beqz	a5,80003d48 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d5c:	0004c783          	lbu	a5,0(s1)
    80003d60:	85a6                	mv	a1,s1
    80003d62:	b7d1                	j	80003d26 <namex+0x122>

0000000080003d64 <dirlink>:
{
    80003d64:	7139                	addi	sp,sp,-64
    80003d66:	fc06                	sd	ra,56(sp)
    80003d68:	f822                	sd	s0,48(sp)
    80003d6a:	f426                	sd	s1,40(sp)
    80003d6c:	f04a                	sd	s2,32(sp)
    80003d6e:	ec4e                	sd	s3,24(sp)
    80003d70:	e852                	sd	s4,16(sp)
    80003d72:	0080                	addi	s0,sp,64
    80003d74:	892a                	mv	s2,a0
    80003d76:	8a2e                	mv	s4,a1
    80003d78:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d7a:	4601                	li	a2,0
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	dd8080e7          	jalr	-552(ra) # 80003b54 <dirlookup>
    80003d84:	e93d                	bnez	a0,80003dfa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d86:	04c92483          	lw	s1,76(s2)
    80003d8a:	c49d                	beqz	s1,80003db8 <dirlink+0x54>
    80003d8c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d8e:	4741                	li	a4,16
    80003d90:	86a6                	mv	a3,s1
    80003d92:	fc040613          	addi	a2,s0,-64
    80003d96:	4581                	li	a1,0
    80003d98:	854a                	mv	a0,s2
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	b90080e7          	jalr	-1136(ra) # 8000392a <readi>
    80003da2:	47c1                	li	a5,16
    80003da4:	06f51163          	bne	a0,a5,80003e06 <dirlink+0xa2>
    if(de.inum == 0)
    80003da8:	fc045783          	lhu	a5,-64(s0)
    80003dac:	c791                	beqz	a5,80003db8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dae:	24c1                	addiw	s1,s1,16
    80003db0:	04c92783          	lw	a5,76(s2)
    80003db4:	fcf4ede3          	bltu	s1,a5,80003d8e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003db8:	4639                	li	a2,14
    80003dba:	85d2                	mv	a1,s4
    80003dbc:	fc240513          	addi	a0,s0,-62
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	0c8080e7          	jalr	200(ra) # 80000e88 <strncpy>
  de.inum = inum;
    80003dc8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dcc:	4741                	li	a4,16
    80003dce:	86a6                	mv	a3,s1
    80003dd0:	fc040613          	addi	a2,s0,-64
    80003dd4:	4581                	li	a1,0
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	c48080e7          	jalr	-952(ra) # 80003a20 <writei>
    80003de0:	872a                	mv	a4,a0
    80003de2:	47c1                	li	a5,16
  return 0;
    80003de4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003de6:	02f71863          	bne	a4,a5,80003e16 <dirlink+0xb2>
}
    80003dea:	70e2                	ld	ra,56(sp)
    80003dec:	7442                	ld	s0,48(sp)
    80003dee:	74a2                	ld	s1,40(sp)
    80003df0:	7902                	ld	s2,32(sp)
    80003df2:	69e2                	ld	s3,24(sp)
    80003df4:	6a42                	ld	s4,16(sp)
    80003df6:	6121                	addi	sp,sp,64
    80003df8:	8082                	ret
    iput(ip);
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	a36080e7          	jalr	-1482(ra) # 80003830 <iput>
    return -1;
    80003e02:	557d                	li	a0,-1
    80003e04:	b7dd                	j	80003dea <dirlink+0x86>
      panic("dirlink read");
    80003e06:	00005517          	auipc	a0,0x5
    80003e0a:	80250513          	addi	a0,a0,-2046 # 80008608 <syscalls+0x1c8>
    80003e0e:	ffffc097          	auipc	ra,0xffffc
    80003e12:	7c8080e7          	jalr	1992(ra) # 800005d6 <panic>
    panic("dirlink");
    80003e16:	00005517          	auipc	a0,0x5
    80003e1a:	91250513          	addi	a0,a0,-1774 # 80008728 <syscalls+0x2e8>
    80003e1e:	ffffc097          	auipc	ra,0xffffc
    80003e22:	7b8080e7          	jalr	1976(ra) # 800005d6 <panic>

0000000080003e26 <namei>:

struct inode*
namei(char *path)
{
    80003e26:	1101                	addi	sp,sp,-32
    80003e28:	ec06                	sd	ra,24(sp)
    80003e2a:	e822                	sd	s0,16(sp)
    80003e2c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e2e:	fe040613          	addi	a2,s0,-32
    80003e32:	4581                	li	a1,0
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	dd0080e7          	jalr	-560(ra) # 80003c04 <namex>
}
    80003e3c:	60e2                	ld	ra,24(sp)
    80003e3e:	6442                	ld	s0,16(sp)
    80003e40:	6105                	addi	sp,sp,32
    80003e42:	8082                	ret

0000000080003e44 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e44:	1141                	addi	sp,sp,-16
    80003e46:	e406                	sd	ra,8(sp)
    80003e48:	e022                	sd	s0,0(sp)
    80003e4a:	0800                	addi	s0,sp,16
    80003e4c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e4e:	4585                	li	a1,1
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	db4080e7          	jalr	-588(ra) # 80003c04 <namex>
}
    80003e58:	60a2                	ld	ra,8(sp)
    80003e5a:	6402                	ld	s0,0(sp)
    80003e5c:	0141                	addi	sp,sp,16
    80003e5e:	8082                	ret

0000000080003e60 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e60:	1101                	addi	sp,sp,-32
    80003e62:	ec06                	sd	ra,24(sp)
    80003e64:	e822                	sd	s0,16(sp)
    80003e66:	e426                	sd	s1,8(sp)
    80003e68:	e04a                	sd	s2,0(sp)
    80003e6a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e6c:	0001e917          	auipc	s2,0x1e
    80003e70:	a9c90913          	addi	s2,s2,-1380 # 80021908 <log>
    80003e74:	01892583          	lw	a1,24(s2)
    80003e78:	02892503          	lw	a0,40(s2)
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	ff8080e7          	jalr	-8(ra) # 80002e74 <bread>
    80003e84:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e86:	02c92683          	lw	a3,44(s2)
    80003e8a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e8c:	02d05763          	blez	a3,80003eba <write_head+0x5a>
    80003e90:	0001e797          	auipc	a5,0x1e
    80003e94:	aa878793          	addi	a5,a5,-1368 # 80021938 <log+0x30>
    80003e98:	05c50713          	addi	a4,a0,92
    80003e9c:	36fd                	addiw	a3,a3,-1
    80003e9e:	1682                	slli	a3,a3,0x20
    80003ea0:	9281                	srli	a3,a3,0x20
    80003ea2:	068a                	slli	a3,a3,0x2
    80003ea4:	0001e617          	auipc	a2,0x1e
    80003ea8:	a9860613          	addi	a2,a2,-1384 # 8002193c <log+0x34>
    80003eac:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003eae:	4390                	lw	a2,0(a5)
    80003eb0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003eb2:	0791                	addi	a5,a5,4
    80003eb4:	0711                	addi	a4,a4,4
    80003eb6:	fed79ce3          	bne	a5,a3,80003eae <write_head+0x4e>
  }
  bwrite(buf);
    80003eba:	8526                	mv	a0,s1
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	0aa080e7          	jalr	170(ra) # 80002f66 <bwrite>
  brelse(buf);
    80003ec4:	8526                	mv	a0,s1
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	0de080e7          	jalr	222(ra) # 80002fa4 <brelse>
}
    80003ece:	60e2                	ld	ra,24(sp)
    80003ed0:	6442                	ld	s0,16(sp)
    80003ed2:	64a2                	ld	s1,8(sp)
    80003ed4:	6902                	ld	s2,0(sp)
    80003ed6:	6105                	addi	sp,sp,32
    80003ed8:	8082                	ret

0000000080003eda <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eda:	0001e797          	auipc	a5,0x1e
    80003ede:	a5a7a783          	lw	a5,-1446(a5) # 80021934 <log+0x2c>
    80003ee2:	0af05663          	blez	a5,80003f8e <install_trans+0xb4>
{
    80003ee6:	7139                	addi	sp,sp,-64
    80003ee8:	fc06                	sd	ra,56(sp)
    80003eea:	f822                	sd	s0,48(sp)
    80003eec:	f426                	sd	s1,40(sp)
    80003eee:	f04a                	sd	s2,32(sp)
    80003ef0:	ec4e                	sd	s3,24(sp)
    80003ef2:	e852                	sd	s4,16(sp)
    80003ef4:	e456                	sd	s5,8(sp)
    80003ef6:	0080                	addi	s0,sp,64
    80003ef8:	0001ea97          	auipc	s5,0x1e
    80003efc:	a40a8a93          	addi	s5,s5,-1472 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f00:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f02:	0001e997          	auipc	s3,0x1e
    80003f06:	a0698993          	addi	s3,s3,-1530 # 80021908 <log>
    80003f0a:	0189a583          	lw	a1,24(s3)
    80003f0e:	014585bb          	addw	a1,a1,s4
    80003f12:	2585                	addiw	a1,a1,1
    80003f14:	0289a503          	lw	a0,40(s3)
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	f5c080e7          	jalr	-164(ra) # 80002e74 <bread>
    80003f20:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f22:	000aa583          	lw	a1,0(s5)
    80003f26:	0289a503          	lw	a0,40(s3)
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	f4a080e7          	jalr	-182(ra) # 80002e74 <bread>
    80003f32:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f34:	40000613          	li	a2,1024
    80003f38:	05890593          	addi	a1,s2,88
    80003f3c:	05850513          	addi	a0,a0,88
    80003f40:	ffffd097          	auipc	ra,0xffffd
    80003f44:	e90080e7          	jalr	-368(ra) # 80000dd0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f48:	8526                	mv	a0,s1
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	01c080e7          	jalr	28(ra) # 80002f66 <bwrite>
    bunpin(dbuf);
    80003f52:	8526                	mv	a0,s1
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	12a080e7          	jalr	298(ra) # 8000307e <bunpin>
    brelse(lbuf);
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	046080e7          	jalr	70(ra) # 80002fa4 <brelse>
    brelse(dbuf);
    80003f66:	8526                	mv	a0,s1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	03c080e7          	jalr	60(ra) # 80002fa4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f70:	2a05                	addiw	s4,s4,1
    80003f72:	0a91                	addi	s5,s5,4
    80003f74:	02c9a783          	lw	a5,44(s3)
    80003f78:	f8fa49e3          	blt	s4,a5,80003f0a <install_trans+0x30>
}
    80003f7c:	70e2                	ld	ra,56(sp)
    80003f7e:	7442                	ld	s0,48(sp)
    80003f80:	74a2                	ld	s1,40(sp)
    80003f82:	7902                	ld	s2,32(sp)
    80003f84:	69e2                	ld	s3,24(sp)
    80003f86:	6a42                	ld	s4,16(sp)
    80003f88:	6aa2                	ld	s5,8(sp)
    80003f8a:	6121                	addi	sp,sp,64
    80003f8c:	8082                	ret
    80003f8e:	8082                	ret

0000000080003f90 <initlog>:
{
    80003f90:	7179                	addi	sp,sp,-48
    80003f92:	f406                	sd	ra,40(sp)
    80003f94:	f022                	sd	s0,32(sp)
    80003f96:	ec26                	sd	s1,24(sp)
    80003f98:	e84a                	sd	s2,16(sp)
    80003f9a:	e44e                	sd	s3,8(sp)
    80003f9c:	1800                	addi	s0,sp,48
    80003f9e:	892a                	mv	s2,a0
    80003fa0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fa2:	0001e497          	auipc	s1,0x1e
    80003fa6:	96648493          	addi	s1,s1,-1690 # 80021908 <log>
    80003faa:	00004597          	auipc	a1,0x4
    80003fae:	66e58593          	addi	a1,a1,1646 # 80008618 <syscalls+0x1d8>
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	ffffd097          	auipc	ra,0xffffd
    80003fb8:	c30080e7          	jalr	-976(ra) # 80000be4 <initlock>
  log.start = sb->logstart;
    80003fbc:	0149a583          	lw	a1,20(s3)
    80003fc0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fc2:	0109a783          	lw	a5,16(s3)
    80003fc6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fc8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fcc:	854a                	mv	a0,s2
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	ea6080e7          	jalr	-346(ra) # 80002e74 <bread>
  log.lh.n = lh->n;
    80003fd6:	4d3c                	lw	a5,88(a0)
    80003fd8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fda:	02f05563          	blez	a5,80004004 <initlog+0x74>
    80003fde:	05c50713          	addi	a4,a0,92
    80003fe2:	0001e697          	auipc	a3,0x1e
    80003fe6:	95668693          	addi	a3,a3,-1706 # 80021938 <log+0x30>
    80003fea:	37fd                	addiw	a5,a5,-1
    80003fec:	1782                	slli	a5,a5,0x20
    80003fee:	9381                	srli	a5,a5,0x20
    80003ff0:	078a                	slli	a5,a5,0x2
    80003ff2:	06050613          	addi	a2,a0,96
    80003ff6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003ff8:	4310                	lw	a2,0(a4)
    80003ffa:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003ffc:	0711                	addi	a4,a4,4
    80003ffe:	0691                	addi	a3,a3,4
    80004000:	fef71ce3          	bne	a4,a5,80003ff8 <initlog+0x68>
  brelse(buf);
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	fa0080e7          	jalr	-96(ra) # 80002fa4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	ece080e7          	jalr	-306(ra) # 80003eda <install_trans>
  log.lh.n = 0;
    80004014:	0001e797          	auipc	a5,0x1e
    80004018:	9207a023          	sw	zero,-1760(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	e44080e7          	jalr	-444(ra) # 80003e60 <write_head>
}
    80004024:	70a2                	ld	ra,40(sp)
    80004026:	7402                	ld	s0,32(sp)
    80004028:	64e2                	ld	s1,24(sp)
    8000402a:	6942                	ld	s2,16(sp)
    8000402c:	69a2                	ld	s3,8(sp)
    8000402e:	6145                	addi	sp,sp,48
    80004030:	8082                	ret

0000000080004032 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004032:	1101                	addi	sp,sp,-32
    80004034:	ec06                	sd	ra,24(sp)
    80004036:	e822                	sd	s0,16(sp)
    80004038:	e426                	sd	s1,8(sp)
    8000403a:	e04a                	sd	s2,0(sp)
    8000403c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000403e:	0001e517          	auipc	a0,0x1e
    80004042:	8ca50513          	addi	a0,a0,-1846 # 80021908 <log>
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	c2e080e7          	jalr	-978(ra) # 80000c74 <acquire>
  while(1){
    if(log.committing){
    8000404e:	0001e497          	auipc	s1,0x1e
    80004052:	8ba48493          	addi	s1,s1,-1862 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004056:	4979                	li	s2,30
    80004058:	a039                	j	80004066 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000405a:	85a6                	mv	a1,s1
    8000405c:	8526                	mv	a0,s1
    8000405e:	ffffe097          	auipc	ra,0xffffe
    80004062:	1f0080e7          	jalr	496(ra) # 8000224e <sleep>
    if(log.committing){
    80004066:	50dc                	lw	a5,36(s1)
    80004068:	fbed                	bnez	a5,8000405a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000406a:	509c                	lw	a5,32(s1)
    8000406c:	0017871b          	addiw	a4,a5,1
    80004070:	0007069b          	sext.w	a3,a4
    80004074:	0027179b          	slliw	a5,a4,0x2
    80004078:	9fb9                	addw	a5,a5,a4
    8000407a:	0017979b          	slliw	a5,a5,0x1
    8000407e:	54d8                	lw	a4,44(s1)
    80004080:	9fb9                	addw	a5,a5,a4
    80004082:	00f95963          	bge	s2,a5,80004094 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004086:	85a6                	mv	a1,s1
    80004088:	8526                	mv	a0,s1
    8000408a:	ffffe097          	auipc	ra,0xffffe
    8000408e:	1c4080e7          	jalr	452(ra) # 8000224e <sleep>
    80004092:	bfd1                	j	80004066 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004094:	0001e517          	auipc	a0,0x1e
    80004098:	87450513          	addi	a0,a0,-1932 # 80021908 <log>
    8000409c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	c8a080e7          	jalr	-886(ra) # 80000d28 <release>
      break;
    }
  }
}
    800040a6:	60e2                	ld	ra,24(sp)
    800040a8:	6442                	ld	s0,16(sp)
    800040aa:	64a2                	ld	s1,8(sp)
    800040ac:	6902                	ld	s2,0(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040b2:	7139                	addi	sp,sp,-64
    800040b4:	fc06                	sd	ra,56(sp)
    800040b6:	f822                	sd	s0,48(sp)
    800040b8:	f426                	sd	s1,40(sp)
    800040ba:	f04a                	sd	s2,32(sp)
    800040bc:	ec4e                	sd	s3,24(sp)
    800040be:	e852                	sd	s4,16(sp)
    800040c0:	e456                	sd	s5,8(sp)
    800040c2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040c4:	0001e497          	auipc	s1,0x1e
    800040c8:	84448493          	addi	s1,s1,-1980 # 80021908 <log>
    800040cc:	8526                	mv	a0,s1
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	ba6080e7          	jalr	-1114(ra) # 80000c74 <acquire>
  log.outstanding -= 1;
    800040d6:	509c                	lw	a5,32(s1)
    800040d8:	37fd                	addiw	a5,a5,-1
    800040da:	0007891b          	sext.w	s2,a5
    800040de:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040e0:	50dc                	lw	a5,36(s1)
    800040e2:	efb9                	bnez	a5,80004140 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040e4:	06091663          	bnez	s2,80004150 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040e8:	0001e497          	auipc	s1,0x1e
    800040ec:	82048493          	addi	s1,s1,-2016 # 80021908 <log>
    800040f0:	4785                	li	a5,1
    800040f2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040f4:	8526                	mv	a0,s1
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	c32080e7          	jalr	-974(ra) # 80000d28 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040fe:	54dc                	lw	a5,44(s1)
    80004100:	06f04763          	bgtz	a5,8000416e <end_op+0xbc>
    acquire(&log.lock);
    80004104:	0001e497          	auipc	s1,0x1e
    80004108:	80448493          	addi	s1,s1,-2044 # 80021908 <log>
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	b66080e7          	jalr	-1178(ra) # 80000c74 <acquire>
    log.committing = 0;
    80004116:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000411a:	8526                	mv	a0,s1
    8000411c:	ffffe097          	auipc	ra,0xffffe
    80004120:	2b8080e7          	jalr	696(ra) # 800023d4 <wakeup>
    release(&log.lock);
    80004124:	8526                	mv	a0,s1
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	c02080e7          	jalr	-1022(ra) # 80000d28 <release>
}
    8000412e:	70e2                	ld	ra,56(sp)
    80004130:	7442                	ld	s0,48(sp)
    80004132:	74a2                	ld	s1,40(sp)
    80004134:	7902                	ld	s2,32(sp)
    80004136:	69e2                	ld	s3,24(sp)
    80004138:	6a42                	ld	s4,16(sp)
    8000413a:	6aa2                	ld	s5,8(sp)
    8000413c:	6121                	addi	sp,sp,64
    8000413e:	8082                	ret
    panic("log.committing");
    80004140:	00004517          	auipc	a0,0x4
    80004144:	4e050513          	addi	a0,a0,1248 # 80008620 <syscalls+0x1e0>
    80004148:	ffffc097          	auipc	ra,0xffffc
    8000414c:	48e080e7          	jalr	1166(ra) # 800005d6 <panic>
    wakeup(&log);
    80004150:	0001d497          	auipc	s1,0x1d
    80004154:	7b848493          	addi	s1,s1,1976 # 80021908 <log>
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffe097          	auipc	ra,0xffffe
    8000415e:	27a080e7          	jalr	634(ra) # 800023d4 <wakeup>
  release(&log.lock);
    80004162:	8526                	mv	a0,s1
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	bc4080e7          	jalr	-1084(ra) # 80000d28 <release>
  if(do_commit){
    8000416c:	b7c9                	j	8000412e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416e:	0001da97          	auipc	s5,0x1d
    80004172:	7caa8a93          	addi	s5,s5,1994 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004176:	0001da17          	auipc	s4,0x1d
    8000417a:	792a0a13          	addi	s4,s4,1938 # 80021908 <log>
    8000417e:	018a2583          	lw	a1,24(s4)
    80004182:	012585bb          	addw	a1,a1,s2
    80004186:	2585                	addiw	a1,a1,1
    80004188:	028a2503          	lw	a0,40(s4)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	ce8080e7          	jalr	-792(ra) # 80002e74 <bread>
    80004194:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004196:	000aa583          	lw	a1,0(s5)
    8000419a:	028a2503          	lw	a0,40(s4)
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	cd6080e7          	jalr	-810(ra) # 80002e74 <bread>
    800041a6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041a8:	40000613          	li	a2,1024
    800041ac:	05850593          	addi	a1,a0,88
    800041b0:	05848513          	addi	a0,s1,88
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	c1c080e7          	jalr	-996(ra) # 80000dd0 <memmove>
    bwrite(to);  // write the log
    800041bc:	8526                	mv	a0,s1
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	da8080e7          	jalr	-600(ra) # 80002f66 <bwrite>
    brelse(from);
    800041c6:	854e                	mv	a0,s3
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	ddc080e7          	jalr	-548(ra) # 80002fa4 <brelse>
    brelse(to);
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	dd2080e7          	jalr	-558(ra) # 80002fa4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041da:	2905                	addiw	s2,s2,1
    800041dc:	0a91                	addi	s5,s5,4
    800041de:	02ca2783          	lw	a5,44(s4)
    800041e2:	f8f94ee3          	blt	s2,a5,8000417e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	c7a080e7          	jalr	-902(ra) # 80003e60 <write_head>
    install_trans(); // Now install writes to home locations
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	cec080e7          	jalr	-788(ra) # 80003eda <install_trans>
    log.lh.n = 0;
    800041f6:	0001d797          	auipc	a5,0x1d
    800041fa:	7207af23          	sw	zero,1854(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	c62080e7          	jalr	-926(ra) # 80003e60 <write_head>
    80004206:	bdfd                	j	80004104 <end_op+0x52>

0000000080004208 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004208:	1101                	addi	sp,sp,-32
    8000420a:	ec06                	sd	ra,24(sp)
    8000420c:	e822                	sd	s0,16(sp)
    8000420e:	e426                	sd	s1,8(sp)
    80004210:	e04a                	sd	s2,0(sp)
    80004212:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004214:	0001d717          	auipc	a4,0x1d
    80004218:	72072703          	lw	a4,1824(a4) # 80021934 <log+0x2c>
    8000421c:	47f5                	li	a5,29
    8000421e:	08e7c063          	blt	a5,a4,8000429e <log_write+0x96>
    80004222:	84aa                	mv	s1,a0
    80004224:	0001d797          	auipc	a5,0x1d
    80004228:	7007a783          	lw	a5,1792(a5) # 80021924 <log+0x1c>
    8000422c:	37fd                	addiw	a5,a5,-1
    8000422e:	06f75863          	bge	a4,a5,8000429e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004232:	0001d797          	auipc	a5,0x1d
    80004236:	6f67a783          	lw	a5,1782(a5) # 80021928 <log+0x20>
    8000423a:	06f05a63          	blez	a5,800042ae <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000423e:	0001d917          	auipc	s2,0x1d
    80004242:	6ca90913          	addi	s2,s2,1738 # 80021908 <log>
    80004246:	854a                	mv	a0,s2
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	a2c080e7          	jalr	-1492(ra) # 80000c74 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004250:	02c92603          	lw	a2,44(s2)
    80004254:	06c05563          	blez	a2,800042be <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004258:	44cc                	lw	a1,12(s1)
    8000425a:	0001d717          	auipc	a4,0x1d
    8000425e:	6de70713          	addi	a4,a4,1758 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004262:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004264:	4314                	lw	a3,0(a4)
    80004266:	04b68d63          	beq	a3,a1,800042c0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000426a:	2785                	addiw	a5,a5,1
    8000426c:	0711                	addi	a4,a4,4
    8000426e:	fec79be3          	bne	a5,a2,80004264 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004272:	0621                	addi	a2,a2,8
    80004274:	060a                	slli	a2,a2,0x2
    80004276:	0001d797          	auipc	a5,0x1d
    8000427a:	69278793          	addi	a5,a5,1682 # 80021908 <log>
    8000427e:	963e                	add	a2,a2,a5
    80004280:	44dc                	lw	a5,12(s1)
    80004282:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	dbc080e7          	jalr	-580(ra) # 80003042 <bpin>
    log.lh.n++;
    8000428e:	0001d717          	auipc	a4,0x1d
    80004292:	67a70713          	addi	a4,a4,1658 # 80021908 <log>
    80004296:	575c                	lw	a5,44(a4)
    80004298:	2785                	addiw	a5,a5,1
    8000429a:	d75c                	sw	a5,44(a4)
    8000429c:	a83d                	j	800042da <log_write+0xd2>
    panic("too big a transaction");
    8000429e:	00004517          	auipc	a0,0x4
    800042a2:	39250513          	addi	a0,a0,914 # 80008630 <syscalls+0x1f0>
    800042a6:	ffffc097          	auipc	ra,0xffffc
    800042aa:	330080e7          	jalr	816(ra) # 800005d6 <panic>
    panic("log_write outside of trans");
    800042ae:	00004517          	auipc	a0,0x4
    800042b2:	39a50513          	addi	a0,a0,922 # 80008648 <syscalls+0x208>
    800042b6:	ffffc097          	auipc	ra,0xffffc
    800042ba:	320080e7          	jalr	800(ra) # 800005d6 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800042be:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800042c0:	00878713          	addi	a4,a5,8
    800042c4:	00271693          	slli	a3,a4,0x2
    800042c8:	0001d717          	auipc	a4,0x1d
    800042cc:	64070713          	addi	a4,a4,1600 # 80021908 <log>
    800042d0:	9736                	add	a4,a4,a3
    800042d2:	44d4                	lw	a3,12(s1)
    800042d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042d6:	faf607e3          	beq	a2,a5,80004284 <log_write+0x7c>
  }
  release(&log.lock);
    800042da:	0001d517          	auipc	a0,0x1d
    800042de:	62e50513          	addi	a0,a0,1582 # 80021908 <log>
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	a46080e7          	jalr	-1466(ra) # 80000d28 <release>
}
    800042ea:	60e2                	ld	ra,24(sp)
    800042ec:	6442                	ld	s0,16(sp)
    800042ee:	64a2                	ld	s1,8(sp)
    800042f0:	6902                	ld	s2,0(sp)
    800042f2:	6105                	addi	sp,sp,32
    800042f4:	8082                	ret

00000000800042f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042f6:	1101                	addi	sp,sp,-32
    800042f8:	ec06                	sd	ra,24(sp)
    800042fa:	e822                	sd	s0,16(sp)
    800042fc:	e426                	sd	s1,8(sp)
    800042fe:	e04a                	sd	s2,0(sp)
    80004300:	1000                	addi	s0,sp,32
    80004302:	84aa                	mv	s1,a0
    80004304:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004306:	00004597          	auipc	a1,0x4
    8000430a:	36258593          	addi	a1,a1,866 # 80008668 <syscalls+0x228>
    8000430e:	0521                	addi	a0,a0,8
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	8d4080e7          	jalr	-1836(ra) # 80000be4 <initlock>
  lk->name = name;
    80004318:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000431c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004320:	0204a423          	sw	zero,40(s1)
}
    80004324:	60e2                	ld	ra,24(sp)
    80004326:	6442                	ld	s0,16(sp)
    80004328:	64a2                	ld	s1,8(sp)
    8000432a:	6902                	ld	s2,0(sp)
    8000432c:	6105                	addi	sp,sp,32
    8000432e:	8082                	ret

0000000080004330 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004330:	1101                	addi	sp,sp,-32
    80004332:	ec06                	sd	ra,24(sp)
    80004334:	e822                	sd	s0,16(sp)
    80004336:	e426                	sd	s1,8(sp)
    80004338:	e04a                	sd	s2,0(sp)
    8000433a:	1000                	addi	s0,sp,32
    8000433c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000433e:	00850913          	addi	s2,a0,8
    80004342:	854a                	mv	a0,s2
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	930080e7          	jalr	-1744(ra) # 80000c74 <acquire>
  while (lk->locked) {
    8000434c:	409c                	lw	a5,0(s1)
    8000434e:	cb89                	beqz	a5,80004360 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004350:	85ca                	mv	a1,s2
    80004352:	8526                	mv	a0,s1
    80004354:	ffffe097          	auipc	ra,0xffffe
    80004358:	efa080e7          	jalr	-262(ra) # 8000224e <sleep>
  while (lk->locked) {
    8000435c:	409c                	lw	a5,0(s1)
    8000435e:	fbed                	bnez	a5,80004350 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004360:	4785                	li	a5,1
    80004362:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	6de080e7          	jalr	1758(ra) # 80001a42 <myproc>
    8000436c:	5d1c                	lw	a5,56(a0)
    8000436e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004370:	854a                	mv	a0,s2
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	9b6080e7          	jalr	-1610(ra) # 80000d28 <release>
}
    8000437a:	60e2                	ld	ra,24(sp)
    8000437c:	6442                	ld	s0,16(sp)
    8000437e:	64a2                	ld	s1,8(sp)
    80004380:	6902                	ld	s2,0(sp)
    80004382:	6105                	addi	sp,sp,32
    80004384:	8082                	ret

0000000080004386 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004386:	1101                	addi	sp,sp,-32
    80004388:	ec06                	sd	ra,24(sp)
    8000438a:	e822                	sd	s0,16(sp)
    8000438c:	e426                	sd	s1,8(sp)
    8000438e:	e04a                	sd	s2,0(sp)
    80004390:	1000                	addi	s0,sp,32
    80004392:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004394:	00850913          	addi	s2,a0,8
    80004398:	854a                	mv	a0,s2
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8da080e7          	jalr	-1830(ra) # 80000c74 <acquire>
  lk->locked = 0;
    800043a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043a6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043aa:	8526                	mv	a0,s1
    800043ac:	ffffe097          	auipc	ra,0xffffe
    800043b0:	028080e7          	jalr	40(ra) # 800023d4 <wakeup>
  release(&lk->lk);
    800043b4:	854a                	mv	a0,s2
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	972080e7          	jalr	-1678(ra) # 80000d28 <release>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043ca:	7179                	addi	sp,sp,-48
    800043cc:	f406                	sd	ra,40(sp)
    800043ce:	f022                	sd	s0,32(sp)
    800043d0:	ec26                	sd	s1,24(sp)
    800043d2:	e84a                	sd	s2,16(sp)
    800043d4:	e44e                	sd	s3,8(sp)
    800043d6:	1800                	addi	s0,sp,48
    800043d8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043da:	00850913          	addi	s2,a0,8
    800043de:	854a                	mv	a0,s2
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	894080e7          	jalr	-1900(ra) # 80000c74 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043e8:	409c                	lw	a5,0(s1)
    800043ea:	ef99                	bnez	a5,80004408 <holdingsleep+0x3e>
    800043ec:	4481                	li	s1,0
  release(&lk->lk);
    800043ee:	854a                	mv	a0,s2
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	938080e7          	jalr	-1736(ra) # 80000d28 <release>
  return r;
}
    800043f8:	8526                	mv	a0,s1
    800043fa:	70a2                	ld	ra,40(sp)
    800043fc:	7402                	ld	s0,32(sp)
    800043fe:	64e2                	ld	s1,24(sp)
    80004400:	6942                	ld	s2,16(sp)
    80004402:	69a2                	ld	s3,8(sp)
    80004404:	6145                	addi	sp,sp,48
    80004406:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004408:	0284a983          	lw	s3,40(s1)
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	636080e7          	jalr	1590(ra) # 80001a42 <myproc>
    80004414:	5d04                	lw	s1,56(a0)
    80004416:	413484b3          	sub	s1,s1,s3
    8000441a:	0014b493          	seqz	s1,s1
    8000441e:	bfc1                	j	800043ee <holdingsleep+0x24>

0000000080004420 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004420:	1141                	addi	sp,sp,-16
    80004422:	e406                	sd	ra,8(sp)
    80004424:	e022                	sd	s0,0(sp)
    80004426:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004428:	00004597          	auipc	a1,0x4
    8000442c:	25058593          	addi	a1,a1,592 # 80008678 <syscalls+0x238>
    80004430:	0001d517          	auipc	a0,0x1d
    80004434:	62050513          	addi	a0,a0,1568 # 80021a50 <ftable>
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	7ac080e7          	jalr	1964(ra) # 80000be4 <initlock>
}
    80004440:	60a2                	ld	ra,8(sp)
    80004442:	6402                	ld	s0,0(sp)
    80004444:	0141                	addi	sp,sp,16
    80004446:	8082                	ret

0000000080004448 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004448:	1101                	addi	sp,sp,-32
    8000444a:	ec06                	sd	ra,24(sp)
    8000444c:	e822                	sd	s0,16(sp)
    8000444e:	e426                	sd	s1,8(sp)
    80004450:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004452:	0001d517          	auipc	a0,0x1d
    80004456:	5fe50513          	addi	a0,a0,1534 # 80021a50 <ftable>
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	81a080e7          	jalr	-2022(ra) # 80000c74 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004462:	0001d497          	auipc	s1,0x1d
    80004466:	60648493          	addi	s1,s1,1542 # 80021a68 <ftable+0x18>
    8000446a:	0001e717          	auipc	a4,0x1e
    8000446e:	59e70713          	addi	a4,a4,1438 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004472:	40dc                	lw	a5,4(s1)
    80004474:	cf99                	beqz	a5,80004492 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004476:	02848493          	addi	s1,s1,40
    8000447a:	fee49ce3          	bne	s1,a4,80004472 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000447e:	0001d517          	auipc	a0,0x1d
    80004482:	5d250513          	addi	a0,a0,1490 # 80021a50 <ftable>
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	8a2080e7          	jalr	-1886(ra) # 80000d28 <release>
  return 0;
    8000448e:	4481                	li	s1,0
    80004490:	a819                	j	800044a6 <filealloc+0x5e>
      f->ref = 1;
    80004492:	4785                	li	a5,1
    80004494:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004496:	0001d517          	auipc	a0,0x1d
    8000449a:	5ba50513          	addi	a0,a0,1466 # 80021a50 <ftable>
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	88a080e7          	jalr	-1910(ra) # 80000d28 <release>
}
    800044a6:	8526                	mv	a0,s1
    800044a8:	60e2                	ld	ra,24(sp)
    800044aa:	6442                	ld	s0,16(sp)
    800044ac:	64a2                	ld	s1,8(sp)
    800044ae:	6105                	addi	sp,sp,32
    800044b0:	8082                	ret

00000000800044b2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044b2:	1101                	addi	sp,sp,-32
    800044b4:	ec06                	sd	ra,24(sp)
    800044b6:	e822                	sd	s0,16(sp)
    800044b8:	e426                	sd	s1,8(sp)
    800044ba:	1000                	addi	s0,sp,32
    800044bc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044be:	0001d517          	auipc	a0,0x1d
    800044c2:	59250513          	addi	a0,a0,1426 # 80021a50 <ftable>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	7ae080e7          	jalr	1966(ra) # 80000c74 <acquire>
  if(f->ref < 1)
    800044ce:	40dc                	lw	a5,4(s1)
    800044d0:	02f05263          	blez	a5,800044f4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044d4:	2785                	addiw	a5,a5,1
    800044d6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044d8:	0001d517          	auipc	a0,0x1d
    800044dc:	57850513          	addi	a0,a0,1400 # 80021a50 <ftable>
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	848080e7          	jalr	-1976(ra) # 80000d28 <release>
  return f;
}
    800044e8:	8526                	mv	a0,s1
    800044ea:	60e2                	ld	ra,24(sp)
    800044ec:	6442                	ld	s0,16(sp)
    800044ee:	64a2                	ld	s1,8(sp)
    800044f0:	6105                	addi	sp,sp,32
    800044f2:	8082                	ret
    panic("filedup");
    800044f4:	00004517          	auipc	a0,0x4
    800044f8:	18c50513          	addi	a0,a0,396 # 80008680 <syscalls+0x240>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	0da080e7          	jalr	218(ra) # 800005d6 <panic>

0000000080004504 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004504:	7139                	addi	sp,sp,-64
    80004506:	fc06                	sd	ra,56(sp)
    80004508:	f822                	sd	s0,48(sp)
    8000450a:	f426                	sd	s1,40(sp)
    8000450c:	f04a                	sd	s2,32(sp)
    8000450e:	ec4e                	sd	s3,24(sp)
    80004510:	e852                	sd	s4,16(sp)
    80004512:	e456                	sd	s5,8(sp)
    80004514:	0080                	addi	s0,sp,64
    80004516:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004518:	0001d517          	auipc	a0,0x1d
    8000451c:	53850513          	addi	a0,a0,1336 # 80021a50 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	754080e7          	jalr	1876(ra) # 80000c74 <acquire>
  if(f->ref < 1)
    80004528:	40dc                	lw	a5,4(s1)
    8000452a:	06f05163          	blez	a5,8000458c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000452e:	37fd                	addiw	a5,a5,-1
    80004530:	0007871b          	sext.w	a4,a5
    80004534:	c0dc                	sw	a5,4(s1)
    80004536:	06e04363          	bgtz	a4,8000459c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000453a:	0004a903          	lw	s2,0(s1)
    8000453e:	0094ca83          	lbu	s5,9(s1)
    80004542:	0104ba03          	ld	s4,16(s1)
    80004546:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000454a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000454e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004552:	0001d517          	auipc	a0,0x1d
    80004556:	4fe50513          	addi	a0,a0,1278 # 80021a50 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	7ce080e7          	jalr	1998(ra) # 80000d28 <release>

  if(ff.type == FD_PIPE){
    80004562:	4785                	li	a5,1
    80004564:	04f90d63          	beq	s2,a5,800045be <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004568:	3979                	addiw	s2,s2,-2
    8000456a:	4785                	li	a5,1
    8000456c:	0527e063          	bltu	a5,s2,800045ac <fileclose+0xa8>
    begin_op();
    80004570:	00000097          	auipc	ra,0x0
    80004574:	ac2080e7          	jalr	-1342(ra) # 80004032 <begin_op>
    iput(ff.ip);
    80004578:	854e                	mv	a0,s3
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	2b6080e7          	jalr	694(ra) # 80003830 <iput>
    end_op();
    80004582:	00000097          	auipc	ra,0x0
    80004586:	b30080e7          	jalr	-1232(ra) # 800040b2 <end_op>
    8000458a:	a00d                	j	800045ac <fileclose+0xa8>
    panic("fileclose");
    8000458c:	00004517          	auipc	a0,0x4
    80004590:	0fc50513          	addi	a0,a0,252 # 80008688 <syscalls+0x248>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	042080e7          	jalr	66(ra) # 800005d6 <panic>
    release(&ftable.lock);
    8000459c:	0001d517          	auipc	a0,0x1d
    800045a0:	4b450513          	addi	a0,a0,1204 # 80021a50 <ftable>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	784080e7          	jalr	1924(ra) # 80000d28 <release>
  }
}
    800045ac:	70e2                	ld	ra,56(sp)
    800045ae:	7442                	ld	s0,48(sp)
    800045b0:	74a2                	ld	s1,40(sp)
    800045b2:	7902                	ld	s2,32(sp)
    800045b4:	69e2                	ld	s3,24(sp)
    800045b6:	6a42                	ld	s4,16(sp)
    800045b8:	6aa2                	ld	s5,8(sp)
    800045ba:	6121                	addi	sp,sp,64
    800045bc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045be:	85d6                	mv	a1,s5
    800045c0:	8552                	mv	a0,s4
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	372080e7          	jalr	882(ra) # 80004934 <pipeclose>
    800045ca:	b7cd                	j	800045ac <fileclose+0xa8>

00000000800045cc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045cc:	715d                	addi	sp,sp,-80
    800045ce:	e486                	sd	ra,72(sp)
    800045d0:	e0a2                	sd	s0,64(sp)
    800045d2:	fc26                	sd	s1,56(sp)
    800045d4:	f84a                	sd	s2,48(sp)
    800045d6:	f44e                	sd	s3,40(sp)
    800045d8:	0880                	addi	s0,sp,80
    800045da:	84aa                	mv	s1,a0
    800045dc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045de:	ffffd097          	auipc	ra,0xffffd
    800045e2:	464080e7          	jalr	1124(ra) # 80001a42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045e6:	409c                	lw	a5,0(s1)
    800045e8:	37f9                	addiw	a5,a5,-2
    800045ea:	4705                	li	a4,1
    800045ec:	04f76763          	bltu	a4,a5,8000463a <filestat+0x6e>
    800045f0:	892a                	mv	s2,a0
    ilock(f->ip);
    800045f2:	6c88                	ld	a0,24(s1)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	082080e7          	jalr	130(ra) # 80003676 <ilock>
    stati(f->ip, &st);
    800045fc:	fb840593          	addi	a1,s0,-72
    80004600:	6c88                	ld	a0,24(s1)
    80004602:	fffff097          	auipc	ra,0xfffff
    80004606:	2fe080e7          	jalr	766(ra) # 80003900 <stati>
    iunlock(f->ip);
    8000460a:	6c88                	ld	a0,24(s1)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	12c080e7          	jalr	300(ra) # 80003738 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004614:	46e1                	li	a3,24
    80004616:	fb840613          	addi	a2,s0,-72
    8000461a:	85ce                	mv	a1,s3
    8000461c:	05093503          	ld	a0,80(s2)
    80004620:	ffffd097          	auipc	ra,0xffffd
    80004624:	116080e7          	jalr	278(ra) # 80001736 <copyout>
    80004628:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000462c:	60a6                	ld	ra,72(sp)
    8000462e:	6406                	ld	s0,64(sp)
    80004630:	74e2                	ld	s1,56(sp)
    80004632:	7942                	ld	s2,48(sp)
    80004634:	79a2                	ld	s3,40(sp)
    80004636:	6161                	addi	sp,sp,80
    80004638:	8082                	ret
  return -1;
    8000463a:	557d                	li	a0,-1
    8000463c:	bfc5                	j	8000462c <filestat+0x60>

000000008000463e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000463e:	7179                	addi	sp,sp,-48
    80004640:	f406                	sd	ra,40(sp)
    80004642:	f022                	sd	s0,32(sp)
    80004644:	ec26                	sd	s1,24(sp)
    80004646:	e84a                	sd	s2,16(sp)
    80004648:	e44e                	sd	s3,8(sp)
    8000464a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000464c:	00854783          	lbu	a5,8(a0)
    80004650:	c3d5                	beqz	a5,800046f4 <fileread+0xb6>
    80004652:	84aa                	mv	s1,a0
    80004654:	89ae                	mv	s3,a1
    80004656:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004658:	411c                	lw	a5,0(a0)
    8000465a:	4705                	li	a4,1
    8000465c:	04e78963          	beq	a5,a4,800046ae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004660:	470d                	li	a4,3
    80004662:	04e78d63          	beq	a5,a4,800046bc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004666:	4709                	li	a4,2
    80004668:	06e79e63          	bne	a5,a4,800046e4 <fileread+0xa6>
    ilock(f->ip);
    8000466c:	6d08                	ld	a0,24(a0)
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	008080e7          	jalr	8(ra) # 80003676 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004676:	874a                	mv	a4,s2
    80004678:	5094                	lw	a3,32(s1)
    8000467a:	864e                	mv	a2,s3
    8000467c:	4585                	li	a1,1
    8000467e:	6c88                	ld	a0,24(s1)
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	2aa080e7          	jalr	682(ra) # 8000392a <readi>
    80004688:	892a                	mv	s2,a0
    8000468a:	00a05563          	blez	a0,80004694 <fileread+0x56>
      f->off += r;
    8000468e:	509c                	lw	a5,32(s1)
    80004690:	9fa9                	addw	a5,a5,a0
    80004692:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	0a2080e7          	jalr	162(ra) # 80003738 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000469e:	854a                	mv	a0,s2
    800046a0:	70a2                	ld	ra,40(sp)
    800046a2:	7402                	ld	s0,32(sp)
    800046a4:	64e2                	ld	s1,24(sp)
    800046a6:	6942                	ld	s2,16(sp)
    800046a8:	69a2                	ld	s3,8(sp)
    800046aa:	6145                	addi	sp,sp,48
    800046ac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046ae:	6908                	ld	a0,16(a0)
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	418080e7          	jalr	1048(ra) # 80004ac8 <piperead>
    800046b8:	892a                	mv	s2,a0
    800046ba:	b7d5                	j	8000469e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046bc:	02451783          	lh	a5,36(a0)
    800046c0:	03079693          	slli	a3,a5,0x30
    800046c4:	92c1                	srli	a3,a3,0x30
    800046c6:	4725                	li	a4,9
    800046c8:	02d76863          	bltu	a4,a3,800046f8 <fileread+0xba>
    800046cc:	0792                	slli	a5,a5,0x4
    800046ce:	0001d717          	auipc	a4,0x1d
    800046d2:	2e270713          	addi	a4,a4,738 # 800219b0 <devsw>
    800046d6:	97ba                	add	a5,a5,a4
    800046d8:	639c                	ld	a5,0(a5)
    800046da:	c38d                	beqz	a5,800046fc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046dc:	4505                	li	a0,1
    800046de:	9782                	jalr	a5
    800046e0:	892a                	mv	s2,a0
    800046e2:	bf75                	j	8000469e <fileread+0x60>
    panic("fileread");
    800046e4:	00004517          	auipc	a0,0x4
    800046e8:	fb450513          	addi	a0,a0,-76 # 80008698 <syscalls+0x258>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	eea080e7          	jalr	-278(ra) # 800005d6 <panic>
    return -1;
    800046f4:	597d                	li	s2,-1
    800046f6:	b765                	j	8000469e <fileread+0x60>
      return -1;
    800046f8:	597d                	li	s2,-1
    800046fa:	b755                	j	8000469e <fileread+0x60>
    800046fc:	597d                	li	s2,-1
    800046fe:	b745                	j	8000469e <fileread+0x60>

0000000080004700 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004700:	00954783          	lbu	a5,9(a0)
    80004704:	14078563          	beqz	a5,8000484e <filewrite+0x14e>
{
    80004708:	715d                	addi	sp,sp,-80
    8000470a:	e486                	sd	ra,72(sp)
    8000470c:	e0a2                	sd	s0,64(sp)
    8000470e:	fc26                	sd	s1,56(sp)
    80004710:	f84a                	sd	s2,48(sp)
    80004712:	f44e                	sd	s3,40(sp)
    80004714:	f052                	sd	s4,32(sp)
    80004716:	ec56                	sd	s5,24(sp)
    80004718:	e85a                	sd	s6,16(sp)
    8000471a:	e45e                	sd	s7,8(sp)
    8000471c:	e062                	sd	s8,0(sp)
    8000471e:	0880                	addi	s0,sp,80
    80004720:	892a                	mv	s2,a0
    80004722:	8aae                	mv	s5,a1
    80004724:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004726:	411c                	lw	a5,0(a0)
    80004728:	4705                	li	a4,1
    8000472a:	02e78263          	beq	a5,a4,8000474e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000472e:	470d                	li	a4,3
    80004730:	02e78563          	beq	a5,a4,8000475a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004734:	4709                	li	a4,2
    80004736:	10e79463          	bne	a5,a4,8000483e <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000473a:	0ec05e63          	blez	a2,80004836 <filewrite+0x136>
    int i = 0;
    8000473e:	4981                	li	s3,0
    80004740:	6b05                	lui	s6,0x1
    80004742:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004746:	6b85                	lui	s7,0x1
    80004748:	c00b8b9b          	addiw	s7,s7,-1024
    8000474c:	a851                	j	800047e0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000474e:	6908                	ld	a0,16(a0)
    80004750:	00000097          	auipc	ra,0x0
    80004754:	254080e7          	jalr	596(ra) # 800049a4 <pipewrite>
    80004758:	a85d                	j	8000480e <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000475a:	02451783          	lh	a5,36(a0)
    8000475e:	03079693          	slli	a3,a5,0x30
    80004762:	92c1                	srli	a3,a3,0x30
    80004764:	4725                	li	a4,9
    80004766:	0ed76663          	bltu	a4,a3,80004852 <filewrite+0x152>
    8000476a:	0792                	slli	a5,a5,0x4
    8000476c:	0001d717          	auipc	a4,0x1d
    80004770:	24470713          	addi	a4,a4,580 # 800219b0 <devsw>
    80004774:	97ba                	add	a5,a5,a4
    80004776:	679c                	ld	a5,8(a5)
    80004778:	cff9                	beqz	a5,80004856 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000477a:	4505                	li	a0,1
    8000477c:	9782                	jalr	a5
    8000477e:	a841                	j	8000480e <filewrite+0x10e>
    80004780:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004784:	00000097          	auipc	ra,0x0
    80004788:	8ae080e7          	jalr	-1874(ra) # 80004032 <begin_op>
      ilock(f->ip);
    8000478c:	01893503          	ld	a0,24(s2)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	ee6080e7          	jalr	-282(ra) # 80003676 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004798:	8762                	mv	a4,s8
    8000479a:	02092683          	lw	a3,32(s2)
    8000479e:	01598633          	add	a2,s3,s5
    800047a2:	4585                	li	a1,1
    800047a4:	01893503          	ld	a0,24(s2)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	278080e7          	jalr	632(ra) # 80003a20 <writei>
    800047b0:	84aa                	mv	s1,a0
    800047b2:	02a05f63          	blez	a0,800047f0 <filewrite+0xf0>
        f->off += r;
    800047b6:	02092783          	lw	a5,32(s2)
    800047ba:	9fa9                	addw	a5,a5,a0
    800047bc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047c0:	01893503          	ld	a0,24(s2)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	f74080e7          	jalr	-140(ra) # 80003738 <iunlock>
      end_op();
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	8e6080e7          	jalr	-1818(ra) # 800040b2 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800047d4:	049c1963          	bne	s8,s1,80004826 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800047d8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047dc:	0349d663          	bge	s3,s4,80004808 <filewrite+0x108>
      int n1 = n - i;
    800047e0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047e4:	84be                	mv	s1,a5
    800047e6:	2781                	sext.w	a5,a5
    800047e8:	f8fb5ce3          	bge	s6,a5,80004780 <filewrite+0x80>
    800047ec:	84de                	mv	s1,s7
    800047ee:	bf49                	j	80004780 <filewrite+0x80>
      iunlock(f->ip);
    800047f0:	01893503          	ld	a0,24(s2)
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	f44080e7          	jalr	-188(ra) # 80003738 <iunlock>
      end_op();
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	8b6080e7          	jalr	-1866(ra) # 800040b2 <end_op>
      if(r < 0)
    80004804:	fc04d8e3          	bgez	s1,800047d4 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004808:	8552                	mv	a0,s4
    8000480a:	033a1863          	bne	s4,s3,8000483a <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000480e:	60a6                	ld	ra,72(sp)
    80004810:	6406                	ld	s0,64(sp)
    80004812:	74e2                	ld	s1,56(sp)
    80004814:	7942                	ld	s2,48(sp)
    80004816:	79a2                	ld	s3,40(sp)
    80004818:	7a02                	ld	s4,32(sp)
    8000481a:	6ae2                	ld	s5,24(sp)
    8000481c:	6b42                	ld	s6,16(sp)
    8000481e:	6ba2                	ld	s7,8(sp)
    80004820:	6c02                	ld	s8,0(sp)
    80004822:	6161                	addi	sp,sp,80
    80004824:	8082                	ret
        panic("short filewrite");
    80004826:	00004517          	auipc	a0,0x4
    8000482a:	e8250513          	addi	a0,a0,-382 # 800086a8 <syscalls+0x268>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	da8080e7          	jalr	-600(ra) # 800005d6 <panic>
    int i = 0;
    80004836:	4981                	li	s3,0
    80004838:	bfc1                	j	80004808 <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000483a:	557d                	li	a0,-1
    8000483c:	bfc9                	j	8000480e <filewrite+0x10e>
    panic("filewrite");
    8000483e:	00004517          	auipc	a0,0x4
    80004842:	e7a50513          	addi	a0,a0,-390 # 800086b8 <syscalls+0x278>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	d90080e7          	jalr	-624(ra) # 800005d6 <panic>
    return -1;
    8000484e:	557d                	li	a0,-1
}
    80004850:	8082                	ret
      return -1;
    80004852:	557d                	li	a0,-1
    80004854:	bf6d                	j	8000480e <filewrite+0x10e>
    80004856:	557d                	li	a0,-1
    80004858:	bf5d                	j	8000480e <filewrite+0x10e>

000000008000485a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000485a:	7179                	addi	sp,sp,-48
    8000485c:	f406                	sd	ra,40(sp)
    8000485e:	f022                	sd	s0,32(sp)
    80004860:	ec26                	sd	s1,24(sp)
    80004862:	e84a                	sd	s2,16(sp)
    80004864:	e44e                	sd	s3,8(sp)
    80004866:	e052                	sd	s4,0(sp)
    80004868:	1800                	addi	s0,sp,48
    8000486a:	84aa                	mv	s1,a0
    8000486c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000486e:	0005b023          	sd	zero,0(a1)
    80004872:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	bd2080e7          	jalr	-1070(ra) # 80004448 <filealloc>
    8000487e:	e088                	sd	a0,0(s1)
    80004880:	c551                	beqz	a0,8000490c <pipealloc+0xb2>
    80004882:	00000097          	auipc	ra,0x0
    80004886:	bc6080e7          	jalr	-1082(ra) # 80004448 <filealloc>
    8000488a:	00aa3023          	sd	a0,0(s4)
    8000488e:	c92d                	beqz	a0,80004900 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	2f4080e7          	jalr	756(ra) # 80000b84 <kalloc>
    80004898:	892a                	mv	s2,a0
    8000489a:	c125                	beqz	a0,800048fa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000489c:	4985                	li	s3,1
    8000489e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048a2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048a6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048aa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048ae:	00004597          	auipc	a1,0x4
    800048b2:	e1a58593          	addi	a1,a1,-486 # 800086c8 <syscalls+0x288>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	32e080e7          	jalr	814(ra) # 80000be4 <initlock>
  (*f0)->type = FD_PIPE;
    800048be:	609c                	ld	a5,0(s1)
    800048c0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048c4:	609c                	ld	a5,0(s1)
    800048c6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048ca:	609c                	ld	a5,0(s1)
    800048cc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048d0:	609c                	ld	a5,0(s1)
    800048d2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048d6:	000a3783          	ld	a5,0(s4)
    800048da:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048de:	000a3783          	ld	a5,0(s4)
    800048e2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048e6:	000a3783          	ld	a5,0(s4)
    800048ea:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048ee:	000a3783          	ld	a5,0(s4)
    800048f2:	0127b823          	sd	s2,16(a5)
  return 0;
    800048f6:	4501                	li	a0,0
    800048f8:	a025                	j	80004920 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048fa:	6088                	ld	a0,0(s1)
    800048fc:	e501                	bnez	a0,80004904 <pipealloc+0xaa>
    800048fe:	a039                	j	8000490c <pipealloc+0xb2>
    80004900:	6088                	ld	a0,0(s1)
    80004902:	c51d                	beqz	a0,80004930 <pipealloc+0xd6>
    fileclose(*f0);
    80004904:	00000097          	auipc	ra,0x0
    80004908:	c00080e7          	jalr	-1024(ra) # 80004504 <fileclose>
  if(*f1)
    8000490c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004910:	557d                	li	a0,-1
  if(*f1)
    80004912:	c799                	beqz	a5,80004920 <pipealloc+0xc6>
    fileclose(*f1);
    80004914:	853e                	mv	a0,a5
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	bee080e7          	jalr	-1042(ra) # 80004504 <fileclose>
  return -1;
    8000491e:	557d                	li	a0,-1
}
    80004920:	70a2                	ld	ra,40(sp)
    80004922:	7402                	ld	s0,32(sp)
    80004924:	64e2                	ld	s1,24(sp)
    80004926:	6942                	ld	s2,16(sp)
    80004928:	69a2                	ld	s3,8(sp)
    8000492a:	6a02                	ld	s4,0(sp)
    8000492c:	6145                	addi	sp,sp,48
    8000492e:	8082                	ret
  return -1;
    80004930:	557d                	li	a0,-1
    80004932:	b7fd                	j	80004920 <pipealloc+0xc6>

0000000080004934 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004934:	1101                	addi	sp,sp,-32
    80004936:	ec06                	sd	ra,24(sp)
    80004938:	e822                	sd	s0,16(sp)
    8000493a:	e426                	sd	s1,8(sp)
    8000493c:	e04a                	sd	s2,0(sp)
    8000493e:	1000                	addi	s0,sp,32
    80004940:	84aa                	mv	s1,a0
    80004942:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	330080e7          	jalr	816(ra) # 80000c74 <acquire>
  if(writable){
    8000494c:	02090d63          	beqz	s2,80004986 <pipeclose+0x52>
    pi->writeopen = 0;
    80004950:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004954:	21848513          	addi	a0,s1,536
    80004958:	ffffe097          	auipc	ra,0xffffe
    8000495c:	a7c080e7          	jalr	-1412(ra) # 800023d4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004960:	2204b783          	ld	a5,544(s1)
    80004964:	eb95                	bnez	a5,80004998 <pipeclose+0x64>
    release(&pi->lock);
    80004966:	8526                	mv	a0,s1
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	3c0080e7          	jalr	960(ra) # 80000d28 <release>
    kfree((char*)pi);
    80004970:	8526                	mv	a0,s1
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	116080e7          	jalr	278(ra) # 80000a88 <kfree>
  } else
    release(&pi->lock);
}
    8000497a:	60e2                	ld	ra,24(sp)
    8000497c:	6442                	ld	s0,16(sp)
    8000497e:	64a2                	ld	s1,8(sp)
    80004980:	6902                	ld	s2,0(sp)
    80004982:	6105                	addi	sp,sp,32
    80004984:	8082                	ret
    pi->readopen = 0;
    80004986:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000498a:	21c48513          	addi	a0,s1,540
    8000498e:	ffffe097          	auipc	ra,0xffffe
    80004992:	a46080e7          	jalr	-1466(ra) # 800023d4 <wakeup>
    80004996:	b7e9                	j	80004960 <pipeclose+0x2c>
    release(&pi->lock);
    80004998:	8526                	mv	a0,s1
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	38e080e7          	jalr	910(ra) # 80000d28 <release>
}
    800049a2:	bfe1                	j	8000497a <pipeclose+0x46>

00000000800049a4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049a4:	7119                	addi	sp,sp,-128
    800049a6:	fc86                	sd	ra,120(sp)
    800049a8:	f8a2                	sd	s0,112(sp)
    800049aa:	f4a6                	sd	s1,104(sp)
    800049ac:	f0ca                	sd	s2,96(sp)
    800049ae:	ecce                	sd	s3,88(sp)
    800049b0:	e8d2                	sd	s4,80(sp)
    800049b2:	e4d6                	sd	s5,72(sp)
    800049b4:	e0da                	sd	s6,64(sp)
    800049b6:	fc5e                	sd	s7,56(sp)
    800049b8:	f862                	sd	s8,48(sp)
    800049ba:	f466                	sd	s9,40(sp)
    800049bc:	f06a                	sd	s10,32(sp)
    800049be:	ec6e                	sd	s11,24(sp)
    800049c0:	0100                	addi	s0,sp,128
    800049c2:	84aa                	mv	s1,a0
    800049c4:	8cae                	mv	s9,a1
    800049c6:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800049c8:	ffffd097          	auipc	ra,0xffffd
    800049cc:	07a080e7          	jalr	122(ra) # 80001a42 <myproc>
    800049d0:	892a                	mv	s2,a0

  acquire(&pi->lock);
    800049d2:	8526                	mv	a0,s1
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	2a0080e7          	jalr	672(ra) # 80000c74 <acquire>
  for(i = 0; i < n; i++){
    800049dc:	0d605963          	blez	s6,80004aae <pipewrite+0x10a>
    800049e0:	89a6                	mv	s3,s1
    800049e2:	3b7d                	addiw	s6,s6,-1
    800049e4:	1b02                	slli	s6,s6,0x20
    800049e6:	020b5b13          	srli	s6,s6,0x20
    800049ea:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    800049ec:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f0:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049f4:	5dfd                	li	s11,-1
    800049f6:	000b8d1b          	sext.w	s10,s7
    800049fa:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800049fc:	2184a783          	lw	a5,536(s1)
    80004a00:	21c4a703          	lw	a4,540(s1)
    80004a04:	2007879b          	addiw	a5,a5,512
    80004a08:	02f71b63          	bne	a4,a5,80004a3e <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004a0c:	2204a783          	lw	a5,544(s1)
    80004a10:	cbad                	beqz	a5,80004a82 <pipewrite+0xde>
    80004a12:	03092783          	lw	a5,48(s2)
    80004a16:	e7b5                	bnez	a5,80004a82 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004a18:	8556                	mv	a0,s5
    80004a1a:	ffffe097          	auipc	ra,0xffffe
    80004a1e:	9ba080e7          	jalr	-1606(ra) # 800023d4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a22:	85ce                	mv	a1,s3
    80004a24:	8552                	mv	a0,s4
    80004a26:	ffffe097          	auipc	ra,0xffffe
    80004a2a:	828080e7          	jalr	-2008(ra) # 8000224e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a2e:	2184a783          	lw	a5,536(s1)
    80004a32:	21c4a703          	lw	a4,540(s1)
    80004a36:	2007879b          	addiw	a5,a5,512
    80004a3a:	fcf709e3          	beq	a4,a5,80004a0c <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a3e:	4685                	li	a3,1
    80004a40:	019b8633          	add	a2,s7,s9
    80004a44:	f8f40593          	addi	a1,s0,-113
    80004a48:	05093503          	ld	a0,80(s2)
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	d76080e7          	jalr	-650(ra) # 800017c2 <copyin>
    80004a54:	05b50e63          	beq	a0,s11,80004ab0 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a58:	21c4a783          	lw	a5,540(s1)
    80004a5c:	0017871b          	addiw	a4,a5,1
    80004a60:	20e4ae23          	sw	a4,540(s1)
    80004a64:	1ff7f793          	andi	a5,a5,511
    80004a68:	97a6                	add	a5,a5,s1
    80004a6a:	f8f44703          	lbu	a4,-113(s0)
    80004a6e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a72:	001d0c1b          	addiw	s8,s10,1
    80004a76:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004a7a:	036b8b63          	beq	s7,s6,80004ab0 <pipewrite+0x10c>
    80004a7e:	8bbe                	mv	s7,a5
    80004a80:	bf9d                	j	800049f6 <pipewrite+0x52>
        release(&pi->lock);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	2a4080e7          	jalr	676(ra) # 80000d28 <release>
        return -1;
    80004a8c:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004a8e:	8562                	mv	a0,s8
    80004a90:	70e6                	ld	ra,120(sp)
    80004a92:	7446                	ld	s0,112(sp)
    80004a94:	74a6                	ld	s1,104(sp)
    80004a96:	7906                	ld	s2,96(sp)
    80004a98:	69e6                	ld	s3,88(sp)
    80004a9a:	6a46                	ld	s4,80(sp)
    80004a9c:	6aa6                	ld	s5,72(sp)
    80004a9e:	6b06                	ld	s6,64(sp)
    80004aa0:	7be2                	ld	s7,56(sp)
    80004aa2:	7c42                	ld	s8,48(sp)
    80004aa4:	7ca2                	ld	s9,40(sp)
    80004aa6:	7d02                	ld	s10,32(sp)
    80004aa8:	6de2                	ld	s11,24(sp)
    80004aaa:	6109                	addi	sp,sp,128
    80004aac:	8082                	ret
  for(i = 0; i < n; i++){
    80004aae:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004ab0:	21848513          	addi	a0,s1,536
    80004ab4:	ffffe097          	auipc	ra,0xffffe
    80004ab8:	920080e7          	jalr	-1760(ra) # 800023d4 <wakeup>
  release(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	26a080e7          	jalr	618(ra) # 80000d28 <release>
  return i;
    80004ac6:	b7e1                	j	80004a8e <pipewrite+0xea>

0000000080004ac8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ac8:	715d                	addi	sp,sp,-80
    80004aca:	e486                	sd	ra,72(sp)
    80004acc:	e0a2                	sd	s0,64(sp)
    80004ace:	fc26                	sd	s1,56(sp)
    80004ad0:	f84a                	sd	s2,48(sp)
    80004ad2:	f44e                	sd	s3,40(sp)
    80004ad4:	f052                	sd	s4,32(sp)
    80004ad6:	ec56                	sd	s5,24(sp)
    80004ad8:	e85a                	sd	s6,16(sp)
    80004ada:	0880                	addi	s0,sp,80
    80004adc:	84aa                	mv	s1,a0
    80004ade:	892e                	mv	s2,a1
    80004ae0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ae2:	ffffd097          	auipc	ra,0xffffd
    80004ae6:	f60080e7          	jalr	-160(ra) # 80001a42 <myproc>
    80004aea:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004aec:	8b26                	mv	s6,s1
    80004aee:	8526                	mv	a0,s1
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	184080e7          	jalr	388(ra) # 80000c74 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004af8:	2184a703          	lw	a4,536(s1)
    80004afc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b00:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b04:	02f71463          	bne	a4,a5,80004b2c <piperead+0x64>
    80004b08:	2244a783          	lw	a5,548(s1)
    80004b0c:	c385                	beqz	a5,80004b2c <piperead+0x64>
    if(pr->killed){
    80004b0e:	030a2783          	lw	a5,48(s4)
    80004b12:	ebc1                	bnez	a5,80004ba2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b14:	85da                	mv	a1,s6
    80004b16:	854e                	mv	a0,s3
    80004b18:	ffffd097          	auipc	ra,0xffffd
    80004b1c:	736080e7          	jalr	1846(ra) # 8000224e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b20:	2184a703          	lw	a4,536(s1)
    80004b24:	21c4a783          	lw	a5,540(s1)
    80004b28:	fef700e3          	beq	a4,a5,80004b08 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b2c:	09505263          	blez	s5,80004bb0 <piperead+0xe8>
    80004b30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b32:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b34:	2184a783          	lw	a5,536(s1)
    80004b38:	21c4a703          	lw	a4,540(s1)
    80004b3c:	02f70d63          	beq	a4,a5,80004b76 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b40:	0017871b          	addiw	a4,a5,1
    80004b44:	20e4ac23          	sw	a4,536(s1)
    80004b48:	1ff7f793          	andi	a5,a5,511
    80004b4c:	97a6                	add	a5,a5,s1
    80004b4e:	0187c783          	lbu	a5,24(a5)
    80004b52:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b56:	4685                	li	a3,1
    80004b58:	fbf40613          	addi	a2,s0,-65
    80004b5c:	85ca                	mv	a1,s2
    80004b5e:	050a3503          	ld	a0,80(s4)
    80004b62:	ffffd097          	auipc	ra,0xffffd
    80004b66:	bd4080e7          	jalr	-1068(ra) # 80001736 <copyout>
    80004b6a:	01650663          	beq	a0,s6,80004b76 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6e:	2985                	addiw	s3,s3,1
    80004b70:	0905                	addi	s2,s2,1
    80004b72:	fd3a91e3          	bne	s5,s3,80004b34 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b76:	21c48513          	addi	a0,s1,540
    80004b7a:	ffffe097          	auipc	ra,0xffffe
    80004b7e:	85a080e7          	jalr	-1958(ra) # 800023d4 <wakeup>
  release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	1a4080e7          	jalr	420(ra) # 80000d28 <release>
  return i;
}
    80004b8c:	854e                	mv	a0,s3
    80004b8e:	60a6                	ld	ra,72(sp)
    80004b90:	6406                	ld	s0,64(sp)
    80004b92:	74e2                	ld	s1,56(sp)
    80004b94:	7942                	ld	s2,48(sp)
    80004b96:	79a2                	ld	s3,40(sp)
    80004b98:	7a02                	ld	s4,32(sp)
    80004b9a:	6ae2                	ld	s5,24(sp)
    80004b9c:	6b42                	ld	s6,16(sp)
    80004b9e:	6161                	addi	sp,sp,80
    80004ba0:	8082                	ret
      release(&pi->lock);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	184080e7          	jalr	388(ra) # 80000d28 <release>
      return -1;
    80004bac:	59fd                	li	s3,-1
    80004bae:	bff9                	j	80004b8c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb0:	4981                	li	s3,0
    80004bb2:	b7d1                	j	80004b76 <piperead+0xae>

0000000080004bb4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bb4:	df010113          	addi	sp,sp,-528
    80004bb8:	20113423          	sd	ra,520(sp)
    80004bbc:	20813023          	sd	s0,512(sp)
    80004bc0:	ffa6                	sd	s1,504(sp)
    80004bc2:	fbca                	sd	s2,496(sp)
    80004bc4:	f7ce                	sd	s3,488(sp)
    80004bc6:	f3d2                	sd	s4,480(sp)
    80004bc8:	efd6                	sd	s5,472(sp)
    80004bca:	ebda                	sd	s6,464(sp)
    80004bcc:	e7de                	sd	s7,456(sp)
    80004bce:	e3e2                	sd	s8,448(sp)
    80004bd0:	ff66                	sd	s9,440(sp)
    80004bd2:	fb6a                	sd	s10,432(sp)
    80004bd4:	f76e                	sd	s11,424(sp)
    80004bd6:	0c00                	addi	s0,sp,528
    80004bd8:	84aa                	mv	s1,a0
    80004bda:	dea43c23          	sd	a0,-520(s0)
    80004bde:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	e60080e7          	jalr	-416(ra) # 80001a42 <myproc>
    80004bea:	892a                	mv	s2,a0

  begin_op();
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	446080e7          	jalr	1094(ra) # 80004032 <begin_op>

  if((ip = namei(path)) == 0){
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	fffff097          	auipc	ra,0xfffff
    80004bfa:	230080e7          	jalr	560(ra) # 80003e26 <namei>
    80004bfe:	c92d                	beqz	a0,80004c70 <exec+0xbc>
    80004c00:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c02:	fffff097          	auipc	ra,0xfffff
    80004c06:	a74080e7          	jalr	-1420(ra) # 80003676 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c0a:	04000713          	li	a4,64
    80004c0e:	4681                	li	a3,0
    80004c10:	e4840613          	addi	a2,s0,-440
    80004c14:	4581                	li	a1,0
    80004c16:	8526                	mv	a0,s1
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	d12080e7          	jalr	-750(ra) # 8000392a <readi>
    80004c20:	04000793          	li	a5,64
    80004c24:	00f51a63          	bne	a0,a5,80004c38 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c28:	e4842703          	lw	a4,-440(s0)
    80004c2c:	464c47b7          	lui	a5,0x464c4
    80004c30:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c34:	04f70463          	beq	a4,a5,80004c7c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	c9e080e7          	jalr	-866(ra) # 800038d8 <iunlockput>
    end_op();
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	470080e7          	jalr	1136(ra) # 800040b2 <end_op>
  }
  return -1;
    80004c4a:	557d                	li	a0,-1
}
    80004c4c:	20813083          	ld	ra,520(sp)
    80004c50:	20013403          	ld	s0,512(sp)
    80004c54:	74fe                	ld	s1,504(sp)
    80004c56:	795e                	ld	s2,496(sp)
    80004c58:	79be                	ld	s3,488(sp)
    80004c5a:	7a1e                	ld	s4,480(sp)
    80004c5c:	6afe                	ld	s5,472(sp)
    80004c5e:	6b5e                	ld	s6,464(sp)
    80004c60:	6bbe                	ld	s7,456(sp)
    80004c62:	6c1e                	ld	s8,448(sp)
    80004c64:	7cfa                	ld	s9,440(sp)
    80004c66:	7d5a                	ld	s10,432(sp)
    80004c68:	7dba                	ld	s11,424(sp)
    80004c6a:	21010113          	addi	sp,sp,528
    80004c6e:	8082                	ret
    end_op();
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	442080e7          	jalr	1090(ra) # 800040b2 <end_op>
    return -1;
    80004c78:	557d                	li	a0,-1
    80004c7a:	bfc9                	j	80004c4c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c7c:	854a                	mv	a0,s2
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	e88080e7          	jalr	-376(ra) # 80001b06 <proc_pagetable>
    80004c86:	8baa                	mv	s7,a0
    80004c88:	d945                	beqz	a0,80004c38 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c8a:	e6842983          	lw	s3,-408(s0)
    80004c8e:	e8045783          	lhu	a5,-384(s0)
    80004c92:	c7ad                	beqz	a5,80004cfc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c94:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c96:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004c98:	6c85                	lui	s9,0x1
    80004c9a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c9e:	def43823          	sd	a5,-528(s0)
    80004ca2:	a42d                	j	80004ecc <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ca4:	00004517          	auipc	a0,0x4
    80004ca8:	a2c50513          	addi	a0,a0,-1492 # 800086d0 <syscalls+0x290>
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	92a080e7          	jalr	-1750(ra) # 800005d6 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cb4:	8756                	mv	a4,s5
    80004cb6:	012d86bb          	addw	a3,s11,s2
    80004cba:	4581                	li	a1,0
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	c6c080e7          	jalr	-916(ra) # 8000392a <readi>
    80004cc6:	2501                	sext.w	a0,a0
    80004cc8:	1aaa9963          	bne	s5,a0,80004e7a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ccc:	6785                	lui	a5,0x1
    80004cce:	0127893b          	addw	s2,a5,s2
    80004cd2:	77fd                	lui	a5,0xfffff
    80004cd4:	01478a3b          	addw	s4,a5,s4
    80004cd8:	1f897163          	bgeu	s2,s8,80004eba <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004cdc:	02091593          	slli	a1,s2,0x20
    80004ce0:	9181                	srli	a1,a1,0x20
    80004ce2:	95ea                	add	a1,a1,s10
    80004ce4:	855e                	mv	a0,s7
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	41c080e7          	jalr	1052(ra) # 80001102 <walkaddr>
    80004cee:	862a                	mv	a2,a0
    if(pa == 0)
    80004cf0:	d955                	beqz	a0,80004ca4 <exec+0xf0>
      n = PGSIZE;
    80004cf2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004cf4:	fd9a70e3          	bgeu	s4,s9,80004cb4 <exec+0x100>
      n = sz - i;
    80004cf8:	8ad2                	mv	s5,s4
    80004cfa:	bf6d                	j	80004cb4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cfc:	4901                	li	s2,0
  iunlockput(ip);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	bd8080e7          	jalr	-1064(ra) # 800038d8 <iunlockput>
  end_op();
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	3aa080e7          	jalr	938(ra) # 800040b2 <end_op>
  p = myproc();
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	d32080e7          	jalr	-718(ra) # 80001a42 <myproc>
    80004d18:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d1a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d1e:	6785                	lui	a5,0x1
    80004d20:	17fd                	addi	a5,a5,-1
    80004d22:	993e                	add	s2,s2,a5
    80004d24:	757d                	lui	a0,0xfffff
    80004d26:	00a977b3          	and	a5,s2,a0
    80004d2a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d2e:	6609                	lui	a2,0x2
    80004d30:	963e                	add	a2,a2,a5
    80004d32:	85be                	mv	a1,a5
    80004d34:	855e                	mv	a0,s7
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	7b0080e7          	jalr	1968(ra) # 800014e6 <uvmalloc>
    80004d3e:	8b2a                	mv	s6,a0
  ip = 0;
    80004d40:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d42:	12050c63          	beqz	a0,80004e7a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d46:	75f9                	lui	a1,0xffffe
    80004d48:	95aa                	add	a1,a1,a0
    80004d4a:	855e                	mv	a0,s7
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	9b8080e7          	jalr	-1608(ra) # 80001704 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d54:	7c7d                	lui	s8,0xfffff
    80004d56:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d58:	e0043783          	ld	a5,-512(s0)
    80004d5c:	6388                	ld	a0,0(a5)
    80004d5e:	c535                	beqz	a0,80004dca <exec+0x216>
    80004d60:	e8840993          	addi	s3,s0,-376
    80004d64:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d68:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	18e080e7          	jalr	398(ra) # 80000ef8 <strlen>
    80004d72:	2505                	addiw	a0,a0,1
    80004d74:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d78:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d7c:	13896363          	bltu	s2,s8,80004ea2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d80:	e0043d83          	ld	s11,-512(s0)
    80004d84:	000dba03          	ld	s4,0(s11)
    80004d88:	8552                	mv	a0,s4
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	16e080e7          	jalr	366(ra) # 80000ef8 <strlen>
    80004d92:	0015069b          	addiw	a3,a0,1
    80004d96:	8652                	mv	a2,s4
    80004d98:	85ca                	mv	a1,s2
    80004d9a:	855e                	mv	a0,s7
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	99a080e7          	jalr	-1638(ra) # 80001736 <copyout>
    80004da4:	10054363          	bltz	a0,80004eaa <exec+0x2f6>
    ustack[argc] = sp;
    80004da8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dac:	0485                	addi	s1,s1,1
    80004dae:	008d8793          	addi	a5,s11,8
    80004db2:	e0f43023          	sd	a5,-512(s0)
    80004db6:	008db503          	ld	a0,8(s11)
    80004dba:	c911                	beqz	a0,80004dce <exec+0x21a>
    if(argc >= MAXARG)
    80004dbc:	09a1                	addi	s3,s3,8
    80004dbe:	fb3c96e3          	bne	s9,s3,80004d6a <exec+0x1b6>
  sz = sz1;
    80004dc2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dc6:	4481                	li	s1,0
    80004dc8:	a84d                	j	80004e7a <exec+0x2c6>
  sp = sz;
    80004dca:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dcc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dce:	00349793          	slli	a5,s1,0x3
    80004dd2:	f9040713          	addi	a4,s0,-112
    80004dd6:	97ba                	add	a5,a5,a4
    80004dd8:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ddc:	00148693          	addi	a3,s1,1
    80004de0:	068e                	slli	a3,a3,0x3
    80004de2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004de6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004dea:	01897663          	bgeu	s2,s8,80004df6 <exec+0x242>
  sz = sz1;
    80004dee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004df2:	4481                	li	s1,0
    80004df4:	a059                	j	80004e7a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004df6:	e8840613          	addi	a2,s0,-376
    80004dfa:	85ca                	mv	a1,s2
    80004dfc:	855e                	mv	a0,s7
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	938080e7          	jalr	-1736(ra) # 80001736 <copyout>
    80004e06:	0a054663          	bltz	a0,80004eb2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e0a:	058ab783          	ld	a5,88(s5)
    80004e0e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e12:	df843783          	ld	a5,-520(s0)
    80004e16:	0007c703          	lbu	a4,0(a5)
    80004e1a:	cf11                	beqz	a4,80004e36 <exec+0x282>
    80004e1c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e1e:	02f00693          	li	a3,47
    80004e22:	a029                	j	80004e2c <exec+0x278>
  for(last=s=path; *s; s++)
    80004e24:	0785                	addi	a5,a5,1
    80004e26:	fff7c703          	lbu	a4,-1(a5)
    80004e2a:	c711                	beqz	a4,80004e36 <exec+0x282>
    if(*s == '/')
    80004e2c:	fed71ce3          	bne	a4,a3,80004e24 <exec+0x270>
      last = s+1;
    80004e30:	def43c23          	sd	a5,-520(s0)
    80004e34:	bfc5                	j	80004e24 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e36:	4641                	li	a2,16
    80004e38:	df843583          	ld	a1,-520(s0)
    80004e3c:	158a8513          	addi	a0,s5,344
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	086080e7          	jalr	134(ra) # 80000ec6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e48:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e4c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e50:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e54:	058ab783          	ld	a5,88(s5)
    80004e58:	e6043703          	ld	a4,-416(s0)
    80004e5c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e5e:	058ab783          	ld	a5,88(s5)
    80004e62:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e66:	85ea                	mv	a1,s10
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	d3a080e7          	jalr	-710(ra) # 80001ba2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e70:	0004851b          	sext.w	a0,s1
    80004e74:	bbe1                	j	80004c4c <exec+0x98>
    80004e76:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e7a:	e0843583          	ld	a1,-504(s0)
    80004e7e:	855e                	mv	a0,s7
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	d22080e7          	jalr	-734(ra) # 80001ba2 <proc_freepagetable>
  if(ip){
    80004e88:	da0498e3          	bnez	s1,80004c38 <exec+0x84>
  return -1;
    80004e8c:	557d                	li	a0,-1
    80004e8e:	bb7d                	j	80004c4c <exec+0x98>
    80004e90:	e1243423          	sd	s2,-504(s0)
    80004e94:	b7dd                	j	80004e7a <exec+0x2c6>
    80004e96:	e1243423          	sd	s2,-504(s0)
    80004e9a:	b7c5                	j	80004e7a <exec+0x2c6>
    80004e9c:	e1243423          	sd	s2,-504(s0)
    80004ea0:	bfe9                	j	80004e7a <exec+0x2c6>
  sz = sz1;
    80004ea2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea6:	4481                	li	s1,0
    80004ea8:	bfc9                	j	80004e7a <exec+0x2c6>
  sz = sz1;
    80004eaa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eae:	4481                	li	s1,0
    80004eb0:	b7e9                	j	80004e7a <exec+0x2c6>
  sz = sz1;
    80004eb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eb6:	4481                	li	s1,0
    80004eb8:	b7c9                	j	80004e7a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eba:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ebe:	2b05                	addiw	s6,s6,1
    80004ec0:	0389899b          	addiw	s3,s3,56
    80004ec4:	e8045783          	lhu	a5,-384(s0)
    80004ec8:	e2fb5be3          	bge	s6,a5,80004cfe <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ecc:	2981                	sext.w	s3,s3
    80004ece:	03800713          	li	a4,56
    80004ed2:	86ce                	mv	a3,s3
    80004ed4:	e1040613          	addi	a2,s0,-496
    80004ed8:	4581                	li	a1,0
    80004eda:	8526                	mv	a0,s1
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	a4e080e7          	jalr	-1458(ra) # 8000392a <readi>
    80004ee4:	03800793          	li	a5,56
    80004ee8:	f8f517e3          	bne	a0,a5,80004e76 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004eec:	e1042783          	lw	a5,-496(s0)
    80004ef0:	4705                	li	a4,1
    80004ef2:	fce796e3          	bne	a5,a4,80004ebe <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ef6:	e3843603          	ld	a2,-456(s0)
    80004efa:	e3043783          	ld	a5,-464(s0)
    80004efe:	f8f669e3          	bltu	a2,a5,80004e90 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f02:	e2043783          	ld	a5,-480(s0)
    80004f06:	963e                	add	a2,a2,a5
    80004f08:	f8f667e3          	bltu	a2,a5,80004e96 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f0c:	85ca                	mv	a1,s2
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	5d6080e7          	jalr	1494(ra) # 800014e6 <uvmalloc>
    80004f18:	e0a43423          	sd	a0,-504(s0)
    80004f1c:	d141                	beqz	a0,80004e9c <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004f1e:	e2043d03          	ld	s10,-480(s0)
    80004f22:	df043783          	ld	a5,-528(s0)
    80004f26:	00fd77b3          	and	a5,s10,a5
    80004f2a:	fba1                	bnez	a5,80004e7a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f2c:	e1842d83          	lw	s11,-488(s0)
    80004f30:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f34:	f80c03e3          	beqz	s8,80004eba <exec+0x306>
    80004f38:	8a62                	mv	s4,s8
    80004f3a:	4901                	li	s2,0
    80004f3c:	b345                	j	80004cdc <exec+0x128>

0000000080004f3e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f3e:	7179                	addi	sp,sp,-48
    80004f40:	f406                	sd	ra,40(sp)
    80004f42:	f022                	sd	s0,32(sp)
    80004f44:	ec26                	sd	s1,24(sp)
    80004f46:	e84a                	sd	s2,16(sp)
    80004f48:	1800                	addi	s0,sp,48
    80004f4a:	892e                	mv	s2,a1
    80004f4c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f4e:	fdc40593          	addi	a1,s0,-36
    80004f52:	ffffe097          	auipc	ra,0xffffe
    80004f56:	baa080e7          	jalr	-1110(ra) # 80002afc <argint>
    80004f5a:	04054063          	bltz	a0,80004f9a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f5e:	fdc42703          	lw	a4,-36(s0)
    80004f62:	47bd                	li	a5,15
    80004f64:	02e7ed63          	bltu	a5,a4,80004f9e <argfd+0x60>
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	ada080e7          	jalr	-1318(ra) # 80001a42 <myproc>
    80004f70:	fdc42703          	lw	a4,-36(s0)
    80004f74:	01a70793          	addi	a5,a4,26
    80004f78:	078e                	slli	a5,a5,0x3
    80004f7a:	953e                	add	a0,a0,a5
    80004f7c:	611c                	ld	a5,0(a0)
    80004f7e:	c395                	beqz	a5,80004fa2 <argfd+0x64>
    return -1;
  if(pfd)
    80004f80:	00090463          	beqz	s2,80004f88 <argfd+0x4a>
    *pfd = fd;
    80004f84:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f88:	4501                	li	a0,0
  if(pf)
    80004f8a:	c091                	beqz	s1,80004f8e <argfd+0x50>
    *pf = f;
    80004f8c:	e09c                	sd	a5,0(s1)
}
    80004f8e:	70a2                	ld	ra,40(sp)
    80004f90:	7402                	ld	s0,32(sp)
    80004f92:	64e2                	ld	s1,24(sp)
    80004f94:	6942                	ld	s2,16(sp)
    80004f96:	6145                	addi	sp,sp,48
    80004f98:	8082                	ret
    return -1;
    80004f9a:	557d                	li	a0,-1
    80004f9c:	bfcd                	j	80004f8e <argfd+0x50>
    return -1;
    80004f9e:	557d                	li	a0,-1
    80004fa0:	b7fd                	j	80004f8e <argfd+0x50>
    80004fa2:	557d                	li	a0,-1
    80004fa4:	b7ed                	j	80004f8e <argfd+0x50>

0000000080004fa6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fa6:	1101                	addi	sp,sp,-32
    80004fa8:	ec06                	sd	ra,24(sp)
    80004faa:	e822                	sd	s0,16(sp)
    80004fac:	e426                	sd	s1,8(sp)
    80004fae:	1000                	addi	s0,sp,32
    80004fb0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	a90080e7          	jalr	-1392(ra) # 80001a42 <myproc>
    80004fba:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fbc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004fc0:	4501                	li	a0,0
    80004fc2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fc4:	6398                	ld	a4,0(a5)
    80004fc6:	cb19                	beqz	a4,80004fdc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fc8:	2505                	addiw	a0,a0,1
    80004fca:	07a1                	addi	a5,a5,8
    80004fcc:	fed51ce3          	bne	a0,a3,80004fc4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fd0:	557d                	li	a0,-1
}
    80004fd2:	60e2                	ld	ra,24(sp)
    80004fd4:	6442                	ld	s0,16(sp)
    80004fd6:	64a2                	ld	s1,8(sp)
    80004fd8:	6105                	addi	sp,sp,32
    80004fda:	8082                	ret
      p->ofile[fd] = f;
    80004fdc:	01a50793          	addi	a5,a0,26
    80004fe0:	078e                	slli	a5,a5,0x3
    80004fe2:	963e                	add	a2,a2,a5
    80004fe4:	e204                	sd	s1,0(a2)
      return fd;
    80004fe6:	b7f5                	j	80004fd2 <fdalloc+0x2c>

0000000080004fe8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fe8:	715d                	addi	sp,sp,-80
    80004fea:	e486                	sd	ra,72(sp)
    80004fec:	e0a2                	sd	s0,64(sp)
    80004fee:	fc26                	sd	s1,56(sp)
    80004ff0:	f84a                	sd	s2,48(sp)
    80004ff2:	f44e                	sd	s3,40(sp)
    80004ff4:	f052                	sd	s4,32(sp)
    80004ff6:	ec56                	sd	s5,24(sp)
    80004ff8:	0880                	addi	s0,sp,80
    80004ffa:	89ae                	mv	s3,a1
    80004ffc:	8ab2                	mv	s5,a2
    80004ffe:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005000:	fb040593          	addi	a1,s0,-80
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	e40080e7          	jalr	-448(ra) # 80003e44 <nameiparent>
    8000500c:	892a                	mv	s2,a0
    8000500e:	12050f63          	beqz	a0,8000514c <create+0x164>
    return 0;

  ilock(dp);
    80005012:	ffffe097          	auipc	ra,0xffffe
    80005016:	664080e7          	jalr	1636(ra) # 80003676 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000501a:	4601                	li	a2,0
    8000501c:	fb040593          	addi	a1,s0,-80
    80005020:	854a                	mv	a0,s2
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	b32080e7          	jalr	-1230(ra) # 80003b54 <dirlookup>
    8000502a:	84aa                	mv	s1,a0
    8000502c:	c921                	beqz	a0,8000507c <create+0x94>
    iunlockput(dp);
    8000502e:	854a                	mv	a0,s2
    80005030:	fffff097          	auipc	ra,0xfffff
    80005034:	8a8080e7          	jalr	-1880(ra) # 800038d8 <iunlockput>
    ilock(ip);
    80005038:	8526                	mv	a0,s1
    8000503a:	ffffe097          	auipc	ra,0xffffe
    8000503e:	63c080e7          	jalr	1596(ra) # 80003676 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005042:	2981                	sext.w	s3,s3
    80005044:	4789                	li	a5,2
    80005046:	02f99463          	bne	s3,a5,8000506e <create+0x86>
    8000504a:	0444d783          	lhu	a5,68(s1)
    8000504e:	37f9                	addiw	a5,a5,-2
    80005050:	17c2                	slli	a5,a5,0x30
    80005052:	93c1                	srli	a5,a5,0x30
    80005054:	4705                	li	a4,1
    80005056:	00f76c63          	bltu	a4,a5,8000506e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000505a:	8526                	mv	a0,s1
    8000505c:	60a6                	ld	ra,72(sp)
    8000505e:	6406                	ld	s0,64(sp)
    80005060:	74e2                	ld	s1,56(sp)
    80005062:	7942                	ld	s2,48(sp)
    80005064:	79a2                	ld	s3,40(sp)
    80005066:	7a02                	ld	s4,32(sp)
    80005068:	6ae2                	ld	s5,24(sp)
    8000506a:	6161                	addi	sp,sp,80
    8000506c:	8082                	ret
    iunlockput(ip);
    8000506e:	8526                	mv	a0,s1
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	868080e7          	jalr	-1944(ra) # 800038d8 <iunlockput>
    return 0;
    80005078:	4481                	li	s1,0
    8000507a:	b7c5                	j	8000505a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000507c:	85ce                	mv	a1,s3
    8000507e:	00092503          	lw	a0,0(s2)
    80005082:	ffffe097          	auipc	ra,0xffffe
    80005086:	45c080e7          	jalr	1116(ra) # 800034de <ialloc>
    8000508a:	84aa                	mv	s1,a0
    8000508c:	c529                	beqz	a0,800050d6 <create+0xee>
  ilock(ip);
    8000508e:	ffffe097          	auipc	ra,0xffffe
    80005092:	5e8080e7          	jalr	1512(ra) # 80003676 <ilock>
  ip->major = major;
    80005096:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000509a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000509e:	4785                	li	a5,1
    800050a0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050a4:	8526                	mv	a0,s1
    800050a6:	ffffe097          	auipc	ra,0xffffe
    800050aa:	506080e7          	jalr	1286(ra) # 800035ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050ae:	2981                	sext.w	s3,s3
    800050b0:	4785                	li	a5,1
    800050b2:	02f98a63          	beq	s3,a5,800050e6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050b6:	40d0                	lw	a2,4(s1)
    800050b8:	fb040593          	addi	a1,s0,-80
    800050bc:	854a                	mv	a0,s2
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	ca6080e7          	jalr	-858(ra) # 80003d64 <dirlink>
    800050c6:	06054b63          	bltz	a0,8000513c <create+0x154>
  iunlockput(dp);
    800050ca:	854a                	mv	a0,s2
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	80c080e7          	jalr	-2036(ra) # 800038d8 <iunlockput>
  return ip;
    800050d4:	b759                	j	8000505a <create+0x72>
    panic("create: ialloc");
    800050d6:	00003517          	auipc	a0,0x3
    800050da:	61a50513          	addi	a0,a0,1562 # 800086f0 <syscalls+0x2b0>
    800050de:	ffffb097          	auipc	ra,0xffffb
    800050e2:	4f8080e7          	jalr	1272(ra) # 800005d6 <panic>
    dp->nlink++;  // for ".."
    800050e6:	04a95783          	lhu	a5,74(s2)
    800050ea:	2785                	addiw	a5,a5,1
    800050ec:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800050f0:	854a                	mv	a0,s2
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	4ba080e7          	jalr	1210(ra) # 800035ac <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050fa:	40d0                	lw	a2,4(s1)
    800050fc:	00003597          	auipc	a1,0x3
    80005100:	60458593          	addi	a1,a1,1540 # 80008700 <syscalls+0x2c0>
    80005104:	8526                	mv	a0,s1
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	c5e080e7          	jalr	-930(ra) # 80003d64 <dirlink>
    8000510e:	00054f63          	bltz	a0,8000512c <create+0x144>
    80005112:	00492603          	lw	a2,4(s2)
    80005116:	00003597          	auipc	a1,0x3
    8000511a:	5f258593          	addi	a1,a1,1522 # 80008708 <syscalls+0x2c8>
    8000511e:	8526                	mv	a0,s1
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	c44080e7          	jalr	-956(ra) # 80003d64 <dirlink>
    80005128:	f80557e3          	bgez	a0,800050b6 <create+0xce>
      panic("create dots");
    8000512c:	00003517          	auipc	a0,0x3
    80005130:	5e450513          	addi	a0,a0,1508 # 80008710 <syscalls+0x2d0>
    80005134:	ffffb097          	auipc	ra,0xffffb
    80005138:	4a2080e7          	jalr	1186(ra) # 800005d6 <panic>
    panic("create: dirlink");
    8000513c:	00003517          	auipc	a0,0x3
    80005140:	5e450513          	addi	a0,a0,1508 # 80008720 <syscalls+0x2e0>
    80005144:	ffffb097          	auipc	ra,0xffffb
    80005148:	492080e7          	jalr	1170(ra) # 800005d6 <panic>
    return 0;
    8000514c:	84aa                	mv	s1,a0
    8000514e:	b731                	j	8000505a <create+0x72>

0000000080005150 <sys_dup>:
{
    80005150:	7179                	addi	sp,sp,-48
    80005152:	f406                	sd	ra,40(sp)
    80005154:	f022                	sd	s0,32(sp)
    80005156:	ec26                	sd	s1,24(sp)
    80005158:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000515a:	fd840613          	addi	a2,s0,-40
    8000515e:	4581                	li	a1,0
    80005160:	4501                	li	a0,0
    80005162:	00000097          	auipc	ra,0x0
    80005166:	ddc080e7          	jalr	-548(ra) # 80004f3e <argfd>
    return -1;
    8000516a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000516c:	02054363          	bltz	a0,80005192 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005170:	fd843503          	ld	a0,-40(s0)
    80005174:	00000097          	auipc	ra,0x0
    80005178:	e32080e7          	jalr	-462(ra) # 80004fa6 <fdalloc>
    8000517c:	84aa                	mv	s1,a0
    return -1;
    8000517e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005180:	00054963          	bltz	a0,80005192 <sys_dup+0x42>
  filedup(f);
    80005184:	fd843503          	ld	a0,-40(s0)
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	32a080e7          	jalr	810(ra) # 800044b2 <filedup>
  return fd;
    80005190:	87a6                	mv	a5,s1
}
    80005192:	853e                	mv	a0,a5
    80005194:	70a2                	ld	ra,40(sp)
    80005196:	7402                	ld	s0,32(sp)
    80005198:	64e2                	ld	s1,24(sp)
    8000519a:	6145                	addi	sp,sp,48
    8000519c:	8082                	ret

000000008000519e <sys_read>:
{
    8000519e:	7179                	addi	sp,sp,-48
    800051a0:	f406                	sd	ra,40(sp)
    800051a2:	f022                	sd	s0,32(sp)
    800051a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a6:	fe840613          	addi	a2,s0,-24
    800051aa:	4581                	li	a1,0
    800051ac:	4501                	li	a0,0
    800051ae:	00000097          	auipc	ra,0x0
    800051b2:	d90080e7          	jalr	-624(ra) # 80004f3e <argfd>
    return -1;
    800051b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b8:	04054163          	bltz	a0,800051fa <sys_read+0x5c>
    800051bc:	fe440593          	addi	a1,s0,-28
    800051c0:	4509                	li	a0,2
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	93a080e7          	jalr	-1734(ra) # 80002afc <argint>
    return -1;
    800051ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051cc:	02054763          	bltz	a0,800051fa <sys_read+0x5c>
    800051d0:	fd840593          	addi	a1,s0,-40
    800051d4:	4505                	li	a0,1
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	948080e7          	jalr	-1720(ra) # 80002b1e <argaddr>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	00054d63          	bltz	a0,800051fa <sys_read+0x5c>
  return fileread(f, p, n);
    800051e4:	fe442603          	lw	a2,-28(s0)
    800051e8:	fd843583          	ld	a1,-40(s0)
    800051ec:	fe843503          	ld	a0,-24(s0)
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	44e080e7          	jalr	1102(ra) # 8000463e <fileread>
    800051f8:	87aa                	mv	a5,a0
}
    800051fa:	853e                	mv	a0,a5
    800051fc:	70a2                	ld	ra,40(sp)
    800051fe:	7402                	ld	s0,32(sp)
    80005200:	6145                	addi	sp,sp,48
    80005202:	8082                	ret

0000000080005204 <sys_write>:
{
    80005204:	7179                	addi	sp,sp,-48
    80005206:	f406                	sd	ra,40(sp)
    80005208:	f022                	sd	s0,32(sp)
    8000520a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520c:	fe840613          	addi	a2,s0,-24
    80005210:	4581                	li	a1,0
    80005212:	4501                	li	a0,0
    80005214:	00000097          	auipc	ra,0x0
    80005218:	d2a080e7          	jalr	-726(ra) # 80004f3e <argfd>
    return -1;
    8000521c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521e:	04054163          	bltz	a0,80005260 <sys_write+0x5c>
    80005222:	fe440593          	addi	a1,s0,-28
    80005226:	4509                	li	a0,2
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	8d4080e7          	jalr	-1836(ra) # 80002afc <argint>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005232:	02054763          	bltz	a0,80005260 <sys_write+0x5c>
    80005236:	fd840593          	addi	a1,s0,-40
    8000523a:	4505                	li	a0,1
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	8e2080e7          	jalr	-1822(ra) # 80002b1e <argaddr>
    return -1;
    80005244:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005246:	00054d63          	bltz	a0,80005260 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000524a:	fe442603          	lw	a2,-28(s0)
    8000524e:	fd843583          	ld	a1,-40(s0)
    80005252:	fe843503          	ld	a0,-24(s0)
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	4aa080e7          	jalr	1194(ra) # 80004700 <filewrite>
    8000525e:	87aa                	mv	a5,a0
}
    80005260:	853e                	mv	a0,a5
    80005262:	70a2                	ld	ra,40(sp)
    80005264:	7402                	ld	s0,32(sp)
    80005266:	6145                	addi	sp,sp,48
    80005268:	8082                	ret

000000008000526a <sys_close>:
{
    8000526a:	1101                	addi	sp,sp,-32
    8000526c:	ec06                	sd	ra,24(sp)
    8000526e:	e822                	sd	s0,16(sp)
    80005270:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005272:	fe040613          	addi	a2,s0,-32
    80005276:	fec40593          	addi	a1,s0,-20
    8000527a:	4501                	li	a0,0
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	cc2080e7          	jalr	-830(ra) # 80004f3e <argfd>
    return -1;
    80005284:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005286:	02054463          	bltz	a0,800052ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	7b8080e7          	jalr	1976(ra) # 80001a42 <myproc>
    80005292:	fec42783          	lw	a5,-20(s0)
    80005296:	07e9                	addi	a5,a5,26
    80005298:	078e                	slli	a5,a5,0x3
    8000529a:	97aa                	add	a5,a5,a0
    8000529c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052a0:	fe043503          	ld	a0,-32(s0)
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	260080e7          	jalr	608(ra) # 80004504 <fileclose>
  return 0;
    800052ac:	4781                	li	a5,0
}
    800052ae:	853e                	mv	a0,a5
    800052b0:	60e2                	ld	ra,24(sp)
    800052b2:	6442                	ld	s0,16(sp)
    800052b4:	6105                	addi	sp,sp,32
    800052b6:	8082                	ret

00000000800052b8 <sys_fstat>:
{
    800052b8:	1101                	addi	sp,sp,-32
    800052ba:	ec06                	sd	ra,24(sp)
    800052bc:	e822                	sd	s0,16(sp)
    800052be:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052c0:	fe840613          	addi	a2,s0,-24
    800052c4:	4581                	li	a1,0
    800052c6:	4501                	li	a0,0
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	c76080e7          	jalr	-906(ra) # 80004f3e <argfd>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052d2:	02054563          	bltz	a0,800052fc <sys_fstat+0x44>
    800052d6:	fe040593          	addi	a1,s0,-32
    800052da:	4505                	li	a0,1
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	842080e7          	jalr	-1982(ra) # 80002b1e <argaddr>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052e6:	00054b63          	bltz	a0,800052fc <sys_fstat+0x44>
  return filestat(f, st);
    800052ea:	fe043583          	ld	a1,-32(s0)
    800052ee:	fe843503          	ld	a0,-24(s0)
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	2da080e7          	jalr	730(ra) # 800045cc <filestat>
    800052fa:	87aa                	mv	a5,a0
}
    800052fc:	853e                	mv	a0,a5
    800052fe:	60e2                	ld	ra,24(sp)
    80005300:	6442                	ld	s0,16(sp)
    80005302:	6105                	addi	sp,sp,32
    80005304:	8082                	ret

0000000080005306 <sys_link>:
{
    80005306:	7169                	addi	sp,sp,-304
    80005308:	f606                	sd	ra,296(sp)
    8000530a:	f222                	sd	s0,288(sp)
    8000530c:	ee26                	sd	s1,280(sp)
    8000530e:	ea4a                	sd	s2,272(sp)
    80005310:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005312:	08000613          	li	a2,128
    80005316:	ed040593          	addi	a1,s0,-304
    8000531a:	4501                	li	a0,0
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	824080e7          	jalr	-2012(ra) # 80002b40 <argstr>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005326:	10054e63          	bltz	a0,80005442 <sys_link+0x13c>
    8000532a:	08000613          	li	a2,128
    8000532e:	f5040593          	addi	a1,s0,-176
    80005332:	4505                	li	a0,1
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	80c080e7          	jalr	-2036(ra) # 80002b40 <argstr>
    return -1;
    8000533c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533e:	10054263          	bltz	a0,80005442 <sys_link+0x13c>
  begin_op();
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	cf0080e7          	jalr	-784(ra) # 80004032 <begin_op>
  if((ip = namei(old)) == 0){
    8000534a:	ed040513          	addi	a0,s0,-304
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	ad8080e7          	jalr	-1320(ra) # 80003e26 <namei>
    80005356:	84aa                	mv	s1,a0
    80005358:	c551                	beqz	a0,800053e4 <sys_link+0xde>
  ilock(ip);
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	31c080e7          	jalr	796(ra) # 80003676 <ilock>
  if(ip->type == T_DIR){
    80005362:	04449703          	lh	a4,68(s1)
    80005366:	4785                	li	a5,1
    80005368:	08f70463          	beq	a4,a5,800053f0 <sys_link+0xea>
  ip->nlink++;
    8000536c:	04a4d783          	lhu	a5,74(s1)
    80005370:	2785                	addiw	a5,a5,1
    80005372:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005376:	8526                	mv	a0,s1
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	234080e7          	jalr	564(ra) # 800035ac <iupdate>
  iunlock(ip);
    80005380:	8526                	mv	a0,s1
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	3b6080e7          	jalr	950(ra) # 80003738 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000538a:	fd040593          	addi	a1,s0,-48
    8000538e:	f5040513          	addi	a0,s0,-176
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	ab2080e7          	jalr	-1358(ra) # 80003e44 <nameiparent>
    8000539a:	892a                	mv	s2,a0
    8000539c:	c935                	beqz	a0,80005410 <sys_link+0x10a>
  ilock(dp);
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	2d8080e7          	jalr	728(ra) # 80003676 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053a6:	00092703          	lw	a4,0(s2)
    800053aa:	409c                	lw	a5,0(s1)
    800053ac:	04f71d63          	bne	a4,a5,80005406 <sys_link+0x100>
    800053b0:	40d0                	lw	a2,4(s1)
    800053b2:	fd040593          	addi	a1,s0,-48
    800053b6:	854a                	mv	a0,s2
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	9ac080e7          	jalr	-1620(ra) # 80003d64 <dirlink>
    800053c0:	04054363          	bltz	a0,80005406 <sys_link+0x100>
  iunlockput(dp);
    800053c4:	854a                	mv	a0,s2
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	512080e7          	jalr	1298(ra) # 800038d8 <iunlockput>
  iput(ip);
    800053ce:	8526                	mv	a0,s1
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	460080e7          	jalr	1120(ra) # 80003830 <iput>
  end_op();
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	cda080e7          	jalr	-806(ra) # 800040b2 <end_op>
  return 0;
    800053e0:	4781                	li	a5,0
    800053e2:	a085                	j	80005442 <sys_link+0x13c>
    end_op();
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	cce080e7          	jalr	-818(ra) # 800040b2 <end_op>
    return -1;
    800053ec:	57fd                	li	a5,-1
    800053ee:	a891                	j	80005442 <sys_link+0x13c>
    iunlockput(ip);
    800053f0:	8526                	mv	a0,s1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	4e6080e7          	jalr	1254(ra) # 800038d8 <iunlockput>
    end_op();
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	cb8080e7          	jalr	-840(ra) # 800040b2 <end_op>
    return -1;
    80005402:	57fd                	li	a5,-1
    80005404:	a83d                	j	80005442 <sys_link+0x13c>
    iunlockput(dp);
    80005406:	854a                	mv	a0,s2
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	4d0080e7          	jalr	1232(ra) # 800038d8 <iunlockput>
  ilock(ip);
    80005410:	8526                	mv	a0,s1
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	264080e7          	jalr	612(ra) # 80003676 <ilock>
  ip->nlink--;
    8000541a:	04a4d783          	lhu	a5,74(s1)
    8000541e:	37fd                	addiw	a5,a5,-1
    80005420:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	186080e7          	jalr	390(ra) # 800035ac <iupdate>
  iunlockput(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	4a8080e7          	jalr	1192(ra) # 800038d8 <iunlockput>
  end_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	c7a080e7          	jalr	-902(ra) # 800040b2 <end_op>
  return -1;
    80005440:	57fd                	li	a5,-1
}
    80005442:	853e                	mv	a0,a5
    80005444:	70b2                	ld	ra,296(sp)
    80005446:	7412                	ld	s0,288(sp)
    80005448:	64f2                	ld	s1,280(sp)
    8000544a:	6952                	ld	s2,272(sp)
    8000544c:	6155                	addi	sp,sp,304
    8000544e:	8082                	ret

0000000080005450 <sys_unlink>:
{
    80005450:	7151                	addi	sp,sp,-240
    80005452:	f586                	sd	ra,232(sp)
    80005454:	f1a2                	sd	s0,224(sp)
    80005456:	eda6                	sd	s1,216(sp)
    80005458:	e9ca                	sd	s2,208(sp)
    8000545a:	e5ce                	sd	s3,200(sp)
    8000545c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000545e:	08000613          	li	a2,128
    80005462:	f3040593          	addi	a1,s0,-208
    80005466:	4501                	li	a0,0
    80005468:	ffffd097          	auipc	ra,0xffffd
    8000546c:	6d8080e7          	jalr	1752(ra) # 80002b40 <argstr>
    80005470:	18054163          	bltz	a0,800055f2 <sys_unlink+0x1a2>
  begin_op();
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	bbe080e7          	jalr	-1090(ra) # 80004032 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000547c:	fb040593          	addi	a1,s0,-80
    80005480:	f3040513          	addi	a0,s0,-208
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	9c0080e7          	jalr	-1600(ra) # 80003e44 <nameiparent>
    8000548c:	84aa                	mv	s1,a0
    8000548e:	c979                	beqz	a0,80005564 <sys_unlink+0x114>
  ilock(dp);
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	1e6080e7          	jalr	486(ra) # 80003676 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005498:	00003597          	auipc	a1,0x3
    8000549c:	26858593          	addi	a1,a1,616 # 80008700 <syscalls+0x2c0>
    800054a0:	fb040513          	addi	a0,s0,-80
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	696080e7          	jalr	1686(ra) # 80003b3a <namecmp>
    800054ac:	14050a63          	beqz	a0,80005600 <sys_unlink+0x1b0>
    800054b0:	00003597          	auipc	a1,0x3
    800054b4:	25858593          	addi	a1,a1,600 # 80008708 <syscalls+0x2c8>
    800054b8:	fb040513          	addi	a0,s0,-80
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	67e080e7          	jalr	1662(ra) # 80003b3a <namecmp>
    800054c4:	12050e63          	beqz	a0,80005600 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054c8:	f2c40613          	addi	a2,s0,-212
    800054cc:	fb040593          	addi	a1,s0,-80
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	682080e7          	jalr	1666(ra) # 80003b54 <dirlookup>
    800054da:	892a                	mv	s2,a0
    800054dc:	12050263          	beqz	a0,80005600 <sys_unlink+0x1b0>
  ilock(ip);
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	196080e7          	jalr	406(ra) # 80003676 <ilock>
  if(ip->nlink < 1)
    800054e8:	04a91783          	lh	a5,74(s2)
    800054ec:	08f05263          	blez	a5,80005570 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054f0:	04491703          	lh	a4,68(s2)
    800054f4:	4785                	li	a5,1
    800054f6:	08f70563          	beq	a4,a5,80005580 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054fa:	4641                	li	a2,16
    800054fc:	4581                	li	a1,0
    800054fe:	fc040513          	addi	a0,s0,-64
    80005502:	ffffc097          	auipc	ra,0xffffc
    80005506:	86e080e7          	jalr	-1938(ra) # 80000d70 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000550a:	4741                	li	a4,16
    8000550c:	f2c42683          	lw	a3,-212(s0)
    80005510:	fc040613          	addi	a2,s0,-64
    80005514:	4581                	li	a1,0
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	508080e7          	jalr	1288(ra) # 80003a20 <writei>
    80005520:	47c1                	li	a5,16
    80005522:	0af51563          	bne	a0,a5,800055cc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005526:	04491703          	lh	a4,68(s2)
    8000552a:	4785                	li	a5,1
    8000552c:	0af70863          	beq	a4,a5,800055dc <sys_unlink+0x18c>
  iunlockput(dp);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	3a6080e7          	jalr	934(ra) # 800038d8 <iunlockput>
  ip->nlink--;
    8000553a:	04a95783          	lhu	a5,74(s2)
    8000553e:	37fd                	addiw	a5,a5,-1
    80005540:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005544:	854a                	mv	a0,s2
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	066080e7          	jalr	102(ra) # 800035ac <iupdate>
  iunlockput(ip);
    8000554e:	854a                	mv	a0,s2
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	388080e7          	jalr	904(ra) # 800038d8 <iunlockput>
  end_op();
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	b5a080e7          	jalr	-1190(ra) # 800040b2 <end_op>
  return 0;
    80005560:	4501                	li	a0,0
    80005562:	a84d                	j	80005614 <sys_unlink+0x1c4>
    end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	b4e080e7          	jalr	-1202(ra) # 800040b2 <end_op>
    return -1;
    8000556c:	557d                	li	a0,-1
    8000556e:	a05d                	j	80005614 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005570:	00003517          	auipc	a0,0x3
    80005574:	1c050513          	addi	a0,a0,448 # 80008730 <syscalls+0x2f0>
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	05e080e7          	jalr	94(ra) # 800005d6 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005580:	04c92703          	lw	a4,76(s2)
    80005584:	02000793          	li	a5,32
    80005588:	f6e7f9e3          	bgeu	a5,a4,800054fa <sys_unlink+0xaa>
    8000558c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005590:	4741                	li	a4,16
    80005592:	86ce                	mv	a3,s3
    80005594:	f1840613          	addi	a2,s0,-232
    80005598:	4581                	li	a1,0
    8000559a:	854a                	mv	a0,s2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	38e080e7          	jalr	910(ra) # 8000392a <readi>
    800055a4:	47c1                	li	a5,16
    800055a6:	00f51b63          	bne	a0,a5,800055bc <sys_unlink+0x16c>
    if(de.inum != 0)
    800055aa:	f1845783          	lhu	a5,-232(s0)
    800055ae:	e7a1                	bnez	a5,800055f6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055b0:	29c1                	addiw	s3,s3,16
    800055b2:	04c92783          	lw	a5,76(s2)
    800055b6:	fcf9ede3          	bltu	s3,a5,80005590 <sys_unlink+0x140>
    800055ba:	b781                	j	800054fa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055bc:	00003517          	auipc	a0,0x3
    800055c0:	18c50513          	addi	a0,a0,396 # 80008748 <syscalls+0x308>
    800055c4:	ffffb097          	auipc	ra,0xffffb
    800055c8:	012080e7          	jalr	18(ra) # 800005d6 <panic>
    panic("unlink: writei");
    800055cc:	00003517          	auipc	a0,0x3
    800055d0:	19450513          	addi	a0,a0,404 # 80008760 <syscalls+0x320>
    800055d4:	ffffb097          	auipc	ra,0xffffb
    800055d8:	002080e7          	jalr	2(ra) # 800005d6 <panic>
    dp->nlink--;
    800055dc:	04a4d783          	lhu	a5,74(s1)
    800055e0:	37fd                	addiw	a5,a5,-1
    800055e2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	fc4080e7          	jalr	-60(ra) # 800035ac <iupdate>
    800055f0:	b781                	j	80005530 <sys_unlink+0xe0>
    return -1;
    800055f2:	557d                	li	a0,-1
    800055f4:	a005                	j	80005614 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055f6:	854a                	mv	a0,s2
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	2e0080e7          	jalr	736(ra) # 800038d8 <iunlockput>
  iunlockput(dp);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	2d6080e7          	jalr	726(ra) # 800038d8 <iunlockput>
  end_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	aa8080e7          	jalr	-1368(ra) # 800040b2 <end_op>
  return -1;
    80005612:	557d                	li	a0,-1
}
    80005614:	70ae                	ld	ra,232(sp)
    80005616:	740e                	ld	s0,224(sp)
    80005618:	64ee                	ld	s1,216(sp)
    8000561a:	694e                	ld	s2,208(sp)
    8000561c:	69ae                	ld	s3,200(sp)
    8000561e:	616d                	addi	sp,sp,240
    80005620:	8082                	ret

0000000080005622 <sys_open>:

uint64
sys_open(void)
{
    80005622:	7131                	addi	sp,sp,-192
    80005624:	fd06                	sd	ra,184(sp)
    80005626:	f922                	sd	s0,176(sp)
    80005628:	f526                	sd	s1,168(sp)
    8000562a:	f14a                	sd	s2,160(sp)
    8000562c:	ed4e                	sd	s3,152(sp)
    8000562e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005630:	08000613          	li	a2,128
    80005634:	f5040593          	addi	a1,s0,-176
    80005638:	4501                	li	a0,0
    8000563a:	ffffd097          	auipc	ra,0xffffd
    8000563e:	506080e7          	jalr	1286(ra) # 80002b40 <argstr>
    return -1;
    80005642:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005644:	0c054163          	bltz	a0,80005706 <sys_open+0xe4>
    80005648:	f4c40593          	addi	a1,s0,-180
    8000564c:	4505                	li	a0,1
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	4ae080e7          	jalr	1198(ra) # 80002afc <argint>
    80005656:	0a054863          	bltz	a0,80005706 <sys_open+0xe4>

  begin_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	9d8080e7          	jalr	-1576(ra) # 80004032 <begin_op>

  if(omode & O_CREATE){
    80005662:	f4c42783          	lw	a5,-180(s0)
    80005666:	2007f793          	andi	a5,a5,512
    8000566a:	cbdd                	beqz	a5,80005720 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000566c:	4681                	li	a3,0
    8000566e:	4601                	li	a2,0
    80005670:	4589                	li	a1,2
    80005672:	f5040513          	addi	a0,s0,-176
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	972080e7          	jalr	-1678(ra) # 80004fe8 <create>
    8000567e:	892a                	mv	s2,a0
    if(ip == 0){
    80005680:	c959                	beqz	a0,80005716 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005682:	04491703          	lh	a4,68(s2)
    80005686:	478d                	li	a5,3
    80005688:	00f71763          	bne	a4,a5,80005696 <sys_open+0x74>
    8000568c:	04695703          	lhu	a4,70(s2)
    80005690:	47a5                	li	a5,9
    80005692:	0ce7ec63          	bltu	a5,a4,8000576a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	db2080e7          	jalr	-590(ra) # 80004448 <filealloc>
    8000569e:	89aa                	mv	s3,a0
    800056a0:	10050263          	beqz	a0,800057a4 <sys_open+0x182>
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	902080e7          	jalr	-1790(ra) # 80004fa6 <fdalloc>
    800056ac:	84aa                	mv	s1,a0
    800056ae:	0e054663          	bltz	a0,8000579a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056b2:	04491703          	lh	a4,68(s2)
    800056b6:	478d                	li	a5,3
    800056b8:	0cf70463          	beq	a4,a5,80005780 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056bc:	4789                	li	a5,2
    800056be:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056c2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056c6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056ca:	f4c42783          	lw	a5,-180(s0)
    800056ce:	0017c713          	xori	a4,a5,1
    800056d2:	8b05                	andi	a4,a4,1
    800056d4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056d8:	0037f713          	andi	a4,a5,3
    800056dc:	00e03733          	snez	a4,a4
    800056e0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056e4:	4007f793          	andi	a5,a5,1024
    800056e8:	c791                	beqz	a5,800056f4 <sys_open+0xd2>
    800056ea:	04491703          	lh	a4,68(s2)
    800056ee:	4789                	li	a5,2
    800056f0:	08f70f63          	beq	a4,a5,8000578e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	042080e7          	jalr	66(ra) # 80003738 <iunlock>
  end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	9b4080e7          	jalr	-1612(ra) # 800040b2 <end_op>

  return fd;
}
    80005706:	8526                	mv	a0,s1
    80005708:	70ea                	ld	ra,184(sp)
    8000570a:	744a                	ld	s0,176(sp)
    8000570c:	74aa                	ld	s1,168(sp)
    8000570e:	790a                	ld	s2,160(sp)
    80005710:	69ea                	ld	s3,152(sp)
    80005712:	6129                	addi	sp,sp,192
    80005714:	8082                	ret
      end_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	99c080e7          	jalr	-1636(ra) # 800040b2 <end_op>
      return -1;
    8000571e:	b7e5                	j	80005706 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005720:	f5040513          	addi	a0,s0,-176
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	702080e7          	jalr	1794(ra) # 80003e26 <namei>
    8000572c:	892a                	mv	s2,a0
    8000572e:	c905                	beqz	a0,8000575e <sys_open+0x13c>
    ilock(ip);
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	f46080e7          	jalr	-186(ra) # 80003676 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005738:	04491703          	lh	a4,68(s2)
    8000573c:	4785                	li	a5,1
    8000573e:	f4f712e3          	bne	a4,a5,80005682 <sys_open+0x60>
    80005742:	f4c42783          	lw	a5,-180(s0)
    80005746:	dba1                	beqz	a5,80005696 <sys_open+0x74>
      iunlockput(ip);
    80005748:	854a                	mv	a0,s2
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	18e080e7          	jalr	398(ra) # 800038d8 <iunlockput>
      end_op();
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	960080e7          	jalr	-1696(ra) # 800040b2 <end_op>
      return -1;
    8000575a:	54fd                	li	s1,-1
    8000575c:	b76d                	j	80005706 <sys_open+0xe4>
      end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	954080e7          	jalr	-1708(ra) # 800040b2 <end_op>
      return -1;
    80005766:	54fd                	li	s1,-1
    80005768:	bf79                	j	80005706 <sys_open+0xe4>
    iunlockput(ip);
    8000576a:	854a                	mv	a0,s2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	16c080e7          	jalr	364(ra) # 800038d8 <iunlockput>
    end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	93e080e7          	jalr	-1730(ra) # 800040b2 <end_op>
    return -1;
    8000577c:	54fd                	li	s1,-1
    8000577e:	b761                	j	80005706 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005780:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005784:	04691783          	lh	a5,70(s2)
    80005788:	02f99223          	sh	a5,36(s3)
    8000578c:	bf2d                	j	800056c6 <sys_open+0xa4>
    itrunc(ip);
    8000578e:	854a                	mv	a0,s2
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	ff4080e7          	jalr	-12(ra) # 80003784 <itrunc>
    80005798:	bfb1                	j	800056f4 <sys_open+0xd2>
      fileclose(f);
    8000579a:	854e                	mv	a0,s3
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	d68080e7          	jalr	-664(ra) # 80004504 <fileclose>
    iunlockput(ip);
    800057a4:	854a                	mv	a0,s2
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	132080e7          	jalr	306(ra) # 800038d8 <iunlockput>
    end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	904080e7          	jalr	-1788(ra) # 800040b2 <end_op>
    return -1;
    800057b6:	54fd                	li	s1,-1
    800057b8:	b7b9                	j	80005706 <sys_open+0xe4>

00000000800057ba <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057ba:	7175                	addi	sp,sp,-144
    800057bc:	e506                	sd	ra,136(sp)
    800057be:	e122                	sd	s0,128(sp)
    800057c0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	870080e7          	jalr	-1936(ra) # 80004032 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057ca:	08000613          	li	a2,128
    800057ce:	f7040593          	addi	a1,s0,-144
    800057d2:	4501                	li	a0,0
    800057d4:	ffffd097          	auipc	ra,0xffffd
    800057d8:	36c080e7          	jalr	876(ra) # 80002b40 <argstr>
    800057dc:	02054963          	bltz	a0,8000580e <sys_mkdir+0x54>
    800057e0:	4681                	li	a3,0
    800057e2:	4601                	li	a2,0
    800057e4:	4585                	li	a1,1
    800057e6:	f7040513          	addi	a0,s0,-144
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	7fe080e7          	jalr	2046(ra) # 80004fe8 <create>
    800057f2:	cd11                	beqz	a0,8000580e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	0e4080e7          	jalr	228(ra) # 800038d8 <iunlockput>
  end_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	8b6080e7          	jalr	-1866(ra) # 800040b2 <end_op>
  return 0;
    80005804:	4501                	li	a0,0
}
    80005806:	60aa                	ld	ra,136(sp)
    80005808:	640a                	ld	s0,128(sp)
    8000580a:	6149                	addi	sp,sp,144
    8000580c:	8082                	ret
    end_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	8a4080e7          	jalr	-1884(ra) # 800040b2 <end_op>
    return -1;
    80005816:	557d                	li	a0,-1
    80005818:	b7fd                	j	80005806 <sys_mkdir+0x4c>

000000008000581a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000581a:	7135                	addi	sp,sp,-160
    8000581c:	ed06                	sd	ra,152(sp)
    8000581e:	e922                	sd	s0,144(sp)
    80005820:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	810080e7          	jalr	-2032(ra) # 80004032 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000582a:	08000613          	li	a2,128
    8000582e:	f7040593          	addi	a1,s0,-144
    80005832:	4501                	li	a0,0
    80005834:	ffffd097          	auipc	ra,0xffffd
    80005838:	30c080e7          	jalr	780(ra) # 80002b40 <argstr>
    8000583c:	04054a63          	bltz	a0,80005890 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005840:	f6c40593          	addi	a1,s0,-148
    80005844:	4505                	li	a0,1
    80005846:	ffffd097          	auipc	ra,0xffffd
    8000584a:	2b6080e7          	jalr	694(ra) # 80002afc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000584e:	04054163          	bltz	a0,80005890 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005852:	f6840593          	addi	a1,s0,-152
    80005856:	4509                	li	a0,2
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	2a4080e7          	jalr	676(ra) # 80002afc <argint>
     argint(1, &major) < 0 ||
    80005860:	02054863          	bltz	a0,80005890 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005864:	f6841683          	lh	a3,-152(s0)
    80005868:	f6c41603          	lh	a2,-148(s0)
    8000586c:	458d                	li	a1,3
    8000586e:	f7040513          	addi	a0,s0,-144
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	776080e7          	jalr	1910(ra) # 80004fe8 <create>
     argint(2, &minor) < 0 ||
    8000587a:	c919                	beqz	a0,80005890 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	05c080e7          	jalr	92(ra) # 800038d8 <iunlockput>
  end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	82e080e7          	jalr	-2002(ra) # 800040b2 <end_op>
  return 0;
    8000588c:	4501                	li	a0,0
    8000588e:	a031                	j	8000589a <sys_mknod+0x80>
    end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	822080e7          	jalr	-2014(ra) # 800040b2 <end_op>
    return -1;
    80005898:	557d                	li	a0,-1
}
    8000589a:	60ea                	ld	ra,152(sp)
    8000589c:	644a                	ld	s0,144(sp)
    8000589e:	610d                	addi	sp,sp,160
    800058a0:	8082                	ret

00000000800058a2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058a2:	7135                	addi	sp,sp,-160
    800058a4:	ed06                	sd	ra,152(sp)
    800058a6:	e922                	sd	s0,144(sp)
    800058a8:	e526                	sd	s1,136(sp)
    800058aa:	e14a                	sd	s2,128(sp)
    800058ac:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058ae:	ffffc097          	auipc	ra,0xffffc
    800058b2:	194080e7          	jalr	404(ra) # 80001a42 <myproc>
    800058b6:	892a                	mv	s2,a0
  
  begin_op();
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	77a080e7          	jalr	1914(ra) # 80004032 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058c0:	08000613          	li	a2,128
    800058c4:	f6040593          	addi	a1,s0,-160
    800058c8:	4501                	li	a0,0
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	276080e7          	jalr	630(ra) # 80002b40 <argstr>
    800058d2:	04054b63          	bltz	a0,80005928 <sys_chdir+0x86>
    800058d6:	f6040513          	addi	a0,s0,-160
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	54c080e7          	jalr	1356(ra) # 80003e26 <namei>
    800058e2:	84aa                	mv	s1,a0
    800058e4:	c131                	beqz	a0,80005928 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	d90080e7          	jalr	-624(ra) # 80003676 <ilock>
  if(ip->type != T_DIR){
    800058ee:	04449703          	lh	a4,68(s1)
    800058f2:	4785                	li	a5,1
    800058f4:	04f71063          	bne	a4,a5,80005934 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	e3e080e7          	jalr	-450(ra) # 80003738 <iunlock>
  iput(p->cwd);
    80005902:	15093503          	ld	a0,336(s2)
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	f2a080e7          	jalr	-214(ra) # 80003830 <iput>
  end_op();
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	7a4080e7          	jalr	1956(ra) # 800040b2 <end_op>
  p->cwd = ip;
    80005916:	14993823          	sd	s1,336(s2)
  return 0;
    8000591a:	4501                	li	a0,0
}
    8000591c:	60ea                	ld	ra,152(sp)
    8000591e:	644a                	ld	s0,144(sp)
    80005920:	64aa                	ld	s1,136(sp)
    80005922:	690a                	ld	s2,128(sp)
    80005924:	610d                	addi	sp,sp,160
    80005926:	8082                	ret
    end_op();
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	78a080e7          	jalr	1930(ra) # 800040b2 <end_op>
    return -1;
    80005930:	557d                	li	a0,-1
    80005932:	b7ed                	j	8000591c <sys_chdir+0x7a>
    iunlockput(ip);
    80005934:	8526                	mv	a0,s1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	fa2080e7          	jalr	-94(ra) # 800038d8 <iunlockput>
    end_op();
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	774080e7          	jalr	1908(ra) # 800040b2 <end_op>
    return -1;
    80005946:	557d                	li	a0,-1
    80005948:	bfd1                	j	8000591c <sys_chdir+0x7a>

000000008000594a <sys_exec>:

uint64
sys_exec(void)
{
    8000594a:	7145                	addi	sp,sp,-464
    8000594c:	e786                	sd	ra,456(sp)
    8000594e:	e3a2                	sd	s0,448(sp)
    80005950:	ff26                	sd	s1,440(sp)
    80005952:	fb4a                	sd	s2,432(sp)
    80005954:	f74e                	sd	s3,424(sp)
    80005956:	f352                	sd	s4,416(sp)
    80005958:	ef56                	sd	s5,408(sp)
    8000595a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000595c:	08000613          	li	a2,128
    80005960:	f4040593          	addi	a1,s0,-192
    80005964:	4501                	li	a0,0
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	1da080e7          	jalr	474(ra) # 80002b40 <argstr>
    return -1;
    8000596e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005970:	0c054a63          	bltz	a0,80005a44 <sys_exec+0xfa>
    80005974:	e3840593          	addi	a1,s0,-456
    80005978:	4505                	li	a0,1
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	1a4080e7          	jalr	420(ra) # 80002b1e <argaddr>
    80005982:	0c054163          	bltz	a0,80005a44 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005986:	10000613          	li	a2,256
    8000598a:	4581                	li	a1,0
    8000598c:	e4040513          	addi	a0,s0,-448
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	3e0080e7          	jalr	992(ra) # 80000d70 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005998:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000599c:	89a6                	mv	s3,s1
    8000599e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059a0:	02000a13          	li	s4,32
    800059a4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059a8:	00391513          	slli	a0,s2,0x3
    800059ac:	e3040593          	addi	a1,s0,-464
    800059b0:	e3843783          	ld	a5,-456(s0)
    800059b4:	953e                	add	a0,a0,a5
    800059b6:	ffffd097          	auipc	ra,0xffffd
    800059ba:	0ac080e7          	jalr	172(ra) # 80002a62 <fetchaddr>
    800059be:	02054a63          	bltz	a0,800059f2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059c2:	e3043783          	ld	a5,-464(s0)
    800059c6:	c3b9                	beqz	a5,80005a0c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059c8:	ffffb097          	auipc	ra,0xffffb
    800059cc:	1bc080e7          	jalr	444(ra) # 80000b84 <kalloc>
    800059d0:	85aa                	mv	a1,a0
    800059d2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059d6:	cd11                	beqz	a0,800059f2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059d8:	6605                	lui	a2,0x1
    800059da:	e3043503          	ld	a0,-464(s0)
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	0d6080e7          	jalr	214(ra) # 80002ab4 <fetchstr>
    800059e6:	00054663          	bltz	a0,800059f2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800059ea:	0905                	addi	s2,s2,1
    800059ec:	09a1                	addi	s3,s3,8
    800059ee:	fb491be3          	bne	s2,s4,800059a4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059f2:	10048913          	addi	s2,s1,256
    800059f6:	6088                	ld	a0,0(s1)
    800059f8:	c529                	beqz	a0,80005a42 <sys_exec+0xf8>
    kfree(argv[i]);
    800059fa:	ffffb097          	auipc	ra,0xffffb
    800059fe:	08e080e7          	jalr	142(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a02:	04a1                	addi	s1,s1,8
    80005a04:	ff2499e3          	bne	s1,s2,800059f6 <sys_exec+0xac>
  return -1;
    80005a08:	597d                	li	s2,-1
    80005a0a:	a82d                	j	80005a44 <sys_exec+0xfa>
      argv[i] = 0;
    80005a0c:	0a8e                	slli	s5,s5,0x3
    80005a0e:	fc040793          	addi	a5,s0,-64
    80005a12:	9abe                	add	s5,s5,a5
    80005a14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a18:	e4040593          	addi	a1,s0,-448
    80005a1c:	f4040513          	addi	a0,s0,-192
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	194080e7          	jalr	404(ra) # 80004bb4 <exec>
    80005a28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a2a:	10048993          	addi	s3,s1,256
    80005a2e:	6088                	ld	a0,0(s1)
    80005a30:	c911                	beqz	a0,80005a44 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	056080e7          	jalr	86(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3a:	04a1                	addi	s1,s1,8
    80005a3c:	ff3499e3          	bne	s1,s3,80005a2e <sys_exec+0xe4>
    80005a40:	a011                	j	80005a44 <sys_exec+0xfa>
  return -1;
    80005a42:	597d                	li	s2,-1
}
    80005a44:	854a                	mv	a0,s2
    80005a46:	60be                	ld	ra,456(sp)
    80005a48:	641e                	ld	s0,448(sp)
    80005a4a:	74fa                	ld	s1,440(sp)
    80005a4c:	795a                	ld	s2,432(sp)
    80005a4e:	79ba                	ld	s3,424(sp)
    80005a50:	7a1a                	ld	s4,416(sp)
    80005a52:	6afa                	ld	s5,408(sp)
    80005a54:	6179                	addi	sp,sp,464
    80005a56:	8082                	ret

0000000080005a58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a58:	7139                	addi	sp,sp,-64
    80005a5a:	fc06                	sd	ra,56(sp)
    80005a5c:	f822                	sd	s0,48(sp)
    80005a5e:	f426                	sd	s1,40(sp)
    80005a60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a62:	ffffc097          	auipc	ra,0xffffc
    80005a66:	fe0080e7          	jalr	-32(ra) # 80001a42 <myproc>
    80005a6a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a6c:	fd840593          	addi	a1,s0,-40
    80005a70:	4501                	li	a0,0
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	0ac080e7          	jalr	172(ra) # 80002b1e <argaddr>
    return -1;
    80005a7a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a7c:	0e054063          	bltz	a0,80005b5c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a80:	fc840593          	addi	a1,s0,-56
    80005a84:	fd040513          	addi	a0,s0,-48
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	dd2080e7          	jalr	-558(ra) # 8000485a <pipealloc>
    return -1;
    80005a90:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a92:	0c054563          	bltz	a0,80005b5c <sys_pipe+0x104>
  fd0 = -1;
    80005a96:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a9a:	fd043503          	ld	a0,-48(s0)
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	508080e7          	jalr	1288(ra) # 80004fa6 <fdalloc>
    80005aa6:	fca42223          	sw	a0,-60(s0)
    80005aaa:	08054c63          	bltz	a0,80005b42 <sys_pipe+0xea>
    80005aae:	fc843503          	ld	a0,-56(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	4f4080e7          	jalr	1268(ra) # 80004fa6 <fdalloc>
    80005aba:	fca42023          	sw	a0,-64(s0)
    80005abe:	06054863          	bltz	a0,80005b2e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ac2:	4691                	li	a3,4
    80005ac4:	fc440613          	addi	a2,s0,-60
    80005ac8:	fd843583          	ld	a1,-40(s0)
    80005acc:	68a8                	ld	a0,80(s1)
    80005ace:	ffffc097          	auipc	ra,0xffffc
    80005ad2:	c68080e7          	jalr	-920(ra) # 80001736 <copyout>
    80005ad6:	02054063          	bltz	a0,80005af6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ada:	4691                	li	a3,4
    80005adc:	fc040613          	addi	a2,s0,-64
    80005ae0:	fd843583          	ld	a1,-40(s0)
    80005ae4:	0591                	addi	a1,a1,4
    80005ae6:	68a8                	ld	a0,80(s1)
    80005ae8:	ffffc097          	auipc	ra,0xffffc
    80005aec:	c4e080e7          	jalr	-946(ra) # 80001736 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005af0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005af2:	06055563          	bgez	a0,80005b5c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005af6:	fc442783          	lw	a5,-60(s0)
    80005afa:	07e9                	addi	a5,a5,26
    80005afc:	078e                	slli	a5,a5,0x3
    80005afe:	97a6                	add	a5,a5,s1
    80005b00:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b04:	fc042503          	lw	a0,-64(s0)
    80005b08:	0569                	addi	a0,a0,26
    80005b0a:	050e                	slli	a0,a0,0x3
    80005b0c:	9526                	add	a0,a0,s1
    80005b0e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b12:	fd043503          	ld	a0,-48(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	9ee080e7          	jalr	-1554(ra) # 80004504 <fileclose>
    fileclose(wf);
    80005b1e:	fc843503          	ld	a0,-56(s0)
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	9e2080e7          	jalr	-1566(ra) # 80004504 <fileclose>
    return -1;
    80005b2a:	57fd                	li	a5,-1
    80005b2c:	a805                	j	80005b5c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b2e:	fc442783          	lw	a5,-60(s0)
    80005b32:	0007c863          	bltz	a5,80005b42 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b36:	01a78513          	addi	a0,a5,26
    80005b3a:	050e                	slli	a0,a0,0x3
    80005b3c:	9526                	add	a0,a0,s1
    80005b3e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b42:	fd043503          	ld	a0,-48(s0)
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	9be080e7          	jalr	-1602(ra) # 80004504 <fileclose>
    fileclose(wf);
    80005b4e:	fc843503          	ld	a0,-56(s0)
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	9b2080e7          	jalr	-1614(ra) # 80004504 <fileclose>
    return -1;
    80005b5a:	57fd                	li	a5,-1
}
    80005b5c:	853e                	mv	a0,a5
    80005b5e:	70e2                	ld	ra,56(sp)
    80005b60:	7442                	ld	s0,48(sp)
    80005b62:	74a2                	ld	s1,40(sp)
    80005b64:	6121                	addi	sp,sp,64
    80005b66:	8082                	ret
	...

0000000080005b70 <kernelvec>:
    80005b70:	7111                	addi	sp,sp,-256
    80005b72:	e006                	sd	ra,0(sp)
    80005b74:	e40a                	sd	sp,8(sp)
    80005b76:	e80e                	sd	gp,16(sp)
    80005b78:	ec12                	sd	tp,24(sp)
    80005b7a:	f016                	sd	t0,32(sp)
    80005b7c:	f41a                	sd	t1,40(sp)
    80005b7e:	f81e                	sd	t2,48(sp)
    80005b80:	fc22                	sd	s0,56(sp)
    80005b82:	e0a6                	sd	s1,64(sp)
    80005b84:	e4aa                	sd	a0,72(sp)
    80005b86:	e8ae                	sd	a1,80(sp)
    80005b88:	ecb2                	sd	a2,88(sp)
    80005b8a:	f0b6                	sd	a3,96(sp)
    80005b8c:	f4ba                	sd	a4,104(sp)
    80005b8e:	f8be                	sd	a5,112(sp)
    80005b90:	fcc2                	sd	a6,120(sp)
    80005b92:	e146                	sd	a7,128(sp)
    80005b94:	e54a                	sd	s2,136(sp)
    80005b96:	e94e                	sd	s3,144(sp)
    80005b98:	ed52                	sd	s4,152(sp)
    80005b9a:	f156                	sd	s5,160(sp)
    80005b9c:	f55a                	sd	s6,168(sp)
    80005b9e:	f95e                	sd	s7,176(sp)
    80005ba0:	fd62                	sd	s8,184(sp)
    80005ba2:	e1e6                	sd	s9,192(sp)
    80005ba4:	e5ea                	sd	s10,200(sp)
    80005ba6:	e9ee                	sd	s11,208(sp)
    80005ba8:	edf2                	sd	t3,216(sp)
    80005baa:	f1f6                	sd	t4,224(sp)
    80005bac:	f5fa                	sd	t5,232(sp)
    80005bae:	f9fe                	sd	t6,240(sp)
    80005bb0:	d7ffc0ef          	jal	ra,8000292e <kerneltrap>
    80005bb4:	6082                	ld	ra,0(sp)
    80005bb6:	6122                	ld	sp,8(sp)
    80005bb8:	61c2                	ld	gp,16(sp)
    80005bba:	7282                	ld	t0,32(sp)
    80005bbc:	7322                	ld	t1,40(sp)
    80005bbe:	73c2                	ld	t2,48(sp)
    80005bc0:	7462                	ld	s0,56(sp)
    80005bc2:	6486                	ld	s1,64(sp)
    80005bc4:	6526                	ld	a0,72(sp)
    80005bc6:	65c6                	ld	a1,80(sp)
    80005bc8:	6666                	ld	a2,88(sp)
    80005bca:	7686                	ld	a3,96(sp)
    80005bcc:	7726                	ld	a4,104(sp)
    80005bce:	77c6                	ld	a5,112(sp)
    80005bd0:	7866                	ld	a6,120(sp)
    80005bd2:	688a                	ld	a7,128(sp)
    80005bd4:	692a                	ld	s2,136(sp)
    80005bd6:	69ca                	ld	s3,144(sp)
    80005bd8:	6a6a                	ld	s4,152(sp)
    80005bda:	7a8a                	ld	s5,160(sp)
    80005bdc:	7b2a                	ld	s6,168(sp)
    80005bde:	7bca                	ld	s7,176(sp)
    80005be0:	7c6a                	ld	s8,184(sp)
    80005be2:	6c8e                	ld	s9,192(sp)
    80005be4:	6d2e                	ld	s10,200(sp)
    80005be6:	6dce                	ld	s11,208(sp)
    80005be8:	6e6e                	ld	t3,216(sp)
    80005bea:	7e8e                	ld	t4,224(sp)
    80005bec:	7f2e                	ld	t5,232(sp)
    80005bee:	7fce                	ld	t6,240(sp)
    80005bf0:	6111                	addi	sp,sp,256
    80005bf2:	10200073          	sret
    80005bf6:	00000013          	nop
    80005bfa:	00000013          	nop
    80005bfe:	0001                	nop

0000000080005c00 <timervec>:
    80005c00:	34051573          	csrrw	a0,mscratch,a0
    80005c04:	e10c                	sd	a1,0(a0)
    80005c06:	e510                	sd	a2,8(a0)
    80005c08:	e914                	sd	a3,16(a0)
    80005c0a:	710c                	ld	a1,32(a0)
    80005c0c:	7510                	ld	a2,40(a0)
    80005c0e:	6194                	ld	a3,0(a1)
    80005c10:	96b2                	add	a3,a3,a2
    80005c12:	e194                	sd	a3,0(a1)
    80005c14:	4589                	li	a1,2
    80005c16:	14459073          	csrw	sip,a1
    80005c1a:	6914                	ld	a3,16(a0)
    80005c1c:	6510                	ld	a2,8(a0)
    80005c1e:	610c                	ld	a1,0(a0)
    80005c20:	34051573          	csrrw	a0,mscratch,a0
    80005c24:	30200073          	mret
	...

0000000080005c2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c2a:	1141                	addi	sp,sp,-16
    80005c2c:	e422                	sd	s0,8(sp)
    80005c2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c30:	0c0007b7          	lui	a5,0xc000
    80005c34:	4705                	li	a4,1
    80005c36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c38:	c3d8                	sw	a4,4(a5)
}
    80005c3a:	6422                	ld	s0,8(sp)
    80005c3c:	0141                	addi	sp,sp,16
    80005c3e:	8082                	ret

0000000080005c40 <plicinithart>:

void
plicinithart(void)
{
    80005c40:	1141                	addi	sp,sp,-16
    80005c42:	e406                	sd	ra,8(sp)
    80005c44:	e022                	sd	s0,0(sp)
    80005c46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	dce080e7          	jalr	-562(ra) # 80001a16 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c50:	0085171b          	slliw	a4,a0,0x8
    80005c54:	0c0027b7          	lui	a5,0xc002
    80005c58:	97ba                	add	a5,a5,a4
    80005c5a:	40200713          	li	a4,1026
    80005c5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c62:	00d5151b          	slliw	a0,a0,0xd
    80005c66:	0c2017b7          	lui	a5,0xc201
    80005c6a:	953e                	add	a0,a0,a5
    80005c6c:	00052023          	sw	zero,0(a0)
}
    80005c70:	60a2                	ld	ra,8(sp)
    80005c72:	6402                	ld	s0,0(sp)
    80005c74:	0141                	addi	sp,sp,16
    80005c76:	8082                	ret

0000000080005c78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c78:	1141                	addi	sp,sp,-16
    80005c7a:	e406                	sd	ra,8(sp)
    80005c7c:	e022                	sd	s0,0(sp)
    80005c7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c80:	ffffc097          	auipc	ra,0xffffc
    80005c84:	d96080e7          	jalr	-618(ra) # 80001a16 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c88:	00d5179b          	slliw	a5,a0,0xd
    80005c8c:	0c201537          	lui	a0,0xc201
    80005c90:	953e                	add	a0,a0,a5
  return irq;
}
    80005c92:	4148                	lw	a0,4(a0)
    80005c94:	60a2                	ld	ra,8(sp)
    80005c96:	6402                	ld	s0,0(sp)
    80005c98:	0141                	addi	sp,sp,16
    80005c9a:	8082                	ret

0000000080005c9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c9c:	1101                	addi	sp,sp,-32
    80005c9e:	ec06                	sd	ra,24(sp)
    80005ca0:	e822                	sd	s0,16(sp)
    80005ca2:	e426                	sd	s1,8(sp)
    80005ca4:	1000                	addi	s0,sp,32
    80005ca6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	d6e080e7          	jalr	-658(ra) # 80001a16 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cb0:	00d5151b          	slliw	a0,a0,0xd
    80005cb4:	0c2017b7          	lui	a5,0xc201
    80005cb8:	97aa                	add	a5,a5,a0
    80005cba:	c3c4                	sw	s1,4(a5)
}
    80005cbc:	60e2                	ld	ra,24(sp)
    80005cbe:	6442                	ld	s0,16(sp)
    80005cc0:	64a2                	ld	s1,8(sp)
    80005cc2:	6105                	addi	sp,sp,32
    80005cc4:	8082                	ret

0000000080005cc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cc6:	1141                	addi	sp,sp,-16
    80005cc8:	e406                	sd	ra,8(sp)
    80005cca:	e022                	sd	s0,0(sp)
    80005ccc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cce:	479d                	li	a5,7
    80005cd0:	04a7cc63          	blt	a5,a0,80005d28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005cd4:	0001d797          	auipc	a5,0x1d
    80005cd8:	32c78793          	addi	a5,a5,812 # 80023000 <disk>
    80005cdc:	00a78733          	add	a4,a5,a0
    80005ce0:	6789                	lui	a5,0x2
    80005ce2:	97ba                	add	a5,a5,a4
    80005ce4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ce8:	eba1                	bnez	a5,80005d38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005cea:	00451713          	slli	a4,a0,0x4
    80005cee:	0001f797          	auipc	a5,0x1f
    80005cf2:	3127b783          	ld	a5,786(a5) # 80025000 <disk+0x2000>
    80005cf6:	97ba                	add	a5,a5,a4
    80005cf8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005cfc:	0001d797          	auipc	a5,0x1d
    80005d00:	30478793          	addi	a5,a5,772 # 80023000 <disk>
    80005d04:	97aa                	add	a5,a5,a0
    80005d06:	6509                	lui	a0,0x2
    80005d08:	953e                	add	a0,a0,a5
    80005d0a:	4785                	li	a5,1
    80005d0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d10:	0001f517          	auipc	a0,0x1f
    80005d14:	30850513          	addi	a0,a0,776 # 80025018 <disk+0x2018>
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	6bc080e7          	jalr	1724(ra) # 800023d4 <wakeup>
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d28:	00003517          	auipc	a0,0x3
    80005d2c:	a4850513          	addi	a0,a0,-1464 # 80008770 <syscalls+0x330>
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	8a6080e7          	jalr	-1882(ra) # 800005d6 <panic>
    panic("virtio_disk_intr 2");
    80005d38:	00003517          	auipc	a0,0x3
    80005d3c:	a5050513          	addi	a0,a0,-1456 # 80008788 <syscalls+0x348>
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	896080e7          	jalr	-1898(ra) # 800005d6 <panic>

0000000080005d48 <virtio_disk_init>:
{
    80005d48:	1101                	addi	sp,sp,-32
    80005d4a:	ec06                	sd	ra,24(sp)
    80005d4c:	e822                	sd	s0,16(sp)
    80005d4e:	e426                	sd	s1,8(sp)
    80005d50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d52:	00003597          	auipc	a1,0x3
    80005d56:	a4e58593          	addi	a1,a1,-1458 # 800087a0 <syscalls+0x360>
    80005d5a:	0001f517          	auipc	a0,0x1f
    80005d5e:	34e50513          	addi	a0,a0,846 # 800250a8 <disk+0x20a8>
    80005d62:	ffffb097          	auipc	ra,0xffffb
    80005d66:	e82080e7          	jalr	-382(ra) # 80000be4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d6a:	100017b7          	lui	a5,0x10001
    80005d6e:	4398                	lw	a4,0(a5)
    80005d70:	2701                	sext.w	a4,a4
    80005d72:	747277b7          	lui	a5,0x74727
    80005d76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d7a:	0ef71163          	bne	a4,a5,80005e5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d7e:	100017b7          	lui	a5,0x10001
    80005d82:	43dc                	lw	a5,4(a5)
    80005d84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d86:	4705                	li	a4,1
    80005d88:	0ce79a63          	bne	a5,a4,80005e5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d8c:	100017b7          	lui	a5,0x10001
    80005d90:	479c                	lw	a5,8(a5)
    80005d92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d94:	4709                	li	a4,2
    80005d96:	0ce79363          	bne	a5,a4,80005e5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d9a:	100017b7          	lui	a5,0x10001
    80005d9e:	47d8                	lw	a4,12(a5)
    80005da0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005da2:	554d47b7          	lui	a5,0x554d4
    80005da6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005daa:	0af71963          	bne	a4,a5,80005e5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dae:	100017b7          	lui	a5,0x10001
    80005db2:	4705                	li	a4,1
    80005db4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db6:	470d                	li	a4,3
    80005db8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dbc:	c7ffe737          	lui	a4,0xc7ffe
    80005dc0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dc4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dc6:	2701                	sext.w	a4,a4
    80005dc8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dca:	472d                	li	a4,11
    80005dcc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dce:	473d                	li	a4,15
    80005dd0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dd2:	6705                	lui	a4,0x1
    80005dd4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dd6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dda:	5bdc                	lw	a5,52(a5)
    80005ddc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dde:	c7d9                	beqz	a5,80005e6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005de0:	471d                	li	a4,7
    80005de2:	08f77d63          	bgeu	a4,a5,80005e7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005de6:	100014b7          	lui	s1,0x10001
    80005dea:	47a1                	li	a5,8
    80005dec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005dee:	6609                	lui	a2,0x2
    80005df0:	4581                	li	a1,0
    80005df2:	0001d517          	auipc	a0,0x1d
    80005df6:	20e50513          	addi	a0,a0,526 # 80023000 <disk>
    80005dfa:	ffffb097          	auipc	ra,0xffffb
    80005dfe:	f76080e7          	jalr	-138(ra) # 80000d70 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e02:	0001d717          	auipc	a4,0x1d
    80005e06:	1fe70713          	addi	a4,a4,510 # 80023000 <disk>
    80005e0a:	00c75793          	srli	a5,a4,0xc
    80005e0e:	2781                	sext.w	a5,a5
    80005e10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e12:	0001f797          	auipc	a5,0x1f
    80005e16:	1ee78793          	addi	a5,a5,494 # 80025000 <disk+0x2000>
    80005e1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e1c:	0001d717          	auipc	a4,0x1d
    80005e20:	26470713          	addi	a4,a4,612 # 80023080 <disk+0x80>
    80005e24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e26:	0001e717          	auipc	a4,0x1e
    80005e2a:	1da70713          	addi	a4,a4,474 # 80024000 <disk+0x1000>
    80005e2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e30:	4705                	li	a4,1
    80005e32:	00e78c23          	sb	a4,24(a5)
    80005e36:	00e78ca3          	sb	a4,25(a5)
    80005e3a:	00e78d23          	sb	a4,26(a5)
    80005e3e:	00e78da3          	sb	a4,27(a5)
    80005e42:	00e78e23          	sb	a4,28(a5)
    80005e46:	00e78ea3          	sb	a4,29(a5)
    80005e4a:	00e78f23          	sb	a4,30(a5)
    80005e4e:	00e78fa3          	sb	a4,31(a5)
}
    80005e52:	60e2                	ld	ra,24(sp)
    80005e54:	6442                	ld	s0,16(sp)
    80005e56:	64a2                	ld	s1,8(sp)
    80005e58:	6105                	addi	sp,sp,32
    80005e5a:	8082                	ret
    panic("could not find virtio disk");
    80005e5c:	00003517          	auipc	a0,0x3
    80005e60:	95450513          	addi	a0,a0,-1708 # 800087b0 <syscalls+0x370>
    80005e64:	ffffa097          	auipc	ra,0xffffa
    80005e68:	772080e7          	jalr	1906(ra) # 800005d6 <panic>
    panic("virtio disk has no queue 0");
    80005e6c:	00003517          	auipc	a0,0x3
    80005e70:	96450513          	addi	a0,a0,-1692 # 800087d0 <syscalls+0x390>
    80005e74:	ffffa097          	auipc	ra,0xffffa
    80005e78:	762080e7          	jalr	1890(ra) # 800005d6 <panic>
    panic("virtio disk max queue too short");
    80005e7c:	00003517          	auipc	a0,0x3
    80005e80:	97450513          	addi	a0,a0,-1676 # 800087f0 <syscalls+0x3b0>
    80005e84:	ffffa097          	auipc	ra,0xffffa
    80005e88:	752080e7          	jalr	1874(ra) # 800005d6 <panic>

0000000080005e8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e8c:	7119                	addi	sp,sp,-128
    80005e8e:	fc86                	sd	ra,120(sp)
    80005e90:	f8a2                	sd	s0,112(sp)
    80005e92:	f4a6                	sd	s1,104(sp)
    80005e94:	f0ca                	sd	s2,96(sp)
    80005e96:	ecce                	sd	s3,88(sp)
    80005e98:	e8d2                	sd	s4,80(sp)
    80005e9a:	e4d6                	sd	s5,72(sp)
    80005e9c:	e0da                	sd	s6,64(sp)
    80005e9e:	fc5e                	sd	s7,56(sp)
    80005ea0:	f862                	sd	s8,48(sp)
    80005ea2:	f466                	sd	s9,40(sp)
    80005ea4:	f06a                	sd	s10,32(sp)
    80005ea6:	0100                	addi	s0,sp,128
    80005ea8:	892a                	mv	s2,a0
    80005eaa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005eac:	00c52c83          	lw	s9,12(a0)
    80005eb0:	001c9c9b          	slliw	s9,s9,0x1
    80005eb4:	1c82                	slli	s9,s9,0x20
    80005eb6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005eba:	0001f517          	auipc	a0,0x1f
    80005ebe:	1ee50513          	addi	a0,a0,494 # 800250a8 <disk+0x20a8>
    80005ec2:	ffffb097          	auipc	ra,0xffffb
    80005ec6:	db2080e7          	jalr	-590(ra) # 80000c74 <acquire>
  for(int i = 0; i < 3; i++){
    80005eca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ecc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ece:	0001db97          	auipc	s7,0x1d
    80005ed2:	132b8b93          	addi	s7,s7,306 # 80023000 <disk>
    80005ed6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ed8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005eda:	8a4e                	mv	s4,s3
    80005edc:	a051                	j	80005f60 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ede:	00fb86b3          	add	a3,s7,a5
    80005ee2:	96da                	add	a3,a3,s6
    80005ee4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ee8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005eea:	0207c563          	bltz	a5,80005f14 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005eee:	2485                	addiw	s1,s1,1
    80005ef0:	0711                	addi	a4,a4,4
    80005ef2:	23548d63          	beq	s1,s5,8000612c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005ef6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ef8:	0001f697          	auipc	a3,0x1f
    80005efc:	12068693          	addi	a3,a3,288 # 80025018 <disk+0x2018>
    80005f00:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f02:	0006c583          	lbu	a1,0(a3)
    80005f06:	fde1                	bnez	a1,80005ede <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f08:	2785                	addiw	a5,a5,1
    80005f0a:	0685                	addi	a3,a3,1
    80005f0c:	ff879be3          	bne	a5,s8,80005f02 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f10:	57fd                	li	a5,-1
    80005f12:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f14:	02905a63          	blez	s1,80005f48 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f18:	f9042503          	lw	a0,-112(s0)
    80005f1c:	00000097          	auipc	ra,0x0
    80005f20:	daa080e7          	jalr	-598(ra) # 80005cc6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f24:	4785                	li	a5,1
    80005f26:	0297d163          	bge	a5,s1,80005f48 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f2a:	f9442503          	lw	a0,-108(s0)
    80005f2e:	00000097          	auipc	ra,0x0
    80005f32:	d98080e7          	jalr	-616(ra) # 80005cc6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f36:	4789                	li	a5,2
    80005f38:	0097d863          	bge	a5,s1,80005f48 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f3c:	f9842503          	lw	a0,-104(s0)
    80005f40:	00000097          	auipc	ra,0x0
    80005f44:	d86080e7          	jalr	-634(ra) # 80005cc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f48:	0001f597          	auipc	a1,0x1f
    80005f4c:	16058593          	addi	a1,a1,352 # 800250a8 <disk+0x20a8>
    80005f50:	0001f517          	auipc	a0,0x1f
    80005f54:	0c850513          	addi	a0,a0,200 # 80025018 <disk+0x2018>
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	2f6080e7          	jalr	758(ra) # 8000224e <sleep>
  for(int i = 0; i < 3; i++){
    80005f60:	f9040713          	addi	a4,s0,-112
    80005f64:	84ce                	mv	s1,s3
    80005f66:	bf41                	j	80005ef6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80005f68:	4785                	li	a5,1
    80005f6a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    80005f6e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80005f72:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005f76:	f9042983          	lw	s3,-112(s0)
    80005f7a:	00499493          	slli	s1,s3,0x4
    80005f7e:	0001fa17          	auipc	s4,0x1f
    80005f82:	082a0a13          	addi	s4,s4,130 # 80025000 <disk+0x2000>
    80005f86:	000a3a83          	ld	s5,0(s4)
    80005f8a:	9aa6                	add	s5,s5,s1
    80005f8c:	f8040513          	addi	a0,s0,-128
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	1b4080e7          	jalr	436(ra) # 80001144 <kvmpa>
    80005f98:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80005f9c:	000a3783          	ld	a5,0(s4)
    80005fa0:	97a6                	add	a5,a5,s1
    80005fa2:	4741                	li	a4,16
    80005fa4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fa6:	000a3783          	ld	a5,0(s4)
    80005faa:	97a6                	add	a5,a5,s1
    80005fac:	4705                	li	a4,1
    80005fae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80005fb2:	f9442703          	lw	a4,-108(s0)
    80005fb6:	000a3783          	ld	a5,0(s4)
    80005fba:	97a6                	add	a5,a5,s1
    80005fbc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005fc0:	0712                	slli	a4,a4,0x4
    80005fc2:	000a3783          	ld	a5,0(s4)
    80005fc6:	97ba                	add	a5,a5,a4
    80005fc8:	05890693          	addi	a3,s2,88
    80005fcc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    80005fce:	000a3783          	ld	a5,0(s4)
    80005fd2:	97ba                	add	a5,a5,a4
    80005fd4:	40000693          	li	a3,1024
    80005fd8:	c794                	sw	a3,8(a5)
  if(write)
    80005fda:	100d0a63          	beqz	s10,800060ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fde:	0001f797          	auipc	a5,0x1f
    80005fe2:	0227b783          	ld	a5,34(a5) # 80025000 <disk+0x2000>
    80005fe6:	97ba                	add	a5,a5,a4
    80005fe8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fec:	0001d517          	auipc	a0,0x1d
    80005ff0:	01450513          	addi	a0,a0,20 # 80023000 <disk>
    80005ff4:	0001f797          	auipc	a5,0x1f
    80005ff8:	00c78793          	addi	a5,a5,12 # 80025000 <disk+0x2000>
    80005ffc:	6394                	ld	a3,0(a5)
    80005ffe:	96ba                	add	a3,a3,a4
    80006000:	00c6d603          	lhu	a2,12(a3)
    80006004:	00166613          	ori	a2,a2,1
    80006008:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000600c:	f9842683          	lw	a3,-104(s0)
    80006010:	6390                	ld	a2,0(a5)
    80006012:	9732                	add	a4,a4,a2
    80006014:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006018:	20098613          	addi	a2,s3,512
    8000601c:	0612                	slli	a2,a2,0x4
    8000601e:	962a                	add	a2,a2,a0
    80006020:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006024:	00469713          	slli	a4,a3,0x4
    80006028:	6394                	ld	a3,0(a5)
    8000602a:	96ba                	add	a3,a3,a4
    8000602c:	6589                	lui	a1,0x2
    8000602e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006032:	94ae                	add	s1,s1,a1
    80006034:	94aa                	add	s1,s1,a0
    80006036:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006038:	6394                	ld	a3,0(a5)
    8000603a:	96ba                	add	a3,a3,a4
    8000603c:	4585                	li	a1,1
    8000603e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006040:	6394                	ld	a3,0(a5)
    80006042:	96ba                	add	a3,a3,a4
    80006044:	4509                	li	a0,2
    80006046:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000604a:	6394                	ld	a3,0(a5)
    8000604c:	9736                	add	a4,a4,a3
    8000604e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006052:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006056:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000605a:	6794                	ld	a3,8(a5)
    8000605c:	0026d703          	lhu	a4,2(a3)
    80006060:	8b1d                	andi	a4,a4,7
    80006062:	2709                	addiw	a4,a4,2
    80006064:	0706                	slli	a4,a4,0x1
    80006066:	9736                	add	a4,a4,a3
    80006068:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000606c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006070:	6798                	ld	a4,8(a5)
    80006072:	00275783          	lhu	a5,2(a4)
    80006076:	2785                	addiw	a5,a5,1
    80006078:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000607c:	100017b7          	lui	a5,0x10001
    80006080:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006084:	00492703          	lw	a4,4(s2)
    80006088:	4785                	li	a5,1
    8000608a:	02f71163          	bne	a4,a5,800060ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000608e:	0001f997          	auipc	s3,0x1f
    80006092:	01a98993          	addi	s3,s3,26 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006096:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006098:	85ce                	mv	a1,s3
    8000609a:	854a                	mv	a0,s2
    8000609c:	ffffc097          	auipc	ra,0xffffc
    800060a0:	1b2080e7          	jalr	434(ra) # 8000224e <sleep>
  while(b->disk == 1) {
    800060a4:	00492783          	lw	a5,4(s2)
    800060a8:	fe9788e3          	beq	a5,s1,80006098 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800060ac:	f9042483          	lw	s1,-112(s0)
    800060b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800060b4:	00479713          	slli	a4,a5,0x4
    800060b8:	0001d797          	auipc	a5,0x1d
    800060bc:	f4878793          	addi	a5,a5,-184 # 80023000 <disk>
    800060c0:	97ba                	add	a5,a5,a4
    800060c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060c6:	0001f917          	auipc	s2,0x1f
    800060ca:	f3a90913          	addi	s2,s2,-198 # 80025000 <disk+0x2000>
    free_desc(i);
    800060ce:	8526                	mv	a0,s1
    800060d0:	00000097          	auipc	ra,0x0
    800060d4:	bf6080e7          	jalr	-1034(ra) # 80005cc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060d8:	0492                	slli	s1,s1,0x4
    800060da:	00093783          	ld	a5,0(s2)
    800060de:	94be                	add	s1,s1,a5
    800060e0:	00c4d783          	lhu	a5,12(s1)
    800060e4:	8b85                	andi	a5,a5,1
    800060e6:	cf89                	beqz	a5,80006100 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800060e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800060ec:	b7cd                	j	800060ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060ee:	0001f797          	auipc	a5,0x1f
    800060f2:	f127b783          	ld	a5,-238(a5) # 80025000 <disk+0x2000>
    800060f6:	97ba                	add	a5,a5,a4
    800060f8:	4689                	li	a3,2
    800060fa:	00d79623          	sh	a3,12(a5)
    800060fe:	b5fd                	j	80005fec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006100:	0001f517          	auipc	a0,0x1f
    80006104:	fa850513          	addi	a0,a0,-88 # 800250a8 <disk+0x20a8>
    80006108:	ffffb097          	auipc	ra,0xffffb
    8000610c:	c20080e7          	jalr	-992(ra) # 80000d28 <release>
}
    80006110:	70e6                	ld	ra,120(sp)
    80006112:	7446                	ld	s0,112(sp)
    80006114:	74a6                	ld	s1,104(sp)
    80006116:	7906                	ld	s2,96(sp)
    80006118:	69e6                	ld	s3,88(sp)
    8000611a:	6a46                	ld	s4,80(sp)
    8000611c:	6aa6                	ld	s5,72(sp)
    8000611e:	6b06                	ld	s6,64(sp)
    80006120:	7be2                	ld	s7,56(sp)
    80006122:	7c42                	ld	s8,48(sp)
    80006124:	7ca2                	ld	s9,40(sp)
    80006126:	7d02                	ld	s10,32(sp)
    80006128:	6109                	addi	sp,sp,128
    8000612a:	8082                	ret
  if(write)
    8000612c:	e20d1ee3          	bnez	s10,80005f68 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006130:	f8042023          	sw	zero,-128(s0)
    80006134:	bd2d                	j	80005f6e <virtio_disk_rw+0xe2>

0000000080006136 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006136:	1101                	addi	sp,sp,-32
    80006138:	ec06                	sd	ra,24(sp)
    8000613a:	e822                	sd	s0,16(sp)
    8000613c:	e426                	sd	s1,8(sp)
    8000613e:	e04a                	sd	s2,0(sp)
    80006140:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006142:	0001f517          	auipc	a0,0x1f
    80006146:	f6650513          	addi	a0,a0,-154 # 800250a8 <disk+0x20a8>
    8000614a:	ffffb097          	auipc	ra,0xffffb
    8000614e:	b2a080e7          	jalr	-1238(ra) # 80000c74 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006152:	0001f717          	auipc	a4,0x1f
    80006156:	eae70713          	addi	a4,a4,-338 # 80025000 <disk+0x2000>
    8000615a:	02075783          	lhu	a5,32(a4)
    8000615e:	6b18                	ld	a4,16(a4)
    80006160:	00275683          	lhu	a3,2(a4)
    80006164:	8ebd                	xor	a3,a3,a5
    80006166:	8a9d                	andi	a3,a3,7
    80006168:	cab9                	beqz	a3,800061be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000616a:	0001d917          	auipc	s2,0x1d
    8000616e:	e9690913          	addi	s2,s2,-362 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006172:	0001f497          	auipc	s1,0x1f
    80006176:	e8e48493          	addi	s1,s1,-370 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000617a:	078e                	slli	a5,a5,0x3
    8000617c:	97ba                	add	a5,a5,a4
    8000617e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006180:	20078713          	addi	a4,a5,512
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	974a                	add	a4,a4,s2
    80006188:	03074703          	lbu	a4,48(a4)
    8000618c:	ef21                	bnez	a4,800061e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000618e:	20078793          	addi	a5,a5,512
    80006192:	0792                	slli	a5,a5,0x4
    80006194:	97ca                	add	a5,a5,s2
    80006196:	7798                	ld	a4,40(a5)
    80006198:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000619c:	7788                	ld	a0,40(a5)
    8000619e:	ffffc097          	auipc	ra,0xffffc
    800061a2:	236080e7          	jalr	566(ra) # 800023d4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061a6:	0204d783          	lhu	a5,32(s1)
    800061aa:	2785                	addiw	a5,a5,1
    800061ac:	8b9d                	andi	a5,a5,7
    800061ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061b2:	6898                	ld	a4,16(s1)
    800061b4:	00275683          	lhu	a3,2(a4)
    800061b8:	8a9d                	andi	a3,a3,7
    800061ba:	fcf690e3          	bne	a3,a5,8000617a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061be:	10001737          	lui	a4,0x10001
    800061c2:	533c                	lw	a5,96(a4)
    800061c4:	8b8d                	andi	a5,a5,3
    800061c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061c8:	0001f517          	auipc	a0,0x1f
    800061cc:	ee050513          	addi	a0,a0,-288 # 800250a8 <disk+0x20a8>
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	b58080e7          	jalr	-1192(ra) # 80000d28 <release>
}
    800061d8:	60e2                	ld	ra,24(sp)
    800061da:	6442                	ld	s0,16(sp)
    800061dc:	64a2                	ld	s1,8(sp)
    800061de:	6902                	ld	s2,0(sp)
    800061e0:	6105                	addi	sp,sp,32
    800061e2:	8082                	ret
      panic("virtio_disk_intr status");
    800061e4:	00002517          	auipc	a0,0x2
    800061e8:	62c50513          	addi	a0,a0,1580 # 80008810 <syscalls+0x3d0>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	3ea080e7          	jalr	1002(ra) # 800005d6 <panic>
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
