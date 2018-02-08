{ ====================================================================
Printer output

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

This utility implements printer output for SwiftForth.

Requires: Printer Preview, Personalities, EVALUATE, CATCH-THROW.

Exports: >PRINT and >FILE
==================================================================== }

PACKAGE PRINTING

{ --------------------------------------------------------------------
Evaluate a string in a personality

(P-EVAL) evaluates the string after invoking the personality.  The
personality is revoked after it is done.

P-EVAL saves the current context and evaluates the string in the
specified personality. Errors are caught and reported in the original
personality.

-------------------------------------------------------------------- }

: (P-EVAL) ( i*x addr n -- j*x )
   INVOKE  ( addr n ) ['] EVALUATE CATCH ( * )
   REVOKE  ( * ) THROW ;

PUBLIC

: P-EVAL ( i*x caddr n personality -- j*x )
   ?DUP IF
      'PERSONALITY @ >R  'PERSONALITY !
      R@ PREVIOUS-PERSONALITY !
      ['] (P-EVAL) CATCH ( * )
      R> 'PERSONALITY !
      ( * ) ?DUP IF
         CR ." Error during P-EVAL " DUP . THROW
      THEN  CR  EXIT
   THEN  2DROP ;

: P-EXECUTE ( i*x xt personality -- j*x )
   'PERSONALITY @ >R  'PERSONALITY !
   R@ PREVIOUS-PERSONALITY !
   INVOKE  ( xt) CATCH ( * )  REVOKE
   R> 'PERSONALITY !
   ( *) THROW ;

PRIVATE

{ --------------------------------------------------------------------
Printer personality I/O words

A personality for output needs to support

PR-INVOKE makes sure that the printer is not already open, opens the
printer buffer, and initializes the display variables.

PR-REVOKE lets the user send the printer buffer to a printer and then
closes the buffer.

PR-TYPE which sends the text to the printer buffer.

[EMIT] generic which types the character on top of the stack.

[CRLF] generic CR which types the CR and LF characters.

[PAGE] generic form feed command.

-------------------------------------------------------------------- }

: PR-INVOKE ( -- )   PRNBUF-HANDLE IOR_PRT_ALREADYOPEN ?THROW  OPEN-PRNBUF ;

: PR-REVOKE ( -- )   PRINT-RICH-EDIT  CLOSE-PRNBUF ;

: PR-TYPE ( addr n -- )   WRITE-TEXT DROP ;

: [EMIT] ( char -- )   SP@ 1 TYPE DROP ;

: [CRLF] ( -- )   <EOL> COUNT TYPE ;

: [PAGE] ( -- )   12 EMIT ;

{ --------------------------------------------------------------------
Printer personality

WINPRINT is the personality to print with.
-------------------------------------------------------------------- }

CREATE WINPRINT
        16 ,            \ datasize
         7 ,            \ maxvector
         0 ,            \ handle
         0 ,            \ PREVIOUS
   ' PR-INVOKE ,        \ INVOKE    ( -- )
   ' PR-REVOKE ,        \ REVOKE    ( -- )
   ' NOOP ,             \ /INPUT    ( -- )
   ' [EMIT] ,           \ EMIT      ( char -- )
   ' PR-TYPE ,          \ TYPE      ( addr len -- )
   ' PR-TYPE ,          \ ?TYPE     ( addr len -- )
   ' [CRLF] ,           \ CR        ( -- )
   ' NOOP ,             \ PAGE      ( -- )

PUBLIC

: >PRINT ( -- )   0 PARSE  WINPRINT P-EVAL ;

PRIVATE

{ --------------------------------------------------------------------
File console output
-------------------------------------------------------------------- }

: F-TYPE ( addr n -- )
   ?DUP IF
      PERSONALITY-HANDLE @ WRITE-FILE THROW EXIT
   THEN  DROP ;

OFN-DIALOGS +ORDER

: F-INVOKE ( -- )
   PERSONALITY-HANDLE @ IOR_PRT_REVECTOR ?THROW
   [OBJECTS
      SAVE-TEXT-DIALOG MAKES SFD
   OBJECTS]
   SFD CHOOSE 0= THROW
   SFD FILENAME ZCOUNT R/W CREATE-FILE THROW
   PERSONALITY-HANDLE ! ;

OFN-DIALOGS -ORDER

: F-REVOKE ( -- )
   PERSONALITY-HANDLE @ ?DUP IF
      CLOSE-FILE DROP
   THEN  0 PERSONALITY-HANDLE ! ;

{ --------------------------------------------------------------------
File personality

WINFILE is the personality to send output to a file.
-------------------------------------------------------------------- }

CREATE WINFILE
        16 ,            \ datasize
         7 ,            \ maxvector
         0 ,            \ handle
         0 ,            \ PREVIOUS
   ' F-INVOKE ,         \ INVOKE    ( -- )
   ' F-REVOKE ,         \ REVOKE    ( -- )
   ' NOOP ,             \ /INPUT    ( -- )
   ' [EMIT] ,           \ EMIT      ( char -- )
   ' F-TYPE ,           \ TYPE      ( addr len -- )
   ' F-TYPE ,           \ ?TYPE     ( addr len -- )
   ' [CRLF] ,           \ CR        ( -- )
   ' [PAGE] ,           \ PAGE      ( -- )

PUBLIC

: >FILE ( -- )   0 PARSE  WINFILE P-EVAL ;

END-PACKAGE
