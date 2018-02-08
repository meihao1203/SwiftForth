{ ====================================================================
Disassembler

Copyright (C) 2001 FORTH, Inc.  All rights reserved.

This file implements a disassembler/decompiler for much of the i386
(IA32) instruction set.
==================================================================== }

{ --------------------------------------------------------------------
80x86 32-bit disassembler

Requires: Address illumination

Exports: DASM  SEE  DECODE:
-------------------------------------------------------------------- }

?( Decompiler)

PACKAGE DECOMPILER

{ ---------------------------------------------------------------------
Decompiler variables

>IP is the pointer to next location to be decompiled.
>DEST points at the destination if the last instruction was a transfer.
?DONE flag indicates that decompilation should terminate.
>START points to start of definition being decoded.
>LIMIT has the highest branch/jump destination address so far.
>OPCODE points to the start of the opcode being disassembled.
>DECODER points to the head of the target decoder chain.
--------------------------------------------------------------------- }

VARIABLE >IP            \ pointer to next location to be decompiled
VARIABLE >DEST          \ pointer to destination of call/branch
VARIABLE ?DONE          \ flag indicating that decompilation should be ended
VARIABLE >START         \ pointer to start of definition being decoded
VARIABLE >LIMIT         \ highest destination address so far
VARIABLE >OPCODE        \ pointer to current opcode
VARIABLE >DECODER       \ Decode chain

:PRUNE   >DECODER UNLINKS ;

{ ---------------------------------------------------------------------
Decompiler internals

+IP  returns current >IP and adds n to contents of >IP.
IC@, IW@, and I@ return the next byte, word, and cell pointed to by IP,
advancing IP past it.
<<8 sign-extends 8-bit values.
?LIMIT sets ?DONE flag if >IP points past >LIMIT .
!LIMIT updates >LIMIT returning the same address.
?WHERE formats a new output line starting with the >IP address.
--------------------------------------------------------------------- }

PUBLIC
: +IP ( n -- addr)   >IP @  SWAP >IP +! ;
PRIVATE

: IC@ ( -- char)   1 +IP C@ ;
: IW@ ( -- char)   2 +IP W@ ;
: I@ ( -- char)   4 +IP @ ;

: <<8 ( char -- n )   255 AND -128 XOR  128 + ;

: ?LIMIT   >LIMIT @  >IP @ U<  ?DONE ! ;

: !LIMIT ( addr -- addr )   DUP >IP @ > IF
   DUP >LIMIT @ MAX  >LIMIT !  THEN ;

: ?WHERE ( -- )   1 ?SCROLL  >IP @ U.  2 SPACES ;

