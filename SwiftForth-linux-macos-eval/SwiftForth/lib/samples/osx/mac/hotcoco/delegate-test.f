{ ====================================================================
Window delegation example

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Shows how to set your eventhandler for a window.
Last: 28 October 2015 at 16:31:56 GMT+1  -rt
==================================================================== }

{ --------------------------------------------------------------------
First create and add a class, WindowDelegate, which will pose as the
delegate for a window.
Here, one method is implemented, the   windowShouldClose:  message,
which is sent to the delegate by the OS (eventhandler) when its window
will be closed. The delegate can than act upon it with some cleaning up,
or decide it doesn't want to close at all.

Then build a window, MYWIN, and set the new class as its delegate
with /DELEGATE. Try the red close button on the window.
Restore the default behaviour by decoupling the delegate from the
window with -DELEGATE. Hit the red button again...

Note: normally you use a delegate for other things than overriding
methods as is done here. See other demo's in the HOTCOCO folder.

Important since OSX 10.11 El Capitan:
/MYDELEGATE -- initiate the NSWindow delegate class on the main thread!

Whenever adding a window (which happens on  the main thread), give it
10 ms at the least to 'settle'.

-------------------------------------------------------------------- }

/FORTH
DECIMAL

CALLBACK: *windowShouldClose: ( rec sel sender:button -- bool )
	IMPOSTOR'S ." We don't close!" CR NO ; 

: DELEGATETYPES   0" c@:V" ;

NSWindow NEW.CLASS WindowDelegate

*windowShouldClose: DELEGATETYPES 0" windowShouldClose:"  WindowDelegate ADD.METHOD

WindowDelegate ADD.CLASS

COCOA: @setDelegate: ( id -- ret ) \ NSWindowDelegate object

\ --- demo

NEW.WINDOW MYWIN
S" Delegate Window" MYWIN W.TITLE

0 VALUE MYDELEGATE

: /DELEGATE ( -- )   MYDELEGATE MYWIN @ @setDelegate: DROP ;

: -DELEGATE ( -- )   0 MYWIN @ @setDelegate: DROP ;

: /MYDELEGATE ( -- )   WindowDelegate @alloc @init TO MYDELEGATE ;

: /DEMO
	MYWIN ADD.WINDOW
	10 ms
	0 0 ['] /MYDELEGATE PASS
	/DELEGATE ;

CR .( window delegate test loaded ...)
CR .( /DEMO       -- init demo, use only once)
CR .( try window's red close button)
CR .( -DELEGATE   -- default window behaviour)
CR .( when you close the window now, it's really gone and demo is over!)


\\ ( eof )