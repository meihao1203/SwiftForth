{ ====================================================================
WINCON.DLL access

Copyright (C) 2001 FORTH, Inc.

The UNDEFINED chain is extnded here to perform a lookup in the
WINCON.DLL library for Windows constants and return (or compile) their
literal values when found.
==================================================================== }

?( WINCON.DLL access)

{ --------------------------------------------------------------------
WINCON.DLL API

The WINCON library is marked as optional so the turnkey won't require
it in order to run (although it will be required if Windows constants
will need to be looked up).

Imported functions:
  BOOL APIENTRY FindWin32Constant(char *addr, int len, int *value)
  char * APIENTRY FindWM(int msg)
  int APIENTRY EnumWin32Constants(char *addr, int len, ENUMPROC callback)

Callback:
  typedef int (WINAPI *ENUMPROC)(char*, int, int);
-------------------------------------------------------------------- }

[OPTIONAL] LIBRARY WINCON

FUNCTION: FindWin32Constant ( c-addr len addr -- bool )
FUNCTION: EnumWin32Constants ( c-addr len cb -- n )
FUNCTION: FindWM ( n -- z-addr )

{ --------------------------------------------------------------------
Wincon lookup

-WINCONS returns true if the FindWin32Constant function has no address
associated with it (i.e. the function is not available).

WINCONSTANT looks up string c-addr len and returns value x and bool (1
if found).

?WINCON is added to the UNDEFINED chain to convert Windows constants
as if they were literals.
-------------------------------------------------------------------- }

PACKAGE WIN32-CONSTANTS

LIB-INTERFACE +ORDER

: -WINCONS ( -- flag )
   ['] FindWin32Constant >BODY @ 0= ;

LIB-INTERFACE -ORDER

: WINCONSTANT ( c-addr len -- x bool )
   0 >R RP@   FindWin32Constant R> SWAP ;

: ?WINCON ( c-addr len 0 | i*x true -- caddr len 0 | j*x true )
   -WINCONS ?EXIT  ?DUP ?EXIT
   2DUP WINCONSTANT ( a n x f) IF NIP NIP
      STATE @ IF  POSTPONE LITERAL  THEN  1
   ELSE DROP 0 THEN ;

' ?WINCON UNDEFINED >CHAIN

END-PACKAGE
