{ ====================================================================
Create and add a menubar without the use of a NIB

Copyright (c) 2017 Roelf Toxopeus

SwiftForth version.
Simple Forth ObjC Runtime interface usage example
Last: 6 November 2017 at 17:06:21 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
This example shows how to create and add a menubar programmatically to
an application. It's a quick and dirty way of adding a simple menubar
plus 'quit' menuitem. No factoring.
Coco-sf boots without a menubar. The OS provides something resembling
it, but it's not a menu: NSApp @ @mainMenu . 0 ok
After executing /SIMPLEMENU  NSApp @ @mainMenu . 244361824  ok

/SIMPLEMENU -- replace the current menubar, if any, with a simple one
item only menubar.

Note the following code in /SIMPLEMENU
	@" Bye" z" terminate:" @selector @" q"
	NSMenuItem @alloc @initWithTitle:action:keyEquivalent: @autorelease
	NSApp @ over @setTarget: drop
The target is the provider of the code for the selector given as action.
The NSApplication instance NSApp has a method terminate: which is what
we want here. So no need to provide an extra menu handling class in
this case.
	
As a bonus, here are some words hiding and revealing the menubar and
dock. Very useful in presentations or when you need the whole screen
estate!
Caution: they need a menubar. Without the system hangs!

MENUON? -- returns true if menubar is visible and selectable.
MENUON -- make menubar and dock visible and selectable.
MENUOFF -- hides menubar and dock, they're not selectable.
~MENU -- toggles menbar and dock state.

See also:
sfmenu.f is an example of an enhanced menubar targeted at coco-sf usage.
cocoa-focus.f has more elaborate presentation possibilities.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSMenu
COCOACLASS NSMenuItem

COCOA: @setMainMenu: ( menu -- ret )	\ NSApplication
COCOA: @mainMenu ( -- menuref )   \ NSApplication
COCOA: @addItem: ( newitem -- ret )	\ NSMenu
COCOA: @setSubmenu: ( newmenu -- ret )	\ NSMenuItem
COCOA: @initWithTitle:action:keyEquivalent: ( nsstring action nsstring -- NSMenuItemRef )		\ NSMenuItem
COCOA: @setTarget: ( obj -- ret )	\ NSMenuItem

: /SIMPLEMENU ( -- )
\ add menubar
	NSMenuItem @alloc @init @autorelease
	NSMenu @alloc @init @autorelease
	2dup @addItem: drop
	NSApp @ @setMainMenu: drop
	( item* )

\ add quit menu
	@" Bye" z" terminate:" @selector @" q"
	NSMenuItem @alloc @initWithTitle:action:keyEquivalent: @autorelease
	NSApp @ over @setTarget: drop
	NSMenu @alloc @init @autorelease
	tuck @addItem: drop
	swap ( item* ) @setSubmenu: drop ;

\ --------------------------------------------------------------------
\ Menubar and Dock visibility

COCOA: @setMenuBarVisible: ( visible -- ret )
COCOA: @menuBarVisible ( -- bool )

: MENUON? ( -- n )   NSMenu @menuBarVisible ;

: MENUON ( -- )   1 NSMenu @setMenuBarVisible: DROP ;

: MENUOFF ( -- )   0 NSMenu @setMenuBarVisible: DROP ;

: ~MENU ( -- )   MENUON? 0= ABS NSMenu @setMenuBarVisible: DROP ;

CR .( /SIMPLEMENU to add a menubar to coco-sf)

\\ ( eof)