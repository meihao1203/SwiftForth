{ ====================================================================
Automatically expanding buffers for output

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL BUFOUT Buffered output

{ --------------------------------------------------------------------
The class GROWING-BUFFER creates an output buffer in allocated
memory and continuously grows the buffer as strings are written to
it. Words provided for typical output functions are:

APPEND ( addr len -- )
Add a string to the buffer, growing as necessary.

CONTENT( -- addr len )
Return the entire buffer as a string.

CLEAR ( -- )
Clear the buffer.
-------------------------------------------------------------------- }

CLASS GROWING-BUFFER

   PROTECTED

   SINGLE SIZE          \ has the number of bytes in the buffer
   SINGLE NEXT          \ has the next available slot
   SINGLE DATA          \ has the address of the buffer

   PUBLIC

   \ Allocate a buffer, set up the pointers. May THROW.

   : CONSTRUCT ( -- )
      0 ALLOCATE THROW TO DATA   0 TO SIZE  0 TO NEXT ;

   \ Destroy the buffer.

   : DESTRUCT ( -- )   DATA DUP IF FREE THEN DROP
      0 TO DATA  0 TO SIZE  0 TO NEXT ;

   PROTECTED

   \ If N will fit in the buffer, do nothing. If not, double
   \ the size of the buffer and continue.

   : EXPAND ( n -- )
      NEXT +  DUP SIZE < IF DROP EXIT THEN
      2* 128 MAX  DUP >R  ALLOCATE THROW >R
      SIZE IF  DATA R@ SIZE CMOVE  THEN
      DATA FREE DROP  R> TO DATA  R> TO SIZE ;

   PUBLIC

   \ Add a string to the end of the buffer. If the buffer
   \ has not been allocated, do so. If the string will not
   \ fit in the buffer, double the size of the buffer.

   : APPEND ( addr len -- )   DATA 0= IF CONSTRUCT THEN
      DUP EXPAND  TUCK DATA NEXT + SWAP CMOVE  +TO NEXT ;

   : CONTENT ( -- addr len )   DATA NEXT ;

   : CLEAR ( -- )   DESTRUCT ;

END-CLASS

{ --------------------------------------------------------------------
We subclass GROWING-BUFFER to provide text output facilities.

PUTS ( addr len -- )   write a string to the buffer.
PUTL ( addr len -- )   write a string with a trailing crlf.
PUTC ( char -- )       write a character.
-------------------------------------------------------------------- }

GROWING-BUFFER SUBCLASS TEXT-BUFFER

   \ User interface to the class. PUTS writes a string;
   \ PUTL writes a string and a CRLF; PUTC writes a single
   \ character.  TEXT returns the address and length of
   \ the buffer.  WIPE destroys the buffer.

   : PUTS ( addr len -- )   APPEND ;
   : PUTL ( addr len -- )   APPEND  S\" \n" APPEND ;
   : PUTC ( char -- )   SP@ 1 PUTS DROP ;

END-CLASS

{ --------------------------------------------------------------------
We subclass GROWING-BUFFER to implement a stack.

PUSH pushes a single value onto the end of the buffer.
POP pops a single value off of the end of the buffer.
-------------------------------------------------------------------- }

GROWING-BUFFER SUBCLASS STACK

   : PUSH ( n -- )   SP@ CELL APPEND DROP ;
   : POP ( -- n )   NEXT CELL - 0 MAX TO NEXT  CONTENT + @ ;
   : DEPTH ( -- n )   NEXT CELL / ;

   : DOT ( -- )   CONTENT BOUNDS ?DO
         I @ .  CELL +LOOP ;

   : CLEAR ( -- )   0 TO NEXT ;

END-CLASS
