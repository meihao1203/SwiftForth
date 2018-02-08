{ ====================================================================
Warning level configuration

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

PACKAGE ERROR-HANDLERS

{ --------------------------------------------------------------------
Configure warnings for user

we defer the dialog template so we can easily replace it if the
user loads the protection option.

the dialog includes an address warnings configuration section which
is not visible by default. it is enabled when the optional file
"protection.f" is loaded. The code which manages the dialog is
already in place to set the relevant bits of the warning variable,
but these bits are meaningless without the code in protection.f
-------------------------------------------------------------------- }

DIALOG WARNCFG-TEMPLATE
   [MODAL " System warning configuration"
          10 20 278 110
          (CLASS SFDLG)
          (FONT 8, MS Sans Serif) ]

    [GROUPBOX      " System warnings"             100   4  4 120 100 ]
    [AUTOCHECKBOX  " Enable system warnings"      101   8 16  88   8 ]
    [AUTOCHECKBOX  " Warn for redefinitions"      102  16 28  88   8 ]
    [AUTOCHECKBOX  " Warn for case ambiguity"     122  16 40  88   8 ]

    [GROUPBOX      " Address warnings"            103  16 52  84 48 ]
    [AUTOCHECKBOX  " Comma ( , ) "                104  28 64  48  8 ]
    [AUTOCHECKBOX  " Constants"                   105  28 76  48  8 ]
    [AUTOCHECKBOX  " Store ( ! )"                 106  28 88  48  8 ]

    [GROUPBOX      " Display warnings and errors" 107 128  4 144 52 ]
    [AUTOCHECKBOX  " In command window"           108 132 16  88  8 ]
    [AUTOCHECKBOX  " In message box"              109 132 28  88  8 ]
    [AUTOCHECKBOX  " Always show details for OS exceptions"   110 132 40  134 8 ]

    [DEFPUSHBUTTON " OK"                         IDOK 140 90  40 14 ]
    [PUSHBUTTON    " Cancel"                 IDCANCEL 188 90  40 14 ]


END-DIALOG

{ --------------------------------------------------------------------
        0000.0000.0000.0001 display warnings on console
        0000.0000.0000.0010 display warnings in message box
        0000.0000.0000.0100 always display warning details for os
        0000.0000.0001.0000 non-uniqueness
        0000.0000.0010.0000 report ambiguities
-------------------------------------------------------------------- }

0 VALUE USING-PROTECTED-MEMORY

GENERICDIALOG SUBCLASS WARNCFG-DIALOG

   : TEMPLATE ( -- addr )   WARNCFG-TEMPLATE ;

   : INIT ( -- res )
      WARNING-LEVEL ( global)
         108 OVER $001 AND SET-CHECK
         109 OVER $002 AND SET-CHECK
         110 OVER $004 AND SET-CHECK
         102 OVER $010 AND SET-CHECK
         122 OVER $020 AND SET-CHECK
         104 OVER $100 AND SET-CHECK
         105 OVER $200 AND SET-CHECK
         106 OVER $400 AND SET-CHECK
      DROP  101 WARNING @ SET-CHECK
      USING-PROTECTED-MEMORY 0= IF
         103 HIDE  104 HIDE  105 HIDE  106 HIDE
      THEN

      -1 ;

   : APPLY ( -- res )
      108 IS-CHECKED $001 AND
      109 IS-CHECKED $002 AND OR
      110 IS-CHECKED $004 AND OR
      102 IS-CHECKED $010 AND OR
      122 IS-CHECKED $020 AND OR
      104 IS-CHECKED $100 AND OR
      105 IS-CHECKED $200 AND OR
      106 IS-CHECKED $400 AND OR  WARNING CELL+ !
      101 IS-CHECKED WARNING !
      CLOSE-DIALOG ;

   : MINIMUM ( -- )
      108 IS-CHECKED ?EXIT
      109 IS-CHECKED ?EXIT
      108 1 SET-CHECK ;

   108 COMMAND: MINIMUM ;
   109 COMMAND: MINIMUM ;
   IDOK COMMAND:  APPLY ;

   WM_INITDIALOG MESSAGE: INIT ;

END-CLASS

PUBLIC

: WARNCFG ( -- )
   [OBJECTS WARNCFG-DIALOG MAKES WCD OBJECTS]
   HWND WCD MODAL DROP ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_WARNCFG RUNS WARNCFG
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE

