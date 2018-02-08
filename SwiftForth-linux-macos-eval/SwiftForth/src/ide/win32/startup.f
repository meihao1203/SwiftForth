{ ====================================================================
Startup the system for interactive use

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

VARIABLE 'STARTER

: STARTER ( -- )  ' 'STARTER ! ;

: ENTER-SWIFT ( -- )   'ONLOAD CALLS ;

: /ONLOAD ( -- )
   ['] ENTER-SWIFT CATCH -EXIT
   0 Z" :ONLOAD failed" EBOX
   -1 ExitProcess ;

:NONAME ( -- )  WPARMS 'WF !  'ONSYSLOAD CALLS ;  IS /SYSTEM

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

\ Use ABOUT-NAME for the signon message so SwiftX can change it.

?( Startup the system for interactive use)

[UNDEFINED] /GUI [IF]

: /GUI ( -- )   START-CONSOLE ;

-? : BYE 0 ExitProcess ;

[THEN]

[UNDEFINED] RESTORE-CONFIGURATION [IF]

: RESTORE-CONFIGURATION ;

[THEN]

: DEVELOPMENT ( -- )
   UP@ OPERATOR !  RESTORE-CONFIGURATION
   /FORTH  /ONLOAD  /GUI
   'ONENVLOAD CALLS  'STARTER @EXECUTE ;

: INTERACTIVE ( -- i*x )
   HCON SetFocus DROP
   /INTERPRETER  /CMDLINE
   ABOUT-NAME ZCOUNT TYPE  CR QUIT ;

0 ' DEVELOPMENT 'MAIN 2!        \ Set entry point to DEVELOPMENT and window type to GUI (0)

STARTER INTERACTIVE
