{ ====================================================================
ObjC executes Forth

Copyright (C) 2008-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
Generic form of executing Forth words on Main thread.
Last: 22 Nov 2016 04:51:45 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
The following words allow execution of Forth words in the main eventloop.
Mostly used to execute GUI specific actions on the main thread from within
the Forth thread.

PBLOCK -- memory block for int and fp parameters:
#ints  n0 ... nn    #floats   r0 ... rn
cell   #ints cells  cell      #floats floats
!PARAMETERS -- pop #ints from data stack and#floats from fp stack to PBLOCK.
@PARAMETERS -- push ints and floats from PBLOCK to data and fp stacks. 

ForthClass -- wrapper class to execute Forth words in ObjC.
@doForth: -- class method, which pops the needed int and fp parameters
from PBLOCK and executes FWORD. For savety reasons FWORD is set to NOP
after execution.

PASS -- deliver xt to main runloop via the generic ForthClass. Pushing
the needed integer and fp parameters to PBLOCK. It synchronizes and
PASS is wrapped inside GET/RELEASE.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: FLOAT- ( n -- n' )   8 - ;

512 BUFFER: PBLOCK

\ these should be in assembler
: !PARAMETERS ( n1 ... nn #ints #floats -- ) ( F: r1 ... rn -- )
	2DUP FLOATS SWAP CELLS + [ 2 CELLS ] LITERAL + \ needed bytes
	PBLOCK +								\ start at bottom
	OVER 0 ?DO FLOAT- DUP F! LOOP	\ fp's
	CELL- TUCK !						\ #fp's
	SWAP DUP >R
	0 ?DO CELL- TUCK ! LOOP       \ int's
	R> SWAP CELL- ! ;             \ #int's

: @PARAMETERS ( -- n1 ... nn ) ( F: -- r1 ... rn )
	PBLOCK
	@+ 0 ?DO @+ SWAP LOOP               \ integers
	@+ 0 ?DO DUP F@ FLOAT+ LOOP DROP ;  \ floats
	
DEFER FWORD

: NOP ( -- )   ;

NSObject NEW.CLASS ForthClass

CALLBACK: *doForth ( rec sel param -- void )   8 FSTACK  @PARAMETERS  FWORD  ['] NOP IS FWORD  0 ;

: doForthtypes   0" v@:" ;

*doForth doForthtypes 0" doForth:" ForthClass ADD.CLASSMETHOD

COCOA: @doForth: ( n -- ret )

ForthClass ADD.CLASS		\ should be executed in HOT.COCO, can't doit twice! don't forget to add this in start word when turnkeyed!

VARIABLE 'PASS

: PASS ( #ints #floats xt -- )
	'PASS GET
	IS FWORD !PARAMETERS
	0" doForth:" @selector 0 YES ForthClass FORMAIN DROP
	'PASS RELEASE ;

\\ ( eof )

\ test:
variable var
: bump var +! ;                                                                                    
1 1 0 ' bump pass var cr ? 500 ms many

\ try nested cocoa versions
: (bump) ( n -- )  var +! ;
: bump ( n -- )  1 0 ['] (bump) pass ;                                                                               
1 1 0 ' bump pass var cr ? 500 ms many
