{ ====================================================================
Simple Forth ObjC Runtime interface usage example

Copyright (c) 2010-2017 Roelf Toxopeus

Last: 24 February 2013 21:00:31 CET   -rt
==================================================================== }

/FORTH
DECIMAL

COCOACLASS NSProcessInfo

COCOA: @processInfo ( -- NSProcessInfo:info )    \ NSProcessInfo method
COCOA: @processName ( -- NSString:name )         \ NSProcessInfo method
COCOA: @getCString: ( NSStringRef -- zstring )   \ NSString method

: .PROCNAME ( -- )
	PAD DUP 40 ERASE                \ setup pad
	NSProcessInfo @processInfo      \ retrieve processinfo
	@processName                    \ get the name info
	@getCString: DROP               \ use pad to convert name info into C string
	PAD ZCOUNT TYPE ;               \ yeah

cr .( simple example loaded ...)
cr .( type  .PROCNAME  to run it)

\\ ( eof )
