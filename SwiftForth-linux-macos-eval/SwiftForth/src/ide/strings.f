{ ====================================================================
String functions

Copyright (C) 2001 FORTH, Inc.  All rights reserved

Windows and Linux require many strings to contain embedded control
characters. Typically <tab> and <newline>, but others may be required.

     \a   BEL (alert, ASCII 7)
     \b   BS (backspace, ASCII 8)
     \e   ESC (not in C99, ASCII 27)
     \f   FF (form feed, ASCII 12)
     \l   LF (ASCII 10)
     \m   CR/LF pair (ASCII 13, 10)
     \n   implementation-dependent newline, e.g. CR/LF, LF, or LF/CR.
     \q   double-quote (ASCII 34)
     \r   CR (ASCII 13)
     \t   HT (tab, ASCII 9)
     \v   VT (ASCII 11)
     \z   NUL (ASCII 0)
     \"   double-quote (ASCII 34)
     \x<hexdigit><hexdigit>
          The resulting character is the conversion of these two
          hexadecimal digits. An ambiguous conditions exists if \x
          is not followed by two hexadecimal characters.
     \\   backslash itself
     \    An ambiguous condition exists if a \ is placed before any
          character, other than those defined above.
          SwiftForth aborts with a warning message.

==================================================================== }

?( String functions)

{ ------------------------------------------------------------------------
Embedded escape sequences

GETCH takes buffer address and length, gets a one-byte character from
it, and returns the remaining buffer, length, and character.

PUTCH adds a character to the string being built at QSTRING.

\BAD complains about the ambiguous condition noted above.
------------------------------------------------------------------------ }

?( ... Embedded escape sequences)

PACKAGE STRING-TOOLS

THROW#
   S" Unexpected quoted character"   >THROW ENUM IOR_QUOTED
TO THROW#

0 VALUE QSTRING         \ Pointer to r-stack string buffer

: GETCH ( addr1 u1 -- addr2 u2 char )
   1 /STRING  OVER 1- C@ ;

: PUTCH ( char -- )
   QSTRING COUNT + C!  1 QSTRING C+! ;

: \BAD ( addr1 u1 char -- )   IOR_QUOTED THROW ;

: HEXDIG ( char -- n )
   UPPER DUP [CHAR] 9 > 7 AND - [CHAR] 0 - ;

: \HEX ( a n -- a+2 n-2 )
   GETCH HEXDIG 4 LSHIFT >R  GETCH HEXDIG  R> OR  PUTCH ;

[SWITCH ADDCH \BAD ( addr1 u1 char -- addr2 u2 )
   CHAR a RUN:  [CTRL] G PUTCH ;                \ alert (bell)
   CHAR b RUN:  [CTRL] H PUTCH ;                \ backspace
   CHAR e RUN:  27 PUTCH ;                      \ escape
   CHAR f RUN:  [CTRL] L PUTCH ;                \ form feed
   CHAR l RUN:  [CTRL] J PUTCH ;                \ line feed
   CHAR m RUN:  13 PUTCH  10 PUTCH ;            \ cr,lf (platform-independent)
   CHAR n RUN:  <EOL> COUNT QSTRING APPEND ;    \ eol (platform-dependent)
   CHAR q RUN:  [CHAR] " PUTCH ;                \ alternate double-quote
   CHAR " RUN:  [CHAR] " PUTCH ;                \ double-quote
   CHAR r RUN:  [CTRL] M PUTCH ;                \ cr
   CHAR t RUN:  [CTRL] I PUTCH ;                \ htab
   CHAR v RUN:  [CTRL] K PUTCH ;                \ vtab
   CHAR x RUN:  \HEX ;                          \ hex digits
   CHAR z RUN:  0 PUTCH ;                       \ nul
   CHAR 0 RUN:  0 PUTCH ;                       \ alternative nul
   CHAR \ RUN:  [CHAR] \ PUTCH ;                \ backslash
SWITCH]

PUBLIC

: FORMAT ( a n -- a )
   256 R-ALLOC TO QSTRING  0 QSTRING C!
   BEGIN ( a n)
      DUP 0> WHILE  GETCH
         DUP [CHAR] \ = IF
            DROP GETCH ADDCH
         ELSE  PUTCH  THEN
   REPEAT 2DROP
   QSTRING COUNT HERE PLACE
   0 TO QSTRING  HERE ;

PRIVATE

