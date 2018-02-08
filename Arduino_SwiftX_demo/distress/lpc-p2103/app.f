{ =====================================================================
Application load file

Copyright 2007  FORTH, Inc.

This file is included near the end of Kernel.f and is intended to
load your application source.  Replace the default definition of GO
with one that performs application initialization and start-up.

===================================================================== }

TARGET

: GREET   ." SwiftX/ARM LPC-P2103 S.O.S. " ;

INCLUDE LED                     \ Board-specific LED interface
INCLUDE ..\DISTRESS             \ Common distress signal source
INCLUDE ..\TASK                 \ Task to operate the SOS beacon

: GO ( -- )
   \ BEACON BUILD  /BEACON  PAUSE
   DEBUG-LOOP ;
