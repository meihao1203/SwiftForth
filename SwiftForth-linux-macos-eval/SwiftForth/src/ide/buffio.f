{ ====================================================================
Buffered output personality

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
Rick VanNorman

This special terminal personality directs output to a buffer in
extended memory.
==================================================================== }

?( ... Simple buffered output)

{ --------------------------------------------------------------------
Buffered output

Usage:
   [BUF  <do some output>  BUF]
   @BUF returns the address and length of the buffered output.
   BUFZ returns the address of buffered output as a z-string.
   .BUF types the buffer.  Don't do this inside a [BUF BUF] pair.
-------------------------------------------------------------------- }

PACKAGE BUFFIO

PRIVATE

32768 CONSTANT |BUFFER|

VARIABLE 'TEXT-BUFFER

: /BUFFER ( -- )   |BUFFER| ALLOCATE THROW  'TEXT-BUFFER ! ;
: BUFFER/ ( -- )   'TEXT-BUFFER @ FREE THROW  0 'TEXT-BUFFER ! ;

:ONSYSLOAD ( -- )   /BUFFER ;
:ONSYSEXIT ( -- )   BUFFER/ ;

/BUFFER

: BUF ( -- addr )   'TEXT-BUFFER @ ;

: (B-EMIT) ( char -- )
   BUF @+ |BUFFER| MOD + C!  1 BUF +! ;

: (B-TYPE) ( c-addr u -- )
   0 ?DO COUNT (B-EMIT) LOOP DROP ;

: (B-CR) ( -- )   <EOL> COUNT (B-TYPE) ;        \ Use platform-dependent <EOL>

: INVOKE(B) ( -- )   0 BUF ! ;

CREATE SIMPLE-BUFFERING
   16 ,                 \ datasize
    7 ,                 \ #vectors
    0 ,                 \ phandle
    0 ,                 \ previous

   ' INVOKE(B) ,        \ INVOKE    ( -- )
   ' NOOP ,             \ REVOKE    ( -- )
   ' NOOP ,             \ /INPUT    ( -- )
   ' (B-EMIT) ,         \ EMIT      ( char -- )
   ' (B-TYPE) ,         \ TYPE      ( addr len -- )
   ' (B-TYPE) ,         \ ?TYPE     ( addr len -- )
   ' (B-CR) ,           \ CR        ( -- )

PUBLIC

: [BUF ( -- )   SIMPLE-BUFFERING OPEN-PERSONALITY ;
: BUF] ( -- )   CLOSE-PERSONALITY ;

: @BUF ( -- addr u )   BUF @+ ;
: .BUF ( -- )   @BUF TYPES ;
: BUFZ ( -- z-addr)   BUF @+ OVER + 0 SWAP C! ;

END-PACKAGE

{ --------------------------------------------------------------------
I-TO-Z is a class implementation of non-dictionary numeric conversion,
which can be used to produce printable numbers without changing the
dictionary based numeric conversion area.
-------------------------------------------------------------------- }

CLASS I-TO-Z

   PRIVATE

   64 BUFFER: WORKING           \ memory for conversion
    1 BUFFER: HEAD              \ end of "pad" plus null

   VARIABLE POS                 \ where we are right now

   : <## ( -- )   HEAD POS ! ;
   : ##> ( ud -- zaddr )   2DROP  POS @  0 HEAD C! ;

   : PUT ( c -- )
      POS @ WORKING = ?EXIT   -1 POS +!  POS @ C! ;

   : ONE-DIGIT ( ud -- ud )   (#) PUT ;

   : ALL-DIGITS ( ud -- 0 0 )
      BEGIN ONE-DIGIT 2DUP OR 0= UNTIL ;

   : SIGNED ( n -- )   0< IF [CHAR] - PUT THEN ;

   PUBLIC

   : Z(D.) ( d -- zstr )
      SWAP OVER DUP 0< IF DNEGATE THEN
      <##  ALL-DIGITS ROT SIGNED  ##> ;

   : Z(DU.) ( d -- zstr )
      <## ALL-DIGITS ##> ;

   : Z(.) ( n -- zstr )
      DUP 0< Z(D.) ;

   : Z(H.) ( n -- zstr )
      BASE @ >R HEX 0 Z(DU.) R> BASE ! ;

END-CLASS

{ --------------------------------------------------------------------
PRINTSTACK is a class designed to print the Forth data stack without
using any dictionary resources.
-------------------------------------------------------------------- }

I-TO-Z SUBCLASS PRINTSTACK

   256 BUFFER: IMAGE
     1 BUFFER: TAIL

   : INSERT ( addr len -- )
      DUP IMAGE  256 0 SKIP DROP  DUP IMAGE -  ROT
      < IF  3DROP  ELSE  OVER - SWAP CMOVE  THEN ;

   : /IMAGE ( -- )   IMAGE 256 ERASE  1 TAIL C! ;
   : IMAGE/ ( -- zstr )   IMAGE 256 0 SKIP DROP  0 TAIL C! ;

   : Z(.S) ( ... -- zstring )   /IMAGE
      S"  <top" INSERT  DEPTH 0 ?DO
         I PICK Z(.) ZCOUNT  INSERT  S"  " INSERT
      LOOP IMAGE/ ;

   : (.S) ( ... -- addr len )   Z(.S) ZCOUNT ;

   : (.BASE) ( n -- addr n )
      CASE
         10 OF S" Dec" ENDOF
          8 OF S" Oct" ENDOF
         16 OF S" Hex" ENDOF
          2 OF S" Bin" ENDOF
        DUP OF S" ---" ENDOF
      ENDCASE ;

END-CLASS

