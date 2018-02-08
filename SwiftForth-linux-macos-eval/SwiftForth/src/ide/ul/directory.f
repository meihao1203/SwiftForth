{ ====================================================================
Directory management

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

This file supplies PWD, CD, and the ability to save and restore the
working directory on a path stack.
==================================================================== }

?( ... Directory management)

{ --------------------------------------------------------------------
System calls
-------------------------------------------------------------------- }

FUNCTION: chdir ( addr -- ior )

{ --------------------------------------------------------------------
Working directory

PWD prints the working directory.

OLDPWD holds the previous working directory.

$HOME returns the HOME path.

>OLDPWD returns the previous working directory string.  We copy it to
POCKET because OLDPWD will be overwritten before the chdir call.

CD followed by a directory path will set the current directory to that
path.  If followed by nothing, does a chdir to the home directory.
Use quotes (") if there are spaces in your directory path.
CD - switches to the previous working directory.
-------------------------------------------------------------------- }

: PWD ( -- )
   PAD 256 getcwd ZCOUNT TYPE ;

256 BUFFER: OLDPWD   OLDPWD 256 ERASE

: !OLDPWD ( -- )   OLDPWD 256 getcwd DROP ;

: $HOME ( -- z-addr )
   S" HOME" FIND-ENV NOT ABORT" HOME not in environment" DROP ;

: (CD) ( addr u -- z-addr )
   OVER C@ [CHAR] " = IF
      NEGATE >IN +! DROP  [CHAR] " WORD COUNT
   THEN  +ROOT  OVER + 0 SWAP C! ;

: >OLDPWD ( -- z-addr )
   OLDPWD C@ 0= ABORT" No previous directory"
   OLDPWD ZCOUNT 2DUP TYPE  POCKET ZPLACE  POCKET ;

: CD ( -- )
   BL WORD COUNT DUP IF
      2DUP S" -" COMPARE IF  (CD)  ELSE  2DROP  >OLDPWD  THEN
   ELSE  2DROP  $HOME  THEN
   !OLDPWD  chdir ABORT" Invalid Directory" ;

{ --------------------------------------------------------------------
Directory display

The former command LS is now supplanted by the ability to pass
commands out to a Linux shell.  Its replacement reminds you to use $
to send ls to the shell instead.
-------------------------------------------------------------------- }

?( ... Directory display)

: LS ( -- )   1 ABORT" Use '$ ls' to send command to shell" ;

{ --------------------------------------------------------------------
Directory tools

DIRSTACK implements an eight-level deep stack of directory paths.
PUSHPATH pushes the current path onto DIRSTACK.
POPPATH pops the top path from DIRSTACK, making it current.
DROPPATH discard the top path from DIRSTACK.

IS-DIR makes a stat call on the filename at z-addr and returns
true if the st_mode field's file type is directory.

IS-FILE makes a stat call on the filename at z-addr and returns
true if the st_mode field's file type is a normal file.

+/ appends a '/' to the end of the path at z-addr if there isn't one
already.
-------------------------------------------------------------------- }

?( ... Directory stack)

PACKAGE SHELL-TOOLS

2048 BUFFER: DIRSTACK

PUBLIC

: PUSHPATH ( -- )
   DIRSTACK DIRSTACK 256 + 1792 CMOVE>
   DIRSTACK 256 ERASE
   DIRSTACK 256 getcwd DROP ;

: POPPATH ( -- )
   DIRSTACK C@ -EXIT
   DIRSTACK chdir DROP
   DIRSTACK 256 + DIRSTACK 1792 CMOVE
   DIRSTACK 1792 + 256 ERASE ;

: DROPPATH ( -- )
   DIRSTACK C@ -EXIT
   DIRSTACK 256 + DIRSTACK 1792 CMOVE
   DIRSTACK 1792 + 256 ERASE ;

PRIVATE  OCTAL

: (FILETYPE) ( z-addr n -- flag )
   R-BUF  SWAP R@  stat 0=              \ stat() returns 0 if okay
   R> FILE_TYPE + @  0170000 AND        \ Mask off just the type bits
   ROT = AND ;                          \ Check for match and okay

PUBLIC

: IS-DIR ( z-addr -- flag )   0040000 (FILETYPE) ;
: IS-FILE ( z-addr -- flag )   0100000 (FILETYPE) ;

DECIMAL

: +/ ( zaddr -- )   DUP >R  ZCOUNT 1- 0 MAX + C@ [CHAR] / <> IF
   S" /" R@ ZAPPEND  THEN R> DROP ;

END-PACKAGE
