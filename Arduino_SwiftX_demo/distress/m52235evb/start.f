{ =====================================================================
Coldfire Initialization

Copyright 2006  FORTH, Inc.

This file supplies the power-up initialization code for the M52235EVB
as well as BDM initialization and download support.

===================================================================== }

TARGET   HEX   IDATA

{ ---------------------------------------------------------------------
System start-up

START performs high-level system initialization and passes control to GO
which may be redefined to start your application.  The default GO
supplied in the kernel awaits commands from the cross-target link. The
write to RAMBAR in START enables BDE (module access to SRAM).  This is
the SCM RAMBAR, not the one in CPU space!

POWER-UP is the flash-resident reset code.  The address of the POWER-UP
routine is placed into the reset vector.  It performs low-lever
initialization and passes control to START above.

0CODE and |CODE| define the start and size of code space.
--------------------------------------------------------------------- }

VARIABLE NI

: START ( -- )
   IRAM $200 + RAMBAR !
   OPERATOR CELL+ STATUS  DUP |U| ERASE  |OPERATOR| CMOVE
   /IDATA  /EXCEPTIONS  /TIMER  /UARTS  GO ;

LABEL POWER-UP
   2700 #W MTSR                                 \ No interrupts, supervisor mode
   0 #Q D0 MOV   D0 CWCR AB B. MOV              \ Disable watchdog
   D0 VBR MOVEC                                 \ Temporary VBR = 0 for initialization
   04 #Q D0 MOV   D0 CCHR AB B. MOV             \ Pre-divide = /5 (25 MHz input --> 5 MHZ refclk)
   4003 #W D0 MOV    D0 SYNCR AB W. MOV         \ Set PLL for 60 MHz (5 MHz ref * 12) operation
   SYNSR AB A0 LEA                              \ Monitor SYNSR for PLL status
   BEGIN   3 # A0 ) BTST   0= NOT UNTIL         \ Spin until LOCK
   2 # D0 BSET   D0 SYNCR AB W. MOV             \ Switch over to PLL output
   IRAM $21 + # D0 MOV   D0 RAMBAR MOVEC        \ RAMBAR = internal SRAM
   $55 #Q D0 MOV   D0 PUAPAR AB B. MOV          \ Set PUA, PUB, PUC for primary (UART) functions
   D0 PUBPAR AB B. MOV   D0 PUCPAR AB B. MOV
   $0F #Q D0 MOV   D0 DDRTC AB B. MOV           \ Port TC[3:0] outputs
   PORTTC AB B. CLR                             \ All off
   'R0 AB U LEA   U R MOV   'S0 AB S LEA
   IMRH0 AB CLR   IMRL0 AB CLR                  \ Unmask interrupts, use ICR's for individual control
   IMRH1 AB CLR   IMRL1 AB CLR
   ' START BRA   END-CODE

SAVE-IDATA  SAVE-CHECKSUM

CDATA LIMITS DROP EQU 0CODE
HERE 0CODE - EQU |CODE|
POWER-UP 0CODE 4 + !

\ CFM Configuration Field
   0 0CODE 408 + !      \ CFMPROT
   0 0CODE 40C + !      \ CFMSACC
   0 0CODE 410 + !      \ CFMDACC

IDATA

{ --------------------------------------------------------------------
BDM initialization

/CPU initializes the CPU for BDM XTL operation.
-------------------------------------------------------------------- }

INTERPRETER

: /CPU ( -- )
   RESET-BDM
   2700 %SR !REG            \ Supervisor mode, no interrupts
   IRAM 21 + %RAMBAR !REG   \ Initialize RAMBAR to enable internal RAM
   0FF PDDPAR C!(B)         \ Set PDD to "Primary" functions for BDM
   POWER-UP %PC !REG ;      \ BDM boot flag in A7

DECIMAL  TARGET
