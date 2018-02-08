{ =====================================================================
Application load file

Copyright 2002 FORTH, Inc.

This file is included near the end of Kernel.f and is intended to
load your application source.  Replace the default definition of GO
with one that performs your application initialization and start-up.

One of the sample demo applications is included here and its start-up
code is executed in GO.
===================================================================== }

TARGET

: GREET ( -- )   ." SwiftX/AVR Arduino Uno SOS Demo " ;

INCLUDE ../LED
INCLUDE ../../DISTRESS
INCLUDE ../../TASK

: GO ( -- )
   BEACON BUILD  /BEACON
   DEBUG-LOOP ;
