{ ====================================================================
Single and multi-part status lines

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL STATUSLINE Single and multi-part status lines for SWOOP

DERIVEDWINDOW SUBCLASS SIMPLESTAT

   0 WS_CHILD OR
     WS_VISIBLE OR
     WS_CLIPSIBLINGS OR
     CCS_BOTTOM OR
   CONSTANT STYLE

   : MyWindow_Style        STYLE ;
   : MyWindow_ClassName    Z" msctls_statusbar32" ;
   : MyWindow_WindowName   0 ;

   : HIGH ( -- n )
      [OBJECTS RECT MAKES AREA OBJECTS]
      mHWND AREA ADDR GetWindowRect DROP
      AREA bottom @ AREA top @ - ;

   : FIXED-FONT ( -- )
      mHWND WM_SETFONT ANSI_FIXED_FONT GetStockObject 1
      SendMessage DROP ;

   : ZTYPE ( z -- )
      >R mHWND SB_SETTEXTA 255 R> SendMessage DROP ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

SIMPLESTAT SUBCLASS MULTISTAT

   5 CONSTANT PARTS

   CREATE PANEMAP
     50 , 100 , 250 , 525 , -1 ,

   : DIVIDES ( -- )                     \ create multiple panes
      mHWND SB_SETPARTS PARTS PANEMAP SendMessage DROP ;

   : PostConstruct ( -- )   DIVIDES ;

   : PANE-TYPE ( addr n pane -- )   -ROT R-BUF  S"  " R@ ZPLACE
      R@ ZAPPEND    mHWND SB_SETTEXTA ROT R> SendMessage DROP ;

END-CLASS

\\

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
\ how to use a global entry to display status

0 VALUE oSTAT

: PANE-TYPE ( addr n pane -- )
   oSTAT [OBJECTS MULTISTAT NAMES STAT OBJECTS]
   STAT PANE-TYPE ;
