{ =====================================================================
LPC-P2103 INITIALIZATION

Copyright 2007  FORTH, Inc.

This file supplies the power-up initialization code for the LPC-P2103
board as well download and flash progamming support.

===================================================================== }

TARGET

{ ---------------------------------------------------------------------
System start-up

START performs high-level system initialization and passes control to
GO which may be redefined to start your application.  The default GO
supplied in the kernel awaits commands from the cross-target link.

0CODE and |CODE| define the start and size of code space.

POWER-UP is the flash-resident initialization code.  It performs any
necessary low-level configuration and initialization, then passes
control to START above.

The address of the POWER-UP routine is placed into the SWI vector.  The
0 SWI instruction forces the CPU to POWER-UP via the SWI vector with the
CPU in a known state.
--------------------------------------------------------------------- }

: START ( -- )
   OPERATOR CELL+ STATUS  DUP |U| ERASE  |OPERATOR| CMOVE
   /IDATA  /TIMER0  /RTC  /UARTS  GO ;

HEX

LABEL POWER-UP
   PRIV_STK R1 LDRI                                             \ Privileged modes stack memory
   D1 CPSR_c MSR   |R| R1 R1 ADD   R1 R MOV                     \ Fast interrupt
   D2 CPSR_c MSR   |R| R1 R1 ADD   R1 R MOV                     \ Interrupt
   D7 CPSR_c MSR   |R| R1 R1 ADD   R1 R MOV                     \ Abort
   DB CPSR_c MSR   |R| R1 R1 ADD   R1 R MOV                     \ Undefined
   13 CPSR_c MSR   'S0 S LDRI   'R0 R LDRI   R U MOV            \ Supervisor (SwiftX kernel normal mode)

   SCB_BASE R0 LDRI                                             \ Initialize PCLK and CCLK using PLL
   2 R1 MOV   VPBDIV R0+ R1 STR                                 \ PCLK = CCLK/2
   23 R1 MOV   PLLCFG R0+ R1 STR                                \ CCLK=F(osc)*4
   01 R1 MOV   PLLCON R0+ R1 STR                                \ PLL enabled, but not yet connected
   AA R1 MOV   PLLFEED R0+ R1 STR
   55 R1 MOV   PLLFEED R0+ R1 STR                               \ Load PLL config
   BEGIN   PLLSTAT R0+ R1 LDR   400 R1 R1 ANDS   0= NOT UNTIL   \ Wait for PLOCK
   03 R1 MOV   PLLCON R0+ R1 STR                                \ PLL enabled and connected
   AA R1 MOV   PLLFEED R0+ R1 STR
   55 R1 MOV   PLLFEED R0+ R1 STR                               \ Load PLL config
   3 R1 MOV   MAMTIM R0+ R1 STR                                 \ MAM timing = 3 for cclk > 40 MHz
   2 R1 MOV   MAMCR R0+ R1 STR                                  \ MAM fully enabled

   PCB_BASE R0 LDRI
   00000005 R1 MOV   PINSEL0 R0+ R1 STR                         \ UART0 pins

   ' START B   END-CODE

SAVE-SECTIONS  CDATA
   LIMITS DROP  HERE OVER - EQU |CODE|  EQU 0CODE

HERE ( *)   0CODE ORG

( IRQ vect addr) 18 8 + VICVectAddr - EQU 'VA

LABEL ENTRY
   0 SWI                \ 00  Reset - use SWI to force int priv mode and go to POWER-UP
   BEGIN B              \ 04  Undefined instruction
   POWER-UP B           \ 08  SWI
   BEGIN B              \ 0C  Abort (prefetch)
   BEGIN B              \ 10  Abort (data)
   0 ,                  \ 14  Reserved (bootloader checksum)
   'VA PC- PC LDR       \ 18  IRQ (load dest from VICVectAddr)
   BEGIN B              \ 1C  FIQ
   END-CODE

INTERPRETER

: !SUMCHECK ( -- )
   0  20 0 DO  0CODE I + @ +  CELL +LOOP
   NEGATE  0CODE 14 + ! ;

TARGET  !SUMCHECK

( *) ORG   RESTORE-SECTIONS

DECIMAL

SAVE-IDATA  SAVE-CHECKSUM

{ ---------------------------------------------------------------------
Burn target flash image

BURN programs the downloaded program into flash.

RELOAD establishes a connection with the target kernel in flash,
compares the target's checksum with the one in the host image, and calls
BURN to reprogram the flash if they're different.
--------------------------------------------------------------------- }

INTERPRETER

: BURN ( -- )
   0CODE |CODE| PROGRAM-FLASH ;

: RELOAD ( -- )
   JTAG-OPEN  JTAG-CONNECT? DUP IF  -CHECKSUM XOR  THEN
   0= IF  BURN  JTAG-CONNECT? NOT ABORT" No response from target"  THEN
   CONNECT TARGET ;

TARGET
