{ ====================================================================
commandhistory.f
A command-line history control

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

/FORTH DECIMAL

PACKAGE COMMAND-HISTORY

{ --------------------------------------------------------------------
The name, message switch, callback, and class for the dialog.
Note that you must declare DLGWINDOWEXTRA in the window extra field.
-------------------------------------------------------------------- }

CREATE HistoryClass ,Z" HistoryClass"

[SWITCH HISTORY-MESSAGES DEFWINPROC ( -- res )   SWITCH]

:NONAME  MSG LOWORD HISTORY-MESSAGES ; 4 CB: RUNHISTORY

: /HISTORY-CLASS ( -- hclass )
      0 CS_OWNDC   OR
      RUNHISTORY                      \ wndproc
      0                              \ class extra
      DLGWINDOWEXTRA                 \ window extra
      HINST                          \ hinstance
      HINST 101 LoadIcon             \ icon
      NULL IDC_ARROW LoadCursor      \ cursor
      COLOR_BTNFACE 1+               \ background brush
      0                              \ no menu
      HistoryClass                    \ class name
   DefineClass ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

DIALOG (HISTORY)
   [MODELESS  " History"  10 10 200 120
      (CLASS HistoryClass) (+STYLE WS_THICKFRAME) (-STYLE WS_VISIBLE) ]

   [EDITBOX 100 2 2 200 160 (+STYLE ES_WANTRETURN WS_VSCROLL WS_HSCROLL) ]
END-DIALOG

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

0 VALUE HEDIT

CREATE HISTORYORG  5 CELLS /ALLOT

CONFIG: HISTORY-WINDOW ( -- addr len )   HISTORYORG 5 CELLS ;

: TOEND ( -- )
   HEDIT EM_SETSEL $7FFF $7FFF SendMessage DROP
   HEDIT EM_SCROLLCARET 0 0 SendMessage  DROP ;

: HISTORY-CLOSE ( -- res )
   HISTORYORG OFF   HWND SW_HIDE ShowWindow DROP  -1 ;

: TRACK-SIZE ( x y -- )   2>R
   HEDIT 0 0 2R> 1 MoveWindow DROP ;

: DUP-FONT ( -- )
   OPERATOR'S PHANDLE TtyGetfont >R
   HEDIT WM_SETFONT R> -1 SendMessage DROP ;

: HISTORY-INIT ( -- -1 )
   HISTORYORG 3 CELLS + 2@ OR IF
      HISTORYORG CELL+ RESTOREWINDOWPOS THEN
   HWND 100 GetDlgItem TO HEDIT
   HWND PAD GetClientRect DROP  PAD CELL+ CELL+ 2@ SWAP TRACK-SIZE
   DUP-FONT  TOEND  -1 ;

: KEEP-POS ( -- res )   HISTORYORG @+ IF SAVEWINDOWPOS THEN ;

: HISTORY-RESHOW ( -- )
   WPARAM IF ( show) HISTORYORG CELL+ RESTOREWINDOWPOS
      HISTORYORG ON
   ELSE HISTORYORG OFF THEN
   REBUTTON ;

[+SWITCH HISTORY-MESSAGES ( -- res )
   WM_CLOSE      RUNS HISTORY-CLOSE
   WM_INITDIALOG RUNS HISTORY-INIT
   WM_MOVE       RUN: KEEP-POS ;
   WM_SIZE       RUN: LPARAM LOHI TRACK-SIZE KEEP-POS ;
   WM_SHOWWINDOW RUN: HISTORY-RESHOW ;
   WM_SETFOCUS   RUN: HEDIT SetFocus ;
SWITCH]

: /HISTORY ( -- )
   /HISTORY-CLASS DROP
   GetForegroundWindow >R
   HISTORYORG @ >R  HISTORYORG OFF
   HINST (HISTORY) 0 RUNHISTORY 0  CreateDialogIndirectParam
   (HISTORY) CELL- !
   R> HISTORYORG !
   R> SetForegroundWindow DROP ;

: HISTORY/ ( -- )
   (HISTORY) CELL- @ ?DUP IF  WM_CLOSE 0 0 SendMessage DROP
   THEN  HistoryClass HINST UnregisterClass DROP ;

PUBLIC

: HISTORY ( -- )   (HISTORY) CELL- @
   DUP SW_SHOWDEFAULT ShowWindow DROP UpdateWindow DROP ;

: HIDE-HISTORY ( -- )
   (HISTORY) CELL- @ WM_CLOSE 0 0 SendMessage DROP ;

:ONENVLOAD ( -- )   /HISTORY  HISTORYORG @ IF HISTORY THEN ;
:ONENVEXIT ( -- )   HISTORY/ ;

PRIVATE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: KILL-4K ( -- )
   HEDIT EM_SETSEL 0 $1000 SendMessage DROP
   HEDIT EM_REPLACESEL 0 Z\" <previous data lost>\n" SendMessage DROP
   TOEND ;

: HISTLENGTH ( -- n )
   TOEND  HEDIT EM_GETSEL 0 0 SendMessage LOWORD ;

: ?HISTFULL ( -- )
   HISTLENGTH 25000 > IF KILL-4K THEN ;

: SENDTEXT ( zaddr -- )   >R  ?HISTFULL ( moves to end)
   HEDIT EM_REPLACESEL 0 R> SendMessage DROP
   HEDIT EM_SCROLLCARET 0 0 SendMessage DROP ;

PRIVATE

: SAVE-STRING ( addr n -- )
   ?DUP IF  R-BUF  R@ ZPLACE  <EOL> COUNT R@ ZAPPEND
   R> SENDTEXT EXIT  THEN DROP ;

ACCEPTOR +ORDER

' SAVE-STRING IS >HISTORY

ACCEPTOR -ORDER

CONSOLE-WINDOW +ORDER

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

[DEFINED] COMMAND-HISTORY [IF]

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_HISTORY     RUN: HISTORYORG @ IF HIDE-HISTORY ELSE HISTORY THEN ;
SWITCH]

END-PACKAGE
