{ ====================================================================
Random number generator - Complex method

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL IRN55 FORTRAN random number generator

{ --------------------------------------------------------------------
These routines originally appeared in The Journal of Forth Applications
and Research, Vol. 1, Number 2, Dec. 1983.

It is based upon Knuth's FORTRAN function IRN55 and uses the
'subtractive tabular' method of Mitchell and Moore.  Successive random
numbers are obtained from the array according to the rule:

      X     = X  - X
       n+55    n    n+31

It has a repetition cycle of 2**55 sequences.

Dependencies: none

Exports: SETUP RANDOM
-------------------------------------------------------------------- }

{ ---------------------------------------------------------------------
RND random manipulation array.  The first cell is the random cycle
counter, the rest are the random index cells.

SEED random number seed.

CYCLE sets up the cyclic index given a limit and a counter to hold the
next index.

STEP this steps the index around the cycle (mod 55).

RAND returns the next random number in the cycle.
--------------------------------------------------------------------- }

CREATE 'RND   56 CELLS /ALLOT

: RND ( n -- a )   CELLS 'RND + ;

314159296 VALUE SEED

: CYCLE ( nlimit a -- nnext )
   DUP @ 1+  ROT OVER U< IF
      DROP 1
   THEN  DUP ROT ! ;

: STEP ( -- n+1 )   55 0 RND CYCLE ;

: RAND ( -- n )
   STEP DUP >R  RND @  DUP R@ DUP  25 < IF
      31 +
   ELSE  24 -
   THEN  RND @  - DUP 0< IF
      1000000000 +
   THEN  R> RND ! ;

{ ---------------------------------------------------------------------
Random number initialization

RND.INIT initializes the random array and the other pointers with
random numbers based upon the seed.  It computes the Fibonacci-like
sequence and then scatters the values around to improve the initial
randomness of the array.

WARMUP initialize and wind up the random number generator by calling it
a number of times.

SETUP seed the random generator and initialize the arrays.

RANDOM returns a complex random number in the given modulo.

--------------------------------------------------------------------- }

: RND.INIT
   0 0 RND !  SEED DUP 55 RND !  1 SWAP  55 1 DO
      OVER DUP  21 I * 55 MOD RND !  - DUP 0< IF
         1000000000 +
      THEN  SWAP
   LOOP  2DROP ;

: WARMUP   221 1 DO  RAND DROP  LOOP ;

: RND.SETUP   RND.INIT  WARMUP ;   RND.SETUP

: RANDOM ( mod -- n )   RAND SWAP MOD ;

{ --------------------------------------------------------------------
TESTING
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

COUNTER TO SEED
RND.SETUP
100 RANDOM .
100 RANDOM .
100 RANDOM .
100 RANDOM .
100 RANDOM .
100 RANDOM .

KEY DROP BYE  [THEN]
