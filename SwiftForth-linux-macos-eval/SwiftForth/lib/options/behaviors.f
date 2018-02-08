{ ====================================================================
OTA-like extended methods

Copyright (C) 2001 FORTH, Inc.   All rights reserved.
==================================================================== }

OPTIONAL BEHAVIORS Extend the concept of METHODS as in OTA

{ --------------------------------------------------------------------
?CREATED aborts if the first entry in the most recently defined word
is not a call.

LASTXT returns the xt of the most recently defined word.

COMMAS takes an array of values on the stack and puts them into
the dictionary, assuming that the tos is the LAST item in the
array, not the first. In other words, we reverse the stack first.
-------------------------------------------------------------------- }

: ?IMMEDIATE ( -- )
   LAST @ 1- C@ $40 AND ABORT" Can't apply methods to immediate words" ;

: -CREATED ( -- flag )
   LAST CELL+ CELL+ @ C@ $E8 <> ;

: ?CREATED ( -- )
   -CREATED ABORT" Can't apply methods to non-created objects" ;

: LASTXT ( -- xt )
   LAST CELL+ CELL+ @ CODE> ;

: COMMAS ( n0 n1 n2 ... n -- )
   DUP BEGIN  ?DUP WHILE  ROT >R  1-  REPEAT
   BEGIN  ?DUP WHILE  R> , 1-  REPEAT ;

{ --------------------------------------------------------------------
When a behaviors vector is defined, a structure is compiled and the
word whose behavior is being modified is revectored to the newly
generated code.

For example, the following sequence:

   120 USER FOO METHODS> @ !

modifies the code for FOO to look something like this (with liberties
taken, and a conversion to semi-standard intel assembler notation):

LABEL FOOXT
        JMP     NEWFOO
        DD      120

LABEL NEWFOO
        CALL    DO-METHOD
        CALL    'ORG
        ADD     EAX, FOOXT+5
        PUSH    EAX
        JMP     (USER)
        DD      2
        DD      XT(@)
        DD      XT(!)

The trick is that when compiling, DO-METHOD uses its return address
to compile a call to the instruction following it and then the value
in method to index the array of xts to compile the behaviour.
DO-METHOD returns to whoever called FOO.

If FOO is executed while interpreting, DO-METHOD does nothing and
returns to the CALL 'ORG in NEWFOO, thus executing the original code
for FOO. This behaviour is a bit confusing, but consistent with
the demands of a target-compiled system such as OTA.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
METHOD contains an integer offset for the current desired behavior. It
is reset to zero after it is used; the default behavior is to "fetch".

METHODS is a compile behaviour flag. If on, we will compile methods
with behaviors; if off no behavior is compiled.

HABIT compiles the a stub which will execute the old behavior of a
word whose behavior is being changed.

COMPILE-BEHAVIOR compiles a reference to a behavior-modified word along
with the specified behavior vector.

DO-BEHAVIOR compiles the proper behavior or executes the old behavior,
depending on STATE.

REVECTOR changes the initial call at an XT into a JUMP to a new bit
of code.
-------------------------------------------------------------------- }

VARIABLE METHOD
VARIABLE METHODS   METHODS ON

: HABIT ( xt -- )
   [+ASM]
      'ORG CALL
      ( xt) DUP 5 + # EAX ADD
      EAX PUSH
      ( xt) >CODE 1+ @+ + JMP
   [-ASM] ;

: COMPILE-BEHAVIOR ( addr -- )
   DUP ,CALL
   METHOD @ 0< IF  DROP EXIT THEN
   METHODS @ 0= IF DROP EXIT THEN
   16 + @+ ( base of vectors and n) CELLS
   METHOD @ <  ABORT" Invalid behavior specified"
   METHOD @ + @ COMPILE, ;

: DO-BEHAVIOR ( -- )
   STATE @ IF R> COMPILE-BEHAVIOR THEN METHOD OFF ;

: REVECTOR ( newcode oldxt -- )
   >CODE $E9 OVER C! 1+ TUCK CELL+ - SWAP ! ;

{ --------------------------------------------------------------------
BEHAVIORS

(BEHAVIORS) compiles a new stub for a word along with an array of
behaviors to act on the stub with.

GET-XTS simply parses N items from the input stream and either
compiles or pushes literals.

BEHAVIORS> compiles N behaviors for the most recently defined word.

METHODS> compiles 2 behaviors for the most recently defined word.
-------------------------------------------------------------------- }

: (BEHAVIORS) ( xt1 xt2 ... xtn n -- )
   ?CREATED ?IMMEDIATE
   HERE >R  ['] DO-BEHAVIOR >CODE ,CALL
   LASTXT HABIT DUP , COMMAS
   R> LASTXT REVECTOR IMMEDIATE ;

: GET-XTS ( n -- ... )
   0 ?DO  ' STATE @ IF POSTPONE LITERAL THEN  LOOP ;

: BEHAVIORS> ( n -- )
   DUP >R  GET-XTS  STATE @ IF
      R> POSTPONE LITERAL  POSTPONE (BEHAVIORS)
   ELSE R> (BEHAVIORS) THEN ; IMMEDIATE

: METHODS> ( -- )   2 POSTPONE BEHAVIORS> ;  IMMEDIATE

{ --------------------------------------------------------------------
We redefine TO and +TO in order to make allowances for the previous
uses.  If the previous TO fails, restore the input pointer and set
METHOD for the new TO.  If the old TO worked, well, things are
just fine.

OLDFN is a method that all behavior-ed words have that allows you
to access the word's original function at run time.
-------------------------------------------------------------------- }

-? : TO
   >IN @ >R
   ['] TO CATCH IF ( failed) R@ >IN ! 4 METHOD ! THEN
   R> DROP ; IMMEDIATE

-? : +TO
   >IN @ >R
   ['] +TO CATCH IF ( failed) R@ >IN ! 8 METHOD ! THEN
   R> DROP ; IMMEDIATE

: OLDFN ( -- n )   -1 METHOD ! ; IMMEDIATE

\\

{ --------------------------------------------------------------------
Simple tests
-------------------------------------------------------------------- }

120 USER FOO METHODS> @ !

: .STRING ( a -- )   COUNT TYPE ;

CREATE BAR 256 ALLOT  METHODS> .STRING PLACE

: T1   FOO ;
: T2   16 TO FOO ;
: T3   10 TO FOO ;

: T4   S" THIS IS A TEST" TO BAR ;
: T5   BAR ;

: FORWARD:   CREATE 0 , METHODS> @EXECUTE ! ;

: VAL CREATE , [ 3 ] BEHAVIORS> @ ! +! ;

88 VAL JOE

: T6 JOE . ;
: T7 99 TO JOE ;
: T8 1 +TO JOE ;

