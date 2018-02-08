{ ============================================================================
Simply Drawing Example

Created 06/06/2007 by Mike Ghan

=========================================================================== }

FUNCTION: CreatePen ( style width|0 rgbColor -- hPen )
FUNCTION: MoveToEx   ( hDC X Y point -- res )
FUNCTION: LineTo     ( hDC X Y  -- res )
FUNCTION: SetROP2    ( hDC ROP2 -- res )
FUNCTION: Rectangle  ( hdc nLeftRect nTopRect nRightRect nBottomRect -- res )


\ ********************************************************************
\  Colors
\ ********************************************************************

: >RGB  ( red green blue --- rgb )   \  rgb = 00bbggrr
   16 LSHIFT  SWAP 8 LSHIFT OR  OR ;

: RGB-COLOR  ( red green blue -- )
   >RGB ( ColorRGB ) CONSTANT ;

\ Some Common Colors
\ Red Grn Blu RGB-COLOR name
  255   0   0 RGB-COLOR RED-COLOR
    0 255   0 RGB-COLOR GREEN-COLOR
    0   0 255 RGB-COLOR BLUE-COLOR
  255 128   0 RGB-COLOR ORANGE-COLOR
  255 255   0 RGB-COLOR YELLOW-COLOR
  255   0 255 RGB-COLOR MAGENTA-COLOR
    0   0   0 RGB-COLOR BLACK-COLOR
  128 128 128 RGB-COLOR GRAY-COLOR


\ ********************************************************************
\  DC Tools
\ ********************************************************************

[UNDEFINED] CURRENT-DC [IF]
\ User Vars
 #USER
   CELL +USER CURRENT-DC  \ Device Context
 TO #USER

: MY-DC  ( -- hDC )     CURRENT-DC @ ;
: IS-MY-DC  ( hDC -- )  CURRENT-DC ! ;  \ Set at BeginPaint etc
: GET-MY-DC  ( -- )     HWND GetDC IS-MY-DC ;
: RELEASE-MY-DC ( -- )  HWND MY-DC ReleaseDC DROP ;
[THEN]


\ ********************************************************************
\  Draw Lines
\ ********************************************************************

: DRAW-LINE  ( x1 y1 x2 y2 -- )
   2>R MY-DC -ROT 0 MoveToEx DROP  MY-DC 2R> LineTo DROP ;

: MOVE-TO  ( x y -- )
   MY-DC -ROT NULL MoveToEx DROP ;

: +LINE  ( x y -- )  \ Append to Previous
   MY-DC -ROT LineTo DROP ;


\ ********************************************************************
\  Testbed
\ ********************************************************************

: DRAW-TEST  ( -- )  \ Draw lines on Current DC
   PS_SOLID 5 ( width ) RED-COLOR CreatePen ( hPen )
   MY-DC SWAP ( hPen ) SelectObject ( hPrevPen ) >R ( Stash )
   25 100 ( x1y1 )  125 200 ( x2y2 ) DRAW-LINE
   225 200 +LINE   25 100 +LINE
   \ Next we'll restore the previous pen and delete the pen we created.
   MY-DC R> ( hPrevPen ) SelectObject ( hPen ) DeleteObject DROP ;

: DRAW-WINDOW  ( -- )  \ Draw lines on SF Console
   GET-MY-DC ( get DC of our window )
   DRAW-TEST  RELEASE-MY-DC ;
