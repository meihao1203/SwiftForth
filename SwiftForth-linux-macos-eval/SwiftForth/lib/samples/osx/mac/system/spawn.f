{ ====================================================================
spawning tasks

Copyright (c) 2004-2017 Roelf Toxopeus

SwiftForth version.
Last: 17 Apr 2017 14:51:08 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Spawn forth word in its own anynomous thread/task. Similar to anonymous
tasks in CMF, there's no direct control over the running task after
spawning it. 
A process can spawn( and kill) an anonymous task without help from the
user. They don't affect code, data or vocab spaces and are not linked
in a task chain. On the Darwin Forth systems, spawning is just ordinary
pthread_create. Necessary cleanup is done by the callback.

Very useful in situations  where you don't know in advance how many tasks
your process is going to need. An example could be sound processing,
where different sound streams with their own processing can exist at the
same time. The duration of every stream determined by a corresponding time
line. See attached example.
Another example could be a server which spawns a task to service a request,
while listening for new requests.

SPAWN-ATTR -- container for pthread attributes. If not destroyed it can
be used over and over again
/SPAWN -- initialise the attributes: detached.
SPAWN -- spawn a task running the given xt as callback in thread. Drops the
returned thread id from (SPAWN).
(SPAWN) can be used for debugging purposes or if you want to keep track
somehow of the spawned tasks.

An alternative is
: SPAWN ( cb -- )   0 (SPAWN) DROP ;
which takes the callback instead.

Note: Don't forget to set FSTACK in executed word in case of fp usage !!!!!!
-------------------------------------------------------------------- }

/FORTH
DECIMAL

(*
LACKING system.framework   FRAMEWORK system.framework
system.framework
*)

FUNCTION: pthread_attr_init ( *attr -- ret )
FUNCTION: pthread_attr_setdetachstate ( *attr detached/joinable -- ret )

56 BUFFER: SPAWN-ATTR

\ set the attributes:
: /SPAWN ( -- )
	SPAWN-ATTR DUP pthread_attr_init DROP
	2 pthread_attr_setdetachstate DROP ;

cr .( initiating spawn attribute now)
/SPAWN

TASKING +ORDER			\ need pthread_create in TASKING package
: (SPAWN) ( cb arg -- pthread )
	0 >R RP@ SPAWN-ATTR 2SWAP pthread_create DROP
	R> ;
PREVIOUS

LIB-INTERFACE +ORDER  \ need RUNCB in LIB-INTERFACE
CREATE (CB)  RUNCB ,CALL  0 ,
PREVIOUS
: >CB ( xt -- )   (CB) 5 + ! ;

: SPAWN ( xt -- )   >CB (CB) 0 (SPAWN) DROP ;

cr .( spawn actions loaded)
cr .( Don't forget to set FSTACK in callback in case of fp usage !)

\\ ( eof )

\ example:

FRAMEWORK Carbon.framework
FUNCTION: SysBeep ( n -- ret )

: BEEP ( -- )   0 SysBeep DROP ;

: BEEPER ( -- )   20 CHOOSE 1+ 0 DO 180 800 ALEA MS BEEP LOOP ;

: BEEP+ ( -- )   250 750 ALEA MS ['] BEEPER SPAWN ;

: BB ( -- )  BEGIN  TOSS IF BEEP+ THEN  KEY? UNTIL ;
