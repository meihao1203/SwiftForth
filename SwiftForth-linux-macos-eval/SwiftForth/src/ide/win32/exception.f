{ ====================================================================
Exception handler context interpreter

Copyright (C) 2001-2011 FORTH, Inc.
Rick VanNorman
==================================================================== }

?( Windows exception handler)

{ --------------------------------------------------------------------
Windows manages exceptions via a mysterious stack frame that only C
compilers seem to know how to build.  The loader program that launches
SwiftFORTH builds this frame and catches all the exceptions generated
by the primary thread.

FS:[0] is used for manipulating the frame-based exception handler for the
current thread.  In NT and 95, the FS register is used to point to the
thread environment block for the currently executing thread.  This
structure begins with a thread information block (an NT_TIB).

Offset 0 of this structure is a pointer to an
EXCEPTION_REGISTRATION_RECORD.  This structure contains a link pointer to
the next exception record in the chain, and a pointer to an exception
handling routine.

As for documentation...Winnt.h has the NT_TIB definition, and MSDN has a
pretty indepth section on exception handling, but your best source of info
for how compilers use it is an article Pietrek did for MSJ back in January
or so of 1997.
-------------------------------------------------------------------- }

PACKAGE ERROR-HANDLERS

{ --------------------------------------------------------------------
CPU CONTEXT -- This maps onto the context_record produced by CAUGHT
-------------------------------------------------------------------- }

0  ENUM4 'CONTEXTFLAGS
   ENUM4 'DR0
   ENUM4 'DR1
   ENUM4 'DR2
   ENUM4 'DR3
   ENUM4 'DR6
   ENUM4 'DR7
   ENUM4 'FPCONTROLWORD
   ENUM4 'FPSTATUSWORD
   ENUM4 'FPTAGWORD
   ENUM4 'FPERROROFFSET
   ENUM4 'FPERRORSELECTOR
   ENUM4 'FPDATAOFFSET
   ENUM4 'FPDATASELECTOR
   DUP CONSTANT 'FPREG0  80 +
   ENUM4 'FPCR0NPXSTATE
   ENUM4 'SEGGS
   ENUM4 'SEGFS
   ENUM4 'SEGES
   ENUM4 'SEGDS
   ENUM4 'EDI
   ENUM4 'ESI
   ENUM4 'EBX
   ENUM4 'EDX
   ENUM4 'ECX
   ENUM4 'EAX
   ENUM4 'EBP
   ENUM4 'EIP
   ENUM4 'SEGCS
   ENUM4 'EFLAGS
   ENUM4 'ESP
   ENUM4 'SEGSS

CONSTANT |CPU_CONTEXT|

{ --------------------------------------------------------------------
The CATCH/THROW behavior captures the error frame on exceptions into
the RSTACK_RECORD etc. This decodes the error frame data. The
register contents, the top 20 items on the data stack, and the top
20 entities on the return stack are presented.

The return stack is used to instantiate many different temporary
things in SwiftForth; each of these is decoded separately and displayed
in some pretty fashion. This means that some data on the return stack
isn't displayed directly, but a much better picture of the error
reference is made.  Each token to be decoded requires a known
return stack address to identify it, so each entity was given
a code-space label. See the definition of R-ALLOC for details.

Local entities don't have persistent names, but local objects have
a discernable class and so the class names are presented. Data pools
defined by R-ALLOC and R-BUF aren't displayed, but their existence
and size are. Local variables are likewise not displayed but
their existence is reported.
-------------------------------------------------------------------- }

: DICTIONARY? ( addr -- flag )
   ORIGIN 1+   UP0 @REL [ H UP@ - ] LITERAL + @  WITHIN ;

