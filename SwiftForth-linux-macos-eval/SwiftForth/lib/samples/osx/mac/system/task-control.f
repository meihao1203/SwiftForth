{ ====================================================================
Task control

Copyright (c) 2001-2017 Roelf Toxopeus

SwiftForth version.
Controlling threads and tasks unconditionally, no cancel-point considered.
Last: 19 April 2014 21:52:45 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
The thread controllers are for brute force control and when dealing with
self created threads without tasks.
SUSPEND -- suspend given thread
RESUME -- wake given thread
TERMINATE -- terminates given thread

The above is used to implement the task controllers which will be the ones
in normal use.
SLEEP -- set given task to sleep
STOP -- goto sleep yourself, another task or interrupt will WAKE you...
WAKE -- wakeup giventask
DONE -- end/stop given task now, unlike SF HALT and KILL. 
The resetting of the task structure copied from Forth, INC. HALT and KILL
After DONE, the task is ready for ACTIVATE (allocates if needed) again
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: thread_suspend ( machport -- ret )
FUNCTION: thread_resume ( machport -- ret )
FUNCTION: thread_terminate ( machport -- ret )
FUNCTION: pthread_mach_thread_np ( thread -- machport )
FUNCTION: pthread_self ( -- thread )

: SUSPEND ( pthread -- )   pthread_mach_thread_np thread_suspend DROP ;

: SLEEP ( task -- )  CELL+ @ SUSPEND ;

: STOP ( -- )   pthread_self SUSPEND ;

: RESUME ( pthread -- )   pthread_mach_thread_np thread_resume DROP ;

: WAKE ( task -- )   CELL+ @ RESUME ;

: TERMINATE ( pthread -- )   pthread_mach_thread_np thread_terminate DROP ;

: DONE ( task --- )
   DUP CELL+ @ ?DUP IF  TERMINATE 0 OVER CELL+ !  THEN
   DUP @ ?DUP IF  FREE DROP 0 OVER ! THEN DROP ;

CR .( Task control loaded)

\\ ( eof )
