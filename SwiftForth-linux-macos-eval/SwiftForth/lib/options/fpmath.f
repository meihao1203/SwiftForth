{ ====================================================================
Floating point math

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL FPMATH Floating point math package

{ --------------------------------------------------------------------
The following illustrates examples of integer and real (floating-
point) numbers.  A number is considered to be floating point when a
numeric string contains a decimal place and an E.  The numeric string
is scanned before conversion and if the number is floating point it is
converted directly on the hardware stack (i.e., the NDP coprocessor's
internal 80-bit hardware stack) and then transfered to the numeric
stack.

The general form of a floating point number is:
   [+/-]digits.[digits]E[+/-]exponent

Note that digits following the decimal point are optional.  The
exponent and plus signs are also optional.

INTEGER numbers are placed on the parameter stack

      ( Singles)   37   -1000
      ( Doubles)   43.   -1,000.   3:45   2,345   6/14/82   +9

FLOATING POINT numbers are placed on the numeric stack

     0.2E  1.0E  -2.3E  +345.0E  12E12  12.5E12  -12.5E-12
     2.E  5.E78  +47.E+09  +1000.E+300  2000.5E  +100.E-34
     1000E  89E+0  +19999999999999999.9E

For more information concerning the details of the operation and
accuracy of the NDP consult either of the following Intel manuals:

     1)  80386 Programmer's Reference Manual, #230985
     2)  NDP Programmer's Reference Manual, #231917

These manuals and additional information may be obtained from:
         Intel Corporation
         Literature Department
         P.O. Box 58130
         Santa Clara, CA  95052-8130    800/548-4725

-------------------------------------------------------------------- }

REQUIRES fpconfig

DECIMAL  ONLY FORTH ALSO DEFINITIONS

