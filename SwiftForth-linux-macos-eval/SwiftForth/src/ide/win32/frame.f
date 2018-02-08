{ ====================================================================
Main window frame for SwiftForth

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

PACKAGE CONSOLE-WINDOW

VARIABLE SIZING

40 VALUE TOP-MARGIN
0 VALUE BOT-MARGIN

{ --------------------------------------------------------------------
DEFPLACEMENT is used by SwiftForth during startup and shutdown when
calling Get and SetWindowPlacement. We only are about the position,
and save that in the registry as local and global configuration.
-------------------------------------------------------------------- }

CREATE DEFPLACEMENT   44 ,      \ size
   0 , 0 ,                      \ flags, showcmd
   -1 , -1 ,                    \ point: minpos
   -1 , -1 ,                    \ point: maxpos
   10 , 10 , 600 , 400 ,        \ rect: norm position

: DEFWINPOS ( -- addr )   DEFPLACEMENT 7 CELLS + ;

CONFIG: WINDOW-POSITION  ( -- addr n )   DEFWINPOS 4 CELLS ;
LOCALCONFIG: WINDOW-POSITION  ( -- addr n )   DEFWINPOS 4 CELLS ;

CREATE DEFZOOM   0 ,
CONFIG: ZOOMED ( -- addr n )   DEFZOOM  CELL ;

{ --------------------------------------------------------------------
TTY is the text pane in the main SwiftForth window. It is created
during WM_CREATE service, at the same time the toolbar and status
line are created. We need the handle of it outside of the callback
context, and save it in a named property of the main widow.
-------------------------------------------------------------------- }

: HTTY ( -- handle )   HWND "TTY" GetProp ;

: TTY-SIZE ( -- x y cx cy )   16 R-ALLOC >R
   HWND R@ GetClientRect DROP
   0 TOP-MARGIN R> CELL+ CELL+ 2@ SWAP TOP-MARGIN - BOT-MARGIN - ;

0 WS_CHILD OR
  WS_VISIBLE OR
  WS_VSCROLL OR
  WS_HSCROLL OR
  WS_BORDER OR
CONSTANT TTY-STYLE

: CREATE-TTY ( -- )   REGISTER-TTY
   0 "TTY" 0 TTY-STYLE TTY-SIZE
   HWND 0 HINST 0 CreateWindowEx ( handle)
   ( handle)  DUP SIMPLE-GUI CELL+ CELL+ !
   ( handle)  HWND "TTY" ROT SetProp DROP ;

: RESIZE-TTY ( -- )
   HTTY TTY-SIZE TRUE MoveWindow DROP
   HTTY 0 0 InvalidateRect DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

TOOL-BAR BUILDS SF-TOOLBAR

DEFER SMALL-TB-BMP
DEFER BIG-TB-BMP

PRIVATE

S" %SWIFTFORTH\SRC\IDE\WIN32\SWIFTBAR.BMP" +ROOT BMP &SMALLBAR
S" %SWIFTFORTH\SRC\IDE\WIN32\SWIFTBIG.BMP" +ROOT BMP &BIGBAR

' &SMALLBAR IS SMALL-TB-BMP
' &BIGBAR   IS BIG-TB-BMP


: GET-BITMAP-HANDLE ( dc bitmap -- hbitmap )
   [OBJECTS BITMAP MAKES BM OBJECTS]   BM GET-HANDLE ;

: CREATE-SF-TOOLBAR ( -- )
   HWND GetDC ( dc)
   DUP SMALL-TB-BMP GET-BITMAP-HANDLE SF-TOOLBAR hSMALL !
   DUP BIG-TB-BMP   GET-BITMAP-HANDLE SF-TOOLBAR hBIG   !
   HWND SWAP ReleaseDC DROP
   ['] TOOLBAR  SF-TOOLBAR xtTOOLBAR !
   #TOOLBUTTONS SF-TOOLBAR #TOOLS !
   HWND SF-TOOLBAR CREATE-TOOLBAR ;

: RESIZE-SF-TOOLBAR ( -- )   SF-TOOLBAR RESIZE
   SF-TOOLBAR HEIGHT TO TOP-MARGIN ;

CONFIG: TOOLBAR-SIZE ( -- addr len )   SF-TOOLBAR BIG CELL ;
CONFIG: TOOLBAR-FLAT ( -- addr len )   SF-TOOLBAR FLAT CELL ;

{ --------------------------------------------------------------------

STATUS-TOOLS (built in STATUS.F) is used here.
-------------------------------------------------------------------- }

STATUS-TOOLS +ORDER

: CREATE-STATUS ( -- )
   CONSTRUCT-SF-STATUSBAR
   OEM_FIXED_FONT GetStockObject SF-STATUS SETFONT
   SF-STATUS HEIGHT TO BOT-MARGIN
   ['] STATUS.STACK IS .STACK ;

STATUS-TOOLS -ORDER

: RESIZE-STATUS ( -- )   SF-STATUS RESIZE
   SF-STATUS HEIGHT TO BOT-MARGIN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: RESIZED ( -- res )   SIZING @ 0= IF
      RESIZE-SF-TOOLBAR  RESIZE-STATUS  RESIZE-TTY
   THEN DEFWINPROC ;

: SAVE-WINDOW-POSITION ( -- )
   HWND IsZoomed DEFZOOM !
   HWND DEFPLACEMENT GetWindowPlacement DROP
   DEFWINPOS 2@ NEGATE  DEFWINPOS 8 + +!
   NEGATE  DEFWINPOS 12 + +! ;

DEFER CLEANUP   ' NOOP IS CLEANUP

: DESTROYS ( -- res )
   CLEANUP  0 PostQuitMessage DROP 0 ;

: CREATES ( -- res )
   CREATE-TTY CREATE-SF-TOOLBAR CREATE-STATUS  DEFWINPROC ;

{ --------------------------------------------------------------------
Visible screen area
-------------------------------------------------------------------- }

4 CELLS BUFFER: WORKAREA

: GET-WORKAREA ( -- )
   SPI_GETWORKAREA 0 WORKAREA 0 SystemParametersInfo DROP ;

: FORCE-ONSCREEN ( -- )   GET-WORKAREA
   HWND  WORKAREA @RECT 2DROP 10 10 D+ 600 400 1 MoveWindow DROP
   HWND SW_SHOWNORMAL ShowWindow DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

[SWITCH SF-NOTIFICATIONS ZERO ( code -- res )
   TTN_FIRST RUN: LPARAM CELL+ @ TOOLTIP LPARAM 3 CELLS + ! 0 ;  ( ttn_needtext)
SWITCH]

[SWITCH SF-COMMANDS DEFWINPROC ( cmd -- res )
SWITCH]

[SWITCH SF-MESSAGES DEFWINPROC
   WM_SYSCOMMAND    RUN:   WPARAM 1024 = IF FORCE-ONSCREEN THEN  DEFWINPROC ;
   WM_CREATE        RUNS CREATES
   WM_CLOSE         RUN: SAVE-WINDOW-POSITION
                         HWND DestroyWindow DROP 0 ;
   WM_SETFOCUS      RUN: HTTY SetFocus DROP  DEFWINPROC ;
   WM_ENTERSIZEMOVE RUN: SIZING ON  DEFWINPROC ;
   WM_SIZE          RUNS RESIZED
   WM_SIZING        RUN: HTTY WM_SIZING WPARAM LPARAM SendMessage ;
   WM_EXITSIZEMOVE  RUN: SIZING OFF RESIZED ;
   WM_DESTROY       RUNS DESTROYS
   WM_NOTIFY        RUN: LPARAM 2 CELLS + @ SF-NOTIFICATIONS  ;
   WM_COMMAND       RUN: WPARAM LOWORD SF-COMMANDS 0 ;
   WM_RBUTTONDOWN   RUN: HWND WM_COMMAND MI_RIGHTMENU 0 PostMessage DROP 0 ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD SF-MESSAGES ;  4 CB: SF-CALLBACK

: DefaultWindow ( zname -- handle )
      0                                 \ extended style
      SWAP                              \ window class name
      DUP                               \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      DEFWINPOS @RECT 2>R >R            \ rel position and size (in workspace)
      WORKAREA @ +                      \ abs corner x
      WORKAREA CELL+ @ R> +             \ abs corner y
      2R>                               \ window (x,y,cx,xy) in screen space
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: SFCLASS ( zname -- res )   >R
   CS_OWNDC                          \ style
   SF-CALLBACK                       \ wndproc
   0                                 \ class extra
   0                                 \ window extra
   HINST                             \ hinstance
   HINST 101 LoadIcon                \
   NULL IDC_ARROW LoadCursor         \
   LTGRAY_BRUSH GetStockObject       \
   0                                 \ no menu
   R>                                \ class name
   DefineClass ;

{ --------------------------------------------------------------------
MAIN-MENU is deferred so turnkeyed applications can change it.
/GUI initializes the SwiftForth console GUI window.
-------------------------------------------------------------------- }

PUBLIC

DEFER MAIN-MENU  ' FORTH-MENU IS MAIN-MENU

PRIVATE

: MODIFY-SYSMENU ( -- )
   HCON 0 GetSystemMenu
   DUP MF_SEPARATOR 0 0 AppendMenu DROP
       MF_STRING 1024 Z" &Force Onscreen" AppendMenu DROP ;

: GUI-FRAME ( -- handle )
   Z" SwiftForth" DUP SFCLASS DROP DefaultWindow
   DUP TO HCON  DUP DEFZOOM @ IF SW_MAXIMIZE ELSE SW_NORMAL THEN ShowWindow DROP
   DUP MAIN-MENU LoadMenuIndirect SetMenu DROP ;

PUBLIC

: /GUI ( -- )
   GET-WORKAREA  GUI-FRAME ( hwnd) WPARMS !  MODIFY-SYSMENU
   SIMPLE-GUI 'PERSONALITY !  PHANDLE TtyNew DROP  -1 ?TTY ! ;

END-PACKAGE
