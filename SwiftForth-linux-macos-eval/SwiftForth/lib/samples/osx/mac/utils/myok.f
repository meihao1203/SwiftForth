{ ====================================================================
Mach2 prompt

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
OK prompt with stacks depth, a la Mach2 from the Palo Alto Shipping Co.
Last: 31 January 2013 07:22:10 CET     -rt
==================================================================== }

{ --------------------------------------------------------------------
BASEID -- return a one char string pair with base identifier.
STACKDEPTH -- return stack depth as string pair.
FSTACKDEPTH -- return numeric stack depth as string pair.
M2PROMPT -- display a Mach2 prompt:  ok <0>
/OK -- save current prompt and set Mach2 prompt.
-OK -- set saved prompt.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: BASEID ( -- a n )
	BASE @ DUP 10 = IF DROP S" "  EXIT THEN
	       DUP 16 = IF DROP S" $" EXIT THEN
	       DUP  8 = IF DROP S" &" EXIT THEN
	            2 = IF      S" %" EXIT THEN
	                        S" ?" ;
	
: STACKDEPTH ( -- a n )   DEPTH S>D <# #S #> ;

: .M2STACK ( -- )
	POCKET >R
	S" <"      R@ PLACE
	BASEID     R@ APPEND
	STACKDEPTH R@ APPEND
	S" >"      R@ APPEND
	R> COUNT TYPE ;
	
: FSTACKDEPTH ( -- a n )   FDEPTH S>D <# #S #> ;

: .M2FSTACK ( -- )
	POCKET >R
	S" ["     R@ PLACE
	BASEID      R@ APPEND
	FSTACKDEPTH R@ APPEND
	S" ]"       R@ APPEND
	R> COUNT TYPE ;

: M2PROMPT ( -- )
	STATE @ 0= IF
		."  ok" SPACE
		.M2STACK
		FDEPTH IF SPACE .M2FSTACK THEN
		CR
	THEN ;
   
: OK   POSTPONE \ ; IMMEDIATE

VARIABLE 'OK

: /OK
	['] PROMPT >BODY @ DUP ['] M2PROMPT = IF DROP EXIT THEN
	'OK !
	['] M2PROMPT IS PROMPT ;

: -OK   'OK @ ?DUP IF IS PROMPT THEN ;


cr .( Mach2 like prompt loaded...)
cr .( /ok -- set Mach2 prompt)
cr .( -ok -- set previous prompt)


\\ ( eof )