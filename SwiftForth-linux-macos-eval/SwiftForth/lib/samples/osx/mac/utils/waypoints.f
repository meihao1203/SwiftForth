{ ====================================================================
waypoints

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Usefull words to set current working directory, works like setting
a context vocabulary. Also working directory utillities.
Last: 16 October 2014 09:24:17 CEST  rt
==================================================================== }

/FORTH
DECIMAL

{ --------------------------------------------------------------------
MAX-PATH -- returned value inherited from PATH_MAX found in
usr/include/sys/syslimits.h
PATHPAD -- buffer for creating and receiving path strings.

CHWD -- changes working directory, takes care of saving cwd before changing it.
Like CD but takes path from the stack.

CWD -- get current working directory in PATHPAD (1024 max), zero terminated.
WHAMI -- returns current working directory as string pair.
Note: both using the PADPATH instead of PAD. Could be a factor of PWD,
which prints the string.
-------------------------------------------------------------------- }

1024 CONSTANT MAX-PATH
MAX-PATH BUFFER: PATHPAD

: CHWD ( a n -- )	\ name is a joke of course, chew on it ;-)
	(CD) !OLDPWD  chdir ABORT" Invalid Directory !" ;

: (CWD) ( -- zstring )   PATHPAD MAX-PATH getcwd ;

: CWD ( -- zstring )   (CWD) >R S" /" R@ ZAPPEND R> ;

: WHAMI ( -- a n )   (CWD) ZCOUNT ;

{ --------------------------------------------------------------------
MAC is the pivotal directory for the Cocoa package. It uses MACPATH,
set during compilation of coco-sf and relative to ROOTPATH. It is
assumed you keep the SwiftForth and mac folders in the same relation
as during compilation of coco-sf. Otherwise MACPATH is invalid.
SWIFTFORTH, ROOT, HOME and DESKTOP allow for quick and easy access to
these default directories.
Note: ROOTPATH contains full path up till the SwiftForth folder.
So as alternative   : ROOT ( -- )   ROOTPATH COUNT CHWD ;

From MacForth: MYFOLDER -- set directory from file being included as
the current working directory. Further including can commence from this
directory as parent. Only from within INCLUDED/LOADED file!!!
INCLUDING ought to return a zero string when nothing is INCLUDED? It
appears it returns a 1 length zero string, so check for anything bigger
than 1.
Avoid getting lost, use with care.
-------------------------------------------------------------------- }

: MAC ( -- )         MACPATH COUNT +ROOT CHWD ;
: SWIFTFORTH ( -- )  S" %SwiftForth" +ROOT CHWD ;
: ROOT ( -- )        S" %" +ROOT CHWD ;
: HOME ( -- )        $HOME !OLDPWD  chdir ABORT" Invalid Directory" ;
: DESKTOP ( -- )     HOME S" Desktop" CHWD ;

: MYFOLDER ( -- )
	INCLUDING DUP 2 < ABORT" Only use MYFOLDER while loading a file"
   -NAME CHWD ;

CR .( Waypoints loaded)

\\ ( eof )
