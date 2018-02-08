{ ====================================================================
Signal error message display

Copyright 2008  FORTH, Inc.

The OS sends a SIGNAL to us when memory faults, illegal opcodes, and
other such exceptions occur.  We set a signal handler that forces a
THROW with throw code IOR_SIGNAL as part of the CATCH/THROW exception
handling.  Our SIGNAL handler captures the registers and stacks from
the user context record, which are decoded and displayed here.
==================================================================== }

PACKAGE ERROR-HANDLERS

?( Signal exception traceback dump)

{ --------------------------------------------------------------------
Signal message

The (THROW) IOR decoding list is extended to include the Signal#
display for IOR_SIGNAL.
-------------------------------------------------------------------- }

: SIGNAL-MESSAGE ( -- addr u )
   BASE @ >R DECIMAL
   S" Signal #" ERRMSG PLACE
   SIGNAL# @ (.) ERRMSG APPEND
   S"  at " ERRMSG APPEND
   'SIGNAL @ DUP 8 (H.0) ERRMSG APPEND
   DUP ORIGIN HERE WITHIN IF
      S"  in "  ERRMSG APPEND
     DUP (.') COUNT ERRMSG APPEND
   THEN DROP  @ERRMSG
   R> BASE ! ;

[+SWITCH (THROW)
   IOR_SIGNAL RUN: SIGNAL-MESSAGE ;
SWITCH]

{ --------------------------------------------------------------------
Traceback display

The kernel's SIGNAL handler captures error frame info into the
TRACEBACK buffer.  This consists of three things:

1) The CPU registers from the user context passed to the SIGNAL handler
2) The return stack pointed by ESP in the user context
3) The Forth data stack pointed to by EBP in the user context

The display words below decode the error frame data. The register
contents, the top 20 items on the data stack, and the top 20 entities
on the return stack are presented.

The return stack is used to instantiate many different temporary
things in SwiftForth; each of these is decoded separately and
displayed in some pretty fashion. This means that some items on the
return stack aren't displayed in full, but a much better picture of
the overall error reference is made.

Each token to be decoded requires a known return stack address to
identify it, so each entity has a code-space label. See the definition
of R-ALLOC for details.

Local entities don't have persistent names, but local objects have a
discernable class and so the class names are presented.  Data pools
defined by R-ALLOC and R-BUF aren't displayed, but their existence and
size are.  Local variables are likewise not displayed but their
existence is reported.
-------------------------------------------------------------------- }

: DICTIONARY? ( addr -- flag )
   ORIGIN 1+   UP0 @REL [ H UP@ - ] LITERAL + @  WITHIN ;

: (ID.') ( addr -- )
   DUP (.')  DUP ORIGIN <  IF  DROP  C" <unknown>"  THEN
   ( a nfa)  COUNT 2DUP TYPE SPACE  + 1+ -
   ?DUP IF  DUP 0> IF ." +" THEN  . THEN ;

: ID.' ( addr -- )
   DUP DICTIONARY? IF  (ID.') EXIT THEN
   +ORIGIN  DUP DICTIONARY? IF  (ID.') EXIT  THEN  DROP ;

: 'RR@ ( i -- x )
   #TRACE_REGS + CELLS  TRACEBACK + @ ;

: .LOCAL-OBJECT ( i1 -- i2 )
   DUP DUP 1+ 'RR@ CELL / + >R 3 + 'RR@  ID.'  R> ;

: .LOCAL-OBJECTS ( i1 -- i2 )
   BEGIN
      DUP #TRACE_RSTACK U< WHILE
      DUP 'RR@ IOR_SIGNAL <> WHILE
      .LOCAL-OBJECT
   REPEAT THEN ;

: .RSTACK-SKIP ( i1 -- i2 n )
   DUP 'RR@  REG_ESP CELLS TRACEBACK + @ - CELL /
   TUCK SWAP - 1- ;

: .REGX ( n -- )
   CASE
      0 OF  ." EAX " REG_EAX  ENDOF
      1 OF  ." EBX " REG_EBX  ENDOF
      2 OF  ." ECX " REG_ECX  ENDOF
      3 OF  ." EDX " REG_EDX  ENDOF
      4 OF  ." ESI " REG_ESI  ENDOF
      5 OF  ." EDI " REG_EDI  ENDOF
      6 OF  ." EBP " REG_EBP  ENDOF
      7 OF  ." ESP " REG_ESP  ENDOF
      8 OF  ." EFL " REG_EFL  ENDOF
      9 OF  ." EIP " REG_EIP  ENDOF
   DROP  14 SPACES  EXIT  ENDCASE ( reg# in ucontext)
   CELLS TRACEBACK + @ H.8  SPACE SPACE ;

: .DS ( offset -- )
   #TRACE_REGS + #TRACE_RSTACK + CELLS
   TRACEBACK + @ H.8  SPACE SPACE ;

: .RS ( i1 -- i2 )
   #TRACE_RSTACK OVER < ?EXIT
   DUP 1+ SWAP 'RR@
   DUP H.8 SPACE  -ORIGIN CASE
      'CATCHER OF ." <<catcher>> "  ENDOF
      'R-ALLOC OF ." <<r-alloc>> "  .RSTACK-SKIP .  ENDOF
      'R-BUF   OF ." <<r-buf>> "    .RSTACK-SKIP .  ENDOF
      'LSPACE  OF ." <<locals>> "   .RSTACK-SKIP .  1+  ENDOF
      'OSPACE  OF ." <<object>> "   .LOCAL-OBJECTS  2+  ENDOF
   DUP ID.'  ENDCASE ;

PUBLIC

: .TRACEBACK ( -- )
   CR ." Registers     Dstack    esp+ Rstack  "
   0  20 0 DO
     CR I .REGX  I .DS   DUP CELLS 4 H.0 SPACE  .RS
   LOOP DROP ;

: .SIGNAL ( -- )
   BASE @ >R DECIMAL
   CR  ." Signal #"  SIGNAL# ?  ." at "  'SIGNAL @ DUP 8 H.0
   DUP ORIGIN HERE WITHIN IF  ."  in "  DUP .'  THEN DROP
   .TRACEBACK  R> BASE ! ;

: .THROW ( ior -- )
   DUP ERRORMSG  IOR_SIGNAL = IF  .TRACEBACK  THEN ;

' .THROW IS .CATCH

END-PACKAGE

\\
{ ----------------------------------------------------------------------
Tests for traceback dump
---------------------------------------------------------------------- }

: ZZ ( -- )   7 >R  33 R-ALLOC  9 >R  0 @  HERE . ;
: ZZZ ( -- )   3 >R  4 >R  ZZ  HERE . ;

: YY ( -- )   7 >R  R-BUF  9 >R  0 @ HERE . ;
: YYY ( -- )   3 >R  4 >R  YY HERE . ;

[UNDEFINED] POINT [IF]

CLASS POINT
   VARIABLE x
   VARIABLE y
END-CLASS

[THEN]

: XX ( -- )
   7 >R  [OBJECTS  POINT MAKES PT  OBJECTS]
   $11111111 PT X !  $55555555 PT Y !
   9 >R  0 @  HERE . ;

: WWW ( -- )   7 >R
   1 2 3 LOCALS| A B C | 9 >R  0 @  HERE . ;

