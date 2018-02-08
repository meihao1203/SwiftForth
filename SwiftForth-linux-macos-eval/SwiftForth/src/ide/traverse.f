{ ====================================================================
Wordlist display

Copyright 2013  FORTH, Inc.

Wordlists in SwiftForth are multistranded, each with potentially a
unique number of strands. To traverse a wordlist, we copy the array of
strands from the wordlist to an array on the return stack, then traverse
the list by processing the strand with the highest value pointed to and
updating the temporary copy. In this manner, the entire wordlist is
traversed in the opposite order that it was created (latest first). The
traversal is finished when all the links are zero.
==================================================================== }

PACKAGE NAME-TOOLS

{ --------------------------------------------------------------------
Wordlist traversal

COPY-WID copies wordlist wid to new address addr, relocating the
relative links.  The source wordlist has the count of strands as the
first cell, followed by the self-relative strand links.  The
destination wordlist has the list of relocated self-relative strand
links with a -1 "stopper" at the end.

TRAVERSE-WORDLIST traverses wordlist wid, executing xt for each word in
the list.  The stack picture for xt is:

   ( i*x nt -- j*x flag )

Data type nt is the name token (in this case, the address of the word's
name field).  The flag returned indicates whether TRAVERSE-WORDLIST
should continue (true) or terminate (false).
-------------------------------------------------------------------- }

: COPY-WID ( wid addr -- )
   SWAP WID> @+ CELLS 2>R  -1 OVER R@ + !
   2R> ROT SWAP 0 DO  OVER I + @REL  OVER I + !REL
   CELL +LOOP  2DROP ;

: LARGEST ( addr -- 'l l )
   0 OVER  BEGIN                ( 'l l a)
      DUP @ 1+ WHILE            ( not -1)
      2DUP @REL U< IF           ( 'l l a)
         -ROT 2DROP             ( a)
         DUP @REL OVER          ( 'l l a)
      THEN  CELL+
   REPEAT DROP ;

: ANOTHER ( addr -- nt | 0 )
   LARGEST DUP IF  DUP @REL  ROT !REL  L>NAME
   ELSE  NIP  THEN ;

PUBLIC

: TRAVERSE-WORDLIST ( i*x xt wid -- j*x )
   DUP WID> @ 1+ CELLS R-ALLOC  DUP >R COPY-WID
   BEGIN  R@ ANOTHER  ?DUP WHILE
      SWAP DUP >R EXECUTE 0= IF  2R> 2DROP EXIT  THEN
   R> REPEAT  R> 2DROP ;

: NAME>INTERPRET ( nt -- xt )   NAME> ;
: NAME>COMPILE ( nt -- x xt )   NAME> ['] COMPILE, ;
: NAME>STRING ( nt -- addr u )   COUNT ;

END-PACKAGE
