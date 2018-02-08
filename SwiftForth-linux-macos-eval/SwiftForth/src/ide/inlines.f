{ ====================================================================
Inline code for optimizer

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

These ICODE definitions are in support of the optimizer.
==================================================================== }

PACKAGE OPTIMIZING-COMPILER

ICODE DROP-R> ( n -- x )   ( R: x -- )
   EBX POP
   RET END-CODE

ICODE DROP-R@ ( n -- x )   ( R: x -- x )
   0 [ESP] EBX MOV
   RET END-CODE

ICODE >R-OVER ( a b c -- a b a )   ( r: -- c )
   EBX PUSH
   4 [EBP] EBX MOV
   RET END-CODE

ICODE >R-OVER-R> ( a b c -- a b a c )
   4 # EBP SUB
   8 [EBP] EAX MOV
   EAX 0 [EBP] MOV
   RET END-CODE

ICODE 2CELLS+ ( a -- a+8 )
   8 # EBX ADD
   RET END-CODE

ICODE SWAP-@ ( a x -- x n )
   0 [EBP] EAX MOV
   EBX 0 [EBP] MOV
   0 [EAX] EBX MOV
   RET END-CODE

ICODE SWAP-! ( a n -- )
   0 [EBP] EAX MOV
   EBX 0 [EAX] MOV
   4 [EBP] EBX MOV
   8 # EBP ADD
   RET END-CODE

ICODE SWAP-C! ( a c -- )
   0 [EBP] EAX MOV
   BL 0 [EAX] MOV
   4 [EBP] EBX MOV
   8 # EBP ADD
   RET END-CODE

ICODE ROT-! ( a x n -- x )
   4 [EBP] EAX MOV
   EBX 0 [EAX] MOV
   0 [EBP] EBX MOV
   8 # EBP ADD
   RET END-CODE

ICODE DUP?EXIT ( f -- f )
   EBX EBX OR
   0<> IF RET THEN
   RET END-CODE

ICODE DUP-EXIT ( f -- f )
   EBX EBX OR
   0= IF RET THEN
   RET END-CODE

ICODE ?DUP?EXIT ( f -- true )   ( f -- )
   EBX EBX OR
   0<> IF RET THEN
   POP(EBX)
   RET END-CODE

ICODE ?DUP-EXIT
   EBX EBX OR
   0= IF
      POP(EBX)
      RET
   THEN
   RET END-CODE

ICODE ?DUP-IF
   EBX EBX OR
   0= IF
      POP(EBX)
      HERE $400 + JMP
   THEN
   RET END-CODE

ICODE DUP-IF
   EBX EBX OR
   HERE $400 + JZ
   RET END-CODE

ICODE OVER-IF
   0 # 0 [EBP] CMP
   HERE $400 + JZ
   RET END-CODE

ICODE R@-IF ( -- )
   0 # 0 [ESP] CMP
   HERE $400 + JZ
   RET END-CODE

ICODE SWAP->R
   0 [EBP] PUSH
   4 # EBP ADD
   RET END-CODE

ICODE OVER->R
   0 [EBP] PUSH
   RET END-CODE

ICODE THIRD->R
   4 [EBP] PUSH
   RET END-CODE

ICODE ROT->R
   4 [EBP] PUSH
   0 [EBP] EAX MOV
   EAX 4 [EBP] MOV
   4 # EBP ADD
   RET END-CODE

ICODE >R-DUP
   EBX PUSH
   0 [EBP] EBX MOV
   RET END-CODE

ICODE DUP-R@
   8 # EBP SUB
   EBX 0 [EBP] MOV
   EBX 4 [EBP] MOV
   0 [ESP] EBX MOV
   RET END-CODE

ICODE @-SWAP
   0 [EBX] EAX MOV
   0 [EBP] EBX MOV
   EAX 0 [EBP] MOV
   RET END-CODE

