{ ====================================================================
bundlecheck

Copyright (c) 2013-2017 Roelf Toxopeus

Check we're launched from an appbundle or not. Allows to find our
resources.
Last: 2 April 2014 22:23:50 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
BUNDLED? -- check we're bundled, return usefull path depending on flag
true  -> return appbundlepath/Contents/
Usefull when we have to search through our bundled resources, frameworks, plugins etc.
false -> return macpath.
Note: zstring path !!!!!!!!!!
-------------------------------------------------------------------- }

/FORTH
DECIMAL

s" .app/Contents/" NIP CONSTANT #KEEPCHARS

: BUNDLED? ( -- zstring f )
	PATHPAD DUP >R 1024 ERASE
	THIS-EXE-NAME 2DUP S" .app" SEARCH
					IF  NIP #KEEPCHARS - - R@ ZPLACE TRUE
			ELSE  2DROP 2DROP MACPATH COUNT R@ ZPLACE FALSE
	THEN  R> SWAP ;

CR .( bundlechecker loaded)

\\ ( eof )
