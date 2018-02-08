{ ====================================================================
Cross Reference Platform Support

Copyright 2008  FORTH, Inc.

This file supplies the platform-specific support for the
cross-reference utility.  Allocation, initialization, saving, and
restoring of the cross-reference list are all done here.
==================================================================== }

PACKAGE CROSS-REFERENCE

{ --------------------------------------------------------------------
Line display
-------------------------------------------------------------------- }

: .LINEREF ( f# l# -- )
   BOLD SWAP 3 .R NORMAL  SPACE  3 .R  ." |" ;

END-PACKAGE
