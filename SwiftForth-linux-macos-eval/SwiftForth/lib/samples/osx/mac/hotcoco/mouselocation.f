{ ====================================================================
Mouse cursor location

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Fetching global mouse coordinates (as floatingpoints)
Last: 9 February 2014 10:57:42 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
@MOUSE -- return current mouse position on fp stack.
MM -- print mouse location until key hit.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSEvent

COCOA: @mouseLocation ( -- sf:x sf:y )

: @MOUSE ( F: -- x y ) NSEvent @mouseLocation SWAP SF>F SF>F ;

: .MOUSE? ( y1 x1 y2 x2 f -- )
	IF 2DROP EXIT THEN
	2SWAP 2DROP 2DUP CR . . ;
	
: MM ( -- )
	0 DUP BEGIN
		@MOUSE F>S F>S 2OVER 2OVER D= .MOUSE?
	KEY? UNTIL 2DROP ;

CR .( global mouse location fetcher loaded ...)
CR .( mm  -- to start demo, move mouse around. Any key stops)

\\ ( eof )