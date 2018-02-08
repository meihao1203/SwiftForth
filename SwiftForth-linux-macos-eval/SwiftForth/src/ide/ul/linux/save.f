{ ====================================================================
Save executable turnkey image

Copyright 2011  FORTH, Inc.

This file supplies the utility for generating an executable turnkey
program image.  The SwiftForth program is written into a precompiled
loader image read in from the file %SwiftForth/bin/linux/sf-loader.img.

The following offsets are modified in sf-loader.img:
  +0C4  size of SwiftForth segment in disk file
  +0C8  size SwiftForth in memory

==================================================================== }

?( Save turnkey)

PACKAGE TURNKEY-TOOLS

{ ------------------------------------------------------------------------
Buffers

ALLOCATE-IMAGE allocates memory for the object file whose size is u
and leaves its address in >FILEIMAGE and the size in #FILEIMAGE.
------------------------------------------------------------------------ }

VARIABLE >FILEIMAGE     \ Pointer to new file image
VARIABLE #FILEIMAGE     \ Size of image

: ALLOCATE-IMAGE ( u -- )
   DUP ALLOCATE THROW  >FILEIMAGE !  #FILEIMAGE ! ;

: SAVE-IMAGE ( -- )
   BL WORD COUNT +ROOT R/W EXE CREATE-FILE
   ABORT" Can't create object file" >R
   >FILEIMAGE @ #FILEIMAGE @ R@ WRITE-FILE
   R> CLOSE-FILE DROP  THROW  >FILEIMAGE @ FREE DROP ;

{ ---------------------------------------------------------------------
File image

READ-IMAGE opens the binary image file, determines its size, allocates
a buffer in extended memory, and reads the image into the buffer.
Takes total size of SwiftForth program image.

>IMG returns an address in the object file memory image.
--------------------------------------------------------------------- }

VARIABLE #LOADER

: READ-IMAGE ( u -- )
   S" %SwiftForth/bin/linux/sf-loader.img"
   +ROOT R/O OPEN-FILE THROW >R                 \ Open loader binary image
   R@ FILE-SIZE THROW  DROP  DUP #LOADER !      \ Loader size
   + ALLOCATE-IMAGE                             \ Allocate buffer for object file image
   >FILEIMAGE @ #LOADER @ R@ READ-FILE
   R> CLOSE-FILE DROP  THROW DROP ;

: >IMG ( n -- addr)   >FILEIMAGE @ + ;

HEX

: ?BADIMG ( flag -- )   ABORT" Bad loader image" ;

: VALIDATE-HEADERS ( -- )
   0 >IMG @ 464C457F <> ?BADIMG                 \ ELF magic number
   0C8 >IMG @ 4444 <> ?BADIMG                   \ Reserved size = 4444
   S" FORTHIMG" 230 >IMG OVER COMPARE ?BADIMG ;

{ --------------------------------------------------------------------
Save program

PROGRAM saves the turnkey.
-------------------------------------------------------------------- }

PUBLIC

: PROGRAM ( -- )
   HERE DP0 !REL  HERE SAVE-XREF                \ xref table
   HERE -ORIGIN OVER + READ-IMAGE               \ Read the binary loader program image into memory
   VALIDATE-HEADERS                             \ Validate loader headers
   ORIGIN 230 >IMG HERE -ORIGIN 2DUP 2>R CMOVE  \ Copy SwiftForth into file image
   HERE -ORIGIN 8 - OVER + 0C4 >IMG +!          \ File size of SwiftForth image (less 8 for "FORTHIMG")
   2R> + SWAP CMOVE                             \ Copy xref table to image
   $1000000 0C8 >IMG +!                         \ Memory size requested by SwiftForth segment (16 MB)
   SAVE-IMAGE ;                                 \ Save binary image

DECIMAL

END-PACKAGE
