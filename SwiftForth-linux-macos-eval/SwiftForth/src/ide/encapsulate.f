{ ====================================================================
Packages

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

This file provieds an alternative to vocabularies.

Encapsulation is the process of containing a set of entities such that
the members are only visible thru a user-defined window.  Object
oriented programming is one kind of encapsulation. Another is when a
word or routine requires supporting words for its definition, but
which have no interest to the "outside" world.
==================================================================== }

{ --------------------------------------------------------------------
Package defining

-PACKAGE enforces a valid PACKAGE frame on the data stack. The frame
is considered valid if the tag is the xt of wordlist and the value
returned by GET-CURRENT is either the wid of the package or its
parent.

?PACKAGE checks the frame, and aborts if bad.

OPEN-PACKAGE creates a frame given a WID.

PACKAGE creates or re-uses a package, leaving a valid frame.

END-PACKAGE restores CONTEXT and CURRENT to their prior states.

PUBLIC changes CURRENT to the parent and
PRIVATE changes CURRENT to the package.
-------------------------------------------------------------------- }

?( Package wordlist encapsulation)

THROW#
   S" Package balance changed" >THROW ENUM IOR_PACKAGEBALANCE
   S" Not a package"           >THROW ENUM IOR_PACKAGENOT
TO THROW#

: -PACKAGE ( parent package tag -- flag )   ['] WORDLIST =
   SWAP GET-CURRENT = ROT GET-CURRENT = OR AND 0= ;

: ?PACKAGE ( parent package tag -- parent package tag )
   3DUP -PACKAGE IOR_PACKAGEBALANCE ?THROW ;

: OPEN-PACKAGE ( wid -- parent package tag )
   GET-CURRENT  SWAP DUP SET-CURRENT
   DUP +ORDER  ['] WORDLIST ;

: PACKAGE ( -- parent package tag )
   >IN @  BL WORD FIND IF ( exists)  NIP
      DUP >BODY CELL+ CELL+ @ ['] WORDLIST <> IOR_PACKAGENOT ?THROW
      >BODY CELL+ @ OPEN-PACKAGE  EXIT
   THEN  DROP >IN !
   1 STRANDS CREATE
      VLINK >LINK  DUP , ['] WORDLIST , OPEN-PACKAGE
   DOES> CELL+ @ ;

: END-PACKAGE ( parent package tag -- )
   ?PACKAGE DROP -ORDER SET-CURRENT ;

: PUBLIC ( parent package tag -- parent package tag )
   ?PACKAGE  THIRD SET-CURRENT ;

: PRIVATE ( parent package tag -- parent package tag )
   ?PACKAGE OVER SET-CURRENT ;
