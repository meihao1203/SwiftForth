{ ====================================================================
Path drawing

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
CoreGraphics draw path tests.
Last: 11 Aug 2015 17:43:07 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Draws 5 boxes, normal, translated, scaled, rotated and wheel.
Uses Paths to draw.
BOXES -- draws a box. Waits for a keystroke to draw next box.
AA -- draws each box in animation.

Note: uses the unsynced _CGContextFlush call
-------------------------------------------------------------------- }

/FORTH
DECIMAL

NEW.WINDOW PATHWIN
 100e0 386e0 599e0 392e0 PATHWIN W.BOUNDS
 S" Path Window"         PATHWIN W.TITLE

: /PATHWIN ( -- )    PATHWIN DUP ADD.WINDOW /GWINDOW ;

/PATHWIN


\ The rest uses relative coordinates
: BOX1 ( -- )
	." box starting in 0,0"
	PATHWIN CGCONTEXT
	DUP CGContextBeginPath DROP
	2e0 DUP LINE.WIDTH
		  0e0 FDUP          F2DUP DUP MOVE.TO
		  0e0  100e0 POINT+ F2DUP DUP LINE.TO
		100e0    0e0 POINT+ F2DUP DUP LINE.TO
		  0e0 -100e0 POINT+       DUP LINE.TO
		DUP CGContextClosePath DROP
	DUP CGContextStrokePath DROP
	_CGContextFlush DROP ;

\ Translating
: BOX2 ( -- )
	." translate x+100 y+0"
	PATHWIN CGCONTEXT
	DUP CGContextSaveGState DROP
	100e0 0e0 DUP CGTRANSLATE
	DUP CGContextBeginPath DROP
	2e0 DUP LINE.WIDTH
		  0e0 FDUP          F2DUP DUP MOVE.TO
		  0e0  100e0 POINT+ F2DUP DUP LINE.TO
		100e0    0e0 POINT+ F2DUP DUP LINE.TO
		  0e0 -100e0 POINT+       DUP LINE.TO
		DUP CGContextClosePath DROP
	DUP CGContextStrokePath DROP
	DUP _CGContextFlush DROP                  \ need the unsynced call !!
	CGContextRestoreGState DROP ;

\ Scaling
: BOX3 ( -- )
	." scales 2x 0.5y"
	PATHWIN CGCONTEXT
	DUP CGContextSaveGState DROP
	2e0 5e-1 DUP CGSCALE
	DUP CGContextBeginPath DROP
	2e0 DUP LINE.WIDTH
		  0e0 FDUP          F2DUP DUP MOVE.TO
		  0e0  100e0 POINT+ F2DUP DUP LINE.TO
		100e0    0e0 POINT+ F2DUP DUP LINE.TO
		  0e0 -100e0 POINT+       DUP LINE.TO
		DUP CGContextClosePath DROP
	DUP CGContextStrokePath DROP
	DUP _CGContextFlush DROP                  \ need the unsynced call !!
	CGContextRestoreGState DROP ;

\ Rotation
: BOX4 ( -- )
	." rotates 10 degrees around 0,0"
	PATHWIN CGCONTEXT
	DUP CGContextSaveGState DROP
	-10e0 DUP CGROTATE
	DUP CGContextBeginPath DROP
	2e0 DUP LINE.WIDTH
		  0e0 FDUP          F2DUP DUP MOVE.TO
		  0e0  100e0 POINT+ F2DUP DUP LINE.TO
		100e0    0e0 POINT+ F2DUP DUP LINE.TO
		  0e0 -100e0 POINT+       DUP LINE.TO
		DUP CGContextClosePath DROP
	DUP CGContextStrokePath DROP
	DUP _CGContextFlush DROP                  \ need the unsynced call !!
	CGContextRestoreGState DROP ;

\ Pivots around point somewher middle screen
: BOX5 ( -- )
	." pivots around point 300,200"
	PATHWIN CGCONTEXT
	360 0 DO
	 DUP CGContextSaveGState DROP
	 300e0 200e0 DUP CGTRANSLATE
	 I NEGATE S>F DUP CGROTATE
	 DUP CGContextBeginPath DROP
		  0e0 FDUP          F2DUP DUP MOVE.TO
		  0e0  100e0 POINT+ F2DUP DUP LINE.TO
		100e0    0e0 POINT+ F2DUP DUP LINE.TO
		  0e0 -100e0 POINT+       DUP LINE.TO
		DUP CGContextClosePath DROP
	 DUP CGContextStrokePath DROP
	 DUP _CGContextFlush DROP                  \ need the unsynced call !!
	 DUP CGContextRestoreGState DROP
	 \ KEY DROP
	45 +LOOP
	DROP ;

: BOXES ( -- )
   CR BOX1 KEY DROP CR BOX2 KEY DROP
   CR BOX3 KEY DROP CR BOX4 KEY DROP
   CR BOX5 CR ." done" ;

: AA ( -- )
   PATHWIN WIPE CR BOX1
   700 MS PATHWIN WIPE CR BOX2
   700 MS PATHWIN WIPE CR BOX3
   700 MS PATHWIN WIPE CR BOX4
   700 MS PATHWIN WIPE CR BOX5
   CR ." done" ;
   
cr .( path tests loaded)
cr .( try  BOXES  any key continues)
cr .( try  AA  runs it self)

\\ ( eof )