{ ====================================================================
Printing the console window

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman
==================================================================== }

{ --------------------------------------------------------------------
Please note: these words are _only_ usable during a callback!
-------------------------------------------------------------------- }

PACKAGE PRINTING

: PX ( xt personality -- )
   'PERSONALITY @ >R  'PERSONALITY !
   INVOKE  CATCH  REVOKE
   R> 'PERSONALITY !  THROW ;

END-PACKAGE

PACKAGE CONSOLE-WINDOW

: TYPE-CONSOLE-TEXT ( -- )
   HCON "TTY" GetProp >R
   R@ TtyFirstLine BEGIN
      ?DUP WHILE  ZCOUNT TYPE CR
      R@ TtyNextLine
   REPEAT R> DROP ;

PRINTING +ORDER  ACCEPTOR +ORDER

: PRINT-CONSOLE-TEXT    ( -- )   ['] TYPE-CONSOLE-TEXT     WINPRINT PX ;
: SAVE-CONSOLE-TEXT     ( -- )   ['] TYPE-CONSOLE-TEXT     WINFILE  PX ;
: SAVE-KEYBOARD-HISTORY ( -- )   ['] TYPE-KEYBOARD-HISTORY WINFILE  PX ;

PRINTING -ORDER  ACCEPTOR -ORDER

[+SWITCH SF-COMMANDS
   MI_PRINT RUN:   ['] PRINT-CONSOLE-TEXT CATCH DROP ;
   MI_SAVECOMMAND RUN:  ['] SAVE-CONSOLE-TEXT CATCH DROP ;
   MI_SAVEHISTORY RUN:   ['] SAVE-KEYBOARD-HISTORY CATCH DROP ;
SWITCH]

{ --------------------------------------------------------------------
Saving the console log is similar, so it's here
-------------------------------------------------------------------- }

OFN-DIALOGS +ORDER

: SESSION-LOG-COMMAND ( -- )
   [OBJECTS
      SAVE-LOG-DIALOG MAKES SLD
   OBJECTS]
   HCON GetMenu MI_LOGGING 0 GetMenuState MF_CHECKED AND IF  0   ELSE
      SLD CHOOSE  IF  SLD +EXT  SLD FILENAME  ELSE 0 THEN
   THEN
   OPERATOR'S PHANDLE TtyRecorder
   HCON GetMenu MI_LOGGING ROT CHECKMARK ;

[+SWITCH SF-COMMANDS
   MI_LOGGING RUNS SESSION-LOG-COMMAND
SWITCH]

OFN-DIALOGS -ORDER

END-PACKAGE


