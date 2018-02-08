{ ====================================================================
Interval timer - callback sample

Copyright 2002  Roelf Toxopeus

This file implements a simple interval timer to demonstrate the use
of callbacks.
==================================================================== }

LIBRARY libc.dylib

{ --------------------------------------------------------------------
Set interval timer

int setitimer(int which, const struct itimerval *value, struct itimerval *ovalue);

  Timer values are defined by the following structures:

           struct itimerval
               struct timeval it_interval; /* next value */
               struct timeval it_value;    /* current value */

           struct timeval
               long tv_sec;                /* seconds */
               long tv_usec;               /* microseconds */

/INTERVAL starts interval timer 0 for the given period (seconds,
microseconds).  Use 0 0 to stop it.


int sigaction(int sig, const struct sigaction *restrict act, struct sigaction *restrict oact);

     struct  sigaction
             union __sigaction_u __sigaction_u;  /* signal handler */
             sigset_t sa_mask;               /* signal mask to apply */
             int     sa_flags;               /* see signal options below */

-------------------------------------------------------------------- }

FUNCTION: setitimer ( which *values *ovalues -- ret )

CREATE ITIMER
   0 , 0 ,      \ next value (secs, usecs)
   0 , 0 ,      \ current value (secs, usecs)

: /INTERVAL ( secs usecs -- n )
   SWAP 2DUP ITIMER 2!  ITIMER 2 CELLS + 2!
   0 ITIMER 0 setitimer ;

2 CONSTANT SA_RESTART           \ resume interrupted call on signal return

CREATE 'SIGACT
   0 , 0 , SA_RESTART ,         \ Hander, mask , flags

14 CONSTANT SIGALRM
1 CONSTANT SIG_IGN

: >ALARM ( x -- n )
   'SIGACT !  SIGALRM 'SIGACT 0 sigaction ;

: -ALARM ( -- n )   SIG_IGN >ALARM ;

THROW#
   S" Call to sigaction() failed" >THROW ENUM IOR_SIGACTION
   S" Call to setitimer() failed" >THROW ENUM IOR_SETTIMER
TO THROW#

: START-TIMER ( addr seconds usecs -- )
   ROT >ALARM  IOR_SIGACTION ?THROW
   /INTERVAL  IOR_SETTIMER ?THROW ;

: CANCEL-TIMER ( -- )
   0 0 /INTERVAL  IOR_SETTIMER ?THROW
   SIG_IGN >ALARM  IOR_SIGACTION ?THROW ;


VARIABLE #SEC

: TICK ( -- ret )   1 #SEC +!  0 ;

' TICK 1 CB: *TICK

: /TICKS ( -- )   *TICK 1 0 START-TIMER ;
