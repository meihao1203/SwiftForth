{ ====================================================================
Editor selection dialog

Copyright 2001  FORTH, Inc.
==================================================================== }

PACKAGE FILE-VIEWER

DIALOG (SELED-HELP)

   [MODAL  " Editor Options Help" 40 40 200 110  (FONT 8, MS Sans Serif)]

   [DEFPUSHBUTTON    " &OK"                 IDOK    80 95   40 12 ]

   [TEXTBOX          " Editor options control the format "
                     " of the command sent to the editor. "
                     " %l (percent L) will be replaced by "
                     " the line number and %f (percent F) "
                     " by the filename. Sample strings: "
                     " (copy with mouse if you wish)"

                        -1 5 5 190 40 ]
   [EDITBOX
                     "         E32: -n%l %f"            \n
                     "        ED4W: -1 -n -l %l %f"     \n
                     "       EMACS: +%l %f"             \n
                     "      EmEdit: /l %l %f"           \n
                     "   gnuclient: -F +%l %f"          \n
                     " Komodo Edit: -l %l %f"           \n
                     "   MultiEdit: %f /L%l"            \n
                     "   Notepad++: -n%l %f"            \n
                     "         PFE: /g%l %f"            \n
                     "     TextPad: -am -q %f(%l,0)"    \n
                     "   UltraEdit: %f/%l"              \n
                     "    VIM/GVIM: +%l %f"             \n
                     "     WinEdit: %f /#:%l"
                     199  5 45 190 43
             (+STYLE WS_BORDER WS_VSCROLL) ]

END-DIALOG

: FIX-SAMPLE-FONT
   199 SetDlgItemFixedFont ;

[SWITCH SELED-HELP-COMMANDS ZERO
   IDOK     RUN: HWND 0 EndDialog ;
   IDCANCEL RUN: HWND 0 EndDialog ;
SWITCH]

