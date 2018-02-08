{ ====================================================================
Send mail

Copyright (C) 2001 FORTH, Inc.   All rights reserved.
Rick VanNorman

A demonstration of a synchronous Winsock interface
==================================================================== }

OPTIONAL SENDMAIL A demonstration of a synchronous Winsock interface

{ --------------------------------------------------------------------
Demonstrates using Win32 Winsock API functions to perform email
transmission using the SMTP protocol. Takes four parameters, as
follows:

      sendmail mailserv to_addr from_addr messagefile.txt

Connects to the specified mail server, uses to_addr and from_addr in
the transmitted message header, then sends each line of the messagefile
(text file) as the email message body. Transfer is implemented using
the SMTP Internet protocol.

WINSOCK FUNCTIONS USED:

      WSAStartup              Initializes specific winsock version.
      gethostbyname           Attempts to lookup host name from IP #.
      getservbyname           Looks up service port from service name.
      socket                  Creates a socket of given type.
      htons                   Converts a USHORT from host byte order.
      connect                 Establishes connection on a socket.
      recv                    Receives data through socket.
      send                    Transmits data through socket.
      closesocket             Closes (deallocates) a socket.
      WSACleanup              Deallocates internal winsock resources.

NOTES:
 - This program supports both Windows 95 and NT 4.0, and requires
   Microsoft TCP/IP networking (or another TCP/IP stack) to be
   installed and configured prior to use. (You will also need to have a
   TCP/IP connection established or else have auto-dialing enabled).

   written by Jim Blaney, 1996
        in Mastering Windows NT Programming

   ported to SwiftForth by Rick VanNorman
-------------------------------------------------------------------- }

REQUIRES WINSOCK

   THROW#
   S" Cannot find Winsock v1.1 or later" >THROW ENUM IOR_SMTP_WINSOCK
   S" Cannot find SMTP mail server"      >THROW ENUM IOR_SMTP_MISSING
   S" Cannot open mail server socket"    >THROW ENUM IOR_SMTP_SOCKET
   S" Error connecting to socket"        >THROW ENUM IOR_SMTP_CONNECT
   S" Error during transfer"             >THROW ENUM IOR_SMTP_XFER
TO THROW#

{ --------------------------------------------------------------------
Messages to send via email are built one line at a time at PAD, and
used via the XT passed to TYPEFILE.

+CR appends a crlf to the string at the address.

ONELINE reads one line from the file storing it at PAD.

TYPEFILE reads each line of the file, using the xt ( addr len) on
   each line returned by ONELINE.  The file is closed when finished.
-------------------------------------------------------------------- }

CREATE <CRLF>  2 C, $0D C, $0A C, 0 C,
: +CRLF ( addr -- )   <CRLF> COUNT ROT APPEND ;

: ONELINE ( fid -- addr n flag )
   PAD 255 ROT READ-LINE 0<> OR 0<> PAD -ROT ;

: TYPEFILE ( fid xt -- )
   >R  BEGIN ( fid)
      DUP ONELINE WHILE ( fid addr n)
      R@ EXECUTE
   REPEAT
   2DROP CLOSE-FILE DROP R> DROP ;

{ ------------------------------------------------------------------------
Usage is a little bit of help for SENDMAIL

CHECK reports an error named by the zstring if the status is SOCKET_ERROR.
------------------------------------------------------------------------ }

: Usage
   CR ." Usage: SENDMAIL mailserv to_addr from_addr messagefile" CR
   CR ." Example: SENDMAIL smtp.myisp.com you@there.com "
      ." me@here.com file.txt"  ;

: CHECK ( status zstr -- )
   OVER SOCKET_ERROR =  THIRD 0=  OR IF
      CR ." Error during call to " ZCOUNT TYPE ." : "
      .  ."  - "  GetLastError .
      IOR_SMTP_XFER THROW
   THEN 2DROP ;

{ ------------------------------------------------------------------------
Buffers for composing the message header

SERVER has the name of the smtp server.
TOADDR has the address of the person destined to recieve the mail.
FROMADDR has the address of the person determined to bother someone.
MSGFILE has the name of the file to transmit from one person to another.

ARGS parses from the forth command line the next 4 blank delimited words
   which will serve as the to, from, etc of the email.
------------------------------------------------------------------------ }

CREATE SERVER   256 ALLOT
CREATE TOADDR   256 ALLOT
CREATE FROMADDR 256 ALLOT
CREATE MSGFILE  256 ALLOT

