{ ====================================================================
Play sound

Copyright 2001  FORTH, Inc.
==================================================================== }

: ,FILE ( addr n -- )
   R/O OPEN-FILE THROW >R
   R@ FILE-SIZE THROW DROP ( n)  DUP ,
   HERE  OVER ALLOT  SWAP R@ READ-FILE THROW DROP
   R> CLOSE-FILE THROW ;

LIBRARY WINMM

FUNCTION: PlaySound ( pszSound hmod fdwSound -- b )

: PLAY ( addr -- )
   CELL+ 0 SND_MEMORY SND_ASYNC OR PlaySound DROP ;

1 VALUE LOUD

: SOUND ( addr -- )
    LOUD IF PLAY ELSE DROP THEN ;

CREATE TICK.WAV   S" TICK.WAV"  ,FILE
CREATE THUD.WAV   S" THUD.WAV"  ,FILE

: SOUND.TICK   TICK.WAV SOUND ;
: SOUND.THUD   THUD.WAV SOUND ;
