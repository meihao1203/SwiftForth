{ ====================================================================
MultiTasking support

Copyright 2008 by FORTH, Inc.
==================================================================== }

PACKAGE TASKING

{ --------------------------------------------------------------------
Imports

SwiftForth tasks are implemented with the pthreads library.
-------------------------------------------------------------------- }

FUNCTION: pthread_create ( *thread *attr *func *arg -- result )   \ 0=success
FUNCTION: pthread_join ( thread *val_ptr -- result )   \ 0=success
FUNCTION: pthread_testcancel ( -- )
FUNCTION: pthread_cancel ( thread -- result )
FUNCTION: pthread_exit ( val -- )

FUNCTION: pthread_mutex_init ( *mutex *attr -- result )
FUNCTION: pthread_mutex_destroy ( *mutex -- result )
FUNCTION: pthread_mutex_lock ( *mutex -- result )
FUNCTION: pthread_mutex_unlock ( *mutex -- result )

FUNCTION: sched_yield ( -- result )

: MUTEX ( -- )   6 CELLS BUFFER: ;

{ --------------------------------------------------------------------
Critical Sections

[C and C] lock and unlock the SF-CRITICAL mutex.
-------------------------------------------------------------------- }

MUTEX SF-CRITICAL

PUBLIC

: [C ( -- )
   SF-CRITICAL pthread_mutex_lock DROP ;

: C] ( -- )
   SF-CRITICAL pthread_mutex_unlock DROP ;

PRIVATE

{ --------------------------------------------------------------------
Task defining

TASK defines a Task Control Block (TCB) structure whose private
dictionary space will be n bytes in size.  All tasks are chained to
the TASKS list.

OPERATOR is the "task" associated with the debug window.

HIS returns the address addr2 of USER variable addr1 owned by task.

OPERATOR'S sets the calling task's 'PERSONALITY to that of OPERATOR.
-------------------------------------------------------------------- }

VARIABLE TASKS

PUBLIC

: TASK ( n -- )         \ Usage: n TASK <name>
   CREATE
   0 ,                  \ address of user area
   0 ,                  \ thread handle
   ( n) ,               \ dictionary size
   TASKS >LINK ;        \ link

CREATE OPERATOR
   UP@ ,                \ address of user area
   0 ,                  \ thread handle
   0 ,                  \ dictionary size
   0 ,                  \ link

: HIS ( task addr1 -- addr2 )   STATUS -  SWAP @ + ;

: OPERATOR'S ( -- )
   OPERATOR 'PERSONALITY HIS @ 'PERSONALITY ! ;

{ --------------------------------------------------------------------
Resource serialization support

PAUSE sets a cancel point and yields the CPU.
-------------------------------------------------------------------- }

: PAUSE ( -- )
   pthread_testcancel  sched_yield DROP ;

{ --------------------------------------------------------------------
Task control

HALT kills a task by canceling and joining its thread, releasing the
thread's resources.

KILL does a HALT to terminate the task and then releases its memory.

|TASK| is the amount of extended memory allocated for a task's user
area, TIB, and FP stack.

(ACTIVATE) is the code passed to pthread_create for the thread to
execute.  The thread initializes its user area to complete the Forth
task instantiation, then executes the code passed in its 'CFA.  If its
behavior is not an infinite loop, it will return here and terminate.

CONSTRUCT instantiates the task's user area and dictionary (defined by
TASK above) and leaves a pointer to the task's memory in the first
cell of the TDB.  If the task has already been instantiated (TDB not
zero), CONSTRUCT does nothing.  The use of CONSTRUCT is optional;
ACTIVATE will do a CONSTRUCT automatically if needed.

ACTIVATE starts task executing the remainder of the definition
following ACTIVATE.  Must be used inside a colon definition.
-------------------------------------------------------------------- }

: HALT ( task -- )
   DUP CELL+ @ ?DUP IF
      DUP pthread_cancel DROP  0 pthread_join DROP
   0 OVER CELL+ !  THEN DROP ;

: KILL ( task -- )   DUP HALT
   DUP @ ?DUP IF  FREE DROP  0 OVER !  THEN  DROP ;

PRIVATE

|USER| |TIB| |FPSTACK| ( PAD) 1024 + + + CONSTANT |TASK|

THROW#
   S" Can't create thread" >THROW ENUM IOR_THREAD
TO THROW#

: (ACTIVATE) ( -- )
   [ASM
   CELL [ESP] ESI MOV                   \ ESI --> user space (param passed in from pthread_create)
   ESP EBP MOV   $2000 # ESP SUB        \ EBP --> data stack, move ESP down to make room
   BEGIN 5 + ( *) DUP CALL
   EDI POP   ( *) -ORIGIN # EDI SUB     \ EDI --> data space
   ASM]
   SP@ S0 !  RP@ R0 !                   \ Save S0, R0 in user area
   UP@  |USER| + DUP DUP 'TIB 2!        \ Initialize user area pointers
   |TIB| + |FPSTACK| + DUP DUP 'N 2!
   DUP H !  TCB @ 2 CELLS + @ + HLIM !
   'CFA @ CALL  0 pthread_exit ;

PUBLIC

: CONSTRUCT ( task -- )
   DUP @ 0= IF  DUP 2 CELLS + @ |TASK| + ALLOCATE THROW
   OVER !  STATUS OVER @ |USER| MOVE  THEN DROP ;

: ACTIVATE ( task -- )
   DUP HALT  DUP CONSTRUCT
   R> OVER 'CFA HIS !  DUP DUP TCB HIS !
   DUP >R CELL+  0  ['] (ACTIVATE) >CODE  R> @
   pthread_create IOR_THREAD ?THROW ;

PRIVATE

{ --------------------------------------------------------------------
Pruning, init, shutdown
-------------------------------------------------------------------- }

: UNLINK-TASKS ( -- )
   TASKS BEGIN
      DUP @REL WHILE
      DUP @REL  ?PRUNED IF
         DUP @REL 3 CELLS - KILL
         DUP @REL UNLINK
         ELSE  @REL
   THEN  REPEAT  DROP ;

:PRUNE ( -- )  UNLINK-TASKS ;

: /TASKS ( -- )
   OPERATOR TCB !  UP@ OPERATOR !
   SF-CRITICAL 0 pthread_mutex_init DROP
   TASKS BEGIN  @REL ?DUP WHILE
   DUP 3 CELLS -  0. ROT 2!  REPEAT ;

: KILL-TASKS ( -- )
   TASKS BEGIN  @REL ?DUP WHILE
   DUP 3 CELLS - KILL  REPEAT
   SF-CRITICAL pthread_mutex_destroy DROP ;

:ONSYSLOAD /TASKS ;
:ONSYSEXIT KILL-TASKS ;

END-PACKAGE

{ --------------------------------------------------------------------
TEST
-------------------------------------------------------------------- }

\\
0 TASK TICKER

: /TICKER   TICKER ACTIVATE
   BEGIN  PAUSE  1 BLK +!  AGAIN ;

: HMM  TICKER BLK HIS ? ;
