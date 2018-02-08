{ ====================================================================
A serial port personality

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

OPTIONAL SERIAL A serial port personality.

REQUIRES SIO

PACKAGE SERIALPORT

: OPEN-SERIALPORT ( -- )
    S" COM1" COM-NAME ZPLACE
    COM-NAME COMINIT
    COMH DCB GetCommState DROP
    9600 BaudRate !
    COMH DCB SetCommState DROP
    SIO.STATUS ;

: CLOSE-SERIALPORT ( -- )
    COMH CloseHandle DROP  0 TO COMH
    S" Inactive" 3 SF-STATUS PANE-TYPE ;

: (COM-CR)   13 (COM-EMIT) 10 (COM-EMIT) ;

: 2ZERO ( -- 0 0 )   0 0 ;

CREATE SERIAL-PERSONALITY
    4 CELLS ,    \ datasize
    19 ,         \ number of vectors
    0 ,          \ handle, not used by serial-personality
    0 ,          \ old personality

    ' OPEN-SERIALPORT ,  \ INVOKE    ( -- )
    ' CLOSE-SERIALPORT , \ REVOKE    ( -- )
    ' NOOP ,             \ /INPUT    ( -- )
    ' (COM-EMIT) ,       \ EMIT      ( char -- )
    ' (COM-TYPE) ,       \ TYPE      ( addr len -- )
    ' (COM-TYPE) ,       \ ?TYPE     ( addr len -- )
    ' (COM-CR) ,         \ CR        ( -- )
    ' NOOP ,             \ PAGE      ( -- )
    ' DROP ,             \ ATTRIBUTE ( n -- )
    ' (COM-KEY) ,        \ KEY       ( -- char )
    ' (COM-KEY?) ,       \ KEY?      ( -- flag )
    ' (COM-KEY) ,        \ EKEY      ( -- echar )
    ' (COM-KEY?) ,       \ EKEY?     ( -- flag )
    ' (COM-KEY) ,        \ AKEY      ( -- char )
    ' 2DROP ,            \ PUSHTEXT  ( addr len -- )
    ' 2DROP ,            \ AT-XY     ( x y -- )
    ' 2ZERO ,            \ AT-XY?    ( -- x y )
    ' 2ZERO ,            \ GET-SIZE  ( -- x y )
    ' (ACCEPT) ,         \ ACCEPT    ( addr u1 -- u2 )

PUBLIC

\ test will revector normal console i/o to the serial port
\ until the user types ENOUGH which will restore the gui console
\ the quit is necessary in both cases to reset the catch frame
\ which maintains the default personality for restoring on throws.

: TEST ( -- )
    SERIAL-PERSONALITY OPEN-PERSONALITY QUIT ;

: ENOUGH ( -- )
    CLOSE-PERSONALITY  QUIT ;

END-PACKAGE

CR CR .( Type: TEST to redirect I/O, ENOUGH to terminate) CR

