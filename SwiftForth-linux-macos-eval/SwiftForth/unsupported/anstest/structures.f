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

TESTING IF ELSE THEN BEGIN WHILE REPEAT UNTIL RECURSE

{> : GI1 IF
         123
      THEN ; -> }
{> : GI2 IF
         123
      ELSE 234
      THEN ; -> }
{> 0 GI1 -> }
{> 1 GI1 -> 123 }
{> -1 GI1 -> 123 }
{> 0 GI2 -> 234 }
{> 1 GI2 -> 123 }
{> -1 GI1 -> 123 }

{> : GI3 BEGIN
         DUP 5 < WHILE
            DUP 1+
      REPEAT ; -> }
{> 0 GI3 -> 0 1 2 3 4 5 }
{> 4 GI3 -> 4 5 }
{> 5 GI3 -> 5 }
{> 6 GI3 -> 6 }

{> : GI4 BEGIN
         DUP 1+ DUP 5 >
      UNTIL ; -> }
{> 3 GI4 -> 3 4 5 6 }
{> 5 GI4 -> 5 6 }
{> 6 GI4 -> 6 7 }

{> : GI5 BEGIN
         DUP 2 > WHILE
            DUP 5 < WHILE
               DUP 1+
      REPEAT 123
         ELSE 345
      THEN ; -> }
{> 1 GI5 -> 1 345 }
{> 2 GI5 -> 2 345 }
{> 3 GI5 -> 3 4 5 123 }
{> 4 GI5 -> 4 5 123 }
{> 5 GI5 -> 5 123 }

{> : GI6 ( N -- 0,1,..N ) DUP IF
         DUP >R 1- RECURSE R>
      THEN ; -> }
{> 0 GI6 -> 0 }
{> 1 GI6 -> 0 1 }
{> 2 GI6 -> 0 1 2 }
{> 3 GI6 -> 0 1 2 3 }
{> 4 GI6 -> 0 1 2 3 4 }

