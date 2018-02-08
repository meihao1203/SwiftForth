{ ====================================================================
Parallel execution

Copyright (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
Using Grand Central Dispatch concurrent queue's and the GCD group
calls to implement a suggested FORK JOIN CONTINUE.
Last: 23 Aug 2015 21:07:04 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
DISPATCH-GROUP -- dispatch n cb's on a concurrent queue as a group.
Return the group for further usage.
JOIN-GROUP -- wait for given group to finish.

FORK JOIN CONTINUE -- process words between FORK and JOIN/CONTINUE to
run in parallel when definition under construction is run.
JOIN waits till forked group has finished.
CONTINUE does not wait.

FORK? -- flags if given xt is allowed to be forked. In essence a stopper
for the FORK JOIN/CONTINUE pairs.

Note: in SwiftForth ' doesn't work over linebreaks, because of WORD.
	  Use NEXTWORD FIND HUH? to compensate in FORK.

The FORK JOIN pair is similar to tForth's PAR END-PAR

Example usage:

: FOTO-FUN ( -- )
	GET-IMAGE
	FORK
	 DO-RED DO-GREEN DO-BLUE DO-ALPHA
	JOIN
	SHOW-IMAGE ;
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ GCD group calls

FUNCTION: dispatch_group_create ( -- group )

FUNCTION: dispatch_group_async_f ( group queue *context 'cb -- ret )   

\ Note: dispatch_time_t is 64bit, so pass it as a Forth double in 32bit SF !!!!!!!!!!!!!!!!!
FUNCTION: dispatch_group_wait ( group time:lo time:hi -- ret:long )

FUNCTION: dispatch_release ( dispatch-object -- ret )

0 INVERT S>D 2CONSTANT DISPATCH_TIME_FOREVER   \   #define DISPATCH_TIME_FOREVER (~0ull) 

: (DISPATCH-GROUP) ( cb group -- )   SWAP >R PARALLELQUEUE 0 R> dispatch_group_async_f DROP ;

: DISPATCH-GROUP ( cb1 ... cbn n -- group )   
	dispatch_group_create SWAP 0 ?DO  TUCK (DISPATCH-GROUP) LOOP ;
		
: JOIN-GROUP ( group -- )  DUP DISPATCH_TIME_FOREVER dispatch_group_wait DROP dispatch_release DROP ;

\ --------------------------------------------------------------------
\ FORK API

: COMPILE-CBS ( cb1 ... cbn n -- )   0 ?DO POSTPONE LITERAL LOOP ;

: JOIN ( cb1 ... cbn n -- )  DUP >R COMPILE-CBS R> POSTPONE LITERAL POSTPONE DISPATCH-GROUP POSTPONE JOIN-GROUP ; IMMEDIATE

: CONTINUE ( cb1 ... cbn n -- )  DUP >R COMPILE-CBS R> POSTPONE LITERAL POSTPONE DISPATCH-GROUP POSTPONE dispatch_release POSTPONE DROP ; IMMEDIATE

: FORK? ( xt -- flag )   DUP ['] JOIN <> SWAP ['] CONTINUE <> AND ;

LIB-INTERFACE +ORDER
: FORK ( <text> -- cb1 ... cbn n ) \ should use compile only, can't be bothered now.
	0
	BEGIN
		NEXTWORD FIND HUH?  DUP FORK?
	WHILE
		POSTPONE AHEAD >R     \ create callback pointers and skip over them
		HERE RUNCB ,CALL SWAP ( xt) ,
		R> POSTPONE THEN
		SWAP 1+								  \ collect cb pointers and bump total
	REPEAT
	EXECUTE ; IMMEDIATE
PREVIOUS

\ --------------------------------------------------------------------
\ PAR API

: END-PAR ( cb1 ... cbn n -- )   POSTPONE JOIN ; IMMEDIATE

LIB-INTERFACE +ORDER
: PAR ( <text> -- ) 
	0
	BEGIN
		NEXTWORD FIND HUH?  DUP ['] END-PAR <>    ( differs here from FORK )
	WHILE
		POSTPONE AHEAD >R     \ create callback pointers and skip over them
		HERE RUNCB ,CALL SWAP ( xt) ,
		R> POSTPONE THEN
		SWAP 1+								  \ collect cb pointers and bump total
	REPEAT
	EXECUTE ; IMMEDIATE
PREVIOUS

\\ ( eof )

\ simple test:

variable accu
: bump1 ( -- )   1 accu +!  500 ms impostor's cr ." nr.1 done" ;
: bump2 ( -- )   1 accu +!  869 ms impostor's cr ." nr.2 done" ;
: bump3 ( -- )   1 accu +! 1200 ms impostor's cr ." nr.3 done" ;
: bump4 ( -- )   1 accu +! 1700 ms impostor's cr ." nr.4 done" ;

: tt ( -- )
	accu off
	par
	  bump1
	  bump2
	  bump3
	  bump4
	end-par
   cr ." accu ? " accu ? ;

{ --------------------------------------------------------------------
More interesting is filling a memory range.
Do it serialy in one go, or divide it up and hand them over to different
tasks/threads/cores running in parallel.

Note: run the first executed test twice, this causes mem to be cached.
Improves bench time considerately. I need to do something about this
cache business. Specialy for short bursts of memory access.
-------------------------------------------------------------------- }

\ --------------------------------------------------------------------
\ One task does all the work in one go.

6000000 CONSTANT /MEM   \ buffer for dfloats, depends on UNUSED

/MEM BUFFER: MEM
: .MEM ( -- )   MEM 100 DUMP  MEM /MEM + 80 - 100 DUMP ;

variable accu
\ : WORK ( addr u -- )   2DUP ERASE BLANK ;
\ : WORK ( addr u -- )   2DUP ERASE  0 DO RANDOM OVER I + C! LOOP DROP ;
: WORK ( addr u -- )   0 DO  I S>F FDUP F* DUP I + DF!  [ 1 DFLOATS ] LITERAL ( 1 accu +!) +LOOP DROP ; 
: FILLMEM ( -- )   MEM /MEM  WORK ;

: FF ( -- )
	CR ." ff not dispatching, just 1 task, "
	COUNTER FILLMEM TIMER ." MS elapsed" ;

\ --------------------------------------------------------------------
\ Using dispatchgroup for 4 parallel execution jobs

/MEM 4 / CONSTANT MEM/4
MEM          CONSTANT MEM1
MEM1 MEM/4 + CONSTANT MEM2
MEM2 MEM/4 + CONSTANT MEM3
MEM3 MEM/4 + CONSTANT MEM4

: FILLMEM1 ( -- )   ( impostor's ." 1 starts ... ") 8 FSTACK MEM1 MEM/4 WORK ( ." 1 done!") ;
: FILLMEM2 ( -- )   ( impostor's ." 2 starts ... ") 8 FSTACK MEM2 MEM/4 WORK ( ." 2 done!") ;
: FILLMEM3 ( -- )   ( impostor's ." 3 starts ... ") 8 FSTACK MEM3 MEM/4 WORK ( ." 3 done!") ;
: FILLMEM4 ( -- )   ( impostor's ." 4 starts ... ") 8 FSTACK MEM4 MEM/4 WORK ( ." 4 done!") ;

: FF2 ( -- )
   CR ." ff2, using dispatch_group for 4 jobs, "
	COUNTER
	FORK FILLMEM1 FILLMEM2 FILLMEM3 FILLMEM4 JOIN
   TIMER ." MS elapsed" ;

\ --------------------------------------------------------------------
\ testing them twice in a row, shows timing improvements...

\ FF FF
\ FF2 FF2

\ --------------------------------------------------------------------
\ View cores, use Activity Monitor with CPU History and CPU Usage
\ windows open.

: DD ( -- )
	CR ." dd not dispatching, just 1 task."
	CR ." any key stops..."
	BEGIN  FILLMEM  KEY? UNTIL ;

: DD2 ( -- )
   CR ." dd2, using dispatch_group for 4 jobs."
	CR ." any key stops..."
	BEGIN
		FORK
	  		FILLMEM1 FILLMEM2 FILLMEM3 FILLMEM4
		JOIN
   KEY? UNTIL ;

\ Same as above but counting how often in 10 seconds
variable accu
: PP ( -- )
	accu off
	CR ." pp not dispatching, just 1 task. 10 seconds: "
	counter 10000 +
	BEGIN  FILLMEM  1 accu +!  dup expired UNTIL drop accu ? ;

: PP2 ( -- )
	accu off
   CR ." pp2, using dispatch_group for 4 jobs. 10 seconds: "
	counter 10000 +
	BEGIN
		FORK
	  		FILLMEM1 FILLMEM2 FILLMEM3 FILLMEM4
		JOIN
     1 accu +!  dup expired UNTIL drop accu ? ;

(*
Snow Leopard 10.6.8
ff ff ff 
ff not dispatching, just 1 task, 16 MS elapsed
ff not dispatching, just 1 task, 11 MS elapsed
ff not dispatching, just 1 task, 11 MS elapsed ok
ff2 ff2 ff2 
ff2, using dispatch_group for 4 jobs, 11 MS elapsed
ff2, using dispatch_group for 4 jobs, 6 MS elapsed
ff2, using dispatch_group for 4 jobs, 6 MS elapsed ok

dd   Activity Monitor CPU Usage window, shows mostly 1 Core active, alternates slowly.
dd2  Activity Monitor CPU Usage window, shows 4 Cores active.

pp
pp not dispatching, just 1 task. 10 seconds: 819  ok
pp2 
pp2, using dispatch_group for 4 jobs. 10 seconds: 1803  ok
Note: regarding PP, see DD wrt core usage

Yosemite, 10.10.3
ff ff ff                                         
ff not dispatching, just 1 task, 16 MS elapsed
ff not dispatching, just 1 task, 11 MS elapsed
ff not dispatching, just 1 task, 13 MS elapsed ok
ff2 ff2 ff2 
ff2, using dispatch_group for 4 jobs, 11 MS elapsed
ff2, using dispatch_group for 4 jobs, 6 MS elapsed
ff2, using dispatch_group for 4 jobs, 5 MS elapsed ok

dd   Activity Monitor CPU Usage window, shows 1 and 2 Cores active. Cores alternate much faster than on Snow Leopard.!
dd2  Activity Monitor CPU Usage window, shows 4 Cores active.

pp 
pp not dispatching, just 1 task. 10 seconds: 820  ok
pp2 
pp2, using dispatch_group for 4 jobs. 10 seconds: 1754  ok
Note: regarding PP, see DD wrt core usage
*)

(*
testing hyperthreading ( turn it on/off with/Xcode/Contents/Applications/instruments -> preferences)

ON
ff 
ff not dispatching, just 1 task, 27 MS elapsed ok
ff 
ff not dispatching, just 1 task, 27 MS elapsed ok
ff 
ff not dispatching, just 1 task, 27 MS elapsed ok

OFF
ff 
ff not dispatching, just 1 task, 21 MS elapsed ok
ff 
ff not dispatching, just 1 task, 21 MS elapsed ok
ff 
ff not dispatching, just 1 task, 21 MS elapsed ok

ON
ff2 
ff2, using dispatch_group for 4 jobs, 13 MS elapsed ok
ff2                                                                             
ff2, using dispatch_group for 4 jobs, 12 MS elapsed ok
ff2                                                                             
ff2, using dispatch_group for 4 jobs, 12 MS elapsed ok

OFF
ff2 
ff2, using dispatch_group for 4 jobs, 14 MS elapsed ok
ff2                                                                             
ff2, using dispatch_group for 4 jobs, 15 MS elapsed ok
ff2                                                                             
ff2, using dispatch_group for 4 jobs, 15 MS elapsed ok

ON
pp 
pp not dispatching, just 1 task. 10 seconds: 626  ok
pp                                                                              
pp not dispatching, just 1 task. 10 seconds: 626  ok

OFF
pp 
pp not dispatching, just 1 task. 10 seconds: 632  ok
pp                                                                              
pp not dispatching, just 1 task. 10 seconds: 632  ok

ON
pp2 
pp2, using dispatch_group for 4 jobs. 10 seconds: 1337  ok
pp2                                                                             
pp2, using dispatch_group for 4 jobs. 10 seconds: 1319  ok

OFF
pp2                                                                             
pp2, using dispatch_group for 4 jobs. 10 seconds: 1192  ok
pp2                                                                             
pp2, using dispatch_group for 4 jobs. 10 seconds: 1163  ok

*)

\\