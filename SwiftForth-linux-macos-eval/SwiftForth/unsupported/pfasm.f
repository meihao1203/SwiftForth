{ ====================================================================
(C) Copyright 1999 FORTH, Inc.   www.forth.com

polyFORTH assembler
======================================================================== }

OPTIONAL PFASSEMBLER PolyForth assembler

CR
CR
CR .( The polyFORTH assembler is a case-sensitive application. SwiftForth is)
CR .( case in-sensitive by its default nature. If you load this package, you)
CR .( may have compatability problems with other aspects of SwiftForth.  If)
CR .( possible, please use the default assembler.)
CR
CR .( Press <esc> to quit now, or <enter> to continue... )

KEY 27 = [IF]  DROP \\ [THEN]

CR
CR

CASE-SENSITIVE

ONLY FORTH ALSO DEFINITIONS

VOCABULARY PFASM

PFASM ALSO DEFINITIONS

CREATE ABYSS   $70000000 , $70010000 ,

VARIABLE PTR

#USER
      CELL  +USER FLAGS             \
      CELL  +USER OFST              \
      CELL  +                       \
TO #USER


: F' ' ;
: F, , ;

: T+! +! ;
: T!   ! ;
: TC! C! ;
: TC@ C@ ;

: RECOVER ;

{ ------------------------------------------------------------------------

Throughout these shadows and within the stack comments the term
   "rm" is used to refer to the most significant 32-bits of an
   operand address-mode specifier.

!FLAGS  sets/clears bits in  FLAGS  via and/or masking.
+SZ  moves size bits from  FLAGS  to the "rm" on top of stack.
+TAG  attaches the "rm-valid" field to defined  RG  and  MR .
RG  and  MR  define named register and memory addressing modes.
   The only difference being that register names do not absorb
   the current size bits in  FLAGS .  Refer to the CPU
   Supplement for addressing mode syntax details.
@RG  masks out the register field from an "rm".
lo  defaults hitherto unspecified addressing as absolute.
r  defaults small numbers as general registers and any other
   unspecific addressing defaults  lo .  Note  +SZ  attachment.
)  specifies register indirect addressing.
WIDE  defines the operand size declaratives that will set their
   respective bits in  FLAGS .  Multiple uses set multiple bits.

------------------------------------------------------------------------ }

( Registers, modes)   HEX

: !FLAGS ( n m)   FLAGS @  AND OR  FLAGS ! ;
: +SZ ( rm - rm)   FLAGS @  7 AND OR  0 -8 !FLAGS ;
: +TAG ( a - rm)   @  ABYSS @ OR ;
: RG ( n)   CONSTANT  DOES> ( rm)   +TAG ;
: MR ( n)   CONSTANT  DOES> ( rm)   +TAG +SZ ;
 08 RG ES   10 RG CS   18 RG SS   20 RG DS  580 MR M)  C1 RG #b
 28 RG FS   30 RG GS  040 MR 0)  140 MR 1)  240 MR 2)  C2 RG #h
340 MR 3)  440 MR S)  540 MR R)  640 MR I)  740 MR W)  C4 RG #l
300 RG U   400 RG S   500 RG R   600 RG I   700 RG W   C0 MR #
: @RG ( rm - r)   700 AND ;
: lo ( a - rm)   DUP ABYSS 2@ WITHIN IF  M)  THEN +SZ ;
: r ( n - rm)   DUP 8 U< IF  >< ABYSS @ OR  THEN lo ;
: ) ( r - rm)   r 40 OR  0 SWAP ;
: WIDE ( s)   CONSTANT  DOES>  @ -1 !FLAGS ;
   1 WIDE b   2 WIDE h   4 WIDE l


