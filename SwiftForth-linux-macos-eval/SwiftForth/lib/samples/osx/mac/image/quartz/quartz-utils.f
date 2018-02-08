{ ====================================================================
Quartz utillity words 

Copyright (c) 2004-2017 Roelf Toxopeus

SwiftForth version.
Defining the much used 2 and 4 fp member structures for points, sizes,
rectangles, ranges and colours as used by the OS.
For 32b SwiftForth SFLOATS are used.
These structures are passed by value when making calls or passing them to
methods. *Not* by reference!
Last: 26 November 2010 19:53:34 CET       -rt
==================================================================== }

{ --------------------------------------------------------------------
Toll free bridging:
CGRects and NSRects are treated the same.
Use CGRects and friends for NSRect and friends.
Creating synonyms is easy: SwiftForth:  AKA ( new old -- ) or just redefine ;-)

CGRect and friends:
url: http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CGGeometry/Reference/reference.html

NSRect and friends:
url: http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_DataTypes/Reference/reference.html

Prior to Mac OS X v10.5 the coordinates, width and height were represented by float values rather than CGFloat values.
When building for 64 bit systems, or building 32 bit like 64 bit, NSRect is typedef’d to CGRect.
When building for 64 bit systems, or building 32 bit like 64 bit, NSPoint is typedef’d to CGPoint.
When building for 64 bit systems, or building 32 bit like 64 bit, NSSize is typedef’d to CGSize.

CG2! CG2@ CG4! and CG4@ -- use the fp stack for the structure contents.
The data stack holds the structure pointer.

CG4: -- create named 4 memeber structure, using fp's on fp stack to
initialise it.
Explicit CGPoints and CGSize structures could be created with 2VARIABLE.

+CGPOINT and +CGSIZE point to their fields in a rectangle structure.

CGRECT@ CGCOLOR@ CGPOINT@ CGSIZE@ pass the contents of their structures
to the datastack for calls and methods.

Example:
1e0 2e0 3e0 4e0 CGRECT: pipo
pipo CGRECT@
pipo +CGPOINT CGPOINT@
pipo +CGSIZE  CGSIZE@

POINT+ and SIZE+ add points and sizes on the fp stack.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ fetching and storing CGFloats in/from structures
: CG2! ( addr -- ) ( F: x y | width height -- )
	DUP SFLOAT+ SF! SF! ;

: CG2@ ( addr -- ) ( F: -- x y | width height )
	DUP SF@ SFLOAT+ SF@ ;
	
: CG4! ( addr -- ) ( F: x y width height | r g b a -- )
	DUP [ 2 SFLOATS ] LITERAL + CG2! CG2! ;

: CG4@ ( addr -- ) ( F: -- x y width height | r g b a )
	DUP CG2@ [ 2 SFLOATS ] LITERAL + CG2@ ;

\ --------------------------------------------------------------------
\ Creating initialised 4 member structures
: CG4: ( <name> -- ) ( F: x y width height | r g b a -- )
	CREATE  HERE [ 4 SFLOATS ] LITERAL ALLOT CG4! ;

\ --------------------------------------------------------------------
\ Passing structures by value

: CGRECT@ ( addr -- x y w h )   CG4@ 4FPUSHS ;
	
: CGCOLOR@ ( addr -- r g b a )    CGRECT@ ;

: +CGPOINT ( *rect -- *point )   ;

: CGPOINT@ ( addr -- x y )   CG2@ 2FPUSHS ;

: +CGSIZE ( *rect -- *size )   [ 2 SFLOATS ] LITERAL + ;

: CGSIZE@ ( addr -- w h )   CGPOINT@ ;

\ words to add points, sizes etc.
: POINT+ ( F: x1 y1 x2 y2 -- x3 y3 )			\ should be in assembler!!!
	FROT F+ FROT FROT F+ FSWAP ;

: SIZE+ ( F: width1 heigth1 width2 heigth2 -- width3 heigth3 )  POINT+ ;

CR .( Quartz utillities loaded )

\\ ( eof )