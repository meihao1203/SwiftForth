{ ====================================================================
SIMPLE Dialog box example

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL SIMPLE A modal dialog template which uses catch/throw.

DIALOG (SIMPLE)  [MODAL  " Press counter"      10   10  160   40
   (FONT 8, MS Sans Serif) ]

\  [control        " default text"     id    xpos ypos xsiz ysiz ]
   [DEFPUSHBUTTON  " OK"               IDOK   105   20   45   15 ]
   [PUSHBUTTON     " Clear"            103     05   20   45   15 ]
   [PUSHBUTTON     " Throw"            104     55   20   45   15 ]
   [RTEXT                              101     05   05   18   10 ]
   [LTEXT          " Total errors"     102     25   05   50   10 ]

END-DIALOG

: SIMPLE-CLOSE ( -- res )   HWND 0 EndDialog ;

VARIABLE PRESSES

: .PRESSES ( -- )   HWND 101 PRESSES @ 0 SetDlgItemInt DROP ;

: THROWING ( -- )   -1 THROW ;

: STUPID ( -- )   ['] THROWING CATCH IF PRESSES ++ .PRESSES THEN ;

[SWITCH SIMPLE-COMMANDS ZERO  ( -- res )
   IDOK     RUN: SIMPLE-CLOSE ;
   IDCANCEL RUN: SIMPLE-CLOSE ;
   103      RUN: PRESSES OFF  .PRESSES 0 ;
   104      RUN: STUPID 0 ;
SWITCH]

[SWITCH SIMPLE-MESSAGES ZERO
   WM_CLOSE      RUNS SIMPLE-CLOSE
   WM_INITDIALOG RUN: ( -- res )   0 PRESSES !  .PRESSES  -1 ;
   WM_COMMAND    RUN: ( -- res )   WPARAM LOWORD SIMPLE-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD SIMPLE-MESSAGES ;  4 CB: RUNSIMPLE

: SIMPLE
   HINST  (SIMPLE)  HWND  RUNSIMPLE  0  DialogBoxIndirectParam DROP ;

CR CR .( Type SIMPLE to run the dialog sample.) CR CR
