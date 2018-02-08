{ ====================================================================
Serial port access extensions

Copyright 2008 FORTH, Inc.  All rights reserved.

This file implements the cross-target link functions over a serial port.

Usage:
SERIAL= <path> (e.g.: SERIAL= /dev/ttyS0)
n BAUD (e.g.: 19200 BAUD)
+COM

N,8,1 is default framing: No parity, 8 data bits, 1 stop bit.

Also available: N,7,1  O,8,1  O,7,1  E,8,1  E,7,1  E,7,2.
Others can be added if need be.
==================================================================== }

PACKAGE SERIALPORT

LIBRARY libc.dylib

FUNCTION: tcgetattr ( fd addr -- n )
FUNCTION: tcsetattr ( fd n1 addr -- n )
FUNCTION: cfsetispeed ( addr n1 -- n )
FUNCTION: cfsetospeed ( addr n1 -- n )

\ n1 = optional_actions for tcsetattr(3):
0   CONSTANT TCSANOW          \ make change immediate */
1   CONSTANT TCSADRAIN        \ drain output, then change */
2   CONSTANT TCSAFLUSH        \ drain output, flush input */
\ #if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
$10 CONSTANT TCSASOFT         \ flag - don't alter h.w. state */

{ --------------------------------------------------------------------
Data structures

We know...they're not "COM ports" in Unix.  However, we keep the
naming convention from Windows, as there's quite a bit of customer
code that digs down in here.

'SERIAL holds the path to the serial device.  64 should suffice
for any /dev/tty* path.

!SERIAL stores the string in 'SERIAL such that 'SERIAL is both counted
and null-terminated.

SERIAL= <path> (e.g.: SERIAL= /dev/ttyS0) sets the path to the serial
device we're using.

Use @SERIAL to retrieve the string set by SERIAL=.  It will abort
with a message if the string is unset.

/dev/cu.usbserial is set as the default serial port at startup.

COM-NAME returns the serial port name az a zstring.

COM-SPEED holds the speed (baud rate).

COMH holds the handle of the open COM port (0 if no port is open).
In Linux, it holds the serial port's file descriptor, which can't be
stdin (0).
-------------------------------------------------------------------- }

64 BUFFER: 'SERIAL

: !SERIAL ( addr u -- )
   'SERIAL PLACE  ( null terminate) 0 'SERIAL COUNT + C! ;

PUBLIC

: SERIAL= ( <path> -- )
   BL WORD COUNT
   DUP 0= ABORT" NO NAME"
   DUP 63 > ABORT" Name too long"
   !SERIAL ;

PRIVATE

: @SERIAL ( -- addr u )
   'SERIAL COUNT ?DUP 0= ABORT" No serial port specified" ;

SERIAL= /dev/cu.usbserial

: COM-NAME ( -- z-addr )   @SERIAL DROP ;

VARIABLE COM-SPEED   0 VALUE COMH

{ --------------------------------------------------------------------
More data

(COM-KEY?)  returns true if a character has been seen and not read.
(COM-KEY)  waits for and returns a character.
(COM-EMIT) sends a character.
(COM-TYPE) sends a string.
-------------------------------------------------------------------- }

PUBLIC

: (COM-KEY?) ( -- flag )
   0 SP@ COMH ( FIONREAD) $4004667f ROT ioctl 0=
   SWAP 0<> AND ;

: (COM-KEY) ( -- char )
   0 >R  BEGIN  COMH RP@ 1 read UNTIL  R> ;

: (COM-TYPE) ( addr n -- )
   COMH -ROT write DROP ;

: (COM-EMIT) ( char -- )
   SP@ COMH SWAP 1 write 2DROP ;

PRIVATE

{ --------------------------------------------------------------------
termios interface

STTY0 holds initial serial port state, which we restore when we close
the port.

STTY1 are the settings we set.
-------------------------------------------------------------------- }

64 BUFFER: STTY0              \ Initial attributes to preserve
64 BUFFER: STTY1              \ Our settings
STTY1 DUP CONSTANT MY-IFLAG
4 + DUP CONSTANT MY-OFLAG
4 + DUP CONSTANT MY-CFLAG
4 + DUP CONSTANT MY-LFLAG
DROP

{ --------------------------------------------------------------------
Debugging tools

.STTY prints termios data (addr from TCGETATTR or TCSETATTR) in hex
and octal.
-------------------------------------------------------------------- }

0 [IF] \ debugging tools

: U.Z ( u1 u2 -- )   0 SWAP <#  0 ?DO  #  LOOP  #> TYPE  SPACE ;
: .HO ( u -- )   BASE @ SWAP  HEX  DUP 8 U.Z  OCTAL 11 U.Z  BASE ! ;

: .STTY ( addr -- )
   CR ." iflag="  DUP @ .HO  4 +
   CR ." oflag="  DUP @ .HO  4 +
   CR ." cflag="  DUP @ .HO  4 +
   CR ." lflag="  @ .HO ;

[THEN] \ debugging tools

{ --------------------------------------------------------------------
termios bits

man stty or man termios for details.  We only define the ones we use.
We disable all I/O translation, so we don't need many.
-------------------------------------------------------------------- }

\ c_iflag bits
&0000001 CONSTANT IGNBRK

\ c_cflag bits
$00000200 CONSTANT CS7        \ 7 data bits
$00000300 CONSTANT CS8        \ 8 data bits
$00000400 CONSTANT CSTOPB     \ 2 stop bits (1 if clear)
$00000800 CONSTANT CREAD      \ Enable receiver
$00001000 CONSTANT PARENB     \ Enable parity (even)
$00002000 CONSTANT PARODD     \ PARENB | PARODD = odd parity
$00008000 CONSTANT CLOCAL     \ Ignore modem signals

