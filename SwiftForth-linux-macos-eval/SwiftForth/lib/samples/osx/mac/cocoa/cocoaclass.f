{ ====================================================================
Cocoa classes

Copyright (c) 2008-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
Get id from existing Cocoa class and cache it like a constant.
Note: I'm using the name Cocoa class for ObjC class. Because that's
how I use them, for interfacing to Cocoa, not programming in ObjC.
Last: 24 February 2013 17:29:43 CET     -rt
==================================================================== }

{ --------------------------------------------------------------------
Forth interface to existing ObjC classes.

Turnkey proof:
A linked list is created, which will hold the class structures.
Upon booting coco-sf, the list is traversed and all our defined Cocoa
classes are initialised.

@COCOACLASS -- return id for classname.
COCOACLASSES -- holds head linked list for Cocoa classes.
>COCOACLASSES -- adds a class to the list.
/COCOACLASSES -- initialise the classes in the list to their proper id's,
execute this somewhere in the startup from a turnkeyed coco-sf.
.COCOACLASSES -- show the classes in the list by their name.

COCOACLASS -- create a named structure from parsed name containing the
class id and the name string. Pass a pointer to this structure to the
herefore mentioned list. When name is executed, return class id. 
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ relink classes

: @COCOACLASS ( 0string -- id )  objc_getClass DUP 0= ABORT" cocoaClass failed" ;

VARIABLE COCOACLASSES

: >COCOACLASSES ( a -- )  COCOACLASSES NODE NODE, ;

: RELINKCLASS ( a -- )
	DUP	   	 \ pointer id
	CELL+        \ pointer to classname
	@COCOACLASS
	SWAP !		 \ save new id
	;

: /COCOACLASSES ( -- )   ['] RELINKCLASS COCOACLASSES ALLNODES ;

: .COCOACLASSNAME ( A -- )  CELL+ ZCOUNT CR TYPE ;

: .COCOACLASSES ( -- )   ['] .COCOACLASSNAME COCOACLASSES ALLNODES ;

\ --------------------------------------------------------------------
\ define COCOACLASS

: COCOACLASS ( <name> -- )
	>IN @ >R  PARSE-WORD POCKET ZPLACE  R> >IN !
	POCKET @COCOACLASS
	CREATE
	HERE SWAP , POCKET ZCOUNT Z, >COCOACLASSES
   DOES> ( a -- id )
    @ ;

\\ ( eof )