{ ====================================================================
Draw colored boxes.

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
Last: 7 October 2011 09:46:20 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Draw colored boxes, some slightly rotated, scaled and translated.
Also colors and transparency are randomly changed.

QWIN /GWINDOW    when included from LOAD-FILE menu.
Uses a borderless window QWIN.
TRANSFORM -- chooses one of the three possible transformations to
be applied to the given CGContext.
SLEEPY -- sleep a bit.
DRAW.A.BOX -- draws abox with the randomly provided transformation
and color: a reddish, a blueish and a yellowish box.
BOXES -- draws boxes until a key hit.
Q.RUNS -- runs BOXES in a background task QUARTZRUNNER.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

NEW.WINDOW QWIN
	402e0 280e0 547e0 438e0 QWIN W.BOUNDS
	NOWIDGETS 					QWIN W.STYLE
	S" "                    QWIN W.TITLE

: /QWIN ( -- )   QWIN DUP ADD.WINDOW /GWINDOW ;

/QWIN

: CHOOSE.TRANSPARENCY ( F: -- r )
	11 CHOOSE ?DUP IF 1e0 S>F F/ ELSE 0e0 THEN ;

: CHOOSE.SCALE ( F:	-- xscal yscale )
	25e-2 4 CHOOSE 1+ S>F F* FDUP ;

: CHOOSE.TRANSLATION ( F: -- xtrans ytrans )
	340 CHOOSE S>F 180 CHOOSE S>F ;

: CHOOSE.ROTATION ( F: -- angle )
	90 CHOOSE 45 - S>F D>R ;

: SCALE-IT ( cgcontext -- )   CHOOSE.SCALE 2FPUSHS CGContextScaleCTM DROP ;

: TRANSLATE-IT ( cgcontext -- )   CHOOSE.TRANSLATION 2FPUSHS CGContextTranslateCTM DROP ;

: ROTATE-IT ( cgcontext -- )   CHOOSE.ROTATION FPUSHS CGContextRotateCTM drop ; 

CREATE TRANSFORMS  ' SCALE-IT ,  ' TRANSLATE-IT ,  ' ROTATE-IT ,

: TRANSFORM ( cgcontext -- )
	TOSS IF
		3 CHOOSE CELLS TRANSFORMS + @ EXECUTE
	ELSE DUP CGContextRestoreGState DROP CGContextSaveGState DROP  \ restore _and_ save for nexttime
	THEN ;

: COLORRECT ( cgcontext -- )
	DUP CGCOLOR CGColor@ CGContextSetRGBFillColor DROP
	CGRECT CGRect@ CGContextFillRect DROP ;

: SLEEPY ( -- )   50 200 ALEA MS ;

: DRAW.A.BOX ( cgcontext -- )
	DUP CGContextSaveGState DROP
	DUP TRANSFORM
	DUP COLORRECT
	DUP CGContextRestoreGState DROP
	SLEEPY CGContextFlush DROP ;

: A.RED.BOX ( cgcontext -- )
	TOSS IF
		1e0 1e0 1e0 5e-1 CGCOLOR CG4!
	ELSE
		1e0 0e0 0e0 CHOOSE.TRANSPARENCY CGCOLOR CG4!
	THEN
	0e0 0e0 200e0 100e0 CGRECT CG4!
	DRAW.A.BOX ;

: A.BLUE.BOX ( cgcontext -- )
	TOSS IF
		1e0 1e0 1e0 5e-1 CGCOLOR CG4!
	ELSE
		0e0 0e0 1e0 CHOOSE.TRANSPARENCY CGCOLOR CG4!
	THEN
	0e0 0e0 100e0 200e0 CGRECT CG4!
	DRAW.A.BOX ;

: A.YELLOW.BOX ( cgcontext -- )
	TOSS IF
		1e0 1e0 1e0 5e-1 CGCOLOR CG4!
	ELSE		
		95e-2 1e0 0e0 CHOOSE.TRANSPARENCY CGCOLOR CG4!
	THEN
	90e0 90e0 173e0 189e0 CGRECT CG4!
	DRAW.A.BOX ;

: BOXES ( -- )
	QWIN CGCONTEXT
	BEGIN
		DUP A.RED.BOX
		DUP A.BLUE.BOX
		DUP A.YELLOW.BOX
	?PAUSE UNTIL
	DROP ;

2000 TASK QUARTZRUNNER

: Q.RUNS ( -- )    QUARTZRUNNER ACTIVATE  ALLOCPOOL  BOXES  RELEASEPOOL DROP ;

cr .( QWIN /GWINDOW    when included from LOAD-FILE menu)
cr .( Q.RUNS  starts)
cr .( QUARTZRUNNER DONE  stops)

\\ ( eof )