: (ID.') ( addr -- )
   DUP (.')
   DUP ORIGIN < IF DROP C" <unknown>" THEN
   ( a nfa)  COUNT 2DUP TYPE SPACE  + 1+ -
   ?DUP IF  DUP 0> IF ." +" THEN  . THEN ;


: ID.' ( addr -- )
   DUP DICTIONARY? IF  (ID.') EXIT THEN
   +ORIGIN DUP DICTIONARY? IF  (ID.') EXIT THEN  DROP ;

: 'RR@ ( offset -- x )   RSTACK_RECORD + @ ;

: .LOCAL-OBJECT ( offset -- OFFSET )
   DUP DUP CELL+ 'RR@ + >R 3 CELLS + 'RR@  ID.'  R> ;

: .LOCAL-OBJECTS ( offset -- OFFSET )
   BEGIN
      DUP |RSTACK_RECORD| U< WHILE
      DUP 'RR@ $DEADBEEF <> WHILE
\      CR DUP 4 .R SPACE
      .LOCAL-OBJECT
   REPEAT THEN ;

: .RSTACK-SKIP ( offset -- OFFSET n )
   DUP 'RR@ 'ESP CONTEXT_RECORD + @ -
   TUCK SWAP - CELL - ;

: .REGX ( offset -- )
   CASE
      0 OF  ." EAX " 'EAX    ENDOF
      1 OF  ." EBX " 'EBX    ENDOF
      2 OF  ." ECX " 'ECX    ENDOF
      3 OF  ." EDX " 'EDX    ENDOF
      4 OF  ." ESI " 'ESI    ENDOF
      5 OF  ." EDI " 'EDI    ENDOF
      6 OF  ." EBP " 'EBP    ENDOF
      7 OF  ." ESP " 'ESP    ENDOF
      8 OF  ." EFL " 'EFLAGS ENDOF
      9 OF  ." EIP " 'EIP    ENDOF

      ( else) DROP 14 SPACES EXIT

   ENDCASE ( offset)
   CONTEXT_RECORD + @ H.8 SPACE SPACE ;

: .DS ( offset -- )
   CELLS DSTACK_RECORD + @ H.8 SPACE SPACE ;

: .RS ( offset1 -- offset2 )
   |RSTACK_RECORD| OVER < ?EXIT
   DUP CELL+ SWAP 'RR@
   DUP H.8 SPACE  ORIGIN - CASE
      'CATCHER OF ." <<catcher>> "  ENDOF
      'R-ALLOC OF ." <<r-alloc>> "  .RSTACK-SKIP .  ENDOF
      'R-BUF   OF ." <<r-buf>> "    .RSTACK-SKIP .  ENDOF
      'LSPACE  OF ." <<locals>> "   .RSTACK-SKIP .  CELL+  ENDOF
      'OSPACE  OF ." <<ospace>> "   .LOCAL-OBJECTS  2 CELLS +  ENDOF
      DUP ORIGIN + ID.'
   ENDCASE ;

PUBLIC

: .EXCEPTION-CONTEXT ( -- )
   CR ." Registers     Dstack    esp+ Rstack  "
   0 LOCALS| rs |  20 0 DO
     CR I .REGX  I .DS   rs 4 H.0 SPACE  rs .RS TO rs
   LOOP ;

: .RSTACK-CONTEXT ( -- )
   0 BEGIN
      CR DUP |RSTACK_RECORD| < WHILE  .RS
   REPEAT DROP ;

{ ----------------------------------------------------------------------
tests for the return stack unroller

: zz 7 >r  33 r-alloc  9 >r  0 @  HERE . ;
: ZZZ 3 >R 4 >R ZZ HERE . ;

: YY 7 >r  R-BUF  9 >r  0 @ HERE . ;
: YYY 3 >R 4 >R YY HERE . ;

: XX 7 >R [OBJECTS POINT MAKES PT RECT MAKES RX OBJECTS]
   $11111111 PT X !  $55555555 PT Y !
   9 >R 0 @ HERE . ;

: WWW 7 >R  1 2 3 LOCALS| A B C | 9 >R  0 @ HERE . ;

---------------------------------------------------------------------- }

PRIVATE

{ --------------------------------------------------------------------
The exception-type switch is a mechanism to produce a printable
string for the standard windows exceptions that we can catch.
Forth errors produce the base string "throw"; unknown values produce
a hex representation of the ior.
-------------------------------------------------------------------- }

[SWITCH EXCEPTION-TYPE (H.8)    ( ior -- addr n )
   STATUS_WAIT_0                   RUN: S" WAIT_0"                    ;
   STATUS_ABANDONED_WAIT_0         RUN: S" ABANDONED_WAIT_0"          ;
   STATUS_USER_APC                 RUN: S" USER_APC"                  ;
   STATUS_TIMEOUT                  RUN: S" TIMEOUT"                   ;
   STATUS_PENDING                  RUN: S" PENDING"                   ;
   STATUS_DATATYPE_MISALIGNMENT    RUN: S" DATATYPE_MISALIGNMENT"     ;
   STATUS_BREAKPOINT               RUN: S" BREAKPOINT"                ;
   STATUS_SINGLE_STEP              RUN: S" SINGLE_STEP"               ;
   STATUS_ACCESS_VIOLATION         RUN: S" ACCESS_VIOLATION"          ;
   STATUS_IN_PAGE_ERROR            RUN: S" IN_PAGE_ERROR"             ;
   STATUS_NO_MEMORY                RUN: S" NO_MEMORY"                 ;
   STATUS_ILLEGAL_INSTRUCTION      RUN: S" ILLEGAL_INSTRUCTION"       ;
   STATUS_NONCONTINUABLE_EXCEPTION RUN: S" NONCONTINUABLE_EXCEPTION"  ;
   STATUS_INVALID_DISPOSITION      RUN: S" INVALID_DISPOSITION"       ;
   STATUS_ARRAY_BOUNDS_EXCEEDED    RUN: S" ARRAY_BOUNDS_EXCEEDED"     ;
   STATUS_FLOAT_DENORMAL_OPERAND   RUN: S" FLOAT_DENORMAL_OPERAND"    ;
   STATUS_FLOAT_DIVIDE_BY_ZERO     RUN: S" FLOAT_DIVIDE_BY_ZERO"      ;
   STATUS_FLOAT_INEXACT_RESULT     RUN: S" FLOAT_INEXACT_RESULT"      ;
   STATUS_FLOAT_INVALID_OPERATION  RUN: S" FLOAT_INVALID_OPERATION"   ;
   STATUS_FLOAT_OVERFLOW           RUN: S" FLOAT_OVERFLOW"            ;
   STATUS_FLOAT_STACK_CHECK        RUN: S" FLOAT_STACK_CHECK"         ;
   STATUS_FLOAT_UNDERFLOW          RUN: S" FLOAT_UNDERFLOW"           ;
   STATUS_INTEGER_DIVIDE_BY_ZERO   RUN: S" INTEGER_DIVIDE_BY_ZERO"    ;
   STATUS_INTEGER_OVERFLOW         RUN: S" INTEGER_OVERFLOW"          ;
   STATUS_PRIVILEGED_INSTRUCTION   RUN: S" PRIVILEGED_INSTRUCTION"    ;
   STATUS_STACK_OVERFLOW           RUN: S" STACK_OVERFLOW"            ;
   STATUS_CONTROL_C_EXIT           RUN: S" CONTROL_C_EXIT"            ;
   IOR_FORTHERROR                  RUN: S" Throw"                     ;
SWITCH]

{ ----------------------------------------------------------------------
.EXCEPT displays the exception context that either THROW or the windows
exception handler captured. IOR_WINEXCEPT is added to the (THROW) switch
to properly decode the windows exception events.
---------------------------------------------------------------------- }

PUBLIC

: WINERROR ( -- addr u )
   EXCEPTION_RECORD @ EXCEPTION-TYPE ;

: .EXCEPT ( -- )   WINERROR TYPE
   CONTEXT_RECORD 'EIP + @ 4 SPACES  ID.'  .EXCEPTION-CONTEXT ;

[+SWITCH (THROW)
   IOR_WINEXCEPT RUN: WINERROR ;
SWITCH]

END-PACKAGE
