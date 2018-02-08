{ ====================================================================
Generate portable executable turnkey program

Copyright 2001  FORTH, Inc.

Major update: July 2011

PROGRAM <objfile> <icon>

  1) icon file name ends in .ico
  2) icon format must be 32x32, 4-bit color, one icon

PE header fields modified here (offsets into image):
+0A0  SizeOfInitializedData
+0D0  SizeOfImage
+0D8  CheckSum
+0DC  Subsystem (2=GUI; 3=Console)
+1F8  VirtualSize for ".data" section
+200  SizeOfRawData for ".data" section
+214  Characteristics for ".data" section

These PE header fields are only modified for DLLs:
+096  File characteristics
+0B4  ImageBase
+0DE  DLL characteristics
+0F8  Export table address
+0FC  Export table size

======================================================================== }

?( Turnkey program generator)

PACKAGE TURNKEY-TOOLS

{ ------------------------------------------------------------------------
Buffers

CHUNK rounds u1 up to u2 chunk size.

ALLOCATE-IMAGE allocates memory for the object file image, leaves its
address in >FILEIMAGE and the calculated size in #FILEIMAGE.
------------------------------------------------------------------------ }

MAX_PATH BUFFER: NAME_OBJ       \ Object filename
MAX_PATH BUFFER: NAME_ICO       \ Icon filename

VARIABLE >FILEIMAGE             \ Pointer to memory image of object file
VARIABLE #FILEIMAGE             \ Size of image

: CHUNK ( u1 u2 -- u3 )   SWAP OVER /MOD SWAP 0<> - * ;

: ALLOCATE-IMAGE ( u -- )
   HERE -ORIGIN  #XREF +  512 CHUNK +                   \ Total turnkey file image size
   DUP ALLOCATE THROW  >FILEIMAGE !  #FILEIMAGE ! ;     \ Allocate memory to build file

