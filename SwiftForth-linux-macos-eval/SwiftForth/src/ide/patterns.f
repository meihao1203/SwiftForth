{ ====================================================================
patterns.f
Optimizer patterns

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

PACKAGE OPTIMIZING-COMPILER

OPTIMIZE NIP NIP       SUBSTITUTE NIPNIP
OPTIMIZE OVER SWAP     SUBSTITUTE UNDER
OPTIMIZE DROP DROP     SUBSTITUTE 2DROP
OPTIMIZE 2DROP DROP    SUBSTITUTE 3DROP
OPTIMIZE DROP 2DROP    SUBSTITUTE 3DROP
OPTIMIZE 2DROP 2DROP   SUBSTITUTE 4DROP
OPTIMIZE I C@          SUBSTITUTE IC@
OPTIMIZE I @           SUBSTITUTE I@
OPTIMIZE CELL+ @       SUBSTITUTE CELL+@
OPTIMIZE TUCK !        SUBSTITUTE TUCK!
OPTIMIZE TUCK! CELL+   SUBSTITUTE ~!+
OPTIMIZE ~!+ !         SUBSTITUTE 2!
OPTIMIZE CELL+ !       SUBSTITUTE CELL+_!
OPTIMIZE >R OVER       SUBSTITUTE >R-OVER
OPTIMIZE >R-OVER R>    SUBSTITUTE >R-OVER-R>
OPTIMIZE R@ SWAP       SUBSTITUTE R@-SWAP
OPTIMIZE DUP +         SUBSTITUTE 2*
OPTIMIZE ! R>          SUBSTITUTE !-R>
OPTIMIZE SWAP -        SUBSTITUTE SWAP-
OPTIMIZE OVER OVER     SUBSTITUTE 2DUP
OPTIMIZE ROT ROT       SUBSTITUTE -ROT
OPTIMIZE R@ (IF)       SUBSTITUTE R@-IF
OPTIMIZE ?DUP (IF)     SUBSTITUTE ?DUP-IF
OPTIMIZE DUP (IF)      SUBSTITUTE DUP-IF
OPTIMIZE SWAP !        SUBSTITUTE SWAP-!
OPTIMIZE SWAP C!       SUBSTITUTE SWAP-C!
OPTIMIZE ROT !         SUBSTITUTE ROT-!
OPTIMIZE DROP R>       SUBSTITUTE DROP-R>
OPTIMIZE DROP R@       SUBSTITUTE DROP-R@
OPTIMIZE DUP >R        SUBSTITUTE DUP>R
OPTIMIZE >R R@         SUBSTITUTE DUP>R
OPTIMIZE R> DROP       SUBSTITUTE R>DROP
OPTIMIZE SWAP DROP     SUBSTITUTE NIP
OPTIMIZE SWAP OVER     SUBSTITUTE TUCK
OPTIMIZE CELL+ CELL+   SUBSTITUTE 2CELLS+
OPTIMIZE ?DUP ?EXIT    SUBSTITUTE ?DUP?EXIT
OPTIMIZE ?DUP -EXIT    SUBSTITUTE ?DUP-EXIT
OPTIMIZE DUP ?EXIT     SUBSTITUTE DUP?EXIT
OPTIMIZE DUP -EXIT     SUBSTITUTE DUP-EXIT
OPTIMIZE >R DUP        SUBSTITUTE >R-DUP
OPTIMIZE DUP R@        SUBSTITUTE DUP-R@
OPTIMIZE @ SWAP        SUBSTITUTE @-SWAP
OPTIMIZE OVER R@       SUBSTITUTE OVER-R@
OPTIMIZE (DOES>) SWAP  SUBSTITUTE DOES>-SWAP
OPTIMIZE ROT 2DROP     SUBSTITUTE ROT-2DROP
OPTIMIZE -ROT 2DROP    SUBSTITUTE -ROT-2DROP
OPTIMIZE @+ +          SUBSTITUTE @+-+
OPTIMIZE @ (IF)        SUBSTITUTE @IF
OPTIMIZE C@ (IF)       SUBSTITUTE C@IF
OPTIMIZE 2SWAP 2DROP   SUBSTITUTE 2NIP
OPTIMIZE DROP DUP      SUBSTITUTE DROP-DUP
OPTIMIZE DROP OVER     SUBSTITUTE DROP-OVER
OPTIMIZE COUNT +       SUBSTITUTE COUNT-+
OPTIMIZE OVER (IF)     SUBSTITUTE OVER-IF
OPTIMIZE ROT >R        SUBSTITUTE ROT->R
OPTIMIZE DUP @         SUBSTITUTE DUP-@
OPTIMIZE RP@ ++        SUBSTITUTE R++
OPTIMIZE 2DUP SWAP     SUBSTITUTE 2DUP-SWAP
OPTIMIZE SWAP @        SUBSTITUTE SWAP-@

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: NIP-LITERAL ( -- )   [+ASM]
      EBX 0 [EBP] MOV
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE NIP (LITERAL) WITH NIP-LITERAL

: NIPNIP-LITERAL ( -- )   [+ASM]
      4 # EBP ADD
      EBX 0 [EBP] MOV
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE NIPNIP (LITERAL) WITH NIPNIP-LITERAL

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: UNDER- ( -- )   [+ASM]
      EBX NEG
      0 [EBP] EBX ADD
   [-ASM] ;

OPTIMIZE UNDER - WITH UNDER-

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }


