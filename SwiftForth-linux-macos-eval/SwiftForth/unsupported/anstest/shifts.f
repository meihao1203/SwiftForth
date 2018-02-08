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

Dependencies: {> -> } { {{ TESTING 0S 1S

Exports: MSB

===================================================================== }

HEX

TESTING 2* 2/ LSHIFT RSHIFT

\ We trust 1S, INVERT, and BITSSET?; we will confirm RSHIFT later
1S 1 RSHIFT INVERT CONSTANT MSB
{> MSB BITSSET? -> 0 0 }

{> 0S 2* -> 0S }
{> 1 2* -> 2 }
{> 4000 2* -> 8000 }
{> 1S 2* 1 XOR -> 1S }
{> MSB 2* -> 0S }

{> 0S 2/ -> 0S }
{> 1 2/ -> 0 }
{> 4000 2/ -> 2000 }
{> 1S 2/ -> 1S }                         \ Msb propogated
{> 1S 1 XOR 2/ -> 1S }
{> MSB 2/ MSB AND -> MSB }

{> 1 0 LSHIFT -> 1 }
{> 1 1 LSHIFT -> 2 }
{> 1 2 LSHIFT -> 4 }
{> 1 F LSHIFT -> 8000 }                  \ Biggest guaranteed shift
{> 1S 1 LSHIFT 1 XOR -> 1S }
{> MSB 1 LSHIFT -> 0 }

{> 1 0 RSHIFT -> 1 }
{> 1 1 RSHIFT -> 0 }
{> 2 1 RSHIFT -> 1 }
{> 4 2 RSHIFT -> 1 }
{> 8000 F RSHIFT -> 1 }                  \ Biggest
{> MSB 1 RSHIFT MSB AND -> 0 }           \ RSHIFT zero fills msbs
{> MSB 1 RSHIFT 2* -> MSB }

