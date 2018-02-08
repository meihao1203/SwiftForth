{ ====================================================================
Send mail

Copyright (C) 2008 FORTH, Inc.   All rights reserved.

A simple network socket demonstration.
==================================================================== }

OPTIONAL SENDMAIL Simple network socket demonstration

{ --------------------------------------------------------------------
Demonstrates using socket functions to send email using the SMTP
protocol.  SENDMAIL parses four items from the input stream:

      SENDMAIL mailserv to_addr from_addr messagefile

Connects to the specified mail server, uses to_addr and from_addr in
the transmitted message header, then sends each line of the
messagefile (text file) as the email message body.  Transfer is
implemented using the SMTP Internet protocol.
-------------------------------------------------------------------- }

REQUIRES sockets

{ --------------------------------------------------------------------
Messages to send via email are built one line at a time at PAD, and
used via the XT passed to TYPEFILE.

+CR appends a crlf to the string at the address.

ONELINE reads one line from the file storing it at PAD.

TYPEFILE reads each line of the file, using the xt ( addr len) on
   each line returned by ONELINE.  The file is closed when finished.
-------------------------------------------------------------------- }

CREATE <CRLF>  2 C, $0D C, $0A C,
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
USAGE is a little bit of help for SENDMAIL

CHECK reports an error named by the zstring if the status is SOCKET_ERROR.
------------------------------------------------------------------------ }

: USAGE ( -- )
   CR ." Usage: SENDMAIL mailserv to_addr from_addr messagefile" CR
   CR ." Example: SENDMAIL smtp.myisp.com you@there.com  me@here.com file.txt"  ;

: CHECK ( ior zstr -- )
   OVER 1 < IF
      CR ." Error "  SWAP . ." during call to "
      ZCOUNT TYPE  ABORT
   THEN 2DROP ;

{ ------------------------------------------------------------------------
Buffers for composing the message header

SERVER has the name of the SMTP server.
TOADDR has the address of the person destined to recieve the mail.
FROMADDR has the address of the person determined to bother someone.
MSGFILE has the name of the file to transmit from one person to another.

ARGS parses from the Forth command line the next 4 blank delimited words
(server, to, from, etc) of the email.
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

{ --------------------------------------------------------------------
Socket interfaces

HOST has the address of the SMTP server when opened for email.

HSERVER has the socket handle allocated for talking to the host.

PORT# has the port number of the communication path to the host as
returned by getservbyname.
-------------------------------------------------------------------- }

0 VALUE HOST
0 VALUE HSERVER
0 VALUE PORT#

{ --------------------------------------------------------------------
Interface

FIND-HOST returns the host IP address for the name in SERVER.
-------------------------------------------------------------------- }

: FIND-HOST ( -- )
   SERVER gethostbyname ( addr | 0 )
   DUP 0= ABORT" Can't find SMTP server"
   4 CELLS + @ @ @ TO HOST ;

: CREATE-SOCKET ( -- )
   PF_INET SOCK_STREAM 0 socket
   DUP SOCKET_ERROR = ABORT" Can't open socket"
   TO HSERVER ;

: SHUTDOWN-SOCKET ( -- )
   HSERVER 0 shutdown  ABORT" Can't close socket" ;

: CLOSE-SOCKET ( -- )
   HSERVER 0 to HSERVER CLOSE-FILE DROP ;

: SET-PORT ( -- )
   Z" smtp" 0 getservbyname
   DUP 0= ABORT" Can't find SMTP service"
   2 CELLS + U@ TO PORT# ;

: CONNECT-SOCKET ( -- )
   PAD 16 ERASE
   AF_INET PAD H!  PORT# PAD 2+ H!  HOST PAD 4 + !
   HSERVER PAD 16 connect ABORT" Can't connect to socket" ;

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
   S" RCPT TO:<" PAD PLACE  TOADDR ZCOUNT PAD APPEND
   S" >" PAD APPEND  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() RCPT TO" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() RCPT TO" CHECK ;

: DATA ( -- )
   S" DATA" PAD PLACE  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() DATA" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() DATA" CHECK ;

: SLINE ( addr n -- )
   DUP 0= IF  2DROP S"  " THEN
   256 R-ALLOC >R  R@ PLACE  R@ +CRLF
   HSERVER R> COUNT 0 send  Z" send() msg" CHECK ;

: OPENFILE ( -- fid )
   MSGFILE ZCOUNT R/O OPEN-FILE THROW ;

CREATE <EOF>   3 C, $0D C, $0A C, CHAR . C,

: SEND-FILE ( -- )
   OPENFILE ['] SLINE TYPEFILE
   S\" \n.\n" SLINE ;

: SEND-QUIT
   S" QUIT" PAD PLACE  PAD +CRLF
   HSERVER PAD COUNT 0 send  Z" send() QUIT" CHECK
   HSERVER PAD 4096 0 recv  Z" recv() QUIT" CHECK ;

: SENDING ( -- )
   FIND-HOST  CREATE-SOCKET  SET-PORT
   CONNECT-SOCKET  CHECK-SMTP
   HELO-SERVER  MAIL-FROM  RCPT-TO
   DATA  SEND-FILE  SEND-QUIT  SHUTDOWN-SOCKET
   CLOSE-SOCKET ;

: SENDMAIL ( -- )
   ARGS  MSGFILE C@ 0= IF  USAGE EXIT  THEN  SENDING ;

CR
CR .( A simple SENDMAIL utility for SwiftForth)
CR
USAGE
CR
CR
