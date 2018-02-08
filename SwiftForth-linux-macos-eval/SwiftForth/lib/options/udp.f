{ ====================================================================
UDP interface

Copyright 2011  FORTH, Inc.

The Forth words defined here assume that >SOCKET pointes to a properly
initialized SOCKET:.

The library for the imported functions below is already selected when
this file is included.
==================================================================== }

FUNCTION: sendto ( sockfd *buf len flags *dst_addr addrlen -- n )
FUNCTION: recvfrom ( sockfd *buf len flags *src_addr *addrlen -- n )

{ --------------------------------------------------------------------
UDP read and write

?UDP-READ performs UDP-READ error handling as needed.
u1 = sizeof(sockaddr), which should be |SOCKADDR_IN|;
n = return from recvfrom.

UDP-READ reads up to u1 characters into the buffer at addr.  Returns
the # of characters actually read.  REMOTE-SA will be set to the
client's IP address and port.

?UDP-WRITE performs UDP-WRITE error handling as needed.
u = original count to UDP-WRITE; n = return from sendto.

UDP-WRITE writes u characters to the client specified by REMOTE-SA.
  If REMOTE-SA is empty, the output is silently discarded.
-------------------------------------------------------------------- }

: ?UDP-READ ( n u1 -- u2 )
   OVER -1 = S" UDP-READ: recvfrom" ?ERRNO
   ?SOCKADDR-SIZE ;

: ?UDP-WRITE ( u n -- )
   DUP -1 = S" UDP-WRITE: sendto" ?ERRNO
   <> IOR_UDP_SHORT_WRITE ?THROW ;

PUBLIC

: UDP-READ ( addr u1 -- u2 )
   |SOCKADDR_IN| >R  SFD @ -ROT 0 REMOTE-SA RP@ recvfrom
   R> ?UDP-READ ;

: UDP-WRITE ( addr u -- )
   REMOTE-SA @ 0= IF  2DROP EXIT  THEN
   TUCK  SFD @ -ROT 0 REMOTE-SA |SOCKADDR_IN| sendto  ?UDP-WRITE ;

PRIVATE
