{ ====================================================================
Cocoa runners

Copyright (c) 2008-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version -> Februari 2014 version and later only !
Running ObjC selectors as methods/functions.
forCocoa and forSuperCocoa check for # of output parameters during compilation.
Last: 4 November 2017 at 21:53:46 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
Compile the actual run parts (DOES>) from the ObjC interface.
Note the fp returning variant, leaves the returned fp on the fp-stack.

Assumes all the message send words defined with GLOBAL:
Needs two private words from the LIB-INTERFACE package, #RETURN and 2RET>
-------------------------------------------------------------------- }

/FORTH
DECIMAL

LIB-INTERFACE +order

: (FORCOCOA) ( x1 ... xn object a -- ret )   2@ objc_msgSend OBJC-EXTERN-CALL ;

: FORCOCOA ( -- )
	#RETURN @
	CASE 0 OF DOES> (FORCOCOA) DROP  EXIT ENDOF
	     1 OF DOES> (FORCOCOA)       EXIT ENDOF
	     2 OF DOES> (FORCOCOA) 2RET> EXIT ENDOF
	     1 ABORT" illegal return count in COCOA: !"
	ENDCASE ;

: (FORSUPERCOCOA) ( x1 ... xn object a -- ret )   2@ objc_msgSendSuper OBJC-EXTERN-CALL ;

: FORSUPERCOCOA ( -- )
	#RETURN @
	CASE 0 OF DOES> (FORSUPERCOCOA) DROP  EXIT ENDOF
	     1 OF DOES> (FORSUPERCOCOA)       EXIT ENDOF
	     2 OF DOES> (FORSUPERCOCOA) 2RET> EXIT ENDOF
	     1 ABORT" illegal return count in SUPERCOCOA: !"
	ENDCASE ;

PREVIOUS

: (FORCOCOA-STRET) ( x1 ... xn stret object a -- ret )   2@ objc_msgSend_stret OBJC-EXTERN-CALL-STRET ;

: FORCOCOA-STRET ( -- )   DOES> (FORCOCOA-STRET) ;
	
: (FORSUPERCOCOA-STRET) ( x1 ... xn stret object a -- ret )   2@ objc_msgSendSuper_stret OBJC-EXTERN-CALL-STRET ;

: FORSUPERCOCOA-STRET ( -- )   DOES> (FORSUPERCOCOA-STRET) ;

: (FORCOCOA-FPRET) ( x1 ... xn object a --  ) ( F: -- r )   2@ objc_msgSend_fpret OBJC-EXTERN-CALL DROP ST0> ;

: FORCOCOA-FPRET ( -- )   DOES> (FORCOCOA-FPRET) ;

\\ ( eof )