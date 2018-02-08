{ ====================================================================
Simple information presentation window class

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL INFOWIN A listbox control for presenging status.

{ --------------------------------------------------------------------
Simple information window built from a listbox control.
-------------------------------------------------------------------- }

DERIVEDWINDOW SUBCLASS INFOBOX

   0 WS_TABSTOP OR
     WS_CHILD OR
     WS_VISIBLE OR
     LBS_NOINTEGRALHEIGHT OR
     WS_VSCROLL OR
   CONSTANT STYLE

   RECT BUILDS PANE

   : RESIZE ( x y cx cy -- )   PANE ADDR !RECT
      mHWND PANE ADDR @RECT -1 MoveWindow DROP ;

   : MyClass_ClassName ( -- zstr )   Z" LISTBOX" ;
   : MyWindow_ClassName ( -- z )   MyClass_ClassName ;
   : MyWindow_Style ( -- style )   STYLE ;

   : WRITE ( addr len -- )   R-BUF R@ ZPLACE
      mHWND LB_ADDSTRING 0 R> SendMessage DROP
      mHWND LB_GETCOUNT 0 0 SendMessage 500 > IF
         mHWND LB_DELETESTRING 0 0 SendMessage DROP
      THEN
      mHWND LB_GETCOUNT 0 0 SendMessage 1-
      mHWND LB_SETCURSEL ROT 0 SendMessage DROP ;

END-CLASS

{ --------------------------------------------------------------------
Our container window controls the actions of the dialer
-------------------------------------------------------------------- }

GENERICWINDOW SUBCLASS INFOWIN

   INFOBOX BUILDS IFW

   0 WS_OVERLAPPED OR
     WS_CAPTION OR
     WS_THICKFRAME OR
     WS_MINIMIZEBOX OR
     WS_SYSMENU OR
   CONSTANT STYLE

   : RESIZE ( -- )
      [OBJECTS RECT MAKES main OBJECTS]
      mHWND main ADDR GetClientRect DROP
      main ADDR @RECT IFW RESIZE ;

   : MyClass_ClassName ( -- z )   Z" InfoWin" ;
   : MyWindow_WindowName ( -- z )   Z" InfoWin" ;
   : MyWindow_Shape ( -- x y cx cy )   10 10 200 150 ;
   : MyWindow_Style ( -- n )   STYLE ;

   WM_SIZE MESSAGE: ( -- res )   RESIZE 0 ;

   : OnCreate ( -- res )
      mHWND IFW ATTACH  RESIZE 0 ;

   : OnClose ( -- res )   0 ( res)
      mHWND DestroyWindow ;

   : WRITE ( addr len -- )   IFW WRITE ;

END-CLASS

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
\\

INFOWIN BUILDS CONNECTOR

: GO CONNECTOR CONSTRUCT
   20 0 DO
      I (.) CONNECTOR WRITE
   LOOP ;

.(
Type GO to open the info window.
)

