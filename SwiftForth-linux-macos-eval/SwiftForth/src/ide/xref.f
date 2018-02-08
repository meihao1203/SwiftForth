{ ====================================================================
Cross Reference Utility

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

The platform-specific xref support must loaded before this.  The
marker (*) is used to denote comments for functions defined in the
platform support file.
==================================================================== }

?( Cross reference utility)

PACKAGE CROSS-REFERENCE

{ --------------------------------------------------------------------
Memory

The cross-reference list is allocated here.

0REF is the address of the cross-reference list.  The first cell of
the list has the total size of the rest of the list.

|XREF| defines the max space allocated for the list.

/REFERENCES empties the reference list.  Do this before you save a
turnkey program image if you don't want it to load a cross-reference
table.
-------------------------------------------------------------------- }

$400000 CONSTANT |XREF|         \ total size of the cross reference table
0 VALUE 0REF                    \ where the table starts (0 if no memory allocted)

PUBLIC

: /REFERENCES ( -- )
   0REF 0= IF  |XREF| ALLOCATE THROW TO 0REF  THEN  0 0REF ! ;

PRIVATE

{ --------------------------------------------------------------------
Cross-reference file image

LOAD-XREF loads the cross-reference table from the address in the code
image at relative address in XREF-IMG.

#XREF returns the size of the xref list.

SAVE-XREF takes addr at which xref list is save in the turnkey image.
Sets XREF-IMG so list can be restore when turnkey loads.  Returns
address and size of list.
-------------------------------------------------------------------- }

VARIABLE XREF-IMG               \ relative pointer to xref in turnkey image (0 if none)

: LOAD-XREF ( -- )   0 TO 0REF  /REFERENCES
   XREF-IMG @REL ?DUP IF  0REF OVER @ CELL+ CMOVE  THEN ;

PUBLIC

: #XREF ( -- u )   0REF @ CELL+ ;

: SAVE-XREF ( addr -- addr u )
   XREF-IMG !REL  0REF DUP @ CELL+ ;

PRIVATE

:ONSYSLOAD ( -- )   LOAD-XREF ;

{ --------------------------------------------------------------------
Building the xref list

The cross-reference list is allocated in virtual memory. Each entry in
the list has two cells:
   +0  referenced xt
   +4  view field (same format as LOCATE uses, textfiles only)

0REF (*) has the address of the list.
B/REF is the size (bytes per entry) 2 cells, as noted above.
/REFERENCES (*) initializes the (empty) reference list.
-------------------------------------------------------------------- }

THROW#
   S" Cross reference failed"        >THROW ENUM IOR_XREF
TO THROW#

2 CELLS CONSTANT B/REF          \ bytes per reference entry in the table
|XREF| B/REF - CONSTANT MAXREF  \ upper limit check

{ --------------------------------------------------------------------
Add data to the reference table

'FLOOR holds the address (relative to ORIGIN, so this is really an xt
limit) below which references won't be added.

THRESHOLD checks addr and if okay, sets 'FLOOR, otherwise throws an
error.  Use FFFFFFFF (-1) THRESHOLD if no references are to be added.
Use HERE THRESHOLD if only references to new words are to be added.

NO-XREF turns off additions to the cross-reference list.

(XREF)  takes an xt and appends a new entry in the REF list if the
following conditions are true:
   -- The xt is larger than the value in 'FLOOR  .
   -- The reference was made while loading a text file.
   If the list is full, the last entry is overwritten.

If cross-referencing is turned off, the vectored behaviour is replaced
with a DROP (to dispose of the xt).
-------------------------------------------------------------------- }

PUBLIC

0 VALUE 'FLOOR

: THRESHOLD ( addr -- )
   DUP -1 = IF  TO 'FLOOR EXIT  THEN
   DUP ORIGIN U< IF  >CODE  THEN
   DUP ORIGIN HERE 1+ WITHIN NOT -9 ?THROW
   CODE> TO 'FLOOR ;

