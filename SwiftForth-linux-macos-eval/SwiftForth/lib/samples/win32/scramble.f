{ ====================================================================
Scramble desktop demo

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL SCRAMBLE A graphics demo that scrambles the desktop

{ --------------------------------------------------------------------
Adapted from Petzold
-------------------------------------------------------------------- }

LIBRARY USER32
FUNCTION: LockWindowUpdate ( hWndLock -- b )

LIBRARY GDI32
FUNCTION: CreateDC ( lpszDriver lpszDevice lpszOutput *lpInitData -- h )

LIBRARY KERNEL32
FUNCTION: GetVersion ( -- addr )

REQUIRES RND

200 CONSTANT NUM

0 VALUE cx
0 VALUE cy
0 VALUE hBitmap
0 VALUE hdcMem

-? 0 VALUE hdc

0 VALUE X1
0 VALUE Y1
0 VALUE X2
0 VALUE Y2

CREATE IKEEP   NUM 4 * CELLS ALLOT

: 'IKEEP ( x y -- a )   SWAP 4 * + CELLS  IKEEP + ;

: DCSWAP
   hdcMem  0  0  cx  cy  hdc   x1  y1  SRCCOPY  BitBlt DROP
   hdc   x1  y1  cx  cy  hdc   x2  y2  SRCCOPY  BitBlt DROP
   hdc   x2  y2  cx  cy  hdcMem  0  0  SRCCOPY  BitBlt DROP ;

: TWIST
   NUM 0 DO
      10 RND cx *  DUP TO x1  I 0 'IKEEP !
      10 RND cy *  DUP TO y1  I 1 'IKEEP !
      10 RND cx *  DUP TO x2  I 2 'IKEEP !
      10 RND cy *  DUP TO y2  I 3 'IKEEP !
      DCSWAP
   LOOP ;

: UNTWIST
   NUM 0 DO
      NUM 1- I - 0 'IKEEP @ TO x1
      NUM 1- I - 1 'IKEEP @ TO y1
      NUM 1- I - 2 'IKEEP @ TO x2
      NUM 1- I - 3 'IKEEP @ TO y2
      DCSWAP
   LOOP ;

: GOING
   Z" DISPLAY" 0 0 0 CreateDC to hdc
   hdc CreateCompatibleDC to hdcMem
   SM_CXSCREEN GetSystemMetrics 10 / to cx
   SM_CYSCREEN GetSystemMetrics 10 / to cy
   hdc cx cy CreateCompatibleBitmap to hBitmap
   hdcMem hBitmap SelectObject Drop
   GetTickCount BUD !
   BEGIN
      TWIST
      1000 MS
      UNTWIST
      1000 MS
      KEY?
   UNTIL
   hdcMem DeleteDC DROP
   hdc DeleteDC DROP
   hBitmap DeleteObject DROP ;

: GO ( -- )
   GetVersion 0< IF
      GetDesktopWindow LockWindowUpdate -EXIT
   THEN
   GOING
   GetVersion 0< IF
      0 LockWindowUpdate DROP
   THEN ;

CR
CR .( Type GO to start demo. Press any key to stop.)
CR
