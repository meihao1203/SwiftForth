{ ====================================================================
Turnkey application

Copyrights (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
Creating an application bundle:
Set appropriate working directory
GILD if necessary
Make app bundle with: s" mystuff" APPBUNDLE or TURNKEY mystuff
Add your nib files and icons to the Resources folder in the bundle
Last: 21 March 2014 07:52:51 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
/APPBUNDLE -- create an application bundle directory tree in current working 
directory. Add some default files needed for the application to run.
Sets the MacOS folder in the bundle as current working directory. 
Some standard folders in the bundle are commented out, adapt to your situation.

APPBUNDLE -- saves turnkey in new created application bundle. 

TURNKEY -- as APPBUNDLE but parsing.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: /APPBUNDLE ( a n -- )
	2DUP PAD PLACE S" .app" PAD APPEND
	PAD COUNT FOLDER+          ( CR PWD )
	S" Contents" FOLDER+       ( CR PWD )
	S" Resources" FOLDER       ( CR PWD )
	\ S" Frameworks" FOLDER    ( CR PWD )
	\ S" Plugins" FOLDER       ( CR PWD )
	\ S" SharedSupport" FOLDER ( CR PWD )
	2DUP INFOPLIST-FILE
	PKGINFO-FILE
	S" MacOS" FOLDER+          ( CR PWD ) 
	APPRUN-FILE ;

: PROGRAM>BUNDLE ( a n -- )
	S" program " PAD PLACE
	PAD APPEND
	PAD COUNT EVALUATE ;

: APPBUNDLE ( a n -- )
	PUSHPATH 
	2DUP /APPBUNDLE PROGRAM>BUNDLE
	POPPATH ;

: TURNKEY ( <text> -- )   BL PARSE APPBUNDLE ;

cr .( application bundling loaded)
cr .( set appropriate workin directory)
cr .( make app bundle with:)
cr .(    s" mystuff" APPBUNDLE or TURNKEY mystuff)

\\ ( eof )