{ ------------------------------------------------------------------------

hi  specifies a high-order byte-register given 0, 1, 2 or 3.
v  sets a  FLAGS  bit whose meaning depends on the next opcode.
sg  attaches a segment override to an "rm".
si  defines the scaled index specifiers.  See CPU Supplement.
?R  produces an id for a register operand.  Segment register #s
   are copied to the "bbb" field.
!M  moves operand offset to  OFST , copies override to  FLAGS
   and produces an id for a memory operand.
!#  moves # data to  OFST 4+  and produces id for # operands.
?RM  an "mm" field vector table.
ID  defaults an operand with  r , copies size bits to  FLAGS ,
   produces operand id bits and stashes operand data.
UNARY  IDs  one operand and places id at  FLAGS 2+ .
BINARY  IDs  two operands placing id at  FLAGS 2+  and  3 + .



------------------------------------------------------------------------ }

   ( Operand recovery)   HEX
: hi ( n - rm)   b r 400 OR ;      : v   80 -1 !FLAGS ;
: sg ( rm sg - rm)   >R lo  R> OR ;
: si ( n)   CONSTANT  DOES> ( rm r - rm)   @ >R  r >R
      lo  R@ 7 AND OR  2R> @RG  XOR 4 * 2* OR ;
   0400 si )1   0C00 si )2   1400 si )4   1C00 si )8
: ?R ( r - r id)   DUP @RG 0=  10 AND 10 +
      OVER 38 AND ?DUP IF  8 - 20 * ROT OR  SWAP 2* THEN ;
: !M ( m+ - m id)   SWAP OFST !  DUP 38 AND FLAGS +!
      DUP FFC0 AND 580 =  NEGATE 1+ ;
: !# ( #+ - # id)   SWAP OFST CELL+ !  0C ;
CREATE ?RM  F' ?R F,  F' !M F,  F' !M F,  F' !# F,
: ID ( rm - rm id)   r  DUP 7 AND FLAGS +!
      DUP C0 AND 10 /  ?RM + @EXECUTE ;
: UNARY ( rm - rm)   ID FLAGS 2+ H! ;
: BINARY ( rm rm - rm rm)   UNARY >R  ID OFST 1- C!  R> ;


{ ------------------------------------------------------------------------

?HIT  returns the mask ANDed with the half-swapped content of
  FLAGS  and the least bit cleared.  i.e. true implies more
  than one bit matches (see  XCHG  for three bit match).
?ADR  compiles an address override if the mask isn't in  FLAGS .
,HL  examines  FLAGS  bits after  PICK  and builds prefix bytes
  as required.
PICK  when more or less than one size is chosen, uses soft
  defaults to resolve.
PICK2  adds the 2-byte opcode escape.
FIX  applies adjustment after opcode is compiled.
FIN  ends opcode assembly.
!OPC  saves opcode template.  @OPC  fetches it and saves  HERE .
B  is for 8086 assembler compatibility.
-BYTE  is true if  n  won't sign extend from a byte.
,#  compiles immediate data of size given in  FLAGS .
,-#  tries to compile sign extended # unless  b  or  v  are set.

------------------------------------------------------------------------ }

   ( Operand analysis)   HEX
: ?HIT ( msk - t)   FLAGS @ >H< AND  DUP 1- AND ;
: ?ADR ( m)   FLAGS @ AND IF  67 C, THEN ;
: ,HL   800 ?ADR  FLAGS @  DUP DUP >< AND  6 AND IF  66 C,
      THEN  DUP 1 AND 0=  10001 AND PTR +!  38 AND ?DUP IF
         1E +  DUP 40 AND IF  8 / 5C + THEN C,  THEN ;
: PICK   0 +SZ  DUP 0= OR  DUP DUP 1- AND IF  FLAGS U@
      2000 / AND  THEN DUP 0= ABORT" Illegal"  FLAGS +!  ,HL ;
