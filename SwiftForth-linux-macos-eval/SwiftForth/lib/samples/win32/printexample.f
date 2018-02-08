{ ====================================================================
Text printing example

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL PRINTEXAMPLE An example showing how a program can print as easily as it can display output in the command window

ONLY FORTH ALSO DEFINITIONS DECIMAL

{ --------------------------------------------------------------------
APPLICATION is a debugged application that displays information using
the standard TYPE EMIT and CR words.  This example uses DUMP as a
simple example of this.
-------------------------------------------------------------------- }

: APPLICATION ( -- )   PAD 100 DUMP ;

{ --------------------------------------------------------------------
TEST runs the application, but with IO vectored to the print routines.

First, we save the current personality.  Next, initialize the printer
personality and begin using it.
-------------------------------------------------------------------- }

PRINTING +ORDER

: TEST ( -- )
   WINPRINT OPEN-PERSONALITY
   ['] APPLICATION CATCH ( *)            \ Catch the app in case of error
   CLOSE-PERSONALITY
   IF ." error running application" THEN ;

PRINTING -ORDER

CR
CR .( Type TEST to run the demo.)
CR
