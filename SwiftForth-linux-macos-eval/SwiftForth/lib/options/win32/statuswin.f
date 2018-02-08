{ ====================================================================
A single part non-object status window.

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL STATUSWIN A single part status window

REQUIRES WINAPP

0 VALUE hStat

: CREATE-STATUS ( hwnd -- hsb )   >R
   WS_CHILD
   WS_VISIBLE OR
   WS_CLIPSIBLINGS OR
   CCS_BOTTOM OR
   0 R> 2 CreateStatusWindow ( hsb) ;

: MAKE-STAT ( -- )
   HWND CREATE-STATUS TO hStat ;

: SIZE-STAT ( -- )
   hStat WM_SIZE 0 0 SendMessage DROP ;

' SIZE-STAT IS SizeStatus
' MAKE-STAT IS MakeStatus
