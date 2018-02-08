OPTIONAL CWND The SFC window class.

{ ====================================================================
CWnd provides the base functionality of all window classes.

Copyright (c) 1972-1999, FORTH, Inc.

The CWnd class provides the base functionality of all window classes
in the Swift Foundation Class Library.

Requires: CCmdTarget

Exports: see MFC documentation

==================================================================== }

REQUIRES CCmdTarget

7 IMPORT: SetWindowPos

: AfxRegisterClassEx ( lpWndClass -- flag )   RegisterClassEx 0<> ;

CREATE SfcClass   ,Z" SFC00000000"

: SfcClassName ( a -- lpszClassName )
   0 SWAP WNDCLASS SIZEOF BOUNDS DO
      8 M* +  I C@ +
   LOOP  8 (H.0)  SfcClass 3 + SWAP MOVE
   SfcClass ;

: AfxRegisterWndClassEx ( nClassStyle hCursor hbrBackground
                        hLIcon hSIcon -- lpszClassName )
   [OBJECTS  WNDCLASSEX MAKES wc  OBJECTS]
   CLASS-CALLBACK wc WndProc !  HINST wc Instance !
   0 wc ClsExtra !  0 wc WndExtra !  0 wc MenuName !
   wc IconSm !  wc Icon !  wc Background !  wc Cursor !  wc style !
   SfcClass wc ClassName !  wc ADDR AfxRegisterClassEx 0= IF
      GetLastError  DUP ERROR_SUCCESS <>
      SWAP ERROR_CLASS_ALREADY_EXISTS <> AND  IF
         GetLastError Z" RegisterClass" LAST-ERROR-ALERT
         IOR_REGISTERCLASS THROW
   THEN  THEN  SfcClass ;

: AfxRegisterWndClass ( nClassStyle hCursor hbrBackground
                        hIcon -- lpszClassName )
   0 AfxRegisterWndClassEx ;

CLASS CREATESTRUCT
   VARIABLE CreateParams
   VARIABLE Instance
   VARIABLE Menu
   VARIABLE Parent
   VARIABLE cy
   VARIABLE cx
   VARIABLE y
   VARIABLE x
   VARIABLE Style
   VARIABLE Name
   VARIABLE Class
   VARIABLE ExStyle
END-CLASS

CLASS tagMSG
   VARIABLE hwnd
   VARIABLE message
   VARIABLE wParam
   VARIABLE lParam
   VARIABLE time
   POINT BUILDS pt
END-CLASS

CCmdTarget BUILDS CWndTemp   2 CELLS ALLOT

CCmdTarget SUBCLASS CWnd

PUBLIC

\ Data Memebers
   VARIABLE m_hCommandBarMenu
   VARIABLE m_hWnd

\ Construction/Destruction
   : DestroyWindow ( -- flag )   m_hWnd @ WM_CLOSE 0 0 SendMessage ;

\ Initialization
   DEFER: PreCreateWindow ( aCREATESTRUCT -- flag )   DROP TRUE ;

   : CreateEx ( dwExStyle lpszClassName lpszWindowName dwStyle
                rect pParentWnd nID lpParam -- flag )
      >R 2>R  @+ SWAP @+ SWAP @+ SWAP @+ NIP  2R> HINST R>
      SP@ PreCreateWindow IF
         >R SELF >R  RP@ COMMON CreateWindowEx  2R> 2DROP
      ELSE 0 THEN  DUP m_hWnd ! ;

   : Attach ( handle -- )   m_hWnd ! ;
   : Detach ( -- handle )   m_hWnd @  0 m_hWnd ! ;

\ Window State Functions
   : GetCapture ( -- CWnd )   COMMON GetCapture
      CWndTemp ADDR  CCmdTarget SIZEOF CELL+ + !
      CWndTemp ADDR ;

   : SetCapture ( -- CWnd )   m_hWnd @ COMMON SetCapture
      CWndTemp ADDR  CCmdTarget SIZEOF CELL+ + !
      CWndTemp ADDR ;

\ Window Size and Position

   : SetWindowPos ( pWndInsertAfter x y cx cy nFlags -- flag )
      m_hWnd @ 6 -ROLL COMMON SetWindowPos ;

   : GetClientRect ( lpRect -- )
      m_hWnd @ SWAP COMMON GetClientRect DROP ;

\ Window Access Functions

\ Update/Painting Functions
   : BeginPaint ( lpPaint -- CDC )   m_hWnd @ SWAP COMMON BeginPaint ;

   : EndPaint ( lpPaint -- )   m_hWnd @ SWAP COMMON EndPaint DROP ;

   : GetDC ( -- CDC )   N/I ;

   : ReleaseDC ( CDC -- )   N/I ;

   : UpdateWindow ( -- )   m_hWnd @ UpdateWindow DROP ;

   : Invalidate ( bErase -- )   m_hWnd @ 0 ROT InvalidateRect DROP ;

   : ShowWindow ( nCmdShow -- flag )   m_hWnd @ SWAP ShowWindow ;

\ Coordinate Mapping Functions

\ Window Text Functions
   : SetWindowText ( lpszString -- )
      m_hWnd @ SWAP COMMON SetWindowText DROP ;

\ Scrolling Functions

\ Drag-Drop Functions

\ Caret Functions

\ Dialog-Box Item Functions

\ Data-Binding Functions

\ Menu Functions

\ ToolTip Functions

\ Timer Functions

   : SetTimer ( IDEvent Elapse Callback -- IDEvent'|0 )
      m_hWnd @ 3 -ROLL COMMON SetTimer ;

   : KillTimer ( IDEvent -- ior )   m_hWnd @ SWAP COMMON KillTimer ;

\ Alert Functions

   : MessageBox ( lpszText lpszCaption nType -- n )
      m_hWnd @ 3 -ROLL MessageBox ;

\ Window Message Functions

   : Default ( -- lResult )   HWND MSG WPARAM LPARAM DefWindowProc ;

   DEFER: PreTranslateMessage ( pMsg -- flag )   DROP FALSE ;

   : SendMessage ( message wParam lParam -- lResult )
      m_hWnd @ 3 -ROLL COMMON SendMessage ;

   : PostMessage ( message wParam lParam -- flag )
      m_hWnd @ 3 -ROLL COMMON PostMessage ;

\ Clipboard Functions

\ OLE Controls

\ Overridables

   DEFER: DefWindowProc ( message wParam lParam -- lResult )
      m_hWnd @ 3 -ROLL DefWindowProc ;

\ Initialization Message Handlers

\ System Message Handlers

\ General Message Handlers

   DEFER: OnClose ( -- )   Default ;

   WM_CLOSE MESSAGE: ( -- res )   OnClose 0 ;

   WM_NCDESTROY MESSAGE: ( -- res )   0 m_hWnd !  Default  0 ;

\ Control Message Handlers

\ Input Message Handlers

\ Nonclient-Area Message Handlers

\ MDI Message Handlers

\ Clipboard Message Handlers

\ Menu Loop Notification

   : Construct ( -- )   \ m_hWnd @ ?EXIT
\      CreateEx DUP m_hWnd !  DUP IF
\         DUP SW_NORMAL ShowWindow DROP
\         UpdateWindow DROP
\      THEN
;

   DEFER: Destroy ( -- )  DestroyWindow DROP ;

END-CLASS

