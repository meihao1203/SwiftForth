{ ====================================================================
Console window trace demo

Copyright 2001 FORTH, Inc.
==================================================================== }

OPTIONAL BUGSAMPLE A simple example of the use of CONSOLEBUG

REQUIRES CONSOLEBUG             \ INCLUDE CONSOLE DEBUG ROUTINES

1 TO BUGME                      \ 0 MEANS DEBUG NOT ACTIVE

: TEST ( -- )
   [BUG CR ." TESTING" .S BUG]  \ ANYTHING OUTPUT ORIENTED BETWEEN [BUG AND BUG]
   [BUG KEY DROP BUG]           \ KEY FOR PAUSE IS ALSO AVAILABLE
   DUP * DROP ;

: TRY ( -- )
   10 0 DO  I TEST  LOOP ;

CR
CR .( Type TRY to run the console debugger example)
CR
