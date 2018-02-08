{ ====================================================================
Temporary Yosemite fixes

Copyright (c) 2014-2017 Roelf Toxopeus

SwiftForth version.
Some work-arounds for OS glitches.
They stay in place till Apple fixes it.
Last: 18 Oct 2016 20:36:24 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
OSX 10.10 Yosemite
Words affected in coco-vfx:  EZGETMAIN LOAD-FILE EDIT-FILE
Glitch: NSopenPanel @openPanel combined with @runModal will litter the
Forth console with error messages and warnings directed at Apple's
programmers. Guess it's debug information left over from the beta testing.
It doesn't affect the functionality AFAIK. But the littering is annoying.
Herefore words to temporary suppress the STDERR output.

Variation on temp-fixes.f
Uses dev/null for redirecting STDERR
Because of the hopefully temporary situation, /DEVNULL is not put in any
system initialiser like HOT.COCO. In case this situation persists, it could
be put in HOT.COCO and all should be adapted slightly.

/DEVNULL -- open /dev/nul
-DEVNULL -- close /dev/null

Use these as pair
-STDERR -- stop stderr output by redirecting it to /dev/null
+STDERR -- reset stderr output

Do not use 'STDERR and 'FD-NULL. They're local to -STDERR and +STDERR

EZGETMAIN, LOAD-FILE and EDIT-FILE are redefined using -STDERR
and +STDERR

XEZGETMAIN -- original version just in case ...
-------------------------------------------------------------------- }

/FORTH
DECIMAL

1010 CONSTANT YOSEMITE

LACKING SYSTEM.FRAMEWORK  FRAMEWORK System.framework

SYSTEM.FRAMEWORK

AS _dup  FUNCTION: dup ( fd -- n )

AS _dup2 FUNCTION: dup2 ( fd1 fd2 -- n )

VARIABLE 'STDERR

VARIABLE 'FD-NULL

: /DEVNULL ( -- )   S" /dev/null" W/O OPEN-FILE THROW  'FD-NULL ! ;
: -DEVNULL ( -- )   'FD-NULL @ CLOSE-FILE THROW ;

\ : >DEVNULL ( -- )   'FD-NULL @ FD-OUT ! ;

: -STDERR ( -- )   /DEVNULL STDERR _dup 'STDERR ! 'FD-NULL @ STDERR _dup2 DROP ;
: +STDERR ( -- )   'STDERR @ DUP STDERR _dup2 DROP  CLOSE-FILE THROW -DEVNULL ;

\ --------------------------------------------------------------------
\ temporary redefinitions:

: XEZGETMAIN  ( -- a n true | false )     EZGETMAIN ;

: EZGETMAIN  ( -- a n true | false )    -STDERR EZGETMAIN +STDERR ;

: LOAD-FILE ( -- )   EZGETMAIN IF INCLUDED THEN ;

: EDIT-FILE ( -- )   EZGETMAIN IF 2DUP 'EDIT-FILE ZPLACE 0 -ROT (EDIT-FILE) THEN ;

cr .( temporary Yosemite fixes loaded)

\\ (eof )
