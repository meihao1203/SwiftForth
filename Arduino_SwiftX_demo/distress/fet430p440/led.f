{ =====================================================================
LED driver

Copyright 2002  FORTH, Inc.

This file supplies the LED initialization and control words for the
FET430P440 board.  The LED is connect to Port 5 Bit 1.
===================================================================== }

TARGET

{ ---------------------------------------------------------------------
LED output control

+LED turns the LED on.
-LED turns the LED off.
/LED initializes the LED pin as an output, initial condition off.
--------------------------------------------------------------------- }

CODE +LED ( -- )   2 # P5OUT & BIS   RET   END-CODE
CODE -LED ( -- )   2 # P5OUT & BIC   RET   END-CODE
CODE /LED ( -- )   2 # P5DIR & BIS   2 # P5OUT & BIC   RET   END-CODE

