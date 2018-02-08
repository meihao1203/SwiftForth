{ =====================================================================
TCP for Windows hosts

Copyright 2012  FORTH, Inc.
===================================================================== }

OPTIONAL TCPIP

PACKAGE TCP-HOST

THROW#
   S" Cannot find Winsock v1.1 or later"  >THROW ENUM IOR_WINSOCK
TO THROW#

{ --------------------------------------------------------------------
Winsock initialization

WSAStartup initializes Winsock.  It must be called before any other
Winsock functions.

WSACleanup must be once called for each successful call to WSAStartup,
according to MSDN.
-------------------------------------------------------------------- }

LIBRARY WSOCK32

FUNCTION: WSAStartup ( wVersionRequired lpWSAData -- int )
FUNCTION: WSACleanup ( -- int )
FUNCTION: WSAGetLastError ( -- err# )

: OPEN-SOCKS ( -- )   $101 PAD WSAStartup  IOR_WINSOCK ?THROW ;
:ONSYSLOAD   OPEN-SOCKS ;
OPEN-SOCKS

: CLOSE-SOCKS ( -- )   WSACleanup DROP ;
:ONSYSEXIT   CLOSE-SOCKS ;

PUBLIC VARIABLE SOCK-LAST-ERROR PRIVATE

: GET-SOCK-ERROR ( -- )  WSAGetLastError SOCK-LAST-ERROR ! ;

{ --------------------------------------------------------------------
Winsock interface
-------------------------------------------------------------------- }

FUNCTION: closesocket ( s -- int )

3 CELLS CONSTANT h_addr_list    \ offset into hostent for gethostbyname

{ --------------------------------------------------------------------
Error logging

Compatibility with embedded Linux TCP/IP source.
-------------------------------------------------------------------- }

: ?ERRNO ( errno c-addr u -- )   2DROP THROW ;

REQUIRES ip
REQUIRES udp
REQUIRES tcp

END-PACKAGE
