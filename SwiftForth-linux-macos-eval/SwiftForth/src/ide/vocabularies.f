{ ====================================================================
Vocabularies, wordlist management

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( Vocabularies, wordlist management)

{ ------------------------------------------------------------------------
Vocabularies

This section completes the kernel support for vocabularies, and extends
the kernel with a few things that are either a little hard to meta
compile or just make more sense to keep apart from the kernel.

The ONLY ALSO vocabulary mechanism is implemented on the ANS wordlist.

\ a wordlist is |#STRANDS|strand0| ... |strandn-1|widlink|
\ a vocabulary is |vlink|^wordlist|

------------------------------------------------------------------------ }

?( ... Vocabularies)

: DO-VOCABULARY ( -- )
   DOES>  CELL+ @ >R
      GET-ORDER  NIP  ( wid1 ... widn-1 n )
      R> SWAP SET-ORDER ;

: (VOCABULARY) ( wid -- )
   CREATE  VLINK >LINK  ( wid) , DO-VOCABULARY ;

: VOCABULARY ( "name" -- )
   WORDLIST (VOCABULARY) ;

{ ------------------------------------------------------------------------
ORDER  displays the wordlists in the CONTEXT search order and in CURRENT.
   Note that some of the wordlists may have no associated VOCABULARY
   name and will be displayed as "[noname].

VOCS  displays all the vocabularies defined in the system.
------------------------------------------------------------------------ }

?( ... Order)

: ORDER ( -- )
   CR ."  Context: "
   CONTEXT  #ORDER @ 0 ?DO  @+ .WID  LOOP  DROP
   CR ."  Current: " CURRENT @ .WID ;

: VOCS ( -- )
   VLINK BEGIN
      @REL ?DUP WHILE
      DUP BODY> >NAME .ID
   REPEAT ;

{ --------------------------------------------------------------------
FORTH and ASSEMBLER are wordlists that really need to be vocabularies.
Here we define them as such.

ROOT-WORDLIST is the default set by -1 SET-ORDER, and must have a
minimal set of things in it.  These are aliases of existing words.
-------------------------------------------------------------------- }

?( ... ROOT management)

FORTH-WORDLIST (VOCABULARY) FORTH
ASM-WORDLIST (VOCABULARY) ASSEMBLER

ROOT-WORDLIST SET-CURRENT

: SET-ORDER SET-ORDER ;
: FORTH-WORDLIST FORTH-WORDLIST ;
: FORTH FORTH ;
: ORDER ORDER ;

ONLY FORTH ALSO DEFINITIONS

: [FORTH]   FORTH-WORDLIST +ORDER ;  IMMEDIATE

{ --------------------------------------------------------------------
/FORTH sets the default search order
-------------------------------------------------------------------- }

: /FORTH ( -- )   ONLY FORTH DEFINITIONS ;
