OPTIONAL CSCRIBBLE A class-based connect-the-dots demo from Petzold

\ Modeled after the SCRIBBLE.C program in Petzold 2nd Edition.

REQUIRES CWinApp
REQUIRES CFrameWnd
REQUIRES CPaintDC

CFrameWnd SUBCLASS CMainWindow

PUBLIC

100 CONSTANT #POINTS

VARIABLE POINT#

#POINTS CPoint BUILDS[] POINTS[]

\ --- ; process WM_PAINT message

: DOPAINT ( -- res )
   POINT# @ 1 > IF
      [OBJECTS  CPaintDC MAKES pdc  OBJECTS]
      POINT# @ 1- 0 DO
         POINT# @ 1 DO
            J POINTS[] ADDR pdc MoveTo DROP
            I POINTS[] ADDR pdc LineTo DROP
         LOOP
      LOOP
   ELSE  Default DROP
   THEN  0 ;

: DOPRESS ( -- res )
   POINT# @ #POINTS < IF
      LPARAM HILO SWAP POINT# @ POINTS[] Set
      1 POINT# +!
   THEN 0 ;

: DOREPAINT ( -- res )   TRUE Invalidate 0 ;

   WM_PAINT       MESSAGE: ( -- res )   DOPAINT ;
   WM_LBUTTONDOWN MESSAGE: ( -- res )   DOPRESS ;
   WM_LBUTTONUP   MESSAGE: ( -- res )   DOREPAINT ;
   WM_SIZE        MESSAGE: ( -- res )   DOREPAINT ;

: PreCreateWindow ( aCREATESTRUCT -- flag )
   [OBJECTS  CREATESTRUCT NAMES cs  OBJECTS]
   300 cs cx !  200 cs cy !
   100 cs x !  100 cs y !
   TRUE ;

: Construct ( -- )
   m_hWnd @ ?EXIT  0 POINT# !

      \ Register a WNDCLASS.

      0 \ ClassStyle
      0 IDC_CROSS COMMON LoadCursor
      WHITE_BRUSH COMMON GetStockObject
      0 IDI_WINLOGO LoadIcon
      AfxRegisterWndClass

      \ Create a window.

       Z" SwiftForth Scribble Demo"
       WS_OVERLAPPEDWINDOW WS_CAPTION OR rectDefault ADDR
       0 0 0 0
       CreateEx DROP

   m_hWnd @ IF  HWND_NOTOPMOST  100 100 300 200
      SWP_SHOWWINDOW SetWindowPos DROP
   THEN ;

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

CR CR .( Type DEMO to start, then click mouse in Scribble window.) CR

