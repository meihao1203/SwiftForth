{ ====================================================================
Using the windows GDI

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL RECTANGLES An application that draws random rectangles in a window using the WINAPP template

REQUIRES RND
REQUIRES WINAPP

LIBRARY GDI32
FUNCTION: Rectangle ( hdc nLeftRect nTopRect nRightRect nBottomRect -- b )

: RND-BRUSH ( -- hbrush )
   256 RND 16 LSHIFT
   256 RND  8 LSHIFT OR
   256 RND           OR CreateSolidBrush ;

: RND-RECTANGLE ( x y -- x y x y )
   >R DUP RND SWAP RND  R@ RND SWAP  R> RND ;

: RND-RECT ( hwnd -- )
   DUP GetDC 2>R
   RND-BRUSH R@ OVER ( *) SelectObject DROP
   2R@ DROP PAD GetClientRect DROP
   R@ PAD CELL+ CELL+ 2@ SWAP RND-RECTANGLE Rectangle DROP
   ( *) DeleteObject DROP
   2R> ReleaseDC DROP ;

\ : TEST BEGIN 100 MS HWND RND-RECT KEY? UNTIL ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: RECT-CREATE ( -- res )
   HWND 1 250 0 SetTimer DROP  0 ;

: RECT-TIMER ( -- res )
   HWND RND-RECT  0 ;

: RECT-PAINT ( -- res )
   HWND 0 1 InvalidateRect DROP
   HWND PAD 2DUP  BeginPaint DROP  EndPaint DROP  0 ;

: RECT-DESTROY ( -- res )
   HWND 1 KillTimer DROP  0 ;

[+SWITCH AppMessages
   WM_CREATE  RUNS RECT-CREATE
   WM_TIMER   RUNS RECT-TIMER
   WM_PAINT   RUNS RECT-PAINT
   WM_DESTROY RUNS RECT-DESTROY
SWITCH]

: GO   AppStart DROP ;

CR
CR .( Type GO to run the rectangles demo.)
CR
