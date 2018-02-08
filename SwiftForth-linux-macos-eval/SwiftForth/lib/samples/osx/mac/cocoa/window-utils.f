{ ====================================================================
Extra window utillities.

Copyright (c) 2002-2017 Roelf Toxopeus

Part of GUI stuff.
SwiftForth version.
Last: 26 October 2015 at 09:42:55 GMT+1  -rt
==================================================================== }

{ --------------------------------------------------------------------
Extra window utils, as used in MacForth.
There is much more you can do, add them when needed.

@MAINSIZE -- return dimensions fullscreen in given rect structure.
FULL.FRAME -- return dimensions fullscreen, uses w.bounds field from
given window.
FULL.SCREEN -- sets given window to full screen.
CONTENT.FRAME -- return dimensions contentview from given window.
CONTENT.SIZE -- return width and height contentview from given window.
MAKE.CONTENTVIEW -- set contentview for window. Main thread execution.

Some background colour presets for window:
WHITE.BG RED.BG
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSScreen
COCOA: @mainScreen ( -- NSScreen:mainscreen )

: @MAINSIZE ( a -- )   NSScreen @mainScreen @frame DROP ;

: FULL.FRAME ( wptr4 -- ) ( F: -- x y w h )   +W.BOUNDS DUP @mainsize CG4@ ;
	
: FULL.SCREEN ( wptr4 -- )   DUP >R FULL.FRAME  R> FIX.WINDOW ;

\ get frame rect contentview
COCOA: @contentView ( -- contentviewref )

: CONTENT.FRAME ( wptr4 -- ) ( F: -- x y w h )
	DUP +W.BOUNDS DUP >R SWAP +W.REF @ @contentView @frame DROP R> CG4@ ;

: CONTENT.SIZE ( wptr4 -- ) ( F: -- width height )
	CONTENT.FRAME F2SWAP FDROP FDROP ;

\ set window contentview
COCOA: @setContentView: ( viewref -- ret )

: MAKE.CONTENTVIEW ( viewref wptr4 -- )
	+W.REF @ >R
	Z" setContentView:" @selector SWAP YES R> FORMAIN DROP ;

(*
: DIMENSIONS ( F: T L B R -- wide high )    ;

: TL.WINDOW ( wptr4 -- ) ( F: -- top left )   ;

: BL.WINDOW ( wptr4 -- ) ( F: -- bottom right )  ;
*)

\ Some colour presets
: WHITE.BG ( wptr4 -- )
	NSColor @whiteColor SWAP +W.REF @ @setBackgroundColor: DROP ;

: RED.BG ( wptr4 -- )
	NSColor @redColor   SWAP +W.REF @ @setBackgroundColor: DROP ;

\\ ( eof )