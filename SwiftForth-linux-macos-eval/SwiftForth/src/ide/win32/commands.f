{ ====================================================================
SwiftForth debug window

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

PACKAGE CONSOLE-WINDOW


: PRESSED ( item addr -- )   SF-TOOLBAR HANDLE @ TB_PRESSBUTTON 2SWAP
   @ 0<> SendMessage DROP ;

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

: INDICATORS ( -- )
   SF-TOOLBAR SHOWN? 0= MI_SHOWTOOL UNCHECKED
   SF-STATUS SHOWN?  0= MI_SHOWSTAT UNCHECKED
[DEFINED] COMMAND-HISTORY [IF]
   [ COMMAND-HISTORY +ORDER ]
   MI_HISTORY HISTORYORG 2DUP CHECKED PRESSED
   [ COMMAND-HISTORY -ORDER ]
[THEN]
[DEFINED] WORD-BROWSER [IF]
   [ WORD-BROWSER +ORDER ]
   MI_WORDS BROWSEORG 2DUP CHECKED  PRESSED
   [ WORD-BROWSER -ORDER ]
[THEN]
[DEFINED] MEMTOOLS [IF]
   [ MEMTOOLS +ORDER ]
   MI_MEMORY DUMPORG  2DUP CHECKED  PRESSED
   MI_WATCH WATCHORG  2DUP CHECKED  PRESSED
   [ MEMTOOLS -ORDER ]
[THEN] ;

:ONENVLOAD ( -- )   INDICATORS ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: TOOLBAR-TOGGLE ( -- )
   SF-TOOLBAR SHOWN? IF SF-TOOLBAR HIDE ELSE SF-TOOLBAR SHOW THEN
   INDICATORS ;

: STATBAR-TOGGLE ( -- )
   SF-STATUS SHOWN? IF SF-STATUS HIDE ELSE SF-STATUS SHOW THEN
   INDICATORS ;

: COPY-TEXT ( -- )
   HTTY WM_COPY 0 0 SendMessage DROP ;

: PASTE-TEXT ( -- )
   HTTY WM_PASTE 0 0 SendMessage DROP ;

: NEW-PANE ( -- )
   HTTY TtyNew DROP ;

: BREAKER ( -- )
   HWND WM_BREAK 0 0 PostMessage DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }


[+SWITCH SF-COMMANDS ( wparam -- )
   MI_BREAK       RUNS BREAKER
   MI_CLEAR       RUNS NEW-PANE
   MI_COPY        RUNS COPY-TEXT
   MI_PASTE       RUNS PASTE-TEXT
   MI_EDIT        RUNS CHOOSE-EDIT-FILE
   MI_INCLUDE     RUNS INCLUDE-FILE-COMMAND
   MI_SHOWTOOL    RUNS TOOLBAR-TOGGLE
   MI_SHOWSTAT    RUNS STATBAR-TOGGLE
   MI_EXIT        RUN: HWND WM_CLOSE 0 0 SendMessage DROP ;
   MI_SAVEOPTIONS RUNS SAVE-CONFIGURATION
   MI_REFRESH     RUNS INDICATORS
   MI_SELALL      RUN: OPERATOR'S PHANDLE TtySelectAll DROP ;
   MI_APIHELP     RUNS API-HELP
   MI_MSDN        RUNS API-MSDN
   MI_USERMANUAL  RUNS SWIFT-PDF
   MI_ANSMAN      RUNS DPANS-PDF
   MI_HANDBOOK    RUNS FORTH-HANDBOOK
   MI_VERSIONS    RUNS RELEASE-NOTES
   MI_ONLINE      RUNS SWF-ONLINE

SWITCH]

PUBLIC

: WIPE ( -- )   NEW-PANE ;

END-PACKAGE
