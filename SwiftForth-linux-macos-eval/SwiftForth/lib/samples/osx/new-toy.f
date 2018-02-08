{ ====================================================================
toy application

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Turnkey Cocoa extended Darwin Forth, here SwiftForth OSX. The new coco-sf
is a bundled application. A double clickable icon: sf-app.
Last: 20 November 2017 at 22:36:58 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Example of creating an application.
 
Using vanilla sf, include this file and in 5 steps a native OSX
application bundle is created: sf-app. Which is coco-sf with its own
I/O window and menubar independently from Terminal.app.

Note 1: words defined in a file which executes PROGRAM can't be located.
Their sourcefile won't be registered, until INCLUDE-FILE in INCLUDED
is finished. This is remedied by executing  F# @ 'FNAME @  =FILENAME
inside the file executing PROGRAM.

Note 2: when you put the bundled application in the same parent folder
as your SwiftForth folder, you enjoy the benefits of EDIT, LOCATE, G
and the Help menu's. The folder structures are similar, same depths.
Conveniently this is ROOTPATH.

WARNING: this version of coco-sf *is*a*toy* version. It uses a very
primitive I/O window compared with the Terminal window as used by sf
and the regular coco-sf. A lot more additions and debugging should be
applied. Use at your own risk.
-------------------------------------------------------------------- }

CR .( --------------------------------------------------------------------)
CR .( 1. Including the Forth, OS and Cocoa extensions and interfaces)

/FORTH
DECIMAL

INCLUDING -NAME PAD FULLNAME
S" /mac/" PAD ZAPPEND
PAD chdir DROP    						\ change directory to /wherever/mac

INCLUDE mac-sf.f	              	   \ the regular coco-sf stuff

CR .( --------------------------------------------------------------------)
CR .( 2. The added GUI items and extras on top of coco-sf)

PUSHPATH MAC
INCLUDE hotcoco/sfmenu.f				\ main menubar
INCLUDE hotcoco/sf-textview.f 		\ textview I/O console
INCLUDE utils/myok.f                \ for fun the Mach2 prompt
POPPATH

CR .( --------------------------------------------------------------------)
CR .( 3. Necessary redefinitions)

\ can't return to terminal console
: /TERMINAL ( -- )   1 ABORT" Can't !" ;

\ possibly quit the Terminal when SF is detached
: BYET ( -- )   S" $ killall Terminal" EVALUATE ;

\ need a new BYE, which stops the NSApplication coco-sf
: (APP-BYE) ( -- )
   ?TTY @ IF  'ONENVEXIT CALLS  THEN
	'ONSYSEXIT CALLS  NSApp @ DUP @terminate: ;

\ adapt BYE, the original is (BYE) in case you need it
' (APP-BYE) IS BYE

\ after launch with nohup, our parent process, the bash shell, is stil around.
\ for now we end it here, better would be in the apprun script, but I don't know how.
\ BTW we don't exit Terminal.app !! It could be doing other things as well. See BEYT.

System.framework

FUNCTION: getppid ( -- ppid )
FUNCTION: kill ( pid n -- ret )

\ signal parent process to quit.
: -PARENT ( -- )   getppid 9 2 0 ['] kill PASS PAUSE ;

\ two redefinitions to make it work out of the box:
\ 1. first thing to do in Forth thread
: GOES.FORTH ( -- )
	PAUSE
	( /INTERPRETER )  /CMDLINE			\ regular sf inits, QUIT executes /INTERPRETER as well -rt
	/RND									   \ coco-sf inits: prng
	ForthClass ADD.CLASS				   \ coco-sf inits: Forth class
	NONAP										\ coco-sf inits: appnap setting
	SFMenuClass ADD.CLASS SFMENU	   \ toy app inits: menu class
	\ BYET   							   \ toy app inits: optional
	PUSHME								   \ toy app inits: make our app the front app
	/OK									   \ toy app inits: mach2 prompt
	-PARENT									\ toy app inits: end bash parent process
	/COCOA-CONSOLE ; 					   \ toy app inits: the cocoa console running Forth
 
\ 2. same as the original version, but uses new GOES.FORTH
: HOT.COCO ( -- )   ['] GOES.FORTH 'PRETENDING ! COCO.RUN ;

\ overwrite previous starter
STARTER HOT.COCO

CR .( --------------------------------------------------------------------)
CR .( 4. Turnkey app)

PUSHPATH
MAC
INCLUDE bundling/bundling.f		   \ necessary turnkey tools
POPPATH

\ keep current included filename for locate
F# @ 'FNAME @  =FILENAME

GILD

\ Create our app in ROOTPATH:
ROOTPATH COUNT PAD ZPLACE
PAD chdir DROP

TURNKEY sf-app

CR .( --------------------------------------------------------------------)
CR .( 5. Add sfmenu.nib and app.icns to bundle)

\ assumes these 'files' exists in the default resources folder:
S" sfmenu.nib" S" sf-app"  COPY-RESOURCE
S" app.icns"   S" sf-app"  COPY-RESOURCE

CR .( --------------------------------------------------------------------)
CR .( 6. Quit)

(BYE)            \ the default Forth bye, we're still in vanilla sf

\\ ( eof )