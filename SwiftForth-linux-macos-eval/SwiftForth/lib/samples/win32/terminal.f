{ ====================================================================
Simple SIO terminal

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL TERMINAL A simple terminal program using SwiftForth's SIO serial port words

{ ---------------------------------------------------------------------------
Timeouts and a friendly polling loop

Windows doesn't respond well to polling loops.  The implementation of
KEY? in SwiftForth is a poll, and so is the implementation of XKEY? .
In order to make the terminal app more responsive to windows, we
calculate a timeout based on how many cycles the processor spends
waiting for 100 ms for keystrokes.

TIMEOUT  is the current downcounter for the snooze action.

TOUT  is the reset value for the timeout.

CALIBRATE  calculates the proper timeout values.

SNOOZE  lets the processor sleep (windows-friendly) if TIMEOUT is
negative.  After the sleep the application is alive for 5 more cycles
round the polling loop, so we don't miss any characters.
--------------------------------------------------------------------------- }

REQUIRES SIO

PACKAGE TERMIO

VARIABLE TIMEOUT
100 VALUE TOUT

: CALIBRATE
   0 TO TOUT
   COUNTER 100 + BEGIN
      KEY? DROP
      1 +TO TOUT
      DUP EXPIRED
   UNTIL DROP
   TOUT 8 / 50 MAX DUP TO TOUT  TIMEOUT ! ;

: SNOOZE ( -- )
   TIMEOUT @ 0< IF 50 Sleep DROP  5 TIMEOUT ! THEN ;

{ ---------------------------------------------------------------------------
Simple terminal

TL-DONE  indicates that the user has hit the escape key.

TL-INIT  sets up for the terminal loop.

The caret (text cursor) is managed here because the KEY behaviour
and EMIT behaviour depend on it being off when they execute, but the
user will definitely want to see the cursor while using the terminal app.

HOSTKEY  checks for a user pressed key and transmits it. If no key is
seen, we decrement the timeout counter so that windows will be happy.

COMKEY  checks for a character arriving from the device.

TLOOP  is the loop, moving characters from the keyboard to the device and
from the device to the display until the user presses the escape key.
If no activity is detected in the timeout period, SNOOZE will pause to let
other applications have the processor.
--------------------------------------------------------------------------- }

VARIABLE TL-DONE

SERIALPORT +ORDER

: TL-INIT ( -- )   TL-DONE OFF  CALIBRATE ;

SERIALPORT -ORDER

: HOSTKEY ( -- )
   KEY? IF
      KEY  DUP 27 = IF  TL-DONE !  ELSE  (COM-EMIT)  THEN
      TOUT TIMEOUT !
   ELSE
      -1 TIMEOUT +!
   THEN ;

: COMKEY ( -- )
   (COM-KEY?) IF
      (COM-KEY) EMIT
      TOUT TIMEOUT !
   ELSE
      -1 TIMEOUT +!
   THEN ;

SERIALPORT +ORDER

: TLOOP ( -- x )
   TL-INIT BEGIN
      SIO.STATUS
      HOSTKEY
      COMKEY
      SNOOZE
   TL-DONE @ UNTIL ;

SERIALPORT -ORDER

{ ---------------------------------------------------------------------------
The application

TERM  initializes a device to the specified baud rate and runs a simple
terminal loop, printing characters received from the device and sending
characters typed to the device.

The simplest terminal program can be implemented via

: SIMPLE
   COMPORT BEGIN
      KEY? IF
         KEY DUP 27 = IF
            DROP CLOSE-COM EXIT THEN
         XMT
      THEN
      XKEY? IF
         XKEY EMIT
      THEN
   AGAIN ;

--------------------------------------------------------------------------- }

PUBLIC

SERIALPORT +ORDER

: TERM ( baud -- ) \ Usage: baud TERM COM1
   ?COMHELP
   COMPORT
   TLOOP
    CLOSE-COM ;

SERIALPORT -ORDER

END-PACKAGE

CR
CR .( Usage: <baud> TERM <comport>,  e.g. 9600 TERM COM1)
CR

