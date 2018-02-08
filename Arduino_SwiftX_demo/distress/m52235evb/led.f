{ =====================================================================
LED driver

Copyright 2007  FORTH, Inc.

This file supplies the LED initialization and control words for the
M52235EVB board.  The LED is connected to Port TC Bit 0.
===================================================================== }

TARGET

{ ---------------------------------------------------------------------
LED output control

+LED turns the LED on.
-LED turns the LED off.
/LED initializes the LED pin as an output, initial condition off.
--------------------------------------------------------------------- }

: +LED ( -- )   1 SETTC C! ;
: -LED ( -- )   $FE CLRTC C! ;
: /LED ( -- )   DDRTC C@  1 OR  DDRTC C!  -LED ;
