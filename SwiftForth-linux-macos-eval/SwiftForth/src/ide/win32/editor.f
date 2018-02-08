{ ====================================================================
Interface to user-specified editor

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
Rick VanNorman

If no external editor is set in SwiftForth's registry entries, we fall
back to Notepad.
==================================================================== }

?( User-specified external editor interface)

PACKAGE FILE-VIEWER

{ --------------------------------------------------------------------
The editor description strings are asciiz

FORMAT-EDIT-COMMAND takes the line/addr/len given to EDIT-FILE plus a
buffer to put it in and creates a command line for the arbitrary
external editor.  In this command line, the string %F is replaced by
the filename and %L is replaced by the line number.

ANY-EDIT creates a buffer for the command and launches the specified
editor.
-------------------------------------------------------------------- }

CREATE EDITOR-OPTIONS  256 /ALLOT
CREATE EDITOR-NAME     256 /ALLOT

CONFIG: ENAME ( -- addr n )   EDITOR-NAME 256 ;
CONFIG: EOPTS ( -- addr n )   EDITOR-OPTIONS 256 ;

: FORMAT-EDIT-COMMAND ( line addr len buf256 -- )
   LOCALS| buf len addr line |   buf OFF  BASE @ >R DECIMAL
   EDITOR-NAME ZCOUNT buf ZPLACE   S"  " buf ZAPPEND
   EDITOR-OPTIONS ZCOUNT BEGIN ( a n)
      [CHAR] % SPLIT  buf ZAPPEND
      DUP WHILE  1 /STRING
      OVER C@ UPPER CASE
         [CHAR] F OF  addr len buf ZAPPEND  1 ENDOF
         [CHAR] L OF  line (.) buf ZAPPEND  1 ENDOF
              DUP OF  S" %"    buf ZAPPEND  0 ENDOF
      ENDCASE ( a n n) /STRING
   REPEAT 2DROP R> BASE ! ;

: USE-NOTEPAD? ( -- flag )
   -1  USE-NOTEPAD @ ?EXIT  EDITOR-NAME C@ -EXIT
   EDITOR-NAME ZCOUNT S" NOTEPAD.EXE" SEARCH(NC) NIP NIP ?EXIT  1+ ;

PUBLIC

: EDIT-FILE ( line addr len -- )
   USE-NOTEPAD? IF NOTEPAD-EDIT EXIT THEN
   R-BUF  R@ FORMAT-EDIT-COMMAND  R> >PROCESS DROP ;

PRIVATE

{ --------------------------------------------------------------------
EDIT-FILE is the primary interface to the editor. There are
   two built-in vectors for it -- one thru NOTEPAD and the
   other thru ANY-EDIT.

EDITED is the editor equivalent to LOCATED. Give it the
   xt of a locatable word and it will start the editor there.

EDIT-WORD looks up the given text in the dictionary and
   starts the editor.

EDIT parses and edits a word.
-------------------------------------------------------------------- }

?( ...Edit a word's source code)

: EDITED ( xt -- )
   FALSE WORD-LOCATION DUP 0=
   ABORT" Can't edit keyboard definitions"
   EDIT-FILE ;

: EDIT-WORD ( addr n -- )   R-BUF  R@ PLACE
   R> FINDANY IF EDITED ELSE  ABORT" Can't be located"  THEN ;

{ ------------------------------------------------------------------------
EDIT does three things
1. EDIT <nothing> starts the editor at the last located word
2. EDIT <word> starts the editor at the location of the word
3. EDIT <filename> starts the editor at the top of the specified file
------------------------------------------------------------------------ }

PUBLIC

: EDIT ( -- )
   BL WORD COUNT EDIT-WORD ;

: G ( -- )
   VIEWED @+ SWAP COUNT EDIT-FILE ;

' G IS EDIT-START

END-PACKAGE
