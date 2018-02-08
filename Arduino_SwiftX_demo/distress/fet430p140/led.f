{ =====================================================================
LED driver

Copyright 2002  FORTH, Inc.

This file supplies the LED initialization and control words for the
FET430P140 board.  The LED is connect to Port 1 Bit 0.
===================================================================== }

TARGET

{ ---------------------------------------------------------------------
LED output control

+LED turns the LED on.
-LED turns the LED off.
/LED initializes the LED pin as an output, initial condition off.
--------------------------------------------------------------------- }

CODE +LED ( -- )   1 # P1OUT & BIS   RET   END-CODE
CODE -LED ( -- )   1 # P1OUT & BIC   RET   END-CODE
CODE /LED ( -- )   1 # P1DIR & BIS   1 # P1OUT & BIC   RET   END-CODE

