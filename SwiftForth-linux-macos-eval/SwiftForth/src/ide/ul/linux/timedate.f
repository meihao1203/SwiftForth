{ ====================================================================
Time and date

Copyright 2008 FORTH, Inc.  All rights reserved.

This file provides system-level access to time and date.

==================================================================== }

{ --------------------------------------------------------------------
System time access

uCOUNTER returns the system time in microseconds.
COUNTER returns the system time, scaled to milliseconds.
-------------------------------------------------------------------- }

?( Timer access)

FUNCTION: gettimeofday ( tv tz -- ior )

: GET-TIME ( -- u1 u2 )
   0 0 SP@ 0 gettimeofday DROP ;
