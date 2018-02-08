{ ====================================================================
Show alert panel

Copyright (c) 2009-2017 Roelf Toxopeus

SwiftForth version.
Show alert window (Lion doesn't really like this), deprecated...
Now, it's a demonstration of error messages issued by the ObjC runtime
in the I/O window.

OSX 10.11 El Capitan
Notice the delayed backtrace dump in the Forth repl.

Last: 28 October 2015 at 16:55:17 GMT+1   -rt
==================================================================== }

/FORTH
DECIMAL

Cocoa.framework

FUNCTION: NSRunAlertPanel ( NSStringRef:head NSStringRef:msg NSStringRef:ok n1 n2 -- ret )

: HEADS ( -- )  @" Cocoa Alert Panel"  ;
: MSG ( -- )     @" Hoi! Groeten uit Utreg"  ;
: OKIDOKI ( -- )   @" Back to Forth"  ;

: DO.ALERT ( -- )
	ALLOCPOOL
	HEADS MSG OKIDOKI 0 0 NSRunAlertPanel DROP
	releasepool DROP ;

CR .( alert demo loaded ...)
CR .( do.alert   --   starts demo)
CR .( OSX 10.7 and up will complain, don't worry, yet)

\\ ( eof )