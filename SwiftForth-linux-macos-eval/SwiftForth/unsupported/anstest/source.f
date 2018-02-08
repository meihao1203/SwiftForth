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

Dependencies: {> -> } { {{ TESTING <TRUE>

Exports:

===================================================================== }

TESTING SOURCE >IN WORD

: GS1 S" SOURCE" 2DUP EVALUATE
   >R SWAP >R = R> R> = ;
{> GS1 -> <TRUE> <TRUE> }

VARIABLE SCANS

: RESCAN?
   -1 SCANS +! SCANS @ IF
      0 >IN !
   THEN ;

{>
   2 SCANS !
   345 RESCAN?
-> 345 345 }

: GS2 5 SCANS ! S" 123 RESCAN?" EVALUATE ;
{> GS2 -> 123 123 123 123 123 }

: GS3 WORD COUNT SWAP C@ ;
{> BL GS3 HELLO -> 5 CHAR H }
{> CHAR " GS3 GOODBYE" -> 7 CHAR G }
{> BL GS3
DROP -> 0 }     \ Blank line returns zero-length string

: GS4 SOURCE >IN ! DROP ;
{> GS4 123 456
-> }

