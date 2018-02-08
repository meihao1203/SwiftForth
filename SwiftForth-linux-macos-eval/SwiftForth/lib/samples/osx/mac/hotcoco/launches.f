{ ====================================================================
File and URL app launching.

Copyright (c) 2013-2017 Roelf Toxopeus

SwitForth version.
Use of NSWorkspace to open files/locations in their default applications.
Last: 30 January 2013 17:44:42 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
LAUNCHURL -- launches default browser with given url.
GOTO" -- browser and go to quoted url, as example:
SFWEB -- go to FORTH, Inc web home web page.

LAUNCHFILE -- launches default opener with given file.
SFMANUAL -- open SwiftForth manual in default PDF viewer.

More examples of NSWorkspace usage:
\ launch application
: >TERMINAL
  @" Terminal.app" NSWorkspace @sharedWorkspace @launchApplication: DROP ;

\ hide all applications from sight
: HH ( -- )
  NSWorkspace @sharedWorkspace @hideOtherApplications DROP ;
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSWorkspace
COCOA: @sharedWorkspace ( -- ref )
COCOA: @openURL: ( nsurl -- boolean )
COCOA: @openFile: ( nsstring -- boolean )
COCOA: @launchApplication: ( string -- ret )
COCOA: @hideOtherApplications ( -- ret )

COCOACLASS NSURL
COCOA: URLWithString: ( nsstring -- nsurl )

: LAUNCHURL ( zstring -- )
	>NSSTRING DUP
	NSURL URLWithString:
	NSWorkspace @sharedWorkspace @openURL: DROP
	@release DROP ;

\ : URL: ( "<spaces>name" -- )   BL WORD COUNT DROP LaunchURL ;
	
: GOTO" ( -- )
	POSTPONE Z"
	STATE @
			IF POSTPONE LAUNCHURL
		ELSE LAUNCHURL
	THEN ; IMMEDIATE

: SFWEB ( -- )   GOTO" http://www.forth.com" ;

: LAUNCHFILE ( zstring -- )	
	>NSSTRING DUP
	NSWorkspace @sharedWorkspace @openFile: DROP
	@release DROP ;

: SFMANUAL ( -- )
	ROOTPATH COUNT PAD ZPLACE
	s" swiftforth/doc/swiftforth-linux-osx.pdf" PAD ZAPPEND
	PAD LAUNCHFILE ;

cr .( SFWEB     will bring you to Forth, Inc.)
cr .( SFMANUAL  will open the SF manual)

\\ ( eof )