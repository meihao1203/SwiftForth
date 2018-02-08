{ ====================================================================
Popup word locate/edit/xref

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

The cross-reference, locate, and edit tools are extended here for
use with the right-click popup menu.
==================================================================== }

{ --------------------------------------------------------------------
File/line references

The cross-reference displays file/line# pairs as <f>_<l>| (the file
number, followed by 1 or more underscore characters, follwed by the
line number, terminated with a vertical bar character).

?XREF takes the address and length of what might be a file/line
reference in the above format.  Returns the line#, and the address and
length of the file name (absolute file path) plus a true flag if it's a
file/line reference. Otherwise, just returns false.
-------------------------------------------------------------------- }

PACKAGE CROSS-REFERENCE

FILE-VIEWER +ORDER

: ?XREF ( c-addr1 u1 -- line c-addr2 u2 true | false  )
   BASE @ >R DECIMAL
   0 0 2SWAP >NUMBER  OVER C@ [CHAR] _ = >R
   0 0 2SWAP [CHAR] _ SKIP >NUMBER  OVER C@ [CHAR] | = >R
   2DROP  ROT 2DROP  2R> AND IF  SWAP FILE#> +ROOT -1
   ELSE  2DROP 0  THEN  R> BASE ! ;

PUBLIC

{ --------------------------------------------------------------------
LOCATE and EDIT can be fed, via the popup command processor, very
complex patterns. In particular, patterns that are a number ending
in a vertical bar plus an arbitrary character are "cross reference
items" where the number is a line number and the arbitrary character
is a file number in the cross reference index.  This is ok, as they
are not common strings. Both may also have a normal forth word fed
to them, and are expected to act on it.

EDIT is however more complicated: one wants to be able to type
1) EDIT FOO  and have the editor start at the definition of FOO.
2) EDIT FOO.F and have the editor start on the file FOO.F
3) EDIT and have the editor start at the last location seen.
-------------------------------------------------------------------- }

-? : LOCATE ( -- )
   BL WORD COUNT  2DUP ?XREF IF  VIEW-FILE 2DROP EXIT  THEN
   LOCATE-WORD ;

-? : EDIT ( -- )
   BL WORD  DUP C@ IF  >R                       \ text following
      R@ FINDANY NIP IF                         \ is forth word
         R> COUNT EDIT-WORD EXIT  THEN          \ so edit it already
      R@ COUNT ?XREF IF ( line)                 \ is xref item?
         R> DROP  EDIT-FILE EXIT THEN           \ edit the file on line#
      R@ COUNT +ROOT FILE-STATUS NIP IF         \ not an existing file
         0 Z" Create a new file?"               \ so ask before creating it
         Z" Edit" MB_YESNO MessageBox           \
         IDNO = IF                              \ said no, so
            R> DROP EXIT THEN                   \ discard and do nothing
      THEN 1 R> COUNT +ROOT EDIT-FILE EXIT      \ edit the given file
   THEN DROP G ;

FILE-VIEWER -ORDER

END-PACKAGE
