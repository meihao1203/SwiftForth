{ ====================================================================
A bmp file regarded as a 2-dimensional fiche of images

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL BMPFICHE

REQUIRES XBITMAP

CLASS BMPFICHE

   XBITMAP BUILDS FICHE

   SINGLE HEIGHT        \ width and height of one frame
   SINGLE WIDTH

   BLITTER BUILDS BLT

   \ a fiche is divided into rows and columns

   DEFER: ROWS ( -- n )   1 ;
   DEFER: COLS ( -- n )   1 ;

   SINGLE _ROWS       \ after open, these are valid
   SINGLE _COLS

   : ROW-POS ( n -- n )   ABS _ROWS MOD  HEIGHT * ;
   : COL-POS ( n -- n )   ABS _COLS MOD  WIDTH *  ;

   : POSITION ( row col -- )
      COL-POS SWAP ROW-POS BLT SetSrc ;

   MAX_PATH BUFFER: FILENAME

   DEFER: BMPFILE ( -- z )   FILENAME ;

   : OPEN ( -- ior )
      BMPFILE FICHE ATTACH DUP ?EXIT DROP
      ROWS TO _ROWS  COLS TO _COLS
      FICHE GETSIZE ( x y)  _ROWS / TO HEIGHT  _COLS / TO WIDTH
      FICHE ADDR BLT ATTACH  WIDTH HEIGHT BLT SetArea  0 ;

   : CLOSE ( -- )   FICHE DETACH ;

   : PAINT ( canvas -- )   BLT BLITTO ;

   : TARGET ( x y -- )   BLT SetDest ;

   : PROJECT ( canvas x y -- )   TARGET PAINT ;

END-CLASS
