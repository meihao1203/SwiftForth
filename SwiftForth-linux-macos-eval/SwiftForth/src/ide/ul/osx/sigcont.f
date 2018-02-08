{ ====================================================================
SIGCONT handler

Copyright 2011 by FORTH, Inc.

The system sends SIGCONT to the process when its console is
reconnected.  That means we need to call SET-TERM to re-establish our
terminal personality.

==================================================================== }

' SET-TERM 0 CB: <SIGCONT>

CREATE SA_SIGCONT
   <SIGCONT> , 0 , $40 ,                \ struct sigaction

: /SIGCONT ( -- )
   19 SA_SIGCONT 0 sigaction DROP ;     \ SIGCONT

:ONENVLOAD ( -- )   /SIGCONT ;
