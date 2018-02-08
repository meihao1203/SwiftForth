{ ====================================================================
Random Walk Demo

Copyright (c) 1988-2017 Roelf Toxopeus

SwiftForth version
Last: 13 Nov 2016 07:40:26 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
First type  WALKWIN /GWINDOW  when included from LOAD-FILE menu.
RR -- randomwalk controlled from IMPOSTOR.
DO.WALK -- randomwalk by WALKER task.
WDONE -- stops WALKER.

Play with parameters.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

NEW.WINDOW WALKWIN
S" random walks"      WALKWIN W.TITLE

: /WALKWIN ( -- )   WALKWIN DUP ADD.WINDOW /GWINDOW ;

/WALKWIN

\ --- Random walk

: BOUNCEX ( F: x1 -- x2 )
	FABS WALKWIN CONTENT.SIZE FDROP FTUCK F- FABS F- ;

: BOUNCEY ( F: x1 -- x2 )
	FABS WALKWIN CONTENT.SIZE FNIP FTUCK F- FABS F- ;

: /WALK ( cgcontext -- )
	1e0 DUP LINE.WIDTH
	WALKWIN CONTENT.SIZE FSWAP 5e-1 F* FSWAP 5e-1 F* MOVE.TO ;

: RR ( -- )
	WALKWIN CGCONTEXT
	DUP /WALK
	DUP PENLOC
	BEGIN
		FSWAP 21 CHOOSE 10 - S>F F+ BOUNCEX
		FSWAP 21 CHOOSE 10 - S>F F+ BOUNCEY
		F2DUP DUP DRAW.TO
		\ 33 MS				\ show each step in 30 fps
	?PAUSE UNTIL
	DROP F2DROP ;

\ assign a task to do the walking
VARIABLE 'WDONE
: WDONE ( -- )   'WDONE ON ;
: -WDONE ( -- )  'WDONE OFF ;
: WDONE? ( -- flag )   PAUSE 'WDONE @ ;

: /WALK ( cgcontext -- )  /WALK -WDONE ;

: CUTS ( -- %cut )   10 CHOOSE DUP 7 < IF DROP 1 THEN ;

: RANDOMWALK ( -- )
	WALKWIN CGCONTEXT
	DUP /WALK
	DUP PENLOC
	BEGIN
		FSWAP 21 CHOOSE 10 - S>F F+ BOUNCEX
		FSWAP 21 CHOOSE 10 - S>F F+ BOUNCEY
		F2DUP DUP DRAW.TO
		33 MS				\ show each step in 30 fps
		WDONE?
	UNTIL
	DROP F2DROP ;

: RANDOMWALK2 ( -- )
	WALKWIN CGCONTEXT
	DUP /WALK
	DUP PENLOC
	BEGIN
		CUTS %CUT IF
			WALKWIN WIPE
			F2DUP DUP MOVE.TO
		ELSE
			FSWAP 21 CHOOSE 10 - S>F F+ BOUNCEX
			FSWAP 21 CHOOSE 10 - S>F F+ BOUNCEY
			F2DUP DUP DRAW.TO
		THEN
		33 MS				\ show each step in 30 fps
		WDONE?
	UNTIL
	DROP F2DROP ;

0 task walker

: DO.WALK ( -- )   WALKER ACTIVATE ALLOCPOOL  RANDOMWALK  RELEASEPOOL DROP ;

cr .( WALKWIN /GWINDOW    when included from LOAD-FILE menu)
cr .( DO.WALK   to start walking)
cr .( WDONE     to stop walking)

\\ ( eof )
