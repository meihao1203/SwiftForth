{ ====================================================================
Internet Protocol (IP) foundation

Copyright 2011  FORTH, Inc.

==================================================================== }

OPTIONAL IP-BASE

{ --------------------------------------------------------------------
Throw codes
-------------------------------------------------------------------- }

THROW#
   S" read: EOF"                 >THROW ENUM IOR_READ_EOF
   S" Unexpected sockaddr size"  >THROW ENUM IOR_SOCKADDR_SIZE
   S" UDP-READ: short read"      >THROW ENUM IOR_UDP_SHORT_READ
   S" UDP-WRITE: short write"    >THROW ENUM IOR_UDP_SHORT_WRITE
TO THROW#

{ --------------------------------------------------------------------
Utilities

SHUCK discards any leading occurrences of char from the input stream.

+OCTET gets the next octet from the string and accumulates it to u1.

DQ gets a dotted quad from the input stream, or dies trying.

.DQ prints a dotted quad.
-------------------------------------------------------------------- }

: SHUCK ( char -- )   /SOURCE OVER >R  ROT SKIP DROP  R> - >IN +! ;

: +OCTET ( u1 c-addr u -- u2 )
   NUMBER? 1 <> ABORT" Malformed address"
   DUP 256 0 WITHIN ABORT" Octet range 0-255"
   SWAP 8 LSHIFT OR ;

: (.OCTET) ( ud1 -- ud2 )
   OVER 255 AND 0  #S  2DROP  SWAP  8 RSHIFT  SWAP ;

: (.DQ) ( u -- c-addr u )
   BASE @ >R DECIMAL
   0 <#  3 0 DO  (.OCTET)  [CHAR] . HOLD  LOOP  (.OCTET)  #>
   R> BASE ! ;

PUBLIC

: DQ ( <n.n.n.n> -- u )
   BASE @ >R  DECIMAL  BL SHUCK
   0  3 0 DO  [CHAR] . PARSE +OCTET  LOOP
   BL PARSE +OCTET  R> BASE ! ;

: .DQ ( u -- )   (.DQ) TYPE SPACE ;

PRIVATE

FUNCTION: bind ( sockfd *addr addrlen -- n )
FUNCTION: getsockopt ( sockfd level optname *optval optlen -- n )
FUNCTION: setsockopt ( sockfd level optname *optval *optlen -- n )
FUNCTION: socket ( domain type protocol -- n )
FUNCTION: htonl ( hostlong -- u_long )
FUNCTION: htons ( hostshort -- u_short )
FUNCTION: ntohl ( netlong -- u_long )
FUNCTION: ntohs ( netshort -- u_short )
FUNCTION: inet_addr ( *cp -- in_addr )
FUNCTION: gethostbyname ( *name -- hostent )

\ socket(2) domains

\ Protocol families
0 CONSTANT PF_UNSPEC            \ Unspecified.
1 CONSTANT PF_LOCAL             \ Local to host (pipes and file-domain).
PF_LOCAL CONSTANT PF_UNIX       \ POSIX name for PF_LOCAL.
PF_LOCAL CONSTANT PF_FILE       \ Another non-standard name for PF_LOCAL.
2 CONSTANT PF_INET              \ IP protocol family.
3 CONSTANT PF_AX25              \ Amateur Radio AX.25.
4 CONSTANT PF_IPX               \ Novell Internet Protocol.
5 CONSTANT PF_APPLETALK         \ Appletalk DDP.
6 CONSTANT PF_NETROM            \ Amateur radio NetROM.
7 CONSTANT PF_BRIDGE            \ Multiprotocol bridge.
8 CONSTANT PF_ATMPVC            \ ATM PVCs.
9 CONSTANT PF_X25               \ Reserved for X.25 project.
10 CONSTANT PF_INET6            \ IP version 6.
11 CONSTANT PF_ROSE             \ Amateur Radio X.25 PLP.
12 CONSTANT PF_DECnet           \ Reserved for DECnet project.
13 CONSTANT PF_NETBEUI          \ Reserved for 802.2LLC project.
14 CONSTANT PF_SECURITY         \ Security callback pseudo AF.
15 CONSTANT PF_KEY              \ PF_KEY key management API.
16 CONSTANT PF_NETLINK
PF_NETLINK CONSTANT PF_ROUTE    \ Alias to emulate 4.4BSD.
17 CONSTANT PF_PACKET           \ Packet family.
18 CONSTANT PF_ASH              \ Ash.
19 CONSTANT PF_ECONET           \ Acorn Econet.
20 CONSTANT PF_ATMSVC           \ ATM SVCs.
21 CONSTANT PF_RDS              \ RDS sockets.
22 CONSTANT PF_SNA              \ Linux SNA Project
23 CONSTANT PF_IRDA             \ IRDA sockets.
24 CONSTANT PF_PPPOX            \ PPPoX sockets.
25 CONSTANT PF_WANPIPE          \ Wanpipe API sockets.
26 CONSTANT PF_LLC              \ Linux LLC.
29 CONSTANT PF_CAN              \ Controller Area Network.
30 CONSTANT PF_TIPC             \ TIPC sockets.
31 CONSTANT PF_BLUETOOTH        \ Bluetooth sockets.
32 CONSTANT PF_IUCV             \ IUCV sockets.
33 CONSTANT PF_RXRPC            \ RxRPC sockets.
34 CONSTANT PF_ISDN             \ mISDN sockets.
35 CONSTANT PF_PHONET           \ Phonet sockets.
36 CONSTANT PF_IEEE802154       \ IEEE 802.15.4 sockets.
37 CONSTANT PF_MAX              \ For now..

