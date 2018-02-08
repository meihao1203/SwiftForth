{ ====================================================================
Simple Windows screen saver demo

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL RNDLINES A simple, incomplete skeleton of a screen saver for Windows

[DEFINED] PROGRAM-SEALED [IF]

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

REQUIRES SCREENSAVER
REQUIRES RND

: LINERATE ( -- zstr )   Z" RndLines" ;

{ --------------------------------------------------------------------
GDI Windows functions
-------------------------------------------------------------------- }

LIBRARY GDI32

FUNCTION: CreatePen ( fnPenStyle nWidth crColor -- h )
FUNCTION: LineTo ( hdc nXEnd nYEnd -- b )
FUNCTION: MoveToEx ( hdc X Y lpPoint -- b )

{ --------------------------------------------------------------------
Line drawing
-------------------------------------------------------------------- }

: DRAWLINE ( x y x y hdc -- )
   DUP 2SWAP 0 MoveToEx DROP  -ROT LineTo DROP ;

CREATE PANE   4 CELLS ALLOT

: ONELINE ( hdc -- )   >R  PANE 2 CELLS +
   @+ DUP RND SWAP RND ( x x)  ROT @ DUP RND SWAP RND ( x x y y)
   -ROT R> DRAWLINE ;

: APEN ( hdc -- holdpen )
   5 RND 16 RND 20 RND $1000000 OR CreatePen
   SelectObject ;

: RNDLINE ( hwnd -- )   LOCALS| hscr |
   hscr GetDC >R
   hscr PANE GetClientRect DROP
   R@ APEN ( holdpen)
   R@ ONELINE
   R@ SWAP ( holdpen) SelectObject DeleteObject DROP
   hscr R> ReleaseDC DROP ;

{ --------------------------------------------------------------------
Saver configuration
-------------------------------------------------------------------- }

0 VALUE hTRACKBAR

DIALOG (CONFIG)
   [MODAL " Options for RNDLINES" 10 10 160 60
   (FONT 8, MS Sans Serif) ]

\  [control        " default text"     id      xpos ypos xsiz ysiz ]
   [DEFPUSHBUTTON  " OK"               IDOK     105   10   45   15 ]
   [PUSHBUTTON     " Cancel"           IDCANCEL 105   30   45   15 ]
   [TRACKBAR                           100        6   12   85   20 (+STYLE TBS_AUTOTICKS)  ]
   [GROUPBOX       " Update interval"  -1         2    2   94   35 ]
   [RTEXT                              101        5   45   30   15 ]
   [LTEXT          " ms"               -1        37   45   20   15 ]
END-DIALOG

: @TRACK ( -- n )
   hTRACKBAR TBM_GETPOS 0 0 SendMessage  ;

: QUERYTRACK ( -- )
   @TRACK  1 MAX 100 MIN  HWND 101 ROT 0 SetDlgItemInt DROP ;

: CONFIG-CLOSE ( -- res )
   HWND 0 EndDialog ;

: CONFIG-SAVE ( -- res )
   @TRACK LINERATE REG! CONFIG-CLOSE ;

: CONFIG-INIT ( -- )
   HWND 100 GetDlgItem TO hTRACKBAR
   hTRACKBAR TBM_SETRANGE 1  100 >H< 0 OR  SendMessage DROP
   hTRACKBAR TBM_SETTICFREQ 10 1 SendMessage DROP
   hTRACKBAR TBM_SETPOS 1 LINERATE REG@ SendMessage DROP
   QUERYTRACK ;

[SWITCH CONFIG-COMMANDS ZERO  ( -- res )
   IDOK     RUN: CONFIG-SAVE ;
   IDCANCEL RUN: CONFIG-CLOSE ;
SWITCH]

[SWITCH CONFIG-MESSAGES ZERO ( -- res )
   WM_CLOSE      RUNS CONFIG-CLOSE
   WM_INITDIALOG RUN: CONFIG-INIT  -1 ;
   WM_COMMAND    RUN: WPARAM LOWORD CONFIG-COMMANDS ;
   WM_HSCROLL    RUN: LPARAM hTRACKBAR = IF QUERYTRACK THEN 0 ;
SWITCH]

:NONAME ( -- res )   MSG $FFFF AND CONFIG-MESSAGES ;  4 CB: RUNCONFIG

: CONFIG ( hparent -- )
   DUP 0= IF DROP GetForegroundWindow THEN
   HINST  (CONFIG)  ROT  RUNCONFIG  0  DialogBoxIndirectParam ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

' RNDLINE  IS DOSAVER
' CONFIG   IS DOCONFIG
' LINERATE IS SAVERRATE


PROGRAM-SEALED RNDLINES.SCR

CR
CR .( Screen saver example compiled and saved as RNDLINES.SCR)
CR
CR .( Press return to stay in forth... )
CR

KEY 13 <> [IF] BYE [THEN]

[ELSE]

CR
.( This demo is not available for the SwiftForth Evaluation version)
CR

[THEN]
