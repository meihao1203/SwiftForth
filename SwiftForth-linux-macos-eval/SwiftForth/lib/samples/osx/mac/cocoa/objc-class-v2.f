{ ====================================================================
ObjC class creation in ObjC 2 Runtime

Copyright (C) 2006-2017 Roelf Toxopeus

Part of adding new classes with Forth methods.
SwiftForth version.
Last: 24 February 2013 17:37:32 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
Forth interface to class creation for the ObjectiveC 2.0 Runtime
wrt Cocoa.
 
Turnkey proof:
A linked list is created, which will hold the class info.
Upon booting coco-sf, the list is traversed and all our defined classes
will be recreated, but not yet added to the ObjC runtime.

(NEW.CLASS) -- creates new class and metaclass and returns its id.
New class is not ready for usage yet. After ADD.CLASS, the new class is
ready for usage.

FORTH-COCOACLASSES -- holds head linked list for in Forth created ObjC classes.
>FORTH-COCOACLASSES -- adds a class to the list.
/FORTH-COCOACLASSES -- recreate the classes in the list, execute this somewhere
in the startup from a turnkeyed coco-sf.
.FORTH-COCOACLASSES -- show the classes in the list by their name.

Working towards the following syntax:
NEW.CLASS -- create named structure containing class id, superclassname
and classname. Pass a pointer to this structure to the herefore mentioned
list. At runtime return class id.
Apple dev doc RE objc_allocateClassPair:
extraBytes -- The number of bytes to allocate for indexed ivars at
the end of the class and metaclass objects. This should usually be 0.
Choose to hide it in NEW.CLASS for now to avoid 'forgot the 0' when
using NEW.CLASS. So syntax is same as used for the ObjC 1 Runtime
interface.

ADD.CLASS -- adds or registers the class to the ObjC runtime.
Use ADD.CLASS as well in turnkey programs to re-add the class to the
OjC 2 Runtime.

In between NEW.CLASS and ADD.CLASS you can build the class
by adding methods, ivars etc.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ relink forth-cocoaclasses

FUNCTION: objc_allocateClassPair ( superclass *name extraBytes -- class )

: (NEW.CLASS) ( superclass:id name -- id )
	0 objc_allocateClassPair DUP 0= ABORT" Can't create class !" ;
	
VARIABLE FORTH-COCOACLASSES

\ add address to relink list
: >FORTH-COCOACLASSES ( a -- )   FORTH-COCOACLASSES NODE NODE, ;

: RELINKFORTHCLASS ( a -- )
	DUP CELL+ DUP
	objc_getClass	  \ get superclass id
	SWAP ZCOUNT + 1+
	(NEW.CLASS)  	  \ skip super, skip 0byte and get new class id
	SWAP ! ;			  \ relink

: /FORTH-COCOACLASSES ( -- )   ['] RELINKFORTHCLASS FORTH-COCOACLASSES ALLNODES ;

: .FCCINFO ( a -- )
	CR DUP CR @ .H 
	CR SPACE CELL+ DUP ZCOUNT TYPE
	CR SPACE SPACE ZCOUNT + 1+ ZCOUNT TYPE ;

: .FORTH-COCOACLASSNAME ( a -- )  CELL+ ZCOUNT + 1+ ZCOUNT CR TYPE ;

: .FORTH-COCOACLASSES ( -- )   ['] .FORTH-COCOACLASSNAME FORTH-COCOACLASSES ALLNODES ;

\ --------------------------------------------------------------------
\ NEW.CLASS

FUNCTION: class_getName ( id -- name )

: NEW.CLASS ( superclass:id <name> -- )
	>IN @ >R  PARSE-WORD POCKET ZPLACE  R> >IN !
	DUP POCKET (NEW.CLASS)
	CREATE
	ALIGN HERE -ROT
	,										\ class id
	class_getName ZCOUNT Z,			\ superclass name
	POCKET ZCOUNT Z,					\ class name
	>FORTH-COCOACLASSES				\ link to forth-cocoaclasses chain
	DOES>
		@									\ when called, return class id
;

FUNCTION: objc_registerClassPair ( class -- ret )

: ADD.CLASS ( class -- )   objc_registerClassPair DROP ;

\\ ( eof )