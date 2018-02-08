{ ====================================================================
About dialog box template

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL ABOUT1 A simple about box dialog template

DIALOG (ABOUT)  [MODAL  " About title"  22 17 167 73
   (FONT 8, MS Sans Serif) ]

[DEFPUSHBUTTON " OK"                    IDOK   132  2  32 14 ]
[ICON          101 RESOURCE             -1       3  2  18 20 ]
[LTEXT         " Application name"      -1      30 12  50  8 ]
[LTEXT         " Description"           -1      30 22 150  8 ]
[LTEXT         " Version"               -1      30 32 150  8 ]
[LTEXT         " Company name"          -1      30 42 150  8 ]

END-DIALOG

:NONAME ( -- res )
   MSG LOWORD WM_COMMAND = IF
      WPARAM LOWORD  DUP IDOK = SWAP IDCANCEL = OR IF
         HWND 1 EndDialog -1 EXIT
      THEN
   THEN
   0 ;

( xt) 4 CB: RUNABOUT

: ABOUT ( -- )
   HINST (ABOUT) HWND RUNABOUT 0 DialogBoxIndirectParam DROP ;

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

ABOUT

BYE  [THEN]
