{ =====================================================================
InpOut32 library interface

Copyright 2011 by FORTH, Inc.

===================================================================== }

OPTIONAL INPOUT32  I/O port access

{ --------------------------------------------------------------------
Library interface

Original InpOut32 function support
  void    _stdcall Out32(short PortAddress, short data);
  short   _stdcall Inp32(short PortAddress);

Driver query functions
  BOOL    _stdcall IsInpOutDriverOpen();  //Returns TRUE if the InpOut driver was opened successfully
  BOOL    _stdcall IsXP64Bit();           //Returns TRUE if the OS is 64bit (x64) Windows.

DLLPortIO function support
  UCHAR   _stdcall DlPortReadPortUchar (USHORT port);
  void    _stdcall DlPortWritePortUchar(USHORT port, UCHAR Value);

  USHORT  _stdcall DlPortReadPortUshort (USHORT port);
  void    _stdcall DlPortWritePortUshort(USHORT port, USHORT Value);

  ULONG   _stdcall DlPortReadPortUlong(ULONG port);
  void    _stdcall DlPortWritePortUlong(ULONG port, ULONG Value);

WinIO function support
  PBYTE   _stdcall MapPhysToLin(PBYTE pbPhysAddr, DWORD dwPhysSize, HANDLE *pPhysicalMemoryHandle);
  BOOL    _stdcall UnmapPhysicalMemory(HANDLE PhysicalMemoryHandle, PBYTE pbLinAddr);
  BOOL    _stdcall GetPhysLong(PBYTE pbPhysAddr, PDWORD pdwPhysVal);
  BOOL    _stdcall SetPhysLong(PBYTE pbPhysAddr, DWORD dwPhysVal);
--------------------------------------------------------------------- }

LIBRARY INPOUT32

FUNCTION: Out32 ( pa char -- )
FUNCTION: Inp32 ( pa -- char )
FUNCTION: IsInpOutDriverOpen ( -- bool )
FUNCTION: IsXP64Bit ( -- bool )
FUNCTION: DlPortReadPortUchar ( pa -- x )
FUNCTION: DlPortWritePortUchar ( pa x -- )
FUNCTION: DlPortReadPortUshort  ( pa -- x )
FUNCTION: DlPortWritePortUshort ( pa x -- )
FUNCTION: DlPortReadPortUlong ( pa -- x )
FUNCTION: DlPortWritePortUlong ( pa x -- )
FUNCTION: MapPhysToLin ( pbPhysAddr dwPhysSize *pPhysicalMemoryHandle -- addr )
FUNCTION: UnmapPhysicalMemory ( PhysicalMemoryHandle pbLinAddr -- bool )
FUNCTION: GetPhysLong ( pbPhysAddr pdwPhysVal -- bool )
FUNCTION: SetPhysLong ( pbPhysAddr dwPhysVal -- bool )

{ ---------------------------------------------------------------------
I/O port interface

The 'P' operators perform port I/O (byte, word, cell).

/PORTS aborts if the InpOut driver is not open.
--------------------------------------------------------------------- }

: PC@ ( addr -- x )   DlPortReadPortUchar ;
: PW@ ( addr -- x )   DlPortReadPortUshort ;
: P@ ( addr -- x )   DlPortReadPortUlong ;

: PC! ( x addr -- )   SWAP DlPortWritePortUchar ;
: PW! ( x addr -- )   SWAP DlPortWritePortUshort ;
: P! ( x addr -- )   SWAP DlPortWritePortUlong ;

: /PORTS ( -- )
   IsInpOutDriverOpen 0= ABORT" Can't access I/O ports" ;

{ ---------------------------------------------------------------------
Parallel port access

>PD holds the currently selected parallel printer data port address.

!PD writes to the data port.
@PS returns parallel interface status port.
!PC writes to the control port.

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
--------------------------------------------------------------------- }

VARIABLE >PD

: !PD ( char -- )   >PD @ PC! ;
: @PS ( -- char)   >PD @ 1+ PC@ ;
: !PC ( char -- )   >PD @ 2+ PC! ;
