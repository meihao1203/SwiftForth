{ ====================================================================
Cocoa interface starter

Copyright (c) 2010-2017 Roelf Toxopeus

Startup for turnkey.
SwiftForth version.
Last: 2 December 2017 at 21:53:23 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
OPERATOR goes coco, IMPOSTOR goes Forth
See swiftforth/src/ide/ul/startup.f

GOES.FORTH -- do necessary initialisations and execute QUIT
HOT.COCO -- set pretender startup hook and launch coco-sf.
The starter word for turnkeyes.
Contains fix for macOS 10.13 High Sierra: kicks the ObjC Runtime in
to action.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: .COCO ( -- )
	   ." Coco brewed 2 December 2017 at 21:53:23 CEST"
	CR ." ACTIVATE is deferred, Forth thread is posix"
;

: .ABOUT ( -- )
	CR .VERSION
	\ CR ." Custom version: no SWOOP no LOCALS|"
	CR .COCO ;
	
: GOES.FORTH ( -- )
	( /INTERPRETER ) /CMDLINE     \ QUIT executes /INTERPRETER as well -rt
	/RND
	ForthClass ADD.CLASS
	NONAP
	.ABOUT
	CR CR BRIGHT ." hello again " NORMAL
	0 DUP ['] NOP PASS				\ fix for macOS 10.13 High Sierra
	QUIT
;

: HOT.COCO ( -- )   ['] GOES.FORTH 'PRETENDING ! COCO.RUN ;

STARTER HOT.COCO

\\ ( eof )
