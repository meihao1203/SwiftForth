{ =====================================================================
Beacon task

Copyright 2003  FORTH, Inc.

This file defines a background task to operate the SOS beacon.

===================================================================== }

TARGET

{ ---------------------------------------------------------------------
Background task
--------------------------------------------------------------------- }

|U| |S| |R| BACKGROUND BEACON

: /BEACON ( -- )   /LED
   BEACON ACTIVATE  BEGIN  SOS  AGAIN ;
