{ ====================================================================
create new coco-sf

Copyright (c) 2011-2017 Roelf Toxopeus

Turnkey Cocoa extended Darwin Forth, here SwiftForth OSX. The new coco-sf
can be found in the SwiftForth bin folder.
Last: 17 November 2017 at 10:40:37 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Portability:
Each Darwin Forth has its own words to create a turnkey, so re-code
here for specific Forth system.

Directory independant:
You can place the mac folder and this file wherever you want.
Put them in  %swiftforth/lib/samples/osx/   or place them in %swiftforth/../
Important: keep this file and the mac folder together. This file must
be in the parent folder of the mac folder, to work out of the box.
Of course you can change things...

This is a 'wrapper' around the Cocoa extensions loader. It automaticly
turnkeys the system. Words defined in a file which executes PROGRAM
can't be located. Their sourcefile won't be registered, until INCLUDE-FILE
in INCLUDED is finished. This file is kept clean of definitions.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

INCLUDING -NAME PAD FULLNAME
S" /mac/" PAD ZAPPEND
PAD chdir DROP    			\ change directory to /wherever/mac

INCLUDE mac-sf.f

\ --------------------------------------------------------------------
\ save dictionary and turnkey as coco-sf

GILD

CD %swiftforth/bin/osx
PROGRAM coco-sf
CR .( new coco-sf in store:)
CR PWD
BYE

\\ ( eof )