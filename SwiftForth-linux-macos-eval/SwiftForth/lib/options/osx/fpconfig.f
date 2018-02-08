{ ====================================================================
Floating point package configuration utility (stub)

Copyright (C) 2008 FORTH, Inc.  All rights reserved

This is a stub for now.  Default values are supplied here.
==================================================================== }

OPTIONAL FPCONFIG Floating point math configuration utility

{ --------------------------------------------------------------------
FP options
-------------------------------------------------------------------- }

CREATE 'FPOPT
    TRUE C,     \ Softare stack
    TRUE C,     \ WAIT for exceptions
    $F22 H,     \ FPU Control word
       8 C,     \ PRECISION significant digits (1-17)
    ," FIX"     \ FIX SCI or ENG output format
