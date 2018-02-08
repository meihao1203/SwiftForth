{ ====================================================================
Windows application template

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL WIN2 A stand-alone Windows application template including a simple menu.

{ --------------------------------------------------------------------
This is a simple example of a Windows program with a menu that does
not need or create a console window.
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS DECIMAL

{ --------------------------------------------------------------------
Define a simple menu, with exit and about options
-------------------------------------------------------------------- }

100 ENUM M_EXIT
    ENUM M_ABOUT
DROP

MENU APP-MENU

   POPUP "&File"
      M_EXIT   MENUITEM "E&xit"
   END-POPUP

   POPUP "&Help"
      M_ABOUT  MENUITEM "&About"
   END-POPUP

END-MENU

{ --------------------------------------------------------------------
Command message execution
-------------------------------------------------------------------- }

: APP-ABOUT ( -- res )
   HWND Z" A sample SwiftForth application" Z" About" MB_OK MessageBox DROP 0 ;

: APP-EXIT ( -- res )
   HWND WM_CLOSE 0 0 PostMessage DROP 0 ;

[SWITCH APP-COMMANDS ZERO ( cmd -- res )
   M_EXIT  RUNS APP-EXIT
   M_ABOUT RUNS APP-ABOUT
SWITCH]

{ --------------------------------------------------------------------
Window creation and message dispatcher.

This is generic template that may be used for windows programs.
-------------------------------------------------------------------- }

CREATE APP-CLASS   ,Z" AppName"
CREATE APP-TITLE  ,Z" Application Title"

0 VALUE hAPP
0 VALUE APPLICATION

: APP-DESTROY ( -- res )   0 TO hAPP
   APPLICATION IF 0 PostQuitMessage DROP  THEN  0 ;

: APP-CREATE ( -- res )
   HWND  APP-MENU LoadMenuIndirect SetMenu DROP 0 ;

: APP-CLOSE ( -- res )
   HWND GetMenu DestroyMenu DROP  HWND DestroyWindow DROP  0 ;

[SWITCH APP-MESSAGES DEFWINPROC ( msg -- res )
   WM_DESTROY RUNS APP-DESTROY
   WM_CREATE  RUNS APP-CREATE
   WM_CLOSE   RUNS APP-CLOSE
   WM_COMMAND RUN: WPARAM LOWORD APP-COMMANDS ;
   WM_LBUTTONDOWN RUNS APP-ABOUT
SWITCH]

:NONAME  MSG LOWORD APP-MESSAGES ; 4 CB: APP-WNDPROC

: /APP-CLASS ( -- )
      0  CS_OWNDC   OR
         CS_HREDRAW OR
         CS_VREDRAW OR                  \ class style
      APP-WNDPROC                       \ wndproc
      0                                 \ class extra
      0                                 \ window extra
      HINST                             \ hinstance
      0                                 \
      NULL IDC_ARROW LoadCursor         \
      WHITE_BRUSH GetStockObject        \
      0                                 \ no menu
      APP-CLASS                         \ class name
   DefineClass DROP ;

: /APP-WINDOW ( cmdshow -- hwnd )   >R
      0                                 \ extended style
      APP-CLASS                         \ window class name
      APP-TITLE                         \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 600 400                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ?DUP IF
      DUP TO hAPP
      DUP R> ShowWindow DROP
      DUP UpdateWindow DROP
   ELSE
      R> DROP
   THEN ;

:PRUNE   ?PRUNE -EXIT
   hAPP IF hAPP WM_CLOSE 0 0 SendMessage DROP THEN
   APP-CLASS HINST UnregisterClass DROP ;

: DEMO ( -- )
   /APP-CLASS SW_SHOWNORMAL /APP-WINDOW DROP ;

: WINMAIN ( -- )
   1 TO APPLICATION  DEMO DISPATCHER 0 ExitProcess ;

{ --------------------------------------------------------------------
Uncomment these lines to create a stand-alone application.

' WINMAIN 'MAIN !
PROGRAM-SEALED MYAPP
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

DEMO

KEY DROP BYE  [THEN]

CR
CR .( Type DEMO to run the demonstration.)
CR
