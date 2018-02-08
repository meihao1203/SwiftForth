{ ====================================================================
Overlapped serial I/O

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL COMMDRIVER

REQUIRES COMMRESOURCE
REQUIRES FORK

FUNCTION: SetPriorityClass  ( hProcess priorityClass -- bool )
FUNCTION: SetThreadPriority ( hProcess priorityLevel -- bool )
FUNCTION: GetCurrentProcess ( -- hProcess )

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS COMMCONFIG
   VARIABLE SIZE
   HVARIABLE VERSION
   HVARIABLE RESERVED
   DCB BUILDS LOCALDCB
   VARIABLE PROVIDER-SUBTYPE
   VARIABLE PROVIDER-OFFSET
   VARIABLE PROVIDER-SIZE
   VARIABLE PROVIDER-DATA

   : SELECT ( zname hwnd -- bool )
      [ THIS SIZEOF ] LITERAL SIZE !
      ADDR CommConfigDialog ;

END-CLASS

COMMCONFIG SUBCLASS DCB-CNTL

   5 BUFFER: DCB-SETTINGS       \ useful for configuration saving

   : SETTINGS>DCB  ( -- )
      DCB-SETTINGS  COUNT LOCALDCB DCBflags C!  COUNT LOCALDCB DCBflags 1+ C!
      COUNT LOCALDCB ByteSize C!  COUNT LOCALDCB Parity C!  C@ LOCALDCB StopBits C! ;

   : DCB>SETTINGS ( -- )   DCB-SETTINGS
      LOCALDCB DCBflags C@  OVER C!  1+
      LOCALDCB DCBflags 1+ C@  OVER C!  1+
      LOCALDCB ByteSize C@  OVER C!  1+
      LOCALDCB Parity C@  OVER C!  1+
      LOCALDCB StopBits C@  SWAP C! ;

END-CLASS

CLASS SERIAL-CONTAINER
   SINGLE HANDLE
END-CLASS

SERIAL-CONTAINER SUBCLASS SERIAL-BACKGROUND
   VARIABLE HTHREAD
   OVERLAPPED BUILDS OL
   VARIABLE XFER
END-CLASS

{ --------------------------------------------------------------------
This class implements the skeleton of a write server thread for
overlapped serial output. The premise is that the client uses PUTS to
write a string to the output device, waiting MAXTIME ms at most for
the output thread to be able to accept the string.  As soon as PUTS
detects that the write thread can accept more data, it copies up to
|BUF| characters of the string to the internal buffer, signals WRITING
to start, and returns to its caller with an ior indicating whether it
started the writer or not, and the remaining string.

Internally, WRITE-STRING is considered to be successful if the
WriteFile operation succeeded; if WriteFile failed, but the reason for
failure was ERROR_IO_PENDING, then the success depends on the result
of GetOverlapped Result.
-------------------------------------------------------------------- }

SERIAL-BACKGROUND SUBCLASS SERIAL-TRANSMITTER

   1024 CONSTANT |BUF|     \ >>>>> power of 2 <<<<<
   |BUF| BUFFER: BUF
   VARIABLE #BUF

   EVENT BUILDS IDLE
   EVENT BUILDS START

   \ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

   : WRITE-STRING ( addr len -- )
      HANDLE ROT ROT XFER OL ADDR WriteFile ?EXIT
      GetLastError ERROR_IO_PENDING = -EXIT
      HANDLE OL ADDR XFER 1 GetOverlappedResult DROP ;

   : /EVENTS ( -- )
      1 IDLE MAKE ( ready)   0 START MAKE ( waiting)
      0 1 0 0 CreateEvent OL HEVENT ! ;

   : WRITING ( -- hthread )
      /EVENTS  FORKS>
      GetCurrentProcess HIGH_PRIORITY_CLASS  SetPriorityClass DROP
      BEGIN  INFINITE START WAIT DROP
         BUF #BUF @ WRITE-STRING  IDLE SIGNAL
      AGAIN ;

   : WRITER ( -- )   HTHREAD @ ?EXIT  WRITING HTHREAD ! ;

   : DETACH ( -- )
      HANDLE ?DUP IF  CancelIO  0 TO HANDLE  THEN
      OL HEVENT @ ?DUP IF  CloseHandle DROP  0 OL HEVENT ! THEN ;

   : ATTACH ( hcomm -- )   DETACH  TO HANDLE  WRITER ;

   \ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

   DEFER: MAXTIME ( -- ms )   5000 ;

   : TYPE  ( addr len -- )
      MAXTIME IDLE WAIT THROW
      |BUF| MIN  DUP #BUF !  BUF SWAP CMOVE  ( Load buffer )
      START SIGNAL ;

   : EMIT  ( char -- )
      MAXTIME IDLE WAIT THROW
      BUF C! 1 #BUF !  START SIGNAL ;

END-CLASS


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

SERIAL-BACKGROUND SUBCLASS SERIAL-RECEIVER

   VARIABLE HTHREAD

   CIRCULAR-BUFFER BUILDS INBUF
   EVENT BUILDS AVAIL  \ Char Available


   : PURGED ( -- )   HANDLE PURGE_RXCLEAR PurgeComm DROP ;

   : /EVENTS ( -- )   0 1 0 0 CreateEvent OL HEVENT !
      0 AVAIL MAKE ( waiting) ;

   \ read a byte. if readfile succeeds, do nothing else.
   \ if readfile fails, we see if the reason was iopending.
   \ if it was, we wait for a character via getoverlappedresult.
   \ if that fails, we accumulate an error.

   : GETCH ( -- bool )
      HANDLE INBUF 'HEAD 1 XFER OL ADDR ReadFile DUP ?EXIT DROP
      GetLastError ERROR_IO_PENDING = DUP -EXIT DROP
      HANDLE OL ADDR XFER 1 GetOverlappedResult DROP
      XFER @ ( did we get a char? ) ;

   : READER ( -- hthread )
      FORKS>
      GetCurrentProcess HIGH_PRIORITY_CLASS  SetPriorityClass DROP
      BEGIN  GETCH ( Recved a char? )
         IF    INBUF +HEAD  AVAIL SIGNAL ( let em know )
         THEN
      AGAIN ;

   : KEY?  ( -- flag )    \ True = Char Available
      INBUF ANY? ;

   : @KEY  ( -- char )
      INBUF 'TAIL C@ ( char )  INBUF +TAIL ;

   : KEY  ( -- char )
      BEGIN  KEY? NOT WHILE
         1 Sleep DROP ( Give up Time Slice )
      REPEAT  @KEY ;

   : WAIT-KEY  ( timeout -- flag )  \ True = Char is available
      INBUF ANY?
      IF  DROP ( timeout )  TRUE  EXIT
      THEN
      BEGIN  INBUF ANY? NOT
      WHILE  [DEFINED] NO-COMM-THREAD
             [IF]    PAUSE
             [THEN]  DUP ( timeout ) AVAIL WAIT
             IF  DROP ( timeout )  FALSE  EXIT
             THEN
      REPEAT DROP ( timeout ) TRUE ;


   : DETACH ( -- )   HANDLE ?DUP IF  CancelIO  THEN
      OL HEVENT @ ?DUP IF  CloseHandle DROP  0 OL HEVENT ! THEN ;

   : ATTACH ( hcomm -- )   DETACH  TO HANDLE  PURGED  /EVENTS
      HTHREAD @ ?EXIT  READER HTHREAD ! ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

SERIAL-CONTAINER SUBCLASS SERIAL-PORT

   DCB-CNTL BUILDS COMMSTATE
   COMMTIMEOUTS BUILDS TOUT

   SERIAL-RECEIVER BUILDS RCV
   SERIAL-TRANSMITTER BUILDS XMT

   : /TIMEOUTS ( -- )
      HANDLE
      0   \ ReadIntervalTimeout
      0   \ ReadTotalTimeoutMultiplier
      10  \ ReadTotalTimeoutConstant
      0   \ WriteTotalTimeoutMultiplier
      0   \ WriteTotalTimeoutConstant
      TOUT SET-TIMEOUTS ;

   : GET-COMMSTATE ( -- )
      HANDLE COMMSTATE LOCALDCB ADDR GetCommState DROP ;

   : SET-COMMSTATE ( -- )
      HANDLE COMMSTATE LOCALDCB ADDR SetCommState DROP ;

   \ Alternate method of setting commstate

   DEFER: COMMSTATE-STRING ( -- z )   Z" 38400,N,8,1" ;

   : /COMMSTATE ( zstr -- )
      COMMSTATE LOCALDCB ADDR BuildCommDCB DROP  SET-COMMSTATE ;

   : OPENED? ( -- flag )   HANDLE 0> ;

   : CLOSE ( -- )
      OPENED? IF  XMT DETACH RCV DETACH  HANDLE CloseHandle DROP  THEN
      INVALID_HANDLE_VALUE TO HANDLE ;

   : ATTACH ( handle -- ior )   CLOSE
      DUP TO HANDLE  INVALID_HANDLE_VALUE = DUP ?EXIT
      /TIMEOUTS ;

   : OPEN ( zstr -- ior )
      GENERIC_R/W 0 0 OPEN_EXISTING FILE_FLAG_OVERLAPPED 0
      CreateFile ATTACH ;

   : ACTIVATE  ( -- )
      HANDLE XMT ATTACH  HANDLE RCV ATTACH ;

    \ -----------------------------------------------------------------

   : COMSTATUS ( -- stat )
      0  OPENED? IF  SP@ HANDLE SWAP GetCommModemStatus DROP THEN ;

   : STATUSBIT ( mask -- flag )   COMSTATUS AND 0<> ;

   : DSR?  ( -- flag )   MS_DSR_ON   STATUSBIT ;
   : CTS?  ( -- flag )   MS_CTS_ON   STATUSBIT ;
   : RING? ( -- flag )   MS_RING_ON  STATUSBIT ;
   : RLSD? ( -- flag )   MS_RLSD_ON  STATUSBIT ;     \ aka CD

   : CONTROLBIT ( mask -- )
      OPENED? IF  HANDLE SWAP EscapeCommFunction  THEN  DROP ;

   : +DTR   ( -- )    SETDTR   CONTROLBIT ;
   : -DTR   ( -- )    CLRDTR   CONTROLBIT ;
   : +RTS   ( -- )    SETRTS   CONTROLBIT ;
   : -RTS   ( -- )    CLRRTS   CONTROLBIT ;
   : +BREAK ( -- )    SETBREAK CONTROLBIT ;
   : -BREAK ( -- )    CLRBREAK CONTROLBIT ;

   \ -----------------------------------------------------------------

   PURGE_TXABORT
   PURGE_RXABORT OR
   PURGE_TXCLEAR OR
   PURGE_RXCLEAR OR CONSTANT PURGE-ALL-FLAGS

   PURGE_RXABORT
   PURGE_RXCLEAR OR CONSTANT PURGE-RCV-FLAGS

   : PURGE ( -- )
      HANDLE PURGE-ALL-FLAGS PurgeComm DROP ;

   : CLEAR-RECV ( -- )
      HANDLE PURGE-RCV-FLAGS PurgeComm DROP ;

   \ -----------------------------------------------------------------

   : BAUD ( baud -- )
      GET-COMMSTATE  COMMSTATE LOCALDCB BaudRate !  SET-COMMSTATE ;

   : SER-KEY? ( -- flag )   RCV KEY? ;
   : SER-KEY ( -- char )   RCV KEY ;
   : SER-WAIT ( ms -- flag )   RCV WAIT-KEY ;

   : SER-EMIT ( char -- )   XMT EMIT ;
   : SER-TYPE ( addr len -- )   XMT TYPE ;

   \ use kill instead of close

   : KILL ( -- )
      XMT HTHREAD @ 0 TerminateThread DROP
      RCV HTHREAD @ 0 TerminateThread DROP  CLOSE ;

END-CLASS

\\ Examples:

SERIAL-PORT BUILDS COM1
SERIAL-PORT BUILDS COM2