: PICK2   PICK  0F C, ;
: FIX ( n)   PTR @ T+! ;      : FIN   R> 0= FLAGS C! ;
: !OPC ( a)   @ PTR ! ;       : B   -1 FIX ;
: @OPC ( - opc)   PTR @  HERE PTR ! ;
: -BYTE ( n - t)   80 + -100 AND ;
: ,# ( rm)   DROP  OFST CELL+ @ HERE T!  0 +SZ ALLOT ;
: ,-# ( rm)   OFST CELL+ @ -BYTE  FLAGS @ 81 AND
      OR IF ,#  EXIT THEN  DROP  2 FIX  OFST CELL+ @ C, ;


{ ------------------------------------------------------------------------

,R  compiles a register into the "r" field of the mod/rm byte.
+R  compiles a register into the opcode byte.
,DIR  is a "," whose width is derived from the addressing size.
,OFST  compiles the address/offset field.  It tests for direct
   addressing, offsets to  R , zero offsets and byte offsets.
REAL  maps "(sib+2)mod32" into real mode's 3-bit "m" encoding.
,RM  compiles mod/rm, sib and offset for non-immediate operands.
   Tests made are for; not a register, 16-bit addressing,
   si not = 0 or b =  S (in sib).
?V  is 80 if the  v  flag has been set.
?0#  drops rm and returns true iff rm =  0 # .
   Otherwise preserves rm and returns false.
UNI  is used by  RM  and  IMUL  to compile non-#  UNARY .




------------------------------------------------------------------------ }

   ( Operand assembly)   HEX
: ,R ( r)   @RG 4 * 2* FIX ;      : +R ( r)   @RG >< FIX ;
: ,DIR ( n)   FLAGS @ 1000 AND IF  H,  ELSE  ,  THEN ;
: ,OFST ( rm)   OFST @  OVER 80 AND IF  ,DIR DROP  EXIT
   THEN  SWAP @RG 500 <> IF  ?DUP WHILE  THEN  DUP -BYTE IF
      ,DIR  8000 FIX  EXIT THEN  C,  4000 FIX  THEN ;
CREATE REAL  F0F0100 F, 60F070F F, F0F0504 F, F0F0F0F F,
               F0F0302 F, 20F000F F, F0F0F0F F, 30F010F F,
: ,RM ( rm)   DUP C0 AND IF  FLAGS @ 1000 AND IF
         DUP >< 2+ 1F AND  REAL + C@ ><  ELSE
      DUP F800 AND  OVER @RG 400 =  OR IF  DUP >< 20 XOR C,
         400  ELSE  DUP @RG  THEN THEN FIX  ,OFST  EXIT
   THEN @RG C000 OR FIX ;
: ?V ( - t)   FLAGS C@ 80 AND ;
: UNI ( rm)   @OPC ?V 40 / + H,  ,RM  FIN ;  RECOVER



{ ------------------------------------------------------------------------

IMM  handles the commented operand cases for  RM# ,  TEST (note
   v  passed to  ,-# ), XCHG ,  MOV (also  v ),  CNV  and  BIT .
   Note that for many above cases, # data are not valid.  Also
   note that  r r  and  m r  both cause an opcode bias.
#AX  handles  # a  case for  RM#  and  TEST  given opcode bias.
NOT  reverses the sense of a branch condition.
RM#  handles the ALU instructions and some subset cases.
RMR  handles  r/m INC  r/m DEC  r/m/s POP  and  r/m/s/# PUSH .
TEST  accepts  # a  # r/m  and  r/m r .
XCHG  accepts  r a  and  r/m r .

------------------------------------------------------------------------ }

   ( Opcode assembly)   HEX
