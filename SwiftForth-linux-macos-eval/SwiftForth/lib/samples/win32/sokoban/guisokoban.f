{ ====================================================================
guisokoban.f
Sokoban (C) Copyright 1996 Rick VanNorman

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

INCLUDE TEXTSOKO
INCLUDE BMPSOKO

CREATE AppName ,Z" Sokoban"

WM_USER ENUM SOKO_REFRESH
        ENUM SOKO_HAPPY
DROP

{ --------------------------------------------------------------------
Menu definition

Constants control what is passed to WM_COMMAND from menu selections.

The menu itself is defined and created here, and its handle is saved
for later deletion.
-------------------------------------------------------------------- }

100 ENUM SOKO_BIG
    ENUM SOKO_SMALL
    ENUM SOKO_ABOUT
    ENUM SOKO_HELP
    ENUM SOKO_EXIT
DROP

MENU SOKO-MENU

   POPUP "&File"
      SOKO_EXIT MENUITEM "E&xit"
   END-POPUP

   POPUP "&Options"
      SOKO_SMALL  MENUITEM "&Small"
      SOKO_BIG    MENUITEM "&Big"
   END-POPUP

   POPUP "&Help"
      SOKO_HELP  MENUITEM "&Help"
      SOKO_ABOUT MENUITEM "&About"
   END-POPUP

END-MENU

{ --------------------------------------------------------------------
Create a status bar for the game.
-------------------------------------------------------------------- }

: SOKO-STATUSBAR ( hwnd-owner -- hsb )   >R
   WS_CHILD WS_VISIBLE OR  \ SBARS_SIZEGRIP OR
   WS_CLIPSIBLINGS OR CCS_BOTTOM OR
   0 R> 2 CreateStatusWindow ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CREATE POS   16 /ALLOT
VARIABLE MAG

0 VALUE SOKO-STATUS
0 VALUE SOKO-HANDLE
0 VALUE SOKO-DC

0 VALUE SOKO-CLASS
0 VALUE SOKO-BRUSH

: SOKOWIN/
   SPRITES/
   HWND GetMenu DestroyMenu DROP ;

: /SOKOWIN
   MAG @ ZOOM
   HWND SOKO-MENU LoadMenuIndirect SetMenu DROP
   HWND SOKO-STATUSBAR TO SOKO-STATUS
   HWND GetDC TO SOKO-DC
   HWND SOKO_REFRESH 0 0 PostMessage DROP ;

{ --------------------------------------------------------------------
Windows function
-------------------------------------------------------------------- }

LIBRARY USER32
FUNCTION: AdjustWindowRect ( lpRect dwStyle bMenu -- b )

{ --------------------------------------------------------------------
Window class and instance creation plus the message dispatcher.
-------------------------------------------------------------------- }

[SWITCH SOKO-MESSAGES DEFWINPROC ( -- res )
   WM_DESTROY RUN:  SOKOWIN/  0 PostQuitMessage DROP  0 ;
   WM_CREATE  RUN:  /SOKOWIN 1 GAME 0 ;
SWITCH]

:NONAME  MSG LOWORD SOKO-MESSAGES ; 4 CB: WNDPROC

: CREATE-SOKO-CLASS ( -- hclass )
      0  CS_OWNDC   OR
         CS_DBLCLKS OR
         CS_HREDRAW OR
         CS_VREDRAW OR                \ class style
      WNDPROC                         \ proc
      0                               \ class extra
      0                               \ window extra
      HINST
      0
      0 IDC_ARROW LoadCursor
      WHITE_BRUSH GetStockObject
      SOKO-MENU                       \ hMenu
      AppName
   DefineClass ;

: CREATE-SOKO-WINDOW ( -- hwnd )
      0                                 \ extended style
      AppName                           \ window class name
      AppName                           \ window caption
      0 WS_OVERLAPPED   OR
        WS_CAPTION      OR
        WS_SYSMENU      OR
        WS_BORDER       OR
        WS_MINIMIZEBOX  OR
        WS_MAXIMIZEBOX  OR              \ window style


      POS @+ SWAP @+ SWAP @+ SWAP @
      >R THIRD - R> THIRD -
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: PLAY ( -- res )
   CREATE-SOKO-CLASS TO SOKO-CLASS
   CREATE-SOKO-WINDOW TO SOKO-HANDLE
   SOKO-HANDLE
      DUP SW_SHOWNORMAL ShowWindow DROP
      DUP UpdateWindow DROP
          SetForegroundWindow DROP
   DISPATCHER  ;

{ --------------------------------------------------------------------
YSIZE and XSIZE returns the overall window size for the given board.
These could use a little tweak or two...
-------------------------------------------------------------------- }

: YSIZE ( -- y )
   HEIGHT SQ *
   SM_CYMENUSIZE GetSystemMetrics +
   SM_CYCAPTION  GetSystemMetrics +
   SM_CYEDGE   GetSystemMetrics 2* +
   SOKO-STATUS PAD GetWindowRect DROP  PAD 3 CELLS + @ PAD CELL+ @ - + ;

: XSIZE ( -- x )
   WIDTH SQ *
   SM_CXEDGE GetSystemMetrics 2* + ;

: RESIZEMAZE
   HWND PAD GetWindowRect DROP
   HWND PAD 2@ SWAP XSIZE YSIZE 1 MoveWindow DROP
   HWND POS GetWindowRect DROP
   SOKO-STATUS WM_SIZE 0 0 SendMessage DROP ;

: PAINTMAZE
   HWND PAD BeginPaint TO hdcDRAW
   RESIZEMAZE SHOW
   HWND PAD EndPaint DROP ;

: INVALIDATE
   HWND 0 1 InvalidateRect DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: HAPPY
   HWND Z" You finished!" Z" Yea!" MB_OK MessageBox DROP ;

: SLOW 5 Sleep DROP ;

[SWITCH KEYACTIONS DROP ( vkey -- )
   VK_HOME   RUN: ['] SLOW IS PACE TEST 0 IS PACE 0 ;
   VK_UP     RUNS U
   VK_DOWN   RUNS D
   VK_RIGHT  RUNS R
   VK_LEFT   RUNS L
   VK_BACK   RUNS Z
   VK_PRIOR  RUN: P INVALIDATE 0 ;
   VK_NEXT   RUN: N INVALIDATE 0 ;
   VK_ESCAPE RUN: HWND WM_CLOSE 0 0 PostMessage DROP  ;
SWITCH]

[SWITCH SOKO-COMMANDS ZERO ( wparam -- res )
   SOKO_EXIT  RUN: HWND WM_CLOSE 0 0 PostMessage DROP 0 ;
   SOKO_BIG   RUN: MAG ON  1 ZOOM INVALIDATE 0 ;
   SOKO_SMALL RUN: MAG OFF 0 ZOOM INVALIDATE 0 ;
SWITCH]

[+SWITCH SOKO-MESSAGES ( msg -- res )
    WM_MOVE      RUN: HWND POS GetWindowRect DROP 0 ;
    WM_PAINT     RUN: PAINTMAZE 0 ;
    WM_KEYDOWN   RUN: WPARAM LOWORD KEYACTIONS 0 ;
    WM_SETFOCUS  RUN: INVALIDATE 0 ;
    WM_COMMAND   RUN: WPARAM LOWORD SOKO-COMMANDS ;
    SOKO_REFRESH RUN: INVALIDATE 0 ;
    SOKO_HAPPY   RUN: HAPPY N 0 ;
SWITCH]

0 IS PACE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: (.STATUS) ( -- zaddr )
   S"   Level " PAD ZPLACE   LOCALE @ (.) PAD ZAPPEND
   S"   Low score " PAD ZAPPEND 'WINNER @ ?DUP IF (.) PAD ZAPPEND THEN
   S"   Moves " PAD ZAPPEND  MOVES  @ (.) PAD ZAPPEND
   S"   Pushes " PAD ZAPPEND PUSHES @ (.) PAD ZAPPEND
   PAD ;

: UPDATE-STATUS
   SOKO-STATUS  SB_SETTEXTA 0 (.STATUS)  SENDMESSAGE  DROP ;

-? : ?FINISHED
   -FINISHED ?EXIT  HWND SOKO_HAPPY 0 0 PostMessage DROP ;

: WIN.STATUS
   UPDATE-STATUS ?FINISHED ;

' WIN.STATUS IS .STATUS

: SOKOKEY ( -- handle )
   HKEY_CURRENT_USER Z" SOFTWARE\Sokoban" 0 >R RP@
   RegCreateKey DROP R> ;

: GET-SCORES ( -- )   SOKOKEY >R
   WINNERS |WINNERS| Z" Scores" R@ READ-REG 2DROP
   R> RegCloseKey DROP ;

: SAVE-SCORES ( -- )   SOKOKEY >R
   WINNERS |WINNERS| Z" Scores" R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

: GET-POSITION ( -- )   SOKOKEY >R
   POS 16 Z" Position" R@ READ-REG 2DROP
   MAG  4 Z" Size"     R@ READ-REG 2DROP
   R> RegCloseKey DROP ;

: SAVE-POSITION ( -- )   SOKOKEY >R
   POS 16 Z" Position" R@ WRITE-REG DROP
   MAG  4 Z" Size"     R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: WINMAIN
   GET-SCORES  GET-POSITION
   ['] PLAY CATCH DUP IF
      0 SWAP Z(.) Z" Sokoban threw " 0 MessageBox DROP
   ELSE
      SAVE-SCORES SAVE-POSITION
   THEN
   0 ExitProcess ;

' WINMAIN 'MAIN !