{ --------------------------------------------------------------------
Baud rate selection

BAUDS is the list of possible baud rates.  Note that an entry in this
table only means that the OS will accept it, not that the hardware
will.

/BAUD configures STTY1 to use COM-SPEED as the input and output baud
rate.  Note that the baud rate is not actually changed untils SET-TERM
is called.
-------------------------------------------------------------------- }

CREATE BAUDS
         0 , \ # of entries, filled in at end of table
        50 ,
        75 ,
       110 ,
       134 ,
       150 ,
       200 ,
       300 ,
       600 ,
      1200 ,
      1800 ,
      2400 ,
      4800 ,
      7200 ,
      9600 ,
     14400 ,
     19200 ,
     28800 ,
     38400 ,
     57600 ,
     76800 ,
    115200 ,
    230400 ,
HERE BAUDS !

: /BAUD ( -- )
   COM-SPEED @  BAUDS @+ SWAP DO
      DUP I @ = IF
         STTY1 SWAP 2DUP cfsetispeed ABORT" cfsetispeed() error"
         cfsetospeed ABORT" cfsetospeed() error"
         UNLOOP EXIT
      THEN
   CELL +LOOP  TRUE ABORT" Invalid baud rate" ;

{ --------------------------------------------------------------------
Serial port configuration

+CFLAG sets the bits in u in MY-CFLAG.

/STTY1 does all of our common port configuration.

+EVEN enables even parity; +ODD enables odd parity.

'STTY is an execution vector whose job it is to completely configure
STTY1 prior to SET-TERM.  If you have an odd framing requirement (such
as O,7,2), you can extend this package to add it.
-------------------------------------------------------------------- }

: +CFLAG ( u -- )   MY-CFLAG @ OR  MY-CFLAG ! ;

: /STTY1 ( -- )   STTY1 16 ERASE  /BAUD
   IGNBRK MY-IFLAG !  CREAD CLOCAL OR +CFLAG ;

: +EVEN ( -- )   MY-CFLAG @ PARODD INVERT AND  PARENB OR MY-CFLAG ! ;
: +ODD ( -- )   PARENB PARODD OR +CFLAG ;

VARIABLE 'STTY

{ --------------------------------------------------------------------
Public termios interface

SAVE-TERM preserves the terminal attributes for the serial port in
STTY0.

SET-TERM sets the terminal attributes for the serial port.

RESTORE-TERM restores the serial port to the attributes preserved
by SAVE-TERM.

(N,7,1) sets STTY1 for COM-SPEED, no parity, 7 data bits, 1 stop bit.
(N,7,1) sets STTY1 for COM-SPEED, no parity, 8 data bits, 1 stop bit.

The P,D,S (Parity,Databits,Stopbits) words below configure for
No|Odd|Even parity, D databits, S stopbits.  Default is N,8,1.
Note that these do not immediately change STTY1; rather, they change
the behavior of SET-TERM.
-------------------------------------------------------------------- }

: SAVE-TERM ( -- )
   COMH STTY0 tcgetattr ABORT" error saving serial port" ;

: SET-TERM ( -- )
   'STTY @EXECUTE
   COMH TCSANOW STTY1 tcsetattr ABORT" Error configuring serial port" ;

: RESTORE-TERM ( -- )
   COMH TCSANOW STTY0 TCSETATTR ABORT" Error restoring serial port" ;

PUBLIC

\ P,D,S: Parity,Databits,Stopbits
: (N,7,1) ( -- )   /STTY1  CS7 +CFLAG ;
: (N,8,1) ( -- )   /STTY1  CS8 +CFLAG ;
: N,8,1 ( -- )   'STTY ASSIGN  (N,8,1) ;
: N,7,1 ( -- )   'STTY ASSIGN  (N,7,1) ;
: O,8,1 ( -- )   'STTY ASSIGN  (N,8,1) +ODD ;
: O,7,1 ( -- )   'STTY ASSIGN  (N,7,1) +ODD ;
: E,8,1 ( -- )   'STTY ASSIGN  (N,8,1) +EVEN ;
: E,7,1 ( -- )   'STTY ASSIGN  (N,7,1) +EVEN ;

N,8,1 ( default )

{ --------------------------------------------------------------------
Open/close COM ports

+COM attempts to open the serial port.  Puts the file
descriptor in COMH or aborts if not successful.

-COM  closes the open COM port.  This is added to the 'ONSYSEXIT
chain so that we restore the port on exit if we didn't disconnect from
the target before quitting.
-------------------------------------------------------------------- }

: +COM ( -- )
   @SERIAL R/W OPEN-FILE ABORT" Error opening serial port"
   TO COMH  SAVE-TERM  SET-TERM ;

: -COM ( -- )
   COMH -EXIT  \ Don't close stdin!
   RESTORE-TERM  COMH CLOSE-FILE THROW  0 TO COMH ;

:ONSYSEXIT   -COM ;

{ --------------------------------------------------------------------
Select com port

COM= takes the baud rate from the stack and is followed by the port
name.  It puts the port name string in COM-NAME and the baud rate in
COM-SPEED but does not open or initialize the port.

COMPORT calls COM= and then opens and initialzes the port.

BAUD sets COM-SPEED and opens the port whose name is in COM-NAME and
whose settings are in COM-SETTINGS.
-------------------------------------------------------------------- }

: COM= ( baud -- )   SERIAL=  COM-SPEED ! ;

: COMPORT ( baud -- )   COM= +COM ;

: BAUD ( n -- )   COM-SPEED !  +COM ;

END-PACKAGE
