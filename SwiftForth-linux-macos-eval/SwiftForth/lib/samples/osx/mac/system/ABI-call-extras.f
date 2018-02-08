{ ====================================================================
ABI call extra's

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version
Extra words wrt Mac OSX function call ABI
Last: 27 February 2014 06:45:08 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
2RET> and >2RET are used with passing POINTs, SIZEs, RANGEs etc.
2RET> is part of SwiftForth now, so commented out.
FUNCTION: and COCOA: take care of the output parameters doing 2RET> depending
on the parameterlist passed along.
Example:   COCOA: @mouseLocation ( -- x y )

>2RET is used when a callback has to leave/pass two parameters.
Example:  the textView:willChangeSelectionFromCharacterRange:toCharacterRange:
			callback leaves a range: location and length
See:
http://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/LowLevelABI/130-IA-32_Function_Calling_Conventions/IA32.html%23//apple_ref/doc/uid/TP40002492-SW4
-------------------------------------------------------------------- }

\ --------------------------------------------------------------------

/FORTH
DECIMAL

(* in kernel now
ICODE 2RET> ( n -- n n2 )
	[COMPILE] DUP
	EDX EBX MOV				\ Retrieve second return from EDX
	RET END-CODE
*)

ICODE >2RET ( n -- )
	EBX EDX MOV				\ Pass a (second) item through EDX
	[COMPILE] DROP
	RET END-CODE

CR .( Extra utils for function call ABI loaded)

\\ ( eof )