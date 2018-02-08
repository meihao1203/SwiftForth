{ =====================================================================
DIECIMILA ENVIRONMENT CONFIGURATION

Copyright 2010  FORTH, Inc.

The Diecimila board with ATmega168 MCU target environment is
configured here.

===================================================================== }

INTERPRETER   HEX

{ ---------------------------------------------------------------------
Memory map

The code and data memory sections are defined here.

The sizes declared in the parent directory's Config.f are used to
allocate target memory, stacks, and user area.

The parameter and return stack addresses are also placed in TS0 and
TR0 for use by the cross-target link (XTL).

CPUCLOCK is the speed (in Hz) of the CPU clock.  This value is used
for calculating timer settings.
--------------------------------------------------------------------- }

0000 3FFF CDATA SECTION FLASH           \ Flash code space (byte addressed)
0100 017F IDATA SECTION IRAM            \ Internal initialized data
0180 04FF UDATA SECTION URAM            \ Internal uninitialized data

|NUM| |PAD| + RESERVE EQU 'H0           \ Target NUM and PAD buffers
|S| RESERVE  |S| + EQU 'S0              \ Target data stack
|R| |U| + RESERVE  |R| + EQU 'R0        \ Target return stack + task user area
'S0 TS0 !  'R0 TR0 !                    \ Set cross-target link pointers

TARGET  DECIMAL  IDATA

0 EQU TARGET-INTERP                     \ Target-resident interpreter (0=no, 1=yes)
TARGET-INTERP [IF]  +HEADS  [THEN]      \ Target heads for resident interpreter

16000000 EQU CPUCLOCK                   \ CPU clock speed
38400 XTL-BAUD                          \ Serial XTL baud rate
$D7FF EQU FUSEBYTES                     \ Fuse bytes for this board
