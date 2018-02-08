{ ====================================================================
IOKit's IOService Show

SwiftForth version
Copyright (c) 2002-2017 Roelf Toxopeus

Display Devicetree. Faster than Apple's IORegistryExplorer.
Makes choosing which device you need somewhat easier.
Last: 25 Apr 2017 10:51:06 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
MATCH-IO -- return a so called iterator from a given IOService string.
           This iterator allows you to travers along the device tree
           finding all devices for the wanted IOService.

SHOW-MATCHED -- traverse IOdevice tree, printing all relevant info and
                properties belonging to services found to members of the
                given IOService.
                
.IO -- print all devices in the IOdevice tree corresponding to given
       IOService string.
       
SHOW-IO -- print the complete IOService tree, with relevant properties
           if any.

SHOW-HID -- print all IOHIDDevices

SHOW-USB -- print all USB devices

If you happen to know the name of the thing you want info on:
Z" AppleHIDMouse" .IO
Z" AppleUSBHIDKeyboard" .IO

see IOKitLib.h in /System/Library/Frameworks/IOKit.framework/Headers/
or IOKit Fundamentals at:
https://developer.apple.com/library/content/documentation/DeviceDrivers/Conceptual/IOKitFundamentals/Introduction/Introduction.html#//apple_ref/doc/uid/TP0000011-CH204-TPXREF101
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FRAMEWORK IOKit.framework
IOKit.framework

FUNCTION: IOServiceMatching ( "name" -- CFMutableDictionaryRef )
FUNCTION: IOServiceGetMatchingServices ( mach_port_t CFDictionaryRef *io_iterator_t -- ret )

GLOBAL: kIOMasterPortDefault

: CHECK-MATCH ( ret iterator -- )   0= OR ABORT" No Match!" ;

: MATCH-IO ( za -- iterator )
	IOServiceMatching
	kIOMasterPortDefault @ SWAP 0 >R RP@ IOServiceGetMatchingServices R> ( check return later )
	TUCK CHECK-MATCH ;

: Ztype  ( za -- )  ZCOUNT TYPE ;

: .PROPERTY ( key dic -- )
	OVER -ROT CFNUMBER@ DUP $DEADBEEF = IF 2DROP EXIT THEN
	CR 3 SPACES SWAP ZTYPE 3 SPACES .H ;

: .PROPERTY$ ( key dic -- )
	OVER -ROT CFSTRING@ ZCOUNT ?DUP IF
		CR 3 SPACES ROT ZTYPE 3 SPACES TYPE
	ELSE 2DROP THEN ;

FUNCTION: IORegistryEntryCreateCFProperties ( device &properties kCFAllocatorDefault kNilOptions -- ret )

: SHOW-PROPERTIES ( io_object_t:device -- )
	0 >R RP@ CFAllocatorGetDefault kNilOptions IORegistryEntryCreateCFProperties DROP
	Z" VendorID"         R@ .PROPERTY	\ HID
	Z" ProductID"        R@ .PROPERTY	\ HID
	Z" PrimaryUsage"     R@ .PROPERTY	\ HID
	Z" PrimaryUsagePage" R@ .PROPERTY	\ HID
	Z" DeviceUsage"      R@ .PROPERTY	\ HID
	Z" DeviceUsagePage"  R@ .PROPERTY	\ HID
	Z" idVendor"         R@ .PROPERTY	\ USB
	Z" idProduct"        R@ .PROPERTY	\ USB
	Z" USB Address"      R@ .PROPERTY   \ USB
	Z" locationID"       R@ .PROPERTY   \ USB
   Z" USB Product Name" R@ .PROPERTY$  \ USB	
	Z" USB Vendor Name"  R@ .PROPERTY$  \ USB
	R> CFRelease DROP ;

FUNCTION: IOIteratorNext ( io_iterator_t -- io_object_t )
FUNCTION: IOObjectRelease ( io_object_t -- ret )
FUNCTION: IOObjectGetClass ( io_object_t io_name_t -- ret )
FUNCTION: IORegistryEntryGetPath ( io_registry_entry_t io_name_t io_string_t -- ret )


FUNCTION: IOHIDDeviceCreate ( CFAllocatorRef io_service_t -- IOHIDDeviceRef )

: SHOW-MATCHED ( iterator -- )
	BEGIN
		DUP IOIteratorNext DUP
	WHILE
		DUP CR .H  \ testing
		\ CFAllocatorGetDefault over IOHIDDeviceCreate cr .h \ testing
		DUP PAD IOObjectGetClass DROP
		CR PAD ZTYPE
		DUP Z" IOService" ( ioservicepath ) HERE IORegistryEntryGetPath DROP
		CR 3 SPACES ( ioservicepath ) HERE ZTYPE
		DUP SHOW-PROPERTIES
		IOObjectRelease DROP    \ need object release?
	REPEAT DROP
	IOObjectRelease DROP ;

\ ------------------------------------------------------------------------

: .IO ( za -- )  MATCH-IO SHOW-MATCHED ;

: SHOW-IO ( -- )   Z" IOService" .IO ;

: SHOW-HID ( -- )   Z" IOHIDDevice" .IO ;

: SHOW-USB ( -- )   Z" IOUSBDevice" .IO ;

\ etc.

cr .( IOService Show loaded)
cr .( SHOW-IO    displays the IORegistry tree)
cr .( SHOW-HID   displays hid devices)
cr .( SHOW-USB   displays USB devices)

\\ ( eof )

