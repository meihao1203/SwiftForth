{ ====================================================================
Serial port access extensions

Copyright 2001  FORTH, Inc.

Modem status tests contributed by Allen Anway.
Support for all bits in DCBflags contributed by Mike Ghan.
==================================================================== }

OPTIONAL SIO Serial port access extensions.

PACKAGE SERIALPORT

{ ---------------------------------------------------------------------------
Data structures

COM-PATH holds the string "\\.\" followed by COM-NAME.
COM-NAME holds the ASCIIZ string of the COM port name.

COM-SPEED holds the baud rate.

COM-SETTING holds miscellaneous settings:
   +0  DCBflags   ( 32 bits )
   +5  ByteSize   (4-8)
   +6  Parity     (0-4 --> no,odd,even,mark,space)
   +7  StopBits   (0,1,2 --> 1,1.5,2)

COMMCONFIG  is the data structure for the CommConfigDialog. It includes
an embedded DCB structure.

DCB: defines the DCB fields within COMMCONFIG.
--------------------------------------------------------------------------- }

MAX_PATH BUFFER: COM-PATH
: COM-NAME ( -- addr)   COM-PATH 4 + ;

VARIABLE COM-SPEED
2 CELLS BUFFER: COM-SETTING

CREATE COMMCONFIG   15 CELLS DUP , CELL- /ALLOT

: DCB: ( u1 u2 -- u3)   CREATE OVER , +
   DOES> ( -- addr)  @ COMMCONFIG + ;

   8                    \ Header
   4 DCB: DCB           \ Size of DCB
   4 DCB: BaudRate      \ Line speed, bits per second
   4 DCB: DCBflags      \ See flags below
   2 +                  \ Not currently used
   2 DCB: XonLim        \ Transmit XON threshold
   2 DCB: XoffLim       \ Transmit XOFF threshold
   1 DCB: ByteSize      \ Bits per character (4-8)
   1 DCB: Parity        \ 0-4 --> no,odd,even,mark,space
   1 DCB: StopBits      \ 0,1,2 --> 1,1.5,2
   1 DCB: XonChar       \ Tx and Rx XON char
   1 DCB: XoffChar      \ Tx and Rx XOFF char
   1 DCB: ErrorChar     \ Error replacement char
   1 DCB: EofChar       \ End of input char
   1 DCB: EvtChar       \ Received event char
   2 +                  \ Reserved, do not use
DROP

{ ---------------------------------------------------------------------------
More data

COMH holds the handle of the open COM port (0 if no port is open).

COMM-TIMEOUTS is an array of data to tell the open com port to
return immediately if no characters are waiting.

XKEY-FLAG is true if a character is waiting and
XKEY-CHAR is the character received.

XMT-FLAG is a holding spot for data transmission and
XMT-CHAR is a holding spot for the transmit character.

(COM-KEY?) returns true if a character has been seen and not read; if
no previous character was waiting, it checks the serial port and reads
a character if available.

(COM-KEY) waits for and returns a character.

(COM-EMIT) sends a character.
--------------------------------------------------------------------------- }

0 VALUE COMH

CREATE COMM-TIMEOUTS   -1 , 0 , 0 , 1 , 20 ,

VARIABLE XKEY-FLAG
VARIABLE XKEY-CHAR

VARIABLE XMT-FLAG
VARIABLE XMT-CHAR

PUBLIC

: (COM-KEY?) ( -- flag )
   PAUSE  XKEY-FLAG @ DUP ?EXIT DROP
   COMH XKEY-CHAR 1 XKEY-FLAG 0 ReadFile 0= THROW
   XKEY-FLAG @ ;

: (COM-KEY) ( -- char )
   BEGIN (COM-KEY?) UNTIL  XKEY-CHAR @  0 XKEY-FLAG ! ;

: (COM-EMIT) ( char -- )
   XMT-CHAR !  PAUSE
   COMH XMT-CHAR 1 XMT-FLAG 0 WriteFile 0= THROW ;

: (COM-TYPE) ( addr u -- )
   PAUSE  COMH -ROT XMT-FLAG 0 WriteFile 0= THROW ;

PRIVATE

{ ---------------------------------------------------------------------------
Configuration

COMHELP  tells the user a little about the TERM program usage.

?COMHELP  checks for a baudrate and a comport name.

SERCONFIG  runs the CommConfigDialog to let the user configure the port.

OPEN-COM  returns a handle to the requested serial device.

CLOSE-COM  closes the open com port.

COMINIT  opens the specified device and sets its initial baudrate.

COMPORT  performs initialization of the comport
--------------------------------------------------------------------------- }

: COMHELP ( -- )
   CR ." Must supply a baud rate and com port string. For example:  "
      ." 9600 COM= COM2 ."
   ABORT ;

