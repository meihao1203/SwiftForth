{ ====================================================================
Core Graphics drawing methods

Copyright (c) 2006-2017 Roelf Tooxpeus

SwiftForth version, version Feb 5 2014 and later !
sf can deal with multiple output parameters:
changed defining CGContextGetPathCurrentPoint to return x and y
removed 2RET> where appropriate
See CHANGES.TXT
Last: 14 Nov 2016 16:52:32 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
Note: all supplied and returned coordinates are fp numbers and passed
via the fp stack.

All words deal with current cgcontext.
LINE.WIDTH -- set linewidth for cgcontext.
PENLOC -- return pen location for cgcontext.
MOVE.TO -- move pen to x/y in cgcontext.
LINE.TO -- add a line using current blendmode etc.
from current penloc to x/y. Doesn't draw it!
SYNC.DRAW -- stroke, flush and set current point in cgcontext
DRAW.TO -- draw a line added to cgcontext, uses SYNC.DRAW
RMOVE -- move pen relative to current pen location.
RDRAW -- draw a line, relative to current pen location.
LINE -- draw a line form x1/y1 to x2/y2, uses DRAW.TO
DOT -- draw a dot at x/y, uses SYNC.DRAW. Pixel size = 5E-1
WIPE or CLEAR.WINDOW.

The jury is still not out on this:
Using integers for coordinates!!
: MOVE.TO  ( x y cgcontext --)
   ROT S>SF ROT S>SF CGContextMoveToPoint DROP ;
  
: LINE.TO ( x y cgcontext --)
   ROT S>SF ROT S>SF CGContextAddLineToPoint DROP ;

: DRAW.TO ( x y cgcontext --)
   DUP >R LINE.TO R> CGContextStrokePath DROP ;

: LINE ( x1 y1 x2 y2 cgcontext --)
   >R 2SWAP R@ MOVE.TO R> DRAW.TO ;

: DOT ( x y cgcontext --)
   >R 2DUP R> LINE ;
-------------------------------------------------------------------- }

/FORTH
DECIMAL

quartz.framework

FUNCTION: CGContextGetPathCurrentPoint ( cgcontext -- x y )
FUNCTION: CGContextMoveToPoint ( cgcontext sf sf -- ret ) 
FUNCTION: CGContextAddLineToPoint ( cgcontext sf sf -- ret )
FUNCTION: CGContextAddRect ( cgcontext sf sf sf sf -- ret )

FUNCTION: CGContextStrokePath ( cgcontext -- ret )
FUNCTION: CGContextFillPath ( cgcontext -- ret )
FUNCTION: CGContextFillRect ( cgcontext sf sf sf sf -- ret )
FUNCTION: CGContextClearRect ( cgcontext sf sf sf sf -- ret )

FUNCTION: CGContextSetLineWidth ( cgcontext sf -- ret )
FUNCTION: CGContextSetAlpha ( cgcontext sf -- ret )
FUNCTION: CGContextSetRGBStrokeColor ( cgcontext sf sf sf sf -- ret )
FUNCTION: CGContextSetRGBFillColor ( cgcontext sf sf sf sf -- ret )
FUNCTION: CGContextSetGrayFillColor ( cgcontext sf sf -- ret )

\ --------------------------------------------------------------------

: LINE.WIDTH ( context --) ( F: width --)
	FPUSHS CGContextSetLineWidth DROP ;

: PENLOC ( cgcontext -- ) ( F: -- x y )
	CGContextGetPathCurrentPoint SWAP SF>F SF>F ;

: MOVE.TO ( cgcontext -- ) ( F: x y -- )
    FSWAP FPUSHS FPUSHS CGContextMoveToPoint DROP ;

: LINE.TO ( cgcontext -- ) ( F: x y -- )
	FSWAP FPUSHS FPUSHS  CGContextAddLineToPoint DROP ;

(*
: DRAW.TO ( cgcontext -- ) ( F: x y -- )
   F2DUP
	DUP LINE.TO DUP CGContextStrokePath DROP
	DUP CGContextFlush DROP
	MOVE.TO ;
*)

: SYNC.DRAW ( cgcontext -- ) ( F: x y -- )
	COUNTER FLUSHED  2DUP @ - 33 U> IF                                \ time to work?
		!																					\ next flushtime
		DUP CGContextStrokePath DROP DUP _CGContextFlush DROP MOVE.TO  \ stroke, flush and set current point
		ELSE 2DROP DROP F2DROP THEN ;
	
: DRAW.TO ( cgcontext -- ) ( F: x y -- )
   F2DUP DUP LINE.TO SYNC.DRAW ;

: RMOVE ( cgcontext -- ) ( F: relativex relativey -- )
	PENLOC POINT+ MOVE.TO ;

: RDRAW ( cgcontext -- ) ( F: relativex relativey -- )
	PENLOC POINT+ DRAW.TO ;
	
: LINE ( cgcontext -- ) ( F: x1 y1 x2 y2 -- )
	DUP F2SWAP MOVE.TO DRAW.TO ;

(*
: DOT ( cgcontext -- ) ( F: x y -- )
	F2DUP
	DUP 1E0 FDUP 4FPUSHS CGContextFillRect DROP
	DUP CGContextFlush DROP
	MOVE.TO ;
*)

: DOT ( cgcontext -- ) ( F: x y -- )
	F2DUP DUP 5E-1 FDUP 4FPUSHS CGContextAddRect DROP SYNC.DRAW ;

: WIPE \ CLEAR.WINDOW ( wptr4 -- )
	DUP cgcontext >R
	R@ CGContextSaveGState DROP
	CGRECT OVER +W.REf @ @contentView @frame DROP
	R@ SWAP +W.BACKGROUND CGColor@ CGContextSetRGBFillColor DROP
	R@ CGRECT CGRECT@ CGContextFillRect DROP
	R@ CGContextRestoreGState DROP
	R> CGContextFlush DROP ;
	
cr .( Core Graphics basic drawing loaded )

\\ ( eof )
