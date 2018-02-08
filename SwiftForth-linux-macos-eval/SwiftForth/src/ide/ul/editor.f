{ ====================================================================
External editor interface

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

The external editor is invoked by running the file
%SwiftForth/bin/editor, which is a Bourne shell script as shipped.
It is invoked as
   %SwiftForth/bin/editor line# filename
So, the user may replace %SwiftForth/bin/editor with any executable
(including a shell script) that takes these arguments.

For a tty-based editor (vi, emacs, pico, etc.) "editor" should not
return until the editor has closed; otherwise, the editor and
SwiftForth will be simultaneously using the same tty, with
undesirable effects.

For an X-based editor (gvim, xemacs, etc.), or any editor which opens
in a different window or tty, "editor" may return immediately.
==================================================================== }

DECIMAL

PACKAGE FILE-EDITOR

{ --------------------------------------------------------------------
Invoking external editor

ARG0 is the full path to %SwiftForth/bin/editor.
ARG1 is the filename to edit.
ARG2 is the line number.  We pass the filename before the line
number, in case the editor is clueless about line numbers.

'ARG is the argv list passed to the OS to invoke the editor.  The
host's environment is passed unchanged to the editor.

EDIT-FILE edits the file named (addr len), beginning at line number
l#.  NOTE: Order is important here, as the string may be in POCKET.
We need to save it before +ROOTing the path to the editor.
-------------------------------------------------------------------- }

256 BUFFER: ARG0
256 BUFFER: ARG1
 12 BUFFER: ARG2

CREATE 'ARG   ARG0 , ARG1 , ARG2 , 0 ,

PUBLIC

256 BUFFER: EDITPATH                            \ Counted string specifying location of 'editor' script file
S" %SwiftForth/bin/editor" EDITPATH PLACE       \ Default location for SwiftForth

: EDIT-FILE ( l# addr u -- )   ARG1 ZPLACE
   BASE @ DECIMAL SWAP (.) ARG2 ZPLACE  BASE !
   EDITPATH COUNT +ROOT ARG0 ZPLACE
   fork ?DUP IF  0 0 waitpid DROP
      ELSE  ARG0 'ARG 'ENV execve DROP  0 sys_exit
   THEN ;

PRIVATE

{ --------------------------------------------------------------------
Edit a word

EDITED is the editor equivalent to LOCATED. Give it the xt of a
locatable word and it will start the editor there.

EDIT-WORD looks up the given text in the dictionary and starts the
editor.
-------------------------------------------------------------------- }

: EDITED ( xt -- )
   FALSE WORD-LOCATION DUP 0=
   ABORT" Can't edit keyboard definitions"
   EDIT-FILE ;

: EDIT-WORD ( addr n -- )   R-BUF  R@ PLACE
   R> FINDANY IF EDITED ELSE  ABORT" Can't be located"  THEN ;

{ --------------------------------------------------------------------
User interface

Y/N gets a yes or no answer, with default Y.

G invokes the editor on the most recently viewed word.

EDIT-XREF takes the beginning of a cross-reference line printed by
WHERE (WH) up to and including the '|', and edits the cross-reference.
The first number is the index into FILEHIST (list of files known
about by SwiftForth), the second the line number.  This can be useful
in most X terminal emulators by typing EDIT, then copying and pasting
the two numbers and trailing |.

EDIT does four things:
1. EDIT <nothing> starts the editor at the last located word
2. EDIT <word> starts the editor at the location of the word
3. EDIT <filename> starts the editor at the top of the specified file.
4. EDIT <file# line#|> (beginning of a WH output line) starts the
        editor in file# at line#.

NOTE: EDIT consumes the entire line.  We need to do this because the
filename may have embedded spaces in it.  We considered
double-quoting the argument, but it's not uncommon for Forth
programmers to name strings "STRING1", etc....so then it would be
   EDIT "\"STRING1\""   \ yuck
Rather than open this Pandora's box, we just consume the entire line
as a filename.
-------------------------------------------------------------------- }

: Y/N ( -- flag )
   ." ? (Y/n) [Y] "
   BEGIN  KEY UPPER
      DUP [CHAR] Y =  OVER 13 = OR IF  ." Y"  DROP  TRUE EXIT THEN
      [CHAR] N = IF  ." N"  FALSE EXIT THEN
   AGAIN ;

CROSS-REFERENCE +ORDER  FILE-VIEWER +ORDER

: @XREF ( c-addr -- line addr len )
   BASE @ >R DECIMAL
   0 0 ROT COUNT >NUMBER  OVER C@ BL <> ABORT" Invalid cross reference"
   0 0 2SWAP BL SKIP >NUMBER 2DROP  ROT 2DROP  R> BASE !
   SWAP FILE#> +ROOT ;

PUBLIC

-? : LOCATE ( -- )
   >IN @  0 WORD DUP COUNT -TRAILING + 1- C@ [CHAR] | = IF
      DUP ['] @XREF CATCH 0= IF  VIEW-FILE 2DROP EXIT
   THEN DROP  THEN DROP >IN !  LOCATE ;

PRIVATE

: EDIT-XREF ( c-addr --  )
   @XREF EDIT-FILE ;

FILE-VIEWER -ORDER  CROSS-REFERENCE -ORDER

PUBLIC

: G ( -- )   VIEWED @+ SWAP COUNT EDIT-FILE ;

' G IS EDIT-START

: EDIT ( -- )   R-BUF
   0 WORD COUNT BL SKIP -TRAILING R@ PLACE  R@ C@ IF            \ parse line, strip leading and trailing spaces
      R@ FINDANY NIP IF  R> COUNT EDIT-WORD  EXIT  THEN         \ if in dictionary, edit that word
      R@ COUNT + 1- C@ [CHAR] | = IF  R> EDIT-XREF  EXIT  THEN  \ if it's an xref, go there
      R@ COUNT +ROOT FILE-STATUS NIP IF                         \ not an existing file
         ." Create a new file" Y/N 0= IF                        \ so ask before creating it
            R> DROP EXIT THEN                                   \ discard and do nothing
      THEN  1 R> COUNT +ROOT EDIT-FILE EXIT                     \ edit the given file
   THEN  R> DROP  G ;

END-PACKAGE
