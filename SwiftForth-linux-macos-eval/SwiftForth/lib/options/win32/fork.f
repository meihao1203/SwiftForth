{ ====================================================================
FORK, an alternative to tasks.

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL FORK An alternative to tasks

FUNCTION: TerminateThread ( hthread n -- ior )

{ --------------------------------------------------------------------
param0 has a pointer to the startup data, which needs to be
released as soon as it is used. The callback will initialize
a dictionary, a user area, and the stacks. The data passed
is simply a pointer to a structure which contains

   +0  'this
   +4  'self
   +8  xt to run
   +12 user parameter

local variables and objects may not be passed across this interface

The variations with () allow the user to pass a parameter into the
new thread as top-of-stack.
-------------------------------------------------------------------- }

:NONAME ( -- )
   _PARAM_0 @+ 'THIS !  @+ 'SELF !  @+  SWAP @  _PARAM_0 FREE DROP
   CATCH ExitThread ;  1 CB: FORKED

: FORK() ( param xt -- handle )   SWAP  0 >R
   4 CELLS ALLOCATE IF DROP INVALID_HANDLE_VALUE EXIT THEN
   DUP >R  THIS !+  SELF !+  SWAP !+ !
   0 65536 FORKED R> 0 RP@ CreateThread   R> DROP ;

: FORK ( xt -- handle )   0 SWAP FORK() ;

: FORKS()> ( n -- handle[to caller] )   R> CODE> FORK() ;

: FORKS> ( -- handle[to caller] )   0 R> CODE> FORK() ;

: KILL-THREAD ( hthread -- )
   DUP 1000 WaitForSingleObject WAIT_TIMEOUT = IF
   -1 TerminateThread  THEN DROP ;

\\

{ --------------------------------------------------------------------
In SwiftForth, the callback mechanism builds a "virtual" Forth machine
for code to execute on, complete with a user context and stacks.  This
is exactly what a background thread needs to be and to do.  So, we
have implemented FORK to do very simple multi-threading.  Give FORK an
xt to execute; it will run as a separate thread either forever, or
until it completes, or until it throws.  This task is allowed to
return; it is not required to be an infinite loop.

FORK returns the handle of the thread created.  If you want to
manipulate the thread, you better keep track of the handle returned!

FORKS> lets you fork the remainder of a word; the side effect is that
it will return the handle as it exits. Sorta like DOES>
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Simple example
-------------------------------------------------------------------- }


VARIABLE FOO
VARIABLE ZOT   FOO ZOT !

: BAR   OPERATOR'S SELF H. THIS H.
   1000 0 DO  1 ZOT @ +!  250 Sleep DROP  LOOP ;

' BAR FORK DROP

{ --------------------------------------------------------------------
Passing a parameter into the thread
-------------------------------------------------------------------- }

VARIABLE FOO
VARIABLE ZOT   FOO ZOT !

: BAR ( n -- )   OPERATOR'S SELF H. THIS H. H.
   1000 0 DO  1 ZOT @ +!  250 Sleep DROP  LOOP ;

HERE ' BAR FORK() DROP

{ --------------------------------------------------------------------
Using FORKS()>
-------------------------------------------------------------------- }

VARIABLE FOO
VARIABLE ZOT   FOO ZOT !

: BAR ( -- )   HERE FORKS()>
   OPERATOR'S SELF H. THIS H. H.
   1000 0 DO  1 ZOT @ +!  250 Sleep DROP  LOOP ;

{ --------------------------------------------------------------------
Class/object based example
Please note that the word which does the activate is protected from
accidental use by the public word GO. This is essential if the code
is to prevent the accidental spawning of many, many threads.
-------------------------------------------------------------------- }

CLASS POO

   PROTECTED

   VARIABLE HTHREAD
   VARIABLE COUNTING

   : TEST ( -- hthread )   0 COUNTING !  FORKS>
      BEGIN  1 COUNTING +!  100 Sleep DROP  AGAIN ;

   PUBLIC

   : GO ( -- )   HTHREAD @ ?EXIT  TEST HTHREAD ! ;

   : DOT ( -- )   COUNTING @ . ;

END-CLASS

POO BUILDS X1
POO BUILDS X2
