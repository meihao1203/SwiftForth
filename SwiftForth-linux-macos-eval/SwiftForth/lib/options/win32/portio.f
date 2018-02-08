{ =====================================================================
Direct port access

Copyright 2006  FORTH, Inc.

===================================================================== }

OPTIONAL PORTIO  Direct I/O port access

{ =====================================================================
Port access is enabled by the GIVEIO driver (installed and started by
the SwiftForth installer) on NT-style systems.

Note: GIVEIO only works on 32-bit Windows systems.

How to use this:

1) In your initialization procedure, call /PORTS to gain access to the
I/O ports using the GIVEIO.SYS driver.  On non-protected versions of
Windows (like Win98), this is basically a no-op.

2) Use the 'P' operators directly, or, for direct LPT port access, place
the base I/O port address in >PD and use the !PD, @PS, and !PC operators
below.

The LPT port register map and pinout are included here as a reference.
Note that you may need to configure your LPT port in your machine's BIOS
setup as required depending on what you're connecting to it.
=======================================================================

LPT PORT PINOUT REFERENCE

PD = Printer Data port
PS = Printer Status port
PC = Printer Control port

             Register  DB-25     I/O
Signal Name    Bit      Pin   Direction
===========  ========  =====  =========
-Strobe         PC0      1      Output
+Data Bit 0     PD0      2      Output
+Data Bit 1     PD1      3      Output
+Data Bit 2     PD2      4      Output
+Data Bit 3     PD3      5      Output
+Data Bit 4     PD4      6      Output
+Data Bit 5     PD5      7      Output
+Data Bit 6     PD6      8      Output
+Data Bit 7     PD7      9      Output
-Acknowledge    PS6     10       Input
+Busy           PS7     11       Input
+Paper End      PS5     12       Input
+Select In      PS4     13       Input
-Auto Feed      PC1     14      Output
-Error          PS3     15       Input
-Initialize     PC2     16      Output
-Select         PC3     17      Output
 Ground          -     18-25       -

===================================================================== }

{ ---------------------------------------------------------------------
I/O port interface

The 'P' operators perform port I/O.

/PORTS opens the GIVEIO driver if GetVersion returns a version number of
a system that requires it.  GIVEIO is installed by the SwiftX installer
for NT, Win2K, XP (etc) systems.
--------------------------------------------------------------------- }

LIBRARY KERNEL32

FUNCTION: GetVersion ( -- addr )

CODE PC@ ( addr -- char )
   EBX EDX MOV   EAX EAX SUB   EDX AL IN
   EAX EBX MOV   RET   END-CODE

CODE PC! ( char addr -- )
   EBX EDX MOV   0 [EBP] EAX MOV   AL EDX OUT
   4 [EBP] EBX MOV   8 # EBP ADD
   RET   END-CODE

CODE P@ ( addr -- x )
   EBX EDX MOV   EDX EAX IN
   EAX EBX MOV   RET   END-CODE

CODE P! ( x addr -- )
   EBX EDX MOV   0 [EBP] EAX MOV   EAX EDX OUT
   4 [EBP] EBX MOV   8 # EBP ADD
   RET   END-CODE

: /NTPORTS ( -- )
   S" \\.\GiveIO" R/W OPEN-FILE  ABORT" Can't open GiveIO driver"
   CLOSE-FILE DROP  $3F8 PC@ DROP ;

: /PORTS ( -- )
   GetVersion 0> IF  ['] /NTPORTS CATCH
   ABORT" Can't access I/O ports"  THEN ;

{ ---------------------------------------------------------------------
Parallel port access

>PD holds the currently selected parallel printer data port address.

!PD writes to the data port.
@PS returns parallel interface status port.
!PC writes to the control port.
--------------------------------------------------------------------- }

VARIABLE >PD

: !PD ( char -- )   >PD @ PC! ;
: @PS ( -- char)   >PD @ 1+ PC@ ;
: !PC ( char -- )   >PD @ 2+ PC! ;
