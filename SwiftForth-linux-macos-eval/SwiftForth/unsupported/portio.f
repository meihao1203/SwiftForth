{ ====================================================================
(C) Copyright 1999 FORTH, Inc.   www.forth.com

Port I/O interface to TVICHW32
==================================================================== }

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

{ --------------------------------------------------------------------
This requires TVICHW32.DLL to be in the system path and either

a) VICHW11.VXD in \WINDOWS\SYSTEM (for win95) or
b) VICHW11.SYS in \WINNT\SYSTEM32\DRIVERS (for winnt)

The install procedure placed the proper files in their directories.

Please note that response time is never guaranteed under the Windows
environment and that Forth, Inc. cannot be held responsible for
programs using these drivers.
-------------------------------------------------------------------- }

LIBRARY TVICHW32.DLL

0 IMPORT: OpenTVicHW32                 ( -- bool )
0 IMPORT: CloseTVicHW32                ( -- x )
0 IMPORT: IsDriverOpened               ( -- bool )
2 IMPORT: MapPhysToLinear              ( addr n -- addr )
1 IMPORT: ReadPort                     ( port -- n )
1 IMPORT: ReadPortW                    ( port -- n )
1 IMPORT: ReadPortL                    ( port -- n )
2 IMPORT: WritePort                    ( port n -- x )
2 IMPORT: WritePortW                   ( port n -- x )
2 IMPORT: WritePortL                   ( port n -- x )
1 IMPORT: SetHardAccess                ( bool -- x )
0 IMPORT: TestHardAccess               ( -- bool )
2 IMPORT: SetIRQ                       ( irqn addr -- x )
0 IMPORT: IsIRQSet                     ( -- bool )
0 IMPORT: UnMaskIRQ                    ( -- x )
0 IMPORT: MaskIRQ                      ( -- x )
0 IMPORT: IsMasked                     ( -- bool )
0 IMPORT: DestroyIRQ                   ( -- x )
0 IMPORT: GetInterruptCounter          ( -- n )
0 IMPORT: SimulateHWInt                ( -- x )

\ Note: All bool values must be masked with $0FF to be valid here.

{ --------------------------------------------------------------------
Sample API

/PORTS must be run before accessing port i/o.

PORTS/ ends the port i/o session. Not needed unless you desire
   to free a port resource for another application.

P@ and PC@ read an arbitrary port while
P! and PC! write a value to an arbitrary port.
-------------------------------------------------------------------- }

1 IMPORT: GetVersionEx ( ^verinfo -- flag )

: /PORTS ( -- )
   OpenTVicHW32 $0FF AND 0= THROW
   5 CELLS 128 +  DUP R-ALLOC >R  R@ !  R@ GetVersionEx DROP
   R> 4 CELLS + @ VER_PLATFORM_WIN32_NT = IF  1 SetHardAccess DROP  THEN ;

: PORTS/ ( -- )
   CloseTVicHW32 DROP ;

: P@ ( port -- n )   ReadPortL ;
: PC@ ( port -- n )   ReadPort ;

: P! ( n port -- )   SWAP WritePortL DROP ;
: PC! ( n port -- )   SWAP WritePort DROP ;

\\ ------------------------------------------------------------------

CONTENTS
========

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

1. GENERAL TVicHW32 FUNCTIONS
2. DIRECT MEMORY ACCESS WITH TVicHW32
3. DIRECT PORT I/O WITH TVicHW32
4. HARDWARE INTERRUPT HANDLING WITH TVicHW32
5. CONTACT INFORMATION



1. GENERAL TVicHW32 FUNCTIONS
====================================================

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

TVicHW32 has the following general functions:

    bool  VICFN OpenTVicHW32(void);
    -------------------------------
    Loads the vichwXX.vxd (under Windows 95) or vichwXX.sys (under
    Windows NT) kernel-mode driver, providing direct access to the
    hardware. If the kernel-mode driver was successfully opened, the
    IsDriverOpened() returns True; if the function fails, the IsDriverOpened()
    returns False.

    void  VICFN CloseTVicHW32(void);
    ----------------------
    Closes the kernel-mode driver and releases memory allocated to it.
    If a hardware interrupt was "unmasked", the "mask" is restored. If the
    driver was successfully closed, the IsDriverOpened() always returns False.

    bool VICFN IsDriverOpened (void);
    ----------------------------------------------

    This boolean function specifies whether the kernel-mode driver is open.
    Returns True if the driver is already open, or False if it is not.


2. DIRECT MEMORY ACCESS WITH TVicHW32
=====================================

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

The following function permits direct memory acccess:

    void* VICFN MapPhysToLinear(DWORD PhAddr, DWORD Size);
    ---------------------------------------- ----------------------
    Maps a specific physical address to a pointer in linear memory,
    where PhAddr is the base address and Size is the actual number of
    bytes to which access is required.

    Note that a subsequent call to MapPhysToLinear invalidates the
    previous pointer.

    The following example returns a pointer to the system ROM BIOS area:

    char *pBios;

    OpenVicHW32();

    if (IsDriverOpened()) {

       pBios = MapPhysToLinear (0xF8000,256); //255 bytes beginning at $F8000

       //...working with pBIOS...

       CloseVicHW32();

     }

     else ...  //  failed

3. DIRECT PORT I/O WITH TVicHW32
================================

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

The following functions permit direct I/O port access:
------------------------------------------------------

    BYTE  VICFN ReadPort   (WORD wPortAddress);              // read one byte
    WORD  VICFN ReadPortW  (WORD wPortAddress);              // read one word
    DWORD VICFN ReadPortL  (WORD wPortAddress);              // read four bytes
    void  VICFN WritePort  (WORD wPortAddress, BYTE bData);  // write one byte
    void  VICFN WritePortW (WORD wPortAddress, WORD wData);  // write one word
    void  VICFN WritePortL (WORD wPortAddress, DWORD lData); // write four bytes


    void  VICFN SetHardAccess(bool HardAccess);
    -------------------------------------------
    The SetHardAccess() function determines whether the kernel-mode driver
    should use "hard" or "soft" access to the I/O ports. If set to True
    "hard" access is employed; if set to False "soft" access is employed.

    "Soft" access provides higher performance access to ports, but may fail
    if the port(s) addressed are already in use by another kernel-mode
    driver. While slower, "Hard" access provides more reliable access to
    ports which have already been opened by another kernel-mode driver.

    bool  VICFN TestHardAccess(void);
    ---------------------------------
    Returns True is "hard" access is used.

4. HARDWARE INTERRUPT HANDLING WITH TVicHW32
============================================

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

In a Win32 environment, hardware interrupts are normally prohibited
by Windows; the TVicHW32 kernel-mode driver allows you to use the
interrupt for direct handling by your application. Note that only one
interrupt can be handled at a time.

The following functions permit access to hardware interrupts.

    void  VICFN SetIRQ(BYTE IRQNumber, void * lpfnOnHwInterrupt);
    -------------------------------------------------------------

    Assign the interrupt specified by the IRQNumber value (1..15) to
    the lpfnOnHwInterrrupt() handler. If success then IsIRQSet() function
    (see below) returns True.
    Note that IRQ0 (the system timer) is *not* supported.

    bool  VICFN IsIRQSet(void);
    ----------------------------------------
    Specifies whether the hardware interrupt handler has been
    created by the SetIRQ method.


    void  VICFN UnMaskIRQ(void);
    ----------------------------
    Physically unmasks the hardware interrupt specified by the IRQNumber
    property, so that an lpfnOnHWInterrupt function will be generated
    when a hardware interrupt occurs.

    void  VICFN MaskIRQ(void);
    --------------------------
    Physically masks the hardware interrupt specified by the IRQNumber value.

    bool  VICFN IsMasked(void);
    ---------------------------
    Function which specifies whether the hardware interrupt
    handler has been physically masked (True).


    void  VICFN DestroyIRQ(void);
    -----------------------------
    Frees the memory and code previously assigned for the hardware
    interrupt specified by the IRQNumber value.

    DWORD VICFN GetInterruptCounter(void);
    --------------------------------------
    Function which counts the number of hardware interrupts
    intercepted by the TVicHW32 kernel-mode driver. The GetInterruptCounter()
    function is provided largely for debugging purposes, allowing you to
    compare the actual number of hardware interrupts generated with the
    number processed by your application.


    void  VICFN SimulateHWInt(void);
    -------------------------------
    This function is provided for purposes of debugging, and allows you to
    simulate a hardware interrupt. When this procedure is called, the TVicHW32
    kernel-mode driver will feign a "hardware interrupt", without directly
    affecting the hardware.


5. CONTACT INFORMATION
======================

OPTIONAL PORTIO Hard I/O for Windows NT/95 via TVICHW32.DLL and VICHW11.VXD (win95) or VICHW11.SYS (nt).

    Comments, questions and suggestions regarding TVicHW32 under SwiftForth
    can be directed by e-mail to forthhelp@forth.com .





