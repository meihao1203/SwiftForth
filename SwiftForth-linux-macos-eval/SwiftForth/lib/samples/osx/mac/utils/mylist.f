{ ====================================================================
relative linked lists

Copyright (c) 1989--2017 Roelf Toxopeus

SwiftForth version.
Defines where necessary the relative linked list words as used and
learned in Mach2 and MacForth.
Last: 31 October 2011 10:12:12 CET -rt
==================================================================== }

{ --------------------------------------------------------------------
Aliasses for SwiftForth's chains/list words
NODE, alias for ,REL    comma n relative to HERE
NODE  alias for >LINK   add a node to the chain
ALLNodes -- Execute xt for every node in the list. Lisp's MAPCAR.
Don't leave anything on the stack
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: NODE, ( n -- )   ,REL ;

: NODE   ( list -- )  >LINK ;

: ALLNodes ( xt list -- )
	SWAP >R
	    BEGIN @REL DUP
		WHILE DUP CELL+ @REL R@ EXECUTE
	REPEAT R> 2DROP ;

CR .( nodes loaded)

\\ ( eof )
