{ ====================================================================
Mach kernel task and thread stuff

Copyright (c) 2011-2017 Roelf Toxopeus

Last: 6 February 2011 23:21:44 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
Utillities for Mach tasks and threads.

#THREADS -- return threadlist and current number of threads in our
task/process. This is an ever changing number!
THREAD# -- return port number id from calling thread. Same number as
used by GDB for THREAD n.
I'M -- set current forth-task's mach thread name. While including this
file, it's assumed I'm Impostor...
-------------------------------------------------------------------- }

/FORTH
DECIMAL

LACKING SYSTEM.FRAMEWORK   FRAMEWORK System.framework

SYSTEM.FRAMEWORK

FUNCTION: mach_task_self ( -- mach_port_t )
FUNCTION: task_threads ( task *thread_list *thread_count -- ret )
FUNCTION: mach_thread_self ( -- thread_port )
FUNCTION: pthread_getname_np ( thread *name size -- ret )  
FUNCTION: pthread_setname_np ( name -- ret )      

: #THREADS ( -- addr n )
	mach_task_self 0 >R RP@ 0 >R RP@
	task_threads DROP R> R> SWAP ;

: THREAD# ( -- n )
	mach_thread_self
	#THREADS 0 DO
		TUCK @ OVER =
		IF 2DROP I 1+  UNLOOP EXIT THEN
		SWAP CELL+
	LOOP DROP 0 ;

: I'M ( 0$name -- )   pthread_setname_np DROP ;

Z" impostor" I'M 

cr .( mach task and thread info loaded)

\\ ( eof )