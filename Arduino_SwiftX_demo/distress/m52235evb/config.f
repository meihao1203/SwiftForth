{ =====================================================================
M52235EVB TARGET ENVIRONMENT CONFIGURATION

Copyright 2006  FORTH, Inc.

The M52235EVB target environment is configured here.
===================================================================== }

INTERPRETER   HEX

{ ---------------------------------------------------------------------
Memory map

The code and data memory sections are defined here.

'FLASH defines the base address of the Flash memory which contains the
boot program.

The sizes declared in the parent directory's Config.f are used to
allocate target dictionary (PAD and NUM spaces), stacks, and user area.

The parameter and return stack addresses are also placed in TS0 and TR0
for use by the cross-target link (XTL).

The CPU exception VECTORS table is defined at the start of program space.
This must reside in RAM if the target needs to modify exception vectors
at run-time.  The first cell of the reset vector is used for the system
checksum so it's always in the same place.  The CPU loads the initial
stack pointer from that location but that SP is never used as the POWER-UP
code establishes all pointers before any use is made of the system stack.

SYSTEM-CLOCK is the speed (in Hz) of the CPU clock.  This value may be
used for calculating time constants.
--------------------------------------------------------------------- }

20000000 EQU IRAM               \ Base address of internal SRAM
40000000 EQU IPSBA              \ Internal peripheral system base address
44000000 EQU IFLASHBD           \ Internal flash "back door" address

00000000 0003FFFF CDATA SECTION PROG            \ Code space in flash
20000400 20000FFF IDATA SECTION CONST-DATA      \ Initialized data (skip exception vectors)
20001000 20006FFF UDATA SECTION EXT-DATA        \ Uninitialized data
20007000 20007FFF CDATA SECTION PRAM            \ Program space in RAM for testing

|NUM| |PAD| + RESERVE EQU 'H0                   \ Target dictionary
|S| |TIB| + RESERVE  |S| + EQU 'S0              \ Target data stack + TIB
|R| |U| + RESERVE  |R| + EQU 'R0                \ Target return stack + task user area

'R0 TR0 !  'S0 TS0 !                            \ Set cross-target link pointers

TARGET   DECIMAL  PROG                          \ Establish defaults

CDATA  HERE EQU VECTORS  $420 ALLOT  IDATA      \ Skip vectors, flash config area
VECTORS EQU CHECKSUM

60000000 EQU SYSTEM-CLOCK               \ 5 MHz ref clk, 12x PLL = 60 MHz sys clk
25000000 EQU DEFAULT-CLOCK              \ Default clk, out of reset

52235 EQU CPU                           \ CPU type

19200 EQU BAUD0                         \ Coldfire UART port 0 baud rate
19200 EQU BAUD1                         \ Coldfire UART port 1 baud rate
19200 EQU BAUD2                         \ Coldfire UART port 2 baud rate

0 EQU TARGET-INTERP                     \ Target-resident interpreter (0=no, 1=yes)
TARGET-INTERP [IF]  +HEADS  [THEN]      \ Target heads for resident interpreter
