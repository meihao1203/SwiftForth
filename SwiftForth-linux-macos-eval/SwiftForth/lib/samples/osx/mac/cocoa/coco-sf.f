{ ====================================================================
Cocoa Interface

Copyright (c) 2008-2017 Roelf Toxopeus

SwiftForth version.
Using ObjC version 2.0
Including necessary cocoa functionality
Last: 16 November 2017 at 15:52:54 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Portability.

If for some reason you can't use a system specific objc-extern.f,
replace the first three INCLUDES with:

INCLUDE cocoa/port/cocoacore-port.f			\ fundamental C functions to call ObjC
INCLUDE cocoa/port/cocoabridge-port.f		\ the ObjC message sender
-------------------------------------------------------------------- }
 
CR .( Loading Cocoa interface ...)

/FORTH
DECIMAL

PUSHPATH
MAC

\ --------------------------------------------------------------------
\ interface to ObjC 2 Runtime

INCLUDE cocoa/objc-extern.f					\ EXTERN-CALL reworked for ObjC
INCLUDE cocoa/cocoacore.f						\ fundamental C functions to call ObjC
INCLUDE cocoa/cocoabridge.f				   \ the ObjC message sender
INCLUDE cocoa/cocoaclass.f						\ existing ObjC class interface
INCLUDE cocoa/cocoafunc.f						\ existing ObjC message interface
INCLUDE cocoa/cocoagoodies.f					\ usefull ObjC messages/utillities

\ --------------------------------------------------------------------
\ adding new classes with Forth methods

INCLUDE cocoa/objc-structures-v2.f			\ ObjC 2 structures
INCLUDE cocoa/objc-class-v2.f					\ new ObjC class creation
INCLUDE cocoa/objc-methods-v2.f				\ new ObjC methods creation
INCLUDE cocoa/objc-ivars-v2.f					\ new ObjC instance variable creation

\ --------------------------------------------------------------------
\ adding Cocoa event handling to Forth

INCLUDE cocoa/sftococoa.f					   \ converts unix app to GUI app
INCLUDE cocoa/cocoathreadaware.f				\ make our NSApp aware of threads
INCLUDE cocoa/cocoaforth.f					   \ queue Forth xt's on the main eventloop
INCLUDE cocoa/impostor.f					   \ move Forth to another thread
INCLUDE cocoa/cocoalaunch-main-thread.f	\ move Forth to IMPOSTOR, launch NSApp on OPERATOR

\ --------------------------------------------------------------------
\ GUI stuff

INCLUDE cocoa/nswindow.f						\ the window interface
INCLUDE cocoa/window-utils.f					\ extra window utillities
INCLUDE cocoa/cocoafilemanager.f				\ the NSFileManager item copy/movers
INCLUDE cocoa/cocoanibs.f						\ nib file interface

\ --------------------------------------------------------------------
\ useful

INCLUDE cocoa/cocoafilekite.f					\ file chooser 'kitebox'
INCLUDE cocoa/cocoaeditfile.f					\ EDIT-FILE redefined, using kitebox for choice
INCLUDE cocoa/cocoapaste.f						\ scrap/clipboard interface

\ --------------------------------------------------------------------
\ specific OS handling

INCLUDE cocoa/no-nap.f							\ deals with App Nap in 10.9 and upwards

\ --------------------------------------------------------------------
\ startup for turnkey

INCLUDE cocoa/cocoastarter.f					\ the main COCO-SF starter

POPPATH

\\ ( eof )