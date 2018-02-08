{ ====================================================================
Cross Reference Platform Support

Copyright 2001  FORTH, Inc.

This file supplies the platform-specific support for the
cross-reference utility display output.
==================================================================== }

PACKAGE CROSS-REFERENCE

{ --------------------------------------------------------------------
Line display
-------------------------------------------------------------------- }

: .LINEREF ( f# l# -- )
   BOLD SWAP 3 .R NORMAL  INVISIBLE  (.) 3 OVER -
   1+ 1 MAX 0 DO ." _" LOOP  NORMAL  TYPE  ." |" ;

END-PACKAGE
