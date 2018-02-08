{ =====================================================================
LPC-P2103 TARGET ENVIRONMENT CONFIGURATION

Copyright 2006  FORTH, Inc.

The LPC-P2103 board's target environment is configured here.

===================================================================== }

INTERPRETER   HEX

{ ---------------------------------------------------------------------
Memory map

The code and data memory sections are defined here.

The sizes declared in the parent directory's Config.f are used to
allocate target dictionary (PAD and NUM spaces), stacks, and user
area.  The parameter and return stack addresses are also placed in TS0
and TR0 for use by the cross-target link (XTL).

MCLK specifies the speed of the core/memory and PCLK specifies the
speed of the peripheral clocks.  Note that PCLK1 and PCLK2 are set to
the same speed.

This memory map assumes internal RAM is mapped in at 0 (i.e. the BOOT
field in PRCCU_BOOTCR = 10).
--------------------------------------------------------------------- }

INTERPRETER   HEX

00000000 00007FFF CDATA SECTION PROG            \ Code space in flash
40000000 400000FF IDATA SECTION IRAM            \ Initialized data
40000100 40000FFF UDATA SECTION URAM            \ Uninitialized data
40001000 40001FFF CDATA SECTION PRAM            \ Code space in RAM for testing

|NUM| |PAD| + RESERVE EQU 'H0           \ Target dictionary
|S| |TIB| + RESERVE  |S| + EQU 'S0      \ Target data stack + TIB
|R| |U| + RESERVE  |R| + EQU 'R0        \ Target return stack + task user area

'R0 TR0 !  'S0 TS0 !                    \ Set cross-target link pointers

TARGET

0 EQU TARGET-INTERP                     \ Target-resident interpreter (0=no, 1=yes)
TARGET-INTERP [IF]  +HEADS  [THEN]      \ Target heads for resident interpreter

PROG  CDATA  20 ALLOT                   \ Vectors
HERE EQU CHECKSUM  4 ALLOT              \ Checksum in fixed location

DECIMAL  IDATA                          \ Establish defaults

14745600 EQU F(OSC)                     \ Xtal oscillator frequency
   32768 EQU RTCOSC                     \ RTC oscillator frequency
58982400 EQU CCLK                       \ 14.7456 MHz f(osc) * 4
29491200 EQU PCLK                       \ Peripheral clock rate (CCLK/2)

19200 EQU BAUD0                         \ UART0 baud rate (omit if port unused)
\ 19200 EQU BAUD1                         \ UART1 baud rate (omit if port unused)
