{ ====================================================================
ObjC structures

Copyright (C) 2006-2017 Roelf Toxopeus

Part of adding new classes with Forth methods.
SwiftForth version.
Class creation utillities for ObjC 2 Runtime
Rewrite from the ObjC 1 version
Most structures as used in ObjC 1 are deprecated in ObjC 2.
In use since Mac OSX 10.5 Leopard and later
Note: ObjC 1.x Runtime stays in use as well, but only 32bit
Last: 20 March 2013 09:02:38 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
List of simple types and character code used by ObjectiveC runtime
c :char
i :int
s :short
l :long
q :long-long
C :unsigned-char
I :unsigned-int
S :unsigned-short
L :unsigned-long
Q :unsigned-long-long
f :float
d :double
B :boolean
v :void
* :string
@ objc-cffi:objc-id
# objc-cffi:objc-class-pointer
: objc-cffi:objc-sel
? objc-unknown-type

Most structures from objc_1.x are deprecated in favour of opaque types
and functional API calls. Only objc_super is unchanged.
objc_class structure see API
objc_method structure  see API
objc_method_list structure NO substitute !!
objc_ivar structure  see API
objc_ivar_list structure  NO substitute !!
-------------------------------------------------------------------- }


/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Could and will add a lot more for the 1.x structure substitutes

FUNCTION: class_getClassMethod ( obj SEL -- Method )
FUNCTION: class_getInstanceMethod ( obj SEL -- Method )
FUNCTION: method_getImplementation ( Method -- IMP )     \ <-- external function
FUNCTION: method_setImplementation ( Method IMP -- IMP ) \ <-- callback
FUNCTION: method_getNumberOfArguments ( Method -- n )
\ was deprecated, now gone in Lion
\ FUNCTION: method_getSizeOfArguments ( Method -- n )
FUNCTION: class_getInstanceVariable ( aClass *Name -- ivar )

{ -------------------------------------------------------
structure objc_super
	ptr:	+receiver
	ptr:	+superclass
structure.end
------------------------------------------------------- }

8 cells constant objc_super
: +receiver ( a -- a2 ) ;
: +superclass ( a -- a2 ) cell+ ;

\\ ( eof )