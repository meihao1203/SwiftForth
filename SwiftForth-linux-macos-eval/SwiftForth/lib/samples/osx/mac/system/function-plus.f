{ ====================================================================
Extended FUNCTION:

Copyright (c) 2014-2017 Roelf Toxopeus

Spotting foreign functions returning 2 values.
Last: 15 November 2017 at 09:39:37 CEST  -rt
==================================================================== }

/FORTH
DECIMAL

{ --------------------------------------------------------------------
Optional extensions

Redefining FUNCTION: to signal foreign functions returning 2 parameters.
Debug help ;-)

.CALL-OUTPUT prints #outputs last defined foreign function
.OUTPUT-WARNING-CALLS flags 2 parameters passing functions
-------------------------------------------------------------------- }

CR .( adding debuging FUNCTION:)
LIB-INTERFACE +ORDER
: .CALL-OUTPUT ( -- )
   >IN @ BL WORD COUNT CR TYPE >IN ! SPACE #RETURN @ ." function call returns " . ;

: .OUTPUT-WARNING-CALLS ( -- )
	#RETURN @ DUP 2 = SWAP 0 = OR IF BRIGHT .CALL-OUTPUT NORMAL THEN ;

: FUNCTION: ( -- )   PARAMETERS() .OUTPUT-WARNING-CALLS _IMPORT: ;
PREVIOUS

\\ ( eof)