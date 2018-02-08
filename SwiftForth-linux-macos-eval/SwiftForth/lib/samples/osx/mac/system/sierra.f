{ ====================================================================
Temporary Sierra fixes

Copyright (c) 2014-2017 Roelf Toxopeus

SwiftForth version.
Some work-arounds for (temprary?) OS issues.
Last: 31 October 2017 at 10:26:57 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Since OSX 10.11 El Capitan, many GUI calls better be executed on the main
thread to avoid some issues. This includes some NIB handling.
Looks like things changed a bit again in macOS 10.12 Sierra. Settings should
be done on the main thread as well to avoid flickering while resizing a window.
Experimenting will clarify.

So far the following has been observed:
Main thread prefered -> initialisation, running modal, property adjustments,
setting title etc.
Also all contentview (NSView and subs) stuff should be PASSed or FORMAINed.

Secundary thread allowed -> opening, hiding, showing, closing, moving,
sizing, queries (@frame) 

The official Thread Programming Guide from Apple regarding the windows:
https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html#//apple_ref/doc/uid/10000057i-CH12-123351-BBCFIIEB

It does not talk about the changes in OSX 10.11 El Capitan and later. AFAIK we
have always done it like they tell us to do. So something fishy...
Notice that SHOW.NIB works from secundary thread in many cases. But when you use
auto layout in your nibs, it should be run from the main thread.  Only the
showWindow: message needs to run from the main thread.

Probably the best practice is to identify the part which should run
on the main thread and only run that on the main thread. Most of the
time this is just one message. But sometimes it's a few, mixed with
others and they're passed in one go like the fix for CREATE.WINDOW.

To get an idea what's happening, try the following (open Console.app as well)
and observe:
nswindow @alloc @init ( *)
( *) dup @orderFront: drop

Initialize Window on Main thread using PASS and switch to the main thread via
PAUSE and a MS instruction to have the initializer executed.
Upon return to the Forth thread show it.
Failing to do that, window resizing will flicker for all windows!
It appears you have to init _all_ things on the main thread to avoid resize
flickering later on in _all_ existing windows ...

El Capitan fixes:
CREATE.WINDOW   -- creates/initialises window on main thread
ADD>WINDOW      -- redefined using new CREATE.WINDOW

\ NIBWINDOW.CONTROLLER -- creates windowcontroller for nib on main thread
\ SHOW.NIB        -- redefined to use new NIBWINDOW.CONTROLLER

SHOW.NIB        -- the show part is PASSed to main thread

Additional fixes to the El Capitan fixes:
SET.WTITLE        -- sets given zero terminated string as title for window
SET.WTRANSPARENCY -- sets given transparency value 0.0-1.0 for window
SET.WBACKGROUND   -- sets given color for window

Sometimes you'll see weird window behavior while resizing. Even with the above
fixes applied. Most certain it's a ContenView stuff issue. These should be
executed on the main thread. Just PASS them...

BTW it looks like the Yosemite nagging issue is gone as of Sierra! So that
patch isn't needed anymore.

Test code:
VARIABLE newwin

: (window) ( -- )
	100e0 600e0 340e0 180e0 4fpushs
	ALLWIDGETS
	NSBackingStoreBuffered
	NO
	NSWindow @alloc @initWithContentRect:styleMask:backing:defer:
	1e0 FDUP F2DUP 4FPUSHS NSColor @colorWithCalibratedRed:green:blue:alpha:
	OVER @setBackgroundColor: DROP
	newwin ! ;


: window ( -- nswindowref )
	0 dup ['] (window) pass
	PAUSE 10 ms
	newwin @ DUP DUP @orderfront: DROP ;

-------------------------------------------------------------------- }

/FORTH
DECIMAL

1012 CONSTANT SIERRA

ABSENT ELCAPITAN [IF]
\ Needed fixes since El Capitan
\ Main thread redefinitions for NSWindow
: (CREATE.WINDOW) ( wptr4 -- )
	DUP WINDOW.ARGS  NSWindow @alloc @initWithContentRect:styleMask:backing:defer:
\ default opaque setting is YES, so need to chage it to change transparency!
	NO OVER @setOpaque: DROP
	OVER +W.REF !
	DUP +W.TITLE @ COUNT DROP OVER SET.WTITLE			\ this is ugly because of counted vs zero string
	DUP +W.TRANSPARENCY SF@ DUP SET.WTRANSPARENCY
	DUP +W.BACKGROUND CG4@ SET.WBACKGROUND ;

: CREATE.WINDOW ( wptr4 -- )   1 0 ['] (CREATE.WINDOW) PASS 100 MS PAUSE ;
	
: ADD.WINDOW ( wptr4 -- )
	DUP +W.REF @ IF DUP CLOSE.WINDOW THEN
	DUP CREATE.WINDOW
	SHOW.WINDOW ;

\ Main thread redefinition for the nibs.
(* testing:
: (NIBWINDOW.CONTROLLER) ( za -- )   NIBWINDOW.CONTROLLER POCKET ! ;
: NIBWINDOW.CONTROLLER ( za -- ref )   1 0 ['] (NIBWINDOW.CONTROLLER) PASS  POCKET @ ;
: SHOW.NIB ( za -- windowcontroller )   >NIBPATH NIBWINDOW.CONTROLLER 0 OVER  @showWindow: DROP ;
*)

: SHOW.NIB ( za -- windowcontroller )
	>NIBPATH NIBWINDOW.CONTROLLER 0 OVER  2 0 ['] @showWindow: PASS ;
[THEN]

\ Sierra additions
\ set window properties
: SET.WTITLE ( 0string wptr4 -- )    2 0 ['] SET.WTITLE PASS ;

: SET.WTRANSPARENCY ( wptr4 -- ) ( F: alpha -- )    1 1 ['] SET.WTRANSPARENCY PASS ;

: SET.WBACKGROUND ( wptr4 -- ) ( F: red green blue alpha -- )    1 4 ['] SET.WBACKGROUND PASS ;

cr .( temporary Sierra fixes loaded)

\\ ( eof)