[SWITCH SELED-HELP-MESSAGES ZERO
   WM_COMMAND RUN: WPARAM LOWORD SELED-HELP-COMMANDS ;
   WM_CLOSE   RUN: HWND 0 EndDialog ;
   WM_INITDIALOG RUN:  FIX-SAMPLE-FONT -1 ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD SELED-HELP-MESSAGES ;  4 CB: RUNSELEDHELP

: SELED-HELP
   HINST (SELED-HELP)  HWND  RUNSELEDHELP  0  DialogBoxIndirectParam DROP ;


{ ------------------------------------------------------------------------
------------------------------------------------------------------------ }


DIALOG (SELED)
   [MODAL  " Select Editor"  10 10 200 85  (FONT 8, MS Sans Serif)]

   [DEFPUSHBUTTON    " &Done"                 IDOK   35 65   40 15 ]
   [PUSHBUTTON       " &Cancel"           IDCANCEL   80 65   40 15 ]
   [PUSHBUTTON       " &Help"                  108  125 65   40 15 ]
   [AUTORADIOBUTTON  " &Notepad"               101    5  5   75 13 ]
   [AUTORADIOBUTTON  " &User Defined"          102    5 15   75 13 ]
   [EDITTEXT                                   103    5 30  140 13 (+STYLE ES_AUTOHSCROLL) ]
   [PUSHBUTTON       " &Browse"                105  150 30   40 15 ]
   [EDITTEXT                                   104    5 45  140 13 (+STYLE ES_AUTOHSCROLL) ]
   [LTEXT            " Editor Options"          -1  150 48   60 13 ]

END-DIALOG

: SELED-CANCEL ( -- res )
   HWND 0 EndDialog ;

: SELED-METHOD
   HWND 101 IsDlgButtonChecked IF ( notepad)
      USE-NOTEPAD ON
      EXIT
   THEN
   HWND 102 IsDlgButtonChecked IF ( external)
      HWND 103 EDITOR-NAME    255 GetDlgItemText DROP
      HWND 104 EDITOR-OPTIONS 255 GetDlgItemText DROP
      USE-NOTEPAD OFF
      EXIT
   THEN
   HWND Z" No editor method selected!" Z" Error!" MB_OK MessageBox DROP ;

: SELED-CLOSE ( -- res )
   SELED-METHOD  SELED-CANCEL ;

: SELED-INIT ( -- )
   103 SetDlgItemFixedFont
   104 SetDlgItemFixedFont
   HWND 103 EDITOR-NAME    SetDlgItemText DROP
   HWND 104 EDITOR-OPTIONS SetDlgItemText DROP
   USE-NOTEPAD? IF 101 ELSE 102 THEN >R
   HWND 100 102 R> CheckRadioButton DROP ;

: SELED-USER-BROWSE ( -- )
   CHOOSE-PROGRAM-FILE DUP IF
      HWND 103 PAD SetDlgItemText
   THEN DROP ;

: SELED-USER ( -- )
   HWND 101 102 102 CheckRadioButton DROP ;

: FOCUS-EDNAME
   HWND 103 GetDlgItem SetFocus DROP ;

CREATE KNOWN-EDITORS
   ," E32"           ,\" -n%l \"%f\""
   ," ED4W"          ,\" -1 -n -l %l \"%f\""
   ," EMACS"         ,\" +%l \"%f\""
   ," EMEDIT"        ,\" /l %l \"%f\""          \ EmEdit
   ," GNUCLIENTW"    ,\" -F +%l \"%f\""         \ emacs front end
   ," KOMODO"        ,\" -l %l \"%f\""          \ Komodo Edit
   ," MEW32"         ,\" \"%f\" /L%l"
   ," NOTEPAD++"     ,\" -n%l \"%f\""           \ Notepad++
   ," PFE32"         ,\" /g%l \"%f\""
   ," TEXTPAD"       ,\" -am -q %f(%l,0)"
   ," TXTPAD32"      ,\" -am -q %f(%l,0)"
   ," UEDIT32"       ,\" %f/%l"                 \ UltraEdit 32-bit version
   ," UEDIT64"       ,\" %f/%l"                 \ UltraEdit 64-bit version
   ," VIM"           ,\" +%l \"%f\""            \ vim and gvim
   ," WINEDIT"       ,\" \"%f\" /#:%l"
   0 ,

: DEFAULT-OPTIONS ( -- )
   HWND 103 PAD 1+ 255 GetDlgItemText PAD C!  PAD COUNT UPCASE
   KNOWN-EDITORS BEGIN
      DUP C@ WHILE
      PAD COUNT THIRD COUNT SEARCH -ROT 2DROP IF
         COUNT + 1+ 1+ HWND 104 ROT SetDlgItemText DROP
         EXIT
      THEN
      COUNT + 1+ COUNT + 1+
   REPEAT DROP ;

: ?UNFOCUS
   WPARAM HIWORD EN_KILLFOCUS = IF DEFAULT-OPTIONS THEN ;

[SWITCH SELED-COMMANDS ZERO
   IDOK     RUN: SELED-CLOSE ;
   IDCANCEL RUN: SELED-CANCEL ;
   102      RUN: DEFAULT-OPTIONS FOCUS-EDNAME 0 ;
   103      RUN: SELED-USER ?UNFOCUS 0 ;
   104      RUN: SELED-USER 0 ;
   105      RUN: SELED-USER-BROWSE DEFAULT-OPTIONS 0 ;
   108      RUN: SELED-HELP 0 ;
SWITCH]

[SWITCH SELED-MESSAGES ZERO
   WM_COMMAND    RUN: ( -- res )   WPARAM LOWORD SELED-COMMANDS ;
   WM_CLOSE      RUN: ( -- res )   SELED-CLOSE ;
   WM_INITDIALOG RUN: ( -- res )   SELED-INIT -1 ;
SWITCH]

:NONAME ( -- res )   MSG $FFFF AND SELED-MESSAGES ;  4 CB: RUNSELED

PUBLIC

: SELED
   HINST (SELED)  HWND  RUNSELED  0  DialogBoxIndirectParam DROP ;

{ --------------------------------------------------------------------
Choose an editor
-------------------------------------------------------------------- }

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_EDITOR    RUNS SELED
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE
