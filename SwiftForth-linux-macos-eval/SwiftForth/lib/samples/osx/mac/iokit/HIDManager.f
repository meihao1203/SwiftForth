{ ====================================================================
IOKit HID Manager

SwiftForth version
Copyright (c) 2012-2017 Roelf Toxopeus

The HID Manager is Apple's preferred HID access
Last: 25 Apr 2017 11:06:55 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------

HIDMANAGER -- Return a HID Manager reference for matching device(s)
              described by given usagepage usage pair.
              Should check if already created !!!

/HIDMANAGER -- Create, initialize and open HID Manager to deal with
               device described by usagepage-usage pair. A copy of the
               ref is saved in a variable for releasing when closing the
               manager.
               During initialization a callback is added to add matched
               devices to device list when opening HIDManager or after
               adding a new matched device. The HIDManager is scheduled
               on the main runloop!

-HIDMANAGER -- Close and release HID manager et al

Note: a HIDmanager should be scheduled on the main runloop!
HID device property keys in IOKit/hid/IOHIDKeys.h
More info in Apple's HID Class Device Interface Guide:
https://developer.apple.com/library/content/documentation/DeviceDrivers/Conceptual/HID/intro/intro.html#//apple_ref/doc/uid/TP40000970-CH202-SW1
and IOKit/hid/IOHIDManager.h
Check IOKit/hid/IOHIDUsageTables.h for meaning UsagePage and Usage

Examle at end of file. It uses a mouse tracker which sleeps and is woken
by callback. Maximum of 2% CPU usage.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FRAMEWORK IOKit.framework
IOKit.framework

\ --- HIDManager
FUNCTION: IOHIDManagerCreate ( CFAllocatorRef IOOptionBits -- IOHIDManagerRef )
FUNCTION: IOHIDManagerGetTypeID ( -- HIDManagerType )
FUNCTION: IOHIDManagerSetDeviceMatching ( IOHIDManagerRef CFDictionaryRef -- ret )
FUNCTION: IOHIDManagerScheduleWithRunLoop ( IOHIDManagerRef CFRunLoopRef CFStringRef -- ret )
FUNCTION: IOHIDManagerUnscheduleFromRunLoop ( IOHIDManagerRef CFRunLoopRef CFStringRef -- ret )
FUNCTION: IOHIDManagerRegisterDeviceMatchingCallback ( IOHIDManagerRef IOHIDDeviceCallback  Context -- ret )
FUNCTION: IOHIDManagerOpen ( IOHIDManagerRef IOOptionBits -- IOReturn )
FUNCTION: IOHIDManagerClose ( IOHIDManagerRef IOOptionBits -- IOReturn )
FUNCTION: IOHIDManagerRegisterInputValueCallback ( IOHIDManagerRef IOHIDValueCallback Context -- ret )
( pass 0 for callbacks to unregister )

\ --- HIDDevice
FUNCTION: IOHIDDeviceGetTypeID ( -- HIDDeviceType )
FUNCTION: IOHIDDeviceGetProperty ( IOHIDDeviceRef CFStringRef -- CFTypeRef )

\ --- HIDValue
FUNCTION: IOHIDValueGetElement ( IOHIDValueRef -- IOHIDElementRef )
FUNCTION: IOHIDValueGetTimeStamp ( IOHIDValueRef -- uint64_t )
FUNCTION: IOHIDValueGetIntegerValue ( IOHIDValueRef -- CFIndex )

\ --- HIDElement
FUNCTION: IOHIDElementGetProperty ( ElementRef CFStringRef -- CFTypeRef )
FUNCTION: IOHIDElementGetCookie ( elementRef -- IOHIDElementCookie )
FUNCTION: IOHIDElementGetType ( elementRef -- IOHIDElementType )
FUNCTION: IOHIDElementGetName ( elementRef -- CFStringRef )
FUNCTION: IOHIDElementGetDevice ( elementRef -- IOHIDDeviceRef )
FUNCTION: IOHIDElementGetUsagePage ( elementRef -- usagepage )
FUNCTION: IOHIDElementGetUsage  ( elementRef -- usage )

0 CONSTANT kIOHIDOptionsTypeNone

( --- HIDManager and Dictionary creation --- )
: HIDref? ( cftyperef -- )  CFGetTypeID IOHIDManagerGetTypeID <> ABORT" not a HID type !" ;

: CREATE-HIDMANAGER ( -- IOHIDManagerRef )
	0 kIOHIDOptionsTypeNone IOHIDManagerCreate DUP 0= ABORT" Creating Manager failed !"
	DUP HIDref? ;

: CREATE-CFDICTIONARY ( -- CFDictionaryMutableRef )
	0 0 kCFTypeDictionaryKeyCallBacks @ kCFTypeDictionaryValueCallBacks @
	CFDictionaryCreateMutable DUP 0= ABORT" Creating Dictionary failed !" ;

: SET-USAGE-VALUES ( usagepage usage CFDictionaryMutableRef -- )
	ROT >CFNumber >R
	DUP 0" DeviceUsagePage" >CFSTRING R@ CFDictionarySetValue DROP
	R> CFRelease DROP
	SWAP >CFNumber >R
	0" DeviceUsage" >CFSTRING R@ CFDictionarySetValue DROP
	R> CFRelease DROP ;

( --- Match Manager and Dictionary --- )

: MATCHDEVICE ( IOHIDManagerRef CFDictionaryMutableRef -- ) IOHIDManagerSetDeviceMatching DROP ;

\ local variables for created manager and dictionary refs, needed to release them when closing manager.
VARIABLE 'HIDMANAGER
VARIABLE 'HIDDICTIONARY

: HIDMANAGER ( usagepage usage -- IOHIDManagerRef )
	CREATE-CFDICTIONARY  DUP 'HIDDICTIONARY !
	SET-USAGE-VALUES
	CREATE-HIDMANAGER DUP 'HIDMANAGER !
	DUP 'HIDDICTIONARY @ MATCHDEVICE ;

( --- Open Callback --- )
: >DEVLIST ( device addr -- )    TUCK LCOUNT 255 MIN CELLS + ! 1 SWAP +! ;

:NONAME ( context result sender HIDDevice -- ) 8 FSTACK _PARAM_3 _PARAM_0 >DEVLIST ;
4 CB: *OPENHIDCB

( --- Initialiser and Cleaner --- )
CREATE DEVLIST 256 CELLS /ALLOT

: /HIDMANAGER ( usagepage usage -- )
	HIDMANAGER DUP *OPENHIDCB DEVLIST IOHIDManagerRegisterDeviceMatchingCallback DROP
	DUP CFRunLoopGetMain kCFRunLoopDefaultMode @ IOHIDManagerScheduleWithRunLoop DROP
	kIOHIDOptionsTypeNone IOHIDManagerOpen ABORT" Can't open HIDManager !" ;

\ Close and release HID manager et al
: -HIDMANAGER ( -- )
	'HIDMANAGER @ ?DUP IF
		DUP kIOHIDOptionsTypeNone IOHIDManagerClose ABORT" Can't close HIDManager !"
		DUP CFRunLoopGetMain kCFRunLoopDefaultMode @ IOHIDManagerUnscheduleFromRunLoop DROP
		DUP 0 DEVLIST IOHIDManagerRegisterDeviceMatchingCallback DROP
		CFRelease DROP 'HIDMANAGER OFF
		'HIDDICTIONARY DUP @ CFRelease DROP OFF
	THEN ;

\ --------------------------------------------------------------------

( --- Exmample Mouse tracking --- )
1 2 2CONSTANT HID-MOUSE

: HELLO-MOUSE ( -- )  HID-MOUSE /HIDMANAGER ;

: BYE-MOUSE ( -- )  -HIDMANAGER ;

\ --- tracking mouse in task

0 TASK HIDRUNNER

2VARIABLE HIDVALUE
:NONAME ( context result sender value -- )
	8 FSTACK _PARAM_3 DUP
	IOHIDValueGetIntegerValue SWAP IOHIDValueGetElement _PARAM_0 2! HIDRUNNER WAKE ;
4 CB: *myhidcb

\ load some Apple HID utillities
FRAMEWORK HIDUtils.framework
HIDUtils.framework
FUNCTION: HIDDumpElementInfo ( IOHIDElementRef -- ret )

: .ELEMENTINFO ( int elementref -- )
  	\ DUP CR HIDDumpElementInfo DROP								\ gives full info, can leave this out 
  	\ ( CR ) DUp ." device: " IOHIDElementGetDevice .H 	\ not really interesting
  	\ DUP ." element: " .H
  	\ DUP ." type: " IOHIDElementGetType .
  	\ DUP ." name: " IOHIDElementGetName .
  	DUP ." usage: 0X" IOHIDElementGetUsage .H
  	." cookie: " IOHIDElementGetCookie .
  	." value: " . CR ;

: /HIDRUNNER ( -- )
	'HIDMANAGER @ *MYHIDCB HIDVALUE  IOHIDManagerRegisterInputValueCallback DROP ;

: -HIDRUNNER ( -- )
	'HIDMANAGER @ 0 HIDVALUE  IOHIDManagerRegisterInputValueCallback DROP ;

: HIDTRACK ( -- )
	BEGIN
		STOP	                   ( sleep until woken by hidvaluecallback )
		HIDVALUE 2@ .ELEMENTINFO ( do work and go to sleep again )
	AGAIN ;

: HIDRUN ( -- )  /HIDRUNNER  HIDRUNNER ACTIVATE HIDTRACK ;

: -HIDRUN ( -- )   HIDRUNNER DONE -HIDRUNNER ;

(* --- using an output window -------------------------------------------------------------------

PUSHPATH
MAC
INCLUDE hotcoco/sf-outview-personality.ldr
POPPATH

NEW.WINDOW HIDWIN
S" HID View" HIDWIN W.TITLE

VARIABLE HIDVIEW
: /HIDWINDOW
	HIDWIN ADD.WINDOW
	10 MS
	HIDWIN WINDOWFORTEXT
	DUP >R HIDVIEW !
	0" Monaco" 14 R> VIEWFONT
;

: HIDRUN ( -- ) 
	/HIDWINDOW  /HIDRUNNER
	HIDRUNNER ACTIVATE
   PAUSE HIDVIEW @ /TEXT>VIEW HIDTRACK ; 

--------------------------------------------------------------------------------------------- *)

cr .( HIDManager loaded)
cr .( HELLO-MOUSE     set things up)
cr .( HIDRUN          see mouse report)
cr .( -HIDRUN         stop it)
cr .( BYE-MOUSE       close and clean when done)

\\ ( eof )