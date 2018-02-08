{ =====================================================================
FET INITIALIZATION

Copyright 2001  FORTH, Inc.

This file supplies the power-up initialization code for the FET as
well as JTAG initialization and download support.

===================================================================== }

TARGET

{ ---------------------------------------------------------------------
System start-up

START performs high-level system initialization and passes control to
GO which may be redefined to start your application.  The default GO
supplied in the kernel awaits commands from the cross-target link.

0CODE and |CODE| define the start and size of code space.

POWER-UP is the boot PROM initialization code.  It sets up some CPU
registers and passes control to START above.

RELOAD initializes the CPU via the JTAG, and reprograms the flash if
the checksum in the target device does not match the one just compiled
in the host memory image.  Passes control to POWER-UP.

The address of the POWER-UP routine is placed into the reset vector.
--------------------------------------------------------------------- }

: START ( -- )   OPERATOR  CELL+ STATUS  DUP |U| ERASE
   |OPERATOR| CMOVE  /IDATA  /TIMERA  /INTERRUPTS  GO ;

LABEL POWER-UP
   ?XTL CLR   $AAAA # R15 CMP           \ Test for AAAA flag in R15
   0= IF   R15 CLR   ?XTL DEC   THEN    \ Indicates we're booted by JTAG XTL
   WDTPW WDTHOLD + # WDTCTL & MOV       \ Stop WDT
   0 # SR MOV                           \ Clear SR
   'S0 # S MOV   0 # T MOV              \ Establish stack pointers
   'R0 # U MOV   U R MOV
   ' START # BR   END-CODE

CDATA  LIMITS DROP  EQU 0CODE
   HERE 0CODE - EQU |CODE|

IDATA

INTERPRETER

: (RELOAD) ( -- )   CONNECT
   0CODE >CDATA 0CODE |CODE| PROGRAM-FLASH ;

: RELOAD ( -- )   -CHECKSUM IF  (RELOAD)  THEN
   RESET-JTAG  CONNECT TARGET ;

: RELOAD! ( -- )   (RELOAD)
   RESET-JTAG  CONNECT TARGET ;

TARGET

POWER-UP RESET_VECTOR !C  SAVE-IDATA  SAVE-CHECKSUM
