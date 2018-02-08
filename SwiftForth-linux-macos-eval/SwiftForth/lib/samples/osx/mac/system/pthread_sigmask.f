{ ====================================================================
Thread specific signal mask

Copyright (c) 2017 Roelf Toxopeus

SwiftForth version.
Make thread ignoring specific signals
Last: 9 November 2017 at 12:08:32 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Problem with signals is they're send to a process. Which thread deals
with them is arbitrary according POSIX. In sf, initialy 1 thread, the
SIGINT signal is caught by OPERATOR. So Ctrl-C and Cmd-. arrive where
they should be.
Coco-sf has at least 3 threads, the main thread runs the ObjC Runtime.
It's not the thread where the SIGINT signals created in the Terminal
repl should arrive. They should go to IMPOSTOR.
Learned from: https://stackoverflow.com/questions/22005719/which-thread-handles-the-signal
This will be used in coco-sf to have the main thread OPERATOR ignoring
the SIGINT signals, so they get to IMPOSTOR.

THREAD-IGNORE-SIGINT -- tell current thread (pthread_self) to ignore
SIGINT signals.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: sigemptyset ( set -- result )
FUNCTION: sigaddset ( set sig# -- result )
FUNCTION: pthread_sigmask ( how set 0set -- result )

VARIABLE SIGSET
2 CONSTANT SIGINT
1 CONSTANT SIG_BLOCK

: THREAD-IGNORE-SIGINT ( -- )
	SIGSET sigemptyset DROP
	SIGSET SIGINT sigaddset DROP
	SIG_BLOCK SIGSET 0 pthread_sigmask DROP ;
	
\\ ( eof )