: LIT-COMPARE ( -- )   [+ASM]
      LASTLIT @ # EBX CMP
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE (LITERAL) <     WITH LIT-COMPARE   ASSEMBLE JGE
OPTIMIZE (LITERAL) >     WITH LIT-COMPARE   ASSEMBLE JLE
OPTIMIZE (LITERAL) <=    WITH LIT-COMPARE   ASSEMBLE JG
OPTIMIZE (LITERAL) >=    WITH LIT-COMPARE   ASSEMBLE JL
OPTIMIZE (LITERAL) =     WITH LIT-COMPARE   ASSEMBLE JNZ
OPTIMIZE (LITERAL) <>    WITH LIT-COMPARE   ASSEMBLE JZ
OPTIMIZE (LITERAL) U<    WITH LIT-COMPARE   ASSEMBLE JAE
OPTIMIZE (LITERAL) U>    WITH LIT-COMPARE   ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R@-LIT-COMP ( -- )   [+ASM]
      PUSH(EBX)
      LASTLIT @ # 0 [ESP] CMP
      0 # EBX MOV
      HERE 3 + 1 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE R@ LIT-COMPARE  WITH R@-LIT-COMP

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R@-LIT-COMP-IF ( -- )   [+ASM]
      LASTLIT @ # 0 [ESP] CMP
      HERE $400 + 2 RULEX
   [-ASM] ;

OPTIMIZE R@-LIT-COMP (IF) WITH R@-LIT-COMP-IF


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DUP-COMPARE ( -- )   [+ASM]
      PUSH(EBX)
      EBX 4 [EBP] CMP
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE 2DUP <     WITH 2DUP-COMPARE   ASSEMBLE JGE
OPTIMIZE 2DUP >     WITH 2DUP-COMPARE   ASSEMBLE JLE
OPTIMIZE 2DUP <=    WITH 2DUP-COMPARE   ASSEMBLE JG
OPTIMIZE 2DUP >=    WITH 2DUP-COMPARE   ASSEMBLE JL
OPTIMIZE 2DUP =     WITH 2DUP-COMPARE   ASSEMBLE JNZ
OPTIMIZE 2DUP <>    WITH 2DUP-COMPARE   ASSEMBLE JZ
OPTIMIZE 2DUP U<    WITH 2DUP-COMPARE   ASSEMBLE JAE
OPTIMIZE 2DUP U>    WITH 2DUP-COMPARE   ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: STACK-COMP ( n -- )   [+ASM]
      ( n) [EBP] EBX CMP
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

: OVER-COMP 0 STACK-COMP ;
: THIRD-COMP  4 STACK-COMP ;

OPTIMIZE OVER <      WITH OVER-COMP  ASSEMBLE JGE
OPTIMIZE OVER >      WITH OVER-COMP  ASSEMBLE JLE
OPTIMIZE OVER <=     WITH OVER-COMP  ASSEMBLE JG
OPTIMIZE OVER >=     WITH OVER-COMP  ASSEMBLE JL
OPTIMIZE OVER =      WITH OVER-COMP  ASSEMBLE JNZ
OPTIMIZE OVER <>     WITH OVER-COMP  ASSEMBLE JZ
OPTIMIZE OVER U<     WITH OVER-COMP  ASSEMBLE JAE
OPTIMIZE OVER U>     WITH OVER-COMP  ASSEMBLE JBE

OPTIMIZE THIRD <     WITH THIRD-COMP  ASSEMBLE JGE
OPTIMIZE THIRD >     WITH THIRD-COMP  ASSEMBLE JLE
OPTIMIZE THIRD <=    WITH THIRD-COMP  ASSEMBLE JG
OPTIMIZE THIRD >=    WITH THIRD-COMP  ASSEMBLE JL
OPTIMIZE THIRD =     WITH THIRD-COMP  ASSEMBLE JNZ
OPTIMIZE THIRD <>    WITH THIRD-COMP  ASSEMBLE JZ
OPTIMIZE THIRD U<    WITH THIRD-COMP  ASSEMBLE JAE
OPTIMIZE THIRD U>    WITH THIRD-COMP  ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: OVER-COMP-IF ( -- )   [+ASM]
      0 [EBP] EBX CMP
      0 [EBP] EBX MOV
      4 [EBP] EBP LEA
      HERE $400 + 1 RULEX
   [-ASM] ;


OPTIMIZE OVER-COMP (IF) WITH OVER-COMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: SWAP-COMP ( -- )   [+ASM]
      0 [EBP] EBX CMP
      4 [EBP] EBP LEA
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE SWAP <      WITH SWAP-COMP  ASSEMBLE JGE
OPTIMIZE SWAP >      WITH SWAP-COMP  ASSEMBLE JLE
OPTIMIZE SWAP <=     WITH SWAP-COMP  ASSEMBLE JG
OPTIMIZE SWAP >=     WITH SWAP-COMP  ASSEMBLE JL
OPTIMIZE SWAP =      WITH SWAP-COMP  ASSEMBLE JNZ
OPTIMIZE SWAP <>     WITH SWAP-COMP  ASSEMBLE JZ
OPTIMIZE SWAP U<     WITH SWAP-COMP  ASSEMBLE JAE
OPTIMIZE SWAP U>     WITH SWAP-COMP  ASSEMBLE JBE

: SWAP-COMP-IF ( -- )   [+ASM]
      0 [EBP] EBX CMP
      4 [EBP] EBX MOV
      8 [EBP] EBP LEA
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE SWAP-COMP (IF) WITH SWAP-COMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-MATH ( -- )   [+ASM]
      LASTLIT @ # EBX 0 RULEX
   [-ASM] ;

OPTIMIZE (LITERAL) -    WITH LIT-MATH  ASSEMBLE SUB
OPTIMIZE (LITERAL) AND  WITH LIT-MATH  ASSEMBLE AND
OPTIMIZE (LITERAL) OR   WITH LIT-MATH  ASSEMBLE OR
OPTIMIZE (LITERAL) XOR  WITH LIT-MATH  ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }


: LIT-PLUS ( -- )   [+ASM]
      LASTLIT @ # EBX ADD
   [-ASM] ;

OPTIMIZE (LITERAL) +    WITH LIT-PLUS

