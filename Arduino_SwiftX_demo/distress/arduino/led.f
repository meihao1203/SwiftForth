{ =====================================================================
LED driver

Copyright 2007  FORTH, Inc.

This file supplies the LED initialization and control words for the
Arduino Diecimila board.  The LED is connected to Port B Bit 5.
===================================================================== }

TARGET

{ ---------------------------------------------------------------------
LED output control

/LED initializes the LED pin as an output, initial condition off.

+LED turns the LED on.
-LED turns the LED off.
--------------------------------------------------------------------- }

CODE /LED ( -- )   5 DDRB SBI   5 PORTB CBI   RET   END-CODE

CODE +LED ( -- )   5 PORTB SBI   RET   END-CODE
CODE -LED ( -- )   5 PORTB CBI   RET   END-CODE
