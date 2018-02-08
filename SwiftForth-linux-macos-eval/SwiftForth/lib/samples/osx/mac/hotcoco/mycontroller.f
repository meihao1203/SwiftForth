{ ====================================================================
Control panel Nib

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Implement a control panel with one slider and its outlet to control
the slider programmaticly.
Last: 18 August 2014 23:54:02 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Cocoa from within SwiftForth demonstration:

Demonstrates the interface to the objc-runtime in action:
-- some Cocoa calls
-- creating a new class for cocoa

Note: in SwiftForth set the I/O stuff right for displaying strings.
	  Use IMPOSTOR'S and don't forget to set FP stack in callback

The @awakeFromNib method in myclass, is executed during nib instantiation.
The method implementation here will just save the myclass instance ref
for further use.

This controller has just one slider:
The  @doSLider:   method will be used when user works the slider.

The slider has an outlet connected to myclass: myOutlet
BTW this is done in IB, not programmaticly.
The runtime will initiate the outlet, actually an instance variable,
using the setter method @setmyOutlet:
You can ommit this method, a default initiation method will be used instead.
The outlet should point to the NSSlider instance when initiated.

The user can programmaticly set the slider using the @myOutlet getter
method.

SLIDER! will set the slider to given value.

SS will run all automaticly. Watch slider move.

Obviously you can change the slider by dragging the 'walker' left and
right.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ the so called IBAction connected to the buttons and slider in the panel

AKA CALLBACK: IBACTION:

VARIABLE MYCLASSREF

IBACTION: *awakeFromNib ( rec sel -- ret )   _PARAM_0 MYCLASSREF ! 0 ;

COCOA: @intValue ( -- n )  \ NSControl method

IBACTION: *doSlider: ( rec sel sender -- n )   8 FSTACK  _PARAM_2  @intValue  IMPOSTOR'S CR .  0 ;

IBACTION: *myOutlet ( rec sel -- n )   8 FSTACK  Z" myOutlet" _PARAM_0 @IVAR ;

IBACTION: *setmyOutlet: ( rec sel obj -- ret )   8 FSTACK  _PARAM_2 Z" myOutlet" _PARAM_0 !IVAR 0 ;

: CONTROLTYPES ( -- a )   0" v@:V" ;

: @OUTLETTYPES ( -- a )    0" @@:" ;

: !OUTLETTYPES ( -- a )    0" v@:@" ;

: VARTYPE ( -- a )   0" @" ;

\ --------------------------------------------------------------------
\ The ForthClass, create class

NSObject NEW.CLASS myclass

\ Assign callbacks as methods to the class and register their names with the objc runtime

*awakeFromNib CONTROLTYPES 0" awakeFromNib"  myclass ADD.METHOD   \ internaly used by runtime at instantiating nib

*doSlider:  CONTROLTYPES 0" doSlider:"  myclass ADD.METHOD        \ internaly used by controler

*myOutlet @OUTLETTYPES 0" myOutlet"  myclass ADD.METHOD   			\ outlet getter, publicly used by us !       

*setmyOutlet: !OUTLETTYPES 0" setmyOutlet:"   myclass ADD.METHOD  \ outlet setter, internaly used by controler

\ Add instance variable, the outlet to the class

VARTYPE 0" myOutlet" myclass ADD.IVAR										\ the IBOutlet !

\ Add the class to the runtime

myclass ADD.CLASS

\ --------------------------------------------------------------------
\ testing

\ Topword
\ : MYNIB ( -- nib )   Z" mycontroller.nib" @NIB DUP /NIB 0= ABORT" Can't initiate NIB !" ;
: MYNIB ( -- windowcontroller )   Z" mycontroller.nib" SHOW.NIB DUP 0= ABORT" Can't initiate NIB !" ;

COCOA: @myOutlet ( -- NSSlider:ref )  \ myclass !!!
COCOA: @setIntValue: ( n -- ret )     \ NSSlider

: SLIDER! ( n -- )   MYCLASSREF @ @myOutlet @setIntValue: DROP ;

: SS ( -- )  MYNIB DROP  BEGIN  100 CHOOSE SLIDER!  500 MS  KEY? UNTIL ;

cr .( control panel with slider loaded ...)
cr .( ss  -- to start things)

\\ ( eof )