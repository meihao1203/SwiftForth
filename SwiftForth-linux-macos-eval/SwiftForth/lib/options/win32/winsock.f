{ ====================================================================
WinSOck import library

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL WINSOCK The import library for WSOCK32 API functions

LIBRARY WSOCK32

AS accept() FUNCTION: accept ( s 'sock 'len -- SOCKET )
FUNCTION: bind ( s 'sock namelen -- int )
FUNCTION: closesocket ( s -- int )
FUNCTION: connect ( s 'sock len -- int )
FUNCTION: ioctlsocket ( s cmd *argp -- int )
FUNCTION: getpeername ( s sockaddr *namelen -- int )
FUNCTION: getsockname ( s sockaddr *namelen -- int )
FUNCTION: getsockopt ( s level optname *optval *optlen -- int )
FUNCTION: htonl ( hostlong -- u_long )
FUNCTION: htons ( hostshort -- u_short )
FUNCTION: inet_addr ( *cp -- in_addr )
FUNCTION: inet_ntoa ( in_addr -- *char )
FUNCTION: listen ( s backlog -- int )
FUNCTION: ntohl ( netlong -- u_long )
FUNCTION: ntohs ( netshort -- u_short )
FUNCTION: recv ( s *buf len flags -- int )
FUNCTION: recvfrom ( s *buf len flags *from *fromlen -- int )
FUNCTION: select ( nfds *readfds *writefds *exceptfds *timeout -- int )
FUNCTION: send ( s *buf len flags -- int )
FUNCTION: sendto ( s *buf len flags *to tolen -- int )
FUNCTION: setsockopt ( s level optname *optval optlen -- int )
FUNCTION: shutdown ( s how -- int )
FUNCTION: socket ( af type protocol -- SOCKET )
FUNCTION: gethostbyaddr ( *addr len type -- hostent )
FUNCTION: gethostbyname ( *name -- hostent )
FUNCTION: gethostname ( *name namelen -- int )
FUNCTION: getservbyport ( port *proto -- servent )
FUNCTION: getservbyname ( *name *proto -- servent )
FUNCTION: getprotobynumber ( proto -- servent )
FUNCTION: getprotobyname ( *name -- servent )

FUNCTION: WSAStartup ( wVersionRequired lpWSAData -- int )
FUNCTION: WSACleanup ( -- int )
FUNCTION: WSASetLastError ( iError -- )
FUNCTION: WSAGetLastError ( -- int )
FUNCTION: WSAIsBlocking ( -- bool )
FUNCTION: WSAUnhookBlockingHook ( -- int )
FUNCTION: WSASetBlockingHook ( lpBlockFunc -- farproc )
FUNCTION: WSACancelBlockingCall ( -- int )
FUNCTION: WSAAsyncGetServByName ( hWnd wMsg *name *proto *buf buflen -- h )
FUNCTION: WSAAsyncGetServByPort ( hWnd wMsg port *proto *buf buflen -- h )
FUNCTION: WSAAsyncGetProtoByName ( hWnd wMsg *name *buf buflen -- h )
FUNCTION: WSAAsyncGetProtoByNumber ( hWnd wMsg number *buf buflen -- h )
FUNCTION: WSAAsyncGetHostByName ( hWnd wMsg *name *buf buflen -- h )
FUNCTION: WSAAsyncGetHostByAddr ( hWnd wMsg *addr len type *buf buflen -- h )
FUNCTION: WSACancelAsyncRequest ( hAsyncTaskh -- int )
FUNCTION: WSAAsyncSelect ( s hWnd wMsg lEvent -- int )
FUNCTION: WSARecvEx ( s *buf len *flags -- int )

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CLASS WSADATA
   HVARIABLE VERSION
   HVARIABLE HIGHVERSION
   257 BUFFER: DESCRIPTION
   129 BUFFER: SYSTEMSTATUS
   HVARIABLE MAXSOCKETS
   HVARIABLE MAXUDPDG
   VARIABLE LPVENDORINFO
END-CLASS

CLASS SOCKADDR_IN
   HVARIABLE SIN_FAMILY
   HVARIABLE SIN_PORT
   VARIABLE IN_ADDR
   8 BUFFER: SIN_ZERO
END-CLASS

CLASS SOCKADDR
   HVARIABLE SA_FAMILY
   14 BUFFER: SA_DATA
END-CLASS

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

WSADATA SUBCLASS WINSOCK

   : CLOSE ( -- )   WSACleanup DROP ;

   : OPEN ( ver -- ior )
      DUP  ADDR WSAStartup DUP IF  NIP EXIT  THEN DROP
      VERSION U@ <> DUP IF  CLOSE  THEN ;

   MAX_PATH BUFFER: HOSTNAME

   : GetLocalAddress ( -- zaddr )
      HOSTNAME 256 gethostname SOCKET_ERROR <> IF
         HOSTNAME gethostbyname ?DUP IF ( ^hostent)
            3 CELLS + @ @ @ inet_ntoa EXIT
         THEN
      THEN 0 ;

END-CLASS
