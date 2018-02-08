{ ====================================================================
sortedlist.f


Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

OPTIONAL SORTEDLIST A Sorted-List class.

{ --------------------------------------------------------------------
A sorted-list class which, when given a specific class to act
with, can grow a sorted list of objects of the desired class.
-------------------------------------------------------------------- }

REQUIRES VALUES

{ --------------------------------------------------------------------
SORTED-LIST is a widget for storing objects in an extensible list.
This is a sorted list, not a linked list, in allocated memory. It
automatically doubles its available memory when full. The default
object is simply an array of 1 cell integers.

API is

... sortkey ADD         \ add the object data at the sortkey
n GET ...               \ get the object data from the nth position
... n PUT               \ write the object data to the nth position
CLEAR                   \ reset the array
USED                    \ how many items are in the array
-------------------------------------------------------------------- }

CLASS SORTED-LIST

   PUBLIC

   SINGLE USED          \ number of items in array

   DEFER: ITEMS ( n -- n )   CELL ;
   DEFER: SORT@ ( 'obj -- value )   @ ;
   DEFER: STORE ( ... n 'obj -- )   ! ;
   DEFER: FETCH ( 'obj -- ... n )   @ ;

\   PROTECTED

   SINGLE HEAD          \ point to memory
   SINGLE SIZE          \ how many items it will hold

   : ITEM ( n -- addr )   ITEMS HEAD + ;

   : CLEAR ( -- )   0 TO USED 0 TO SIZE ;

   : 1MORE ( -- )   HEAD -EXIT   USED SIZE < IF EXIT THEN
      SIZE 2* 1 MAX ITEMS ALLOCATE IF DROP EXIT THEN
      HEAD IF HEAD OVER SIZE ITEMS CMOVE  THEN  TO HEAD
      SIZE 2* 1 MAX TO SIZE ;

   : LOCALE ( x -- n )   >R
      0 USED BEGIN ( lo hi)
         2DUP - ABS 1 > WHILE
         2DUP + 2/ DUP ITEM SORT@
         R@ <= IF SWAP ROT ELSE SWAP THEN DROP
      REPEAT OVER ITEM SORT@ R>  > IF SWAP THEN NIP ;

   : SPREAD ( addr -- )
      DUP 1 ITEMS + USED ITEM 2 PICK - CMOVE> ;

   : SPOT ( x -- addr )
      LOCALE  ITEM  DUP SPREAD ;

   PUBLIC

   : ADD ( ... sortkey -- )   1MORE  SPOT STORE  1 +TO USED ;
   : GET ( n -- ... n )   ITEM FETCH ;
   : PUT ( ... n n -- )   ITEM STORE ;

   : DESTRUCT ( -- )
      HEAD IF HEAD FREE DROP THEN  0 TO HEAD ;

   : CONSTRUCT ( -- )   DESTRUCT
      1 ITEMS ALLOCATE IF DROP 0 THEN TO HEAD  CLEAR ;

   : CLEAR ( -- )   0 TO USED ;

END-CLASS

\\ An example of how to use this class is

{ --------------------------------------------------------------------
Simple vector point class. Data is hidden, but public methods can
access it.
-------------------------------------------------------------------- }

CLASS VPOINT

   PROTECTED

   VARIABLE X
   VARIABLE Y

   PUBLIC

   : V@ ( -- x y )   X @ Y @ ;
   : V! ( x y -- )   Y ! X ! ;

   : X@ ( -- x )   X @ ;
   : Y@ ( -- y )   Y @ ;
   : X! ( x -- )   X ! ;
   : Y! ( y -- )   Y ! ;

END-CLASS

SORTED-LIST SUBCLASS SORTED-POINTS

   : ITEMS ( n -- n )   VPOINT SIZEOF * ;

   : SORT@ ( n -- x )
      [OBJECTS VPOINT NAMES VP OBJECTS]  VP X@ ;

   : STORE ( x y 'obj -- )
      [OBJECTS VPOINT NAMES VP OBJECTS]  VP V! ;

   : FETCH ( 'obj -- x y )
      [OBJECTS VPOINT NAMES VP OBJECTS]  VP V@ ;

END-CLASS



