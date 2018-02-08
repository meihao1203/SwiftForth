{ ====================================================================
Serial port configuration

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL CHOOSEPORT A COM port picker dialog

{ --------------------------------------------------------------------
This dialog allows the user to select a com port from the com1 thru
com4 list. The user word SELCOM-DIALOG returns false if the user
either canceled or the selected port if ok.

The calling program is responsible for closing the existing open
com port and initializing the new one.

If this is extended for more com ports, note that the order of the
radio buttons is very significant, and is used to calculate which
com port is meant by which button.
-------------------------------------------------------------------- }

DIALOG SELCOM
[MODAL " Select ComPort" 20 20 80 63 ]
 [DEFPUSHBUTTON     " OK"                         1    6    48   32   12 ]
 [PUSHBUTTON        " Cancel"                     2    42   48   32   12 ]
 [AUTORADIOBUTTON   " Com &1"                     101  6    14   32   10 ]
 [AUTORADIOBUTTON   " Com &2"                     102  6    28   32   10 ]
 [AUTORADIOBUTTON   " Com &3"                     103  42   14   32   10 ]
 [AUTORADIOBUTTON   " Com &4"                     104  42   28   32   10 ]
 [GROUPBOX          " Select ComPort"             -1   2    2    76   42 ]
END-DIALOG

: PICKED ( -- n )
   5 1 DO
      HWND I 100 + IsDlgButtonChecked IF I UNLOOP EXIT THEN
   LOOP 0 ;

[SWITCH SELCOM-COMMANDS DROP ( wparam -- )
   IDOK RUN:
      HWND  PICKED  EndDialog ;
   IDCANCEL RUN:
      HWND 0 EndDialog ;
SWITCH]

[SWITCH SELCOM-MESSAGES ZERO ( msg -- res )
   WM_COMMAND RUN:
      WPARAM LOWORD SELCOM-COMMANDS ;
   WM_INITDIALOG RUN:
      HWND 101 104 LPARAM 1 MAX 4 MIN 100 + CheckRadioButton DROP ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD SELCOM-MESSAGES ;  4 CB: SELCOM-CALLBACK

: SELECT-PORT ( initial -- new )
   >R HINST SELCOM HWND SELCOM-CALLBACK R> DialogBoxIndirectParam ;
