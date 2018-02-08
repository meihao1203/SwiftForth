{ ====================================================================
System timer

Copyright 2008 FORTH, Inc.  All rights reserved.

This file supplies system timer acess.

==================================================================== }

{ --------------------------------------------------------------------
System time access

uCOUNTER returns the system time in microseconds.
COUNTER returns the system time, scaled to milliseconds.

TIMER and uTIMER display elapsed time in corresponding units since
the given timer value.  Usage:

   COUNTER <process to be timed> TIMER
   uCOUNTER <process to be timed> uTIMER

EXPIRED returns true if COUNTER has exceeded n.  There is a 1-day
window in which this routine must be called to allow for slow
monitoring routines.
-------------------------------------------------------------------- }

?( Timer access)


FUNCTION: clock_gettime ( type timespec -- ior )

: GET-MONO-TIME  ( -- nanosecs seconds )
   ( CLOCK_MONOTONIC) 1 0. 2>R  RP@ clock_gettime DROP  2R> ;

: COUNTER  ( -- ms )
   GET-MONO-TIME 1000 * >R 1000000 / R> + ;

: uCOUNTER ( -- d )
   GET-MONO-TIME 1000000 UM* ROT 1000 / M+ ;