{ --------------------------------------------------------------------
Floating point debug options

FPDEBUG is only defined if the option to WAIT on exceptions is
checked.

Use this version of FNEXT and vector 'FBUG to something useful if you
need to debug floating point code.

VARIABLE 'FBUG

: FBUG   'FBUG @EXECUTE ;

ONLY FORTH ALSO ASSEMBLER ALSO DEFINITIONS FORTH

: FNEXT
   ['] FBUG >CODE CALL
   RET END-CODE ;

-------------------------------------------------------------------- }

'FPOPT 1+ C@ [IF] : FPDEBUG ; [THEN]

ASSEMBLER

: FNEXT ( -- )   [DEFINED] FPDEBUG [IF]  WAIT  [THEN]
   RET  END-CODE ;

FORTH

{ --------------------------------------------------------------------
Floating point initialization

/FSTACK resets the numeric stack pointer.

/NDP initializes the NDP.  It sets the Control Register to the
value saved in the floating point options registry settings.

-------------------------------------------------------------------- }

CODE /FSTACK
   'N0 [U] EAX MOV  EAX 'N [U] MOV
   RET END-CODE

CODE (/NDP)
   FINIT  'FPOPT 2+ EDX ADDR  0 [EDX] FLDCW
   ' /FSTACK >CODE JMP
   END-CODE

' (/NDP) IS /NDP   /NDP

{ --------------------------------------------------------------------
Optional numeric stack control

NUMERICS is only defined if the software floating point stack is being
used.

NDP is a facility variable to control access to the NDP's hardware
stack.  Access to the NDP must be controlled if the NUMERICS option is
not defined.

<<F and F>> can be used to control task access to the NDP.  They are
compile time no-ops if NUMERICS is defined.

-------------------------------------------------------------------- }

'FPOPT C@ [IF] : NUMERICS ; [THEN]

VARIABLE NDP

: <<F ( -- )   [UNDEFINED] NUMERICS [IF]
      NDP GET  [THEN] ;
[DEFINED] NUMERICS [IF]  IMMEDIATE  [THEN]

: F>> ( -- )   [UNDEFINED] NUMERICS [IF]
      NDP RELEASE  [THEN] ;
[DEFINED] NUMERICS [IF]  IMMEDIATE  [THEN]

{ --------------------------------------------------------------------
Numeric stack

There is a pre-allocated 32-item floating point stack in the task's
user area already defined in Kernel\Header.f, so we only need to begin
using it here. The other words are provided for convenience.

|NUMERIC| width of each numeric stack item in bytes.

#NS is the number of floating point items in the stack.

@FSTS returns the NDP status in TOS.

FSTACK allocates n elements to the numeric stack for the current task.
The stack is also initialized to empty.

FDEPTH returns the number of items on the numeric stack. It can do
this even if the numeric stack is not installed.

?FSTACK  checks for numeric stack error, aborts if there is nothing on
the numeric stack or if there are too many items on the stack.  One
item is always reserved at the top of the stack for display
conversion.

?FPRINT aborts if there is not at least one item on the floating point
stack. This makes printing floating point numbers much more robust.
-------------------------------------------------------------------- }

10 CONSTANT |NUMERIC|
32 CONSTANT #NS

CODE @FSTS ( -- n )
   4 # EBP SUB
   EBX 0 [EBP] MOV
   0 # PUSH
   0 [ESP] FSTSW
   EBX POP
   RET END-CODE

: FSTACK ( n -- )   [DEFINED] NUMERICS [IF]
      |NUMERIC| * ALLOT  HERE 'N0 !  /FSTACK
   [ELSE]  DROP  [THEN] ;

: ?FPERR ( flag -- )
   -EXIT  /NDP  -1 ABORT" Numeric stack error" ;

: ?FPSTACK ( -- )
   @FSTS $40 AND ?FPERR ;

: FDEPTH ( -- n )   [DEFINED] NUMERICS [IF]
      'N0 @ 'N @ - |NUMERIC| /
   [ELSE]  ?FPSTACK 8 @FSTS 2048 / 7 AND - 8 MOD  [THEN] ;

: ?FSTACK ( -- )
   FDEPTH 0 #NS 1+ WITHIN  ?EXIT
   /FSTACK  1 ?FPERR ;

:NONAME ( -- )
   [ ' ?STACK >BODY @ ] LITERAL EXECUTE ?FSTACK ; IS ?STACK


: ?FPRINT ( -- )
   ?FSTACK  FDEPTH 0= ABORT" No floating point number to print" ;

{ --------------------------------------------------------------------
Numeric stack manipulation

These are assembler macros that transfer data to and from the NDP
numeric stack and the software supported numeric stack if the stack is
installed.  Otherwise, they are merely compile time no-ops.

>f  assembler macro to transfer one stack item to NDP.
f>  assembler macro to transfer one stack item from NDP.

>fs  assembler macro to transfer  n  stack items to NDP.
fs>  assembler macro to transfer  n  stack items from NDP.

-------------------------------------------------------------------- }

ALSO ASSEMBLER DEFINITIONS

: >f ( -- )   [DEFINED] NUMERICS [IF]
      'N [U] EAX MOV  0 [EAX] TBYTE FLD
      |NUMERIC| # 'N [U] ADD  [THEN] ;

: f> ( -- )   [DEFINED] NUMERICS [IF]
      |NUMERIC| # 'N [U] SUB  'N [U] EAX MOV
      0 [EAX] TBYTE FSTP  [THEN] ;

: >fs ( n -- )   [DEFINED] NUMERICS [IF]
      DUP ( n) |NUMERIC| * # 'N [U] ADD
      'N [U] EAX MOV
      ( n) # ECX MOV
      HERE
         |NUMERIC| # EAX SUB
         0 [EAX] TBYTE FLD
   LOOP  [ELSE]  DROP  [THEN] ;

: fs> ( n -- )   [DEFINED] NUMERICS [IF]
      DUP ( n) |NUMERIC| * # 'N [U] SUB
      'N [U] EAX MOV
      ( n) # ECX MOV
      HERE
         0 [EAX] TBYTE FSTP
         |NUMERIC| # EAX ADD
   LOOP  [ELSE]  DROP  [THEN] ;

PREVIOUS DEFINITIONS

{ --------------------------------------------------------------------
FPU Control Word

            Invalid Operation  Bit on means exception is disabled
        Denormalized Operand|
                Zero Divide||
                  Overflow|||
                Underflow||||
               Precision|||||
    Precision Control  ||||||  00=24 Bits, 10=53 Bits, 11=64 Bits
   Rounding Control |  ||||||  00=nearest, 01=down, 10=up, 11=truncate
 Infinity Control | |  ||||||  (not meaningful on 387, 486 or Pentium)
                | | |  ||||||
             ---XRCPC--PUOZDI

-------------------------------------------------------------------- }
CREATE FP-ROUND
BINARY             1100110010 H, \ ROUND
                  11100110010 H, \ FLOOR
                 101100110010 H, \ ROUND-UP
                 111100110010 H, \ TRUNCATE
DECIMAL

{ --------------------------------------------------------------------
Rounding

The ANS default is to truncate. Commands are provided to temporarily
switch to ROUND (round-to-nearest, and at the boundary round to even,
ROUND-UP (to the right, -1.5 would round to -1), FLOOR (to the left
1.5 rounds to 1 and -1.5 rounds to -2) or to TRUNCATE.  The original
state is restored immediately after use to preserve exception states,
etc.

Note that rounding operations are always done with the default
precision and exception masking.  These can be changed by adjusting
the values in FP-ROUND .

The MAKE-<name> version will set the rounding behavior more
permanently.  However, this change is not recorded in the floating
point options registry entry.

-------------------------------------------------------------------- }

LABEL ROUNDING
   FP-ROUND EAX ADDR
   EAX EDX ADD                  \ and address of interest in eax
   4 # EBP SUB                  \ room for holding status
   >f                           \ move float to ndp
   0 [EBP] FNSTCW               \ save old rounding
   0 [EDX] FLDCW                \ write new rounding
   FRNDINT                      \ integerfy
   0 [EBP] FLDCW                \ restore old
   f>
   4 # EBP ADD
   FNEXT

CODE ROUND      0 # EDX MOV   ROUNDING JMP END-CODE
CODE FLOOR      2 # EDX MOV   ROUNDING JMP END-CODE
CODE ROUND-UP   4 # EDX MOV   ROUNDING JMP END-CODE
CODE TRUNCATE   6 # EDX MOV   ROUNDING JMP END-CODE

CODE MAKE-ROUND
   FP-ROUND EAX ADDR
   0 [EAX] FLDCW
   FNEXT

CODE MAKE-FLOOR
   FP-ROUND EAX ADDR
   2 [EAX] FLDCW
   FNEXT

CODE MAKE-ROUND-UP
   FP-ROUND EAX ADDR
   4 [EAX] FLDCW
   FNEXT

CODE MAKE-TRUNCATE
   FP-ROUND EAX ADDR
   6 [EAX] FLDCW
   FNEXT

{ --------------------------------------------------------------------
Stack operators

These are the code definitions that correspond to the parameter stack
operators on the numeric stack.

S>F transfers a 32-bit integer from the top of the parameter stack to
the top of the numeric stack.

F>S rounds the number on the top of the numeric stack to a 32-bit
integer and transfers it to the parameter stack.

D>F same as S>F except it is a 64-bit operation.
F>D same as F>S except it is a 64-bit operation.

-------------------------------------------------------------------- }

CODE FSWAP ( -- ) ( r r -- r r )
   2 >fs   ST(1) FXCH   2 fs>   FNEXT

CODE FDUP ( -- ) ( r -- r r )
   >f  ST(0) FLD   2 fs>   FNEXT

CODE F2DUP ( -- ) ( r r -- r r r r )
   2 >fs   ST(1) FLD  ST(1) FLD   4 fs>
   FNEXT

CODE FOVER ( -- ) ( r r -- r r r )
   2 >fs   ST(1) FLD   3 fs>   FNEXT

CODE FDROP ( -- ) ( r -- )
   >f   ST(0) FSTP   FNEXT

CODE FROT ( -- ) ( r r r -- r r r )
   3 >fs   ST(1) FXCH   ST(2) FXCH  3 fs>   FNEXT

CODE S>F ( n -- ) ( -- r )
   0 [EBP] EBX XCHG  0 [EBP] DWORD FILD  4 # EBP ADD  f>  FNEXT

CODE D>F ( d -- ) ( -- r )
   4 [EBP] EBX XCHG   0 [EBP] QWORD FILD  8 # EBP ADD  f>  FNEXT

CODE (F>S) ( -- n ) ( r -- )
   >f  4 # EBP SUB  0 [EBP] DWORD FISTP  0 [EBP] EBX XCHG  FNEXT

CODE (F>D) ( -- d ) ( r -- )
   >f  8 # EBP SUB  0 [EBP] QWORD FISTP  4 [EBP] EBX XCHG  FNEXT

: F>D ( -- d ) ( r -- )   TRUNCATE (F>D) ;
: F>S ( -- n ) ( r -- )   TRUNCATE (F>S) ;

{ --------------------------------------------------------------------
Arithmetic

This is the high-level interface to the NDP numeric stack for
arithmetic functions.

Note that the second set of stack comments give the input-output
function on the numeric stack.

-------------------------------------------------------------------- }

CODE F+ ( -- ) ( r r -- r )   2 >fs   FADDP   f>   FNEXT
CODE F- ( -- ) ( r r -- r )   2 >fs   FSUBP   f>   FNEXT
CODE F* ( -- ) ( r r -- r )   2 >fs   FMULP   f>   FNEXT
CODE F/ ( -- ) ( r r -- r )   2 >fs   FDIVP   f>   FNEXT

CODE FSQRT ( -- ) ( r -- r )   >f   FSQRT   f>   FNEXT
CODE FABS ( -- ) ( r -- r )   >f   FABS   f>   FNEXT
CODE FNEGATE ( -- ) ( r -- r )   >f   FCHS   f>   FNEXT
CODE Extract ( -- ) ( r -- x s )   >f   FXTRACT   2 fs>   FNEXT

CODE FATAN ( -- ) ( r1 -- r2 )   >f   FLD1  FPATAN   f>   FNEXT
CODE FATAN2 ( -- ) ( y x -- r )   2 >fs   FPATAN   f>   FNEXT
CODE 2**X-1 ( -- ) ( x -- r )   >f   F2XM1   f>   FNEXT
CODE Y*LOG2(X) ( -- ) ( y x -- r )   2 >fs   FYL2X   f>   FNEXT
CODE Y*LOG2(X+1) ( -- ) ( y x -- r )   2 >fs   FYL2XP1   f>   FNEXT
CODE FROUND ( -- ) ( r -- r )   >f   FRNDINT   f>   FNEXT
CODE 1/N ( -- ) ( x -- r )   >f   FLD1   FDIVRP  f>   FNEXT

{ --------------------------------------------------------------------
Constants

These words provide definitions of two types of real constants. The
first group defines words that access constants which are actually NDP
opcodes.

FINTEGER is a defining word that creates real numeric constants; in this
case the real constants are integers and are loaded directly on the
numeric stack when executed.

-------------------------------------------------------------------- }

CODE #0.0E ( -- ) ( -- r )   FLDZ   f>   FNEXT
CODE #1.0E ( -- ) ( -- r )   FLD1   f>   FNEXT
CODE PI ( -- ) ( -- r )   FLDPI  f>   FNEXT
CODE LN2 ( -- ) ( -- r )   FLDLN2 f>   FNEXT

CODE LOG2(E) ( -- ) ( -- r )   FLDL2E   f>   FNEXT
CODE LOG2(10) ( -- ) ( -- r )   FLDL2T   f>   FNEXT
CODE LOG10(2) ( -- ) ( -- r )   FLDLG2   f>   FNEXT

: FINTEGER ( n -- )  \ Usage: n FINTEGER <name>
   CREATE ( n) ,
   ;CODE
      EAX POP   0 [EAX] DWORD FILD  f>  FNEXT

-1 FINTEGER #-1.0E
-2 FINTEGER #-2.0E
 2 FINTEGER #2.0E
10 FINTEGER #10.0E

{ --------------------------------------------------------------------
Conditionals

These words correspond to the parameter stack conditional tests.  Note
that the flag left by the numeric stack test is returned to the
parameter stack.  This is a requirement for Forth conditionals ( IF ,
WHILE , UNTIL , etc.)

F?DUP tests the top of the numeric stack for non-zero; if non-zero,
the number is left and a true flag is placed on the parameter stack;
if the number is zero, it is popped and a false flag is placed on the
parameter stack.

-------------------------------------------------------------------- }

LABEL FTESTRES
      4 # EBP SUB       \ make room
      EBX 0 [EBP] MOV
      EBX EBX SUB       \ and a zero
      ECX POP           \ address of test value
      FSTSWAX           \ move ndp status word to ax
      $4100 # EAX AND
      0 [ECX] EAX CMP
      0= IF
         EBX DEC
      THEN
      RET END-CODE

: FUNARY ( cc -- )      \ Usage: nn FUNARY <name>
   CREATE ,
   ;CODE
      >f                \ push to ndp
      FTST              \ test value against zero
      ST(0) FSTP        \ and drop the value
      FTESTRES JMP
      END-CODE

: FBINARY ( cc -- )     \ Usage: nn FBINARY <name>
   CREATE ,
   ;CODE
      2 >fs             \ push values to ndp
      FCOMPP            \ compare two, pop both
      FTESTRES JMP
      END-CODE

$4000 FUNARY F0= ( -- flag )  ( r -- )
$0100 FUNARY F0< ( -- flag )  ( r -- )
$0000 FUNARY F0> ( -- flag )  ( r -- )

$4000 FBINARY F= ( -- flag )  ( r r -- )
$0100 FBINARY F> ( -- flag )  ( r r -- )
$0000 FBINARY F< ( -- flag )  ( r r -- )

: FMIN ( -- ) ( r r -- r )   F2DUP F>  IF  FSWAP  THEN  FDROP ;
: FMAX ( -- ) ( r r -- r )   F2DUP F<  IF  FSWAP  THEN  FDROP ;
: FWITHIN ( - t) ( n l h -- )   FROT  FDUP FROT F<  F2DUP F<
   F= OR  AND ;
: F?DUP ( -- t ) ( r -- , r )   FDUP F0= DUP  IF  FDROP  THEN  0= ;

{ --------------------------------------------------------------------
Floating point similarity

Three tests are provided; the switch is in the top item.

If it is zero, the next two items are tested bitwise, and fail if any
bit is different.

If it is positive, the difference between the next two numbers is
compared to the third number; an absolute test.

If the top number is negative, a relative comparison is made.

-------------------------------------------------------------------- }

: F~ ( -- t ) ( r r r -- )
   F?DUP IF
      FDUP  F0<  IF
         FABS FROT FROT F2DUP F- FABS    ( |r3 r1 r2 |r1-r2 )
         FROT FABS  FROT FABS F+ FROT F* ( |r1-r2 |r1+|r2 *|r3 )
         F<
      ELSE
         FROT FROT F- FABS               ( r3 |r1-r2 )
         F>
      THEN
   ELSE
      F=
   THEN ;

{ --------------------------------------------------------------------
Memory reference operators

SF! 32-bit real store to the parameter stack address.
DF! 64-bit real store to the parameter stack address.
SF@ 32-bit real fetch from the parameter stack address.
DF@ 64-bit real fetch from the parameter stack address.

SF, 32-bit real comma.
DF, 64-bit real comma.

SF+! 32-bit real plus store.
DF+! 64-bit real plus store.

The default floating point operators are defined as aliases of the
64-bit routines.

-------------------------------------------------------------------- }

CODE SF! ( a -- ) ( r -- )
   >f   0 [EBX] DWORD FSTP
   0 [EBP] EBX MOV  4 # EBP ADD
   FNEXT

CODE SF@ ( a -- ) ( -- r )
   0 [EBX] DWORD FLD
   0 [EBP] EBX MOV  4 # EBP ADD
   f> FNEXT

CODE DF! ( a -- ) ( r -- )
   >f   0 [EBX] QWORD FSTP
   0 [EBP] EBX MOV  4 # EBP ADD
   FNEXT

CODE DF@ ( a -- ) ( -- r )
   0 [EBX] QWORD FLD
   0 [EBP] EBX MOV  4 # EBP ADD
   f> FNEXT

: SF, ( -- ) ( r -- )   HERE  4 ALLOT  SF! ;
: DF, ( -- ) ( r -- )   HERE  8 ALLOT  DF! ;

CODE SF+! ( a -- ) ( r -- )
   >f
   0 [EBX] DWORD FADD
   0 [EBX] DWORD FSTP
   0 [EBP] EBX MOV  4 # EBP ADD
   FNEXT

CODE DF+! ( a -- ) ( r -- )
   >f
   0 [EBX] QWORD FADD
   0 [EBX] QWORD FSTP
   0 [EBP] EBX MOV  4 # EBP ADD
   FNEXT

AKA DF!  F!
AKA DF@  F@
AKA DF+! F+!
AKA DF,  F,

{ --------------------------------------------------------------------
Variables and constants

SFVARIABLE creates a 32-bit real variable.
DFVARIABLE creates a 64-bit real variable.

SFCONSTANT creates a 32-bit real constant.
DFCONSTANT creates a 64-bit real constant.

FVARIABLE creates a DFVARIABLE.
FCONSTANT creates a DFCONSTANT.

F2* multiplies the top N-Stack value by 2.0 .
F2/ divides the top N-Stack value by 2.0 .

-------------------------------------------------------------------- }

: SFVARIABLE   CREATE  #0.0E SF, ;   \ Usage: SFVARIABLE <name>
: DFVARIABLE   CREATE  #0.0E DF, ;   \ Usage: DFVARIABLE <name>

: SFCONSTANT ( -- ) ( r -- ) \ Usage: r SFCONSTANT <name>
   CREATE  SF,
   ;CODE ( -- addr )
      EAX POP  0 [EAX] DWORD FLD   f> FNEXT


: DFCONSTANT ( -- ) ( r -- ) \ Usage: r DFCONSTANT <name>
   CREATE  DF,
   ;CODE ( -- addr )
      EAX POP  0 [EAX] QWORD FLD   f> FNEXT

AKA DFVARIABLE FVARIABLE
AKA DFCONSTANT FCONSTANT

CODE F2* ( r -- 2r )
   >f   ST(0) ST(0) FADD   f>   FNEXT

CODE F2/ ( r -- r/2 )
   >f
   ' #2.0E >BODY EAX ADDR
   0 [EAX] DWORD FIDIV
   f>   FNEXT

{ --------------------------------------------------------------------
Values

FVALUE defines a floating point value.
TO is extended to handle words defined by FVALUE.
-------------------------------------------------------------------- }

CODE (FVALUE) ( -- ) ( -- r )
      EAX POP  0 [EAX] QWORD FLD   f> FNEXT

: FVALUE ( -- ) ( r -- )
   HEADER  POSTPONE (FVALUE)  DF, ;

: >BODYF! ( n xt -- )   >BODY F! ;
: >BODYF+! ( n xt -- )   >BODY F+! ;

: (FTO) ( xt -- )
   STATE @ IF  POSTPONE LITERAL  POSTPONE >BODYF!  EXIT  THEN   >BODYF! ;

: (F+TO) ( xt -- )
   STATE @ IF  POSTPONE LITERAL  POSTPONE >BODYF+!  EXIT  THEN   >BODYF+! ;

: TO-FVALUE ( -- flag )   >IN @ >R  '
   DUP PARENT ['] (FVALUE) = IF  (FTO)  R> DROP  -1
   ELSE  DROP  R> >IN !  0  THEN ;

: +TO-FVALUE ( -- flag )   >IN @ >R  '
   DUP PARENT ['] (FVALUE) = IF  (F+TO)  R> DROP  -1
   ELSE  DROP  R> >IN !  0  THEN ;

-? : TO ( n -- )
   LOBJ-COMP TO-LOCAL ?EXIT    \ local object
   LVAR-COMP TO-LOCAL ?EXIT    \ local variable
             TO-VALUE ?EXIT    \ VALUE
             TO-FVALUE ?EXIT   \ FVALUE
   1 'METHOD ! ; IMMEDIATE     \ SINGLE

-? : +TO ( n -- )
   LOBJ-COMP +TO-LOCAL ?EXIT
   LVAR-COMP +TO-LOCAL ?EXIT
             +TO-VALUE ?EXIT
             +TO-FVALUE ?EXIT
   2 'METHOD ! ; IMMEDIATE

{ --------------------------------------------------------------------
Literals

ieee32 pushes a 32-bit literal onto the floating point stack.
ieee64 pushes a 64-bit literal onto the floating point stack.

SFLITERAL compiles an in-line 32-bit real literal.
DFLITERAL compiles an in-line 64-bit real literal.
-------------------------------------------------------------------- }

CODE ieee32 ( -- ) ( -- r )
   EAX POP
   0 [EAX] DWORD FLD
   4 # EAX ADD
   EAX PUSH
   f>
   FNEXT

CODE ieee64 ( -- ) ( -- r )
   EAX POP
   0 [EAX] QWORD FLD
   8 # EAX ADD
   EAX PUSH
   f>
   FNEXT

: SFLITERAL ( -- ) ( r -- )
   POSTPONE ieee32 SF, ; IMMEDIATE

: DFLITERAL ( -- ) ( r -- )
   POSTPONE ieee64 DF, ; IMMEDIATE

AKA DFLITERAL FLITERAL IMMEDIATE

{ ---------------------------------------------------------------------
Decoding extensions
--------------------------------------------------------------------- }

: .ieee ( n )   SPACE  0 DO  1 +IP C@ 2 H.0  LOOP ;
: .ieee32   4 .ieee ;
: .ieee64   8 .ieee ;

DECODE: ieee32 .ieee32
DECODE: ieee64 .ieee64

{ --------------------------------------------------------------------
Integers

This is code for compiling real numbers as integers. This allows
compilation of integers that are loaded directly on the numeric stack
when the definition is executed. The integer form also requires less
memory and is faster.

SFI!  16-bit integer store to the parameter stack address.
DFI!  32-bit integer store to the parameter stack address.
SFI@  16-bit integer fetch from the parameter stack address.
DFI@  32-bit integer fetch from the parameter stack address.

SFI,  16-bit integer comma.
DFI,  32-bit integer comma.

FILITERAL compiles a real number as either a 32-bit integer
or a 64-bit integer literal, whichever will fit.  At run-time it
will be put on the stack as a real number.

-------------------------------------------------------------------- }

CODE SFI! ( a -- ) ( r -- )
   >f
   0 [EBX] DWORD FISTP
   POP(EBX)
   FNEXT

CODE DFI! ( a -- ) ( r -- )
   >f
   0 [EBX] QWORD FISTP
   POP(EBX)
   FNEXT

CODE SFI@ ( a -- ) ( -- r )
   0 [EBX] DWORD FILD
   f>
   POP(EBX)
   FNEXT

CODE DFI@ ( a -- ) ( -- r )
   0 [EBX] QWORD FILD
   f>
   POP(EBX)
   FNEXT

: SFI, ( r -- )   HERE  4 ALLOT  SFI! ;
: DFI, ( r -- )   HERE  8 ALLOT  DFI! ;

AKA DFI! FI!
AKA DFI@ FI@
AKA DFI, FI,

{ --------------------------------------------------------------------
Integer literals

ieee32i pushes a 32-bit integer literal.
ieee64i pushes a 64-bit integer literal.

FILITERAL sets the numeric conversion vector for floating integers.

-------------------------------------------------------------------- }

CODE ieee32i ( -- ) ( -- r )
   EAX POP
   0 [EAX] DWORD FILD
   4 # EAX ADD
   EAX PUSH
   f>
   FNEXT

CODE ieee64i ( -- ) ( -- r )
   EAX POP
   0 [EAX] QWORD FILD
   8 # EAX ADD
   EAX PUSH
   f>
   FNEXT

: FILITERAL ( r -- )
   FDUP FABS
   $7FFFFFFF S>F F> IF
      POSTPONE ieee64i DFI,
   ELSE  POSTPONE ieee32i SFI,
   THEN ; IMMEDIATE

{ --------------------------------------------------------------------
Alignment words

These words adjust the alignment of addresses for real numbers. They
are used for array indexing, etc.

-------------------------------------------------------------------- }

AKA CELLS SFLOATS
AKA CELL+ SFLOAT+

: DFLOATS ( n -- n' )   8 * ;
: DFLOAT+ ( n -- n' )   8 + ;

AKA DFLOATS FLOATS
AKA DFLOAT+ FLOAT+

: DFALIGNED ( addr -- dfaddr)
   7 + -8 AND ;

: DFALIGN ( -- )
   HERE DFALIGNED H ! ;

AKA DFALIGN FALIGN       AKA ALIGN SFALIGN
AKA DFALIGNED FALIGNED   AKA ALIGNED SFALIGNED

{ --------------------------------------------------------------------
Powers of 10

Here we build a table of 64-bit powers of ten from 10**0 to 10**18
named POWERS .  It is primary used for accurate input conversion of
fractional floating numbers.

T10** converts a positive integer (0-18) on the parameter stack into
that power of ten left on the numeric stack.

-------------------------------------------------------------------- }

CREATE POWERS
   #10.0E
      #1.0E    FDUP F,          ( 0  1.0)
      FOVER F* FDUP F,          ( 1  10.0)
      FOVER F* FDUP F,          ( 2  100.0)
      FOVER F* FDUP F,          ( 3  1000.0)
      FOVER F* FDUP F,          ( 4  10000.0)
      FOVER F* FDUP F,          ( 5  100000.0)
      FOVER F* FDUP F,          ( 6  1000000.0)
      FOVER F* FDUP F,          ( 7  10000000.0)
      FOVER F* FDUP F,          ( 8  100000000.0)
      FOVER F* FDUP F,          ( 9  1000000000.0)
      FOVER F* FDUP F,          ( 10 10000000000.0)
      FOVER F* FDUP F,          ( 11 100000000000.0)
      FOVER F* FDUP F,          ( 12 1000000000000.0)
      FOVER F* FDUP F,          ( 13 10000000000000.0)
      FOVER F* FDUP F,          ( 14 100000000000000.0)
      FOVER F* FDUP F,          ( 15 1000000000000000.0)
      FOVER F* FDUP F,          ( 16 10000000000000000.0)
      FOVER F* FDUP F,          ( 17 100000000000000000.0)
      FOVER F* FDUP F,          ( 18 1000000000000000000.0)
   FDROP FDROP

CODE T10** ( +n) ( -- r )
   POWERS EAX ADDR
   0 [EAX] [EBX*8] QWORD FLD
   f>
   POP(EBX)
   FNEXT

{ --------------------------------------------------------------------
These words are used to convert numbers that exceed the range of the
powers of ten table.  To compute a larger power of ten, the power is
broken into integer and fractional parts due to restrictions in the
range of the NDP instructions.

The relationship:  2**(I+F) = 2**I * 2**F   is used.

(I+F) computes the integer and fractional part of the top of the
numeric stack, leaving the fractional part.

Raise raises the third number on numeric stack to the integer and
fractional powers.  A true flag on the parameter stack specifies if
the power is negative.

>10** raises the top of the numeric stack number to an integer power
of ten (parameter stack value).

/10** divides the top of the numeric stack number by an integer power
of ten (parameter stack value).

-------------------------------------------------------------------- }

CODE (I+F) ( -- ) ( r -- x s)
   >f
   EAX PUSH
   0 [ESP] FNSTCW
   0 [ESP] EAX MOV
   $F3FF # EAX AND
   $0400 # EAX OR
   EAX 0 [ESP] XCHG
   FLD1
   FCHS
   ST(1) FLD
   0 [ESP] FLDCW
   FRNDINT
   EAX 0 [ESP] MOV
   0 [ESP] FLDCW
   ST(2) FXCH
   EAX POP
   ST(2) ST(0) FSUB
   FSCALE
   F2XM1
   ST(0) ST(1) FSUBP
   ST(0) ST(0) FMUL
   2 fs>
   FNEXT

CODE [Raise] ( t -- ) ( r x s -- r )
   3 >fs
   ST(1) FXCH   ST(2) FXCH
   EBX EBX OR 0= IF
      ST(0) ST(1) FMULP
   ELSE
      FDIVRP
      ST(1) FXCH  FCHS  ST(1) FXCH
   THEN  FSCALE  ST(1) FXCH  ST(0) FSTP
   POP(EBX)
   f> FNEXT

: >10** ( n -- ) ( r -- r )
   DUP 0<  SWAP  ABS DUP 19 <  IF
      T10** Extract
   ELSE
      S>F LOG2(10) F* (I+F)
   THEN  [Raise]  ;

: /10** ( n) ( r -- r )   #1.0E >10**  F/  ;

{ --------------------------------------------------------------------
An excerpt from ANS...

12.3.7   Text interpreter input number conversion

      If the Floating-Point word set is present in the dictionary and
      the current base is DECIMAL, the input number-conversion
      algorithm shall be extended to recognize floating-point numbers
      in this form:

      Convertible string := <significand><exponent>

      <significand> := [<sign>]<digits>[.<digits0>]
      <exponent> := E[<sign>]<digits0>
      <sign> := ( + | - )
      <digits> := <digit><digits0>
      <digits0> := <digit>*
      <digit> := ( 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 )

      These are examples of valid representations of floating-point
      numbers in program source:

         1E   1.E   1.E0   +1.23E-1   -1.23E+1

      See:  3.4.1.3  Text interpreter input number conversion,
      12.6.1.0558 >FLOAT.

12.6.1.0558   >FLOAT               ``to-float''                FLOATING

      ( c-addr u -- true | false ) ( F: -- r |  )  or
      ( c-addr u -- r true | false )

      An attempt is made to convert the string specified by c-addr and
      u to internal floating-point representation.  If the string
      represents a valid floating-point number in the syntax below, its
      value r and true are returned.  If the string does not represent
      a valid floating-point number only false is returned.

      A string of blanks should be treated as a special case
      representing zero.

      The syntax of a convertible string := <significand>[<exponent>]
      <significand> := [<sign>](<digits>[.<digits0>] | .<digits> )
      <exponent> := <marker><digits0>
      <marker> := (<e-form> | <sign-form>)
      <e-form> := <e-char>[<sign-form>]
      <sign-form> := ( + | -- )
      <e-char>:= ( D | d | E | e )

-------------------------------------------------------------------- }

CODE *DIGIT ( d a n -- d a )
   4 [EBP] EAX MOV      \ eax = hi(d)
   8 [EBP] ECX MOV      \ ecx = lo(d)
   BASE [U] MUL         \ shift hi(d) up by base
   EAX ECX XCHG         \
   BASE [U] MUL         \ shift lo(d) up by base
   EBX EAX ADD          \ add new digit
   EDX ECX ADC          \ and accumulate overflow from lo(d) shift
   ECX 4 [EBP] MOV      \ put back on stack
   EAX 8 [EBP] MOV      \
   POP(EBX)             \ and pop
   RET END-CODE

{ --------------------------------------------------------------------
This is a very simple BNF-sorta parser. It accepts two different forms
of floating point numbers. Not very fast, but reliable.

HAS takes the address A of a character and a counted string on the
stack and tests for whether the character is contained in the string.
If the character is present return the address incremented, the
character and 1; if absent return the address, the character, and 0.

<SIGN> tests for a numeric sign.
<DOT> tests for a decimal point.
<E> tests for upper or lower case E.
<ED> tests for upper or lower case E or D.
<BL> tests for a blank space.
<DIGIT> tests for any valid decimal digit.

<DIGITS> converts the string at A to a double number until it
finds a non-digit character.

FCONVERT produces a floating point number per the 12.3.7 rules.

FCONVERT2 produces a floating point number per the 12.6.1.0558 rules.
-------------------------------------------------------------------- }

: HAS ( a addr n -- a c 0 | a+1 c 1 )
   THIRD C@ DUP >R SCAN NIP 0<> 1 AND TUCK + SWAP R> SWAP ;

: <SIGN>  ( a -- a' c f )   S" +-" HAS ;
: <DOT>   ( a -- a' c f )   S" ." HAS ;
: <E>     ( a -- a' c f )   S" Ee" HAS ;
: <ED>    ( a -- a' c f )   S" EeDd" HAS ;
: <BL>    ( a -- a' c f )   S"  " HAS ;
: <DIGIT> ( a -- a' c f )   S" 0123456789" HAS ;

: <DIGITS> ( a -- a' d f )
   0 0 ROT 0 BEGIN ( d a n)
      >R <DIGIT> WHILE [CHAR] 0 - *DIGIT R> 1+
   REPEAT DROP -ROT R> ;

: FCONVERT ( a -- 0 | a -1 ) ( -- | r )
   <SIGN>    ( a c f)  DROP [CHAR] - = >R
   <DIGITS>  ( a d n)  0= IF 2DROP R> 2DROP 0 EXIT THEN D>F
   <DOT>     ( a c f)  2DROP
   <DIGITS>  ( a d n)  -ROT D>F T10** F/ F+
                       R> IF FNEGATE THEN
   <E>       ( a c f)  0= IF FDROP 2DROP 0 EXIT THEN DROP
   <SIGN>    ( a c f)  DROP [CHAR] - = >R
   <DIGITS>  ( a d n)  2DROP R> IF NEGATE THEN >10**
   <BL>      ( a c f)  0= IF FDROP 2DROP 0 EXIT THEN DROP
   -1 ;

: FCONVERT2 ( a -- 0 | a -1 ) ( -- | r )
   <SIGN>    ( a c f)  DROP [CHAR] - = >R
   <DIGITS>  ( a d n)  DROP D>F
   <DOT>     ( a c f)  2DROP
   <DIGITS>  ( a d n)  -ROT D>F T10** F/ F+
                       R> IF FNEGATE THEN
   <ED>      ( a c f)  2DROP
   <SIGN>    ( a c f)  DROP [CHAR] - = >R
   <DIGITS>  ( a d n)  2DROP R> IF NEGATE THEN >10**
   -1 ;

{ --------------------------------------------------------------------
Number conversion

(REAL) performs real number conversion on the numeric string starting
at the parameter stack address.  The real number is converted directly
on the numeric stack; exponent conversion is performed if present.
The numeric conversion uses FCONVERT and is very strict.

(REAL) nominally takes a counted string; actually the count is not
used.  It returns -1 if the operation is successful.

>FLOAT is similar to (REAL), but uses the not-so-strict rules.

-------------------------------------------------------------------- }

: (REAL) ( a -- a 0 | -1 ) ( -- r )
   DUP 1+ FCONVERT
   DUP -EXIT -ROT 2DROP ;

: >FLOAT ( caddr n -- true | false ) ( -- r )
   R-BUF  -TRAILING R@ ZPLACE  R@ FCONVERT2 ( 0 | a\f ) IF
      R> ZCOUNT + = DUP ?EXIT FDROP EXIT
   THEN R> DROP 0 ;

{ --------------------------------------------------------------------
Here we re-vector NUMBER-CONVERSION to handle real numbers as input.
Integer number conversion on the parameter stack is not affected by
the addition of the numeric stack or the conversion of real numbers.
Double numbers, though, are treated as real if they contain a decimal
point.
-------------------------------------------------------------------- }

: FNUMBER? ( addr len 0 | ... xt -- addr len 0 | ... xt )
   ?DUP ?EXIT  BASE @ 10 = IF
      R-BUF  2DUP R@ PLACE  BL R@ COUNT + C!  R> (REAL) IF
         2DROP ['] FLITERAL  EXIT
   ELSE DROP THEN THEN 0 ;

' FNUMBER? NUMBER-CONVERSION <CHAIN

{ --------------------------------------------------------------------
Logarithmic functions

These words compute Log and Exponential functions using the NDP.

F2**  Given the number  r  returns the value of 2 to the  r .
F**  Given  y  and  x  returns  y  to the  x  power.
FEXP  Given  x  returns e to the  x .
FALOG  Given  x  returns 10 to the  x .
FLN  Given  x  returns the value of the natural log of  x .
FLOG  Given  x  returns the value of the common (base 10) log of  x .

-------------------------------------------------------------------- }

: F2** ( -- )( r -- r )
   FDUP F0< FABS #1.0E FSWAP (I+F) [Raise]  ;

: F** ( -- ) ( y x -- r )   FSWAP Y*LOG2(X) F2**  ;   \ y to the x
: FEXP ( -- ) ( x -- r )   LOG2(E) F* F2**  ;         \ e to the x
: FALOG ( -- ) ( x -- r )   LOG2(10) F* F2**  ;       \ 10 to the x

( Natural log of x)
CODE FLN ( -- ) ( x -- r )   >f
   FLDLN2
   ST(1) FXCH
   FYL2X
   f> FNEXT

( Log base 10 of x)
CODE FLOG ( -- ) ( x -- r )   >f
   FLDLG2
   ST(1) FXCH
   FYL2X
   f> FNEXT

: FLNP1 ( r -- r )
   FDUP [ 1.0E 2.0E FSQRT 2.0E F/ F- FNEGATE ] FLITERAL F> IF
     FDUP [ 2.0E FSQRT 1.0E F- ] FLITERAL F< IF
       LN2  FSWAP  Y*LOG2(X+1)  EXIT  THEN THEN
   #1.0E F+ FLN ;    \ ln(x+1)

: FEXPM1 ( r -- r )
   LOG2(E) F*
   FDUP FABS #1.0E F< IF
     2**X-1
   ELSE
     F2** #1.0E F-  THEN ;  \ (e to the x) - 1

{ --------------------------------------------------------------------
Display routines

PRECISION returns the number of digits to display.

SET-PRECISION sets that number.

-------------------------------------------------------------------- }

: PRECISION ( -- u )   'FPOPT 4 + C@ ;

: SET-PRECISION ( u -- )   1 MAX 17 MIN  'FPOPT 4 + C!  ;

{ --------------------------------------------------------------------
These are words to output a real number from the top of the numeric
stack in a fractional format without an exponent.

#EXP reports the number of digits left of the decimal.

REPRESENT consumes the top floating number, and places its
digits in a buffer of your choice.  On the stack it
returns n, the number of digits before the decimal, flag1, true if
the number is negative, and flag2, true if the operation was
successful. (Errors are trapped by the system, this is always
true.)

FDISPLAY displays a number using digits from the FBUFFER buffer,
n from the stack for # of leading digits, and PRECISION for the
total number of digits.  A minus sign may have been displayed
previously.

-------------------------------------------------------------------- }

18 CONSTANT MAX-FBUFFER

CREATE FBUFFER MAX-FBUFFER 2+ ALLOT

: FSIGN? ( -- n ) ( r -- r )   FDUP F0<  ;

: #EXP ( -- n ) ( r -- r )   FDUP F0=  IF  PRECISION 1-  ELSE
   FDUP FABS FLOG FLOOR F>S  THEN  ;

: FSIGN ( n -- )   IF  [CHAR] - EMIT  THEN  ;

: 0'S ( n -- )   DUP 0> IF DUP 0  DO
   [CHAR] 0 EMIT  LOOP  THEN  DROP  ;

: REPRESENT ( c-addr u -- n flag1 flag2 ) ( r -- )
   2DUP [CHAR] 0 FILL 2DUP FSIGN? >R FABS
   #EXP DUP >R - 1- >10** FROUND DROP  F>D <# #S #>
   ROT 2DUP - >R  MIN ROT SWAP MOVE 2R> + 1+  R> -1 ;

{ --------------------------------------------------------------------
Scientific and Engineering output

.EXP displays the exponent it finds on the stack.

FS. displays a real number in scientific notation with  n fractional
digits.

FE. is like FS. except that it adjusts to allow up to three digits
before the decimal, with the exponent always a multiple of three.

-------------------------------------------------------------------- }

: FDISPLAY ( n -- )
   FBUFFER  OVER 0 MAX TYPE   [CHAR] . EMIT
   DUP FBUFFER +  SWAP NEGATE 0 MIN PRECISION + TYPE  ;

: .EXP ( n -- )
   [CHAR] E EMIT  DUP ABS  0  <#  #S
   PAD DPL @ -  1 = IF  [CHAR] 0 HOLD  THEN
   ROT 0<  IF  [CHAR] -  ELSE  [CHAR] +  THEN  HOLD  #>
   TYPE SPACE  ;

: FS. ( r -- )
   ?FPRINT  FBUFFER PRECISION REPRESENT DROP FSIGN
   1 FDISPLAY 1-  .EXP  ;

: Adjust ( n1 -- n2 1|2|3 )
   S>D 3 FM/MOD 3 * SWAP 1+  ;

{ --------------------------------------------------------------------
Old code was:
: Adjust ( n - n' 1|2|3 )
   DUP 0< 2 AND - 3 / 3 * OVER 3000000 + 3 MOD 1+ ;
and seems to be broken.
-------------------------------------------------------------------- }

: FE. ( r)
   ?FPRINT  FBUFFER PRECISION REPRESENT DROP FSIGN
   1- Adjust FDISPLAY  .EXP  ;

{ --------------------------------------------------------------------
Fractional output

The three cases are:

a large numer with not enough significant digits to the left
of the decimal, requiring trailing zeros,

a small number requiring leading zeroes after the decimal,

an in-between number.

F. prints the top floating number with no exponent.

-------------------------------------------------------------------- }

: DISPLAY-SMALL ( n -- )
   [CHAR] 0 EMIT [CHAR] . EMIT
   ABS DUP PRECISION MIN 1- 0'S
   FBUFFER PRECISION ROT - 0 MAX TYPE  ;

: DISPLAY-BIG ( n -- )
   FBUFFER PRECISION TYPE PRECISION - 1+ 0'S [CHAR] . EMIT  ;

: FNS. ( -- ) ( r -- )
   ?FPRINT #EXP 0< >R
   FBUFFER PRECISION  REPRESENT DROP FSIGN R> IF
      DUP 1 < IF 1- DISPLAY-SMALL ELSE FDISPLAY THEN
   ELSE
      DUP PRECISION >  IF  1- DISPLAY-BIG  ELSE  FDISPLAY  THEN
   THEN  ;

: F. ( -- ) ( r -- )   FNS. SPACE  ;

{ --------------------------------------------------------------------
These words provide formatted output, prints right-justified in an
area of your chosen length.

If all the significant digits are too far behind the decimal
point, the displayed number will be all zeroes.

If the digits to the left of the decimal won't fit in the space,
they will be printed regardless.

-------------------------------------------------------------------- }

: FS.R ( u -- ) ( r -- )
   FSIGN?  2 #EXP ABS 99 > -  SWAP -  3 +  -
   PRECISION 2DUP > IF TUCK - SPACES ELSE SWAP SET-PRECISION THEN
   FS.  SET-PRECISION  ;

: F.R ( u -- ) ( r -- )
   ?FPRINT 1- FSIGN? + PRECISION 2DUP >
   IF  OVER SET-PRECISION   ELSE  2DUP SWAP - SPACES  THEN
   FNS. SET-PRECISION DROP  ;

{ --------------------------------------------------------------------
Programmable format output

N. is a programmable output display for real numbers.

[N] defines words that program N. to a specified behavior.  Three
examples follow:

n FIX  programs  N.  to output in  n F.  format.
n SCI  programs  N.  to output in  n FS.  format.
n ENG  programs  N.  to output in  n FE.  format.

-------------------------------------------------------------------- }

#USER DUP USER 'POINTS
CELL+ DUP USER 'FORMAT
CELL+ TO #USER

: N. ( -- ) ( r -- )
   ?FPRINT PRECISION
   'POINTS @ SET-PRECISION 'FORMAT @EXECUTE SET-PRECISION  ;

: [N] ( -- ) \ Usage: [N] <existingname> <name>
   ' CREATE ,
   DOES> ( n a -- )   @ 'FORMAT !  'POINTS !  ;

[N] F. FIX    [N] FS. SCI    [N] FE. ENG

'FPOPT 4 + COUNT SWAP COUNT EVALUATE

{ --------------------------------------------------------------------
Fractional output

NB: This is included solely for compatibility with CBD pre-defined
formats.  These words are not used by FPMATH.F.  These are words to
output a real number from the top of the numeric stack in a fractional
format without an exponent.

F/DIGIT  divides a real number by ten, returns the quotient to
   the numeric stack and the remainder to the parameter stack.
<#.  starts the floating numeric conversion.
#.  converts one real digit starting with the least significant.
#S.  converts the real number until zero.
.#>  terminates the conversion.
FSIGN  inserts the negative sign for negative numbers.
(F.)  performs conversion of fractional real numbers leaving
   the count and address of the numeric character string.
F.  outputs a real number with  n  fractional digits.
F.R   right justified version of  F. .

-------------------------------------------------------------------- }

CODE F/DIGIT ( -- n ) ( r -- q )
   >f                                   \ r to tos
   ' #10.0E >BODY EAX ADDR
   0 [EAX] DWORD FILD                   \ push 10.0
   ST(1) FLD                            \ r 10 r
   FPREM                                \ r%10 10 r
   ST(2) FXCH                           \ r 10 r%10
   FDIVRP                               \ r/10 r%10
   0 # PUSH                             \ make a place
   0 [ESP] FNSTCW                       \ read control word
   0 [ESP] EAX MOV                      \ to eax
   $0C00 # EAX OR                       \ set mask
   0 [ESP] EAX XCHG                     \ swap new with old
   0 [ESP] FLDCW                        \ write new
   FRNDINT                              \
   0 [ESP] EAX XCHG                     \ swap new with old
   0 [ESP] FLDCW                        \ write old
   ST(1) FXCH                           \
   0 [ESP] FISTP                        \
   PUSH(EBX)                            \ push tos
   EBX POP                              \ and get n from stack
   f> FNEXT

: <#. ( -- ) ( r -- r )   FROUND  <# ;

: #. ( -- ) ( r -- q)   F/DIGIT  DIGIT HOLD ;

: #S. ( -- ) ( r -- r )   BEGIN  #.  FDUP F0= UNTIL ;

: .#> ( - a n) ( r -- )   FDROP  DPL @ PAD OVER - ;

: (FSIGN) ( n)   IF  [CHAR] -  ELSE  BL THEN  HOLD ;

: (F.) ( len1 -- addr len2 ) ( r -- )
   0 MAX  18 MIN  FDUP F0<  >R  FABS
   DUP >10**  <#.  ?DUP IF  0 DO  #. LOOP  THEN
   [CHAR] . HOLD  #S.  R> (FSIGN)  .#> ;

{ --------------------------------------------------------------------
Math option: Percent

Computation of percent leaves the original value next on stack and the
percentage top of stack.  This allows addition, subtraction, etc. of
the percentage directly following the computation.

-------------------------------------------------------------------- }

CODE % ( -- ) ( x % - x r)
   2 >fs
   ST(1) ST(0) FMUL
   100 # PUSH
   0 [ESP] FILD
   FDIVP
   4 # ESP ADD
   2 fs> FNEXT

{ --------------------------------------------------------------------
Math option: Matrix defining words

SMATRIX  creates a matrix with 32-bit real elements.
LMATRIX  creates a matrix with 64-bit real elements.

creation:      #rows #cols SMATRIX name
execution:     row# col# name      ( returns address of matrix
                                     element to parameter stack)

Floating memory access operators such as  F! ,  F@  and  F+!  are used
to access matrix elements.  Note that addressing a matrix starts with
row 0 and column 0.

Matrix display:   #rows #cols SMD name   ( 32-bit elements )
      likewise:   #rows #cols LMD name   ( 64-bit elements )
Use  n FIX ,  n SCI  and  n ENG  to change display format.

-------------------------------------------------------------------- }

: SMATRIX ( #r #c -- )
   CREATE
      DUP SFLOATS , * 0 DO
         #0.0E SF,
      LOOP
   DOES> ( r c a -- a )
      ROT OVER @ * ( c a o1) ROT SFLOATS +  +  CELL+ ;

: LMATRIX ( #r #c -- )
   CREATE
      DUP DFLOATS , * 0 DO
         #0.0E DF,
      LOOP
   DOES> ( r c a -- a )
      ROT OVER @ * ( c a o1) ROT DFLOATS +  +  CELL+ ;

( Short matrix display)

: SMD ( #r #c -- ) \ Usage: n m SMD <name>
   SWAP  ' >BODY CELL+ SWAP  0  ?DO
      CR OVER  0  DO
         DUP SF@ N. 1 SFLOATS +
      LOOP
   LOOP  CR 2DROP  ;

( Long matrix display)

: LMD ( #r #c -- ) \ Usage: n m LMD <name>
   SWAP  ' >BODY CELL+ SWAP  0  ?DO
      CR OVER  0 DO
         DUP DF@ N. 1 DFLOATS +
      LOOP
   LOOP  CR 2DROP  ;

{ --------------------------------------------------------------------
Trig functions - degree/radian conversion, Tangent

PI/180  returns a value equal to 1 degree expressed as radians.
D>R  and  R>D  convert input and output to degrees.

PI/4  returns a value equal to 45 degrees expressed as radians.

FTAN is given an angle in radians and returns the tangent of the
angle.  The angle can have any value or sign and the result will be
accurate.

TAN works the same as FTAN , but is passed an angle in degrees, rather
than radians.
-------------------------------------------------------------------- }

PI 180.0E0 F/ DFCONSTANT PI/180
PI 4.0E0   F/ DFCONSTANT PI/4
PI 2.0E0   F/ DFCONSTANT PI/2

: R>D ( r -- r )   PI/180 F/  ;
: D>R ( r -- r )   PI/180 F*  ;

CODE FTAN ( r -- r )
   >f   FTST
   0 # PUSH  0 [ESP] FSTSW  EDX POP
   FABS
   ' PI/4 >BODY EAX ADDR
   EAX ECX MOV  0 [ECX] QWORD FLD
   ST(1) FXCH   FPREM   FSTSWAX
   ST(1) FSTP   $200 # EAX TEST   0= NOT  IF
      0 [ECX] QWORD FSUBR   THEN   FPTAN
   EAX ECX MOV   $4200 # ECX AND   0= NOT  IF  $4200 # ECX SUB
      0= NOT  IF  ST(1) FXCH   THEN   THEN   FDIVP
   $4000 # EAX TEST   0= NOT  IF  FCHS   THEN
   $100 # EDX TEST   0= NOT  IF  FCHS   THEN   f>   FNEXT

: TAN ( r -- r )   D>R FTAN  ;

{ --------------------------------------------------------------------
COS.SIN is a fast routine that when given any angle in radians returns
both the cosine and the sine.  The cosine is the top stack item.
-------------------------------------------------------------------- }

CODE COS.SIN ( r -- r r )
   >f   FTST  0 # PUSH  0 [ESP] FSTSW  EDX POP   FABS
   ' PI/4 >BODY EAX ADDR
   EAX ECX MOV  0 [ECX] QWORD FLD
   ST(1) FXCH   FPREM   FSTSWAX
   ST(1) FSTP   $200 # EAX TEST   0= NOT  IF
      0 [ECX] QWORD FSUBR   THEN   FPTAN
   ST(0) FLD  ST(0) FLD  FMULP
   ST(2) FLD  ST(0) FLD  FMULP  FADDP  FSQRT
   ST(0) FLD  ST(0) ST(2) FDIVP ST(0) ST(2) FDIVP

   EAX ECX MOV  $4200 # ECX AND
   0= NOT IF  $4200 # ECX SUB  0= NOT IF  ST(1) FXCH  THEN THEN
   EAX ECX MOV  $4100 # ECX AND
   0= NOT IF  $4100 # ECX SUB  0= NOT IF  FCHS THEN THEN
   $100 # EAX TEST
   0= NOT IF  ST(1) FXCH FCHS ST(1) FXCH THEN
   $100 # EDX TEST
   0= NOT IF  ST(1) FXCH FCHS ST(1) FXCH THEN

   2 fs> FNEXT

{ --------------------------------------------------------------------
Trig functions - Cosine and Sine

FCOS  and  FSIN  use  COS.SIN  and return only their respective
function values from the given angle.

COS  and  SIN  work the same as  FCOS  and  FSIN , but are passed
angles in degrees rather than radians.
-------------------------------------------------------------------- }

: FSINCOS ( r -- r r )   COS.SIN ;
: FSIN ( r -- r )   COS.SIN  FDROP  ;
: FCOS ( r -- r )   COS.SIN  FSWAP  FDROP  ;
: SIN ( r -- r )   D>R FSIN  ;
: COS ( r -- r )   D>R FCOS  ;

{ --------------------------------------------------------------------
Trig functions - arctangent

FCOMPLEMENT given an angle in radians returns its complement.  Two
angles are complementary if they produce a right angle when combined.

FSUPPLEMENT given an angle in radians returns its supplement.  Two
angles are supplementary if they produce a straight angle when
combined.
-------------------------------------------------------------------- }

: FCOMPLEMENT ( r -- r )   FNEGATE PI/2 F+  ;
: FSUPPLEMENT ( r -- r )   FNEGATE PI F+  ;

{ --------------------------------------------------------------------
Additional auxiliary trig functions

Cotangent, Secant, and Cosecant
Arcsine and Arccosine
Hyperbolic Sine and Cosine
Inverse Hyperbolic Sine, Cosine, and Tangent
-------------------------------------------------------------------- }

: COT ( r -- r )   TAN 1/N  ;
: SEC ( r -- r )   COS 1/N  ;
: CSC ( r -- r )   SIN 1/N  ;
: R ( r -- r )   FDUP F* FNEGATE  #1.0E F+  FSQRT  ;
: FASIN ( r -- r )   FDUP  R  FATAN2  ;
: FACOS ( r -- r )   FDUP  R  FSWAP  FATAN2  ;

\ sinh(x) = 1/2 * (d + d/(d-1)) ; d = expm1(x)
: FSINH ( r -- r )
   FEXPM1  FDUP  FDUP #1.0E F+  F/  F+  f2/ ;

: FCOSH ( r -- r )   FEXP  FDUP  1/N  F+  F2/  ;

\ tanh(x) = -d / (d+2) ; d = expm1(-2x)
: FTANH ( r -- r )
   FDUP 22.0E0 F< IF
     F2* FEXPM1  2.0E0 FOVER  F+  F/
   ELSE  #1.0E
   THEN ;

\ asinh(x) = sign(x) * lnp1(|x| + x^2/(1 + sqrt(1+x^2)))
: FASINH ( r -- r )
   FDUP F0< >R FABS
   FDUP [ 28.0e F2** ] FLITERAL F< IF
     FDUP  FDUP F*
     FDUP  #1.0E F+  FSQRT  #1.0E F+  F/  F+  FLNP1
   ELSE
     FLN  LN2 F+    \ avoid overflow
   THEN
   R> IF  FNEGATE  THEN ;

\ acosh(x) = ln(x + sqrt(x^2-1))
: FACOSH ( r -- r )
   FABS FDUP [ 28.0E F2** ] FLITERAL F< IF
     FDUP  FDUP F*  #1.0E F-  FSQRT  F+  FLN
   ELSE
     FLN  LN2 F+    \ avoid overflow
   THEN ;

\ atanh(x) = sign(x)* 1/2 * lnp1(2*(x / (1-x)))
: FATANH ( r -- r)
   FDUP F0< >R FABS
   FDUP #1.0E FOVER F- F/ F2*  FLNP1  F2/
   R> IF  FNEGATE  THEN ;

{ --------------------------------------------------------------------
Numeric stack display

FPICK fetches the nth numeric item placing it on top of the numeric
stack.

.S is redefined to display both the parameter and the numeric stack
contents.
-------------------------------------------------------------------- }

[DEFINED] NUMERICS [IF]

CODE FPICK ( n -- ) ( -- r )
   |NUMERIC| # EAX MOV  EBX MUL
   'N [U] EAX ADD  0 [EAX] TBYTE FLD
   0 [EBP] EBX MOV  4 # EBP ADD
   f> FNEXT

[ELSE]

LABEL (FPICK)
   ST(0) FLD   RET
   ST(1) FLD   RET
   ST(2) FLD   RET
   ST(3) FLD   RET
   ST(4) FLD   RET
   ST(5) FLD   RET
   ST(6) FLD   RET
   ST(7) FLD   RET
   END-CODE

CODE FPICK ( n -- ) ( -- r)
   3 # EAX MOV   EBX MUL
   (FPICK) # EAX ADD   POP(EBX)
   EAX JMP   END-CODE

[THEN]

-? : .S   .S  FDEPTH ?DUP IF
      0  DO  I' I - 1- FPICK N.  LOOP
   ." <-NTop "  THEN ;

{ --------------------------------------------------------------------
Hyperbolic Tangent

-------------------------------------------------------------------- }

: TANH ( r -- r )
   FEXP FDUP  FDUP 1/N FDUP  FROT FSWAP F-
   FROT FROT  F+  F/ ;

: +POINTS ( -- )   PRECISION 1+ DUP SET-PRECISION 'POINTS !  ;

: +N ( -- ) ( r -- r )   FDUP N. +POINTS CR  ;
: |N ( -- ) ( r -- )   FDROP 3 SET-PRECISION  ;

{ --------------------------------------------------------------------
Environmental queries

String          Type Constant?  Meaning

FLOATING        flag   no       floating-point word set present
FLOATING-EXT    flag   no       floating-point extensions word set
                                present
FLOATING-STACK     n   yes      If n = zero, floating-point numbers
                                are kept on the data stack;
                                otherwise n is the maximum depth of
                                the separate floating- point stack.
MAX-FLOAT          r   yes      largest usable floating-point number
-------------------------------------------------------------------- }

ENVIRONMENT-WORDLIST SET-CURRENT
   TRUE  CONSTANT FLOATING
   TRUE  CONSTANT FLOATING-EXT
   [DEFINED] NUMERICS [IF]  #NS
   [ELSE]  8  [THEN]  CONSTANT FLOATING-STACK
   1.E308 FCONSTANT MAX-FLOAT

:ONENVLOAD   /NDP ;
/NDP

{ ----------------------------------------------------------------------
Add SWOOP support for FVARIABLES
---------------------------------------------------------------------- }

DECIMAL  ONLY FORTH ALSO DEFINITIONS  OOP +ORDER
GET-CURRENT ( *) CC-WORDS SET-CURRENT

   \ Usage: DFVARIABLE <name>

   : DFVARIABLE ( -- )
      THIS SIZEOF FALIGNED THIS >SIZE !
      [ +CC ] 8 BUFFER: [ -CC ] ;

   \ Usage: SFVARIABLE <name>

   : SFVARIABLE ( -- )
      THIS SIZEOF FALIGNED THIS >SIZE !
      [ +CC ] 4 BUFFER: [ -CC ] ;

   : FVARIABLE ( -- )
      [ +CC ]  DFVARIABLE [ -CC ] ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT

DECIMAL  ONLY FORTH ALSO DEFINITIONS

\ ----------------------------------------------------------------------

ONLY FORTH ALSO DEFINITIONS
GILD
