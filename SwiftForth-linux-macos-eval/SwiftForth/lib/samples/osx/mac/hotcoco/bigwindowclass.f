{ ====================================================================
Background Window

Copyright (c) 2010-2017 Roelf Tooxpeus

SwiftForth version.
Implements NSWindow subclass BigWindowClass.
In use as curtain to hide desktop and other applications from view
Can't be brought to the front (I hope)
Last: 24 October 2017 at 16:48:57 CEST  -rt
==================================================================== }

/FORTH
DECIMAL

COCOA: @windowNumbersWithOptions: ( options -- array )							\ NSWindow
COCOA: @lastObject ( -- id )																\ NSArray 
COCOA: @integerValue ( -- n )																\ NSNUmber
COCOA: @orderWindow:relativeTo: ( orderingmode otherwindownumber -- ret ) 	\ NSWindow
-1 CONSTANT NSWINDOWBELOW

CALLBACK: *mouseDown: ( rec sel event -- ret )
	 NSWINDOWBELOW
	 0 NSWindow @windowNumbersWithOptions: @lastObject @integerValue
	 _PARAM_0 @orderWindow:relativeTo: ;

: BWTYPES1   0" v@:V" ;

NSWindow NEW.CLASS BigWindowClass

*mouseDown: BWTYPES1 0" mouseDown:" BigWindowClass ADD.METHOD

BigWindowClass ADD.CLASS

\ --- usage

NEW.WINDOW BIGWINDOW

NOWIDGETS            BIGWINDOW W.STYLE
0e0 FDUP FDUP 1e0    BIGWINDOW W.BACKGROUND
                     BIGWINDOW FULL.FRAME  F2DROP F2DROP

: (NEW.BIGWINDOW) ( wptr4 -- )
	DUP WINDOW.ARGS  BigWindowClass @alloc @initWithContentRect:styleMask:backing:defer:
\ default opaque setting is YES, so need to chage it to change transparency!
	NO OVER @setOpaque: DROP
	SWAP +W.REF ! ;
	
: NEW.BIGWINDOW ( -- )
	BIGWINDOW DUP +W.REF @  IF BIGWINDOW CLOSE.WINDOW THEN
	DUP 1 0 ['] (NEW.BIGWINDOW) PASS 100 MS PAUSE
	DUP +W.BACKGROUND CG4@ DUP SET.WBACKGROUND
	SHOW.WINDOW ;

\\ ( eof )