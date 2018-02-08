{ ====================================================================
Dispatch tasking

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Run Forth tasks based on GCD dispatch queues, allowing for concurency
on multicore processors.
Last: 20 March 2013 21:40:43 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
Only the global concurent queues are of interest here:
DEFAULTQUEUE -- default priority concurent concurentdispatch queue.
PARALLELQUEUE -- high priority dispatch queue, ok for parallel execution.

(DISPATCH) -- acts like (ACTIVATE), but geared towards GCD.
As with callbacks, no DONE or TERMINATE at end, GCD takes care of that.


DISPATCH -- usage is the same as using ACTIVATE. But rather than using
POSIX threads, Grand Central Dispatch queues are used. This should be
transparent to the user. ACTIVATE could be recoded as DISPATCH, but
sometimes you might want a POSIX based task, so both exists.

Info on GCD:
See: man dispatch_async_f  etc.
See: http://developer.apple.com/library/mac/#documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html%23//apple_ref/doc/uid/TP40008091

Forth task control words can be used: PAUSE HALT KILL DONE etc.
but see Apple's warnings:

<QUOTE>
Compatibility with POSIX Threads
Because Grand Central Dispatch manages the relationship between the tasks you provide and
the threads on which those tasks run, you should generally avoid calling POSIX thread routines
from your task code.
If you do need to call them for some reason, you should be very careful about which routines
you call. This section provides you with an indication of which routines are safe to call and
which are not safe to call from your queued tasks. This list is not complete but should give you
an indication of what is safe to call and what is not.

In general, your application must not delete or mutate objects or data structures that it did
not create. Consequently, block objects that are executed using a dispatch queue must not call
the following functions:

pthread_detach
pthread_cancel
pthread_join
pthread_kill
pthread_exit


Although it is alright to modify the state of a thread while your task is running, you must
return the thread to its original state before your task returns. Therefore, it is safe to call
the following functions as long as you return the thread to its original state:

pthread_setcancelstate
pthread_setcanceltype
pthread_setschedparam
pthread_sigmask
pthread_setspecific


The underlying thread used to execute a given block can change from invocation to invocation.
As a result, your application should not rely on the following functions returning predictable
results between invocations of your block:

pthread_self
pthread_getschedparam
pthread_get_stacksize_np
pthread_get_stackaddr_np
pthread_mach_thread_np
pthread_from_mach_thread_np
pthread_getspecific

For more information about POSIX threads and the functions mentioned in this section,
see the pthread man pages.
</QUOTE>
 
Note: functions like dispatch_resume and dispatch_suspend only work on a queue *not*
	  on a spawned thread by a queue. So you can't use them to control our tasks.

So we're probably save. Most from the above is not in use.
What is in use:  pthread_self (DISPATCH)
And see task-controls.f for others like pthread_mach_thread_np etc.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: dispatch_get_global_queue ( priority 0 -- aQueue )
FUNCTION: dispatch_async_f ( queue *context 'cb -- ret )

\ 3 global concurrent queues
 2 CONSTANT DISPATCH_QUEUE_PRIORITY_HIGH
 0 CONSTANT DISPATCH_QUEUE_PRIORITY_DEFAULT
-2 CONSTANT DISPATCH_QUEUE_PRIORITY_LOW

: DEFAULTQUEUE ( -- queue )  DISPATCH_QUEUE_PRIORITY_DEFAULT 0 dispatch_get_global_queue ;

: PARALLELQUEUE ( -- queue )  DISPATCH_QUEUE_PRIORITY_HIGH 0 dispatch_get_global_queue ;

: (DISPATCH) ( -- )   \ combination RUNCB and (XACTIVATE)
   [ASM
   CELL [ESP] ECX MOV                   	\ ECX points to task area
    
   EBX PUSH                             	\ Save registers
   ESI PUSH
   EDI PUSH
   EBP PUSH

   -16 [ESP] EBP LEA                    	\ start stack in open space
   $2000 # ESP SUB        						\ EBP --> data stack, move ESP down to make room

   ECX ESI MOV										\ rt Set USER register
   ESP R0 [U] MOV                       	\ rt save stack pointers in user area
   EBP S0 [U] MOV

	BEGIN 5 + ( *) DUP CALL
   EDI POP   ( *) -ORIGIN # EDI SUB     	\ EDI --> data space
   ASM]
 
 drop			\ there's something on the stack!!! also sets topstack EBX
 
   UP@  |USER| + DUP DUP 'TIB 2!        	\ Initialize user area pointers
   |TIB| + |FPSTACK| + DUP DUP 'N 2!
   DUP H !  TCB @ 2 CELLS + @ + HLIM !
   pthread_self TCB @ CELL+ !				 	\ rt: get our thread id and make global accessable (see documentation!)
   'CFA @ CALL
   0 TCB @ CELL+ !								\ rt sign off
   
   [ASM   
   S0 [U] ESP MOV                       \ restore
   16 # ESP ADD                         \ and negate the padding
   EBP POP                              \ restore registers
   EDI POP
   ESI POP
   EBX POP
   ASM]
;

: DISPATCH ( task <text> -- )
   DUP HALT
   DUP CONSTRUCT
   R> OVER 'CFA HIS !
   DUP DUP TCB HIS !
   DEFAULTQUEUE SWAP @ ['] (DISPATCH) >CODE dispatch_async_f DROP ;

CR .( dispatch tasking loaded)

\\ ( eof )