: IMM   ( # r/m)0433 ?HIT IF  @OPC >H< H,  ,RM  ,-#  FIN THEN
   ( r/m r)3370 ?HIT IF  2 PTR +!  SWAP THEN
   ( r m) @OPC H,  ,RM  ,R  FIN ;  RECOVER
: #AX ( n)   ( # a)420 ?HIT IF  @OPC + C,  DROP ,#  FIN THEN
   DROP IMM ;      : NOT ( cc)   1 XOR ;
: RM#   >H< CONSTANT  DOES> !OPC  BINARY  PICK 4 #AX ;
: RMR   >H< CONSTANT  DOES> !OPC  UNARY  PICK
   ( r)60030 ?HIT IF  @OPC C,  +R  FIN THEN
   ( m)70033 ?HIT IF  @OPC >H< H,  ,RM  FIN THEN
   ( s)60040 ?HIT IF  38 AND 2-  @OPC >< 1 AND OR
      DUP 20 AND IF  0F C,  7A +  THEN C,  FIN THEN
   ( #) @OPC >< C,  ,-#  FIN ;  RECOVER
: TEST   F60082 PTR !  BINARY  PICK  26 v #AX ;
: XCHG   8F0084 PTR !  BINARY  PICK  ( r a)63020
      ?HIT ?HIT IF  @OPC >H< C,  DROP  +R  FIN THEN  IMM ;


{ ------------------------------------------------------------------------

RM  for shift instructions accepts  r/m  r/m v  and  r/m n # .
   For  COM  NEG  MUL  DIV  and  IDIV  only  r/m  is valid.
   For  PIP  PCS  LIP  and  LCS  only  m  is valid.
IMUL  valid operands forms are  r/m  r/m r v  and  r/m r n # .
MOV  valid operands are  d a  a d  (old  LDA  and  STA ),  r/m s
   s r/m  (old  LSG  and  SSG ),  # r  # m  r/m r  and  r m .
SEG  is redundant given the address modifier  sg  but is here
   for compatibility.
I/O  for  IN  and  OUT  instructions, the format is  n  or  v .
   for  INT  #DIV  and  #MUL  only  n  is valid.  The notation
   n  refers to an un-encoded number less than 256.

------------------------------------------------------------------------ }

   ( More opcodes)   HEX
: RM   CONSTANT  DOES> !OPC  UNARY  ( #)0C ?HIT IF
      DROP UNARY  PICK  @OPC 10 - H,  ,RM  OFST CELL+ @ C,  FIN
   THEN  PICK  UNI ;
: IMUL   6828F6 PTR !  ?V IF  BINARY  PICK2
      @OPC DROP 0AF H,  ,R  ,RM  FIN THEN
   UNARY  ( #)0C ?HIT IF  >R  BINARY  PICK
      @OPC >H< H,  ,R  ,RM  R> ,-#  FIN  THEN  PICK  UNI ;
: MOV   C60088 PTR !  BINARY  PICK
   ( # r)430 ?HIT IF  @OPC 4 * 2* 70 + C,  +R  ,#  FIN THEN
   ( d a)220 ?HIT 0= IF  ( a d)2002 ?HIT WHILE  2 PTR +!
      THEN  2DROP  @OPC 18 + C,  OFST @ ,DIR  FIN THEN
   ( ?s)64040 ?HIT IF  3 PTR +!  THEN  v IMM ;
: SEG ( s)   FLAGS C!  ,HL  FIN ;  RECOVER
: I/O   CONSTANT  DOES> !OPC  0 +SZ  DUP 0= -  FLAGS +!
      PICK  @OPC  ?V IF  4+ 4+ C, FIN  THEN  C, C, FIN ; RECOVER

{ ------------------------------------------------------------------------

PEEK  allows  OPC  and  SIO  generated opcodes that normally
   would not expect operands, to examine an operand for size
   information only whenever the  v  flag is set.  The input
   number allows  SIO  instructions to default size to byte.
OPC  generates for the largest number of mnemonic definitions,
   for most of which no size specification is valid.  Those
   for which a size is meaningfull are:  MOVS  CMPS  STOS  LODS
   SCAS  SXT  and  SXT2  (the last two taking only  l  or  h ).
SIO  generates only  INS  and  OUTS .
RTN  generates  RET  and  RET+  that either take no operands or
   n v  where  n  is a 16-bit stack adjust value.
ENTER  takes the "lexical nest level" on top the stack with the
   number of bytes to allocate next.
CNV  generates  MOVSX  and  MOVZX  that accept  r/m r  operands.
   Sizes: nil=h>CPU, b=b>CPU, b&h=b>h, b&l=b>l, h&l=h>l.
   For more discussion refer to the CPU Supplement.

------------------------------------------------------------------------ }

   ( Opcodes, opcodes...)   HEX
: PEEK ( n)   ?V IF  DROP UNARY DROP  ELSE  0 +SZ  SWAP OVER
      0= AND OR  FLAGS +!  THEN PICK  @OPC C,  FIN ;  RECOVER
: OPC   CONSTANT  DOES> !OPC  7 PEEK ;
: SIO   CONSTANT  DOES> !OPC  1 PEEK ;
: RTN   CONSTANT  DOES> !OPC  @OPC C,  ?V IF  H, B
   THEN FIN ;  RECOVER      C3 RTN RET   CB RTN RET+
: ENTER ( n n)   C8 C,  SWAP H,  C, ;      C8 OPC LEAVE

: CNV   CONSTANT  DOES> !OPC  BINARY
      0 +SZ  5 OVER < 2* +  FLAGS +!  ,HL  0F C,  IMM ;
   00B4 CNV MOVZX   00BC CNV MOVSX
: SYS   CONSTANT  DOES> !OPC  UNARY  PICK2  UNI ;
   FFFF SYS SLDT   07FF SYS STR    0FFF SYS LLDT   17FF SYS LTR
   1FFF SYS VERR   27FF SYS VERW   0000 SYS SGDT   0800 SYS SIDT
   1000 SYS LGDT   1800 SYS LIDT   2000 SYS SMSW   3000 SYS LMSW


{ ------------------------------------------------------------------------

SYS  generates the 2-byte unary opcodes of interest only to
   systems programmers.
OP2  generates binary opcodes in the 2-byte class whose operands
   are in the form of  r/m r  or  m r .
DSH  handles the "bit blt" shifts.  Valid operand inputs are
   r r/m v  or  r r/m n # .
BIT  generates the bit test opcodes whose operand syntax is
   n # r/m  or  r r/m .

16BIT  and  32BIT  set the assembler's default address and data
   size modes.  These should always match the machine state.
16{  and  32{  assemble (if required) address size prefixes so
   that the next instuction will be in the given mode.  Their
   use must be restricted to  LOOP  -LOOP  =LOOP  and  1NZ IF
   to define the width of the count.

------------------------------------------------------------------------ }

   ( Opcodes, opcodes...)   HEX
: OP2   CONSTANT  DOES> !OPC  BINARY  PICK2  IMM ;
   00AF OP2 LSS   00B1 OP2 LFS   00B2 OP2 LGS
   00B9 OP2 BSF   00BA OP2 BSR   FFFF OP2 LAR   0000 OP2 LSL
: DSH   CONSTANT  DOES> !OPC ?V 0= IF  UNARY DROP  THEN
   BINARY  PICK2  @OPC H,  ,RM  ,R  ?V 0= IF  OFST CELL+ @ C,
      -1 FIX  THEN FIN ;  RECOVER
   00A4 DSH SHLD   00AC DSH SHRD
: BIT   CONSTANT  DOES> !OPC  BINARY  PICK2  1 FLAGS C!
      ( #)C00 ?HIT IF  IMM  EXIT THEN  @OPC H,  ,RM  ,R  FIN ;
   RECOVER      20B900A2 BIT BT
   28B900AA BIT BTS   30B900B2 BIT BTR   38B900BA BIT BTC
: !MODE   CONSTANT  DOES> @ FLAGS ! ;
   5400 !MODE 16BIT   8200 !MODE 32BIT
: ?ADRS   CONSTANT  DOES> @ ?ADR ;
   200 ?ADRS 16{   400 ?ADRS 32{

{ ------------------------------------------------------------------------

NPC  makes Numeric Processor Control intructions.
FDT  makes Floating Data Transfer intructions.
CDT  makes Control/Debug/Test register move intructions.

------------------------------------------------------------------------ }

: NPC   CONSTANT  DOES> !OPC
      UNARY  ,HL  @OPC H,  ,RM  FIN ;

: FDT   CONSTANT  DOES> !OPC  ID  ,HL
   ( r)30 AND IF  @OPC H,  ,RM  FIN THEN
   ( m) @OPC >H< H,  ,RM  FIX  FIN ;

{ ------------------------------------------------------------------------

NEVER  is the condition code for an unconditional bracnh.
?RANGE  generates an error message if its input is true.
?HALF  aborts if its input could not be sign expanded from
   a halfcell.
?C,  compiles the conditional branch  c  to address  a  if it
   can be reached with a byte displacement and exits.  Otherwise
   it returns with  c  and the displacement from  HERE 2+ .
,DISP  compiles a displacement whose width is determined by the
   data size mode.
JMP  makes an unconditional jump to the given address.
AGAIN  ditto.
?CS  prevents accidental usages of CS as a conditional.
UNTIL  makes a jump to  a  until  c  condition is met.
CALL  there is no short displacement version.
FJMP  assembles an unconditional far (inter-segment) jump.

------------------------------------------------------------------------ }

   ( Structures)   HEX
EB CONSTANT NEVER

: ?RANGE ( t)   ABORT" Out of range" ;
: ?HALF ( a)   8000 + -10000 AND ?RANGE ;
: ?C, ( a c)   >R  HERE 2+ -  DUP -BYTE 0= IF
      R> C, C,  R> DROP FIN  THEN R> ( - n c) ;
: ,DISP ( a)   1-  FLAGS @ 200 AND IF  2- ,  FIN THEN
      DUP ?HALF  H,  FIN ;  RECOVER
: JMP ( a)   NEVER ?C,  2- C, ,DISP ;
: AGAIN ( a)   JMP ;
: ?CS ( c - c)   DUP CS = ABORT" Use CY instead of CS" ;
: UNTIL ( a c)   ?CS  ?C,  0F C, 10 + C,  1- ,DISP ;
: CALL ( a)   E8 C,  HERE 1+ - ,DISP ;
: FJMP ( s o)   EA C,  FLAGS @ 200 AND IF  ,  ELSE   DUP
   0FFFF > ABORT" out of range"  H,  THEN  H,  FIN ;  RECOVER

{ ------------------------------------------------------------------------

IF  assembles a conditional forward jump with byte displacement.
ALTHOUGH  assembles an unconditional forward jump with byte
   displacement.  Usage:   ...  ALTHOUGH  ...  THEN ...
   Control is transferred to  THEN  from the  ALTHOUGH .
WHILE  an  IF  that escapes one layer of containment.
THEN  terminates  IF  WHILE  ELSE  or  SKIP  transfers.
ELSE  separates true and false clauses.
REPEAT  assembles a return to  BEGIN  then terminates  WHILE .
MEANWHILE  begins an  UNTIL  loop structure whose entry point is
   the next  THEN  at the same nest level.
Usage:   MEANWHILE  <A>  THEN  <B>  UNTIL  (or  LOOP  or  AGAIN)
The first time  <A>  is not executed, <B> is; if branches are
   made subsequently, they execute <A> .
ASSEMBLER version of ALIGN forces alignment with NOPs.  May be
   used before BEGIN in time-critical loop.

------------------------------------------------------------------------ }

   ( More structures)   HEX
: ,CX   FLAGS C@ >< ?ADR ;
: -FULL ( c - c t)   DUP 80 <  FLAGS @ 4 AND AND 0= ;

: then ( a)   HERE OVER -  OVER 1- TC@ IF  4- 2-  ELSE
   DUP -BYTE ?RANGE  THEN  SWAP 1- T+! ;
: IF ( c - a)   ?CS  -FULL IF  ,CX  H,  HERE  FIN  THEN  0F C,
   10 + C,  HERE 1+  6 ,DISP ;

: THEN ( a)   then ;
: ALTHOUGH ( - a)   NEVER IF ;
: WHILE ( a c - a a)   IF SWAP ;
: ELSE ( a - a)   ALTHOUGH SWAP  THEN ;
: REPEAT ( a a)   AGAIN  THEN ;
: MEANWHILE ( - a a')   ALTHOUGH  HERE SWAP ;

{ ------------------------------------------------------------------------

RPT  generates the counted loop opcodes.  They are limited to
   byte displacement transfers.

The rest are condition codes.  Note that  1NZ  transfers must be
   limited to byte displacements.  S>  and  S<  are signed.
   U<  and  U>  are unsigned.  Note equivalents  CY  and  0> .

------------------------------------------------------------------------ }

   ( Loop & Conditional Constants)   HEX
: RPT   CONSTANT  DOES> ( a)   ,CX @ ?C,  ?RANGE ;
   RECOVER    E2 RPT LOOP   E1 RPT =LOOP   E0 RPT -LOOP

71 CONSTANT OV  73 CONSTANT U<  75 CONSTANT 0=  76 CONSTANT U>
79 CONSTANT 0<  7B CONSTANT PE  7D CONSTANT S<  7E CONSTANT S>
U< CONSTANT CY  S> CONSTANT 0>  E3 CONSTANT 1NZ

{ ------------------------------------------------------------------------

These are the bulk of the opcode definitions.  Note that among
   them are  AND  OR  and  XOR .  These words, as well as  NOT
   and the conditional branch structures, will bury their  FORTH
   equivalents whenever the context is  ASSEMBLER .  This block
   is suggested reading only for hardcore insomniacs.

SET  assembles the SETcc instruction.  It takes as arguments
  register/memory destination and condition code.

------------------------------------------------------------------------ }

   ( Opcode tables)   HEX
600000 RM# ARPL   5F0000 RM# BOUND   000080 RM# ADD
080880 RM# OR     101080 RM# ADC     181880 RM# SBB
202080 RM# AND    282880 RM# SUB     303080 RM# XOR
383880 RM# CMP    C10000 RM# LES     C20000 RM# LDS
8A0000 RM# LEA

157008E RMR POP   3F00FE RMR INC   4708FE RMR DEC
684F30FE RMR PUSH

00D0 RM ROL   08D0 RM ROR   10D0 RM RCL   18D0 RM RCR
20D0 RM SHL   28D0 RM SHR   38D0 RM SAR   10F6 RM COM
18F6 RM NEG   10FE RM PIP   18FE RM PCS   20FE RM LIP
28FE RM LCS   20F6 RM MUL   30F6 RM DIV   38F6 RM IDIV

0CD I/O INT   D4 I/O #DIV   D5 I/O #MUL   E4 I/O IN
E6 I/O OUT   6C SIO INS    6E SIO OUTS

26 OPC DAA     2E OPC DAS     36 OPC AAA    3E OPC AAS
5F OPC PUSHA   60 OPC POPA    97 OPC SXT    98 OPC SXT2
9A OPC FWAIT   9B OPC PUSHF   9C OPC POPF   9D OPC SAHF
9E OPC LAHF    A4 OPC MOVS    A6 OPC CMPS   AA OPC STOS
AC OPC LODS    AE OPC SCAS    CB OPC BRK    0CD OPC INTO
CE OPC IRET    D6 OPC XLAT    EF OPC LOCK   F1 OPC -REP
F2 OPC REP     F3 OPC HLT     F4 OPC CMC    F7 OPC CLC
F8 OPC STC     F9 OPC CLI     FA OPC STI    FB OPC CLD
FC OPC STD     90 OPC NOP

: SET ( r/m c)   NOT 20 + PTR !  0F C,  UNARY UNI ;


32BIT


{ ------------------------------------------------------------------------

This block is the first of three blocks required to extend the
   80386 assembler to include the 80387 assembly instructions.
   Note that the 80387 uses the 80386 memory addressing operands
   (the 80386 performs the actual addressing).

INH  builds opcodes which do not reference memory or the 80387
   stack (inherent).

For detailed instruction set information consult one of the
   manuals listed in shadow of the 80387 HELP block.

------------------------------------------------------------------------ }

( 80387 inherent opcodes)

HEX

: INH ( n)   CONSTANT  DOES>  @ H, ;

  FAD9 INH FSQRT     FDD9 INH FSCALE     F8D9 INH FPREM
  FCD9 INH FRNDINT   F4D9 INH FXTRACT    E1D9 INH FABS
  E0D9 INH FCHS      F2D9 INH FPTAN      F3D9 INH FPATAN
  F0D9 INH F2XM1     F1D9 INH FYL2X      F9D9 INH FYL2XP1
  E4D9 INH FTST      E5D9 INH FXAM       EED9 INH FLDZ
  E8D9 INH FLD1      EBD9 INH FLDPI      E9D9 INH FLDL2T
  EAD9 INH FLDL2E    ECD9 INH FLDLG2     EDD9 INH FLDLN2
  F7D9 INH FINCSTP   F6D9 INH FDECSTP    D0D9 INH FNOP
  E3DB INH FINIT     E0DB INH FENI       E1DB INH FDISI
  E2DB INH FCLEX     D9DE INH FCOMPP     E0DF INH FSTSWAX
  E4DB INH FSETPM    F5D9 INH FPREM1     E9DA INH FUCOMPP
  FBD9 INH FSINCOS   FED9 INH FSIN       FFD9 INH FCOS

{ ------------------------------------------------------------------------

NPC  builds 80387 coprocessor control class opcodes.

For detailed instruction set information consult one of the
   manuals listed in shadow of the 80387 HELP block.

------------------------------------------------------------------------ }

   ( Processor control class opcodes)

HEX

  28D8 NPC FLDCW       38D8 NPC FSTCW       38DC NPC FSTSW
  30D8 NPC FSTENV      20D8 NPC FLDENV      30DC NPC FSAVE
  20DE NPC FBLD        30DE NPC FBSTP       20DC NPC FRSTOR
  28DE NPC FILD        38DE NPC FISTP
  28DA NPC FTLD        38DA NPC FTSTP

{ ------------------------------------------------------------------------

This block builds 80387 data transfer class opcodes.
   Their operands formats are  r OPC stm  or  size m OPC .

stm   builds a post op-code directive.
-POP  specifies "no-pop".
N0  specifies "dest is stack top" and implies "no-pop".
REV  specifies "use stack top as minuend or dividend".

I16  specifies memory reference to a 16-bit integer.
I32  specifies memory reference to a 32-bit integer.
R32  specifies memory reference to a 32-bit floating.
R64  specifies memory reference to a 64-bit floating.

For detailed instruction set information consult one of the
   manuals listed in shadow of the 80387 HELP block.


------------------------------------------------------------------------ }

   ( Data transfer class opcodes)

HEX

: stm ( n)   CONSTANT  DOES>  @ PTR @ +! ;

   -2 stm -POP   -800 stm REV   -6 stm N0

0 CONSTANT R32   2 CONSTANT I32
4 CONSTANT R64   6 CONSTANT I16

  00D800D8 FDT FLD     10D810DC FDT FST     18D818DC FDT FSTP
  10D710D7 FDT FCOM    18D718D7 FDT FCOMP   00D700DD FDT FADD
  28D728DD FDT FSUB    08D708DD FDT FMUL    38D738DD FDT FDIV
  000008D8 FDT FXCH    000020DC FDT FUCOM   000028DC FDT FUCOMP
  000000DC FDT FFREE



DECIMAL

ONLY FORTH ALSO DEFINITIONS

