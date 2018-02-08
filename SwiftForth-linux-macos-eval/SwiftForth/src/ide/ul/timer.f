{ ====================================================================
System timer

Copyright 2008 FORTH, Inc.  All rights reserved.

This file implements the timing and millisecond delay functions.

==================================================================== }

{ --------------------------------------------------------------------
Timing

TIMER and uTIMER display elapsed time in corresponding units since
the given timer value.  Usage:

   COUNTER <process to be timed> TIMER
   uCOUNTER <process to be timed> uTIMER

EXPIRED returns true if COUNTER has exceeded n.  There is a 1-day
window in which this routine must be called to allow for slow
monitoring routines.
-------------------------------------------------------------------- }

: (uTIMER) ( d1 -- d2 )   uCOUNTER 2SWAP D- ;
: (TIMER) ( ms1 -- ms2 )   COUNTER SWAP - ;

: uTIMER ( d -- )   (uTIMER) D. ;
: TIMER ( ms -- )   (TIMER) . ;

: EXPIRED ( ms -- t )   COUNTER -  -86400000 1 WITHIN ;

{ --------------------------------------------------------------------
Delay

MS provides a delay of the given milliseconds. If nanosleep returns
-1, it's most likely because we got a SIGINT.
-------------------------------------------------------------------- }

FUNCTION: nanosleep ( req rem -- ior )

: MS ( u -- )   ?DUP IF
      1000000 UM* 1000000000 UM/MOD
      SP@ 0 nanosleep -1 = -28 AND THROW
   2DROP  THEN ;
