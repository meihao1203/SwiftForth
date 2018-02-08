{ ====================================================================
Savage floating point benchmark.

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL SAVAGETEST A reputedly savage floating point benchmark

{ --------------------------------------------------------------------
The Forth implementation is attributed to Julian Noble
-------------------------------------------------------------------- }

REQUIRES fpmath

2500 VALUE MaxLoop

: (SAVAGE)	\ F: <> --- <r>
	1e
	MaxLoop 1- 0	( Do 2499 times for result of 2500 )
	 ?DO
	    FDUP F* FSQRT 	\ 93 ms, zero error
	    FLN   FEXP
	    FATAN FTAN 		\ most errors are in here !!
	    #1.0E F+
	LOOP ;


: SAVAGE
	CR ." Testing . . " COUNTER
	0e  100 0 DO FDROP (SAVAGE) LOOP
        TIMER ." ms for 100 iterations" ;



CR
CR .( Type SAVAGE to test the floating point speed)
CR





