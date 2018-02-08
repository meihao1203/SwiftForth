{ ====================================================================
OSX Frameworks

Copyright (C) 2010-2017 Roelf Toxopeus

SwiftForth version.
MacForth Framework (like) words, the OSX way for access to foreign
function libraries.
Simple, crude version making use of LIBRARY.
Last: 4 October 2011 16:10:56 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
FRAMEWORK -- create name with parsed word, then run LIBRARY with a
prepared path pointing to name.framework/name

Words created with FRAMEWORK when executed will evaluate a string with
LIBRARY <frameworkpath> again, so setting it self as the current to be
searched library in 'LIB
Similar to setting context.

Note: FRAMEWORK (actualy dlopen) will search for frameworks in all the
default Frameworks directories:
/Library/Frameworks
/System/Library/Frameworks
~/Library/Frameworks

Problem with EVALUATE and LIBRARY ?
: FRAMEWORK ( SPACES<NAME> -- )
  >IN @ >R CREATE R> >IN !
  BL PARSE FRAMEWORK>LIBRARY COUNT 2DUP STRING, EVALUATE
  DOES> COUNT EVALUATE ;		\ this line is never executed...

Solving this with first compiling the DOES> part and then doing the
EVALUATE, see (FRAMEWORK)

Example FRAMEWORK usage:
framework Cocoa.framework  ok
.libs 
00900240 [REQUIRED]  /System/Library/Frameworks/Cocoa.framework/Cocoa
8FE46700 [REQUIRED]  libpthread.dylib
8FE46700 [REQUIRED]  libc.dylib ok
framework Carbon.framework  ok                                            
.libs 
0090CB50 [REQUIRED]  /System/Library/Frameworks/Carbon.framework/Carbon
00900240 [REQUIRED]  /System/Library/Frameworks/Cocoa.framework/Cocoa
8FE46700 [REQUIRED]  libpthread.dylib
8FE46700 [REQUIRED]  libc.dylib ok
function: NSRunAlertPanel ( ns" ns" ns" n n -- ret )  not in current library
cocoa.framework  ok
.libs 
0090CB50 [REQUIRED]  /System/Library/Frameworks/Carbon.framework/Carbon
00900240 [REQUIRED]  /System/Library/Frameworks/Cocoa.framework/Cocoa
8FE46700 [REQUIRED]  libpthread.dylib
8FE46700 [REQUIRED]  libc.dylib ok
function: NSRunAlertPanel ( ns" ns" ns" n n -- ret )  ok
-------------------------------------------------------------------- }

/FORTH
DECIMAL

CREATE FRAME.PAD 256 ALLOT
S" .framework" NIP CONSTANT #EXTCHARS
	
: FRAMEWORK>LIBRARY ( a1 n1 -- a2 )
	S" LIBRARY " FRAME.PAD DUP >R PLACE
	2DUP R@ APPEND									\ Library xxx.framework
	S" /" R@ APPEND								\ Library xxx.framework/
	#EXTCHARS - R@ APPEND						\ Library xxx.framework/xxx
	R> ;

: (FRAMEWORK) ( a n spaces<name> -- )
	CREATE STRING,
	DOES> COUNT EVALUATE ;
	
: FRAMEWORK  ( spaces<name> -- )
	>IN @ >R BL PARSE R> >IN !
	FRAMEWORK>LIBRARY COUNT 2DUP
	(FRAMEWORK)
	EVALUATE ;


CR .( Framework stuff loaded)

\\ ( eof )