{ ====================================================================
Base functionality for calling ObjC

Copyright (c) 2006-2017 Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
The main functions to deal with the ObjC Runtime, which 'runs' Cocoa.
Needs OBJC-EXTERN-CALL and OBJC-EXTERN-CALL-STRET to function properly.
Last: 9 February 2014 10:40:18 CET     -rt
==================================================================== }

{ --------------------------------------------------------------------
Cocoa.framework -- the Cocoa umbrella framework, i.e. everything connected
with Cocoa.
objc_getClass -- return class definition (id) from given class name
sel_getUid -- return selector from given method name

To do the 'call' i.e. send the message, the OS provides us with a set
of procedural C functions.
All the message sending C functions are vararg functions. The id from
the receiver and the message selector should be passed along with the
actual parameters (arguments). Some have a SUPER variant to send the message
to the super class of the receiver.

objc_msgSend -- ( id:receiver SEL:selector arg1 ... argn -- ret )
objc_msgSendSuper -- ( objc_super*:superContext SEL:selector arg1 ... argn -- ret )

objc_msgSend_stret -- ( *stretaddr id:receiver SEL:selector arg1 ... argn  -- ret )
objc_msgSendSuper_stret -- ( *stretaddr objc_super*:superContext SEL:selector arg1 ... argn  -- ret )
Sends a message with a data-structure return value to an instance of a class.
So these pass a STucture for RETurn value(s)as well: the left most parameter.

objc_msgSend_fpret -- ( id:receiver SEL:selector arg1 ... argn -- double )
Sends a message with a floating-point return value to an instance of a class.

NSApp -- a variable created by the OS for our application.
Contains our NSApplication instance ref after SHAREAPP is executed.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FRAMEWORK Cocoa.framework

FUNCTION: objc_getClass ( 0string:class -- id )
FUNCTION: sel_getUid ( 0string:method -- SEL )

\ --------------------------------------------------------------------
\ Because we use a special OBJC-CALL we only need their pointers
\ so GLOBAL: instead of FUNCTION:
GLOBAL: objc_msgSend
GLOBAL: objc_msgSendSuper
GLOBAL: objc_msgSend_stret
GLOBAL: objc_msgSendSuper_stret
GLOBAL: objc_msgSend_fpret

GLOBAL: NSApp   \ use @

\\  ( eof )
