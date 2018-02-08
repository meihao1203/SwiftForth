{ ====================================================================
Block support for SwiftForth

Copyright (C) 1999 FORTH, Inc.  All rights reserved

This block, buffer, and parts map interface is based on the legacy
polyFORTH implementation.
==================================================================== }

OPTIONAL BLOCKS Blocks mapped to files

{ --------------------------------------------------------------------
Background

The parts system was originally ported from polyFORTH ISD4.  It has
been enhanced with the following features:

   1) Buffers are linked in most and least recently used chains.
   2) Files are charted with read-only access to allow sharing.
   3) Updated buffers are not written until all are flushed.
   4) New buffers are added if all have been updated.
   5) Added buffers are freed when buffers are flushed to files.
-------------------------------------------------------------------- }

PACKAGE BLOCK-PARTS

PUBLIC

#USER
     CELL  +USER OFFSET         \ offset from absolute block 0
     CELL  +USER 'PART          \ pointer to entry in parts map
     CELL  +USER SCR            \ current block considered by editor
     CELL  +USER CHR            \ offset in SCR
   2 CELLS +USER (SCR)          \ copy of SCR/CHR for alternating by O
TO #USER

VARIABLE 'BLOCK
VARIABLE 'BUFFER
VARIABLE 'ABLOCK

DEFER LIST ( n -- )
DEFER LOAD ( n -- )

: (BLK-SOURCE) ( -- c-addr u )
   BLK @ IF  BLK @ 'ABLOCK @EXECUTE 1024  ELSE  #TIB 2@  THEN ;

: MARK ( a n -- )   INVERSE TYPE NORMAL ;

{ --------------------------------------------------------------------
Allocate Buffers

The buffers are doubly linked in order of of use. PREV is the head of
both chains.  Its first cell points to the most recently used buffer's
descriptor.  Its second cell points to the least recently used
buffer’s descriptor.  Each buffer entry is laid out as follows:

BUF-LRU         next Least Recently Used descriptor, or zero
BUF-MRU         next More Recently Used descriptor, or zero
BUF-NUM         block number (-1 if buffer is empty)
BUF-UPD         update flag, set to U of updating task
BUF-PART        parts table entry, set during block read
BUF-ADDR        pointer to data buffer

Buffers are in external memory and must be initialized on power up.

NB holds the number of buffers.  Its second cell contains the number
of buffers that the user last requested with MAXBUFFERS.

PREV holds the address of the most recently used buffer.  Its second
cell holds the address of the Least Recently Used buffer.

FLUSHING is a facility variable that is held when the system is saving
the buffers to disk.

DISK is a facility variable that is held while a task is modifying the
disk buffers.

,BUFFER links the given buffer into the top of the buffer chains and
increments NB .

MOREBUFFERS allocates memory to hold the given number of buffers and
adds them to the buffer chains.

-BUFFER removes the buffer from the buffer chains and decrements NB.

LESSBUFFERS removes the given number of buffers from the buffer chains
and frees the memory allocated for each.  The buffer with the highest
memory address is freed first.

MAXBUFFERS adds or removes buffers if necessary so the total is n.

.BUFFERS  displays the buffer pool.  It is harmless and can be very
useful in learning how the LRU buffer manager works.  Empty buffers
are denoted by displaying 'FREE' rather than block number FFFFFFFF.
The first buffer listed is the most recently accessed. Each buffer
listed after the first was accessed less recently than the one above
it and more recently than the one below it. UPDATEd buffers are
indicated with the U character.
-------------------------------------------------------------------- }

PUBLIC

2VARIABLE NB
2VARIABLE PREV
VARIABLE FLUSHING
VARIABLE DISK

PRIVATE

