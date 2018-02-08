{ ====================================================================
stacks.f
Simple memory based stacks

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

OPTIONAL STACKS Define memory based stacks

{ --------------------------------------------------------------------
STACK creates a stack of N cells.

PUSH  puts the value X on top of the stack.

TOP  reads the top of the stack.

POP  discards the top number on the stack.

/STACK clears the stack.

EMPTY? checks if the stack has any data.
-------------------------------------------------------------------- }

: STACK ( n -- )  \ Usage: n STACK <name>
   CREATE   HERE ,  CELLS ALLOT ;

: PUSH ( x stack -- )
   CELL OVER +! @ ! ;

: TOP ( stack -- x )
   @ @ ;

: POP ( stack -- )
   DUP DUP @ = NOT IF  -CELL SWAP +!  THEN ;

: /STACK ( stack -- )
   DUP ! ;

: EMPTY? ( stack -- flag )
   DUP @ = ;

