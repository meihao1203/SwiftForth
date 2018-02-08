{ ====================================================================
Edit file

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Edit file in editor using filekite and load into sf when needed
Last: 1 February 2013 16:42:26 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
(EDIT-FILE) -- redefinition of sf's original EDIT-FILE.
EDIT-FILE -- edit file in preferred editor using filekite
LOAD-EDIT -- load/include last file summoned with EDIT-FILE
-------------------------------------------------------------------- }

/FORTH
DECIMAL

512 BUFFER: 'EDIT-FILE

: (EDIT-FILE) ( l# addr u -- )   EDIT-FILE ;

: EDIT-FILE ( -- )   EZGETMAIN IF 2DUP 'EDIT-FILE ZPLACE 0 -ROT (EDIT-FILE) THEN ;

: LOAD-EDIT ( -- )   'EDIT-FILE ZCOUNT ?DUP IF INCLUDED EXIT THEN DROP ;

\\ ( eof )