: (BUF) ( o -- o' ) \ Usage: (BUF) <name>
   CREATE
      DUP , CELL+
   DOES> ( a --  a' )
      @ + ;

0 (BUF) BUF-LRU
  (BUF) BUF-MRU
  (BUF) BUF-NUM
  (BUF) BUF-UPD
  (BUF) BUF-PART
  (BUF) BUF-ADDR
CELL- 1024 + CONSTANT |BUFFER|

: ,BUFFER ( a -- )
   PREV @ DUP IF
      2DUP BUF-MRU !
   ELSE  OVER PREV CELL+ !
   THEN  OVER BUF-LRU !  DUP PREV !
   DUP BUF-NUM ON  DUP BUF-UPD OFF
   0 OVER BUF-MRU !  BUF-PART OFF
   1 NB +! ;

: MOREBUFFERS ( n -- )
   ?DUP 0= ?EXIT  0 DO
      |BUFFER| ALLOCATE THROW
      ,BUFFER
   LOOP ;

: -BUFFER ( a -- )
   DUP PREV @ = IF
      DUP BUF-LRU @ PREV !
   THEN  DUP PREV CELL+ @ = IF
      DUP BUF-MRU @ PREV CELL+ !
   THEN  DUP BUF-MRU @ ?DUP IF
      OVER BUF-LRU @ SWAP BUF-LRU !
   THEN  DUP BUF-LRU @ ?DUP IF
      OVER BUF-MRU @ SWAP BUF-MRU !
   THEN  DROP  -1 NB +! ;

: LESSBUFFERS ( n -- )
   ?DUP 0= ?EXIT  0 DO
      PREV @ DUP  NB @ 0 DO
         BUF-LRU @  2DUP U< IF
            NIP DUP
      THEN  LOOP  DROP
      DUP -BUFFER  FREE THROW
   LOOP ;

PUBLIC

: MAXBUFFERS ( n -- )
   DUP NB CELL+ !
   NB @ - DUP 0> IF
      DUP MOREBUFFERS
   ELSE  DUP 0< IF
      NEGATE DUP LESSBUFFERS
   THEN  THEN  DROP ;

: .BUFFERS ( -- )
   BASE @  PREV  NB @ 0 DO
      I 4 MOD 0= IF  CR  THEN
      BUF-LRU @ DUP IF
         DUP BUF-ADDR  HEX 9 U.R  ."  = "
         DUP BUF-NUM @  DUP -1 = IF
            DROP  ."  FREE"
         ELSE  DECIMAL 5 U.R
         THEN  DUP BUF-UPD @  IF
            ."  U"  ELSE  2 SPACES
      THEN  ELSE  LEAVE  THEN
   LOOP  DROP  BASE !  SPACE ;

{ ------------------------------------------------------------------------
LRU buffer manager, unsigned, single-length

ESTABLISH moves the given buffer to the top of the PREV chain,
identifying it with the given block number and clearing its update
flag.

OLDEST returns the oldest buffer's block number.

?ABSENT searches for a given block number.  If present, brings the
buffer to the top, exiting the calling routine with the buffer address
on stack.  If absent, leaves the block number.

?UPDATED picks the LRU buffer.  If the buffer was not updated or is
free, exits the calling routine with buffer address on the stack.  If
it was updated and not free, returns buffer address under block number
and continues.  In either case the buffer is marked empty.

?-UPDATED searches the buffer chain from least to most recently
accessed until it finds a buffer that is free or not updated.  If it
finds one, it exits the calling routine with the buffer address on the
stack.  Otherwise, it continues with the stack empty.
------------------------------------------------------------------------ }

PRIVATE

: (ESTABLISH) ( n a -- a )
   DUP >R  [ ' BUF-ADDR >BODY @ ] LITERAL -
   DUP BUF-MRU @  ?DUP IF
      OVER BUF-LRU @  ?DUP IF
         2DUP BUF-MRU !  SWAP BUF-LRU !
      ELSE  0 OVER BUF-LRU !  PREV CELL+ !
      THEN  0 OVER BUF-MRU !  PREV @
      2DUP BUF-MRU !  OVER BUF-LRU !
      DUP PREV !
   THEN  BUF-NUM !  R> ;

PUBLIC

: ESTABLISH ( n a -- a )
   (ESTABLISH)  DUP [ 0 BUF-ADDR 0 BUF-UPD - ]
   LITERAL - OFF ;

: OLDEST ( -- n )
   PREV CELL+ @ BUF-NUM @ ;

PRIVATE

: ?ABSENT ( n -- a | n )
   FLUSHING @ ?EXIT
   PREV @  BEGIN
      2DUP BUF-NUM @ <> WHILE
         BUF-LRU @  ?DUP 0=
      UNTIL  EXIT
   THEN  BUF-ADDR (ESTABLISH)
   R> DROP ;

: ?UPDATED ( -- a | a n )
   PREV CELL+ @  DUP BUF-ADDR SWAP
   DUP BUF-NUM @ SWAP  DUP BUF-NUM ON
   DUP BUF-UPD @ SWAP  BUF-UPD OFF  IF
      1+ DUP IF
         1-  EXIT
   THEN  THEN  R> 2DROP ;

: ?-UPDATED ( -- a | )
   PREV CELL+ @  BEGIN
      DUP BUF-UPD @ WHILE
         DUP BUF-NUM @ 1+ WHILE
            BUF-MRU @  ?DUP 0=
         UNTIL  EXIT
   THEN  THEN  DUP BUF-NUM ON
   DUP BUF-UPD OFF  BUF-ADDR
   R> DROP ;

{ ------------------------------------------------------------------------
Vectored blocks, unsigned, single-length

ABSOLUTE takes an OFFSET relative block number and returns an absolute
block number.  Note that this relativization is done in IDENTIFY ,
BUFFER , and BLOCK .

RELATIVE takes an absolute block number and returns an OFFSET relative
block number.

IDENTIFY marks the most recently used buffer as containing the given
block and turns off its update flag.

AIDENTIFY uses an absolute block number.

BUFFER returns the address of a non-updated buffer marked for the
given block, without necessarily accessing the disk.

ABUFFER uses an absolute block number.

BLOCK returns the address of a buffer containing the newest copy of
the given block.

ABLOCK uses an absolute block number.
------------------------------------------------------------------------ }

PUBLIC

: ABSOLUTE ( n -- n )   OFFSET @ + ;
: RELATIVE ( n -- n )   OFFSET @ - ;

: AIDENTIFY ( n -- )
   PREV @ DUP BUF-UPD OFF
   BUF-NUM ! ;

: IDENTIFY ( n -- )   ABSOLUTE AIDENTIFY ;

PRIVATE

: _BLOCK   'BLOCK @EXECUTE ;
: _BUFFER  'BUFFER @EXECUTE ;

PUBLIC

: ABUFFER ( n -- a )
   DISK GET  _BUFFER ESTABLISH  DISK RELEASE ;
: BUFFER ( n -- a )   ABSOLUTE ABUFFER ;

: ABLOCK ( n -- a )
   PAUSE ?ABSENT  DISK GRAB  _BLOCK
   DISK RELEASE ;
: BLOCK ( n -- a )   ABSOLUTE ABLOCK ;

{ ------------------------------------------------------------------------
Block Mapping

#PARTS returns the maximum number of available parts.

(PART) defines words that return addresses in the descriptor pointed
to by user variable 'PART :

#BLOCK holds the starting block number or -1 if no file mapped.
#LIMIT holds the ending block number + 1.
FILE-HANDLE holds the OS file handle.
FILE-UPDATED flag is set when a block in this file is updated.
FILE-MODE holds the access rights when the file is opened ( R/W ,
R/O , W/O ) .

The above fields have been carefully organized for the fastest
possible searching during block-to-file translation.

The filename index is still an integer, 0-255.

The filename table that points to the names in the dictionary
contains origin relative pointers.

PARTS is the array of the above descriptors.  It is established when
the system is powered up.

The parts array looks like:

        #block(0)  #block(1)  ... #block(n-1)
        #limit(0)  #limit(1)  ... #limit(n-1)
        fhandle(0) fhandle(1) ... fhandle(n-1)
        fupdate(0) fupdate(1) ... fupdate(n-1)
        fmode(0)   fmode(1)   ... fmode(n-1)
        fname(0)   fname(1)   ... fname(n-1)

#BLOCKS returns the number of 1K blocks for the file mapped in
the part pointed to by 'PART .

------------------------------------------------------------------------ }

256 CONSTANT #PARTS

PRIVATE

: (PART) ( o n -- o' ) \ Usage: (PART) <name>
   CREATE
      OVER , +
   DOES> ( -- a )
      @ 'PART @ + ;

PUBLIC

0 CELL (PART) #BLOCK       #PARTS 1- CELLS +
  CELL (PART) #LIMIT       #PARTS 1- CELLS +
  CELL (PART) FILE-HANDLE  #PARTS 1- CELLS +
  CELL (PART) FILE-UPDATED #PARTS 1- CELLS +
  CELL (PART) FILE-MODE    #PARTS 1- CELLS +
  CELL (PART) #FILENAME    #PARTS 1- CELLS +

CONSTANT |PARTS|

CREATE PARTS   |PARTS| ALLOT   PARTS |PARTS| -1 FILL

: #BLOCKS ( -- n )   #LIMIT @  #BLOCK @ - ;

{ ------------------------------------------------------------------------
Block Mapping

'FILENAMES is a list of pointers to counted file name strings.

/FILES initializes the file name pointer table.

>FILENAME returns the address of pointer number n in the
'FILENAMES array.  This is the address of a counted filename
string or 0.

-PATHS removes the directory paths for all the files in the 'FILENAMES
table.  All files will then be referenced from the directory where the
executable program resides, rather than from the directory that they
were compiled in.

'FILENAME returns the address of the counted filename string for
the current part, 0 if none.

MAPPED takes absolute block number and returns it along with
address of part descriptor ap and part number p that hold the
block.  If block is not found in the map, returns 0 instead of ap
and p is illegal part number.  It assumes #BLOCK starts at PARTS
and that #LIMIT is offset from #BLOCK by #PARTS cells.

------------------------------------------------------------------------ }

PRIVATE

CREATE 'FILENAMES  256 CELLS ALLOT

PUBLIC

: /FILES ( -- )   'FILENAMES 256 CELLS ERASE ;

/FILES

: >FILENAME ( n -- a )   CELLS 'FILENAMES + ;

: -PATHS ( -- )
   256 0 DO
      I >FILENAME @ ?DUP IF
         +ORIGIN COUNT  -PATH  SWAP 1-
         DUP -ORIGIN I >FILENAME !  C!
   THEN  LOOP ;

: 'FILENAME ( -- a )
   #FILENAME @ >FILENAME @ +ORIGIN ;

: MAPPED ( n -- n ap p )
   PARTS #PARTS [ASM
      EDI PUSH
      1 CELLS [EBP] EAX MOV  \ EAX = n
      0 CELLS [EBP] EDI MOV  \ EDI = 'PARTS
      0 # 0 [EBP] MOV        \ Initial ap
      EBX ECX MOV            \ ECX = #PARTS
      EBX EDX MOV            \ EDX = #PARTS
      EDX DEC                \ EDX = #PARTS-1
   1 L:
      SCASD                  \ Scan from 'PARTS
                             \ For #PARTS
                             \ Looking for n
      2 L# JAE
      1 L# LOOP
      EDI POP
      RET

   2 L:
      0 [EDI] [EDX*4] EAX CMP \ Check limit
      3 L# JB
      1 L# LOOP
      EDI POP
      RET

   3 L:
      CELL # EDI SUB         \ Start of parts
      EDI 0 [EBP] MOV        \ Write to stack
      ECX EBX SUB            \ Return part #
      EDI POP
      RET   END-CODE

{ ------------------------------------------------------------------------
Win32 Block I/O

These words implement block read and write for the block manager.

FHANDLE returns the handle from the given parts map entry.

SEEK-BLOCK positions the file read/write pointer to the start of
the given block number.

BLOCK-READ fills the given block address with end-of-file
characters, then reads the block from the file.  This allows non-
block files to be updated with the block words without adding
garbage to its end.

BLOCK-WRITE writes the given block to the file.  It also sets the
updated flag in the file's parts map entry.

------------------------------------------------------------------------ }

PRIVATE

: FHANDLE ( ap -- handle )
   [ ' FILE-HANDLE >BODY @ ] LITERAL + @ ;

: SEEK-BLOCK ( n ap -- )
   DUP -ROT  [ ' #BLOCK >BODY @ ] LITERAL + @
   - 1024 * 0 ( ap d )  ROT
   FHANDLE REPOSITION-FILE THROW ;

: BLOCK-READ ( a n ap p -- )
   DROP  DUP 0= THROW  ROT DUP 1024 26 FILL
   -ROT TUCK SEEK-BLOCK ( a ap ) 1024 SWAP
   FHANDLE READ-FILE THROW DROP ;

: BLOCK-WRITE ( a n ap p -- )
   DROP  DUP 0= THROW
   TUCK SEEK-BLOCK ( a ap ) 1024 SWAP
   FHANDLE WRITE-FILE THROW ;

{ ------------------------------------------------------------------------
Block and Buffer

(BUFFER) is the routine that performs the work of BUFFER .  It
finds a disk buffer and makes it available to the task, writing
out the old data if the data was marked as updated with UPDATE .

(BLOCK) performs the actual work of BLOCK .  It takes the block
number from the stack, finds a disk buffer in which to write the
new data from disk, reads the data, and returns the address of
the block buffer into which the newly read data was transferred.

?MAPPED returns true if the part pointed to by 'PART has a valid
32-bit block number.

MAPPED? aborts if ?MAPPED returns false (no part).

>PART sets 'PART to the given part# if the number is valid.

PART sets OFFSET to the start of part  n .

------------------------------------------------------------------------ }

PRIVATE

: (BUFFER) ( -- a )
   ?UPDATED  OVER SWAP MAPPED BLOCK-WRITE ;

: (NEW-BUFFER) ( -- a )
   ?-UPDATED  1 MOREBUFFERS  PREV @ BUF-ADDR ;

: (BLOCK) ( n -- a )
   ?ABSENT  'BUFFER @EXECUTE
   2DUP SWAP MAPPED OVER >R BLOCK-READ
   ESTABLISH  R> PREV @ BUF-PART ! ;

: ?MAPPED ( -- t )   #BLOCK @ 0< NOT ;

: MAPPED? ( -- )
   ?MAPPED NOT ABORT" Not mapped" ;

PUBLIC

: >PART ( n -- )
   DUP #PARTS U< NOT ABORT" No part"
   CELLS PARTS +  'PART ! ;

: PART ( n -- )
   >PART MAPPED?  #BLOCK @ OFFSET ! ;

' (NEW-BUFFER) 'BUFFER !
' (BLOCK)  'BLOCK  !
' ABLOCK 'ABLOCK !

{ ------------------------------------------------------------------------
Defered File Writes

SET-UPDATES sets the parts map update flags for any buffers that
have been updated.  This is to cover the case of n BUFFER UPDATE .

CLEAR-UPDATES removes all the update flags from the parts map.

UPDATED-R/W goes through the parts map changing the access mode
of any files that have been updated to R/W.  If the file is
already opened with R/W access, it simply clears the update flag,
assuming it has been opened with something other than CHART.  If
there is an error opening the file with R/W access, the file
handle is left cleared.

UPDATED-R/O goes through the parts map changing the access mode
of any files that have been updated back to R/O.  If there is an
error opening the file with R/O access, the file handle is left
cleared, and we have a serious problem.

REOPEN-FILES goes through the file name table, opening each one
that has been set.  If the file name does not contain a path,
then it is opened in the local directory.

UPDATE marks the most recently used buffer as updated.

EMPTY-BUFFERS unconditionally marks all buffers as empty, clears
all the update flags and frees any extra buffers.  Distructive!!!

(SAVE-BUFFERS) writes all updated buffers to disk and retains
their existing block numbers.  This is the previous behavior of
SAVE-BUFFERS .

SAVE-BUFFERS reopens all the updated files with R/W access and
writes the updated buffers only if that is successful.  It then
reopens the updated files with R/O access and clears the update
flags only if everything worked ok.

(FLUSH) writes all updated buffers to disk and returns with the
buffer pool empty.  This is the previous behavior of FLUSH .

FLUSH reopens all the updated files with R/W access and writes
the updated buffers only if that is successful.  It then reopens
the updated files with R/O access and clears the update flags and
frees any extra buffers only if everything worked ok.

------------------------------------------------------------------------ }

PRIVATE

: SET-UPDATES ( -- )
   'PART @  PREV  BEGIN
      @ ?DUP WHILE
         DUP BUF-UPD @ IF
            DUP BUF-NUM @ MAPPED >PART
            FILE-UPDATED ON  2DROP
         THEN  BUF-LRU
   REPEAT  'PART ! ;

: CLEAR-UPDATES ( -- )
   'PART @  #PARTS 0 DO
      I >PART  FILE-UPDATED OFF
   LOOP  'PART ! ;

: UPDATED-R/W ( -- )
   'PART @  #PARTS 0 DO
      I >PART  FILE-UPDATED @ IF
         FILE-MODE @  R/O = IF
            FILE-HANDLE @ ?DUP IF
               CLOSE-FILE THROW
            THEN  FILE-HANDLE OFF
            'FILENAME COUNT R/W OPEN-FILE THROW
            FILE-HANDLE !  R/W FILE-MODE !
         ELSE  FILE-UPDATED OFF
   THEN  THEN  LOOP  'PART ! ;

: UPDATED-R/O ( -- )
   'PART @  #PARTS 0 DO
      I >PART  FILE-UPDATED @ IF
         FILE-MODE @  R/W = IF
            FILE-HANDLE @ ?DUP IF
               CLOSE-FILE THROW
            THEN  FILE-HANDLE OFF
            'FILENAME COUNT R/O OPEN-FILE THROW
            FILE-HANDLE !  R/O FILE-MODE !
   THEN  THEN  LOOP  'PART ! ;

PUBLIC

: REOPEN-FILES ( -- )
   'PART @  #PARTS 0 DO
      I >FILENAME @ IF
         I >PART  FILE-HANDLE OFF
         'FILENAME COUNT R/O OPEN-FILE THROW
         DUP FILE-HANDLE !  R/O FILE-MODE !
         FILE-SIZE THROW  1023 M+ 1024 M/
         #LIMIT @ SWAP - #BLOCK !
   THEN  LOOP  'PART ! ;

: UPDATE ( -- )
   PREV @ [ASM
      ESI 0 BUF-UPD [EBX] MOV \ Set update flag
      0 BUF-PART [EBX] EBX MOV \ Get parts addr
      EBX EBX OR   0= NOT IF   \ Set parts update flag
         ESI ' FILE-UPDATED >BODY @ [EBX] MOV
   THEN   ASM] DROP ;

: EMPTY-BUFFERS ( -- )
   NB @ 0 DO
      -1 PREV CELL+ @ BUF-ADDR ESTABLISH DROP
   LOOP  CLEAR-UPDATES  NB CELL+ @ MAXBUFFERS ;

: (SAVE-BUFFERS) ( -- )
   DISK GET  FLUSHING GRAB  NB @ 0 DO
      OLDEST _BUFFER ESTABLISH DROP
   LOOP  FLUSHING RELEASE  DISK RELEASE ;

: SAVE-BUFFERS ( -- )
   ['] (BUFFER) 'BUFFER !  SET-UPDATES
   ['] UPDATED-R/W CATCH DUP 0= IF
      ['] (SAVE-BUFFERS) CATCH OR
   THEN  ['] (NEW-BUFFER) 'BUFFER !
   ['] UPDATED-R/O CATCH OR THROW
   CLEAR-UPDATES ;

: (FLUSH) ( -- )
   DISK GET  FLUSHING GRAB  NB @ 0 DO
      -1 _BUFFER ESTABLISH DROP
   LOOP  FLUSHING RELEASE  DISK RELEASE ;

: FLUSH ( -- )
   ['] (BUFFER) 'BUFFER !  SET-UPDATES
   ['] UPDATED-R/W CATCH DUP 0= IF
      ['] (FLUSH) CATCH OR
   THEN  ['] (NEW-BUFFER) 'BUFFER !
   ['] UPDATED-R/O CATCH OR THROW
   CLEAR-UPDATES  NB CELL+ @ MAXBUFFERS ;

{ ------------------------------------------------------------------------
Unmap Files

UNMAPPED returns the number of the lowest unmapped part.

(UNMAP) is the inner working of UNMAP and UNMAPS below.  It takes
a part number, closes the file, and marks the part as available.
If the part is already unmapped, it does nothing.

UNMAP does a FLUSH before UNMAP to be sure file is written before
closing it.

UNMAPS removes a range of parts from the map.

------------------------------------------------------------------------ }

PUBLIC

: UNMAPPED ( -- p )
   'PART @ 0  BEGIN
      DUP >PART  ?MAPPED WHILE
         1+
   REPEAT  SWAP 'PART ! ;

: (UNMAP) ( p -- )
   DISK GRAB  >PART ?MAPPED IF
      -1 #BLOCK !  FILE-HANDLE @
      CLOSE-FILE THROW
   THEN  DISK RELEASE ;

: UNMAP ( n -- )   FLUSH  (UNMAP) ;
: UNMAPS ( f l -- )
   FLUSH  1+ SWAP DO
      I (UNMAP)
   LOOP ;

{ ------------------------------------------------------------------------
File Name List

>PATH takes an ASCII string address and count and converts it to
full path name at HERE.

=FILE converts a 'FILENAMES entry at a to a fully qualified file
name and returns true if the string at HERE matches.

+FILENAME takes address and count of file name and searches
through all strings pointed to in 'FILENAMES .  Returns the index
pointer into the table where it found or placed the new filename.

------------------------------------------------------------------------ }

PRIVATE

: >PATH ( addr n -- )
   +ROOT HERE C! HERE COUNT CMOVE ;

: =FILE ( a -- t )
   HERE >R  HERE C@ 1+ ALLOT  COUNT >PATH
   HERE COUNT R@ COUNT COMPARE 0=  R> H ! ;

: +FILENAME ( a n -- n )
   >PATH  #PARTS 0 DO
      I >FILENAME @  ?DUP IF
         +ORIGIN =FILE IF
            I UNLOOP EXIT
   THEN  THEN  LOOP
   $100 0 DO
      I >FILENAME DUP @ 0= IF
         HERE -ORIGIN SWAP !
         HERE COUNT + H !
         I UNLOOP EXIT
   THEN  DROP  LOOP
   1 ABORT" File list full" ;

: /FILENAMES
   'PART @ >R  #PARTS 0 DO
      I >PART  ?MAPPED IF
         'FILENAME HERE >= IF
            #FILENAME @ >FILENAME OFF
            I UNMAP
         THEN
      THEN
   LOOP
   R> 'PART ! ;

:PRUNE /FILENAMES ;

{ ------------------------------------------------------------------------
Map Files

BUSY? aborts if the selected part is already mapped.

MAP is passed a part number p and a filename string a n .  If the
part is free, the string is added to the global filename list.

MAPS is used interpretively to map a filename.

MAPS" maps quote delimited filenames inside definitions.

(OPEN) takes a relative block number and access mode, opens the
file indicated by the current part, and sets the remaining fields
in the part descriptor.

MODIFY and READONLY finish the mapping process begun by one of
the MAP words in the previous block.  Each takes a relative block
number and opens the file with the appropriate access method.

NEWBLOCKS takes a relative block number b and number of blocks n
and creates the file mapped in with read/write access.

RESIZE-PART sets part p to u bytes.

------------------------------------------------------------------------ }

PRIVATE

: BUSY?   ?MAPPED ABORT" Part in use" ;

PUBLIC

: MAP ( p a n -- )
   +FILENAME  #PARTS 0 DO
      I >PART ?MAPPED IF
         DUP #FILENAME @ =
         ABORT" Already mapped"
   THEN  LOOP  SWAP >PART BUSY?  #FILENAME ! ;

: MAPS ( p -- ) \ Usage: MAPS <name>
   BL WORD COUNT MAP ;

: MAPS" ( p -- ) \ Usage: MAPS" name"
   POSTPONE S"  POSTPONE MAP ;  IMMEDIATE

PRIVATE

: (OPEN) ( n m -- )
   BUSY?  DUP FILE-MODE !  'FILENAME COUNT
   ROT OPEN-FILE THROW  ( fileid ) DUP
   FILE-HANDLE !  FILE-UPDATED OFF
   FILE-SIZE THROW  1023 M+ 1024 M/
   SWAP ABSOLUTE DUP #BLOCK !  + #LIMIT ! ;

PUBLIC

: MODIFY ( n -- )   R/W (OPEN) ;
: READONLY ( n -- )   R/O (OPEN) ;

: NEWBLOCKS ( b n -- )
   BUSY?  'FILENAME COUNT R/W CREATE-FILE THROW
   FILE-HANDLE !  0 FILE-UPDATED !
   R/W FILE-MODE !  SWAP ABSOLUTE DUP #LIMIT !
   #BLOCK !  DUP 1024 UM*  FILE-HANDLE @
   RESIZE-FILE THROW  #LIMIT +! ;

: RESIZE-PART ( u p -- )
   >PART  DUP 0 FILE-HANDLE @ RESIZE-FILE THROW
   1 1024 U*/  #BLOCK @ +  #LIMIT ! ;

{ ------------------------------------------------------------------------
Parts Map Display

.PARTS displays the parts table.

.MAP resets the scroll region to the top of the display window before
the .PARTS display.

?MAP displays the file map if input is not from a block.
------------------------------------------------------------------------ }

PRIVATE

: .PARTS ( -- )
   CR ." PART   BLOCK  MODE  SIZE  FILE"
   'PART @ >R  DECIMAL  #PARTS 0 DO
      I >PART  ?MAPPED IF
         CR  I 4 U.R
         #BLOCK @ 8 U.R  2 SPACES
         FILE-MODE @  CASE
            R/W OF  ." R/W"  ENDOF
            R/O OF  ." R/O"  ENDOF
            W/O OF  ." W/O"  ENDOF
            ." ???"
         ENDCASE  FILE-UPDATED @ IF
            ." U"  ELSE  SPACE
         THEN  #BLOCKS 6 U.R  2 SPACES
         'FILENAME COUNT TYPE
   THEN  LOOP  SPACE  R> 'PART ! ;

PUBLIC

: .MAP ( -- )   .PARTS ;
: ?MAP ( -- )   SOURCE-ID ?EXIT .PARTS ;

{ ------------------------------------------------------------------------
Part Management

".src" is the default block file extension.

"." is used to determine if a full canonical filename has an
extension.

?EXT returns true if the counted string at a is found at the end
of the filename at HERE .

+HERE adds a string to the one at HERE .

+EXT appends the counted string at a to the counted string being
built at HERE .

AFTER returns the next available relative block number.

REMAP maps a file into the next available part and then passes
the next block number to the function vectored through 'REMAP .

------------------------------------------------------------------------ }

PRIVATE

CREATE ".SRC"   BL STRING .src
CREATE "."      BL STRING .

: ?EXT ( a -- t )
   HERE COUNT -PATH  ROT COUNT -MATCH NOT NIP ;

: +HERE ( a n -- )
   >R  HERE COUNT + R@ CMOVE  R> HERE C+! ;

: +EXT ( a -- )   COUNT +HERE ;

VARIABLE 'REMAP

PUBLIC

: AFTER ( -- n )
   'PART @  0  #PARTS 0 DO
      I >PART  ?MAPPED IF
         #LIMIT @ MAX
   THEN  LOOP  RELATIVE  SWAP 'PART ! ;

PRIVATE

: REMAP ( -- )
   UNMAPPED HERE COUNT MAP  AFTER
   'REMAP @EXECUTE ;

{ ------------------------------------------------------------------------
Chart Files

CHARTS maps files into highest available block.  Appends the
".SRC" extension to name with no extension.

(CHART) maps a file using READONLY .  The file mode will only be
changed while the buffered data are being written to the file.

CHART maps files using the (CHART) behavior.

+U compiles an absolute block number that will return a run-time
relative block number for utilities.

+B returns a block number relative to the currently LOADing block
or if used from the keyboard, the last block LISTed.

+PART given the block and part, returns the block# relative to
the current value of OFFSET .  It will abort if the given part is
not currently mapped in.

?PART returns the number of the part mapping a block.

+P returns a block number residing in the same PART as the
currently loading block.

------------------------------------------------------------------------ }

PRIVATE

: CHARTS ( -- )         \ Usage: CHARTS <name>
   BL WORD COUNT >PATH
   "." ?EXT NOT IF  ".SRC" +EXT  THEN
   REMAP  ?MAP ;

: (CHART) ( -- )
   'REMAP ASSIGN ( b -- )   READONLY ;

PUBLIC

: CHART   (CHART) CHARTS ;

: +U ( n -- n )
   ABSOLUTE  POSTPONE LITERAL
   POSTPONE RELATIVE ;  IMMEDIATE

: +B ( n -- n )
   BLK @  ?DUP 0= IF
      SCR @
   THEN  RELATIVE + ;

: +PART ( n p -- n' )
   >PART MAPPED?  #BLOCK @ RELATIVE + ;

: ?PART ( n -- p )   MAPPED NIP NIP ;

: +P ( n -- n )
   BLK @  ?DUP 0= IF
      SCR @
   THEN  ?PART +PART ;

{ ------------------------------------------------------------------------
Source File Mapping

(NEWFILE) creates the file with the appropriate number of blocks,
maps it into the next avaiable part and writes blanks in every
block of the file.

NEWFILE maps new files using the (NEWFILE) behavior.

-MAPPED takes file name string address and count, returns true if
file is not in parts map.  Otherwise, returns part# and false.
Always leaves counted string with full pathname at HERE for
subsequent use or display by ABORT" .

@PART returns the currently selected part number.

USES is primarily for referencing source block files.  It takes
the address and count of a filename string and returns the part
number in which the file is mapped. Uses default file extension
of .SRC if not found on first attempt and there was no extension
in the original string.

(USING) searches the part map for the given counted string.  If the
file is not found in the parts map, it is charted into the next
available part and block#.

USING returns the part number of the file that follows in the
input stream.  Charts the file if it is not currently mapped. If
this is used inside a definition, the part check is defered until
run time.

IN is a short-cut for USING filename +PART.

>LIMITS returns the relative starting and ending block numbers
for the given part suitable for use with THRU.
------------------------------------------------------------------------ }

PRIVATE

: (NEWFILE) ( -- )
   'REMAP ASSIGN ( n b -- n )
      OVER 2DUP NEWBLOCKS  0 DO
         DUP BUFFER 1024 BLANK  UPDATE  1+
      LOOP  DROP  FLUSH ;

PUBLIC

: NEWFILE ( n -- )
   (NEWFILE) CHARTS DROP ;

PRIVATE

: -MAPPED ( a n -- t | p f )
   >PATH  -1  #PARTS 0 DO
      I >PART  ?MAPPED IF
         'FILENAME =FILE IF
            DROP I 0 LEAVE
   THEN  THEN  LOOP ;

: @PART ( -- p )
   'PART @ PARTS - CELL /  ;

: USES ( a n -- p )
   -MAPPED IF
      "." ?EXT IF
         REMAP @PART
      ELSE  ".SRC" +EXT  HERE COUNT -MAPPED IF
         REMAP @PART
   THEN  THEN  THEN ;

PUBLIC

: (USING) ( a n -- p )   (CHART)  USES ;

-? : USING ( -- p ) \ Usage: USING <name>
   STATE @ IF
      POSTPONE S"  POSTPONE (USING)
   ELSE  BL WORD COUNT (USING)
   THEN ;  IMMEDIATE

: IN ( n -- n' ) \ Usage: IN <name>
   STATE @ IF
      POSTPONE S"  POSTPONE (USING)
      POSTPONE +PART
   ELSE  BL WORD COUNT (USING)  +PART
   THEN ;  IMMEDIATE

: >LIMITS ( p -- l h )
   0 SWAP +PART  #LIMIT @ RELATIVE 1- ;

{ ------------------------------------------------------------------------
Panic editor

This block defines minimal words to edit source blocks.

(LIST) displays a block in its simplist form.

TP copies the text following, to the given line number of the
last block listed.

------------------------------------------------------------------------ }

: (LIST) ( n -- )
   ABSOLUTE  16 0 DO
      CR  I 2 U.R  SPACE  DUP ABLOCK
      I 64 * +  64 TYPE
   LOOP  SPACE  SCR ! ;

PUBLIC

' (LIST) IS LIST

: TP ( n -- ) \ Usage: TP <text>
   64 *  SCR @ ABLOCK +  HERE 65 BLANK
   94 WORD 1+  SWAP 64 CMOVE  UPDATE ;

{ ------------------------------------------------------------------------
Block Loading

(LOAD) and LOAD save the current position in the input stream and
call INTERPRET then restore the input stream pointer.

THRU loads a range of block numbers, inclusive.  It compacts load
blocks and encourages sequential arrangement of code.

LOADUSING loads the given block from the file whose name follows
in the input stream.

-LOAD loads the given block then unmaps the file it is in.

------------------------------------------------------------------------ }

PRIVATE

: (LOAD) ( ofs blk -- )   DUP 0= -250 ?THROW
   SAVE-INPUT N>R  BLK 2!  'SOURCE-ID OFF
   ['] INTERPRET CATCH ( ior ) ?DUP IF
      BLK @ SCR !  >IN @ CHR !
   POSTPONE [  THROW  THEN
   NR> RESTORE-INPUT DROP  DECIMAL ;

: (LOADS) ( n -- )   0 SWAP ABSOLUTE (LOAD) ;

' (LOADS) IS LOAD

PUBLIC

: THRU ( f l -- )
   1+ SWAP DO  I LOAD  LOOP ;

: LOADUSING ( n -- ) \ Usage: LOADUSING <name>
   POSTPONE IN LOAD ;

: -LOAD ( n -- )
   DUP >R  LOAD  R> ABSOLUTE ?PART
   ?DUP IF  UNMAP  THEN ;

{ ------------------------------------------------------------------------
Index Display

>SCR saves the values of SCR and CHR at (SCR) if SCR differs from
n, returns n and SCR .  n is absolute.

.PART displays the part, absolute and relative block numbers of
the given absolute block number.

(FILENAME) returns the address and count of the filename string.

.FILENAME displays the filename of the given absolute block
number.

@IX returns the high and low limits for the index page containing
absolute block number u.

>IX positions the cursor on the line that will display the index
entry for absolute block number u.  Also displays the relative
block number, a star (*) if u is the same as (SCR) and returns
the address and length of the string to display from a block
buffer.

LX displays the index page containing the block in SCR .

QX displays the index page containing the given block.

NX and BX display the next and previous index pages.

------------------------------------------------------------------------ }

PUBLIC

: >SCR ( n -- n a )
   SCR  2DUP @ <> IF DUP 2@ (SCR) 2!  THEN ;

PRIVATE

: (FILENAME) ( -- a n )   'FILENAME COUNT ;

: .FILENAME ( n -- )
   ?PART >PART  (FILENAME) TYPE ;

: .PART ( n -- )
   DUP ?PART DUP >PART  SWAP  OFFSET @ IF
      ."  Abs "  DUP U.
   THEN  ."  Part "  SWAP .
   ."  Rel "  #BLOCK @ - 0 U.R ;

: @IX ( n -- l h )
   MAPPED >PART DROP  #BLOCK @ -  60 / 60 *
   #BLOCK @ +  DUP 60 #BLOCKS MIN + ;

: >IX ( n -- a n )
   DUP DUP @IX DROP - 21 /MOD 26 * 1 M+ SWAP AT-XY
   DUP RELATIVE (.)  5 OVER - SPACES TYPE
   DUP (SCR) @ = IF
      ." *"  ELSE  SPACE
   THEN  ABLOCK 20 ;

: .IX ( -- )
   0. AT-XY  SCR @ DUP .FILENAME SPACE  DUP .PART
   #BLOCK @ #LIMIT @ + 2/ < NOT IF
      ."   SHADOW"
   THEN ;

PUBLIC

: LX ( -- )
   FORTH  PAGE .IX  SCR @ @IX SWAP 2DUP DO
      I >IX  SCR @ I = IF
         MARK  ELSE  TYPE
   THEN  LOOP  - 1+ 22 MIN
   0 SWAP AT-XY ;

: QX ( n -- )
   ABSOLUTE 0 MAX >SCR !  LX ;

: NX ( -- )
   SCR @ DUP @IX @IX   1- 2SWAP - ROT + MIN
   SCR ! LX ;

: BX ( -- )
   SCR @ DUP @IX DROP DUP 1- @IX
   1- 2SWAP - ROT + MIN SCR ! LX ;

{ ------------------------------------------------------------------------
Load-time initializations

/PARTS sets all parts to available.  Leaves enough information for
REOPEN-FILES to recover the map, if desired by the user.
------------------------------------------------------------------------ }

: /PARTS ( -- )
   #PARTS 0 DO
      I >PART  -1 #BLOCK !
   LOOP  0 >PART ;

: /BLOCKS ( -- )
   0 0 NB 2!  0 0 PREV 2!  FLUSHING OFF  DISK OFF
   /PARTS  8 MAXBUFFERS ;

:ONLOAD   /BLOCKS ( REOPEN-FILES) ;

/BLOCKS

' (LIST) IS LIST
' (BLK-SOURCE) IS SOURCE

END-PACKAGE

{ ------------------------------------------------------------------------
ANS environment queries

BLOCK and BLOCK-EXT are added to ENVIRONMENT-WORDLIST.  Each
returns true.
------------------------------------------------------------------------ }

ENVIRONMENT-WORDLIST +ORDER DEFINITIONS

   TRUE CONSTANT BLOCK
   TRUE CONSTANT BLOCK-EXT

PREVIOUS DEFINITIONS

GILD

BOLD .(

This file, if loaded as it was shipped, will obscure future use of the
Swoop operator USING.  If you need access to this feature of Swoop,
please rename the USING operation in this file.

Also note that the contents of this file, once loaded, cannot be
unloaded via EMPTY.  The dictionary space is protected with GILD.

) NORMAL
