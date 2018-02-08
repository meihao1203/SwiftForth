{ ====================================================================
Fast CRC-16 calculation.

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL CRC16

{ ---------------------------------------------------------------------
Table-driven CRC-16

Poly describes the CRC polynomial x**16 + x**15 + x**2 + 1 .
Bits in Poly are reversed due to transmission order.

CRC takes address and length of string.  Returns CRC and ending address.
The 16-bit CRC is returned in transmission order for this little-endian
CPU (the low byte of the 16-bit value is transmitted first).

Usage:  a n CRC W!  (before sending a buffer)
        a n CRC W@ = (test the received CRC)
--------------------------------------------------------------------- }

CREATE 'CRC  512 ALLOT

$A001 CONSTANT Poly

: >CRC ( c - n)   8 0 DO  2 /MOD  SWAP NEGATE
   Poly AND XOR  LOOP ;

: /CRC   256 0 DO  I >CRC  I 2* 'CRC + W!  LOOP ;

/CRC

CODE CRC ( c-addr1 u1 -- u2 c-addr2)
   EBX ECX MOV   0 [EBP] EBX MOV   $FFFF # EAX MOV
   ECXNZ IF   BEGIN   0 [EBX] EDX MOVZX   EBX INC
      AL DL XOR   AL AL XOR   AH AL XCHG   'CRC [EDX] [EDX] AX XOR
   LOOP   THEN   EAX 0 [EBP] MOV   RET   END-CODE
