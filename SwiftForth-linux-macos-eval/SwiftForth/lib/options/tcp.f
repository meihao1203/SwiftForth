{ ====================================================================
TCP interface

Copyright 2011  FORTH, Inc.

The Forth words defined here assume that >SOCKET pointes to a properly
initialized SOCKET:.

The library for the imported functions below is already selected when
this file is included.
==================================================================== }

FUNCTION: listen ( sockfd backlog -- n )
AS sys_accept FUNCTION: accept ( sockfd *dst_addr *addrlen -- n )
AS sys_connect FUNCTION: connect ( sockfd *dst_addr *addrlen -- n )

FUNCTION: send ( sockfd *buf len flags -- n )
FUNCTION: recv ( sockfd *buf len flags -- n )

{ --------------------------------------------------------------------
TCP server

DEFAULT-LISTEN-BACKLOG specifies the default backlog value for
listen(2) calls.

/LISTEN begins listening on SFD using DEFAULT-LISTEN-BACKLOG.

/ACCEPT blocks until a connection is ready, then accepts it.  Upon
successful return, CFD is set to the connection file descriptor
returned by accept(2).
-------------------------------------------------------------------- }

5 CONSTANT DEFAULT-LISTEN-BACKLOG

PUBLIC

: /LISTEN ( -- )
   SFD @ DEFAULT-LISTEN-BACKLOG listen  -1 = S" /LISTEN" ?ERRNO ;

: /ACCEPT ( -- )
   |SOCKADDR_IN| >R  SFD @ REMOTE-SA RP@ sys_accept
   DUP -1 = S" /ACCEPT" ?ERRNO  R> ?SOCKADDR-SIZE  CFD ! ;

{ --------------------------------------------------------------------
TCP client

/CONNECT connects to the IP address and port specified in REMOTE-SA.
-------------------------------------------------------------------- }

: /CONNECT ( -- )
   SFD @ REMOTE-SA |SOCKADDR_IN| sys_connect
   S" /CONNECT" ?ERRNO  SFD @ CFD ! ;

{ --------------------------------------------------------------------
TCP read and write

TCP-READ reads up to u1 characters into the buffer at addr.  Returns
the # of characters actually read.

TCP-READX reads eXactly length u characters into the buffer at addr
making successive calls to TCP-READ as needed.  Throws on EOF
(returned 0 length) error.

TCP-WRITE writes u characters to the client specified by REMOTE-SA.
-------------------------------------------------------------------- }

: TCP-READ ( addr u1 -- u2 )
   CFD @ -ROT 0 recv  DUP -1 = S" TCP-READ" ?ERRNO ;

: TCP-READX ( addr u -- )
   BEGIN  DUP 0> WHILE  2DUP TCP-READ
      DUP 0= -39 ?THROW                         \ EOF = -39 (ANS Forth-94 standard throw code)
   /STRING REPEAT  2DROP ;

: TCP-WRITE ( addr u -- )
   CFD @ -ROT 0 send  -1 = S" TCP-WRITE" ?ERRNO ;

PRIVATE
