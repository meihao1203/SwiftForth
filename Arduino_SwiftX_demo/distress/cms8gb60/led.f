{ =====================================================================
LED driver

Copyright 2007  FORTH, Inc.

This file supplies the LED initialization and control words for the
CMS8GB60 board.  The LED is connected to Port F Bit 0.
===================================================================== }

TARGET

{ ---------------------------------------------------------------------
LED output control

/LED initializes the LED pin as an output, initial condition off.

+LED turns the LED on.
-LED turns the LED off.
--------------------------------------------------------------------- }

CODE /LED ( -- )   PTFDD 0 BSET   PTFD 0 BSET   RTS   END-CODE

CODE +LED ( -- )   PTFD 0 BCLR   RTS   END-CODE
CODE -LED ( -- )   PTFD 0 BSET   RTS   END-CODE
