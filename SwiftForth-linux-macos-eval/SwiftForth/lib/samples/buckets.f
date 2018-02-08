{ ====================================================================
buckets.f
Measure thread usage

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

OPTIONAL HASHTEST Measure how the hash distrubition is working in the existing wordlists

{ --------------------------------------------------------------------
The SwiftForth implementation of WORDLIST uses multiple strands to increase
the speed of dictionary searches.  The measure of the effeciency of the
hash algorithm is how many words are in each thread.

Requires:

Exports:  BUCKETS
-------------------------------------------------------------------- }

VARIABLE TALLIES

\ report bucket use in wordlist hashing

: TALLY ( thread -- n )
   0 SWAP BEGIN
      @REL ?DUP WHILE
      SWAP 1+ SWAP
      TALLIES ++
   REPEAT ;

: .BUCKETS ( wid -- )
   TALLIES @ >R  TALLIES OFF
   WID> @+ 0 ?DO ( a)
      DUP TALLY (.) ?TYPE S"  " ?TYPE CELL+
   LOOP DROP
   CR ."  (Total words " TALLIES ? ." )"
   R> TALLIES +! ;

: BUCKETS
   TALLIES OFF  WIDS BEGIN
      @REL ?DUP WHILE
      CR DUP CELL+ -ORIGIN DUP .WID SPACE .BUCKETS
   REPEAT
   CR ."  system words " TALLIES ? ;

CR CR .( Type BUCKETS to display # words in each WORDLIST thread.)
