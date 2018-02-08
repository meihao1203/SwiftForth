{ ====================================================================
MultiTasking support

Copyright 2001 by FORTH, Inc.
==================================================================== }

{ --------------------------------------------------------------------
Imports

SwiftForth tasks are implemented with a small set of API calls.

HANDLE CreateThread
    LPSECURITY_ATTRIBUTES lpThreadAttributes,           // pointer to thread security attributes
    DWORD dwStackSize,	                                // initial thread stack size, in bytes
    LPTHREAD_START_ROUTINE lpStartAddress,              // pointer to thread function
    LPVOID lpParameter,	                                // argument for new thread
    DWORD dwCreationFlags,                              // creation flags
    LPDWORD lpThreadId                                  // pointer to returned thread identifier

-------------------------------------------------------------------- }

FUNCTION: CreateThread                  ( attr size func param flags *id -- x )
FUNCTION: GetCurrentThread              ( -- hthread )
FUNCTION: GetCurrentThreadId            ( -- id )
FUNCTION: SuspendThread                 ( hthread -- res )
FUNCTION: ResumeThread                  ( hthread -- res )
FUNCTION: ExitThread                    ( n -- )
FUNCTION: WaitForSingleObject           ( handle time -- ior )

{ --------------------------------------------------------------------
Tasker hooks

PAUSE and STOP are deferred and will be filled in later.
-------------------------------------------------------------------- }

DEFER PAUSE
DEFER STOP

PACKAGE TASKING

{ --------------------------------------------------------------------
Critical Sections

[C and C] lock and unlock the SF-CRITICAL critical section.

A critical section must be cleared before calling
InitializeCriticalSection or the API may fail and delete another
process-owned critical section.
-------------------------------------------------------------------- }

CREATE SF-CRITICAL  512 /ALLOT

PUBLIC

: [C ( -- )
   SF-CRITICAL EnterCriticalSection DROP ;

: C] ( -- )
   SF-CRITICAL LeaveCriticalSection DROP ;

PRIVATE

{ --------------------------------------------------------------------
Task defining

TASK defines a Task Control Block (TCB) structure whose private
dictionary space will be n bytes in size.  All tasks are chained to
the TASKS list.

/TASK returns the size of a TCB. This word allows arrays of tasks to
be created without having to name each one.

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

3 CELLS CONSTANT /TASK  \ size of a TCB

CREATE OPERATOR
   UP@ ,                \ address of user area
   0 ,                  \ thread handle
   0 ,                  \ dictionary size
   0 ,                  \ link

: HIS ( task addr1 -- addr2 )   STATUS -  SWAP @ + ;

: OPERATOR'S ( -- )
   OPERATOR 'PERSONALITY HIS @ 'PERSONALITY ! ;

{ --------------------------------------------------------------------
Windows message dispatch
-------------------------------------------------------------------- }

$7FFF CONSTANT WM_BREAK         \ global constant for message dispatcher
VARIABLE DLGACTIVE              \ flag set if dialog active

PRIVATE

: FINISHED ( -- )
   UP@ OPERATOR @ = IF
      'ONENVEXIT CALLS  'ONSYSEXIT CALLS
   0 ExitProcess DROP  THEN
   0 ExitThread DROP ;

: MSGDISPATCH ( -- )
   DLGACTIVE @ IF  DLGACTIVE @ WINMSG IsDialogMessage ?EXIT  THEN
   WINMSG CELL+ W@ WM_QUIT = IF  FINISHED  THEN
   WINMSG CELL+ W@ WM_BREAK = IF  IOR_BREAK THROW  THEN
   WINMSG TranslateMessage DROP
   WINMSG DispatchMessage DROP ;

PUBLIC

: DISPATCHER ( -- res )
   BEGIN
      WINMSG 0 0 0 GetMessage WHILE
      WINMSG TranslateMessage DROP
      WINMSG DispatchMessage DROP
   REPEAT  WINMSG 2 CELLS + @ ( wparam) ;

PRIVATE

{ --------------------------------------------------------------------
Message loop, termination

TERMINATE causes the calling thread to cease operation and release its
stack memory.

STOP and PAUSE are holdover terminology from cooperative round-robin
multitasking models of Forth. The paradigm is so ingrained that it is
probably reasonable to leave them in, but to encourage the user to use
the real base functions that represent what the program is doing.

The application program can do one of two things: either check to see
if a message is waiting (via PAUSE) or wait for a message (via STOP).
In WINPAUSE, we use 0 Sleep to give up the remainder of the current
time slice.

A thread that has stopped without a message loop may be assigned a new
behavior with ACTIVATE or restarted with RESUME below.
-------------------------------------------------------------------- }

PUBLIC

: TERMINATE ( -- )   0 ExitThread ;

PRIVATE

#USER  CELL +USER ?TERM         \ Flag set to terminate task
TO #USER

: WINSTOP ( -- )
   HWND IF
      WINMSG 0 0 0 GetMessage
      0> IF  MSGDISPATCH EXIT THEN
   FINISHED EXIT  THEN
   GetCurrentThread SuspendThread DROP
   ?TERM @ IF  TERMINATE  THEN ;

: WINPAUSE ( -- )
   HWND IF
      BEGIN
         WINMSG 0 0 0 PM_NOREMOVE PeekMessage WHILE
         WINMSG 0 0 0 GetMessage  0> WHILE
         MSGDISPATCH
      REPEAT FINISHED THEN EXIT
   THEN  0 Sleep DROP
   ?TERM @ IF  TERMINATE  THEN ;

' WINSTOP IS STOP
' WINPAUSE IS PAUSE

{ --------------------------------------------------------------------
Task control

HALT terminates the task causing it to exit and free its stack space.
The thread handle is no longer relevant, so it is closed and its cell
in the TCB is cleared.

KILL does a HALT to terminate the task and then releases its memory.

|TASK| is the amount of extended memory allocated for a task's user
area, TIB, and FP stack.

(ACTIVATE) is the code passed to ThreadCreate for the thread to
execute.  The thread initializes its user area to complete the Forth
task instantiation, then executes the code passed in its 'CFA.  If its
behavior is not an infinite loop, it will return here and terminate.

CONSTRUCT instantiates the task's user area and dictionary (defined by
TASK above) and leaves a pointer to the task's memory in the first
cell of the TCB.  If the task has already been instantiated (TCB not
zero), CONSTRUCT does nothing.  The use of CONSTRUCT is optional;
ACTIVATE will do a CONSTRUCT automatically if needed.

ACTIVATE starts task executing the remainder of the definition
following ACTIVATE.  Must be used inside a colon definition.

SUSPEND and RESUME are convenient words for managing tasks. They
return IORs because we can't guarantee that we can perform the
operation.
-------------------------------------------------------------------- }

