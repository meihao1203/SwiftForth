{ ====================================================================
Bitmap image display

Copyright (C) 2001 FORTH, Inc.  All rights reserved.

Simple bitmap image display.
==================================================================== }

{ --------------------------------------------------------------------
A primitive bitmap display class

The API for using bitmaps is:

: READ-BMPFILE ( addr n -- bitmap-addr )

Load the bitmap file specified by the (addr1 n) string into memory.
Bitmap-addr is the address of memory allocated for the bitmap data; it must
be freed by the user when the data is no longer needed.

BMP ( addr n -- )  \ Use: S" FILENAME.BMP" BMP ANYNAME

Load the bitmap file specified by the (addr1 n) string into the
Forth dictionary; it is referencable by the specified name.

BITMAP defines a class to operate on bitmaps. It exports the following
functions:

DRAW ( bitmap-addr dc x y -- )
CENTERED ( bitmap-addr hwnd -- )
GET-HANDLE ( dc bitmap-addr -- hbitmap )

The following simple example displays a bitmap centered in the console
window, then displays it at the top left corner of the window.

S" \SWIFTFORTH\BIN\SWIFT.BMP" BMP TESTING

: TEST ( -- )
   [OBJECTS BITMAP MAKES BM OBJECTS]
   TESTING HWND BM CENTERED  KEY DROP
   TESTING HWND GetDC 0 0 BM DRAW  KEY DROP ;
-------------------------------------------------------------------- }

\ this class combines the windows data structures
\ BITMAPFILEHEADER and BITMAPINFOHEADER

CLASS BITMAPHEADER
   HVARIABLE Type       \ specifies file type, must be "BM"
   VARIABLE  Size       \ size in bytes of the file
   HVARIABLE Res1       \ reserved
   HVARIABLE Res2       \
   VARIABLE  OffBits    \ offset from the BITMAPFILEHEADER structure to the bitmap bits
   0 BUFFER: Info
   VARIABLE  Size
   VARIABLE  Width
   VARIABLE  Height
   HVARIABLE Planes
   HVARIABLE BitCount
   VARIABLE  Compression
   VARIABLE  SizeImage
   VARIABLE  XPelsPerMeter
   VARIABLE  YPelsPerMeter
   VARIABLE  ClrUsed
   VARIABLE  ClrImportant
END-CLASS

CLASS RGBQUAD
   CVARIABLE red
   CVARIABLE green
   CVARIABLE blue
   CVARIABLE reserved
END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

\ This is a class for displaying bitmaps

BITMAPHEADER SUBCLASS BITMAP

   VARIABLE hOldBitmap
   VARIABLE hMemDC
   VARIABLE hBitmap
   VARIABLE hPalette
   VARIABLE hOldPalette
   VARIABLE X
   VARIABLE Y
   VARIABLE hDC
   VARIABLE BMP
   VARIABLE W

   : Palette ( -- addr )   BMP @ BITMAPHEADER SIZEOF + ;
   : InfoHeader ( -- addr )   BMP @ Info Type - + ;

   : numEntries ( -- n )
      ClrUsed @ ?DUP ?EXIT  1 BitCount U@ LSHIFT ;

   : Data ( -- addr )
      BMP @ OffBits @ + ;

   \ From: "Bret Latshaw" <bret@bedford.net>
   \ Convert a cell representing an RGBQUAD to a PALETTEENTRY,
   \ by swapping the 1st and 3rd bytes ( blue and red ), and
   \ also setting peFLAGS ( 4th byte ) to 0 (it should be 0
   \ already, but it doesn't cost us anything to make sure.)
   : rgbSwap ( n1 -- n2 )
      DUP $ff00ff AND >H< SWAP $ff00 AND OR ;

   : CreateDIBPalette ( -- hpal )
      numEntries CELLS 4 + R-ALLOC >R
      $300 R@ H!  numEntries R@ 2+ H!
      R@ 4 +
      numEntries 0 ?DO
         Palette i CELLS + @ rgbSwap !+
      LOOP DROP
      R> CreatePalette ;

   : BMP! ( bmp -- )
      DUP BMP !  Type BITMAPHEADER SIZEOF CMOVE ;       \ copy header to local data

   PROTECTED

   \ Extended to account for presence or absence of palette
   \ from comments and code submitted by Mike Ghan.

   : Palette? ( -- flag )   BitCount U@ 9 < ;

   : (BMPHANDLE) ( -- )
      hDC @ CreateCompatibleDC hMemDC !
      Palette? IF  CreateDIBPalette hPalette !
         hMemDC @ hPalette @ 0 SelectPalette
         hOldPalette !
         hMemDC @ RealizePalette DROP
      THEN
      hDC @ Width @ Height @
         CreateCompatibleBitmap hBitmap !
      hMemDC @ hBitmap @ SelectObject hOldBitmap !
      hMemDC @ hBitmap @ 0 Height @ Data InfoHeader
         DIB_RGB_COLORS SetDIBits DROP
      hMemDC @ hOldBitmap @ SelectObject DROP
      Palette? IF
         hMemDC @ hOldPalette @ 0 SelectPalette DROP
      THEN
      hMemDC @ DeleteDC DROP ;

   PUBLIC

   : RENDER ( bitmap-addr -- ) BMP!
      (BMPHANDLE)
      Palette? IF
         hDC @ hPalette @ 0 SelectPalette
         hOldPalette !
         hDC @ RealizePalette DROP
      THEN
      hDC @ CreateCompatibleDC hMemDC !
      hMemDC @ hBitmap @ SelectObject hOldBitmap !
      hDC @ X @ Y @ Width @ Height @ hMemDC @
         0 0 SRCCOPY BitBlt DROP
      hMemDC @ hOldBitmap @ SelectObject DROP
      Palette? IF
         hDC @ hOldPalette @ 0 SelectPalette DROP
      THEN
      hMemDC @ DeleteDC DROP
      Palette? IF  hPalette @ DeleteObject DROP  THEN
      hBitmap @ DeleteObject DROP ;

   : DRAW ( bitmap-addr dc x y -- )
      Y ! X ! hDC ! RENDER ;

   : CENTERED ( bitmap-addr hwnd -- )
      W ! BMP!
      16 R-ALLOC >R W @ R@ GetClientRect DROP
      R> CELL+ CELL+ 2@ ( y x)
      2/ Width @ 2/ - 0 MAX X !
      2/ Height @ 2/ - 0 MAX Y !
      W @ GetDC hDC ! BMP @ RENDER
      W @ hDC @ ReleaseDC DROP ;

   : GET-HANDLE ( dc bitmap-addr -- hbitmap ) BMP! hDC !
      (BMPHANDLE) hBitmap @ ;

END-CLASS

{ ------------------------------------------------------------------------
If READ-BMPFILE is used, the memory returned must be _FREE -ed when done
------------------------------------------------------------------------ }

: BMP  ( addr n -- )
   R/O OPEN-FILE THROW ( fileid) >R
   CREATE ( "name")
      R@ FILE-SIZE THROW DROP
      HERE  OVER ALLOT
      SWAP R@ READ-FILE THROW DROP
      R> CLOSE-FILE THROW ;

: READ-BMPFILE ( addr n -- bitmap-addr )
   R/O OPEN-FILE IF ( no file) DROP 0 EXIT THEN >R
   R@ FILE-SIZE 2DROP           \ n
   DUP ALLOCATE DROP            \ n addr
   DUP ROT                      \ addr addr n
   R@ READ-FILE 2DROP           \ addr
   R> CLOSE-FILE DROP ;


