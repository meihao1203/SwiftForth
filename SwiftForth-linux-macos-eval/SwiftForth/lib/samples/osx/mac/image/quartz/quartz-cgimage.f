{ ====================================================================
CoreGraphic Image display

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
Drawing pictures in a Core Graphic Context from a file or memory.
Last: 9 April 2014 12:45:19 CEST     -rt
==================================================================== }

{ --------------------------------------------------------------------
CGImage -- a pad for a CGImage.
>CGIMAGE -- return a CGImage created from an url.
DRAW.CGIMAGE -- draw a CGImage in the context from a given window.
Note: the rectangle size is the display size in the window to which
the picture is scaled.
DRAWPIC -- draw picture at url in window.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

quartz.framework

FUNCTION: CGImageSourceCreateWithURL ( CFURLRef NULL -- CGImageSourceRef )
FUNCTION: CGImageSourceCreateImageAtIndex ( CGImageSourceRef index NULL -- CGIOmageRef )
FUNCTION: CGContextDrawImage ( CGContext sf:x sf:y sf:w sf:h CGImage -- ret )
FUNCTION: CGImageGetWidth ( CGImage -- size:pixels )
FUNCTION: CGImageGetHeight ( CGImage -- size:pixels )

VARIABLE CGImage

: >CGIMAGE ( zstringurl -- cgimage )
	>CFURL
	0 CGImageSourceCreateWithURL DUP 0= ABORT" Can't create image form URL"
	DUP 0 0 CGImageSourceCreateImageAtIndex
	SWAP CFRelease DROP ;

: DRAW.CGIMAGE ( cgimage wptr4 -- )
	SWAP >R
	DUP CGContext TUCK
	BLENDMODE @ OVER SET.BLENDMODE
	SWAP CONTENT.FRAME 4FPUSHS R@ CGContextDrawImage DROP
	CGContextFlush DROP
	R> CFRelease DROP ;

: DRAWPIC ( zstringurl wptr4 -- )   >R >CGIMAGE R> DRAW.CGIMAGE ;

cr .( CoreGraphics picture loader and drawing loaded )

\\ ( eof )