
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c5c78793          	addi	a5,a5,-932 # 80005cc0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca6f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e6678793          	addi	a5,a5,-410 # 80000f14 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	436080e7          	jalr	1078(ra) # 80002562 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	7dc080e7          	jalr	2012(ra) # 80000918 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	aa4080e7          	jalr	-1372(ra) # 80000c36 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	89c080e7          	jalr	-1892(ra) # 80001a5c <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1e4080e7          	jalr	484(ra) # 800023ac <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f2e080e7          	jalr	-210(ra) # 80002104 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2fa080e7          	jalr	762(ra) # 8000250c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	af2080e7          	jalr	-1294(ra) # 80000d20 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	adc080e7          	jalr	-1316(ra) # 80000d20 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5ba080e7          	jalr	1466(ra) # 80000846 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5a8080e7          	jalr	1448(ra) # 80000846 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	59c080e7          	jalr	1436(ra) # 80000846 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	592080e7          	jalr	1426(ra) # 80000846 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	962080e7          	jalr	-1694(ra) # 80000c36 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2c6080e7          	jalr	710(ra) # 800025b8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a1e080e7          	jalr	-1506(ra) # 80000d20 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d22080e7          	jalr	-734(ra) # 80002168 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	73a080e7          	jalr	1850(ra) # 80000ba2 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	386080e7          	jalr	902(ra) # 800007f6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	78078793          	addi	a5,a5,1920 # 80020bf8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b9e60613          	addi	a2,a2,-1122 # 80008058 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07ab23          	sw	zero,1494(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b8450513          	addi	a0,a0,-1148 # 800080f0 <digits+0x98>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  //backtrace();
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	36f72123          	sw	a5,866(a4) # 800088e0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	566dad83          	lw	s11,1382(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a72b0b13          	addi	s6,s6,-1422 # 80008058 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	51050513          	addi	a0,a0,1296 # 80010b08 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	636080e7          	jalr	1590(ra) # 80000c36 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3b250513          	addi	a0,a0,946 # 80010b08 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	5c2080e7          	jalr	1474(ra) # 80000d20 <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
  
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	39648493          	addi	s1,s1,918 # 80010b08 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	41e080e7          	jalr	1054(ra) # 80000ba2 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <backtrace>:

void backtrace(void)
{
    8000079a:	7179                	addi	sp,sp,-48
    8000079c:	f406                	sd	ra,40(sp)
    8000079e:	f022                	sd	s0,32(sp)
    800007a0:	ec26                	sd	s1,24(sp)
    800007a2:	e84a                	sd	s2,16(sp)
    800007a4:	e44e                	sd	s3,8(sp)
    800007a6:	1800                	addi	s0,sp,48
   printf("backtrace: \n");
    800007a8:	00008517          	auipc	a0,0x8
    800007ac:	89850513          	addi	a0,a0,-1896 # 80008040 <etext+0x40>
    800007b0:	00000097          	auipc	ra,0x0
    800007b4:	dd8080e7          	jalr	-552(ra) # 80000588 <printf>
  return x;
}
static inline uint64 r_fp()
{
  uint64 x;
  asm volatile ("mv %0, s0" : "=r" (x));
    800007b8:	84a2                	mv	s1,s0
   uint64 fp = r_fp();
   uint64 bottom = PGROUNDUP(fp);
    800007ba:	6905                	lui	s2,0x1
    800007bc:	197d                	addi	s2,s2,-1
    800007be:	9926                	add	s2,s2,s1
    800007c0:	77fd                	lui	a5,0xfffff
    800007c2:	00f97933          	and	s2,s2,a5
   while(fp < bottom)
    800007c6:	0324f163          	bgeu	s1,s2,800007e8 <backtrace+0x4e>
   {
    uint64 ra = *(uint64 *)(fp-8);
    printf("%p\n", ra);
    800007ca:	00008997          	auipc	s3,0x8
    800007ce:	88698993          	addi	s3,s3,-1914 # 80008050 <etext+0x50>
    800007d2:	ff84b583          	ld	a1,-8(s1)
    800007d6:	854e                	mv	a0,s3
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	db0080e7          	jalr	-592(ra) # 80000588 <printf>
    fp = *(uint64*)(fp-16);
    800007e0:	ff04b483          	ld	s1,-16(s1)
   while(fp < bottom)
    800007e4:	ff24e7e3          	bltu	s1,s2,800007d2 <backtrace+0x38>
   }
}
    800007e8:	70a2                	ld	ra,40(sp)
    800007ea:	7402                	ld	s0,32(sp)
    800007ec:	64e2                	ld	s1,24(sp)
    800007ee:	6942                	ld	s2,16(sp)
    800007f0:	69a2                	ld	s3,8(sp)
    800007f2:	6145                	addi	sp,sp,48
    800007f4:	8082                	ret

00000000800007f6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007f6:	1141                	addi	sp,sp,-16
    800007f8:	e406                	sd	ra,8(sp)
    800007fa:	e022                	sd	s0,0(sp)
    800007fc:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007fe:	100007b7          	lui	a5,0x10000
    80000802:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000806:	f8000713          	li	a4,-128
    8000080a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000080e:	470d                	li	a4,3
    80000810:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000814:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000818:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000081c:	469d                	li	a3,7
    8000081e:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000822:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000826:	00008597          	auipc	a1,0x8
    8000082a:	84a58593          	addi	a1,a1,-1974 # 80008070 <digits+0x18>
    8000082e:	00010517          	auipc	a0,0x10
    80000832:	2fa50513          	addi	a0,a0,762 # 80010b28 <uart_tx_lock>
    80000836:	00000097          	auipc	ra,0x0
    8000083a:	36c080e7          	jalr	876(ra) # 80000ba2 <initlock>
}
    8000083e:	60a2                	ld	ra,8(sp)
    80000840:	6402                	ld	s0,0(sp)
    80000842:	0141                	addi	sp,sp,16
    80000844:	8082                	ret

0000000080000846 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000846:	1101                	addi	sp,sp,-32
    80000848:	ec06                	sd	ra,24(sp)
    8000084a:	e822                	sd	s0,16(sp)
    8000084c:	e426                	sd	s1,8(sp)
    8000084e:	1000                	addi	s0,sp,32
    80000850:	84aa                	mv	s1,a0
  push_off();
    80000852:	00000097          	auipc	ra,0x0
    80000856:	398080e7          	jalr	920(ra) # 80000bea <push_off>

  if(panicked){
    8000085a:	00008797          	auipc	a5,0x8
    8000085e:	0867a783          	lw	a5,134(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000862:	10000737          	lui	a4,0x10000
  if(panicked){
    80000866:	c391                	beqz	a5,8000086a <uartputc_sync+0x24>
    for(;;)
    80000868:	a001                	j	80000868 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000086a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000086e:	0207f793          	andi	a5,a5,32
    80000872:	dfe5                	beqz	a5,8000086a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000874:	0ff4f513          	andi	a0,s1,255
    80000878:	100007b7          	lui	a5,0x10000
    8000087c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000880:	00000097          	auipc	ra,0x0
    80000884:	440080e7          	jalr	1088(ra) # 80000cc0 <pop_off>
}
    80000888:	60e2                	ld	ra,24(sp)
    8000088a:	6442                	ld	s0,16(sp)
    8000088c:	64a2                	ld	s1,8(sp)
    8000088e:	6105                	addi	sp,sp,32
    80000890:	8082                	ret

0000000080000892 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000892:	00008797          	auipc	a5,0x8
    80000896:	0567b783          	ld	a5,86(a5) # 800088e8 <uart_tx_r>
    8000089a:	00008717          	auipc	a4,0x8
    8000089e:	05673703          	ld	a4,86(a4) # 800088f0 <uart_tx_w>
    800008a2:	06f70a63          	beq	a4,a5,80000916 <uartstart+0x84>
{
    800008a6:	7139                	addi	sp,sp,-64
    800008a8:	fc06                	sd	ra,56(sp)
    800008aa:	f822                	sd	s0,48(sp)
    800008ac:	f426                	sd	s1,40(sp)
    800008ae:	f04a                	sd	s2,32(sp)
    800008b0:	ec4e                	sd	s3,24(sp)
    800008b2:	e852                	sd	s4,16(sp)
    800008b4:	e456                	sd	s5,8(sp)
    800008b6:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b8:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00010a17          	auipc	s4,0x10
    800008c0:	26ca0a13          	addi	s4,s4,620 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	00008497          	auipc	s1,0x8
    800008c8:	02448493          	addi	s1,s1,36 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008cc:	00008997          	auipc	s3,0x8
    800008d0:	02498993          	addi	s3,s3,36 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d4:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008d8:	02077713          	andi	a4,a4,32
    800008dc:	c705                	beqz	a4,80000904 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008de:	01f7f713          	andi	a4,a5,31
    800008e2:	9752                	add	a4,a4,s4
    800008e4:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800008e8:	0785                	addi	a5,a5,1
    800008ea:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008ec:	8526                	mv	a0,s1
    800008ee:	00002097          	auipc	ra,0x2
    800008f2:	87a080e7          	jalr	-1926(ra) # 80002168 <wakeup>
    
    WriteReg(THR, c);
    800008f6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008fa:	609c                	ld	a5,0(s1)
    800008fc:	0009b703          	ld	a4,0(s3)
    80000900:	fcf71ae3          	bne	a4,a5,800008d4 <uartstart+0x42>
  }
}
    80000904:	70e2                	ld	ra,56(sp)
    80000906:	7442                	ld	s0,48(sp)
    80000908:	74a2                	ld	s1,40(sp)
    8000090a:	7902                	ld	s2,32(sp)
    8000090c:	69e2                	ld	s3,24(sp)
    8000090e:	6a42                	ld	s4,16(sp)
    80000910:	6aa2                	ld	s5,8(sp)
    80000912:	6121                	addi	sp,sp,64
    80000914:	8082                	ret
    80000916:	8082                	ret

0000000080000918 <uartputc>:
{
    80000918:	7179                	addi	sp,sp,-48
    8000091a:	f406                	sd	ra,40(sp)
    8000091c:	f022                	sd	s0,32(sp)
    8000091e:	ec26                	sd	s1,24(sp)
    80000920:	e84a                	sd	s2,16(sp)
    80000922:	e44e                	sd	s3,8(sp)
    80000924:	e052                	sd	s4,0(sp)
    80000926:	1800                	addi	s0,sp,48
    80000928:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    8000092a:	00010517          	auipc	a0,0x10
    8000092e:	1fe50513          	addi	a0,a0,510 # 80010b28 <uart_tx_lock>
    80000932:	00000097          	auipc	ra,0x0
    80000936:	304080e7          	jalr	772(ra) # 80000c36 <acquire>
  if(panicked){
    8000093a:	00008797          	auipc	a5,0x8
    8000093e:	fa67a783          	lw	a5,-90(a5) # 800088e0 <panicked>
    80000942:	e7c9                	bnez	a5,800009cc <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000944:	00008717          	auipc	a4,0x8
    80000948:	fac73703          	ld	a4,-84(a4) # 800088f0 <uart_tx_w>
    8000094c:	00008797          	auipc	a5,0x8
    80000950:	f9c7b783          	ld	a5,-100(a5) # 800088e8 <uart_tx_r>
    80000954:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000958:	00010997          	auipc	s3,0x10
    8000095c:	1d098993          	addi	s3,s3,464 # 80010b28 <uart_tx_lock>
    80000960:	00008497          	auipc	s1,0x8
    80000964:	f8848493          	addi	s1,s1,-120 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000968:	00008917          	auipc	s2,0x8
    8000096c:	f8890913          	addi	s2,s2,-120 # 800088f0 <uart_tx_w>
    80000970:	00e79f63          	bne	a5,a4,8000098e <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000974:	85ce                	mv	a1,s3
    80000976:	8526                	mv	a0,s1
    80000978:	00001097          	auipc	ra,0x1
    8000097c:	78c080e7          	jalr	1932(ra) # 80002104 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00093703          	ld	a4,0(s2)
    80000984:	609c                	ld	a5,0(s1)
    80000986:	02078793          	addi	a5,a5,32
    8000098a:	fee785e3          	beq	a5,a4,80000974 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000098e:	00010497          	auipc	s1,0x10
    80000992:	19a48493          	addi	s1,s1,410 # 80010b28 <uart_tx_lock>
    80000996:	01f77793          	andi	a5,a4,31
    8000099a:	97a6                	add	a5,a5,s1
    8000099c:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a0:	0705                	addi	a4,a4,1
    800009a2:	00008797          	auipc	a5,0x8
    800009a6:	f4e7b723          	sd	a4,-178(a5) # 800088f0 <uart_tx_w>
  uartstart();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	ee8080e7          	jalr	-280(ra) # 80000892 <uartstart>
  release(&uart_tx_lock);
    800009b2:	8526                	mv	a0,s1
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	36c080e7          	jalr	876(ra) # 80000d20 <release>
}
    800009bc:	70a2                	ld	ra,40(sp)
    800009be:	7402                	ld	s0,32(sp)
    800009c0:	64e2                	ld	s1,24(sp)
    800009c2:	6942                	ld	s2,16(sp)
    800009c4:	69a2                	ld	s3,8(sp)
    800009c6:	6a02                	ld	s4,0(sp)
    800009c8:	6145                	addi	sp,sp,48
    800009ca:	8082                	ret
    for(;;)
    800009cc:	a001                	j	800009cc <uartputc+0xb4>

00000000800009ce <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ce:	1141                	addi	sp,sp,-16
    800009d0:	e422                	sd	s0,8(sp)
    800009d2:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009d4:	100007b7          	lui	a5,0x10000
    800009d8:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009dc:	8b85                	andi	a5,a5,1
    800009de:	cb91                	beqz	a5,800009f2 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009e0:	100007b7          	lui	a5,0x10000
    800009e4:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009e8:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ec:	6422                	ld	s0,8(sp)
    800009ee:	0141                	addi	sp,sp,16
    800009f0:	8082                	ret
    return -1;
    800009f2:	557d                	li	a0,-1
    800009f4:	bfe5                	j	800009ec <uartgetc+0x1e>

00000000800009f6 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a00:	54fd                	li	s1,-1
    80000a02:	a029                	j	80000a0c <uartintr+0x16>
      break;
    consoleintr(c);
    80000a04:	00000097          	auipc	ra,0x0
    80000a08:	8ba080e7          	jalr	-1862(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a0c:	00000097          	auipc	ra,0x0
    80000a10:	fc2080e7          	jalr	-62(ra) # 800009ce <uartgetc>
    if(c == -1)
    80000a14:	fe9518e3          	bne	a0,s1,80000a04 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a18:	00010497          	auipc	s1,0x10
    80000a1c:	11048493          	addi	s1,s1,272 # 80010b28 <uart_tx_lock>
    80000a20:	8526                	mv	a0,s1
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	214080e7          	jalr	532(ra) # 80000c36 <acquire>
  uartstart();
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	e68080e7          	jalr	-408(ra) # 80000892 <uartstart>
  release(&uart_tx_lock);
    80000a32:	8526                	mv	a0,s1
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	2ec080e7          	jalr	748(ra) # 80000d20 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6105                	addi	sp,sp,32
    80000a44:	8082                	ret

0000000080000a46 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a46:	1101                	addi	sp,sp,-32
    80000a48:	ec06                	sd	ra,24(sp)
    80000a4a:	e822                	sd	s0,16(sp)
    80000a4c:	e426                	sd	s1,8(sp)
    80000a4e:	e04a                	sd	s2,0(sp)
    80000a50:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a52:	03451793          	slli	a5,a0,0x34
    80000a56:	ebb9                	bnez	a5,80000aac <kfree+0x66>
    80000a58:	84aa                	mv	s1,a0
    80000a5a:	00021797          	auipc	a5,0x21
    80000a5e:	33678793          	addi	a5,a5,822 # 80021d90 <end>
    80000a62:	04f56563          	bltu	a0,a5,80000aac <kfree+0x66>
    80000a66:	47c5                	li	a5,17
    80000a68:	07ee                	slli	a5,a5,0x1b
    80000a6a:	04f57163          	bgeu	a0,a5,80000aac <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a6e:	6605                	lui	a2,0x1
    80000a70:	4585                	li	a1,1
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	2fc080e7          	jalr	764(ra) # 80000d6e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7a:	00010917          	auipc	s2,0x10
    80000a7e:	0e690913          	addi	s2,s2,230 # 80010b60 <kmem>
    80000a82:	854a                	mv	a0,s2
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	1b2080e7          	jalr	434(ra) # 80000c36 <acquire>
  r->next = kmem.freelist;
    80000a8c:	01893783          	ld	a5,24(s2)
    80000a90:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a92:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	288080e7          	jalr	648(ra) # 80000d20 <release>
}
    80000aa0:	60e2                	ld	ra,24(sp)
    80000aa2:	6442                	ld	s0,16(sp)
    80000aa4:	64a2                	ld	s1,8(sp)
    80000aa6:	6902                	ld	s2,0(sp)
    80000aa8:	6105                	addi	sp,sp,32
    80000aaa:	8082                	ret
    panic("kfree");
    80000aac:	00007517          	auipc	a0,0x7
    80000ab0:	5cc50513          	addi	a0,a0,1484 # 80008078 <digits+0x20>
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>

0000000080000abc <freerange>:
{
    80000abc:	7179                	addi	sp,sp,-48
    80000abe:	f406                	sd	ra,40(sp)
    80000ac0:	f022                	sd	s0,32(sp)
    80000ac2:	ec26                	sd	s1,24(sp)
    80000ac4:	e84a                	sd	s2,16(sp)
    80000ac6:	e44e                	sd	s3,8(sp)
    80000ac8:	e052                	sd	s4,0(sp)
    80000aca:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000acc:	6785                	lui	a5,0x1
    80000ace:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ad2:	94aa                	add	s1,s1,a0
    80000ad4:	757d                	lui	a0,0xfffff
    80000ad6:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0095ee63          	bltu	a1,s1,80000af6 <freerange+0x3a>
    80000ade:	892e                	mv	s2,a1
    kfree(p);
    80000ae0:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae2:	6985                	lui	s3,0x1
    kfree(p);
    80000ae4:	01448533          	add	a0,s1,s4
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	f5e080e7          	jalr	-162(ra) # 80000a46 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af0:	94ce                	add	s1,s1,s3
    80000af2:	fe9979e3          	bgeu	s2,s1,80000ae4 <freerange+0x28>
}
    80000af6:	70a2                	ld	ra,40(sp)
    80000af8:	7402                	ld	s0,32(sp)
    80000afa:	64e2                	ld	s1,24(sp)
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
    80000b02:	6145                	addi	sp,sp,48
    80000b04:	8082                	ret

0000000080000b06 <kinit>:
{
    80000b06:	1141                	addi	sp,sp,-16
    80000b08:	e406                	sd	ra,8(sp)
    80000b0a:	e022                	sd	s0,0(sp)
    80000b0c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b0e:	00007597          	auipc	a1,0x7
    80000b12:	57258593          	addi	a1,a1,1394 # 80008080 <digits+0x28>
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	04a50513          	addi	a0,a0,74 # 80010b60 <kmem>
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	084080e7          	jalr	132(ra) # 80000ba2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b26:	45c5                	li	a1,17
    80000b28:	05ee                	slli	a1,a1,0x1b
    80000b2a:	00021517          	auipc	a0,0x21
    80000b2e:	26650513          	addi	a0,a0,614 # 80021d90 <end>
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	f8a080e7          	jalr	-118(ra) # 80000abc <freerange>
}
    80000b3a:	60a2                	ld	ra,8(sp)
    80000b3c:	6402                	ld	s0,0(sp)
    80000b3e:	0141                	addi	sp,sp,16
    80000b40:	8082                	ret

0000000080000b42 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b42:	1101                	addi	sp,sp,-32
    80000b44:	ec06                	sd	ra,24(sp)
    80000b46:	e822                	sd	s0,16(sp)
    80000b48:	e426                	sd	s1,8(sp)
    80000b4a:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b4c:	00010497          	auipc	s1,0x10
    80000b50:	01448493          	addi	s1,s1,20 # 80010b60 <kmem>
    80000b54:	8526                	mv	a0,s1
    80000b56:	00000097          	auipc	ra,0x0
    80000b5a:	0e0080e7          	jalr	224(ra) # 80000c36 <acquire>
  r = kmem.freelist;
    80000b5e:	6c84                	ld	s1,24(s1)
  if(r)
    80000b60:	c885                	beqz	s1,80000b90 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b62:	609c                	ld	a5,0(s1)
    80000b64:	00010517          	auipc	a0,0x10
    80000b68:	ffc50513          	addi	a0,a0,-4 # 80010b60 <kmem>
    80000b6c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	1b2080e7          	jalr	434(ra) # 80000d20 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b76:	6605                	lui	a2,0x1
    80000b78:	4595                	li	a1,5
    80000b7a:	8526                	mv	a0,s1
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	1f2080e7          	jalr	498(ra) # 80000d6e <memset>
  return (void*)r;
}
    80000b84:	8526                	mv	a0,s1
    80000b86:	60e2                	ld	ra,24(sp)
    80000b88:	6442                	ld	s0,16(sp)
    80000b8a:	64a2                	ld	s1,8(sp)
    80000b8c:	6105                	addi	sp,sp,32
    80000b8e:	8082                	ret
  release(&kmem.lock);
    80000b90:	00010517          	auipc	a0,0x10
    80000b94:	fd050513          	addi	a0,a0,-48 # 80010b60 <kmem>
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	188080e7          	jalr	392(ra) # 80000d20 <release>
  if(r)
    80000ba0:	b7d5                	j	80000b84 <kalloc+0x42>

0000000080000ba2 <initlock>:
#include "defs.h"

//struct spinlock shared_lock;
void
initlock(struct spinlock *lk, char *name)
{
    80000ba2:	1141                	addi	sp,sp,-16
    80000ba4:	e422                	sd	s0,8(sp)
    80000ba6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ba8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000baa:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bae:	00053823          	sd	zero,16(a0)
  lk->priority = 1;
    80000bb2:	4785                	li	a5,1
    80000bb4:	c15c                	sw	a5,4(a0)
}
    80000bb6:	6422                	ld	s0,8(sp)
    80000bb8:	0141                	addi	sp,sp,16
    80000bba:	8082                	ret

0000000080000bbc <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bbc:	411c                	lw	a5,0(a0)
    80000bbe:	e399                	bnez	a5,80000bc4 <holding+0x8>
    80000bc0:	4501                	li	a0,0
  return r;
}
    80000bc2:	8082                	ret
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	6904                	ld	s1,16(a0)
    80000bd0:	00001097          	auipc	ra,0x1
    80000bd4:	e70080e7          	jalr	-400(ra) # 80001a40 <mycpu>
    80000bd8:	40a48533          	sub	a0,s1,a0
    80000bdc:	00153513          	seqz	a0,a0
}
    80000be0:	60e2                	ld	ra,24(sp)
    80000be2:	6442                	ld	s0,16(sp)
    80000be4:	64a2                	ld	s1,8(sp)
    80000be6:	6105                	addi	sp,sp,32
    80000be8:	8082                	ret

0000000080000bea <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf4:	100024f3          	csrr	s1,sstatus
    80000bf8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bfe:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	e3e080e7          	jalr	-450(ra) # 80001a40 <mycpu>
    80000c0a:	5d3c                	lw	a5,120(a0)
    80000c0c:	cf89                	beqz	a5,80000c26 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c0e:	00001097          	auipc	ra,0x1
    80000c12:	e32080e7          	jalr	-462(ra) # 80001a40 <mycpu>
    80000c16:	5d3c                	lw	a5,120(a0)
    80000c18:	2785                	addiw	a5,a5,1
    80000c1a:	dd3c                	sw	a5,120(a0)
}
    80000c1c:	60e2                	ld	ra,24(sp)
    80000c1e:	6442                	ld	s0,16(sp)
    80000c20:	64a2                	ld	s1,8(sp)
    80000c22:	6105                	addi	sp,sp,32
    80000c24:	8082                	ret
    mycpu()->intena = old;
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	e1a080e7          	jalr	-486(ra) # 80001a40 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c2e:	8085                	srli	s1,s1,0x1
    80000c30:	8885                	andi	s1,s1,1
    80000c32:	dd64                	sw	s1,124(a0)
    80000c34:	bfe9                	j	80000c0e <push_off+0x24>

0000000080000c36 <acquire>:
{
    80000c36:	7179                	addi	sp,sp,-48
    80000c38:	f406                	sd	ra,40(sp)
    80000c3a:	f022                	sd	s0,32(sp)
    80000c3c:	ec26                	sd	s1,24(sp)
    80000c3e:	e84a                	sd	s2,16(sp)
    80000c40:	e44e                	sd	s3,8(sp)
    80000c42:	1800                	addi	s0,sp,48
    80000c44:	84aa                	mv	s1,a0
  push_off(); // Disable interrupts to avoid deadlock.
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	fa4080e7          	jalr	-92(ra) # 80000bea <push_off>
  if(holding(lk))
    80000c4e:	8526                	mv	a0,s1
    80000c50:	00000097          	auipc	ra,0x0
    80000c54:	f6c080e7          	jalr	-148(ra) # 80000bbc <holding>
    80000c58:	ed05                	bnez	a0,80000c90 <acquire+0x5a>
  int priority = (myproc()->lock).priority;
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	e02080e7          	jalr	-510(ra) # 80001a5c <myproc>
    80000c62:	00452903          	lw	s2,4(a0)
    int old_value = __sync_val_compare_and_swap(&lk->locked, 0, 1);
    80000c66:	4985                	li	s3,1
    80000c68:	0f50000f          	fence	iorw,ow
    80000c6c:	1404a7af          	lr.w.aq	a5,(s1)
    80000c70:	e781                	bnez	a5,80000c78 <acquire+0x42>
    80000c72:	1d34a72f          	sc.w.aq	a4,s3,(s1)
    80000c76:	fb7d                	bnez	a4,80000c6c <acquire+0x36>
    80000c78:	2781                	sext.w	a5,a5
    if (old_value == 0 || priority < lk->priority) {
    80000c7a:	c39d                	beqz	a5,80000ca0 <acquire+0x6a>
    80000c7c:	40dc                	lw	a5,4(s1)
    80000c7e:	02f94163          	blt	s2,a5,80000ca0 <acquire+0x6a>
      sleep(lk, lk);
    80000c82:	85a6                	mv	a1,s1
    80000c84:	8526                	mv	a0,s1
    80000c86:	00001097          	auipc	ra,0x1
    80000c8a:	47e080e7          	jalr	1150(ra) # 80002104 <sleep>
  while (1) {
    80000c8e:	bfe9                	j	80000c68 <acquire+0x32>
    {panic("acquire"); lk->priority = 0;}
    80000c90:	00007517          	auipc	a0,0x7
    80000c94:	3f850513          	addi	a0,a0,1016 # 80008088 <digits+0x30>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8a6080e7          	jalr	-1882(ra) # 8000053e <panic>
      lk->priority = priority; // Update the lock's priority
    80000ca0:	0124a223          	sw	s2,4(s1)
      __sync_synchronize(); // Ensure memory ordering
    80000ca4:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ca8:	00001097          	auipc	ra,0x1
    80000cac:	d98080e7          	jalr	-616(ra) # 80001a40 <mycpu>
    80000cb0:	e888                	sd	a0,16(s1)
}
    80000cb2:	70a2                	ld	ra,40(sp)
    80000cb4:	7402                	ld	s0,32(sp)
    80000cb6:	64e2                	ld	s1,24(sp)
    80000cb8:	6942                	ld	s2,16(sp)
    80000cba:	69a2                	ld	s3,8(sp)
    80000cbc:	6145                	addi	sp,sp,48
    80000cbe:	8082                	ret

0000000080000cc0 <pop_off>:

void
pop_off(void)
{
    80000cc0:	1141                	addi	sp,sp,-16
    80000cc2:	e406                	sd	ra,8(sp)
    80000cc4:	e022                	sd	s0,0(sp)
    80000cc6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cc8:	00001097          	auipc	ra,0x1
    80000ccc:	d78080e7          	jalr	-648(ra) # 80001a40 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cd4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cd6:	e78d                	bnez	a5,80000d00 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cd8:	5d3c                	lw	a5,120(a0)
    80000cda:	02f05b63          	blez	a5,80000d10 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cde:	37fd                	addiw	a5,a5,-1
    80000ce0:	0007871b          	sext.w	a4,a5
    80000ce4:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000ce6:	eb09                	bnez	a4,80000cf8 <pop_off+0x38>
    80000ce8:	5d7c                	lw	a5,124(a0)
    80000cea:	c799                	beqz	a5,80000cf8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cf0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cf8:	60a2                	ld	ra,8(sp)
    80000cfa:	6402                	ld	s0,0(sp)
    80000cfc:	0141                	addi	sp,sp,16
    80000cfe:	8082                	ret
    panic("pop_off - interruptible");
    80000d00:	00007517          	auipc	a0,0x7
    80000d04:	39050513          	addi	a0,a0,912 # 80008090 <digits+0x38>
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	836080e7          	jalr	-1994(ra) # 8000053e <panic>
    panic("pop_off");
    80000d10:	00007517          	auipc	a0,0x7
    80000d14:	39850513          	addi	a0,a0,920 # 800080a8 <digits+0x50>
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	826080e7          	jalr	-2010(ra) # 8000053e <panic>

0000000080000d20 <release>:
{
    80000d20:	1101                	addi	sp,sp,-32
    80000d22:	ec06                	sd	ra,24(sp)
    80000d24:	e822                	sd	s0,16(sp)
    80000d26:	e426                	sd	s1,8(sp)
    80000d28:	1000                	addi	s0,sp,32
    80000d2a:	84aa                	mv	s1,a0
    if (!holding(lk))
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	e90080e7          	jalr	-368(ra) # 80000bbc <holding>
    80000d34:	c50d                	beqz	a0,80000d5e <release+0x3e>
    lk->priority = -1;
    80000d36:	57fd                	li	a5,-1
    80000d38:	c0dc                	sw	a5,4(s1)
    wakeup(lk);
    80000d3a:	8526                	mv	a0,s1
    80000d3c:	00001097          	auipc	ra,0x1
    80000d40:	42c080e7          	jalr	1068(ra) # 80002168 <wakeup>
    __sync_lock_release(&lk->locked);
    80000d44:	0f50000f          	fence	iorw,ow
    80000d48:	0804a02f          	amoswap.w	zero,zero,(s1)
    pop_off();
    80000d4c:	00000097          	auipc	ra,0x0
    80000d50:	f74080e7          	jalr	-140(ra) # 80000cc0 <pop_off>
}
    80000d54:	60e2                	ld	ra,24(sp)
    80000d56:	6442                	ld	s0,16(sp)
    80000d58:	64a2                	ld	s1,8(sp)
    80000d5a:	6105                	addi	sp,sp,32
    80000d5c:	8082                	ret
        panic("release");
    80000d5e:	00007517          	auipc	a0,0x7
    80000d62:	35250513          	addi	a0,a0,850 # 800080b0 <digits+0x58>
    80000d66:	fffff097          	auipc	ra,0xfffff
    80000d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>

0000000080000d6e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d74:	ca19                	beqz	a2,80000d8a <memset+0x1c>
    80000d76:	87aa                	mv	a5,a0
    80000d78:	1602                	slli	a2,a2,0x20
    80000d7a:	9201                	srli	a2,a2,0x20
    80000d7c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d80:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d84:	0785                	addi	a5,a5,1
    80000d86:	fee79de3          	bne	a5,a4,80000d80 <memset+0x12>
  }
  return dst;
}
    80000d8a:	6422                	ld	s0,8(sp)
    80000d8c:	0141                	addi	sp,sp,16
    80000d8e:	8082                	ret

0000000080000d90 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d96:	ca05                	beqz	a2,80000dc6 <memcmp+0x36>
    80000d98:	fff6069b          	addiw	a3,a2,-1
    80000d9c:	1682                	slli	a3,a3,0x20
    80000d9e:	9281                	srli	a3,a3,0x20
    80000da0:	0685                	addi	a3,a3,1
    80000da2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	0005c703          	lbu	a4,0(a1)
    80000dac:	00e79863          	bne	a5,a4,80000dbc <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000db0:	0505                	addi	a0,a0,1
    80000db2:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000db4:	fed518e3          	bne	a0,a3,80000da4 <memcmp+0x14>
  }

  return 0;
    80000db8:	4501                	li	a0,0
    80000dba:	a019                	j	80000dc0 <memcmp+0x30>
      return *s1 - *s2;
    80000dbc:	40e7853b          	subw	a0,a5,a4
}
    80000dc0:	6422                	ld	s0,8(sp)
    80000dc2:	0141                	addi	sp,sp,16
    80000dc4:	8082                	ret
  return 0;
    80000dc6:	4501                	li	a0,0
    80000dc8:	bfe5                	j	80000dc0 <memcmp+0x30>

0000000080000dca <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dca:	1141                	addi	sp,sp,-16
    80000dcc:	e422                	sd	s0,8(sp)
    80000dce:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dd0:	c205                	beqz	a2,80000df0 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dd2:	02a5e263          	bltu	a1,a0,80000df6 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dd6:	1602                	slli	a2,a2,0x20
    80000dd8:	9201                	srli	a2,a2,0x20
    80000dda:	00c587b3          	add	a5,a1,a2
{
    80000dde:	872a                	mv	a4,a0
      *d++ = *s++;
    80000de0:	0585                	addi	a1,a1,1
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	fff5c683          	lbu	a3,-1(a1)
    80000de8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dec:	fef59ae3          	bne	a1,a5,80000de0 <memmove+0x16>

  return dst;
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
  if(s < d && s + n > d){
    80000df6:	02061693          	slli	a3,a2,0x20
    80000dfa:	9281                	srli	a3,a3,0x20
    80000dfc:	00d58733          	add	a4,a1,a3
    80000e00:	fce57be3          	bgeu	a0,a4,80000dd6 <memmove+0xc>
    d += n;
    80000e04:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e06:	fff6079b          	addiw	a5,a2,-1
    80000e0a:	1782                	slli	a5,a5,0x20
    80000e0c:	9381                	srli	a5,a5,0x20
    80000e0e:	fff7c793          	not	a5,a5
    80000e12:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e14:	177d                	addi	a4,a4,-1
    80000e16:	16fd                	addi	a3,a3,-1
    80000e18:	00074603          	lbu	a2,0(a4)
    80000e1c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e20:	fee79ae3          	bne	a5,a4,80000e14 <memmove+0x4a>
    80000e24:	b7f1                	j	80000df0 <memmove+0x26>

0000000080000e26 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e26:	1141                	addi	sp,sp,-16
    80000e28:	e406                	sd	ra,8(sp)
    80000e2a:	e022                	sd	s0,0(sp)
    80000e2c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e2e:	00000097          	auipc	ra,0x0
    80000e32:	f9c080e7          	jalr	-100(ra) # 80000dca <memmove>
}
    80000e36:	60a2                	ld	ra,8(sp)
    80000e38:	6402                	ld	s0,0(sp)
    80000e3a:	0141                	addi	sp,sp,16
    80000e3c:	8082                	ret

0000000080000e3e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e3e:	1141                	addi	sp,sp,-16
    80000e40:	e422                	sd	s0,8(sp)
    80000e42:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e44:	ce11                	beqz	a2,80000e60 <strncmp+0x22>
    80000e46:	00054783          	lbu	a5,0(a0)
    80000e4a:	cf89                	beqz	a5,80000e64 <strncmp+0x26>
    80000e4c:	0005c703          	lbu	a4,0(a1)
    80000e50:	00f71a63          	bne	a4,a5,80000e64 <strncmp+0x26>
    n--, p++, q++;
    80000e54:	367d                	addiw	a2,a2,-1
    80000e56:	0505                	addi	a0,a0,1
    80000e58:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e5a:	f675                	bnez	a2,80000e46 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e5c:	4501                	li	a0,0
    80000e5e:	a809                	j	80000e70 <strncmp+0x32>
    80000e60:	4501                	li	a0,0
    80000e62:	a039                	j	80000e70 <strncmp+0x32>
  if(n == 0)
    80000e64:	ca09                	beqz	a2,80000e76 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e66:	00054503          	lbu	a0,0(a0)
    80000e6a:	0005c783          	lbu	a5,0(a1)
    80000e6e:	9d1d                	subw	a0,a0,a5
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	addi	sp,sp,16
    80000e74:	8082                	ret
    return 0;
    80000e76:	4501                	li	a0,0
    80000e78:	bfe5                	j	80000e70 <strncmp+0x32>

0000000080000e7a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e7a:	1141                	addi	sp,sp,-16
    80000e7c:	e422                	sd	s0,8(sp)
    80000e7e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e80:	872a                	mv	a4,a0
    80000e82:	8832                	mv	a6,a2
    80000e84:	367d                	addiw	a2,a2,-1
    80000e86:	01005963          	blez	a6,80000e98 <strncpy+0x1e>
    80000e8a:	0705                	addi	a4,a4,1
    80000e8c:	0005c783          	lbu	a5,0(a1)
    80000e90:	fef70fa3          	sb	a5,-1(a4)
    80000e94:	0585                	addi	a1,a1,1
    80000e96:	f7f5                	bnez	a5,80000e82 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e98:	86ba                	mv	a3,a4
    80000e9a:	00c05c63          	blez	a2,80000eb2 <strncpy+0x38>
    *s++ = 0;
    80000e9e:	0685                	addi	a3,a3,1
    80000ea0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ea4:	fff6c793          	not	a5,a3
    80000ea8:	9fb9                	addw	a5,a5,a4
    80000eaa:	010787bb          	addw	a5,a5,a6
    80000eae:	fef048e3          	bgtz	a5,80000e9e <strncpy+0x24>
  return os;
}
    80000eb2:	6422                	ld	s0,8(sp)
    80000eb4:	0141                	addi	sp,sp,16
    80000eb6:	8082                	ret

0000000080000eb8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eb8:	1141                	addi	sp,sp,-16
    80000eba:	e422                	sd	s0,8(sp)
    80000ebc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ebe:	02c05363          	blez	a2,80000ee4 <safestrcpy+0x2c>
    80000ec2:	fff6069b          	addiw	a3,a2,-1
    80000ec6:	1682                	slli	a3,a3,0x20
    80000ec8:	9281                	srli	a3,a3,0x20
    80000eca:	96ae                	add	a3,a3,a1
    80000ecc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ece:	00d58963          	beq	a1,a3,80000ee0 <safestrcpy+0x28>
    80000ed2:	0585                	addi	a1,a1,1
    80000ed4:	0785                	addi	a5,a5,1
    80000ed6:	fff5c703          	lbu	a4,-1(a1)
    80000eda:	fee78fa3          	sb	a4,-1(a5)
    80000ede:	fb65                	bnez	a4,80000ece <safestrcpy+0x16>
    ;
  *s = 0;
    80000ee0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ee4:	6422                	ld	s0,8(sp)
    80000ee6:	0141                	addi	sp,sp,16
    80000ee8:	8082                	ret

0000000080000eea <strlen>:

int
strlen(const char *s)
{
    80000eea:	1141                	addi	sp,sp,-16
    80000eec:	e422                	sd	s0,8(sp)
    80000eee:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ef0:	00054783          	lbu	a5,0(a0)
    80000ef4:	cf91                	beqz	a5,80000f10 <strlen+0x26>
    80000ef6:	0505                	addi	a0,a0,1
    80000ef8:	87aa                	mv	a5,a0
    80000efa:	4685                	li	a3,1
    80000efc:	9e89                	subw	a3,a3,a0
    80000efe:	00f6853b          	addw	a0,a3,a5
    80000f02:	0785                	addi	a5,a5,1
    80000f04:	fff7c703          	lbu	a4,-1(a5)
    80000f08:	fb7d                	bnez	a4,80000efe <strlen+0x14>
    ;
  return n;
}
    80000f0a:	6422                	ld	s0,8(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f10:	4501                	li	a0,0
    80000f12:	bfe5                	j	80000f0a <strlen+0x20>

0000000080000f14 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f14:	7179                	addi	sp,sp,-48
    80000f16:	f406                	sd	ra,40(sp)
    80000f18:	f022                	sd	s0,32(sp)
    80000f1a:	1800                	addi	s0,sp,48
  struct spinlock shared_lock;
  initlock(&shared_lock, "shared_lock");
    80000f1c:	00007597          	auipc	a1,0x7
    80000f20:	19c58593          	addi	a1,a1,412 # 800080b8 <digits+0x60>
    80000f24:	fd840513          	addi	a0,s0,-40
    80000f28:	00000097          	auipc	ra,0x0
    80000f2c:	c7a080e7          	jalr	-902(ra) # 80000ba2 <initlock>
  if(cpuid() == 0){
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	b00080e7          	jalr	-1280(ra) # 80001a30 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f38:	00008717          	auipc	a4,0x8
    80000f3c:	9c070713          	addi	a4,a4,-1600 # 800088f8 <started>
  if(cpuid() == 0){
    80000f40:	c139                	beqz	a0,80000f86 <main+0x72>
    while(started == 0)
    80000f42:	431c                	lw	a5,0(a4)
    80000f44:	2781                	sext.w	a5,a5
    80000f46:	dff5                	beqz	a5,80000f42 <main+0x2e>
      ;
    __sync_synchronize();
    80000f48:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	ae4080e7          	jalr	-1308(ra) # 80001a30 <cpuid>
    80000f54:	85aa                	mv	a1,a0
    80000f56:	00007517          	auipc	a0,0x7
    80000f5a:	18a50513          	addi	a0,a0,394 # 800080e0 <digits+0x88>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62a080e7          	jalr	1578(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000f66:	00000097          	auipc	ra,0x0
    80000f6a:	0d8080e7          	jalr	216(ra) # 8000103e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	78a080e7          	jalr	1930(ra) # 800026f8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	d8a080e7          	jalr	-630(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	fd4080e7          	jalr	-44(ra) # 80001f52 <scheduler>
    consoleinit();
    80000f86:	fffff097          	auipc	ra,0xfffff
    80000f8a:	4ca080e7          	jalr	1226(ra) # 80000450 <consoleinit>
    printfinit();
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	7da080e7          	jalr	2010(ra) # 80000768 <printfinit>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	15a50513          	addi	a0,a0,346 # 800080f0 <digits+0x98>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5ea080e7          	jalr	1514(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000fa6:	00007517          	auipc	a0,0x7
    80000faa:	12250513          	addi	a0,a0,290 # 800080c8 <digits+0x70>
    80000fae:	fffff097          	auipc	ra,0xfffff
    80000fb2:	5da080e7          	jalr	1498(ra) # 80000588 <printf>
    printf("\n");
    80000fb6:	00007517          	auipc	a0,0x7
    80000fba:	13a50513          	addi	a0,a0,314 # 800080f0 <digits+0x98>
    80000fbe:	fffff097          	auipc	ra,0xfffff
    80000fc2:	5ca080e7          	jalr	1482(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000fc6:	00000097          	auipc	ra,0x0
    80000fca:	b40080e7          	jalr	-1216(ra) # 80000b06 <kinit>
    kvminit();       // create kernel page table
    80000fce:	00000097          	auipc	ra,0x0
    80000fd2:	326080e7          	jalr	806(ra) # 800012f4 <kvminit>
    kvminithart();   // turn on paging
    80000fd6:	00000097          	auipc	ra,0x0
    80000fda:	068080e7          	jalr	104(ra) # 8000103e <kvminithart>
    procinit();      // process table
    80000fde:	00001097          	auipc	ra,0x1
    80000fe2:	99e080e7          	jalr	-1634(ra) # 8000197c <procinit>
    trapinit();      // trap vectors
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	6ea080e7          	jalr	1770(ra) # 800026d0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fee:	00001097          	auipc	ra,0x1
    80000ff2:	70a080e7          	jalr	1802(ra) # 800026f8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ff6:	00005097          	auipc	ra,0x5
    80000ffa:	cf4080e7          	jalr	-780(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	d02080e7          	jalr	-766(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80001006:	00002097          	auipc	ra,0x2
    8000100a:	eaa080e7          	jalr	-342(ra) # 80002eb0 <binit>
    iinit();         // inode table
    8000100e:	00002097          	auipc	ra,0x2
    80001012:	54e080e7          	jalr	1358(ra) # 8000355c <iinit>
    fileinit();      // file table
    80001016:	00003097          	auipc	ra,0x3
    8000101a:	4ec080e7          	jalr	1260(ra) # 80004502 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000101e:	00005097          	auipc	ra,0x5
    80001022:	dea080e7          	jalr	-534(ra) # 80005e08 <virtio_disk_init>
    userinit();      // first user process
    80001026:	00001097          	auipc	ra,0x1
    8000102a:	d0e080e7          	jalr	-754(ra) # 80001d34 <userinit>
    __sync_synchronize();
    8000102e:	0ff0000f          	fence
    started = 1;
    80001032:	4785                	li	a5,1
    80001034:	00008717          	auipc	a4,0x8
    80001038:	8cf72223          	sw	a5,-1852(a4) # 800088f8 <started>
    8000103c:	b789                	j	80000f7e <main+0x6a>

000000008000103e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000103e:	1141                	addi	sp,sp,-16
    80001040:	e422                	sd	s0,8(sp)
    80001042:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001044:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001048:	00008797          	auipc	a5,0x8
    8000104c:	8b87b783          	ld	a5,-1864(a5) # 80008900 <kernel_pagetable>
    80001050:	83b1                	srli	a5,a5,0xc
    80001052:	577d                	li	a4,-1
    80001054:	177e                	slli	a4,a4,0x3f
    80001056:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001058:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000105c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001060:	6422                	ld	s0,8(sp)
    80001062:	0141                	addi	sp,sp,16
    80001064:	8082                	ret

0000000080001066 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001066:	7139                	addi	sp,sp,-64
    80001068:	fc06                	sd	ra,56(sp)
    8000106a:	f822                	sd	s0,48(sp)
    8000106c:	f426                	sd	s1,40(sp)
    8000106e:	f04a                	sd	s2,32(sp)
    80001070:	ec4e                	sd	s3,24(sp)
    80001072:	e852                	sd	s4,16(sp)
    80001074:	e456                	sd	s5,8(sp)
    80001076:	e05a                	sd	s6,0(sp)
    80001078:	0080                	addi	s0,sp,64
    8000107a:	84aa                	mv	s1,a0
    8000107c:	89ae                	mv	s3,a1
    8000107e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001080:	57fd                	li	a5,-1
    80001082:	83e9                	srli	a5,a5,0x1a
    80001084:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001086:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001088:	04b7f263          	bgeu	a5,a1,800010cc <walk+0x66>
    panic("walk");
    8000108c:	00007517          	auipc	a0,0x7
    80001090:	06c50513          	addi	a0,a0,108 # 800080f8 <digits+0xa0>
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	4aa080e7          	jalr	1194(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000109c:	060a8663          	beqz	s5,80001108 <walk+0xa2>
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	aa2080e7          	jalr	-1374(ra) # 80000b42 <kalloc>
    800010a8:	84aa                	mv	s1,a0
    800010aa:	c529                	beqz	a0,800010f4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010ac:	6605                	lui	a2,0x1
    800010ae:	4581                	li	a1,0
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	cbe080e7          	jalr	-834(ra) # 80000d6e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010b8:	00c4d793          	srli	a5,s1,0xc
    800010bc:	07aa                	slli	a5,a5,0xa
    800010be:	0017e793          	ori	a5,a5,1
    800010c2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010c6:	3a5d                	addiw	s4,s4,-9
    800010c8:	036a0063          	beq	s4,s6,800010e8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010cc:	0149d933          	srl	s2,s3,s4
    800010d0:	1ff97913          	andi	s2,s2,511
    800010d4:	090e                	slli	s2,s2,0x3
    800010d6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010d8:	00093483          	ld	s1,0(s2)
    800010dc:	0014f793          	andi	a5,s1,1
    800010e0:	dfd5                	beqz	a5,8000109c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e2:	80a9                	srli	s1,s1,0xa
    800010e4:	04b2                	slli	s1,s1,0xc
    800010e6:	b7c5                	j	800010c6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010e8:	00c9d513          	srli	a0,s3,0xc
    800010ec:	1ff57513          	andi	a0,a0,511
    800010f0:	050e                	slli	a0,a0,0x3
    800010f2:	9526                	add	a0,a0,s1
}
    800010f4:	70e2                	ld	ra,56(sp)
    800010f6:	7442                	ld	s0,48(sp)
    800010f8:	74a2                	ld	s1,40(sp)
    800010fa:	7902                	ld	s2,32(sp)
    800010fc:	69e2                	ld	s3,24(sp)
    800010fe:	6a42                	ld	s4,16(sp)
    80001100:	6aa2                	ld	s5,8(sp)
    80001102:	6b02                	ld	s6,0(sp)
    80001104:	6121                	addi	sp,sp,64
    80001106:	8082                	ret
        return 0;
    80001108:	4501                	li	a0,0
    8000110a:	b7ed                	j	800010f4 <walk+0x8e>

000000008000110c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000110c:	57fd                	li	a5,-1
    8000110e:	83e9                	srli	a5,a5,0x1a
    80001110:	00b7f463          	bgeu	a5,a1,80001118 <walkaddr+0xc>
    return 0;
    80001114:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001116:	8082                	ret
{
    80001118:	1141                	addi	sp,sp,-16
    8000111a:	e406                	sd	ra,8(sp)
    8000111c:	e022                	sd	s0,0(sp)
    8000111e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001120:	4601                	li	a2,0
    80001122:	00000097          	auipc	ra,0x0
    80001126:	f44080e7          	jalr	-188(ra) # 80001066 <walk>
  if(pte == 0)
    8000112a:	c105                	beqz	a0,8000114a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000112c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000112e:	0117f693          	andi	a3,a5,17
    80001132:	4745                	li	a4,17
    return 0;
    80001134:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001136:	00e68663          	beq	a3,a4,80001142 <walkaddr+0x36>
}
    8000113a:	60a2                	ld	ra,8(sp)
    8000113c:	6402                	ld	s0,0(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret
  pa = PTE2PA(*pte);
    80001142:	00a7d513          	srli	a0,a5,0xa
    80001146:	0532                	slli	a0,a0,0xc
  return pa;
    80001148:	bfcd                	j	8000113a <walkaddr+0x2e>
    return 0;
    8000114a:	4501                	li	a0,0
    8000114c:	b7fd                	j	8000113a <walkaddr+0x2e>

000000008000114e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114e:	715d                	addi	sp,sp,-80
    80001150:	e486                	sd	ra,72(sp)
    80001152:	e0a2                	sd	s0,64(sp)
    80001154:	fc26                	sd	s1,56(sp)
    80001156:	f84a                	sd	s2,48(sp)
    80001158:	f44e                	sd	s3,40(sp)
    8000115a:	f052                	sd	s4,32(sp)
    8000115c:	ec56                	sd	s5,24(sp)
    8000115e:	e85a                	sd	s6,16(sp)
    80001160:	e45e                	sd	s7,8(sp)
    80001162:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001164:	c639                	beqz	a2,800011b2 <mappages+0x64>
    80001166:	8aaa                	mv	s5,a0
    80001168:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000116a:	77fd                	lui	a5,0xfffff
    8000116c:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001170:	15fd                	addi	a1,a1,-1
    80001172:	00c589b3          	add	s3,a1,a2
    80001176:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000117a:	8952                	mv	s2,s4
    8000117c:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001180:	6b85                	lui	s7,0x1
    80001182:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001186:	4605                	li	a2,1
    80001188:	85ca                	mv	a1,s2
    8000118a:	8556                	mv	a0,s5
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	eda080e7          	jalr	-294(ra) # 80001066 <walk>
    80001194:	cd1d                	beqz	a0,800011d2 <mappages+0x84>
    if(*pte & PTE_V)
    80001196:	611c                	ld	a5,0(a0)
    80001198:	8b85                	andi	a5,a5,1
    8000119a:	e785                	bnez	a5,800011c2 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000119c:	80b1                	srli	s1,s1,0xc
    8000119e:	04aa                	slli	s1,s1,0xa
    800011a0:	0164e4b3          	or	s1,s1,s6
    800011a4:	0014e493          	ori	s1,s1,1
    800011a8:	e104                	sd	s1,0(a0)
    if(a == last)
    800011aa:	05390063          	beq	s2,s3,800011ea <mappages+0x9c>
    a += PGSIZE;
    800011ae:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011b0:	bfc9                	j	80001182 <mappages+0x34>
    panic("mappages: size");
    800011b2:	00007517          	auipc	a0,0x7
    800011b6:	f4e50513          	addi	a0,a0,-178 # 80008100 <digits+0xa8>
    800011ba:	fffff097          	auipc	ra,0xfffff
    800011be:	384080e7          	jalr	900(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011c2:	00007517          	auipc	a0,0x7
    800011c6:	f4e50513          	addi	a0,a0,-178 # 80008110 <digits+0xb8>
    800011ca:	fffff097          	auipc	ra,0xfffff
    800011ce:	374080e7          	jalr	884(ra) # 8000053e <panic>
      return -1;
    800011d2:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011d4:	60a6                	ld	ra,72(sp)
    800011d6:	6406                	ld	s0,64(sp)
    800011d8:	74e2                	ld	s1,56(sp)
    800011da:	7942                	ld	s2,48(sp)
    800011dc:	79a2                	ld	s3,40(sp)
    800011de:	7a02                	ld	s4,32(sp)
    800011e0:	6ae2                	ld	s5,24(sp)
    800011e2:	6b42                	ld	s6,16(sp)
    800011e4:	6ba2                	ld	s7,8(sp)
    800011e6:	6161                	addi	sp,sp,80
    800011e8:	8082                	ret
  return 0;
    800011ea:	4501                	li	a0,0
    800011ec:	b7e5                	j	800011d4 <mappages+0x86>

00000000800011ee <kvmmap>:
{
    800011ee:	1141                	addi	sp,sp,-16
    800011f0:	e406                	sd	ra,8(sp)
    800011f2:	e022                	sd	s0,0(sp)
    800011f4:	0800                	addi	s0,sp,16
    800011f6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011f8:	86b2                	mv	a3,a2
    800011fa:	863e                	mv	a2,a5
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f52080e7          	jalr	-174(ra) # 8000114e <mappages>
    80001204:	e509                	bnez	a0,8000120e <kvmmap+0x20>
}
    80001206:	60a2                	ld	ra,8(sp)
    80001208:	6402                	ld	s0,0(sp)
    8000120a:	0141                	addi	sp,sp,16
    8000120c:	8082                	ret
    panic("kvmmap");
    8000120e:	00007517          	auipc	a0,0x7
    80001212:	f1250513          	addi	a0,a0,-238 # 80008120 <digits+0xc8>
    80001216:	fffff097          	auipc	ra,0xfffff
    8000121a:	328080e7          	jalr	808(ra) # 8000053e <panic>

000000008000121e <kvmmake>:
{
    8000121e:	1101                	addi	sp,sp,-32
    80001220:	ec06                	sd	ra,24(sp)
    80001222:	e822                	sd	s0,16(sp)
    80001224:	e426                	sd	s1,8(sp)
    80001226:	e04a                	sd	s2,0(sp)
    80001228:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	918080e7          	jalr	-1768(ra) # 80000b42 <kalloc>
    80001232:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001234:	6605                	lui	a2,0x1
    80001236:	4581                	li	a1,0
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	b36080e7          	jalr	-1226(ra) # 80000d6e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001240:	4719                	li	a4,6
    80001242:	6685                	lui	a3,0x1
    80001244:	10000637          	lui	a2,0x10000
    80001248:	100005b7          	lui	a1,0x10000
    8000124c:	8526                	mv	a0,s1
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	fa0080e7          	jalr	-96(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001256:	4719                	li	a4,6
    80001258:	6685                	lui	a3,0x1
    8000125a:	10001637          	lui	a2,0x10001
    8000125e:	100015b7          	lui	a1,0x10001
    80001262:	8526                	mv	a0,s1
    80001264:	00000097          	auipc	ra,0x0
    80001268:	f8a080e7          	jalr	-118(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000126c:	4719                	li	a4,6
    8000126e:	004006b7          	lui	a3,0x400
    80001272:	0c000637          	lui	a2,0xc000
    80001276:	0c0005b7          	lui	a1,0xc000
    8000127a:	8526                	mv	a0,s1
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f72080e7          	jalr	-142(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001284:	00007917          	auipc	s2,0x7
    80001288:	d7c90913          	addi	s2,s2,-644 # 80008000 <etext>
    8000128c:	4729                	li	a4,10
    8000128e:	80007697          	auipc	a3,0x80007
    80001292:	d7268693          	addi	a3,a3,-654 # 8000 <_entry-0x7fff8000>
    80001296:	4605                	li	a2,1
    80001298:	067e                	slli	a2,a2,0x1f
    8000129a:	85b2                	mv	a1,a2
    8000129c:	8526                	mv	a0,s1
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f50080e7          	jalr	-176(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012a6:	4719                	li	a4,6
    800012a8:	46c5                	li	a3,17
    800012aa:	06ee                	slli	a3,a3,0x1b
    800012ac:	412686b3          	sub	a3,a3,s2
    800012b0:	864a                	mv	a2,s2
    800012b2:	85ca                	mv	a1,s2
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f38080e7          	jalr	-200(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012be:	4729                	li	a4,10
    800012c0:	6685                	lui	a3,0x1
    800012c2:	00006617          	auipc	a2,0x6
    800012c6:	d3e60613          	addi	a2,a2,-706 # 80007000 <_trampoline>
    800012ca:	040005b7          	lui	a1,0x4000
    800012ce:	15fd                	addi	a1,a1,-1
    800012d0:	05b2                	slli	a1,a1,0xc
    800012d2:	8526                	mv	a0,s1
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f1a080e7          	jalr	-230(ra) # 800011ee <kvmmap>
  proc_mapstacks(kpgtbl);
    800012dc:	8526                	mv	a0,s1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	608080e7          	jalr	1544(ra) # 800018e6 <proc_mapstacks>
}
    800012e6:	8526                	mv	a0,s1
    800012e8:	60e2                	ld	ra,24(sp)
    800012ea:	6442                	ld	s0,16(sp)
    800012ec:	64a2                	ld	s1,8(sp)
    800012ee:	6902                	ld	s2,0(sp)
    800012f0:	6105                	addi	sp,sp,32
    800012f2:	8082                	ret

00000000800012f4 <kvminit>:
{
    800012f4:	1141                	addi	sp,sp,-16
    800012f6:	e406                	sd	ra,8(sp)
    800012f8:	e022                	sd	s0,0(sp)
    800012fa:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f22080e7          	jalr	-222(ra) # 8000121e <kvmmake>
    80001304:	00007797          	auipc	a5,0x7
    80001308:	5ea7be23          	sd	a0,1532(a5) # 80008900 <kernel_pagetable>
}
    8000130c:	60a2                	ld	ra,8(sp)
    8000130e:	6402                	ld	s0,0(sp)
    80001310:	0141                	addi	sp,sp,16
    80001312:	8082                	ret

0000000080001314 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001314:	715d                	addi	sp,sp,-80
    80001316:	e486                	sd	ra,72(sp)
    80001318:	e0a2                	sd	s0,64(sp)
    8000131a:	fc26                	sd	s1,56(sp)
    8000131c:	f84a                	sd	s2,48(sp)
    8000131e:	f44e                	sd	s3,40(sp)
    80001320:	f052                	sd	s4,32(sp)
    80001322:	ec56                	sd	s5,24(sp)
    80001324:	e85a                	sd	s6,16(sp)
    80001326:	e45e                	sd	s7,8(sp)
    80001328:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000132a:	03459793          	slli	a5,a1,0x34
    8000132e:	e795                	bnez	a5,8000135a <uvmunmap+0x46>
    80001330:	8a2a                	mv	s4,a0
    80001332:	892e                	mv	s2,a1
    80001334:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001336:	0632                	slli	a2,a2,0xc
    80001338:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133e:	6b05                	lui	s6,0x1
    80001340:	0735e263          	bltu	a1,s3,800013a4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001344:	60a6                	ld	ra,72(sp)
    80001346:	6406                	ld	s0,64(sp)
    80001348:	74e2                	ld	s1,56(sp)
    8000134a:	7942                	ld	s2,48(sp)
    8000134c:	79a2                	ld	s3,40(sp)
    8000134e:	7a02                	ld	s4,32(sp)
    80001350:	6ae2                	ld	s5,24(sp)
    80001352:	6b42                	ld	s6,16(sp)
    80001354:	6ba2                	ld	s7,8(sp)
    80001356:	6161                	addi	sp,sp,80
    80001358:	8082                	ret
    panic("uvmunmap: not aligned");
    8000135a:	00007517          	auipc	a0,0x7
    8000135e:	dce50513          	addi	a0,a0,-562 # 80008128 <digits+0xd0>
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	1dc080e7          	jalr	476(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000136a:	00007517          	auipc	a0,0x7
    8000136e:	dd650513          	addi	a0,a0,-554 # 80008140 <digits+0xe8>
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	1cc080e7          	jalr	460(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000137a:	00007517          	auipc	a0,0x7
    8000137e:	dd650513          	addi	a0,a0,-554 # 80008150 <digits+0xf8>
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	1bc080e7          	jalr	444(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000138a:	00007517          	auipc	a0,0x7
    8000138e:	dde50513          	addi	a0,a0,-546 # 80008168 <digits+0x110>
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	1ac080e7          	jalr	428(ra) # 8000053e <panic>
    *pte = 0;
    8000139a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139e:	995a                	add	s2,s2,s6
    800013a0:	fb3972e3          	bgeu	s2,s3,80001344 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013a4:	4601                	li	a2,0
    800013a6:	85ca                	mv	a1,s2
    800013a8:	8552                	mv	a0,s4
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	cbc080e7          	jalr	-836(ra) # 80001066 <walk>
    800013b2:	84aa                	mv	s1,a0
    800013b4:	d95d                	beqz	a0,8000136a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013b6:	6108                	ld	a0,0(a0)
    800013b8:	00157793          	andi	a5,a0,1
    800013bc:	dfdd                	beqz	a5,8000137a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013be:	3ff57793          	andi	a5,a0,1023
    800013c2:	fd7784e3          	beq	a5,s7,8000138a <uvmunmap+0x76>
    if(do_free){
    800013c6:	fc0a8ae3          	beqz	s5,8000139a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013ca:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013cc:	0532                	slli	a0,a0,0xc
    800013ce:	fffff097          	auipc	ra,0xfffff
    800013d2:	678080e7          	jalr	1656(ra) # 80000a46 <kfree>
    800013d6:	b7d1                	j	8000139a <uvmunmap+0x86>

00000000800013d8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013d8:	1101                	addi	sp,sp,-32
    800013da:	ec06                	sd	ra,24(sp)
    800013dc:	e822                	sd	s0,16(sp)
    800013de:	e426                	sd	s1,8(sp)
    800013e0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	760080e7          	jalr	1888(ra) # 80000b42 <kalloc>
    800013ea:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ec:	c519                	beqz	a0,800013fa <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	97c080e7          	jalr	-1668(ra) # 80000d6e <memset>
  return pagetable;
}
    800013fa:	8526                	mv	a0,s1
    800013fc:	60e2                	ld	ra,24(sp)
    800013fe:	6442                	ld	s0,16(sp)
    80001400:	64a2                	ld	s1,8(sp)
    80001402:	6105                	addi	sp,sp,32
    80001404:	8082                	ret

0000000080001406 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001406:	7179                	addi	sp,sp,-48
    80001408:	f406                	sd	ra,40(sp)
    8000140a:	f022                	sd	s0,32(sp)
    8000140c:	ec26                	sd	s1,24(sp)
    8000140e:	e84a                	sd	s2,16(sp)
    80001410:	e44e                	sd	s3,8(sp)
    80001412:	e052                	sd	s4,0(sp)
    80001414:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001416:	6785                	lui	a5,0x1
    80001418:	04f67863          	bgeu	a2,a5,80001468 <uvmfirst+0x62>
    8000141c:	8a2a                	mv	s4,a0
    8000141e:	89ae                	mv	s3,a1
    80001420:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001422:	fffff097          	auipc	ra,0xfffff
    80001426:	720080e7          	jalr	1824(ra) # 80000b42 <kalloc>
    8000142a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000142c:	6605                	lui	a2,0x1
    8000142e:	4581                	li	a1,0
    80001430:	00000097          	auipc	ra,0x0
    80001434:	93e080e7          	jalr	-1730(ra) # 80000d6e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001438:	4779                	li	a4,30
    8000143a:	86ca                	mv	a3,s2
    8000143c:	6605                	lui	a2,0x1
    8000143e:	4581                	li	a1,0
    80001440:	8552                	mv	a0,s4
    80001442:	00000097          	auipc	ra,0x0
    80001446:	d0c080e7          	jalr	-756(ra) # 8000114e <mappages>
  memmove(mem, src, sz);
    8000144a:	8626                	mv	a2,s1
    8000144c:	85ce                	mv	a1,s3
    8000144e:	854a                	mv	a0,s2
    80001450:	00000097          	auipc	ra,0x0
    80001454:	97a080e7          	jalr	-1670(ra) # 80000dca <memmove>
}
    80001458:	70a2                	ld	ra,40(sp)
    8000145a:	7402                	ld	s0,32(sp)
    8000145c:	64e2                	ld	s1,24(sp)
    8000145e:	6942                	ld	s2,16(sp)
    80001460:	69a2                	ld	s3,8(sp)
    80001462:	6a02                	ld	s4,0(sp)
    80001464:	6145                	addi	sp,sp,48
    80001466:	8082                	ret
    panic("uvmfirst: more than a page");
    80001468:	00007517          	auipc	a0,0x7
    8000146c:	d1850513          	addi	a0,a0,-744 # 80008180 <digits+0x128>
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>

0000000080001478 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001478:	1101                	addi	sp,sp,-32
    8000147a:	ec06                	sd	ra,24(sp)
    8000147c:	e822                	sd	s0,16(sp)
    8000147e:	e426                	sd	s1,8(sp)
    80001480:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001482:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001484:	00b67d63          	bgeu	a2,a1,8000149e <uvmdealloc+0x26>
    80001488:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	17fd                	addi	a5,a5,-1
    8000148e:	00f60733          	add	a4,a2,a5
    80001492:	767d                	lui	a2,0xfffff
    80001494:	8f71                	and	a4,a4,a2
    80001496:	97ae                	add	a5,a5,a1
    80001498:	8ff1                	and	a5,a5,a2
    8000149a:	00f76863          	bltu	a4,a5,800014aa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000149e:	8526                	mv	a0,s1
    800014a0:	60e2                	ld	ra,24(sp)
    800014a2:	6442                	ld	s0,16(sp)
    800014a4:	64a2                	ld	s1,8(sp)
    800014a6:	6105                	addi	sp,sp,32
    800014a8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014aa:	8f99                	sub	a5,a5,a4
    800014ac:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ae:	4685                	li	a3,1
    800014b0:	0007861b          	sext.w	a2,a5
    800014b4:	85ba                	mv	a1,a4
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	e5e080e7          	jalr	-418(ra) # 80001314 <uvmunmap>
    800014be:	b7c5                	j	8000149e <uvmdealloc+0x26>

00000000800014c0 <uvmalloc>:
  if(newsz < oldsz)
    800014c0:	0ab66563          	bltu	a2,a1,8000156a <uvmalloc+0xaa>
{
    800014c4:	7139                	addi	sp,sp,-64
    800014c6:	fc06                	sd	ra,56(sp)
    800014c8:	f822                	sd	s0,48(sp)
    800014ca:	f426                	sd	s1,40(sp)
    800014cc:	f04a                	sd	s2,32(sp)
    800014ce:	ec4e                	sd	s3,24(sp)
    800014d0:	e852                	sd	s4,16(sp)
    800014d2:	e456                	sd	s5,8(sp)
    800014d4:	e05a                	sd	s6,0(sp)
    800014d6:	0080                	addi	s0,sp,64
    800014d8:	8aaa                	mv	s5,a0
    800014da:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014dc:	6985                	lui	s3,0x1
    800014de:	19fd                	addi	s3,s3,-1
    800014e0:	95ce                	add	a1,a1,s3
    800014e2:	79fd                	lui	s3,0xfffff
    800014e4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e8:	08c9f363          	bgeu	s3,a2,8000156e <uvmalloc+0xae>
    800014ec:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014ee:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014f2:	fffff097          	auipc	ra,0xfffff
    800014f6:	650080e7          	jalr	1616(ra) # 80000b42 <kalloc>
    800014fa:	84aa                	mv	s1,a0
    if(mem == 0){
    800014fc:	c51d                	beqz	a0,8000152a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014fe:	6605                	lui	a2,0x1
    80001500:	4581                	li	a1,0
    80001502:	00000097          	auipc	ra,0x0
    80001506:	86c080e7          	jalr	-1940(ra) # 80000d6e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000150a:	875a                	mv	a4,s6
    8000150c:	86a6                	mv	a3,s1
    8000150e:	6605                	lui	a2,0x1
    80001510:	85ca                	mv	a1,s2
    80001512:	8556                	mv	a0,s5
    80001514:	00000097          	auipc	ra,0x0
    80001518:	c3a080e7          	jalr	-966(ra) # 8000114e <mappages>
    8000151c:	e90d                	bnez	a0,8000154e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151e:	6785                	lui	a5,0x1
    80001520:	993e                	add	s2,s2,a5
    80001522:	fd4968e3          	bltu	s2,s4,800014f2 <uvmalloc+0x32>
  return newsz;
    80001526:	8552                	mv	a0,s4
    80001528:	a809                	j	8000153a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000152a:	864e                	mv	a2,s3
    8000152c:	85ca                	mv	a1,s2
    8000152e:	8556                	mv	a0,s5
    80001530:	00000097          	auipc	ra,0x0
    80001534:	f48080e7          	jalr	-184(ra) # 80001478 <uvmdealloc>
      return 0;
    80001538:	4501                	li	a0,0
}
    8000153a:	70e2                	ld	ra,56(sp)
    8000153c:	7442                	ld	s0,48(sp)
    8000153e:	74a2                	ld	s1,40(sp)
    80001540:	7902                	ld	s2,32(sp)
    80001542:	69e2                	ld	s3,24(sp)
    80001544:	6a42                	ld	s4,16(sp)
    80001546:	6aa2                	ld	s5,8(sp)
    80001548:	6b02                	ld	s6,0(sp)
    8000154a:	6121                	addi	sp,sp,64
    8000154c:	8082                	ret
      kfree(mem);
    8000154e:	8526                	mv	a0,s1
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	4f6080e7          	jalr	1270(ra) # 80000a46 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001558:	864e                	mv	a2,s3
    8000155a:	85ca                	mv	a1,s2
    8000155c:	8556                	mv	a0,s5
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	f1a080e7          	jalr	-230(ra) # 80001478 <uvmdealloc>
      return 0;
    80001566:	4501                	li	a0,0
    80001568:	bfc9                	j	8000153a <uvmalloc+0x7a>
    return oldsz;
    8000156a:	852e                	mv	a0,a1
}
    8000156c:	8082                	ret
  return newsz;
    8000156e:	8532                	mv	a0,a2
    80001570:	b7e9                	j	8000153a <uvmalloc+0x7a>

0000000080001572 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001572:	7179                	addi	sp,sp,-48
    80001574:	f406                	sd	ra,40(sp)
    80001576:	f022                	sd	s0,32(sp)
    80001578:	ec26                	sd	s1,24(sp)
    8000157a:	e84a                	sd	s2,16(sp)
    8000157c:	e44e                	sd	s3,8(sp)
    8000157e:	e052                	sd	s4,0(sp)
    80001580:	1800                	addi	s0,sp,48
    80001582:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001584:	84aa                	mv	s1,a0
    80001586:	6905                	lui	s2,0x1
    80001588:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158a:	4985                	li	s3,1
    8000158c:	a821                	j	800015a4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000158e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001590:	0532                	slli	a0,a0,0xc
    80001592:	00000097          	auipc	ra,0x0
    80001596:	fe0080e7          	jalr	-32(ra) # 80001572 <freewalk>
      pagetable[i] = 0;
    8000159a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000159e:	04a1                	addi	s1,s1,8
    800015a0:	03248163          	beq	s1,s2,800015c2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a6:	00f57793          	andi	a5,a0,15
    800015aa:	ff3782e3          	beq	a5,s3,8000158e <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ae:	8905                	andi	a0,a0,1
    800015b0:	d57d                	beqz	a0,8000159e <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b2:	00007517          	auipc	a0,0x7
    800015b6:	bee50513          	addi	a0,a0,-1042 # 800081a0 <digits+0x148>
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    800015c2:	8552                	mv	a0,s4
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	482080e7          	jalr	1154(ra) # 80000a46 <kfree>
}
    800015cc:	70a2                	ld	ra,40(sp)
    800015ce:	7402                	ld	s0,32(sp)
    800015d0:	64e2                	ld	s1,24(sp)
    800015d2:	6942                	ld	s2,16(sp)
    800015d4:	69a2                	ld	s3,8(sp)
    800015d6:	6a02                	ld	s4,0(sp)
    800015d8:	6145                	addi	sp,sp,48
    800015da:	8082                	ret

00000000800015dc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015dc:	1101                	addi	sp,sp,-32
    800015de:	ec06                	sd	ra,24(sp)
    800015e0:	e822                	sd	s0,16(sp)
    800015e2:	e426                	sd	s1,8(sp)
    800015e4:	1000                	addi	s0,sp,32
    800015e6:	84aa                	mv	s1,a0
  if(sz > 0)
    800015e8:	e999                	bnez	a1,800015fe <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ea:	8526                	mv	a0,s1
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	f86080e7          	jalr	-122(ra) # 80001572 <freewalk>
}
    800015f4:	60e2                	ld	ra,24(sp)
    800015f6:	6442                	ld	s0,16(sp)
    800015f8:	64a2                	ld	s1,8(sp)
    800015fa:	6105                	addi	sp,sp,32
    800015fc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015fe:	6605                	lui	a2,0x1
    80001600:	167d                	addi	a2,a2,-1
    80001602:	962e                	add	a2,a2,a1
    80001604:	4685                	li	a3,1
    80001606:	8231                	srli	a2,a2,0xc
    80001608:	4581                	li	a1,0
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	d0a080e7          	jalr	-758(ra) # 80001314 <uvmunmap>
    80001612:	bfe1                	j	800015ea <uvmfree+0xe>

0000000080001614 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001614:	c679                	beqz	a2,800016e2 <uvmcopy+0xce>
{
    80001616:	715d                	addi	sp,sp,-80
    80001618:	e486                	sd	ra,72(sp)
    8000161a:	e0a2                	sd	s0,64(sp)
    8000161c:	fc26                	sd	s1,56(sp)
    8000161e:	f84a                	sd	s2,48(sp)
    80001620:	f44e                	sd	s3,40(sp)
    80001622:	f052                	sd	s4,32(sp)
    80001624:	ec56                	sd	s5,24(sp)
    80001626:	e85a                	sd	s6,16(sp)
    80001628:	e45e                	sd	s7,8(sp)
    8000162a:	0880                	addi	s0,sp,80
    8000162c:	8b2a                	mv	s6,a0
    8000162e:	8aae                	mv	s5,a1
    80001630:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001632:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001634:	4601                	li	a2,0
    80001636:	85ce                	mv	a1,s3
    80001638:	855a                	mv	a0,s6
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	a2c080e7          	jalr	-1492(ra) # 80001066 <walk>
    80001642:	c531                	beqz	a0,8000168e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001644:	6118                	ld	a4,0(a0)
    80001646:	00177793          	andi	a5,a4,1
    8000164a:	cbb1                	beqz	a5,8000169e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000164c:	00a75593          	srli	a1,a4,0xa
    80001650:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001654:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	4ea080e7          	jalr	1258(ra) # 80000b42 <kalloc>
    80001660:	892a                	mv	s2,a0
    80001662:	c939                	beqz	a0,800016b8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001664:	6605                	lui	a2,0x1
    80001666:	85de                	mv	a1,s7
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	762080e7          	jalr	1890(ra) # 80000dca <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001670:	8726                	mv	a4,s1
    80001672:	86ca                	mv	a3,s2
    80001674:	6605                	lui	a2,0x1
    80001676:	85ce                	mv	a1,s3
    80001678:	8556                	mv	a0,s5
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	ad4080e7          	jalr	-1324(ra) # 8000114e <mappages>
    80001682:	e515                	bnez	a0,800016ae <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001684:	6785                	lui	a5,0x1
    80001686:	99be                	add	s3,s3,a5
    80001688:	fb49e6e3          	bltu	s3,s4,80001634 <uvmcopy+0x20>
    8000168c:	a081                	j	800016cc <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000168e:	00007517          	auipc	a0,0x7
    80001692:	b2250513          	addi	a0,a0,-1246 # 800081b0 <digits+0x158>
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	ea8080e7          	jalr	-344(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000169e:	00007517          	auipc	a0,0x7
    800016a2:	b3250513          	addi	a0,a0,-1230 # 800081d0 <digits+0x178>
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	e98080e7          	jalr	-360(ra) # 8000053e <panic>
      kfree(mem);
    800016ae:	854a                	mv	a0,s2
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	396080e7          	jalr	918(ra) # 80000a46 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016b8:	4685                	li	a3,1
    800016ba:	00c9d613          	srli	a2,s3,0xc
    800016be:	4581                	li	a1,0
    800016c0:	8556                	mv	a0,s5
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	c52080e7          	jalr	-942(ra) # 80001314 <uvmunmap>
  return -1;
    800016ca:	557d                	li	a0,-1
}
    800016cc:	60a6                	ld	ra,72(sp)
    800016ce:	6406                	ld	s0,64(sp)
    800016d0:	74e2                	ld	s1,56(sp)
    800016d2:	7942                	ld	s2,48(sp)
    800016d4:	79a2                	ld	s3,40(sp)
    800016d6:	7a02                	ld	s4,32(sp)
    800016d8:	6ae2                	ld	s5,24(sp)
    800016da:	6b42                	ld	s6,16(sp)
    800016dc:	6ba2                	ld	s7,8(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret
  return 0;
    800016e2:	4501                	li	a0,0
}
    800016e4:	8082                	ret

00000000800016e6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016e6:	1141                	addi	sp,sp,-16
    800016e8:	e406                	sd	ra,8(sp)
    800016ea:	e022                	sd	s0,0(sp)
    800016ec:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ee:	4601                	li	a2,0
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	976080e7          	jalr	-1674(ra) # 80001066 <walk>
  if(pte == 0)
    800016f8:	c901                	beqz	a0,80001708 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fa:	611c                	ld	a5,0(a0)
    800016fc:	9bbd                	andi	a5,a5,-17
    800016fe:	e11c                	sd	a5,0(a0)
}
    80001700:	60a2                	ld	ra,8(sp)
    80001702:	6402                	ld	s0,0(sp)
    80001704:	0141                	addi	sp,sp,16
    80001706:	8082                	ret
    panic("uvmclear");
    80001708:	00007517          	auipc	a0,0x7
    8000170c:	ae850513          	addi	a0,a0,-1304 # 800081f0 <digits+0x198>
    80001710:	fffff097          	auipc	ra,0xfffff
    80001714:	e2e080e7          	jalr	-466(ra) # 8000053e <panic>

0000000080001718 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001718:	c6bd                	beqz	a3,80001786 <copyout+0x6e>
{
    8000171a:	715d                	addi	sp,sp,-80
    8000171c:	e486                	sd	ra,72(sp)
    8000171e:	e0a2                	sd	s0,64(sp)
    80001720:	fc26                	sd	s1,56(sp)
    80001722:	f84a                	sd	s2,48(sp)
    80001724:	f44e                	sd	s3,40(sp)
    80001726:	f052                	sd	s4,32(sp)
    80001728:	ec56                	sd	s5,24(sp)
    8000172a:	e85a                	sd	s6,16(sp)
    8000172c:	e45e                	sd	s7,8(sp)
    8000172e:	e062                	sd	s8,0(sp)
    80001730:	0880                	addi	s0,sp,80
    80001732:	8b2a                	mv	s6,a0
    80001734:	8c2e                	mv	s8,a1
    80001736:	8a32                	mv	s4,a2
    80001738:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000173c:	6a85                	lui	s5,0x1
    8000173e:	a015                	j	80001762 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001740:	9562                	add	a0,a0,s8
    80001742:	0004861b          	sext.w	a2,s1
    80001746:	85d2                	mv	a1,s4
    80001748:	41250533          	sub	a0,a0,s2
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	67e080e7          	jalr	1662(ra) # 80000dca <memmove>

    len -= n;
    80001754:	409989b3          	sub	s3,s3,s1
    src += n;
    80001758:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000175e:	02098263          	beqz	s3,80001782 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001762:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001766:	85ca                	mv	a1,s2
    80001768:	855a                	mv	a0,s6
    8000176a:	00000097          	auipc	ra,0x0
    8000176e:	9a2080e7          	jalr	-1630(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001772:	cd01                	beqz	a0,8000178a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001774:	418904b3          	sub	s1,s2,s8
    80001778:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177a:	fc99f3e3          	bgeu	s3,s1,80001740 <copyout+0x28>
    8000177e:	84ce                	mv	s1,s3
    80001780:	b7c1                	j	80001740 <copyout+0x28>
  }
  return 0;
    80001782:	4501                	li	a0,0
    80001784:	a021                	j	8000178c <copyout+0x74>
    80001786:	4501                	li	a0,0
}
    80001788:	8082                	ret
      return -1;
    8000178a:	557d                	li	a0,-1
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6c02                	ld	s8,0(sp)
    800017a0:	6161                	addi	sp,sp,80
    800017a2:	8082                	ret

00000000800017a4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a4:	caa5                	beqz	a3,80001814 <copyin+0x70>
{
    800017a6:	715d                	addi	sp,sp,-80
    800017a8:	e486                	sd	ra,72(sp)
    800017aa:	e0a2                	sd	s0,64(sp)
    800017ac:	fc26                	sd	s1,56(sp)
    800017ae:	f84a                	sd	s2,48(sp)
    800017b0:	f44e                	sd	s3,40(sp)
    800017b2:	f052                	sd	s4,32(sp)
    800017b4:	ec56                	sd	s5,24(sp)
    800017b6:	e85a                	sd	s6,16(sp)
    800017b8:	e45e                	sd	s7,8(sp)
    800017ba:	e062                	sd	s8,0(sp)
    800017bc:	0880                	addi	s0,sp,80
    800017be:	8b2a                	mv	s6,a0
    800017c0:	8a2e                	mv	s4,a1
    800017c2:	8c32                	mv	s8,a2
    800017c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017c8:	6a85                	lui	s5,0x1
    800017ca:	a01d                	j	800017f0 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017cc:	018505b3          	add	a1,a0,s8
    800017d0:	0004861b          	sext.w	a2,s1
    800017d4:	412585b3          	sub	a1,a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	fffff097          	auipc	ra,0xfffff
    800017de:	5f0080e7          	jalr	1520(ra) # 80000dca <memmove>

    len -= n;
    800017e2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017e8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ec:	02098263          	beqz	s3,80001810 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017f0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f4:	85ca                	mv	a1,s2
    800017f6:	855a                	mv	a0,s6
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	914080e7          	jalr	-1772(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001800:	cd01                	beqz	a0,80001818 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001802:	418904b3          	sub	s1,s2,s8
    80001806:	94d6                	add	s1,s1,s5
    if(n > len)
    80001808:	fc99f2e3          	bgeu	s3,s1,800017cc <copyin+0x28>
    8000180c:	84ce                	mv	s1,s3
    8000180e:	bf7d                	j	800017cc <copyin+0x28>
  }
  return 0;
    80001810:	4501                	li	a0,0
    80001812:	a021                	j	8000181a <copyin+0x76>
    80001814:	4501                	li	a0,0
}
    80001816:	8082                	ret
      return -1;
    80001818:	557d                	li	a0,-1
}
    8000181a:	60a6                	ld	ra,72(sp)
    8000181c:	6406                	ld	s0,64(sp)
    8000181e:	74e2                	ld	s1,56(sp)
    80001820:	7942                	ld	s2,48(sp)
    80001822:	79a2                	ld	s3,40(sp)
    80001824:	7a02                	ld	s4,32(sp)
    80001826:	6ae2                	ld	s5,24(sp)
    80001828:	6b42                	ld	s6,16(sp)
    8000182a:	6ba2                	ld	s7,8(sp)
    8000182c:	6c02                	ld	s8,0(sp)
    8000182e:	6161                	addi	sp,sp,80
    80001830:	8082                	ret

0000000080001832 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001832:	c6c5                	beqz	a3,800018da <copyinstr+0xa8>
{
    80001834:	715d                	addi	sp,sp,-80
    80001836:	e486                	sd	ra,72(sp)
    80001838:	e0a2                	sd	s0,64(sp)
    8000183a:	fc26                	sd	s1,56(sp)
    8000183c:	f84a                	sd	s2,48(sp)
    8000183e:	f44e                	sd	s3,40(sp)
    80001840:	f052                	sd	s4,32(sp)
    80001842:	ec56                	sd	s5,24(sp)
    80001844:	e85a                	sd	s6,16(sp)
    80001846:	e45e                	sd	s7,8(sp)
    80001848:	0880                	addi	s0,sp,80
    8000184a:	8a2a                	mv	s4,a0
    8000184c:	8b2e                	mv	s6,a1
    8000184e:	8bb2                	mv	s7,a2
    80001850:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001852:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001854:	6985                	lui	s3,0x1
    80001856:	a035                	j	80001882 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001858:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000185e:	0017b793          	seqz	a5,a5
    80001862:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001866:	60a6                	ld	ra,72(sp)
    80001868:	6406                	ld	s0,64(sp)
    8000186a:	74e2                	ld	s1,56(sp)
    8000186c:	7942                	ld	s2,48(sp)
    8000186e:	79a2                	ld	s3,40(sp)
    80001870:	7a02                	ld	s4,32(sp)
    80001872:	6ae2                	ld	s5,24(sp)
    80001874:	6b42                	ld	s6,16(sp)
    80001876:	6ba2                	ld	s7,8(sp)
    80001878:	6161                	addi	sp,sp,80
    8000187a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001880:	c8a9                	beqz	s1,800018d2 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001882:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001886:	85ca                	mv	a1,s2
    80001888:	8552                	mv	a0,s4
    8000188a:	00000097          	auipc	ra,0x0
    8000188e:	882080e7          	jalr	-1918(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001892:	c131                	beqz	a0,800018d6 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001894:	41790833          	sub	a6,s2,s7
    80001898:	984e                	add	a6,a6,s3
    if(n > max)
    8000189a:	0104f363          	bgeu	s1,a6,800018a0 <copyinstr+0x6e>
    8000189e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a0:	955e                	add	a0,a0,s7
    800018a2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a6:	fc080be3          	beqz	a6,8000187c <copyinstr+0x4a>
    800018aa:	985a                	add	a6,a6,s6
    800018ac:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ae:	41650633          	sub	a2,a0,s6
    800018b2:	14fd                	addi	s1,s1,-1
    800018b4:	9b26                	add	s6,s6,s1
    800018b6:	00f60733          	add	a4,a2,a5
    800018ba:	00074703          	lbu	a4,0(a4)
    800018be:	df49                	beqz	a4,80001858 <copyinstr+0x26>
        *dst = *p;
    800018c0:	00e78023          	sb	a4,0(a5)
      --max;
    800018c4:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018c8:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ca:	ff0796e3          	bne	a5,a6,800018b6 <copyinstr+0x84>
      dst++;
    800018ce:	8b42                	mv	s6,a6
    800018d0:	b775                	j	8000187c <copyinstr+0x4a>
    800018d2:	4781                	li	a5,0
    800018d4:	b769                	j	8000185e <copyinstr+0x2c>
      return -1;
    800018d6:	557d                	li	a0,-1
    800018d8:	b779                	j	80001866 <copyinstr+0x34>
  int got_null = 0;
    800018da:	4781                	li	a5,0
  if(got_null){
    800018dc:	0017b793          	seqz	a5,a5
    800018e0:	40f00533          	neg	a0,a5
}
    800018e4:	8082                	ret

00000000800018e6 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
    800018fa:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fc:	0000f497          	auipc	s1,0xf
    80001900:	6b448493          	addi	s1,s1,1716 # 80010fb0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001904:	8b26                	mv	s6,s1
    80001906:	00006a97          	auipc	s5,0x6
    8000190a:	6faa8a93          	addi	s5,s5,1786 # 80008000 <etext>
    8000190e:	04000937          	lui	s2,0x4000
    80001912:	197d                	addi	s2,s2,-1
    80001914:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001916:	00015a17          	auipc	s4,0x15
    8000191a:	09aa0a13          	addi	s4,s4,154 # 800169b0 <tickslock>
    char *pa = kalloc();
    8000191e:	fffff097          	auipc	ra,0xfffff
    80001922:	224080e7          	jalr	548(ra) # 80000b42 <kalloc>
    80001926:	862a                	mv	a2,a0
    if(pa == 0)
    80001928:	c131                	beqz	a0,8000196c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000192a:	416485b3          	sub	a1,s1,s6
    8000192e:	858d                	srai	a1,a1,0x3
    80001930:	000ab783          	ld	a5,0(s5)
    80001934:	02f585b3          	mul	a1,a1,a5
    80001938:	2585                	addiw	a1,a1,1
    8000193a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000193e:	4719                	li	a4,6
    80001940:	6685                	lui	a3,0x1
    80001942:	40b905b3          	sub	a1,s2,a1
    80001946:	854e                	mv	a0,s3
    80001948:	00000097          	auipc	ra,0x0
    8000194c:	8a6080e7          	jalr	-1882(ra) # 800011ee <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001950:	16848493          	addi	s1,s1,360
    80001954:	fd4495e3          	bne	s1,s4,8000191e <proc_mapstacks+0x38>
  }
}
    80001958:	70e2                	ld	ra,56(sp)
    8000195a:	7442                	ld	s0,48(sp)
    8000195c:	74a2                	ld	s1,40(sp)
    8000195e:	7902                	ld	s2,32(sp)
    80001960:	69e2                	ld	s3,24(sp)
    80001962:	6a42                	ld	s4,16(sp)
    80001964:	6aa2                	ld	s5,8(sp)
    80001966:	6b02                	ld	s6,0(sp)
    80001968:	6121                	addi	sp,sp,64
    8000196a:	8082                	ret
      panic("kalloc");
    8000196c:	00007517          	auipc	a0,0x7
    80001970:	89450513          	addi	a0,a0,-1900 # 80008200 <digits+0x1a8>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	bca080e7          	jalr	-1078(ra) # 8000053e <panic>

000000008000197c <procinit>:

// initialize the proc table.
void
procinit(void)
{
    8000197c:	7139                	addi	sp,sp,-64
    8000197e:	fc06                	sd	ra,56(sp)
    80001980:	f822                	sd	s0,48(sp)
    80001982:	f426                	sd	s1,40(sp)
    80001984:	f04a                	sd	s2,32(sp)
    80001986:	ec4e                	sd	s3,24(sp)
    80001988:	e852                	sd	s4,16(sp)
    8000198a:	e456                	sd	s5,8(sp)
    8000198c:	e05a                	sd	s6,0(sp)
    8000198e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001990:	00007597          	auipc	a1,0x7
    80001994:	87858593          	addi	a1,a1,-1928 # 80008208 <digits+0x1b0>
    80001998:	0000f517          	auipc	a0,0xf
    8000199c:	1e850513          	addi	a0,a0,488 # 80010b80 <pid_lock>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	202080e7          	jalr	514(ra) # 80000ba2 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019a8:	00007597          	auipc	a1,0x7
    800019ac:	86858593          	addi	a1,a1,-1944 # 80008210 <digits+0x1b8>
    800019b0:	0000f517          	auipc	a0,0xf
    800019b4:	1e850513          	addi	a0,a0,488 # 80010b98 <wait_lock>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	1ea080e7          	jalr	490(ra) # 80000ba2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c0:	0000f497          	auipc	s1,0xf
    800019c4:	5f048493          	addi	s1,s1,1520 # 80010fb0 <proc>
      initlock(&p->lock, "proc");
    800019c8:	00007b17          	auipc	s6,0x7
    800019cc:	858b0b13          	addi	s6,s6,-1960 # 80008220 <digits+0x1c8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    800019d0:	8aa6                	mv	s5,s1
    800019d2:	00006a17          	auipc	s4,0x6
    800019d6:	62ea0a13          	addi	s4,s4,1582 # 80008000 <etext>
    800019da:	04000937          	lui	s2,0x4000
    800019de:	197d                	addi	s2,s2,-1
    800019e0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e2:	00015997          	auipc	s3,0x15
    800019e6:	fce98993          	addi	s3,s3,-50 # 800169b0 <tickslock>
      initlock(&p->lock, "proc");
    800019ea:	85da                	mv	a1,s6
    800019ec:	8526                	mv	a0,s1
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	1b4080e7          	jalr	436(ra) # 80000ba2 <initlock>
      p->state = UNUSED;
    800019f6:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019fa:	415487b3          	sub	a5,s1,s5
    800019fe:	878d                	srai	a5,a5,0x3
    80001a00:	000a3703          	ld	a4,0(s4)
    80001a04:	02e787b3          	mul	a5,a5,a4
    80001a08:	2785                	addiw	a5,a5,1
    80001a0a:	00d7979b          	slliw	a5,a5,0xd
    80001a0e:	40f907b3          	sub	a5,s2,a5
    80001a12:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a14:	16848493          	addi	s1,s1,360
    80001a18:	fd3499e3          	bne	s1,s3,800019ea <procinit+0x6e>
  }
}
    80001a1c:	70e2                	ld	ra,56(sp)
    80001a1e:	7442                	ld	s0,48(sp)
    80001a20:	74a2                	ld	s1,40(sp)
    80001a22:	7902                	ld	s2,32(sp)
    80001a24:	69e2                	ld	s3,24(sp)
    80001a26:	6a42                	ld	s4,16(sp)
    80001a28:	6aa2                	ld	s5,8(sp)
    80001a2a:	6b02                	ld	s6,0(sp)
    80001a2c:	6121                	addi	sp,sp,64
    80001a2e:	8082                	ret

0000000080001a30 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a30:	1141                	addi	sp,sp,-16
    80001a32:	e422                	sd	s0,8(sp)
    80001a34:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a36:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a38:	2501                	sext.w	a0,a0
    80001a3a:	6422                	ld	s0,8(sp)
    80001a3c:	0141                	addi	sp,sp,16
    80001a3e:	8082                	ret

0000000080001a40 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a40:	1141                	addi	sp,sp,-16
    80001a42:	e422                	sd	s0,8(sp)
    80001a44:	0800                	addi	s0,sp,16
    80001a46:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a48:	2781                	sext.w	a5,a5
    80001a4a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a4c:	0000f517          	auipc	a0,0xf
    80001a50:	16450513          	addi	a0,a0,356 # 80010bb0 <cpus>
    80001a54:	953e                	add	a0,a0,a5
    80001a56:	6422                	ld	s0,8(sp)
    80001a58:	0141                	addi	sp,sp,16
    80001a5a:	8082                	ret

0000000080001a5c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a5c:	1101                	addi	sp,sp,-32
    80001a5e:	ec06                	sd	ra,24(sp)
    80001a60:	e822                	sd	s0,16(sp)
    80001a62:	e426                	sd	s1,8(sp)
    80001a64:	1000                	addi	s0,sp,32
  push_off();
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	184080e7          	jalr	388(ra) # 80000bea <push_off>
    80001a6e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a70:	2781                	sext.w	a5,a5
    80001a72:	079e                	slli	a5,a5,0x7
    80001a74:	0000f717          	auipc	a4,0xf
    80001a78:	10c70713          	addi	a4,a4,268 # 80010b80 <pid_lock>
    80001a7c:	97ba                	add	a5,a5,a4
    80001a7e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	240080e7          	jalr	576(ra) # 80000cc0 <pop_off>
  return p;
}
    80001a88:	8526                	mv	a0,s1
    80001a8a:	60e2                	ld	ra,24(sp)
    80001a8c:	6442                	ld	s0,16(sp)
    80001a8e:	64a2                	ld	s1,8(sp)
    80001a90:	6105                	addi	sp,sp,32
    80001a92:	8082                	ret

0000000080001a94 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a94:	1141                	addi	sp,sp,-16
    80001a96:	e406                	sd	ra,8(sp)
    80001a98:	e022                	sd	s0,0(sp)
    80001a9a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	fc0080e7          	jalr	-64(ra) # 80001a5c <myproc>
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	27c080e7          	jalr	636(ra) # 80000d20 <release>

  if (first) {
    80001aac:	00007797          	auipc	a5,0x7
    80001ab0:	dc47a783          	lw	a5,-572(a5) # 80008870 <first.1>
    80001ab4:	eb89                	bnez	a5,80001ac6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ab6:	00001097          	auipc	ra,0x1
    80001aba:	c5a080e7          	jalr	-934(ra) # 80002710 <usertrapret>
}
    80001abe:	60a2                	ld	ra,8(sp)
    80001ac0:	6402                	ld	s0,0(sp)
    80001ac2:	0141                	addi	sp,sp,16
    80001ac4:	8082                	ret
    first = 0;
    80001ac6:	00007797          	auipc	a5,0x7
    80001aca:	da07a523          	sw	zero,-598(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001ace:	4505                	li	a0,1
    80001ad0:	00002097          	auipc	ra,0x2
    80001ad4:	a0c080e7          	jalr	-1524(ra) # 800034dc <fsinit>
    80001ad8:	bff9                	j	80001ab6 <forkret+0x22>

0000000080001ada <allocpid>:
{
    80001ada:	1101                	addi	sp,sp,-32
    80001adc:	ec06                	sd	ra,24(sp)
    80001ade:	e822                	sd	s0,16(sp)
    80001ae0:	e426                	sd	s1,8(sp)
    80001ae2:	e04a                	sd	s2,0(sp)
    80001ae4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ae6:	0000f917          	auipc	s2,0xf
    80001aea:	09a90913          	addi	s2,s2,154 # 80010b80 <pid_lock>
    80001aee:	854a                	mv	a0,s2
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	146080e7          	jalr	326(ra) # 80000c36 <acquire>
  pid = nextpid;
    80001af8:	00007797          	auipc	a5,0x7
    80001afc:	d7c78793          	addi	a5,a5,-644 # 80008874 <nextpid>
    80001b00:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b02:	0014871b          	addiw	a4,s1,1
    80001b06:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b08:	854a                	mv	a0,s2
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	216080e7          	jalr	534(ra) # 80000d20 <release>
}
    80001b12:	8526                	mv	a0,s1
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6902                	ld	s2,0(sp)
    80001b1c:	6105                	addi	sp,sp,32
    80001b1e:	8082                	ret

0000000080001b20 <proc_pagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b2e:	00000097          	auipc	ra,0x0
    80001b32:	8aa080e7          	jalr	-1878(ra) # 800013d8 <uvmcreate>
    80001b36:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b38:	c121                	beqz	a0,80001b78 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b3a:	4729                	li	a4,10
    80001b3c:	00005697          	auipc	a3,0x5
    80001b40:	4c468693          	addi	a3,a3,1220 # 80007000 <_trampoline>
    80001b44:	6605                	lui	a2,0x1
    80001b46:	040005b7          	lui	a1,0x4000
    80001b4a:	15fd                	addi	a1,a1,-1
    80001b4c:	05b2                	slli	a1,a1,0xc
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	600080e7          	jalr	1536(ra) # 8000114e <mappages>
    80001b56:	02054863          	bltz	a0,80001b86 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b5a:	4719                	li	a4,6
    80001b5c:	05893683          	ld	a3,88(s2)
    80001b60:	6605                	lui	a2,0x1
    80001b62:	020005b7          	lui	a1,0x2000
    80001b66:	15fd                	addi	a1,a1,-1
    80001b68:	05b6                	slli	a1,a1,0xd
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	5e2080e7          	jalr	1506(ra) # 8000114e <mappages>
    80001b74:	02054163          	bltz	a0,80001b96 <proc_pagetable+0x76>
}
    80001b78:	8526                	mv	a0,s1
    80001b7a:	60e2                	ld	ra,24(sp)
    80001b7c:	6442                	ld	s0,16(sp)
    80001b7e:	64a2                	ld	s1,8(sp)
    80001b80:	6902                	ld	s2,0(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret
    uvmfree(pagetable, 0);
    80001b86:	4581                	li	a1,0
    80001b88:	8526                	mv	a0,s1
    80001b8a:	00000097          	auipc	ra,0x0
    80001b8e:	a52080e7          	jalr	-1454(ra) # 800015dc <uvmfree>
    return 0;
    80001b92:	4481                	li	s1,0
    80001b94:	b7d5                	j	80001b78 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b96:	4681                	li	a3,0
    80001b98:	4605                	li	a2,1
    80001b9a:	040005b7          	lui	a1,0x4000
    80001b9e:	15fd                	addi	a1,a1,-1
    80001ba0:	05b2                	slli	a1,a1,0xc
    80001ba2:	8526                	mv	a0,s1
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	770080e7          	jalr	1904(ra) # 80001314 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bac:	4581                	li	a1,0
    80001bae:	8526                	mv	a0,s1
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	a2c080e7          	jalr	-1492(ra) # 800015dc <uvmfree>
    return 0;
    80001bb8:	4481                	li	s1,0
    80001bba:	bf7d                	j	80001b78 <proc_pagetable+0x58>

0000000080001bbc <proc_freepagetable>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
    80001bc8:	84aa                	mv	s1,a0
    80001bca:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bcc:	4681                	li	a3,0
    80001bce:	4605                	li	a2,1
    80001bd0:	040005b7          	lui	a1,0x4000
    80001bd4:	15fd                	addi	a1,a1,-1
    80001bd6:	05b2                	slli	a1,a1,0xc
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	73c080e7          	jalr	1852(ra) # 80001314 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001be0:	4681                	li	a3,0
    80001be2:	4605                	li	a2,1
    80001be4:	020005b7          	lui	a1,0x2000
    80001be8:	15fd                	addi	a1,a1,-1
    80001bea:	05b6                	slli	a1,a1,0xd
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	726080e7          	jalr	1830(ra) # 80001314 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bf6:	85ca                	mv	a1,s2
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	9e2080e7          	jalr	-1566(ra) # 800015dc <uvmfree>
}
    80001c02:	60e2                	ld	ra,24(sp)
    80001c04:	6442                	ld	s0,16(sp)
    80001c06:	64a2                	ld	s1,8(sp)
    80001c08:	6902                	ld	s2,0(sp)
    80001c0a:	6105                	addi	sp,sp,32
    80001c0c:	8082                	ret

0000000080001c0e <freeproc>:
{
    80001c0e:	1101                	addi	sp,sp,-32
    80001c10:	ec06                	sd	ra,24(sp)
    80001c12:	e822                	sd	s0,16(sp)
    80001c14:	e426                	sd	s1,8(sp)
    80001c16:	1000                	addi	s0,sp,32
    80001c18:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c1a:	6d28                	ld	a0,88(a0)
    80001c1c:	c509                	beqz	a0,80001c26 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	e28080e7          	jalr	-472(ra) # 80000a46 <kfree>
  p->trapframe = 0;
    80001c26:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c2a:	68a8                	ld	a0,80(s1)
    80001c2c:	c511                	beqz	a0,80001c38 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c2e:	64ac                	ld	a1,72(s1)
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	f8c080e7          	jalr	-116(ra) # 80001bbc <proc_freepagetable>
  p->pagetable = 0;
    80001c38:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c3c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c40:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c44:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c48:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c4c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c50:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c54:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c58:	0004ac23          	sw	zero,24(s1)
}
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret

0000000080001c66 <allocproc>:
{
    80001c66:	1101                	addi	sp,sp,-32
    80001c68:	ec06                	sd	ra,24(sp)
    80001c6a:	e822                	sd	s0,16(sp)
    80001c6c:	e426                	sd	s1,8(sp)
    80001c6e:	e04a                	sd	s2,0(sp)
    80001c70:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c72:	0000f497          	auipc	s1,0xf
    80001c76:	33e48493          	addi	s1,s1,830 # 80010fb0 <proc>
    80001c7a:	00015917          	auipc	s2,0x15
    80001c7e:	d3690913          	addi	s2,s2,-714 # 800169b0 <tickslock>
    acquire(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	fb2080e7          	jalr	-78(ra) # 80000c36 <acquire>
    if(p->state == UNUSED) {
    80001c8c:	4c9c                	lw	a5,24(s1)
    80001c8e:	cf81                	beqz	a5,80001ca6 <allocproc+0x40>
      release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	08e080e7          	jalr	142(ra) # 80000d20 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9a:	16848493          	addi	s1,s1,360
    80001c9e:	ff2492e3          	bne	s1,s2,80001c82 <allocproc+0x1c>
  return 0;
    80001ca2:	4481                	li	s1,0
    80001ca4:	a889                	j	80001cf6 <allocproc+0x90>
  p->pid = allocpid();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e34080e7          	jalr	-460(ra) # 80001ada <allocpid>
    80001cae:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cb0:	4785                	li	a5,1
    80001cb2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	e8e080e7          	jalr	-370(ra) # 80000b42 <kalloc>
    80001cbc:	892a                	mv	s2,a0
    80001cbe:	eca8                	sd	a0,88(s1)
    80001cc0:	c131                	beqz	a0,80001d04 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	e5c080e7          	jalr	-420(ra) # 80001b20 <proc_pagetable>
    80001ccc:	892a                	mv	s2,a0
    80001cce:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cd0:	c531                	beqz	a0,80001d1c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cd2:	07000613          	li	a2,112
    80001cd6:	4581                	li	a1,0
    80001cd8:	06048513          	addi	a0,s1,96
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	092080e7          	jalr	146(ra) # 80000d6e <memset>
  p->context.ra = (uint64)forkret;
    80001ce4:	00000797          	auipc	a5,0x0
    80001ce8:	db078793          	addi	a5,a5,-592 # 80001a94 <forkret>
    80001cec:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cee:	60bc                	ld	a5,64(s1)
    80001cf0:	6705                	lui	a4,0x1
    80001cf2:	97ba                	add	a5,a5,a4
    80001cf4:	f4bc                	sd	a5,104(s1)
}
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	60e2                	ld	ra,24(sp)
    80001cfa:	6442                	ld	s0,16(sp)
    80001cfc:	64a2                	ld	s1,8(sp)
    80001cfe:	6902                	ld	s2,0(sp)
    80001d00:	6105                	addi	sp,sp,32
    80001d02:	8082                	ret
    freeproc(p);
    80001d04:	8526                	mv	a0,s1
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	f08080e7          	jalr	-248(ra) # 80001c0e <freeproc>
    release(&p->lock);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	010080e7          	jalr	16(ra) # 80000d20 <release>
    return 0;
    80001d18:	84ca                	mv	s1,s2
    80001d1a:	bff1                	j	80001cf6 <allocproc+0x90>
    freeproc(p);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	ef0080e7          	jalr	-272(ra) # 80001c0e <freeproc>
    release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	ff8080e7          	jalr	-8(ra) # 80000d20 <release>
    return 0;
    80001d30:	84ca                	mv	s1,s2
    80001d32:	b7d1                	j	80001cf6 <allocproc+0x90>

0000000080001d34 <userinit>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	f28080e7          	jalr	-216(ra) # 80001c66 <allocproc>
    80001d46:	84aa                	mv	s1,a0
  initproc = p;
    80001d48:	00007797          	auipc	a5,0x7
    80001d4c:	bca7b023          	sd	a0,-1088(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d50:	03400613          	li	a2,52
    80001d54:	00007597          	auipc	a1,0x7
    80001d58:	b2c58593          	addi	a1,a1,-1236 # 80008880 <initcode>
    80001d5c:	6928                	ld	a0,80(a0)
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	6a8080e7          	jalr	1704(ra) # 80001406 <uvmfirst>
  p->sz = PGSIZE;
    80001d66:	6785                	lui	a5,0x1
    80001d68:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d6a:	6cb8                	ld	a4,88(s1)
    80001d6c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d70:	6cb8                	ld	a4,88(s1)
    80001d72:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d74:	4641                	li	a2,16
    80001d76:	00006597          	auipc	a1,0x6
    80001d7a:	4b258593          	addi	a1,a1,1202 # 80008228 <digits+0x1d0>
    80001d7e:	15848513          	addi	a0,s1,344
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	136080e7          	jalr	310(ra) # 80000eb8 <safestrcpy>
  p->cwd = namei("/");
    80001d8a:	00006517          	auipc	a0,0x6
    80001d8e:	4ae50513          	addi	a0,a0,1198 # 80008238 <digits+0x1e0>
    80001d92:	00002097          	auipc	ra,0x2
    80001d96:	16c080e7          	jalr	364(ra) # 80003efe <namei>
    80001d9a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d9e:	478d                	li	a5,3
    80001da0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	f7c080e7          	jalr	-132(ra) # 80000d20 <release>
}
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6105                	addi	sp,sp,32
    80001db4:	8082                	ret

0000000080001db6 <growproc>:
{
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	e04a                	sd	s2,0(sp)
    80001dc0:	1000                	addi	s0,sp,32
    80001dc2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	c98080e7          	jalr	-872(ra) # 80001a5c <myproc>
    80001dcc:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dce:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dd0:	01204c63          	bgtz	s2,80001de8 <growproc+0x32>
  } else if(n < 0){
    80001dd4:	02094663          	bltz	s2,80001e00 <growproc+0x4a>
  p->sz = sz;
    80001dd8:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dda:	4501                	li	a0,0
}
    80001ddc:	60e2                	ld	ra,24(sp)
    80001dde:	6442                	ld	s0,16(sp)
    80001de0:	64a2                	ld	s1,8(sp)
    80001de2:	6902                	ld	s2,0(sp)
    80001de4:	6105                	addi	sp,sp,32
    80001de6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001de8:	4691                	li	a3,4
    80001dea:	00b90633          	add	a2,s2,a1
    80001dee:	6928                	ld	a0,80(a0)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	6d0080e7          	jalr	1744(ra) # 800014c0 <uvmalloc>
    80001df8:	85aa                	mv	a1,a0
    80001dfa:	fd79                	bnez	a0,80001dd8 <growproc+0x22>
      return -1;
    80001dfc:	557d                	li	a0,-1
    80001dfe:	bff9                	j	80001ddc <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e00:	00b90633          	add	a2,s2,a1
    80001e04:	6928                	ld	a0,80(a0)
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	672080e7          	jalr	1650(ra) # 80001478 <uvmdealloc>
    80001e0e:	85aa                	mv	a1,a0
    80001e10:	b7e1                	j	80001dd8 <growproc+0x22>

0000000080001e12 <fork>:
{
    80001e12:	7139                	addi	sp,sp,-64
    80001e14:	fc06                	sd	ra,56(sp)
    80001e16:	f822                	sd	s0,48(sp)
    80001e18:	f426                	sd	s1,40(sp)
    80001e1a:	f04a                	sd	s2,32(sp)
    80001e1c:	ec4e                	sd	s3,24(sp)
    80001e1e:	e852                	sd	s4,16(sp)
    80001e20:	e456                	sd	s5,8(sp)
    80001e22:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	c38080e7          	jalr	-968(ra) # 80001a5c <myproc>
    80001e2c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	e38080e7          	jalr	-456(ra) # 80001c66 <allocproc>
    80001e36:	10050c63          	beqz	a0,80001f4e <fork+0x13c>
    80001e3a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e3c:	048ab603          	ld	a2,72(s5)
    80001e40:	692c                	ld	a1,80(a0)
    80001e42:	050ab503          	ld	a0,80(s5)
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	7ce080e7          	jalr	1998(ra) # 80001614 <uvmcopy>
    80001e4e:	04054863          	bltz	a0,80001e9e <fork+0x8c>
  np->sz = p->sz;
    80001e52:	048ab783          	ld	a5,72(s5)
    80001e56:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e5a:	058ab683          	ld	a3,88(s5)
    80001e5e:	87b6                	mv	a5,a3
    80001e60:	058a3703          	ld	a4,88(s4)
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
    80001e88:	058a3783          	ld	a5,88(s4)
    80001e8c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e90:	0d0a8493          	addi	s1,s5,208
    80001e94:	0d0a0913          	addi	s2,s4,208
    80001e98:	150a8993          	addi	s3,s5,336
    80001e9c:	a00d                	j	80001ebe <fork+0xac>
    freeproc(np);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	d6e080e7          	jalr	-658(ra) # 80001c0e <freeproc>
    release(&np->lock);
    80001ea8:	8552                	mv	a0,s4
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	e76080e7          	jalr	-394(ra) # 80000d20 <release>
    return -1;
    80001eb2:	597d                	li	s2,-1
    80001eb4:	a059                	j	80001f3a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eb6:	04a1                	addi	s1,s1,8
    80001eb8:	0921                	addi	s2,s2,8
    80001eba:	01348b63          	beq	s1,s3,80001ed0 <fork+0xbe>
    if(p->ofile[i])
    80001ebe:	6088                	ld	a0,0(s1)
    80001ec0:	d97d                	beqz	a0,80001eb6 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec2:	00002097          	auipc	ra,0x2
    80001ec6:	6d2080e7          	jalr	1746(ra) # 80004594 <filedup>
    80001eca:	00a93023          	sd	a0,0(s2)
    80001ece:	b7e5                	j	80001eb6 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ed0:	150ab503          	ld	a0,336(s5)
    80001ed4:	00002097          	auipc	ra,0x2
    80001ed8:	846080e7          	jalr	-1978(ra) # 8000371a <idup>
    80001edc:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ee0:	4641                	li	a2,16
    80001ee2:	158a8593          	addi	a1,s5,344
    80001ee6:	158a0513          	addi	a0,s4,344
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	fce080e7          	jalr	-50(ra) # 80000eb8 <safestrcpy>
  pid = np->pid;
    80001ef2:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ef6:	8552                	mv	a0,s4
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	e28080e7          	jalr	-472(ra) # 80000d20 <release>
  acquire(&wait_lock);
    80001f00:	0000f497          	auipc	s1,0xf
    80001f04:	c9848493          	addi	s1,s1,-872 # 80010b98 <wait_lock>
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	d2c080e7          	jalr	-724(ra) # 80000c36 <acquire>
  np->parent = p;
    80001f12:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	e08080e7          	jalr	-504(ra) # 80000d20 <release>
  acquire(&np->lock);
    80001f20:	8552                	mv	a0,s4
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	d14080e7          	jalr	-748(ra) # 80000c36 <acquire>
  np->state = RUNNABLE;
    80001f2a:	478d                	li	a5,3
    80001f2c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f30:	8552                	mv	a0,s4
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	dee080e7          	jalr	-530(ra) # 80000d20 <release>
}
    80001f3a:	854a                	mv	a0,s2
    80001f3c:	70e2                	ld	ra,56(sp)
    80001f3e:	7442                	ld	s0,48(sp)
    80001f40:	74a2                	ld	s1,40(sp)
    80001f42:	7902                	ld	s2,32(sp)
    80001f44:	69e2                	ld	s3,24(sp)
    80001f46:	6a42                	ld	s4,16(sp)
    80001f48:	6aa2                	ld	s5,8(sp)
    80001f4a:	6121                	addi	sp,sp,64
    80001f4c:	8082                	ret
    return -1;
    80001f4e:	597d                	li	s2,-1
    80001f50:	b7ed                	j	80001f3a <fork+0x128>

0000000080001f52 <scheduler>:
{
    80001f52:	7139                	addi	sp,sp,-64
    80001f54:	fc06                	sd	ra,56(sp)
    80001f56:	f822                	sd	s0,48(sp)
    80001f58:	f426                	sd	s1,40(sp)
    80001f5a:	f04a                	sd	s2,32(sp)
    80001f5c:	ec4e                	sd	s3,24(sp)
    80001f5e:	e852                	sd	s4,16(sp)
    80001f60:	e456                	sd	s5,8(sp)
    80001f62:	e05a                	sd	s6,0(sp)
    80001f64:	0080                	addi	s0,sp,64
    80001f66:	8792                	mv	a5,tp
  int id = r_tp();
    80001f68:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f6a:	00779a93          	slli	s5,a5,0x7
    80001f6e:	0000f717          	auipc	a4,0xf
    80001f72:	c1270713          	addi	a4,a4,-1006 # 80010b80 <pid_lock>
    80001f76:	9756                	add	a4,a4,s5
    80001f78:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	c3c70713          	addi	a4,a4,-964 # 80010bb8 <cpus+0x8>
    80001f84:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f86:	498d                	li	s3,3
        p->state = RUNNING;
    80001f88:	4b11                	li	s6,4
        c->proc = p;
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	0000fa17          	auipc	s4,0xf
    80001f90:	bf4a0a13          	addi	s4,s4,-1036 # 80010b80 <pid_lock>
    80001f94:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f96:	00015917          	auipc	s2,0x15
    80001f9a:	a1a90913          	addi	s2,s2,-1510 # 800169b0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fa2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa6:	10079073          	csrw	sstatus,a5
    80001faa:	0000f497          	auipc	s1,0xf
    80001fae:	00648493          	addi	s1,s1,6 # 80010fb0 <proc>
    80001fb2:	a811                	j	80001fc6 <scheduler+0x74>
      release(&p->lock);
    80001fb4:	8526                	mv	a0,s1
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	d6a080e7          	jalr	-662(ra) # 80000d20 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fbe:	16848493          	addi	s1,s1,360
    80001fc2:	fd248ee3          	beq	s1,s2,80001f9e <scheduler+0x4c>
      acquire(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	c6e080e7          	jalr	-914(ra) # 80000c36 <acquire>
      if(p->state == RUNNABLE) {
    80001fd0:	4c9c                	lw	a5,24(s1)
    80001fd2:	ff3791e3          	bne	a5,s3,80001fb4 <scheduler+0x62>
        p->state = RUNNING;
    80001fd6:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fda:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fde:	06048593          	addi	a1,s1,96
    80001fe2:	8556                	mv	a0,s5
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	682080e7          	jalr	1666(ra) # 80002666 <swtch>
        c->proc = 0;
    80001fec:	020a3823          	sd	zero,48(s4)
    80001ff0:	b7d1                	j	80001fb4 <scheduler+0x62>

0000000080001ff2 <sched>:
{
    80001ff2:	7179                	addi	sp,sp,-48
    80001ff4:	f406                	sd	ra,40(sp)
    80001ff6:	f022                	sd	s0,32(sp)
    80001ff8:	ec26                	sd	s1,24(sp)
    80001ffa:	e84a                	sd	s2,16(sp)
    80001ffc:	e44e                	sd	s3,8(sp)
    80001ffe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	a5c080e7          	jalr	-1444(ra) # 80001a5c <myproc>
    80002008:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	bb2080e7          	jalr	-1102(ra) # 80000bbc <holding>
    80002012:	c93d                	beqz	a0,80002088 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002014:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002016:	2781                	sext.w	a5,a5
    80002018:	079e                	slli	a5,a5,0x7
    8000201a:	0000f717          	auipc	a4,0xf
    8000201e:	b6670713          	addi	a4,a4,-1178 # 80010b80 <pid_lock>
    80002022:	97ba                	add	a5,a5,a4
    80002024:	0a87a703          	lw	a4,168(a5)
    80002028:	4785                	li	a5,1
    8000202a:	06f71763          	bne	a4,a5,80002098 <sched+0xa6>
  if(p->state == RUNNING)
    8000202e:	4c98                	lw	a4,24(s1)
    80002030:	4791                	li	a5,4
    80002032:	06f70b63          	beq	a4,a5,800020a8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002036:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000203a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000203c:	efb5                	bnez	a5,800020b8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002040:	0000f917          	auipc	s2,0xf
    80002044:	b4090913          	addi	s2,s2,-1216 # 80010b80 <pid_lock>
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	97ca                	add	a5,a5,s2
    8000204e:	0ac7a983          	lw	s3,172(a5)
    80002052:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	0000f597          	auipc	a1,0xf
    8000205c:	b6058593          	addi	a1,a1,-1184 # 80010bb8 <cpus+0x8>
    80002060:	95be                	add	a1,a1,a5
    80002062:	06048513          	addi	a0,s1,96
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	600080e7          	jalr	1536(ra) # 80002666 <swtch>
    8000206e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002070:	2781                	sext.w	a5,a5
    80002072:	079e                	slli	a5,a5,0x7
    80002074:	97ca                	add	a5,a5,s2
    80002076:	0b37a623          	sw	s3,172(a5)
}
    8000207a:	70a2                	ld	ra,40(sp)
    8000207c:	7402                	ld	s0,32(sp)
    8000207e:	64e2                	ld	s1,24(sp)
    80002080:	6942                	ld	s2,16(sp)
    80002082:	69a2                	ld	s3,8(sp)
    80002084:	6145                	addi	sp,sp,48
    80002086:	8082                	ret
    panic("sched p->lock");
    80002088:	00006517          	auipc	a0,0x6
    8000208c:	1b850513          	addi	a0,a0,440 # 80008240 <digits+0x1e8>
    80002090:	ffffe097          	auipc	ra,0xffffe
    80002094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
    panic("sched locks");
    80002098:	00006517          	auipc	a0,0x6
    8000209c:	1b850513          	addi	a0,a0,440 # 80008250 <digits+0x1f8>
    800020a0:	ffffe097          	auipc	ra,0xffffe
    800020a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>
    panic("sched running");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	1b850513          	addi	a0,a0,440 # 80008260 <digits+0x208>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	48e080e7          	jalr	1166(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020b8:	00006517          	auipc	a0,0x6
    800020bc:	1b850513          	addi	a0,a0,440 # 80008270 <digits+0x218>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	47e080e7          	jalr	1150(ra) # 8000053e <panic>

00000000800020c8 <yield>:
{
    800020c8:	1101                	addi	sp,sp,-32
    800020ca:	ec06                	sd	ra,24(sp)
    800020cc:	e822                	sd	s0,16(sp)
    800020ce:	e426                	sd	s1,8(sp)
    800020d0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	98a080e7          	jalr	-1654(ra) # 80001a5c <myproc>
    800020da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	b5a080e7          	jalr	-1190(ra) # 80000c36 <acquire>
  p->state = RUNNABLE;
    800020e4:	478d                	li	a5,3
    800020e6:	cc9c                	sw	a5,24(s1)
  sched();
    800020e8:	00000097          	auipc	ra,0x0
    800020ec:	f0a080e7          	jalr	-246(ra) # 80001ff2 <sched>
  release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	c2e080e7          	jalr	-978(ra) # 80000d20 <release>
}
    800020fa:	60e2                	ld	ra,24(sp)
    800020fc:	6442                	ld	s0,16(sp)
    800020fe:	64a2                	ld	s1,8(sp)
    80002100:	6105                	addi	sp,sp,32
    80002102:	8082                	ret

0000000080002104 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002104:	7179                	addi	sp,sp,-48
    80002106:	f406                	sd	ra,40(sp)
    80002108:	f022                	sd	s0,32(sp)
    8000210a:	ec26                	sd	s1,24(sp)
    8000210c:	e84a                	sd	s2,16(sp)
    8000210e:	e44e                	sd	s3,8(sp)
    80002110:	1800                	addi	s0,sp,48
    80002112:	89aa                	mv	s3,a0
    80002114:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	946080e7          	jalr	-1722(ra) # 80001a5c <myproc>
    8000211e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b16080e7          	jalr	-1258(ra) # 80000c36 <acquire>
  release(lk);
    80002128:	854a                	mv	a0,s2
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	bf6080e7          	jalr	-1034(ra) # 80000d20 <release>

  // Go to sleep.
  p->chan = chan;
    80002132:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002136:	4789                	li	a5,2
    80002138:	cc9c                	sw	a5,24(s1)

  sched();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	eb8080e7          	jalr	-328(ra) # 80001ff2 <sched>

  // Tidy up.
  p->chan = 0;
    80002142:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	bd8080e7          	jalr	-1064(ra) # 80000d20 <release>
  acquire(lk);
    80002150:	854a                	mv	a0,s2
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	ae4080e7          	jalr	-1308(ra) # 80000c36 <acquire>
}
    8000215a:	70a2                	ld	ra,40(sp)
    8000215c:	7402                	ld	s0,32(sp)
    8000215e:	64e2                	ld	s1,24(sp)
    80002160:	6942                	ld	s2,16(sp)
    80002162:	69a2                	ld	s3,8(sp)
    80002164:	6145                	addi	sp,sp,48
    80002166:	8082                	ret

0000000080002168 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002168:	7139                	addi	sp,sp,-64
    8000216a:	fc06                	sd	ra,56(sp)
    8000216c:	f822                	sd	s0,48(sp)
    8000216e:	f426                	sd	s1,40(sp)
    80002170:	f04a                	sd	s2,32(sp)
    80002172:	ec4e                	sd	s3,24(sp)
    80002174:	e852                	sd	s4,16(sp)
    80002176:	e456                	sd	s5,8(sp)
    80002178:	0080                	addi	s0,sp,64
    8000217a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000217c:	0000f497          	auipc	s1,0xf
    80002180:	e3448493          	addi	s1,s1,-460 # 80010fb0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002184:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002186:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002188:	00015917          	auipc	s2,0x15
    8000218c:	82890913          	addi	s2,s2,-2008 # 800169b0 <tickslock>
    80002190:	a811                	j	800021a4 <wakeup+0x3c>
      }
      release(&p->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b8c080e7          	jalr	-1140(ra) # 80000d20 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000219c:	16848493          	addi	s1,s1,360
    800021a0:	03248663          	beq	s1,s2,800021cc <wakeup+0x64>
    if(p != myproc()){
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	8b8080e7          	jalr	-1864(ra) # 80001a5c <myproc>
    800021ac:	fea488e3          	beq	s1,a0,8000219c <wakeup+0x34>
      acquire(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a84080e7          	jalr	-1404(ra) # 80000c36 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021ba:	4c9c                	lw	a5,24(s1)
    800021bc:	fd379be3          	bne	a5,s3,80002192 <wakeup+0x2a>
    800021c0:	709c                	ld	a5,32(s1)
    800021c2:	fd4798e3          	bne	a5,s4,80002192 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021c6:	0154ac23          	sw	s5,24(s1)
    800021ca:	b7e1                	j	80002192 <wakeup+0x2a>
    }
  }
}
    800021cc:	70e2                	ld	ra,56(sp)
    800021ce:	7442                	ld	s0,48(sp)
    800021d0:	74a2                	ld	s1,40(sp)
    800021d2:	7902                	ld	s2,32(sp)
    800021d4:	69e2                	ld	s3,24(sp)
    800021d6:	6a42                	ld	s4,16(sp)
    800021d8:	6aa2                	ld	s5,8(sp)
    800021da:	6121                	addi	sp,sp,64
    800021dc:	8082                	ret

00000000800021de <reparent>:
{
    800021de:	7179                	addi	sp,sp,-48
    800021e0:	f406                	sd	ra,40(sp)
    800021e2:	f022                	sd	s0,32(sp)
    800021e4:	ec26                	sd	s1,24(sp)
    800021e6:	e84a                	sd	s2,16(sp)
    800021e8:	e44e                	sd	s3,8(sp)
    800021ea:	e052                	sd	s4,0(sp)
    800021ec:	1800                	addi	s0,sp,48
    800021ee:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f0:	0000f497          	auipc	s1,0xf
    800021f4:	dc048493          	addi	s1,s1,-576 # 80010fb0 <proc>
      pp->parent = initproc;
    800021f8:	00006a17          	auipc	s4,0x6
    800021fc:	710a0a13          	addi	s4,s4,1808 # 80008908 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002200:	00014997          	auipc	s3,0x14
    80002204:	7b098993          	addi	s3,s3,1968 # 800169b0 <tickslock>
    80002208:	a029                	j	80002212 <reparent+0x34>
    8000220a:	16848493          	addi	s1,s1,360
    8000220e:	01348d63          	beq	s1,s3,80002228 <reparent+0x4a>
    if(pp->parent == p){
    80002212:	7c9c                	ld	a5,56(s1)
    80002214:	ff279be3          	bne	a5,s2,8000220a <reparent+0x2c>
      pp->parent = initproc;
    80002218:	000a3503          	ld	a0,0(s4)
    8000221c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	f4a080e7          	jalr	-182(ra) # 80002168 <wakeup>
    80002226:	b7d5                	j	8000220a <reparent+0x2c>
}
    80002228:	70a2                	ld	ra,40(sp)
    8000222a:	7402                	ld	s0,32(sp)
    8000222c:	64e2                	ld	s1,24(sp)
    8000222e:	6942                	ld	s2,16(sp)
    80002230:	69a2                	ld	s3,8(sp)
    80002232:	6a02                	ld	s4,0(sp)
    80002234:	6145                	addi	sp,sp,48
    80002236:	8082                	ret

0000000080002238 <exit>:
{
    80002238:	7179                	addi	sp,sp,-48
    8000223a:	f406                	sd	ra,40(sp)
    8000223c:	f022                	sd	s0,32(sp)
    8000223e:	ec26                	sd	s1,24(sp)
    80002240:	e84a                	sd	s2,16(sp)
    80002242:	e44e                	sd	s3,8(sp)
    80002244:	e052                	sd	s4,0(sp)
    80002246:	1800                	addi	s0,sp,48
    80002248:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	812080e7          	jalr	-2030(ra) # 80001a5c <myproc>
    80002252:	89aa                	mv	s3,a0
  if(p == initproc)
    80002254:	00006797          	auipc	a5,0x6
    80002258:	6b47b783          	ld	a5,1716(a5) # 80008908 <initproc>
    8000225c:	0d050493          	addi	s1,a0,208
    80002260:	15050913          	addi	s2,a0,336
    80002264:	02a79363          	bne	a5,a0,8000228a <exit+0x52>
    panic("init exiting");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	02050513          	addi	a0,a0,32 # 80008288 <digits+0x230>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2ce080e7          	jalr	718(ra) # 8000053e <panic>
      fileclose(f);
    80002278:	00002097          	auipc	ra,0x2
    8000227c:	36e080e7          	jalr	878(ra) # 800045e6 <fileclose>
      p->ofile[fd] = 0;
    80002280:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002284:	04a1                	addi	s1,s1,8
    80002286:	01248563          	beq	s1,s2,80002290 <exit+0x58>
    if(p->ofile[fd]){
    8000228a:	6088                	ld	a0,0(s1)
    8000228c:	f575                	bnez	a0,80002278 <exit+0x40>
    8000228e:	bfdd                	j	80002284 <exit+0x4c>
  begin_op();
    80002290:	00002097          	auipc	ra,0x2
    80002294:	e8a080e7          	jalr	-374(ra) # 8000411a <begin_op>
  iput(p->cwd);
    80002298:	1509b503          	ld	a0,336(s3)
    8000229c:	00001097          	auipc	ra,0x1
    800022a0:	676080e7          	jalr	1654(ra) # 80003912 <iput>
  end_op();
    800022a4:	00002097          	auipc	ra,0x2
    800022a8:	ef6080e7          	jalr	-266(ra) # 8000419a <end_op>
  p->cwd = 0;
    800022ac:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b0:	0000f497          	auipc	s1,0xf
    800022b4:	8e848493          	addi	s1,s1,-1816 # 80010b98 <wait_lock>
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	97c080e7          	jalr	-1668(ra) # 80000c36 <acquire>
  reparent(p);
    800022c2:	854e                	mv	a0,s3
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	f1a080e7          	jalr	-230(ra) # 800021de <reparent>
  wakeup(p->parent);
    800022cc:	0389b503          	ld	a0,56(s3)
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	e98080e7          	jalr	-360(ra) # 80002168 <wakeup>
  acquire(&p->lock);
    800022d8:	854e                	mv	a0,s3
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	95c080e7          	jalr	-1700(ra) # 80000c36 <acquire>
  p->xstate = status;
    800022e2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022e6:	4795                	li	a5,5
    800022e8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	a32080e7          	jalr	-1486(ra) # 80000d20 <release>
  sched();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	cfc080e7          	jalr	-772(ra) # 80001ff2 <sched>
  panic("zombie exit");
    800022fe:	00006517          	auipc	a0,0x6
    80002302:	f9a50513          	addi	a0,a0,-102 # 80008298 <digits+0x240>
    80002306:	ffffe097          	auipc	ra,0xffffe
    8000230a:	238080e7          	jalr	568(ra) # 8000053e <panic>

000000008000230e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000230e:	7179                	addi	sp,sp,-48
    80002310:	f406                	sd	ra,40(sp)
    80002312:	f022                	sd	s0,32(sp)
    80002314:	ec26                	sd	s1,24(sp)
    80002316:	e84a                	sd	s2,16(sp)
    80002318:	e44e                	sd	s3,8(sp)
    8000231a:	1800                	addi	s0,sp,48
    8000231c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000231e:	0000f497          	auipc	s1,0xf
    80002322:	c9248493          	addi	s1,s1,-878 # 80010fb0 <proc>
    80002326:	00014997          	auipc	s3,0x14
    8000232a:	68a98993          	addi	s3,s3,1674 # 800169b0 <tickslock>
    acquire(&p->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	906080e7          	jalr	-1786(ra) # 80000c36 <acquire>
    if(p->pid == pid){
    80002338:	589c                	lw	a5,48(s1)
    8000233a:	01278d63          	beq	a5,s2,80002354 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	9e0080e7          	jalr	-1568(ra) # 80000d20 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002348:	16848493          	addi	s1,s1,360
    8000234c:	ff3491e3          	bne	s1,s3,8000232e <kill+0x20>
  }
  return -1;
    80002350:	557d                	li	a0,-1
    80002352:	a829                	j	8000236c <kill+0x5e>
      p->killed = 1;
    80002354:	4785                	li	a5,1
    80002356:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002358:	4c98                	lw	a4,24(s1)
    8000235a:	4789                	li	a5,2
    8000235c:	00f70f63          	beq	a4,a5,8000237a <kill+0x6c>
      release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	9be080e7          	jalr	-1602(ra) # 80000d20 <release>
      return 0;
    8000236a:	4501                	li	a0,0
}
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret
        p->state = RUNNABLE;
    8000237a:	478d                	li	a5,3
    8000237c:	cc9c                	sw	a5,24(s1)
    8000237e:	b7cd                	j	80002360 <kill+0x52>

0000000080002380 <setkilled>:

void
setkilled(struct proc *p)
{
    80002380:	1101                	addi	sp,sp,-32
    80002382:	ec06                	sd	ra,24(sp)
    80002384:	e822                	sd	s0,16(sp)
    80002386:	e426                	sd	s1,8(sp)
    80002388:	1000                	addi	s0,sp,32
    8000238a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8aa080e7          	jalr	-1878(ra) # 80000c36 <acquire>
  p->killed = 1;
    80002394:	4785                	li	a5,1
    80002396:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	986080e7          	jalr	-1658(ra) # 80000d20 <release>
}
    800023a2:	60e2                	ld	ra,24(sp)
    800023a4:	6442                	ld	s0,16(sp)
    800023a6:	64a2                	ld	s1,8(sp)
    800023a8:	6105                	addi	sp,sp,32
    800023aa:	8082                	ret

00000000800023ac <killed>:

int
killed(struct proc *p)
{
    800023ac:	1101                	addi	sp,sp,-32
    800023ae:	ec06                	sd	ra,24(sp)
    800023b0:	e822                	sd	s0,16(sp)
    800023b2:	e426                	sd	s1,8(sp)
    800023b4:	e04a                	sd	s2,0(sp)
    800023b6:	1000                	addi	s0,sp,32
    800023b8:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	87c080e7          	jalr	-1924(ra) # 80000c36 <acquire>
  k = p->killed;
    800023c2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	958080e7          	jalr	-1704(ra) # 80000d20 <release>
  return k;
}
    800023d0:	854a                	mv	a0,s2
    800023d2:	60e2                	ld	ra,24(sp)
    800023d4:	6442                	ld	s0,16(sp)
    800023d6:	64a2                	ld	s1,8(sp)
    800023d8:	6902                	ld	s2,0(sp)
    800023da:	6105                	addi	sp,sp,32
    800023dc:	8082                	ret

00000000800023de <wait>:
{
    800023de:	715d                	addi	sp,sp,-80
    800023e0:	e486                	sd	ra,72(sp)
    800023e2:	e0a2                	sd	s0,64(sp)
    800023e4:	fc26                	sd	s1,56(sp)
    800023e6:	f84a                	sd	s2,48(sp)
    800023e8:	f44e                	sd	s3,40(sp)
    800023ea:	f052                	sd	s4,32(sp)
    800023ec:	ec56                	sd	s5,24(sp)
    800023ee:	e85a                	sd	s6,16(sp)
    800023f0:	e45e                	sd	s7,8(sp)
    800023f2:	e062                	sd	s8,0(sp)
    800023f4:	0880                	addi	s0,sp,80
    800023f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	664080e7          	jalr	1636(ra) # 80001a5c <myproc>
    80002400:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002402:	0000e517          	auipc	a0,0xe
    80002406:	79650513          	addi	a0,a0,1942 # 80010b98 <wait_lock>
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	82c080e7          	jalr	-2004(ra) # 80000c36 <acquire>
    havekids = 0;
    80002412:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002414:	4a15                	li	s4,5
        havekids = 1;
    80002416:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002418:	00014997          	auipc	s3,0x14
    8000241c:	59898993          	addi	s3,s3,1432 # 800169b0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002420:	0000ec17          	auipc	s8,0xe
    80002424:	778c0c13          	addi	s8,s8,1912 # 80010b98 <wait_lock>
    havekids = 0;
    80002428:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242a:	0000f497          	auipc	s1,0xf
    8000242e:	b8648493          	addi	s1,s1,-1146 # 80010fb0 <proc>
    80002432:	a0bd                	j	800024a0 <wait+0xc2>
          pid = pp->pid;
    80002434:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002438:	000b0e63          	beqz	s6,80002454 <wait+0x76>
    8000243c:	4691                	li	a3,4
    8000243e:	02c48613          	addi	a2,s1,44
    80002442:	85da                	mv	a1,s6
    80002444:	05093503          	ld	a0,80(s2)
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	2d0080e7          	jalr	720(ra) # 80001718 <copyout>
    80002450:	02054563          	bltz	a0,8000247a <wait+0x9c>
          freeproc(pp);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	7b8080e7          	jalr	1976(ra) # 80001c0e <freeproc>
          release(&pp->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	8c0080e7          	jalr	-1856(ra) # 80000d20 <release>
          release(&wait_lock);
    80002468:	0000e517          	auipc	a0,0xe
    8000246c:	73050513          	addi	a0,a0,1840 # 80010b98 <wait_lock>
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	8b0080e7          	jalr	-1872(ra) # 80000d20 <release>
          return pid;
    80002478:	a0b5                	j	800024e4 <wait+0x106>
            release(&pp->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	8a4080e7          	jalr	-1884(ra) # 80000d20 <release>
            release(&wait_lock);
    80002484:	0000e517          	auipc	a0,0xe
    80002488:	71450513          	addi	a0,a0,1812 # 80010b98 <wait_lock>
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	894080e7          	jalr	-1900(ra) # 80000d20 <release>
            return -1;
    80002494:	59fd                	li	s3,-1
    80002496:	a0b9                	j	800024e4 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002498:	16848493          	addi	s1,s1,360
    8000249c:	03348463          	beq	s1,s3,800024c4 <wait+0xe6>
      if(pp->parent == p){
    800024a0:	7c9c                	ld	a5,56(s1)
    800024a2:	ff279be3          	bne	a5,s2,80002498 <wait+0xba>
        acquire(&pp->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	78e080e7          	jalr	1934(ra) # 80000c36 <acquire>
        if(pp->state == ZOMBIE){
    800024b0:	4c9c                	lw	a5,24(s1)
    800024b2:	f94781e3          	beq	a5,s4,80002434 <wait+0x56>
        release(&pp->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	868080e7          	jalr	-1944(ra) # 80000d20 <release>
        havekids = 1;
    800024c0:	8756                	mv	a4,s5
    800024c2:	bfd9                	j	80002498 <wait+0xba>
    if(!havekids || killed(p)){
    800024c4:	c719                	beqz	a4,800024d2 <wait+0xf4>
    800024c6:	854a                	mv	a0,s2
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	ee4080e7          	jalr	-284(ra) # 800023ac <killed>
    800024d0:	c51d                	beqz	a0,800024fe <wait+0x120>
      release(&wait_lock);
    800024d2:	0000e517          	auipc	a0,0xe
    800024d6:	6c650513          	addi	a0,a0,1734 # 80010b98 <wait_lock>
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	846080e7          	jalr	-1978(ra) # 80000d20 <release>
      return -1;
    800024e2:	59fd                	li	s3,-1
}
    800024e4:	854e                	mv	a0,s3
    800024e6:	60a6                	ld	ra,72(sp)
    800024e8:	6406                	ld	s0,64(sp)
    800024ea:	74e2                	ld	s1,56(sp)
    800024ec:	7942                	ld	s2,48(sp)
    800024ee:	79a2                	ld	s3,40(sp)
    800024f0:	7a02                	ld	s4,32(sp)
    800024f2:	6ae2                	ld	s5,24(sp)
    800024f4:	6b42                	ld	s6,16(sp)
    800024f6:	6ba2                	ld	s7,8(sp)
    800024f8:	6c02                	ld	s8,0(sp)
    800024fa:	6161                	addi	sp,sp,80
    800024fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024fe:	85e2                	mv	a1,s8
    80002500:	854a                	mv	a0,s2
    80002502:	00000097          	auipc	ra,0x0
    80002506:	c02080e7          	jalr	-1022(ra) # 80002104 <sleep>
    havekids = 0;
    8000250a:	bf39                	j	80002428 <wait+0x4a>

000000008000250c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	84aa                	mv	s1,a0
    8000251e:	892e                	mv	s2,a1
    80002520:	89b2                	mv	s3,a2
    80002522:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	538080e7          	jalr	1336(ra) # 80001a5c <myproc>
  if(user_dst){
    8000252c:	c08d                	beqz	s1,8000254e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000252e:	86d2                	mv	a3,s4
    80002530:	864e                	mv	a2,s3
    80002532:	85ca                	mv	a1,s2
    80002534:	6928                	ld	a0,80(a0)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	1e2080e7          	jalr	482(ra) # 80001718 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    memmove((char *)dst, src, len);
    8000254e:	000a061b          	sext.w	a2,s4
    80002552:	85ce                	mv	a1,s3
    80002554:	854a                	mv	a0,s2
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	874080e7          	jalr	-1932(ra) # 80000dca <memmove>
    return 0;
    8000255e:	8526                	mv	a0,s1
    80002560:	bff9                	j	8000253e <either_copyout+0x32>

0000000080002562 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002562:	7179                	addi	sp,sp,-48
    80002564:	f406                	sd	ra,40(sp)
    80002566:	f022                	sd	s0,32(sp)
    80002568:	ec26                	sd	s1,24(sp)
    8000256a:	e84a                	sd	s2,16(sp)
    8000256c:	e44e                	sd	s3,8(sp)
    8000256e:	e052                	sd	s4,0(sp)
    80002570:	1800                	addi	s0,sp,48
    80002572:	892a                	mv	s2,a0
    80002574:	84ae                	mv	s1,a1
    80002576:	89b2                	mv	s3,a2
    80002578:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	4e2080e7          	jalr	1250(ra) # 80001a5c <myproc>
  if(user_src){
    80002582:	c08d                	beqz	s1,800025a4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002584:	86d2                	mv	a3,s4
    80002586:	864e                	mv	a2,s3
    80002588:	85ca                	mv	a1,s2
    8000258a:	6928                	ld	a0,80(a0)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	218080e7          	jalr	536(ra) # 800017a4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6a02                	ld	s4,0(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a4:	000a061b          	sext.w	a2,s4
    800025a8:	85ce                	mv	a1,s3
    800025aa:	854a                	mv	a0,s2
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	81e080e7          	jalr	-2018(ra) # 80000dca <memmove>
    return 0;
    800025b4:	8526                	mv	a0,s1
    800025b6:	bff9                	j	80002594 <either_copyin+0x32>

00000000800025b8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	b2250513          	addi	a0,a0,-1246 # 800080f0 <digits+0x98>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb2080e7          	jalr	-78(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	0000f497          	auipc	s1,0xf
    800025e2:	b2a48493          	addi	s1,s1,-1238 # 80011108 <proc+0x158>
    800025e6:	00014917          	auipc	s2,0x14
    800025ea:	52290913          	addi	s2,s2,1314 # 80016b08 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f0:	00006997          	auipc	s3,0x6
    800025f4:	cb898993          	addi	s3,s3,-840 # 800082a8 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	00006a97          	auipc	s5,0x6
    800025fc:	cb8a8a93          	addi	s5,s5,-840 # 800082b0 <digits+0x258>
    printf("\n");
    80002600:	00006a17          	auipc	s4,0x6
    80002604:	af0a0a13          	addi	s4,s4,-1296 # 800080f0 <digits+0x98>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	00006b97          	auipc	s7,0x6
    8000260c:	ce8b8b93          	addi	s7,s7,-792 # 800082f0 <states.0>
    80002610:	a00d                	j	80002632 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002612:	ed86a583          	lw	a1,-296(a3)
    80002616:	8556                	mv	a0,s5
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f70080e7          	jalr	-144(ra) # 80000588 <printf>
    printf("\n");
    80002620:	8552                	mv	a0,s4
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f66080e7          	jalr	-154(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262a:	16848493          	addi	s1,s1,360
    8000262e:	03248163          	beq	s1,s2,80002650 <procdump+0x98>
    if(p->state == UNUSED)
    80002632:	86a6                	mv	a3,s1
    80002634:	ec04a783          	lw	a5,-320(s1)
    80002638:	dbed                	beqz	a5,8000262a <procdump+0x72>
      state = "???";
    8000263a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263c:	fcfb6be3          	bltu	s6,a5,80002612 <procdump+0x5a>
    80002640:	1782                	slli	a5,a5,0x20
    80002642:	9381                	srli	a5,a5,0x20
    80002644:	078e                	slli	a5,a5,0x3
    80002646:	97de                	add	a5,a5,s7
    80002648:	6390                	ld	a2,0(a5)
    8000264a:	f661                	bnez	a2,80002612 <procdump+0x5a>
      state = "???";
    8000264c:	864e                	mv	a2,s3
    8000264e:	b7d1                	j	80002612 <procdump+0x5a>
  }
}
    80002650:	60a6                	ld	ra,72(sp)
    80002652:	6406                	ld	s0,64(sp)
    80002654:	74e2                	ld	s1,56(sp)
    80002656:	7942                	ld	s2,48(sp)
    80002658:	79a2                	ld	s3,40(sp)
    8000265a:	7a02                	ld	s4,32(sp)
    8000265c:	6ae2                	ld	s5,24(sp)
    8000265e:	6b42                	ld	s6,16(sp)
    80002660:	6ba2                	ld	s7,8(sp)
    80002662:	6161                	addi	sp,sp,80
    80002664:	8082                	ret

0000000080002666 <swtch>:
    80002666:	00153023          	sd	ra,0(a0)
    8000266a:	00253423          	sd	sp,8(a0)
    8000266e:	e900                	sd	s0,16(a0)
    80002670:	ed04                	sd	s1,24(a0)
    80002672:	03253023          	sd	s2,32(a0)
    80002676:	03353423          	sd	s3,40(a0)
    8000267a:	03453823          	sd	s4,48(a0)
    8000267e:	03553c23          	sd	s5,56(a0)
    80002682:	05653023          	sd	s6,64(a0)
    80002686:	05753423          	sd	s7,72(a0)
    8000268a:	05853823          	sd	s8,80(a0)
    8000268e:	05953c23          	sd	s9,88(a0)
    80002692:	07a53023          	sd	s10,96(a0)
    80002696:	07b53423          	sd	s11,104(a0)
    8000269a:	0005b083          	ld	ra,0(a1)
    8000269e:	0085b103          	ld	sp,8(a1)
    800026a2:	6980                	ld	s0,16(a1)
    800026a4:	6d84                	ld	s1,24(a1)
    800026a6:	0205b903          	ld	s2,32(a1)
    800026aa:	0285b983          	ld	s3,40(a1)
    800026ae:	0305ba03          	ld	s4,48(a1)
    800026b2:	0385ba83          	ld	s5,56(a1)
    800026b6:	0405bb03          	ld	s6,64(a1)
    800026ba:	0485bb83          	ld	s7,72(a1)
    800026be:	0505bc03          	ld	s8,80(a1)
    800026c2:	0585bc83          	ld	s9,88(a1)
    800026c6:	0605bd03          	ld	s10,96(a1)
    800026ca:	0685bd83          	ld	s11,104(a1)
    800026ce:	8082                	ret

00000000800026d0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d0:	1141                	addi	sp,sp,-16
    800026d2:	e406                	sd	ra,8(sp)
    800026d4:	e022                	sd	s0,0(sp)
    800026d6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d8:	00006597          	auipc	a1,0x6
    800026dc:	c4858593          	addi	a1,a1,-952 # 80008320 <states.0+0x30>
    800026e0:	00014517          	auipc	a0,0x14
    800026e4:	2d050513          	addi	a0,a0,720 # 800169b0 <tickslock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	4ba080e7          	jalr	1210(ra) # 80000ba2 <initlock>
}
    800026f0:	60a2                	ld	ra,8(sp)
    800026f2:	6402                	ld	s0,0(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e422                	sd	s0,8(sp)
    800026fc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fe:	00003797          	auipc	a5,0x3
    80002702:	53278793          	addi	a5,a5,1330 # 80005c30 <kernelvec>
    80002706:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270a:	6422                	ld	s0,8(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	344080e7          	jalr	836(ra) # 80001a5c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002720:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002724:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002726:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000272a:	00005617          	auipc	a2,0x5
    8000272e:	8d660613          	addi	a2,a2,-1834 # 80007000 <_trampoline>
    80002732:	00005697          	auipc	a3,0x5
    80002736:	8ce68693          	addi	a3,a3,-1842 # 80007000 <_trampoline>
    8000273a:	8e91                	sub	a3,a3,a2
    8000273c:	040007b7          	lui	a5,0x4000
    80002740:	17fd                	addi	a5,a5,-1
    80002742:	07b2                	slli	a5,a5,0xc
    80002744:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002746:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000274c:	180026f3          	csrr	a3,satp
    80002750:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002752:	6d38                	ld	a4,88(a0)
    80002754:	6134                	ld	a3,64(a0)
    80002756:	6585                	lui	a1,0x1
    80002758:	96ae                	add	a3,a3,a1
    8000275a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000275c:	6d38                	ld	a4,88(a0)
    8000275e:	00000697          	auipc	a3,0x0
    80002762:	13068693          	addi	a3,a3,304 # 8000288e <usertrap>
    80002766:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002768:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276a:	8692                	mv	a3,tp
    8000276c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002772:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002776:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002780:	6f18                	ld	a4,24(a4)
    80002782:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002786:	6928                	ld	a0,80(a0)
    80002788:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000278a:	00005717          	auipc	a4,0x5
    8000278e:	91270713          	addi	a4,a4,-1774 # 8000709c <userret>
    80002792:	8f11                	sub	a4,a4,a2
    80002794:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002796:	577d                	li	a4,-1
    80002798:	177e                	slli	a4,a4,0x3f
    8000279a:	8d59                	or	a0,a0,a4
    8000279c:	9782                	jalr	a5
}
    8000279e:	60a2                	ld	ra,8(sp)
    800027a0:	6402                	ld	s0,0(sp)
    800027a2:	0141                	addi	sp,sp,16
    800027a4:	8082                	ret

00000000800027a6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a6:	1101                	addi	sp,sp,-32
    800027a8:	ec06                	sd	ra,24(sp)
    800027aa:	e822                	sd	s0,16(sp)
    800027ac:	e426                	sd	s1,8(sp)
    800027ae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b0:	00014497          	auipc	s1,0x14
    800027b4:	20048493          	addi	s1,s1,512 # 800169b0 <tickslock>
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	47c080e7          	jalr	1148(ra) # 80000c36 <acquire>
  ticks++;
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	14e50513          	addi	a0,a0,334 # 80008910 <ticks>
    800027ca:	411c                	lw	a5,0(a0)
    800027cc:	2785                	addiw	a5,a5,1
    800027ce:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	998080e7          	jalr	-1640(ra) # 80002168 <wakeup>
  release(&tickslock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	546080e7          	jalr	1350(ra) # 80000d20 <release>
}
    800027e2:	60e2                	ld	ra,24(sp)
    800027e4:	6442                	ld	s0,16(sp)
    800027e6:	64a2                	ld	s1,8(sp)
    800027e8:	6105                	addi	sp,sp,32
    800027ea:	8082                	ret

00000000800027ec <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ec:	1101                	addi	sp,sp,-32
    800027ee:	ec06                	sd	ra,24(sp)
    800027f0:	e822                	sd	s0,16(sp)
    800027f2:	e426                	sd	s1,8(sp)
    800027f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027fa:	00074d63          	bltz	a4,80002814 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027fe:	57fd                	li	a5,-1
    80002800:	17fe                	slli	a5,a5,0x3f
    80002802:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002804:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002806:	06f70363          	beq	a4,a5,8000286c <devintr+0x80>
  }
}
    8000280a:	60e2                	ld	ra,24(sp)
    8000280c:	6442                	ld	s0,16(sp)
    8000280e:	64a2                	ld	s1,8(sp)
    80002810:	6105                	addi	sp,sp,32
    80002812:	8082                	ret
     (scause & 0xff) == 9){
    80002814:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002818:	46a5                	li	a3,9
    8000281a:	fed792e3          	bne	a5,a3,800027fe <devintr+0x12>
    int irq = plic_claim();
    8000281e:	00003097          	auipc	ra,0x3
    80002822:	51a080e7          	jalr	1306(ra) # 80005d38 <plic_claim>
    80002826:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002828:	47a9                	li	a5,10
    8000282a:	02f50763          	beq	a0,a5,80002858 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000282e:	4785                	li	a5,1
    80002830:	02f50963          	beq	a0,a5,80002862 <devintr+0x76>
    return 1;
    80002834:	4505                	li	a0,1
    } else if(irq){
    80002836:	d8f1                	beqz	s1,8000280a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002838:	85a6                	mv	a1,s1
    8000283a:	00006517          	auipc	a0,0x6
    8000283e:	aee50513          	addi	a0,a0,-1298 # 80008328 <states.0+0x38>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	d46080e7          	jalr	-698(ra) # 80000588 <printf>
      plic_complete(irq);
    8000284a:	8526                	mv	a0,s1
    8000284c:	00003097          	auipc	ra,0x3
    80002850:	510080e7          	jalr	1296(ra) # 80005d5c <plic_complete>
    return 1;
    80002854:	4505                	li	a0,1
    80002856:	bf55                	j	8000280a <devintr+0x1e>
      uartintr();
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	19e080e7          	jalr	414(ra) # 800009f6 <uartintr>
    80002860:	b7ed                	j	8000284a <devintr+0x5e>
      virtio_disk_intr();
    80002862:	00004097          	auipc	ra,0x4
    80002866:	9c6080e7          	jalr	-1594(ra) # 80006228 <virtio_disk_intr>
    8000286a:	b7c5                	j	8000284a <devintr+0x5e>
    if(cpuid() == 0){
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	1c4080e7          	jalr	452(ra) # 80001a30 <cpuid>
    80002874:	c901                	beqz	a0,80002884 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002876:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000287a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000287c:	14479073          	csrw	sip,a5
    return 2;
    80002880:	4509                	li	a0,2
    80002882:	b761                	j	8000280a <devintr+0x1e>
      clockintr();
    80002884:	00000097          	auipc	ra,0x0
    80002888:	f22080e7          	jalr	-222(ra) # 800027a6 <clockintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x8a>

000000008000288e <usertrap>:
{
    8000288e:	1101                	addi	sp,sp,-32
    80002890:	ec06                	sd	ra,24(sp)
    80002892:	e822                	sd	s0,16(sp)
    80002894:	e426                	sd	s1,8(sp)
    80002896:	e04a                	sd	s2,0(sp)
    80002898:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289e:	1007f793          	andi	a5,a5,256
    800028a2:	e3b1                	bnez	a5,800028e6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a4:	00003797          	auipc	a5,0x3
    800028a8:	38c78793          	addi	a5,a5,908 # 80005c30 <kernelvec>
    800028ac:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	1ac080e7          	jalr	428(ra) # 80001a5c <myproc>
    800028b8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ba:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028bc:	14102773          	csrr	a4,sepc
    800028c0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c6:	47a1                	li	a5,8
    800028c8:	02f70763          	beq	a4,a5,800028f6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	f20080e7          	jalr	-224(ra) # 800027ec <devintr>
    800028d4:	892a                	mv	s2,a0
    800028d6:	c151                	beqz	a0,8000295a <usertrap+0xcc>
  if(killed(p))
    800028d8:	8526                	mv	a0,s1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	ad2080e7          	jalr	-1326(ra) # 800023ac <killed>
    800028e2:	c929                	beqz	a0,80002934 <usertrap+0xa6>
    800028e4:	a099                	j	8000292a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	a6250513          	addi	a0,a0,-1438 # 80008348 <states.0+0x58>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	c50080e7          	jalr	-944(ra) # 8000053e <panic>
    if(killed(p))
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	ab6080e7          	jalr	-1354(ra) # 800023ac <killed>
    800028fe:	e921                	bnez	a0,8000294e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002900:	6cb8                	ld	a4,88(s1)
    80002902:	6f1c                	ld	a5,24(a4)
    80002904:	0791                	addi	a5,a5,4
    80002906:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10079073          	csrw	sstatus,a5
    syscall();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	2d4080e7          	jalr	724(ra) # 80002be8 <syscall>
  if(killed(p))
    8000291c:	8526                	mv	a0,s1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	a8e080e7          	jalr	-1394(ra) # 800023ac <killed>
    80002926:	c911                	beqz	a0,8000293a <usertrap+0xac>
    80002928:	4901                	li	s2,0
    exit(-1);
    8000292a:	557d                	li	a0,-1
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	90c080e7          	jalr	-1780(ra) # 80002238 <exit>
  if(which_dev == 2)
    80002934:	4789                	li	a5,2
    80002936:	04f90f63          	beq	s2,a5,80002994 <usertrap+0x106>
  usertrapret();
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	dd6080e7          	jalr	-554(ra) # 80002710 <usertrapret>
}
    80002942:	60e2                	ld	ra,24(sp)
    80002944:	6442                	ld	s0,16(sp)
    80002946:	64a2                	ld	s1,8(sp)
    80002948:	6902                	ld	s2,0(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret
      exit(-1);
    8000294e:	557d                	li	a0,-1
    80002950:	00000097          	auipc	ra,0x0
    80002954:	8e8080e7          	jalr	-1816(ra) # 80002238 <exit>
    80002958:	b765                	j	80002900 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000295e:	5890                	lw	a2,48(s1)
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a0850513          	addi	a0,a0,-1528 # 80008368 <states.0+0x78>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c20080e7          	jalr	-992(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002970:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002974:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a2050513          	addi	a0,a0,-1504 # 80008398 <states.0+0xa8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c08080e7          	jalr	-1016(ra) # 80000588 <printf>
    setkilled(p);
    80002988:	8526                	mv	a0,s1
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	9f6080e7          	jalr	-1546(ra) # 80002380 <setkilled>
    80002992:	b769                	j	8000291c <usertrap+0x8e>
    yield();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	734080e7          	jalr	1844(ra) # 800020c8 <yield>
    8000299c:	bf79                	j	8000293a <usertrap+0xac>

000000008000299e <kerneltrap>:
{
    8000299e:	7179                	addi	sp,sp,-48
    800029a0:	f406                	sd	ra,40(sp)
    800029a2:	f022                	sd	s0,32(sp)
    800029a4:	ec26                	sd	s1,24(sp)
    800029a6:	e84a                	sd	s2,16(sp)
    800029a8:	e44e                	sd	s3,8(sp)
    800029aa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029b8:	1004f793          	andi	a5,s1,256
    800029bc:	cb85                	beqz	a5,800029ec <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029be:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c4:	ef85                	bnez	a5,800029fc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029c6:	00000097          	auipc	ra,0x0
    800029ca:	e26080e7          	jalr	-474(ra) # 800027ec <devintr>
    800029ce:	cd1d                	beqz	a0,80002a0c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d0:	4789                	li	a5,2
    800029d2:	06f50a63          	beq	a0,a5,80002a46 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029da:	10049073          	csrw	sstatus,s1
}
    800029de:	70a2                	ld	ra,40(sp)
    800029e0:	7402                	ld	s0,32(sp)
    800029e2:	64e2                	ld	s1,24(sp)
    800029e4:	6942                	ld	s2,16(sp)
    800029e6:	69a2                	ld	s3,8(sp)
    800029e8:	6145                	addi	sp,sp,48
    800029ea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9cc50513          	addi	a0,a0,-1588 # 800083b8 <states.0+0xc8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b4a080e7          	jalr	-1206(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	9e450513          	addi	a0,a0,-1564 # 800083e0 <states.0+0xf0>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b3a080e7          	jalr	-1222(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a0c:	85ce                	mv	a1,s3
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9f250513          	addi	a0,a0,-1550 # 80008400 <states.0+0x110>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b72080e7          	jalr	-1166(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a22:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	9ea50513          	addi	a0,a0,-1558 # 80008410 <states.0+0x120>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b5a080e7          	jalr	-1190(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	9f250513          	addi	a0,a0,-1550 # 80008428 <states.0+0x138>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	016080e7          	jalr	22(ra) # 80001a5c <myproc>
    80002a4e:	d541                	beqz	a0,800029d6 <kerneltrap+0x38>
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	00c080e7          	jalr	12(ra) # 80001a5c <myproc>
    80002a58:	4d18                	lw	a4,24(a0)
    80002a5a:	4791                	li	a5,4
    80002a5c:	f6f71de3          	bne	a4,a5,800029d6 <kerneltrap+0x38>
    yield();
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	668080e7          	jalr	1640(ra) # 800020c8 <yield>
    80002a68:	b7bd                	j	800029d6 <kerneltrap+0x38>

0000000080002a6a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a6a:	1101                	addi	sp,sp,-32
    80002a6c:	ec06                	sd	ra,24(sp)
    80002a6e:	e822                	sd	s0,16(sp)
    80002a70:	e426                	sd	s1,8(sp)
    80002a72:	1000                	addi	s0,sp,32
    80002a74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	fe6080e7          	jalr	-26(ra) # 80001a5c <myproc>
  switch (n) {
    80002a7e:	4795                	li	a5,5
    80002a80:	0497e163          	bltu	a5,s1,80002ac2 <argraw+0x58>
    80002a84:	048a                	slli	s1,s1,0x2
    80002a86:	00006717          	auipc	a4,0x6
    80002a8a:	9da70713          	addi	a4,a4,-1574 # 80008460 <states.0+0x170>
    80002a8e:	94ba                	add	s1,s1,a4
    80002a90:	409c                	lw	a5,0(s1)
    80002a92:	97ba                	add	a5,a5,a4
    80002a94:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a9a:	60e2                	ld	ra,24(sp)
    80002a9c:	6442                	ld	s0,16(sp)
    80002a9e:	64a2                	ld	s1,8(sp)
    80002aa0:	6105                	addi	sp,sp,32
    80002aa2:	8082                	ret
    return p->trapframe->a1;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	7fa8                	ld	a0,120(a5)
    80002aa8:	bfcd                	j	80002a9a <argraw+0x30>
    return p->trapframe->a2;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	63c8                	ld	a0,128(a5)
    80002aae:	b7f5                	j	80002a9a <argraw+0x30>
    return p->trapframe->a3;
    80002ab0:	6d3c                	ld	a5,88(a0)
    80002ab2:	67c8                	ld	a0,136(a5)
    80002ab4:	b7dd                	j	80002a9a <argraw+0x30>
    return p->trapframe->a4;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	6bc8                	ld	a0,144(a5)
    80002aba:	b7c5                	j	80002a9a <argraw+0x30>
    return p->trapframe->a5;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	6fc8                	ld	a0,152(a5)
    80002ac0:	bfe9                	j	80002a9a <argraw+0x30>
  panic("argraw");
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	97650513          	addi	a0,a0,-1674 # 80008438 <states.0+0x148>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	a74080e7          	jalr	-1420(ra) # 8000053e <panic>

0000000080002ad2 <fetchaddr>:
{
    80002ad2:	1101                	addi	sp,sp,-32
    80002ad4:	ec06                	sd	ra,24(sp)
    80002ad6:	e822                	sd	s0,16(sp)
    80002ad8:	e426                	sd	s1,8(sp)
    80002ada:	e04a                	sd	s2,0(sp)
    80002adc:	1000                	addi	s0,sp,32
    80002ade:	84aa                	mv	s1,a0
    80002ae0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	f7a080e7          	jalr	-134(ra) # 80001a5c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aea:	653c                	ld	a5,72(a0)
    80002aec:	02f4f863          	bgeu	s1,a5,80002b1c <fetchaddr+0x4a>
    80002af0:	00848713          	addi	a4,s1,8
    80002af4:	02e7e663          	bltu	a5,a4,80002b20 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002af8:	46a1                	li	a3,8
    80002afa:	8626                	mv	a2,s1
    80002afc:	85ca                	mv	a1,s2
    80002afe:	6928                	ld	a0,80(a0)
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	ca4080e7          	jalr	-860(ra) # 800017a4 <copyin>
    80002b08:	00a03533          	snez	a0,a0
    80002b0c:	40a00533          	neg	a0,a0
}
    80002b10:	60e2                	ld	ra,24(sp)
    80002b12:	6442                	ld	s0,16(sp)
    80002b14:	64a2                	ld	s1,8(sp)
    80002b16:	6902                	ld	s2,0(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
    return -1;
    80002b1c:	557d                	li	a0,-1
    80002b1e:	bfcd                	j	80002b10 <fetchaddr+0x3e>
    80002b20:	557d                	li	a0,-1
    80002b22:	b7fd                	j	80002b10 <fetchaddr+0x3e>

0000000080002b24 <fetchstr>:
{
    80002b24:	7179                	addi	sp,sp,-48
    80002b26:	f406                	sd	ra,40(sp)
    80002b28:	f022                	sd	s0,32(sp)
    80002b2a:	ec26                	sd	s1,24(sp)
    80002b2c:	e84a                	sd	s2,16(sp)
    80002b2e:	e44e                	sd	s3,8(sp)
    80002b30:	1800                	addi	s0,sp,48
    80002b32:	892a                	mv	s2,a0
    80002b34:	84ae                	mv	s1,a1
    80002b36:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	f24080e7          	jalr	-220(ra) # 80001a5c <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b40:	86ce                	mv	a3,s3
    80002b42:	864a                	mv	a2,s2
    80002b44:	85a6                	mv	a1,s1
    80002b46:	6928                	ld	a0,80(a0)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	cea080e7          	jalr	-790(ra) # 80001832 <copyinstr>
    80002b50:	00054e63          	bltz	a0,80002b6c <fetchstr+0x48>
  return strlen(buf);
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	394080e7          	jalr	916(ra) # 80000eea <strlen>
}
    80002b5e:	70a2                	ld	ra,40(sp)
    80002b60:	7402                	ld	s0,32(sp)
    80002b62:	64e2                	ld	s1,24(sp)
    80002b64:	6942                	ld	s2,16(sp)
    80002b66:	69a2                	ld	s3,8(sp)
    80002b68:	6145                	addi	sp,sp,48
    80002b6a:	8082                	ret
    return -1;
    80002b6c:	557d                	li	a0,-1
    80002b6e:	bfc5                	j	80002b5e <fetchstr+0x3a>

0000000080002b70 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	eee080e7          	jalr	-274(ra) # 80002a6a <argraw>
    80002b84:	c088                	sw	a0,0(s1)
}
    80002b86:	60e2                	ld	ra,24(sp)
    80002b88:	6442                	ld	s0,16(sp)
    80002b8a:	64a2                	ld	s1,8(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret

0000000080002b90 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b90:	1101                	addi	sp,sp,-32
    80002b92:	ec06                	sd	ra,24(sp)
    80002b94:	e822                	sd	s0,16(sp)
    80002b96:	e426                	sd	s1,8(sp)
    80002b98:	1000                	addi	s0,sp,32
    80002b9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	ece080e7          	jalr	-306(ra) # 80002a6a <argraw>
    80002ba4:	e088                	sd	a0,0(s1)
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb0:	7179                	addi	sp,sp,-48
    80002bb2:	f406                	sd	ra,40(sp)
    80002bb4:	f022                	sd	s0,32(sp)
    80002bb6:	ec26                	sd	s1,24(sp)
    80002bb8:	e84a                	sd	s2,16(sp)
    80002bba:	1800                	addi	s0,sp,48
    80002bbc:	84ae                	mv	s1,a1
    80002bbe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bc0:	fd840593          	addi	a1,s0,-40
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	fcc080e7          	jalr	-52(ra) # 80002b90 <argaddr>
  return fetchstr(addr, buf, max);
    80002bcc:	864a                	mv	a2,s2
    80002bce:	85a6                	mv	a1,s1
    80002bd0:	fd843503          	ld	a0,-40(s0)
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	f50080e7          	jalr	-176(ra) # 80002b24 <fetchstr>
}
    80002bdc:	70a2                	ld	ra,40(sp)
    80002bde:	7402                	ld	s0,32(sp)
    80002be0:	64e2                	ld	s1,24(sp)
    80002be2:	6942                	ld	s2,16(sp)
    80002be4:	6145                	addi	sp,sp,48
    80002be6:	8082                	ret

0000000080002be8 <syscall>:
[SYS_acquire_priority] sys_acquire_priority,
};

void
syscall(void)
{
    80002be8:	1101                	addi	sp,sp,-32
    80002bea:	ec06                	sd	ra,24(sp)
    80002bec:	e822                	sd	s0,16(sp)
    80002bee:	e426                	sd	s1,8(sp)
    80002bf0:	e04a                	sd	s2,0(sp)
    80002bf2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	e68080e7          	jalr	-408(ra) # 80001a5c <myproc>
    80002bfc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bfe:	05853903          	ld	s2,88(a0)
    80002c02:	0a893783          	ld	a5,168(s2)
    80002c06:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c0a:	37fd                	addiw	a5,a5,-1
    80002c0c:	4755                	li	a4,21
    80002c0e:	00f76f63          	bltu	a4,a5,80002c2c <syscall+0x44>
    80002c12:	00369713          	slli	a4,a3,0x3
    80002c16:	00006797          	auipc	a5,0x6
    80002c1a:	86278793          	addi	a5,a5,-1950 # 80008478 <syscalls>
    80002c1e:	97ba                	add	a5,a5,a4
    80002c20:	639c                	ld	a5,0(a5)
    80002c22:	c789                	beqz	a5,80002c2c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c24:	9782                	jalr	a5
    80002c26:	06a93823          	sd	a0,112(s2)
    80002c2a:	a839                	j	80002c48 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c2c:	15848613          	addi	a2,s1,344
    80002c30:	588c                	lw	a1,48(s1)
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	80e50513          	addi	a0,a0,-2034 # 80008440 <states.0+0x150>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	94e080e7          	jalr	-1714(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c42:	6cbc                	ld	a5,88(s1)
    80002c44:	577d                	li	a4,-1
    80002c46:	fbb8                	sd	a4,112(a5)
  }
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6902                	ld	s2,0(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c5c:	fec40593          	addi	a1,s0,-20
    80002c60:	4501                	li	a0,0
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	f0e080e7          	jalr	-242(ra) # 80002b70 <argint>
  exit(n);
    80002c6a:	fec42503          	lw	a0,-20(s0)
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	5ca080e7          	jalr	1482(ra) # 80002238 <exit>
  return 0;  // not reached
}
    80002c76:	4501                	li	a0,0
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c80:	1141                	addi	sp,sp,-16
    80002c82:	e406                	sd	ra,8(sp)
    80002c84:	e022                	sd	s0,0(sp)
    80002c86:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	dd4080e7          	jalr	-556(ra) # 80001a5c <myproc>
}
    80002c90:	5908                	lw	a0,48(a0)
    80002c92:	60a2                	ld	ra,8(sp)
    80002c94:	6402                	ld	s0,0(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <sys_fork>:

uint64
sys_fork(void)
{
    80002c9a:	1141                	addi	sp,sp,-16
    80002c9c:	e406                	sd	ra,8(sp)
    80002c9e:	e022                	sd	s0,0(sp)
    80002ca0:	0800                	addi	s0,sp,16
  return fork();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	170080e7          	jalr	368(ra) # 80001e12 <fork>
}
    80002caa:	60a2                	ld	ra,8(sp)
    80002cac:	6402                	ld	s0,0(sp)
    80002cae:	0141                	addi	sp,sp,16
    80002cb0:	8082                	ret

0000000080002cb2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cba:	fe840593          	addi	a1,s0,-24
    80002cbe:	4501                	li	a0,0
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	ed0080e7          	jalr	-304(ra) # 80002b90 <argaddr>
  return wait(p);
    80002cc8:	fe843503          	ld	a0,-24(s0)
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	712080e7          	jalr	1810(ra) # 800023de <wait>
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cdc:	7179                	addi	sp,sp,-48
    80002cde:	f406                	sd	ra,40(sp)
    80002ce0:	f022                	sd	s0,32(sp)
    80002ce2:	ec26                	sd	s1,24(sp)
    80002ce4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ce6:	fdc40593          	addi	a1,s0,-36
    80002cea:	4501                	li	a0,0
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	e84080e7          	jalr	-380(ra) # 80002b70 <argint>
  addr = myproc()->sz;
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	d68080e7          	jalr	-664(ra) # 80001a5c <myproc>
    80002cfc:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002cfe:	fdc42503          	lw	a0,-36(s0)
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	0b4080e7          	jalr	180(ra) # 80001db6 <growproc>
    80002d0a:	00054863          	bltz	a0,80002d1a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d0e:	8526                	mv	a0,s1
    80002d10:	70a2                	ld	ra,40(sp)
    80002d12:	7402                	ld	s0,32(sp)
    80002d14:	64e2                	ld	s1,24(sp)
    80002d16:	6145                	addi	sp,sp,48
    80002d18:	8082                	ret
    return -1;
    80002d1a:	54fd                	li	s1,-1
    80002d1c:	bfcd                	j	80002d0e <sys_sbrk+0x32>

0000000080002d1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d1e:	7139                	addi	sp,sp,-64
    80002d20:	fc06                	sd	ra,56(sp)
    80002d22:	f822                	sd	s0,48(sp)
    80002d24:	f426                	sd	s1,40(sp)
    80002d26:	f04a                	sd	s2,32(sp)
    80002d28:	ec4e                	sd	s3,24(sp)
    80002d2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d2c:	fcc40593          	addi	a1,s0,-52
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	e3e080e7          	jalr	-450(ra) # 80002b70 <argint>
  acquire(&tickslock);
    80002d3a:	00014517          	auipc	a0,0x14
    80002d3e:	c7650513          	addi	a0,a0,-906 # 800169b0 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	ef4080e7          	jalr	-268(ra) # 80000c36 <acquire>
  ticks0 = ticks;
    80002d4a:	00006917          	auipc	s2,0x6
    80002d4e:	bc692903          	lw	s2,-1082(s2) # 80008910 <ticks>
  while(ticks - ticks0 < n){
    80002d52:	fcc42783          	lw	a5,-52(s0)
    80002d56:	cf9d                	beqz	a5,80002d94 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d58:	00014997          	auipc	s3,0x14
    80002d5c:	c5898993          	addi	s3,s3,-936 # 800169b0 <tickslock>
    80002d60:	00006497          	auipc	s1,0x6
    80002d64:	bb048493          	addi	s1,s1,-1104 # 80008910 <ticks>
    if(killed(myproc())){
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	cf4080e7          	jalr	-780(ra) # 80001a5c <myproc>
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	63c080e7          	jalr	1596(ra) # 800023ac <killed>
    80002d78:	e131                	bnez	a0,80002dbc <sys_sleep+0x9e>
    sleep(&ticks, &tickslock);
    80002d7a:	85ce                	mv	a1,s3
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	386080e7          	jalr	902(ra) # 80002104 <sleep>
  while(ticks - ticks0 < n){
    80002d86:	409c                	lw	a5,0(s1)
    80002d88:	412787bb          	subw	a5,a5,s2
    80002d8c:	fcc42703          	lw	a4,-52(s0)
    80002d90:	fce7ece3          	bltu	a5,a4,80002d68 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d94:	00014517          	auipc	a0,0x14
    80002d98:	c1c50513          	addi	a0,a0,-996 # 800169b0 <tickslock>
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	f84080e7          	jalr	-124(ra) # 80000d20 <release>
  backtrace();
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	9f6080e7          	jalr	-1546(ra) # 8000079a <backtrace>
  return 0;
    80002dac:	4501                	li	a0,0
}
    80002dae:	70e2                	ld	ra,56(sp)
    80002db0:	7442                	ld	s0,48(sp)
    80002db2:	74a2                	ld	s1,40(sp)
    80002db4:	7902                	ld	s2,32(sp)
    80002db6:	69e2                	ld	s3,24(sp)
    80002db8:	6121                	addi	sp,sp,64
    80002dba:	8082                	ret
      release(&tickslock);
    80002dbc:	00014517          	auipc	a0,0x14
    80002dc0:	bf450513          	addi	a0,a0,-1036 # 800169b0 <tickslock>
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	f5c080e7          	jalr	-164(ra) # 80000d20 <release>
      return -1;
    80002dcc:	557d                	li	a0,-1
    80002dce:	b7c5                	j	80002dae <sys_sleep+0x90>

0000000080002dd0 <sys_kill>:

uint64
sys_kill(void)
{
    80002dd0:	1101                	addi	sp,sp,-32
    80002dd2:	ec06                	sd	ra,24(sp)
    80002dd4:	e822                	sd	s0,16(sp)
    80002dd6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dd8:	fec40593          	addi	a1,s0,-20
    80002ddc:	4501                	li	a0,0
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	d92080e7          	jalr	-622(ra) # 80002b70 <argint>
  return kill(pid);
    80002de6:	fec42503          	lw	a0,-20(s0)
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	524080e7          	jalr	1316(ra) # 8000230e <kill>
}
    80002df2:	60e2                	ld	ra,24(sp)
    80002df4:	6442                	ld	s0,16(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret

0000000080002dfa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e04:	00014517          	auipc	a0,0x14
    80002e08:	bac50513          	addi	a0,a0,-1108 # 800169b0 <tickslock>
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	e2a080e7          	jalr	-470(ra) # 80000c36 <acquire>
  xticks = ticks;
    80002e14:	00006497          	auipc	s1,0x6
    80002e18:	afc4a483          	lw	s1,-1284(s1) # 80008910 <ticks>
  release(&tickslock);
    80002e1c:	00014517          	auipc	a0,0x14
    80002e20:	b9450513          	addi	a0,a0,-1132 # 800169b0 <tickslock>
    80002e24:	ffffe097          	auipc	ra,0xffffe
    80002e28:	efc080e7          	jalr	-260(ra) # 80000d20 <release>
  return xticks;
}
    80002e2c:	02049513          	slli	a0,s1,0x20
    80002e30:	9101                	srli	a0,a0,0x20
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <sys_acquire_priority>:

int
sys_acquire_priority(void)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	1000                	addi	s0,sp,32
    struct spinlock *lk = 0;
    uint priority  = 10;
    
    if (argstr(0, (char*)lk, sizeof(struct spinlock)) < 0)
    80002e46:	4661                	li	a2,24
    80002e48:	4581                	li	a1,0
    80002e4a:	4501                	li	a0,0
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	d64080e7          	jalr	-668(ra) # 80002bb0 <argstr>
    80002e54:	04054c63          	bltz	a0,80002eac <sys_acquire_priority+0x70>
        return -1;
    
    acquire(lk); // Acquire the spinlock normally
    80002e58:	4501                	li	a0,0
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	ddc080e7          	jalr	-548(ra) # 80000c36 <acquire>
    //lk->priority = 0;
    // Check if there are higher-priority contenders
    if (lk->priority == -1 || priority < lk->priority) {
    80002e62:	00402783          	lw	a5,4(zero) # 4 <_entry-0x7ffffffc>
    80002e66:	0007869b          	sext.w	a3,a5
    80002e6a:	4729                	li	a4,10
    80002e6c:	02d76663          	bltu	a4,a3,80002e98 <sys_acquire_priority+0x5c>
        lk->priority = priority;
        release(lk);
        return 0;
    }
    
    while (lk->priority == priority) {
    80002e70:	44a9                	li	s1,10
        sleep(lk, lk);
    }
    
    return 0;
    80002e72:	4501                	li	a0,0
    while (lk->priority == priority) {
    80002e74:	00e79d63          	bne	a5,a4,80002e8e <sys_acquire_priority+0x52>
        sleep(lk, lk);
    80002e78:	4581                	li	a1,0
    80002e7a:	4501                	li	a0,0
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	288080e7          	jalr	648(ra) # 80002104 <sleep>
    while (lk->priority == priority) {
    80002e84:	00402783          	lw	a5,4(zero) # 4 <_entry-0x7ffffffc>
    80002e88:	fe9788e3          	beq	a5,s1,80002e78 <sys_acquire_priority+0x3c>
    return 0;
    80002e8c:	4501                	li	a0,0
}
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	64a2                	ld	s1,8(sp)
    80002e94:	6105                	addi	sp,sp,32
    80002e96:	8082                	ret
        lk->priority = priority;
    80002e98:	47a9                	li	a5,10
    80002e9a:	00f02223          	sw	a5,4(zero) # 4 <_entry-0x7ffffffc>
        release(lk);
    80002e9e:	4501                	li	a0,0
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	e80080e7          	jalr	-384(ra) # 80000d20 <release>
        return 0;
    80002ea8:	4501                	li	a0,0
    80002eaa:	b7d5                	j	80002e8e <sys_acquire_priority+0x52>
        return -1;
    80002eac:	557d                	li	a0,-1
    80002eae:	b7c5                	j	80002e8e <sys_acquire_priority+0x52>

0000000080002eb0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eb0:	7179                	addi	sp,sp,-48
    80002eb2:	f406                	sd	ra,40(sp)
    80002eb4:	f022                	sd	s0,32(sp)
    80002eb6:	ec26                	sd	s1,24(sp)
    80002eb8:	e84a                	sd	s2,16(sp)
    80002eba:	e44e                	sd	s3,8(sp)
    80002ebc:	e052                	sd	s4,0(sp)
    80002ebe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ec0:	00005597          	auipc	a1,0x5
    80002ec4:	67058593          	addi	a1,a1,1648 # 80008530 <syscalls+0xb8>
    80002ec8:	00014517          	auipc	a0,0x14
    80002ecc:	b0050513          	addi	a0,a0,-1280 # 800169c8 <bcache>
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	cd2080e7          	jalr	-814(ra) # 80000ba2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed8:	0001c797          	auipc	a5,0x1c
    80002edc:	af078793          	addi	a5,a5,-1296 # 8001e9c8 <bcache+0x8000>
    80002ee0:	0001c717          	auipc	a4,0x1c
    80002ee4:	d5070713          	addi	a4,a4,-688 # 8001ec30 <bcache+0x8268>
    80002ee8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ef0:	00014497          	auipc	s1,0x14
    80002ef4:	af048493          	addi	s1,s1,-1296 # 800169e0 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002efa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002efc:	00005a17          	auipc	s4,0x5
    80002f00:	63ca0a13          	addi	s4,s4,1596 # 80008538 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f04:	2b893783          	ld	a5,696(s2)
    80002f08:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f0a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f0e:	85d2                	mv	a1,s4
    80002f10:	01048513          	addi	a0,s1,16
    80002f14:	00001097          	auipc	ra,0x1
    80002f18:	4c4080e7          	jalr	1220(ra) # 800043d8 <initsleeplock>
    bcache.head.next->prev = b;
    80002f1c:	2b893783          	ld	a5,696(s2)
    80002f20:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f22:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f26:	45848493          	addi	s1,s1,1112
    80002f2a:	fd349de3          	bne	s1,s3,80002f04 <binit+0x54>
  }
}
    80002f2e:	70a2                	ld	ra,40(sp)
    80002f30:	7402                	ld	s0,32(sp)
    80002f32:	64e2                	ld	s1,24(sp)
    80002f34:	6942                	ld	s2,16(sp)
    80002f36:	69a2                	ld	s3,8(sp)
    80002f38:	6a02                	ld	s4,0(sp)
    80002f3a:	6145                	addi	sp,sp,48
    80002f3c:	8082                	ret

0000000080002f3e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f3e:	7179                	addi	sp,sp,-48
    80002f40:	f406                	sd	ra,40(sp)
    80002f42:	f022                	sd	s0,32(sp)
    80002f44:	ec26                	sd	s1,24(sp)
    80002f46:	e84a                	sd	s2,16(sp)
    80002f48:	e44e                	sd	s3,8(sp)
    80002f4a:	1800                	addi	s0,sp,48
    80002f4c:	892a                	mv	s2,a0
    80002f4e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f50:	00014517          	auipc	a0,0x14
    80002f54:	a7850513          	addi	a0,a0,-1416 # 800169c8 <bcache>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	cde080e7          	jalr	-802(ra) # 80000c36 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f60:	0001c497          	auipc	s1,0x1c
    80002f64:	d204b483          	ld	s1,-736(s1) # 8001ec80 <bcache+0x82b8>
    80002f68:	0001c797          	auipc	a5,0x1c
    80002f6c:	cc878793          	addi	a5,a5,-824 # 8001ec30 <bcache+0x8268>
    80002f70:	02f48f63          	beq	s1,a5,80002fae <bread+0x70>
    80002f74:	873e                	mv	a4,a5
    80002f76:	a021                	j	80002f7e <bread+0x40>
    80002f78:	68a4                	ld	s1,80(s1)
    80002f7a:	02e48a63          	beq	s1,a4,80002fae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f7e:	449c                	lw	a5,8(s1)
    80002f80:	ff279ce3          	bne	a5,s2,80002f78 <bread+0x3a>
    80002f84:	44dc                	lw	a5,12(s1)
    80002f86:	ff3799e3          	bne	a5,s3,80002f78 <bread+0x3a>
      b->refcnt++;
    80002f8a:	40bc                	lw	a5,64(s1)
    80002f8c:	2785                	addiw	a5,a5,1
    80002f8e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	a3850513          	addi	a0,a0,-1480 # 800169c8 <bcache>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	d88080e7          	jalr	-632(ra) # 80000d20 <release>
      acquiresleep(&b->lock);
    80002fa0:	01048513          	addi	a0,s1,16
    80002fa4:	00001097          	auipc	ra,0x1
    80002fa8:	46e080e7          	jalr	1134(ra) # 80004412 <acquiresleep>
      return b;
    80002fac:	a8b9                	j	8000300a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fae:	0001c497          	auipc	s1,0x1c
    80002fb2:	cca4b483          	ld	s1,-822(s1) # 8001ec78 <bcache+0x82b0>
    80002fb6:	0001c797          	auipc	a5,0x1c
    80002fba:	c7a78793          	addi	a5,a5,-902 # 8001ec30 <bcache+0x8268>
    80002fbe:	00f48863          	beq	s1,a5,80002fce <bread+0x90>
    80002fc2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fc4:	40bc                	lw	a5,64(s1)
    80002fc6:	cf81                	beqz	a5,80002fde <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc8:	64a4                	ld	s1,72(s1)
    80002fca:	fee49de3          	bne	s1,a4,80002fc4 <bread+0x86>
  panic("bget: no buffers");
    80002fce:	00005517          	auipc	a0,0x5
    80002fd2:	57250513          	addi	a0,a0,1394 # 80008540 <syscalls+0xc8>
    80002fd6:	ffffd097          	auipc	ra,0xffffd
    80002fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>
      b->dev = dev;
    80002fde:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fe2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fe6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fea:	4785                	li	a5,1
    80002fec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fee:	00014517          	auipc	a0,0x14
    80002ff2:	9da50513          	addi	a0,a0,-1574 # 800169c8 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	d2a080e7          	jalr	-726(ra) # 80000d20 <release>
      acquiresleep(&b->lock);
    80002ffe:	01048513          	addi	a0,s1,16
    80003002:	00001097          	auipc	ra,0x1
    80003006:	410080e7          	jalr	1040(ra) # 80004412 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000300a:	409c                	lw	a5,0(s1)
    8000300c:	cb89                	beqz	a5,8000301e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000300e:	8526                	mv	a0,s1
    80003010:	70a2                	ld	ra,40(sp)
    80003012:	7402                	ld	s0,32(sp)
    80003014:	64e2                	ld	s1,24(sp)
    80003016:	6942                	ld	s2,16(sp)
    80003018:	69a2                	ld	s3,8(sp)
    8000301a:	6145                	addi	sp,sp,48
    8000301c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000301e:	4581                	li	a1,0
    80003020:	8526                	mv	a0,s1
    80003022:	00003097          	auipc	ra,0x3
    80003026:	fd2080e7          	jalr	-46(ra) # 80005ff4 <virtio_disk_rw>
    b->valid = 1;
    8000302a:	4785                	li	a5,1
    8000302c:	c09c                	sw	a5,0(s1)
  return b;
    8000302e:	b7c5                	j	8000300e <bread+0xd0>

0000000080003030 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	e426                	sd	s1,8(sp)
    80003038:	1000                	addi	s0,sp,32
    8000303a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000303c:	0541                	addi	a0,a0,16
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	46e080e7          	jalr	1134(ra) # 800044ac <holdingsleep>
    80003046:	cd01                	beqz	a0,8000305e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003048:	4585                	li	a1,1
    8000304a:	8526                	mv	a0,s1
    8000304c:	00003097          	auipc	ra,0x3
    80003050:	fa8080e7          	jalr	-88(ra) # 80005ff4 <virtio_disk_rw>
}
    80003054:	60e2                	ld	ra,24(sp)
    80003056:	6442                	ld	s0,16(sp)
    80003058:	64a2                	ld	s1,8(sp)
    8000305a:	6105                	addi	sp,sp,32
    8000305c:	8082                	ret
    panic("bwrite");
    8000305e:	00005517          	auipc	a0,0x5
    80003062:	4fa50513          	addi	a0,a0,1274 # 80008558 <syscalls+0xe0>
    80003066:	ffffd097          	auipc	ra,0xffffd
    8000306a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>

000000008000306e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000306e:	1101                	addi	sp,sp,-32
    80003070:	ec06                	sd	ra,24(sp)
    80003072:	e822                	sd	s0,16(sp)
    80003074:	e426                	sd	s1,8(sp)
    80003076:	e04a                	sd	s2,0(sp)
    80003078:	1000                	addi	s0,sp,32
    8000307a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000307c:	01050913          	addi	s2,a0,16
    80003080:	854a                	mv	a0,s2
    80003082:	00001097          	auipc	ra,0x1
    80003086:	42a080e7          	jalr	1066(ra) # 800044ac <holdingsleep>
    8000308a:	c92d                	beqz	a0,800030fc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000308c:	854a                	mv	a0,s2
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	3da080e7          	jalr	986(ra) # 80004468 <releasesleep>

  acquire(&bcache.lock);
    80003096:	00014517          	auipc	a0,0x14
    8000309a:	93250513          	addi	a0,a0,-1742 # 800169c8 <bcache>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	b98080e7          	jalr	-1128(ra) # 80000c36 <acquire>
  b->refcnt--;
    800030a6:	40bc                	lw	a5,64(s1)
    800030a8:	37fd                	addiw	a5,a5,-1
    800030aa:	0007871b          	sext.w	a4,a5
    800030ae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030b0:	eb05                	bnez	a4,800030e0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030b2:	68bc                	ld	a5,80(s1)
    800030b4:	64b8                	ld	a4,72(s1)
    800030b6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b8:	64bc                	ld	a5,72(s1)
    800030ba:	68b8                	ld	a4,80(s1)
    800030bc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030be:	0001c797          	auipc	a5,0x1c
    800030c2:	90a78793          	addi	a5,a5,-1782 # 8001e9c8 <bcache+0x8000>
    800030c6:	2b87b703          	ld	a4,696(a5)
    800030ca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030cc:	0001c717          	auipc	a4,0x1c
    800030d0:	b6470713          	addi	a4,a4,-1180 # 8001ec30 <bcache+0x8268>
    800030d4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030d6:	2b87b703          	ld	a4,696(a5)
    800030da:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030dc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030e0:	00014517          	auipc	a0,0x14
    800030e4:	8e850513          	addi	a0,a0,-1816 # 800169c8 <bcache>
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	c38080e7          	jalr	-968(ra) # 80000d20 <release>
}
    800030f0:	60e2                	ld	ra,24(sp)
    800030f2:	6442                	ld	s0,16(sp)
    800030f4:	64a2                	ld	s1,8(sp)
    800030f6:	6902                	ld	s2,0(sp)
    800030f8:	6105                	addi	sp,sp,32
    800030fa:	8082                	ret
    panic("brelse");
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	46450513          	addi	a0,a0,1124 # 80008560 <syscalls+0xe8>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	43a080e7          	jalr	1082(ra) # 8000053e <panic>

000000008000310c <bpin>:

void
bpin(struct buf *b) {
    8000310c:	1101                	addi	sp,sp,-32
    8000310e:	ec06                	sd	ra,24(sp)
    80003110:	e822                	sd	s0,16(sp)
    80003112:	e426                	sd	s1,8(sp)
    80003114:	1000                	addi	s0,sp,32
    80003116:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003118:	00014517          	auipc	a0,0x14
    8000311c:	8b050513          	addi	a0,a0,-1872 # 800169c8 <bcache>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	b16080e7          	jalr	-1258(ra) # 80000c36 <acquire>
  b->refcnt++;
    80003128:	40bc                	lw	a5,64(s1)
    8000312a:	2785                	addiw	a5,a5,1
    8000312c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000312e:	00014517          	auipc	a0,0x14
    80003132:	89a50513          	addi	a0,a0,-1894 # 800169c8 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	bea080e7          	jalr	-1046(ra) # 80000d20 <release>
}
    8000313e:	60e2                	ld	ra,24(sp)
    80003140:	6442                	ld	s0,16(sp)
    80003142:	64a2                	ld	s1,8(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret

0000000080003148 <bunpin>:

void
bunpin(struct buf *b) {
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	e426                	sd	s1,8(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	87450513          	addi	a0,a0,-1932 # 800169c8 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	ada080e7          	jalr	-1318(ra) # 80000c36 <acquire>
  b->refcnt--;
    80003164:	40bc                	lw	a5,64(s1)
    80003166:	37fd                	addiw	a5,a5,-1
    80003168:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000316a:	00014517          	auipc	a0,0x14
    8000316e:	85e50513          	addi	a0,a0,-1954 # 800169c8 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	bae080e7          	jalr	-1106(ra) # 80000d20 <release>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	e04a                	sd	s2,0(sp)
    8000318e:	1000                	addi	s0,sp,32
    80003190:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003192:	00d5d59b          	srliw	a1,a1,0xd
    80003196:	0001c797          	auipc	a5,0x1c
    8000319a:	f0e7a783          	lw	a5,-242(a5) # 8001f0a4 <sb+0x1c>
    8000319e:	9dbd                	addw	a1,a1,a5
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	d9e080e7          	jalr	-610(ra) # 80002f3e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a8:	0074f713          	andi	a4,s1,7
    800031ac:	4785                	li	a5,1
    800031ae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031b2:	14ce                	slli	s1,s1,0x33
    800031b4:	90d9                	srli	s1,s1,0x36
    800031b6:	00950733          	add	a4,a0,s1
    800031ba:	05874703          	lbu	a4,88(a4)
    800031be:	00e7f6b3          	and	a3,a5,a4
    800031c2:	c69d                	beqz	a3,800031f0 <bfree+0x6c>
    800031c4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031c6:	94aa                	add	s1,s1,a0
    800031c8:	fff7c793          	not	a5,a5
    800031cc:	8ff9                	and	a5,a5,a4
    800031ce:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031d2:	00001097          	auipc	ra,0x1
    800031d6:	120080e7          	jalr	288(ra) # 800042f2 <log_write>
  brelse(bp);
    800031da:	854a                	mv	a0,s2
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	e92080e7          	jalr	-366(ra) # 8000306e <brelse>
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6902                	ld	s2,0(sp)
    800031ec:	6105                	addi	sp,sp,32
    800031ee:	8082                	ret
    panic("freeing free block");
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	37850513          	addi	a0,a0,888 # 80008568 <syscalls+0xf0>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	346080e7          	jalr	838(ra) # 8000053e <panic>

0000000080003200 <balloc>:
{
    80003200:	711d                	addi	sp,sp,-96
    80003202:	ec86                	sd	ra,88(sp)
    80003204:	e8a2                	sd	s0,80(sp)
    80003206:	e4a6                	sd	s1,72(sp)
    80003208:	e0ca                	sd	s2,64(sp)
    8000320a:	fc4e                	sd	s3,56(sp)
    8000320c:	f852                	sd	s4,48(sp)
    8000320e:	f456                	sd	s5,40(sp)
    80003210:	f05a                	sd	s6,32(sp)
    80003212:	ec5e                	sd	s7,24(sp)
    80003214:	e862                	sd	s8,16(sp)
    80003216:	e466                	sd	s9,8(sp)
    80003218:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000321a:	0001c797          	auipc	a5,0x1c
    8000321e:	e727a783          	lw	a5,-398(a5) # 8001f08c <sb+0x4>
    80003222:	10078163          	beqz	a5,80003324 <balloc+0x124>
    80003226:	8baa                	mv	s7,a0
    80003228:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000322a:	0001cb17          	auipc	s6,0x1c
    8000322e:	e5eb0b13          	addi	s6,s6,-418 # 8001f088 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003232:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003234:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003236:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003238:	6c89                	lui	s9,0x2
    8000323a:	a061                	j	800032c2 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000323c:	974a                	add	a4,a4,s2
    8000323e:	8fd5                	or	a5,a5,a3
    80003240:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003244:	854a                	mv	a0,s2
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	0ac080e7          	jalr	172(ra) # 800042f2 <log_write>
        brelse(bp);
    8000324e:	854a                	mv	a0,s2
    80003250:	00000097          	auipc	ra,0x0
    80003254:	e1e080e7          	jalr	-482(ra) # 8000306e <brelse>
  bp = bread(dev, bno);
    80003258:	85a6                	mv	a1,s1
    8000325a:	855e                	mv	a0,s7
    8000325c:	00000097          	auipc	ra,0x0
    80003260:	ce2080e7          	jalr	-798(ra) # 80002f3e <bread>
    80003264:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003266:	40000613          	li	a2,1024
    8000326a:	4581                	li	a1,0
    8000326c:	05850513          	addi	a0,a0,88
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	afe080e7          	jalr	-1282(ra) # 80000d6e <memset>
  log_write(bp);
    80003278:	854a                	mv	a0,s2
    8000327a:	00001097          	auipc	ra,0x1
    8000327e:	078080e7          	jalr	120(ra) # 800042f2 <log_write>
  brelse(bp);
    80003282:	854a                	mv	a0,s2
    80003284:	00000097          	auipc	ra,0x0
    80003288:	dea080e7          	jalr	-534(ra) # 8000306e <brelse>
}
    8000328c:	8526                	mv	a0,s1
    8000328e:	60e6                	ld	ra,88(sp)
    80003290:	6446                	ld	s0,80(sp)
    80003292:	64a6                	ld	s1,72(sp)
    80003294:	6906                	ld	s2,64(sp)
    80003296:	79e2                	ld	s3,56(sp)
    80003298:	7a42                	ld	s4,48(sp)
    8000329a:	7aa2                	ld	s5,40(sp)
    8000329c:	7b02                	ld	s6,32(sp)
    8000329e:	6be2                	ld	s7,24(sp)
    800032a0:	6c42                	ld	s8,16(sp)
    800032a2:	6ca2                	ld	s9,8(sp)
    800032a4:	6125                	addi	sp,sp,96
    800032a6:	8082                	ret
    brelse(bp);
    800032a8:	854a                	mv	a0,s2
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	dc4080e7          	jalr	-572(ra) # 8000306e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032b2:	015c87bb          	addw	a5,s9,s5
    800032b6:	00078a9b          	sext.w	s5,a5
    800032ba:	004b2703          	lw	a4,4(s6)
    800032be:	06eaf363          	bgeu	s5,a4,80003324 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800032c2:	41fad79b          	sraiw	a5,s5,0x1f
    800032c6:	0137d79b          	srliw	a5,a5,0x13
    800032ca:	015787bb          	addw	a5,a5,s5
    800032ce:	40d7d79b          	sraiw	a5,a5,0xd
    800032d2:	01cb2583          	lw	a1,28(s6)
    800032d6:	9dbd                	addw	a1,a1,a5
    800032d8:	855e                	mv	a0,s7
    800032da:	00000097          	auipc	ra,0x0
    800032de:	c64080e7          	jalr	-924(ra) # 80002f3e <bread>
    800032e2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e4:	004b2503          	lw	a0,4(s6)
    800032e8:	000a849b          	sext.w	s1,s5
    800032ec:	8662                	mv	a2,s8
    800032ee:	faa4fde3          	bgeu	s1,a0,800032a8 <balloc+0xa8>
      m = 1 << (bi % 8);
    800032f2:	41f6579b          	sraiw	a5,a2,0x1f
    800032f6:	01d7d69b          	srliw	a3,a5,0x1d
    800032fa:	00c6873b          	addw	a4,a3,a2
    800032fe:	00777793          	andi	a5,a4,7
    80003302:	9f95                	subw	a5,a5,a3
    80003304:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003308:	4037571b          	sraiw	a4,a4,0x3
    8000330c:	00e906b3          	add	a3,s2,a4
    80003310:	0586c683          	lbu	a3,88(a3)
    80003314:	00d7f5b3          	and	a1,a5,a3
    80003318:	d195                	beqz	a1,8000323c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331a:	2605                	addiw	a2,a2,1
    8000331c:	2485                	addiw	s1,s1,1
    8000331e:	fd4618e3          	bne	a2,s4,800032ee <balloc+0xee>
    80003322:	b759                	j	800032a8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003324:	00005517          	auipc	a0,0x5
    80003328:	25c50513          	addi	a0,a0,604 # 80008580 <syscalls+0x108>
    8000332c:	ffffd097          	auipc	ra,0xffffd
    80003330:	25c080e7          	jalr	604(ra) # 80000588 <printf>
  return 0;
    80003334:	4481                	li	s1,0
    80003336:	bf99                	j	8000328c <balloc+0x8c>

0000000080003338 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003338:	7179                	addi	sp,sp,-48
    8000333a:	f406                	sd	ra,40(sp)
    8000333c:	f022                	sd	s0,32(sp)
    8000333e:	ec26                	sd	s1,24(sp)
    80003340:	e84a                	sd	s2,16(sp)
    80003342:	e44e                	sd	s3,8(sp)
    80003344:	e052                	sd	s4,0(sp)
    80003346:	1800                	addi	s0,sp,48
    80003348:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000334a:	47ad                	li	a5,11
    8000334c:	02b7e763          	bltu	a5,a1,8000337a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003350:	02059493          	slli	s1,a1,0x20
    80003354:	9081                	srli	s1,s1,0x20
    80003356:	048a                	slli	s1,s1,0x2
    80003358:	94aa                	add	s1,s1,a0
    8000335a:	0504a903          	lw	s2,80(s1)
    8000335e:	06091e63          	bnez	s2,800033da <bmap+0xa2>
      addr = balloc(ip->dev);
    80003362:	4108                	lw	a0,0(a0)
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e9c080e7          	jalr	-356(ra) # 80003200 <balloc>
    8000336c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003370:	06090563          	beqz	s2,800033da <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003374:	0524a823          	sw	s2,80(s1)
    80003378:	a08d                	j	800033da <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000337a:	ff45849b          	addiw	s1,a1,-12
    8000337e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003382:	0ff00793          	li	a5,255
    80003386:	08e7e563          	bltu	a5,a4,80003410 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000338a:	08052903          	lw	s2,128(a0)
    8000338e:	00091d63          	bnez	s2,800033a8 <bmap+0x70>
      addr = balloc(ip->dev);
    80003392:	4108                	lw	a0,0(a0)
    80003394:	00000097          	auipc	ra,0x0
    80003398:	e6c080e7          	jalr	-404(ra) # 80003200 <balloc>
    8000339c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033a0:	02090d63          	beqz	s2,800033da <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033a4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033a8:	85ca                	mv	a1,s2
    800033aa:	0009a503          	lw	a0,0(s3)
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	b90080e7          	jalr	-1136(ra) # 80002f3e <bread>
    800033b6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033b8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033bc:	02049593          	slli	a1,s1,0x20
    800033c0:	9181                	srli	a1,a1,0x20
    800033c2:	058a                	slli	a1,a1,0x2
    800033c4:	00b784b3          	add	s1,a5,a1
    800033c8:	0004a903          	lw	s2,0(s1)
    800033cc:	02090063          	beqz	s2,800033ec <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033d0:	8552                	mv	a0,s4
    800033d2:	00000097          	auipc	ra,0x0
    800033d6:	c9c080e7          	jalr	-868(ra) # 8000306e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033da:	854a                	mv	a0,s2
    800033dc:	70a2                	ld	ra,40(sp)
    800033de:	7402                	ld	s0,32(sp)
    800033e0:	64e2                	ld	s1,24(sp)
    800033e2:	6942                	ld	s2,16(sp)
    800033e4:	69a2                	ld	s3,8(sp)
    800033e6:	6a02                	ld	s4,0(sp)
    800033e8:	6145                	addi	sp,sp,48
    800033ea:	8082                	ret
      addr = balloc(ip->dev);
    800033ec:	0009a503          	lw	a0,0(s3)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e10080e7          	jalr	-496(ra) # 80003200 <balloc>
    800033f8:	0005091b          	sext.w	s2,a0
      if(addr){
    800033fc:	fc090ae3          	beqz	s2,800033d0 <bmap+0x98>
        a[bn] = addr;
    80003400:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003404:	8552                	mv	a0,s4
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	eec080e7          	jalr	-276(ra) # 800042f2 <log_write>
    8000340e:	b7c9                	j	800033d0 <bmap+0x98>
  panic("bmap: out of range");
    80003410:	00005517          	auipc	a0,0x5
    80003414:	18850513          	addi	a0,a0,392 # 80008598 <syscalls+0x120>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	126080e7          	jalr	294(ra) # 8000053e <panic>

0000000080003420 <iget>:
{
    80003420:	7179                	addi	sp,sp,-48
    80003422:	f406                	sd	ra,40(sp)
    80003424:	f022                	sd	s0,32(sp)
    80003426:	ec26                	sd	s1,24(sp)
    80003428:	e84a                	sd	s2,16(sp)
    8000342a:	e44e                	sd	s3,8(sp)
    8000342c:	e052                	sd	s4,0(sp)
    8000342e:	1800                	addi	s0,sp,48
    80003430:	89aa                	mv	s3,a0
    80003432:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003434:	0001c517          	auipc	a0,0x1c
    80003438:	c7450513          	addi	a0,a0,-908 # 8001f0a8 <itable>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	7fa080e7          	jalr	2042(ra) # 80000c36 <acquire>
  empty = 0;
    80003444:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003446:	0001c497          	auipc	s1,0x1c
    8000344a:	c7a48493          	addi	s1,s1,-902 # 8001f0c0 <itable+0x18>
    8000344e:	0001d697          	auipc	a3,0x1d
    80003452:	70268693          	addi	a3,a3,1794 # 80020b50 <log>
    80003456:	a039                	j	80003464 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003458:	02090b63          	beqz	s2,8000348e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000345c:	08848493          	addi	s1,s1,136
    80003460:	02d48a63          	beq	s1,a3,80003494 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003464:	449c                	lw	a5,8(s1)
    80003466:	fef059e3          	blez	a5,80003458 <iget+0x38>
    8000346a:	4098                	lw	a4,0(s1)
    8000346c:	ff3716e3          	bne	a4,s3,80003458 <iget+0x38>
    80003470:	40d8                	lw	a4,4(s1)
    80003472:	ff4713e3          	bne	a4,s4,80003458 <iget+0x38>
      ip->ref++;
    80003476:	2785                	addiw	a5,a5,1
    80003478:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000347a:	0001c517          	auipc	a0,0x1c
    8000347e:	c2e50513          	addi	a0,a0,-978 # 8001f0a8 <itable>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	89e080e7          	jalr	-1890(ra) # 80000d20 <release>
      return ip;
    8000348a:	8926                	mv	s2,s1
    8000348c:	a03d                	j	800034ba <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000348e:	f7f9                	bnez	a5,8000345c <iget+0x3c>
    80003490:	8926                	mv	s2,s1
    80003492:	b7e9                	j	8000345c <iget+0x3c>
  if(empty == 0)
    80003494:	02090c63          	beqz	s2,800034cc <iget+0xac>
  ip->dev = dev;
    80003498:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000349c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034a0:	4785                	li	a5,1
    800034a2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034a6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034aa:	0001c517          	auipc	a0,0x1c
    800034ae:	bfe50513          	addi	a0,a0,-1026 # 8001f0a8 <itable>
    800034b2:	ffffe097          	auipc	ra,0xffffe
    800034b6:	86e080e7          	jalr	-1938(ra) # 80000d20 <release>
}
    800034ba:	854a                	mv	a0,s2
    800034bc:	70a2                	ld	ra,40(sp)
    800034be:	7402                	ld	s0,32(sp)
    800034c0:	64e2                	ld	s1,24(sp)
    800034c2:	6942                	ld	s2,16(sp)
    800034c4:	69a2                	ld	s3,8(sp)
    800034c6:	6a02                	ld	s4,0(sp)
    800034c8:	6145                	addi	sp,sp,48
    800034ca:	8082                	ret
    panic("iget: no inodes");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	0e450513          	addi	a0,a0,228 # 800085b0 <syscalls+0x138>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>

00000000800034dc <fsinit>:
fsinit(int dev) {
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	1800                	addi	s0,sp,48
    800034ea:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034ec:	4585                	li	a1,1
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	a50080e7          	jalr	-1456(ra) # 80002f3e <bread>
    800034f6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034f8:	0001c997          	auipc	s3,0x1c
    800034fc:	b9098993          	addi	s3,s3,-1136 # 8001f088 <sb>
    80003500:	02000613          	li	a2,32
    80003504:	05850593          	addi	a1,a0,88
    80003508:	854e                	mv	a0,s3
    8000350a:	ffffe097          	auipc	ra,0xffffe
    8000350e:	8c0080e7          	jalr	-1856(ra) # 80000dca <memmove>
  brelse(bp);
    80003512:	8526                	mv	a0,s1
    80003514:	00000097          	auipc	ra,0x0
    80003518:	b5a080e7          	jalr	-1190(ra) # 8000306e <brelse>
  if(sb.magic != FSMAGIC)
    8000351c:	0009a703          	lw	a4,0(s3)
    80003520:	102037b7          	lui	a5,0x10203
    80003524:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003528:	02f71263          	bne	a4,a5,8000354c <fsinit+0x70>
  initlog(dev, &sb);
    8000352c:	0001c597          	auipc	a1,0x1c
    80003530:	b5c58593          	addi	a1,a1,-1188 # 8001f088 <sb>
    80003534:	854a                	mv	a0,s2
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	b40080e7          	jalr	-1216(ra) # 80004076 <initlog>
}
    8000353e:	70a2                	ld	ra,40(sp)
    80003540:	7402                	ld	s0,32(sp)
    80003542:	64e2                	ld	s1,24(sp)
    80003544:	6942                	ld	s2,16(sp)
    80003546:	69a2                	ld	s3,8(sp)
    80003548:	6145                	addi	sp,sp,48
    8000354a:	8082                	ret
    panic("invalid file system");
    8000354c:	00005517          	auipc	a0,0x5
    80003550:	07450513          	addi	a0,a0,116 # 800085c0 <syscalls+0x148>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>

000000008000355c <iinit>:
{
    8000355c:	7179                	addi	sp,sp,-48
    8000355e:	f406                	sd	ra,40(sp)
    80003560:	f022                	sd	s0,32(sp)
    80003562:	ec26                	sd	s1,24(sp)
    80003564:	e84a                	sd	s2,16(sp)
    80003566:	e44e                	sd	s3,8(sp)
    80003568:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000356a:	00005597          	auipc	a1,0x5
    8000356e:	06e58593          	addi	a1,a1,110 # 800085d8 <syscalls+0x160>
    80003572:	0001c517          	auipc	a0,0x1c
    80003576:	b3650513          	addi	a0,a0,-1226 # 8001f0a8 <itable>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	628080e7          	jalr	1576(ra) # 80000ba2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003582:	0001c497          	auipc	s1,0x1c
    80003586:	b4e48493          	addi	s1,s1,-1202 # 8001f0d0 <itable+0x28>
    8000358a:	0001d997          	auipc	s3,0x1d
    8000358e:	5d698993          	addi	s3,s3,1494 # 80020b60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003592:	00005917          	auipc	s2,0x5
    80003596:	04e90913          	addi	s2,s2,78 # 800085e0 <syscalls+0x168>
    8000359a:	85ca                	mv	a1,s2
    8000359c:	8526                	mv	a0,s1
    8000359e:	00001097          	auipc	ra,0x1
    800035a2:	e3a080e7          	jalr	-454(ra) # 800043d8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035a6:	08848493          	addi	s1,s1,136
    800035aa:	ff3498e3          	bne	s1,s3,8000359a <iinit+0x3e>
}
    800035ae:	70a2                	ld	ra,40(sp)
    800035b0:	7402                	ld	s0,32(sp)
    800035b2:	64e2                	ld	s1,24(sp)
    800035b4:	6942                	ld	s2,16(sp)
    800035b6:	69a2                	ld	s3,8(sp)
    800035b8:	6145                	addi	sp,sp,48
    800035ba:	8082                	ret

00000000800035bc <ialloc>:
{
    800035bc:	715d                	addi	sp,sp,-80
    800035be:	e486                	sd	ra,72(sp)
    800035c0:	e0a2                	sd	s0,64(sp)
    800035c2:	fc26                	sd	s1,56(sp)
    800035c4:	f84a                	sd	s2,48(sp)
    800035c6:	f44e                	sd	s3,40(sp)
    800035c8:	f052                	sd	s4,32(sp)
    800035ca:	ec56                	sd	s5,24(sp)
    800035cc:	e85a                	sd	s6,16(sp)
    800035ce:	e45e                	sd	s7,8(sp)
    800035d0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d2:	0001c717          	auipc	a4,0x1c
    800035d6:	ac272703          	lw	a4,-1342(a4) # 8001f094 <sb+0xc>
    800035da:	4785                	li	a5,1
    800035dc:	04e7fa63          	bgeu	a5,a4,80003630 <ialloc+0x74>
    800035e0:	8aaa                	mv	s5,a0
    800035e2:	8bae                	mv	s7,a1
    800035e4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035e6:	0001ca17          	auipc	s4,0x1c
    800035ea:	aa2a0a13          	addi	s4,s4,-1374 # 8001f088 <sb>
    800035ee:	00048b1b          	sext.w	s6,s1
    800035f2:	0044d793          	srli	a5,s1,0x4
    800035f6:	018a2583          	lw	a1,24(s4)
    800035fa:	9dbd                	addw	a1,a1,a5
    800035fc:	8556                	mv	a0,s5
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	940080e7          	jalr	-1728(ra) # 80002f3e <bread>
    80003606:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003608:	05850993          	addi	s3,a0,88
    8000360c:	00f4f793          	andi	a5,s1,15
    80003610:	079a                	slli	a5,a5,0x6
    80003612:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003614:	00099783          	lh	a5,0(s3)
    80003618:	c3a1                	beqz	a5,80003658 <ialloc+0x9c>
    brelse(bp);
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	a54080e7          	jalr	-1452(ra) # 8000306e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003622:	0485                	addi	s1,s1,1
    80003624:	00ca2703          	lw	a4,12(s4)
    80003628:	0004879b          	sext.w	a5,s1
    8000362c:	fce7e1e3          	bltu	a5,a4,800035ee <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	fb850513          	addi	a0,a0,-72 # 800085e8 <syscalls+0x170>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f50080e7          	jalr	-176(ra) # 80000588 <printf>
  return 0;
    80003640:	4501                	li	a0,0
}
    80003642:	60a6                	ld	ra,72(sp)
    80003644:	6406                	ld	s0,64(sp)
    80003646:	74e2                	ld	s1,56(sp)
    80003648:	7942                	ld	s2,48(sp)
    8000364a:	79a2                	ld	s3,40(sp)
    8000364c:	7a02                	ld	s4,32(sp)
    8000364e:	6ae2                	ld	s5,24(sp)
    80003650:	6b42                	ld	s6,16(sp)
    80003652:	6ba2                	ld	s7,8(sp)
    80003654:	6161                	addi	sp,sp,80
    80003656:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003658:	04000613          	li	a2,64
    8000365c:	4581                	li	a1,0
    8000365e:	854e                	mv	a0,s3
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	70e080e7          	jalr	1806(ra) # 80000d6e <memset>
      dip->type = type;
    80003668:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000366c:	854a                	mv	a0,s2
    8000366e:	00001097          	auipc	ra,0x1
    80003672:	c84080e7          	jalr	-892(ra) # 800042f2 <log_write>
      brelse(bp);
    80003676:	854a                	mv	a0,s2
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	9f6080e7          	jalr	-1546(ra) # 8000306e <brelse>
      return iget(dev, inum);
    80003680:	85da                	mv	a1,s6
    80003682:	8556                	mv	a0,s5
    80003684:	00000097          	auipc	ra,0x0
    80003688:	d9c080e7          	jalr	-612(ra) # 80003420 <iget>
    8000368c:	bf5d                	j	80003642 <ialloc+0x86>

000000008000368e <iupdate>:
{
    8000368e:	1101                	addi	sp,sp,-32
    80003690:	ec06                	sd	ra,24(sp)
    80003692:	e822                	sd	s0,16(sp)
    80003694:	e426                	sd	s1,8(sp)
    80003696:	e04a                	sd	s2,0(sp)
    80003698:	1000                	addi	s0,sp,32
    8000369a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000369c:	415c                	lw	a5,4(a0)
    8000369e:	0047d79b          	srliw	a5,a5,0x4
    800036a2:	0001c597          	auipc	a1,0x1c
    800036a6:	9fe5a583          	lw	a1,-1538(a1) # 8001f0a0 <sb+0x18>
    800036aa:	9dbd                	addw	a1,a1,a5
    800036ac:	4108                	lw	a0,0(a0)
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	890080e7          	jalr	-1904(ra) # 80002f3e <bread>
    800036b6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b8:	05850793          	addi	a5,a0,88
    800036bc:	40c8                	lw	a0,4(s1)
    800036be:	893d                	andi	a0,a0,15
    800036c0:	051a                	slli	a0,a0,0x6
    800036c2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036c4:	04449703          	lh	a4,68(s1)
    800036c8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036cc:	04649703          	lh	a4,70(s1)
    800036d0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036d4:	04849703          	lh	a4,72(s1)
    800036d8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036dc:	04a49703          	lh	a4,74(s1)
    800036e0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036e4:	44f8                	lw	a4,76(s1)
    800036e6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036e8:	03400613          	li	a2,52
    800036ec:	05048593          	addi	a1,s1,80
    800036f0:	0531                	addi	a0,a0,12
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	6d8080e7          	jalr	1752(ra) # 80000dca <memmove>
  log_write(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	00001097          	auipc	ra,0x1
    80003700:	bf6080e7          	jalr	-1034(ra) # 800042f2 <log_write>
  brelse(bp);
    80003704:	854a                	mv	a0,s2
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	968080e7          	jalr	-1688(ra) # 8000306e <brelse>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6902                	ld	s2,0(sp)
    80003716:	6105                	addi	sp,sp,32
    80003718:	8082                	ret

000000008000371a <idup>:
{
    8000371a:	1101                	addi	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003726:	0001c517          	auipc	a0,0x1c
    8000372a:	98250513          	addi	a0,a0,-1662 # 8001f0a8 <itable>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	508080e7          	jalr	1288(ra) # 80000c36 <acquire>
  ip->ref++;
    80003736:	449c                	lw	a5,8(s1)
    80003738:	2785                	addiw	a5,a5,1
    8000373a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000373c:	0001c517          	auipc	a0,0x1c
    80003740:	96c50513          	addi	a0,a0,-1684 # 8001f0a8 <itable>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	5dc080e7          	jalr	1500(ra) # 80000d20 <release>
}
    8000374c:	8526                	mv	a0,s1
    8000374e:	60e2                	ld	ra,24(sp)
    80003750:	6442                	ld	s0,16(sp)
    80003752:	64a2                	ld	s1,8(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret

0000000080003758 <ilock>:
{
    80003758:	1101                	addi	sp,sp,-32
    8000375a:	ec06                	sd	ra,24(sp)
    8000375c:	e822                	sd	s0,16(sp)
    8000375e:	e426                	sd	s1,8(sp)
    80003760:	e04a                	sd	s2,0(sp)
    80003762:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003764:	c115                	beqz	a0,80003788 <ilock+0x30>
    80003766:	84aa                	mv	s1,a0
    80003768:	451c                	lw	a5,8(a0)
    8000376a:	00f05f63          	blez	a5,80003788 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000376e:	0541                	addi	a0,a0,16
    80003770:	00001097          	auipc	ra,0x1
    80003774:	ca2080e7          	jalr	-862(ra) # 80004412 <acquiresleep>
  if(ip->valid == 0){
    80003778:	40bc                	lw	a5,64(s1)
    8000377a:	cf99                	beqz	a5,80003798 <ilock+0x40>
}
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6902                	ld	s2,0(sp)
    80003784:	6105                	addi	sp,sp,32
    80003786:	8082                	ret
    panic("ilock");
    80003788:	00005517          	auipc	a0,0x5
    8000378c:	e7850513          	addi	a0,a0,-392 # 80008600 <syscalls+0x188>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	dae080e7          	jalr	-594(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003798:	40dc                	lw	a5,4(s1)
    8000379a:	0047d79b          	srliw	a5,a5,0x4
    8000379e:	0001c597          	auipc	a1,0x1c
    800037a2:	9025a583          	lw	a1,-1790(a1) # 8001f0a0 <sb+0x18>
    800037a6:	9dbd                	addw	a1,a1,a5
    800037a8:	4088                	lw	a0,0(s1)
    800037aa:	fffff097          	auipc	ra,0xfffff
    800037ae:	794080e7          	jalr	1940(ra) # 80002f3e <bread>
    800037b2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b4:	05850593          	addi	a1,a0,88
    800037b8:	40dc                	lw	a5,4(s1)
    800037ba:	8bbd                	andi	a5,a5,15
    800037bc:	079a                	slli	a5,a5,0x6
    800037be:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037c0:	00059783          	lh	a5,0(a1)
    800037c4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037c8:	00259783          	lh	a5,2(a1)
    800037cc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037d0:	00459783          	lh	a5,4(a1)
    800037d4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037d8:	00659783          	lh	a5,6(a1)
    800037dc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037e0:	459c                	lw	a5,8(a1)
    800037e2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037e4:	03400613          	li	a2,52
    800037e8:	05b1                	addi	a1,a1,12
    800037ea:	05048513          	addi	a0,s1,80
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	5dc080e7          	jalr	1500(ra) # 80000dca <memmove>
    brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	876080e7          	jalr	-1930(ra) # 8000306e <brelse>
    ip->valid = 1;
    80003800:	4785                	li	a5,1
    80003802:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003804:	04449783          	lh	a5,68(s1)
    80003808:	fbb5                	bnez	a5,8000377c <ilock+0x24>
      panic("ilock: no type");
    8000380a:	00005517          	auipc	a0,0x5
    8000380e:	dfe50513          	addi	a0,a0,-514 # 80008608 <syscalls+0x190>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>

000000008000381a <iunlock>:
{
    8000381a:	1101                	addi	sp,sp,-32
    8000381c:	ec06                	sd	ra,24(sp)
    8000381e:	e822                	sd	s0,16(sp)
    80003820:	e426                	sd	s1,8(sp)
    80003822:	e04a                	sd	s2,0(sp)
    80003824:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003826:	c905                	beqz	a0,80003856 <iunlock+0x3c>
    80003828:	84aa                	mv	s1,a0
    8000382a:	01050913          	addi	s2,a0,16
    8000382e:	854a                	mv	a0,s2
    80003830:	00001097          	auipc	ra,0x1
    80003834:	c7c080e7          	jalr	-900(ra) # 800044ac <holdingsleep>
    80003838:	cd19                	beqz	a0,80003856 <iunlock+0x3c>
    8000383a:	449c                	lw	a5,8(s1)
    8000383c:	00f05d63          	blez	a5,80003856 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003840:	854a                	mv	a0,s2
    80003842:	00001097          	auipc	ra,0x1
    80003846:	c26080e7          	jalr	-986(ra) # 80004468 <releasesleep>
}
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6902                	ld	s2,0(sp)
    80003852:	6105                	addi	sp,sp,32
    80003854:	8082                	ret
    panic("iunlock");
    80003856:	00005517          	auipc	a0,0x5
    8000385a:	dc250513          	addi	a0,a0,-574 # 80008618 <syscalls+0x1a0>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>

0000000080003866 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003866:	7179                	addi	sp,sp,-48
    80003868:	f406                	sd	ra,40(sp)
    8000386a:	f022                	sd	s0,32(sp)
    8000386c:	ec26                	sd	s1,24(sp)
    8000386e:	e84a                	sd	s2,16(sp)
    80003870:	e44e                	sd	s3,8(sp)
    80003872:	e052                	sd	s4,0(sp)
    80003874:	1800                	addi	s0,sp,48
    80003876:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003878:	05050493          	addi	s1,a0,80
    8000387c:	08050913          	addi	s2,a0,128
    80003880:	a021                	j	80003888 <itrunc+0x22>
    80003882:	0491                	addi	s1,s1,4
    80003884:	01248d63          	beq	s1,s2,8000389e <itrunc+0x38>
    if(ip->addrs[i]){
    80003888:	408c                	lw	a1,0(s1)
    8000388a:	dde5                	beqz	a1,80003882 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000388c:	0009a503          	lw	a0,0(s3)
    80003890:	00000097          	auipc	ra,0x0
    80003894:	8f4080e7          	jalr	-1804(ra) # 80003184 <bfree>
      ip->addrs[i] = 0;
    80003898:	0004a023          	sw	zero,0(s1)
    8000389c:	b7dd                	j	80003882 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000389e:	0809a583          	lw	a1,128(s3)
    800038a2:	e185                	bnez	a1,800038c2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038a4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038a8:	854e                	mv	a0,s3
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	de4080e7          	jalr	-540(ra) # 8000368e <iupdate>
}
    800038b2:	70a2                	ld	ra,40(sp)
    800038b4:	7402                	ld	s0,32(sp)
    800038b6:	64e2                	ld	s1,24(sp)
    800038b8:	6942                	ld	s2,16(sp)
    800038ba:	69a2                	ld	s3,8(sp)
    800038bc:	6a02                	ld	s4,0(sp)
    800038be:	6145                	addi	sp,sp,48
    800038c0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038c2:	0009a503          	lw	a0,0(s3)
    800038c6:	fffff097          	auipc	ra,0xfffff
    800038ca:	678080e7          	jalr	1656(ra) # 80002f3e <bread>
    800038ce:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038d0:	05850493          	addi	s1,a0,88
    800038d4:	45850913          	addi	s2,a0,1112
    800038d8:	a021                	j	800038e0 <itrunc+0x7a>
    800038da:	0491                	addi	s1,s1,4
    800038dc:	01248b63          	beq	s1,s2,800038f2 <itrunc+0x8c>
      if(a[j])
    800038e0:	408c                	lw	a1,0(s1)
    800038e2:	dde5                	beqz	a1,800038da <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038e4:	0009a503          	lw	a0,0(s3)
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	89c080e7          	jalr	-1892(ra) # 80003184 <bfree>
    800038f0:	b7ed                	j	800038da <itrunc+0x74>
    brelse(bp);
    800038f2:	8552                	mv	a0,s4
    800038f4:	fffff097          	auipc	ra,0xfffff
    800038f8:	77a080e7          	jalr	1914(ra) # 8000306e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038fc:	0809a583          	lw	a1,128(s3)
    80003900:	0009a503          	lw	a0,0(s3)
    80003904:	00000097          	auipc	ra,0x0
    80003908:	880080e7          	jalr	-1920(ra) # 80003184 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000390c:	0809a023          	sw	zero,128(s3)
    80003910:	bf51                	j	800038a4 <itrunc+0x3e>

0000000080003912 <iput>:
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	e04a                	sd	s2,0(sp)
    8000391c:	1000                	addi	s0,sp,32
    8000391e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003920:	0001b517          	auipc	a0,0x1b
    80003924:	78850513          	addi	a0,a0,1928 # 8001f0a8 <itable>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	30e080e7          	jalr	782(ra) # 80000c36 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003930:	4498                	lw	a4,8(s1)
    80003932:	4785                	li	a5,1
    80003934:	02f70363          	beq	a4,a5,8000395a <iput+0x48>
  ip->ref--;
    80003938:	449c                	lw	a5,8(s1)
    8000393a:	37fd                	addiw	a5,a5,-1
    8000393c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000393e:	0001b517          	auipc	a0,0x1b
    80003942:	76a50513          	addi	a0,a0,1898 # 8001f0a8 <itable>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	3da080e7          	jalr	986(ra) # 80000d20 <release>
}
    8000394e:	60e2                	ld	ra,24(sp)
    80003950:	6442                	ld	s0,16(sp)
    80003952:	64a2                	ld	s1,8(sp)
    80003954:	6902                	ld	s2,0(sp)
    80003956:	6105                	addi	sp,sp,32
    80003958:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000395a:	40bc                	lw	a5,64(s1)
    8000395c:	dff1                	beqz	a5,80003938 <iput+0x26>
    8000395e:	04a49783          	lh	a5,74(s1)
    80003962:	fbf9                	bnez	a5,80003938 <iput+0x26>
    acquiresleep(&ip->lock);
    80003964:	01048913          	addi	s2,s1,16
    80003968:	854a                	mv	a0,s2
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	aa8080e7          	jalr	-1368(ra) # 80004412 <acquiresleep>
    release(&itable.lock);
    80003972:	0001b517          	auipc	a0,0x1b
    80003976:	73650513          	addi	a0,a0,1846 # 8001f0a8 <itable>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	3a6080e7          	jalr	934(ra) # 80000d20 <release>
    itrunc(ip);
    80003982:	8526                	mv	a0,s1
    80003984:	00000097          	auipc	ra,0x0
    80003988:	ee2080e7          	jalr	-286(ra) # 80003866 <itrunc>
    ip->type = 0;
    8000398c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003990:	8526                	mv	a0,s1
    80003992:	00000097          	auipc	ra,0x0
    80003996:	cfc080e7          	jalr	-772(ra) # 8000368e <iupdate>
    ip->valid = 0;
    8000399a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000399e:	854a                	mv	a0,s2
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	ac8080e7          	jalr	-1336(ra) # 80004468 <releasesleep>
    acquire(&itable.lock);
    800039a8:	0001b517          	auipc	a0,0x1b
    800039ac:	70050513          	addi	a0,a0,1792 # 8001f0a8 <itable>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	286080e7          	jalr	646(ra) # 80000c36 <acquire>
    800039b8:	b741                	j	80003938 <iput+0x26>

00000000800039ba <iunlockput>:
{
    800039ba:	1101                	addi	sp,sp,-32
    800039bc:	ec06                	sd	ra,24(sp)
    800039be:	e822                	sd	s0,16(sp)
    800039c0:	e426                	sd	s1,8(sp)
    800039c2:	1000                	addi	s0,sp,32
    800039c4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	e54080e7          	jalr	-428(ra) # 8000381a <iunlock>
  iput(ip);
    800039ce:	8526                	mv	a0,s1
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	f42080e7          	jalr	-190(ra) # 80003912 <iput>
}
    800039d8:	60e2                	ld	ra,24(sp)
    800039da:	6442                	ld	s0,16(sp)
    800039dc:	64a2                	ld	s1,8(sp)
    800039de:	6105                	addi	sp,sp,32
    800039e0:	8082                	ret

00000000800039e2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039e2:	1141                	addi	sp,sp,-16
    800039e4:	e422                	sd	s0,8(sp)
    800039e6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039e8:	411c                	lw	a5,0(a0)
    800039ea:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039ec:	415c                	lw	a5,4(a0)
    800039ee:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039f0:	04451783          	lh	a5,68(a0)
    800039f4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039f8:	04a51783          	lh	a5,74(a0)
    800039fc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a00:	04c56783          	lwu	a5,76(a0)
    80003a04:	e99c                	sd	a5,16(a1)
}
    80003a06:	6422                	ld	s0,8(sp)
    80003a08:	0141                	addi	sp,sp,16
    80003a0a:	8082                	ret

0000000080003a0c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a0c:	457c                	lw	a5,76(a0)
    80003a0e:	0ed7e963          	bltu	a5,a3,80003b00 <readi+0xf4>
{
    80003a12:	7159                	addi	sp,sp,-112
    80003a14:	f486                	sd	ra,104(sp)
    80003a16:	f0a2                	sd	s0,96(sp)
    80003a18:	eca6                	sd	s1,88(sp)
    80003a1a:	e8ca                	sd	s2,80(sp)
    80003a1c:	e4ce                	sd	s3,72(sp)
    80003a1e:	e0d2                	sd	s4,64(sp)
    80003a20:	fc56                	sd	s5,56(sp)
    80003a22:	f85a                	sd	s6,48(sp)
    80003a24:	f45e                	sd	s7,40(sp)
    80003a26:	f062                	sd	s8,32(sp)
    80003a28:	ec66                	sd	s9,24(sp)
    80003a2a:	e86a                	sd	s10,16(sp)
    80003a2c:	e46e                	sd	s11,8(sp)
    80003a2e:	1880                	addi	s0,sp,112
    80003a30:	8b2a                	mv	s6,a0
    80003a32:	8bae                	mv	s7,a1
    80003a34:	8a32                	mv	s4,a2
    80003a36:	84b6                	mv	s1,a3
    80003a38:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a3a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a3c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a3e:	0ad76063          	bltu	a4,a3,80003ade <readi+0xd2>
  if(off + n > ip->size)
    80003a42:	00e7f463          	bgeu	a5,a4,80003a4a <readi+0x3e>
    n = ip->size - off;
    80003a46:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4a:	0a0a8963          	beqz	s5,80003afc <readi+0xf0>
    80003a4e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a50:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a54:	5c7d                	li	s8,-1
    80003a56:	a82d                	j	80003a90 <readi+0x84>
    80003a58:	020d1d93          	slli	s11,s10,0x20
    80003a5c:	020ddd93          	srli	s11,s11,0x20
    80003a60:	05890793          	addi	a5,s2,88
    80003a64:	86ee                	mv	a3,s11
    80003a66:	963e                	add	a2,a2,a5
    80003a68:	85d2                	mv	a1,s4
    80003a6a:	855e                	mv	a0,s7
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	aa0080e7          	jalr	-1376(ra) # 8000250c <either_copyout>
    80003a74:	05850d63          	beq	a0,s8,80003ace <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	fffff097          	auipc	ra,0xfffff
    80003a7e:	5f4080e7          	jalr	1524(ra) # 8000306e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a82:	013d09bb          	addw	s3,s10,s3
    80003a86:	009d04bb          	addw	s1,s10,s1
    80003a8a:	9a6e                	add	s4,s4,s11
    80003a8c:	0559f763          	bgeu	s3,s5,80003ada <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a90:	00a4d59b          	srliw	a1,s1,0xa
    80003a94:	855a                	mv	a0,s6
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	8a2080e7          	jalr	-1886(ra) # 80003338 <bmap>
    80003a9e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003aa2:	cd85                	beqz	a1,80003ada <readi+0xce>
    bp = bread(ip->dev, addr);
    80003aa4:	000b2503          	lw	a0,0(s6)
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	496080e7          	jalr	1174(ra) # 80002f3e <bread>
    80003ab0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab2:	3ff4f613          	andi	a2,s1,1023
    80003ab6:	40cc87bb          	subw	a5,s9,a2
    80003aba:	413a873b          	subw	a4,s5,s3
    80003abe:	8d3e                	mv	s10,a5
    80003ac0:	2781                	sext.w	a5,a5
    80003ac2:	0007069b          	sext.w	a3,a4
    80003ac6:	f8f6f9e3          	bgeu	a3,a5,80003a58 <readi+0x4c>
    80003aca:	8d3a                	mv	s10,a4
    80003acc:	b771                	j	80003a58 <readi+0x4c>
      brelse(bp);
    80003ace:	854a                	mv	a0,s2
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	59e080e7          	jalr	1438(ra) # 8000306e <brelse>
      tot = -1;
    80003ad8:	59fd                	li	s3,-1
  }
  return tot;
    80003ada:	0009851b          	sext.w	a0,s3
}
    80003ade:	70a6                	ld	ra,104(sp)
    80003ae0:	7406                	ld	s0,96(sp)
    80003ae2:	64e6                	ld	s1,88(sp)
    80003ae4:	6946                	ld	s2,80(sp)
    80003ae6:	69a6                	ld	s3,72(sp)
    80003ae8:	6a06                	ld	s4,64(sp)
    80003aea:	7ae2                	ld	s5,56(sp)
    80003aec:	7b42                	ld	s6,48(sp)
    80003aee:	7ba2                	ld	s7,40(sp)
    80003af0:	7c02                	ld	s8,32(sp)
    80003af2:	6ce2                	ld	s9,24(sp)
    80003af4:	6d42                	ld	s10,16(sp)
    80003af6:	6da2                	ld	s11,8(sp)
    80003af8:	6165                	addi	sp,sp,112
    80003afa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003afc:	89d6                	mv	s3,s5
    80003afe:	bff1                	j	80003ada <readi+0xce>
    return 0;
    80003b00:	4501                	li	a0,0
}
    80003b02:	8082                	ret

0000000080003b04 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b04:	457c                	lw	a5,76(a0)
    80003b06:	10d7e863          	bltu	a5,a3,80003c16 <writei+0x112>
{
    80003b0a:	7159                	addi	sp,sp,-112
    80003b0c:	f486                	sd	ra,104(sp)
    80003b0e:	f0a2                	sd	s0,96(sp)
    80003b10:	eca6                	sd	s1,88(sp)
    80003b12:	e8ca                	sd	s2,80(sp)
    80003b14:	e4ce                	sd	s3,72(sp)
    80003b16:	e0d2                	sd	s4,64(sp)
    80003b18:	fc56                	sd	s5,56(sp)
    80003b1a:	f85a                	sd	s6,48(sp)
    80003b1c:	f45e                	sd	s7,40(sp)
    80003b1e:	f062                	sd	s8,32(sp)
    80003b20:	ec66                	sd	s9,24(sp)
    80003b22:	e86a                	sd	s10,16(sp)
    80003b24:	e46e                	sd	s11,8(sp)
    80003b26:	1880                	addi	s0,sp,112
    80003b28:	8aaa                	mv	s5,a0
    80003b2a:	8bae                	mv	s7,a1
    80003b2c:	8a32                	mv	s4,a2
    80003b2e:	8936                	mv	s2,a3
    80003b30:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b32:	00e687bb          	addw	a5,a3,a4
    80003b36:	0ed7e263          	bltu	a5,a3,80003c1a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b3a:	00043737          	lui	a4,0x43
    80003b3e:	0ef76063          	bltu	a4,a5,80003c1e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b42:	0c0b0863          	beqz	s6,80003c12 <writei+0x10e>
    80003b46:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b48:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b4c:	5c7d                	li	s8,-1
    80003b4e:	a091                	j	80003b92 <writei+0x8e>
    80003b50:	020d1d93          	slli	s11,s10,0x20
    80003b54:	020ddd93          	srli	s11,s11,0x20
    80003b58:	05848793          	addi	a5,s1,88
    80003b5c:	86ee                	mv	a3,s11
    80003b5e:	8652                	mv	a2,s4
    80003b60:	85de                	mv	a1,s7
    80003b62:	953e                	add	a0,a0,a5
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	9fe080e7          	jalr	-1538(ra) # 80002562 <either_copyin>
    80003b6c:	07850263          	beq	a0,s8,80003bd0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b70:	8526                	mv	a0,s1
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	780080e7          	jalr	1920(ra) # 800042f2 <log_write>
    brelse(bp);
    80003b7a:	8526                	mv	a0,s1
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	4f2080e7          	jalr	1266(ra) # 8000306e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b84:	013d09bb          	addw	s3,s10,s3
    80003b88:	012d093b          	addw	s2,s10,s2
    80003b8c:	9a6e                	add	s4,s4,s11
    80003b8e:	0569f663          	bgeu	s3,s6,80003bda <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b92:	00a9559b          	srliw	a1,s2,0xa
    80003b96:	8556                	mv	a0,s5
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	7a0080e7          	jalr	1952(ra) # 80003338 <bmap>
    80003ba0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ba4:	c99d                	beqz	a1,80003bda <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ba6:	000aa503          	lw	a0,0(s5)
    80003baa:	fffff097          	auipc	ra,0xfffff
    80003bae:	394080e7          	jalr	916(ra) # 80002f3e <bread>
    80003bb2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb4:	3ff97513          	andi	a0,s2,1023
    80003bb8:	40ac87bb          	subw	a5,s9,a0
    80003bbc:	413b073b          	subw	a4,s6,s3
    80003bc0:	8d3e                	mv	s10,a5
    80003bc2:	2781                	sext.w	a5,a5
    80003bc4:	0007069b          	sext.w	a3,a4
    80003bc8:	f8f6f4e3          	bgeu	a3,a5,80003b50 <writei+0x4c>
    80003bcc:	8d3a                	mv	s10,a4
    80003bce:	b749                	j	80003b50 <writei+0x4c>
      brelse(bp);
    80003bd0:	8526                	mv	a0,s1
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	49c080e7          	jalr	1180(ra) # 8000306e <brelse>
  }

  if(off > ip->size)
    80003bda:	04caa783          	lw	a5,76(s5)
    80003bde:	0127f463          	bgeu	a5,s2,80003be6 <writei+0xe2>
    ip->size = off;
    80003be2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003be6:	8556                	mv	a0,s5
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	aa6080e7          	jalr	-1370(ra) # 8000368e <iupdate>

  return tot;
    80003bf0:	0009851b          	sext.w	a0,s3
}
    80003bf4:	70a6                	ld	ra,104(sp)
    80003bf6:	7406                	ld	s0,96(sp)
    80003bf8:	64e6                	ld	s1,88(sp)
    80003bfa:	6946                	ld	s2,80(sp)
    80003bfc:	69a6                	ld	s3,72(sp)
    80003bfe:	6a06                	ld	s4,64(sp)
    80003c00:	7ae2                	ld	s5,56(sp)
    80003c02:	7b42                	ld	s6,48(sp)
    80003c04:	7ba2                	ld	s7,40(sp)
    80003c06:	7c02                	ld	s8,32(sp)
    80003c08:	6ce2                	ld	s9,24(sp)
    80003c0a:	6d42                	ld	s10,16(sp)
    80003c0c:	6da2                	ld	s11,8(sp)
    80003c0e:	6165                	addi	sp,sp,112
    80003c10:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c12:	89da                	mv	s3,s6
    80003c14:	bfc9                	j	80003be6 <writei+0xe2>
    return -1;
    80003c16:	557d                	li	a0,-1
}
    80003c18:	8082                	ret
    return -1;
    80003c1a:	557d                	li	a0,-1
    80003c1c:	bfe1                	j	80003bf4 <writei+0xf0>
    return -1;
    80003c1e:	557d                	li	a0,-1
    80003c20:	bfd1                	j	80003bf4 <writei+0xf0>

0000000080003c22 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c22:	1141                	addi	sp,sp,-16
    80003c24:	e406                	sd	ra,8(sp)
    80003c26:	e022                	sd	s0,0(sp)
    80003c28:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c2a:	4639                	li	a2,14
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	212080e7          	jalr	530(ra) # 80000e3e <strncmp>
}
    80003c34:	60a2                	ld	ra,8(sp)
    80003c36:	6402                	ld	s0,0(sp)
    80003c38:	0141                	addi	sp,sp,16
    80003c3a:	8082                	ret

0000000080003c3c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c3c:	7139                	addi	sp,sp,-64
    80003c3e:	fc06                	sd	ra,56(sp)
    80003c40:	f822                	sd	s0,48(sp)
    80003c42:	f426                	sd	s1,40(sp)
    80003c44:	f04a                	sd	s2,32(sp)
    80003c46:	ec4e                	sd	s3,24(sp)
    80003c48:	e852                	sd	s4,16(sp)
    80003c4a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c4c:	04451703          	lh	a4,68(a0)
    80003c50:	4785                	li	a5,1
    80003c52:	00f71a63          	bne	a4,a5,80003c66 <dirlookup+0x2a>
    80003c56:	892a                	mv	s2,a0
    80003c58:	89ae                	mv	s3,a1
    80003c5a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5c:	457c                	lw	a5,76(a0)
    80003c5e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c60:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c62:	e79d                	bnez	a5,80003c90 <dirlookup+0x54>
    80003c64:	a8a5                	j	80003cdc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c66:	00005517          	auipc	a0,0x5
    80003c6a:	9ba50513          	addi	a0,a0,-1606 # 80008620 <syscalls+0x1a8>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	8d0080e7          	jalr	-1840(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c76:	00005517          	auipc	a0,0x5
    80003c7a:	9c250513          	addi	a0,a0,-1598 # 80008638 <syscalls+0x1c0>
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	8c0080e7          	jalr	-1856(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c86:	24c1                	addiw	s1,s1,16
    80003c88:	04c92783          	lw	a5,76(s2)
    80003c8c:	04f4f763          	bgeu	s1,a5,80003cda <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c90:	4741                	li	a4,16
    80003c92:	86a6                	mv	a3,s1
    80003c94:	fc040613          	addi	a2,s0,-64
    80003c98:	4581                	li	a1,0
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	d70080e7          	jalr	-656(ra) # 80003a0c <readi>
    80003ca4:	47c1                	li	a5,16
    80003ca6:	fcf518e3          	bne	a0,a5,80003c76 <dirlookup+0x3a>
    if(de.inum == 0)
    80003caa:	fc045783          	lhu	a5,-64(s0)
    80003cae:	dfe1                	beqz	a5,80003c86 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cb0:	fc240593          	addi	a1,s0,-62
    80003cb4:	854e                	mv	a0,s3
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	f6c080e7          	jalr	-148(ra) # 80003c22 <namecmp>
    80003cbe:	f561                	bnez	a0,80003c86 <dirlookup+0x4a>
      if(poff)
    80003cc0:	000a0463          	beqz	s4,80003cc8 <dirlookup+0x8c>
        *poff = off;
    80003cc4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cc8:	fc045583          	lhu	a1,-64(s0)
    80003ccc:	00092503          	lw	a0,0(s2)
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	750080e7          	jalr	1872(ra) # 80003420 <iget>
    80003cd8:	a011                	j	80003cdc <dirlookup+0xa0>
  return 0;
    80003cda:	4501                	li	a0,0
}
    80003cdc:	70e2                	ld	ra,56(sp)
    80003cde:	7442                	ld	s0,48(sp)
    80003ce0:	74a2                	ld	s1,40(sp)
    80003ce2:	7902                	ld	s2,32(sp)
    80003ce4:	69e2                	ld	s3,24(sp)
    80003ce6:	6a42                	ld	s4,16(sp)
    80003ce8:	6121                	addi	sp,sp,64
    80003cea:	8082                	ret

0000000080003cec <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cec:	711d                	addi	sp,sp,-96
    80003cee:	ec86                	sd	ra,88(sp)
    80003cf0:	e8a2                	sd	s0,80(sp)
    80003cf2:	e4a6                	sd	s1,72(sp)
    80003cf4:	e0ca                	sd	s2,64(sp)
    80003cf6:	fc4e                	sd	s3,56(sp)
    80003cf8:	f852                	sd	s4,48(sp)
    80003cfa:	f456                	sd	s5,40(sp)
    80003cfc:	f05a                	sd	s6,32(sp)
    80003cfe:	ec5e                	sd	s7,24(sp)
    80003d00:	e862                	sd	s8,16(sp)
    80003d02:	e466                	sd	s9,8(sp)
    80003d04:	1080                	addi	s0,sp,96
    80003d06:	84aa                	mv	s1,a0
    80003d08:	8aae                	mv	s5,a1
    80003d0a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d0c:	00054703          	lbu	a4,0(a0)
    80003d10:	02f00793          	li	a5,47
    80003d14:	02f70363          	beq	a4,a5,80003d3a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d18:	ffffe097          	auipc	ra,0xffffe
    80003d1c:	d44080e7          	jalr	-700(ra) # 80001a5c <myproc>
    80003d20:	15053503          	ld	a0,336(a0)
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	9f6080e7          	jalr	-1546(ra) # 8000371a <idup>
    80003d2c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d2e:	02f00913          	li	s2,47
  len = path - s;
    80003d32:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d34:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d36:	4b85                	li	s7,1
    80003d38:	a865                	j	80003df0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d3a:	4585                	li	a1,1
    80003d3c:	4505                	li	a0,1
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	6e2080e7          	jalr	1762(ra) # 80003420 <iget>
    80003d46:	89aa                	mv	s3,a0
    80003d48:	b7dd                	j	80003d2e <namex+0x42>
      iunlockput(ip);
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	c6e080e7          	jalr	-914(ra) # 800039ba <iunlockput>
      return 0;
    80003d54:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d56:	854e                	mv	a0,s3
    80003d58:	60e6                	ld	ra,88(sp)
    80003d5a:	6446                	ld	s0,80(sp)
    80003d5c:	64a6                	ld	s1,72(sp)
    80003d5e:	6906                	ld	s2,64(sp)
    80003d60:	79e2                	ld	s3,56(sp)
    80003d62:	7a42                	ld	s4,48(sp)
    80003d64:	7aa2                	ld	s5,40(sp)
    80003d66:	7b02                	ld	s6,32(sp)
    80003d68:	6be2                	ld	s7,24(sp)
    80003d6a:	6c42                	ld	s8,16(sp)
    80003d6c:	6ca2                	ld	s9,8(sp)
    80003d6e:	6125                	addi	sp,sp,96
    80003d70:	8082                	ret
      iunlock(ip);
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	aa6080e7          	jalr	-1370(ra) # 8000381a <iunlock>
      return ip;
    80003d7c:	bfe9                	j	80003d56 <namex+0x6a>
      iunlockput(ip);
    80003d7e:	854e                	mv	a0,s3
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	c3a080e7          	jalr	-966(ra) # 800039ba <iunlockput>
      return 0;
    80003d88:	89e6                	mv	s3,s9
    80003d8a:	b7f1                	j	80003d56 <namex+0x6a>
  len = path - s;
    80003d8c:	40b48633          	sub	a2,s1,a1
    80003d90:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d94:	099c5463          	bge	s8,s9,80003e1c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d98:	4639                	li	a2,14
    80003d9a:	8552                	mv	a0,s4
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	02e080e7          	jalr	46(ra) # 80000dca <memmove>
  while(*path == '/')
    80003da4:	0004c783          	lbu	a5,0(s1)
    80003da8:	01279763          	bne	a5,s2,80003db6 <namex+0xca>
    path++;
    80003dac:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dae:	0004c783          	lbu	a5,0(s1)
    80003db2:	ff278de3          	beq	a5,s2,80003dac <namex+0xc0>
    ilock(ip);
    80003db6:	854e                	mv	a0,s3
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	9a0080e7          	jalr	-1632(ra) # 80003758 <ilock>
    if(ip->type != T_DIR){
    80003dc0:	04499783          	lh	a5,68(s3)
    80003dc4:	f97793e3          	bne	a5,s7,80003d4a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dc8:	000a8563          	beqz	s5,80003dd2 <namex+0xe6>
    80003dcc:	0004c783          	lbu	a5,0(s1)
    80003dd0:	d3cd                	beqz	a5,80003d72 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dd2:	865a                	mv	a2,s6
    80003dd4:	85d2                	mv	a1,s4
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	e64080e7          	jalr	-412(ra) # 80003c3c <dirlookup>
    80003de0:	8caa                	mv	s9,a0
    80003de2:	dd51                	beqz	a0,80003d7e <namex+0x92>
    iunlockput(ip);
    80003de4:	854e                	mv	a0,s3
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	bd4080e7          	jalr	-1068(ra) # 800039ba <iunlockput>
    ip = next;
    80003dee:	89e6                	mv	s3,s9
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	05279763          	bne	a5,s2,80003e42 <namex+0x156>
    path++;
    80003df8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dfa:	0004c783          	lbu	a5,0(s1)
    80003dfe:	ff278de3          	beq	a5,s2,80003df8 <namex+0x10c>
  if(*path == 0)
    80003e02:	c79d                	beqz	a5,80003e30 <namex+0x144>
    path++;
    80003e04:	85a6                	mv	a1,s1
  len = path - s;
    80003e06:	8cda                	mv	s9,s6
    80003e08:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e0a:	01278963          	beq	a5,s2,80003e1c <namex+0x130>
    80003e0e:	dfbd                	beqz	a5,80003d8c <namex+0xa0>
    path++;
    80003e10:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	ff279ce3          	bne	a5,s2,80003e0e <namex+0x122>
    80003e1a:	bf8d                	j	80003d8c <namex+0xa0>
    memmove(name, s, len);
    80003e1c:	2601                	sext.w	a2,a2
    80003e1e:	8552                	mv	a0,s4
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	faa080e7          	jalr	-86(ra) # 80000dca <memmove>
    name[len] = 0;
    80003e28:	9cd2                	add	s9,s9,s4
    80003e2a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e2e:	bf9d                	j	80003da4 <namex+0xb8>
  if(nameiparent){
    80003e30:	f20a83e3          	beqz	s5,80003d56 <namex+0x6a>
    iput(ip);
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	adc080e7          	jalr	-1316(ra) # 80003912 <iput>
    return 0;
    80003e3e:	4981                	li	s3,0
    80003e40:	bf19                	j	80003d56 <namex+0x6a>
  if(*path == 0)
    80003e42:	d7fd                	beqz	a5,80003e30 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e44:	0004c783          	lbu	a5,0(s1)
    80003e48:	85a6                	mv	a1,s1
    80003e4a:	b7d1                	j	80003e0e <namex+0x122>

0000000080003e4c <dirlink>:
{
    80003e4c:	7139                	addi	sp,sp,-64
    80003e4e:	fc06                	sd	ra,56(sp)
    80003e50:	f822                	sd	s0,48(sp)
    80003e52:	f426                	sd	s1,40(sp)
    80003e54:	f04a                	sd	s2,32(sp)
    80003e56:	ec4e                	sd	s3,24(sp)
    80003e58:	e852                	sd	s4,16(sp)
    80003e5a:	0080                	addi	s0,sp,64
    80003e5c:	892a                	mv	s2,a0
    80003e5e:	8a2e                	mv	s4,a1
    80003e60:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e62:	4601                	li	a2,0
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	dd8080e7          	jalr	-552(ra) # 80003c3c <dirlookup>
    80003e6c:	e93d                	bnez	a0,80003ee2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6e:	04c92483          	lw	s1,76(s2)
    80003e72:	c49d                	beqz	s1,80003ea0 <dirlink+0x54>
    80003e74:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e76:	4741                	li	a4,16
    80003e78:	86a6                	mv	a3,s1
    80003e7a:	fc040613          	addi	a2,s0,-64
    80003e7e:	4581                	li	a1,0
    80003e80:	854a                	mv	a0,s2
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	b8a080e7          	jalr	-1142(ra) # 80003a0c <readi>
    80003e8a:	47c1                	li	a5,16
    80003e8c:	06f51163          	bne	a0,a5,80003eee <dirlink+0xa2>
    if(de.inum == 0)
    80003e90:	fc045783          	lhu	a5,-64(s0)
    80003e94:	c791                	beqz	a5,80003ea0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e96:	24c1                	addiw	s1,s1,16
    80003e98:	04c92783          	lw	a5,76(s2)
    80003e9c:	fcf4ede3          	bltu	s1,a5,80003e76 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ea0:	4639                	li	a2,14
    80003ea2:	85d2                	mv	a1,s4
    80003ea4:	fc240513          	addi	a0,s0,-62
    80003ea8:	ffffd097          	auipc	ra,0xffffd
    80003eac:	fd2080e7          	jalr	-46(ra) # 80000e7a <strncpy>
  de.inum = inum;
    80003eb0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb4:	4741                	li	a4,16
    80003eb6:	86a6                	mv	a3,s1
    80003eb8:	fc040613          	addi	a2,s0,-64
    80003ebc:	4581                	li	a1,0
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	c44080e7          	jalr	-956(ra) # 80003b04 <writei>
    80003ec8:	1541                	addi	a0,a0,-16
    80003eca:	00a03533          	snez	a0,a0
    80003ece:	40a00533          	neg	a0,a0
}
    80003ed2:	70e2                	ld	ra,56(sp)
    80003ed4:	7442                	ld	s0,48(sp)
    80003ed6:	74a2                	ld	s1,40(sp)
    80003ed8:	7902                	ld	s2,32(sp)
    80003eda:	69e2                	ld	s3,24(sp)
    80003edc:	6a42                	ld	s4,16(sp)
    80003ede:	6121                	addi	sp,sp,64
    80003ee0:	8082                	ret
    iput(ip);
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	a30080e7          	jalr	-1488(ra) # 80003912 <iput>
    return -1;
    80003eea:	557d                	li	a0,-1
    80003eec:	b7dd                	j	80003ed2 <dirlink+0x86>
      panic("dirlink read");
    80003eee:	00004517          	auipc	a0,0x4
    80003ef2:	75a50513          	addi	a0,a0,1882 # 80008648 <syscalls+0x1d0>
    80003ef6:	ffffc097          	auipc	ra,0xffffc
    80003efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>

0000000080003efe <namei>:

struct inode*
namei(char *path)
{
    80003efe:	1101                	addi	sp,sp,-32
    80003f00:	ec06                	sd	ra,24(sp)
    80003f02:	e822                	sd	s0,16(sp)
    80003f04:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f06:	fe040613          	addi	a2,s0,-32
    80003f0a:	4581                	li	a1,0
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	de0080e7          	jalr	-544(ra) # 80003cec <namex>
}
    80003f14:	60e2                	ld	ra,24(sp)
    80003f16:	6442                	ld	s0,16(sp)
    80003f18:	6105                	addi	sp,sp,32
    80003f1a:	8082                	ret

0000000080003f1c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f1c:	1141                	addi	sp,sp,-16
    80003f1e:	e406                	sd	ra,8(sp)
    80003f20:	e022                	sd	s0,0(sp)
    80003f22:	0800                	addi	s0,sp,16
    80003f24:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f26:	4585                	li	a1,1
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	dc4080e7          	jalr	-572(ra) # 80003cec <namex>
}
    80003f30:	60a2                	ld	ra,8(sp)
    80003f32:	6402                	ld	s0,0(sp)
    80003f34:	0141                	addi	sp,sp,16
    80003f36:	8082                	ret

0000000080003f38 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f38:	1101                	addi	sp,sp,-32
    80003f3a:	ec06                	sd	ra,24(sp)
    80003f3c:	e822                	sd	s0,16(sp)
    80003f3e:	e426                	sd	s1,8(sp)
    80003f40:	e04a                	sd	s2,0(sp)
    80003f42:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f44:	0001d917          	auipc	s2,0x1d
    80003f48:	c0c90913          	addi	s2,s2,-1012 # 80020b50 <log>
    80003f4c:	01892583          	lw	a1,24(s2)
    80003f50:	02892503          	lw	a0,40(s2)
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	fea080e7          	jalr	-22(ra) # 80002f3e <bread>
    80003f5c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f5e:	02c92683          	lw	a3,44(s2)
    80003f62:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f64:	02d05763          	blez	a3,80003f92 <write_head+0x5a>
    80003f68:	0001d797          	auipc	a5,0x1d
    80003f6c:	c1878793          	addi	a5,a5,-1000 # 80020b80 <log+0x30>
    80003f70:	05c50713          	addi	a4,a0,92
    80003f74:	36fd                	addiw	a3,a3,-1
    80003f76:	1682                	slli	a3,a3,0x20
    80003f78:	9281                	srli	a3,a3,0x20
    80003f7a:	068a                	slli	a3,a3,0x2
    80003f7c:	0001d617          	auipc	a2,0x1d
    80003f80:	c0860613          	addi	a2,a2,-1016 # 80020b84 <log+0x34>
    80003f84:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f86:	4390                	lw	a2,0(a5)
    80003f88:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8a:	0791                	addi	a5,a5,4
    80003f8c:	0711                	addi	a4,a4,4
    80003f8e:	fed79ce3          	bne	a5,a3,80003f86 <write_head+0x4e>
  }
  bwrite(buf);
    80003f92:	8526                	mv	a0,s1
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	09c080e7          	jalr	156(ra) # 80003030 <bwrite>
  brelse(buf);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	0d0080e7          	jalr	208(ra) # 8000306e <brelse>
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret

0000000080003fb2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb2:	0001d797          	auipc	a5,0x1d
    80003fb6:	bca7a783          	lw	a5,-1078(a5) # 80020b7c <log+0x2c>
    80003fba:	0af05d63          	blez	a5,80004074 <install_trans+0xc2>
{
    80003fbe:	7139                	addi	sp,sp,-64
    80003fc0:	fc06                	sd	ra,56(sp)
    80003fc2:	f822                	sd	s0,48(sp)
    80003fc4:	f426                	sd	s1,40(sp)
    80003fc6:	f04a                	sd	s2,32(sp)
    80003fc8:	ec4e                	sd	s3,24(sp)
    80003fca:	e852                	sd	s4,16(sp)
    80003fcc:	e456                	sd	s5,8(sp)
    80003fce:	e05a                	sd	s6,0(sp)
    80003fd0:	0080                	addi	s0,sp,64
    80003fd2:	8b2a                	mv	s6,a0
    80003fd4:	0001da97          	auipc	s5,0x1d
    80003fd8:	baca8a93          	addi	s5,s5,-1108 # 80020b80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fde:	0001d997          	auipc	s3,0x1d
    80003fe2:	b7298993          	addi	s3,s3,-1166 # 80020b50 <log>
    80003fe6:	a00d                	j	80004008 <install_trans+0x56>
    brelse(lbuf);
    80003fe8:	854a                	mv	a0,s2
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	084080e7          	jalr	132(ra) # 8000306e <brelse>
    brelse(dbuf);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	07a080e7          	jalr	122(ra) # 8000306e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffc:	2a05                	addiw	s4,s4,1
    80003ffe:	0a91                	addi	s5,s5,4
    80004000:	02c9a783          	lw	a5,44(s3)
    80004004:	04fa5e63          	bge	s4,a5,80004060 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004008:	0189a583          	lw	a1,24(s3)
    8000400c:	014585bb          	addw	a1,a1,s4
    80004010:	2585                	addiw	a1,a1,1
    80004012:	0289a503          	lw	a0,40(s3)
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	f28080e7          	jalr	-216(ra) # 80002f3e <bread>
    8000401e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004020:	000aa583          	lw	a1,0(s5)
    80004024:	0289a503          	lw	a0,40(s3)
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	f16080e7          	jalr	-234(ra) # 80002f3e <bread>
    80004030:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004032:	40000613          	li	a2,1024
    80004036:	05890593          	addi	a1,s2,88
    8000403a:	05850513          	addi	a0,a0,88
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	d8c080e7          	jalr	-628(ra) # 80000dca <memmove>
    bwrite(dbuf);  // write dst to disk
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	fe8080e7          	jalr	-24(ra) # 80003030 <bwrite>
    if(recovering == 0)
    80004050:	f80b1ce3          	bnez	s6,80003fe8 <install_trans+0x36>
      bunpin(dbuf);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	0f2080e7          	jalr	242(ra) # 80003148 <bunpin>
    8000405e:	b769                	j	80003fe8 <install_trans+0x36>
}
    80004060:	70e2                	ld	ra,56(sp)
    80004062:	7442                	ld	s0,48(sp)
    80004064:	74a2                	ld	s1,40(sp)
    80004066:	7902                	ld	s2,32(sp)
    80004068:	69e2                	ld	s3,24(sp)
    8000406a:	6a42                	ld	s4,16(sp)
    8000406c:	6aa2                	ld	s5,8(sp)
    8000406e:	6b02                	ld	s6,0(sp)
    80004070:	6121                	addi	sp,sp,64
    80004072:	8082                	ret
    80004074:	8082                	ret

0000000080004076 <initlog>:
{
    80004076:	7179                	addi	sp,sp,-48
    80004078:	f406                	sd	ra,40(sp)
    8000407a:	f022                	sd	s0,32(sp)
    8000407c:	ec26                	sd	s1,24(sp)
    8000407e:	e84a                	sd	s2,16(sp)
    80004080:	e44e                	sd	s3,8(sp)
    80004082:	1800                	addi	s0,sp,48
    80004084:	892a                	mv	s2,a0
    80004086:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	ac848493          	addi	s1,s1,-1336 # 80020b50 <log>
    80004090:	00004597          	auipc	a1,0x4
    80004094:	5c858593          	addi	a1,a1,1480 # 80008658 <syscalls+0x1e0>
    80004098:	8526                	mv	a0,s1
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	b08080e7          	jalr	-1272(ra) # 80000ba2 <initlock>
  log.start = sb->logstart;
    800040a2:	0149a583          	lw	a1,20(s3)
    800040a6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040a8:	0109a783          	lw	a5,16(s3)
    800040ac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040b2:	854a                	mv	a0,s2
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	e8a080e7          	jalr	-374(ra) # 80002f3e <bread>
  log.lh.n = lh->n;
    800040bc:	4d34                	lw	a3,88(a0)
    800040be:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040c0:	02d05563          	blez	a3,800040ea <initlog+0x74>
    800040c4:	05c50793          	addi	a5,a0,92
    800040c8:	0001d717          	auipc	a4,0x1d
    800040cc:	ab870713          	addi	a4,a4,-1352 # 80020b80 <log+0x30>
    800040d0:	36fd                	addiw	a3,a3,-1
    800040d2:	1682                	slli	a3,a3,0x20
    800040d4:	9281                	srli	a3,a3,0x20
    800040d6:	068a                	slli	a3,a3,0x2
    800040d8:	06050613          	addi	a2,a0,96
    800040dc:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040de:	4390                	lw	a2,0(a5)
    800040e0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040e2:	0791                	addi	a5,a5,4
    800040e4:	0711                	addi	a4,a4,4
    800040e6:	fed79ce3          	bne	a5,a3,800040de <initlog+0x68>
  brelse(buf);
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	f84080e7          	jalr	-124(ra) # 8000306e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040f2:	4505                	li	a0,1
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	ebe080e7          	jalr	-322(ra) # 80003fb2 <install_trans>
  log.lh.n = 0;
    800040fc:	0001d797          	auipc	a5,0x1d
    80004100:	a807a023          	sw	zero,-1408(a5) # 80020b7c <log+0x2c>
  write_head(); // clear the log
    80004104:	00000097          	auipc	ra,0x0
    80004108:	e34080e7          	jalr	-460(ra) # 80003f38 <write_head>
}
    8000410c:	70a2                	ld	ra,40(sp)
    8000410e:	7402                	ld	s0,32(sp)
    80004110:	64e2                	ld	s1,24(sp)
    80004112:	6942                	ld	s2,16(sp)
    80004114:	69a2                	ld	s3,8(sp)
    80004116:	6145                	addi	sp,sp,48
    80004118:	8082                	ret

000000008000411a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000411a:	1101                	addi	sp,sp,-32
    8000411c:	ec06                	sd	ra,24(sp)
    8000411e:	e822                	sd	s0,16(sp)
    80004120:	e426                	sd	s1,8(sp)
    80004122:	e04a                	sd	s2,0(sp)
    80004124:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004126:	0001d517          	auipc	a0,0x1d
    8000412a:	a2a50513          	addi	a0,a0,-1494 # 80020b50 <log>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	b08080e7          	jalr	-1272(ra) # 80000c36 <acquire>
  while(1){
    if(log.committing){
    80004136:	0001d497          	auipc	s1,0x1d
    8000413a:	a1a48493          	addi	s1,s1,-1510 # 80020b50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000413e:	4979                	li	s2,30
    80004140:	a039                	j	8000414e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004142:	85a6                	mv	a1,s1
    80004144:	8526                	mv	a0,s1
    80004146:	ffffe097          	auipc	ra,0xffffe
    8000414a:	fbe080e7          	jalr	-66(ra) # 80002104 <sleep>
    if(log.committing){
    8000414e:	50dc                	lw	a5,36(s1)
    80004150:	fbed                	bnez	a5,80004142 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004152:	509c                	lw	a5,32(s1)
    80004154:	0017871b          	addiw	a4,a5,1
    80004158:	0007069b          	sext.w	a3,a4
    8000415c:	0027179b          	slliw	a5,a4,0x2
    80004160:	9fb9                	addw	a5,a5,a4
    80004162:	0017979b          	slliw	a5,a5,0x1
    80004166:	54d8                	lw	a4,44(s1)
    80004168:	9fb9                	addw	a5,a5,a4
    8000416a:	00f95963          	bge	s2,a5,8000417c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000416e:	85a6                	mv	a1,s1
    80004170:	8526                	mv	a0,s1
    80004172:	ffffe097          	auipc	ra,0xffffe
    80004176:	f92080e7          	jalr	-110(ra) # 80002104 <sleep>
    8000417a:	bfd1                	j	8000414e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000417c:	0001d517          	auipc	a0,0x1d
    80004180:	9d450513          	addi	a0,a0,-1580 # 80020b50 <log>
    80004184:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	b9a080e7          	jalr	-1126(ra) # 80000d20 <release>
      break;
    }
  }
}
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6902                	ld	s2,0(sp)
    80004196:	6105                	addi	sp,sp,32
    80004198:	8082                	ret

000000008000419a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000419a:	7139                	addi	sp,sp,-64
    8000419c:	fc06                	sd	ra,56(sp)
    8000419e:	f822                	sd	s0,48(sp)
    800041a0:	f426                	sd	s1,40(sp)
    800041a2:	f04a                	sd	s2,32(sp)
    800041a4:	ec4e                	sd	s3,24(sp)
    800041a6:	e852                	sd	s4,16(sp)
    800041a8:	e456                	sd	s5,8(sp)
    800041aa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ac:	0001d497          	auipc	s1,0x1d
    800041b0:	9a448493          	addi	s1,s1,-1628 # 80020b50 <log>
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a80080e7          	jalr	-1408(ra) # 80000c36 <acquire>
  log.outstanding -= 1;
    800041be:	509c                	lw	a5,32(s1)
    800041c0:	37fd                	addiw	a5,a5,-1
    800041c2:	0007891b          	sext.w	s2,a5
    800041c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041c8:	50dc                	lw	a5,36(s1)
    800041ca:	e7b9                	bnez	a5,80004218 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041cc:	04091e63          	bnez	s2,80004228 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041d0:	0001d497          	auipc	s1,0x1d
    800041d4:	98048493          	addi	s1,s1,-1664 # 80020b50 <log>
    800041d8:	4785                	li	a5,1
    800041da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	b42080e7          	jalr	-1214(ra) # 80000d20 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041e6:	54dc                	lw	a5,44(s1)
    800041e8:	06f04763          	bgtz	a5,80004256 <end_op+0xbc>
    acquire(&log.lock);
    800041ec:	0001d497          	auipc	s1,0x1d
    800041f0:	96448493          	addi	s1,s1,-1692 # 80020b50 <log>
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	a40080e7          	jalr	-1472(ra) # 80000c36 <acquire>
    log.committing = 0;
    800041fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004202:	8526                	mv	a0,s1
    80004204:	ffffe097          	auipc	ra,0xffffe
    80004208:	f64080e7          	jalr	-156(ra) # 80002168 <wakeup>
    release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	b12080e7          	jalr	-1262(ra) # 80000d20 <release>
}
    80004216:	a03d                	j	80004244 <end_op+0xaa>
    panic("log.committing");
    80004218:	00004517          	auipc	a0,0x4
    8000421c:	44850513          	addi	a0,a0,1096 # 80008660 <syscalls+0x1e8>
    80004220:	ffffc097          	auipc	ra,0xffffc
    80004224:	31e080e7          	jalr	798(ra) # 8000053e <panic>
    wakeup(&log);
    80004228:	0001d497          	auipc	s1,0x1d
    8000422c:	92848493          	addi	s1,s1,-1752 # 80020b50 <log>
    80004230:	8526                	mv	a0,s1
    80004232:	ffffe097          	auipc	ra,0xffffe
    80004236:	f36080e7          	jalr	-202(ra) # 80002168 <wakeup>
  release(&log.lock);
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	ae4080e7          	jalr	-1308(ra) # 80000d20 <release>
}
    80004244:	70e2                	ld	ra,56(sp)
    80004246:	7442                	ld	s0,48(sp)
    80004248:	74a2                	ld	s1,40(sp)
    8000424a:	7902                	ld	s2,32(sp)
    8000424c:	69e2                	ld	s3,24(sp)
    8000424e:	6a42                	ld	s4,16(sp)
    80004250:	6aa2                	ld	s5,8(sp)
    80004252:	6121                	addi	sp,sp,64
    80004254:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004256:	0001da97          	auipc	s5,0x1d
    8000425a:	92aa8a93          	addi	s5,s5,-1750 # 80020b80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000425e:	0001da17          	auipc	s4,0x1d
    80004262:	8f2a0a13          	addi	s4,s4,-1806 # 80020b50 <log>
    80004266:	018a2583          	lw	a1,24(s4)
    8000426a:	012585bb          	addw	a1,a1,s2
    8000426e:	2585                	addiw	a1,a1,1
    80004270:	028a2503          	lw	a0,40(s4)
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	cca080e7          	jalr	-822(ra) # 80002f3e <bread>
    8000427c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000427e:	000aa583          	lw	a1,0(s5)
    80004282:	028a2503          	lw	a0,40(s4)
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	cb8080e7          	jalr	-840(ra) # 80002f3e <bread>
    8000428e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004290:	40000613          	li	a2,1024
    80004294:	05850593          	addi	a1,a0,88
    80004298:	05848513          	addi	a0,s1,88
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	b2e080e7          	jalr	-1234(ra) # 80000dca <memmove>
    bwrite(to);  // write the log
    800042a4:	8526                	mv	a0,s1
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	d8a080e7          	jalr	-630(ra) # 80003030 <bwrite>
    brelse(from);
    800042ae:	854e                	mv	a0,s3
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	dbe080e7          	jalr	-578(ra) # 8000306e <brelse>
    brelse(to);
    800042b8:	8526                	mv	a0,s1
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	db4080e7          	jalr	-588(ra) # 8000306e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	2905                	addiw	s2,s2,1
    800042c4:	0a91                	addi	s5,s5,4
    800042c6:	02ca2783          	lw	a5,44(s4)
    800042ca:	f8f94ee3          	blt	s2,a5,80004266 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	c6a080e7          	jalr	-918(ra) # 80003f38 <write_head>
    install_trans(0); // Now install writes to home locations
    800042d6:	4501                	li	a0,0
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	cda080e7          	jalr	-806(ra) # 80003fb2 <install_trans>
    log.lh.n = 0;
    800042e0:	0001d797          	auipc	a5,0x1d
    800042e4:	8807ae23          	sw	zero,-1892(a5) # 80020b7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	c50080e7          	jalr	-944(ra) # 80003f38 <write_head>
    800042f0:	bdf5                	j	800041ec <end_op+0x52>

00000000800042f2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042f2:	1101                	addi	sp,sp,-32
    800042f4:	ec06                	sd	ra,24(sp)
    800042f6:	e822                	sd	s0,16(sp)
    800042f8:	e426                	sd	s1,8(sp)
    800042fa:	e04a                	sd	s2,0(sp)
    800042fc:	1000                	addi	s0,sp,32
    800042fe:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004300:	0001d917          	auipc	s2,0x1d
    80004304:	85090913          	addi	s2,s2,-1968 # 80020b50 <log>
    80004308:	854a                	mv	a0,s2
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	92c080e7          	jalr	-1748(ra) # 80000c36 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004312:	02c92603          	lw	a2,44(s2)
    80004316:	47f5                	li	a5,29
    80004318:	06c7c563          	blt	a5,a2,80004382 <log_write+0x90>
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	8507a783          	lw	a5,-1968(a5) # 80020b6c <log+0x1c>
    80004324:	37fd                	addiw	a5,a5,-1
    80004326:	04f65e63          	bge	a2,a5,80004382 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000432a:	0001d797          	auipc	a5,0x1d
    8000432e:	8467a783          	lw	a5,-1978(a5) # 80020b70 <log+0x20>
    80004332:	06f05063          	blez	a5,80004392 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004336:	4781                	li	a5,0
    80004338:	06c05563          	blez	a2,800043a2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000433c:	44cc                	lw	a1,12(s1)
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	84270713          	addi	a4,a4,-1982 # 80020b80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004346:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004348:	4314                	lw	a3,0(a4)
    8000434a:	04b68c63          	beq	a3,a1,800043a2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000434e:	2785                	addiw	a5,a5,1
    80004350:	0711                	addi	a4,a4,4
    80004352:	fef61be3          	bne	a2,a5,80004348 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004356:	0621                	addi	a2,a2,8
    80004358:	060a                	slli	a2,a2,0x2
    8000435a:	0001c797          	auipc	a5,0x1c
    8000435e:	7f678793          	addi	a5,a5,2038 # 80020b50 <log>
    80004362:	963e                	add	a2,a2,a5
    80004364:	44dc                	lw	a5,12(s1)
    80004366:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004368:	8526                	mv	a0,s1
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	da2080e7          	jalr	-606(ra) # 8000310c <bpin>
    log.lh.n++;
    80004372:	0001c717          	auipc	a4,0x1c
    80004376:	7de70713          	addi	a4,a4,2014 # 80020b50 <log>
    8000437a:	575c                	lw	a5,44(a4)
    8000437c:	2785                	addiw	a5,a5,1
    8000437e:	d75c                	sw	a5,44(a4)
    80004380:	a835                	j	800043bc <log_write+0xca>
    panic("too big a transaction");
    80004382:	00004517          	auipc	a0,0x4
    80004386:	2ee50513          	addi	a0,a0,750 # 80008670 <syscalls+0x1f8>
    8000438a:	ffffc097          	auipc	ra,0xffffc
    8000438e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004392:	00004517          	auipc	a0,0x4
    80004396:	2f650513          	addi	a0,a0,758 # 80008688 <syscalls+0x210>
    8000439a:	ffffc097          	auipc	ra,0xffffc
    8000439e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043a2:	00878713          	addi	a4,a5,8
    800043a6:	00271693          	slli	a3,a4,0x2
    800043aa:	0001c717          	auipc	a4,0x1c
    800043ae:	7a670713          	addi	a4,a4,1958 # 80020b50 <log>
    800043b2:	9736                	add	a4,a4,a3
    800043b4:	44d4                	lw	a3,12(s1)
    800043b6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043b8:	faf608e3          	beq	a2,a5,80004368 <log_write+0x76>
  }
  release(&log.lock);
    800043bc:	0001c517          	auipc	a0,0x1c
    800043c0:	79450513          	addi	a0,a0,1940 # 80020b50 <log>
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	95c080e7          	jalr	-1700(ra) # 80000d20 <release>
}
    800043cc:	60e2                	ld	ra,24(sp)
    800043ce:	6442                	ld	s0,16(sp)
    800043d0:	64a2                	ld	s1,8(sp)
    800043d2:	6902                	ld	s2,0(sp)
    800043d4:	6105                	addi	sp,sp,32
    800043d6:	8082                	ret

00000000800043d8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043d8:	1101                	addi	sp,sp,-32
    800043da:	ec06                	sd	ra,24(sp)
    800043dc:	e822                	sd	s0,16(sp)
    800043de:	e426                	sd	s1,8(sp)
    800043e0:	e04a                	sd	s2,0(sp)
    800043e2:	1000                	addi	s0,sp,32
    800043e4:	84aa                	mv	s1,a0
    800043e6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043e8:	00004597          	auipc	a1,0x4
    800043ec:	2c058593          	addi	a1,a1,704 # 800086a8 <syscalls+0x230>
    800043f0:	0521                	addi	a0,a0,8
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	7b0080e7          	jalr	1968(ra) # 80000ba2 <initlock>
  lk->name = name;
    800043fa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043fe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004402:	0204a423          	sw	zero,40(s1)
}
    80004406:	60e2                	ld	ra,24(sp)
    80004408:	6442                	ld	s0,16(sp)
    8000440a:	64a2                	ld	s1,8(sp)
    8000440c:	6902                	ld	s2,0(sp)
    8000440e:	6105                	addi	sp,sp,32
    80004410:	8082                	ret

0000000080004412 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004412:	1101                	addi	sp,sp,-32
    80004414:	ec06                	sd	ra,24(sp)
    80004416:	e822                	sd	s0,16(sp)
    80004418:	e426                	sd	s1,8(sp)
    8000441a:	e04a                	sd	s2,0(sp)
    8000441c:	1000                	addi	s0,sp,32
    8000441e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004420:	00850913          	addi	s2,a0,8
    80004424:	854a                	mv	a0,s2
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	810080e7          	jalr	-2032(ra) # 80000c36 <acquire>
  while (lk->locked) {
    8000442e:	409c                	lw	a5,0(s1)
    80004430:	cb89                	beqz	a5,80004442 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004432:	85ca                	mv	a1,s2
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	cce080e7          	jalr	-818(ra) # 80002104 <sleep>
  while (lk->locked) {
    8000443e:	409c                	lw	a5,0(s1)
    80004440:	fbed                	bnez	a5,80004432 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004442:	4785                	li	a5,1
    80004444:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	616080e7          	jalr	1558(ra) # 80001a5c <myproc>
    8000444e:	591c                	lw	a5,48(a0)
    80004450:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004452:	854a                	mv	a0,s2
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	8cc080e7          	jalr	-1844(ra) # 80000d20 <release>
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004468:	1101                	addi	sp,sp,-32
    8000446a:	ec06                	sd	ra,24(sp)
    8000446c:	e822                	sd	s0,16(sp)
    8000446e:	e426                	sd	s1,8(sp)
    80004470:	e04a                	sd	s2,0(sp)
    80004472:	1000                	addi	s0,sp,32
    80004474:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	7ba080e7          	jalr	1978(ra) # 80000c36 <acquire>
  lk->locked = 0;
    80004484:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004488:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffe097          	auipc	ra,0xffffe
    80004492:	cda080e7          	jalr	-806(ra) # 80002168 <wakeup>
  release(&lk->lk);
    80004496:	854a                	mv	a0,s2
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	888080e7          	jalr	-1912(ra) # 80000d20 <release>
}
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6902                	ld	s2,0(sp)
    800044a8:	6105                	addi	sp,sp,32
    800044aa:	8082                	ret

00000000800044ac <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ac:	7179                	addi	sp,sp,-48
    800044ae:	f406                	sd	ra,40(sp)
    800044b0:	f022                	sd	s0,32(sp)
    800044b2:	ec26                	sd	s1,24(sp)
    800044b4:	e84a                	sd	s2,16(sp)
    800044b6:	e44e                	sd	s3,8(sp)
    800044b8:	1800                	addi	s0,sp,48
    800044ba:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044bc:	00850913          	addi	s2,a0,8
    800044c0:	854a                	mv	a0,s2
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	774080e7          	jalr	1908(ra) # 80000c36 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ca:	409c                	lw	a5,0(s1)
    800044cc:	ef99                	bnez	a5,800044ea <holdingsleep+0x3e>
    800044ce:	4481                	li	s1,0
  release(&lk->lk);
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	84e080e7          	jalr	-1970(ra) # 80000d20 <release>
  return r;
}
    800044da:	8526                	mv	a0,s1
    800044dc:	70a2                	ld	ra,40(sp)
    800044de:	7402                	ld	s0,32(sp)
    800044e0:	64e2                	ld	s1,24(sp)
    800044e2:	6942                	ld	s2,16(sp)
    800044e4:	69a2                	ld	s3,8(sp)
    800044e6:	6145                	addi	sp,sp,48
    800044e8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ea:	0284a983          	lw	s3,40(s1)
    800044ee:	ffffd097          	auipc	ra,0xffffd
    800044f2:	56e080e7          	jalr	1390(ra) # 80001a5c <myproc>
    800044f6:	5904                	lw	s1,48(a0)
    800044f8:	413484b3          	sub	s1,s1,s3
    800044fc:	0014b493          	seqz	s1,s1
    80004500:	bfc1                	j	800044d0 <holdingsleep+0x24>

0000000080004502 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004502:	1141                	addi	sp,sp,-16
    80004504:	e406                	sd	ra,8(sp)
    80004506:	e022                	sd	s0,0(sp)
    80004508:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000450a:	00004597          	auipc	a1,0x4
    8000450e:	1ae58593          	addi	a1,a1,430 # 800086b8 <syscalls+0x240>
    80004512:	0001c517          	auipc	a0,0x1c
    80004516:	78650513          	addi	a0,a0,1926 # 80020c98 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	688080e7          	jalr	1672(ra) # 80000ba2 <initlock>
}
    80004522:	60a2                	ld	ra,8(sp)
    80004524:	6402                	ld	s0,0(sp)
    80004526:	0141                	addi	sp,sp,16
    80004528:	8082                	ret

000000008000452a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000452a:	1101                	addi	sp,sp,-32
    8000452c:	ec06                	sd	ra,24(sp)
    8000452e:	e822                	sd	s0,16(sp)
    80004530:	e426                	sd	s1,8(sp)
    80004532:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004534:	0001c517          	auipc	a0,0x1c
    80004538:	76450513          	addi	a0,a0,1892 # 80020c98 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	6fa080e7          	jalr	1786(ra) # 80000c36 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004544:	0001c497          	auipc	s1,0x1c
    80004548:	76c48493          	addi	s1,s1,1900 # 80020cb0 <ftable+0x18>
    8000454c:	0001d717          	auipc	a4,0x1d
    80004550:	70470713          	addi	a4,a4,1796 # 80021c50 <disk>
    if(f->ref == 0){
    80004554:	40dc                	lw	a5,4(s1)
    80004556:	cf99                	beqz	a5,80004574 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004558:	02848493          	addi	s1,s1,40
    8000455c:	fee49ce3          	bne	s1,a4,80004554 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004560:	0001c517          	auipc	a0,0x1c
    80004564:	73850513          	addi	a0,a0,1848 # 80020c98 <ftable>
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	7b8080e7          	jalr	1976(ra) # 80000d20 <release>
  return 0;
    80004570:	4481                	li	s1,0
    80004572:	a819                	j	80004588 <filealloc+0x5e>
      f->ref = 1;
    80004574:	4785                	li	a5,1
    80004576:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004578:	0001c517          	auipc	a0,0x1c
    8000457c:	72050513          	addi	a0,a0,1824 # 80020c98 <ftable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	7a0080e7          	jalr	1952(ra) # 80000d20 <release>
}
    80004588:	8526                	mv	a0,s1
    8000458a:	60e2                	ld	ra,24(sp)
    8000458c:	6442                	ld	s0,16(sp)
    8000458e:	64a2                	ld	s1,8(sp)
    80004590:	6105                	addi	sp,sp,32
    80004592:	8082                	ret

0000000080004594 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	1000                	addi	s0,sp,32
    8000459e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045a0:	0001c517          	auipc	a0,0x1c
    800045a4:	6f850513          	addi	a0,a0,1784 # 80020c98 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	68e080e7          	jalr	1678(ra) # 80000c36 <acquire>
  if(f->ref < 1)
    800045b0:	40dc                	lw	a5,4(s1)
    800045b2:	02f05263          	blez	a5,800045d6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045b6:	2785                	addiw	a5,a5,1
    800045b8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ba:	0001c517          	auipc	a0,0x1c
    800045be:	6de50513          	addi	a0,a0,1758 # 80020c98 <ftable>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	75e080e7          	jalr	1886(ra) # 80000d20 <release>
  return f;
}
    800045ca:	8526                	mv	a0,s1
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6105                	addi	sp,sp,32
    800045d4:	8082                	ret
    panic("filedup");
    800045d6:	00004517          	auipc	a0,0x4
    800045da:	0ea50513          	addi	a0,a0,234 # 800086c0 <syscalls+0x248>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>

00000000800045e6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045e6:	7139                	addi	sp,sp,-64
    800045e8:	fc06                	sd	ra,56(sp)
    800045ea:	f822                	sd	s0,48(sp)
    800045ec:	f426                	sd	s1,40(sp)
    800045ee:	f04a                	sd	s2,32(sp)
    800045f0:	ec4e                	sd	s3,24(sp)
    800045f2:	e852                	sd	s4,16(sp)
    800045f4:	e456                	sd	s5,8(sp)
    800045f6:	0080                	addi	s0,sp,64
    800045f8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045fa:	0001c517          	auipc	a0,0x1c
    800045fe:	69e50513          	addi	a0,a0,1694 # 80020c98 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	634080e7          	jalr	1588(ra) # 80000c36 <acquire>
  if(f->ref < 1)
    8000460a:	40dc                	lw	a5,4(s1)
    8000460c:	06f05163          	blez	a5,8000466e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004610:	37fd                	addiw	a5,a5,-1
    80004612:	0007871b          	sext.w	a4,a5
    80004616:	c0dc                	sw	a5,4(s1)
    80004618:	06e04363          	bgtz	a4,8000467e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000461c:	0004a903          	lw	s2,0(s1)
    80004620:	0094ca83          	lbu	s5,9(s1)
    80004624:	0104ba03          	ld	s4,16(s1)
    80004628:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000462c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004630:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004634:	0001c517          	auipc	a0,0x1c
    80004638:	66450513          	addi	a0,a0,1636 # 80020c98 <ftable>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	6e4080e7          	jalr	1764(ra) # 80000d20 <release>

  if(ff.type == FD_PIPE){
    80004644:	4785                	li	a5,1
    80004646:	04f90d63          	beq	s2,a5,800046a0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000464a:	3979                	addiw	s2,s2,-2
    8000464c:	4785                	li	a5,1
    8000464e:	0527e063          	bltu	a5,s2,8000468e <fileclose+0xa8>
    begin_op();
    80004652:	00000097          	auipc	ra,0x0
    80004656:	ac8080e7          	jalr	-1336(ra) # 8000411a <begin_op>
    iput(ff.ip);
    8000465a:	854e                	mv	a0,s3
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	2b6080e7          	jalr	694(ra) # 80003912 <iput>
    end_op();
    80004664:	00000097          	auipc	ra,0x0
    80004668:	b36080e7          	jalr	-1226(ra) # 8000419a <end_op>
    8000466c:	a00d                	j	8000468e <fileclose+0xa8>
    panic("fileclose");
    8000466e:	00004517          	auipc	a0,0x4
    80004672:	05a50513          	addi	a0,a0,90 # 800086c8 <syscalls+0x250>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	ec8080e7          	jalr	-312(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000467e:	0001c517          	auipc	a0,0x1c
    80004682:	61a50513          	addi	a0,a0,1562 # 80020c98 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	69a080e7          	jalr	1690(ra) # 80000d20 <release>
  }
}
    8000468e:	70e2                	ld	ra,56(sp)
    80004690:	7442                	ld	s0,48(sp)
    80004692:	74a2                	ld	s1,40(sp)
    80004694:	7902                	ld	s2,32(sp)
    80004696:	69e2                	ld	s3,24(sp)
    80004698:	6a42                	ld	s4,16(sp)
    8000469a:	6aa2                	ld	s5,8(sp)
    8000469c:	6121                	addi	sp,sp,64
    8000469e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046a0:	85d6                	mv	a1,s5
    800046a2:	8552                	mv	a0,s4
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	34c080e7          	jalr	844(ra) # 800049f0 <pipeclose>
    800046ac:	b7cd                	j	8000468e <fileclose+0xa8>

00000000800046ae <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046ae:	715d                	addi	sp,sp,-80
    800046b0:	e486                	sd	ra,72(sp)
    800046b2:	e0a2                	sd	s0,64(sp)
    800046b4:	fc26                	sd	s1,56(sp)
    800046b6:	f84a                	sd	s2,48(sp)
    800046b8:	f44e                	sd	s3,40(sp)
    800046ba:	0880                	addi	s0,sp,80
    800046bc:	84aa                	mv	s1,a0
    800046be:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046c0:	ffffd097          	auipc	ra,0xffffd
    800046c4:	39c080e7          	jalr	924(ra) # 80001a5c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c8:	409c                	lw	a5,0(s1)
    800046ca:	37f9                	addiw	a5,a5,-2
    800046cc:	4705                	li	a4,1
    800046ce:	04f76763          	bltu	a4,a5,8000471c <filestat+0x6e>
    800046d2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	082080e7          	jalr	130(ra) # 80003758 <ilock>
    stati(f->ip, &st);
    800046de:	fb840593          	addi	a1,s0,-72
    800046e2:	6c88                	ld	a0,24(s1)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	2fe080e7          	jalr	766(ra) # 800039e2 <stati>
    iunlock(f->ip);
    800046ec:	6c88                	ld	a0,24(s1)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	12c080e7          	jalr	300(ra) # 8000381a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046f6:	46e1                	li	a3,24
    800046f8:	fb840613          	addi	a2,s0,-72
    800046fc:	85ce                	mv	a1,s3
    800046fe:	05093503          	ld	a0,80(s2)
    80004702:	ffffd097          	auipc	ra,0xffffd
    80004706:	016080e7          	jalr	22(ra) # 80001718 <copyout>
    8000470a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000470e:	60a6                	ld	ra,72(sp)
    80004710:	6406                	ld	s0,64(sp)
    80004712:	74e2                	ld	s1,56(sp)
    80004714:	7942                	ld	s2,48(sp)
    80004716:	79a2                	ld	s3,40(sp)
    80004718:	6161                	addi	sp,sp,80
    8000471a:	8082                	ret
  return -1;
    8000471c:	557d                	li	a0,-1
    8000471e:	bfc5                	j	8000470e <filestat+0x60>

0000000080004720 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004720:	7179                	addi	sp,sp,-48
    80004722:	f406                	sd	ra,40(sp)
    80004724:	f022                	sd	s0,32(sp)
    80004726:	ec26                	sd	s1,24(sp)
    80004728:	e84a                	sd	s2,16(sp)
    8000472a:	e44e                	sd	s3,8(sp)
    8000472c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000472e:	00854783          	lbu	a5,8(a0)
    80004732:	c3d5                	beqz	a5,800047d6 <fileread+0xb6>
    80004734:	84aa                	mv	s1,a0
    80004736:	89ae                	mv	s3,a1
    80004738:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000473a:	411c                	lw	a5,0(a0)
    8000473c:	4705                	li	a4,1
    8000473e:	04e78963          	beq	a5,a4,80004790 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004742:	470d                	li	a4,3
    80004744:	04e78d63          	beq	a5,a4,8000479e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004748:	4709                	li	a4,2
    8000474a:	06e79e63          	bne	a5,a4,800047c6 <fileread+0xa6>
    ilock(f->ip);
    8000474e:	6d08                	ld	a0,24(a0)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	008080e7          	jalr	8(ra) # 80003758 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004758:	874a                	mv	a4,s2
    8000475a:	5094                	lw	a3,32(s1)
    8000475c:	864e                	mv	a2,s3
    8000475e:	4585                	li	a1,1
    80004760:	6c88                	ld	a0,24(s1)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	2aa080e7          	jalr	682(ra) # 80003a0c <readi>
    8000476a:	892a                	mv	s2,a0
    8000476c:	00a05563          	blez	a0,80004776 <fileread+0x56>
      f->off += r;
    80004770:	509c                	lw	a5,32(s1)
    80004772:	9fa9                	addw	a5,a5,a0
    80004774:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004776:	6c88                	ld	a0,24(s1)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	0a2080e7          	jalr	162(ra) # 8000381a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004780:	854a                	mv	a0,s2
    80004782:	70a2                	ld	ra,40(sp)
    80004784:	7402                	ld	s0,32(sp)
    80004786:	64e2                	ld	s1,24(sp)
    80004788:	6942                	ld	s2,16(sp)
    8000478a:	69a2                	ld	s3,8(sp)
    8000478c:	6145                	addi	sp,sp,48
    8000478e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004790:	6908                	ld	a0,16(a0)
    80004792:	00000097          	auipc	ra,0x0
    80004796:	3c6080e7          	jalr	966(ra) # 80004b58 <piperead>
    8000479a:	892a                	mv	s2,a0
    8000479c:	b7d5                	j	80004780 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000479e:	02451783          	lh	a5,36(a0)
    800047a2:	03079693          	slli	a3,a5,0x30
    800047a6:	92c1                	srli	a3,a3,0x30
    800047a8:	4725                	li	a4,9
    800047aa:	02d76863          	bltu	a4,a3,800047da <fileread+0xba>
    800047ae:	0792                	slli	a5,a5,0x4
    800047b0:	0001c717          	auipc	a4,0x1c
    800047b4:	44870713          	addi	a4,a4,1096 # 80020bf8 <devsw>
    800047b8:	97ba                	add	a5,a5,a4
    800047ba:	639c                	ld	a5,0(a5)
    800047bc:	c38d                	beqz	a5,800047de <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047be:	4505                	li	a0,1
    800047c0:	9782                	jalr	a5
    800047c2:	892a                	mv	s2,a0
    800047c4:	bf75                	j	80004780 <fileread+0x60>
    panic("fileread");
    800047c6:	00004517          	auipc	a0,0x4
    800047ca:	f1250513          	addi	a0,a0,-238 # 800086d8 <syscalls+0x260>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>
    return -1;
    800047d6:	597d                	li	s2,-1
    800047d8:	b765                	j	80004780 <fileread+0x60>
      return -1;
    800047da:	597d                	li	s2,-1
    800047dc:	b755                	j	80004780 <fileread+0x60>
    800047de:	597d                	li	s2,-1
    800047e0:	b745                	j	80004780 <fileread+0x60>

00000000800047e2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047e2:	715d                	addi	sp,sp,-80
    800047e4:	e486                	sd	ra,72(sp)
    800047e6:	e0a2                	sd	s0,64(sp)
    800047e8:	fc26                	sd	s1,56(sp)
    800047ea:	f84a                	sd	s2,48(sp)
    800047ec:	f44e                	sd	s3,40(sp)
    800047ee:	f052                	sd	s4,32(sp)
    800047f0:	ec56                	sd	s5,24(sp)
    800047f2:	e85a                	sd	s6,16(sp)
    800047f4:	e45e                	sd	s7,8(sp)
    800047f6:	e062                	sd	s8,0(sp)
    800047f8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047fa:	00954783          	lbu	a5,9(a0)
    800047fe:	10078663          	beqz	a5,8000490a <filewrite+0x128>
    80004802:	892a                	mv	s2,a0
    80004804:	8aae                	mv	s5,a1
    80004806:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004808:	411c                	lw	a5,0(a0)
    8000480a:	4705                	li	a4,1
    8000480c:	02e78263          	beq	a5,a4,80004830 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004810:	470d                	li	a4,3
    80004812:	02e78663          	beq	a5,a4,8000483e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004816:	4709                	li	a4,2
    80004818:	0ee79163          	bne	a5,a4,800048fa <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000481c:	0ac05d63          	blez	a2,800048d6 <filewrite+0xf4>
    int i = 0;
    80004820:	4981                	li	s3,0
    80004822:	6b05                	lui	s6,0x1
    80004824:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004828:	6b85                	lui	s7,0x1
    8000482a:	c00b8b9b          	addiw	s7,s7,-1024
    8000482e:	a861                	j	800048c6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004830:	6908                	ld	a0,16(a0)
    80004832:	00000097          	auipc	ra,0x0
    80004836:	22e080e7          	jalr	558(ra) # 80004a60 <pipewrite>
    8000483a:	8a2a                	mv	s4,a0
    8000483c:	a045                	j	800048dc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000483e:	02451783          	lh	a5,36(a0)
    80004842:	03079693          	slli	a3,a5,0x30
    80004846:	92c1                	srli	a3,a3,0x30
    80004848:	4725                	li	a4,9
    8000484a:	0cd76263          	bltu	a4,a3,8000490e <filewrite+0x12c>
    8000484e:	0792                	slli	a5,a5,0x4
    80004850:	0001c717          	auipc	a4,0x1c
    80004854:	3a870713          	addi	a4,a4,936 # 80020bf8 <devsw>
    80004858:	97ba                	add	a5,a5,a4
    8000485a:	679c                	ld	a5,8(a5)
    8000485c:	cbdd                	beqz	a5,80004912 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000485e:	4505                	li	a0,1
    80004860:	9782                	jalr	a5
    80004862:	8a2a                	mv	s4,a0
    80004864:	a8a5                	j	800048dc <filewrite+0xfa>
    80004866:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	8b0080e7          	jalr	-1872(ra) # 8000411a <begin_op>
      ilock(f->ip);
    80004872:	01893503          	ld	a0,24(s2)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	ee2080e7          	jalr	-286(ra) # 80003758 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000487e:	8762                	mv	a4,s8
    80004880:	02092683          	lw	a3,32(s2)
    80004884:	01598633          	add	a2,s3,s5
    80004888:	4585                	li	a1,1
    8000488a:	01893503          	ld	a0,24(s2)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	276080e7          	jalr	630(ra) # 80003b04 <writei>
    80004896:	84aa                	mv	s1,a0
    80004898:	00a05763          	blez	a0,800048a6 <filewrite+0xc4>
        f->off += r;
    8000489c:	02092783          	lw	a5,32(s2)
    800048a0:	9fa9                	addw	a5,a5,a0
    800048a2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048a6:	01893503          	ld	a0,24(s2)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	f70080e7          	jalr	-144(ra) # 8000381a <iunlock>
      end_op();
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	8e8080e7          	jalr	-1816(ra) # 8000419a <end_op>

      if(r != n1){
    800048ba:	009c1f63          	bne	s8,s1,800048d8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048be:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048c2:	0149db63          	bge	s3,s4,800048d8 <filewrite+0xf6>
      int n1 = n - i;
    800048c6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048ca:	84be                	mv	s1,a5
    800048cc:	2781                	sext.w	a5,a5
    800048ce:	f8fb5ce3          	bge	s6,a5,80004866 <filewrite+0x84>
    800048d2:	84de                	mv	s1,s7
    800048d4:	bf49                	j	80004866 <filewrite+0x84>
    int i = 0;
    800048d6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048d8:	013a1f63          	bne	s4,s3,800048f6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048dc:	8552                	mv	a0,s4
    800048de:	60a6                	ld	ra,72(sp)
    800048e0:	6406                	ld	s0,64(sp)
    800048e2:	74e2                	ld	s1,56(sp)
    800048e4:	7942                	ld	s2,48(sp)
    800048e6:	79a2                	ld	s3,40(sp)
    800048e8:	7a02                	ld	s4,32(sp)
    800048ea:	6ae2                	ld	s5,24(sp)
    800048ec:	6b42                	ld	s6,16(sp)
    800048ee:	6ba2                	ld	s7,8(sp)
    800048f0:	6c02                	ld	s8,0(sp)
    800048f2:	6161                	addi	sp,sp,80
    800048f4:	8082                	ret
    ret = (i == n ? n : -1);
    800048f6:	5a7d                	li	s4,-1
    800048f8:	b7d5                	j	800048dc <filewrite+0xfa>
    panic("filewrite");
    800048fa:	00004517          	auipc	a0,0x4
    800048fe:	dee50513          	addi	a0,a0,-530 # 800086e8 <syscalls+0x270>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>
    return -1;
    8000490a:	5a7d                	li	s4,-1
    8000490c:	bfc1                	j	800048dc <filewrite+0xfa>
      return -1;
    8000490e:	5a7d                	li	s4,-1
    80004910:	b7f1                	j	800048dc <filewrite+0xfa>
    80004912:	5a7d                	li	s4,-1
    80004914:	b7e1                	j	800048dc <filewrite+0xfa>

0000000080004916 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004916:	7179                	addi	sp,sp,-48
    80004918:	f406                	sd	ra,40(sp)
    8000491a:	f022                	sd	s0,32(sp)
    8000491c:	ec26                	sd	s1,24(sp)
    8000491e:	e84a                	sd	s2,16(sp)
    80004920:	e44e                	sd	s3,8(sp)
    80004922:	e052                	sd	s4,0(sp)
    80004924:	1800                	addi	s0,sp,48
    80004926:	84aa                	mv	s1,a0
    80004928:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000492a:	0005b023          	sd	zero,0(a1)
    8000492e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004932:	00000097          	auipc	ra,0x0
    80004936:	bf8080e7          	jalr	-1032(ra) # 8000452a <filealloc>
    8000493a:	e088                	sd	a0,0(s1)
    8000493c:	c551                	beqz	a0,800049c8 <pipealloc+0xb2>
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	bec080e7          	jalr	-1044(ra) # 8000452a <filealloc>
    80004946:	00aa3023          	sd	a0,0(s4)
    8000494a:	c92d                	beqz	a0,800049bc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	1f6080e7          	jalr	502(ra) # 80000b42 <kalloc>
    80004954:	892a                	mv	s2,a0
    80004956:	c125                	beqz	a0,800049b6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004958:	4985                	li	s3,1
    8000495a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000495e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004962:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004966:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000496a:	00004597          	auipc	a1,0x4
    8000496e:	d8e58593          	addi	a1,a1,-626 # 800086f8 <syscalls+0x280>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	230080e7          	jalr	560(ra) # 80000ba2 <initlock>
  (*f0)->type = FD_PIPE;
    8000497a:	609c                	ld	a5,0(s1)
    8000497c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004980:	609c                	ld	a5,0(s1)
    80004982:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004986:	609c                	ld	a5,0(s1)
    80004988:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000498c:	609c                	ld	a5,0(s1)
    8000498e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004992:	000a3783          	ld	a5,0(s4)
    80004996:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000499a:	000a3783          	ld	a5,0(s4)
    8000499e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049a2:	000a3783          	ld	a5,0(s4)
    800049a6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049aa:	000a3783          	ld	a5,0(s4)
    800049ae:	0127b823          	sd	s2,16(a5)
  return 0;
    800049b2:	4501                	li	a0,0
    800049b4:	a025                	j	800049dc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049b6:	6088                	ld	a0,0(s1)
    800049b8:	e501                	bnez	a0,800049c0 <pipealloc+0xaa>
    800049ba:	a039                	j	800049c8 <pipealloc+0xb2>
    800049bc:	6088                	ld	a0,0(s1)
    800049be:	c51d                	beqz	a0,800049ec <pipealloc+0xd6>
    fileclose(*f0);
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	c26080e7          	jalr	-986(ra) # 800045e6 <fileclose>
  if(*f1)
    800049c8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049cc:	557d                	li	a0,-1
  if(*f1)
    800049ce:	c799                	beqz	a5,800049dc <pipealloc+0xc6>
    fileclose(*f1);
    800049d0:	853e                	mv	a0,a5
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	c14080e7          	jalr	-1004(ra) # 800045e6 <fileclose>
  return -1;
    800049da:	557d                	li	a0,-1
}
    800049dc:	70a2                	ld	ra,40(sp)
    800049de:	7402                	ld	s0,32(sp)
    800049e0:	64e2                	ld	s1,24(sp)
    800049e2:	6942                	ld	s2,16(sp)
    800049e4:	69a2                	ld	s3,8(sp)
    800049e6:	6a02                	ld	s4,0(sp)
    800049e8:	6145                	addi	sp,sp,48
    800049ea:	8082                	ret
  return -1;
    800049ec:	557d                	li	a0,-1
    800049ee:	b7fd                	j	800049dc <pipealloc+0xc6>

00000000800049f0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049f0:	1101                	addi	sp,sp,-32
    800049f2:	ec06                	sd	ra,24(sp)
    800049f4:	e822                	sd	s0,16(sp)
    800049f6:	e426                	sd	s1,8(sp)
    800049f8:	e04a                	sd	s2,0(sp)
    800049fa:	1000                	addi	s0,sp,32
    800049fc:	84aa                	mv	s1,a0
    800049fe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	236080e7          	jalr	566(ra) # 80000c36 <acquire>
  if(writable){
    80004a08:	02090d63          	beqz	s2,80004a42 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a0c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a10:	21848513          	addi	a0,s1,536
    80004a14:	ffffd097          	auipc	ra,0xffffd
    80004a18:	754080e7          	jalr	1876(ra) # 80002168 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a1c:	2204b783          	ld	a5,544(s1)
    80004a20:	eb95                	bnez	a5,80004a54 <pipeclose+0x64>
    release(&pi->lock);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	2fc080e7          	jalr	764(ra) # 80000d20 <release>
    kfree((char*)pi);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	018080e7          	jalr	24(ra) # 80000a46 <kfree>
  } else
    release(&pi->lock);
}
    80004a36:	60e2                	ld	ra,24(sp)
    80004a38:	6442                	ld	s0,16(sp)
    80004a3a:	64a2                	ld	s1,8(sp)
    80004a3c:	6902                	ld	s2,0(sp)
    80004a3e:	6105                	addi	sp,sp,32
    80004a40:	8082                	ret
    pi->readopen = 0;
    80004a42:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a46:	21c48513          	addi	a0,s1,540
    80004a4a:	ffffd097          	auipc	ra,0xffffd
    80004a4e:	71e080e7          	jalr	1822(ra) # 80002168 <wakeup>
    80004a52:	b7e9                	j	80004a1c <pipeclose+0x2c>
    release(&pi->lock);
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	2ca080e7          	jalr	714(ra) # 80000d20 <release>
}
    80004a5e:	bfe1                	j	80004a36 <pipeclose+0x46>

0000000080004a60 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a60:	711d                	addi	sp,sp,-96
    80004a62:	ec86                	sd	ra,88(sp)
    80004a64:	e8a2                	sd	s0,80(sp)
    80004a66:	e4a6                	sd	s1,72(sp)
    80004a68:	e0ca                	sd	s2,64(sp)
    80004a6a:	fc4e                	sd	s3,56(sp)
    80004a6c:	f852                	sd	s4,48(sp)
    80004a6e:	f456                	sd	s5,40(sp)
    80004a70:	f05a                	sd	s6,32(sp)
    80004a72:	ec5e                	sd	s7,24(sp)
    80004a74:	e862                	sd	s8,16(sp)
    80004a76:	1080                	addi	s0,sp,96
    80004a78:	84aa                	mv	s1,a0
    80004a7a:	8aae                	mv	s5,a1
    80004a7c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a7e:	ffffd097          	auipc	ra,0xffffd
    80004a82:	fde080e7          	jalr	-34(ra) # 80001a5c <myproc>
    80004a86:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a88:	8526                	mv	a0,s1
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	1ac080e7          	jalr	428(ra) # 80000c36 <acquire>
  while(i < n){
    80004a92:	0b405663          	blez	s4,80004b3e <pipewrite+0xde>
  int i = 0;
    80004a96:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a98:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a9a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a9e:	21c48b93          	addi	s7,s1,540
    80004aa2:	a089                	j	80004ae4 <pipewrite+0x84>
      release(&pi->lock);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	27a080e7          	jalr	634(ra) # 80000d20 <release>
      return -1;
    80004aae:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ab0:	854a                	mv	a0,s2
    80004ab2:	60e6                	ld	ra,88(sp)
    80004ab4:	6446                	ld	s0,80(sp)
    80004ab6:	64a6                	ld	s1,72(sp)
    80004ab8:	6906                	ld	s2,64(sp)
    80004aba:	79e2                	ld	s3,56(sp)
    80004abc:	7a42                	ld	s4,48(sp)
    80004abe:	7aa2                	ld	s5,40(sp)
    80004ac0:	7b02                	ld	s6,32(sp)
    80004ac2:	6be2                	ld	s7,24(sp)
    80004ac4:	6c42                	ld	s8,16(sp)
    80004ac6:	6125                	addi	sp,sp,96
    80004ac8:	8082                	ret
      wakeup(&pi->nread);
    80004aca:	8562                	mv	a0,s8
    80004acc:	ffffd097          	auipc	ra,0xffffd
    80004ad0:	69c080e7          	jalr	1692(ra) # 80002168 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ad4:	85a6                	mv	a1,s1
    80004ad6:	855e                	mv	a0,s7
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	62c080e7          	jalr	1580(ra) # 80002104 <sleep>
  while(i < n){
    80004ae0:	07495063          	bge	s2,s4,80004b40 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ae4:	2204a783          	lw	a5,544(s1)
    80004ae8:	dfd5                	beqz	a5,80004aa4 <pipewrite+0x44>
    80004aea:	854e                	mv	a0,s3
    80004aec:	ffffe097          	auipc	ra,0xffffe
    80004af0:	8c0080e7          	jalr	-1856(ra) # 800023ac <killed>
    80004af4:	f945                	bnez	a0,80004aa4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004af6:	2184a783          	lw	a5,536(s1)
    80004afa:	21c4a703          	lw	a4,540(s1)
    80004afe:	2007879b          	addiw	a5,a5,512
    80004b02:	fcf704e3          	beq	a4,a5,80004aca <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b06:	4685                	li	a3,1
    80004b08:	01590633          	add	a2,s2,s5
    80004b0c:	faf40593          	addi	a1,s0,-81
    80004b10:	0509b503          	ld	a0,80(s3)
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	c90080e7          	jalr	-880(ra) # 800017a4 <copyin>
    80004b1c:	03650263          	beq	a0,s6,80004b40 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b20:	21c4a783          	lw	a5,540(s1)
    80004b24:	0017871b          	addiw	a4,a5,1
    80004b28:	20e4ae23          	sw	a4,540(s1)
    80004b2c:	1ff7f793          	andi	a5,a5,511
    80004b30:	97a6                	add	a5,a5,s1
    80004b32:	faf44703          	lbu	a4,-81(s0)
    80004b36:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b3a:	2905                	addiw	s2,s2,1
    80004b3c:	b755                	j	80004ae0 <pipewrite+0x80>
  int i = 0;
    80004b3e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b40:	21848513          	addi	a0,s1,536
    80004b44:	ffffd097          	auipc	ra,0xffffd
    80004b48:	624080e7          	jalr	1572(ra) # 80002168 <wakeup>
  release(&pi->lock);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	1d2080e7          	jalr	466(ra) # 80000d20 <release>
  return i;
    80004b56:	bfa9                	j	80004ab0 <pipewrite+0x50>

0000000080004b58 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b58:	715d                	addi	sp,sp,-80
    80004b5a:	e486                	sd	ra,72(sp)
    80004b5c:	e0a2                	sd	s0,64(sp)
    80004b5e:	fc26                	sd	s1,56(sp)
    80004b60:	f84a                	sd	s2,48(sp)
    80004b62:	f44e                	sd	s3,40(sp)
    80004b64:	f052                	sd	s4,32(sp)
    80004b66:	ec56                	sd	s5,24(sp)
    80004b68:	e85a                	sd	s6,16(sp)
    80004b6a:	0880                	addi	s0,sp,80
    80004b6c:	84aa                	mv	s1,a0
    80004b6e:	892e                	mv	s2,a1
    80004b70:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	eea080e7          	jalr	-278(ra) # 80001a5c <myproc>
    80004b7a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	0b8080e7          	jalr	184(ra) # 80000c36 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b86:	2184a703          	lw	a4,536(s1)
    80004b8a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b8e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b92:	02f71763          	bne	a4,a5,80004bc0 <piperead+0x68>
    80004b96:	2244a783          	lw	a5,548(s1)
    80004b9a:	c39d                	beqz	a5,80004bc0 <piperead+0x68>
    if(killed(pr)){
    80004b9c:	8552                	mv	a0,s4
    80004b9e:	ffffe097          	auipc	ra,0xffffe
    80004ba2:	80e080e7          	jalr	-2034(ra) # 800023ac <killed>
    80004ba6:	e941                	bnez	a0,80004c36 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ba8:	85a6                	mv	a1,s1
    80004baa:	854e                	mv	a0,s3
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	558080e7          	jalr	1368(ra) # 80002104 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb4:	2184a703          	lw	a4,536(s1)
    80004bb8:	21c4a783          	lw	a5,540(s1)
    80004bbc:	fcf70de3          	beq	a4,a5,80004b96 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc4:	05505363          	blez	s5,80004c0a <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004bc8:	2184a783          	lw	a5,536(s1)
    80004bcc:	21c4a703          	lw	a4,540(s1)
    80004bd0:	02f70d63          	beq	a4,a5,80004c0a <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bd4:	0017871b          	addiw	a4,a5,1
    80004bd8:	20e4ac23          	sw	a4,536(s1)
    80004bdc:	1ff7f793          	andi	a5,a5,511
    80004be0:	97a6                	add	a5,a5,s1
    80004be2:	0187c783          	lbu	a5,24(a5)
    80004be6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bea:	4685                	li	a3,1
    80004bec:	fbf40613          	addi	a2,s0,-65
    80004bf0:	85ca                	mv	a1,s2
    80004bf2:	050a3503          	ld	a0,80(s4)
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	b22080e7          	jalr	-1246(ra) # 80001718 <copyout>
    80004bfe:	01650663          	beq	a0,s6,80004c0a <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c02:	2985                	addiw	s3,s3,1
    80004c04:	0905                	addi	s2,s2,1
    80004c06:	fd3a91e3          	bne	s5,s3,80004bc8 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c0a:	21c48513          	addi	a0,s1,540
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	55a080e7          	jalr	1370(ra) # 80002168 <wakeup>
  release(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	108080e7          	jalr	264(ra) # 80000d20 <release>
  return i;
}
    80004c20:	854e                	mv	a0,s3
    80004c22:	60a6                	ld	ra,72(sp)
    80004c24:	6406                	ld	s0,64(sp)
    80004c26:	74e2                	ld	s1,56(sp)
    80004c28:	7942                	ld	s2,48(sp)
    80004c2a:	79a2                	ld	s3,40(sp)
    80004c2c:	7a02                	ld	s4,32(sp)
    80004c2e:	6ae2                	ld	s5,24(sp)
    80004c30:	6b42                	ld	s6,16(sp)
    80004c32:	6161                	addi	sp,sp,80
    80004c34:	8082                	ret
      release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	0e8080e7          	jalr	232(ra) # 80000d20 <release>
      return -1;
    80004c40:	59fd                	li	s3,-1
    80004c42:	bff9                	j	80004c20 <piperead+0xc8>

0000000080004c44 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c44:	1141                	addi	sp,sp,-16
    80004c46:	e422                	sd	s0,8(sp)
    80004c48:	0800                	addi	s0,sp,16
    80004c4a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c4c:	8905                	andi	a0,a0,1
    80004c4e:	c111                	beqz	a0,80004c52 <flags2perm+0xe>
      perm = PTE_X;
    80004c50:	4521                	li	a0,8
    if(flags & 0x2)
    80004c52:	8b89                	andi	a5,a5,2
    80004c54:	c399                	beqz	a5,80004c5a <flags2perm+0x16>
      perm |= PTE_W;
    80004c56:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c5a:	6422                	ld	s0,8(sp)
    80004c5c:	0141                	addi	sp,sp,16
    80004c5e:	8082                	ret

0000000080004c60 <exec>:

int
exec(char *path, char **argv)
{
    80004c60:	de010113          	addi	sp,sp,-544
    80004c64:	20113c23          	sd	ra,536(sp)
    80004c68:	20813823          	sd	s0,528(sp)
    80004c6c:	20913423          	sd	s1,520(sp)
    80004c70:	21213023          	sd	s2,512(sp)
    80004c74:	ffce                	sd	s3,504(sp)
    80004c76:	fbd2                	sd	s4,496(sp)
    80004c78:	f7d6                	sd	s5,488(sp)
    80004c7a:	f3da                	sd	s6,480(sp)
    80004c7c:	efde                	sd	s7,472(sp)
    80004c7e:	ebe2                	sd	s8,464(sp)
    80004c80:	e7e6                	sd	s9,456(sp)
    80004c82:	e3ea                	sd	s10,448(sp)
    80004c84:	ff6e                	sd	s11,440(sp)
    80004c86:	1400                	addi	s0,sp,544
    80004c88:	892a                	mv	s2,a0
    80004c8a:	dea43423          	sd	a0,-536(s0)
    80004c8e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	dca080e7          	jalr	-566(ra) # 80001a5c <myproc>
    80004c9a:	84aa                	mv	s1,a0
  begin_op();
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	47e080e7          	jalr	1150(ra) # 8000411a <begin_op>
  //p = 0;
  if((ip = namei(path)) == 0){
    80004ca4:	854a                	mv	a0,s2
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	258080e7          	jalr	600(ra) # 80003efe <namei>
    80004cae:	c93d                	beqz	a0,80004d24 <exec+0xc4>
    80004cb0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	aa6080e7          	jalr	-1370(ra) # 80003758 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cba:	04000713          	li	a4,64
    80004cbe:	4681                	li	a3,0
    80004cc0:	e5040613          	addi	a2,s0,-432
    80004cc4:	4581                	li	a1,0
    80004cc6:	8556                	mv	a0,s5
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	d44080e7          	jalr	-700(ra) # 80003a0c <readi>
    80004cd0:	04000793          	li	a5,64
    80004cd4:	00f51a63          	bne	a0,a5,80004ce8 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cd8:	e5042703          	lw	a4,-432(s0)
    80004cdc:	464c47b7          	lui	a5,0x464c4
    80004ce0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ce4:	04f70663          	beq	a4,a5,80004d30 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ce8:	8556                	mv	a0,s5
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	cd0080e7          	jalr	-816(ra) # 800039ba <iunlockput>
    end_op();
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	4a8080e7          	jalr	1192(ra) # 8000419a <end_op>
  }
  return -1;
    80004cfa:	557d                	li	a0,-1
}
    80004cfc:	21813083          	ld	ra,536(sp)
    80004d00:	21013403          	ld	s0,528(sp)
    80004d04:	20813483          	ld	s1,520(sp)
    80004d08:	20013903          	ld	s2,512(sp)
    80004d0c:	79fe                	ld	s3,504(sp)
    80004d0e:	7a5e                	ld	s4,496(sp)
    80004d10:	7abe                	ld	s5,488(sp)
    80004d12:	7b1e                	ld	s6,480(sp)
    80004d14:	6bfe                	ld	s7,472(sp)
    80004d16:	6c5e                	ld	s8,464(sp)
    80004d18:	6cbe                	ld	s9,456(sp)
    80004d1a:	6d1e                	ld	s10,448(sp)
    80004d1c:	7dfa                	ld	s11,440(sp)
    80004d1e:	22010113          	addi	sp,sp,544
    80004d22:	8082                	ret
    end_op();
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	476080e7          	jalr	1142(ra) # 8000419a <end_op>
    return -1;
    80004d2c:	557d                	li	a0,-1
    80004d2e:	b7f9                	j	80004cfc <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d30:	8526                	mv	a0,s1
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	dee080e7          	jalr	-530(ra) # 80001b20 <proc_pagetable>
    80004d3a:	8b2a                	mv	s6,a0
    80004d3c:	d555                	beqz	a0,80004ce8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d3e:	e7042783          	lw	a5,-400(s0)
    80004d42:	e8845703          	lhu	a4,-376(s0)
    80004d46:	c735                	beqz	a4,80004db2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d48:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d4a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d4e:	6a05                	lui	s4,0x1
    80004d50:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d54:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d58:	6d85                	lui	s11,0x1
    80004d5a:	7d7d                	lui	s10,0xfffff
    80004d5c:	a481                	j	80004f9c <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d5e:	00004517          	auipc	a0,0x4
    80004d62:	9a250513          	addi	a0,a0,-1630 # 80008700 <syscalls+0x288>
    80004d66:	ffffb097          	auipc	ra,0xffffb
    80004d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d6e:	874a                	mv	a4,s2
    80004d70:	009c86bb          	addw	a3,s9,s1
    80004d74:	4581                	li	a1,0
    80004d76:	8556                	mv	a0,s5
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	c94080e7          	jalr	-876(ra) # 80003a0c <readi>
    80004d80:	2501                	sext.w	a0,a0
    80004d82:	1aa91a63          	bne	s2,a0,80004f36 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d86:	009d84bb          	addw	s1,s11,s1
    80004d8a:	013d09bb          	addw	s3,s10,s3
    80004d8e:	1f74f763          	bgeu	s1,s7,80004f7c <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004d92:	02049593          	slli	a1,s1,0x20
    80004d96:	9181                	srli	a1,a1,0x20
    80004d98:	95e2                	add	a1,a1,s8
    80004d9a:	855a                	mv	a0,s6
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	370080e7          	jalr	880(ra) # 8000110c <walkaddr>
    80004da4:	862a                	mv	a2,a0
    if(pa == 0)
    80004da6:	dd45                	beqz	a0,80004d5e <exec+0xfe>
      n = PGSIZE;
    80004da8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004daa:	fd49f2e3          	bgeu	s3,s4,80004d6e <exec+0x10e>
      n = sz - i;
    80004dae:	894e                	mv	s2,s3
    80004db0:	bf7d                	j	80004d6e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004db2:	4901                	li	s2,0
  iunlockput(ip);
    80004db4:	8556                	mv	a0,s5
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	c04080e7          	jalr	-1020(ra) # 800039ba <iunlockput>
  end_op();
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	3dc080e7          	jalr	988(ra) # 8000419a <end_op>
  p = myproc();
    80004dc6:	ffffd097          	auipc	ra,0xffffd
    80004dca:	c96080e7          	jalr	-874(ra) # 80001a5c <myproc>
    80004dce:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dd0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dd4:	6785                	lui	a5,0x1
    80004dd6:	17fd                	addi	a5,a5,-1
    80004dd8:	993e                	add	s2,s2,a5
    80004dda:	77fd                	lui	a5,0xfffff
    80004ddc:	00f977b3          	and	a5,s2,a5
    80004de0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004de4:	4691                	li	a3,4
    80004de6:	6609                	lui	a2,0x2
    80004de8:	963e                	add	a2,a2,a5
    80004dea:	85be                	mv	a1,a5
    80004dec:	855a                	mv	a0,s6
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	6d2080e7          	jalr	1746(ra) # 800014c0 <uvmalloc>
    80004df6:	8c2a                	mv	s8,a0
  ip = 0;
    80004df8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dfa:	12050e63          	beqz	a0,80004f36 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dfe:	75f9                	lui	a1,0xffffe
    80004e00:	95aa                	add	a1,a1,a0
    80004e02:	855a                	mv	a0,s6
    80004e04:	ffffd097          	auipc	ra,0xffffd
    80004e08:	8e2080e7          	jalr	-1822(ra) # 800016e6 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e0c:	7afd                	lui	s5,0xfffff
    80004e0e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e10:	df043783          	ld	a5,-528(s0)
    80004e14:	6388                	ld	a0,0(a5)
    80004e16:	c925                	beqz	a0,80004e86 <exec+0x226>
    80004e18:	e9040993          	addi	s3,s0,-368
    80004e1c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e20:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e22:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	0c6080e7          	jalr	198(ra) # 80000eea <strlen>
    80004e2c:	0015079b          	addiw	a5,a0,1
    80004e30:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e34:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e38:	13596663          	bltu	s2,s5,80004f64 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e3c:	df043d83          	ld	s11,-528(s0)
    80004e40:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e44:	8552                	mv	a0,s4
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	0a4080e7          	jalr	164(ra) # 80000eea <strlen>
    80004e4e:	0015069b          	addiw	a3,a0,1
    80004e52:	8652                	mv	a2,s4
    80004e54:	85ca                	mv	a1,s2
    80004e56:	855a                	mv	a0,s6
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	8c0080e7          	jalr	-1856(ra) # 80001718 <copyout>
    80004e60:	10054663          	bltz	a0,80004f6c <exec+0x30c>
    ustack[argc] = sp;
    80004e64:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e68:	0485                	addi	s1,s1,1
    80004e6a:	008d8793          	addi	a5,s11,8
    80004e6e:	def43823          	sd	a5,-528(s0)
    80004e72:	008db503          	ld	a0,8(s11)
    80004e76:	c911                	beqz	a0,80004e8a <exec+0x22a>
    if(argc >= MAXARG)
    80004e78:	09a1                	addi	s3,s3,8
    80004e7a:	fb3c95e3          	bne	s9,s3,80004e24 <exec+0x1c4>
  sz = sz1;
    80004e7e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e82:	4a81                	li	s5,0
    80004e84:	a84d                	j	80004f36 <exec+0x2d6>
  sp = sz;
    80004e86:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e88:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e8a:	00349793          	slli	a5,s1,0x3
    80004e8e:	f9040713          	addi	a4,s0,-112
    80004e92:	97ba                	add	a5,a5,a4
    80004e94:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd170>
  sp -= (argc+1) * sizeof(uint64);
    80004e98:	00148693          	addi	a3,s1,1
    80004e9c:	068e                	slli	a3,a3,0x3
    80004e9e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ea2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ea6:	01597663          	bgeu	s2,s5,80004eb2 <exec+0x252>
  sz = sz1;
    80004eaa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eae:	4a81                	li	s5,0
    80004eb0:	a059                	j	80004f36 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eb2:	e9040613          	addi	a2,s0,-368
    80004eb6:	85ca                	mv	a1,s2
    80004eb8:	855a                	mv	a0,s6
    80004eba:	ffffd097          	auipc	ra,0xffffd
    80004ebe:	85e080e7          	jalr	-1954(ra) # 80001718 <copyout>
    80004ec2:	0a054963          	bltz	a0,80004f74 <exec+0x314>
  p->trapframe->a1 = sp;
    80004ec6:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004eca:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ece:	de843783          	ld	a5,-536(s0)
    80004ed2:	0007c703          	lbu	a4,0(a5)
    80004ed6:	cf11                	beqz	a4,80004ef2 <exec+0x292>
    80004ed8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eda:	02f00693          	li	a3,47
    80004ede:	a039                	j	80004eec <exec+0x28c>
      last = s+1;
    80004ee0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ee4:	0785                	addi	a5,a5,1
    80004ee6:	fff7c703          	lbu	a4,-1(a5)
    80004eea:	c701                	beqz	a4,80004ef2 <exec+0x292>
    if(*s == '/')
    80004eec:	fed71ce3          	bne	a4,a3,80004ee4 <exec+0x284>
    80004ef0:	bfc5                	j	80004ee0 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ef2:	4641                	li	a2,16
    80004ef4:	de843583          	ld	a1,-536(s0)
    80004ef8:	158b8513          	addi	a0,s7,344
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	fbc080e7          	jalr	-68(ra) # 80000eb8 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f04:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f08:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f0c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f10:	058bb783          	ld	a5,88(s7)
    80004f14:	e6843703          	ld	a4,-408(s0)
    80004f18:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f1a:	058bb783          	ld	a5,88(s7)
    80004f1e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f22:	85ea                	mv	a1,s10
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	c98080e7          	jalr	-872(ra) # 80001bbc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f2c:	0004851b          	sext.w	a0,s1
    80004f30:	b3f1                	j	80004cfc <exec+0x9c>
    80004f32:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f36:	df843583          	ld	a1,-520(s0)
    80004f3a:	855a                	mv	a0,s6
    80004f3c:	ffffd097          	auipc	ra,0xffffd
    80004f40:	c80080e7          	jalr	-896(ra) # 80001bbc <proc_freepagetable>
  if(ip){
    80004f44:	da0a92e3          	bnez	s5,80004ce8 <exec+0x88>
  return -1;
    80004f48:	557d                	li	a0,-1
    80004f4a:	bb4d                	j	80004cfc <exec+0x9c>
    80004f4c:	df243c23          	sd	s2,-520(s0)
    80004f50:	b7dd                	j	80004f36 <exec+0x2d6>
    80004f52:	df243c23          	sd	s2,-520(s0)
    80004f56:	b7c5                	j	80004f36 <exec+0x2d6>
    80004f58:	df243c23          	sd	s2,-520(s0)
    80004f5c:	bfe9                	j	80004f36 <exec+0x2d6>
    80004f5e:	df243c23          	sd	s2,-520(s0)
    80004f62:	bfd1                	j	80004f36 <exec+0x2d6>
  sz = sz1;
    80004f64:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f68:	4a81                	li	s5,0
    80004f6a:	b7f1                	j	80004f36 <exec+0x2d6>
  sz = sz1;
    80004f6c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f70:	4a81                	li	s5,0
    80004f72:	b7d1                	j	80004f36 <exec+0x2d6>
  sz = sz1;
    80004f74:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f78:	4a81                	li	s5,0
    80004f7a:	bf75                	j	80004f36 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f7c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f80:	e0843783          	ld	a5,-504(s0)
    80004f84:	0017869b          	addiw	a3,a5,1
    80004f88:	e0d43423          	sd	a3,-504(s0)
    80004f8c:	e0043783          	ld	a5,-512(s0)
    80004f90:	0387879b          	addiw	a5,a5,56
    80004f94:	e8845703          	lhu	a4,-376(s0)
    80004f98:	e0e6dee3          	bge	a3,a4,80004db4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f9c:	2781                	sext.w	a5,a5
    80004f9e:	e0f43023          	sd	a5,-512(s0)
    80004fa2:	03800713          	li	a4,56
    80004fa6:	86be                	mv	a3,a5
    80004fa8:	e1840613          	addi	a2,s0,-488
    80004fac:	4581                	li	a1,0
    80004fae:	8556                	mv	a0,s5
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	a5c080e7          	jalr	-1444(ra) # 80003a0c <readi>
    80004fb8:	03800793          	li	a5,56
    80004fbc:	f6f51be3          	bne	a0,a5,80004f32 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80004fc0:	e1842783          	lw	a5,-488(s0)
    80004fc4:	4705                	li	a4,1
    80004fc6:	fae79de3          	bne	a5,a4,80004f80 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80004fca:	e4043483          	ld	s1,-448(s0)
    80004fce:	e3843783          	ld	a5,-456(s0)
    80004fd2:	f6f4ede3          	bltu	s1,a5,80004f4c <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fd6:	e2843783          	ld	a5,-472(s0)
    80004fda:	94be                	add	s1,s1,a5
    80004fdc:	f6f4ebe3          	bltu	s1,a5,80004f52 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80004fe0:	de043703          	ld	a4,-544(s0)
    80004fe4:	8ff9                	and	a5,a5,a4
    80004fe6:	fbad                	bnez	a5,80004f58 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fe8:	e1c42503          	lw	a0,-484(s0)
    80004fec:	00000097          	auipc	ra,0x0
    80004ff0:	c58080e7          	jalr	-936(ra) # 80004c44 <flags2perm>
    80004ff4:	86aa                	mv	a3,a0
    80004ff6:	8626                	mv	a2,s1
    80004ff8:	85ca                	mv	a1,s2
    80004ffa:	855a                	mv	a0,s6
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	4c4080e7          	jalr	1220(ra) # 800014c0 <uvmalloc>
    80005004:	dea43c23          	sd	a0,-520(s0)
    80005008:	d939                	beqz	a0,80004f5e <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000500a:	e2843c03          	ld	s8,-472(s0)
    8000500e:	e2042c83          	lw	s9,-480(s0)
    80005012:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005016:	f60b83e3          	beqz	s7,80004f7c <exec+0x31c>
    8000501a:	89de                	mv	s3,s7
    8000501c:	4481                	li	s1,0
    8000501e:	bb95                	j	80004d92 <exec+0x132>

0000000080005020 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005020:	7179                	addi	sp,sp,-48
    80005022:	f406                	sd	ra,40(sp)
    80005024:	f022                	sd	s0,32(sp)
    80005026:	ec26                	sd	s1,24(sp)
    80005028:	e84a                	sd	s2,16(sp)
    8000502a:	1800                	addi	s0,sp,48
    8000502c:	892e                	mv	s2,a1
    8000502e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005030:	fdc40593          	addi	a1,s0,-36
    80005034:	ffffe097          	auipc	ra,0xffffe
    80005038:	b3c080e7          	jalr	-1220(ra) # 80002b70 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000503c:	fdc42703          	lw	a4,-36(s0)
    80005040:	47bd                	li	a5,15
    80005042:	02e7eb63          	bltu	a5,a4,80005078 <argfd+0x58>
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	a16080e7          	jalr	-1514(ra) # 80001a5c <myproc>
    8000504e:	fdc42703          	lw	a4,-36(s0)
    80005052:	01a70793          	addi	a5,a4,26
    80005056:	078e                	slli	a5,a5,0x3
    80005058:	953e                	add	a0,a0,a5
    8000505a:	611c                	ld	a5,0(a0)
    8000505c:	c385                	beqz	a5,8000507c <argfd+0x5c>
    return -1;
  if(pfd)
    8000505e:	00090463          	beqz	s2,80005066 <argfd+0x46>
    *pfd = fd;
    80005062:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005066:	4501                	li	a0,0
  if(pf)
    80005068:	c091                	beqz	s1,8000506c <argfd+0x4c>
    *pf = f;
    8000506a:	e09c                	sd	a5,0(s1)
}
    8000506c:	70a2                	ld	ra,40(sp)
    8000506e:	7402                	ld	s0,32(sp)
    80005070:	64e2                	ld	s1,24(sp)
    80005072:	6942                	ld	s2,16(sp)
    80005074:	6145                	addi	sp,sp,48
    80005076:	8082                	ret
    return -1;
    80005078:	557d                	li	a0,-1
    8000507a:	bfcd                	j	8000506c <argfd+0x4c>
    8000507c:	557d                	li	a0,-1
    8000507e:	b7fd                	j	8000506c <argfd+0x4c>

0000000080005080 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005080:	1101                	addi	sp,sp,-32
    80005082:	ec06                	sd	ra,24(sp)
    80005084:	e822                	sd	s0,16(sp)
    80005086:	e426                	sd	s1,8(sp)
    80005088:	1000                	addi	s0,sp,32
    8000508a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	9d0080e7          	jalr	-1584(ra) # 80001a5c <myproc>
    80005094:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005096:	0d050793          	addi	a5,a0,208
    8000509a:	4501                	li	a0,0
    8000509c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000509e:	6398                	ld	a4,0(a5)
    800050a0:	cb19                	beqz	a4,800050b6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050a2:	2505                	addiw	a0,a0,1
    800050a4:	07a1                	addi	a5,a5,8
    800050a6:	fed51ce3          	bne	a0,a3,8000509e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050aa:	557d                	li	a0,-1
}
    800050ac:	60e2                	ld	ra,24(sp)
    800050ae:	6442                	ld	s0,16(sp)
    800050b0:	64a2                	ld	s1,8(sp)
    800050b2:	6105                	addi	sp,sp,32
    800050b4:	8082                	ret
      p->ofile[fd] = f;
    800050b6:	01a50793          	addi	a5,a0,26
    800050ba:	078e                	slli	a5,a5,0x3
    800050bc:	963e                	add	a2,a2,a5
    800050be:	e204                	sd	s1,0(a2)
      return fd;
    800050c0:	b7f5                	j	800050ac <fdalloc+0x2c>

00000000800050c2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050c2:	715d                	addi	sp,sp,-80
    800050c4:	e486                	sd	ra,72(sp)
    800050c6:	e0a2                	sd	s0,64(sp)
    800050c8:	fc26                	sd	s1,56(sp)
    800050ca:	f84a                	sd	s2,48(sp)
    800050cc:	f44e                	sd	s3,40(sp)
    800050ce:	f052                	sd	s4,32(sp)
    800050d0:	ec56                	sd	s5,24(sp)
    800050d2:	e85a                	sd	s6,16(sp)
    800050d4:	0880                	addi	s0,sp,80
    800050d6:	8b2e                	mv	s6,a1
    800050d8:	89b2                	mv	s3,a2
    800050da:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050dc:	fb040593          	addi	a1,s0,-80
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	e3c080e7          	jalr	-452(ra) # 80003f1c <nameiparent>
    800050e8:	84aa                	mv	s1,a0
    800050ea:	14050f63          	beqz	a0,80005248 <create+0x186>
    return 0;

  ilock(dp);
    800050ee:	ffffe097          	auipc	ra,0xffffe
    800050f2:	66a080e7          	jalr	1642(ra) # 80003758 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050f6:	4601                	li	a2,0
    800050f8:	fb040593          	addi	a1,s0,-80
    800050fc:	8526                	mv	a0,s1
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	b3e080e7          	jalr	-1218(ra) # 80003c3c <dirlookup>
    80005106:	8aaa                	mv	s5,a0
    80005108:	c931                	beqz	a0,8000515c <create+0x9a>
    iunlockput(dp);
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	8ae080e7          	jalr	-1874(ra) # 800039ba <iunlockput>
    ilock(ip);
    80005114:	8556                	mv	a0,s5
    80005116:	ffffe097          	auipc	ra,0xffffe
    8000511a:	642080e7          	jalr	1602(ra) # 80003758 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000511e:	000b059b          	sext.w	a1,s6
    80005122:	4789                	li	a5,2
    80005124:	02f59563          	bne	a1,a5,8000514e <create+0x8c>
    80005128:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2b4>
    8000512c:	37f9                	addiw	a5,a5,-2
    8000512e:	17c2                	slli	a5,a5,0x30
    80005130:	93c1                	srli	a5,a5,0x30
    80005132:	4705                	li	a4,1
    80005134:	00f76d63          	bltu	a4,a5,8000514e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005138:	8556                	mv	a0,s5
    8000513a:	60a6                	ld	ra,72(sp)
    8000513c:	6406                	ld	s0,64(sp)
    8000513e:	74e2                	ld	s1,56(sp)
    80005140:	7942                	ld	s2,48(sp)
    80005142:	79a2                	ld	s3,40(sp)
    80005144:	7a02                	ld	s4,32(sp)
    80005146:	6ae2                	ld	s5,24(sp)
    80005148:	6b42                	ld	s6,16(sp)
    8000514a:	6161                	addi	sp,sp,80
    8000514c:	8082                	ret
    iunlockput(ip);
    8000514e:	8556                	mv	a0,s5
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	86a080e7          	jalr	-1942(ra) # 800039ba <iunlockput>
    return 0;
    80005158:	4a81                	li	s5,0
    8000515a:	bff9                	j	80005138 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000515c:	85da                	mv	a1,s6
    8000515e:	4088                	lw	a0,0(s1)
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	45c080e7          	jalr	1116(ra) # 800035bc <ialloc>
    80005168:	8a2a                	mv	s4,a0
    8000516a:	c539                	beqz	a0,800051b8 <create+0xf6>
  ilock(ip);
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	5ec080e7          	jalr	1516(ra) # 80003758 <ilock>
  ip->major = major;
    80005174:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005178:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000517c:	4905                	li	s2,1
    8000517e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005182:	8552                	mv	a0,s4
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	50a080e7          	jalr	1290(ra) # 8000368e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000518c:	000b059b          	sext.w	a1,s6
    80005190:	03258b63          	beq	a1,s2,800051c6 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005194:	004a2603          	lw	a2,4(s4)
    80005198:	fb040593          	addi	a1,s0,-80
    8000519c:	8526                	mv	a0,s1
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	cae080e7          	jalr	-850(ra) # 80003e4c <dirlink>
    800051a6:	06054f63          	bltz	a0,80005224 <create+0x162>
  iunlockput(dp);
    800051aa:	8526                	mv	a0,s1
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	80e080e7          	jalr	-2034(ra) # 800039ba <iunlockput>
  return ip;
    800051b4:	8ad2                	mv	s5,s4
    800051b6:	b749                	j	80005138 <create+0x76>
    iunlockput(dp);
    800051b8:	8526                	mv	a0,s1
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	800080e7          	jalr	-2048(ra) # 800039ba <iunlockput>
    return 0;
    800051c2:	8ad2                	mv	s5,s4
    800051c4:	bf95                	j	80005138 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c6:	004a2603          	lw	a2,4(s4)
    800051ca:	00003597          	auipc	a1,0x3
    800051ce:	55658593          	addi	a1,a1,1366 # 80008720 <syscalls+0x2a8>
    800051d2:	8552                	mv	a0,s4
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	c78080e7          	jalr	-904(ra) # 80003e4c <dirlink>
    800051dc:	04054463          	bltz	a0,80005224 <create+0x162>
    800051e0:	40d0                	lw	a2,4(s1)
    800051e2:	00003597          	auipc	a1,0x3
    800051e6:	54658593          	addi	a1,a1,1350 # 80008728 <syscalls+0x2b0>
    800051ea:	8552                	mv	a0,s4
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	c60080e7          	jalr	-928(ra) # 80003e4c <dirlink>
    800051f4:	02054863          	bltz	a0,80005224 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800051f8:	004a2603          	lw	a2,4(s4)
    800051fc:	fb040593          	addi	a1,s0,-80
    80005200:	8526                	mv	a0,s1
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	c4a080e7          	jalr	-950(ra) # 80003e4c <dirlink>
    8000520a:	00054d63          	bltz	a0,80005224 <create+0x162>
    dp->nlink++;  // for ".."
    8000520e:	04a4d783          	lhu	a5,74(s1)
    80005212:	2785                	addiw	a5,a5,1
    80005214:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	474080e7          	jalr	1140(ra) # 8000368e <iupdate>
    80005222:	b761                	j	800051aa <create+0xe8>
  ip->nlink = 0;
    80005224:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005228:	8552                	mv	a0,s4
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	464080e7          	jalr	1124(ra) # 8000368e <iupdate>
  iunlockput(ip);
    80005232:	8552                	mv	a0,s4
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	786080e7          	jalr	1926(ra) # 800039ba <iunlockput>
  iunlockput(dp);
    8000523c:	8526                	mv	a0,s1
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	77c080e7          	jalr	1916(ra) # 800039ba <iunlockput>
  return 0;
    80005246:	bdcd                	j	80005138 <create+0x76>
    return 0;
    80005248:	8aaa                	mv	s5,a0
    8000524a:	b5fd                	j	80005138 <create+0x76>

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
    80005262:	dc2080e7          	jalr	-574(ra) # 80005020 <argfd>
    return -1;
    80005266:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005268:	02054363          	bltz	a0,8000528e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000526c:	fd843503          	ld	a0,-40(s0)
    80005270:	00000097          	auipc	ra,0x0
    80005274:	e10080e7          	jalr	-496(ra) # 80005080 <fdalloc>
    80005278:	84aa                	mv	s1,a0
    return -1;
    8000527a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000527c:	00054963          	bltz	a0,8000528e <sys_dup+0x42>
  filedup(f);
    80005280:	fd843503          	ld	a0,-40(s0)
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	310080e7          	jalr	784(ra) # 80004594 <filedup>
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
  argaddr(1, &p);
    800052a2:	fd840593          	addi	a1,s0,-40
    800052a6:	4505                	li	a0,1
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	8e8080e7          	jalr	-1816(ra) # 80002b90 <argaddr>
  argint(2, &n);
    800052b0:	fe440593          	addi	a1,s0,-28
    800052b4:	4509                	li	a0,2
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	8ba080e7          	jalr	-1862(ra) # 80002b70 <argint>
  if(argfd(0, 0, &f) < 0)
    800052be:	fe840613          	addi	a2,s0,-24
    800052c2:	4581                	li	a1,0
    800052c4:	4501                	li	a0,0
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	d5a080e7          	jalr	-678(ra) # 80005020 <argfd>
    800052ce:	87aa                	mv	a5,a0
    return -1;
    800052d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052d2:	0007cc63          	bltz	a5,800052ea <sys_read+0x50>
  return fileread(f, p, n);
    800052d6:	fe442603          	lw	a2,-28(s0)
    800052da:	fd843583          	ld	a1,-40(s0)
    800052de:	fe843503          	ld	a0,-24(s0)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	43e080e7          	jalr	1086(ra) # 80004720 <fileread>
}
    800052ea:	70a2                	ld	ra,40(sp)
    800052ec:	7402                	ld	s0,32(sp)
    800052ee:	6145                	addi	sp,sp,48
    800052f0:	8082                	ret

00000000800052f2 <sys_write>:
{
    800052f2:	7179                	addi	sp,sp,-48
    800052f4:	f406                	sd	ra,40(sp)
    800052f6:	f022                	sd	s0,32(sp)
    800052f8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052fa:	fd840593          	addi	a1,s0,-40
    800052fe:	4505                	li	a0,1
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	890080e7          	jalr	-1904(ra) # 80002b90 <argaddr>
  argint(2, &n);
    80005308:	fe440593          	addi	a1,s0,-28
    8000530c:	4509                	li	a0,2
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	862080e7          	jalr	-1950(ra) # 80002b70 <argint>
  if(argfd(0, 0, &f) < 0)
    80005316:	fe840613          	addi	a2,s0,-24
    8000531a:	4581                	li	a1,0
    8000531c:	4501                	li	a0,0
    8000531e:	00000097          	auipc	ra,0x0
    80005322:	d02080e7          	jalr	-766(ra) # 80005020 <argfd>
    80005326:	87aa                	mv	a5,a0
    return -1;
    80005328:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000532a:	0007cc63          	bltz	a5,80005342 <sys_write+0x50>
  return filewrite(f, p, n);
    8000532e:	fe442603          	lw	a2,-28(s0)
    80005332:	fd843583          	ld	a1,-40(s0)
    80005336:	fe843503          	ld	a0,-24(s0)
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	4a8080e7          	jalr	1192(ra) # 800047e2 <filewrite>
}
    80005342:	70a2                	ld	ra,40(sp)
    80005344:	7402                	ld	s0,32(sp)
    80005346:	6145                	addi	sp,sp,48
    80005348:	8082                	ret

000000008000534a <sys_close>:
{
    8000534a:	1101                	addi	sp,sp,-32
    8000534c:	ec06                	sd	ra,24(sp)
    8000534e:	e822                	sd	s0,16(sp)
    80005350:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005352:	fe040613          	addi	a2,s0,-32
    80005356:	fec40593          	addi	a1,s0,-20
    8000535a:	4501                	li	a0,0
    8000535c:	00000097          	auipc	ra,0x0
    80005360:	cc4080e7          	jalr	-828(ra) # 80005020 <argfd>
    return -1;
    80005364:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005366:	02054463          	bltz	a0,8000538e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	6f2080e7          	jalr	1778(ra) # 80001a5c <myproc>
    80005372:	fec42783          	lw	a5,-20(s0)
    80005376:	07e9                	addi	a5,a5,26
    80005378:	078e                	slli	a5,a5,0x3
    8000537a:	97aa                	add	a5,a5,a0
    8000537c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005380:	fe043503          	ld	a0,-32(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	262080e7          	jalr	610(ra) # 800045e6 <fileclose>
  return 0;
    8000538c:	4781                	li	a5,0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	60e2                	ld	ra,24(sp)
    80005392:	6442                	ld	s0,16(sp)
    80005394:	6105                	addi	sp,sp,32
    80005396:	8082                	ret

0000000080005398 <sys_fstat>:
{
    80005398:	1101                	addi	sp,sp,-32
    8000539a:	ec06                	sd	ra,24(sp)
    8000539c:	e822                	sd	s0,16(sp)
    8000539e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053a0:	fe040593          	addi	a1,s0,-32
    800053a4:	4505                	li	a0,1
    800053a6:	ffffd097          	auipc	ra,0xffffd
    800053aa:	7ea080e7          	jalr	2026(ra) # 80002b90 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053ae:	fe840613          	addi	a2,s0,-24
    800053b2:	4581                	li	a1,0
    800053b4:	4501                	li	a0,0
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	c6a080e7          	jalr	-918(ra) # 80005020 <argfd>
    800053be:	87aa                	mv	a5,a0
    return -1;
    800053c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053c2:	0007ca63          	bltz	a5,800053d6 <sys_fstat+0x3e>
  return filestat(f, st);
    800053c6:	fe043583          	ld	a1,-32(s0)
    800053ca:	fe843503          	ld	a0,-24(s0)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	2e0080e7          	jalr	736(ra) # 800046ae <filestat>
}
    800053d6:	60e2                	ld	ra,24(sp)
    800053d8:	6442                	ld	s0,16(sp)
    800053da:	6105                	addi	sp,sp,32
    800053dc:	8082                	ret

00000000800053de <sys_link>:
{
    800053de:	7169                	addi	sp,sp,-304
    800053e0:	f606                	sd	ra,296(sp)
    800053e2:	f222                	sd	s0,288(sp)
    800053e4:	ee26                	sd	s1,280(sp)
    800053e6:	ea4a                	sd	s2,272(sp)
    800053e8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ea:	08000613          	li	a2,128
    800053ee:	ed040593          	addi	a1,s0,-304
    800053f2:	4501                	li	a0,0
    800053f4:	ffffd097          	auipc	ra,0xffffd
    800053f8:	7bc080e7          	jalr	1980(ra) # 80002bb0 <argstr>
    return -1;
    800053fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053fe:	10054e63          	bltz	a0,8000551a <sys_link+0x13c>
    80005402:	08000613          	li	a2,128
    80005406:	f5040593          	addi	a1,s0,-176
    8000540a:	4505                	li	a0,1
    8000540c:	ffffd097          	auipc	ra,0xffffd
    80005410:	7a4080e7          	jalr	1956(ra) # 80002bb0 <argstr>
    return -1;
    80005414:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005416:	10054263          	bltz	a0,8000551a <sys_link+0x13c>
  begin_op();
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	d00080e7          	jalr	-768(ra) # 8000411a <begin_op>
  if((ip = namei(old)) == 0){
    80005422:	ed040513          	addi	a0,s0,-304
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	ad8080e7          	jalr	-1320(ra) # 80003efe <namei>
    8000542e:	84aa                	mv	s1,a0
    80005430:	c551                	beqz	a0,800054bc <sys_link+0xde>
  ilock(ip);
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	326080e7          	jalr	806(ra) # 80003758 <ilock>
  if(ip->type == T_DIR){
    8000543a:	04449703          	lh	a4,68(s1)
    8000543e:	4785                	li	a5,1
    80005440:	08f70463          	beq	a4,a5,800054c8 <sys_link+0xea>
  ip->nlink++;
    80005444:	04a4d783          	lhu	a5,74(s1)
    80005448:	2785                	addiw	a5,a5,1
    8000544a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000544e:	8526                	mv	a0,s1
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	23e080e7          	jalr	574(ra) # 8000368e <iupdate>
  iunlock(ip);
    80005458:	8526                	mv	a0,s1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	3c0080e7          	jalr	960(ra) # 8000381a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005462:	fd040593          	addi	a1,s0,-48
    80005466:	f5040513          	addi	a0,s0,-176
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	ab2080e7          	jalr	-1358(ra) # 80003f1c <nameiparent>
    80005472:	892a                	mv	s2,a0
    80005474:	c935                	beqz	a0,800054e8 <sys_link+0x10a>
  ilock(dp);
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	2e2080e7          	jalr	738(ra) # 80003758 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000547e:	00092703          	lw	a4,0(s2)
    80005482:	409c                	lw	a5,0(s1)
    80005484:	04f71d63          	bne	a4,a5,800054de <sys_link+0x100>
    80005488:	40d0                	lw	a2,4(s1)
    8000548a:	fd040593          	addi	a1,s0,-48
    8000548e:	854a                	mv	a0,s2
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	9bc080e7          	jalr	-1604(ra) # 80003e4c <dirlink>
    80005498:	04054363          	bltz	a0,800054de <sys_link+0x100>
  iunlockput(dp);
    8000549c:	854a                	mv	a0,s2
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	51c080e7          	jalr	1308(ra) # 800039ba <iunlockput>
  iput(ip);
    800054a6:	8526                	mv	a0,s1
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	46a080e7          	jalr	1130(ra) # 80003912 <iput>
  end_op();
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	cea080e7          	jalr	-790(ra) # 8000419a <end_op>
  return 0;
    800054b8:	4781                	li	a5,0
    800054ba:	a085                	j	8000551a <sys_link+0x13c>
    end_op();
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	cde080e7          	jalr	-802(ra) # 8000419a <end_op>
    return -1;
    800054c4:	57fd                	li	a5,-1
    800054c6:	a891                	j	8000551a <sys_link+0x13c>
    iunlockput(ip);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	4f0080e7          	jalr	1264(ra) # 800039ba <iunlockput>
    end_op();
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	cc8080e7          	jalr	-824(ra) # 8000419a <end_op>
    return -1;
    800054da:	57fd                	li	a5,-1
    800054dc:	a83d                	j	8000551a <sys_link+0x13c>
    iunlockput(dp);
    800054de:	854a                	mv	a0,s2
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	4da080e7          	jalr	1242(ra) # 800039ba <iunlockput>
  ilock(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	26e080e7          	jalr	622(ra) # 80003758 <ilock>
  ip->nlink--;
    800054f2:	04a4d783          	lhu	a5,74(s1)
    800054f6:	37fd                	addiw	a5,a5,-1
    800054f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	190080e7          	jalr	400(ra) # 8000368e <iupdate>
  iunlockput(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	4b2080e7          	jalr	1202(ra) # 800039ba <iunlockput>
  end_op();
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	c8a080e7          	jalr	-886(ra) # 8000419a <end_op>
  return -1;
    80005518:	57fd                	li	a5,-1
}
    8000551a:	853e                	mv	a0,a5
    8000551c:	70b2                	ld	ra,296(sp)
    8000551e:	7412                	ld	s0,288(sp)
    80005520:	64f2                	ld	s1,280(sp)
    80005522:	6952                	ld	s2,272(sp)
    80005524:	6155                	addi	sp,sp,304
    80005526:	8082                	ret

0000000080005528 <sys_unlink>:
{
    80005528:	7151                	addi	sp,sp,-240
    8000552a:	f586                	sd	ra,232(sp)
    8000552c:	f1a2                	sd	s0,224(sp)
    8000552e:	eda6                	sd	s1,216(sp)
    80005530:	e9ca                	sd	s2,208(sp)
    80005532:	e5ce                	sd	s3,200(sp)
    80005534:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005536:	08000613          	li	a2,128
    8000553a:	f3040593          	addi	a1,s0,-208
    8000553e:	4501                	li	a0,0
    80005540:	ffffd097          	auipc	ra,0xffffd
    80005544:	670080e7          	jalr	1648(ra) # 80002bb0 <argstr>
    80005548:	18054163          	bltz	a0,800056ca <sys_unlink+0x1a2>
  begin_op();
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	bce080e7          	jalr	-1074(ra) # 8000411a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005554:	fb040593          	addi	a1,s0,-80
    80005558:	f3040513          	addi	a0,s0,-208
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	9c0080e7          	jalr	-1600(ra) # 80003f1c <nameiparent>
    80005564:	84aa                	mv	s1,a0
    80005566:	c979                	beqz	a0,8000563c <sys_unlink+0x114>
  ilock(dp);
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	1f0080e7          	jalr	496(ra) # 80003758 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005570:	00003597          	auipc	a1,0x3
    80005574:	1b058593          	addi	a1,a1,432 # 80008720 <syscalls+0x2a8>
    80005578:	fb040513          	addi	a0,s0,-80
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	6a6080e7          	jalr	1702(ra) # 80003c22 <namecmp>
    80005584:	14050a63          	beqz	a0,800056d8 <sys_unlink+0x1b0>
    80005588:	00003597          	auipc	a1,0x3
    8000558c:	1a058593          	addi	a1,a1,416 # 80008728 <syscalls+0x2b0>
    80005590:	fb040513          	addi	a0,s0,-80
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	68e080e7          	jalr	1678(ra) # 80003c22 <namecmp>
    8000559c:	12050e63          	beqz	a0,800056d8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a0:	f2c40613          	addi	a2,s0,-212
    800055a4:	fb040593          	addi	a1,s0,-80
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	692080e7          	jalr	1682(ra) # 80003c3c <dirlookup>
    800055b2:	892a                	mv	s2,a0
    800055b4:	12050263          	beqz	a0,800056d8 <sys_unlink+0x1b0>
  ilock(ip);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	1a0080e7          	jalr	416(ra) # 80003758 <ilock>
  if(ip->nlink < 1)
    800055c0:	04a91783          	lh	a5,74(s2)
    800055c4:	08f05263          	blez	a5,80005648 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055c8:	04491703          	lh	a4,68(s2)
    800055cc:	4785                	li	a5,1
    800055ce:	08f70563          	beq	a4,a5,80005658 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d2:	4641                	li	a2,16
    800055d4:	4581                	li	a1,0
    800055d6:	fc040513          	addi	a0,s0,-64
    800055da:	ffffb097          	auipc	ra,0xffffb
    800055de:	794080e7          	jalr	1940(ra) # 80000d6e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e2:	4741                	li	a4,16
    800055e4:	f2c42683          	lw	a3,-212(s0)
    800055e8:	fc040613          	addi	a2,s0,-64
    800055ec:	4581                	li	a1,0
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	514080e7          	jalr	1300(ra) # 80003b04 <writei>
    800055f8:	47c1                	li	a5,16
    800055fa:	0af51563          	bne	a0,a5,800056a4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055fe:	04491703          	lh	a4,68(s2)
    80005602:	4785                	li	a5,1
    80005604:	0af70863          	beq	a4,a5,800056b4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	3b0080e7          	jalr	944(ra) # 800039ba <iunlockput>
  ip->nlink--;
    80005612:	04a95783          	lhu	a5,74(s2)
    80005616:	37fd                	addiw	a5,a5,-1
    80005618:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000561c:	854a                	mv	a0,s2
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	070080e7          	jalr	112(ra) # 8000368e <iupdate>
  iunlockput(ip);
    80005626:	854a                	mv	a0,s2
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	392080e7          	jalr	914(ra) # 800039ba <iunlockput>
  end_op();
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	b6a080e7          	jalr	-1174(ra) # 8000419a <end_op>
  return 0;
    80005638:	4501                	li	a0,0
    8000563a:	a84d                	j	800056ec <sys_unlink+0x1c4>
    end_op();
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	b5e080e7          	jalr	-1186(ra) # 8000419a <end_op>
    return -1;
    80005644:	557d                	li	a0,-1
    80005646:	a05d                	j	800056ec <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005648:	00003517          	auipc	a0,0x3
    8000564c:	0e850513          	addi	a0,a0,232 # 80008730 <syscalls+0x2b8>
    80005650:	ffffb097          	auipc	ra,0xffffb
    80005654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005658:	04c92703          	lw	a4,76(s2)
    8000565c:	02000793          	li	a5,32
    80005660:	f6e7f9e3          	bgeu	a5,a4,800055d2 <sys_unlink+0xaa>
    80005664:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005668:	4741                	li	a4,16
    8000566a:	86ce                	mv	a3,s3
    8000566c:	f1840613          	addi	a2,s0,-232
    80005670:	4581                	li	a1,0
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	398080e7          	jalr	920(ra) # 80003a0c <readi>
    8000567c:	47c1                	li	a5,16
    8000567e:	00f51b63          	bne	a0,a5,80005694 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005682:	f1845783          	lhu	a5,-232(s0)
    80005686:	e7a1                	bnez	a5,800056ce <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005688:	29c1                	addiw	s3,s3,16
    8000568a:	04c92783          	lw	a5,76(s2)
    8000568e:	fcf9ede3          	bltu	s3,a5,80005668 <sys_unlink+0x140>
    80005692:	b781                	j	800055d2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005694:	00003517          	auipc	a0,0x3
    80005698:	0b450513          	addi	a0,a0,180 # 80008748 <syscalls+0x2d0>
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056a4:	00003517          	auipc	a0,0x3
    800056a8:	0bc50513          	addi	a0,a0,188 # 80008760 <syscalls+0x2e8>
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	e92080e7          	jalr	-366(ra) # 8000053e <panic>
    dp->nlink--;
    800056b4:	04a4d783          	lhu	a5,74(s1)
    800056b8:	37fd                	addiw	a5,a5,-1
    800056ba:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	fce080e7          	jalr	-50(ra) # 8000368e <iupdate>
    800056c8:	b781                	j	80005608 <sys_unlink+0xe0>
    return -1;
    800056ca:	557d                	li	a0,-1
    800056cc:	a005                	j	800056ec <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	2ea080e7          	jalr	746(ra) # 800039ba <iunlockput>
  iunlockput(dp);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	2e0080e7          	jalr	736(ra) # 800039ba <iunlockput>
  end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	ab8080e7          	jalr	-1352(ra) # 8000419a <end_op>
  return -1;
    800056ea:	557d                	li	a0,-1
}
    800056ec:	70ae                	ld	ra,232(sp)
    800056ee:	740e                	ld	s0,224(sp)
    800056f0:	64ee                	ld	s1,216(sp)
    800056f2:	694e                	ld	s2,208(sp)
    800056f4:	69ae                	ld	s3,200(sp)
    800056f6:	616d                	addi	sp,sp,240
    800056f8:	8082                	ret

00000000800056fa <sys_open>:

uint64
sys_open(void)
{
    800056fa:	7131                	addi	sp,sp,-192
    800056fc:	fd06                	sd	ra,184(sp)
    800056fe:	f922                	sd	s0,176(sp)
    80005700:	f526                	sd	s1,168(sp)
    80005702:	f14a                	sd	s2,160(sp)
    80005704:	ed4e                	sd	s3,152(sp)
    80005706:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005708:	f4c40593          	addi	a1,s0,-180
    8000570c:	4505                	li	a0,1
    8000570e:	ffffd097          	auipc	ra,0xffffd
    80005712:	462080e7          	jalr	1122(ra) # 80002b70 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005716:	08000613          	li	a2,128
    8000571a:	f5040593          	addi	a1,s0,-176
    8000571e:	4501                	li	a0,0
    80005720:	ffffd097          	auipc	ra,0xffffd
    80005724:	490080e7          	jalr	1168(ra) # 80002bb0 <argstr>
    80005728:	87aa                	mv	a5,a0
    return -1;
    8000572a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000572c:	0a07c963          	bltz	a5,800057de <sys_open+0xe4>

  begin_op();
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	9ea080e7          	jalr	-1558(ra) # 8000411a <begin_op>

  if(omode & O_CREATE){
    80005738:	f4c42783          	lw	a5,-180(s0)
    8000573c:	2007f793          	andi	a5,a5,512
    80005740:	cfc5                	beqz	a5,800057f8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005742:	4681                	li	a3,0
    80005744:	4601                	li	a2,0
    80005746:	4589                	li	a1,2
    80005748:	f5040513          	addi	a0,s0,-176
    8000574c:	00000097          	auipc	ra,0x0
    80005750:	976080e7          	jalr	-1674(ra) # 800050c2 <create>
    80005754:	84aa                	mv	s1,a0
    if(ip == 0){
    80005756:	c959                	beqz	a0,800057ec <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005758:	04449703          	lh	a4,68(s1)
    8000575c:	478d                	li	a5,3
    8000575e:	00f71763          	bne	a4,a5,8000576c <sys_open+0x72>
    80005762:	0464d703          	lhu	a4,70(s1)
    80005766:	47a5                	li	a5,9
    80005768:	0ce7ed63          	bltu	a5,a4,80005842 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	dbe080e7          	jalr	-578(ra) # 8000452a <filealloc>
    80005774:	89aa                	mv	s3,a0
    80005776:	10050363          	beqz	a0,8000587c <sys_open+0x182>
    8000577a:	00000097          	auipc	ra,0x0
    8000577e:	906080e7          	jalr	-1786(ra) # 80005080 <fdalloc>
    80005782:	892a                	mv	s2,a0
    80005784:	0e054763          	bltz	a0,80005872 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005788:	04449703          	lh	a4,68(s1)
    8000578c:	478d                	li	a5,3
    8000578e:	0cf70563          	beq	a4,a5,80005858 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005792:	4789                	li	a5,2
    80005794:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005798:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000579c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057a0:	f4c42783          	lw	a5,-180(s0)
    800057a4:	0017c713          	xori	a4,a5,1
    800057a8:	8b05                	andi	a4,a4,1
    800057aa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ae:	0037f713          	andi	a4,a5,3
    800057b2:	00e03733          	snez	a4,a4
    800057b6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ba:	4007f793          	andi	a5,a5,1024
    800057be:	c791                	beqz	a5,800057ca <sys_open+0xd0>
    800057c0:	04449703          	lh	a4,68(s1)
    800057c4:	4789                	li	a5,2
    800057c6:	0af70063          	beq	a4,a5,80005866 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	04e080e7          	jalr	78(ra) # 8000381a <iunlock>
  end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	9c6080e7          	jalr	-1594(ra) # 8000419a <end_op>

  return fd;
    800057dc:	854a                	mv	a0,s2
}
    800057de:	70ea                	ld	ra,184(sp)
    800057e0:	744a                	ld	s0,176(sp)
    800057e2:	74aa                	ld	s1,168(sp)
    800057e4:	790a                	ld	s2,160(sp)
    800057e6:	69ea                	ld	s3,152(sp)
    800057e8:	6129                	addi	sp,sp,192
    800057ea:	8082                	ret
      end_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	9ae080e7          	jalr	-1618(ra) # 8000419a <end_op>
      return -1;
    800057f4:	557d                	li	a0,-1
    800057f6:	b7e5                	j	800057de <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057f8:	f5040513          	addi	a0,s0,-176
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	702080e7          	jalr	1794(ra) # 80003efe <namei>
    80005804:	84aa                	mv	s1,a0
    80005806:	c905                	beqz	a0,80005836 <sys_open+0x13c>
    ilock(ip);
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	f50080e7          	jalr	-176(ra) # 80003758 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005810:	04449703          	lh	a4,68(s1)
    80005814:	4785                	li	a5,1
    80005816:	f4f711e3          	bne	a4,a5,80005758 <sys_open+0x5e>
    8000581a:	f4c42783          	lw	a5,-180(s0)
    8000581e:	d7b9                	beqz	a5,8000576c <sys_open+0x72>
      iunlockput(ip);
    80005820:	8526                	mv	a0,s1
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	198080e7          	jalr	408(ra) # 800039ba <iunlockput>
      end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	970080e7          	jalr	-1680(ra) # 8000419a <end_op>
      return -1;
    80005832:	557d                	li	a0,-1
    80005834:	b76d                	j	800057de <sys_open+0xe4>
      end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	964080e7          	jalr	-1692(ra) # 8000419a <end_op>
      return -1;
    8000583e:	557d                	li	a0,-1
    80005840:	bf79                	j	800057de <sys_open+0xe4>
    iunlockput(ip);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	176080e7          	jalr	374(ra) # 800039ba <iunlockput>
    end_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	94e080e7          	jalr	-1714(ra) # 8000419a <end_op>
    return -1;
    80005854:	557d                	li	a0,-1
    80005856:	b761                	j	800057de <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005858:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000585c:	04649783          	lh	a5,70(s1)
    80005860:	02f99223          	sh	a5,36(s3)
    80005864:	bf25                	j	8000579c <sys_open+0xa2>
    itrunc(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	ffe080e7          	jalr	-2(ra) # 80003866 <itrunc>
    80005870:	bfa9                	j	800057ca <sys_open+0xd0>
      fileclose(f);
    80005872:	854e                	mv	a0,s3
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	d72080e7          	jalr	-654(ra) # 800045e6 <fileclose>
    iunlockput(ip);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	13c080e7          	jalr	316(ra) # 800039ba <iunlockput>
    end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	914080e7          	jalr	-1772(ra) # 8000419a <end_op>
    return -1;
    8000588e:	557d                	li	a0,-1
    80005890:	b7b9                	j	800057de <sys_open+0xe4>

0000000080005892 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005892:	7175                	addi	sp,sp,-144
    80005894:	e506                	sd	ra,136(sp)
    80005896:	e122                	sd	s0,128(sp)
    80005898:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	880080e7          	jalr	-1920(ra) # 8000411a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a2:	08000613          	li	a2,128
    800058a6:	f7040593          	addi	a1,s0,-144
    800058aa:	4501                	li	a0,0
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	304080e7          	jalr	772(ra) # 80002bb0 <argstr>
    800058b4:	02054963          	bltz	a0,800058e6 <sys_mkdir+0x54>
    800058b8:	4681                	li	a3,0
    800058ba:	4601                	li	a2,0
    800058bc:	4585                	li	a1,1
    800058be:	f7040513          	addi	a0,s0,-144
    800058c2:	00000097          	auipc	ra,0x0
    800058c6:	800080e7          	jalr	-2048(ra) # 800050c2 <create>
    800058ca:	cd11                	beqz	a0,800058e6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	0ee080e7          	jalr	238(ra) # 800039ba <iunlockput>
  end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	8c6080e7          	jalr	-1850(ra) # 8000419a <end_op>
  return 0;
    800058dc:	4501                	li	a0,0
}
    800058de:	60aa                	ld	ra,136(sp)
    800058e0:	640a                	ld	s0,128(sp)
    800058e2:	6149                	addi	sp,sp,144
    800058e4:	8082                	ret
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	8b4080e7          	jalr	-1868(ra) # 8000419a <end_op>
    return -1;
    800058ee:	557d                	li	a0,-1
    800058f0:	b7fd                	j	800058de <sys_mkdir+0x4c>

00000000800058f2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f2:	7135                	addi	sp,sp,-160
    800058f4:	ed06                	sd	ra,152(sp)
    800058f6:	e922                	sd	s0,144(sp)
    800058f8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	820080e7          	jalr	-2016(ra) # 8000411a <begin_op>
  argint(1, &major);
    80005902:	f6c40593          	addi	a1,s0,-148
    80005906:	4505                	li	a0,1
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	268080e7          	jalr	616(ra) # 80002b70 <argint>
  argint(2, &minor);
    80005910:	f6840593          	addi	a1,s0,-152
    80005914:	4509                	li	a0,2
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	25a080e7          	jalr	602(ra) # 80002b70 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000591e:	08000613          	li	a2,128
    80005922:	f7040593          	addi	a1,s0,-144
    80005926:	4501                	li	a0,0
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	288080e7          	jalr	648(ra) # 80002bb0 <argstr>
    80005930:	02054b63          	bltz	a0,80005966 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005934:	f6841683          	lh	a3,-152(s0)
    80005938:	f6c41603          	lh	a2,-148(s0)
    8000593c:	458d                	li	a1,3
    8000593e:	f7040513          	addi	a0,s0,-144
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	780080e7          	jalr	1920(ra) # 800050c2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594a:	cd11                	beqz	a0,80005966 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	06e080e7          	jalr	110(ra) # 800039ba <iunlockput>
  end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	846080e7          	jalr	-1978(ra) # 8000419a <end_op>
  return 0;
    8000595c:	4501                	li	a0,0
}
    8000595e:	60ea                	ld	ra,152(sp)
    80005960:	644a                	ld	s0,144(sp)
    80005962:	610d                	addi	sp,sp,160
    80005964:	8082                	ret
    end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	834080e7          	jalr	-1996(ra) # 8000419a <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	b7fd                	j	8000595e <sys_mknod+0x6c>

0000000080005972 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005972:	7135                	addi	sp,sp,-160
    80005974:	ed06                	sd	ra,152(sp)
    80005976:	e922                	sd	s0,144(sp)
    80005978:	e526                	sd	s1,136(sp)
    8000597a:	e14a                	sd	s2,128(sp)
    8000597c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000597e:	ffffc097          	auipc	ra,0xffffc
    80005982:	0de080e7          	jalr	222(ra) # 80001a5c <myproc>
    80005986:	892a                	mv	s2,a0
  
  begin_op();
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	792080e7          	jalr	1938(ra) # 8000411a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005990:	08000613          	li	a2,128
    80005994:	f6040593          	addi	a1,s0,-160
    80005998:	4501                	li	a0,0
    8000599a:	ffffd097          	auipc	ra,0xffffd
    8000599e:	216080e7          	jalr	534(ra) # 80002bb0 <argstr>
    800059a2:	04054b63          	bltz	a0,800059f8 <sys_chdir+0x86>
    800059a6:	f6040513          	addi	a0,s0,-160
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	554080e7          	jalr	1364(ra) # 80003efe <namei>
    800059b2:	84aa                	mv	s1,a0
    800059b4:	c131                	beqz	a0,800059f8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	da2080e7          	jalr	-606(ra) # 80003758 <ilock>
  if(ip->type != T_DIR){
    800059be:	04449703          	lh	a4,68(s1)
    800059c2:	4785                	li	a5,1
    800059c4:	04f71063          	bne	a4,a5,80005a04 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	e50080e7          	jalr	-432(ra) # 8000381a <iunlock>
  iput(p->cwd);
    800059d2:	15093503          	ld	a0,336(s2)
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	f3c080e7          	jalr	-196(ra) # 80003912 <iput>
  end_op();
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	7bc080e7          	jalr	1980(ra) # 8000419a <end_op>
  p->cwd = ip;
    800059e6:	14993823          	sd	s1,336(s2)
  return 0;
    800059ea:	4501                	li	a0,0
}
    800059ec:	60ea                	ld	ra,152(sp)
    800059ee:	644a                	ld	s0,144(sp)
    800059f0:	64aa                	ld	s1,136(sp)
    800059f2:	690a                	ld	s2,128(sp)
    800059f4:	610d                	addi	sp,sp,160
    800059f6:	8082                	ret
    end_op();
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	7a2080e7          	jalr	1954(ra) # 8000419a <end_op>
    return -1;
    80005a00:	557d                	li	a0,-1
    80005a02:	b7ed                	j	800059ec <sys_chdir+0x7a>
    iunlockput(ip);
    80005a04:	8526                	mv	a0,s1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	fb4080e7          	jalr	-76(ra) # 800039ba <iunlockput>
    end_op();
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	78c080e7          	jalr	1932(ra) # 8000419a <end_op>
    return -1;
    80005a16:	557d                	li	a0,-1
    80005a18:	bfd1                	j	800059ec <sys_chdir+0x7a>

0000000080005a1a <sys_exec>:

uint64
sys_exec(void)
{
    80005a1a:	7145                	addi	sp,sp,-464
    80005a1c:	e786                	sd	ra,456(sp)
    80005a1e:	e3a2                	sd	s0,448(sp)
    80005a20:	ff26                	sd	s1,440(sp)
    80005a22:	fb4a                	sd	s2,432(sp)
    80005a24:	f74e                	sd	s3,424(sp)
    80005a26:	f352                	sd	s4,416(sp)
    80005a28:	ef56                	sd	s5,408(sp)
    80005a2a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a2c:	e3840593          	addi	a1,s0,-456
    80005a30:	4505                	li	a0,1
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	15e080e7          	jalr	350(ra) # 80002b90 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a3a:	08000613          	li	a2,128
    80005a3e:	f4040593          	addi	a1,s0,-192
    80005a42:	4501                	li	a0,0
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	16c080e7          	jalr	364(ra) # 80002bb0 <argstr>
    80005a4c:	87aa                	mv	a5,a0
    return -1;
    80005a4e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a50:	0c07c263          	bltz	a5,80005b14 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a54:	10000613          	li	a2,256
    80005a58:	4581                	li	a1,0
    80005a5a:	e4040513          	addi	a0,s0,-448
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	310080e7          	jalr	784(ra) # 80000d6e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a66:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a6a:	89a6                	mv	s3,s1
    80005a6c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a6e:	02000a13          	li	s4,32
    80005a72:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a76:	00391793          	slli	a5,s2,0x3
    80005a7a:	e3040593          	addi	a1,s0,-464
    80005a7e:	e3843503          	ld	a0,-456(s0)
    80005a82:	953e                	add	a0,a0,a5
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	04e080e7          	jalr	78(ra) # 80002ad2 <fetchaddr>
    80005a8c:	02054a63          	bltz	a0,80005ac0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a90:	e3043783          	ld	a5,-464(s0)
    80005a94:	c3b9                	beqz	a5,80005ada <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a96:	ffffb097          	auipc	ra,0xffffb
    80005a9a:	0ac080e7          	jalr	172(ra) # 80000b42 <kalloc>
    80005a9e:	85aa                	mv	a1,a0
    80005aa0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aa4:	cd11                	beqz	a0,80005ac0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aa6:	6605                	lui	a2,0x1
    80005aa8:	e3043503          	ld	a0,-464(s0)
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	078080e7          	jalr	120(ra) # 80002b24 <fetchstr>
    80005ab4:	00054663          	bltz	a0,80005ac0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ab8:	0905                	addi	s2,s2,1
    80005aba:	09a1                	addi	s3,s3,8
    80005abc:	fb491be3          	bne	s2,s4,80005a72 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac0:	10048913          	addi	s2,s1,256
    80005ac4:	6088                	ld	a0,0(s1)
    80005ac6:	c531                	beqz	a0,80005b12 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	f7e080e7          	jalr	-130(ra) # 80000a46 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad0:	04a1                	addi	s1,s1,8
    80005ad2:	ff2499e3          	bne	s1,s2,80005ac4 <sys_exec+0xaa>
  return -1;
    80005ad6:	557d                	li	a0,-1
    80005ad8:	a835                	j	80005b14 <sys_exec+0xfa>
      argv[i] = 0;
    80005ada:	0a8e                	slli	s5,s5,0x3
    80005adc:	fc040793          	addi	a5,s0,-64
    80005ae0:	9abe                	add	s5,s5,a5
    80005ae2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ae6:	e4040593          	addi	a1,s0,-448
    80005aea:	f4040513          	addi	a0,s0,-192
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	172080e7          	jalr	370(ra) # 80004c60 <exec>
    80005af6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af8:	10048993          	addi	s3,s1,256
    80005afc:	6088                	ld	a0,0(s1)
    80005afe:	c901                	beqz	a0,80005b0e <sys_exec+0xf4>
    kfree(argv[i]);
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	f46080e7          	jalr	-186(ra) # 80000a46 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b08:	04a1                	addi	s1,s1,8
    80005b0a:	ff3499e3          	bne	s1,s3,80005afc <sys_exec+0xe2>
  return ret;
    80005b0e:	854a                	mv	a0,s2
    80005b10:	a011                	j	80005b14 <sys_exec+0xfa>
  return -1;
    80005b12:	557d                	li	a0,-1
}
    80005b14:	60be                	ld	ra,456(sp)
    80005b16:	641e                	ld	s0,448(sp)
    80005b18:	74fa                	ld	s1,440(sp)
    80005b1a:	795a                	ld	s2,432(sp)
    80005b1c:	79ba                	ld	s3,424(sp)
    80005b1e:	7a1a                	ld	s4,416(sp)
    80005b20:	6afa                	ld	s5,408(sp)
    80005b22:	6179                	addi	sp,sp,464
    80005b24:	8082                	ret

0000000080005b26 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b26:	7139                	addi	sp,sp,-64
    80005b28:	fc06                	sd	ra,56(sp)
    80005b2a:	f822                	sd	s0,48(sp)
    80005b2c:	f426                	sd	s1,40(sp)
    80005b2e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	f2c080e7          	jalr	-212(ra) # 80001a5c <myproc>
    80005b38:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b3a:	fd840593          	addi	a1,s0,-40
    80005b3e:	4501                	li	a0,0
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	050080e7          	jalr	80(ra) # 80002b90 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b48:	fc840593          	addi	a1,s0,-56
    80005b4c:	fd040513          	addi	a0,s0,-48
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	dc6080e7          	jalr	-570(ra) # 80004916 <pipealloc>
    return -1;
    80005b58:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b5a:	0c054463          	bltz	a0,80005c22 <sys_pipe+0xfc>
  fd0 = -1;
    80005b5e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b62:	fd043503          	ld	a0,-48(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	51a080e7          	jalr	1306(ra) # 80005080 <fdalloc>
    80005b6e:	fca42223          	sw	a0,-60(s0)
    80005b72:	08054b63          	bltz	a0,80005c08 <sys_pipe+0xe2>
    80005b76:	fc843503          	ld	a0,-56(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	506080e7          	jalr	1286(ra) # 80005080 <fdalloc>
    80005b82:	fca42023          	sw	a0,-64(s0)
    80005b86:	06054863          	bltz	a0,80005bf6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b8a:	4691                	li	a3,4
    80005b8c:	fc440613          	addi	a2,s0,-60
    80005b90:	fd843583          	ld	a1,-40(s0)
    80005b94:	68a8                	ld	a0,80(s1)
    80005b96:	ffffc097          	auipc	ra,0xffffc
    80005b9a:	b82080e7          	jalr	-1150(ra) # 80001718 <copyout>
    80005b9e:	02054063          	bltz	a0,80005bbe <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba2:	4691                	li	a3,4
    80005ba4:	fc040613          	addi	a2,s0,-64
    80005ba8:	fd843583          	ld	a1,-40(s0)
    80005bac:	0591                	addi	a1,a1,4
    80005bae:	68a8                	ld	a0,80(s1)
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	b68080e7          	jalr	-1176(ra) # 80001718 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bba:	06055463          	bgez	a0,80005c22 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bbe:	fc442783          	lw	a5,-60(s0)
    80005bc2:	07e9                	addi	a5,a5,26
    80005bc4:	078e                	slli	a5,a5,0x3
    80005bc6:	97a6                	add	a5,a5,s1
    80005bc8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bcc:	fc042503          	lw	a0,-64(s0)
    80005bd0:	0569                	addi	a0,a0,26
    80005bd2:	050e                	slli	a0,a0,0x3
    80005bd4:	94aa                	add	s1,s1,a0
    80005bd6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bda:	fd043503          	ld	a0,-48(s0)
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	a08080e7          	jalr	-1528(ra) # 800045e6 <fileclose>
    fileclose(wf);
    80005be6:	fc843503          	ld	a0,-56(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	9fc080e7          	jalr	-1540(ra) # 800045e6 <fileclose>
    return -1;
    80005bf2:	57fd                	li	a5,-1
    80005bf4:	a03d                	j	80005c22 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bf6:	fc442783          	lw	a5,-60(s0)
    80005bfa:	0007c763          	bltz	a5,80005c08 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bfe:	07e9                	addi	a5,a5,26
    80005c00:	078e                	slli	a5,a5,0x3
    80005c02:	94be                	add	s1,s1,a5
    80005c04:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	9da080e7          	jalr	-1574(ra) # 800045e6 <fileclose>
    fileclose(wf);
    80005c14:	fc843503          	ld	a0,-56(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9ce080e7          	jalr	-1586(ra) # 800045e6 <fileclose>
    return -1;
    80005c20:	57fd                	li	a5,-1
}
    80005c22:	853e                	mv	a0,a5
    80005c24:	70e2                	ld	ra,56(sp)
    80005c26:	7442                	ld	s0,48(sp)
    80005c28:	74a2                	ld	s1,40(sp)
    80005c2a:	6121                	addi	sp,sp,64
    80005c2c:	8082                	ret
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	d2ffc0ef          	jal	ra,8000299e <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	6d0c                	ld	a1,24(a0)
    80005ccc:	7110                	ld	a2,32(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	d28080e7          	jalr	-728(ra) # 80001a30 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	00052023          	sw	zero,0(a0)
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	cf0080e7          	jalr	-784(ra) # 80001a30 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5179b          	slliw	a5,a0,0xd
    80005d4c:	0c201537          	lui	a0,0xc201
    80005d50:	953e                	add	a0,a0,a5
  return irq;
}
    80005d52:	4148                	lw	a0,4(a0)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	cc8080e7          	jalr	-824(ra) # 80001a30 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	04a7cc63          	blt	a5,a0,80005de8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d94:	0001c797          	auipc	a5,0x1c
    80005d98:	ebc78793          	addi	a5,a5,-324 # 80021c50 <disk>
    80005d9c:	97aa                	add	a5,a5,a0
    80005d9e:	0187c783          	lbu	a5,24(a5)
    80005da2:	ebb9                	bnez	a5,80005df8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005da4:	00451613          	slli	a2,a0,0x4
    80005da8:	0001c797          	auipc	a5,0x1c
    80005dac:	ea878793          	addi	a5,a5,-344 # 80021c50 <disk>
    80005db0:	6394                	ld	a3,0(a5)
    80005db2:	96b2                	add	a3,a3,a2
    80005db4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005db8:	6398                	ld	a4,0(a5)
    80005dba:	9732                	add	a4,a4,a2
    80005dbc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005dc0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005dc4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005dc8:	953e                	add	a0,a0,a5
    80005dca:	4785                	li	a5,1
    80005dcc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005dd0:	0001c517          	auipc	a0,0x1c
    80005dd4:	e9850513          	addi	a0,a0,-360 # 80021c68 <disk+0x18>
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	390080e7          	jalr	912(ra) # 80002168 <wakeup>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret
    panic("free_desc 1");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	98850513          	addi	a0,a0,-1656 # 80008770 <syscalls+0x2f8>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	74e080e7          	jalr	1870(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005df8:	00003517          	auipc	a0,0x3
    80005dfc:	98850513          	addi	a0,a0,-1656 # 80008780 <syscalls+0x308>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	73e080e7          	jalr	1854(ra) # 8000053e <panic>

0000000080005e08 <virtio_disk_init>:
{
    80005e08:	1101                	addi	sp,sp,-32
    80005e0a:	ec06                	sd	ra,24(sp)
    80005e0c:	e822                	sd	s0,16(sp)
    80005e0e:	e426                	sd	s1,8(sp)
    80005e10:	e04a                	sd	s2,0(sp)
    80005e12:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e14:	00003597          	auipc	a1,0x3
    80005e18:	97c58593          	addi	a1,a1,-1668 # 80008790 <syscalls+0x318>
    80005e1c:	0001c517          	auipc	a0,0x1c
    80005e20:	f5c50513          	addi	a0,a0,-164 # 80021d78 <disk+0x128>
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	d7e080e7          	jalr	-642(ra) # 80000ba2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e2c:	100017b7          	lui	a5,0x10001
    80005e30:	4398                	lw	a4,0(a5)
    80005e32:	2701                	sext.w	a4,a4
    80005e34:	747277b7          	lui	a5,0x74727
    80005e38:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e3c:	14f71c63          	bne	a4,a5,80005f94 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e40:	100017b7          	lui	a5,0x10001
    80005e44:	43dc                	lw	a5,4(a5)
    80005e46:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e48:	4709                	li	a4,2
    80005e4a:	14e79563          	bne	a5,a4,80005f94 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	479c                	lw	a5,8(a5)
    80005e54:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e56:	12e79f63          	bne	a5,a4,80005f94 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	47d8                	lw	a4,12(a5)
    80005e60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e62:	554d47b7          	lui	a5,0x554d4
    80005e66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e6a:	12f71563          	bne	a4,a5,80005f94 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e76:	4705                	li	a4,1
    80005e78:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7a:	470d                	li	a4,3
    80005e7c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e7e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e80:	c7ffe737          	lui	a4,0xc7ffe
    80005e84:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9cf>
    80005e88:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e8a:	2701                	sext.w	a4,a4
    80005e8c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	472d                	li	a4,11
    80005e90:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e92:	5bbc                	lw	a5,112(a5)
    80005e94:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e98:	8ba1                	andi	a5,a5,8
    80005e9a:	10078563          	beqz	a5,80005fa4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ea6:	43fc                	lw	a5,68(a5)
    80005ea8:	2781                	sext.w	a5,a5
    80005eaa:	10079563          	bnez	a5,80005fb4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	5bdc                	lw	a5,52(a5)
    80005eb4:	2781                	sext.w	a5,a5
  if(max == 0)
    80005eb6:	10078763          	beqz	a5,80005fc4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005eba:	471d                	li	a4,7
    80005ebc:	10f77c63          	bgeu	a4,a5,80005fd4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005ec0:	ffffb097          	auipc	ra,0xffffb
    80005ec4:	c82080e7          	jalr	-894(ra) # 80000b42 <kalloc>
    80005ec8:	0001c497          	auipc	s1,0x1c
    80005ecc:	d8848493          	addi	s1,s1,-632 # 80021c50 <disk>
    80005ed0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ed2:	ffffb097          	auipc	ra,0xffffb
    80005ed6:	c70080e7          	jalr	-912(ra) # 80000b42 <kalloc>
    80005eda:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	c66080e7          	jalr	-922(ra) # 80000b42 <kalloc>
    80005ee4:	87aa                	mv	a5,a0
    80005ee6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ee8:	6088                	ld	a0,0(s1)
    80005eea:	cd6d                	beqz	a0,80005fe4 <virtio_disk_init+0x1dc>
    80005eec:	0001c717          	auipc	a4,0x1c
    80005ef0:	d6c73703          	ld	a4,-660(a4) # 80021c58 <disk+0x8>
    80005ef4:	cb65                	beqz	a4,80005fe4 <virtio_disk_init+0x1dc>
    80005ef6:	c7fd                	beqz	a5,80005fe4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005ef8:	6605                	lui	a2,0x1
    80005efa:	4581                	li	a1,0
    80005efc:	ffffb097          	auipc	ra,0xffffb
    80005f00:	e72080e7          	jalr	-398(ra) # 80000d6e <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f04:	0001c497          	auipc	s1,0x1c
    80005f08:	d4c48493          	addi	s1,s1,-692 # 80021c50 <disk>
    80005f0c:	6605                	lui	a2,0x1
    80005f0e:	4581                	li	a1,0
    80005f10:	6488                	ld	a0,8(s1)
    80005f12:	ffffb097          	auipc	ra,0xffffb
    80005f16:	e5c080e7          	jalr	-420(ra) # 80000d6e <memset>
  memset(disk.used, 0, PGSIZE);
    80005f1a:	6605                	lui	a2,0x1
    80005f1c:	4581                	li	a1,0
    80005f1e:	6888                	ld	a0,16(s1)
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	e4e080e7          	jalr	-434(ra) # 80000d6e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	4721                	li	a4,8
    80005f2e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f30:	4098                	lw	a4,0(s1)
    80005f32:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f36:	40d8                	lw	a4,4(s1)
    80005f38:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f3c:	6498                	ld	a4,8(s1)
    80005f3e:	0007069b          	sext.w	a3,a4
    80005f42:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f46:	9701                	srai	a4,a4,0x20
    80005f48:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f4c:	6898                	ld	a4,16(s1)
    80005f4e:	0007069b          	sext.w	a3,a4
    80005f52:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f56:	9701                	srai	a4,a4,0x20
    80005f58:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f5c:	4705                	li	a4,1
    80005f5e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f60:	00e48c23          	sb	a4,24(s1)
    80005f64:	00e48ca3          	sb	a4,25(s1)
    80005f68:	00e48d23          	sb	a4,26(s1)
    80005f6c:	00e48da3          	sb	a4,27(s1)
    80005f70:	00e48e23          	sb	a4,28(s1)
    80005f74:	00e48ea3          	sb	a4,29(s1)
    80005f78:	00e48f23          	sb	a4,30(s1)
    80005f7c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f80:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f84:	0727a823          	sw	s2,112(a5)
}
    80005f88:	60e2                	ld	ra,24(sp)
    80005f8a:	6442                	ld	s0,16(sp)
    80005f8c:	64a2                	ld	s1,8(sp)
    80005f8e:	6902                	ld	s2,0(sp)
    80005f90:	6105                	addi	sp,sp,32
    80005f92:	8082                	ret
    panic("could not find virtio disk");
    80005f94:	00003517          	auipc	a0,0x3
    80005f98:	80c50513          	addi	a0,a0,-2036 # 800087a0 <syscalls+0x328>
    80005f9c:	ffffa097          	auipc	ra,0xffffa
    80005fa0:	5a2080e7          	jalr	1442(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fa4:	00003517          	auipc	a0,0x3
    80005fa8:	81c50513          	addi	a0,a0,-2020 # 800087c0 <syscalls+0x348>
    80005fac:	ffffa097          	auipc	ra,0xffffa
    80005fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80005fb4:	00003517          	auipc	a0,0x3
    80005fb8:	82c50513          	addi	a0,a0,-2004 # 800087e0 <syscalls+0x368>
    80005fbc:	ffffa097          	auipc	ra,0xffffa
    80005fc0:	582080e7          	jalr	1410(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005fc4:	00003517          	auipc	a0,0x3
    80005fc8:	83c50513          	addi	a0,a0,-1988 # 80008800 <syscalls+0x388>
    80005fcc:	ffffa097          	auipc	ra,0xffffa
    80005fd0:	572080e7          	jalr	1394(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005fd4:	00003517          	auipc	a0,0x3
    80005fd8:	84c50513          	addi	a0,a0,-1972 # 80008820 <syscalls+0x3a8>
    80005fdc:	ffffa097          	auipc	ra,0xffffa
    80005fe0:	562080e7          	jalr	1378(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80005fe4:	00003517          	auipc	a0,0x3
    80005fe8:	85c50513          	addi	a0,a0,-1956 # 80008840 <syscalls+0x3c8>
    80005fec:	ffffa097          	auipc	ra,0xffffa
    80005ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>

0000000080005ff4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ff4:	7119                	addi	sp,sp,-128
    80005ff6:	fc86                	sd	ra,120(sp)
    80005ff8:	f8a2                	sd	s0,112(sp)
    80005ffa:	f4a6                	sd	s1,104(sp)
    80005ffc:	f0ca                	sd	s2,96(sp)
    80005ffe:	ecce                	sd	s3,88(sp)
    80006000:	e8d2                	sd	s4,80(sp)
    80006002:	e4d6                	sd	s5,72(sp)
    80006004:	e0da                	sd	s6,64(sp)
    80006006:	fc5e                	sd	s7,56(sp)
    80006008:	f862                	sd	s8,48(sp)
    8000600a:	f466                	sd	s9,40(sp)
    8000600c:	f06a                	sd	s10,32(sp)
    8000600e:	ec6e                	sd	s11,24(sp)
    80006010:	0100                	addi	s0,sp,128
    80006012:	8aaa                	mv	s5,a0
    80006014:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006016:	00c52d03          	lw	s10,12(a0)
    8000601a:	001d1d1b          	slliw	s10,s10,0x1
    8000601e:	1d02                	slli	s10,s10,0x20
    80006020:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006024:	0001c517          	auipc	a0,0x1c
    80006028:	d5450513          	addi	a0,a0,-684 # 80021d78 <disk+0x128>
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	c0a080e7          	jalr	-1014(ra) # 80000c36 <acquire>
  for(int i = 0; i < 3; i++){
    80006034:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006036:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006038:	0001cb97          	auipc	s7,0x1c
    8000603c:	c18b8b93          	addi	s7,s7,-1000 # 80021c50 <disk>
  for(int i = 0; i < 3; i++){
    80006040:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006042:	0001cc97          	auipc	s9,0x1c
    80006046:	d36c8c93          	addi	s9,s9,-714 # 80021d78 <disk+0x128>
    8000604a:	a08d                	j	800060ac <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000604c:	00fb8733          	add	a4,s7,a5
    80006050:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006054:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006056:	0207c563          	bltz	a5,80006080 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000605a:	2905                	addiw	s2,s2,1
    8000605c:	0611                	addi	a2,a2,4
    8000605e:	05690c63          	beq	s2,s6,800060b6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006062:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006064:	0001c717          	auipc	a4,0x1c
    80006068:	bec70713          	addi	a4,a4,-1044 # 80021c50 <disk>
    8000606c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000606e:	01874683          	lbu	a3,24(a4)
    80006072:	fee9                	bnez	a3,8000604c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006074:	2785                	addiw	a5,a5,1
    80006076:	0705                	addi	a4,a4,1
    80006078:	fe979be3          	bne	a5,s1,8000606e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000607c:	57fd                	li	a5,-1
    8000607e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006080:	01205d63          	blez	s2,8000609a <virtio_disk_rw+0xa6>
    80006084:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006086:	000a2503          	lw	a0,0(s4)
    8000608a:	00000097          	auipc	ra,0x0
    8000608e:	cfc080e7          	jalr	-772(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80006092:	2d85                	addiw	s11,s11,1
    80006094:	0a11                	addi	s4,s4,4
    80006096:	ffb918e3          	bne	s2,s11,80006086 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000609a:	85e6                	mv	a1,s9
    8000609c:	0001c517          	auipc	a0,0x1c
    800060a0:	bcc50513          	addi	a0,a0,-1076 # 80021c68 <disk+0x18>
    800060a4:	ffffc097          	auipc	ra,0xffffc
    800060a8:	060080e7          	jalr	96(ra) # 80002104 <sleep>
  for(int i = 0; i < 3; i++){
    800060ac:	f8040a13          	addi	s4,s0,-128
{
    800060b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060b2:	894e                	mv	s2,s3
    800060b4:	b77d                	j	80006062 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060b6:	f8042583          	lw	a1,-128(s0)
    800060ba:	00a58793          	addi	a5,a1,10
    800060be:	0792                	slli	a5,a5,0x4

  if(write)
    800060c0:	0001c617          	auipc	a2,0x1c
    800060c4:	b9060613          	addi	a2,a2,-1136 # 80021c50 <disk>
    800060c8:	00f60733          	add	a4,a2,a5
    800060cc:	018036b3          	snez	a3,s8
    800060d0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060d2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800060d6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060da:	f6078693          	addi	a3,a5,-160
    800060de:	6218                	ld	a4,0(a2)
    800060e0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060e2:	00878513          	addi	a0,a5,8
    800060e6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060e8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060ea:	6208                	ld	a0,0(a2)
    800060ec:	96aa                	add	a3,a3,a0
    800060ee:	4741                	li	a4,16
    800060f0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060f2:	4705                	li	a4,1
    800060f4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800060f8:	f8442703          	lw	a4,-124(s0)
    800060fc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006100:	0712                	slli	a4,a4,0x4
    80006102:	953a                	add	a0,a0,a4
    80006104:	058a8693          	addi	a3,s5,88
    80006108:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000610a:	6208                	ld	a0,0(a2)
    8000610c:	972a                	add	a4,a4,a0
    8000610e:	40000693          	li	a3,1024
    80006112:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006114:	001c3c13          	seqz	s8,s8
    80006118:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000611a:	001c6c13          	ori	s8,s8,1
    8000611e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006122:	f8842603          	lw	a2,-120(s0)
    80006126:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000612a:	0001c697          	auipc	a3,0x1c
    8000612e:	b2668693          	addi	a3,a3,-1242 # 80021c50 <disk>
    80006132:	00258713          	addi	a4,a1,2
    80006136:	0712                	slli	a4,a4,0x4
    80006138:	9736                	add	a4,a4,a3
    8000613a:	587d                	li	a6,-1
    8000613c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006140:	0612                	slli	a2,a2,0x4
    80006142:	9532                	add	a0,a0,a2
    80006144:	f9078793          	addi	a5,a5,-112
    80006148:	97b6                	add	a5,a5,a3
    8000614a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000614c:	629c                	ld	a5,0(a3)
    8000614e:	97b2                	add	a5,a5,a2
    80006150:	4605                	li	a2,1
    80006152:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006154:	4509                	li	a0,2
    80006156:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000615a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000615e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006162:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006166:	6698                	ld	a4,8(a3)
    80006168:	00275783          	lhu	a5,2(a4)
    8000616c:	8b9d                	andi	a5,a5,7
    8000616e:	0786                	slli	a5,a5,0x1
    80006170:	97ba                	add	a5,a5,a4
    80006172:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006176:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000617a:	6698                	ld	a4,8(a3)
    8000617c:	00275783          	lhu	a5,2(a4)
    80006180:	2785                	addiw	a5,a5,1
    80006182:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006186:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000618a:	100017b7          	lui	a5,0x10001
    8000618e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006192:	004aa783          	lw	a5,4(s5)
    80006196:	02c79163          	bne	a5,a2,800061b8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000619a:	0001c917          	auipc	s2,0x1c
    8000619e:	bde90913          	addi	s2,s2,-1058 # 80021d78 <disk+0x128>
  while(b->disk == 1) {
    800061a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061a4:	85ca                	mv	a1,s2
    800061a6:	8556                	mv	a0,s5
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	f5c080e7          	jalr	-164(ra) # 80002104 <sleep>
  while(b->disk == 1) {
    800061b0:	004aa783          	lw	a5,4(s5)
    800061b4:	fe9788e3          	beq	a5,s1,800061a4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800061b8:	f8042903          	lw	s2,-128(s0)
    800061bc:	00290793          	addi	a5,s2,2
    800061c0:	00479713          	slli	a4,a5,0x4
    800061c4:	0001c797          	auipc	a5,0x1c
    800061c8:	a8c78793          	addi	a5,a5,-1396 # 80021c50 <disk>
    800061cc:	97ba                	add	a5,a5,a4
    800061ce:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061d2:	0001c997          	auipc	s3,0x1c
    800061d6:	a7e98993          	addi	s3,s3,-1410 # 80021c50 <disk>
    800061da:	00491713          	slli	a4,s2,0x4
    800061de:	0009b783          	ld	a5,0(s3)
    800061e2:	97ba                	add	a5,a5,a4
    800061e4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061e8:	854a                	mv	a0,s2
    800061ea:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061ee:	00000097          	auipc	ra,0x0
    800061f2:	b98080e7          	jalr	-1128(ra) # 80005d86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061f6:	8885                	andi	s1,s1,1
    800061f8:	f0ed                	bnez	s1,800061da <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061fa:	0001c517          	auipc	a0,0x1c
    800061fe:	b7e50513          	addi	a0,a0,-1154 # 80021d78 <disk+0x128>
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	b1e080e7          	jalr	-1250(ra) # 80000d20 <release>
}
    8000620a:	70e6                	ld	ra,120(sp)
    8000620c:	7446                	ld	s0,112(sp)
    8000620e:	74a6                	ld	s1,104(sp)
    80006210:	7906                	ld	s2,96(sp)
    80006212:	69e6                	ld	s3,88(sp)
    80006214:	6a46                	ld	s4,80(sp)
    80006216:	6aa6                	ld	s5,72(sp)
    80006218:	6b06                	ld	s6,64(sp)
    8000621a:	7be2                	ld	s7,56(sp)
    8000621c:	7c42                	ld	s8,48(sp)
    8000621e:	7ca2                	ld	s9,40(sp)
    80006220:	7d02                	ld	s10,32(sp)
    80006222:	6de2                	ld	s11,24(sp)
    80006224:	6109                	addi	sp,sp,128
    80006226:	8082                	ret

0000000080006228 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006228:	1101                	addi	sp,sp,-32
    8000622a:	ec06                	sd	ra,24(sp)
    8000622c:	e822                	sd	s0,16(sp)
    8000622e:	e426                	sd	s1,8(sp)
    80006230:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006232:	0001c497          	auipc	s1,0x1c
    80006236:	a1e48493          	addi	s1,s1,-1506 # 80021c50 <disk>
    8000623a:	0001c517          	auipc	a0,0x1c
    8000623e:	b3e50513          	addi	a0,a0,-1218 # 80021d78 <disk+0x128>
    80006242:	ffffb097          	auipc	ra,0xffffb
    80006246:	9f4080e7          	jalr	-1548(ra) # 80000c36 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000624a:	10001737          	lui	a4,0x10001
    8000624e:	533c                	lw	a5,96(a4)
    80006250:	8b8d                	andi	a5,a5,3
    80006252:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006254:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006258:	689c                	ld	a5,16(s1)
    8000625a:	0204d703          	lhu	a4,32(s1)
    8000625e:	0027d783          	lhu	a5,2(a5)
    80006262:	04f70863          	beq	a4,a5,800062b2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006266:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000626a:	6898                	ld	a4,16(s1)
    8000626c:	0204d783          	lhu	a5,32(s1)
    80006270:	8b9d                	andi	a5,a5,7
    80006272:	078e                	slli	a5,a5,0x3
    80006274:	97ba                	add	a5,a5,a4
    80006276:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006278:	00278713          	addi	a4,a5,2
    8000627c:	0712                	slli	a4,a4,0x4
    8000627e:	9726                	add	a4,a4,s1
    80006280:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006284:	e721                	bnez	a4,800062cc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006286:	0789                	addi	a5,a5,2
    80006288:	0792                	slli	a5,a5,0x4
    8000628a:	97a6                	add	a5,a5,s1
    8000628c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000628e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	ed6080e7          	jalr	-298(ra) # 80002168 <wakeup>

    disk.used_idx += 1;
    8000629a:	0204d783          	lhu	a5,32(s1)
    8000629e:	2785                	addiw	a5,a5,1
    800062a0:	17c2                	slli	a5,a5,0x30
    800062a2:	93c1                	srli	a5,a5,0x30
    800062a4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062a8:	6898                	ld	a4,16(s1)
    800062aa:	00275703          	lhu	a4,2(a4)
    800062ae:	faf71ce3          	bne	a4,a5,80006266 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062b2:	0001c517          	auipc	a0,0x1c
    800062b6:	ac650513          	addi	a0,a0,-1338 # 80021d78 <disk+0x128>
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	a66080e7          	jalr	-1434(ra) # 80000d20 <release>
}
    800062c2:	60e2                	ld	ra,24(sp)
    800062c4:	6442                	ld	s0,16(sp)
    800062c6:	64a2                	ld	s1,8(sp)
    800062c8:	6105                	addi	sp,sp,32
    800062ca:	8082                	ret
      panic("virtio_disk_intr status");
    800062cc:	00002517          	auipc	a0,0x2
    800062d0:	58c50513          	addi	a0,a0,1420 # 80008858 <syscalls+0x3e0>
    800062d4:	ffffa097          	auipc	ra,0xffffa
    800062d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
