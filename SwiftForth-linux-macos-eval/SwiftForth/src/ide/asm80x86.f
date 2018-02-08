{ ====================================================================
i386 ASSEMBLER

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman, Leon Wagner
==================================================================== }

PACKAGE ASM-WORDLIST

?( i386 assembler)

{ --------------------------------------------------------------------
This assembler assumes at least an 80386 operating in protected mode.

Exports: Assembler word set
-------------------------------------------------------------------- }

HEX

THROW#
     S" Destination must be a register" >THROW ENUM IOR_ASM_NOTREG
     S" Illegal operand"                >THROW ENUM IOR_ASM_ILLOP
     S" Unresolved forward references"  >THROW ENUM IOR_ASM_FWDREF
     S" Branch out of range"            >THROW ENUM IOR_ASM_RANGE
     S" Invalid condition code"         >THROW ENUM IOR_ASM_INVALIDCC
TO THROW#

{ ---------------------------------------------------------------------
Assembler support

HERE(A), ALLOT(A), and C!(A) are defined here so their actions can be
changed to support the target compiler.

SHORT? returns true if n can be represented by a signed byte.
LONG? returns true if n requires greater than signed byte.
ILLOP? aborts if illegal operand flag is true.
--------------------------------------------------------------------- }

DEFER HERE(A)           ' HERE IS HERE(A)
DEFER ALLOT(A)          ' ALLOT IS ALLOT(A)
DEFER C!(A)             ' C! IS C!(A)

: C,(A) ( n -- )   HERE(A)  1 ALLOT(A)  C!(A)  ;
: W,(A) ( n -- )   DUP C,(A)  >< C,(A)  ;
: ,(A) ( n -- )   DUP W,(A)  >H< W,(A) ;

: SHORT? ( n -- flag)   -80 80 WITHIN ;
: LONG? ( n -- flag)   SHORT? NOT ;
: ILLOP? ( flag -- )   IOR_ASM_ILLOP ?THROW ;


{ ---------------------------------------------------------------------
Local labels

Unresolved fwd reference associative stack.  Associate stacks can be
"popped" from the middle, or wherever the key is found.

BWDS is the resolved label value array.  Cleared by /ASM.
LPUSH pushes unresolved reference.
LPOP pops any unresolved references.
L? returns the address of the label n or 0 if unresolved.

L: assigns HERE to label n-1.  Resolves any forward references.
Assumes 8-bit relative displacements.

/LABELS initializes local labels and switches.
--------------------------------------------------------------------- }

20 CONSTANT MXL#

CREATE FWDS
   2 CELLS ALLOT  ( pointers)
   MXL# 2 * CELLS ALLOT  ( pairs)

CREATE BWDS
   MXL# CELLS ALLOT

