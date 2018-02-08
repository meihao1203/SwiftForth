{ ====================================================================
NIB file handling.

Copyright (c) 2006-2017 Roelf Toxopeus

Part of GUI stuff.
SwiftForth version.
An example of loading cocoanib files and showing and controlling the objects.
Last: 7 Oct 2015 12:42:19 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
NIB files are actualy bundles/folders containing XML files. These XML
files describe the GUI widgets used by an application.
Ctrl-click on a NIB file, allows you to open the bundle for inspection.

/MYNIBS -- initialise my/your working nib path. Two versions: for distro
and my setup. Needs attention !

>NIBPATH -- append nib filename to our default nibpaths as provided by
BUNDLED?. Return full path as NSString instance. It points to the Resources
folder used for nibs icns, images etc. as used in application bundles.

RESOURCES -- the default nibs path. The Resources folder.
Path does not have a nib bundle appended!

@NIB -- will load a given nibbundle from the resources folder. Does not
instantiate/unpack it. Returns a reference to the loaded nib bundle,
an NSBundle instance. Case sensitive !

*NIBOBJECTS -- will point to an NSArray with the toplevel objects
found in the most recent instantiated nib bundle.

/NIB -- unpack/instantiate the given nib bundle, uses *NIBOBJECTS.

OBJECTS? -- shows the available objects in the most recent instantiated
nib.

The combination @NIB and /NIB is enough to get the nibs loaded, instan-
tiated and on screen.

An alternative and much used way is:
NIBWINDOW.CONTROLLER -- return a NSWindowController instance build from
given NIB path. Send its @showWindow: message to display the widgets
described by the NIB.

SHOW.NIB -- display widgets described by given nibname
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ NIB paths

(*
\ for distro:
\ : /MYNIBS ( addr --  )   DUP ROOTPATH COUNT ROT ZPLACE S" swiftforth/lib/samples/osx/mac/resources/" ROT ZAPPEND ;

\ for work:
: /MYNIBS ( addr --  )   DUP ROOTPATH COUNT ROT ZPLACE S" mac/resources/" ROT ZAPPEND ;

\ initialize the pathpad with the path
: /NIBPATH ( -- a )
	BUNDLED?
			IF  DUP S" Resources/" ROT ZAPPEND
		ELSE  DUP /MYNIBS
	THEN  ;
*)

\ initialize the pathpad with the path
: /NIBPATH ( -- za )
	BUNDLED? 0= IF
		DUP >R ZCOUNT +ROOT R@ ZPLACE R>
	THEN  DUP S" Resources/" ROT ZAPPEND ;

: >NIBPATH ( za -- nsstring )    ZCOUNT /NIBPATH DUP >R ZAPPEND R> >NSSTRING ;                         

COCOACLASS NSBundle
COCOA: @initWithPath: ( nsstring:ref -- id )

: RESOURCES ( -- NSBundle:ref)   Z" " >NIBPATH NSBundle @alloc @initWithPath: ;

COCOACLASS NSNib
COCOA: @initWithNibNamed:bundle: ( nibname nsbundle:ref -- id )
COCOA: @instantiateNibWithOwner:topLevelObjects: ( owner address -- bool )  \ OSX 10.6 and OSX 10.7
COCOA: @instantiateWithOwner:topLevelObjects: ( owner address -- bool )		 \ OSX 10.8 and upwards

: @NIB ( za -- NSNib:ref )   >NSSTRING RESOURCES NSNib @alloc @initWithNibNamed:bundle: ;

VARIABLE *NIBOBJECTS

: OBJECTS? ( -- )
	*NIBOBJECTS @ DUP @count                    
	0 ?DO
		I OVER @objectAtIndex: @class class_getName ZCOUNT  CR I . SPACE TYPE
	LOOP DROP ;

\ : /NIB ( nib -- flag )  NSApp @ *NIBOBJECTS ROT  @instantiateWithOwner:topLevelObjects: ;

: /NIB ( nib -- flag )
	NSApp @ *NIBOBJECTS ROT 
	Z" instantiateWithOwner:topLevelObjects:" @selector
	OVER @respondsToSelector:
	IF @instantiateWithOwner:topLevelObjects:
	ELSE @instantiateNibWithOwner:topLevelObjects:
	THEN ;

\ --------------------------------------------------------------------
\ NIB controller

COCOACLASS NSWindowController

\ NOTE: use  @ALLOC  first !!!!!!!
COCOA: @initWithWindowNibPath:owner: ( windowNibPath owner -- id ) \ NSString object, id -- NSWindowController object
COCOA: @showWindow: ( sender -- ret ) \ id

: NIBWINDOW.CONTROLLER  ( nstring:nibpath -- ref )   NSApp @ NSWindowController @alloc @initWithWindowNibPath:owner: ;

: SHOW.NIB ( za -- windowcontroller )   >NIBPATH NIBWINDOW.CONTROLLER 0 OVER @showWindow: DROP ;

\\ ( eof )