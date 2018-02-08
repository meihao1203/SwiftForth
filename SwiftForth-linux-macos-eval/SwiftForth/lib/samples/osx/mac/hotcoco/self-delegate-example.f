{ ====================================================================
Window delegation example

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Shows how to set your eventhandler for a window.
Last: 11 November 2017 at 11:52:22 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Example of a 'self' delegate: NSWindow instances.
Adding a delegate method to the NSWindow class is enough to work with
the NSWindow delegate protocol. Appearently NSWindow instances are their
own delegates by default.

Here the windowShouldClose: delegate method is implemented. The action
of the window close button depends on the method implementation.
CLOSE? -- deferred. Implementation of the windowShouldClose: method.
Expects the sender, here the close button and leaves a true/false flag.
-CLOSE and CLOSE -- actions for CLOSE?
/DELEGATE and -DELEGATE -- setting CLOSE?
-------------------------------------------------------------------- }

/FORTH
DECIMAL

DEFER CLOSE? ( sender -- flag )

: -CLOSE ( sender -- NO )   DROP IMPOSTOR'S ." We don't close!" CR NO ;

: CLOSE ( sender -- YES )   DROP IMPOSTOR'S ." Closing window... " CR 500 MS YES ;

CALLBACK: *windowShouldClose: ( rec sel sender:button -- bool )   _PARAM_2 CLOSE? ; 

: DELEGATETYPES   0" c@:V" ;

*windowShouldClose: DELEGATETYPES 0" windowShouldClose:"  NSWindow ADD.METHOD

: /DELEGATE ( -- )   ['] -CLOSE IS CLOSE? ;

: -DELEGATE ( -- )   ['] CLOSE IS CLOSE? ;

\ --- demo

NEW.WINDOW MYWIN
S" Delegate Window" MYWIN W.TITLE

: /DEMO
	MYWIN ADD.WINDOW
	10 ms
	/DELEGATE ;

CR .( window delegate test loaded ...)
CR .( /DEMO       -- init demo)
CR .( try window's red close button)
CR .( -DELEGATE   -- default window behaviour)

\\ ( eof )