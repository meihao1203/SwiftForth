{ ====================================================================
Run coco-sf

Copyright (c) 2009-2017 Roelf Toxopeus

Part of adding Cocoa event handling to Forth.
SwiftForth version.
Running a cocoa interface on the main thread
Last: 12 November 2017 at 09:14:51 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
The ObjC interface will not work properly when it isn't run on the main
thread. At least wrt GUI and graphic stuff. One way to solve this is
the following:
Cocoa can run on main thread and QUIT on another in SwiftForth. In this
case the main thread, OPERATOR, is lost for further direct interaction
and you lose the main thread's privileges. Use FORMAIN or PASS for those
situations.

/COCOALINKS -- relink all our cocoa and cocoa related words before
we can use them safely in turnkey.
INIT.COCOA -- initialise, launch the NSApp part of coco-sf and make
NSApp multi threading aware. This should happen _before_ PRETENDING
so the Cocoa framework is protected.

RUNCOCOA -- ignore sigint signals and run the NSApplication run method.
THREAD-IGNORE-SIGINT runs _after_ PRETENDING so IMPOSTOR will not inherit
OPERATOR's new SIGINT mask.

COCO.RUN -- topword: init, launch and run coco-sf. Cocoa on main thread
and Forth on another, side by side.

Note: main thread will save autoreleasepool in mainpool (see SF>COCOA).
might be drained automaticly by main thread, so saved pool is not valid
after a while.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ initialise and launch the NSApp part of coco-sf

: /COCOALINKS ( -- )
	/COCOACLASSES /COCOASELECTORS
	/FORTH-COCOACLASSES /FORTH-COCOACLASSMETHODS /FORTH-COCOAMETHODS /FORTH-COCOAIVARS ;
	
: INIT.COCOA ( -- )   /COCOALINKS  SF>COCOA  MULTI.AWARE ;
	
\ --------------------------------------------------------------------
\ setup IMPOSTOR running Forth and OPERATOR runnning Cocoa.
	
COCOA: @run ( -- ret )
: RUNCOCOA ( -- )   THREAD-IGNORE-SIGINT NSApp @ @run DROP ;

: COCO.RUN ( -- )   INIT.COCOA PRETENDING RUNCOCOA ;

\\ ( eof )