{ ------------------------------------------------------------------------
PE header

READ-HEADER opens the PE header image file, determines its size
(saving it in #PHEAD), allocates exteneded memory for the header plus
program image, and reads the header into the start of the image.

CheckSumMappedFile in Imagehlp.dll is used to calculate the PE header
checksum.

>PE returns an address in the PE header in the object file memory image.
------------------------------------------------------------------------ }

VARIABLE #LOADER        \ Size of the loader image file

: READ-HEADER ( -- )
   S" %SwiftForth\bin\sf-loader.img"            \ Open PE header binary image
   +ROOT R/O OPEN-FILE IF DROP                  \ default image not found
      R-BUF                                     \
      THIS-EXE-NAME -NAME R@ PLACE              \ check in exe directory
      S" \sf-loader.img" R@ APPEND              \ create name
      R> COUNT R/O OPEN-FILE THROW              \ and throw now
   THEN >R                                      \ save handle
   R@ FILE-SIZE THROW  DROP  DUP #LOADER !      \ Loader file size
   ALLOCATE-IMAGE                               \ Allocate buffer for object file image
   >FILEIMAGE @ #LOADER @ R@ READ-FILE
   R> CLOSE-FILE DROP  THROW DROP ;

LIBRARY Imagehlp.dll
FUNCTION: CheckSumMappedFile ( addr1 len addr2 addr3 -- x )

VARIABLE SUM0   \ Original checksum from CheckSumMappedFile
VARIABLE SUM1   \ Calculated checksum

: >PE ( n -- addr)   >FILEIMAGE @ + ;

{ --------------------------------------------------------------------
Icon in PE header

If the next string in the input stream ends in ".ico" we open it and
use it as the turnkey image's icon.

The icon file must be conform to the 22-byte header in ICON-FMT.
-------------------------------------------------------------------- }

HEX

CREATE ICON-FMT
   0 H,  1 H,  1 H,     \ type=icon; exactly 1 image in file
   20 C, 20 C,  10 H,   \ format is 32x32, palette 16
   1 H,  4 H,           \ one plane, 4-bit pixels
   2E8 ,  16 ,          \ size and offset

: READ-ICON ( -- )
   NAME_ICO C@ IF
      NAME_ICO COUNT R/O OPEN-FILE THROW >R
      PAD 16 R@ READ-FILE THROW DROP
      PAD 16 ICON-FMT OVER COMPARE
      ABORT" Unsupported icon format"
      890 >PE 2E8 R@ READ-FILE
      R> CLOSE-FILE DROP  THROW DROP
   THEN ;

{ --------------------------------------------------------------------
Build file image

VALIDATE-HEADER does a quick sanity check to make sure fields are
where we expect them in the header.

BUILD-IMAGE reads in the PE header from sf-loader.img, makes sure it's
in the expected format, updates the header size fields, appends the
code image, and updates the PE header checksum.
-------------------------------------------------------------------- }

: VALIDATE-HEADER ( -- )
   80 >PE @ 4550 <> ABORT" PE signature misplaced"
   1F0 >PE @ 7461642E <> ABORT" Can't find .data section"
   200 >PE @ ABORT" Bad .data section size" ;

[UNDEFINED] EXPORT: [IF]

0 CONSTANT #EXPORTS
: ,XDIR 2DROP ;
: DLL-HEADER ;

[ELSE]

: DLL-HEADER ( -- )
   DLL-ENTRY -ORIGIN #LOADER @ >PE !    \ Set entry point offset at ORIGIN
   >XDIR 2@  0FC >PE !  0F8 >PE !       \ Set PE header export table RVA and length
   10000000 0B4 >PE !                   \ Default ImageBase for DLLs
   230E 96 >PE W!  0 0DE >PE W! ;       \ File and DLL characteristics

[THEN]

VARIABLE ?SEALED        \ True for "sealed" turnkey

: BUILD-IMAGE ( -- )
   NAME_OBJ COUNT -PATH ,XDIR           \ Build export table
   READ-HEADER                          \ Read the PE header into memory
   VALIDATE-HEADER                      \ Sanity check
   HERE -ORIGIN #XREF + 200 CHUNK       \ Size of turnkey program including xref table in file
   DUP A0 >PE +!  200 >PE !             \ Add kernel size to SizeOfInitializedData, set SizeOfRawData in .data section
   2 IS-CONSOLE? -  0DC >PE W!          \ Set program type (2=GUI, 3=console)
   READ-ICON                            \ Overlay icon if .ico specified
   HERE DP0 !REL  HERE SAVE-XREF        \ Set DP0 for turnkey, set xref restore addr
   ?SEALED @ IF  0 ?SEALED !            \ If ?SEALED set, this is a "sealed" turnkey
      200 >PE @  1F8 >PE  2DUP @ -      \ SizeOfRawData minus original VirtualSize
      0D0 >PE +!  !                     \ Adjust SizeOfImage down; set new VirtualSize
   E0000040 214 >PE !  THEN             \ Mark section as having no uninitialized data
   ORIGIN  >FILEIMAGE @ #LOADER @ +     \ Source from origin, dest after PE header in object file image
   HERE -ORIGIN 2DUP 2>R CMOVE          \ Copy SwiftForth into file image
   2R> + SWAP CMOVE                     \ Copy xref table to image
   #EXPORTS IF  DLL-HEADER  THEN        \ Set DLL header fields if there are exports
   >FILEIMAGE @  #FILEIMAGE @           \ addr len for call to CheckSumMappedFile
   SUM0 SUM1 CheckSumMappedFile         \ Calculate the checksum
   0= ABORT" Can't checksum image"      \ Complain if checksum fails
   SUM1 @ D8 >PE ! ;                    \ Set the new checksum in the header

DECIMAL

{ --------------------------------------------------------------------
Files
-------------------------------------------------------------------- }

: (PARSE-OBJ) ( -- )
   BL WORD COUNT +ROOT NAME_OBJ PLACE
   NAME_OBJ COUNT -PATH  [CHAR] . SCAN
   0= IF  #EXPORTS IF  S" .dll"  ELSE  S" .exe" THEN
   NAME_OBJ APPEND  THEN DROP ;

: (PARSE-ICO) ( -- )   >IN @
   BL WORD COUNT  2DUP 4 STRING/ S" .ico"
   COMPARE(NC) IF  2DROP >IN !  0 NAME_ICO C!
   ELSE  +ROOT NAME_ICO PLACE  DROP  THEN ;

{ --------------------------------------------------------------------
Program turnkey

PROGRAM is followed by the object file name and an option icon name.
It sets up the object and icon file names, builds the object file
image in extended memory, and writes it to the file.
-------------------------------------------------------------------- }

PUBLIC

: PROGRAM ( -- )
   (PARSE-OBJ)  (PARSE-ICO)  BUILD-IMAGE        \ Build the turnkey file memory image
   NAME_OBJ COUNT R/W CREATE-FILE THROW >R      \ Create object file, save name for xref
   >FILEIMAGE @ #FILEIMAGE @ R@ WRITE-FILE      \ Write file image to object file
   >FILEIMAGE @ FREE  R> CLOSE-FILE             \ Release buffer memory, close file, throw if write error
   2DROP THROW ;

: PROGRAM-SEALED ( -- )   -1 ?SEALED !  PROGRAM ;

END-PACKAGE