PUBLIC

: HALT ( task -- )
   DUP CELL+ @ ?DUP IF  OVER ?TERM HIS ON       \ Set ?TERM flag
      DUP ResumeThread DROP                     \ Resume (in case suspended)
      DUP INFINITE WaitForSingleObject DROP     \ Wait until task exits
      CloseHandle DROP  0 OVER CELL+ !          \ Release the handle
   THEN DROP ;

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
   |TIB| + |FPSTACK| + DUP DUP 'N 2!    \ N-stack
   DUP H !  TCB @ 2 CELLS + @ + HLIM !  \ Dictionary pointers
   WPARMS DUP 4 CELLS ERASE  'WF !      \ Dummy WF so HWND works and is zero
   'CFA @ CALL  TERMINATE ;

PUBLIC

: CONSTRUCT ( task -- )
   DUP @ 0= IF  DUP 2 CELLS + @ |TASK| + ALLOCATE THROW
   OVER !  STATUS OVER @ |USER| MOVE  THEN DROP ;

: ACTIVATE ( task -- )
   DUP HALT  DUP CONSTRUCT
   R> OVER 'CFA HIS !  DUP DUP TCB HIS !
   0 OVER ?TERM HIS !  >R
   0 $4000 ['] (ACTIVATE) >CODE R@ @ 0 0
   CreateThread  DUP 0= IOR_THREAD ?THROW
   R> CELL+ ! ;

: SUSPEND ( task -- ior )   CELL+ @ SuspendThread ;
: RESUME ( task -- ior )   CELL+ @ ResumeThread ;

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

: /TASKS
   OPERATOR TCB !  UP@ OPERATOR !
   SF-CRITICAL 512 ERASE
   SF-CRITICAL InitializeCriticalSection DROP
   TASKS BEGIN  @REL ?DUP WHILE
   DUP 3 CELLS -  0. ROT 2!  REPEAT ;

: KILL-TASKS ( -- )
   TASKS BEGIN  @REL ?DUP WHILE
   DUP 3 CELLS - KILL  REPEAT
   SF-CRITICAL DeleteCriticalSection DROP ;

:ONSYSLOAD   /TASKS ;
:ONDLLLOAD   /TASKS ;

:ONSYSEXIT   KILL-TASKS ;
:ONDLLEXIT   KILL-TASKS ;

END-PACKAGE

{ --------------------------------------------------------------------
TEST
-------------------------------------------------------------------- }

\\
0 TASK TICKER

: /TICKER   TICKER ACTIVATE
   BEGIN  PAUSE  1 BLK +!  AGAIN ;

: HMM  TICKER BLK HIS ? ;
