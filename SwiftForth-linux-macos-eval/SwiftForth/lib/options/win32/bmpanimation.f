{ ====================================================================
Animation via a BMP fiche as a strip of images

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL BMPANIMATION

REQUIRES BMPFICHE

BMPFICHE SUBCLASS BMPANIMATION

   RECT BUILDS R

   MAX_PATH BUFFER: FILENAME

   : BMPFILE ( -- z )   FILENAME ;

   : ROWS ( -- n )   1 ;
   : COLS ( -- n )   FICHE GETSIZE ( x y) ROWS / / ;

   : DRAW ( canvas x y index -- )   0 SWAP POSITION
      HEIGHT * SWAP WIDTH * SWAP PROJECT ;

   : FEATURES ( addr len -- )   FILENAME ZPLACE  OPEN DROP ;

   SINGLE INDX

   : ADVANCE ( canvas -- )
      0 INDX POSITION  0 0 TARGET  PAINT   1 +TO INDX ;

END-CLASS
