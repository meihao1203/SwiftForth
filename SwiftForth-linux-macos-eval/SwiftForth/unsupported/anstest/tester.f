{ =====================================================================
ANS Forth Test Harness

Copyright (c) 1998, FORTH, Incorporated

This file is the test harness which provides a common mechanism for
testing our Forth systems.  It was originally devloped by John Hayes
and retains the following statement as required for its use:

(C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.

His last know update was VERSION 1.1

Dependencies: { VERBOSE

Exports: {> -> } { {{ TESTING

===================================================================== }

( ---------------------------------------------------------------------
Test harness

INITIAL-DEPTH records the depth of the stack at compile time and uses
this to redefine DEPTH.  This prevents invalid failures when there are
values on the stack before this test suite is loaded.  This value is set
back to 0 after the test suite is completed.

EMPTY-STACK empty the data stack: handles underflowed stack too.

ERROR display an error message followed by the line that had the error.

{{ bypasses the test with a message, treating it as a comment.

{> Start a test, syntactic sugar.

-> record depth and up to 32 stack items.

} compare expected stack contents with saved contents.

TESTING talking comment.

--------------------------------------------------------------------- )

DEPTH VALUE INITIAL-DEPTH \ Allow stack values before INCLUDE.

-? : DEPTH ( -- n )   DEPTH INITIAL-DEPTH - ;

: EMPTY-STACK ( ... -- )
   DEPTH ?DUP IF
      DUP 0< IF
         NEGATE 0 DO
            0
      LOOP ELSE 0 DO
            DROP
   LOOP THEN THEN ;

: ERROR ( c-addr u -- )
   TYPE SOURCE TYPE CR  \ Display line corresponding to error
   EMPTY-STACK          \ Throw away every thing else
;

VARIABLE ACTUAL-DEPTH   \ Stack record

CREATE ACTUAL-RESULTS 32 CELLS ALLOT

: {{ ( -- )
   S" BYPASSED: " ERROR  POSTPONE { ;

: {> ( -- )
   ;

-? : -> ( ... -- )
   DEPTH DUP ACTUAL-DEPTH !             \ Record depth
   ?DUP IF                              \ If something is on stack
      0 DO                              \ For each stack item
         ACTUAL-RESULTS I CELLS + !     \ Save them
   LOOP THEN ;

: } ( ... -- )
   DEPTH ACTUAL-DEPTH @ = IF            \ If depths match
      DEPTH ?DUP IF                     \ If something is on stack
         0 DO                           \ For each stack item
            ACTUAL-RESULTS I CELLS + @  \ Compare actual to expected
            <> IF
               S" INCORRECT RESULT: " ERROR LEAVE
   THEN  LOOP  THEN  ELSE               \ Depth mismatch
      S" WRONG NUMBER OF RESULTS: " ERROR
   THEN ;

: TESTING ( -- )
   SOURCE VERBOSE @ IF
      DUP >R TYPE CR R> >IN !
   ELSE  >IN ! DROP
   THEN ;

