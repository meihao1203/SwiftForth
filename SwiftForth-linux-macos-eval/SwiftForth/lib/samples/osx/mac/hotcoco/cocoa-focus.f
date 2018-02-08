{ ====================================================================
Kiosk modes

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Cocoa version of the Carbon Kiosk mode settings.
Note: Snow Leopard (OSX 10.6) will complain. Don't botter!
	  From Lion (OSX 10.7) and up, ok without wining
Last: 24 October 2017 at 16:59:02 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Rewrite of the Focus On functions as used in CarbonMacForth. 
The focus words allow for kiosk settings used to isolate you from the
desktop and other applications during development and presentations.
It also helps in enlarging the screen estate, by hiding the menubar
and dock. In some modes, no mouse movement or click will expose them!

Apart from setting presentation modes, a curtain is drawn between
coco-sf and the rest: CURTAIN. Default is black, but you can change it,
see bigwindowclass3.f  Open curtain with -CURTAIN.

Setting the focus, create words like
WEOWN -- focus on me, all hidden, command.tab process switching still on.
WEALLOWSOME -- focus on us, hidden desktop showable menubar and dock.
WEALLOW -- focus on No-one, normal situation with desktop menubar dock etc.

Some notes:
It effects COCO-SF *not* TERMINAL.APP.
If you have other GUI objects in COCO-SF and they seem to be covered
by the black fill:
click in the black void and your COCO-SF GUI things ought to pop up.

So using Terminal for I/O, it's not as useful as it was in MacForth.
Having a Cocoa I/O window makes improves the situation. Than add the
Sibly editor(s) in sf...
Check MFonVFX!

This is probably Roelf's most favourite Forth utillity with a multi-
tasking OS. It recreates in a way the situation with a monotasking OS
on the Atari and Mach2: P A R A D I S E.
Speedup development time 1000x. No distractions, playing with widgets,
launching other applications, getting carried away.
Ideal for presentations. Whole screen presentations using video beamers,
no inadvertently popping up menus and dock!

There are other ways to achieve this: quit the Finder and hide all
other applications.
-------------------------------------------------------------------- }

LACKING BIGWINDOW  PUSHPATH MAC INCLUDE hotcoco/bigwindowclass4.f POPPATH

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ the Curtain we draw between us and the rest:

COCOA: @setHidesOnDeactivate: ( bool -- ret ) \ NSWindow, 10.11 should run on main thread

: -CURTAIN ( -- )   BIGWINDOW +W.REF @ IF BIGWINDOW CLOSE.WINDOW THEN ;

: (CURTAIN) ( -- )   YES BIGWINDOW +W.REF @ @setHidesOnDeactivate: DROP ;

: CURTAIN ( -- )   NEW.BIGWINDOW  0 0 ['] (CURTAIN) PASS ;

\ --------------------------------------------------------------------
\ The actual kiosk/presentation modes:

COCOA: @setPresentationOptions: ( options -- ret ) \ NSApplication

\ NSUInteger -- NSApplicationPresentationOptions
         0 CONSTANT NSApplicationPresentationDefault
1 0 LSHIFT CONSTANT NSApplicationPresentationAutoHideDock
1 1 LSHIFT CONSTANT NSApplicationPresentationHideDock
1 2 LSHIFT CONSTANT NSApplicationPresentationAutoHideMenuBar
1 3 LSHIFT CONSTANT NSApplicationPresentationHideMenuBar

{ --------------------------------------------------------------------
1 4 LSHIFT CONSTANT NSApplicationPresentationDisableAppleMenu
1 5 LSHIFT CONSTANT NSApplicationPresentationDisableProcessSwitching
1 6 LSHIFT CONSTANT NSApplicationPresentationDisableForceQuit
1 7 LSHIFT CONSTANT NSApplicationPresentationDisableSessionTermination
1 8 LSHIFT CONSTANT NSApplicationPresentationDisableHideApplication
1 9 LSHIFT CONSTANT NSApplicationPresentationDisableMenuBarTransparency
-------------------------------------------------------------------- }

\ --------------------------------------------------------------------
\ Focussing

: WEALLOW ( -- )  ( normal situation with desktop menubar dock etc. )
	NSApplicationPresentationDefault NSApp @ @setPresentationOptions: DROP
	-CURTAIN ;

: WEALLOWSOME ( -- )  ( hidden desktop showable menubar and dock )
	NSApplicationPresentationAutoHideDock
	NSApplicationPresentationAutoHideMenuBar OR
	NSApp @ @setPresentationOptions: DROP
	CURTAIN ;

: WEOWN ( -- )
	NSApplicationPresentationHideDock
	NSApplicationPresentationHideMenuBar OR
	NSApp @ @setPresentationOptions: DROP
	CURTAIN ;

: .HELP-FOCUS ( -- )
CR ." WeOwn       -- all hidden, command.tab process switching still on "
CR ." WeAllowSome -- hidden desktop showable menubar and dock"
CR ." WeAllow     -- normal situation with desktop menubar dock etc." ;

CR .( Focus on... loaded)
.HELP-FOCUS

\\ ( eof )

\ test:
WEOWN
NEW.WINDOW WIN WIN ADD.WINDOW  \ click on window, should see a lonely window on black screen