{ ====================================================================
System options dialog box

Copyright 2001  FORTH, Inc.
Rick VanNorman

==================================================================== }

PACKAGE PREFS-DIALOG

{ ------------------------------------------------------------------------
Tools to build the dialog with... Nice if I could kill them later!

------------------------------------------------------------------------ }

2VARIABLE <BOX>

: ~BOX ( id -- id x y n n )
   DUP 100 MOD   4 /MOD >R
   2 /MOD  SWAP 12 * 10 + R> 70 * +  SWAP 12 * 15 +
   2DUP <BOX> 2!  8 8 ;

: ~TEXT ( -- id x y n n )
   -1  <BOX> 2@  25 0 D+  40 10 ;

{ ------------------------------------------------------------------------
------------------------------------------------------------------------ }

DIALOG (PREFS)
   [MODAL " SwiftForth Preferences"  10 10 150 105  (FONT 8, MS Sans Serif) ]

   [DEFPUSHBUTTON   " OK"                      IDOK    6  90  30 12 ]
   [PUSHBUTTON      " Apply"                     99   42  90  30 12 ]
   [PUSHBUTTON      " Reset"                     98   78  90  30 12 ]
   [PUSHBUTTON      " Cancel"              IDCANCEL  114  90  30 12 ]

   [AUTOCHECKBOX    " Use coloring for &WORDS"  204   10 45 120 10 ]
   [AUTOCHECKBOX    " &Flat toolbar buttons"    220   10 55 120 10 ]
   [AUTOCHECKBOX    " &Large toolbar buttons"   221   10 65 120 10 ]
   [AUTOCHECKBOX    " &Pause while scrolling"   205   10 75 120 10 ]

   [DRAWNBUTTON  100 ~BOX ] [LTEXT  " Normal"  ~TEXT ]
   [DRAWNBUTTON  101 ~BOX ]
   [DRAWNBUTTON  102 ~BOX ] [LTEXT  " Inverse" ~TEXT ]
   [DRAWNBUTTON  103 ~BOX ]
   [DRAWNBUTTON  104 ~BOX ] [LTEXT  " Bold"    ~TEXT ]
   [DRAWNBUTTON  105 ~BOX ]
   [DRAWNBUTTON  106 ~BOX ] [LTEXT  " Bright"  ~TEXT ]
   [DRAWNBUTTON  107 ~BOX ]

   [GROUPBOX   " Colors (Text/Background)"     -1    5  3 140 38  ]

{ ------------------------------------------------------------------------
Working storage for the dialog, including saving the original
settings for RESET.

In the 2VARIABLES, the first cell is the working copy, the second
is the original value.

------------------------------------------------------------------------ }

CREATE NEWCOLORS   8 CELLS ALLOT
CREATE ORGCOLORS   8 CELLS ALLOT

2VARIABLE NEWCOLORING
2VARIABLE NEWSCROLLMODE
2VARIABLE NEWFLAT
2VARIABLE NEWBIG

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

0 VALUE THEBRUSH

: ABUTTON ( id -- hbrush )
   THEBRUSH DeleteObject DROP
   100 - CELLS NEWCOLORS + @ CreateSolidBrush  DUP TO THEBRUSH ;

: COLOR-MY-BUTTONS ( -- hbrush )
   LPARAM GetDlgCtrlID DUP 100 108 WITHIN IF
      ABUTTON EXIT
   THEN DROP 0 ;

: PREFS-CLOSE ( -- res )
   THEBRUSH DeleteObject DROP  HWND 0 EndDialog ;

: PREFS-GET-VALUES
   COLOR-TABLE NEWCOLORS 8 CELLS CMOVE  COLOR-TABLE ORGCOLORS 8 CELLS CMOVE
   SCROLLMODE        @ DUP NEWSCROLLMODE 2!
   COLORING        @ DUP NEWCOLORING 2!
   SF-TOOLBAR BIG  @ DUP NEWBIG      2!
   SF-TOOLBAR FLAT @ DUP NEWFLAT     2! ;

