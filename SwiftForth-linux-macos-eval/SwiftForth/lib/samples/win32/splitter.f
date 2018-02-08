{ ====================================================================
Splitter Window

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL SPLITTER Demonstrates how to divide a main window with multiple children and resize both simultaneously

{ --------------------------------------------------------------------
A splitter window is actually made up of multiple child windows that
are a single pixel apart in the parent's frame.  When the cursor is
over the single pixel, it is used to redistribute the sizes of the
split windows.

The strategy is to leave a single pixel line as a crosshair between
the panes, using it to adjust the splitter sizes.
-------------------------------------------------------------------- }

0 VALUE SPLIT-HWND

CREATE AppName ,Z" Splitter"

[SWITCH SPLIT-MESSAGES DEFWINPROC ( -- res )
   WM_DESTROY RUN:  0 TO SPLIT-HWND  ( 0 PostQuitMessage DROP ) 0 ;
SWITCH]

:NONAME  MSG LOWORD SPLIT-MESSAGES ; 4 CB: SPLITPROC

: SPLITWINDOW ( -- hwnd )
      0                                 \ extended style
      AppName                           \ window class name
      Z" Source Debug"                  \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 200 200
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: EDWINDOW ( hwnd -- hwnd )
   >R
      WS_EX_CLIENTEDGE                             \ extended style
      Z" edit"                          \ window class name
      0
      [  WS_CHILD
         WS_VISIBLE     OR
         WS_BORDER      OR
         WS_HSCROLL     OR
         WS_VSCROLL     OR
         ES_NOHIDESEL   OR
         ES_LEFT        OR
         ES_AUTOHSCROLL OR
         ES_AUTOVSCROLL OR
         ES_MULTILINE   OR ] LITERAL    \ window style
      0 0 0 0
      R>                                \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

0 VALUE ED-HWND0
0 VALUE ED-HWND1
0 VALUE ED-HWND2
0 VALUE ED-HWND3


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

100 VALUE SX      \ split point x
100 VALUE SY      \ and y

: SPLIT0 ( c s -- 0 s-1 )
   1- >R DROP 0 R> ;

: SPLIT1 ( c s -- s+1 c-s )
   DUP 1+ -ROT - ;

: SPLIT-CREATE ( -- res )
   HWND EDWINDOW TO ED-HWND0
   HWND EDWINDOW TO ED-HWND1
   HWND EDWINDOW TO ED-HWND2
   HWND EDWINDOW TO ED-HWND3
   0 ;

: CX ( -- x )   LPARAM LOWORD ;
: CY ( -- y )   LPARAM HIWORD ;

: QUAD0 ( -- x y cx cy )   CX SX SPLIT0  CY SY SPLIT0  ROT SWAP ;
: QUAD1 ( -- x y cx cy )   CX SX SPLIT1  CY SY SPLIT0  ROT SWAP ;
: QUAD2 ( -- x y cx cy )   CX SX SPLIT0  CY SY SPLIT1  ROT SWAP ;
: QUAD3 ( -- x y cx cy )   CX SX SPLIT1  CY SY SPLIT1  ROT SWAP ;


: SPLIT-SIZE ( -- res )
   ED-HWND0 QUAD0 1 MoveWindow DROP
   ED-HWND1 QUAD1 1 MoveWindow DROP
   ED-HWND2 QUAD2 1 MoveWindow DROP
   ED-HWND3 QUAD3 1 MoveWindow DROP
   0 ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

0 VALUE NS/WE

: CURSORWE ( -- )   0 TO NS/WE
   0 IDC_SIZEWE LoadCursor SetCursor DROP ;

: CURSORNS ( -- )   1 TO NS/WE
   0 IDC_SIZENS LoadCursor SetCursor DROP ;

: SPLIT-SETCURSOR ( -- )
   CX SX = IF  CURSORWE ELSE
      CY SY = IF  CURSORNS THEN
   THEN ;

: SPLIT-SETCAPTURE ( -- res )
   CX SX =  CY SY = OR IF
      HWND SetCapture DROP  SPLIT-SETCURSOR
   THEN 0 ;

: SPLIT-RELEASECAPTURE ( -- res )
   ReleaseCapture DROP 0 ;

: SPLIT-ADJUSTPANES ( -- res )
   GetCapture HWND = IF ( dragging!)
      NS/WE IF ( ns capture)
         CY TO SY
      ELSE
         CX TO SX
      THEN
      HWND PAD GetClientRect  PAD 2 CELLS + 2@  SWAP 16 LSHIFT OR >R
      HWND WM_SIZE 0 R> SendMessage DROP
   THEN
   SPLIT-SETCURSOR 0 ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

[+SWITCH SPLIT-MESSAGES ( msg -- res )
   WM_CREATE      RUNS SPLIT-CREATE
   WM_MOUSEMOVE   RUNS SPLIT-ADJUSTPANES
   WM_SIZE        RUNS SPLIT-SIZE
   WM_LBUTTONDOWN RUNS SPLIT-SETCAPTURE
   WM_LBUTTONUP   RUNS SPLIT-RELEASECAPTURE
SWITCH]

: TEST ( -- )
   SPLIT-HWND ?EXIT
   AppName SPLITPROC DefaultClass DROP
   SPLITWINDOW TO SPLIT-HWND
   SPLIT-HWND DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP ;

:PRUNE
   SPLIT-HWND DestroyWindow DROP  0 TO SPLIT-HWND
   AppName HINST UnregisterClass DROP ;

CR
CR .( Type TEST to run the splitter demo.)
CR
