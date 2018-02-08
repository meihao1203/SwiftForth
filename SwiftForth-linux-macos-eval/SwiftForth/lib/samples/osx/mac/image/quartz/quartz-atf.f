{ ====================================================================
CoreGraphics Affine Transform Matrices

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Current transformation matrix
Use together with CGContextSaveGState and CGContextRestoreGState
Most of these transform the space, not the points!!!
Last: 27 January 2011 19:34:04 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
Affine Transform Matrices to transform the CGContexts

CGatf -- a pad for temporary storage of a ATM
CGATF@ -- passing the AffineTransformstructure contents for calls.
Similar to CGRECT@ etc.

For transforming the context space there is: CGTRANSLATE CGSCALE and
CGROTATE, which do what their name suggest.
-------------------------------------------------------------------- }

\ --------------------------------------------------------------------

/FORTH
DECIMAL

FUNCTION: CGContextGetCTM ( *cgatf cgcontext -- ret )
FUNCTION: CGContextGetUserSpaceToDeviceSpaceTransform ( *cgatf cgcontext -- ret )
\ cgatf is a structure with 6 sfloat/cell memebers to big to pass by value, a reference?
FUNCTION: CGContextConcatCTM ( cgcontext *cgatf -- ret )
FUNCTION: CGContextTranslateCTM ( cgcontext sf sf -- ret )
FUNCTION: CGContextScaleCTM ( cgcontext sf sf -- ret )
FUNCTION: CGContextRotateCTM ( cgcontext sf:radians -- ret ) \ use D>R !!

6 SFLOATS BUFFER: CGatf

\ Passing the AffineTransformstructure:
: CGATF@ ( addr -- a b c d tx ty )
	DUP >R CG2@ 2FPUSHS R> [ 2 SFLOATS ] LITERAL + CG4@ 4FPUSHS ;

\ Transform the context space:	
: CGTRANSLATE ( cgcontext -- ) ( F: x y -- )  2FPUSHS CGContextTranslateCTM DROP ;

: CGSCALE ( cgcontext -- )  ( F: x y -- )  2FPUSHS CGContextScaleCTM DROP ;

: CGROTATE ( cgcontext -- )  ( F: degrees -- )  D>R FPUSHS CGContextRotateCTM DROP ;

cr .( Transform matrices loaded )

\\ ( eof )