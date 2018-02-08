{ ====================================================================
Floating point package configuration utility (stub)

Copyright (C) 2008 FORTH, Inc.  All rights reserved

This is a stub for now.  Default values are supplied here.
==================================================================== }

OPTIONAL FPCONFIG Floating point math configuration utility

{ --------------------------------------------------------------------
FP options

'FPOPT has FPU options.  The FPU control word field has this format:

Bits[15:13]     Reserved
Bit[12]         Infinity control
                0 = Both -infinity and +infinity are treated as unsigned infinity
                1 = Respects both -infinity and +infinity
Bits[11:10]     Rounding mode
                00 = Round to nearest, or to even if equidistant
                01 = Round down (toward -infinity)
                10 = Round up (toward +infinity)
                11 = Truncate (toward 0)
Bits[9:8]       Precision control
                00 = 24 bits (REAL4)
                01 = Not used
                10 = 53 bits (REAL8)
                11 = 64 bits (REAL10)
Bits[7:6]       Reserved
Bit [5]         Precision Mask
Bit [4]         Underflow Mask
Bit [3]         Overflow Mask
Bit [2]         Zero divide Mask
Bit [1]         Denormalized operand Mask
Bit [0]         Invalid operation Mask

Set mask bit to 1 to ignore corresponding exception.
-------------------------------------------------------------------- }

CREATE 'FPOPT
    TRUE C,     \ Softare stack
    TRUE C,     \ WAIT for exceptions
    $F22 H,     \ FPU Control word
       8 C,     \ PRECISION significant digits (1-17)
    ," FIX"     \ FIX SCI or ENG output format