: NO-XREF  ( -- )  -1 THRESHOLD  ['] DROP IS >XREF ;

PRIVATE

: (XREF) ( xt -- view xt 0 | -1 )
   0REF ?DUP IF  @ MAXREF U< IF  SOURCE=FILE IF  DUP 'FLOOR U< NOT IF
      LOCATION OVER 0REF @+ + 2!  B/REF 0REF +!
   THEN THEN THEN THEN  DROP ;

0 THRESHOLD

{ --------------------------------------------------------------------
Initial list

A very simple xref list is implemented in the kernel that uses memory
in the unused dictionary space.  We take that list and import it into
the list allocted by /REFERENCES and then move forward using this new
memory space which is outside the dictionary.
-------------------------------------------------------------------- }

' DROP IS >XREF         \ disable the kernel's xref
'REF 2@ OVER -          \ addr len of list to move
/REFERENCES             \ allocate empty list outside dictionary space
0REF !                  \ set initial size
0REF @+ CMOVE           \ copy the list to its new home
 ' (XREF) IS >XREF      \ set new xref vector

{ --------------------------------------------------------------------
Dictionary management
-------------------------------------------------------------------- }

:REMEMBER   0REF @ , ;
:PRUNE ( addr1 -- addr2 )   ?PRUNE NOT IF  @+ 0REF !  THEN ;

{ --------------------------------------------------------------------
Source display lines

.XTREF takes the line number and the address and length of the
filename, gets that line from the file, then displays it with MARKED
(see above).

.SOURCE takes the line number and filename address and length.  If
this the filename is different from LASTNAME, we display the filename.
Then we call .LINEREF to show the file/line# and .XTREF to display the
marked line itself.

.LOC takes an xt and a view field and displays the filename and line
plus the text of the line with all occurances of the word highlighted.
If the view field of the word has its file# = 0, nothing is displayed.
Uses LASTLOC to keep track of previous reference to suppress
displaying the same line multiple times.
-------------------------------------------------------------------- }

VARIABLE LASTFNAME
VARIABLE LASTLOC
VARIABLE XNAME

: .XTREF ( line addr u -- )
   +ROOT GET-VIEWLINE  XNAME @ COUNT MARKED ;

: .SOURCE ( line# file# addr u -- )
   OVER LASTFNAME @ <> IF  2 ?SCROLL  OVER LASTFNAME !
   2DUP BOLD  +ROOT TYPE  NORMAL  THEN
   2>R  OVER  1 ?SCROLL  .LINEREF  2R> .XTREF ;

FILE-VIEWER +ORDER

: .LOC ( viewfield xt -- )
   2DUP LASTLOC 2@ D= IF  2DROP EXIT  THEN  2DUP LASTLOC 2!
   >NAME XNAME !  LOHI DUP FILE#> DUP IF  .SOURCE  ELSE  2DROP 2DROP THEN ;

FILE-VIEWER -ORDER

{ --------------------------------------------------------------------
Scan list

.REFS takes an xt and displays all references to it in the xref list.
#REFS returns the number of times xt was referenced.
-------------------------------------------------------------------- }

: 'XREFS ( addr2 addr1 -- )   0REF @+ OVER + SWAP ;

: .ALL ( -- )   0 LASTFNAME !
   'XREFS ?DO  I 2@ .LOC  B/REF +LOOP ;

: .REFS ( xt -- )
   'XREFS ?DO  DUP I @ = IF I  2@  .LOC THEN
   B/REF +LOOP DROP ;

PUBLIC

: #REFS ( xt -- n )
   0  'XREFS ?DO  OVER I @ = -  B/REF +LOOP  NIP ;

PRIVATE

{ ---------------------------------------------------------------------------
Find all occurances of a word, all wordlists
--------------------------------------------------------------------------- }

: SEARCH-AGAIN ( xt -- xt true | 0 )
   >NAME DUP COUNT ROT N>LINK SEARCH-STRAND ;

: (WID-WHERE) ( a n wid -- )
   DUP>R  SEARCH-WORDLIST 0= IF  R>DROP EXIT  THEN
   ( xt)  DUP 'FLOOR U< IF  DROP R>DROP  EXIT  THEN
   3 ?SCROLL  ." WORDLIST: "  R> .WID
   BEGIN
      DUP >VIEW @ OVER  .LOC
      DUP .REFS
      SEARCH-AGAIN 0=
   UNTIL ;

: (WHERE) ( a n -- )
   0REF 0= IF 2DROP EXIT THEN
   0. LASTLOC 2!  /SCROLL  2>R
   WIDS BEGIN
      @REL ?DUP WHILE
      2R@ THIRD  CELL+ -ORIGIN  (WID-WHERE)
   REPEAT 2R> 2DROP ;

PUBLIC

: WHERE ( -- )   \ Usage: WHERE <name>
   BASE @ DECIMAL  BL WORD DUP FINDANY NIP 0= IOR_XREF ?THROW
   LASTFNAME OFF  256 R-ALLOC >R
   COUNT R@ PLACE  R> COUNT (WHERE)  BASE ! ;

AKA WHERE WH  -? AKA WHERE wh

PRIVATE

{ --------------------------------------------------------------------
Uncalled words

UNCALLED displays all words in all linked wordlists that have no
references in the cross-reference list.
-------------------------------------------------------------------- }

: #WID-UNCALLED ( u1 nt -- u2 flag )
   NAME>INTERPRET  DUP 'FLOOR U> IF  DUP #REFS 0<> AND  THEN
   0= -  TRUE ;

: .WID-UNCALLED ( nt -- flag )
   NAME>INTERPRET  DUP 'FLOOR U> IF
      DUP #REFS 0= IF
         DUP >VIEW @ OVER .LOC
   THEN THEN DROP  TRUE ;

PUBLIC

: UNCALLED ( -- )
   0REF -EXIT
   WIDS  BEGIN  @REL  ?DUP WHILE
      DUP CELL+ >WID 2>R
      0 ['] #WID-UNCALLED R@ TRAVERSE-WORDLIST IF
         3 ?SCROLL  BOLD  CR ." Wordlist: "  R@ .WID  NORMAL
         ['] .WID-UNCALLED R@ TRAVERSE-WORDLIST
      THEN  2R> DROP
   REPEAT ;

PRIVATE

END-PACKAGE
