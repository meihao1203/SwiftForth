{ ====================================================================
Single-linked list

Copyright 2001  FORTH, Inc.

Patch to DEL contributed by Mike Ghan
==================================================================== }

OPTIONAL LINKEDLIST A class implementation of a generic single-linked list.

{ --------------------------------------------------------------------
A linked list consists of the list head and the list items. Every list
has a unique head, every item has at least a link to the next item.

linked list has a head, and it has members. The head is a pointer to the
first item; each item is identical in format and contains a pointer to
the next item.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
LIST-ITEM is the prototype item class.

INIT is the item initialization method.  Any number of parameters may
be specified here.

FINI is the item finalization method.  Any number of parameters may be
specified here.

DOT displays the item contents. Or not.

MATCH performs a user defined test, returning true if successful.
-------------------------------------------------------------------- }

CLASS LIST-ITEM
   VARIABLE NEXT

   DEFER: INIT  ( i*x -- )   ;
   DEFER: FINI  ( i*x -- )   ;
   DEFER: DOT   ( -- )   ADDR . ;
   DEFER: MATCH ( key -- flag )   DROP 0 ;
END-CLASS

{ --------------------------------------------------------------------
The LINKED-LIST class has a
HEAD which points to the first item in the list.
ITEM-CLASS which has the class identifier of the items.
CONSTRUCT is a default.
LINKED adds an item at the given address to the list.
UNLINK removes the item whose address is given from the list.

ADD puts a new item at the head of the list and executes an item-
specific initialization routine.

DEL removes the specified item from the list.
FIND looks for an item by an item-specific key.
SHOW displays all the list items.
INIT sets the item class.
FIRST returns the address of the first item in the list.
NEXT returns the address of the next item after the one specified.
-------------------------------------------------------------------- }

CLASS LINKED-LIST

   VARIABLE HEAD
   VARIABLE ITEM-CLASS

   : CONSTRUCT ( -- )
      0 HEAD !  LIST-ITEM ITEM-CLASS ! ;

   : LINKED ( addr -- )
      HEAD @ OVER !  HEAD ! ;

   : UNLINK ( addr -- flag )
      HEAD BEGIN
         DUP @ WHILE
         2DUP @ <> WHILE @
      REPEAT SWAP @ SWAP ! -1 ELSE 2DROP 0 THEN ;

   : ADD ( i*x -- addr )   ITEM-CLASS @ :: NEW  DUP -EXIT  >R
      R@ LINKED  R@ [MEMBER] INIT SENDMSG  R> ;

   : DEL ( i*x addr -- )
      DUP >R UNLINK IF R@ [MEMBER] FINI SENDMSG  THEN R> DESTROY ;

   : FIND ( key -- addr )
      HEAD BEGIN @ DUP WHILE
         2DUP 2>R [MEMBER] MATCH SENDMSG IF
            2R> NIP EXIT
         THEN  2R>
      REPEAT 2DROP 0 ;

   : SHOW ( -- )
      HEAD BEGIN @ ?DUP WHILE
         DUP >R  [MEMBER] DOT SENDMSG  R>
      REPEAT ;

   : INIT ( class -- )
      ITEM-CLASS !  0 HEAD ! ;

   : FIRST ( -- addr )   HEAD @ ;
   : NEXT ( addr -- addr )   DUP IF @ THEN ;

END-CLASS
