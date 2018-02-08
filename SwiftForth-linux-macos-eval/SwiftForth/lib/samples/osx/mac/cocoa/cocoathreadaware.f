{ ====================================================================
Thread awareness

Copyright (c) 2009-2017 Roelf Toxopeus

Part of adding Cocoa event handling to Forth.
SwiftForth version.
Make sure Cocoa is aware of multi(posix)threading.
Last: 24 February 2013 17:35:16 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
MULTI.AWARE -- should be executed before any serious threads are added.
This protects the Cocoa framework.
Uses a much advised tric: create an NSThread and immediately end it.

After MULTI.AWARE is executed we can safely add the IMPOSTOR thread
for Forth to run on.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSThread
COCOA: @start ( -- ret )
COCOA: @cancel ( -- ret )
COCOA: @isMultiThreaded ( -- flag ) \ BOOL

: MULTI.AWARE ( -- )
	NSThread @alloc @init
	DUP @start DROP @cancel DROP
	NSThread @isMultiThreaded
	0= ABORT" Cocoa not aware of multi threading ! Aborting..."
;

\\ ( eof )

