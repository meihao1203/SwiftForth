{ ====================================================================
Modeless dialog template

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL SAMPLE-DIALOG A simple modeless dialog template

EMPTY

DIALOG (SAMPLE)
   [MODELESS " Sample" 10 10 80 40
   (FONT 8, MS Sans Serif) (-STYLE WS_SYSMENU) ]

   [DEFPUSHBUTTON   " OK"    IDOK 5 5 40 15 ]
END-DIALOG

: SAMPLE-CLOSE ( -- res )
   (SAMPLE) CELL- OFF  HWND DestroyWindow ;

: SAMPLE-INIT ( -- )
   ;

[SWITCH SAMPLE-COMMANDS ZERO ( -- res)
   IDOK      RUN: SAMPLE-CLOSE ;
   IDCANCEL  RUN: SAMPLE-CLOSE ;
   100       RUN: SAMPLE-CLOSE ;
SWITCH]

[SWITCH SAMPLE-MESSAGES ZERO ( -- res)
   WM_ACTIVATE       RUNS MODELESS-ACTIVATE
   WM_CLOSE          RUNS SAMPLE-CLOSE
   WM_INITDIALOG     RUN: SAMPLE-INIT -1 ;
   WM_COMMAND        RUN: WPARAM LOWORD SAMPLE-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD SAMPLE-MESSAGES ;  4 CB: RUNSAMPLE

: SAMPLE
   (SAMPLE) CELL- @ ?EXIT
   HINST (SAMPLE)  HWND  RUNSAMPLE  0  CreateDialogIndirectParam
   (SAMPLE) CELL- ! ;

CR
CR .( Type SAMPLE to invoke the sample modeless dialog)
CR
