{ ====================================================================
SIGCONT handler

Copyright 2011 by FORTH, Inc.

The system sends SIGCONT to the process when its console is
reconnected.  That means we need to call SET-TERM to re-establish our
terminal personality.

==================================================================== }

' SET-TERM 0 CB: <SIGCONT>

4 CONSTANT SA_SIGINFO

: /SIGCONT ( -- )
   R-BUF  R@ 140 ERASE                  \ This is struct sigaction
   <SIGCONT> R@ !                       \ sa_siginfo handler
   SA_SIGINFO R@ 132 + !                \ sa_flags (skip 128-bit sa_mask field)
   18 R> 0 sigaction DROP ;             \ SIGCONT

:ONENVLOAD ( -- )   /SIGCONT ;
