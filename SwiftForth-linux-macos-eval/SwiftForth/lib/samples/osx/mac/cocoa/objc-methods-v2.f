{ ====================================================================
ObjC method creation in ObjC 2 Runtime

Copyright (c) 2006-2017 Roelf Toxopeus

Part of adding new classes with Forth methods.
SwiftForth version.
Adding methods while building new class in ObjC 2 Runtime.
Last: 24 February 2013 17:38:28 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
Forth interface to method creation for the ObjC 2 Runtime.
	
Turnkey proof:
Two linked lists are created, one holds the instance method info and one
holds the class method info.
Upon booting coco-sf, the lists are traversed and all our defined instance
and class methods will be recreated, and added to their classes.

(ADD.METHOD) -- register and add method for given (meta)class.

FORTH-COCOAMETHODS -- holds head linked list for in Forth created ObjC
instance methods.
>FORTH-COCOAMETHODS -- adds an instance method to the list.
/FORTH-COCOAMETHODS -- recreate and add the instance methods in the list,
execute this somewhere in the startup from a turnkeyed coco-sf.
.FORTH-COCOAMETHODS -- show the instance methods in the list by their name.

FORTH-COCOACLASSMETHODS -- holds head linked list for in Forth created ObjC
class methods.
>FORTH-COCOACLASSMETHODS -- adds a class method to the list.
/FORTH-COCOACLASSMETHODS -- recreate and add the class methods in the list,
execute this somewhere in the startup from a turnkeyed coco-sf.
.FORTH-COCOACLASSMETHODS -- show the class methods in the list by their name.

Working towards the following syntax:

ADD.METHOD -- creates an internal structure containing the implementation
pointer, parameter types pointer, method-name and the class-name.
Adds the implementation as instance method to class.

ADD.CLASSMETHOD -- same as ADD.METHOD but adds the implementation as
a class method to the class. This is done by using the metaclass rather
than the class itself.
The metaclass from a class under construction can be obtained by calling
object_getClass on the class, before the class is added.
Note: object_getClass always returns the metaclass, before and after the
class is added. Passing a metaclass to object_getClass will return the
metaclass of its superclass.

The ADD words usually come between NEW.CLASS and ADD.CLASS, but can
also be used after ADD.CLASS is executed.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ relink forth-cocoamethods

FUNCTION: class_addMethod ( class SEL:name imp *types -- bool )
FUNCTION: sel_registerName ( 0string -- sel )

\ syntactic sugar, tradition causing the stack order
: (ADD.METHOD) ( imp *types name class -- )
	SWAP sel_registerName 2SWAP
	class_addMethod 0= ABORT" Can't add method !" ;
	
VARIABLE FORTH-COCOAMETHODS

: >FORTH-COCOAMETHODS ( a -- )   FORTH-COCOAMETHODS NODE NODE, ;

: RELINKMETHOD	( a -- )
	DUP @							   				\ imp
	SWAP CELL+ DUP @			   				\ *types
	SWAP CELL+					   				\ name
	DUP ZCOUNT + 1+ ( ALIGNED )
	FIND DROP EXECUTE								\ class id, is updated by /forth-cocoaclasses !!
	(ADD.METHOD) ;				   				\ relink

: /FORTH-COCOAMETHODS ( -- )  ['] RELINKMETHOD FORTH-COCOAMETHODS ALLNODES ;

: .FORTH-COCOAMETHODNAME ( a -- )  CELL+ CELL+ ZCOUNT CR TYPE ;

: .FORTH-COCOAMETHODS ( -- )   ['] .FORTH-COCOAMETHODNAME FORTH-COCOAMETHODS ALLNODES ;

\ --------------------------------------------------------------------
\ ADD.METHOD

: BUILD.METHOD ( imp *types name class -- address )
	2OVER 2OVER (ADD.METHOD)
	ALIGN HERE >R
	2SWAP SWAP ,					   \ imp
	,								      \ *types
	SWAP ZCOUNT Z,					   \ method name
	CLASS_GETNAME ZCOUNT STRING,	\ class name (also Forth dict name!), don't save class id, might change
	R> ;							      \ start of structure
	
\ creates an internal structure: imp *types method-name class-name
: ADD.METHOD ( imp *types name class -- )  BUILD.METHOD >FORTH-COCOAMETHODS ;

\ --------------------------------------------------------------------
\ relink forth-cocoaclassmethods

FUNCTION: object_getClass ( object -- class )

VARIABLE FORTH-COCOACLASSMETHODS

: >FORTH-COCOACLASSMETHODS ( a -- )   FORTH-COCOACLASSMETHODS NODE NODE, ;

: RELINKCLASSMETHOD	( a -- )
	DUP @							   			\ imp
	SWAP CELL+ DUP @			   			\ *types
	SWAP CELL+					   			\ name
	DUP ZCOUNT + 1+ ( ALIGNED )
	FIND DROP EXECUTE							\ class id, is updated by /forth-cocoaclasses !!
	object_getClass							\ get metaclass
	(ADD.METHOD) ;				   			\ relink

: /FORTH-COCOACLASSMETHODS ( -- )  ['] RELINKCLASSMETHOD FORTH-COCOACLASSMETHODS ALLNODES ;

: .FORTH-COCOACLASSMETHODS ( -- )   ['] .FORTH-COCOAMETHODNAME FORTH-COCOACLASSMETHODS ALLNODES ;

\ --------------------------------------------------------------------
\ ADD.CLASSMETHOD

: ADD.CLASSMETHOD ( imp *types name class -- )   object_getClass BUILD.METHOD >FORTH-COCOACLASSMETHODS ;
	
\\ ( eof )