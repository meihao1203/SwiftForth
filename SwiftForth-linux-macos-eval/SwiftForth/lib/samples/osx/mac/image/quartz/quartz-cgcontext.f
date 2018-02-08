{ ====================================================================
CoreGraphicsContext

Copyright (c) 2006-2017 Roelf Tooxpeus

SwiftForth version.
Core Graphics basic setup for displaying images and pictures.
Last: 17 October 2017 at 21:24:07 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Using Quartz in NSWindow's needs CGContexts. Here many CGContext related
functions are defined.
See the Quartz 2D Programming Guide at:
https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Introduction/Introduction.html#//apple_ref/doc/uid/TP30001066

quartz.framework -- the Quartz 2D libraries.

CGContextFlush -- will execute only at the advised framerate of 60Hz.
This will speed up drawing considerable. 
Trying to flush faster than the framerate will slow down the drawing!
Note: uses some finetuning.

FLUSHED -- returnes last time _CGContextFlush got executed. Updated
by CGContextFlush.
 
CGCONTEXT -- will return the CoreGraphicContextRef, if any, for the given window.
It's also known as the graphics port. It uses the NSGraphicsContext instance
method CGContext (or @CGContext as it is declared here).

/GWINDOW -- will fetch the CGContext from the OS for the given window
and store it in its window record.
The CGContext is per thread! If /GWINDOW is executed during an include
from the LOAD-FILE menu, make sure you execute it again from IMPOSTOR
before you run anything which makes use of CGContext.
For now I don't know why other threads don't complain when they use the
the CGContext asked for by IMPOSTOR. Because they're IMPOSTOR children?
Best thing is to initialize on thread which will run the graphic stuff.

GPORT -- return the grahics port or CGContextRef from given window's
window record. It's assumed to be set by /GWINDOW

CGCOLOR and CGRECT are color and rect pads for temporary usage.

Might add the following to simulate MacForth:
\ --- window for Core Graphics output
#USER CELL +USER TASKWINDOW
	  CELL +USER TASKCGCONTEXT
TO #USER

\ set output window for graphics
: WINDOW ( wptr4 -- )
  TASKCGCONTEXT @ ?DUP IF CGContextRelease DROP THEN
  DUP @CGCONTEXT TASKCGCONTEXT ! TASKWINDOW ! ;

\ get current output window for graphics
: GET.WINDOW ( -- wptr4 )   TASKWINDOW @ ;
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FRAMEWORK quartz.framework

quartz.framework

FUNCTION: CGContextSaveGState ( cgcontext -- ret )
FUNCTION: CGContextRestoreGState ( cgcontext -- ret )

FUNCTION: CGContextRetain ( cgcontext -- cgcontext ) 
FUNCTION: CGContextRelease ( cgcontext -- ret )

FUNCTION: CGContextBeginPath ( cgcontext -- ret )		\ hardly used?
FUNCTION: CGContextClosePath ( cgcontext -- ret )

AS _CGContextFlush FUNCTION: CGContextFlush ( cgcontext -- ret )			\ Note: use for drawing
FUNCTION: CGContextSynchronize	( cgcontext -- ret )    \       use for images

COCOACLASS NSGraphicsContext

COCOA: @graphicsContextWithWindow: ( nswindow -- NSGraphicsContextRef ) \ NSGraphicsContextRef
COCOA: @graphicsContext ( -- NSGraphicsContextRef )	\ NSWindow
COCOA: @CGContext ( -- CGContextRef )	\ NSGraphicsContext
COCOA: @graphicsPort ( -- CGContextRef )  \ NSGraphicsContext Deprecated

\ --------------------------------------------------------------------

VARIABLE FLUSHED

: CGContextFlush ( cgcontext -- ret )
	COUNTER FLUSHED  2DUP @ - 33 U> IF ! _CGContextFlush  ELSE 2DROP DROP 0 THEN ;

(*
\ Snow Leopard
: CGCONTEXT ( wptr4 -- CGContextRef )
	+W.REF @ NSGraphicsContext @graphicsContextWithWindow: @graphicsPort ;

\ Yosemite and up
: CGCONTEXT ( wptr4 -- CGContextRef )
	+W.REF @ NSGraphicsContext @graphicsContextWithWindow: @CGContext ;
*)

\ Snow Leopard
\ : CGCONTEXT ( wptr4 -- CGContextRef ) +W.REF @ @graphicsContext @graphicsPort ;

\ Yosemite and up
: CGCONTEXT ( wptr4 -- CGContextRef )   +W.REF @ @graphicsContext @CGContext ;

: /GWINDOW ( wptr4 -- )   DUP CGCONTEXT SWAP +W.GPORT ! ;

: GPORT ( wptr4 -- CGContextRef )   +W.GPORT @ ;

0E0 FDUP FDUP FDUP CG4: CGCOLOR
0E0 FDUP FDUP FDUP CG4: CGRECT

cr .( CGContext loaded )

\\ ( eof )
