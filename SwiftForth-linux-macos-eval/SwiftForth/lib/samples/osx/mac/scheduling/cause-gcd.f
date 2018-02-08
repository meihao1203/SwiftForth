{ =================================================================================================
	Schedule word
	
	SwiftForth version

	Copyright (C) 2016-2017 Roelf Toxopeus
	
	GCD CAUSE version
	Last: 26 Oct 2016 10:29:01 CEST  -rt
================================================================================================= }

{ -------------------------------------------------------------------------------------------------
  CAUSE originates at STEIM (c) Frank Balde 1986. Based on words written by R.Kuivila and D.Anderson
  in Forthmacs.
  Rather than creating an irq-server like in the original CAUSE implementations, GCD is used to
  cause an action in the future. The GCD dispatch_after_f function is central to the planning.
  
  FROM-NOW - create a 64bit dispatch time using the walltime plus given nanoseconds in the future
  CAUSE - schedule a Forth word (xt) to a given time from now, using milliseconds as default.
  Can be used for a one shot timer! See the special RECURSIVE examples at the end reagrding
  scheduling yourself in again.
  Uses the DEFAULTQUEUE for dispatch

  Because the dispatch routines use nanoseconds, there are some conversion words:
  S>NANO converts seconds to nanoseconds
  MS>NAN converts milliseconds to nanoseconds
  US>NAN converts microseconds to nanoseconds
  These nanoseconds are 2 cell values on 32b Forth systems!
  
  Note: this version of CAUSE is based on AFTER as defined in test-after-gcd.f
  Difference is addition of context parameter and usage of an xt rather than a callback pointer.
  The stack picture for original CAUSE ( par ticks xt -- ), with tick unit, user defined, driving
  the irq server with a beat or pulse (originaly the midi clock on Atari ST's).
  
  Activating or dispatching a task starting with nanosleep is not what GCD does.
  0 TASK PIPO   : HAIL ( -- )   PIPO ACTIVATE 6000 MS IMPOSTOR'S ." ahoi ahoi" ; HAIL
  has the same result as
  : HAIL ( -- )   IMPOSTOR'S ." ahoi ahoi" ;   0 6000 ' HAIL CAUSE
  but is executed differently.
  Activity Monitor shows for CAUSE, a workthread is spawned at the time of action, not before
  and sleeping till moment of action as in the TASK version.
  
  Perhaps for heavy load and strict realtime requirements, a sleeping task, woken at the right
  time and executing a defered word and go to sleep again, is a better approach.
    
------------------------------------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: dispatch_after_f ( when:lo when:hi queue *context work -- ret )
FUNCTION: dispatch_walltime ( *timespec delta:lo delta:hi -- dispatch_time_t:lo dispatch_time_t:hi )

: S>NANO  ( n -- d )   1000000000 M* ;
: MS>NANO ( n -- d )   1000000 M* ;
: US>NANO ( n -- d )   1000 M* ;

: FROM-NOW ( interval:lo interval:hi -- dispatch-time:lo dispatch-time:hi )   0 -ROT  dispatch_walltime ( 2RET> ) ;

DEFER (CAUSE)
CALLBACK: *CAUSE ( n -- )   _PARAM_0 (CAUSE) ;

: CAUSE ( param when:ms xt -- )
			IS (CAUSE) SWAP >R MS>NANO FROM-NOW DEFAULTQUEUE R> *CAUSE dispatch_after_f DROP ;

\\ ( eof )

\ example
variable var
: bump ( -- )  recursive  var dup @ 10 < if  1 swap +! 0 6000 ['] bump cause  then ;
0 6000 ' bump cause
var ? 8  ok
var ? 10  ok                                     
var ? 10  ok                                     
var ? 10  ok  

