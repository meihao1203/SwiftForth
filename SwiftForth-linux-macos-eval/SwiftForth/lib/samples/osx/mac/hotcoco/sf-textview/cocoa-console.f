{ ====================================================================
I/O window

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Cocoa I/O console for Forth example.
Last: 19 Nov 2016 16:40:11 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
/TEXTVIEW -- initialise Textview for Forth I/O, this preserves the prior
personality. Does QUIT.
/TERMINAL -- for emergencies, return to Terminal console, if there!
MYTVWIN -- textview window for Forth I/O, initialised with dimensions
and title.
MYTEXTVIEW -- keeps NSTextView instance.
/MYWINDOW -- draws window and connects window and textview.
/COCOA-CONSOLE -- draw window, init all and run Forth.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: /TEXTVIEW	( id -- )
	DUP /VIEWDELEGATE 'TEXTVIEW !
	TEXTVIEW-MODE OPEN-PERSONALITY
	CLS .ABOUT
	CR CR ." hello again"  CR    								\ Removed text attributes 30 Oct 2014 21:56:06 CET  -rt
	QUIT ;												         \ QUIT will do a CATCH internally, so preserves new PERSONALITY in exception frame

: /TERMINAL
	/CONSOLE
	'TEXTVIEW @ -VIEWDELEGATE 									\ added 6 February 2014 14:06:51 CET  -rt
	CR ." I/O redirected to and from Terminal.app"
	CR PROMPT
	QUIT ;												         \ QUIT will do a CATCH internally, so preserves new PERSONALITY in exception frame

NEW.WINDOW MYTVWIN
100e0 100e0 500e0 200e0 MYTVWIN W.BOUNDS
S" Coco-SF I/O View"    MYTVWIN W.TITLE

VARIABLE MYTEXTVIEW
: /MYWINDOW ( -- )
	MYTVWIN ADD.WINDOW
	10 MS  ( OSX 10.11 El Capitan issue)
	MYTVWIN WINDOWFORTEXT
	DUP MYTEXTVIEW !
	\ DUP SCROLLS.HORIZONTAL
	0" Geneva" 15 ROT VIEWFONT ;

: /COCOA-CONSOLE ( -- )   	/MYWINDOW MYTEXTVIEW @ /TEXTVIEW ;

cr .( Cocoa console loaded: )
cr .( /COCOA-CONSOLE  to install)
cr .( /TERMINAL       to return to Terminal console)

\\ ( eof )