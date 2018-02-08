{ ===============================================================================
defines CALLBACK:

Copyright (C) 2013-2017 Roelf Toxopeus

SwifForth specific version.
Extends CB:
Last: 21 February 2014 09:36:20 CET  -rt
=============================================================================== }

{ -------------------------------------------------------------------------------
CALLBACK: is a parsing variant on CB: including :NONAME for the xt.
Similar to CB: words created with CALLBACK: leave the code address for the calback.
A kind of handy shortcut for those who use the :NONAME and CB: sequence a lot.

CALLBACK: mycallback ( n1 n2 -- )  whatever needs to be done ;
	
Note: CB: in the OSX version, disregards the n parameter. This CALLBACK: is Mac
and Linux only, adapt for Windows. You could put PARAMETERS() before CREATE.
Then a stack picture is essential like with FUNCTION:. Or have it accept the in-
and output parameters like in VFX.
	
Recall from osx/callback.f 
: CB: ( xt n -- )  \ Usage: xt n CB: <name>
	 CREATE  RUNCB ,CALL  ( n) DROP  ( xt) , ;

For coco-sf users,  AKA CALLBACK: IBACTION:  makes nice/useful syntax sugar.

Alternative version:
SF specific code, don't need :NONAME for portability
RUNCB expects an xt, not the actual codepointer
Note: LAST not set, need RECURSE in a callback?

LIB-INTERFACE +ORDER
: CALLBACK: ( <spaces>name text -- )
	CREATE  RUNCB ,CALL  HERE 0 , HERE CODE> SWAP ! ] ;         
PREVIOUS
------------------------------------------------------------------------------- }

LIB-INTERFACE +ORDER
: CALLBACK: ( <spaces>name text -- )
	CREATE  RUNCB ,CALL  HERE 0 , :NONAME SWAP ! ;         
PREVIOUS

{ -------------------------------------------------------------------------------
CB: Windows version:
: CB: ( xt n -- )  \ Usage: xt n CB: <name>
	CREATE  RUNCB ,CALL  ( n) $C2 C, CELLS H,
	( Filler) 0 C,  ( xt) , ;


LIB-INTERFACE +ORDER
: CALLBACK: ( <spaces>name text -- )
	PARAMETERS()   CREATE  RUNCB ,CALL    ( nRET) $C2 C, CELLS H,
	( Filler) 0 C,  HERE 0 , :NONAME SWAP ! ;         
PREVIOUS
------------------------------------------------------------------------------- }

CR .( callback extension loaded)

\\ ( eof )