: ("PARSE) ( -- addr n )
   /SOURCE 2DUP BEGIN ( a n a n)
      ?DUP WHILE  >IN ++
      OVER C@ [CHAR] " = IF
         OVER 1- C@ [CHAR] \ <> IF
            NIP - EXIT
         THEN
      THEN
      1 /STRING
   REPEAT DROP ;

: "\PARSE ( -- c-addr )
   ("PARSE) FORMAT ;

: "\QPAD ( -- )
   $80 QHEAD +!  "\PARSE COUNT QPAD PLACE ;

PUBLIC

: UPLACE ( caddr n addr -- )
   OVER IF
      -ROT  256 R-ALLOC >R  R@ PLACE
      R> COUNT BOUNDS DO
         I C@ OVER H!  2+
      LOOP 0 SWAP H!
   ELSE
      3DROP
   THEN ;

{ --------------------------------------------------------------------
Compile strings

S" ( -- a n )
Z" ( -- zstr )
U" ( -- ustr )
C" ( -- a )

Parse a string till the next quote. If interpreting, the string
is placed in a temporary buffer and the appropriate string reference
is returned on the stack. If compiling, the string is laid down
in memory and when executed will produce the correct string reference.

S\"
Z\"
U\"
C\"

Same as above, but allow escape characters.

,"
,Z"
,U"

Parse a string, allocate memory for it, and place it in the dictionary.

,\"
,Z\"
,U\"

Same as above, but allow escape characters.
-------------------------------------------------------------------- }

?( ... String compilers)

: ,U" ( -- )   [CHAR] " WORD  ( c-addr) COUNT U, ;
: ,Z" ( -- )   [CHAR] " WORD  ( c-addr) COUNT Z, ;

: ,\" ( -- )   "\PARSE  C@ 1+ ALLOT 0 C, ALIGN ;
: ,Z\" ( -- )   "\PARSE ( c-addr) COUNT Z, ;
: ,U\" ( -- )   "\PARSE ( c-addr) COUNT U, ;

: S\" ( -- )
   STATE @ IF  POSTPONE (S")  ,\"  EXIT THEN  "\QPAD
   QPAD COUNT ;  IMMEDIATE

: C\" ( -- )
   STATE @ IF  POSTPONE (C")  ,\"  EXIT THEN  "\QPAD
   QPAD ;  IMMEDIATE

: Z\" ( -- )
   STATE @ IF  POSTPONE (Z")  ,\"  EXIT THEN  "\QPAD
   0 QPAD COUNT + C!  QPAD 1+ ;  IMMEDIATE

: .\" ( -- )
   POSTPONE S\"  POSTPONE TYPE ;  IMMEDIATE

END-PACKAGE

{ --------------------------------------------------------------------
String substitution

REPLACE changes old string to new string if found in source string.
-------------------------------------------------------------------- }

?( ... String substitution)

PACKAGE STRING-TOOLS

CREATE STRBUF   256 ALLOT

PUBLIC

: SUBST ( source len old len new len -- result len )
   LOCALS| nl n pl p |   0 STRBUF C!
   BEGIN   DUP 0> WHILE
      2DUP p pl SEARCH WHILE ( s l m l)
         ROT OVER - >R ROT R> STRBUF APPEND
         n nl STRBUF APPEND
         pl /STRING
   REPEAT 2SWAP STRBUF APPEND THEN
   2DROP STRBUF COUNT ;

: REPLACE ( new l source l old l -- result l )
   DUP>R  2OVER 2>R
   SEARCH IF    ( new l a n)
      DUP 2R> ROT - STRBUF PLACE
      R> /STRING  2SWAP STRBUF APPEND  STRBUF APPEND
   ELSE         ( new l a n)
      2R> STRBUF PLACE  R>DROP 2DROP 2DROP
   THEN  STRBUF COUNT ;

: REPLACE-CHAR ( source n oldch newch -- )
   2SWAP BEGIN ( old new a n)
      DUP WHILE
      FOURTH SCAN
      DUP IF 3DUP DROP C! THEN
   REPEAT 2DROP 2DROP ;

: SPLITSTR ( source n pattern n -- remainder n beginning n )
   2>R OVER SWAP BEGIN
      DUP 0> WHILE
      OVER 2R@ TUCK  COMPARE(CS) WHILE  \ Compare using current case sensitivity
      1 /STRING
   REPEAT THEN
   ROT THIRD OVER - 2R> 2DROP ;

PRIVATE

: -BLANKS ( addr n -- addr n )
   BL SKIP -TRAILING ;

: <BLANKS> ( addr n addr -- )   >R
   S"  " R@ PLACE  -BLANKS  R@ APPEND  S"  " R> APPEND ;

PUBLIC

: MARKED ( addr n pat n -- )
   256 R-ALLOC 256 R-ALLOC LOCALS| src pat |
   pat <BLANKS>  src <BLANKS>
   src COUNT BEGIN ( a n)
      DUP 0> WHILE
      pat COUNT SPLITSTR TYPE
      DUP 0> WHILE
         SPACE BRIGHT
         pat COUNT -BLANKS TYPE
         NORMAL
         pat C@ 1- /STRING
   REPEAT THEN 2DROP ;

: ZNEXT ( z -- z )   ZCOUNT + 1+ ;

END-PACKAGE
