{ ====================================================================
Locate facility

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( Locate facility)

PACKAGE FILE-VIEWER

{ --------------------------------------------------------------------
The locate facility has multiple features: first, locate a given word,
returning a filename and line number

FILE#> searches the files wordlist for a match to file#.  Important:
FILES-WORDLIST must have only a single thread for this to work.

.FILES is a diagnostic tool that displays the FILES-WORDLIST.

WORD-LOCATION returns the line and file name where XT was defined. If
the name was relative (truncated), root path is NOT prepended. If flag
is true, LINE# will be set such that the line# in the VIEW field will
be highlighted when displayed.  If false, LINE# CELL+ is set to -1 to
prevent highlighting lines.
-------------------------------------------------------------------- }

: FILE#> ( file# -- addr len )
   FILES-WORDLIST WID> CELL+ BEGIN ( link)
      @REL DUP WHILE
      DUP LINK> >BODY @ THIRD = IF ( match)
         NIP LINK> >NAME COUNT EXIT
      THEN
   REPEAT 2DROP 0 0 ;

PUBLIC

: WORD-LOCATION ( xt flag -- line addr len )
   SWAP >VIEW @ HILO  ROT IF  DUP 0 LINE# 2!
   ELSE  -1 0 LINE# 2!  THEN
   SWAP FILE#>  DUP IF  +ROOT  THEN ;

: .FILES ( -- )
   FILES-WORDLIST WID> CELL+ BEGIN ( link)
      @REL DUP WHILE  CR
      DUP LINK> >BODY @ 4 H.0 SPACE
      DUP LINK> >NAME COUNT TYPE
   REPEAT DROP ;

PRIVATE

{ --------------------------------------------------------------------
LOCATED finds the xt's source and displays it.

LOCATE parses for a word and uses LOCATED if it is found.
-------------------------------------------------------------------- }

: LOCATED ( xt -- )
   TRUE WORD-LOCATION DUP 0= ABORT" Source file not available"
   LINE# CELL+ @ >R  VIEW-FILE  R> VIEWED ! ;

: LOCATE-WORD ( addr n -- )   R-BUF  R@ PLACE
   R> FINDANY IF  LOCATED  ELSE  ABORT" Can't be located"  THEN ;

PUBLIC

: LOCATE ( -- )
   BL WORD COUNT LOCATE-WORD ;

END-PACKAGE
