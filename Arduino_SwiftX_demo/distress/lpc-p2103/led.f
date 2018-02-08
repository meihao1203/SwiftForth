{ =====================================================================
LED driver

Copyright 2007  FORTH, Inc.

This file supplies the LED initialization and control words for the
LPC-P2103 board.  The LED is connected to GPIO P0.26.
===================================================================== }

TARGET

{ ---------------------------------------------------------------------
LED output control

+LED turns the LED on.
-LED turns the LED off.
/LED initializes the LED pin as an output, initial condition off.
--------------------------------------------------------------------- }

1 26 LSHIFT EQU %LED    \ LED bit mask

: +LED ( -- )   %LED IOCLR ! ;
: -LED ( -- )   %LED IOSET ! ;
: /LED ( -- )   -LED  IODIR @  %LED OR  IODIR ! ;
