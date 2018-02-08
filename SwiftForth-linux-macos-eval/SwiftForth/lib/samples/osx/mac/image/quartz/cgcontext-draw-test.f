{ ====================================================================
Quartz draw test

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
Last: 11 Aug 2015 01:14:29 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Testing quartz drawing.
First   DRAWWIN /GWINDOW    when included from LOAD-FILE menu.
Randomly draw lines  LL or dots DD in DRAWWIN. Any key stops.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

NEW.WINDOW DRAWWIN
s" drawwin Choose"      DRAWWIN W.TITLE

: /DRAWWIN ( -- )   DRAWWIN DUP ADD.WINDOW /GWINDOW ;

/DRAWWIN
	
: LL ( -- )
	DRAWWIN CGCONTEXT >R
	1e0 R@ LINE.WIDTH
	BEGIN
		DRAWWIN CONTENT.SIZE F>S F>S 2DUP
		CHOOSE S>F CHOOSE S>F CHOOSE S>F CHOOSE S>F R@ LINE
		16 ms ( PAUSE )
	?PAUSE UNTIL
	R> DROP ;

: DD ( -- )
	DRAWWIN CGCONTEXT >R
	BEGIN
		DRAWWIN CONTENT.SIZE F>S F>S CHOOSE S>F CHOOSE S>F R@ DOT
		PAUSE
	?PAUSE UNTIL
	R> DROP ;

cr .( CGContext demo loaded:  LL or DD )

\\ ( eof )