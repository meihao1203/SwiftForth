{ ====================================================================
Source interpreted macros

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

This file supplies simple source macro defining.

==================================================================== }

OPTIONAL MACROS Source interpreted macros

{ --------------------------------------------------------------------
Internals

This is modeled on SwiftForth's standard INCLUDED behavior.  The
internals are redefined here to skip lines into the source file and
position >IN after the macro name and interpret from there (instead of
from the beginning of file as in standard INCLUDED).

SKIP-TEXT parses the input stream until the string c-addr u is found,
or until end of file.  The text comparison is based on the current
global case senstivity setting (i.e. CASE-SENSITIVE or
CASE-INSENSITIVE).

MACRO-INCLUDED takes the >IN offset, line# (1-relative), and the addr
len of the filename string.  It opens the file and calls MACRO-
INCLUDE-FILE to do the postioning, interpreting, and error handling.
-------------------------------------------------------------------- }

: SKIP-TEXT ( c-addr u -- )
   BEGIN BEGIN  BL WORD COUNT DUP WHILE
      2OVER COMPARE(CS) 0= IF  2DROP EXIT  THEN
   REPEAT 2DROP  REFILL 0= UNTIL  2DROP ;

PACKAGE MACRO-INTERPRETER

: (MACRO-INTERPRET) ( -- )
   BEGIN  INTERPRET  REFILL-NEXTLINE  0= UNTIL ;

: MACRO-INCLUDE-FILE ( offs line fid -- )
   SAVE-INPUT N>R  >IN OFF  LINE OFF  'SOURCE-ID OFF
   DUP >R  MAP-FILE ?DUP ( *) 0= IF
      2DUP 2>R 2>R  RP@ 'SOURCE-ID !
      0 DO  REFILL-NEXTLINE  0= -39 ?THROW  LOOP  >IN !
      ['] (MACRO-INTERPRET) CATCH ( *)
      DUP IF  .FERROR  THEN
   2R> 2DROP  2R> UNMAP-FILE DROP  THEN
   R> CLOSE-FILE  DROP  NR> RESTORE-INPUT DROP
   ( *) THROW ;

: MACRO-INCLUDED ( offs line addr len -- )
   /INCLUDE                             \ get ready
   R-BUF  R@ FULLNAME                   \ qualify the name
   R@ ZCOUNT R/O OPEN-FILE THROW        \ open the file
   R> 'FNAME @ >R 'FNAME !              \ point 'fname to our name
   F# @ >R  FNUM++                      \ save starting F#, make us new
   F# @ 'FNAME @  =FILENAME             \ keep filename for locate
   HERE >R                              \ see if anything loaded
   ['] MACRO-INCLUDE-FILE CATCH ( *)    \
   DUP IF  NIP  THEN                    \ ior, discarding remainder
   HERE R> <> IF                        \ no change in HERE, skip locate name
      HERE FENCE @REL = >R              \ was the last thing a GILD?
      F# @ 'FNAME @  =FILENAME          \ keep filename for locate
      R> IF  HERE FENCE !REL  THEN      \ reset FENCE to preserve GILDing
   THEN  R> F# !  R> 'FNAME !           \ restore f# and fname
   INCLUDE/  ( *) THROW ;               \ restore 'fname, etc

FILE-VIEWER +ORDER

: MACRO-LOCATION ( offs loc -- offs line addr len )
   LOHI FILE#>  DUP 0= ABORT" Source file not available"  +ROOT ;

PREVIOUS

{ --------------------------------------------------------------------
API

Usage:

MACRO <name>  ...text to be interpreted at run-time...  END-MACRO

MACRO defines a source macro.  The word being defined must be in a
source file.  The parameter field holds the LOCATION and >IN offset
after CREATE.  At run-time, the file is included from that point.

END-MACRO skips to end of file to terminate interpretation of the
source macro.
-------------------------------------------------------------------- }

PUBLIC

: MACRO ( -- )
   SOURCE=FILE NOT ABORT" must be in a source file"
   CREATE  LOCATION , >IN @ ,  S" END-MACRO" SKIP-TEXT
   DOES> 2@ MACRO-LOCATION MACRO-INCLUDED ;

: END-MACRO ( -- )   \\ ;

END-PACKAGE
