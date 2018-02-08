OPTIONAL MouseCap Mouse Capturing example from MFC book.

{ ====================================================================
Mouse Capturing in Action

Copyright (c) 1972-1999, FORTH, Inc.

The MouseCap application is taken from Chapter 3, Figure 3-5 of the
book Programming Windows with MFC, Second Edition, written by Jeff
Prosise. It is a rudimentary paint program that lets the user draw
lines with the mouse. To draw a line, press the left mouse button
anywhere in the window's client area and drag the cursor with the
button held down. As the mouse is moved, a thin line is rubber-banded
between the anchor point and the cursor. When the mouse button is
released, the rubber-band line is erased and a red line 16 pixels wide
is drawn in its place. Because the mouse is captured while the button
is depressed, rubber-banding works even if the mouse is moved outside
the window. And no matter where the cursor is when the mouse button is
released, a red line is drawn between the anchor point and the
endpoint.

Requires: CWinApp CFrameWnd CPaintDC CClientDC CPen

Exports: DEMO

==================================================================== }

{ --------------------------------------------------------------------
A few things we need...
-------------------------------------------------------------------- }

\ Debugging support
\ REQUIRES MSGTEXT
\ REQUIRES CONSOLEBUG   TRUE TO BUGME

REQUIRES CWinApp
REQUIRES CFrameWnd
REQUIRES CPaintDC
REQUIRES CClientDC
REQUIRES CPen

CFrameWnd SUBCLASS CMainWindow

PROTECTED

   VARIABLE m_bTracking          \ TRUE if rubber banding
   VARIABLE m_bCaptureEnabled    \ TRUE if capture enabled
   CPoint BUILDS m_ptFrom        \ "From" point for rubber banding
   CPoint BUILDS m_ptTo          \ "To" point for rubber banding

PUBLIC

   : Construct ( -- )
      FALSE m_bTracking !
      TRUE m_bCaptureEnabled !

      \ Register a WNDCLASS.

      0 \ ClassStyle
      0 IDC_CROSS LoadCursor
      WHITE_BRUSH COMMON GetStockObject  \ ???? WHY COMMON ????
      0 IDI_WINLOGO LoadIcon
      AfxRegisterWndClass

      \ Create a window.

       Z" Mouse Capture Demo (Capture Enabled)"
       WS_OVERLAPPEDWINDOW rectDefault ADDR
       0 0 0 0
       CreateEx DROP ;

PROTECTED

   : InvertLine ( pDC ptFrom ptTo -- )

      \ Invert a line of pixels by drawing a line in the R2_NOT
      \ drawing mode.

      [OBJECTS  CPoint NAMES ptTo  CPoint NAMES ptFrom
                CDC NAMES pDC  OBJECTS]

      R2_NOT pDC SetROP2 >R

      ptFrom ADDR pDC MoveTo DROP
      ptTo ADDR pDC LineTo DROP

      R> pDC SetROP2 DROP ;

   : OnLButtonDown ( nFlags CPoint -- )

      \ Record the anchor point and set the tracking flag.

      USING CPoint Get  2DUP m_ptFrom Set  m_ptTo Set
      TRUE m_bTracking !

      \ If capture is enabled, capture the mouse.

      m_bCaptureEnabled @ IF
         SetCapture DROP
      THEN ;

   : OnMouseMove ( nFlags CPoint -- )

      \ If the mouse is moved while we're "tracking" (that is, while a
      \ line is being rubber-banded), erase the old rubber-band line
      \ and draw a new one.

      [OBJECTS  CPoint NAMES point  CClientDC MAKES dc  OBJECTS]
      m_bTracking @ IF
         dc ADDR m_ptFrom ADDR m_ptTo ADDR InvertLine
         dc ADDR m_ptFrom ADDR point ADDR InvertLine
         point Get m_ptTo Set
      THEN  DROP ;

   : OnLButtonUp ( nFlags CPoint -- )

      \ If the left mouse button is released while we're tracking,
      \ release the mouse if it's currently captured, erase the last
      \ rubber-band line, and draw a thick red line in its place.

      m_bTracking @ IF
         FALSE m_bTracking !
         GetCapture USING CWnd m_hWnd @  m_hWnd @ = IF
            ReleaseCapture DROP  THEN

         [OBJECTS  CPoint NAMES point  CClientDC MAKES dc
                   CPen MAKES pen  OBJECTS]
\         dc ADDR m_ptFrom ADDR m_ptTo ADDR InvertLine

         PS_SOLID 16 RED pen CreatePen DROP
         pen ADDR dc SelectObject DROP

         m_ptFrom ADDR dc MoveTo DROP
         point ADDR dc LineTo DROP
      ELSE  DROP  THEN  DROP ;

   : OnNcLButtonDown ( nHitTest CPoint -- )

      \ When the window's title bar is clicked with the left mouse
      \ button, toggle the capture flag on or off and update the
      \ window title.

      OVER HTCAPTION = IF
         m_bCaptureEnabled @ NOT DUP m_bCaptureEnabled ! IF
            Z" Mouse Capture Demo (Capture Enabled)"
         ELSE
            Z" Mouse Capture Demo (Capture Disabled)"
         THEN  SetWindowText
    THEN ( * SUPER OnNcLButtonDown * )  2DROP Default DROP ;

   : SIGNED ( n16 -- n32 )   [ASM
      $00008000 # EBX TEST  0<> IF
         $FFFF0000 # EBX OR
      THEN  ASM] ;

   : MOUSE-PARAMS ( -- nFlags CPoint )
      WPARAM LPARAM LOWORD SIGNED LPARAM HIWORD SIGNED
      CPoint NEW  DUP >R  USING CPoint Set  R> ;

   WM_LBUTTONDOWN   MESSAGE: ( -- res )   MOUSE-PARAMS DUP >R OnLButtonDown R> COMMON DESTROY 0 ;
   WM_LBUTTONUP     MESSAGE: ( -- res )   MOUSE-PARAMS DUP >R OnLButtonUp R> COMMON DESTROY 0 ;
   WM_MOUSEMOVE     MESSAGE: ( -- res )   MOUSE-PARAMS DUP >R OnMouseMove R> COMMON DESTROY 0 ;
   WM_NCLBUTTONDOWN MESSAGE: ( -- res )   MOUSE-PARAMS DUP >R OnNcLButtonDown R> COMMON DESTROY 0 ;

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

