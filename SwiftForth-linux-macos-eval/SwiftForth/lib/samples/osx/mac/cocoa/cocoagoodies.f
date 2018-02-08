{ ====================================================================
Cocoa goodies

Copyright (C) 2008-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
Often used selectors, functions etc. for Cocoa
Last: 12 November 2017 at 09:10:05 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
NSObject -- is ObjC rootclass, can be used as super for new classes.
@super -- mimics ObjC compilers super directive, returns a structure
containing class id and its superclass id.
FORMAIN -- all objects inherit this method. Run given selector and its
arguments on mainthread. Some methods can only be run on the main thread.
Note that the argument is an object!
Usefull for GUI related methods.
PUSHME -- will push the NSApplication part of coco-sf to the front.
NSArray instances are used throughout Cocoa, so the much used @count
and @objectAtIndex: are conveniently defined here. 
>NSSTRING -- convert zeroterminated cstring to a NSString reference.
>4THSTRING -- convert NSString ref to an address length string pair.
@" -- equivalent to S" Z" etc. parse up to next " and return an
NSString ref.
-------------------------------------------------------------------- }


/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ the root class

COCOACLASS NSObject

\ --------------------------------------------------------------------
\ trivial, but useful

0 CONSTANT NO
1 CONSTANT YES

\ --------------------------------------------------------------------
\ some often used general selectors:

COCOA: @alloc ( -- obj )
COCOA: @init ( -- ref )
COCOA: @retain ( -- ret )
COCOA: @drain ( -- ret )
COCOA: @release ( -- ret )
COCOA: @autorelease ( -- id )
COCOA: @class ( -- class )
COCOA: @self ( -- id )        \ sure you can use DUP instead...

COCOA: @superclass ( -- superclass )

\ transient !
2VARIABLE (SUPER)

: @super ( id -- *superstruct )   (SUPER) >R DUP @SUPERCLASS SWAP R@ 2! R> ;

\ --------------------------------------------------------------------
\ check if method is available

COCOA: @respondsToSelector: ( selector -- bool )

\ --------------------------------------------------------------------
\ perform action on main thread

COCOA: @performSelectorOnMainThread:withObject:waitUntilDone: ( selector arg wait -- ret ) \ SEL object-id BOOL

: FORMAIN ( selector arg:object wait -- ret ) @performSelectorOnMainThread:withObject:waitUntilDone: ;

\ --------------------------------------------------------------------
\ releasepool
COCOACLASS NSAutoreleasePool

: allocPool ( -- id )   NSAutoreleasePool @alloc @init ;

: releasePool ( id -- ret ) @drain ;

\ --------------------------------------------------------------------
\ push coco-sf to front

\ make coco-sf nsapp the active front, this will also cause some internal initializations I hope
COCOA: @activateIgnoringOtherApps: ( flag -- ret ) \ NSApplication

: PUSHME ( -- )  YES NSApp @ @activateIgnoringOtherApps: DROP ;

\ --------------------------------------------------------------------
\ Much NSArray 

COCOACLASS NSArray

COCOA: @count  ( -- n )
\ COCOA: @makeObjectsPerformSelector:  ( sel -- ret )
\ COCOA: @containsObject:  ( obj:id -- bool )
COCOA: @objectAtIndex:  ( index -- id )

\ --------------------------------------------------------------------
\ NSString utils

COCOACLASS NSString

\ use instance rather than class: this works when coco is running!
COCOA: @initWithCString:encoding: ( 0string encoding -- nsstring )
: >NSSTRING ( 0string -- nsstring )   1 NSString @alloc @initWithCString:encoding: ;

COCOA: @length ( -- length )							\ NSString
COCOA: @UTF8String ( -- utf8stringref )			\ NSString
: >4THSTRING ( nsstring -- a n )   DUP @utf8string SWAP @length ;
	
\ You are responsable for calling @release when done with the string
: @" ( <string>"   -- NSStringRef )	\ convert following string to a NSString
	POSTPONE 0"
	STATE @
	IF  POSTPONE >NSString  ELSE  >NSString  THEN  ; IMMEDIATE

\\ ( eof )