{ ====================================================================
Network sockets interface

Copyright (C) 2008 FORTH, Inc.   All rights reserved.

The socket and network functions in libc are imported here.
==================================================================== }

OPTIONAL SOCKETS Socket and network functions

LIBRARY libc.so.6

FUNCTION: gethostbyname ( addr1 -- addr2 )
FUNCTION: getservbyname ( *name *proto -- *servent )
FUNCTION: socket ( domain type proto -- s )
FUNCTION: connect ( s *servaddr addrlen -- ior )
FUNCTION: shutdown ( s how -- ior )
FUNCTION: recv ( s *buf len flags -- u )
FUNCTION: send ( s *buf len flags -- u )
FUNCTION: recvfrom ( s *buf len flags *from fromlen -- u )
FUNCTION: sendto ( s *buf len flags *to tolen -- u )

2 CONSTANT PF_INET              \ Internet protocol family
2 CONSTANT AF_INET              \ Internet address family
1 CONSTANT SOCK_STREAM          \ Stream-oriented protocols (e.g. TCP)
2 CONSTANT SOCK_DGRAM           \ Datagram protocols (e.g. UDP)
-1 CONSTANT SOCKET_ERROR        \ ior for error

\\

struct servent {
        char    *s_name;        /* official service name */
        char    **s_aliases;    /* alias list */
        int     s_port;         /* port number */
        char    *s_proto;       /* protocol to use */
}

/* Structure describing an Internet (IP) socket address. */
#define __SOCK_SIZE__   16              /* sizeof(struct sockaddr)      */
struct sockaddr_in {
  sa_family_t           sin_family;     /* Address family               */
  unsigned short int    sin_port;       /* Port number                  */
  struct in_addr        sin_addr;       /* Internet address             */

  /* Pad to size of `struct sockaddr'. */
  unsigned char         __pad[__SOCK_SIZE__ - sizeof(short int) -
                        sizeof(unsigned short int) - sizeof(struct in_addr)];
};

