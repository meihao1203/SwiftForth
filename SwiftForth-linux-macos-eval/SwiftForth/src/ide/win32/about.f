{ ====================================================================
About SwiftForth

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

The about box for SwiftForth is an example of a modeless dialog.
==================================================================== }

{ --------------------------------------------------------------------
Dialog box

ABOUT-NAME is used at startup to identify the application. SwiftX
replaces this to display its own message.

The file about.bmp has the following requirements:
  1) Must be located in the same directory as the current exe file
  2) BMP file format is 8- or 24-bit
  3) Image size, in pixels: 300w x 220h
-------------------------------------------------------------------- }

PACKAGE ABOUTBOX

PUBLIC

' VERSION IS ABOUT-NAME

PRIVATE

: NAMED ( -- )
   HWND Z" About..." SetWindowText DROP
   HWND 100 ABOUT-NAME SetDlgItemText DROP
   HWND 102 COPYRIGHT SetDlgItemText DROP ;

DIALOG (ABOUT)
   [MODAL  10 10 220 200 (FONT 9, Segoe UI Semibold) ]

   [CTEXT  " SwiftForth®"                      100   5 145 210 10 ]
   [CTEXT  " Copyright © "                     102   5 155 210 10 ]
   [CTEXT  " www.forth.com"                     -1   5 165 210 10 ]
   [DEFPUSHBUTTON   " OK"                     IDOK  85 180  50 14 ]

   [STATIC                                      101   5   5 210 75 (+STYLE SS_OWNERDRAW) (-STYLE WS_BORDER) ]

END-DIALOG

VARIABLE 'BMP-IMAGE     \ Address of BMP image in extended memory, 0 if none

: DRAW-PICTURE ( -- res )
   [OBJECTS  BITMAP MAKES PICTURE  OBJECTS]
   'BMP-IMAGE @ ?DUP IF  LPARAM 5 CELLS + @ PICTURE CENTERED  THEN  0 ;

: ABOUT-CLOSE ( -- res )
   HWND 0 EndDialog ;

[SWITCH ABOUT-COMMANDS ZERO
   IDOK     RUNS ABOUT-CLOSE
   IDCANCEL RUNS ABOUT-CLOSE
SWITCH]

[SWITCH ABOUT-MESSAGES ZERO
   WM_CLOSE          RUNS ABOUT-CLOSE
   WM_DRAWITEM       RUNS DRAW-PICTURE
   WM_INITDIALOG     RUN: ( -- res )   LPARAM 'BMP-IMAGE !  NAMED   -1 ;
   WM_COMMAND        RUN: ( -- res )   WPARAM LOWORD ABOUT-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD ABOUT-MESSAGES ;  4 CB: RUNABOUT

PUBLIC

: ABOUT ( -- )   R-BUF
   THIS-EXE-NAME -NAME R@ PLACE  S" \about.bmp" R@ APPEND
   R> COUNT  READ-BMPFILE >R
   HINST (ABOUT)  HWND RUNABOUT R@ DialogBoxIndirectParam DROP
   R> ?DUP -EXIT FREE DROP ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS
   MI_ABOUT       RUNS ABOUT
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE
