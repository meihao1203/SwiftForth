{ ====================================================================
Values

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
SWOOP extension to implement the VALUE datatype, named SINGLE here
since VALUE requires an initial value, and we don't.

This technique uses a method index to compile an access for a datum.
'METHOD is kept in the user area for re-entrancy.

The implementation checks for local object, local variable, standard
forth VALUE, then object SINGLE.

SINGLE is a special case, and uses 'METHOD to indicate the access
method for the variable.
-------------------------------------------------------------------- }

-? : TO ( n -- )   
   LOBJ-COMP TO-LOCAL ?EXIT    \ local object
   LVAR-COMP TO-LOCAL ?EXIT    \ local variable
             TO-VALUE ?EXIT    \ VALUE
   1 'METHOD ! ; IMMEDIATE     \ SINGLE

-? : +TO ( n -- )   
   LOBJ-COMP +TO-LOCAL ?EXIT  
   LVAR-COMP +TO-LOCAL ?EXIT  
             +TO-VALUE ?EXIT  
   2 'METHOD ! ; IMMEDIATE

-? : &OF ( -- addr )   
   LOBJ-COMP &OF-LOCAL ?EXIT
   LVAR-COMP &OF-LOCAL ?EXIT 
             &OF-VALUE ?EXIT  
   3 'METHOD ! ; IMMEDIATE

{ --------------------------------------------------------------------
| compiler-xt | link | member handle | runtime-xt | offset | nmethods | method0 | method1 |

The run-value and compile-value operators are similar to the normal
data operators, but they compile or execute the specified method
automatically.
-------------------------------------------------------------------- }

PACKAGE OOP

: THE-METHOD ( ... 'nmethods -- xt )
   @+ 'METHOD @ TUCK  0 'METHOD !  < ABORT" invalid method "  CELLS + @ ;

: RUN-VALUE ( object 'data -- addr )
   @+ ROT +  ( 'm0 a)  SWAP  THE-METHOD EXECUTE
   0 >THIS ;

: COMPILE-VALUE ( 'data -- )   "SELF"   \ 'data: offset
   @+ ?DUP IF POSTPONE LITERAL POSTPONE + THEN  THE-METHOD COMPILE,
   END-REFERENCE ;

{ --------------------------------------------------------------------
SINGLE defines a method-based datum. The default is to fetch it, like
a value. Method 1 is store, method 2 is plus-store.

We keep the number of methods, and an array of xts for dealing with
the various methods. These should be normal forth words.
-------------------------------------------------------------------- }

GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : SINGLE ( -- )
      MEMBER  THIS SIZEOF
      ['] RUN-VALUE ['] COMPILE-VALUE  NEW-MEMBER
      4 ,  ['] @ , ['] ! ,  ['] +! ,  ['] NOOP , 
      CELL THIS >SIZE +! ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT

END-PACKAGE

{ --------------------------------------------------------------------
A simple example

CLASS X1
   SINGLE X
   SINGLE Y
   : DOT X . Y . ;
END-CLASS

X1 BUILDS ZOT

5 TO ZOT X
4 ZOT TO Y
7 ZOT +TO Y
ZOT DOT
-------------------------------------------------------------------- }