{ ---------------------------------------------------------------------
Decompiler behavior

.DECODE defers the behavior to decompile a single instruction pointed
to by >IP.

.DATA defers the action to display addtional data at the end of an
instruction.  Its initial default is NoData which does nothing.

DECODE, adds decode behavior addr2 for xt addr1 to the >DECODER chain.

DECODE: is followed by target word then host decode action which are
added to the decoder chain.

.DEST-ADDR runs down the decoder chain looking for a match with addr
and if found executes the host behavior.  If not found, calls .DEST-
ADDR which displays the address or name if (.') finds an exact match.
--------------------------------------------------------------------- }

DEFER .DECODE   DEFER .DATA

: NoData ;

: DECODE ( addr -- )
   /SCROLL  0 ?DONE !                   \ Setup, clear flag
   DUP >IP !  DUP >START !  >LIMIT !    \ Establish start of definition
   BASE @ >R  HEX                       \ Disassemble in HEX
   BEGIN                                \ Main decode loop
       ['] NoData IS .DATA  >DEST OFF   \ Establish defaults
       ?WHERE  >IP @ >R  .DECODE        \ Display addr, opcode, data
       40 GET-XY DROP - SPACES
       >IP @ R> DO
       I C@ 2 H.0  LOOP  .DATA  ( ?DEBUG)
   ?DONE @   >IP @ @ 0= OR UNTIL        \ Until ?DONE set or in the weeds
   R> BASE ! ;                          \ Restore BASE

PUBLIC
: DECODE, ( xt1 xt2 -- )                \ xt1=runtime xt, xt2=decode xt
   >DECODER >LINK  SWAP , , ;

: DECODE:   ' '  DECODE, ;

: .DECODES ( -- )
   >DECODER  BEGIN  @REL  ?DUP WHILE    \ Run down >DECODER chain
      CR  DUP CELL+ 2@ >CODE .' >CODE .'
   REPEAT ;

PRIVATE

: .DEST-ADDR ( addr -- )   DUP .
   DUP ORIGIN >START @ WITHIN IF
   ." ( "  DUP .'  ." ) "  THEN DROP ;

: .DEST ( addr -- )
   DUP >DEST !  CODE>                   \ Save dest addr, convert to xt
   >DECODER  BEGIN  @REL  ?DUP WHILE    \ Run down >DECODER chain
      2DUP CELL+ @ = IF                 \ Decode behavior?
         DUP CELL+ CELL+ @ IS .DATA     \ If so, set .DATA
   THEN  REPEAT  >CODE .DEST-ADDR ;     \ Display as linear addr

{ ---------------------------------------------------------------------
Vectored decode table

'OPCODES vectors the decoding of opcodes.  The first half of the table
is for one-byte opcodes.  The second half is for 2-byte opcodes whose
first byte is 0F.

'OPCODE returns the address in 'OPCODES for index i .
OPC: compiles headless disassembly code for index i .

.OPCODE gets the next byte to disassemble, adds offset i, and vectors
through the 'OPCODES table.

DASM  decodes starting at code address a.
SEE decodes the next word in the input stream.
MORE continues where the previous disassembly stopped.
--------------------------------------------------------------------- }

CREATE 'OPCODES  512 CELLS ALLOT

: 'OPCODE ( i -- addr)   CELLS 'OPCODES + ;

: OPC: ( i -- )   DUP $1FF > ABORT" Illegal"
   'OPCODE >R  :NONAME  R> ! ;

: .OPCODE ( i -- )   IC@ +  'OPCODE @EXECUTE ;

: .CODE   >IP @  >OPCODE !  0 .OPCODE  SPACE ;

: ILLOP   ." ILLEGAL" ;

' ILLOP 'OPCODES !   'OPCODES DUP CELL+ 511 CELLS CMOVE

{ ---------------------------------------------------------------------
Operand display

?D16 is set if the next opcode is to be decoded as 16-bit.
@MMR returns r/m mod and reg fields from next opcode byte.
@RMM returns reg r/m and mod fields from next opcode byte.
@MM returns r/m and mod fields from next opcode byte.

?E displays "E" if ?D16 isn't set.
?D displays "D" if ?D16 is set.
?W/D displays either "W" or "D" based on the ?D16 flag.

.FLD displays subfield n1 of counted string at c-addr whose substrings
are all n2 bytes long.

.Rb, .Rw, and .Rv display byte, word, and word/long register names.
.Gb, .Gw, and .Gv display general register operands.
.Sw displays segment register operands.
Ib, Iw, and Iv display immediate operands.
Jb and Jv display relative branch/call destinations.
Offs displays operand which has an Offset only.
.X displays an index register.
.SIB displays the Scale, Index, Base byte.
Ex is internal to (Eb), (Ev), and (Ew) to display ModR/M decode.
Eb, Ev, Ew display a single ModR/M operand with size info if necessary.

Eb,Gb and so on display pairs of operands.  The names correspond to the
notation used int he Intel reference manual OPCODE MAP.
--------------------------------------------------------------------- }

HEX

VARIABLE ?D16

: @MMR ( -- r/m mod reg)   IC@  8 /MOD  8 /MOD  SWAP ;
: @RMM ( -- reg r/m mod)   @MMR -ROT ;
: @MM ( -- r/m mod)   @MMR DROP ;

: ?E ( -- )   ?D16 @ 0= IF  ." E"  THEN ;
: ?D ( -- )   ?D16 0= IF  ." D"  THEN ;
: ?W/D ( -- )   ?D16 @ IF  ." W"  ELSE  ." D"  THEN ;

: .FLD ( n1 addr n2 -- )   >R  SWAP R@ * + 1+ R> TYPE ;

: .Rb ( n -- )   C" ALCLDLBLAHCHDHBH" 2 .FLD ;
: .Rw ( n -- )   C" AXCXDXBXSPBPSIDI" 2 .FLD ;
: .Rv ( n -- )   ?E .Rw ;

: .Gb ( n -- )   .Rb SPACE ;
: .Gw ( n -- )   .Rw SPACE ;
: .Gv ( n -- )   .Rv SPACE ;

: .Sw ( n -- )   C" ESCSSSDSFSGS????" 2 .FLD SPACE ;

: .IMM ( n -- )   . ." # " ;
: @Iv ( -- n)   ?D16 @ IF  IW@  ELSE  I@  THEN ;

: Ib ( -- )   IC@ .IMM ;
: Iw ( -- )   IW@ .IMM ;
: Iv ( -- )   @Iv .IMM ;

: Jb ( -- )   IC@ <<8 >IP @ + !LIMIT .DEST ;
: Jv ( -- )   I@ >IP @ + !LIMIT .DEST ;

: Offs ( -- )   I@ .DEST ;

: .X ( n -- )   ." [E"  .Rw ." ] " ;

: .SI ( s i -- )   ." [E"  .Rw  ?DUP IF  ." *"
   C" 248" + 1 TYPE  THEN  ." ] " ;

: .SIB ( sib mod -- )   >R  8 /MOD  8 /MOD
   ROT  DUP 5 <> R@ OR IF  DUP .X  THEN DROP    \ No base reg if b=5 & mod=0
   OVER 4 <> IF  SWAP 2DUP .SI  THEN
   2DROP  R> DROP ;

DEFER .Gx   DEFER .SIZ   ' NOOP IS .SIZ

: "BYTE   ." BYTE " ;
: "WORD   ." WORD " ;
: "QWORD   ." QWORD " ;
: "TBYTE   ." TBYTE " ;
: "B/W   ?D16 @ IF  "WORD  THEN ;

: Ex ( r/m mod -- )   CASE
      0 OF  CASE
         4 OF  ." 0 " IC@ 0 .SIB  ENDOF  5 OF  I@ .  ENDOF
         ." 0 " DUP .X  ENDCASE  .SIZ  ENDOF
      1 OF  DUP 4 = IF  DROP  IC@  IC@ <<8 .  1 .SIB
         ELSE  IC@ <<8 . .X  THEN  .SIZ  ENDOF
      2 OF  DUP 4 = IF  DROP  IC@  I@ .  2 .SIB
         ELSE  I@ . .X  THEN  .SIZ  ENDOF
   SWAP .Gx  ENDCASE  ['] NOOP IS .SIZ ;

: (Eb) ( r/m mod -- )   ['] .Gb IS .Gx  Ex ;
: (Ev) ( r/m mod -- )   ['] .Gv IS .Gx  Ex ;
: (Ew) ( r/m mod -- )   ['] .Gw IS .Gx  Ex ;

: Eb ( r/m mod -- )   ['] "BYTE IS .SIZ  (Eb) ;
: Ev ( r/m mod -- )   ['] "B/W IS .SIZ  (Ev) ;
: Ew ( r/m mod -- )   ['] "WORD IS .SIZ  (Ew) ;
: Eq ( r/m mod -- )   ['] "QWORD IS .SIZ  (Ev) ;
: Et ( r/m mod -- )   ['] "TBYTE IS .SIZ  (Ev) ;

: Eb,Gb ( -- )   @MMR .Gb (Eb) ;
: Ev,Gv ( -- )   @MMR .Gv (Ev) ;
: Ew,Gw ( -- )   @MMR .Gw (Ew) ;

: Gb,Eb ( -- )   @RMM (Eb) .Gb ;
: Gv,Ev ( -- )   @RMM (Ev) .Gv ;
: Gv,Eb ( -- )   @RMM (Eb) .Gv ;
: Gv,Ew ( -- )   @RMM (Ew) .Gv ;

: Ew,Sw ( -- )   @MMR .Sw (Ev) ;
: Sw,Ew ( -- )   @RMM (Ev) .Sw ;

: Eb,Ib ( -- )   [BUF @MM Eb BUF]  Ib .BUF ;
: Ev,Iv ( -- )   [BUF @MM Ev BUF]  Iv .BUF ;
: Ev,Ib ( -- )   [BUF @MM Ev BUF]  IC@ <<8 .IMM .BUF ;

: Gv,Ev,Iv ( -- ) ;
: Gv,Ev,Ib ( -- ) ;

{ ---------------------------------------------------------------------
Special opcode groups

Secondary opcodes whose instruction type is in the REG field of the
ModR/M byte are decoded here.  These are grouped as described in the
Intel manual's Opcode Extensions table.
--------------------------------------------------------------------- }

: @REG ( -- n )   >OPCODE @ 1+ C@  3 RSHIFT  7 AND ;

: IMM1 ( -- )   @REG  C" ADDOR ADCSBBANDSUBXORCMP" 3 .FLD ;

: SH2 ( -- )   @REG  C" ROLRORRCLRCRSHLSHR???SAR"  3 .FLD ;

: (UN3) ( n -- )   C" TEST????NOT NEG MUL IMULDIV IDIV"  4 .FLD ;

: UN3 ( -- )   @REG  DUP 0= IF  Ev,Iv  ELSE  @MM Ev  THEN  (UN3) ;

: UN3B ( -- )   @REG  DUP 0= IF  Eb,Ib  ELSE  @MM Eb  THEN  (UN3) ;

: ID4 ( -- )   @REG IF  ." DEC"  ELSE  ." INC"  THEN ;

: ID5 ( -- )   @REG  DUP C" INC DEC CALLCALLJMP JMP PUSH????"  4 .FLD
   4 6 WITHIN IF  ?LIMIT  THEN ;

{ ---------------------------------------------------------------------
Numeric coprocessor opcode groups

.ST displays ST(n).
.FALU displays one of the floating point math opcodes.
ESC-xx decodes the second byte of the corresponding coprocessor escapes.
--------------------------------------------------------------------- }

: .ST ( n -- )   ." ST(" 0 U.R ." ) " ;
: .FALU ( n -- )   C" FADD FMUL FCOM FCOMPFSUB FSUBRFDIV FDIVR" 5 .FLD ;

: ESC-D8 ( -- )   @RMM DUP 3 < IF  (Ev)  ELSE
   DROP .ST 0 .ST  THEN  .FALU ;

: ESC-D9 ( -- )   @RMM DUP 3 < IF  (Ev)
      C" FLD   F?    FST   FSTP  FLDENVFLDCW FSTENVFSTCW "  6 .FLD
      ELSE  DROP  SWAP CASE
         0 OF  .ST ." FLD"  ENDOF
         1 OF  .ST ." FXCH"  ENDOF
         2 OF  0= IF  ." FNOP"  ELSE  ILLOP  THEN  ENDOF
         4 OF  C" FCHSFABSF?  F?  FTSTFXAMF?  F?  " 4 .FLD  ENDOF
         5 OF  C" FLD1  FLDL2TFLDL2EFLDPI FLDLG2FLDLN2FLDZ  F?    " 6 .FLD  ENDOF
         6 OF  C" F2XM1  FYL2X  FPTAN  FPATAN FXTRACTFPREM1 FDECSTPFINCSTP" 7 .FLD  ENDOF
         7 OF  C" FPREM  FYL2XP1FSQRT  FSINCOSFRNDINTFSCALE FSIN   FCOS   " 7 .FLD  ENDOF
   DROP  ILLOP  ENDCASE  THEN ;

: ESC-DA ( -- )   @RMM DUP 3 < IF  (Ev)
      C" FIADD FIMUL FICOM FICOMPFISUB FISUBRFIDIV FIDIVR" 6 .FLD
      ELSE DROP  OVER 3 < IF  .ST  0 .ST  ELSE  DROP  THEN
   C" FCMOVB FCMOVE FCMOVBEFCMOVU F?     FUCOMPPF?     F?     " 7 .FLD  THEN ;

: ESC-DB ( -- )   @RMM DUP 3 < IF  @REG 4 < IF  (Ev)  ELSE  Et  THEN
      C" FILD F?   FIST FISTPF?   FLD  F?   FSTP " 5 .FLD
      ELSE  DROP  OVER 4 = IF  NIP  CASE 2 OF  ." FCLEX"  ENDOF
         3 OF  ." FINIT"  ENDOF  ILLOP  ENDCASE  ELSE  .ST
         C" FCMOVNB FCMOVNE FCMOVNBEFCMOVNU F?      FUCOMI  FCOMI   F?      "
   8 .FLD  THEN THEN ;

: ESC-DC ( -- )   @RMM DUP 3 < IF  Eq .FALU  ELSE  DROP  OVER 2 4 WITHIN IF
   2DROP ILLOP  ELSE  0 .ST  .ST  DUP 3 > 1 AND XOR .FALU  THEN THEN ;

: ESC-DD ( -- )   @RMM  DUP 3 < IF  @REG 4 < IF  Eq  ELSE  (Ev)  THEN
      C" FLD   F?    FST   FSTP  FRSTORF?    FSAVE  FSTSW "  6 .FLD
      ELSE  DROP  OVER 4 = IF  0 .ST  THEN  .ST
   C" FFREE F?    FST   FSTP  FUCOM FUCOMPF?    ?F    "  6 .FLD  THEN ;

: ESC-DE ( -- )   @RMM DUP 3 < IF  Ew
      C" FIADD FIMUL FICOM FICOMPFISUB FISUBRFIDIV FIDIVR" 6 .FLD
      ELSE  DROP  0 .ST .ST
   C" FADDP FMULP F?    FCOMPPFSUBRPFSUBP FDIVRPFDIVP " 6 .FLD  THEN ;

: ESC-DF ( -- )   @RMM DUP 3 < IF  @REG 4 < IF  Ew  ELSE
      @REG 1 AND IF  Eq  ELSE  Ev  THEN THEN
      C" FILD F?   FIST FISTPFBLD FILD FBSTPFISTP" 5 .FLD
   ELSE  2DROP DROP ILLOP  THEN ;

{ ---------------------------------------------------------------------
Opcode map
--------------------------------------------------------------------- }

000 OPC:   Eb,Gb ." ADD" ;
001 OPC:   Ev,Gv ." ADD" ;
002 OPC:   Gb,Eb ." ADD" ;
003 OPC:   Gv,Ev ." ADD" ;
004 OPC:   Ib ." AL ADD" ;
005 OPC:   Iv ?E ." AX ADD" ;
006 OPC:   ." ES PUSH" ;
007 OPC:   ." ES POP" ;
008 OPC:   Eb,Gb ." OR" ;
009 OPC:   Ev,Gv ." OR" ;
00A OPC:   Gb,Eb ." OR" ;
00B OPC:   Gv,Ev ." OR" ;
00C OPC:   Ib ." AL OR" ;
00D OPC:   Iv ?E ." AX OR" ;
00E OPC:   ." CS PUSH" ;
00F OPC:   100 .OPCODE ;

010 OPC:   Eb,Gb ." ADC" ;
011 OPC:   Ev,Gv ." ADC" ;
012 OPC:   Gb,Eb ." ADC" ;
013 OPC:   Gv,Ev ." ADC" ;
014 OPC:   Ib ." AL ADC" ;
015 OPC:   Iv ?E ." AX ADC" ;
016 OPC:   ." SS PUSH" ;
017 OPC:   ." SS POP" ;
018 OPC:   Eb,Gb ." SBC" ;
019 OPC:   Ev,Gv ." SBC" ;
01A OPC:   Gb,Eb ." SBC" ;
01B OPC:   Gv,Ev ." SBC" ;
01C OPC:   Ib ." AL SBC" ;
01D OPC:   Iv ?E ." AX SBC" ;
01E OPC:   ." DS PUSH" ;
01F OPC:   ." DS POP" ;

020 OPC:   Eb,Gb ." AND" ;
021 OPC:   Ev,Gv ." AND" ;
022 OPC:   Gb,Eb ." AND" ;
023 OPC:   Gv,Ev ." AND" ;
024 OPC:   Ib ." AL AND" ;
025 OPC:   Iv ?E ." AX AND" ;
026 OPC:   ." ES: "  .CODE ;
027 OPC:   ." DAA" ;
028 OPC:   Eb,Gb ." SUB" ;
029 OPC:   Ev,Gv ." SUB" ;
02A OPC:   Gb,Eb ." SUB" ;
02B OPC:   Gv,Ev ." SUB" ;
02C OPC:   Ib ." AL SUB" ;
02D OPC:   Iv ?E ." AX SUB" ;
02E OPC:   ." CS: "  .CODE ;
02F OPC:   ." DAS" ;

030 OPC:   Eb,Gb ." XOR" ;
031 OPC:   Ev,Gv ." XOR" ;
032 OPC:   Gb,Eb ." XOR" ;
033 OPC:   Gv,Ev ." XOR" ;
034 OPC:   Ib ." AL XOR" ;
035 OPC:   Iv ?E ." AX XOR" ;
036 OPC:   ." ES: "  .CODE ;
037 OPC:   ." DAA" ;

038 OPC:   Eb,Gb ." CMP" ;
039 OPC:   Ev,Gv ." CMP" ;
03A OPC:   Gb,Eb ." CMP" ;
03B OPC:   Gv,Ev ." CMP" ;
03C OPC:   Ib ." AL CMP" ;
03D OPC:   Iv ?E ." AX CMP" ;
03E OPC:   ." DS: "  .CODE ;
03F OPC:   ." AAS" ;

040 OPC:   ?E ." AX INC" ;
041 OPC:   ?E ." CX INC" ;
042 OPC:   ?E ." DX INC" ;
043 OPC:   ?E ." BX INC" ;
044 OPC:   ?E ." SP INC" ;
045 OPC:   ?E ." BP INC" ;
046 OPC:   ?E ." SI INC" ;
047 OPC:   ?E ." DI INC" ;

048 OPC:   ?E ." AX DEC" ;
049 OPC:   ?E ." CX DEC" ;
04A OPC:   ?E ." DX DEC" ;
04B OPC:   ?E ." BX DEC" ;
04C OPC:   ?E ." SP DEC" ;
04D OPC:   ?E ." BP DEC" ;
04E OPC:   ?E ." SI DEC" ;
04F OPC:   ?E ." DI DEC" ;

050 OPC:   ?E ." AX PUSH" ;
051 OPC:   ?E ." CX PUSH" ;
052 OPC:   ?E ." DX PUSH" ;
053 OPC:   ?E ." BX PUSH" ;
054 OPC:   ?E ." SP PUSH" ;
055 OPC:   ?E ." BP PUSH" ;
056 OPC:   ?E ." SI PUSH" ;
057 OPC:   ?E ." DI PUSH" ;

058 OPC:   ?E ." AX POP" ;
059 OPC:   ?E ." CX POP" ;
05A OPC:   ?E ." DX POP" ;
05B OPC:   ?E ." BX POP" ;
05C OPC:   ?E ." SP POP" ;
05D OPC:   ?E ." BP POP" ;
05E OPC:   ?E ." SI POP" ;
05F OPC:   ?E ." DI POP" ;

060 OPC:   ." PUSHA" ?D ;
061 OPC:   ." POPA" ?D ;
062 OPC:   Gv,Ev ." BOUND" ;
063 OPC:   Ew,Gw ." ARPL" ;
064 OPC:   ." FS: "  .CODE ;
065 OPC:   ." GS: "  .CODE ;
066 OPC:   ?D16 ON  .CODE  ?D16 OFF ;
067 OPC:   ." A16:" ;

068 OPC:   Iv ." PUSH" ;
069 OPC:   Gv,Ev,Iv ." IMUL" ;
06A OPC:   Ib ." PUSH" ;
06B OPC:   Gv,Ev,Ib ." IMUL" ;
06C OPC:   ." DX INSB" ;
06D OPC:   ." DX INS"  ?W/D ;
06E OPC:   ." DX OUTSB" ;
06F OPC:   ." DX OUTS"  ?W/D ;

070 OPC:   Jb ." JO" ;
071 OPC:   Jb ." JNO" ;
072 OPC:   Jb ." JB" ;
073 OPC:   Jb ." JNB" ;
074 OPC:   Jb ." JZ" ;
075 OPC:   Jb ." JNZ" ;
076 OPC:   Jb ." JBE" ;
077 OPC:   Jb ." JNBE" ;

078 OPC:   Jb ." JS" ;
079 OPC:   Jb ." JNS" ;
07A OPC:   Jb ." JP" ;
07B OPC:   Jb ." JNP" ;
07C OPC:   Jb ." JL" ;
07D OPC:   Jb ." JNL" ;
07E OPC:   Jb ." JLE" ;
07F OPC:   Jb ." JNLE" ;

080 OPC:   Eb,Ib IMM1 ;
081 OPC:   Ev,Iv IMM1 ;
083 OPC:   Ev,Ib IMM1 ;
084 OPC:   Eb,Gb ." TEST" ;
085 OPC:   Ev,Gv ." TEST" ;
086 OPC:   Eb,Gb ." XCHG" ;
087 OPC:   Ev,Gv ." XCHG" ;

088 OPC:   Eb,Gb ." MOV" ;
089 OPC:   Ev,Gv ." MOV" ;
08A OPC:   Gb,Eb ." MOV" ;
08B OPC:   Gv,Ev ." MOV" ;
08C OPC:   Ew,Sw ." MOV" ;
08D OPC:   Gv,Ev ." LEA" ;
08E OPC:   Sw,Ew ." MOV" ;
08F OPC:   @MM Ev ." POP" ;

090 OPC:   ." NOP" ;
091 OPC:   ?E ." CX "  ?E ." AX XCHG" ;
092 OPC:   ?E ." DX "  ?E ." AX XCHG" ;
093 OPC:   ?E ." BX "  ?E ." AX XCHG" ;
094 OPC:   ?E ." SP "  ?E ." AX XCHG" ;
095 OPC:   ?E ." BP "  ?E ." AX XCHG" ;
096 OPC:   ?E ." SI "  ?E ." AX XCHG" ;
097 OPC:   ?E ." DI "  ?E ." AX XCHG" ;

098 OPC:   ." CBW" ;
099 OPC:   ?D16 @ IF  ." CWD"   ELSE  ." CDQ"  THEN ;
09B OPC:   ." WAIT" ;
09C OPC:   ." PUSHF" ;
09D OPC:   ." POPF" ;
09E OPC:   ." SAHF" ;
09F OPC:   ." LAHF" ;

0A0 OPC:   Offs ." AL MOV" ;
0A1 OPC:   Offs  ?E ." AX MOV" ;
0A2 OPC:   ." AL "  Offs  ." MOV" ;
0A3 OPC:   ?E ." AX "  Offs  ." MOV" ;
0A4 OPC:   ." MOVSB" ;
0A5 OPC:   ." MOVS"  ?W/D ;
0A6 OPC:   ." CMPSB" ;
0A7 OPC:   ." CMPS"  ?W/D ;

0A8 OPC:   Ib ." AL TEST" ;
0A9 OPC:   Iv ?E ." AX TEST" ;
0AA OPC:   ." STOSB" ;
0AB OPC:   ." STOS"  ?W/D ;
0AC OPC:   ." LODSB" ;
0AD OPC:   ." LODS"  ?W/D ;
0AE OPC:   ." SCASB" ;
0AF OPC:   ." SCAS"  ?W/D ;

0B0 OPC:   Ib ." AL MOV" ;
0B1 OPC:   Ib ." CL MOV" ;
0B2 OPC:   Ib ." DL MOV" ;
0B3 OPC:   Ib ." BL MOV" ;
0B4 OPC:   Ib ." AH MOV" ;
0B5 OPC:   Ib ." CH MOV" ;
0B6 OPC:   Ib ." DH MOV" ;
0B7 OPC:   Ib ." BH MOV" ;

0B8 OPC:   Iv ?E ." AX MOV" ;
0B9 OPC:   Iv ?E ." CX MOV" ;
0BA OPC:   Iv ?E ." DX MOV" ;
0BB OPC:   Iv ?E ." BX MOV" ;
0BC OPC:   Iv ?E ." SP MOV" ;
0BD OPC:   Iv ?E ." BP MOV" ;
0BE OPC:   Iv ?E ." SI MOV" ;
0BF OPC:   Iv ?E ." DI MOV" ;

0C0 OPC:   @MM Eb Ib SH2 ;
0C1 OPC:   @MM Ev Ib SH2 ;
0C2 OPC:   Iw ." RET"  ?LIMIT ;
0C3 OPC:   ." RET"  ?LIMIT ;
0C4 OPC:   Gv,Ev ." LES" ;
0C5 OPC:   Gv,Ev ." LDS" ;
0C6 OPC:   Eb,Ib ." MOV" ;
0C7 OPC:   Ev,Iv ." MOV" ;

0CC OPC:   ." 3 INT" ;
0CD OPC:   IC@ . ." INT" ;
0CE OPC:   ." INTO" ;
0CF OPC:   ." IRET" ;

0D0 OPC:   @MM Eb SH2 ;
0D1 OPC:   @MM Ev SH2 ;
0D2 OPC:   @MM Eb ." CL " SH2 ;
0D3 OPC:   @MM Ev ." CL " SH2 ;
0D4 OPC:   ." AAM" ;
0D5 OPC:   ." AAD" ;
0D7 OPC:   ." XLAT" ;

0D8 OPC:   ESC-D8 ;
0D9 OPC:   ESC-D9 ;
0DA OPC:   ESC-DA ;
0DB OPC:   ESC-DB ;
0DC OPC:   ESC-DC ;
0DD OPC:   ESC-DD ;
0DE OPC:   ESC-DE ;
0DF OPC:   ESC-DF ;

0E0 OPC:   Jb ." LOOPN" ;
0E1 OPC:   Jb ." LOOPE" ;
0E2 OPC:   Jb ." LOOP" ;
0E3 OPC:   Jb ." J" ?E ." CXZ" ;
0E4 OPC:   Ib ." AL IN" ;
0E5 OPC:   Ib ?E ." AX IN" ;
0E6 OPC:   ." AL "  Ib  ." OUT" ;
0E7 OPC:   ?E ." AX " Ib ." OUT" ;

0E8 OPC:   Jv ." CALL" ;
0E9 OPC:   Jv ." JMP"  ?LIMIT ;
0EB OPC:   Jb ." JMP"  ?LIMIT ;
0EC OPC:   ." DX AL IN" ;
0ED OPC:   ." DX "  ?E ." AX IN" ;
0EE OPC:   ." AL DX OUT" ;
0EF OPC:   ?E ." AX DX OUT" ;

0F0 OPC:   ." LOCK" ;
0F2 OPC:   ." REPNE "  .CODE ;
0F3 OPC:   ." REPE "  .CODE ;
0F4 OPC:   ." HLT" ;
0F5 OPC:   ." CMC" ;
0F6 OPC:   UN3B ;
0F7 OPC:   UN3 ;

0F8 OPC:   ." CLC" ;
0F9 OPC:   ." STC" ;
0FA OPC:   ." CLI" ;
0FB OPC:   ." STI" ;
0FC OPC:   ." CLD" ;
0FD OPC:   ." STD" ;
0FE OPC:   @MM Eb ID4 ;
0FF OPC:   @MM Ev ID5 ;

180 OPC:   Jv ." JO" ;
181 OPC:   Jv ." JNO" ;
182 OPC:   Jv ." JB" ;
183 OPC:   Jv ." JNB" ;
184 OPC:   Jv ." JZ" ;
185 OPC:   Jv ." JNZ" ;
186 OPC:   Jv ." JBE" ;
187 OPC:   Jv ." JNBE" ;

188 OPC:   Jv ." JS" ;
189 OPC:   Jv ." JNS" ;
18A OPC:   Jv ." JP" ;
18B OPC:   Jv ." JNP" ;
18C OPC:   Jv ." JL" ;
18D OPC:   Jv ." JNL" ;
18E OPC:   Jv ." JLE" ;
18F OPC:   Jv ." JNLE" ;

190 OPC:   @MM Eb  ." SETO" ;
191 OPC:   @MM Eb  ." SETNO" ;
192 OPC:   @MM Eb  ." SETC" ;           \ SETB, SETNAE
193 OPC:   @MM Eb  ." SETNC" ;          \ SETNB, SETAE
194 OPC:   @MM Eb  ." SETZ" ;           \ SETE
195 OPC:   @MM Eb  ." SETNZ" ;          \ SETNE
196 OPC:   @MM Eb  ." SETBE" ;          \ SETNA
197 OPC:   @MM Eb  ." SETA" ;           \ SETNBE
198 OPC:   @MM Eb  ." SETS" ;
199 OPC:   @MM Eb  ." SETNS" ;
19A OPC:   @MM Eb  ." SETPE" ;          \ SETP
19B OPC:   @MM Eb  ." SETPO" ;          \ SETNP
19C OPC:   @MM Eb  ." SETL" ;           \ SETNGE
19D OPC:   @MM Eb  ." SETGE" ;          \ SETNL
19E OPC:   @MM Eb  ." SETLE" ;          \ SETNG
19F OPC:   @MM Eb  ." SETG" ;           \ SETNLE

1A0 OPC:   ." FS PUSH" ;
1A1 OPC:   ." FS POP" ;
1A8 OPC:   ." GS PUSH" ;
1A9 OPC:   ." GS POP" ;

1B1 OPC:   Gv,Ev ." CMPXCHG" ;
1B2 OPC:   Gv,Ev ." LSS" ;
1B3 OPC:   Ev,Gv ." BTR" ;
1B4 OPC:   Gv,Ev ." LFS" ;
1B5 OPC:   Gv,Ev ." LGS" ;
1B6 OPC:   Gv,Eb ." MOVZX" ;
1B7 OPC:   Gv,Ew ." MOVZXW" ;
1BC OPC:   Gv,Ev ." BSF" ;
1BD OPC:   Gv,Ev ." BSR" ;
1BE OPC:   Gv,Eb ." MOVSX" ;
1BF OPC:   Gv,Ew ." MOVSXW" ;

DECIMAL

{ ---------------------------------------------------------------------
Disassembler access

DASM disassembles starting at address a.
SEE disassembles the code field of the next name in the input stream.
--------------------------------------------------------------------- }

PUBLIC

: DASM ( addr -- )   ['] .CODE IS .DECODE
   ?D16 OFF  DECODE ;

: SEE ( "name" -- )   ' >CODE DASM ;

: MORE ( -- )   >IP @ DASM ;

{ ---------------------------------------------------------------------
Decoding extensions

.STRING displays an in-line compiled string.  This is the .DATA action
for compiled strings.
--------------------------------------------------------------------- }

PRIVATE

: .STRING   ?WHERE  [CHAR] " EMIT  IC@ 0 ?DO  IC@ EMIT  LOOP
   [CHAR] " EMIT  1 >IP +! ;

: .INLINE-XT   ?WHERE I@ >CODE .' ;

DECODE: (S") .STRING
DECODE: (C") .STRING
DECODE: (Z") .STRING

: .SINGLE   ?WHERE  I@ DUP . DUP 0< IF  DUP U.  THEN DROP  ?LIMIT ;
: .DOUBLE   ?WHERE  I@ I@ SWAP D.  ?LIMIT ;

: .DEFER ( -- )   CR CR  I@ >CODE DUP .'
   DUP >IP !  DUP >START !  >LIMIT ! ;

DECODE: (USER) .SINGLE
DECODE: (CONSTANT) .SINGLE
DECODE: (VALUE) .SINGLE
DECODE: (2CONSTANT) .DOUBLE
DECODE: (DEFER) .DEFER

: .PFA ( -- )   ?WHERE  ." [PFA] "  ?LIMIT ;
DECODE: (CREATE) .PFA

END-PACKAGE
