{ ====================================================================
Cocoa functions

Copyright (c) 2008-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
Declare message as if it is a function
Together with cocoacore7.f and cocoabridge7.f this file defines the
interface to ObjC message sending.
Last: 4 November 2017 at 21:48:44 CET     -rt
==================================================================== }

{ --------------------------------------------------------------------
Turnkey proof:
A linked list is created, which will hold the message selectors.
Upon booting coco-sf, the list is traversed and all our defined Cocoa
messages are initialised.

@SELECTOR -- return selector for messagename. It tests the selector name
for a leading '@' character, and skips it in the name when found.
This leading '@' is used as a Cocoa identifier in coco-sf, it's optional.
Likewise the underscore _ prepended to foreign function names in some Forth
systems. The '@' is borrowed from ObjC where it serves as compiler hint.
COCOASELECTORS -- holds head linked list for Cocoa selectors.
>COCOASELECTORS -- adds a selector to the list.
/COCOASELECTORS -- initialise the messages in the list to their proper selectors,
execute this somewhere in the startup from a turnkeyed coco-sf.
.COCOASELECTORS -- show the selectors in the list by their name.

COCOASELECTOR -- create a named structure from parsed name containing the
#input-parameters, selector and the name string. Pass a pointer to this structure
to the herefore mentioned list.
NoTE the syntax is similar to the one used for FUNCTION:
The required receiver and selector for passing are implied. You don't have to
put them in the parameterlist. At runtime return pointer to structure.
For 'STRET' functions, add the stret pointer to the parameterlist.
COCOA-STRET: @frame ( frame-rect -- ret )

The following words use COCOASELECTOR to create the needed structure and at runtime
use the selector and #input-parameters to run the Cocoa message as a function.
The stackpictures at define time differs from the ones used at runtime.
At runtime add the receiver as right most parameter on top of all the others,
including th possible STRET pointer.
COCOA: -- run the defined word with this stackpicture ( n1 ... nn receiver -- x )
SUPERCOCOA: -- as COCOA: but pass it to the superclass of the receiver.
COCOA-STRET: -- add a structure pointer for return(ed) values  ( n1 ... nn stret receiver -- x )
SUPERCOCOA-STRET: -- id. but pass it to superclass of the receiver.
COCOA-FPRET: -- run the defined word with this stackpicture ( n1 ... nn receiver -- ret ) ( F: -- r )

Note: ObjC is a dynamic binding system. The implementation of the method for
a certain selector depends on the receiver/class/object. The lookup is done
at runtime, hence the passing along of the receiver and selector when sending
the message.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Relink selectors

: @SELECTOR ( 0string -- sel )
	DUP C@ [CHAR] @  = IF  CHAR+  THEN		\ ignore leading 'identifier'
	sel_getUid DUP 0= ABORT" @SELECTOR failed !" ;

VARIABLE COCOASELECTORS

: >COCOASELECTORS ( a -- )  COCOASELECTORS NODE NODE, ;

: RELINKSELECTOR ( a -- )  CELL+ DUP CELL+ @SELECTOR SWAP ! ;

: /COCOASELECTORS ( -- )   ['] RELINKSELECTOR COCOASELECTORS ALLNODES ;

: .SELECTORNAME ( a -- )  CELL+ CELL+ ZCOUNT CR TYPE ;

: .COCOASELECTORS ( -- )   ['] .SELECTORNAME COCOASELECTORS ALLNODES ;

\ --------------------------------------------------------------------
\ COCOA: family

\ debug info
LIB-INTERFACE +ORDER
: .METHOD-OUTPUT ( -- )
	POCKET ZCOUNT CR TYPE SPACE ." method returns " #RETURN ? ;

: .OUTPUT-WARNING ( -- )
	#RETURN @ DUP 2 = SWAP 0 = OR IF BRIGHT .METHOD-OUTPUT THEN NORMAL ;
PREVIOUS
	
: COCOASELECTOR ( <name-sel> <... parameters ...> -- )
	>IN @ >R  PARSE-WORD POCKET ZPLACE  R> >IN !
	POCKET @SELECTOR
	PARAMETERS() 2+		\ add obj and sel now
	.OUTPUT-WARNING
	CREATE
	HERE -ROT , , POCKET ZCOUNT Z, >COCOASELECTORS ;

: COCOA: ( <name-sel> <... parameters ...> -- )
	COCOASELECTOR FORCOCOA ;

: SUPERCOCOA: ( <name-sel> <... parameters ...> -- )
	COCOASELECTOR FORSUPERCOCOA ;

: COCOA-STRET: ( <name-sel> <... parameters ...> -- )
	COCOASELECTOR FORCOCOA-STRET ;

: SUPERCOCOA-STRET: ( <name-sel> <... parameters ...> -- )
	COCOASELECTOR FORSUPERCOCOA-STRET ;

: COCOA-FPRET: ( <name-sel> <... parameters ...> -- )
	COCOASELECTOR FORCOCOA-FPRET ;

\\ ( eof )