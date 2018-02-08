OPTIONAL Circle Example of creating a circle in a window.

{ ====================================================================
Simple circle example

Copyright (c) 1972-1999, FORTH, Inc.

A very simple example of a window.

Requires: CWinApp CFrameWnd CPaintDC

Exports: DEMO

==================================================================== }

REQUIRES CWinApp
REQUIRES CFrameWnd
REQUIRES CPaintDC

CFrameWnd SUBCLASS CMainWindow

   : Construct ( -- )

      \ Register a WNDCLASS.

      0 \ ClassStyle
      0 IDC_CROSS LoadCursor
      WHITE_BRUSH COMMON GetStockObject
      0 IDI_WINLOGO LoadIcon
      AfxRegisterWndClass

      \ Create a window.

       Z" Just a circle"
       WS_OVERLAPPEDWINDOW rectDefault ADDR
       0 0 0 0
       CreateEx DROP ;

   : OnPaint ( -- )
      [OBJECTS  CPaintDC MAKES dc
                CRect MAKES rect  OBJECTS]
      rect ADDR GetClientRect  rect ADDR dc Ellipse DROP ;

   WM_PAINT  MESSAGE: ( -- res )   OnPaint 0 ;
   WM_SIZE   MESSAGE: ( -- res )   TRUE Invalidate 0 ;

END-CLASS

CWinApp SUBCLASS CMyApp

   : InitInstance ( -- flag )
       CMainWindow NEW m_pMainWnd !
       m_nCmdShow @ m_pMainWnd @ USING CWnd ShowWindow DROP
       m_pMainWnd @ USING CWnd UpdateWindow
       TRUE ;

END-CLASS

: DEMO ( -- )   [OBJECTS  CMyApp MAKES myApp  OBJECTS]
   myApp InitInstance DROP ;

CR CR .( Type DEMO to start, then drag mouse in window.) CR

