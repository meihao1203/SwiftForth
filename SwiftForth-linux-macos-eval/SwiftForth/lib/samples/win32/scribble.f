{ ====================================================================
Scribble demo

Copyright 2001  FORTH, Inc.

Based on the SCRIBBLE.C program in Petzold 2nd Edition.
==================================================================== }

OPTIONAL SCRIBBLE A connect-the-dots demo from Petzold

100 CONSTANT #POINTS

0 VALUE POINT#
0 VALUE SCRIBBLING

CREATE POINTS #POINTS CELLS ALLOT

\ Import Windows library functions

LIBRARY GDI32
FUNCTION: LineTo ( hdc nXEnd nYEnd -- b )
FUNCTION: MoveToEx ( hdc X Y lpPoint -- b )

LIBRARY USER32
FUNCTION: SetWindowPos ( hWnd hWndInsertAfter X Y cx cy uFlags -- b )

\ --- ; process WM_PAINT message

: DOPAINT ( -- res )
   POINT# 1 > IF
      64 R-ALLOC ( a)
      HWND OVER BeginPaint LOCALS| hdc ps |
      POINT# 1- 0 DO
         POINT# 1 DO
            hdc  J CELLS POINTS + @ HILO SWAP 0 MoveToEx DROP
            hdc  I CELLS POINTS + @ HILO SWAP LineTo DROP
         LOOP
      LOOP
      HWND ps EndPaint DROP
   ELSE  HWND MSG WPARAM LPARAM DefWindowProc DROP
   THEN 0 ;

: DOPRESS ( -- res )
   POINT# #POINTS < IF
      LPARAM  POINT# CELLS POINTS + !
      1 +TO POINT#
   THEN 0 ;

: DOREPAINT ( -- res )
   HWND 0 1 InvalidateRect DROP 0 ;

: DEFMSG ( n -- res )
   DROP  HWND MSG WPARAM LPARAM DefWindowProc ;

[SWITCH SCRIBBLE-MESSAGES DEFMSG
   WM_CLOSE       RUN: 0 TO SCRIBBLING  HWND DestroyWindow DROP 0 ;
   WM_PAINT       RUNS DOPAINT
   WM_LBUTTONDOWN RUNS DOPRESS
   WM_LBUTTONUP   RUNS DOREPAINT
   WM_SIZE        RUNS DOREPAINT
SWITCH]

: SCRIBBLE-PROC
   MSG $FFFF AND SCRIBBLE-MESSAGES ;

' SCRIBBLE-PROC 4 CB: SCRIBBLE-WNDPROC

: AppName ( -- zstr )   Z" SCRIBBLE" ;
: AppTitle   ( -- zstr )   Z" SwiftFORTH Scribble Demo" ;

: CREATE-SCRIBBLE-WINDOW  ( -- f )
   0                       \ exended style
   AppName                 \ class name
   AppTitle                \ window title
   WS_OVERLAPPEDWINDOW
   WS_CAPTION OR
   100 100 300 200         \ x y cx cy
   0                       \ parent window
   0                       \ menu
   HINST                   \ instance handle
   0                       \ creation parameters
   CreateWindowEx DUP IF
      DUP
      HWND_NOTOPMOST
      100 100 300 200
      SWP_SHOWWINDOW
      SetWindowPos DROP
   THEN ;

: DEMO  ( -- )
   SCRIBBLING ?EXIT  0 TO POINT#
   AppName SCRIBBLE-WNDPROC DefaultClass DROP
   CREATE-SCRIBBLE-WINDOW DUP TO SCRIBBLING
   DUP 0= ABORT" create window failed"
   DUP SW_SHOWNORMAL ShowWindow DROP
       UpdateWindow DROP ;

CR CR .( Type DEMO to start, then click mouse in Scribble window.) CR
