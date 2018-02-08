{ ====================================================================
System timer

Copyright 2008 FORTH, Inc.  All rights reserved.

This file implements counter and timer functions.

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

: uCOUNTER ( -- d )   GET-TIME 1000000 UM* ROT M+ ;
: COUNTER ( -- ms )   GET-TIME 1000 * SWAP 1000 / + ;
