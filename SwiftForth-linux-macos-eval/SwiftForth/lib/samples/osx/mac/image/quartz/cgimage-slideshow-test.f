{ ====================================================================
Image slideshow

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version
Image/picture showing with CoreGraphics
Last: 5 Apr 2017 10:36:43 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Slideshow precaution:
Change the hard coded image paths to a set of your images !!!
PHOTOWIN /GWINDOW    when included from LOAD-FILE menu.

PHOTOWIN has a certain amount of transparency. Optional set PHOTOWIN
to fullscreen.
Change DELAY to preferred value, default is 1 second.
-------------------------------------------------------------------- }

\ --------------------------------------------------------------------

/FORTH
DECIMAL

\ *** examples:

NEW.WINDOW PHOTOWIN
\ NOWIDGETS PHOTOWIN PHOTOWIN W.STYLE
S" PHOTO VIEW" 	   PHOTOWIN W.TITLE
80e-2 					PHOTOWIN W.TRANSPARENCY

: /PHOTOWIN ( -- )    PHOTOWIN DUP ADD.WINDOW /GWINDOW ;

/PHOTOWIN
 
\ PHOTOWIN FULL.SCREEN

VARIABLE DELAY 1000 DELAY !

: SLIDESHOW ( -- )
	BEGIN
		0" file:///transport/ijs/ijs01.tif" PHOTOWIN DRAWPIC
 		DELAY @ MS
 		0" file:///transport/ijs/ijs02.tif" PHOTOWIN DRAWPIC
 		DELAY @ MS
		0" file:///transport/ijs/ijs03.tif" PHOTOWIN DRAWPIC
		DELAY @ MS
		0" file:///transport/ijs/ijs04.tif" PHOTOWIN DRAWPIC
		DELAY @ MS
		0" file:///transport/ijs/ijs05.tif" PHOTOWIN DRAWPIC
 		DELAY @ MS
		0" file:///transport/ijs/ijs06.tif" PHOTOWIN DRAWPIC
		DELAY @ MS
		0" file:///transport/ijs/ijs07.tif" PHOTOWIN DRAWPIC
		DELAY @ MS
		KEY?
	UNTIL ;

0 TASK SLIDESHOW.RUNNER
: SLIDESHOW.RUNS ( -- )  SLIDESHOW.RUNNER ACTIVATE  SLIDESHOW ;

cr .( slideshow demo loaded)
cr .( SLIDESHOW.RUNS   to start)
cr .( SLIDESHOW.RUNNER DONE stops )

\\ ( eof )