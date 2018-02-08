{ =====================================================================
BASIC TIMER 1

Copyright 2002  FORTH, Inc.

Basic Timer 1 provides the interrupt-driven millisecond timer for the
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

VARIABLE MSECS

LABEL <MSEC>
   MSECS INC   RETI   END-CODE

<MSEC> BASICTIMER_VECTOR INTERRUPT

LABEL <DELAY>
   MSECS & #DLY & CMP   0< IF                   \ Skip to <MSEC> if #DLY not timed out
      U PUSH   'DLY & U MOV                     \ Get suspended task STATUS pointer
      WAKE # STATUS (U) MOV   U POP             \ Awaken task
      <MSEC> TIMERA0_VECTOR INTERRUPT           \ Reset interrupt vector to <MSEC>
      &LPM # 0 (SP) BIC                         \ Clear LPM bits in stacked SR
   THEN   <MSEC> # BR   END-CODE                \ Finish with standard <MSEC> handler

1024 1000 2CONSTANT T/MS

: COUNTER ( -- u )   MSECS @ ;

: MS ( u -- )   'DLY GET  T/MS */  COUNTER + #DLY !
   <DELAY> BASICTIMER_VECTOR INTERRUPT  STOP  'DLY RELEASE ;

{ ---------------------------------------------------------------------
Initialization

/TIMERS initializes Basic Timer 1 to provide millisecond (approximate)
clock interrupt.
--------------------------------------------------------------------- }

CODE /TIMER1 ( -- )
   $1C # BTCTL & MOV.B                  \ Int=ACLK/32 (1024 Hz)
   BTIE # IE2 & BIS.B                   \ Enable RTC interrupt
   RET   END-CODE                       \ Clear 'MS (no task)

