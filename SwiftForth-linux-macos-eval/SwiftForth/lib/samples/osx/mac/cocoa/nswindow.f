{ ====================================================================
Window interface

Copyright (c) 2008-2017 Roelf Toxopeus

Part of GUI stuff.
SwiftForth version.
A minimal window creating interface
Compatible where possible with MacForth and Mach2.
Last: 15 Dec 2016 14:28:36 CET     -rt
==================================================================== }

{ --------------------------------------------------------------------
About this window interface.

The OS does the housekeeping. Forth keeps track of things in case of a
turnkey, so windows can be restored with last settings.

Forth creates a named window record with NEW.WINDOW.
This record is initialy used to create the new window. Later it's used
as scratch area for setting and retrieving window info from the OS.
The record is also used after a turnkey/snapshot to re-add the window.
All the W.xxx and +W.xxx words affect this record (only) and don't change
the window (directly).
For real changes use the other words like the SET.Wxxx and xxx.WINDOW words.
Note: there is a variant on NEW.WINDOW, (NEW.WINDOW) which allows creating
nameless windows.

Windows are added to the environment with ADD.WINDOW.
If an existing window is re-added, it will be closed first.

To update the current window settings in the window record, use SAVE.WINDOW.
Useful before a snapshot or turnkey.

When closing a window, the window structure in Forth is not forgotten,
it's just pointing to 0: no window
You can reuse the window structure for another window, with ADD.WINDOW.

Most words defined are in MacForth style:

/WINDOW.RECORD -- size in bytes for a default window record.
Field pointers in to the record:
+W.REF -- points to windowref field, contains NSWindow ref.
+W.GPORT -- points to windowgport field, contains gport ref.
+W.BOUNDS -- points to windowbounds field, contains CGRect values.
+W.BACKING -- points to windowbacking field, do we need this?
+W.DEFER -- points to windowdefer field, do we need this?
+W.STYLE -- points to windowstyle field
+W.TITLE -- points to windowtitle field, contains pointer to counted string.
+W.TRANSPARENCY -- points to windowtransparency field, contains transparency CGFloat.
+W.BACKGROUND -- points to windowbackground field, contains NSColor ref.

Affects the window record only, execute these before ADD.WINDOW.
W.BOUNDS -- set initial window bounds
W.STYLE -- set initial window style
W.TITLE -- set initial window title
W.TRANSPARENCY--  set initial window transparency
W.BACKGROUND -- set initial window background colour

Change window after ADD.WINDOW, window record is used for scratch.
RESIZE.WINDOW -- resize window with given width and height.
MOVE.WINDOW -- move window to given x and y.
FIX.WINDOW -- place window with given CGRect.
SHOW.WINDOW -- show window.
HIDE.WINDOW -- hide window, doesn't close it.
CLOSE.WINDOW -- close window, reset window record.
SET.WTITLE -- set/change the window title.
SET.WTRANSPARENCY -- set/change the window transparency.
SET.WBACKGROUND -- set/change the window background colour.
SET.WSTYLE -- still crashes, do not use.
WINDOW.FRAME -- get window frame size CGRect. Updates the window record as well.
SAVE.WINDOW -- save window frame for before doing a turnkey/snapshot.
Updates the window record as well. Should save a lot more info.

/WINDOW -- initialises a window record to default valaues.
(NEW.WINDOW) -- allocates an initialised window record.
NEW.WINDOW -- creates a new named window record, initialised to defaults.
WINDOW.ARGS -- fetches the necessary parameters for creating a NSWindow
instance, from a window record.
CREATE.WINDOW -- creates new NSWindow instance. Values stored in window
record can be used as parameters.
ADD.WINDOW -- create NSWindow instance and show it on screen. Uses values
from given window record.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ NSWindow class

COCOACLASS NSWindow

COCOA: @initWithContentRect:styleMask:backing:defer: ( cgfloat:x cgfloat:y cgfloat:w cgfloat:h stylemask backing defer -- id ) \ 4 CGFloats int int BOOL -- NSWindow object
COCOA: @setOpaque: ( flag -- ret )								\ BOOL flag
COCOA: @orderFront: ( sender -- ret )							\ id sender
COCOA: @orderOut: ( sender -- ret )								\ id sender
COCOA: @close ( -- ret )
COCOA: @setTitle: ( title -- ret )								\ NSString object
COCOA: @setAlphaValue: ( viewAlpha -- ret )					\ CGFloat is sfloat
COCOA: @setBackgroundColor: ( backgroundColor -- ret )	\ NSColor object
COCOA: @display ( -- ret )
COCOA: @setStyleMask: ( nsuinteger:stylemask -- ret )
COCOA: @setContentSize: ( cgfloat:w cgfloat:h -- ret )
COCOA: @setFrameOrigin: ( cgfloat:x cgfloat:y -- ret )
COCOA: @setFrame:display: ( cgfloat:x cgfloat:y cgfloat:w cgfloat:h flag -- ret )
COCOA-STRET: @frame ( *rect -- ret )    \ SnowLeopard returns *rect Lion returns not!!!

\ --------------------------------------------------------------------
\ NSWindow parameters

COCOACLASS NSColor

COCOA: @colorWithCalibratedRed:green:blue:alpha: ( red green blue alpha -- rgba )  \ NSColor object
COCOA: @redColor ( -- red )				\ NSColor object
COCOA: @whiteColor ( -- white )			\ NSColor object
COCOA: @blackColor ( -- black )			\ NSColor object

0 CONSTANT NSBorderlessWindowMask
1 CONSTANT NSTitledWindowMask
2 CONSTANT NSClosableWindowMask
4 CONSTANT NSMiniaturizableWindowMask
8 CONSTANT NSResizableWindowMask
256 CONSTANT NSTexturedBackgroundWindowMask

NSTitledWindowMask NSClosableWindowMask OR NSMiniaturizableWindowMask OR
NSResizableWindowMask OR CONSTANT ALLWIDGETS

NSTexturedBackgroundWindowMask CONSTANT NOWIDGETS

0 CONSTANT NSBackingStoreRetained
1 CONSTANT NSBackingStoreNonretained
2 CONSTANT NSBackingStoreBuffered

\ --------------------------------------------------------------------
\ Forth NSWindow record and parameters

6 CELLS 9 SFLOATS + CONSTANT /WINDOW.RECORD

: +W.REF ( wptr4 -- 'windowref )  ;

: +W.GPORT ( wptr4 -- 'windowgport )  CELL + ;

: +W.BOUNDS ( wptr4 -- 'windowbounds ) [ 0 +W.GPORT CELL+ ] LITERAL + ;

: +W.BACKING ( wptr4 -- 'windowbacking ) [ 0 +W.BOUNDS 4 SFLOATS + ] LITERAL + ;

: +W.DEFER ( wptr4 -- 'windowbacking ) [ 0 +W.BACKING CELL+ ] LITERAL +  ;

: +W.STYLE ( wptr4 -- 'windowstyle ) [ 0 +W.DEFER CELL+ ] LITERAL + ;

: +W.TITLE ( wptr4 -- 'windowtitle ) [ 0 +W.STYLE CELL+ ] LITERAL + ;

: +W.TRANSPARENCY ( wptr4 -- 'windowtransparency ) [ 0 +W.TITLE CELL+ ] LITERAL + ;

: +W.BACKGROUND ( wptr4 -- 'windowbackground ) [ 0 +W.TRANSPARENCY SFLOAT+ ] LITERAL + ;

\ --------------------------------------------------------------------
\ set/change stuff before window is added with ADD.WINDOW

: W.BOUNDS ( wptr4 -- ) ( F: x y width height -- )   +W.BOUNDS CG4! ;

: W.STYLE ( n wptr4 -- )   +W.STYLE ! ;

: W.TITLE ( a n wptr4 -- )
	-ROT HERE >R STRING, R> SWAP +W.TITLE ! ;

: W.TRANSPARENCY ( wptr4 -- ) ( F: alpha -- )  +W.TRANSPARENCY SF! ;

: W.BACKGROUND ( wptr4 -- ) ( F: r g b alpha -- )  +W.BACKGROUND CG4! ;

\ --------------------------------------------------------------------
\ User interface words, interact with Cocoa

: RESIZE.WINDOW ( wptr4 -- ) ( F: w h -- )
	>R FPUSHS FPUSHS SWAP R> +W.REF @ @setContentSize: DROP ;

: MOVE.WINDOW ( wptr4 -- ) ( F: x y -- )
	>R FPUSHS FPUSHS SWAP R> +w.ref @ @setFrameOrigin: DROP  ;

: FIX.WINDOW	( wptr4 -- ) ( F: x y w h -- )
	>R 4FPUSHS YES R> +W.REF @ @setFrame:display: DROP ;

(*
: SHOW.WINDOW ( wptr4 -- )
	+W.REF @ DUP DUP @orderFront: DROP @display DROP ;
*)
: SHOW.WINDOW ( wptr4 -- )
	+W.REF @ 0 SWAP @orderFront: DROP ;

: HIDE.WINDOW ( wptr4 -- )
	+W.REF @ DUP @orderOut: DROP ;
	
: CLOSE.WINDOW ( wptr4 -- )
	DUP +W.REF @ DUP @close DROP @release DROP OFF ;

: SET.WTITLE ( 0string wptr4 -- )
	SWAP >NSSTRING SWAP +W.REF @  @setTitle: DROP ;

: SET.WTRANSPARENCY ( wptr4 -- ) ( F: alpha -- )
	>R FPUSHS R> +W.REF @ @setAlphaValue: DROP ;

: SET.WBACKGROUND ( wptr4 -- ) ( F: red green blue alpha -- )
	4FPUSHS NSColor @colorWithCalibratedRed:green:blue:alpha:
	SWAP +W.REF @ @setBackgroundColor: DROP ;

\ -- crashes ?!
: SET.WSTYLE ( stylemask wptr4 -- )
	+w.ref @ @setStyleMask: drop ;

: WINDOW.FRAME ( wptr4 -- ) ( F: -- x y w h )
	DUP +W.BOUNDS DUP >R SWAP +W.REF @ @frame DROP R>  CG4@ ;

: SAVE.WINDOW ( wptr4 -- )
	WINDOW.FRAME FDROP FDROP FDROP FDROP ;

\ --------------------------------------------------------------------
\ Window creating words

\ Note: was z" for s" !!
: /WINDOW ( a -- )
	0 						      OVER +W.REF !
	0								OVER +W.GPORT !
	100e0 600e0 340e0 180e0	DUP  W.BOUNDS
	ALLWIDGETS				   OVER W.STYLE
	NSBackingStoreBuffered	OVER +W.BACKING !
	NO						      OVER +W.DEFER !
	DUP S" untitled"			ROT  W.TITLE			\ 'saves' as a counted string!
	1e0						   DUP  W.TRANSPARENCY
	1e0 FDUP F2DUP  		   W.BACKGROUND ;

: (NEW.WINDOW) (  -- addr )   HERE /WINDOW.RECORD ALLOT DUP /WINDOW ;

\ : NEW.WINDOW ( <name > -- )  (NEW.WINDOW) CONSTANT ;

: NEW.WINDOW ( <name > -- )  CREATE (NEW.WINDOW) DROP ;

: WINDOW.ARGS ( wptr4 -- n1 ... n7 )
	>R
	R@ +W.BOUNDS CGRECT@
	R@ +W.STYLE @
	R@ +W.BACKING @
	R> +W.DEFER @
;

: CREATE.WINDOW ( n1 ... n7 -- instance )
	NSWindow @alloc @initWithContentRect:styleMask:backing:defer: ;

: ADD.WINDOW ( wptr4 -- )
	DUP +W.REF @ IF DUP CLOSE.WINDOW THEN
	DUP WINDOW.ARGS CREATE.WINDOW
\ default opaque setting is YES, so need to chage it to change transparency!
	NO OVER @setOpaque: DROP
	OVER +W.REF !
	DUP +W.TITLE @ COUNT DROP OVER SET.WTITLE			\ this is ugly because of counted vs zero string
	DUP +W.TRANSPARENCY SF@ DUP SET.WTRANSPARENCY
	DUP +W.BACKGROUND CG4@ DUP SET.WBACKGROUND
	SHOW.WINDOW ;

\\ ( eof )