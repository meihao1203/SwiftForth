{ ====================================================================
sf menu

Copyright (c) 2008-2017 Roelf Toxopeus

SwiftForth version.
Add an application menu to coco-sf.
Last: 27 November 2017 at 09:54:51 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
SFMenuClass defined here. It will run the mainmenu items for coco-sf.

Forth words to run in the SFMenuClass methods:
BYE-APP -- quit coco-sf.

/CB-INTERPRETER -- Halt IMPOSTOR putting it to sleep. Initiate the
necessary USER variables, borrowing from IMPOSTOR, used by INTERPRET
and others in the INCLUDE words invoked by CB-LOAD-FILE and CB-LOAD-EDIT.
Also synchronize the dictionary related user variables with IMPOSTOR
executing <SYNC.

CB-INTERPRETER/ -- update IMPOSTOR's dictionary related user variables
executing SYNC>, resume IMPOSTOR.

CB-LOAD-FILE -- callback version of LOAD-EDIT. Init callback interpreter,
sync with IMPOSTOR's dictionary related USER variables, run LOAD-FILE and  
uodate IMPOSTOR's dictionary related USER variables.
Note: all saving and restoring USER input variables and the exception
handling is done in the INLCUDE words. No need to do it here again.

CB-LOAD-EDIT -- similar to CB-LOAD-FILE but runs LOAD-EDIT.

CB-VERBOSE -- toggles SILENT/VERBOSE for INCLUDE. Set given menuitem
according current VERBOSE state: on/off.

CB-ABORT -- defered word for the CMD. key press. Initialy set to PANIC.

PANIC -- send user interrupt to IMPOSTOR.

HELPME/2/3/4 -- launch some PDF help files. Uses the 'open' BSD command.
The PAD is used to create the string send to SYSTEM.
Alternative is using LAUNCHFILE from %mac/hotcoco/launches.f
  
The following methods will be defined for the SFMenuClass:
awakeFromNib -- when defined, internaly used by runtime at instantiating nib.
At awakeFromNib, the SFClassREF is initiated by the ObjC runtime.
SFClassREF is usefull as target for new menu items added programmaticly.

menuQuit: -- execute BYE-APP for the given sender.

menuOpenFile: -- for Open File... menu, to open file in editor
executes EDIT-FILE. 

menuLoadFile: -- for Load File... menu, executes CB-LOAD-FILE.
To be safe put IMPOSTOR to sleep while loading.
Note: Some things are very thread related, f.i. graphic contexts
Initialization of such things during including a file should be
reinitialized after including. /GWINDOW is such an initializer.
Using LOAD-FILE directly in stead of menuLoadFile: doesn't have
this problem.

menuLoadEdit: -- for Load from Editor menu item, executes CB-LOAD-EDIT.

menuVerbose: -- for the verbose/silent items. Runs CB-VERBOSE.

menuAbort: -- executes the defered CB-ABORT. Plug in what's appropriate,
for instance an exceptionhandler.
It reacts to cmd. when the coco-sf part is up front.
  
For the Help menu's:
menuHelp: -- open swiftforth-linux-osx.pdf in PDF viewer, HELPME.
menuHelp2: -- open the coco-sf readme.pdf in PDF viewer, HELPME2. 
menuHelp3: -- open dpans94.pdf in PDF viewer, HELPME3.
menuHelp4: -- open handbook.pdf in PDF viewer, HELPME4.
 
The ObjC runtime calls these when the corresponding menu's are activated.
No need to create class instance or delegate, the OS takes care.

SFMenuClass and its methods are connected to the corresponding menubar
in sfmenu.nib.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Utillities, Actions, etc.

COCOA: @terminate: ( sender -- ret )    \ NSApplication

: BYE-APP ( sender -- )   ( 'ONSYSEXIT CALLS)  NSApp @ @terminate: DROP ;

: /CB-INTERPRETER ( -- )
   IMPOSTOR SLEEP 
   /FORTH  STATE OFF IMPOSTOR #TIB HIS 2@ #TIB 2! BLK OFF
   <SYNC ;

: CB-INTERPRETER/ ( -- )    SYNC>  PROMPT  IMPOSTOR WAKE ;

: CB-LOAD-FILE ( -- )   /CB-INTERPRETER  LOAD-FILE  CB-INTERPRETER/ ;

: CB-LOAD-EDIT ( -- )   /CB-INTERPRETER  LOAD-EDIT  CB-INTERPRETER/ ;

COCOA: @mainMenu ( -- id ) \ NSMenu object
COCOA: @itemChanged: ( menuitem -- ret ) \ NSMenuItem object
VARIABLE ~VERBOSE

: CB-VERBOSE ( MENUITEM -- )
	~VERBOSE DUP @ TUCK INVERT SWAP !
		IF SILENT Z" Verbose"
		ELSE VERBOSE Z" Silent"
	THEN >NSSTRING OVER @setTitle: DROP
	NSApp @ @mainMenu @itemChanged: DROP ;

DEFER CB-ABORT

FUNCTION: pthread_kill ( thread signal# -- ret )

: PANIC ( -- )   IMPOSTOR CELL+ @ 2 pthread_kill DROP ;

FUNCTION: system ( addr -- ret )

: HELPME ( -- )
	S\" open \"" PAD ZPLACE
	ROOTPATH COUNT PAD ZAPPEND
	S\" swiftforth/doc/swiftforth-linux-macos.pdf\"" PAD ZAPPEND
	PAD system DROP ;

: HELPME2 ( -- )
	S\" open \"" PAD ZPLACE
	MACPATH COUNT +ROOT PAD ZAPPEND
	S\" doc/readme.pdf\"" PAD ZAPPEND
	PAD system DROP ;

: HELPME3 ( -- )
	S\" open \"" PAD ZPLACE
	ROOTPATH COUNT PAD ZAPPEND
	s\" swiftforth/doc/dpans94.pdf\"" PAD ZAPPEND
	PAD system DROP ;

: HELPME4 ( -- )
	S\" open \"" PAD ZPLACE
	ROOTPATH COUNT PAD ZAPPEND
	s\" swiftforth/doc/handbook.pdf\"" PAD ZAPPEND
	PAD system DROP ;

\ --------------------------------------------------------------------
\ the so called IBActions connected to the menus in the main menubar

variable SFClassREF

CALLBACK: *awakeFromNib ( rec sel -- ret )   _PARAM_0 SFClassREF ! 0 ;

CALLBACK: *menuQuit: ( rec sel sender -- n )  8 FSTACK _PARAM_2 BYE-APP 0 ;

CALLBACK: *menuOpenFile: ( rec sel sender -- n )  8 FSTACK EDIT-FILE 0 ;

CALLBACK: *menuLoadFile: ( rec sel sender -- n )  8 FSTACK CB-LOAD-FILE 0 ;

CALLBACK: *menuLoadEdit: ( rec sel sender -- n )  8 FSTACK CB-LOAD-EDIT 0 ;

CALLBACK: *menuVerbose: ( rec sel sender -- n )  8 FSTACK _PARAM_2 CB-VERBOSE  0 ;

CALLBACK: *menuAbort: ( rec sel sender -- n )  8 FSTACK CB-ABORT 0 ;

CALLBACK: *menuHelp: ( rec sel sender -- n )  8 FSTACK HELPME 0 ;

CALLBACK: *menuHelp2: ( rec sel sender -- n )  8 FSTACK HELPME2 0 ;

CALLBACK: *menuHelp3: ( rec sel sender -- n )  8 FSTACK HELPME3 0 ;

CALLBACK: *menuHelp4: ( rec sel sender -- n )  8 FSTACK HELPME4 0 ;

: menuMethodTypes ( -- addr )   0" v@:V" ;

\ --------------------------------------------------------------------
\ The ForthClass

NSObject NEW.CLASS SFMenuClass

\ --- assign callback as method to the class and register its name with the objc runtime

*awakeFromNib  menuMethodTypes 0" awakeFromNib"  SFMenuClass ADD.METHOD

*menuQuit:     menuMethodTypes 0" menuQuit:"     SFMenuClass ADD.METHOD

*menuOpenFile: menuMethodTypes 0" menuOpenFile:" SFMenuClass ADD.METHOD

*menuLoadFile: menuMethodTypes 0" menuLoadFile:" SFMenuClass ADD.METHOD

*menuLoadEdit: menuMethodTypes 0" menuLoadEdit:" SFMenuClass ADD.METHOD

*menuVerbose:  menuMethodTypes 0" menuVerbose:"  SFMenuClass ADD.METHOD

*menuAbort:    menuMethodTypes 0" menuAbort:"    SFMenuClass ADD.METHOD

*menuHelp:     menuMethodTypes 0" menuHelp:"     SFMenuClass ADD.METHOD

*menuHelp2:    menuMethodTypes 0" menuHelp2:"    SFMenuClass ADD.METHOD

*menuHelp3:    menuMethodTypes 0" menuHelp3:"    SFMenuClass ADD.METHOD

*menuHelp4:    menuMethodTypes 0" menuHelp4:"    SFMenuClass ADD.METHOD

SFMenuClass ADD.CLASS

{ --------------------------------------------------------------------
  The Nib stuff
  SFMENU -- topword, initializes the main menu and draws it.
-------------------------------------------------------------------- }

\ : SFMENU ( --  )   ['] PANIC IS CB-ABORT Z" sfmenu.nib" @NIB /NIB 0= ABORT" Can't initiate NIB !" ;
: SFMENU ( --  )   ['] PANIC IS CB-ABORT  Z" sfmenu.nib" SHOW.NIB 0= ABORT" Can't initiate NIB !" ;

cr .( menu for coco-sf loaded ...)
cr .( sfmenu   -- to add main menu to coco-sf)

\\ ( eof )