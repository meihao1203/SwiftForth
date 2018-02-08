{ ====================================================================
Transform SF in to GUI app

Copyright (c) 2009-2017 Roelf Toxopeus

Part of adding Cocoa event handling to Forth.
SwiftForth version.
Last: 12 November 2017 at 09:24:10 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Make current background proces (SwiftForth) a GUI app, at least wrt
the GUI itself. Uses NSApplication ActivationPolicies.

SF>COCOA -- transform sf in to coco-sf, following standard procedure:
allocate autoreleasepool, create shared application and set the NSApp
policy to NSApplicationActivationPolicyRegular.
*It becomes an ordinary app with an icon in the Dock and a user interface.
NSApplicationActivationPolicyRegular is the default for bundled apps,
unless overridden in the Info.plist.

Prior to SF>COCOA, sf activation policy is NSApplicationActivationPolicyProhibited.
Which is typical for processes running in a shell, like sf.
*It does not appear in the Dock and may not create windows or be activated.
This corresponds to the value of the LSBackgroundOnly key in the application’s
Info.plist being 1. This is also the default for unbundled executables
that do not have Info.plists.

* = learned from NSRunningApplication.h

0 CONSTANT NSApplicationActivationPolicyRegular
2 CONSTANT NSApplicationActivationPolicyProhibited

Test: redefine SF>COCOA and recomplie
COCOA: @activationPolicy ( -- policy )

VARIABLE SF-POLICY

: SF>COCOA ( -- )
	NSApp @ @activationPolicy SF-POLICY !
   SF>COCOA ;
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSApplication

COCOA: @sharedApplication ( -- NSApplication:ref )
COCOA: @setActivationPolicy: ( policy -- bool )

VARIABLE MAINPOOL	 \ cache main autoreleasepool

: SF>COCOA ( -- )
	allocPool MAINPOOL !
	NSApplication @sharedApplication DUP 0= ABORT" Can't create a shared application !"
	0 SWAP @setActivationPolicy: DROP ;

\\ ( eof )

