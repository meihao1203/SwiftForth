{ ====================================================================
guitetris.f
(C) Copyright 1972-1998 FORTH, Inc.

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

INCLUDE TEXTTETRIS
INCLUDE MMPLAY

{ --------------------------------------------------------------------
Define a dialog window for tetris

IDBEGIN is an identifier for the only control the dialog has.

AppName is an ascii z string which represents the class name.

(TETRIS) is the defined dialog for the game.
-------------------------------------------------------------------- }

100 ENUM IDBEGIN
    ENUM IDPAUSE
    ENUM IDPREV
    ENUM IDSOUND
    DROP

: AppName ( -- z )   Z" Tetris" ;

DIALOG (TETRIS)
   [MODELESS " Tetris" 10 10 240 300
      (CLASS Tetris) (FONT 8, MS Sans Serif) ]

   [PUSHBUTTON    " Preview"       IDPREV  180 130  35 13 ]
   [PUSHBUTTON    " Loud"          IDSOUND 180 150  35 13 ]
   [PUSHBUTTON    " Start"         IDBEGIN 180 170  35 13 ]
   [PUSHBUTTON    " Pause"         IDPAUSE 180 190  35 13 ]

END-DIALOG

{ --------------------------------------------------------------------
TETRIS-MESSAGES is the default message handler for TETRIS. Defined
   here so the class registration can reference it.

WNDPROC is the name of the tetris callback.

CREATE-TETRIS-CLASS registers a window class for the game. The
   DLGWINDOWEXTRA field is required because we are using a dialog
   as our basic windows defining tool.

HCLASS is the class handle and
HTETRIS is the window instance handle.

TM_INIT defines a user message to force initialization of the game.

TRY is the entry point for testing the game.
-------------------------------------------------------------------- }

[SWITCH TETRIS-MESSAGES DEFWINPROC ( -- res )
   WM_DESTROY RUN:  0 PostQuitMessage DROP  0 ;
SWITCH]

:NONAME  MSG LOWORD TETRIS-MESSAGES ; 4 CB: WNDPROC

: CREATE-TETRIS-CLASS ( -- hclass )
   0  CS_OWNDC   OR
      CS_HREDRAW OR
      CS_VREDRAW OR                     \ style
      WNDPROC                           \ wndproc
      0                                 \ class extra
      DLGWINDOWEXTRA                    \ window extra
      HINST                             \ hinstance
      0                                 \ icon
      NULL IDC_ARROW LoadCursor         \
      LTGRAY_BRUSH GetStockObject       \
      0                                 \ no menu
      AppName                           \ class name
   DefineClass ;

0 VALUE HCLASS
0 VALUE HTETRIS

WM_USER CONSTANT TM_INIT

: TRY
   CREATE-TETRIS-CLASS TO HCLASS
   HINST (TETRIS) 0 0 0 CreateDialogIndirectParam TO HTETRIS
   HTETRIS SW_NORMAL ShowWindow DROP  HTETRIS UpdateWindow DROP
   HTETRIS TM_INIT 0 0 SendMessage DROP DISPATCHER ;

:PRUNE HCLASS IF AppName HINST UnregisterClass DROP 0 TO HCLASS THEN ;

{ --------------------------------------------------------------------
SQ is the pixel size of the building blocks of tetris bricks.

WIDTH and HEIGHT are the pixel size of the pit.

SQUARE calculates the bounding rectangle for a brick and leaves it
   as a data structure at ADDR.

COLORED assigns a color to the object. Since objects are nominally
   characters per the TETRIS api, this is a simple switch.

HDCDRAW is the device context handle of the window. Since we defined
   the class with CS_OWNDC this value is persistent.

D.OBJECT revectors the TETRIS api .OBJECT to draw graphics objects.
-------------------------------------------------------------------- }

20 VALUE SQ

: WIDTH   WIDE SQ * ;
: HEIGHT  HIGH SQ * ;

: SQUARE ( x y addr -- )
   LOCALS| a y x |
   x SQ * TO x  y SQ * TO y
   a x !+
     y !+
     x SQ + !+
     y SQ + !+ DROP ;

: COLORED ( object -- brush )
   ( object) CASE
      [CHAR] | OF GRAY ENDOF
      [CHAR] - OF GRAY ENDOF
      [CHAR] 1 OF RED  ENDOF
      [CHAR] 2 OF BLUE ENDOF
      [CHAR] 3 OF GREEN ENDOF
      [CHAR] 4 OF CYAN ENDOF
      [CHAR] 5 OF MAGENTA   ENDOF
      [CHAR] 6 OF DARK-GREEN  ENDOF
      [CHAR] 7 OF DARK-CYAN  ENDOF
      [CHAR] Z OF LIGHT-GRAY ENDOF

          DUP  OF WHITE ENDOF
   ENDCASE CreateSolidBrush ;

0 VALUE HDCDRAW

: D.OBJECT ( object x y -- )
   PAD SQUARE
   COLORED ( hbrush)
   HDCDRAW PAD THIRD FillRect DROP
   DeleteObject DROP ;

' D.OBJECT  IS .OBJECT

: D.PREVIEW ( n -- )
   64 * BRICKS +  4 0 DO
      4 0 DO
         COUNT DUP BL = IF DROP [CHAR] Z THEN
         WIDE 2+ I + HIGH 2/ J + D.OBJECT
      LOOP
   LOOP DROP ;

' D.PREVIEW IS .PREVIEW


{ --------------------------------------------------------------------
.CLS vectors to noop here.



-------------------------------------------------------------------- }

' NOOP IS .CLS

0 VALUE TICKER

: KILL-TIMER ( -- )
   TICKER IF HWND 1 KillTimer DROP THEN  0 TO TICKER ;

VARIABLE LASTLEVEL

: D!TICK ( ms -- )
   TICKER 1+ IF
      LASTLEVEL @ LEVEL @ <> IF
         SOUND.THUD  LEVEL @ LASTLEVEL !
      THEN
      HWND 1 ROT 0 SetTimer TO TICKER
   THEN ;

' D!TICK    IS !TICK

: D.REMATCH ( -- flag )
   -1 TO TICKER KILL-TIMER
   HWND Z" Play again?" Z" Game Over" MB_YESNO MB_APPLMODAL OR MessageBox
   IDNO = IF HWND WM_CLOSE 0 0 SendMessage DROP THEN
   0 TO TICKER ;

' D.REMATCH IS .REMATCH


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: POS ( y -- hdc x y )
   HDCDRAW WIDTH SQ + ROT 1+ SQ * ;

: (.STATUS) ( a n value -- a n )
   -ROT PAD PLACE  (.) PAD APPEND  S"      " PAD APPEND  PAD COUNT ;

: (.HIGHSCORE) ( -- a n )
   S" High Score " HIGHEST @ (.STATUS) ;

: (.SCORE) ( -- a n )
   S" Current Score " SCORE @ (.STATUS) ;

: (.LEVEL) ( -- a n )
   S" Level " LEVEL @ (.STATUS) ;

: D.STATUS
   HDCDRAW LIGHT-GRAY SetBkColor DROP
   0 POS S" SwiftForth Tetris" TextOut DROP
   1 POS (.HIGHSCORE) TextOut DROP
   2 POS (.SCORE)     TextOut DROP
   3 POS (.LEVEL)     TextOut DROP ;

' D.STATUS  IS .STATUS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: XY-BUTTON ( x y id -- )
   HWND SWAP GetDlgItem >R
   R@ PAD GetWindowRect DROP
   SWAP SQ *  SWAP SQ *  R> -ROT
      PAD 2 CELLS + 2@ SWAP PAD 2@ SWAP D- 0 MoveWindow DROP ;

: MOVE-BUTTONS ( -- )
   WIDE 1 + HIGH 2- IDBEGIN XY-BUTTON
   WIDE 5 + HIGH 2- IDPAUSE XY-BUTTON
   WIDE 1 + HIGH 4 - IDSOUND XY-BUTTON
   WIDE 5 + HIGH 4 - IDPREV  XY-BUTTON ;


: YSIZE ( -- y )
   HIGH SQ *
   SM_CYMENUSIZE GetSystemMetrics +
   SM_CYCAPTION  GetSystemMetrics +
   SM_CYEDGE   GetSystemMetrics 2* + ;

: XSIZE ( -- x )
   WIDE SQ * 180 100 */
   SM_CXEDGE GetSystemMetrics 2* + ;

CREATE SPOT  4 CELLS ALLOT

: SAVEPOS
   ;

: SIZE-WINDOW
   HWND PAD GetWindowRect DROP
   HWND PAD 2@ SWAP XSIZE YSIZE 1 MoveWindow DROP
   HWND SPOT GetWindowRect DROP
   MOVE-BUTTONS ;

: PAINTPIT
   HWND PAD BeginPaint TO HDCDRAW
   SHOW
   HWND PAD EndPaint DROP ;

[SWITCH D.TRANSLATE ZERO ( wparam -- n )
   VK_UP     RUNS T_TURN
   VK_DOWN   RUNS T_DOWN
   VK_RIGHT  RUNS T_RIGHT
   VK_LEFT   RUNS T_LEFT
   VK_SPACE  RUNS T_BANG
   VK_ESCAPE RUNS T_PLAY
SWITCH]

: KEYSTROKE ( -- key )
   WPARAM LOWORD D.TRANSLATE ;

: PAUSE-GAME ( -- )
   KILL-TIMER HWND IDPAUSE Z" Resume" SetDlgItemText DROP ;

: RESUME-GAME ( -- )
   TOCKS @ !TICK  HWND IDPAUSE Z" Pause" SetDlgItemText DROP ;


: LOUD/QUIET ( -- )
   LOUD IF Z" Quiet" ELSE Z" Loud" THEN
   HWND IDSOUND ROT SetDlgItemText DROP ;

: TETRIS-INIT ( -- )
   HWND GetDC TO HDCDRAW SIZE-WINDOW
   1 LASTLEVEL !  T_PLAY SEND
   PAUSE-GAME 0 TO LOUD LOUD/QUIET ;

: PAUSED ( -- )
   TICKER IF PAUSE-GAME ELSE RESUME-GAME THEN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

[SWITCH TETRIS-COMMANDS ZERO ( wparam -- res )
   IDOK    RUN: HWND WM_CLOSE 0 0 PostMessage DROP
                TICKER KillTimer DROP  0 TO TICKER  0 ;
   IDBEGIN RUN: T_PLAY SEND RESUME-GAME 0 ;
   IDCANCEL RUN: T_DONE SEND 0 ;
   IDPAUSE RUN: PAUSED 0 ;
   IDSOUND RUN: LOUD 0= TO LOUD  LOUD/QUIET 0 ;
SWITCH]

[+SWITCH TETRIS-MESSAGES ( msg -- res )
   WM_COMMAND RUN: HWND SetFocus DROP WPARAM LOWORD TETRIS-COMMANDS ;
   WM_TIMER   RUN: SOUND.TICK T_TICK SEND 0 ;
   WM_CHAR    RUN: SOUND.TICK KEYSTROKE SEND 0 ;
   WM_KEYDOWN RUN: KEYSTROKE SEND 0 ;
   TM_INIT    RUN: TETRIS-INIT 0 ;
   WM_PAINT   RUN: PAINTPIT 0 ;
   WM_CLOSE   RUN: SAVEPOS HWND DestroyWindow DROP ;
SWITCH]


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: TETRIS
   TRY 0 ExitProcess DROP ;

' TETRIS 'MAIN !

: TT   TRY ;