: ?COMHELP ( -- )
   DEPTH 0= IF COMHELP EXIT THEN
   >IN @  BL WORD C@ 0= IF COMHELP EXIT THEN  >IN ! ;

: SERCONFIG ( -- )
   COMMCONFIG >R
   COM-NAME HWND R@ CommConfigDialog IF
      COMH DCB SetCommState DROP
   THEN
   R> DROP ;

: OPEN-COM ( zaddr -- handle )
   GENERIC_READ GENERIC_WRITE OR
   0
   0
   OPEN_EXISTING
   0
   0
   CreateFile
   DUP -1 = ABORT" Port not available" ;

CONSOLE-WINDOW +ORDER

: CLOSE-COM ( -- )
   COMH CloseHandle DROP  0 TO COMH
   S" Inactive" 3 SF-STATUS PANE-TYPE ;

CONSOLE-WINDOW -ORDER

: COMINIT ( zaddr -- )
   COMH IF  CLOSE-COM  THEN
   OPEN-COM TO COMH
   COMH COMM-TIMEOUTS SetCommTimeouts DROP ;

{ ---------------------------------------------------------------------
Port control

The EscapeCommFunction function directs a specified communications device
to perform an extended function.

BOOL EscapeCommFunction(
    HANDLE hFile,	// handle to communications device
    DWORD dwFunc 	// extended function to perform
   );

dwFunc	Meaning
CLRDTR	Clears the DTR (data-terminal-ready) signal.
CLRRTS	Clears the RTS (request-to-send) signal.
SETDTR	Sends the DTR (data-terminal-ready) signal.
SETRTS	Sends the RTS (request-to-send) signal.
SETXOFF	Causes transmission to act as if an XOFF character has been received.
SETXON	Causes transmission to act as if an XON character has been received.

SETBREAK suspends character transmission and places the
transmission line in a break state until the ClearCommBreak function
is called (or EscapeCommFunction is called with the CLRBREAK extended
function code). The SETBREAK extended function code is identical to
the SetCommBreak function. Note that this extended function does not
flush data that has not been transmitted.

CLRBREAK restores character transmission and places the transmission
line in a nonbreak state. The CLRBREAK extended function code is
identical to the ClearCommBreak function.

If the function succeeds, the return value is nonzero.

+DTR asserts DTR, -DTR lowers it.  And so on...
---------------------------------------------------------------------

pin  9  25  pin  connectors

     3   2  TxD  transmit data         output -->
     2   3  RxD   receive data          input <--
     7   4  RTS  request to send       output -->
     8   5  CTS    clear to send        input <--
     6   6  DSR  data set ready         input <--
     4  20  DTR  data terminal ready   output -->
     1   8  DCD  data carrier detect    input <--
     9  22  RI   ring indicator         input <--
     5   7  SG   signal ground

CTS?, DSR? etc. return true if the named modem status line is asserted.
--------------------------------------------------------------------- }

LIBRARY KERNEL32

FUNCTION: GetCommModemStatus ( hFile lpModemStat -- b )
FUNCTION: EscapeCommFunction ( hFile dwFunc -- b )

VARIABLE ModemStatus

: ?MODEM-STATUS ( mask -- flag )
   COMH ModemStatus GetCommModemStatus DROP
   ModemStatus @ AND 0<> ;

PUBLIC

: CTS? ( -- flag )   $10 ?MODEM-STATUS ;
: DSR? ( -- flag )   $20 ?MODEM-STATUS ;
: RI?  ( -- flag )   $40 ?MODEM-STATUS ;
: DCD? ( -- flag )   $80 ?MODEM-STATUS ;

: +DTR ( -- )   COMH SETDTR EscapeCommFunction DROP ;
: -DTR ( -- )   COMH CLRDTR EscapeCommFunction DROP ;

: +RTS ( -- )   COMH SETRTS EscapeCommFunction DROP ;
: -RTS ( -- )   COMH CLRRTS EscapeCommFunction DROP ;

: +BREAK ( -- )   COMH SETBREAK EscapeCommFunction DROP ;
: -BREAK ( -- )   COMH CLRBREAK EscapeCommFunction DROP ;

PRIVATE

{ ---------------------------------------------------------------------------
Comport status line

COMSTAT  is an array in which the com port status line is built.
.BAUD  puts the numeric representation of the baud rate into COMSTAT .
.COM  puts the ASCII representation of the comport into COMSTAT .
SIO.STATUS  updates the status bar with the comport information.

The message switch SBAR-MESSAGES is extended to include the detection
of a left button press on the com port status area of the status bar.
If a press is detected, the configuration dialog is displayed.
--------------------------------------------------------------------------- }

CREATE COMSTAT  256 ALLOT

: .BAUD ( -- )
   BASE @ >R DECIMAL
   BaudRate @ (.) COMSTAT APPEND
   R> BASE ! ;

: .COM ( -- )
   COM-NAME ZCOUNT COMSTAT APPEND  S" :" COMSTAT APPEND ;

CONSOLE-WINDOW +ORDER

: SIO.STATUS ( -- )
   COMH IF  0 COMSTAT C!
      .COM .BAUD COMSTAT COUNT
   3 SF-STATUS PANE-TYPE  THEN ;

CONSOLE-WINDOW -ORDER

: SIO.CONFIG ( -- )   SERCONFIG SIO.STATUS ;

' SIO.CONFIG SBLHITS 3 CELLS + !

{ --------------------------------------------------------------------
Port settings

COMSET: defines words that specify port settings.  Defined words
like N,8,1 which specify No parity, 8 data bits, 1 stop bit.
When executed, these words move parameters into COM-SETTING for
use by +COM when it initializes the port.  Do this before opening the port.
Values passed to COMSET:
   c1  StopBits (0,1,2 --> 1,1.5,2)
   c2  Parity (0-4 --> no,odd,even,mark,space)
   c3  ByteSize (4-8)
   n4  DCBflags low byte

DCBflags bits
bit#  descr              typical value
0     fBinary            1
1     fParity            x
2     fOutxCtsFlow       0
3     fOutxDsrFlow       0
4-5   fDtrControl        01
6     fDsrSensitivity    0
7     fTXContinueOnXoff  0
8     fOutX              0
9     fInX               0
10    fErrorChar         0
11    fNull              0
12-13 fRtsControl        01
14    fAbortOnError      0
15-31 fDummy2            0

-------------------------------------------------------------------- }

: COMSET: ( c1 c2 c3 c4 -- )   CREATE  , C, C, C,
   DOES> ( -- )   COM-SETTING 7 CMOVE ;

PUBLIC

0 0 8 $1011 COMSET: N,8,1         0 0 7 $1011 COMSET: N,7,1
0 1 8 $1013 COMSET: O,8,1         0 1 7 $1013 COMSET: O,7,1
0 2 8 $1013 COMSET: E,8,1         0 2 7 $1013 COMSET: E,7,1

( Default) N,8,1

{ --------------------------------------------------------------------
Open com port

+COM opens the port whose name is in COM-NAME and initializes it
with settings in COM-SPEED and COM-SETTING.  +COM is called from
within COMPORT and BAUD below.
-------------------------------------------------------------------- }

: +COM ( -- )
   S" \\.\" COM-PATH SWAP CMOVE
   COM-PATH COMINIT
   COMH DCB GetCommState DROP
   COM-SPEED @  BaudRate !
   COM-SETTING  @+ DCBflags !  COUNT ByteSize C!
   COUNT Parity C!  C@ StopBits C!
   COMH DCB SetCommState DROP  SIO.STATUS ;

: -COM ( -- )   CLOSE-COM ;

:ONSYSLOAD   0 TO COMH ;
:ONSYSEXIT   CLOSE-COM ;

{ --------------------------------------------------------------------
Select com port

COM= takes the baud rate from the stack and is followed by the port name.
It puts the port name string in COM-NAME and the baud rate in COM-SPEED
but does not open or initialize the port.

COMPORT calls COM= and then opens and initialzes the port.

COMNAME: defines named COM ports.

BAUD sets COM-SPEED and opens the port whose name is in COM-NAME
and whose settings are in COM-SETTINGS.

--------------------------------------------------------------------
USAGE EXAMPLES

Here are two ways to open COM1 for 9600 baud, even parity, 1 stop bit:

1)  COM1  E,7,1  9600 BAUD      (uses ports named by COMPORT:, extend as necessary)
2)  E,7,1  9600 COMPORT COM1    (parses port name from input stream)

Use -COM to close the port.
-------------------------------------------------------------------- }

: COM= ( baud -- )
   BL WORD COUNT  DUP 0= ABORT" NO NAME"
   COM-NAME ZPLACE  COM-SPEED ! ;

: COMPORT ( baud -- )   COM= +COM ;

PRIVATE

: COMNAME: ( -- )   >IN @  CREATE  >IN !  BL STRING
   DOES>  COUNT COM-NAME ZPLACE ;

PUBLIC

COMNAME: COM1   COMNAME: COM2   COMNAME: COM3   COMNAME: COM4
COMNAME: COM5   COMNAME: COM6   COMNAME: COM7   COMNAME: COM8


: BAUD ( n -- )   COM-SPEED !  +COM ;

END-PACKAGE

.(
Type <baud> COMPORT COM[1234] to open a connection.
)
