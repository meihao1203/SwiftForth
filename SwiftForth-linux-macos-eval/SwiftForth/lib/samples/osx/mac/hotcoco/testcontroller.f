{ ====================================================================
Control panel Nib

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Implement a control panel with three buttons and a slider: 4 defered actions
Last: 17 Oct 2015 13:07:30 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Cocoa from within SwiftForth demonstration:

Demonstrates the interface to the objc-runtime in action:
-- some Cocoa calls
-- creating a new class for cocoa

Note: in SwiftForth set the I/O stuff right for displaying strings.
	  Use IMPOSTOR'S and don't forget to set FP stack in callback

First add some deferred actions for the buttons and the slider:
BUTTON1   BUTTON2   BUTTON3   SLIDER
/ACTIONS -- sets these to default actions.
Plug in other actions at will.

Then create the callbacks *BUTTON1  *BUTTON2  *BUTTON3  *SLIDER
which are the implementations for the methods, IBActions, declared
later in the TestController class. All callbacks receive 3 parameters
	receiver selector sender
Only the sender is passed to the deferred word. Its consumption is
mandatory. All callbacks return a zero on top.
Here CALLBACK is aliased with IBACTION: for consistency with Apple's
terminology in Interface Builder.

Now create the TestController class and add the methods
doButton1:  doButton2:   doButton3:   doSlider:
using the implementations created earlier.
Add the class to the runtime.

Get the panel's NIB testcontroller.nib and create nib window
controller TCCONTROLLER and show it with DO.SHOW.

Press buttons and move slider to execute the actions.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Utillities, Actions, etc.

DEFER BUTTON1   DEFER BUTTON2   DEFER BUTTON3   DEFER SLIDER

VARIABLE SCALER 1 SCALER !

: SCALER+ ( -- )   IMPOSTOR'S CR ." scale by " 1 SCALER +! SCALER ? ;
: SCALER- ( -- )   IMPOSTOR'S CR ." scale by " -1 SCALER +! SCALER ? ;
: /SCALER ( -- )   IMPOSTOR'S CR ." reset scaler"  1 SCALER ! ;

COCOA: @intValue ( -- n )  \ NSControl method
: SCALE ( x -- )   IMPOSTOR'S CR @intValue SCALER @ * . ;

: /ACTIONS ( -- )
	['] SCALER+ IS BUTTON1 ['] SCALER- IS BUTTON2  ['] /SCALER IS BUTTON3
	['] SCALE IS SLIDER ;

\ --------------------------------------------------------------------
\ the so called IBAction connected to the buttons and slider in the panel

AKA CALLBACK: IBACTION:

IBACTION: *BUTTON1 ( rec sel sender -- n )   8 FSTACK  _PARAM_2 BUTTON1  0 ;

IBACTION: *BUTTON2 ( rec sel sender -- n )   8 FSTACK  _PARAM_2 BUTTON2  0 ;

IBACTION: *BUTTON3 ( rec sel sender -- n )   8 FSTACK  _PARAM_2 BUTTON3  0 ;

IBACTION: *SLIDER ( rec sel sender -- n )   8 FSTACK  _PARAM_2 SLIDER  0 ;

: CONTROLTYPES ( -- a )   0" v@:V" ;

\ --------------------------------------------------------------------
\ The ForthClass, create class

NSObject NEW.CLASS TestController

\ Assign callbacks as methods to the class and register their names with the objc runtime
*BUTTON1 CONTROLTYPES 0" doButton1:" TestController ADD.METHOD

*BUTTON2 CONTROLTYPES 0" doButton2:" TestController ADD.METHOD

*BUTTON3 CONTROLTYPES 0" doButton3:" TestController ADD.METHOD

*SLIDER  CONTROLTYPES 0" doSlider:"  TestController ADD.METHOD

\ Add the class to the runtime

TestController ADD.CLASS

\ --------------------------------------------------------------------
\ The Nib stuff

\ Topword
\ : DO.SHOW ( -- )   /ACTIONS Z" testcontroller.nib" @NIB /NIB 0= ABORT" Can't initiate NIB !" ;
: DO.SHOW ( -- )   /ACTIONS Z" testcontroller.nib" SHOW.NIB 0= ABORT" Can't initiate NIB !" ;

cr .( control panel with buttons and slider loaded ...)
cr .( do.show   -- to start things)

\\ ( eof )