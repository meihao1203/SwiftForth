OPTIONAL SOCKETS A Winsock interface wrapped in a class.

{ ----------------------------------------------------------------------
(C) 2012 Rick VanNorman
---------------------------------------------------------------------- }

LIBRARY WSOCK32

AS accept() FUNCTION: accept ( s 'sock 'len -- SOCKET )
FUNCTION: bind ( s 'sock namelen -- int )
FUNCTION: closesocket ( s -- int )
FUNCTION: connect ( s 'sock len -- int )
FUNCTION: htonl ( hostlong -- u_long )
FUNCTION: htons ( hostshort -- u_short )
FUNCTION: listen ( s backlog -- int )
FUNCTION: recv ( s *buf len flags -- int )
FUNCTION: send ( s *buf len flags -- int )
FUNCTION: shutdown ( s how -- int )
FUNCTION: socket ( af type protocol -- SOCKET )
FUNCTION: gethostbyname ( *name -- hostent )

3 CELLS CONSTANT h_addr_list    \ offset into hostent for gethostbyname

FUNCTION: WSAStartup ( wVersionRequired lpWSAData -- int )
FUNCTION: WSACleanup ( -- int )
FUNCTION: WSASetLastError ( iError -- )
FUNCTION: WSAGetLastError ( -- int )
FUNCTION: WSAIsBlocking ( -- bool )
FUNCTION: WSAAsyncSelect ( s hWnd wMsg lEvent -- int )

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

{ ----------------------------------------------------------------------
Our sockets class support the most basic structures required for a
winsock connection. Two primary interfaces to kick things off:
CONNECT-TO and LISTEN-ON.

Clients will use CONNECT-TO; the acutal interface will depend on what
use is required. Examples show an always-waiting client (like streaming
media) and a send-message-receive-reply client (like a web browser or
chat client).

Servers must match clients, or visa-versa. Servers are supplied to
connect with both client demonstrations.

The program can be evaluated by loading it into two separate instances
of SwiftForth, designating one as the server and one as the client,
and launching the appropriate handlers.
---------------------------------------------------------------------- }

{ ----------------------------------------------------------------------
The SOCKETS class

Primary user interfaces are:

client: CONNECT-TO
both  : READ WRITE
server: LISTEN-ON
        OPEN-CLIENT
        CLOSE-CLIENT
---------------------------------------------------------------------- }

CLASS SOCKETS

   SINGLE WM_ID       \ these are assigned by CONNECT-TO and LISTEN-ON.
   SINGLE EVENTS      \ they are maintained and used internally.
   SINGLE PORT        \
   SINGLE mHWND       \

   SINGLE SOCK        \ the handle of the connection socket, for read or write
   SINGLE LISTENER    \ the handle of the listening socket on a server

   256 BUFFER: ZHOST  \ the host name a client is connecting to

   \ initialise the windows socket system

   : STARTUP ( -- flag )   $0101 PAD WSAStartup 0= ;

   \ initialize clients and servers

   : /INFO ( mhwnd message events zhostname port -- )
      TO PORT  ZCOUNT ZHOST ZPLACE  TO EVENTS  TO WM_ID  TO mHWND
      INVALID_SOCKET TO SOCK  INVALID_SOCKET TO LISTENER ;

   \ return the non-zero ip address of a hostname

   : LOOKUP ( zaddr -- ip )
      gethostbyname DUP IF  h_addr_list + @ @ @  THEN ;

   \ create an unassigned socket; return true if ok

   : CREATE-SOCKET ( -- socket flag )
      AF_INET SOCK_STREAM IPPROTO_TCP socket
      DUP  INVALID_SOCKET <> ;

   \ return true if we could connect the socket

   : CONNECT-SOCKET ( socket zhost port -- flag )
      [OBJECTS SOCKADDR_IN MAKES SA OBJECTS]
      ( port) htons SA SIN_PORT H!  AF_INET SA SIN_FAMILY H!
      ( host) LOOKUP  DUP  SA IN_ADDR !
      IF    ( sock) SA ADDR  SOCKADDR_IN SIZEOF  connect 0=
      ELSE  ( sock) DROP 0  THEN ;

   \ return true if we could bind the socket

   : BIND-SOCKET ( socket port -- flag )
      [OBJECTS SOCKADDR_IN MAKES SA OBJECTS]
      ( port) htons SA SIN_PORT H!  AF_INET SA SIN_FAMILY H!
      INADDR_ANY SA IN_ADDR !
      ( sock) SA ADDR  SOCKADDR_IN SIZEOF  bind 0=  ;

   \ our server must accept clients that attempt to connect. we only
   \ manage one connection. multiple connections are possible, but
   \ not supported

   : OPEN-CLIENT ( -- )
      SOCK INVALID_SOCKET = IF
         LISTENER 0 0 accept() TO SOCK
      THEN ;

   \ disconnect the client from our server

   : CLOSE-CLIENT ( -- )
      SOCK closesocket DROP  INVALID_SOCKET TO SOCK ;

   \ map events on the specified socket to the windows message
   \ handler for the host window

   : SELECT-SOCKET ( socket -- flag )
      mHWND WM_ID EVENTS WSAAsyncSelect 0= ;

   \ begin listening for connection attempts to our server

   : LISTEN-SOCKET ( socket -- flag )
      100 listen 0= ;

   \ connect the window to a server

   : CONNECT-TO ( mhwnd message events zhostname port -- flag )
      /INFO  STARTUP IF
         CREATE-SOCKET ( s f) IF
            ( s) DUP ZHOST PORT CONNECT-SOCKET IF
               ( s) DUP SELECT-SOCKET IF
                  ( s) TO SOCK  -1 EXIT
               THEN
            THEN
            ( s) DUP 2 shutdown DROP  closesocket
         THEN
         ( x) DROP  WSACleanup DROP
      THEN 0 ;

   \ create a server in the window message handler

   : LISTEN-ON ( mhwnd message events hostname port -- flag )
      /INFO  STARTUP IF
         CREATE-SOCKET ( s f) IF
            ( s) DUP PORT BIND-SOCKET IF
               ( s) DUP SELECT-SOCKET IF
                  ( s) DUP LISTEN-SOCKET IF
                     ( s) TO LISTENER  -1 EXIT
                  THEN
               THEN
            THEN
            ( s) DUP 2 shutdown DROP  closesocket
         THEN
         ( x) DROP  WSACleanup DROP
      THEN 0 ;

   \ disconnect a client socket

   : DETACH ( -- )
      SOCK INVALID_SOCKET = ?EXIT
      SOCK 2 ( SD_BOTH) shutdown DROP
      SOCK closesocket DROP
      INVALID_SOCKET TO SOCK
      WSACleanup DROP ;

   \ read data from the connected socket

   : READ ( addr len -- n )
      SOCK -ROT 0 recv ;

   \ write data to the connected socket

   : WRITE ( addr len -- n )
      SOCK -ROT 0 send ;

END-CLASS

\ ----------------------------------------------------------------------
\\ \\\\ samples, load in two separate sf windows to test
\\\ \\\
\\\\ \\
\\\\\ \

\ ----------------------------------------------------------------------

WM_USER 10312 +
   ENUM WM_CLIENT_SOCKET
   ENUM WM_SERVER_SOCKET
CONSTANT WM_USER

\ ----------------------------------------------------------------------

SOCKETS BUILDS CLIENT_SOCKET

0 VALUE RECEIVED
0 VALUE PACKETS
0 VALUE INCOMPLETE

32 CONSTANT |PACKET|

|PACKET| BUFFER: CDATA

: READ-TEST-SOCKET ( -- )
   1 +TO PACKETS
   CDATA |PACKET| CLIENT_SOCKET READ  DUP +TO RECEIVED
   |PACKET| <> IF 1 +TO INCOMPLETE THEN ;

: TRY-CLIENT ( -- )
   LPARAM LOWORD CASE
      FD_READ  OF  READ-TEST-SOCKET   ENDOF
      FD_CLOSE OF  CLIENT_SOCKET DETACH ENDOF
   ENDCASE ;

: /CLIENT ( -- )
   3 SKIN  HWND  500 500 800 600 MOVEWIN DROP  Z" CLIENT" SET-TITLE
   HWND WM_CLIENT_SOCKET FD_READ FD_CLOSE OR Z" localhost" 5005
   CLIENT_SOCKET CONNECT-TO . ;

\ ----------------------------------------------------------------------

SOCKETS BUILDS SERVER_SOCKET

: TRY-SERVER ( -- )
OPERATOR'S CR ." WM_SERVER "
   LPARAM LOWORD CASE
      FD_ACCEPT OF  ." ACCEPT" SERVER_SOCKET OPEN-CLIENT   ENDOF
      FD_CLOSE  OF  ." CLOSE " SERVER_SOCKET CLOSE-CLIENT  ENDOF
   ENDCASE ;

: /SERVER ( -- )
   1 SKIN  HWND  100 100 800 600 MOVEWIN DROP  Z" SERVER" SET-TITLE
   HWND WM_SERVER_SOCKET FD_ACCEPT FD_CLOSE OR INADDR_ANY 5005
   SERVER_SOCKET LISTEN-ON . ;

\ ----------------------------------------------------------------------

CONSOLE-WINDOW +ORDER
[+SWITCH SF-MESSAGES
   WM_SERVER_SOCKET RUN:  TRY-SERVER 0 ;
   WM_CLIENT_SOCKET RUN:  TRY-CLIENT 0 ;
SWITCH]


