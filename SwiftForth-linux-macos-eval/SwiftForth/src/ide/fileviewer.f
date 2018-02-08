{ ====================================================================
Fileview facility

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( Fileview facility)

PACKAGE FILE-VIEWER

{ --------------------------------------------------------------------
|VIEW| returns the number of lines to display at once in VIEW-FILE
(1/2 the available window height as returned by GET-SIZE).

SKIP-LINE reads a line from a file without any action.
ECHO-LINE reads and prints a line

VIEW-LINES types a range of lines in a file. ior is always zero.

VIEWING opens the file and displays |VIEW| lines.
-------------------------------------------------------------------- }

2VARIABLE LINE#         \ First cell=current line#, second has target line#

: |VIEW| ( -- n )   GET-SIZE NIP 2/ 3 MAX ;

: ALINE ( addr ask fid -- 0 0 0 | got t 0 | ? ? ior)
   READ-LINE  OVER IF  1 LINE# +!   THEN ;

: SKIP-LINE ( fid -- )
   R-BUF R> 250 ROT ALINE 3DROP ;

: GOTO-LINE ( fid line -- fid )
   0 LINE# !  1 MAX 1 ?DO  DUP SKIP-LINE  LOOP ;

: ECHO-LINE ( fid -- flag )
   R-BUF  R@ 250 ROT ALINE DROP  CR  R> ROT
   LINE# 2@  DUP 5 U.R ." : "  = IF  BRIGHT TYPE NORMAL
   ELSE  TYPE  THEN  ;

: VIEW-LINES ( start len fid -- ior )
   DUP REWIND-FILE DROP  ROT GOTO-LINE  SWAP 0 ?DO
      DUP ECHO-LINE  0= IF  CR ." <-eof->" LEAVE
   THEN LOOP  DROP 0 ;

PUBLIC

: GET-VIEWLINE ( line addr len -- addr len )
   R/O OPEN-FILE IF  2DROP  S" ..."  EXIT  THEN
   SWAP GOTO-LINE ( fid)
   PAD 1+ 250 THIRD READ-LINE 2DROP PAD C!
   CLOSE-FILE DROP  PAD COUNT ;

: VIEWING-LINES ( line addr len #lines -- )   >R
   R/O OPEN-FILE THROW ( line fid)
   SWAP R> THIRD VIEW-LINES DROP
   CLOSE-FILE DROP ;

: VIEWING ( line addr len -- )    |VIEW| VIEWING-LINES ;

PRIVATE

{ --------------------------------------------------------------------
.VIEW prints the context of the VIEWING.

VIEW-FILE uses VIEWING, but remembers what was displayed.

L re-views the current viewing.

N and B advance or backup the current viewing.
-------------------------------------------------------------------- }

: .VIEW ( addr len -- addr len )
   BOLD  2DUP TYPE  NORMAL ;

: ?VIEW ( addr len -- addr len flag )
   2DUP FILE-STATUS NIP 0= ;

PUBLIC

: VIEW-FILE ( line addr len -- )
   ?VIEW IF  CR .VIEW  3DUP VIEWING   ELSE  CR .VIEW  THEN
   VIEWED CELL+ PLACE  VIEWED ! ;

: L ( -- )
   VIEWED @+  SWAP COUNT ?VIEW IF  CR .VIEW  VIEWING
   ELSE  CR ." <no current file>" 3DROP  THEN ;

: +VIEW ( n -- )   VIEWED @ + 1 MAX  VIEWED !  L ;

: N ( -- )   |VIEW| +VIEW ;
: B ( -- )   |VIEW| NEGATE +VIEW ;

END-PACKAGE
