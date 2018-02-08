{ =====================================================================
Application load file

Copyright 2000 FORTH, Inc.

This file loads the application source files and redefines GO to
start the demo application.
===================================================================== }

TARGET

INCLUDE TIMER                   \ Timer A timing functions
INCLUDE LED                     \ Board-specific LED interface
INCLUDE ..\DISTRESS             \ Common distress signal source
INCLUDE ..\TASK                 \ Task to operate the SOS beacon

: GREET   ." SwiftX/MSP430 FET430P440 S.O.S. " ;

: GO ( -- )   0 'DLY !
   BEACON BUILD  /BEACON  PAUSE  DEBUG-LOOP ;
