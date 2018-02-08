{ ====================================================================
Random numbers in Forth

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL RNDOOP Random number class implementation

{ --------------------------------------------------------------------
D. H. Lehmers Parametric multiplicative linear congruential random
number generator is implemented as outlined in the October 1988
Communications of the ACM (V 31, N 10, pg 1192)
-------------------------------------------------------------------- }

CLASS RND-NUMBERS

VARIABLE SEED

: RAND ( -- u )
    SEED @  3141592621 *  1+  DUP  SEED ! ;

: NUMBER ( n -- u )
    RAND UM* NIP ;

: INIT ( -- )
   uCOUNTER DROP  SEED ! ;

END-CLASS

RND-NUMBERS BUILDS STOCKRND

: RND   STOCKRND NUMBER ;
: /RND   STOCKRND INIT ;

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