ICODE OVER-R@
   8 # EBP SUB
   EBX 4 [EBP] MOV
   8 [EBP] EAX MOV
   EAX 0 [EBP] MOV
   0 [ESP] EBX MOV
   RET END-CODE

ICODE DOES>-SWAP
   4 # EBP SUB
   0 [EBP] POP
   RET END-CODE

ICODE ROT-2DROP
   0 [EBP] EBX MOV
   8 # EBP ADD
   RET END-CODE

ICODE -ROT-2DROP
   8 # EBP ADD
   RET END-CODE

ICODE @+-+
   0 [EBX] EAX MOV
   4 [EBX] [EAX] EBX LEA
   RET END-CODE

ICODE @IF
   0 [EBX] EAX MOV
   0 [EBP] EBX MOV
   4 # EBP ADD
   EAX EAX OR
   HERE $400 + JZ
   RET END-CODE

ICODE C@IF
   0 [EBX] AL MOV
   0 [EBP] EBX MOV
   4 # EBP ADD
   AL AL OR
   HERE $400 + JZ
   RET END-CODE

ICODE DROP-OVER
   4 [EBP] EBX MOV
   RET END-CODE

ICODE DROP-DUP
   0 [EBP] EBX MOV
   RET END-CODE

ICODE COUNT-+
   EAX EAX XOR
   0 [EBX] AL MOV
   1 [EBX] [EAX] EBX LEA
   RET END-CODE

ICODE !-R>
   0 [EBP] EAX MOV
   EAX 0 [EBX] MOV
   EBX POP
   4 # EBP ADD
   RET END-CODE

ICODE DUP-@
   PUSH(EBX)
   0 [EBX] EBX MOV
   RET END-CODE

ICODE R@-SWAP
   4 # EBP SUB
   0 [ESP] EAX MOV
   EAX 0 [EBP] MOV
   RET END-CODE

ICODE TUCK! ( n a -- a )
   0 [EBP] EAX MOV
   EAX 0 [EBX] MOV
   4 # EBP ADD
   RET END-CODE

ICODE CELL+@ ( a -- n )
   4 [EBX] EBX MOV
   RET END-CODE

ICODE CELL+_! ( n a -- )
   0 [EBP] EAX MOV
   EAX 4 [EBX] MOV
   4 [EBP] EBX MOV
   8 # EBP ADD
   RET END-CODE

ICODE I@ ( -- n )
   4 # EBP SUB
   EBX 0 [EBP] MOV
   0 [ESP] EAX MOV
   4 [ESP] EAX ADD
   0 [EAX] EBX MOV
   RET END-CODE

ICODE IC@ ( -- n )
   4 # EBP SUB
   EBX 0 [EBP] MOV
   EBX EBX XOR
   0 [ESP] EAX MOV
   4 [ESP] EAX ADD
   0 [EAX] BL MOV
   RET END-CODE

ICODE UNDER ( a b -- a a b )
   0 [EBP] EAX MOV
   4 # EBP SUB
   EAX 0 [EBP] MOV
   RET END-CODE

ICODE 2@SWAP ( a -- hi lo )
   4 # EBP SUB
   0 [EBX] EAX MOV
   4 [EBX] EBX MOV
   EAX 0 [EBP] MOV
   RET END-CODE

ICODE 2DUP-SWAP ( a b -- a b b a )
   8 # EBP SUB
   EBX 4 [EBP] MOV
   EBX 0 [EBP] MOV
   8 [EBP] EBX MOV
   RET END-CODE

ICODE NIPNIP ( a b c -- c )
   8 # EBP ADD
   RET END-CODE

PUBLIC

ICODE 4DROP ( a b c d -- )
   12 [EBP] EBX MOV                  \ load new tos
   16 # EBP ADD                     \ and clean up stack
   RET END-CODE

ICODE R++
   1 # 0 [ESP] ADD
   RET END-CODE

END-PACKAGE