: LPUSH ( value=here' key=label# -- )
   FWDS 2@ = 0= HUH? ( full?)  FWDS @ 2!  2 CELLS FWDS +! ;

: LPOP  ( key=label# - value=addr true | key 0 )
   >R  FWDS @  FWDS 2 CELLS + BEGIN ( end start)
      2DUP = 0= WHILE
      DUP @  R@ = IF ( found!)
         DUP CELL+ @ ( addr) >R
         SWAP 2 CELLS -  DUP FWDS !  2@ ROT 2!  \ promote last pair
         R> R> ( addr key)  -1 OR  ( addr true)  EXIT
      THEN
      2 CELLS +
   REPEAT  2DROP  R> 0 ;

: L? ( n - a | 0)   DUP MXL# U< HUH?  CELLS  BWDS + @ ;

: L: ( n -- )
   DUP L? 0= HUH?  ( should be unknown)
   HERE(A)  OVER CELLS BWDS + !     ( now known)
   BEGIN  DUP LPOP  ( a -1 | n 0)
   WHILE  HERE(A) OVER - 1-  TUCK  SHORT? HUH?  C!(A)  ( resolve ref)
   REPEAT  2DROP ;

: L# ( n -- a )   \ retrieves the value of label n-1.
   DUP L?  ?DUP 0=
   IF  HERE(A) 1+ 2DUP SWAP  LPUSH  THEN  NIP ;

: ?DANGLING ( -- )
   FWDS 2 CELLS + FWDS @ <> IOR_ASM_FWDREF ?THROW ;

: /LABELS ( -- )
   FWDS 2 CELLS + DUP FWDS !  MXL# 2 * CELLS + FWDS CELL+ !
   BWDS MXL# CELLS ERASE ;


{ ---------------------------------------------------------------------
Operands and modes

Operand and mode specifiers have A5A5 in the high half, which is unlikely
to be confused with a 32-bit address.

Mode specifier format:  A5A5 <flags> <value>

Flag byte: -sss tttt
  sss (size)
      0  8-bit or N/A
      1  16-bit
      2  32-bit
      3  64-bit
      4  80-bit
  tttt (type)
      0  general register
      1  segment register
      2  special register
      3  memory (ModR/M)
      4  memory (ModR/M + SIB)
      5  immediate
      6  conditional
      7  absolute (displacement only)
      8  NDP ST register

Value byte depends on the flags.  Examples: ModR/M, Reg, SIB.

SIMPLE defines simple operand specifiers.  Most of these are registers,
except for [] and #, which specify memory and immediate operands.

Examples of [] (same as OFFSET):

        1234 [] EAX MOV         1234 @
        1234 [] JMP             1234 @ EXECUTE

--------------------------------------------------------------------- }

: SIMPLE ( x -- )   A5A50000 + CONSTANT ;

0000 SIMPLE AL    1000 SIMPLE AX    2000 SIMPLE EAX    0100 SIMPLE ES
0001 SIMPLE CL    1001 SIMPLE CX    2001 SIMPLE ECX    0101 SIMPLE CS
0002 SIMPLE DL    1002 SIMPLE DX    2002 SIMPLE EDX    0102 SIMPLE SS
0003 SIMPLE BL    1003 SIMPLE BX    2003 SIMPLE EBX    0103 SIMPLE DS
0004 SIMPLE AH    1004 SIMPLE SP    2004 SIMPLE ESP    0104 SIMPLE FS
0005 SIMPLE CH    1005 SIMPLE BP    2005 SIMPLE EBP    0105 SIMPLE GS
0006 SIMPLE DH    1006 SIMPLE SI    2006 SIMPLE ESI
0007 SIMPLE BH    1007 SIMPLE DI    2007 SIMPLE EDI

4800 SIMPLE ST    4800 SIMPLE ST(0)
4801 SIMPLE ST(1)
4802 SIMPLE ST(2)
4803 SIMPLE ST(3)
4804 SIMPLE ST(4)
4805 SIMPLE ST(5)
4806 SIMPLE ST(6)
4807 SIMPLE ST(7)

2500 SIMPLE #     2705 SIMPLE []    2705 SIMPLE OFFSET

{ ---------------------------------------------------------------------
Operand test and access

R/M masks off the R/M field.
REG moves the low 3 bits to the REG field.

REG? returns true if m specifies any general register.
R8? returns true only if m specifies a 8-bit register.
R16? returns true only if m specifies a 16-bit register.
R32? returns true only if m specifies a 32-bit register.
ACC? returns true if m specifies EAX or AL accumulator.
SEG? returns true if m specifies a segment register.
SIZE? returns the w flag in bit 0 (see above).
@SIZE returns the size field.
IMM? returns true if there's immediate data.
ABS? returns true if m specifies an absolute address.
SIB? returns true if m specifies scaled index + base.
IDX? returns true if m specifies an indexed memory operand.
ADDR? returns true if x is an address (i.e. not a mode specifier).
MEM? returns true if m specifies a memory operand.
COND? returns true if x specifies a structured branch condition.

SIZES defines pairs of words that define a size field constant
and modify the size field of an operand.  For example, S8 is the
contents of the size field (0), and BYTE sets the size field to 0.
--------------------------------------------------------------------- }

: R/M ( m -- r)   7 AND ;
: REG ( m -- r)   R/M 3 LSHIFT ;

: REG? ( m -- flag)   FFFF8FF8 AND AL = ;
: R8? ( m -- flag)   FFFFFFF8 AND AL = ;
: R16? ( m -- flag)   FFFFFFF8 AND AX = ;
: R32? ( m -- flag)   FFFFFFF8 AND EAX = ;
: ACC? ( m -- flag)   FFFF8FFF AND AL = ;
: SEG? ( m -- flag)   FFFFFFF8 AND ES = ;
: SIZE? ( m -- w )   7000 AND 0<> 1 AND ;
: @SIZE ( m -- n)   7000 AND  1000 / ;

: IMM? ( m -- flag)   FFFF8FFF AND 2000 OR # = ;
: ABS? ( m -- flag)   2000 OR  [] = ;
: ADDR? ( x -- flag)   FFFF0000 AND A5A50000 <> ;
: IDX? ( m -- flag)   FFFF8F00 AND  A5A50300 = ;
: SIB? ( m -- flag)   FFFF8F00 AND  A5A50400 = ;
: MEM? ( m -- flag)   DUP IDX?  OVER SIB? OR  SWAP ABS? OR ;
: COND? ( x -- flag)   FFFFFF00 AND  A5A50600 = ;
: ST? ( m -- flag)   FFFFFFF0 AND  ST(0) = ;

: SIZES ( n -- )   DUP CONSTANT  CREATE 1000 * ,
   DOES> ( x1 -- x2)  @ SWAP  DUP ADDR? ILLOP?
   FFFF8FFF AND OR ;

0 SIZES S8  BYTE        \ 8-bit
1 SIZES S16 WORD        \ 16-bit integer
2 SIZES S32 DWORD       \ 32-bit integer and real
3 SIZES S64 QWORD       \ 64-bit integer and real
4 SIZES S80 TBYTE       \ BCD or 80-bit internal real

: S16? ( m -- flag)   @SIZE S16 = ;

{ ---------------------------------------------------------------------
Indexed and scaled addressing modes

INDEX defines indexed mode specifiers.  A pair of indexed mode specifiers
is used to specify base + index addressing that forces the SIB byte.

SCALE defines words that add scale factor forcing SIB byte.
--------------------------------------------------------------------- }

: INDEX  ( n -- )   CREATE  A5A50000 + ,
   DOES> ( x -- x m | m)   @  OVER SIB? ILLOP?
   OVER IDX? IF  REG OR  100 +  THEN ;

2300 INDEX [EAX]
2301 INDEX [ECX]
2302 INDEX [EDX]
2303 INDEX [EBX]
2304 SIMPLE [ESP]
2305 INDEX [EBP]
2306 INDEX [ESI]
2307 INDEX [EDI]

: SCALE  ( n -- )   CREATE  A5A50000 + ,
   DOES> ( x -- x m | m)   @  OVER IDX? NOT ILLOP?
   SWAP R/M OR ;

2440 SCALE [EAX*2]    2480 SCALE [EAX*4]    24C0 SCALE [EAX*8]
2448 SCALE [ECX*2]    2488 SCALE [ECX*4]    24C8 SCALE [ECX*8]
2450 SCALE [EDX*2]    2490 SCALE [EDX*4]    24D0 SCALE [EDX*8]
2458 SCALE [EBX*2]    2498 SCALE [EBX*4]    24D8 SCALE [EBX*8]
2468 SCALE [EBP*2]    24A8 SCALE [EBP*4]    24E8 SCALE [EBP*8]
2470 SCALE [ESI*2]    24B0 SCALE [ESI*4]    24F0 SCALE [ESI*8]
2478 SCALE [EDI*2]    24B8 SCALE [EDI*4]    24F8 SCALE [EDI*8]

{ ---------------------------------------------------------------------
Opcode compiling

OP, assembles combined opcode byte.

SIZE, takes opcode byte with reg/mode specifier and assembles opcode with
W field set for size in m.

DISP, assembles 8, 16, 32 bit displacement or immediate value.
EXT, assembles 8 or 32 bit displacement.

RR, assembles register to register ModR/M byte.  The register in m1 is placed
in the R/M field, m2 goes in the reg/opc field.

SOP, assembles ModR/M and optional SIB bytes for MR, below.
MR, assembles memory to register ModR/M byte (and SIB byte if needed).
RR/RM, assembles either reg to reg or reg to mem mode byte(s).
WRM, assembles 2-operand mem to reg opcode with w field set by register.

WRR, assembles 2-operand reg to reg opcode with w field set by regsters
whose sizes must match.

WRR/MR, assembles 2-operand reg to reg or mem to reg opcode with w field.

WR/SM,  assembles either reg to reg or reg to mem opcode with the size
field of the opcode determined by the first operand.
--------------------------------------------------------------------- }

: OP, ( op m -- )   OR C,(A)  ;

: SIZE, ( opc m --)   SIZE? OP, ;

: EXT, ( n t -- )   IF  ,(A)  ELSE  C,(A)  THEN ;

: DISP, ( n x -- )
   @SIZE CASE
      S8 OF  C,(A)  ENDOF
      S16 OF  W,(A)  ENDOF
      S32 OF  ,(A)  ENDOF
   ILLOP?  ENDCASE ;

: RR, ( m1 m2 -- )   SWAP R/M  SWAP REG OR  C0 OP, ;

: SOP, ( m reg mod -- )   ROT
   DUP SIB? IF  >R  4 OR OP,  R> C,(A)  EXIT THEN
   DUP>R  R/M OR  OP,  R> DWORD [ESP] = IF  $24 C,(A)  THEN ;

: MR, ( mem reg -- )   REG                              \ reg/opc field
   OVER ABS? IF  0 SOP, ,(A)  EXIT THEN                 \ disp32
   2 PICK LONG? IF  80 SOP, ,(A)  EXIT THEN             \ disp32 [reg]
   2 PICK 0<> IF  40 SOP, C,(A)   EXIT THEN             \ disp8 [reg]
   OVER R/M 5 = IF  40 SOP, C,(A)  EXIT THEN            \ 0 [EBP] ...
   0 SOP, DROP ;                                        \ [reg]

: RR/RM, ( disp m reg | reg reg -- )   OVER REG? IF  RR,  ELSE  MR,  THEN  ;

: WRM, ( disp m reg opc  -- )   OVER SIZE,  MR, ;

: WRR, ( reg reg opc  -- )   >R  2DUP XOR 300 AND ILLOP?
   R> OVER SIZE, RR, ;

: WRR/RM, ( disp m reg opc | reg reg opc -- )
   2 PICK REG? IF  WRR,  ELSE  WRM,  THEN ;

: WR/SM, ( r/m r op -- )   2 PICK  DUP REG? IF  SIZE, RR,
   ELSE  SIZE, MR,  THEN ;

{ ---------------------------------------------------------------------
Define instruction classes

INH1 defines simple 1-byte instructions with inherent operands.
16BIT: is the override prefix required for 16-bit operations.
16BIT, automatically compiles the prefix if either operand is 16bit.
INH2 defines simple 2-byte instructions with inherent operands.
ALU1 defines single-operand arithmetic and logical instructions.
ALU2 defines 2-operand arithmetic and logical instructions.
SH defines shift/rotate instructions.
MR defines 2-operand mem->reg32 instructions.
RMR defines 2-operand mem8/reg->reg32 instructions.
RMRW defines 2-operand mem8/reg->reg16/32 instructions.
I/D  define increment/decrement instructions.
SET defines the Set Byte on Condition class.

NPC defines numeric processor control instructions.
Format of opc passed to this defining word is:  --ppii0d
The low byte (d) is the /digit field for the R/M byte.
The ii field is the opcode byte and the optional pp field is the
prefix.  If pp is 0, no prefix is appended.

NFMR defines numeric instructions that take a single memory operand
or a pair of ST registers one of which must be ST(0).

NFR defines numeric instructions that take a pair of ST registers
whose source must be ST(0) or have ST(0) ST(1) implied.

NIM defines numeric processor instructions whose integer operand is
in memory.

NPS defines numeric processor instructions that take a single
ST register or have ST(1) implied.

REL8? takes the branch address (before opcode byte is compiled)
and returns true if an 8-bit branch will work.

REL8, and REL32, assemble the short and long branch offsets
(after the opcode is compiled).

REL  defines relative branch instructions.
--------------------------------------------------------------------- }

: INH1 ( opc)   CREATE C,
   DOES> ( -- )     C@  DUP C,(A)
   D4 D6 WITHIN IF  0A C,(A)  THEN ;            \ AAM, AAD -> Append 0A

: PRE ( opc)   CREATE C,
   DOES> ( -- )     C@ C,(A) ;

$66 PRE 16BIT:

: 16BIT, ( m -- )
   @SIZE  S16 = IF  16BIT:  THEN ;

: INH2 ( opc)   CREATE ,
   DOES> ( -- )     @ W,(A) ;

: ALU1 ( opc -- )   CREATE  C,
   DOES> ( r/m -- )    C@
   OVER 16BIT,  F6 WR/SM, ;

: ALU2 ( opc -- )   CREATE  3 LSHIFT  C,
   DOES> ( src dst -- )     C@ >R
   DUP REG? IF  DUP 16BIT,
      OVER REG? IF  SWAP R> WRR,  EXIT THEN             \ reg -> reg
      OVER MEM? IF  R> 2+ WRM,  EXIT THEN               \ mem -> reg
      SWAP IMM? NOT ILLOP?                              \ imm -> acc/reg
      DUP ACC? IF  R> 4 OR OVER SIZE,
         DISP,  EXIT THEN                               \ imm -> acc
      OVER SHORT? 2 AND 1+  OVER R32? 3 AND AND
      DUP 80 OP,  SWAP R/M C0 +  R> OP,
      1 = EXT,  EXIT  THEN
   ROT DUP REG? IF  DUP 16BIT,  R> WRM,  EXIT THEN      \ reg -> mem
   IMM? NOT ILLOP?  DUP 16BIT,                          \ imm -> mem
   2 PICK SHORT? 2 AND 1+  OVER SIZE? 0<> 3 AND AND
   DUP 80 OP,  -ROT R> 3 RSHIFT MR,  1 = EXT, ;

: SH ( /dig -- )  CREATE  C,
   DOES> ( r/m # | r/m cl | r/m -- )    C@
   OVER CL =  IF  NIP  OVER 16BIT,                      \ r/m CL shift
      D2 WR/SM,  EXIT THEN
   OVER # = IF  NIP SWAP >R  OVER 16BIT,                \ r/m imm shift
      C0 WR/SM,  R> C,(A)  EXIT THEN
   OVER 16BIT,  D0 WR/SM, ;                             \ r/m shift

: MR ( opc -- )   CREATE  C,
   DOES> ( m r --)     C@
   OVER R32? NOT ILLOP?                                 \ dest must be r32
   DUP B2 BF WITHIN IF  0F C,(A)  THEN  C,(A)  MR, ;    \ B2-BE need prefix

: RMR ( opc -- )   CREATE  C,
   DOES> ( m r --)     C@
   OVER R32? NOT ILLOP?                                 \ dest must be r32
   0F C,(A)  C,(A)  RR/RM, ;

: RMRW ( opc -- )   CREATE  C,
   DOES> ( m r --)    C@
   OVER REG? NOT ILLOP?  OVER R8? ILLOP?  OVER R16? -
   0F C,(A)  C,(A)  RR/RM, ;

: I/D ( opc -- )   CREATE  C,
   DOES> ( r/m -- )    C@
   OVER 16BIT,  OVER REG? IF  OVER R8? NOT IF           \ r16/32
      40 OR SWAP R/M OP,  EXIT  THEN THEN
   3 RSHIFT  0FE WR/SM, ;                               \ r8/m

: SET ( opc -- )   CREATE C,
   DOES> ( r/m -- )     C@
   OVER REG? IF  OVER R8? NOT ILLOP?  THEN              \ r8/m
   0F C,(A) C,(A)  0 RR/RM, ;

: NPC ( opc -- )   CREATE ,
   DOES> ( m -- )
   OVER MEM? NOT ILLOP?  @ 100 /MOD  100 /MOD
   ?DUP IF  C,(A)  THEN  C,(A)  MR, ;

: NFMR ( opc -- )   CREATE C,
   DOES> ( m | r r -- )     C@ >R
   DUP ST? IF  DUP ST(0) = IF  D8 C,(A)   SWAP R> RR,
         ELSE  OVER ST(0) <> ILLOP?  0DC C,(A)  R> RR,
   THEN DROP  EXIT  THEN  DUP MEM? NOT ILLOP?  DUP @SIZE
   CASE  S32 OF  D8  ENDOF  S64 OF  0DC   ENDOF
   1 ILLOP?  ENDCASE  C,(A)  R> MR, ;

: NFR ( opc -- )   CREATE C,
   DOES> ( r | -- )     C@
   0DE C,(A)  OVER ST? IF  RR,  ST(0) <> ILLOP?  ELSE
   1 SWAP RR,  THEN ;

: NIM ( opc -- )   CREATE C,
   DOES> ( mem -- )     C@
   OVER MEM? NOT ILLOP?  OVER @SIZE CASE  S32 OF  0DA  ENDOF
   S16 OF  0DE  ENDOF  1 ILLOP?  ENDCASE  C,(A) MR, ;

: NPS ( opc -- )   CREATE ,
   DOES> ( reg | -- )     COUNT C,(A) C@
   OVER ST? NOT IF  1 SWAP  THEN  RR, ;

: REL8? ( addr -- flag)   HERE(A) 2 + - SHORT? ;
: REL8, ( addr -- )   HERE(A) 1+ - C,(A) ;
: REL32, ( addr -- )  HERE(A) 4 + - ,(A) ;
: RANGE? ( flag -- )   IOR_ASM_RANGE ?THROW ;

: REL ( opc -- )   CREATE  C,
   DOES> ( addr -- )    C@
   OVER REL8? IF  C,(A)  REL8,  EXIT THEN               \ Short offset
   DUP 80 AND RANGE?  0F C,(A)  10 + C,(A)  REL32, ;    \ Long offset


{ ---------------------------------------------------------------------
Special instructions

These instructions don't fit into any of the above groups.
--------------------------------------------------------------------- }

: JMP  ( addr | r | disp m -- )
   DUP ADDR? IF  $E9  OVER REL8? IF  2+ C,(A)  REL8,    \ rel8
      EXIT THEN  C,(A)  REL32,  EXIT THEN               \ rel32
   0FF C,(A)  4 RR/RM, ;                                \ r/m

: LJMP  ( addr | r | disp m -- )
   DUP ADDR? IF  $E9 C,(A)  REL32,  EXIT THEN           \ rel32
   0FF C,(A)  4 RR/RM, ;                                \ r/m

: CALL  ( addr | r/m -- )
   DUP ADDR? IF  E8 C,(A)  REL32,  EXIT THEN            \ rel32
   0FF C,(A)  2 RR/RM, ;                                \ r/m

: RET ( n # | -- )
   DUP IMM? IF  DROP  ?DUP IF  C2 C,(A) W,(A)           \ imm16
   EXIT  THEN THEN  C3 C,(A) ;

: TEST ( src dst -- )
   DUP REG? IF  DUP 16BIT,
      OVER REG? IF  84 WRR/RM,  EXIT THEN               \ r/m -> reg
      SWAP IMM? NOT ILLOP?                              \ imm -> acc/reg
      DUP ACC? IF  A8 OVER SIZE,                        \ imm -> acc
      ELSE  F6 OVER SIZE,  DUP R/M C0 OP,  THEN         \ imm -> reg
      DISP,  EXIT  THEN
   ROT DUP REG? IF  DUP 16BIT,  84 WRM,  EXIT THEN      \ reg -> mem
   IMM? NOT ILLOP?  DUP >R 16BIT,  F6 R@ SIZE,          \ imm -> mem
   R@ 0 MR,  R> DISP, ;

: INT ( n -- )     DUP 3 = IF  DROP 0CC
   ELSE  0CD C,(A)  THEN  C,(A) ;

: XCHG ( r/m r | r r/m -- )
   DUP REG? NOT IF  ROT  DUP REG? NOT ILLOP?  THEN
   OVER R32?  OVER EAX = AND IF  DROP R/M 90 OP,  EXIT  THEN
   OVER EAX =  OVER R32? AND IF  R/M 90 OP, DROP  EXIT  THEN
   OVER R16?  OVER AX = AND IF  16BIT: DROP R/M 90 OP,  EXIT  THEN
   OVER AX =  OVER R16? AND IF  16BIT: R/M 90 OP, DROP  EXIT  THEN
   DUP 16BIT,  86 WRR/RM, ;

: MOV ( src dst -- )
   DUP SEG? IF  8E C,(A) RR/RM,  EXIT THEN              \ r/m -> seg
   DUP REG? IF
      OVER SEG? IF  8C C,(A) SWAP RR,  EXIT THEN        \ seg -> reg
      DUP 16BIT,  OVER IMM? IF  NIP  DUP R/M            \ imm -> reg
      OVER R8? NOT 8 AND OR  B0 OP,  DISP,  EXIT THEN
      8A WRR/RM,  EXIT THEN                             \ r/m -> reg
   ROT DUP SEG? IF  8C C,(A) MR,  EXIT THEN             \ seg -> mem
   DUP IMM? IF  DROP  DUP 16BIT,  C6 OVER SIZE,         \ imm -> mem
      DUP -ROT 0 MR,  DISP,  EXIT THEN
   DUP 16BIT,  88 WRR/RM, ;                             \ reg -> mem

: PUSH ( r32 | mem | imm -- )
   DUP SEG? IF  REG 6 OP,  EXIT THEN                    \ seg
   DUP R32? IF  R/M 50 OP,  EXIT THEN                   \ r32
   DUP R16? IF  16BIT:  R/M 50 OP,  EXIT THEN           \ r16
   DUP MEM? IF  DUP 16BIT,  0FF C,(A) 6 MR,  EXIT THEN  \ mem
   DUP IMM? NOT ILLOP?  16BIT,  DUP SHORT? IF           \ imm
      6A C,(A) C,(A)                                    \ imm8
   ELSE  68 C,(A) ,(A)  THEN ;                          \ imm32

: POP ( r32 | mem -- )
   DUP SEG? IF
      DUP CS = ILLOP?  REG 7 OP,  EXIT THEN             \ seg (not CS)
   DUP R32? IF  R/M 58 OP,  EXIT THEN                   \ r32
   DUP R16? IF  16BIT:  R/M 58 OP,  EXIT THEN           \ r16
   DUP MEM? NOT ILLOP?  DUP 16BIT, 8F C,(A)  0 MR, ;    \ mem

: IN ( src dst -- )
   DUP ACC? NOT ILLOP?  DUP 16BIT,
   OVER EDX = IF  0EC SWAP SIZE, DROP                   \ Variable port
   ELSE  E4 SWAP SIZE, C,(A)  THEN ;                    \ Fixed port

: OUT ( src dst -- )
   OVER ACC? NOT ILLOP?  OVER 16BIT,
   DUP EDX = IF  0EE ROT SIZE, DROP  ELSE               \ Variable port
   E6 ROT SIZE, C,(A)  THEN ;                           \ Fixed port


{ ---------------------------------------------------------------------
Special numeric processor instructions

These numeric processor instructions don't fit into any of the above
NPC defining word classes.
--------------------------------------------------------------------- }

: FILD ( mem -- )
   DUP MEM? NOT ILLOP?  DUP @SIZE CASE                  \ mem
      S16 OF  0 0DF  ENDOF                              \ m16int
      S32 OF  0 0DB  ENDOF                              \ m32int
      S64 OF  5 0DF  ENDOF                              \ m64int
   1 ILLOP?  ENDCASE  C,(A)  MR, ;

: FIST ( mem -- )
   DUP MEM? NOT ILLOP?  DUP @SIZE CASE                  \ mem
      S16 OF  2 0DF  ENDOF                              \ m16int
      S32 OF  2 0DB  ENDOF                              \ m32int
   1 ILLOP?  ENDCASE  C,(A)  MR, ;

: FISTP ( mem -- )
   DUP MEM? NOT ILLOP?  DUP @SIZE CASE                  \ mem
      S16 OF  3 0DF  ENDOF                              \ m16int
      S32 OF  3 0DB  ENDOF                              \ m32int
      S64 OF  7 0DF  ENDOF                              \ m64int
   1 ILLOP?  ENDCASE  C,(A)  MR, ;

: FLD ( mem | reg -- )
   DUP ST? IF  D9 C,(A)  0 RR,  EXIT  THEN              \ reg
   DUP MEM? NOT ILLOP?  DUP @SIZE CASE                  \ mem
      S32 OF  0 0D9  ENDOF                              \ m32real
      S64 OF  0 0DD  ENDOF                              \ m64real
      S80 OF  5 0DB  ENDOF                              \ m80real
   1 ILLOP?  ENDCASE  C,(A)  MR, ;

: FST ( mem  | reg -- )
   DUP ST? IF  0DD C,(A)  2 RR,  EXIT THEN              \ reg
   DUP MEM? NOT ILLOP?  DUP @SIZE CASE                  \ mem
      S32 OF  2 0D9  ENDOF                              \ m32real
      S64 OF  2 0DD  ENDOF                              \ m64real
   1 ILLOP?  ENDCASE  C,(A)  MR, ;

: FSTP ( mem | reg -- )
   DUP ST? IF  0DD C,(A)  3 RR,  EXIT THEN              \ reg
   DUP MEM? NOT ILLOP?  DUP @SIZE CASE                  \ mem
      S32 OF  3 0D9  ENDOF                              \ m32real
      S64 OF  3 0DD  ENDOF                              \ m64real
      S80 OF  7 0DB  ENDOF                              \ m80real
   1 ILLOP?  ENDCASE  C,(A)  MR, ;

: FCOM ( mem | reg | -- )
   DUP ST? IF  D8 C,(A)  2 RR,  EXIT THEN               \ reg
   DUP MEM? IF  DUP @SIZE CASE                          \ mem
      S32 OF  2 0D8  ENDOF                              \ m32real
      S64 OF  2 0DC  ENDOF                              \ m64real
   1 ILLOP?  ENDCASE  C,(A)  MR,  EXIT THEN
   D8 C,(A) 1 2 RR, ;                                   \ ST(1)

: FCOMP ( mem | reg | -- )
   DUP ST? IF  D8 C,(A)  3 RR,  EXIT THEN               \ reg
   DUP MEM? IF  DUP @SIZE CASE                          \ mem
      S32 OF  3 0D8  ENDOF                              \ m33real
      S64 OF  3 0DC  ENDOF                              \ m64real
   1 ILLOP?  ENDCASE  C,(A)  MR,  EXIT THEN
   D8 C,(A) 1 3 RR, ;                                   \ ST(1)


{ ---------------------------------------------------------------------
Structured transfers

COND defines condition codes required by IF, WHILE, and UNTIL.

COND, compiles the condition code.  Also allows CS ("Carry Set", which
is also the name of the Code Segment register).

NOT is defined here to invert a condition code or assemble the Intel
NOT instruction if there isn't a cc on the stack.
--------------------------------------------------------------------- }

: COND ( opc -- )   A5A50600 + CONSTANT ;

71 COND OV              \ Overflow
72 COND U>=             \ Unsigned greater than or equal
72 COND CC              \ Carry clear
73 COND U<              \ Unsigned less than
74 COND 0<>             \ Not zero
75 COND 0=              \ Zero
76 COND U>              \ Unsigned greater than
77 COND U<=             \ Unsigned less than or equal
78 COND 0>=             \ Not negative
79 COND 0<              \ Negative
7A COND PO              \ Parity odd
7B COND PE              \ Parity even
7C COND >=              \ Signed greater or equal
7D COND <               \ Signed less than
7E COND >               \ Signed greater than
7E COND 0>              \ Positive
7F COND <=              \ Signed less than or equal
E3 COND ECXNZ           \ CX not zero
EB COND NEVER           \ Unconditional

: CS? ( x1 -- x2)   DUP CS = IF  DROP U<  THEN ;

: COND, ( x -- )   CS?  DUP COND? NOT
   IOR_ASM_INVALIDCC ?THROW    C,(A) ;

2 ALU1 (NOT)

: NOT ( i*x -- j*x)   CS?  DUP COND? IF  1 XOR  ELSE  (NOT)  THEN ;

: -SHORT ( addr1 addr2 -- n)   1+ - DUP LONG? RANGE? ;

: IF ( cc -- addr)   COND,  HERE(A)  0 C,(A) ;
: THEN ( addr -- )   HERE(A) OVER -SHORT  SWAP C!(A) ;
: ELSE ( addr1 -- addr2)   NEVER IF  SWAP THEN ;
: BEGIN ( -- addr)   HERE(A) ;
: AGAIN ( addr -- )   JMP ;
: WHILE ( addr1 cc - addr2 addr1)   IF SWAP ;
: REPEAT ( addr1 addr2 -- )   AGAIN THEN ;
: UNTIL ( addr cc -- )   COND,  HERE(A) -SHORT C,(A) ;


{ ---------------------------------------------------------------------
Instruction groups

Only 32-bit CMPXCHG is supported.
--------------------------------------------------------------------- }

27 INH1 DAA      2F INH1 DAS      37 INH1 AAA      3F INH1 AAS
60 INH1 PUSHA    61 INH1 POPA     90 INH1 NOP      98 INH1 CBW
99 INH1 CDQ      9B INH1 WAIT     9C INH1 PUSHF    9D INH1 POPF
9E INH1 SAHF     9F INH1 LAHF     CE INH1 INTO     CF INH1 IRET
D4 INH1 AAM      D5 INH1 AAD      D7 INH1 XLAT     F0 INH1 LOCK
F2 INH1 REPNE    F2 INH1 REPNZ    F3 INH1 REP      F3 INH1 REPE
F3 INH1 REPZ     F4 INH1 HLT      F5 INH1 CMC      F8 INH1 CLC
F9 INH1 STC      FA INH1 CLI      FB INH1 STI      FC INH1 CLD
FD INH1 STD

26 PRE ES:      2E PRE CS:      36 PRE SS:      3E PRE DS:
64 PRE FS:      65 PRE GS:

3 ALU1 NEG      4 ALU1 MUL      5 ALU1 IMUL     6 ALU1 DIV
7 ALU1 IDIV

0 ALU2 ADD      1 ALU2 OR       2 ALU2 ADC      3 ALU2 SBB
4 ALU2 AND      5 ALU2 SUB      6 ALU2 XOR      7 ALU2 CMP

0 SH ROL        1 SH ROR        2 SH RCL        3 SH RCR
4 SH SHL        5 SH SHR        7 SH SAR

62 MR BOUND     8D MR LEA       C4 MR LES       C5 MR LDS
B2 MR LSS       B4 MR LFS       B5 MR LGS

BC RMR BSF      BD RMR BSR
B1 RMR CMPXCHG

B6 RMRW MOVZX   BE RMRW MOVSX
B7 RMRW MOVZXW  BF RMRW MOVSXW

00 I/D INC      08 I/D DEC

70 REL JO       71 REL JNO      72 REL JB       72 REL JC
73 REL JAE      73 REL JNC      74 REL JE       74 REL JZ
75 REL JNE      75 REL JNZ      76 REL JBE      77 REL JA
78 REL JS       79 REL JNS      7A REL JPE      7B REL JPO
7C REL JL       7D REL JGE      7E REL JLE      7F REL JG
E0 REL LOOPNE   E1 REL LOOPE    E2 REL LOOP     E3 REL JECXZ

{ ---------------------------------------------------------------------
Set on conditions instructions
--------------------------------------------------------------------- }

90 SET SETO     \ Set byte if overflow (OF=1)
91 SET SETNO    \ Set byte if not overflow (OF=0)
92 SET SETB     \ Set byte if below (CF=1)
92 SET SETC     \ Set if carry (CF=1)
92 SET SETNAE   \ Set byte if not above or equal (CF=1)
93 SET SETAE    \ Set byte if above or equal (CF=0)
93 SET SETNB    \ Set byte if not below (CF=0)
93 SET SETNC    \ Set byte if not carry (CF=0)
94 SET SETE     \ Set byte if equal (ZF=1)
94 SET SETZ     \ Set byte if zero (ZF=1)
95 SET SETNE    \ Set byte if not equal (ZF=0)
95 SET SETNZ    \ Set byte if not zero (ZF=0)
96 SET SETBE    \ Set byte if below or equal (CF=1 or ZF=1)
96 SET SETNA    \ Set byte if not above (CF=1 or ZF=1)
97 SET SETA     \ Set byte if above (CF=0 and ZF=0)
97 SET SETNBE   \ Set byte if not below or equal (CF=0 and ZF=0)
98 SET SETS     \ Set byte if sign (SF=1)
99 SET SETNS    \ Set byte if not sign (SF=0)
9A SET SETP     \ Set byte if parity (PF=1)
9A SET SETPE    \ Set byte if parity even (PF=1)
9B SET SETNP    \ Set byte if not parity (PF=0)
9B SET SETPO    \ Set byte if parity odd (PF=0)
9C SET SETL     \ Set byte if less (SF<>OF)
9C SET SETNGE   \ Set if not greater or equal (SF<>OF)
9D SET SETGE    \ Set byte if greater or equal (SF=OF)
9D SET SETNL    \ Set byte if not less (SF=OF)
9E SET SETLE    \ Set byte if less or equal (ZF=1 or SF<>OF)
9E SET SETNG    \ Set byte if not greater (ZF=1 or SF<>OF)
9F SET SETG     \ Set byte if greater (ZF=0 and SF=OF)
9F SET SETNLE   \ Set byte if not less or equal (ZF=0 and SF=OF)

{ ---------------------------------------------------------------------
String instructions
--------------------------------------------------------------------- }

6C INH1 INSB     6D INH1 INSD     6D66 INH2 INSW
6E INH1 OUTSB    6F INH1 OUTSD    6F66 INH2 OUTSW
A4 INH1 MOVSB    A5 INH1 MOVSD    A566 INH2 MOVSW
A6 INH1 CMPSB    A7 INH1 CMPSD    A766 INH2 CMPSW
AA INH1 STOSB    AB INH1 STOSD    AB66 INH2 STOSW
AC INH1 LODSB    AD INH1 LODSD    AD66 INH2 LODSW
AE INH1 SCASB    AF INH1 SCASD    AF66 INH2 SCASW

{ ---------------------------------------------------------------------
Floating point instructions
--------------------------------------------------------------------- }

D0D9 INH2 FNOP          D9DE INH2 FCOMPP
E0D9 INH2 FCHS          E0DB INH2 FENI
E0DF INH2 FSTSWAX       E1D9 INH2 FABS
E1DB INH2 FDISI         E2DB INH2 FCLEX
E3DB INH2 FINIT         E4D9 INH2 FTST
E4DB INH2 FSETPM        E5D9 INH2 FXAM
E8D9 INH2 FLD1          E9D9 INH2 FLDL2T
E9DA INH2 FUCOMPP       EAD9 INH2 FLDL2E
EBD9 INH2 FLDPI         ECD9 INH2 FLDLG2
EDD9 INH2 FLDLN2        EED9 INH2 FLDZ
F0D9 INH2 F2XM1         F1D9 INH2 FYL2X
F2D9 INH2 FPTAN         F3D9 INH2 FPATAN
F4D9 INH2 FXTRACT       F5D9 INH2 FPREM1
F6D9 INH2 FDECSTP       F7D9 INH2 FINCSTP
F8D9 INH2 FPREM         F9D9 INH2 FYL2XP1
FAD9 INH2 FSQRT         FBD9 INH2 FSINCOS
FCD9 INH2 FRNDINT       FDD9 INH2 FSCALE
FED9 INH2 FSIN          FFD9 INH2 FCOS

D904 NPC FLDENV
D905 NPC FLDCW
D906 NPC FNSTENV        9BD906 NPC FSTENV
D907 NPC FNSTCW         9BD907 NPC FSTCW
DD04 NPC FRSTOR
DD06 NPC FNSAVE         9BDD06 NPC FSAVE
DD07 NPC FNSTSW         9BDD07 NPC FSTSW
DF04 NPC FBLD
DF06 NPC FBSTP

0 NFMR FADD     0 NFR FADDP     0 NIM FIADD
1 NFMR FMUL     1 NFR FMULP     1 NIM FIMUL
4 NFMR FSUB     4 NFR FSUBRP    4 NIM FISUB
5 NFMR FSUBR    5 NFR FSUBP     5 NIM FISUBR
6 NFMR FDIV     6 NFR FDIVRP    6 NIM FIDIV
7 NFMR FDIVR    7 NFR FDIVP     7 NIM FIDIVR

0DD NPS FFREE   1D9 NPS FXCH    4DD NPS FUCOM   5DD NPS FUCOMP

DECIMAL

{ --------------------------------------------------------------------
Macros

[U] takes a user variable address and generates the [ESI] index
mode for that user offset.  ESI is the user pointer in SwiftForth.

POP(EBX) pops EBX (TOS) from the data stack.
PUSH(EBX) pushes EBX (TOS) onto the data stack.
ADDR generates [EDI] index mode for the data space address.
-------------------------------------------------------------------- }

: [U] ( user -- )
   UP@ - [ESI] ;

: POP(EBX) ( -- )
   0 [EBP] EBX MOV  4 # EBP ADD  ;

: PUSH(EBX)
   4 # EBP SUB  EBX 0 [EBP] MOV  ;

: ADDR ( address reg -- )
   DUP R32? 0 = IOR_ASM_NOTREG ?THROW >R
   ORIGIN - [EDI] R> LEA ;

END-PACKAGE
