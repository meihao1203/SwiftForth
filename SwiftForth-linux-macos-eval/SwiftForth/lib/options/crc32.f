{ ====================================================================
CRC-32 calculation.

Copyright 2007  FORTH, Inc.
==================================================================== }

OPTIONAL CRC32

{ ---------------------------------------------------------------------
CRC32 calculation

This file implements CRC32 calculation using the IEEE 802.3 polynomial:
   x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1

CRC32 takes the address and length of a region of target memory over
which to run the CRC32 calculation.  Returns the result as a 32-bit
value.

Poly32 is the bit-reversed representation of the IEEE 802.3 CRC32
polynomial.  This optimization allows us to read, xor, and right shift
each byte without bit reversing it.
--------------------------------------------------------------------- }

$EDB88320 CONSTANT Poly32               \ Bit-reversed polynomial

: CRC32 ( addr u1 -- u2 )
   -1 -ROT OVER + SWAP ?DO  I C@ XOR
      8 0 DO  DUP 1 AND 0<> Poly32 AND
         SWAP 1 RSHIFT XOR
   LOOP LOOP  INVERT ;
