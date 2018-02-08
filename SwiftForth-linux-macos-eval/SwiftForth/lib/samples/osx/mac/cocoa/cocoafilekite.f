{ ====================================================================
The file kite...

Copyright (c) 2009-2017 Roelf Toxopeus

SwiftForth version.
Loading files with the Cocoa file kite.
Last: 24 October 2015 at 21:50:20 GMT+2  -rt
==================================================================== }

{ --------------------------------------------------------------------
File kite is the name given to the file open/save dialog window hovering
on top of all, like a kite. Term used in the 1980's in Atari GEM (Mac?).
Name stuck...

PIMP.KITE -- allows to add widgets and text to NSOpenPanel instance.
NEW.KITE -- return new NSOpenPanel instance.
CHOICE -- retrieves choosen file path from NSOpenPanel instance after
user modal interaction.
EZGET -- 'easy get' file path. Return path and true flag if user made
choice, or just false flag if user canceled. EZGET is MacForth.
EZGETMAIN -- is the proper way of running EZGET: on the main thread.
Uses PASS to deliver EZGET to the main eventloop. Uses POCKET for the
return string.
LOAD-FILE -- include/load file choosen with EZGETMAIN.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ NSOpenPanel aka File Kite.

COCOACLASS NSOpenPanel

COCOA: @openPanel	( -- id ) \ NSOpenPanel object
COCOA: @setCanChooseFiles: ( flag -- ret ) \ BOOL

\ --------------------------------------------------------------------
\ NSSavePanel methods inherited by NSOpenPanel

COCOA: @setPrompt: ( prompt -- ret )	\ NSString object
COCOA: @URL ( -- id ) 						\ NSURL object
COCOA: @runModal ( -- int ) 				\ NSInteger 1 or 0

\ --------------------------------------------------------------------
\ NSURL method

COCOA: @path ( -- path ) 					\ NSString object				

: PIMP.KITE ( panel -- )
	0" Choose" >NSSTRING OVER @setTitle: DROP
	\ 100 MS
	0" Load" >NSSTRING SWAP @setPrompt: DROP ;

: NEW.KITE ( -- panel )
	NSOpenPanel @openPanel
	DUP 0= ABORT" Can't open a panel !"
	DUP @retain DROP			\  Mountain Lion4 August 2012 09:53:17 CEST -rt
	YES OVER @setcanchoosefiles: DROP
	DUP PIMP.KITE ;

: CHOICE ( panel -- a n )
	DUP @URL SWAP @release DROP	\ get rid of panel
	@path >4THSTRING
	\ 2dup type			\ for testing
;

: EZGET ( -- a n true | false )   PUSHME NEW.KITE DUP @runModal DUP >R IF CHOICE ELSE @release DROP THEN R> ;

\ --------------------------------------------------------------------
\ run kite on main thread to include file

: (EZGETMAIN) ( -- ret )  POCKET  EZGET IF ROT PLACE ELSE OFF THEN  0 ;

: EZGETMAIN  ( -- a n true | false )
	0 0 ['] (EZGETMAIN) PASS
	POCKET COUNT DUP 0<> DUP IF ELSE NIP NIP THEN ;

: LOAD-FILE ( -- )   EZGETMAIN IF INCLUDED THEN ;

\\ ( eof )