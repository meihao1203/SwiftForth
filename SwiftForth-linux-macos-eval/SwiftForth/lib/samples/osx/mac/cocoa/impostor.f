{ ====================================================================
Keep Forth running

Copyright (C) 2015-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
Move Forth to another thread
Last: 9 Oct 2015 20:26:10 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Run Forth in another task (thread), pretending to be OPERATOR.
The IMPOSTOR task will pretend to be OPERATOR.
OPERATOR will not maintain the dictionary when, for instance, running
Cocoa, it's the IMPOSTOR's job:
<OPERATOR'S> -- inherit these USER variables from OPERATOR.

Other threads and callbacks which compile/interpret need to sync
with IMPOSTOR:
<SYNC -- behave like IMPOSTOR, copy relevant USER variables.
SYNC> -- make sure everything changed in dictionary and runtime is
relayed to IMPOSTOR.

IMPOSTOR'S -- like OPERATOR"S but set current personality to IMPOSTOR'S
Most if not all references to OPERATOR'S should be replaced by
IMPOSTOR'S in coco-sf.

'PRETENDING -- execution vector used by the coco-sf startup word.
Can be used as a hook for extra initialisation.
PRETENDING -- activate and run the IMPOSTOR task.

--  executing GILD will make sure new Forth thread can prune
	if this gives problems, run GILD manualy after QUIT is running
--  some cocoa stuff invoked from Forth thread need an autorelease pool
--  new Forth thread uses Operator's I/O settings

-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ IMPOSTOR task and behaviours.

#USER 100 CELLS + TASK IMPOSTOR  \ stay safe for now with allocated user area

: <OPERATOR'S> ( -- )
	OPERATOR HLIM HIS @ HLIM !
	OPERATOR H HIS @ H !
	OPERATOR FENCE HIS @ FENCE !
	OPERATOR 'EMPTY HIS @ 'EMPTY !
	OPERATOR #ORDER HIS #ORDER [ 3 #VOCS + CELLS ] LITERAL MOVE
	OPERATOR'S
\	OPERATOR HLIM HIS  HLIM  #USER HLIM STATUS - - MOVE
;

: <SYNC ( -- )
	IMPOSTOR HLIM HIS @ HLIM !
	IMPOSTOR H HIS @ H !
	IMPOSTOR FENCE HIS @ FENCE !
	IMPOSTOR 'EMPTY HIS @ 'EMPTY !
	IMPOSTOR #ORDER HIS #ORDER [ 3 #VOCS + CELLS ] LITERAL MOVE
	IMPOSTOR 'PERSONALITY HIS @ 'PERSONALITY !
\	IMPOSTOR HLIM HIS  HLIM   #USER HLIM STATUS - -  |CB-USER| MIN  MOVE
;

: SYNC> ( -- )
	HLIM @ IMPOSTOR HLIM HIS !
	H @ IMPOSTOR H HIS !
	FENCE @ IMPOSTOR FENCE HIS !
	'EMPTY @ IMPOSTOR 'EMPTY HIS !
	#ORDER IMPOSTOR #ORDER HIS [ 3 #VOCS + CELLS ] LITERAL MOVE
	'PERSONALITY @ IMPOSTOR 'PERSONALITY HIS !
\	HLIM  IMPOSTOR HLIM HIS   #USER HLIM STATUS - -  |CB-USER| MIN  MOVE
;

: IMPOSTOR'S ( -- )
   IMPOSTOR 'PERSONALITY HIS @ 'PERSONALITY ! ;

\ --------------------------------------------------------------------
\ setup IMPOSTOR running Forth.

VARIABLE 'PRETENDING   \ execution vector
VARIABLE SF.POOL       \ caching autoreleasepool from Forth thread.

: PRETENDING ( -- )
	IMPOSTOR ACTIVATE
		ALLOCPOOL SF.POOL !
		<OPERATOR'S>
		GILD S" REMEMBER ?!?!?" EVALUATE EMPTY	( hack, make sure PRUNE and friends behave )
		'PRETENDING @EXECUTE ;

\\ ( eof)