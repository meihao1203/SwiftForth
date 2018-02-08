{ ====================================================================
Optimizing compiler extensions for Swoop

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

This file supplies some optimizations for SWOOP code.
==================================================================== }

PACKAGE OPTIMIZING-COMPILER

PUBLIC

ICODE SELF ( -- addr )
   PUSH(EBX)
   'SELF [U] EBX MOV
   RET END-CODE

ICODE >S ( a -- )
   'SELF [U] PUSH
   EBX 'SELF [U] MOV
   POP(EBX)  RET END-CODE

ICODE S> ( -- )
   'SELF [U] POP  RET END-CODE

ICODE THIS ( -- addr )
   PUSH(EBX)
   'THIS [U] EBX MOV
   RET END-CODE

ICODE >C ( xt -- )
   'THIS [U] PUSH
   EBX 'THIS [U] MOV
   POP(EBX)
   RET END-CODE

ICODE C> ( -- )
   'THIS [U] POP
   RET END-CODE

ICODE >DATA ( xt -- object )
   3 CELLS 5 + [EDI] [EBX] EBX LEA
   RET END-CODE

ICODE >THIS ( class -- )
   EBX 'THIS [U] MOV
   POP(EBX)
   RET END-CODE

ICODE >SELF ( addr -- )
   EBX 'SELF [U] MOV
   POP(EBX)
   RET END-CODE

PRIVATE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

ICODE SELF->S ( -- )
   'SELF [U] PUSH
   RET END-CODE

OPTIMIZE SELF >S SUBSTITUTE SELF->S

OPTIMIZE S> >S

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: SELF-LIT+ ( -- )   [+ASM]
      PUSH(EBX)
      'SELF [U] EBX MOV
   [-ASM]
      LASTLIT @ IF
   [+ASM]
         LASTLIT @ # EBX ADD
   [-ASM]
      THEN ;

OPTIMIZE SELF LIT-PLUS WITH SELF-LIT+

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: SELF-LIT+LIT+ ( -- )
   LASTLIT 2@ + LASTLIT !
   SELF-LIT+
   ['] SELF-LIT+ XTHIST ! ;

OPTIMIZE SELF-LIT+ LIT-PLUS WITH SELF-LIT+LIT+


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: SELF-LIT-PLUS-! ( -- )   [+ASM]
      'SELF [U] EAX MOV
   [-ASM]
      LASTLIT @ IF
   [+ASM]
         LASTLIT @ # EAX ADD
   [-ASM]
      THEN
   [+ASM]
      EBX 0 [EAX] MOV
      POP(EBX)
   [-ASM] ;

OPTIMIZE SELF-LIT+ ! WITH SELF-LIT-PLUS-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT->DATA ( -- )   [+ASM]
      PUSH(EBX)
      LASTLIT @ 3 CELLS 5 + + [EDI] EBX LEA
   [-ASM] ;

OPTIMIZE (LITERAL) >DATA WITH LIT->DATA

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT->DATA->S ( -- )   [+ASM]
      'SELF [U] PUSH
      LASTLIT @ 3 CELLS 5 + + [EDI] EAX LEA
      EAX 'SELF [U] MOV
   [-ASM] ;

OPTIMIZE LIT->DATA >S WITH LIT->DATA->S

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT->DATA+ ( -- )
   LASTLIT 2@ + LASTLIT !
   LIT->DATA
   ['] LIT->DATA XTHIST ! ;


OPTIMIZE LIT->DATA LIT-PLUS WITH LIT->DATA+

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

ICODE THIS->C ( -- )
   'THIS [U] PUSH
   RET END-CODE

OPTIMIZE THIS >C SUBSTITUTE THIS->C

: LIT->C ( -- )   [+ASM]
      'THIS [U] PUSH
      LASTLIT @ # 'THIS [U] MOV
   [-ASM] ;

OPTIMIZE (LITERAL) >C WITH LIT->C

END-PACKAGE
