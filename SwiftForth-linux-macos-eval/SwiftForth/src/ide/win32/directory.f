{ ====================================================================
Directory management

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( ... Directory management)

: PWD ( -- )
   PAD 256 OVER GetCurrentDirectory TYPE ;

: CD ( -- )
   BL WORD COUNT DUP IF
      OVER C@ [CHAR] " = IF  NEGATE >IN +! DROP
      [CHAR] " WORD COUNT  THEN  +ROOT  OVER + 0 SWAP C!
      SetCurrentDirectory 0= ABORT" Invalid Directory"
   ELSE  2DROP PWD  THEN ;

{ --------------------------------------------------------------------
Simple directory listing
-------------------------------------------------------------------- }

?( ... Directory display)

PACKAGE SHELL-TOOLS

: FILESPEC ( -- zaddr )
   0 WORD DUP C@ IF ( file spec follows)
      0 OVER COUNT + C! 1+
   ELSE
      DROP Z" *.*"
   THEN ;

: ZFILENAME ( addr -- addr n )
   11 CELLS + ZCOUNT ;

: ZDIRNAME ( addr -- addr n )
   S" [" HERE PLACE
   ZFILENAME HERE APPEND
   S" ]" HERE APPEND
   HERE COUNT ;

: .FOUNDNAME ( addr -- )
   DUP @ FILE_ATTRIBUTE_DIRECTORY AND IF
      ZDIRNAME
   ELSE
      ZFILENAME
   THEN
   ?TYPE GET-XY DROP 16 + 16 / 16 * GET-XY DROP - SPACES ;

PUBLIC

: DIR ( -- )   CR
   FILESPEC PAD FindFirstFile >R
   R@ INVALID_HANDLE_VALUE <>
   BEGIN ( flag) WHILE
      PAD .FOUNDNAME
      R@ PAD FindNextFile ( flag)
   REPEAT R> FindClose DROP ;

END-PACKAGE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

?( ... Directory stack)

PACKAGE SHELL-TOOLS

0 VALUE DIRSTACK

PUBLIC

: DIRSTACK/ ( -- )   DIRSTACK IF
   DIRSTACK FREE DROP  THEN  0 TO DIRSTACK ;

: /DIRSTACK ( -- )
   DIRSTACK/
   2048 ALLOCATE THROW TO DIRSTACK  DIRSTACK 2048 ERASE ;

PRIVATE

:ONSYSLOAD   0 TO DIRSTACK  /DIRSTACK ;
:ONSYSEXIT   DIRSTACK/ ;

PUBLIC

{ --------------------------------------------------------------------
Directory tools

DIRSTACK implements an eight-level deep stack of directory paths.
PUSHPATH pushes the current path onto DIRSTACK.
POPPATH pops the top path from DIRSTACK, making it current.
DROPPATH discard the top path from DIRSTACK.
POPPATH-ALL pops from DIRSTACK until it can't pop anymore

IS-DIR makes a GetFileAttributes call on the filename at z-addr and
returns true if the file type is directory.

IS-FILE makes a GetFileAttributes call on the filename at z-addr and
returns true if the file type is a normal file.

+/ appends a '/' to the end of the path at z-addr if there isn't one
already.
-------------------------------------------------------------------- }

: PUSHPATH ( -- )
   DIRSTACK DIRSTACK 256 + 1792 CMOVE>
   DIRSTACK 256 ERASE
   255 DIRSTACK GetCurrentDirectory DROP ;

: POPPATH ( -- )
   DIRSTACK C@ -EXIT
   DIRSTACK SetCurrentDirectory DROP
   DIRSTACK 256 + DIRSTACK 1792 CMOVE
   DIRSTACK 1792 + 256 ERASE ;

: DROPPATH ( -- )
   DIRSTACK C@ -EXIT
   DIRSTACK 256 + DIRSTACK 1792 CMOVE
   DIRSTACK 1792 + 256 ERASE ;

: POPPATH-ALL ( -- )
   BEGIN
      DIRSTACK C@ WHILE
      POPPATH
   REPEAT ;

FUNCTION: CreateDirectory ( zname flags -- res )

: IS-DIR ( zstr -- flag )
   GetFileAttributes  DUP -1 <>  AND
   FILE_ATTRIBUTE_DIRECTORY AND 0<> ;

: IS-FILE ( zstr -- flag )
   GetFileAttributes  DUP -1 <> AND
   FILE_ATTRIBUTE_NORMAL FILE_ATTRIBUTE_ARCHIVE OR AND 0<> ;

: +\ ( zaddr -- )   DUP >R  ZCOUNT 1- 0 MAX + C@ [CHAR] \ <> IF
   S" \" R@ ZAPPEND  THEN R> DROP ;

{ --------------------------------------------------------------------
This class extends the WIN32_FIND_DATA structure and the windows
api directory access calls.

A flag of zero indicates an error for all operations.

One opens a directory operation with FIRST, giving it a file string
to match. Then, one calls NEXT to get the next file match. Finally,
one would call CLOSE to terminate the operation.  SPEC is provided
for the caller to keep track of the name in, but is not used by
any internal function.

IS-DIR returns true if the file found was any type of directory
specifier; IS-SUBDIR returns true only if the file found was a
directory, but not self "." or parent ".." .
-------------------------------------------------------------------- }

PUBLIC

WIN32_FIND_DATA SUBCLASS DIRTOOL

   VARIABLE HANDLE
   MAX_PATH BUFFER: SPEC

   : IS-DIR ( -- flag )
      FileAttributes @ FILE_ATTRIBUTE_DIRECTORY AND 0<> ;

   : IS-SUBDIR ( -- flag )   IS-DIR
      FileName ZCOUNT S" ."  COMPARE 0<> AND
      FileName ZCOUNT S" .." COMPARE 0<> AND ;

   : FIRST ( zstr -- flag )
      ADDR FindFirstFile DUP HANDLE !  INVALID_HANDLE_VALUE <> ;

   : NEXT ( -- flag )
      HANDLE @ ADDR FindNextFile ;

   : CLOSE ( -- )
      HANDLE @ FindClose DROP ;

END-CLASS

END-PACKAGE