: LIT+LIT+ ( -- )   [+ASM]
      LASTLIT 2@ + LASTLIT !
      LASTLIT @ # EBX ADD
   [-ASM]
   ['] LIT-PLUS XTHIST ! ;

OPTIMIZE LIT-PLUS LIT-PLUS WITH LIT+LIT+

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R>-MATH ( -- )   [+ASM]
      EAX POP
      EAX EBX 0 RULEX
   [-ASM] ;

OPTIMIZE R> +   WITH R>-MATH ASSEMBLE ADD
OPTIMIZE R> -   WITH R>-MATH ASSEMBLE SUB
OPTIMIZE R> AND WITH R>-MATH ASSEMBLE AND
OPTIMIZE R> OR  WITH R>-MATH ASSEMBLE OR
OPTIMIZE R> XOR WITH R>-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R@-MATH ( -- )   [+ASM]
      0 [ESP] EBX 0 RULEX
   [-ASM] ;

OPTIMIZE R@ +   WITH R@-MATH ASSEMBLE ADD
OPTIMIZE R@ -   WITH R@-MATH ASSEMBLE SUB
OPTIMIZE R@ AND WITH R@-MATH ASSEMBLE AND
OPTIMIZE R@ OR  WITH R@-MATH ASSEMBLE OR
OPTIMIZE R@ XOR WITH R@-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: MATH-DUP ( -- )   [+ASM]
      0 [EBP] EBX 0 RULEX
      EBX 0 [EBP] MOV
   [-ASM] ;

OPTIMIZE +   DUP WITH MATH-DUP ASSEMBLE ADD
OPTIMIZE AND DUP WITH MATH-DUP ASSEMBLE AND
OPTIMIZE OR  DUP WITH MATH-DUP ASSEMBLE OR
OPTIMIZE XOR DUP WITH MATH-DUP ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: STACK-MATH ( n -- )   [+ASM]
      ( n) [EBP] EBX 0 RULEX
   [-ASM] ;

: OVER-MATH   0 STACK-MATH ;
: THIRD-MATH   4 STACK-MATH ;


OPTIMIZE OVER +    WITH  OVER-MATH ASSEMBLE ADD
OPTIMIZE OVER -    WITH  OVER-MATH ASSEMBLE SUB
OPTIMIZE OVER AND  WITH  OVER-MATH ASSEMBLE AND
OPTIMIZE OVER OR   WITH  OVER-MATH ASSEMBLE OR
OPTIMIZE OVER XOR  WITH  OVER-MATH ASSEMBLE XOR

OPTIMIZE THIRD +   WITH  THIRD-MATH ASSEMBLE ADD
OPTIMIZE THIRD -   WITH  THIRD-MATH ASSEMBLE SUB
OPTIMIZE THIRD AND WITH  THIRD-MATH ASSEMBLE AND
OPTIMIZE THIRD OR  WITH  THIRD-MATH ASSEMBLE OR
OPTIMIZE THIRD XOR WITH  THIRD-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: MATH->R ( -- )   [+ASM]
      0 [EBP] EBX 0 RULEX
      EBX PUSH
      4 [EBP] EBX MOV
      8 # EBP ADD
   [-ASM] ;

OPTIMIZE +   >R  WITH  MATH->R ASSEMBLE ADD
OPTIMIZE AND >R  WITH  MATH->R ASSEMBLE AND
OPTIMIZE OR  >R  WITH  MATH->R ASSEMBLE OR
OPTIMIZE XOR >R  WITH  MATH->R ASSEMBLE XOR


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DUP-OVER ( -- )   [+ASM]
      12 # EBP SUB    
      EBX 0 [EBP] MOV  
      EBX 8 [EBP] MOV  
      12 [EBP] EBX MOV  
      EBX 4 [EBP] MOV  
   [-ASM] ;

OPTIMIZE 2DUP OVER WITH 2DUP-OVER

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2OVER-MATH ( -- )   [+ASM]
      PUSH(EBX)
      12 [EBP] EBX MOV
      8 [EBP] EBX 0 RULEX
   [-ASM] ;

OPTIMIZE 2OVER +   WITH  2OVER-MATH ASSEMBLE ADD
OPTIMIZE 2OVER -   WITH  2OVER-MATH ASSEMBLE SUB
OPTIMIZE 2OVER AND WITH  2OVER-MATH ASSEMBLE AND
OPTIMIZE 2OVER OR  WITH  2OVER-MATH ASSEMBLE OR
OPTIMIZE 2OVER XOR WITH  2OVER-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DUP-MATH ( -- )   [+ASM]
      PUSH(EBX)
      4 [EBP] EAX MOV
      EBX EAX 0 RULEX
      EAX EBX MOV
   [-ASM] ;

OPTIMIZE 2DUP +   WITH  2DUP-MATH ASSEMBLE ADD
OPTIMIZE 2DUP -   WITH  2DUP-MATH ASSEMBLE SUB
OPTIMIZE 2DUP AND WITH  2DUP-MATH ASSEMBLE AND
OPTIMIZE 2DUP OR  WITH  2DUP-MATH ASSEMBLE OR
OPTIMIZE 2DUP XOR WITH  2DUP-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DUP-MATH->R ( -- )   [+ASM]
      0 [EBP] EAX MOV
      EBX EAX 1 RULEX
      EAX PUSH
   [-ASM] ;

OPTIMIZE 2DUP-MATH >R WITH 2DUP-MATH->R

: 2OVER-MATH->R ( -- )   [+ASM]
      8 [EBP] EAX MOV
      4 [EBP] EAX 1 RULEX
      EAX PUSH
   [-ASM] ;

OPTIMIZE 2OVER-MATH >R WITH 2OVER-MATH->R

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R@-COMP ( -- )   [+ASM]
      0 [ESP] EBX CMP
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE R@ <      WITH R@-COMP  ASSEMBLE JGE
OPTIMIZE R@ >      WITH R@-COMP  ASSEMBLE JLE
OPTIMIZE R@ <=     WITH R@-COMP  ASSEMBLE JG
OPTIMIZE R@ >=     WITH R@-COMP  ASSEMBLE JL
OPTIMIZE R@ =      WITH R@-COMP  ASSEMBLE JNZ
OPTIMIZE R@ <>     WITH R@-COMP  ASSEMBLE JZ
OPTIMIZE R@ U<     WITH R@-COMP  ASSEMBLE JAE
OPTIMIZE R@ U>     WITH R@-COMP  ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R>-COMP ( -- )   [+ASM]
      EAX POP
      EAX EBX CMP
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE R> <      WITH R>-COMP  ASSEMBLE JGE
OPTIMIZE R> >      WITH R>-COMP  ASSEMBLE JLE
OPTIMIZE R> <=     WITH R>-COMP  ASSEMBLE JG
OPTIMIZE R> >=     WITH R>-COMP  ASSEMBLE JL
OPTIMIZE R> =      WITH R>-COMP  ASSEMBLE JNZ
OPTIMIZE R> <>     WITH R>-COMP  ASSEMBLE JZ
OPTIMIZE R> U<     WITH R>-COMP  ASSEMBLE JAE
OPTIMIZE R> U>     WITH R>-COMP  ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: R@-CMP-IF ( -- )   [+ASM]
      0 [ESP] EBX CMP
      0 [EBP] EBX MOV
      4 [EBP] EBP LEA
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE R@-COMP (IF) WITH R@-CMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: #-CMP-IF ( -- )   [+ASM]
      LASTLIT @ # EBX CMP
      0 [EBP] EBX MOV
      4 [EBP] EBP LEA
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE LIT-COMPARE (IF) WITH #-CMP-IF


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: OVER-C@ ( -- )   [+ASM]
      4 # EBP SUB
      EBX 0 [EBP] MOV
      4 [EBP] EAX MOV
      EBX EBX XOR
      0 [EAX] BL MOV
   [-ASM] ;

OPTIMIZE OVER C@ WITH OVER-C@

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: OVER-C@-#-CMP-IF ( -- )   [+ASM]
      0 [EBP] EAX MOV
      0 [EAX] AL MOV
      LASTLIT @ # AL CMP
      HERE $400 + 2 RULEX
   [-ASM] ;

OPTIMIZE OVER-C@ #-CMP-IF WITH OVER-C@-#-CMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DUP-CMP-IF ( -- )   [+ASM]
      EBX 0 [EBP] CMP
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE 2DUP-COMPARE (IF) WITH 2DUP-CMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-#-CMP-IF ( -- )
   [+ASM]
      LASTLIT @ # EBX CMP
      HERE $400 + 2 RULEX
   [-ASM] ;

OPTIMIZE DUP #-CMP-IF WITH DUP-#-CMP-IF

: OVER-#-CMP-IF ( -- )   [+ASM]
      LASTLIT @ # 0 [EBP] CMP
      HERE $400 + 2 RULEX
   [-ASM] ;

OPTIMIZE OVER #-CMP-IF WITH OVER-#-CMP-IF

: THIRD-#-CMP-IF ( -- )   [+ASM]
      LASTLIT @ # 4 [EBP] CMP
      HERE $400 + 2 RULEX
   [-ASM] ;

OPTIMIZE THIRD #-CMP-IF WITH THIRD-#-CMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: MATH-IF ( -- )   [+ASM]
        0 [EBP] EBX 0 RULEX
        4 [EBP] EBX MOV
        8 [EBP] EBP LEA
        HERE $400 + JZ
   [-ASM] ;

OPTIMIZE +   (IF) WITH MATH-IF  ASSEMBLE ADD
OPTIMIZE -   (IF) WITH MATH-IF  ASSEMBLE SUB
OPTIMIZE AND (IF) WITH MATH-IF  ASSEMBLE AND
OPTIMIZE OR  (IF) WITH MATH-IF  ASSEMBLE OR
OPTIMIZE XOR (IF) WITH MATH-IF  ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: STACK-MATH-IF ( n -- )   [+ASM]
        ( n) [EBP] EBX 1 RULEX
        0 [EBP] EBX MOV
        4 [EBP] EBP LEA
        HERE $400 + JZ
   [-ASM] ;

: OVER-MATH-IF   0 STACK-MATH-IF ;
: THIRD-MATH-IF   4 STACK-MATH-IF ;

OPTIMIZE OVER  MATH-IF WITH OVER-MATH-IF
OPTIMIZE THIRD MATH-IF WITH THIRD-MATH-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-UNARY ( -- )   [+ASM]
      PUSH(EBX)
      EBX EBX OR
      0 # EBX MOV
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE DUP 0=  WITH DUP-UNARY ASSEMBLE JNZ
OPTIMIZE DUP 0<> WITH DUP-UNARY ASSEMBLE JZ
OPTIMIZE DUP 0<  WITH DUP-UNARY ASSEMBLE JNS
OPTIMIZE DUP 0>  WITH DUP-UNARY ASSEMBLE JLE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: OVER-UNARY ( -- )   [+ASM]
      PUSH(EBX)
      EBX EBX XOR
      0 # 4 [EBP] CMP
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE OVER 0=  WITH OVER-UNARY ASSEMBLE JNZ
OPTIMIZE OVER 0<> WITH OVER-UNARY ASSEMBLE JZ
OPTIMIZE OVER 0<  WITH OVER-UNARY ASSEMBLE JNS
OPTIMIZE OVER 0>  WITH OVER-UNARY ASSEMBLE JLE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: THIRD-UNARY ( -- )   [+ASM]
      PUSH(EBX)
      EBX EBX XOR
      0 # 8 [EBP] CMP
      HERE 3 + 0 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE THIRD 0=  WITH THIRD-UNARY ASSEMBLE JNZ
OPTIMIZE THIRD 0<> WITH THIRD-UNARY ASSEMBLE JZ
OPTIMIZE THIRD 0<  WITH THIRD-UNARY ASSEMBLE JNS
OPTIMIZE THIRD 0>  WITH THIRD-UNARY ASSEMBLE JLE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: UNARY-IF ( -- )   [+ASM]
      EBX EBX OR
      0 [EBP] EBX MOV
      4 [EBP] EBP LEA
      HERE $400 + 0 RULEX
   [-ASM] ;

OPTIMIZE 0=  (IF) WITH UNARY-IF ASSEMBLE JNZ
OPTIMIZE 0<> (IF) WITH UNARY-IF ASSEMBLE JZ
OPTIMIZE 0<  (IF) WITH UNARY-IF ASSEMBLE JNS
OPTIMIZE 0>  (IF) WITH UNARY-IF ASSEMBLE JLE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: CMP-IF ( -- )   [+ASM]
      EBX 0 [EBP] CMP
      4 [EBP] EBX MOV
      8 [EBP] EBP LEA
      HERE $400 + 0 RULEX
   [-ASM] ;

OPTIMIZE <  (IF)    WITH CMP-IF   ASSEMBLE JGE
OPTIMIZE >  (IF)    WITH CMP-IF   ASSEMBLE JLE
OPTIMIZE <= (IF)    WITH CMP-IF   ASSEMBLE JG
OPTIMIZE >= (IF)    WITH CMP-IF   ASSEMBLE JL
OPTIMIZE =  (IF)    WITH CMP-IF   ASSEMBLE JNZ
OPTIMIZE <> (IF)    WITH CMP-IF   ASSEMBLE JZ
OPTIMIZE U< (IF)    WITH CMP-IF   ASSEMBLE JAE
OPTIMIZE U> (IF)    WITH CMP-IF   ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: CMP-?EXIT ( -- )   [+ASM]
      EBX 0 [EBP] CMP
      4 [EBP] EBX MOV
      8 [EBP] EBP LEA
      HERE 3 + 0 RULEX
      RET
   [-ASM] ;

OPTIMIZE <  ?EXIT    WITH CMP-?EXIT   ASSEMBLE JGE
OPTIMIZE >  ?EXIT    WITH CMP-?EXIT   ASSEMBLE JLE
OPTIMIZE <= ?EXIT    WITH CMP-?EXIT   ASSEMBLE JG
OPTIMIZE >= ?EXIT    WITH CMP-?EXIT   ASSEMBLE JL
OPTIMIZE =  ?EXIT    WITH CMP-?EXIT   ASSEMBLE JNZ
OPTIMIZE <> ?EXIT    WITH CMP-?EXIT   ASSEMBLE JZ
OPTIMIZE U< ?EXIT    WITH CMP-?EXIT   ASSEMBLE JAE
OPTIMIZE U> ?EXIT    WITH CMP-?EXIT   ASSEMBLE JBE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-R@-CMP-IF ( -- )
   [+ASM]
      0 [ESP] EBX CMP
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE DUP-R@ CMP-IF WITH DUP-R@-CMP-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-UNARY-IF ( -- )   [+ASM]
      EBX EBX OR
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE DUP-UNARY (IF) WITH DUP-UNARY-IF

: OVER-UNARY-IF ( -- )   [+ASM]
      0 # 0 [EBP] CMP
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE OVER-UNARY (IF) WITH OVER-UNARY-IF

: THIRD-UNARY-IF ( -- )   [+ASM]
      0 # 4 [EBP] CMP
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE THIRD-UNARY (IF) WITH THIRD-UNARY-IF

{ --------------------------------------------------------------------
OVER CELL + !
-------------------------------------------------------------------- }

: PLUS-! ( -- )   [+ASM]
      0 [EBP] EAX MOV
      4 [EBP] ECX MOV
      ECX 0 [EBX] [EAX] MOV
      8 [EBP] EBX MOV
      12 # EBP ADD
   [-ASM] ;

OPTIMIZE + ! WITH PLUS-!

: LIT-MATH-! ( -- )   [+ASM]
      0 [EBP] EAX MOV
      LASTLIT @ # EBX 1 RULEX
      EAX 0 [EBX] MOV
      4 [EBP] EBX MOV
      8 # EBP ADD
   [-ASM] ;

OPTIMIZE LIT-MATH ! WITH LIT-MATH-!

: OVER-LIT-MATH-! ( -- )   [+ASM]
      4 [EBP] EAX MOV
      LASTLIT @ # EAX 2 RULEX
      EBX 0 [EAX] MOV
      POP(EBX)
   [-ASM] ;

OPTIMIZE OVER LIT-MATH-! WITH OVER-LIT-MATH-!

: DUP-@-OVER-LIT-MATH-! ( -- )   [+ASM]
      0 [EBX] EDX MOV
      EBX EAX MOV
      LASTLIT @ # EAX 3 RULEX
      EDX 0 [EAX] MOV
   [-ASM] ;

OPTIMIZE DUP-@ OVER-LIT-MATH-! WITH DUP-@-OVER-LIT-MATH-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-LIT ( -- )   [+ASM]
      8 # EBP SUB
      EBX 0 [EBP] MOV
      EBX 4 [EBP] MOV
      LASTLIT @ # EBX MOV
   [-ASM] ;


\ OPTIMIZE DUP (LITERAL) WITH DUP-LIT

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-PICK ( -- )   [+ASM]
      PUSH(EBX)
      LASTLIT @ CELLS [EBP] EBX MOV
   [-ASM] ;

OPTIMIZE (LITERAL) PICK WITH LIT-PICK

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DROP-LIT ( -- )   [+ASM]
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE DROP (LITERAL) WITH DROP-LIT

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT->R ( -- )   [+ASM]
      LASTLIT @ # PUSH
   [-ASM] ;

OPTIMIZE (LITERAL) >R WITH LIT->R

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: >R-LIT ( -- )   [+ASM]
      EBX PUSH
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE >R (LITERAL) WITH >R-LIT

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-CELLS ( -- )   [+ASM]
      PUSH(EBX)
      LASTLIT @ CELLS # EBX MOV
      LASTLIT @ CELLS LASTLIT !
   [-ASM]
   ['] (LITERAL) XTHIST ! ;

OPTIMIZE (LITERAL) CELLS WITH LIT-CELLS

: LIT-CELLS+ ( -- )   [+ASM]
      LASTLIT @ CELLS # EBX ADD
   [-ASM] ;

OPTIMIZE LIT-CELLS + WITH LIT-CELLS+

: CELLS+@ ( -- )   [+ASM]
      LASTLIT @ CELLS [EBX] EBX MOV
   [-ASM] ;

OPTIMIZE LIT-CELLS+ @ WITH CELLS+@

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-SWAP ( -- )   [+ASM]
      4 # EBP SUB
      LASTLIT @ # 0 [EBP] MOV
   [-ASM] ;

OPTIMIZE (LITERAL) SWAP WITH LIT-SWAP

: LIT-SWAP-! ( -- )   [+ASM]
      LASTLIT @ # 0 [EBX] MOV
      POP(EBX)
   [-ASM] ;

: LIT-SWAP-C! ( -- )   [+ASM]
      LASTLIT @ # 0 [EBX] BYTE MOV
      POP(EBX)
   [-ASM] ;

OPTIMIZE LIT-SWAP !  WITH LIT-SWAP-!
OPTIMIZE LIT-SWAP C! WITH LIT-SWAP-C!


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-SHIFT ( -- )   [+ASM]
      EBX LASTLIT @ # 0 RULEX
   [-ASM] ;

OPTIMIZE (LITERAL) LSHIFT WITH LIT-SHIFT ASSEMBLE SHL
OPTIMIZE (LITERAL) RSHIFT WITH LIT-SHIFT ASSEMBLE SHR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-STAR ( -- )   [+ASM]
      LASTLIT @ # EAX MOV
      EBX MUL
      EAX EBX MOV
   [-ASM] ;

: LIT-DIV ( -- )   [+ASM]
      EBX EAX MOV
      CDQ
      LASTLIT @ # EBX MOV
      EBX IDIV
      EAX EBX MOV
   [-ASM] ;

: LIT-MOD ( -- )   [+ASM]
      EBX EAX MOV
      CDQ
      LASTLIT @ # EBX MOV
      EBX IDIV
      EDX EBX MOV
   [-ASM] ;

OPTIMIZE (LITERAL) *   WITH LIT-STAR
OPTIMIZE (LITERAL) /   WITH LIT-DIV
OPTIMIZE (LITERAL) MOD WITH LIT-MOD

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DROP-LIT ( -- )   [+ASM]
      4 # EBP ADD
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE 2DROP (LITERAL) WITH 2DROP-LIT

: 3DROP-LIT ( -- )   [+ASM]
      8 # EBP ADD
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE 3DROP (LITERAL) WITH 3DROP-LIT

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-/STRING ( -- )   [+ASM]
      LASTLIT @ # 0 [EBP] ADD
      LASTLIT @ # EBX SUB
   [-ASM] ;

OPTIMIZE (LITERAL) /STRING WITH LIT-/STRING

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: I-MATH ( -- )   [+ASM]
      0 [ESP] EAX MOV
      4 [ESP] EAX ADD
      EAX EBX 0 RULEX
   [-ASM] ;

OPTIMIZE I +     WITH I-MATH ASSEMBLE ADD
OPTIMIZE I -     WITH I-MATH ASSEMBLE SUB
OPTIMIZE I AND   WITH I-MATH ASSEMBLE AND
OPTIMIZE I OR    WITH I-MATH ASSEMBLE OR
OPTIMIZE I XOR   WITH I-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: I@-MATH ( -- )   [+ASM]
      0 [ESP] EAX MOV
      4 [ESP] EAX ADD
      0 [EAX] EBX 0 RULEX
   [-ASM] ;

OPTIMIZE I@ +   WITH I@-MATH ASSEMBLE ADD
OPTIMIZE I@ AND WITH I@-MATH ASSEMBLE AND
OPTIMIZE I@ OR  WITH I@-MATH ASSEMBLE OR
OPTIMIZE I@ XOR WITH I@-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: IC@-MATH ( -- )   [+ASM]
      EDX EDX XOR
      0 [ESP] EAX MOV
      4 [ESP] EAX ADD
      0 [EAX] DL MOV
      EDX EBX 0 RULEX
   [-ASM] ;

OPTIMIZE IC@ +   WITH IC@-MATH ASSEMBLE ADD
OPTIMIZE IC@ AND WITH IC@-MATH ASSEMBLE AND
OPTIMIZE IC@ OR  WITH IC@-MATH ASSEMBLE OR
OPTIMIZE IC@ XOR WITH IC@-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: TWO-LITERALS ( -- )   [+ASM]
      8 # EBP SUB
      EBX 4 [EBP] MOV
      LASTLIT CELL+ @ # 0 [EBP] MOV
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE (LITERAL) (LITERAL) WITH TWO-LITERALS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2LIT-MATH ( -- )
   LASTLIT 2@ 0 RULEX POSTPONE LITERAL ;

OPTIMIZE TWO-LITERALS +      WITH 2LIT-MATH WITH +
OPTIMIZE TWO-LITERALS -      WITH 2LIT-MATH WITH -
OPTIMIZE TWO-LITERALS AND    WITH 2LIT-MATH WITH AND
OPTIMIZE TWO-LITERALS OR     WITH 2LIT-MATH WITH OR
OPTIMIZE TWO-LITERALS XOR    WITH 2LIT-MATH WITH XOR
OPTIMIZE TWO-LITERALS LSHIFT WITH 2LIT-MATH WITH LSHIFT
OPTIMIZE TWO-LITERALS RSHIFT WITH 2LIT-MATH WITH RSHIFT
OPTIMIZE TWO-LITERALS *      WITH 2LIT-MATH WITH *
OPTIMIZE TWO-LITERALS /      WITH 2LIT-MATH WITH /

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2LIT-D+ ( -- )   [+ASM]
      LASTLIT CELL+ @ # 0 [EBP] ADD
      LASTLIT @ # EBX ADC
   [-ASM] ;

OPTIMIZE TWO-LITERALS D+ WITH 2LIT-D+ 
    
{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-DUP ( -- )   [+ASM]
      8 # EBP SUB
      EBX 4 [EBP] MOV
      LASTLIT @ # EBX MOV
      EBX 0 [EBP] MOV
   [-ASM] ;

OPTIMIZE (LITERAL) DUP WITH LIT-DUP

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: 2DUP-LIT ( -- )   [+ASM]
      12 # EBP SUB
      12 [EBP] EAX MOV
      EBX 0 [EBP] MOV
      EBX 8 [EBP] MOV
      EAX 4 [EBP] MOV
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE 2DUP (LITERAL) WITH 2DUP-LIT

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DOES>-MATH ( -- )   [+ASM]
      EAX POP
      EAX EBX 0 RULEX
   [-ASM] ;

OPTIMIZE (DOES>) +   WITH DOES>-MATH ASSEMBLE ADD
OPTIMIZE (DOES>) AND WITH DOES>-MATH ASSEMBLE AND
OPTIMIZE (DOES>) OR  WITH DOES>-MATH ASSEMBLE OR
OPTIMIZE (DOES>) XOR WITH DOES>-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: TAIL-RECURSE? ( -- flag )
   XTHIST1 @ 0<>
   XTHIST1 CELL+ 2@ - 5 = AND
   HERE 5 - C@ $E8 = AND ;

: TAIL-RECURSION ( -- )
   TAIL-RECURSE? IF
      $E9 HERE 5 - C!
   ELSE [+ASM]
         RET
      [-ASM]
   THEN /OPT ;

OPTIMIZE ANY EXIT WITH TAIL-RECURSION

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: -ROT-LIT-/STRING ( -- )
   ['] -ROT (COMPILE,)  LIT-/STRING ;

OPTIMIZE -ROT LIT-/STRING WITH -ROT-LIT-/STRING

: -ROT-LIT-/STRING-ROT ( -- )   [+ASM]
      LASTLIT @ # 4 [EBP] ADD
      LASTLIT @ # 0 [EBP] SUB
   [-ASM] ;

OPTIMIZE -ROT-LIT-/STRING ROT WITH -ROT-LIT-/STRING-ROT

{ --------------------------------------------------------------------
constants
-------------------------------------------------------------------- }

: CONST->LITERAL ( -- )
   LASTLIT @ LASTCHILD @ >BODY @ LASTLIT 2!
   ['] (LITERAL) XTHIST ! ;

: NEW-CONST ( -- )   [+ASM]
      CONST->LITERAL
      PUSH(EBX)
      LASTLIT @ # EBX MOV
   [-ASM] ;

OPTIMIZE ANY (CONSTANT) WITH NEW-CONST

: LIT-CONST ( -- )
   LASTLIT @ LASTCHILD @ >BODY @ LASTLIT 2!
   TWO-LITERALS  ['] TWO-LITERALS XTHIST ! ;

OPTIMIZE (LITERAL) (CONSTANT) WITH LIT-CONST

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: NEW-USER ( -- )   [+ASM]
      PUSH(EBX)
      LASTCHILD @ >BODY @ [ESI] EBX LEA
   [-ASM] ;

OPTIMIZE ANY (USER) WITH NEW-USER

: USER-@ ( -- )   [+ASM]
      PUSH(EBX)
      LASTCHILD @ >BODY @ [ESI] EBX MOV
   [-ASM] ;

OPTIMIZE NEW-USER @ WITH USER-@

: USER-! ( -- )   [+ASM]
      EBX LASTCHILD @ >BODY @ [ESI] MOV
      POP(EBX)
   [-ASM] ;

OPTIMIZE NEW-USER ! WITH USER-!

: LIT-USER-! ( -- )   [+ASM]
      LASTLIT @ # LASTCHILD @ >BODY @ [ESI] MOV
   [-ASM] ;

OPTIMIZE (LITERAL) USER-! WITH LIT-USER-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-USER-! ( -- )   [+ASM]
      EBX LASTCHILD @ >BODY @ [ESI] MOV
   [-ASM] ;

OPTIMIZE DUP USER-! WITH DUP-USER-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: USER-@-MATH ( -- )   [+ASM]
      LASTCHILD @ >BODY @ [ESI] EBX 0 RULEX
   [-ASM] ;

OPTIMIZE USER-@ +   WITH USER-@-MATH ASSEMBLE ADD
OPTIMIZE USER-@ AND WITH USER-@-MATH ASSEMBLE AND
OPTIMIZE USER-@ OR  WITH USER-@-MATH ASSEMBLE OR
OPTIMIZE USER-@ XOR WITH USER-@-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: USER-@->R ( -- )   [+ASM]
      LASTCHILD @ >BODY @ [ESI] PUSH
   [-ASM] ;

: R>-USER-! ( -- )   [+ASM]
      LASTCHILD @ >BODY @ [ESI] POP
   [-ASM] ;


OPTIMIZE USER-@ >R WITH USER-@->R
OPTIMIZE R> USER-! WITH R>-USER-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: USER-@-IF ( -- )   [+ASM]
      0 # LASTCHILD @ >BODY @ [ESI] CMP
      HERE $400 + JZ
   [-ASM] ;

OPTIMIZE USER-@ (IF) WITH USER-@-IF

: USER-@-UNARY-IF ( -- )   [+ASM]
      0 # LASTCHILD @ >BODY @ [ESI] CMP
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE USER-@ UNARY-IF WITH USER-@-UNARY-IF

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: NEW-VAR ( -- )   [+ASM]
      PUSH(EBX)
      LASTCHILD CELL+ @ [EDI] EBX LEA
   [-ASM] ;

OPTIMIZE ANY (CREATE) WITH NEW-VAR

: VAR-@ ( -- )   [+ASM]
      PUSH(EBX)
      LASTCHILD CELL+ @ [EDI] EBX MOV
   [-ASM] ;

OPTIMIZE NEW-VAR @ WITH VAR-@

: VAR-! ( -- )   [+ASM]
      EBX LASTCHILD CELL+ @ [EDI] MOV
      POP(EBX)
   [-ASM] ;

OPTIMIZE NEW-VAR ! WITH VAR-!

: VAR-PLUS ( -- )   [+ASM]
      LASTCHILD CELL+ @ [EDI] [EBX] EBX LEA
   [-ASM] ;

OPTIMIZE NEW-VAR +    WITH VAR-PLUS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DUP-VAR-! ( -- )   [+ASM]
      EBX LASTCHILD CELL+ @ [EDI] MOV
   [-ASM] ;

OPTIMIZE DUP VAR-! WITH DUP-VAR-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: VAR-ON ( -- )   [+ASM]
      -1 # LASTCHILD CELL+ @ [EDI] MOV
   [-ASM] ;

: VAR-OFF ( -- )   [+ASM]
      EAX EAX XOR
      EAX LASTCHILD CELL+ @ [EDI] MOV
   [-ASM] ;

OPTIMIZE NEW-VAR ON WITH VAR-ON
OPTIMIZE NEW-VAR OFF WITH VAR-OFF

: LIT-VAR-! ( -- )   [+ASM]
      LASTLIT @ # LASTCHILD CELL+ @ [EDI] MOV
   [-ASM] ;

OPTIMIZE (LITERAL) VAR-! WITH LIT-VAR-!

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: VAR-+! ( -- )   [+ASM]
      EBX LASTCHILD CELL+ @ [EDI] ADD
      POP(EBX)
   [-ASM] ;

OPTIMIZE NEW-VAR +! WITH VAR-+!

: LIT-VAR-+! ( -- )   [+ASM]
      LASTLIT @ # LASTCHILD CELL+ @ [EDI] ADD
   [-ASM] ;

OPTIMIZE (LITERAL) VAR-+! WITH LIT-VAR-+!

{ --------------------------------------------------------------------
values
-------------------------------------------------------------------- }

OPTIMIZE ANY (VALUE) WITH VAR-@

: LIT->BODY! ( -- )   [+ASM]
      EBX LASTLIT @ 5 + [EDI] MOV
      POP(EBX)
   [-ASM] ;

OPTIMIZE (LITERAL) >BODY! WITH LIT->BODY!

: 2LIT->BODY! ( -- )   [+ASM]
      LASTLIT CELL+ @ # LASTLIT @ 5 + [EDI] MOV
   [-ASM] ;

OPTIMIZE TWO-LITERALS >BODY! WITH 2LIT->BODY!

: LIT->BODY+! ( -- )   [+ASM]
      EBX LASTLIT @ 5 + [EDI] ADD
      POP(EBX)
   [-ASM] ;

OPTIMIZE (LITERAL) >BODY+! WITH LIT->BODY+!

: 2LIT->BODY+! ( -- )   [+ASM]
      LASTLIT CELL+ @ # LASTLIT @ 5 + [EDI] ADD
   [-ASM] ;

OPTIMIZE TWO-LITERALS >BODY+! WITH 2LIT->BODY+!


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: VAR-@-MATH ( -- )   [+ASM]
      LASTCHILD CELL+ @ [EDI] EBX 0 RULEX
   [-ASM] ;

OPTIMIZE VAR-@ +   WITH VAR-@-MATH ASSEMBLE ADD
OPTIMIZE VAR-@ -   WITH VAR-@-MATH ASSEMBLE SUB
OPTIMIZE VAR-@ AND WITH VAR-@-MATH ASSEMBLE AND
OPTIMIZE VAR-@ OR  WITH VAR-@-MATH ASSEMBLE OR
OPTIMIZE VAR-@ XOR WITH VAR-@-MATH ASSEMBLE XOR

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: VAR-@-IF ( -- )   [+ASM]
      0 # LASTCHILD CELL+ @ [EDI] CMP
      HERE $400 + JZ
   [-ASM] ;

OPTIMIZE VAR-@ (IF) WITH VAR-@-IF

: VAR-@-UNARY-IF ( -- )   [+ASM]
      0 # LASTCHILD CELL+ @ [EDI] CMP
      HERE $400 + 1 RULEX
   [-ASM] ;

OPTIMIZE VAR-@ UNARY-IF WITH VAR-@-UNARY-IF


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT-DO ( -- )   [+ASM]
      $80000000 # EBX ADD
      EBX PUSH
      EBX NEG
      LASTLIT @ # EBX ADD
      EBX PUSH
      POP(EBX)
   [-ASM] ;

OPTIMIZE (LITERAL) (DO) WITH LIT-DO

: 2LIT-DO ( -- )   [+ASM]
      LASTLIT CELL+ @ $80000000 + # PUSH
      LASTLIT @ LASTLIT CELL+ @ $80000000 + - # PUSH
   [-ASM] ;

OPTIMIZE TWO-LITERALS (DO) WITH 2LIT-DO

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT+LOOP ( -- )   [+ASM]
      LASTLIT @ # 0 [ESP] ADD
      HERE $400 + JNO
   [-ASM] ;

OPTIMIZE (LITERAL) (+LOOP) WITH LIT+LOOP

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT->BODY ( -- )   [+ASM]
      PUSH(EBX)
      LASTLIT @ 5 + [EDI] EBX LEA
   [-ASM] ;

OPTIMIZE (LITERAL) >BODY WITH LIT->BODY

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: LIT->BODY-LIT+ ( -- )   [+ASM]
      LASTLIT 2@ + LASTLIT !
      PUSH(EBX)
      LASTLIT @ 5 + [EDI] EBX LEA
   [-ASM] ;

OPTIMIZE LIT->BODY LIT-PLUS WITH LIT->BODY-LIT+

{ --------------------------------------------------------------------
bad benchmark optimizations
-------------------------------------------------------------------- }

: A-3DROP ( -- )
   ['] DROP COMPILE, ['] 2DROP COMPILE, ;

: A-2DROP ( -- )
   ['] 2DROP COMPILE, ;

: A-DROP ( -- )
   ['] DROP COMPILE, ;

OPTIMIZE +   DROP WITH A-2DROP
OPTIMIZE -   DROP WITH A-2DROP
OPTIMIZE *   DROP WITH A-2DROP
OPTIMIZE /   DROP WITH A-2DROP
OPTIMIZE MOD DROP WITH A-2DROP

OPTIMIZE I A-2DROP WITH A-DROP

OPTIMIZE I A-DROP

OPTIMIZE (LITERAL) A-DROP

OPTIMIZE M+  2DROP WITH A-3DROP
OPTIMIZE UM* 2DROP WITH A-2DROP
OPTIMIZE M*  2DROP WITH A-2DROP

OPTIMIZE TWO-LITERALS 2DROP

{ --------------------------------------------------------------------
ABSURDITIES
-------------------------------------------------------------------- }

OPTIMIZE DUP DROP
OPTIMIZE OVER DROP

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

-?  4 CONSTANT CELL
-? -4 CONSTANT -CELL

END-PACKAGE
