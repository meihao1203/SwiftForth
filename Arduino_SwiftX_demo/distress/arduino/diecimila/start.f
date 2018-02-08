{ =====================================================================
DIECIMILA INITIALIZATION

Copyright 2010  FORTH, Inc.

This file supplies the power-up initialization code for the Diecimila
board with an ATmega168 microcontroller.

===================================================================== }

TARGET

{ ---------------------------------------------------------------------
Initialization

POWER-UP is jumped to from the reset vector.  It performs low-level
initialization, boots the system token code into external RAM and
and finishes in high-level START code.
--------------------------------------------------------------------- }

: START ( -- )   'R0 U !  /IDATA
   OPERATOR CELL+ STATUS DUP |U| ERASE |OPERATOR| CMOVE
   [DEFINED] /TIMER [IF] /TIMER [THEN]  -DEBUG  GO ;

LABEL POWER-UP
   CLI
   'S0 |S| - Z LDI                      \ Start of stack space
   |S| |R| + X LDI                      \ Size of data + return stacks
   'S0 S LDI   'R0 1- Z LDI             \ Initial data and return stack
   ZL SPL OUT   ZH SPH OUT              \ Set CPU stack pointer
   SEI   ' START RJMP   END-CODE        \ Finish in START

POWER-UP 0 INTERRUPT

SAVE-IDATA  SAVE-CHECKSUM

THERE EQU |CODE|

INTERPRETER

: RELOAD! ( -- )
   FUSEBYTES FLASH-SCRIPT ;

: RELOAD ( -- )
   -CHECKSUM IF  RELOAD!  THEN  CONNECT TARGET ;

TARGET
