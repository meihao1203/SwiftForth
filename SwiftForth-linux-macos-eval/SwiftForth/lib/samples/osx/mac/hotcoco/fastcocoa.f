{ ====================================================================
Early binding Cocoa

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Calling Cocoa methods directly, bypassing message sending.
Just testing, no relinking.
Last: 28 October 2015 at 16:42:43 GMT+1 -rt
==================================================================== }

{ --------------------------------------------------------------------
Further development of the method swizzling idea's found in swizzling-
test.f
Create FUNCTION: like words for early binding, i.e. no method lookup,
ObjC methods.

INSTANCEMETHOD -- create structure: imp sel #parameters
for fast objc call: add obj and sel to parameters: 2+
FASTCOCOA -- will retrieve the imp sel and #parameters and passes
them to OBJC-EXTERN-CALL directly.
INSTANCEFUNC -- will create a fast or early binding instance method.

CLASSMETHOD similar to INSTANCEMETHOD, but for class methods.
CLASSFUNC similar to INSTANCEFUNC, but for class methods.

Note: method implementations follow the rules of their messages:
so take care of mainthread recuirements.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: @IMP ( class 0string -- sel imp )
	@SELECTOR TUCK
	class_getInstanceMethod DUP 0= ABORT" No Method for Selector !"
	method_getImplementation DUP 0= ABORT" No IMP for Method !" ;

\ for fast objc call: add obj and sel to parameters
: INSTANCEMETHOD ( class <name> -- )
	PARAMETERS() 2+ SWAP
	>IN @ >R  PARSE-WORD POCKET ZPLACE  R> >IN !
	POCKET @IMP
	CREATE , , , ;
	
: 3@ ( a -- n1 n2 n3 )
	[ 2 CELLS ] LITERAL + DUP @
	SWAP CELL- DUP @
	SWAP CELL- @ ;

\ for fast objc call
: FASTCOCOA ( n0 ... nx obj a -- ? )
	3@ >R SWAP R> OBJC-EXTERN-CALL ;

: INSTANCEFUNC ( class <name-sel> -- )
	INSTANCEMETHOD
	DOES>  ( n0 ... nx obj a -- ? )
		FASTCOCOA ;

\ ---

: @CLASSIMP ( class 0string -- sel imp )
	@SELECTOR TUCK
	class_getClassMethod DUP 0= ABORT" No Method for Selector !"
	method_getImplementation DUP 0= ABORT" No IMP for Method !" ;

: CLASSMETHOD ( class <name> -- )
	PARAMETERS() 2+ SWAP
	>IN @ >R  PARSE-WORD POCKET ZPLACE  R> >IN !
	POCKET @CLASSIMP
	CREATE , , , ;

: CLASSFUNC ( class <name-sel> -- )
	CLASSMETHOD
	DOES>  ( n0 ... nx obj a -- ? )
		FASTCOCOA ;

\\ ...

\ testing:

NSWINDOW INSTANCEFUNC @close ( -- ret )

NEW.WINDOW WIN  WIN ADD.WINDOW

: CLOSE.IT ( -- )  WIN +W.REF @ 1 0 ['] @close PASS ;

\\ ( eof )