: PREFS-SET-CHECKS
   HWND 220 NEWFLAT     @ 0<> 1 AND CheckDlgButton DROP
   HWND 221 NEWBIG      @ 0<> 1 AND CheckDlgButton DROP
   HWND 204 NEWCOLORING @ 0<> 1 AND CheckDlgButton DROP
   HWND 205 NEWSCROLLMODE @ 0<> 1 AND CheckDlgButton DROP ;

: PREFS-INIT
   PREFS-GET-VALUES PREFS-SET-CHECKS  0 TO THEBRUSH ;

: PREFS-APPLY-COLORS
   NEWCOLORS COLOR-TABLE 8 CELLS CMOVE
   OPERATOR'S  COLOR-TABLE SET-COLORS ;

: PREFS-APPLY-CHECKS
   HWND 220 IsDlgButtonChecked SF-TOOLBAR FLAT/BUTTONS
   HWND 221 IsDlgButtonChecked SF-TOOLBAR BIG/SMALL
   HWND 204 IsDlgButtonChecked COLORING !
   HWND 205 IsDlgButtonChecked SCROLLMODE ! ;

: PREFS-APPLY
   PREFS-APPLY-COLORS
   PREFS-APPLY-CHECKS ;

: PREFS-RESET
   ORGCOLORS NEWCOLORS 8 CELLS MOVE
   NEWBIG      CELL+ @ NEWBIG  !
   NEWFLAT     CELL+ @ NEWFLAT !
   NEWCOLORING CELL+ @ NEWCOLORING !
   NEWSCROLLMODE CELL+ @ NEWSCROLLMODE !
   PREFS-SET-CHECKS
   PREFS-APPLY ;

: COLOR-BUTTON ( -- )
   PICKCOLOR  DUP 0< IF  DROP EXIT  THEN   \ ignore negative values
   WPARAM LOWORD 100 - CELLS NEWCOLORS + !
   HWND WPARAM LOWORD GetDlgItem 0 1 InvalidateRect DROP ;

[SWITCH PREFS-COMMANDS ZERO
   IDOK     RUN: ( -- res )   PREFS-APPLY PREFS-CLOSE ;
   IDCANCEL RUN: ( -- res )   PREFS-RESET PREFS-CLOSE ;
   100      RUN: ( -- res )   COLOR-BUTTON 0 ;
   101      RUN: ( -- res )   COLOR-BUTTON 0 ;
   102      RUN: ( -- res )   COLOR-BUTTON 0 ;
   103      RUN: ( -- res )   COLOR-BUTTON 0 ;
   104      RUN: ( -- res )   COLOR-BUTTON 0 ;
   105      RUN: ( -- res )   COLOR-BUTTON 0 ;
   106      RUN: ( -- res )   COLOR-BUTTON 0 ;
   107      RUN: ( -- res )   COLOR-BUTTON 0 ;
    99      RUN: ( -- res )   PREFS-APPLY 0 ;
    98      RUN: ( -- res )   PREFS-RESET 0 ;
SWITCH]

[SWITCH PREFS-MESSAGES ZERO
   WM_CLOSE       RUNS PREFS-CLOSE
   WM_INITDIALOG  RUN: ( -- res )   PREFS-INIT -1 ;
   WM_COMMAND     RUN: ( -- res )   WPARAM LOWORD PREFS-COMMANDS ;
   WM_CTLCOLORBTN RUN: ( -- res )   COLOR-MY-BUTTONS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD PREFS-MESSAGES ;  4 CB: RUNPREFS

PUBLIC

: PREFS ( -- )
   HINST (PREFS)  HWND  RUNPREFS  0  DialogBoxIndirectParam DROP ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS
   MI_PREFS       RUNS PREFS
SWITCH]


END-PACKAGE
