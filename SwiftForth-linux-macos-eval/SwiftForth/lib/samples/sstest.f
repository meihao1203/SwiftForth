{ ====================================================================
Exercise the simple single-step debugger

Copyright (C) 2001 FORTH, Inc.  All rights reserved
==================================================================== }

OPTIONAL SSTEST A simple example of the use of the single step debugger

REQUIRES singlestep

[DEBUG

: 2X ( n -- n*2)   DUP + ;

: 3X ( n -- n*3 )   DUP 2X + ;

: 4X ( n -- n*4 )   DUP 2X SWAP 2X + ;

: 5X ( n -- n*5 )   DUP 3X SWAP 2X + ;

DEBUG]

CR
CR .( Type 4 DEBUG 5X to run the debugger example)
CR
