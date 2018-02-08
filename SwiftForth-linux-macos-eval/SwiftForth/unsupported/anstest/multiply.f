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

Dependencies: {> -> } { {{ TESTING MSB MAX-UINT MAX-INT MIN-INT MID-UINT
MID-UINT+1 1S

Exports:

===================================================================== }

TESTING MULTIPLY: S>D * M* UM*

{> 0 S>D -> 0 0 }
{> 1 S>D -> 1 0 }
{> 2 S>D -> 2 0 }
{> -1 S>D -> -1 -1 }
{> -2 S>D -> -2 -1 }
{> MIN-INT S>D -> MIN-INT -1 }
{> MAX-INT S>D -> MAX-INT 0 }

{> 0 0 M* -> 0 S>D }
{> 0 1 M* -> 0 S>D }
{> 1 0 M* -> 0 S>D }
{> 1 2 M* -> 2 S>D }
{> 2 1 M* -> 2 S>D }
{> 3 3 M* -> 9 S>D }
{> -3 3 M* -> -9 S>D }
{> 3 -3 M* -> -9 S>D }
{> -3 -3 M* -> 9 S>D }
{> 0 MIN-INT M* -> 0 S>D }
{> 1 MIN-INT M* -> MIN-INT S>D }
{> 2 MIN-INT M* -> 0 1S }
{> 0 MAX-INT M* -> 0 S>D }
{> 1 MAX-INT M* -> MAX-INT S>D }
{> 2 MAX-INT M* -> MAX-INT 1 LSHIFT 0 }
{> MIN-INT MIN-INT M* -> 0 MSB 1 RSHIFT }
{> MAX-INT MIN-INT M* -> MSB MSB 2/ }
{> MAX-INT MAX-INT M* -> 1 MSB 2/ INVERT }

{> 0 0 * -> 0 }                          \ Test identities
{> 0 1 * -> 0 }
{> 1 0 * -> 0 }
{> 1 2 * -> 2 }
{> 2 1 * -> 2 }
{> 3 3 * -> 9 }
{> -3 3 * -> -9 }
{> 3 -3 * -> -9 }
{> -3 -3 * -> 9 }

{> MID-UINT+1 1 RSHIFT 2 * -> MID-UINT+1 }
{> MID-UINT+1 2 RSHIFT 4 * -> MID-UINT+1 }
{> MID-UINT+1 1 RSHIFT MID-UINT+1 OR 2 * -> MID-UINT+1 }

{> 0 0 UM* -> 0 0 }
{> 0 1 UM* -> 0 0 }
{> 1 0 UM* -> 0 0 }
{> 1 2 UM* -> 2 0 }
{> 2 1 UM* -> 2 0 }
{> 3 3 UM* -> 9 0 }

{> MID-UINT+1 1 RSHIFT 2 UM* -> MID-UINT+1 0 }
{> MID-UINT+1 2 UM* -> 0 1 }
{> MID-UINT+1 4 UM* -> 0 2 }
{> 1S 2 UM* -> 1S 1 LSHIFT 1 }
{> MAX-UINT MAX-UINT UM* -> 1 1 INVERT }

