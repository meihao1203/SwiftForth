{ ====================================================================
SwiftForth evaluation "nag" screen

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
The splash box is an example of a modeless dialog.

SPLASH-NAME is used at startup to identify the application. SwiftForth
uses this to display its own message.
-------------------------------------------------------------------- }

PACKAGE SPLASHBOX

PUBLIC

: SF-UPGRADE ( -- )
   S" http://www.forth.com/swiftforth/eval-special.html" >SHELL ;

: SPLASH-IMAGE ( -- addr n )
   S" %SwiftForth\bin\about.bmp" +ROOT ;

VARIABLE SPLASH-BMP

PRIVATE

: NAMED ( -- )
   HWND Z" SwiftForth Evaluation"  SetWindowText DROP
   HWND 100 ABOUT-NAME SetDlgItemText DROP
   HWND 102 COPYRIGHT SetDlgItemText DROP ;

DIALOG NAG-BOX
\          x   y   xsiz ysiz
   [MODAL  10  10  220  230  (FONT 9, MS Sans Serif) ]

\ [control " default text"                      id xpos ypos xsiz ysiz ]
   [CTEXT  " SwiftForth"                       100   5 145 210 10 ]
   [CTEXT  " Copyright © "                     102   5 155 210 10 ]
   [CTEXT  " www.forth.com"                     -1   5 165 210 10 ]

   [CTEXT  " This program is supplied for evaluation purposes only."  -1  0  180  220  10 ]
   [CTEXT  " You must purchase a licensed version for any other use."  -1  0  190  220  10 ]

   [DEFPUSHBUTTON   " OK"                    IDCANCEL  40 210  50 14 ]
   [DEFPUSHBUTTON   " More Info"                 IDOK 130 210  50 14 ]

   [STATIC                                      101   5   5 210 75 (+STYLE SS_OWNERDRAW) (-STYLE WS_BORDER) ]

END-DIALOG

: DRAW-PICTURE ( -- res )
   [OBJECTS  BITMAP MAKES PICTURE  OBJECTS]
   SPLASH-BMP @ LPARAM 5 CELLS + @ PICTURE CENTERED  0 ;

: ENDED ( -- )   HWND 0 EndDialog ;

: SPLASH-CLOSE ( -- res )   ENDED ;

: SF-INFO ( -- res )   SF-UPGRADE ENDED ;

VARIABLE NAGTIME

: SPLASH-INIT ( -- )
   NAGTIME @ ?DUP IF
      HWND 99 ROT ( ms) 0 SetTimer DROP
      HWND IDCANCEL GetDlgItem 0 EnableWindow DROP
   THEN ;

[SWITCH SPLASH-COMMANDS ZERO
   IDCANCEL RUN: NAGTIME @ IF  SPLASH-CLOSE  ELSE  SF-INFO  THEN ;
   IDOK     RUNS SF-INFO
SWITCH]

[SWITCH SPLASH-MESSAGES ZERO
   WM_CLOSE          RUNS SPLASH-CLOSE
   WM_DRAWITEM       RUNS DRAW-PICTURE
   WM_INITDIALOG     RUN: SPLASH-INIT  LPARAM SPLASH-BMP !  NAMED   -1 ;
   WM_COMMAND        RUN: ( -- res )   WPARAM LOWORD SPLASH-COMMANDS ;
   WM_TIMER          RUN: ( -- res )
      HWND 99 KillTimer DROP
      HWND IDCANCEL GetDlgItem 1 EnableWindow DROP  0 ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD SPLASH-MESSAGES ;  4 CB: RUNSPLASH

: (SPLASH) ( -- )
   SPLASH-IMAGE READ-BMPFILE >R
   HINST NAG-BOX  HWND RUNSPLASH R@ DialogBoxIndirectParam DROP
   R> ?DUP -EXIT FREE DROP ;

PUBLIC

DEFER SPLASH   ' (SPLASH) IS SPLASH

CONSOLE-WINDOW +ORDER

[+SWITCH SF-MESSAGES
   WM_CLOSE RUN:   0 NAGTIME !  SPLASH  HWND DestroyWindow DROP 0 ;
   WM_CREATE RUN:  2000 NAGTIME !  CREATES SPLASH ;
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE
