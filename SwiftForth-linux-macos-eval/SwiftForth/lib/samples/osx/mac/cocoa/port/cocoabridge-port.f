{ ====================================================================
Cocoa runners

Copyright (c) 2008-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version -> Februari 2014 version and later only !
Running ObjC selectors as methods/functions.
forCocoa and forSuperCocoa check for # of output parameters during compilation.
This is the portable version.
Last: 15 November 2017 at 00:24:42 CEST   -rt
==================================================================== }

/FORTH
DECIMAL

{ --------------------------------------------------------------------
Before running the method, we need to change the Forth stackorder
to ObjC stackorder. An 'argument' stack is used to temporarely store
the arguments while re-shuffling the stack.

-ARGP -- clears argument stack.
PUSHES --  pushes n parameters from data stack to the argument stack.
POPS -- pops n parameters from argument stack to data stack.
REORDER -- puts all parameters in the required ObjC parameter order.
REORDER-STRET -- same, but deals with the STructure RET pointer as well.
-------------------------------------------------------------------- }

32 CONSTANT MAXARGS
CREATE ARGSTACK HERE MAXARGS CELLS DUP ALLOT ERASE	\ argument stack
ARGSTACK MAXARGS CELLS + CONSTANT ARGBP	         \ arguments stack base pointer
ARGBP VALUE ARGP							               \ arguments stack pointer, top arg stack

: >ARG ( n -- )								\ push n to arguments stack predecrement  
	ARGP CELL- DUP TO ARGP ! ;

: ARG> ( -- n )								\ pop n from argument stack postincrement
	ARGP DUP @ SWAP CELL+ TO ARGP ;

: -ARGP ( -- )  ARGBP TO ARGP ;					\ reset argument stack pointer

: ARGDEPTH ( -- n ) ARGBP ARGP - 4 / ;

: ?ARGP ( -- )
   ARGDEPTH MAXARGS > IF -ARGP TRUE ABORT" Argument stack overflow !" THEN ;

: PUSHES ( x1 ... xn n -- ) 0 ?DO >ARG LOOP ;

: POPS ( n -- x1 ... xn ) 0 ?DO ARG> LOOP ;

0 VALUE #ARGS

: REORDER ( x1 ... xn object selector n -- object selector x1 ... xn n )
	DUP >R
	2 - TO #ARGS -ARGP   \ do not push object and selector to argument stack
\ clear stack
	2>R
	#ARGS PUSHES
\ fill stack
	2R>   #ARGS POPS
	R>
;

: REORDER-STRET ( x1 ... xn stret object selector n+stret -- stret object selector x1 ... xn n+stret )
	DUP >R
	3 - TO #ARGS -ARGP   \ do not push stret, object and selector to argument stack
\ clear stack
	>R 2>R
	#ARGS PUSHES
\ fill stack
	2R> R>  #ARGS POPS
	R>
;

{ --------------------------------------------------------------------
Running the selector as method.

Compile the actual run parts (DOES>) from the ObjC interface.
Note the fp returning variant, leaves the returned fp on the fp-stack.

Needs two private words from the LIB-INTERFACE package, #RETURN and 2RET>
-------------------------------------------------------------------- }

LIB-INTERFACE +order

: (FORCOCOA) ( x1 ... xn object a -- ret )   2@ REORDER objc_msgSend ;

: FORCOCOA ( -- )
	#RETURN @
	CASE 0 OF DOES> (FORCOCOA) DROP  EXIT ENDOF
	     1 OF DOES> (FORCOCOA)       EXIT ENDOF
	     2 OF DOES> (FORCOCOA) 2RET> EXIT ENDOF
	     1 ABORT" illegal return count in COCOA: !"
	ENDCASE ;

: (FORSUPERCOCOA) ( x1 ... xn object a -- ret )   2@ REORDER objc_msgSendSuper ;

: FORSUPERCOCOA ( -- )
	#RETURN @
	CASE 0 OF DOES> (FORSUPERCOCOA) DROP  EXIT ENDOF
	     1 OF DOES> (FORSUPERCOCOA)       EXIT ENDOF
	     2 OF DOES> (FORSUPERCOCOA) 2RET> EXIT ENDOF
	     1 ABORT" illegal return count in SUPERCOCOA: !"
	ENDCASE ;

PREVIOUS

: (FORCOCOA-STRET) ( x1 ... xn stret object a -- ret )   2@ REORDER-STRET objc_msgSend_stret ;

: FORCOCOA-STRET ( -- )   DOES> (FORCOCOA-STRET) ;
	
: (FORSUPERCOCOA-STRET) ( x1 ... xn stret object a -- ret )   2@ REORDER-STRET objc_msgSendSuper_stret ;

: FORSUPERCOCOA-STRET ( -- )   DOES> (FORSUPERCOCOA-STRET) ;

: (FORCOCOA-FPRET) ( x1 ... xn object a --  ) ( F: -- r )   2@ REORDER objc_msgSend_fpret DROP ST0> ;

: FORCOCOA-FPRET ( -- )   DOES> (FORCOCOA-FPRET) ;

\\ ( eof )