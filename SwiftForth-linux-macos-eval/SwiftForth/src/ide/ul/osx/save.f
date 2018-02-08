{ ====================================================================
Save executable turnkey image

Copyright 2011  FORTH, Inc.

This file supplies the utility for generating an executable turnkey
program image.  The SwiftForth program is written into a precompiled
loader image read in from the file %SwiftForth/bin/osx/sf-loader.img.

The following offsets are modified in sf-loader.img:

+1B8  vmsize of __DATA segment
+1C0  filesize of __DATA segment
+280  size of __data section (actual size in file)
+2B8  vmaddr of __LINKEDIT segment
+2C0  fileoff of  __LINKEDIT segment
+2E8  bind_off in LC_DYLD_INFO_ONLY
+2F8  lazy_bind_off in LC_DYLD_INFO_ONLY
+300  export_off in LC_DYLD_INFO_ONLY
+310  symoff in LC_SYMTAB
+318  stroff in LC_SYMTAB
+358  indirectsymoff in LC_DYSYMTAB
+428  dataoff in LC_FUNCTION_STARTS

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
Takes size of SwiftForth program image, rounded to page size.

>IMG returns an address in the object file memory image.
--------------------------------------------------------------------- }

VARIABLE #LOADER

: READ-IMAGE ( u -- )
   S" %SwiftForth/bin/osx/sf-loader.img"
   +ROOT R/O OPEN-FILE THROW >R                 \ Open loader binary image
   R@ FILE-SIZE THROW  DROP  DUP #LOADER !      \ Loader size
   + ALLOCATE-IMAGE                             \ Allocate buffer for object file image
   >FILEIMAGE @ #LOADER @ R@ READ-FILE
   R> CLOSE-FILE DROP  THROW DROP ;

: >IMG ( n -- addr)   >FILEIMAGE @ + ;

HEX

: ?BADIMG ( flag -- )   ABORT" Bad loader image" ;

: VALIDATE-HEADERS ( -- )
   0 >IMG @ 0FEEDFACE <> ?BADIMG
   S" FORTHIMG" 1020 >IMG OVER COMPARE ?BADIMG
   S" dyld_stub_binder" 2002 >IMG OVER COMPARE ?BADIMG ;

{ --------------------------------------------------------------------
Save program

PROGRAM saves the turnkey.
-------------------------------------------------------------------- }

PUBLIC

: PROGRAM ( -- )
   HERE -ORIGIN #XREF + FE0 - 0FFF + -1000 AND  \ Extra size to insert SwiftForth image
   DUP >R READ-IMAGE  VALIDATE-HEADERS          \ Read the binary loader program image into memory
   2000 >IMG  DUP R@ + #LOADER @ 2000 - CMOVE>  \ Relocate dyld tables
   HERE DP0 !REL  HERE SAVE-XREF                \ ( addr u) xref table
   1020 >IMG HERE -ORIGIN 2>R                   \ Dest addr in program image and size of SwiftForth
   ORIGIN 2R@ CMOVE  2R> + SWAP CMOVE           \ Copy SwiftForth and xrefs into file image
   $1000000 1B8 >IMG +!                         \ vmsize of __DATA segment (16MB)
   R@ 1C0 >IMG +!                               \ filesize of __DATA segment
   HERE -ORIGIN #XREF + 280 >IMG !              \ size of __data section (actual size in file)
   $1000000 2B8 >IMG +!                         \ vmaddr of __LINKEDIT segment
   R@ 2C0 >IMG +!                               \ fileoff of  __LINKEDIT segment
   R@ 2E8 >IMG +!                               \ bind_off in LC_DYLD_INFO_ONLY
   R@ 2F8 >IMG +!                               \ lazy_bind_off in LC_DYLD_INFO_ONLY
   R@ 300 >IMG +!                               \ export_off in LC_DYLD_INFO_ONLY
   R@ 310 >IMG +!                               \ symoff in LC_SYMTAB
   R@ 318 >IMG +!                               \ stroff in LC_SYMTAB
   R@ 358 >IMG +!                               \ indirectsymoff in LC_DYSYMTAB
   R> 428 >IMG +!                               \ dataoff in LC_FUNCTION_STARTS
   SAVE-IMAGE ;                                 \ Save binary image

DECIMAL

END-PACKAGE
