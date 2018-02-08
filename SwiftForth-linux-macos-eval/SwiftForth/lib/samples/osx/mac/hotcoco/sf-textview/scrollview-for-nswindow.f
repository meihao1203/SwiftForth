{ ====================================================================
text window

Copyright (c) 2007-2017 Roelf Toxopeus

SwiftForth version
Implements a text scrollview in a window
Last: 28 October 2015 at 17:12:27 GMT+1   -rt
==================================================================== }

{ --------------------------------------------------------------------
Two necessary classes and their relevant methods are defined:
NSScrollView and NSTextView.
You can have several scroll- and text-views in a window, so save the
current views in 'scrollview and 'textview if you plan to add others.
A textview is connected to a scrollview which becomes a window's
contentview. It's all about views.

SCROLLVIEW -- create and initialise a scrollview instance. Use some
default attributes, default scrolls only verticaly. Main thread required,
use PASS.

TEXTVIEW -- create and initialise a textview instance. Use some
default attributes. Main thread required, use PASS.

SCROLLS.HORIZONTAL -- set scrollview from given textview to allow
horizontal scrolling.

WINDOWFORTEXT -- initialise given window for text I/O. Return an instance
from the textview. This is executed on the main thread, because all
the messages are required to run on the main thread.

FONT -- return NSFont instance from given font name and size.

VIEWFONT -- set font for given textview instance, using fontname and size.

demo usage:

new.window mytvwin
s" A Text View" mytvwin w.title

variable mytextview
: /mywindow
mytvwin add.window
10 ms ( el capitan quirk)
mytvwin windowfortext
dup mytextview !
dup scrolls.horizontal
0" Monaco" 15 rot viewfont ;
-------------------------------------------------------------------- }


/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ the scrollview

COCOACLASS NSScrollView

COCOA: @setBorderType: ( NSBorderType:atype -- ret )      \ NSScrollView          
COCOA: @setHasVerticalScroller: ( BOOL:flag -- ret )      \ NSScrollView 
COCOA: @setHasHorizontalScroller: ( BOOL:flag -- ret )    \ NSScrollView 
COCOA: @setAutoresizingMask: ( NSUInteger:mask -- ret )   \ NSScrollView 

 0 CONSTANT NSNoBorder
 2 CONSTANT NSViewWidthSizable
16 CONSTANT NSViewHeightSizable

: SCROLLVIEW ( -- NSScrollView:ref )
	NSScrollView @alloc @init DUP >R
	NSNoBorder R@ @setBorderType: DROP
	YES        R@ @setHasVerticalScroller: DROP
	NO         R@ @setHasHorizontalScroller: DROP
	NSViewWidthSizable NSViewHeightSizable OR R> @setAutoresizingMask: DROP
;

\ --------------------------------------------------------------------
\ the textview

COCOACLASS NSTextView

COCOA: @setVerticallyResizable: ( BOOL:flag -- ret )								\ NSTextView
COCOA: @setHorizontallyResizable: ( BOOL:flag -- ret )  							\ NSTextView
COCOA: @textContainer ( -- NSTextContainer:ref )  									\ NSTextView
COCOA: @setWidthTracksTextView: ( BOOL:flag -- ret )								\ NSTextContainer

: TEXTVIEW ( -- NSTextView:ref )
	NSTextView @alloc @init DUP >R
	YES R@ @setVerticallyResizable: DROP
	NO  R@ @setHorizontallyResizable: DROP
	NSViewWidthSizable R@ @setAutoresizingMask: DROP
	YES R> @textContainer @setWidthTracksTextView: DROP
;

\ --------------------------------------------------------------------
\ horizontal scroller change

COCOA: @enclosingScrollView ( -- NSScrollView:ref )  								\ NSTextView
COCOA: @setContainerSize: ( NSSize:widthfloat NSSize:heightfloat -- ret )	\ NSTextContainer

3.40282347e+38 FCONSTANT FLT_MAX	\ see: /usr/include/float.h

: SCROLLS.HORIZONTAL ( textview -- )
	>R
	YES R@ @enclosingScrollView @setHasHorizontalScroller: DROP
	YES R@ @setHorizontallyResizable: DROP
	NSViewWidthSizable NSViewHeightSizable OR R@ @setAutoresizingMask: DROP
	FLT_MAX FDUP FPUSHS FPUSHS R@ @textContainer @setContainerSize: DROP
	NO R> @textContainer @setWidthTracksTextView: DROP
;
	
\ --------------------------------------------------------------------
\ put the lot together:
\ all of these want the main thread!

COCOA: @setDocumentView: ( NSView:aView -- ret )					\ NSScrollView
COCOA: @makeKeyAndOrderFront: ( id:sender -- ret )					\ NSWindow
COCOA: @makeFirstResponder: ( NSResponder:responder -- BOOL )	\ NSWindow

: (WINDOWFORTEXT) ( wptr4 -- )
	+W.REF @ >R
	TEXTVIEW SCROLLVIEW 2DUP						\ new text- and scrollview
	@setDocumentView: DROP							\ connect textview to scrollview
	R@ @setContentView: DROP						\ set scrollview to window's contentview
	0 R@ @makeKeyAndOrderFront: DROP				\ make window the event receiver
	DUP R> @makeFirstResponder: DROP				\ make textview the text receiver
	POCKET !
;

: WINDOWFORTEXT ( wptr4 -- textview )   1 0 ['] (WINDOWFORTEXT) PASS POCKET @ ;

\ --------------------------------------------------------------------
\ last set font:

COCOACLASS NSFont

COCOA: @fontWithName:size: ( NSString:fontName CGFloat:fontSize -- NSFont:ref )  \ NSFont
COCOA: @setFont: ( NSFont:ref -- ret )   														\ NSTextStorage/NSTextView

: FONT ( 0string:fontname fontsize -- nsfont:ref )
	SWAP >NSSTRING SWAP S>SF NSFont @fontWithName:size: ;

: VIEWFONT ( 0string:fontname fontsize textview -- )
	>R FONT ?DUP
			IF R> @setFont: DROP
		ELSE R> DROP
	THEN ;

cr .( TextView for Cocoa window loaded)

\\ ( oef )
