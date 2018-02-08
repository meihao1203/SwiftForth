{ ====================================================================
Single-step debug

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

This file supplies a simple single-step debug tool.
==================================================================== }

OPTIONAL SINGLESTEP Simple single-step debugger

{ --------------------------------------------------------------------
Words to be debugged must be compiled between [DEBUG and DEBUG] and
the source must be compiled from a text file.

Usage:

   [DEBUG
   : 2X ( n -- n*2 )   DUP + ;
   : 3X ( n -- n*3 )   DUP 2X + ;
   : 4X ( n -- n*4 )   DUP 3X + ;
   : 5X ( n -- n*5 )   DUP 2X SWAP 3X + ;
   DEBUG]

The debugger is then run with the word DEBUG

   4 DEBUG 5X

While the debugger is active, it is controlled by keys in the debug
window:

Nest    executes the next token, nesting if it is a call.
Step    executes the next token, with no nesting.
Return  executes to the next return without stopping.
Finish  runs the word at (near) full speed until it returns out of DEBUG

The basic technique used for stepping is to compile a "breakpoint"
along with enough information to display the source code between each
xt that Forth would normally compile.  The source location information
is used to synchronize the text display of the code being stepped, and
to allow the system to advance the execution point one xt at a time.

CPU registers are not of interest here; only the Forth virtual machine
is guaranteed to be intact between execution tokens.

Limitations:
  1) May only be used in source files (not from the keyboard).
  2) Object code may not span more then 64k.
  3) Source code may not span files.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Debug information is compiled inline.

DEBUG, is the replacement for COMPILE, which compiles breakpoint code
between each xt compiled.  Each breakpoint is a call to BKPT followed
by a breakpoint record.  The comments next to DEBUG, enumerate the
fields in the breakpoint record.

BKPT is directed to either SKIP-BKPT or DEBUG-BKPT.

.BKPT is added to the decompiler to display the inlined breakpoint
info instead of just garbage.
-------------------------------------------------------------------- }

PACKAGE SINGLE-STEPPER

CODE SKIP-BKPT ( -- )   8 # 0 [ESP] ADD   RET   END-CODE

DEFER BKPT   ' SKIP-BKPT IS BKPT

: DEBUG, ( xt -- )
   LAST @ N>VIEW 2+ W@ F# @ <>          \ Make sure we're still in the same source file
   ABORT" Definition spans source files"
   ['] BKPT (COMPILE,)                  \ Call to BKPT
   HERE LAST @ - H,                     \ Offset back to this word's name field
   LINE @ LAST @ N>VIEW W@ - H,         \ Offset from word's starting line# to this line
   IN> 2@ H, H,                         \ Position and length of this word in source line
   (COMPILE,) ;                         \ Compile the actual xt

DECOMPILER +ORDER

: .BKPT ( -- )   ?WHERE  ." -N=" IW@ 4 H.0  ."  +L=" IW@ 4 H.0
   ."  In " IW@ 4 H.0  ."  Len " IW@ 4 H.0 ;

DECODE: BKPT .BKPT

DECOMPILER -ORDER

{ --------------------------------------------------------------------
[DEBUG begins a source debug layer and DEBUG] ends it. These words are
valid only during a file include, because they must be able to make
source references in order to display the single step tracing.
-------------------------------------------------------------------- }

THROW#
   S" Single-step debug only from source file" >THROW  ENUM IOR_DEBUG
TO THROW#

: ?INCLUDING ( -- )
   SOURCE=FILE NOT IOR_DEBUG ?THROW ;

PUBLIC

-? : [DEBUG ( -- )   ?INCLUDING   ['] DEBUG, IS COMPILE, ;
-? : DEBUG] ( -- )   ?INCLUDING   [ ' COMPILE, >BODY @ ] LITERAL IS COMPILE, ;

PRIVATE

{ --------------------------------------------------------------------
Breakpoint nesting and display

[BKPT] defines the 16-bit fields in the record pointed to by 'BKPT.

WVIEW uses the offset in WNAME to go back to the View field of the
word being single-stepped.

PLINE reads a line into PAD.  Lines longer than 1024 will be a problem.
NESTED and LEVEL keep track of current and target return stack depths.

.BREAK displays the breakpoint and prompts for next action.  Sets
LEVEL according to user input.

DEBUG-BKPT does the .BREAK display if the current return stack nesting
level is less than the value in LEVEL.  Otherwise, it just returns.
-------------------------------------------------------------------- }

2VARIABLE 'BKPT         \ Pointers to breakpoint records (current and prev)
   HERE DUP 'BKPT 2!    \ Point to safe place

: [BKPT] ( n1 -- n2 )   CREATE DUP , 2+
   DOES> ( -- addr )   @ 'BKPT @ + ;

0  [BKPT] WNAME         \ Offset to this word's name field
   [BKPT] WLINE         \ Relative line# for this breakpoint record
   [BKPT] WOFFS         \ Offset into line at which word was parsed
   [BKPT] WLEN          \ Length of the word
DROP

: WVIEW ( -- addr )   WNAME DUP W@ - N>VIEW ;

: PLINE ( fid -- n )   PAD 1024 ROT READ-LINE DROP
   0= ABORT" Unexpected end of file" ;

VARIABLE NESTED   VARIABLE LEVEL

: .BREAK ( -- )
   BRIGHT  .S  NORMAL  32 GET-XY DROP - 1 MAX SPACES
   ." [ Nest | Step | Return | Finish ] "
   BEGIN  0  KEY $20 OR  CASE
      [CHAR] n OF  0 LEVEL !  1-  ENDOF
      [CHAR] s OF  NESTED @  LEVEL !  1-  ENDOF
      [CHAR] r OF  NESTED @ CELL+  LEVEL !  1-  ENDOF
      [CHAR] f OF  -1 LEVEL !  1-  ENDOF
   ENDCASE UNTIL ;

FILE-VIEWER +ORDER

: DEBUG-BKPT ( -- )
   R> 'BKPT @ OVER 'BKPT 2!  8 + >R             \ Set 'BKPT to 8-byte debug record, saving last 'BKPT
   RP@ DUP NESTED !  LEVEL @ U< ?EXIT           \ Check nest level, bail if not showing nesting
   'BKPT 2@ 2+ 6 ROT 2+ OVER COMPARE -EXIT      \ Suppress same output as last time
   WVIEW 2+ W@ FILE#> +ROOT                     \ Full filname from word's view field
   CR CR  BOLD  2DUP TYPE  NORMAL SPACE
   R/O OPEN-FILE THROW                          \ fid
   WVIEW W@ 1 ?DO  DUP PLINE DROP  LOOP         \ skip to 1st line of word
   WVIEW W@ WLINE W@ 1+ OVER + SWAP DO          \ show lines in word up to debug line
      CR  I 5 U.R ." : "  PAD OVER PLINE
      WVIEW W@ WLINE W@ + I = IF
         OVER WOFFS W@ TYPE  WOFFS W@ /STRING
         INVERSE  OVER WLEN W@ TYPE  NORMAL
         WLEN W@ /STRING  TYPE  ELSE  TYPE
   THEN LOOP  CLOSE-FILE DROP  .BREAK ;

FILE-VIEWER -ORDER

{ --------------------------------------------------------------------
User interface

DEBUG sets the vectored BKPT behavior to DEBUG-BKPT and then executes
the word that follows.  Restores BKPT back to SKIP-BKPT when done.
-------------------------------------------------------------------- }

PUBLIC

: DEBUG ( -- )   ['] DEBUG-BKPT IS BKPT  0 LEVEL !
   ' CATCH ( *)  ['] SKIP-BKPT IS BKPT  ( *) THROW ;

END-PACKAGE