\ Address families
PF_UNSPEC CONSTANT AF_UNSPEC
PF_LOCAL CONSTANT AF_LOCAL
PF_UNIX CONSTANT AF_UNIX
PF_FILE CONSTANT AF_FILE
PF_INET CONSTANT AF_INET
PF_AX25 CONSTANT AF_AX25
PF_IPX CONSTANT AF_IPX
PF_APPLETALK CONSTANT AF_APPLETALK
PF_NETROM CONSTANT AF_NETROM
PF_BRIDGE CONSTANT AF_BRIDGE
PF_ATMPVC CONSTANT AF_ATMPVC
PF_X25 CONSTANT AF_X25
PF_INET6 CONSTANT AF_INET6
PF_ROSE CONSTANT AF_ROSE
PF_DECnet CONSTANT AF_DECnet
PF_NETBEUI CONSTANT AF_NETBEUI
PF_SECURITY CONSTANT AF_SECURITY
PF_KEY CONSTANT AF_KEY
PF_NETLINK CONSTANT AF_NETLINK
PF_ROUTE CONSTANT AF_ROUTE
PF_PACKET CONSTANT AF_PACKET
PF_ASH CONSTANT AF_ASH
PF_ECONET CONSTANT AF_ECONET
PF_ATMSVC CONSTANT AF_ATMSVC
PF_RDS CONSTANT AF_RDS
PF_SNA CONSTANT AF_SNA
PF_IRDA CONSTANT AF_IRDA
PF_PPPOX CONSTANT AF_PPPOX
PF_WANPIPE CONSTANT AF_WANPIPE
PF_LLC CONSTANT AF_LLC
PF_CAN CONSTANT AF_CAN
PF_TIPC CONSTANT AF_TIPC
PF_BLUETOOTH CONSTANT AF_BLUETOOTH
PF_IUCV CONSTANT AF_IUCV
PF_RXRPC CONSTANT AF_RXRPC
PF_ISDN CONSTANT AF_ISDN
PF_PHONET CONSTANT AF_PHONET
PF_IEEE802154 CONSTANT AF_IEEE802154
PF_MAX CONSTANT AF_MAX

\ Types of sockets
1 CONSTANT SOCK_STREAM          \ Sequenced, reliable, connection-based byte streams.
2 CONSTANT SOCK_DGRAM           \ Connectionless, unreliable datagrams of fixed
                                \ maximum length.
3 CONSTANT SOCK_RAW             \ Raw protocol interface.
4 CONSTANT SOCK_RDM             \ Reliably-delivered messages.
5 CONSTANT SOCK_SEQPACKET       \ Sequenced, reliable, connection-based, datagrams of fixed maximum length.
6 CONSTANT SOCK_DCCP            \ Datagram Congestion Control Protocol.

\ For setsockopt(2)
1 CONSTANT SOL_SOCKET
1 CONSTANT SO_DEBUG
2 CONSTANT SO_REUSEADDR
3 CONSTANT SO_TYPE
4 CONSTANT SO_ERROR
5 CONSTANT SO_DONTROUTE
6 CONSTANT SO_BROADCAST
7 CONSTANT SO_SNDBUF
8 CONSTANT SO_RCVBUF
9 CONSTANT SO_KEEPALIVE
10 CONSTANT SO_OOBINLINE
11 CONSTANT SO_NO_CHECK
12 CONSTANT SO_PRIORITY
13 CONSTANT SO_LINGER
14 CONSTANT SO_BSDCOMPAT
16 CONSTANT SO_PASSCRED
17 CONSTANT SO_PEERCRED
18 CONSTANT SO_RCVLOWAT
19 CONSTANT SO_SNDLOWAT
20 CONSTANT SO_RCVTIMEO
21 CONSTANT SO_SNDTIMEO
25 CONSTANT SO_BINDTODEVICE
26 CONSTANT SO_ATTACH_FILTER
27 CONSTANT SO_DETACH_FILTER
28 CONSTANT SO_PEERNAME
29 CONSTANT SO_TIMESTAMP
30 CONSTANT SO_ACCEPTCONN
31 CONSTANT SO_PEERSEC
32 CONSTANT SO_SNDBUFFORCE
33 CONSTANT SO_RCVBUFFORCE
34 CONSTANT SO_PASSSEC

