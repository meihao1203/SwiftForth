{ =====================================================================
WinIO physical memory and I/O

Copyright 2011 by FORTH, Inc.

===================================================================== }

OPTIONAL WINIO  Physical memory and I/O access

{ --------------------------------------------------------------------
Library interface

This file supplies access to a block of physical memory or to I/O
ports using the WinIO driver and DLL.  The driver must already be
installed and running before using the DLL.

Use the service control manager to create the WinIO driver service:
  sc.exe create create winio type= kernel start= auto binpath= <path>\winio32.sys
  sc.exe start winio

Note that <path> must be the full path to the sys file.  The 'create'
command need only be performed once. The 'start' command is only
needed the first time.  After that, the service starts automatically
on boot.

The WinIo32.dll library provides port I/O and physical memory access.
This is a subset of the library's API calls.

How to use this interface:

1) Driver must be installed and running (see notes on sc.exe above)

2) Call InitializeWinIo before using the other calls.  If it returns
0, you probably don't have the driver installed or running.

3) For physical memory access, use PHYSMEM: below to define a
PhysStruct and pass that address to MapPhysToLin.  Use the address
returned to access the physical memory.  MapPhysToLen returns 0
(NULL) if it can't map in the memory to user space.

4) For port I/O, use GetPortVal and SetPortVal.  The second item on
the stack, pdwPortVal points at a cell in user memory for the actual
value to read/write.
-------------------------------------------------------------------- }

LIBRARY WINIO32

FUNCTION: InitializeWinIo ( -- bool )
FUNCTION: ShutdownWinIo ( -- )
FUNCTION: MapPhysToLin ( &PhysStruct -- addr )
FUNCTION: UnmapPhysicalMemory ( &PhysStruct -- bool )
FUNCTION: GetPortVal ( wPortAddr pdwPortVal bSize -- bool )
FUNCTION: SetPortVal ( wPortAddr pdwPortVal bSize -- bool )

{ --------------------------------------------------------------------
Physical memory access

struct tagPhysStruct layout (compiled by PHYSMEM: below)
   DWORD64 dwPhysMemSizeInBytes
   DWORD64 pvPhysAddress
   DWORD64 PhysicalMemoryHandle
   DWORD64 pvPhysMemLin
   DWORD64 pvPhysSection

Only the first two fields (size and physical address) of a PhysStruct
are supplied by the caller.  The rest is filled in by the call to
MapPhysToLin.  The same struct addr is later passed to
UnmapPhysicalMemory for unmapping the physical memory block.
-------------------------------------------------------------------- }

: PHYSMEM: ( addr len -- )
   CREATE  , 0 ,   , 0 ,  0. , ,  0. , ,  0. , , ;

{ --------------------------------------------------------------------
Port I/O

The 'P' operators perform port I/O.

/PORTS aborts if the WinIO driver can't be initialized.
--------------------------------------------------------------------- }

4 BUFFER: 'PORTVAL

: ?PORT ( bool -- )   0= ABORT" I/O operation failed" ;

: PC@ ( addr -- x )   'PORTVAL 1 GetPortVal ?PORT  'PORTVAL C@ ;
: PW@ ( addr -- x )   'PORTVAL 2 GetPortVal ?PORT  'PORTVAL W@ ;
: P@ ( addr -- x )   'PORTVAL 4 GetPortVal ?PORT  'PORTVAL @ ;

: PC! ( x addr -- )   SWAP 'PORTVAL C!  'PORTVAL 1 SetPortVal ?PORT ;
: PW! ( x addr -- )   SWAP 'PORTVAL W!  'PORTVAL 2 SetPortVal ?PORT ;
: P! ( x addr -- )   SWAP 'PORTVAL !  'PORTVAL 4 SetPortVal ?PORT ;

: /PORTS ( -- )
   InitializeWinIo 0= ABORT" Can't initialize WinIO driver" ;

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
