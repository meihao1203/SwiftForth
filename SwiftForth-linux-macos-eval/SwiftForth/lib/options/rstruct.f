{ ====================================================================
Return stack temporary data

Copyright (C) 2006  Charles Melice
==================================================================== }

OPTIONAL RSTRUCT Temporary data structures allocated on the return stack

{ --------------------------------------------------------------------
This tool enable to replace the next write-only construct:

 7 cells r-alloc dup cell+ dup 2 cells +
 locals| rect point x |

with this contruct:

 [STRUCT
     cell    R-FIELD x
     2 cells R-FIELD point
     4 cells R-FIELD rect
 STRUCT]

That will result in the next compiled code:
 28 r-alloc >r 12 r@ + 4 r@ + r> locals| x point rect |
-------------------------------------------------------------------- }

256 BUFFER: RPAD

: PARSE>RPAD  ( delim -- )
   PARSE SWAP 1 CHARS - SWAP 1+ RPAD APPEND ;

: [STRUCT  ( -- offset0 count )
   S" LOCALS|" RPAD PLACE
   0 0 POSTPONE [  ; IMMEDIATE

: R-FIELD  ( offset0 count size "name" -- offset0 offset1 count+1 )
   BL PARSE>RPAD THIRD + SWAP 1+ ;  IMMEDIATE

\ Enable to insert "normal" locals int R-STRUCT.
\ Valid only at the bottom location of the r-struct.

: +LOCALS|  ( "locals'|'" -- )
   [CHAR] | PARSE>RPAD ;

: STRUCT]  \ ( (count+1)*offset count -- )
   ] SWAP
   POSTPONE LITERAL        \ data size
   POSTPONE R-ALLOC        \ addr
   POSTPONE >R
   1- 0 ?DO
       POSTPONE LITERAL    \ offset
       POSTPONE R@
       POSTPONE +
   LOOP DROP
   POSTPONE R>
   S"  |" RPAD APPEND
   RPAD COUNT EVALUATE ;  IMMEDIATE
