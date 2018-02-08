{ =====================================================================
Power-up initialization

Copyright 2006  FORTH, Inc.

This should be the last source file loaded.

After POWER-UP completes, it jumps to high-level code in START. This
completes the initialization process and starts the application GO .

===================================================================== }

TARGET

: START ( -- )
   OPERATOR CELL+ STATUS  DUP |U| ERASE  |OPERATOR| CMOVE
   /IDATA  /RTI  /SCIS  GO ;

LABEL POWER-UP                  \ CPU reset vector points here
   SEI                          \ Prevent interrupts
   $53 # LDA   SOPT STA         \ Disable COP watchdog for development
   $38 # LDA   ICGC1 STA        \ low range, xtal, FLL ext ref
   $70 # LDA   ICGC2 STA        \ 32.768 kHz xtal, x18 = 37,748,736
   BEGIN   ICGS1 3 ?SET UNTIL   \ Wait for LOCK
   'R0 # LDHX   U STHX          \ Establish user pointer
   TXS   'S0 # LDHX   CLI       \ Set stacks, enable interrupts
   ' START JMP   END-CODE       \ Transfer to START

POWER-UP V-RESET !C             \ Set reset vector
$C2 NVOPT C!C                   \ Set NVOPT for unsecured mode
SAVE-IDATA  SAVE-CHECKSUM       \ Initial values in PROM image

CDATA LIMITS DROP EQU 0CODE     \ Start of code space in flash
HERE 0CODE - EQU |CODE|         \ Total size of code in flash
IDATA