: ARGS ( -- )
   BL WORD COUNT SERVER   ZPLACE
   BL WORD COUNT TOADDR   ZPLACE
   BL WORD COUNT FROMADDR ZPLACE
   BL WORD COUNT MSGFILE  ZPLACE ;

\ ARGS 192.168.0.1 rick@pophost.com rvn@forth.com hi.f

{ --------------------------------------------------------------------
Socket interfaces

HOST has the address of the smtp server when opened for email.
HSERVER has the socket number allocated for talking to the host.
PORT has the port (duh!) number of the communication path to the
   host. This is normally IPPORT_SMTP (25) unless getservbyname
   tells us differently.
-------------------------------------------------------------------- }

0 VALUE HOST
0 VALUE HSERVER
0 VALUE PORT

{ --------------------------------------------------------------------
OPEN-SOCKS creates a socket session and
CLOSE-SOCKS closes one.
-------------------------------------------------------------------- }

: OPEN-SOCKS ( -- )   $101 PAD WSAStartup  IOR_SMTP_WINSOCK ?THROW ;

: CLOSE-SOCKS ( -- )   WSACleanup DROP ;

\ if the server address is a valid ip address, we use it as is
\ otherwise we try to have our dns resolve it to an ip address for us.

: FIND-HOST ( -- hostaddr )
   SERVER inet_addr DUP 1+ ?EXIT
   SERVER gethostbyname ( a)
   DUP 0= IOR_SMTP_MISSING ?THROW
   3 CELLS + @ @ @ ;

: CREATE-SOCKET ( -- )
   PF_INET SOCK_STREAM 0 socket TO HSERVER
   HSERVER INVALID_SOCKET = IOR_SMTP_SOCKET ?THROW ;

: SET-PORT ( -- )
   Z" mail" 0 getservbyname ?DUP IF
      8 + U@
   ELSE
      IPPORT_SMTP htons
   THEN  TO PORT ;

: CONNECT-SOCKET ( -- )
   PAD 16 ERASE
   AF_INET PAD H!  PORT PAD 2+ H!  HOST PAD 4 + !
   HSERVER PAD 16 connect IOR_SMTP_CONNECT ?THROW ;

: CHECK-SMTP ( -- )
   HSERVER PAD 4096 0 recv z" recv() Reply" CHECK ;

: HELO-SERVER ( -- )
   S" HELO " PAD PLACE  SERVER ZCOUNT PAD APPEND  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() HELO" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() HELO" CHECK ;

: MAIL-FROM ( -- )
   S" MAIL FROM:<" PAD PLACE  FROMADDR ZCOUNT PAD APPEND
   S" >" PAD APPEND  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() MAIL FROM" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() MAIL FROM" CHECK ;

: RCPT-TO ( -- )
   S" RCPT TO:" PAD PLACE  TOADDR ZCOUNT PAD APPEND
   S" >" PAD APPEND  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() RCPT TO" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() RCPT TO" CHECK ;

: DATA ( -- )
   S" DATA" PAD PLACE  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() DATA" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() DATA" CHECK ;

: SLINE ( addr n -- )
   DUP 0= IF 2DROP S"  " THEN
   256 R-ALLOC >R  R@ PLACE  R@ +CRLF
   HSERVER R> COUNT 0 send  Z" send() msg" CHECK ;

: OPENFILE ( -- fid )
   MSGFILE ZCOUNT R/O OPEN-FILE THROW ;

: SEND-FILE ( -- )
   OPENFILE ['] SLINE TYPEFILE
   S\" \n.\n" SLINE ;

: SEND-QUIT ( -- )
   S" QUIT" PAD PLACE  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() QUIT" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() QUIT" CHECK ;

: SENDING ( -- )
   OPEN-SOCKS
   FIND-HOST TO HOST  CREATE-SOCKET SET-PORT
   CONNECT-SOCKET CHECK-SMTP
   HELO-SERVER MAIL-FROM RCPT-TO DATA SEND-FILE SEND-QUIT ;

-? : SENDMAIL ( -- )
   ARGS MSGFILE C@ 0= IF USAGE EXIT THEN
   ['] SENDING CATCH IF CR ." errors sending mail" THEN
   CLOSE-SOCKS ;

CR
CR .( A simple SENDMAIL utility for SwiftForth)
CR
Usage
CR
CR
