{ ====================================================================
Simple databases

Copyright (C) 2008  FORTH, Inc.  All rights reserved.
==================================================================== }

REQUIRES blocks
OPTIONAL DATABASE Simple database support system

{ ====================================================================
This is a port of the polyFORTH DBSS (DataBase Support System) which
was at the heart of many database-intensive applications written on
that platform.
==================================================================== }

{ --------------------------------------------------------------------
Data space

WORKING  returns the address of the working storage area used by
Ordered Indexes and Subtotaling.

ORDERED is a facility variable that serialized access to ordered
indexes during search and updating operations.
-------------------------------------------------------------------- }

1024 BUFFER: WORKING    \ FIXME!

VARIABLE ORDERED        \ Facility variable for ordered indexes
VARIABLE 'APP           \ Pointer to main report title

HERE 'APP !  ," FORTH, Inc."

#USER
   CELL +USER R#        \ Current record#
   CELL +USER 'F        \ Current file pointer
   CELL +USER P#        \ Report page#
   CELL +USER 'RPT      \ Report heading pointer
   CELL +USER 'COL      \ Column pointer in report
   CELL +USER HEAD      \ 'Head' record in a chain
TO #USER

{ --------------------------------------------------------------------
File definition & access

SAVE and RESTORE allow temporary use of a different file & record
combination. Since the Return Stack is used for temporary storage,
they must be used in the same definition and at the same level with
respect to any DO structure. Note also that these words presume that
user variables R# and 'F are adjacent.

FILE defines a file given bytes/record, records, blocks (not saved)
and absolute starting block number.

ORG, LIM, B/B and B/R return parameters for the current file (i.e.,
the one selected by the use of its name, whose address is in 'F ).

READ is a slightly misleading name, as it doesn't perform an actual
disk operation, but merely selects the current record.

RECORD is used to perform the actual disk I/O for the field operators
defined later.
-------------------------------------------------------------------- }

: SAVE ( -- )   R>  R# 2@ 2>R  >R ;
: RESTORE ( -- )   R>  2R> R# 2!  >R ;  NO-TAIL-RECURSION

: FILE ( b r n o -- )   CREATE
   HERE 'F !  , DROP ,  1024 OVER /
   OVER * H, H,  DOES> ( -- )   'F ! ;

: (FILE) ( n -- )   CONSTANT DOES> ( -- addr)   @  'F @ + ;

 0 (FILE) ORG           \ First block
 4 (FILE) LIM           \ # of records
 8 (FILE) B/B           \ Bytes/block
10 (FILE) B/R           \ Bytes/record

: SAFE ( n -- n )   DUP LIM @ U<  NOT ABORT" Outside file" ;
: READ ( n -- )   SAFE R# ! ;
: RECORD ( n -- addr )   B/R U@  B/B U@ */MOD  ORG @ + ABLOCK + ;

{ --------------------------------------------------------------------
File initialization

#B and #R are useful in determining how many blocks a file will
require and how many records will fit in a range of blocks. Note that
they are the converse of each other.

STOPPER initializes a record to all "high values". This is required
for Ordered Indexes, but is harmless for other files as the first SLOT
clears the record to zeroes.

INITIALIZE erases the entire file to zeroes, except for the STOPPER in
record 1.
-------------------------------------------------------------------- }

: #B ( nr b/r -- nb)   1024 SWAP /  DUP 1- ROT +  SWAP / ;
: #R ( nb b/r -- nr)   1024 SWAP / * ;

: STOPPER ( -- )   1 RECORD CELL+  B/R U@ CELL-  -1 FILL  UPDATE
   SAVE-BUFFERS ;

: INITIALIZE ( -- )   LIM @  B/R U@  #B 0 DO
      ORG @ I + ABUFFER 1024 ERASE  UPDATE
   LOOP  STOPPER  FLUSH ;

{ --------------------------------------------------------------------
Record allocation

AVAILABLE contains the last assigned record#. It will be accurate for
files managed by SLOT and +ORDERED .

These words follow the convention that a record is "available" if its
1st cell contains 0.

SLOT is used for allocating single records. The assigned record is
cleared to zeroes.

SCRATCH de-allocates the record, but doesn't destroy its contents
except for the 1st cell.

RECORDS returns loop values for an Ordered Index or other file which
has never "wrapped around".

WHOLE returns loop values for the entire file.
-------------------------------------------------------------------- }

: AVAILABLE ( -- addr )   ORG @  ABLOCK ;

: SLOT ( -- r )   AVAILABLE @ DUP  BEGIN  1+  LIM @ MOD
      2DUP = ABORT" File full"  DUP RECORD  DUP @ IF
         0=  [ SWAP ] UNTIL  THEN DUP  B/R U@ ERASE
   -1 SWAP !  UPDATE  DUP AVAILABLE !  UPDATE  NIP ;

: SCRATCH ( r -- )   SAFE  RECORD  0 SWAP !  UPDATE ;

: RECORDS ( -- u1 u2 )   AVAILABLE @ 1+  1 ;
: WHOLE ( -- u1 u2 )   LIM @ 1 ;

{ --------------------------------------------------------------------
 Field operators

These words access data in named fields in the current record.

ADDRESS converts a field address in WORKING to the address of that
field in the current record of the current file.

S@ , S! , and S. move strings between PAD and a given address usually
in WORKING or the equivalent field in the file.

N@ and N! move 16-bit numbers between the stack and the file.
D@ and D! move 32-bit numbers between the stack and the file.
1@ and 1! move 8-bit numbers between the stack and the file.
B@ and B! move strings between PAD and the file.

PUT puts the rest of the input stream in a specified BYTES field.
ASK awaits input and then calls PUT .
-------------------------------------------------------------------- }

: ADDRESS ( addr1 -- addr2 )   R# @ RECORD  WORKING - + ;

: S@ ( n addr -- )   PAD ROT MOVE ;
: S! ( n addr -- )   PAD SWAP ROT MOVE ;
: S. ( n addr -- )   DROP PAD SWAP -TRAILING TYPE ;

: N@ ( addr -- n )   ADDRESS H@ ;
: N! ( n addr -- )   ADDRESS H! UPDATE ;

: D@ ( addr -- n )   ADDRESS @ ;
: D! ( d addr -- )   ADDRESS ! UPDATE ;

: B@ ( n addr -- )   ADDRESS S@ ;
: B! ( n addr -- )   ADDRESS S! UPDATE ;

: 1@ ( addr -- n )   ADDRESS C@ ;
: 1! ( n addr -- )   ADDRESS C! UPDATE ;

: TEXT ( char -- )   PAD 80 BLANK  WORD COUNT PAD SWAP MOVE ;
: PUT ( n addr -- )   0 TEXT  B! ;
: ASK ( n addr -- )   REFILL IF  2DUP PUT  THEN 2DROP ;

{ --------------------------------------------------------------------
Fields within records

The words in this block define named fields within records. All return
an address in WORKING, which the operators in the previous block
convert to addresses in the file.

1BYTE fields occupy 8 bits.
NUMERIC fields occupy 16 bits.
DOUBLE fields occupy 32 bits.
BYTES fields occupy a specified number of bytes.

LINK is a field defined as the 1st 32-bits of a record. It is used by
"chains" and Ordered indexes. If you aren't using these features, you
may rename (or reuse) this field.

ENTIRE returns parameters for a pseudo-BYTES field occupying the
entire record.

FILLER skips a specified number of bytes in the description.

N?, D?, 1? and B? fetch and type data from NUMERIC, DOUBLE, 1BYTE, and
BYTES fields, respectively.
-------------------------------------------------------------------- }

: 1BYTE ( n1 -- n2 )   DUP CREATE , 1+
   DOES> ( -- addr )   @  WORKING + ;

: NUMERIC ( n1 -- n2 )   1BYTE 1+ ;
: DOUBLE ( n1 -- n2 )   NUMERIC 2+ ;

: BYTES ( n n1 -- n2 )   SWAP 2DUP CREATE , , +
   DOES> ( -- n addr )   2@  WORKING + ;

: ENTIRE ( -- n addr )   B/R U@ WORKING ;
: FILLER ( n1 -- n2 )   + ;

0 DOUBLE LINK   DROP

: N? ( addr -- )   N@ . ;
: D? ( addr -- )   D@ . ;
: 1? ( addr -- )   1@ . ;
: B? ( n addr -- )   2DUP B@ S.  SPACE ;

{ --------------------------------------------------------------------
Subtotaling

REGISTER  returns the address of the beginning of the sub-total
registers, normally in  WORKING .  Four bytes plus 8 for each total
(subtotal & grand total, 32-bits ea.) must be allotted.

REG  returns the address of the next 32-bit register, treating the
registers (as many as specified by  ZERO ) in a circle.

ZERO-REGS  initializes the subtotaling registers, given the number 32-bit
columnar totals to be maintained.  Must be used at the beginning of a
report using this feature.

SUM  is given a 32-bit value and sub-total register number, adds the
amount to the register.

FOOT  like  SUM , but uses the next register, and returns a copy of
the value.

SUB  returns the next subtotal, leaving that register cleared and
adding the sum to the associated grand total.

GRAND  copies the grand totals to the subtotals.
-------------------------------------------------------------------- }

: REGISTER ( -- addr )   WORKING 16 + ;

: REG ( -- addr )   REGISTER 2+ H@  REGISTER H@  MOD 4+
   DUP REGISTER 2+ H!  REGISTER + ;

: ZERO-REGS ( n -- )   CELLS  REGISTER  OVER 2+ 2* ERASE  REGISTER H! ;
: SUM ( n1 n2 -- )   CELLS  REGISTER +  +! ;
: FOOT ( n -- n)   DUP REG +! ;

: SUB ( n1 n2 -- )   REG  DUP >R  @
   DUP REGISTER H@ R@ + +!  0 R> ! ;

: GRAND ( -- )   REGISTER H@ >R  REGISTER 4+  DUP R@ +  SWAP R> MOVE ;

{ --------------------------------------------------------------------
Report formatting

0COL resets the column pointer to the 1st column.
+L performs a CR and increments the line counter.
+COL advances to the next column if there is one.

HEADING given the address of a title-heading table, outputs the title
and heading, and saves the address of the table to control future
columnar output.

TITLE outputs the current title/heading pair.

TITLE[ constructs the start of a title-heading structure, and returns
its starting address.  The remainder of the structure is built by
successive calls to L[ and R[.  TITLE[ is followed by the report
title, delimited by a closing right bracket (]) character.

L[ and R[ define left- and right-justified fields and are followed by
the column headers, delimited with a closing right bracket (]).  Each
takes the total field width in the report.

The title-heading structure has the following layout:
   CELL  Execution token of title display word
   <n>   Report title counted string
   <i*n> Column headings (see below)

Each column heading has the following layout:
    1    Flag (1=left justify, 2=right justify)
    1    Field width in characters
   <n>   Column heading counted string

A flag byte of 0 (with no field after it) marks the end of the title-
heading structure.  A flag byte of 3 has a byte with the number of
spaces to skip after it.  There is no string.
-------------------------------------------------------------------- }

: 0COL ( -- )   'RPT @ CELL+ COUNT + 'COL ! ;
: +L ( -- )   CR  0COL ;
: +COL ( -- )   'COL @ C@ IF  'COL @ 2+ COUNT + 'COL !  THEN ;

: .FIELD ( a n -- )
  'COL @ 2C@ CASE
      1 OF  2DUP SWAP - >R  MIN TYPE  R> SPACES  +COL  SPACE  ENDOF
      2 OF  2DUP SWAP - SPACES  MIN TYPE  +COL  SPACE  ENDOF
   2DROP  ENDCASE
   BEGIN  'COL @ 2C@ 3 = WHILE  SPACES  2 'COL +!  REPEAT  DROP ;

: HEADING ( addr -- )   DUP 'RPT !  CELL+ COUNT TYPE  +L
   BEGIN  'COL @ C@ WHILE  'COL @ 2+ COUNT .FIELD  REPEAT  0COL ;

: (TITLE) ( -- )   'RPT @ HEADING ;

: S, ( char -- )   WORD C@ 1+ ALLOT ;

: TITLE[ ( -- addr )   HERE  ['] (TITLE) ,  [CHAR] ] S,  0 C, ;

: >> ( n -- )   -1 ALLOT  3 C, C,  0 C, ;

: (COL) ( n flag -- )   -1 ALLOT  ( flag) C,  ( width) C,
   [CHAR] ] S,  ( end) 0 C, ;

: L[ ( n -- )   1 (COL) ;
: R[ ( n -- )   2 (COL) ;

{ --------------------------------------------------------------------
Page formatting

SKIP-FIELD skips one column.
SKIP-FIELDS skips a specified number of columns.

+PAGE performs the new-page functions for the report generator.

?PAGE given a number of lines, goes to the next page if there aren't
at least that many left on the current page.

+CR performs a CR and checks for page-full.

LAYOUT specifies that the title-heading table whose address is given
is the one for this report, and initializes the first page of the
report.
-------------------------------------------------------------------- }

: SKIP-FIELD ( -- )   'COL @ 2C@ IF  DUP SPACES  +COL  THEN DROP ;
: SKIP-FIELDS ( n -- )   0 ?DO  SKIP-FIELD  LOOP ;

: +PAGE ( -- )   PAGE  1 P# +!  'APP @ COUNT TYPE  2 SPACES
   DATE  2 SPACES  ." Page "  P# ?  +L  'RPT @  @EXECUTE ;

: +CR ( -- )   CR ;     \ FIXME

: LAYOUT ( addr -- )   'RPT !  0 P# !  +PAGE ;

{ --------------------------------------------------------------------
Report generator field output

.N outputs a 16-bit number in the next report column.
.D outputs a 32-bit number in the next report column.

?N fetches the contents of a specified NUMERIC field and outputs it in
the next report column.

?1 fetches the contents of a specified 1BYTE field and outputs it in
the next report column.

?S outputs a specified BYTES field from PAD .

?B fetches the contents of a specified BYTES field and outputs it in
the next report column.

.M/D/Y given a Julian date, outputs it in the next report column.
-------------------------------------------------------------------- }

: .N ( n -- )   (.) .FIELD ;
: .D ( n -- )   (.) .FIELD ;
: ?N ( addr -- )   N@ .N ;
: ?1 ( addr -- )   1@ .N ;
: ?S ( n addr -- )   DROP PAD  SWAP  .FIELD ;
: ?B ( n addr -- )   2DUP B@  PAD U@ IF  ?S  ELSE  2DROP SKIP-FIELD  THEN ;

: .M/D/Y ( n -- )   ?DUP IF  (DATE) .FIELD  ELSE  SKIP-FIELD  THEN ;

{ --------------------------------------------------------------------
Ordered Index updates

These are the tools that modify Ordered Indexes.

RSWAP swaps the record in WORKING with the current record of the
current file.

DIRECTION adjusts AVAILABLE depending upon the parameter: 1 indicates
an insertion, -1 indicates a deletion. It then returns the parameters
for the loop that will update the index.

+ORDERED inserts the record in WORKING before the record indicated by
R# in an ordered index.

-ORDERED deletes the record to which R# points from an ordered index.
-------------------------------------------------------------------- }

: RSWAP ( n addr1 addr2 -- n addr1 )
   2 PICK 0 DO  OVER I + @  OVER I + @
   2OVER -ROT I + ! I + !  CELL +LOOP DROP ;

: DIRECTION ( n --- n  addr rh rl )   AVAILABLE +! UPDATE
   ENTIRE  AVAILABLE @ 2+   SAFE R# @ ;

: +ORDERED ( -- )   1 DIRECTION DO  I RECORD RSWAP UPDATE  LOOP
   2DROP  ORDERED RELEASE ;

: -ORDERED ( -- )   ENTIRE SWAP ERASE  -1 DIRECTION SWAP DO
   I RECORD RSWAP UPDATE  -1 +LOOP  2DROP  ORDERED RELEASE ;

{ --------------------------------------------------------------------
Binary index search

These words perform a binary search of an Ordered Index.

-BINARY  performs a binary search on an ordered index, given:
  BYTES field parameters (length, addr) on the stack.
  A key in  WORKING  in the field specified.
  'F  indicates the desired ordered index file.

-BINARY  returns 'true' if the record is not found, leaving the record
pointer positioned at the record before which the given key might be
inserted; it returns 0 otherwise, leaving  R#  set to the first
occurrance of a matching key.

#BINARY is used like -BINARY , with the difference that, having
performed the search, it will abort if a match is not found.
Otherwise, it returns the record number of the main file record
associated with the index record found.
-------------------------------------------------------------------- }

: -BINARY ( n addr -- flag )
   SWAP  AVAILABLE @ 2/ 1+ DUP READ
   ORDERED GET  BEGIN DUP 1+ 2/  2OVER OVER ADDRESS
   OVER COMPARE 1- IF NEGATE THEN  R# +!  2/ DUP 0= UNTIL  DROP
   2DUP OVER ADDRESS  OVER COMPARE 0> ABS  R# +!
   OVER ADDRESS OVER COMPARE ;

: #BINARY ( n addr -- n )
    -BINARY  ORDERED RELEASE  ABORT" Unknown"  LINK D@ ;

{ --------------------------------------------------------------------
Chained records

This section supports chains of records attached to a 'head'. This
facility corresponds roughly to CODASYL "sets".

SNATCH  takes a field address and record number.  It fetches the
record number from that field, replacing it with the record number
given.  It is used to update chains.

-NEXT  reads the next record, assuming the chain is linked through
LINK , returning 'true' if there is another.

FIRST  reads the 'head' record.

-LOCATE  searches a chain for the nth record, returning 'true' if the
chain isn't that long, in which case  R#  is at the actual end of the
chain;  otherwise, leaves  R#  set to the nth record in the chain and
returns 0.

+CHAIN  inserts a new record at the nth position or the end.
-CHAIN  removes the nth record from the chain.
-------------------------------------------------------------------- }

: SNATCH ( addr r - r)   OVER D@  SWAP ROT D! ;

: -NEXT ( - t)   LINK D@  DUP 0> IF  READ 1  THEN  1- ;

: FIRST   HEAD @ READ ;

: -LOCATE ( n - r t)   1+ FIRST BEGIN  1- DUP WHILE
   -NEXT  UNTIL  THEN ;

: +CHAIN ( n -- )   -LOCATE DROP  ( nth record or end)
   SLOT LINK OVER  SNATCH  SWAP READ  LINK D! ;

: -CHAIN ( n -- )   DUP 0= ABORT" Won't"  -LOCATE ABORT" Not found"
   SAVE  LINK D@ READ  LINK 0 SNATCH  RESTORE  LINK D! ;
