{ ====================================================================
Simple winsock interface test

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL WHOAMI Report computer's network name

REQUIRES WINSOCK

CREATE WSADATA   1000 ALLOT   WSADATA 1000 ERASE

: WHOAMI ( -- )
   $101 wsadata wsastartup 0= if
      pad 255 gethostname 0= if
         pad gethostbyname if
            pad zcount type
            wsacleanup drop exit
         then
         ." can't gethostbyname"  wsacleanup drop exit
      then
      ." can't gethostname" wsacleanup drop exit
   then
   ." can't wsastartup" ;

CR CR .( Type WHOAMI to return your computer's network name.) CR CR
