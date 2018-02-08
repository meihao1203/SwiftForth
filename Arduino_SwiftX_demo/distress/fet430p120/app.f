{ =====================================================================
Application load file

Copyright 2000 FORTH, Inc.

This file loads the application source files and redefines GO to
start the demo application.
===================================================================== }

TARGET

INCLUDE LED                     \ Board-specific LED interface
INCLUDE ..\DISTRESS             \ Common distress signal source

: GREET   ." SwiftX/MSP430 FET430P120 S.O.S. " ;

: GO ( -- )   /LED
   ?XTL @ IF  DEBUG-LOOP  THEN
   BEGIN  SOS  AGAIN ;
