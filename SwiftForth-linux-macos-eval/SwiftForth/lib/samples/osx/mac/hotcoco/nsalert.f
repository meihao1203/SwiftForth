{ ====================================================================
Show alert

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Preferred alert usage: NSAlert
Last: 24 May 2013 10:28:37 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
/WELCOME -- creates and initializes an alert.

NoTE:
: WELCOME  /WELCOME @runModal DROP ;
will run it on our Forth thread, which is a background thread, so unsafe!

ALERT -- using FORMAIN will run it on the ObjC thread, i.e. the main thread.

WELCOME -- example
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSAlert

COCOA: @alertWithMessageText:defaultButton:alternateButton:otherButton:informativeTextWithFormat: ( alerttext button1 button2 button3 text -- ref )
\ COCOA: @runModal ( -- integer )

: /WELCOME ( -- NSAlertRef )
	0  ( Alert )
	0 	( OK )
	0	( no alternative )
	0	( no other button )
	@" Hi, push button for Forth"
	NSAlert @alertWithMessageText:defaultButton:alternateButton:otherButton:informativeTextWithFormat:
;

: ALERT ( NSAlertRef -- )   >R 0" runModal" @selector 0 YES R> FORMAIN DROP ;

: WELCOME  ( -- )    /WELCOME ALERT ;

cr .( type   welcome)

\\ ( eof )


