{ ====================================================================
Sealed turnkey

Copyright 2001  FORTH, Inc.
Rick VanNorman

Seal the system to prevent re-saving an application
==================================================================== }

[UNDEFINED] PROGRAM [IF]

.(
This file is only valid for non-eval versions of SwiftForth.
)

-1 THROW

[THEN]


OPTIONAL SEALED Hide arbitrary words by obliterating their names

{ --------------------------------------------------------------------
Exports: HIDE HIDES

HIDES requires a list of XTs that have valid headers. It hides each
word in the list.  A zero cell terminates the list.
-------------------------------------------------------------------- }

: HIDE ( xt -- )
   >NAME   DUP COUNT ERASE  0 SWAP C! ;

: HIDES ( addr -- )
   BEGIN @+ ?DUP WHILE HIDE REPEAT DROP ;

CREATE IMPORTANT
   ' HIDE ,
   ' HIDES ,
   ' IMPORTANT ,
   ' PROGRAM ,
   ' CONFIG: ,
   0 ,

\ IMPORTANT HIDES
