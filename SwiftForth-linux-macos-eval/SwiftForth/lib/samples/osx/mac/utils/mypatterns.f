{ ====================================================================
extra patterns for the optimizer

Copyright (c) 2013-2017 Roelf Toxopeus

SwiftForth only.
Last: 4 November 2017 at 21:43:43 CET -rt
==================================================================== }

{ --------------------------------------------------------------------
Example where edge optimization could help:

: SF>F ( float -- ) ( F: -- r )   >R RP@ SF@ R>DROP ;

SEE SF>F 
3FB7F   EBX PUSH                        53
3FB80   0 [EBP] EBX MOV                 8B5D00		\ typical found a lot in SF
3FB83   4 # EBP ADD                     83C504		\ with this one
3FB86   4 # EBP SUB                     83ED04		\ this one
3FB89   EBX 0 [EBP] MOV                 895D00		\ and this one, self canceling
3FB8C   ESP EBX MOV                     8BDC
3FB8E   3BEAF ( SF@ ) CALL              E81CC3FFFF
3FB93   EAX POP                         58
3FB94   RET                             C3 ok

Remember what code caused this:

ICODE >R ( x -- )   ( R: -- x )
EBX PUSH                         \ push tos to return stack
POP(EBX)                         \ update tos
RET   END-CODE

ICODE RP@ ( -- a )
PUSH(EBX)                        \ save tos
ESP EBX MOV                      \ get return stack pointer
RET   END-CODE

'Chaining' inline defenitions (macro's) can produce these selfcanceling
instructions. In this case the sequence POP(EBX) PUSH(EBX).
Without the presence of an edge optimizer, we'll have to do with providing
substitution patterns for the optimizer.
-------------------------------------------------------------------- }

{ -------------------------------------------------------------------
usefull optimizer patterns and extra stackwords, not used much, but still...

a cliche without a common Forth name, 'dup that one' or 'keep that one'
OVER -ROT also known in optimizer inline list as UNDER

UNDER+ using the second on stack as accumulator, by C. Moore
short for  ROT + SWAP

UNDER and UNDER+ could be useful outside the optimizer as well, don't
need PUBLIC to make them visible...

the >R RP@ sequence is used quite a lot in passing one-off addresses
to external lib functions, hence >RP@

@+UNDER+ looks obscure, but accumulates fetching from an array

-2@ is reversed order 2@ i.e. 2@ SWAP
-------------------------------------------------------------------- }

/FORTH
DECIMAL

ICODE UNDER ( a b -- a a b )
   0 [EBP] EAX MOV
   4 # EBP SUB
   EAX 0 [EBP] MOV
   RET	END-CODE

ICODE UNDER+ ( n1 n2 n3 -- n1+n3 n2 )
	EBX 4 [EBP] ADD
	0 [EBP] EBX MOV
	4 # EBP ADD
	RET	END-CODE

\ --------------------------------------------------------------------
\ add optimizer patterns to optimizer package

PACKAGE OPTIMIZING-COMPILER

ICODE >RP@ ( n -- addr ; R: -- n )
	EBX PUSH                         \ push tos to return stack
   ESP EBX MOV                      \ get return stack pointer
   RET	END-CODE

ICODE ROT+ ( n1 n2 n3 -- n2 n1+n3 )
	0 [EBP] EAX MOV                                                   
	4 [EBP] EBX ADD
	4 # EBP ADD
	EAX 0 [EBP] MOV
	RET	END-CODE

ICODE @+UNDER+ ( n a -- n2 a+cell )
	0 [EBX] EAX MOV
	4 # EBX ADD
	EAX 0 [EBP] ADD
	RET	END-CODE

ICODE -2@ ( a-addr -- x1 x2 )
   4 # EBP SUB                      \ make room on stack for a cell
   0 [EBX] EAX MOV                  \ read x1 from addr+0
   EAX 0 [EBP] MOV                  \ write onto stack
   4 [EBX] EBX MOV                  \ read x2 from addr+4, replacing tos
   RET   END-CODE

OPTIMIZE ROT +     SUBSTITUTE ROT+
OPTIMIZE ROT+ SWAP SUBSTITUTE UNDER+
OPTIMIZE >R RP@	 SUBSTITUTE >RP@
OPTIMIZE OVER -ROT SUBSTITUTE UNDER
OPTIMIZE @+ UNDER+ SUBSTITUTE @+UNDER+
OPTIMIZE 2@ SWAP   SUBSTITUTE -2@

END-PACKAGE

\\ ( eof )