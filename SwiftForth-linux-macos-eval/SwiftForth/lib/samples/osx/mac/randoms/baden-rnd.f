{ ====================================================================
Wil Baden Random Number Generator

Copyright 2016 by FORTH, Inc.
Copyright (c) 1986-2017 Joel Ryan, STEIM, Roelf Toxopeus

See rnd.f in swiftforth/lib/options/
Changed RND in CHOOSE and added the other usual random things.
Last: 3 March 2011 10:40:44 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
Over the years I have collected a lot of RNG's. I use them a lot.
All my RNG packages define the same set of words.

Wil Badens RAND is very much faster than RANDOM16 (Paul Mennens) and
R250 (Skip Carter).
Quoting Wil: " Random Number Generators should be written for speed ..."

/RND -- initialise RNG. Add this word to Forth startup sequence.
RANDOM -- return unsigned random number
CHOOSE -- return random number in range n, exclusive.
RANF -- generate a random value from 0.0 to 1.0
ALEA -- ( low high -- low <= n < high ) return random number in range.
TOSS -- like tossing a coin : get 0 or -1
%CUT -- returns true if toss puts you within 0..%, where % is passed n.
50 %cut is 50-50 chance of t/f, 30 %cut is 30% true.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

VARIABLE BUD

: /RND ( -- )   UCOUNTER DROP BUD ! ;

: RANDOM  ( -- u )   BUD @  3141592621 *  1+  DUP BUD ! ;

: CHOOSE   ( n1 -- n2 )   RANDOM UM* NIP ;

\ --------------------------------------------------------------------
\ Useful additions:

HEX 7FFFFFFF DECIMAL S>F FCONSTANT MAX32-AS-FP

: RANF ( F: -- X )   RANDOM S>F MAX32-AS-FP F/ ;

: ALEA  ( n1 n2 -- n3 )    OVER - CHOOSE + ;

: TOSS  ( --- flag )   RANDOM 0< ;  \ 1 AND doesn't work well with this rng
        
: %CUT ( n -- flag )   100 CHOOSE > ;

CR .( Baden Pseudo Random Gen loaded)

/RND

\\ ( eof )