{ --------------------------------------------------------------------
Key protocols from /etc/protocols

The "proper" way to get these is to use getprotoent(3), which will do
a lookup by name in /etc/protocols.  Considering that the Internet
will stop working if these numbers ever change (unless every host on
the Internet changes simultaneously), it's probably safe to assume
these are constant.
-------------------------------------------------------------------- }

1 CONSTANT ICMP
6 CONSTANT TCP
17 CONSTANT UDP

{ --------------------------------------------------------------------
Flags to be ORed into the type parameter of socket and socketpair and
used for the flags parameter of paccept.
-------------------------------------------------------------------- }

&02000000 CONSTANT SOCK_CLOEXEC    \ Atomically set close-on-exec flag for the new descriptor(s).
&04000 CONSTANT SOCK_NONBLOCK      \ Atomically mark descriptor(s) as non-blocking.

{ --------------------------------------------------------------------
INADDR constants
-------------------------------------------------------------------- }

0 CONSTANT INADDR_ANY
DQ 127.0.0.1 CONSTANT INADDR_LOOPBACK
DQ 255.255.255.255 CONSTANT INADDR_BROADCAST

{ --------------------------------------------------------------------
SOCKADDR_IN access

The SOCKADDR_IN structure is used to store addresses for the Internet
address family and is used with socket functions.

sin_family, sin_port, sin_addr take a sockaddr_in address and return
the address of the appropriate field.

-SOCKADDR_IN erases a sockaddr_in.

!SOCKADDR_IN initializes a sockaddr_in at addr with the given IP
address and port.
-------------------------------------------------------------------- }

16 CONSTANT |SOCKADDR_IN|          \ sizeof(struct sockaddr_in)
: SOCKADDR_IN ( -- )   |SOCKADDR_IN| BUFFER: ;

: sin_family ( addr1 -- addr2 )   ;
: sin_port ( addr1 -- addr2 )   sin_family 2+ ;
: sin_addr ( addr1 -- addr2 )   sin_family 4 + ;

: -SOCKADDR_IN ( addr -- )   |SOCKADDR_IN| ERASE ;

: !SOCKADDR_IN ( ip port addr -- )
   DUP >R -SOCKADDR_IN
   AF_INET R@ sin_family W!
   htons R@ sin_port W!
   htonl R> sin_addr ! ;

{ --------------------------------------------------------------------
Socket structure

SOCKET: defines a data structure specific to each socket in use.
Words defined by SOCKET:, when executed, set >SOCKET to the base
address of the data structure.

We need separate file descriptors SFD (socket file descriptor) and CFD
(connection file descriptor) because when we're operating as a server,
the fd returned by socket(2) is used for mulitiple calls to accept(2).

Overview of usage with TCP:

SOCKET: MY-SOCKET

: TCP-SERVER ( -- )
   MY-SOCKET /TCP-SOCKET  <port> SERVER  /BIND  /LISTEN
   BEGIN  /ACCEPT  (serve the client; return when CFD closes)  AGAIN ;

When we're operating as a client, SFD and CFD will hold the same fd.
Typical client usage:

: TCP-CLIENT ( -- )
   MY-SOCKET  <ip-addr> <port> CLIENT
   BEGIN  /TCP-SOCKET  /CONNECT  (talk with server; return when CFD closes)  AGAIN ;

SOCKETS: defines an array of u sockets.  At run-time, the named socket
array takes the index i and sets >SOCKET to that socket in the array.
-------------------------------------------------------------------- }

#USER   CELL +USER >SOCKET      \ Pointer to socket structure
TO #USER

: +SOCKET ( n1 n2 -- n3 )   CREATE OVER , +
   DOES> ( -- addr )   @ >SOCKET @ + ;

0
            0 +SOCKET 'SOCKET           \ Start of socket structure
         CELL +SOCKET SFD               \ File descriptor from socket(2)
         CELL +SOCKET CFD               \ File descriptor for connection
