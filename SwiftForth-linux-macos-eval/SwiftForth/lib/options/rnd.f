{ ====================================================================
Random numbers in Forth

Copyright (C) 2001 FORTH, Inc.  All rights reserved
==================================================================== }

OPTIONAL RANDOM Parametric multiplicative linear congruential random number generator

{ --------------------------------------------------------------------
Exports: RND SEED

D. H. Lehmers Parametric multiplicative linear congruential random
number generator is implemented as outlined in the October 1988
Communications of the ACM (V 31, N 10, pg 1192)

Per Wil Baden, this code is flawed. It is left in a comment so the
user can learn from my misteaks

     16807 CONSTANT A
2147483647 CONSTANT M
    127773 CONSTANT Q   \ m a /
      2836 CONSTANT R   \ m a mod

CREATE SEED  123475689 ,

\ Returns a full cycle random number

: RANDS ( 'seed -- rand )
   DUP >R
   @ Q /MOD ( lo high)
   R * SWAP A * 2DUP > IF  - ELSE  - M +  THEN  DUP R> ! ;

: RAND ( -- rand )  \ 0 <= rand < ((4,294,967,296/2)-1)
   SEED RANDS ;

\ Returns single random number less than n

: RND ( n -- rnd )  \ 0 <= rnd < n
   RAND SWAP MOD ;

: RNDS ( n 'seed -- rnd )
   RANDS SWAP MOD ;

-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
\ The code in RND.F is not quite right.  The article that was its
\ source was intended for languages without a double accumulator --
\ Fortran, Pascal, C.  For Forth  M  should be the machine word.
\ Random Number Generators should be written for speed so  RANDS
\ should be eliminated.  The range given in  RANDS  is wrong.
\ And  SEED  is not the seed -- the seed is the first of the
\ sequence.
\
\ The serious error is in  RND  .  MOD  should not be used for
\ ranges of random numbers.  This program shows why.
\
\     mil  is a convenient factor for large numbers.
\     #Samples  is the number of samples to be taken.
\     Sample-Range  is the range of the samples.
\     |Bins|  is the number of bins used for the bar-graph.
\     Bins  is the array of bins for the sample.
\     bar-graph  displays  Bins  .
\     take-samples  takes samples.  It's run before  bar-graph  .
\
\ Test the random number generator

: EMITS  ( n c -- )  SWAP 0 ?DO  DUP EMIT  LOOP  DROP ;
: BUFFER:  ( n -- )  CREATE ALLOT ;

: mil 1000000 * ;
1 mil    CONSTANT #Samples
1000 mil CONSTANT Sample-Range
10       CONSTANT |Bins|
|Bins| CELLS BUFFER: Bins

: bar-graph   CR ( -- )
    |Bins| 0 DO
        CR  I Sample-Range |Bins| */ 10 .R  SPACE
        I CELLS Bins + @
            DUP  |Bins| 40 *  #Samples  */  [CHAR] # EMITS
            SPACE  .
    LOOP
    CR
;

: take-samples                                        ( -- )
    Bins |Bins| CELLS ERASE
    #Samples 0 ?DO
        Sample-Range RND
            |Bins| Sample-Range */ CELLS Bins + ++
    LOOP
;

take-samples  bar-graph

\ The problem is negligible with small ranges, but should not be
\ allowed.  So here are re-written  RAND  and  RND  with  SEED
\ re-named to  Bud  because it comes after  SEED  .  The sampler
\ take-samples  is re-compiled.
\ This code was run in PowerMacForth and SwiftForth.
\
\ --
\ Wil Baden   Costa Mesa, California   WilBaden@Netcom.com
-------------------------------------------------------------------- }

VARIABLE BUD

: RAND  ( -- u )  BUD @  3141592621 *  1+  DUP BUD ! ;
: RND   ( n -- u )  RAND UM* NIP ;

: /RND ( -- )
   uCOUNTER DROP BUD ! ;

/RND

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

/RND
100 RND .
100 RND .
100 RND .
100 RND .
100 RND .
100 RND .
100 RND .
100 RND .
100 RND .

KEY DROP BYE  [THEN]
