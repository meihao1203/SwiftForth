{ =====================================================================
TIMER A

Copyright 2002  FORTH, Inc.

Timer A provides the interrupt-driven millisecond timer for the
Distress application.  This version of MS supplies service to a single
task only and allows the CPU to enter low-power mode during the
delay interval.

===================================================================== }

TARGET

{ ---------------------------------------------------------------------
Timing

MS specifies a delay of u milliseconds.  Sets the delay value
in #DLY and the task's STATUS address in 'DLY then suspends the task.
The <DELAY> interrupt compares the timer with the system millisecond
count in MSECS and awakens the task when the timeout is reached.
--------------------------------------------------------------------- }

VARIABLE #DLY
VARIABLE 'DLY

LABEL <DELAY>
   MSECS & #DLY & CMP   0< IF                   \ Skip to <MSEC> if #DLY not timed out
      U PUSH   'DLY & U MOV                     \ Get suspended task STATUS pointer
      WAKE # STATUS (U) MOV   U POP             \ Awaken task
      <MSEC> TIMERA0_VECTOR INTERRUPT           \ Reset interrupt vector to <MSEC>
      &LPM # 0 (SP) BIC                         \ Clear LPM bits in stacked SR
   THEN   <MSEC> # BR   END-CODE                \ Finish with standard <MSEC> handler

: MS ( u -- )   'DLY GET  COUNTER + #DLY !
   <DELAY> TIMERA0_VECTOR INTERRUPT  STOP  'DLY RELEASE ;

