{ ====================================================================
Wordlist display

Copyright 2001  FORTH, Inc.

Requires TRAVERSE-WORDLIST
==================================================================== }

?( ... WORDS, filtered and otherwise)

PACKAGE NAME-TOOLS

{ ------------------------------------------------------------------------
Filtered words

FILTER is a holding area for a word filter.

FILTERED checks the input stream for a word following WORDS by exactly
one space. If present, this becomes the filter.

.FILTER is a version of .ID which will use the filter if present.
------------------------------------------------------------------------ }

VARIABLE #WORDS

CREATE FILTER   32 ALLOT

: FILTERED ( -- )   FILTER OFF
   /SOURCE DROP C@ BL <> IF ( text follows immediately)
      BL WORD COUNT 31 MIN FILTER PLACE  FILTER COUNT UPCASE
   THEN ;

: FILTER? ( nt -- flag )
   FILTER C@ IF
      COUNT R-BUF R@ PLACE  R> COUNT 2DUP UPCASE
      FILTER COUNT -MATCH NIP 0=
   THEN 0<> ;

: .NAME ( nt -- flag )    #WORDS ++  .ID TRUE ;

: .FILTER ( nt -- flag )
   DUP FILTER? IF  .NAME  THEN DROP  TRUE ;

: TALLIES ( u1 nt -- u2 flag )   FILTER? - TRUE ;

{ --------------------------------------------------------------------
WID-WORDS  displays all the words, sorted, from a wordlist.

WORDS displays either all or a filtered subset of the words in the
   CONTEXT wordlist.
ALL-WORDS displays words from all wids in the WIDS list. Filters
   are accepted as for WORDS.
-------------------------------------------------------------------- }

: .REPORT ( -- )
   CR #WORDS ? ."  words found." ;

PUBLIC

: WID-WORDS ( wid -- )
   FILTER OFF  ['] .NAME SWAP TRAVERSE-WORDLIST ;

PRIVATE

: ALL-WORDS ( -- )
   #WORDS OFF
   FILTERED  WIDS BEGIN
      @REL ?DUP WHILE DUP
      CELL+ >WID >R
      0 ['] TALLIES R@ TRAVERSE-WORDLIST IF
         3 ?SCROLL  BOLD  CR ." Wordlist: "  R@ .WID  NORMAL  CR
         ['] .FILTER R@ TRAVERSE-WORDLIST
      THEN  R> DROP
   REPEAT .REPORT ;

: CONTEXT-WORDS ( -- )
   #WORDS OFF  FILTERED
   ['] .FILTER CONTEXT @ TRAVERSE-WORDLIST ;

PUBLIC

: ALL ( -- addr )   ['] ALL-WORDS ;

: WORDS ( | 'all -- )
   DEPTH 0> IF
      DUP ['] ALL-WORDS = IF EXECUTE EXIT THEN
   THEN CONTEXT-WORDS ;

END-PACKAGE
