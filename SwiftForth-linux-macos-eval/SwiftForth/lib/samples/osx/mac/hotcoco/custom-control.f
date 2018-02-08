{ ====================================================================
Custom Control Panel

Copyright (c) 2012-2017 Roelf Toxopeus

SwiftForth version
Programmaticly adding controls, like buttons and sliders
Last: 17 Oct 2015 16:00:42 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Interesting part is adding a method to an existing class:
Objective-C allows you to add your own methods to existing classes
through categories and class extensions:
Customizing Existing Classes

Create a window MYCONTROLWIN for the control objects: NSButton and
NSSlider, both NSControl subclasses. The button will randomly set a
scaler value for the slider.
Declare some methods from NSWindow, NSControl, NSSlider and NSActionCell.
Create a method for what to do when the button is hit and add it to
the NSButton class. Similar for the slider.
/BUTTON and /SLIDER will create instances, set their actions and
draw them in MYCONTROLWIN.
/CONTROL ties it all together and displays MYCONTROLWIN with the
controls.
Use SLIDER.MAX and SLIDER.MAX! to inspect and change the maximum
slider values.
SLIDER! sets the slider value programmaticly.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ window containing controls
NEW.WINDOW MYCONTROLWIN
S" controls" MYCONTROLWIN W.TITLE

\ NSControl subclasses
COCOACLASS NSButton
COCOACLASS NSSlider

\ some methods needed
COCOA: @initWithFrame: ( x y w h -- id )
COCOA: @addSubview: ( view -- ret )
COCOA: @intValue ( -- n )  \ NSControl
COCOA: @setMaxValue: ( double:lo double:hi -- ret ) \ NSSlider
COCOA: @setMinValue: ( double:lo double:hi -- ret ) \ NSSlider
COCOA: @setAction: ( sel -- ret )	\ NSActionCell
COCOA: @setTarget: ( id -- ret )	\ NSActionCell

\ some needed words for all
VARIABLE SCALER 12 CHOOSE SCALER !
: CONTROLTYPES ( -- a )  0" v@:@" ;

\ add a method to the NSButton class
\ what to do when our button is hit
CALLBACK: *klik ( rec sel sender -- void )
	12 CHOOSE SCALER !
	IMPOSTOR'S ( CR ) INVERSE 0 20 AT-XY ."  scaler: " SCALER ? NORMAL ;
 
*klik CONTROLTYPES 0" klik" NSButton ADD.METHOD

\ draw button and set it's action
: /BUTTON ( -- )
	10e0 10e0 100e0 100e0 4FPUSHS  								( frame size and position )
	NSButton @alloc @initWithFrame:								( button instance )
	@" Click me!" OVER @setTitle: DROP
	DUP MYCONTROLWIN +W.REF @ @contentView @addSubview: DROP	( add control as view to windowview )
	DUP DUP @setTarget: DROP									   ( self is target )
	0" klik" @SELECTOR SWAP @setAction: DROP					( apply new method as action )
;

\ add a method to the NSSlider class
\ what to do when slider is moved
CALLBACK: *schuif ( rec sel sender -- void )
	8 FSTACK _PARAM_2 @intValue SCALER @ *
	IMPOSTOR'S ( CR ) INVERSE 20 DUP AT-XY 4 .R NORMAL ;

*schuif CONTROLTYPES 0" schuif" NSSlider ADD.METHOD

\ draw slider and set the action
VARIABLE MYSLIDER
: /SLIDER ( -- )
	200e0 10e0 30e0 100e0 4FPUSHS  								( frame size and position )
	NSSlider @alloc @initWithFrame:								( slider instance )
	DUP MYCONTROLWIN +W.REF @ @contentView @addSubview: DROP	( add control as view to windowview )
	DUP DUP @setTarget: DROP									   ( self is target )
	0" schuif" @SELECTOR OVER @setAction: DROP				( apply new method as action )
	>R
	100e0 FPUSHD R@ @setMaxValue: DROP							( set maximum value )
	  0e0 FPUSHD R@ @setMinValue: DROP							( set minimum value )
	R> MYSLIDER !
;

\ just to test the FPRET call
\ Note: in a FUNCTION: declaration don not use a F: in the first stackpicture,
\ the F: will be seen as a parameter!
COCOA-FPRET: @maxValue ( -- ) ( F: -- r )  \ NSSlider
: SLIDER.MAX ( F: -- r )   MYSLIDER @ @maxvalue ;

: SLIDER.MAX! ( F: r -- )  FPUSHD MYSLIDER @ @setmaxvalue: DROP ;

\ test setting the slider programmaticly
COCOA: @setIntValue: ( n -- ret )   \ NSControl

: SLIDER! ( n -- )   MYSLIDER @ @setIntValue: DROP ;

\ build control window
: /CONTROL ( -- )   MYCONTROLWIN ADD.WINDOW /BUTTON /SLIDER ;

cr .( /CONTROL to build control)

\\ ( eof )