|SOCKADDR_IN| +SOCKET MY-SA             \ sockaddr_in for me
|SOCKADDR_IN| +SOCKET REMOTE-SA         \ sockaddr_in for remote end

( size) CONSTANT |SOCKET|

PUBLIC

: SOCKET: ( <name> -- )
   CREATE  |SOCKET| ALLOT
   DOES> ( -- )   >SOCKET ! ;

: SOCKETS: ( u <name> -- )
   CREATE  |SOCKET| * ALLOT
   DOES> ( i -- )  SWAP
   |SOCKET| * + >SOCKET ! ;

{ --------------------------------------------------------------------
Sockets and connections

?CONNECTED returns true if CFD has a valid connection.  When the
socket is closed, we invalidate CFD by putting -1 in it.
-------------------------------------------------------------------- }

: ?CONNECTED ( -- flag )   CFD @ 0> ;

: CLOSE-CONNECTION ( -- )
   ?CONNECTED IF  CFD @
      DUP SFD @ = IF  -1 SFD !  THEN
   -1 CFD !  closesocket DROP  THEN ;

: CLOSE-SOCKET ( -- )
   SFD @ 0> IF  SFD @
      DUP CFD @ = IF  -1 CFD !  THEN
   -1 SFD !  closesocket DROP  THEN ;

: LOOKUP ( zaddr -- ip )
   gethostbyname DUP IF  h_addr_list + @ @ @  THEN ;

PRIVATE

{ --------------------------------------------------------------------
Socket initialization

/SOCKET initializes the socket pointed to by >SOCKET.  Sets SFD to the
given file descriptor.  TCP uses a separate connection file descriptor
given by accept(2); UDP uses the same fd given by socket(2).

/UDP-SOCKET initializes a UDP socket;
/TCP-SOCKET initializes a TCP socket.

!SOCKOPT sets a setsockopt(2) option at the socket level for the
given socket.  flag=true to set the option; false (0) to clear it.

(REUSEADDR) sets the SO_REUSEADDR option on the given socket.  You'll
usually want this for a server, and always want it for the XTL socket;
otherwise, you'll get a stream of
   XTL bind(): [98] Address already in use
errors until the socket exits the TCP TIME_WAIT state.

BROADCAST sets SO_BROADCAST option on SFD.

SERVER sets us up as the "server" end of a connection; that is, we'll
listen to anybody.

CLIENT sets us up and the "client" end of the connection to remote
port and ip address.

/BIND binds to the socket pointed to by >SOCKET using MY-SA as the
source.
-------------------------------------------------------------------- }

: /SOCKET ( domain type protocol -- )
   CLOSE-CONNECTION  CLOSE-SOCKET               \ Close FDs, invalidate SFD, CFD
   socket DUP -1 = S" /SOCKET" ?ERRNO  SFD ! ;

PUBLIC

: /UDP-SOCKET ( -- )   AF_INET SOCK_DGRAM UDP /SOCKET ;
: /TCP-SOCKET ( -- )   AF_INET SOCK_STREAM TCP /SOCKET ;

: !SOCKOPT ( socket option flag -- )
   >R  SOL_SOCKET SWAP  RP@ CELL setsockopt
   S" !SOCKOPT: setsockopt()" ?ERRNO  R> DROP ;

: (REUSEADDR) ( socket -- )   SO_REUSEADDR TRUE !SOCKOPT ;
: REUSEADDR ( -- )   SFD @ (REUSEADDR) ;

: BROADCAST ( -- )   SFD @ SO_BROADCAST TRUE !SOCKOPT ;

: SERVER ( port -- )   INADDR_ANY SWAP MY-SA !SOCKADDR_IN ;

: CLIENT ( ip-addr port -- )   REMOTE-SA !SOCKADDR_IN ;

: /BIND ( -- )   SFD @ MY-SA |SOCKADDR_IN| bind  S" /BIND" ?ERRNO ;

: BIND-INTERFACE ( addr len -- )   2>R
   SFD @ SOL_SOCKET SO_BINDTODEVICE 2R> setsockopt
   S" BIND-INTERFACE: setsockopt()" ?ERRNO ;

{ --------------------------------------------------------------------
Sanity checking

Currently, we only support IPv4.  ?SOCKADDR-SIZE checks a sockaddr
size returned by a system call, and throws IOR_SOCKADDR_SIZE if it's
not a supported value.
-------------------------------------------------------------------- }

PRIVATE

: ?SOCKADDR-SIZE ( n -- )
   |SOCKADDR_IN| <> IOR_SOCKADDR_SIZE ?THROW ;
