{ =====================================================================
TCP for Linux hosts

Copyright 2012  FORTH, Inc.

===================================================================== }

OPTIONAL TCPIP

PACKAGE TCP-HOST

{ --------------------------------------------------------------------
Winsock compatibility
-------------------------------------------------------------------- }

: closesocket ( s -- int )   close ;
: OPEN-SOCKS ;

{ --------------------------------------------------------------------
Socket interface
-------------------------------------------------------------------- }

-1 CONSTANT INVALID_SOCKET
-1 CONSTANT SOCKET_ERROR
6 CONSTANT IPPROTO_TCP

4 CELLS CONSTANT h_addr_list    \ offset into hostent for gethostbyname

{ --------------------------------------------------------------------
Error logging

Compatibility with embedded Linux TCP/IP source.
-------------------------------------------------------------------- }

: ?ERRNO ( errno c-addr u -- )   2DROP THROW ;

LIBRARY libc.dylib

REQUIRES ip
REQUIRES udp
REQUIRES tcp

END-PACKAGE
