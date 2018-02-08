{ ====================================================================
Mouse cursor visibility.

Copyright (C) 2011-2017 Roelf Toxopeus

SwiftForth version.
Hide and show mouse/cursor, handy for presentations.
Last: 24 February 2013 21:36:29 CET  -rt
==================================================================== }

/FORTH
DECIMAL

COCOACLASS NSCursor

COCOA: @hide ( -- ret )
COCOA: @unhide ( -- ret )
COCOA: @setHiddenUntilMouseMoves: ( flag -- ret )

: HIDE-MOUSE ( -- )
	NSCursor @hide DROP
	NO NSCursor @setHiddenUntilMouseMoves: DROP ;

: SHOW-MOUSE ( -- )   NSCursor @unhide DROP ;

\\ ( eof )

\ test:
NEW.WINDOW WIN WIN ADD.WINDOW
HIDE-MOUSE                           \ click on window, mouse pinter vanishes
	