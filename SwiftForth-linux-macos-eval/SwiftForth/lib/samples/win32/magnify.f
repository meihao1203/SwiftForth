{ ====================================================================
A mouse position magnifying glass for Windows

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL MAGNIFY A mouse position magnifying glass for Windows.

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

ONLY FORTH  ALSO DEFINITIONS  DECIMAL

{ --------------------------------------------------------------------
Window creation and message dispatcher.
-------------------------------------------------------------------- }

CREATE MAG-CLASS   ,Z" Magnify"
CREATE MAG-TITLE   ,Z" Magnifying glass"

0 VALUE hMAG

: MAG-DESTROY ( -- res )   0 TO hMAG
   0 'MAIN @ ?EXIT PostQuitMessage ;

[SWITCH MAG-MESSAGES DEFWINPROC ( msg -- res )
   WM_DESTROY RUNS MAG-DESTROY
SWITCH]

:NONAME ( -- res )
   MSG LOWORD MAG-MESSAGES ; 4 CB: MAG-WNDPROC

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: /MAG-WINDOW ( cmdshow -- hwnd )   >R
      0                                 \ extended style
      MAG-CLASS                         \ window class name
      MAG-TITLE                         \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 200 200                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ?DUP IF
      DUP TO hMAG
      DUP R> ShowWindow DROP
      DUP UpdateWindow DROP
   ELSE
      R> DROP
   THEN ;

:PRUNE   ?PRUNE -EXIT
   hMAG IF hMAG WM_CLOSE 0 0 SendMessage DROP THEN
   MAG-CLASS HINST UnregisterClass DROP ;

: DEMO ( -- )
   MAG-CLASS MAG-WNDPROC DefaultClass DROP
   SW_SHOWNORMAL /MAG-WINDOW DROP ;

: WINMAIN ( -- )
   0 'MAIN !  DEMO DISPATCHER  0 ExitProcess ;

{ --------------------------------------------------------------------
GDI Windows functions
-------------------------------------------------------------------- }

LIBRARY GDI32

FUNCTION: CreateDC ( lpszDriver lpszDevice lpszOutput *lpInitData -- h )
FUNCTION: StretchBlt ( hdcDest nXOriginDest nYOriginDest nWidthDest nHeightDest hdcSrc nXOriginSrc nYOriginSrc nWidthSrc nHeightSrc dwRop -- b )

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

50 VALUE ZOOM

CREATE CURXY   2 CELLS ALLOT

: MAGNIFY
   HWND PAD GetClientRect DROP
   CURXY GetCursorPos DROP
   HWND GetDC
   PAD @RECT
   Z" DISPLAY" 0 0 0 CreateDC DUP >R
   CURXY 2@ ( y x)  ZOOM 2/ -  SWAP ZOOM 2/ - ZOOM ZOOM
   SRCCOPY StretchBlt DROP
   R> DeleteDC DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

[+SWITCH MAG-MESSAGES
   WM_CREATE RUN: HWND 0 50 0 SetTimer DROP 0 ;
   WM_TIMER  RUN: MAGNIFY 0 ;
   WM_CLOSE  RUN: 0 KillTimer DROP HWND  DestroyWindow DROP 0 ;
SWITCH]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

[DEFINED] PROGRAM-SEALED [IF]

' WINMAIN 'MAIN !
PROGRAM-SEALED MAGNIFY.EXE

[THEN]

CR
CR .( Type DEMO to run the demonstration.)
CR
