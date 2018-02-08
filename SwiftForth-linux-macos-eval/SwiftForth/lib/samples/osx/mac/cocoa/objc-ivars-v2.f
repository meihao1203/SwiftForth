{ ====================================================================
ObjC instance variables

Copyright (C) 2006-2017 Roelf Toxopeus

Part of adding new classes with Forth methods.
SwiftForth version.
Add instance variable to class in ObjC 2 Runtime.
Last: 24 February 2013 17:37:07 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
Forth interface to instance variables (ivars) creation for the ObjC
runtime.
 
Turnkey proof:
A linked list is created, which will hold the instance variables info.
Upon booting coco-sf, the list is traversed and all our defined instance
variables will be added to their classes.

(ADD.IVAR) -- add named instance variable to class.

FORTH-COCOAIVARS -- holds head linked list for in Forth created ObjC instance
variables.
>FORTH-COCOAIVARS -- adds an instance variable to the list.
/FORTH-COCOAIVARS -- add the instance variables to their classes in the list,
execute this somewhere in the startup from a turnkeyed coco-sf.
.FORTH-COCOAIVARSS -- show the instance variables in the list by their name.

Working towards the following syntax:

ADD.IVAR -- creates an internal structure containing a pointer to the type,
the variables name and the class name.
Adds the instance variable to the class, initialised to zero.

Use ADD.IVAR between NEW.CLASS and ADD.CLASS. Methods can be added anytime,
instance variables can only be added before objc_registerClassPair, executed
by ADD.CLASS.

Use @IVAR and !IVAR for fetching respectively storing values.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ relink forth-cocoaivars

\ from Foundation framework
FUNCTION: NSGetSizeAndAlignment ( *typePtr *sizep *alignp -- *nexttypePtr )

2VARIABLE 'S&A

: S&A ( 0string:type -- size aligment )
	'S&A DUP CELL+ NSGetSizeAndAlignment DROP 'S&A 2@ ;

FUNCTION: class_addIvar ( class *name size uint8_t:alignment *types -- bool )

\ syntactic sugar, tradition causing the stack order
: (ADD.IVAR) ( *types name class -- )
	SWAP
	ROT DUP >R S&A R>
	class_addIvar 0= ABORT" Can't add ivar !" ;

VARIABLE FORTH-COCOAIVARS

: >FORTH-COCOAIVARS ( a -- )   FORTH-COCOAIVARS NODE NODE, ;

: RELINKIVAR	( a -- )
	DUP @									\ *types
	SWAP CELL+							\ name
	DUP ZCOUNT + 1+ ( ALIGNED )
	FIND DROP EXECUTE					\ class id, updated by /forth-cocoaclasses !!
	(ADD.IVAR) ;

: /FORTH-COCOAIVARS ( -- )   ['] RELINKIVAR FORTH-COCOAIVARS ALLNODES ;

: .FORTH-COCOAIVARNAME ( a -- )  CELL+ ZCOUNT CR TYPE ;

: .FORTH-COCOAIVARS ( -- )   ['] .FORTH-COCOAIVARNAME FORTH-COCOAIVARS ALLNODES ;

\ --------------------------------------------------------------------
\ add ivar

: ADD.IVAR 	( *types name class -- )
	3DUP (ADD.IVAR)
	ALIGN HERE >R
	ROT ,									\ *types
	SWAP ZCOUNT Z,						\ ivar name
	class_getName ZCOUNT STRING,	\ class name (also Forth dict name!), don't save class id, might change	
	R> >FORTH-COCOAIVARS 	      \ start of structure
;

\ --------------------------------------------------------------------
\ fetching from and storing in ivars.

FUNCTION: object_getInstanceVariable ( object *name **value -- ivar ) \ pointer to a pointer, bug?
\ Note: object_getIvar is faster than object_getInstanceVariable if the Ivar for the instance variable is already known

\ Not sure how iForth >r rp@ r> like in CMF and SF works, so use a local scratch
VARIABLE 'IVAR

: @IVAR ( *name object -- n )
	SWAP 'IVAR object_getInstanceVariable DROP 'IVAR @ ;

FUNCTION: object_setInstanceVariable ( object *name *value -- ivar )  \ use n straight
\ Note: object_setIvar is faster than object_setInstanceVariable if the Ivar for the instance variable is already known

: !IVAR ( n *name object -- )		\ it sets the value directly, in Forth a pointer = integer !!!!
	SWAP ROT object_setInstanceVariable DROP ;

\\ ( eof )