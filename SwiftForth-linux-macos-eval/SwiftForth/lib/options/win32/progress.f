{ ====================================================================
Progress bar dialog

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL PROGRESS Progress bar dialog

PACKAGE GUI-TOOLS

{ --------------------------------------------------------------------
SIMPLE PROGRESS BAR

Features:

-- With cancel button
-- Either as total number or % start with range, optional string to append
-- Routine to call to update value
-- Title

+PROGRESS starts it with the given title.
-PROGRESS closes the dialog box.

.PROGRESS will update it with a number between 0 and 100.

PROGRESS-NAME changes the title.
PROGRESS-TEXT changes the description.
-------------------------------------------------------------------- }

0 VALUE PBAR
0 VALUE PB

100 ENUM IDPROG
    ENUM IDNAME
DROP

{ --------------------------------------------------------------------
The name, message switch, callback, and class for the dialog.
Note that you must declare DLGWINDOWEXTRA in the window extra field.
-------------------------------------------------------------------- }

CREATE ProgBarName ,Z" ProgBar"

[SWITCH PROGBAR-MESSAGES DEFWINPROC ( -- res )
  SWITCH]

:NONAME  MSG LOWORD PROGBAR-MESSAGES ; 4 CB: RUNPROGBAR

: /PROGBAR-CLASS ( -- hclass )
      0 CS_OWNDC   OR
        CS_HREDRAW OR
        CS_VREDRAW OR                \ class style
      RUNPROGBAR                     \ wndproc
      0                              \ class extra
      DLGWINDOWEXTRA                 \ window extra
      HINST                          \ hinstance
      HINST 101 LoadIcon             \ icon
      NULL IDC_ARROW LoadCursor      \ cursor
      COLOR_BTNFACE 1+               \ background brush
      0                              \ no menu
      ProgBarName                    \ class name
   DefineClass ;

DIALOG (PROGBAR)  [MODELESS  (CLASS ProgBar)  " Progress"
   (FONT 8, MS Sans Serif) (-STYLE WS_SYSMENU)  10 10 200 30 ]

   [LTEXT                           IDNAME       2 20 155 10 ]
   [PROGRESS                        IDPROG       2  5 196 10
                                         (+STYLE PBS_SMOOTH) ]
   [DEFPUSHBUTTON   " Cancel"       IDCANCEL   158 17  40 12 ]

END-DIALOG

: PROGBAR-CLOSE ( -- res )
   0 TO PB  0 TO PBAR   HWND DestroyWindow ;

: PROGBAR-CANCEL
   HWND GetParent WM_BREAK 0 0 PostMessage DROP
   PROGBAR-CLOSE ;

: PROGBAR-INIT ( -- )
   HWND IDPROG GetDlgItem TO PBAR
   HWND LPARAM @ SetWindowText DROP ;

[SWITCH PROGBAR-COMMANDS ZERO ( -- res)
   IDCANCEL  RUN: PROGBAR-CANCEL ;
SWITCH]

[+SWITCH PROGBAR-MESSAGES
   WM_CLOSE          RUNS PROGBAR-CLOSE
   WM_INITDIALOG     RUN: PROGBAR-INIT -1 ;
   WM_COMMAND        RUN: WPARAM LOWORD PROGBAR-COMMANDS ;
SWITCH]

PUBLIC

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: +PROGRESS ( zname -- )
   PB IF DROP EXIT THEN   SP@ >R  /PROGBAR-CLASS DROP
   HINST (PROGBAR)  HWND  RUNPROGBAR  R>  CreateDialogIndirectParam
   DUP TO PB  DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow 2DROP ;

: -PROGRESS ( -- )
   PB IF PB WM_CLOSE 0 0 PostMessage DROP THEN PAUSE ;

: .PROGRESS ( n -- )
   PB IF  PBAR PBM_SETPOS ROT 0 SendMessage THEN DROP PAUSE ;

: PROGRESS-NAME ( z -- )
   PB IF  PB SWAP SetWindowText THEN DROP PAUSE ;

: PROGRESS-TEXT ( z -- )
   PB IF  PB IDNAME ROT SetDlgItemText THEN DROP PAUSE ;

END-PACKAGE

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF]

: TEST ( -- )   z" Test" +PROGRESS
   z" Test text" PROGRESS-TEXT
   100 0 DO  I (.) PAD ZPLACE  S"  Test" PAD ZAPPEND
      PAD PROGRESS-NAME  50 MS I .PROGRESS LOOP
   CR ." Finished"  1000 MS  -PROGRESS ;

TEST

KEY DROP BYE  [THEN]
