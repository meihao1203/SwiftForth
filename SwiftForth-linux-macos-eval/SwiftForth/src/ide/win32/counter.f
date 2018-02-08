{ ====================================================================
System timer

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
System performance counter access

DCOUNTER returns the system performance counter.
uCOUNTER returns the system performance counter, scaled to microseconds.
COUNTER returns the system performace counter, scaled to milliseconds.

TIMER (uTIMER, DTIMER) display elapsed time in corresponding units since
the given timer value.  Usage:

   COUNTER <process to be timed> TIMER
   uCOUNTER <process to be timed> uTIMER
   DCOUNTER <process to be timed> DTIMER

DCOUNTER and DTIMER are performance-counter variants of COUNTER TIMER.
They produce much more accurate results, but they do not have human
interpretable units.

EXPIRED  returns true if  COUNTER  has exceeded  n .  There is a 1 day
window in which this routine must be called to allow for slow monitoring
routines.
-------------------------------------------------------------------- }

?( Timer access)

: DCOUNTER ( -- d )   0 0 SP@ QueryPerformanceCounter DROP SWAP ;

: uCOUNTER ( -- d )
   DCOUNTER  1000000 0 0 SP@ QueryPerformanceFrequency DROP NIP M*/  ;

: COUNTER ( -- ms )
   DCOUNTER  1000 0 0 SP@ QueryPerformanceFrequency DROP NIP M*/ DROP  ;

: (DTIMER) ( d1 -- d2 )   DCOUNTER 2SWAP D- ;
: (uTIMER) ( d1 -- d2 )   uCOUNTER 2SWAP D- ;
: (TIMER) ( ms1 -- ms2 )   COUNTER SWAP - ;

: DTIMER ( d -- )   (DTIMER) D. ;
: uTIMER ( d -- )   (uTIMER) D. ;
: TIMER ( ms -- )   (TIMER) . ;

: EXPIRED ( ms -- t )
   COUNTER -  -86400000 1 WITHIN ;

{ --------------------------------------------------------------------
MS  provides a delay of the given milliseconds.
-------------------------------------------------------------------- }

: MS ( n -- )
   ?DUP IF
      COUNTER + BEGIN
         PAUSE  1 Sleep DROP
         DUP EXPIRED
      UNTIL DROP
   THEN ;
