{ ====================================================================
Programmer tools

Copyright 2001  FORTH, Inc.
Rick VanNorman

==================================================================== }

?( Programmer tools)

{ --------------------------------------------------------------------
More? (pause while scrolling)

Call /SCROLL before starting the word that generates all the output.

Within the word, instead of CR, call ?SCROLL with the number of lines
desired to be kept together (this should be a small number and it must
be less than the height of the output window).  Note that this has no
effect if ?TTY is 0 (we're in "no tty" mode, reading input from a file
or pipe) or if SCROLLMODE is 0 (we don't care to pause scrolling).
-------------------------------------------------------------------- }

#USER
   CELL +USER #SCROLL           \ Number of lines left before pausing
TO #USER

: /SCROLL ( -- )   GET-SIZE 1- #SCROLL ! DROP ;

VARIABLE SCROLLMODE     \ False=pause for prompt; true=just keep scrolling

: ?SCROLL ( n -- )
   CR  ?TTY @ 0= SCROLLMODE @ 0= OR  IF  DROP EXIT  THEN
   -1 #SCROLL +!  #SCROLL @ > IF  GET-XY
      ." Press space for more... "  KEY BL <> THROW
   2DUP AT-XY  24 SPACES  AT-XY  /SCROLL  THEN ;

{ --------------------------------------------------------------------
Memory dump

DUMP is redefined here to use ?SCROLL.
UDUMP displays memory as unsigned cells in the current base,
IDUMP as signed cells in the current base, and
HDUMP as unsigned hex values.
-------------------------------------------------------------------- }

?( ... Dump, various forms)

-? : DUMPLINE ( addr u -- )
   1 ?SCROLL  BASE @ >R  HEX
   OVER 8 U.R SPACE  2DUP DUMPHEX  DUMPTEXT
   R> BASE ! ;

-? : DUMP ( addr u -- )   /SCROLL
   BEGIN ( a n)  2DUP 16 MIN DUMPLINE
      16 /STRING  DUP 0 <= UNTIL 2DROP ;

VARIABLE 'DOT ( a -- n )

: (DUMP) ( addr n -- )
   /SCROLL  BEGIN
      0 MAX  DUP WHILE
      1 ?SCROLL OVER H.8 ." : "
      2DUP 16 MIN BOUNDS ?DO ( a n)
         I 'DOT @EXECUTE
      ( n) +LOOP
      16 /STRING
   REPEAT 2DROP ;

: (WDUMP)   'DOT ASSIGN  W@ 4 H.0 SPACE 2 ;
: (UDUMP)   'DOT ASSIGN  @ 10 U.R SPACE 4 ;
: (IDUMP)   'DOT ASSIGN  @ 10  .R SPACE 4 ;
: (HDUMP)   'DOT ASSIGN  @    H.8 SPACE 4 ;

: WDUMP ( addr n -- )   (WDUMP) (DUMP) ;
: UDUMP ( addr n -- )   (UDUMP) (DUMP) ;
: IDUMP ( addr n -- )   (IDUMP) (DUMP) ;
: HDUMP ( addr n -- )   (HDUMP) (DUMP) ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

?( ... FYI)

: FYI ( -- )
   CR ."     ORIGIN      HERE     Total      Free" CR
   ORIGIN 9 H.R ." h"
   HERE 9 H.R ." h"
   MEMTOP -ORIGIN 9 H.R ." h"
   UNUSED  9 H.R ." h" ;

\ : SET-MEMSIZE ( n -- )   ORIGIN + HLIM ! ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

DEFER ABOUT-IMAGE ( -- addr n )
DEFER ABOUT-NAME ( -- zaddr )

' VERSION IS ABOUT-NAME

{ --------------------------------------------------------------------
Wordlist tools

.WIDNAME attempts to associate a vocabulary in the vlink list with
   the given wid. If a match is found, it prints the name of the
   vocabulary and returns true. Otherwise, returns false.

.WID prints the wid in hex then attempts to name the wid.
-------------------------------------------------------------------- }

: .WIDNAME ( wid -- flag )
   VLINK BEGIN
      @REL DUP WHILE
      2DUP CELL+ @ = IF ( wid vlink)
         BODY> >NAME .ID DROP 1 EXIT
      THEN
   REPEAT NIP ;

: .WID ( wid -- )
   DUP .WIDNAME IF  DROP EXIT  THEN  ." [" 0 H.R ." ] " ;
