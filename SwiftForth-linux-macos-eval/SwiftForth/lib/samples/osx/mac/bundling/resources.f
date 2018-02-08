{ ====================================================================
bundle resources

Copyrights (c) 2014-2017 Roelf Toxopeus

SwiftForth version.
Implements resource utillities like COPY-RESOURCE.
Last: 29 October 2015 at 13:13:16 GMT+1   -rt
==================================================================== }

{ --------------------------------------------------------------------
Convenient way to copy resources like nib bundles and icon files, from
the development path as indicated by >NIBPATH to the appropriate Resources
folder inside an application bundle.
COPY-RESOURCE -- copies resource (a1 n2) to app(a2 n2) bundle Resources
folder.

Example usage:
S" sfmenu.nib" S" sf-app"  COPY-RESOURCE
S" app.icns"   S" sf-app"  COPY-RESOURCE
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: COPY-RESOURCE ( a1 n2 a2 n2 -- )
	PAD >R
	CWD ZCOUNT R@ ZPLACE
	R@ ZAPPEND
	S" .app/Contents/Resources/" R@ ZAPPEND
	2DUP R@ ZAPPEND
	R@ ZCOUNT + CHAR+ DUP >R ZPLACE R> >NIBPATH   \ NSStringRef source, >NIBPATH takes zerostring, uses next available PAD storage
	R>  >NSSTRING   \ NSStringRef destination
	2DUP (COPY-ITEM) @release DROP @release DROP ;

\\ ( oef )