{ ====================================================================
MDI window demo

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL MDIDEMO A demonstration of MDI windows in SwiftForth.

EMPTY

REQUIRES RND

LIBRARY USER32

FUNCTION: DrawMenuBar ( hWnd -- b )
FUNCTION: IsWindow ( hWnd -- b )
FUNCTION: DefMDIChildProc ( hWnd uMsg wParam lParam -- x )
FUNCTION: DefFrameProc ( hWnd hWndMDIClient uMsg wParam lParam -- x )

LIBRARY GDI32

FUNCTION: Rectangle ( hdc nLeftRect nTopRect nRightRect nBottomRect -- b )

: RND-BRUSH ( -- hbrush )
   256 RND 16 LSHIFT
   256 RND  8 LSHIFT OR
   256 RND           OR CreateSolidBrush ;

: RND-RECTANGLE ( x y -- x y x y )
   >R DUP RND SWAP RND  R@ RND SWAP  R> RND ;

: RND-RECT ( hwnd -- )
   DUP GetDC RND-BRUSH 0 LOCALS| old brush dc hwnd |
   dc brush SelectObject TO old
   hwnd PAD GetClientRect DROP
   dc PAD CELL+ CELL+ 2@ SWAP RND-RECTANGLE Rectangle DROP
   hwnd dc ReleaseDC DROP
   brush DeleteObject DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

0 VALUE hwndClient

: DEFMDIPROC ( -- res )
   HWND MSG WPARAM LPARAM DefMDIChildProc ;

: DEFFRAME ( -- res )
   HWND hwndClient MSG WPARAM LPARAM DefFrameProc ;


[SWITCH FrameMessages DEFFRAME    SWITCH]
[SWITCH HelloMessages DEFMDIPROC  SWITCH]
[SWITCH RectMessages  DEFMDIPROC  SWITCH]

:NONAME ( -- res )   MSG LOWORD FrameMessages ;   4 CB: FrameProc
:NONAME ( -- res )   MSG LOWORD HelloMessages ;   4 CB: HelloProc
:NONAME ( -- res )   MSG LOWORD RectMessages  ;   4 CB: RectProc

: CLOSING ( -- )
   HWND GW_OWNER GetWindow ?EXIT
   HWND GetParent WM_MDIRESTORE HWND 0 SendMessage DROP
   HWND WM_QUERYENDSESSION 0 0 SendMessage -EXIT
   HWND GetParent WM_MDIDESTROY HWND 0 SendMessage DROP ;

:NONAME ( -- res )   CLOSING 1 ; 2 CB: CloseEnumProc

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: zFrameClass ( -- z )   Z" MdiFrame" ;
: zHelloClass ( -- z )   Z" MdiHelloChild" ;
: zRectClass  ( -- z )   Z" MdiRectChild" ;

0 VALUE hMenuInit
0 VALUE hMenuHello
0 VALUE hMenuRect

0 VALUE hMenuInitWindow
0 VALUE hMenuHelloWindow
0 VALUE hMenuRectWindow

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: /FRAMECLASS
   0 CS_OWNDC   OR
     CS_HREDRAW OR
     CS_VREDRAW OR                   \ class style
   FrameProc                         \ wndproc
   0                                 \ class extra
   0                                 \ window extra
   HINST                             \ hinstance
   HINST 101 LoadIcon
   NULL IDC_ARROW LoadCursor         \
   COLOR_APPWORKSPACE 1+             \
   0                                 \ no menu
   zFrameClass                       \ class name
   DefineClass DROP ;

: /HELLOCLASS
   0 CS_HREDRAW OR
     CS_VREDRAW OR                   \ class style
   HelloProc                         \ wndproc
   0                                 \ class extra
   0                                 \ window extra
   HINST                             \ hinstance
   HINST 101 LoadIcon
   NULL IDC_ARROW LoadCursor         \
   WHITE_BRUSH GetStockObject        \
   0                                 \ no menu
   zHelloClass                       \ class name
   DefineClass DROP ;

: /RECTCLASS
   0 CS_HREDRAW OR
     CS_VREDRAW OR                   \ class style
   RectProc                          \ wndproc
   0                                 \ class extra
   0                                 \ window extra
   HINST                             \ hinstance
   HINST 101 LoadIcon
   NULL IDC_ARROW LoadCursor         \
   WHITE_BRUSH GetStockObject        \
   0                                 \ no menu
   zRectClass                        \ class name
   DefineClass DROP ;

: /CLASSES ( -- )
   /FRAMECLASS /HELLOCLASS /RECTCLASS ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

100
   ENUM IDM_NEWHELLO
   ENUM IDM_NEWRECT
   ENUM IDM_EXIT
   ENUM IDM_CASCADE
   ENUM IDM_ARRANGE
   ENUM IDM_TILE
   ENUM IDM_CLOSEALL
   ENUM IDM_CLOSE

100 +
   ENUM IDM_FIRSTCHILD

DROP

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

MENU MENUINIT
   POPUP "&File"
      IDM_NEWHELLO MENUITEM "New &Hello"
      IDM_NEWRECT  MENUITEM "New &Rect"
                   SEPARATOR
      IDM_EXIT     MENUITEM "E&xit"
   END-POPUP
END-MENU

MENU MENUHELLO
   POPUP "&File"
      IDM_NEWHELLO MENUITEM "New &Hello"
      IDM_NEWRECT  MENUITEM "New &Rect"
                   SEPARATOR
      IDM_EXIT     MENUITEM "E&xit"
   END-POPUP
   POPUP "&Window"
      IDM_CASCADE  MENUITEM "&Cascade"
      IDM_TILE     MENUITEM "&Tile"
      IDM_ARRANGE  MENUITEM "Arrange &Icons"
      IDM_CLOSEALL MENUITEM "Close &All"
   END-POPUP
END-MENU

MENU MENURECT
   POPUP "&File"
      IDM_NEWHELLO MENUITEM "New &Hello"
      IDM_NEWRECT  MENUITEM "New &Rect"
                   SEPARATOR
      IDM_EXIT     MENUITEM "E&xit"
   END-POPUP
   POPUP "&Window"
      IDM_CASCADE  MENUITEM "&Cascade"
      IDM_TILE     MENUITEM "&Tile"
      IDM_ARRANGE  MENUITEM "Arrange &Icons"
      IDM_CLOSEALL MENUITEM "Close &All"
   END-POPUP
END-MENU

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: /MENUINIT ( -- )
   MENUINIT LoadMenuIndirect TO hMenuInit
   hMenuInit 0 GetSubMenu TO hMenuInitWindow ;

: /MENUHELLO ( -- )
   MENUHELLO LoadMenuIndirect TO hMenuHello
   hMenuHello 1 GetSubMenu TO hMenuHelloWindow ;

: /MENURECT ( -- )
   MENURECT LoadMenuIndirect TO hMenuRect
   hMenuRect 1 GetSubMenu TO hMenuRectWindow ;

: /MENUS ( -- )
   /MENUINIT /MENUHELLO /MENURECT ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

0 VALUE hwndFrame

: /FRAME
   0 zFrameClass Z" MDI Demo" WS_OVERLAPPEDWINDOW WS_CLIPCHILDREN OR
   CW_USEDEFAULT DUP 2DUP
   0 hMenuInit HINST 0 CreateWindowEx TO hwndFrame ;

: GO
   /CLASSES /MENUS /FRAME
   hwndFRAME SW_SHOW ShowWindow DROP
   hwndFRAME UpdateWindow DROP ;

:PRUNE   ?PRUNE -EXIT
   hwndFRAME IF hwndFRAME WM_CLOSE 0 0 SendMessage DROP THEN
   zFrameClass HINST UnregisterClass DROP
   zHelloClass HINST UnregisterClass DROP
   zRectClass HINST UnregisterClass DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: FRAME-CREATE ( -- res )
   IDM_FIRSTCHILD hMenuInitWindow PAD 2!
   0
   Z" MDICLIENT"
   0
   0 WS_CHILD OR
     WS_CLIPCHILDREN OR
     WS_VISIBLE OR
   0 0 0 0
   HWND
   1
   HINST
   PAD CreateWindowEx TO hwndClient
   0 ;

DEFER /HELLO
DEFER /RECT

: CHILD-CLOSE ( -- )
   hwndClient WM_MDIGETACTIVE 0 0 SendMessage
   hwndClient WM_MDIDESTROY ROT 0 SendMessage DROP ;

: DefFrameCommand ( cmd -- )
   hwndClient WM_MDIGETACTIVE 0 0 SendMessage
   DUP IsWindow IF
      WM_COMMAND WPARAM LPARAM SendMessage
   THEN DROP DEFFRAME ;

[SWITCH FrameCommands DefFrameCommand ( cmd -- )
   IDM_NEWHELLO RUNS /HELLO
   IDM_NEWRECT  RUNS /RECT
   IDM_CLOSE    RUNS CHILD-CLOSE
   IDM_EXIT     RUN: HWND WM_CLOSE 0 0 SendMessage DROP ;
   IDM_TILE     RUN: hwndClient WM_MDITILE 0 0 SendMessage DROP ;
   IDM_CASCADE  RUN: hwndClient WM_MDICASCADE 0 0 SendMessage DROP ;
   IDM_ARRANGE  RUN: hwndClient WM_MDIICONARRANGE 0 0 SendMessage DROP ;
   IDM_CLOSEALL RUN: hwndClient CloseEnumProc 0 EnumChildWindows DROP ;
SWITCH]

[+SWITCH FrameMessages
   WM_COMMAND RUN: WPARAM LOWORD FrameCommands 0 ;
   WM_CREATE  RUNS FRAME-CREATE
SWITCH]

{ --------------------------------------------------------------------
  LPCTSTR szClass;
    LPCTSTR szTitle;
    HANDLE  hOwner;
    int     x;
    int     y;
    int     cx;
    int     cy;
    DWORD   style;
    LPARAM  lParam;
-------------------------------------------------------------------- }

: (/HELLO)
   PAD zHelloClass !+
   Z" Hello"  !+
   HINST !+
   CW_USEDEFAULT !+
   CW_USEDEFAULT !+
   CW_USEDEFAULT !+
   CW_USEDEFAULT !+
   0 !+
   0 !+ DROP
   hwndClient WM_MDICREATE 0 PAD SendMessage DROP ;

' (/HELLO) IS /HELLO

: HELLO-PAINT ( -- res )
   HWND PAD GetClientRect DROP
   HWND HERE BeginPaint ( hdc)
   ( hdc) Z" Hello, World!" -1 PAD DT_SINGLELINE DT_CENTER OR DT_VCENTER OR
      DrawText DROP
   HWND HERE EndPaint DROP 0 ;

: HELLO-ACTIVATE ( -- res )
   LPARAM HWND = IF
      hwndCLIENT WM_MDISETMENU hMenuHello hMenuHelloWindow SendMessage DROP
   ELSE
      hwndCLIENT WM_MDISETMENU hMenuInit hMenuInitWindow SendMessage DROP
   THEN hwndFrame DrawMenuBar DROP 0 ;

[+SWITCH HelloMessages
  WM_DESTROY RUN: 0 ;
  WM_PAINT RUNS HELLO-PAINT
  WM_MDIACTIVATE RUNS HELLO-ACTIVATE
SWITCH]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: (/RECT)
   PAD zRectClass !+
   Z" Rectangles"  !+
   HINST !+
   CW_USEDEFAULT !+
   CW_USEDEFAULT !+
   CW_USEDEFAULT !+
   CW_USEDEFAULT !+
   0 !+
   0 !+ DROP
   hwndClient WM_MDICREATE 0 PAD SendMessage DROP ;

' (/RECT) IS /RECT

: RECT-CREATE ( -- res )
   HWND 1 250 0 SetTimer DROP  0 ;

: RECT-TIMER ( -- res )
   HWND RND-RECT  0 ;

: RECT-PAINT ( -- res )
   HWND 0 1 InvalidateRect DROP
   HWND PAD 2DUP  BeginPaint DROP  EndPaint DROP  0 ;

: RECT-DESTROY ( -- res )
   HWND 1 KillTimer DROP  0 ;

: RECT-ACTIVATE ( -- res )
   LPARAM HWND = IF
      hwndCLIENT WM_MDISETMENU hMenuRect hMenuRectWindow SendMessage DROP
   ELSE
      hwndCLIENT WM_MDISETMENU hMenuInit hMenuInitWindow SendMessage DROP
   THEN hwndFrame DrawMenuBar DROP 0 ;

[+SWITCH RectMessages
   WM_CREATE  RUNS RECT-CREATE
   WM_TIMER   RUNS RECT-TIMER
   WM_PAINT   RUNS RECT-PAINT
   WM_DESTROY RUNS RECT-DESTROY
   WM_MDIACTIVATE RUNS RECT-ACTIVATE
SWITCH]

CR
CR .( Type GO to run the MDI example)
CR
