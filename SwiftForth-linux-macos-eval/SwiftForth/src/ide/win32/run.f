{ ====================================================================
run.f
Simple RUN dialog

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

PACKAGE EXTERNAL-APPLICATION

100 ENUM RUN_TEXT
    ENUM RUN_BROWSE
    ENUM RUN_NAME
DROP

DIALOG (RUN)
   [MODAL " Run program"  10 10 200 60  (FONT 8, MS Sans Serif) ]

   [EDITTEXT                 RUN_TEXT    30 20 160 12 (+STYLE ES_AUTOHSCROLL WS_TABSTOP) ]
   [PUSHBUTTON    " OK"      IDOK        30 40  50 16 ]
   [PUSHBUTTON    " Cancel"  IDCANCEL    85 40  50 16 ]
   [PUSHBUTTON    " Browse"  RUN_BROWSE 140 40  50 16 ]
   [LTEXT         " &Run"    RUN_NAME     8 22  18 12 ]
   [CTEXT         " Type the name of a program to execute it" -1 0 4 200 12 ]

END-DIALOG

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: RUN-BROWSE ( -- )
   CHOOSE-PROGRAM-FILE DUP IF
      HWND RUN_TEXT ROT SetDlgItemText
   THEN DROP 0 ;

: RUN-CLOSE ( -- res )
   HWND 0 EndDialog DROP 0 ;

: RUN-OK ( -- res )
   HWND RUN_TEXT HERE 255 GetDlgItemText IF
      HERE >PROCESS DROP
   THEN  RUN-CLOSE ;

[SWITCH RUN-COMMANDS ZERO
   RUN_BROWSE RUNS RUN-BROWSE
   IDOK       RUNS RUN-OK
   IDCANCEL   RUNS RUN-CLOSE
SWITCH]

[SWITCH RUN-MESSAGES ZERO
   WM_CLOSE      RUNS RUN-CLOSE
   WM_INITDIALOG RUN: HWND RUN_TEXT GetDlgItem SetFocus DROP 0 ;
   WM_COMMAND    RUN: WPARAM LOWORD RUN-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD RUN-MESSAGES ;  4 CB: RUNNER

PUBLIC

: RUN ( -- )
   HINST (RUN)  HWND  RUNNER  0  DialogBoxIndirectParam DROP ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS 
   MI_RUN         RUNS RUN
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE

