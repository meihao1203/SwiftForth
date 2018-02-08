{ =====================================================================
FET430P120 TARGET ENVIRONMENT CONFIGURATION

Copyright 2001  FORTH, Inc.

The target environment is configured here for the MSP-FET430P120
as shipped with the MSP430F1232.

The F1232 part does not contain enough RAM to support on-the-fly
downloading of test code.  Program changes require reprogramming
the flash.

===================================================================== }

INTERPRETER   HEX

{ ---------------------------------------------------------------------
Memory map

The code and data memory sections are defined here.

The parameter and return stack addresses are also placed in TS0 and TR0
for use by the cross-target link (XTL).
--------------------------------------------------------------------- }

HEX

0200 020F IDATA SECTION IRAM            \ Initialized data
0210 02FF UDATA SECTION URAM            \ Uninitialized data
E000 FFFF CDATA SECTION PROG            \ Main program in flash memory

|NUM| RESERVE EQU 'H0                   \ Number conversion area (no room for PAD)
|S| RESERVE  |S| + EQU 'S0              \ Target data stack
|R| |U| + RESERVE  |R| + EQU 'R0        \ Target return stack + task user area

'S0 TS0 !  'R0 TR0 !                    \ Set cross-target link pointers
LPM3 EQU LPMODE                         \ Establish low-power mode
DECIMAL  TARGET  IDATA                  \ Defaults
