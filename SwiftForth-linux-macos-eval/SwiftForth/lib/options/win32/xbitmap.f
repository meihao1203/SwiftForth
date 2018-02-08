{ ====================================================================
Bitmap management

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL XBITMAP A bitmap class.

LIBRARY USER32

FUNCTION: LoadImage ( hinst zname type xdesired ydesired flags -- bool )
FUNCTION: StretchBlt ( ddc dx dy dw dh sdc sx sy sw sh rop -- bool )

CLASS BITMAPOBJ
   VARIABLE  Type
   VARIABLE  Width
   VARIABLE  Height
   VARIABLE  WidthBytes
   HVARIABLE Planes
   HVARIABLE BitPixel
   VARIABLE  BITS
END-CLASS

CLASS XBITMAP

   SINGLE HANDLE

   : DETACH ( -- )   HANDLE IF
      HANDLE DeleteObject DROP  0 TO HANDLE  THEN ;

   : ATTACH ( zpath -- ior )
      DETACH 0 SWAP IMAGE_BITMAP 0 0 LR_LOADFROMFILE LoadImage
      DUP TO HANDLE 0= ;

   : GETSIZE ( -- width height )
      [OBJECTS BITMAPOBJ MAKES BM OBJECTS]
      HANDLE BITMAPOBJ SIZEOF BM ADDR GetObject DROP
      BM Width @ BM Height @ ;

   : CREATE-COMPATIBLE ( dc x y -- )
      DETACH CreateCompatibleBitmap TO HANDLE ;

   : DESTRUCT ( -- )   DETACH ;
   : CONSTRUCT ( -- )   0 TO HANDLE ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS BLITTER

   SINGLE XSRC  SINGLE YSRC             \ source coordinate
   SINGLE WIDTH SINGLE HEIGHT           \ and size
   SINGLE MODE  SINGLE BMP              \ rop and image handle
   SINGLE XDST  SINGLE YDST             \ destination coordinate
   SINGLE WIDE  SINGLE HIGH             \ and size (for stretch)

   : SetMode ( mode -- )   TO MODE ;
   : SetDest ( x y -- )   TO YDST  TO XDST ;
   : SetSrc ( x y -- )   TO YSRC  TO XSRC ;
   : SetArea ( w h -- )   TO HEIGHT  TO WIDTH ;
   : SetDstArea ( w h -- )   TO HIGH  TO WIDE ;

   : ATTACH ( bitmap -- )   TO BMP
      SRCCOPY SetMode  0 0 SetDest  0 0 SetSrc
      BMP USING XBITMAP GETSIZE TO HEIGHT TO WIDTH ;

   : BlitTo ( canvas -- )
      [OBJECTS
         CANVAS NAMES REAL
         MEMCANVAS MAKES VIRTUAL
      OBJECTS]
      REAL HDC  VIRTUAL ATTACH
      BMP USING XBITMAP HANDLE VIRTUAL SelectObject
      REAL HDC XDST YDST WIDTH HEIGHT VIRTUAL HDC XSRC YSRC MODE
      BitBlt DROP ;

   : StretchTo ( canvas -- )
      [OBJECTS
         CANVAS NAMES REAL
         MEMCANVAS MAKES VIRTUAL
      OBJECTS]
      REAL HDC  VIRTUAL ATTACH
      BMP USING XBITMAP HANDLE VIRTUAL SelectObject
      REAL HDC XDST YDST WIDE HIGH VIRTUAL HDC XSRC YSRC WIDTH HEIGHT MODE
      StretchBlt DROP ;

END-CLASS
