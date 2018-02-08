{ ====================================================================
Timers using GCD dispatch queues

Copyright (C) 2014-2017 Roelf Toxopeus

SwiftForth version
Allows many independant timers, simple interface!
Last: 3 Nov 2016 13:09:44 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
For all the imported functions, see:
  usr/include/dispatch/*.h
  Apple's GCD_libdispatch_Ref
  Apple's Concurrency Programming Guide

Note: example of a GLOBAL: defined reference without using @ on it.
The external name of C objects in the UNIX world is the name with an underscore
prepended, here _dispatch_source_type_timer.
Thanks Mitch Bradley!

DISPATCH_SOURCE_TYPE_TIME a pointer to a constant (&_dispatch_source_type_timer)
defining a timer dispatch source type. Used for creating timers.

DISPATCH_TIME_NOW a 64b time constant indicating 'now', used by GCD dispatch functions.

Because the dispatch routines use nanoseconds, there are some conversion words:
S>NANO converts seconds to nanoseconds
MS>NAN converts milliseconds to nanoseconds
US>NAN converts microseconds to nanoseconds
These nanoseconds are 2 cell values on 32b Forth systems!
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: dispatch_source_create ( *type handle mask queue -- source )
FUNCTION: dispatch_time ( when:lo when:hi delta:lo delta:hi -- dispatch_time_t:lo dispatch_time_t:hi )
FUNCTION: dispatch_source_set_timer ( source start:lo start:hi interval:lo interval:hi leeway:lo leeway:hi -- ret )
FUNCTION: dispatch_source_set_event_handler_f ( source handler -- ret )
FUNCTION: dispatch_resume ( object -- ret )
FUNCTION: dispatch_source_cancel ( source -- ret )
FUNCTION: dispatch_release ( object -- ret )

\ don't fetch this one, we need a pointer
GLOBAL: _dispatch_source_type_timer

: DISPATCH_SOURCE_TYPE_TIMER ( -- addr )  _dispatch_source_type_timer ;

0 DUP 2CONSTANT DISPATCH_TIME_NOW

: S>NANO  ( n -- d )   1000000000 M* ;
: MS>NANO ( n -- d )   1000000 M* ;
: US>NANO ( n -- d )   1000 M* ;

{ --------------------------------------------------------------------
CREATE-TIMER creates a GCD dispatch timer. You need to initialise it before
it can be dispatched. A Timer type has 0 for the handle and mask parameters,
until further notice from Apple.
Could try parallelqueue for hi-priority.

TIME-NOW returns dispatch time in nanoseconds, meaning do it now.
The default clock is based on mach_absolute_time.
Using 0 0 delta parameter for now, start immediately.

FROM-NOW returns dispatch time in nanoseconds _after_ given ms from TIME-NOW

LEEWAY is a 64b variable containing the allowed leeway for the timer. Assuming
most of the time you want it as accurate as possible, a default value of 1 nanosecond
is used. This so you won't be bothered to pass a leeway parameter along. You can
set it to a preferred value with  <double:nanoseconds> LEEWAY 2!
Do this before you execute NEW-TIMER or LOAD-TIMER.

LOAD-TIMER will prepare the given timer for duty. Interval and eventhandler
are set. Afterwards the leeway parameter is reset to a default 1 nanosecond,
just in case a custom value was used.

NEW-TIMER creates a GCD dispatch timer, initialised and ready to run. It starts
in suspended state. The interval parameter is in milliseconds. The callback is
a Forth callback, run when the timer fires.

START-TIMER will start a suspended timer. Room for additions.

STOP-TIMER stops and removes a timer. Room for additions.
-------------------------------------------------------------------- }

: CREATE-TIMER ( -- timer )   DISPATCH_SOURCE_TYPE_TIMER 0 0 DEFAULTQUEUE dispatch_source_create ;

: TIME-NOW ( -- dispatch-time:lo dispatch-time:hi )   DISPATCH_TIME_NOW 0 DUP dispatch_time ;

: FROM-NOW ( ms -- dispatch-time:lo dispatch-time:hi )   TIME-NOW ROT MS>NANO dispatch_time ;

2VARIABLE LEEWAY
: /LEEWAY ( -- )   1  MS>NANO LEEWAY 2! ;
/LEEWAY

: LOAD-TIMER ( cb interval timer -- )
	SWAP >R
	DUP R@ FROM-NOW  R> MS>NANO  LEEWAY 2@  dispatch_source_set_timer DROP
	/LEEWAY
	SWAP dispatch_source_set_event_handler_f DROP ;

: NEW-TIMER ( cb interval -- timer )
	CREATE-TIMER DUP 0= ABORT" No Timer Source !"
	DUP >R LOAD-TIMER R> ;

: START-TIMER ( timer -- )  dispatch_resume DROP ;

: STOP-TIMER ( timer -- )  DUP dispatch_source_cancel DROP  dispatch_release DROP ;

\\

\ --- examples:

callback: *greet ( -- )   impostor's cr ." hoi" ;
*greet 5000 new-timer dup value mt start-timer

mt stop-timer

\ ---

variable accu
: bump ( -- )  1 accu +! ;
' bump 0 cb: *bump

variable mytimer

: tt ( -- )   *bump 250 new-timer dup mytimer ! start-timer ;

: ss ( -- )   mytimer @ stop-timer ;

: xx ( -- )  accu off tt counter 4999 ms ss timer accu ? ;

: bump2 ( -- )  10 accu +! ;
' bump2 0 cb: *bump2

variable mytimer2

: tt2 ( -- )   *bump2 1000 new-timer dup mytimer2 ! start-timer ;

: ss2 ( -- )   mytimer2 @ stop-timer ;

: xx2 ( -- )  accu off tt2 counter 4999 ms ss2 timer accu ? ;

: yy ( -- )   accu off tt tt2 counter 4999 ms ss ss2 timer accu ? ;

: bump3 ( -- )  7 accu +! ;
' bump3 0 cb: *bump3

variable mytimer3

: tt3 ( -- )   *bump3 700 new-timer dup mytimer3 ! start-timer ;

: ss3 ( -- )   mytimer3 @ stop-timer ;

: xx3 ( -- )  accu off tt3 counter 4999 ms ss3 timer accu ? ;

: zz ( -- )   accu off tt tt2 tt3 counter 4999 ms ss ss2 ss3 timer accu ? ;

cr .( examples: )
cr .( 1 timer:  xx   -> expect 5000  20)
cr .( 2 timers: yy   -> expect 5000  70)
cr .( 3 timers: zz   -> expect 5000 126)

\\ ( eof )
