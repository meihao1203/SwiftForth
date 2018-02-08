{ =====================================================================
ANS Forth Test Suite

Copyright (c) 1998, FORTH, Incorporated

This set of tests has been taken from John Hayes' original Core.fr
Dated Mon, 27 Nov 95 13:10.  We retain the following statement as
required for its use:

(C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.

His last know update was VERSION 1.2

This program tests the core words of an ANS Forth system.
The program assumes a two's complement implementation where
the range of signed numbers is -2^(n-1) ... 2^(n-1)-1 and
the range of unsigned numbers is 0 ... 2^(n)-1.

Dependencies: {> -> } { {{ TESTING

Exports:

===================================================================== }

TESTING INPUT: ACCEPT

CREATE ABUF 80 CHARS ALLOT

: ACCEPT-TEST
   CR ." PLEASE TYPE UP TO 80 CHARACTERS:" CR
   ABUF 80 ACCEPT
   CR ." RECEIVED: " [CHAR] " EMIT
   ABUF SWAP TYPE [CHAR] " EMIT CR
;

{> ACCEPT-TEST -> }

