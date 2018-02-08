{ ====================================================================
Another GUI example

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Load a nib file with buttons and assign words to them.
Last: 16 Oct 2015 21:25:15 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Cocoa from within SwiftForth demonstration:

Using a grid of buttons in a NIB.
Add tags in IB for every button: 0 up to 11
Use @tag to retrieve tag, which will be used as index.
This allows for an indexed execution array and only one method is needed!
Could have tagged the buttons with the calculated indexes: e.g. 0 4 8 12 etc.

Biggest challenge is getting the nib right in XCode4
What a lousy interface! This is 2013 remember...

Note: the Forth running the actions, is NOT the Forth thread IMPOSTOR.
It's a callback running on another thread/GCD-queue.
This can be either the Main thread, or a thread/dispatch-queue spawned
by MAIN, or perhaps even an 'ordinary' callback. You don't know and
maybe it's completely irrelevant as long as you're aware it's not IMPOSTOR.
You can suspend IMPOSTOR when needed.

DEF.ACTION -- default actions for buttons:
BUTTONS -- execution array for buttons, fill it with the defualt actions
DO.BUTTON -- default actions for testing

MyButtonsClassTagged -- class taking care of button actions, using
one method:    button:

/BUTTONS -- init and run demo
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Utillities, Actions, etc.

\ NSControl class
COCOA: @intValue ( -- N )      \ for the buttons, this will be 'on/off' toggling
COCOA: @tag ( -- NSInteger )   \ tag is set to whatever you want in IB, here indexes

: DEF.ACTION ( sender -- )   @intValue . ;

12 CELLS BUFFER: BUTTONS
' DEF.ACTION BUTTONS !
BUTTONS BUTTONS CELL+ 11 CELLS CMOVE 

: DO.BUTTON ( SENDER -- )
	IMPOSTOR'S INVERSE 
	DUP @tag DUP 1+ . ." : "
	CELLS BUTTONS + @EXECUTE
	NORMAL ;

\ --------------------------------------------------------------------
\ the so called IBActions connected to the buttons

\ nice syntactic sugar
AKA CALLBACK: IBACTION:

IBACTION: *button: ( rec sel sender -- n )  8 FSTACK _PARAM_2 DO.BUTTON 0 ;

: BUTTONMETHODTYPES ( -- addr )   0" v@:V" ;

\ --------------------------------------------------------------------
\ this will be the delegate class for the button actions in the nib.
\ the OS takes care of assigning it as such.

NSObject NEW.CLASS MyButtonsClassTagged

\ assign callback ( ibaction ) as method to the class and register its name with the objc runtime
*button:  BUTTONMETHODTYPES 0" button:"   MyButtonsClassTagged ADD.METHOD

\ add the class
MyButtonsClassTagged ADD.CLASS

\ --------------------------------------------------------------------
\ The Nib stuff

\ : /BUTTONS ( -- )   Z" MyButtonsTagged.nib" @NIB /NIB 0= ABORT" Can't initiate NIB !" ;
: /BUTTONS ( -- )   Z" MyButtonsTagged.nib" SHOW.NIB 0= ABORT" Can't initiate NIB !" ;

cr .( /buttons   -- to add buttons window to coco-sf)

\\ ( eof )