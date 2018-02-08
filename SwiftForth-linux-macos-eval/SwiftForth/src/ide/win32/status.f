{ ====================================================================
status.f
multipart status bar

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

?( Simple status bar class)

SIMPLEWINCLASS SUBCLASS STATUS-BAR

   0 WS_CHILD OR
     WS_VISIBLE OR
     WS_CLIPSIBLINGS OR
     CCS_BOTTOM OR
   CONSTANT STYLE

   VARIABLE PARTS

   : CREATE-STATUSBAR ( owner -- )   OWNER !
      STYLE Z" Status" OWNER @ 2 CreateStatusWindow  HANDLE ! ;

   : TYPE ( addr n -- )   R-BUF  R@ ZPLACE
      HANDLE @ SB_SETTEXTA 0 R> SendMessage DROP ;

END-CLASS

{ --------------------------------------------------------------------
Swift-Bar is a specialized subclass of the status bar. It subclasses
the normal status bar callback and replaces it with a single instance
custom callback which deals with mouse clicks on the bar.
-------------------------------------------------------------------- }

STATUS-BAR SUBCLASS SWIFT-BAR            \ custom 6-part status bar

   6 CONSTANT PARTS                     \ 6 panes 0..5

   PARTS CELLS BUFFER: PANEMAP          \ pixel counts for resize

   CREATE PANES                         \ pane 0 is floating size
      -1 , 3 , 15 , 15 , 3 , 3 ,        \ others are in characters

   : CHAR-WIDTH ( -- n )
      [OBJECTS TEXTMETRIC MAKES TM OBJECTS]
      HANDLE @ GetDC DUP DC !
      HANDLE @ WM_GETFONT 0 0 SendMessage
      SelectObject >R
      DC @ TM ADDR GetTextMetrics DROP  TM AveCharWidth @
      DC @ R> SelectObject DROP
      HANDLE @ DC @ ReleaseDC DROP ;

   : PANEW ( n -- width )
      CELLS PANES + @  1+ CHAR-WIDTH *  ;

   : PANESIZE ( n -- addr )
      CELLS PANEMAP + ;

   RECT BUILDS BORDERS

   : GET-BORDERS ( -- addr )
      HANDLE @ SB_GETBORDERS 0 BORDERS ADDR SendMessage  DROP
      BORDERS ADDR ;

   : HBORDER   ( -- n )   GET-BORDERS @ ;               \ horizontal border
   : SEPARATOR ( -- n )   GET-BORDERS 2 CELLS + @ ;     \ separator

   : DIVIDES ( -- )                     \ create multiple panes
      HANDLE @ CLIENT-WIDTH  HBORDER -  \ area to divide
      1 PARTS 1- 1 MAX DO               \ right edge
         DUP I PANESIZE !
         I PANEW -  SEPARATOR - 0 MAX
      -1 +LOOP    0 MAX  0 PANESIZE !
      HANDLE @ SB_SETPARTS PARTS PANEMAP SendMessage DROP ;

   : RESIZE ( -- )
      SUPER RESIZE  DIVIDES ;

   : PANE-TYPE ( addr n pane -- )   -ROT R-BUF  R@ ZPLACE
      HANDLE @ SB_SETTEXTA ROT R> SendMessage DROP ;

   : PANE-WIDTH ( n -- chars )   4 CELLS R-ALLOC >R
      HANDLE @ SB_GETRECT ROT R@ SendMessage DROP
      R> @RECT ( x y x y) ROT 2DROP SWAP -  CHAR-WIDTH / 1- 0 MAX ;

   : RIGHTMOST ( addr n n -- addr n )
      2DUP U< IF DROP ELSE OVER SWAP - /STRING THEN 0 MAX 255 MIN ;

   : PANE-RIGHT ( addr n pane -- )
      DUP >R  PANE-WIDTH  RIGHTMOST  R> PANE-TYPE ;


   \ only performs a test

   : HIT ( mousex -- part )
      0  PARTS 0 DO ( mousex left)
         OVER SWAP I PANESIZE @ WITHIN IF
            DROP I CELLS UNLOOP EXIT THEN
         I PANESIZE @
      LOOP 2DROP -1 ;

   : HIT-VECTOR ( addr -- )
      LPARAM LOWORD HIT  DUP 0< IF  2DROP EXIT  THEN  + @EXECUTE ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

SWIFT-BAR BUILDS SF-STATUS

\ compatability to old swiftforth
\ must match the number of parts specified in the class!
\ this is a bad dependency, but ...

CREATE SBRHITS   0 , 0 , 0 , 0 , 0 , 0 ,        \ xts for right button hits
CREATE SBLHITS   0 , 0 , 0 , 0 , 0 , 0 ,        \ xts for left button hits

: SBLEFT ( n -- a )   CELLS SBLHITS + ;
: SBRIGHT ( n -- a )   CELLS SBRHITS + ;

: LEFTHIT  ( -- res )   SBLHITS SF-STATUS HIT-VECTOR 0 ;
: RIGHTHIT ( -- res )   SBRHITS SF-STATUS HIT-VECTOR 0 ;

: .SPART ( zstr pane -- )   SWAP ZCOUNT ROT SF-STATUS PANE-TYPE ;

{ --------------------------------------------------------------------
callback processing for subclass
-------------------------------------------------------------------- }

PACKAGE STATUS-TOOLS

0 VALUE OLDSBARPROC            \ address of old status bar winproc

: DEFSBPROC ( n -- res )
   DROP OLDSBARPROC HWND MSG WPARAM LPARAM CallWindowProc ;

[SWITCH SBAR-MESSAGES DEFSBPROC
   WM_LBUTTONDOWN RUNS LEFTHIT
   WM_RBUTTONDOWN RUNS RIGHTHIT
SWITCH]

:NONAME ( -- res )   MSG LOWORD SBAR-MESSAGES ;  4 CB: SBARPROC

: CONSTRUCT-SF-STATUSBAR ( -- )
   HWND SF-STATUS CREATE-STATUSBAR
   SF-STATUS HANDLE @ GWL_WNDPROC SBARPROC SetWindowLong TO OLDSBARPROC ;

PRINTSTACK BUILDS PSTK

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: SB.BASE  ( -- )   BASE @ PSTK (.BASE)  1 SF-STATUS PANE-TYPE ;

: SB.STACK ( -- )   PSTK Z(.S) ZCOUNT 0 SF-STATUS PANE-RIGHT ;

: STATUS.STACK ( -- )    SB.BASE  SB.STACK ;

: +BASE ( -- )
   OPERATOR BASE HIS @ CASE
      10 OF 16 ENDOF
      16 OF  8 ENDOF
       8 OF  2 ENDOF
     DUP OF 10 ENDOF
   ENDCASE
   DUP  OPERATOR BASE HIS !
   PSTK (.BASE)  1 SF-STATUS PANE-TYPE ;

' +BASE SBLHITS CELL+ !

END-PACKAGE


