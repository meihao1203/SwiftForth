{ ====================================================================
Network sockets interface

Copyright (C) 2008 FORTH, Inc.   All rights reserved.

The socket and network functions in libc are imported here.
==================================================================== }

OPTIONAL SOCKETS Socket and network functions

LIBRARY libc.dylib

FUNCTION: gethostbyname ( addr1 -- addr2 )
FUNCTION: getservbyname ( *name *proto -- *servent )
FUNCTION: socket ( domain type proto -- s )
FUNCTION: connect ( s *servaddr addrlen -- ior )
FUNCTION: shutdown ( s how -- ior )
FUNCTION: recv ( s *buf len flags -- u )
FUNCTION: send ( s *buf len flags -- u )
FUNCTION: recvfrom ( s *buf len flags *from fromlen -- u )
FUNCTION: sendto ( s *buf len flags *to tolen -- u )
FUNCTION: bind ( sockfd *addr addrlen -- n )
FUNCTION: getsockopt ( sockfd level optname *optval optlen -- n )
FUNCTION: setsockopt ( sockfd level optname *optval *optlen -- n )
