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

Dependencies: {> -> } { {{ TESTING MID-UINT MID-UINT+1 MIN-INT

Exports:

===================================================================== }

TESTING ADD/SUBTRACT: + - 1+ 1- ABS NEGATE

{> 0 5 + -> 5 }
{> 5 0 + -> 5 }
{> 0 -5 + -> -5 }
{> -5 0 + -> -5 }
{> 1 2 + -> 3 }
{> 1 -2 + -> -1 }
{> -1 2 + -> 1 }
{> -1 -2 + -> -3 }
{> -1 1 + -> 0 }
{> MID-UINT 1 + -> MID-UINT+1 }

{> 0 5 - -> -5 }
{> 5 0 - -> 5 }
{> 0 -5 - -> 5 }
{> -5 0 - -> -5 }
{> 1 2 - -> -1 }
{> 1 -2 - -> 3 }
{> -1 2 - -> -3 }
{> -1 -2 - -> 1 }
{> 0 1 - -> -1 }
{> MID-UINT+1 1 - -> MID-UINT }

{> 0 1+ -> 1 }
{> -1 1+ -> 0 }
{> 1 1+ -> 2 }
{> MID-UINT 1+ -> MID-UINT+1 }

{> 2 1- -> 1 }
{> 1 1- -> 0 }
{> 0 1- -> -1 }
{> MID-UINT+1 1- -> MID-UINT }

{> 0 NEGATE -> 0 }
{> 1 NEGATE -> -1 }
{> -1 NEGATE -> 1 }
{> 2 NEGATE -> -2 }
{> -2 NEGATE -> 2 }

{> 0 ABS -> 0 }
{> 1 ABS -> 1 }
{> -1 ABS -> 1 }
{> MIN-INT ABS -> MID-UINT+1 }

