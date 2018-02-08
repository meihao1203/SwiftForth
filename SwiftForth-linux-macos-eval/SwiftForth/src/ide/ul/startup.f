{ ====================================================================
Turnkey startup

Copyright (C) 2008  FORTH, Inc.  All rights reserved

The turnkey development environment or user program is started here.
We use ABOUT-NAME for the signon message so SwiftX can change it.
==================================================================== }

{ --------------------------------------------------------------------
PLug in some system extensions to the kernel startup.
-------------------------------------------------------------------- }

VARIABLE 'STARTER

: STARTER ( -- )  ' 'STARTER ! ;

: ENTER-SWIFT ( -- )   'ONLOAD CALLS ;

: /ONLOAD ( -- )
   ['] ENTER-SWIFT CATCH ?DUP IF  EXITSTATUS !
   S" :ONLOAD failed" .BYE  THEN ;

:NONAME ( -- )   'ONSYSLOAD CALLS ;  IS /SYSTEM

{ --------------------------------------------------------------------
Plug in some system extensions to the kernel startup.
-------------------------------------------------------------------- }

?( Startup the system for interactive use)

: DEVELOPMENT ( -- )
   /CONSOLE  ?TTY @ 0= IF  /CMDLINE N-QUIT  THEN
   /FORTH  /ONLOAD
   'ONENVLOAD CALLS  'STARTER @EXECUTE ;

: INTERACTIVE ( -- i*x )
   /INTERPRETER  /CMDLINE
   ABOUT-NAME ZCOUNT TYPE  CR QUIT ;

' DEVELOPMENT 'MAIN !

STARTER INTERACTIVE

: (BYE) ( -- )
   ?TTY @ IF  'ONENVEXIT CALLS  THEN
   'ONSYSEXIT CALLS  _BYE ;

' (BYE) IS BYE
