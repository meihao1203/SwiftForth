{ ====================================================================
Resources and datastructures for COM port access

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL COMMRESOURCE

FUNCTION: CreateEvent ( attrib manreset initial name -- handle )
FUNCTION: SetEvent ( hevent -- bool )
FUNCTION: GetOverlappedResult ( hfile 'overlap 'count wait -- bool )
FUNCTION: PurgeComm ( hFile dwFlags -- res )
FUNCTION: CancelIo ( hfile -- )  \ CancelIO is not supported under Win95
FUNCTION: GetCommModemStatus ( hfile 'status -- bool )
FUNCTION: BuildCommDCB ( zstring 'dcb -- bool )  \ like z" 96,n,8,1"
FUNCTION: EscapeCommFunction ( hfile funciton -- bool )
FUNCTION: GetCommTimeouts ( hfile 'timeouts -- bool )

\ --------------------------------------------------------------------

REQUIRES BITFIELDS

\ --------------------------------------------------------------------

\ DCBflags bit meaning
\  0     binary mode, no EOF check - must always be set
\  1     enable parity checking
\  2     CTS output flow control, true = output flow control
\  3     DSR output flow control, true = output flow control
\  4-5   DTR flow control, type 00=none-DTR off, 01=Always on, 10=Handshake
\  6     DSR sensitivity, true = ignore recv if DSR off
\  7     XOFF continues Tx
\  8     XON/XOFF out flow control
\  9     XON/XOFF in flow control
\  10    enable error replacement, 1=replace parity err chars with ErrorChar
\  11    enable null stripping, 1=ignore recv nul chars
\  12-13 RTS flow control, 00=none-RTS off, 01=RTS On, 10=buffer handshake,
\                          11=RTS on during xmit
\  14    abort reads/writes on error, must be reset
\  15-16 fDummy2 reserved
\  17-31 undefined

CLASS DCB
    VARIABLE DCBlength                  \ sizeof(DCB)
    VARIABLE BaudRate                   \ current baud rate

    BITVAR DCBflags
       1 BITS fBinary                   \  0 binary mode, no EOF check
       1 BITS fParity                   \  1 enable parity checking
       1 BITS fOutxCtsFlow              \  2 CTS output flow control
       1 BITS fOutxDsrFlow              \  3 DSR output flow control
       2 BITS fDtrControl               \  4 DTR flow control type
       1 BITS fDsrSensitivity           \  6 DSR sensitivity
       1 BITS fTXContinueOnXoff         \  7 XOFF continues Tx
       1 BITS fOutX                     \  8 XON/XOFF out flow control
       1 BITS fInX                      \  9 XON/XOFF in flow control
       1 BITS fErrorChar                \  A enable error replacement
       1 BITS fNull                     \  B enable null stripping
       2 BITS fRtsControl               \  C RTS flow control
       1 BITS fAbortOnError             \  E abort reads/writes on error
      17 UNUSED-BITS                    \  F fDummy2 reserved
    END-BITVAR

    HVARIABLE wReserved                 \ not currently used
    HVARIABLE XonLim                    \ transmit XON threshold
    HVARIABLE XoffLim                   \ transmit XOFF threshold

    CVARIABLE ByteSize                  \ number of bits/byte, 4-8
    CVARIABLE Parity                    \ 0-4=no,odd,even,mark,space
    CVARIABLE StopBits                  \ 0,1,2 = 1, 1.5, 2
    CVARIABLE XonChar                   \ Tx and Rx XON character
    CVARIABLE XoffChar                  \ Tx and Rx XOFF characteracter
    CVARIABLE ErrorChar                 \ error replacement character

    CVARIABLE EofChar                   \ end of input character
    CVARIABLE EvtChar                   \ received event character

    HVARIABLE wReserved1                \ reserved; do not use

    : CONSTRUCT ( -- )   [ THIS SIZEOF ] LITERAL DCBlength ! ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------------------
Comm Timeouts Structure, See COMMTIMEOUTS in Win API

If an application sets ReadIntervalTimeout and ReadTotalTimeoutMultiplier to
MAXDWORD and sets ReadTotalTimeoutConstant to a value greater than zero and
less than MAXDWORD, one of the following occurs when the ReadFile function is
called:

>  If there are any characters in the input buffer, ReadFile returns immediately
   with the characters in the buffer.
>  If there are no characters in the input buffer, ReadFile waits until a
   character arrives and then returns immediately.
>  If no character arrives within the time specified by
   ReadTotalTimeoutConstant, ReadFile times out.

If an application sets ReadIntervalTimeout a value of MAXDWORD, combined with
zero values for both the ReadTotalTimeoutConstant and
ReadTotalTimeoutMultiplier members, the read operation is to return
immediately with the characters that have already been received, even if no
characters have been received.
-------------------------------------------------------------------------------- }

CLASS COMMTIMEOUTS
    VARIABLE ReadIntervalTimeout
    VARIABLE ReadTotalTimeoutMultiplier
    VARIABLE ReadTotalTimeoutConstant
    VARIABLE WriteTotalTimeoutMultiplier
    VARIABLE WriteTotalTimeoutConstant

   : SET-TIMEOUTS ( handle n n n n n -- )
      WriteTotalTimeoutConstant   !
      WriteTotalTimeoutMultiplier !
      ReadTotalTimeoutConstant    !
      ReadTotalTimeoutMultiplier  !
      ReadIntervalTimeout         !
      ADDR SetCommTimeouts DROP ;

END-CLASS

{ --------------------------------------------------------------------
Events implemented as a class. An event is create by MAKE either as
already signaled (ie ready) or not. SIGNAL will make the event ready;
WAIT will shut down the calling thread for MAX ms or until the event
is ready and returns 0 only if the event signaled itself as ready.
-------------------------------------------------------------------- }

CLASS EVENT
   VARIABLE HANDLE
   : WAIT ( max -- ior )   HANDLE @ SWAP WaitForSingleObject ;
   : SIGNAL ( -- )   HANDLE @ SetEvent DROP ;
   : MAKE ( initial -- )   0 0 ROT 0 CreateEvent HANDLE ! ;
   : CLOSE ( -- )   HANDLE @ CloseHandle DROP  0 HANDLE ! ;
END-CLASS

{ --------------------------------------------------------------------
OVERLAPPED is a structure for managing overlapped events for
the asynchronous read/write file operations.
-------------------------------------------------------------------- }

CLASS OVERLAPPED
   VARIABLE INTERNAL
   VARIABLE INTERNALHIGH
   VARIABLE OFFSET
   VARIABLE OFFSETHIGH
   VARIABLE HEVENT
END-CLASS

{ --------------------------------------------------------------------
A circular buffer. Always write to the head and read from the tail.
-------------------------------------------------------------------- }

CLASS CIRCULAR-BUFFER

   VARIABLE HEAD
   VARIABLE TAIL

   1024 CONSTANT |BUF|

   |BUF| BUFFER: BUF

   : 'BUF ( n -- a )   0 ( ud) |BUF| UM/MOD DROP BUF + ;

   : EOB ( -- a )   |BUF| 'BUF 1+ ;

   : +HEAD ( bool -- )    1 HEAD +! ;
   : +TAIL ( -- )   1 TAIL +! ;

   : 'HEAD ( -- a )   HEAD @ 'BUF ;
   : 'TAIL ( -- a )   TAIL @ 'BUF ;

   : ANY? ( -- n )   HEAD @ TAIL @ - 0> ;

   : DOT HEAD ? TAIL ? ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

GENERIC_READ GENERIC_WRITE OR CONSTANT GENERIC_R/W
