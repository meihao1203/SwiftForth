{ =====================================================================
TARGET ENVIRONMENT CONFIGURATION

Copyright 2006 FORTH, Inc.

The CMS-8GB60 target environment is configured here.

===================================================================== }

INTERPRETER   HEX

{ ---------------------------------------------------------------------
Memory map

The code and data memory sections are defined here.
--------------------------------------------------------------------- }

0080 00FF UDATA SECTION IREG            \ Internal "register" RAM
0100 01FF IDATA SECTION IRAM            \ Initialized data
0200 0BFF UDATA SECTION URAM            \ Uninitialized data
0C00 107F CDATA SECTION PRAM            \ Code space in SRAM for testing
1900 FFFF CDATA SECTION PROG            \ Code space in flash memory

URAM

|PAD| |NUM| + RESERVE EQU 'H0           \ Target dictionary
|S| |TIB| + RESERVE  |S| + EQU 'S0      \ Target data stack + TIB
|R| |U| + RESERVE  |R| + EQU 'R0        \ Target return stack + task user area
'S0 TS0 !  'R0 TR0 !                    \ Set cross-target link pointers

DECIMAL
37748736 ( Hz CPU clock) 2/ EQU BUSCLK  \ CPU clock / 4 = Bus clock
32768 EQU EXTCLK                        \ External clock
8000000 EQU DEFCLK                      \ Default clock out of reset

TARGET  PROG  IRAM  URAM  IDATA         \ Establish defaults

{ ---------------------------------------------------------------------
Serial ports

BAUDx defines the baud rate for serial port SCIx.  Omit if the port
is not to be configured.
--------------------------------------------------------------------- }

9600 EQU BAUD1                          \ Baud rate for SCI1
9600 EQU BAUD2                          \ Baud rate for SCI2
