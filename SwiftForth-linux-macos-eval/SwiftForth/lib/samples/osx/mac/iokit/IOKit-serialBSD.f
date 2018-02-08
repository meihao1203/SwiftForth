{ ====================================================================
access BSD serial device files in /dev

SwiftForth version
Copyright (c) 2014-2017 Roelf Toxopeus

Derived from HIDMANAGER.F
Last: 17 Apr 2017 21:09:21 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
MATCH-BSD -- returns iterator for the BSD service devices

SHOW-BSD -- displays the connected BSD devices

USBMODEM -- returns the serial usb device as a string pair

Can use kIOMasterPortDefault instead of IOMasterPort in IOServiceGetMatchingServices
Also see Device File Access Guide for Serial Devices at
https://developer.apple.com/library/content/documentation/DeviceDrivers/Conceptual/WorkingWSerial/WWSerial_SerialDevs/SerialDevices.html 

Use path found with the kIOCalloutDeviceKey i.e. IOCalloutDevice property
for !SERIAL   defined in sio.f
Note: it's just the programmatic way of finding the path.
Faster to use your eyes and wit ;-)

Example of usage in a SwiftX for OSX PROJECT.F file:

MYFOLDER
INCLUDE %SwiftX/xcomp/avr/code/swiftx-cli
USBMODEM !SERIAL
.( Arduino Uno )
\\

-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ -- Common kernel access for all IOKit stuff:

FRAMEWORK IOKit.framework
IOKit.framework

\ -- Keys:
\ see: IOKit/BSD.h
\ bsd-related registry properties
: kIOBSDNameKey ( -- a )	           Z" BSD Name" ;

\ see: IOKit/serial/IOSerialKeys.h
\ Service Matching That is the 'IOProviderClass'
: kIOSerialBSDServiceValue ( -- a )	  Z" IOSerialBSDClient" ;

\ Matching keys
: kIOSerialBSDTypeKey ( -- a )	     Z" IOSerialBSDClientType" ;

\ Currently possible kIOSerialBSDTypeKey values.
: kIOSerialBSDAllTypes ( -- a )	     Z" IOSerialStream" ;
: kIOSerialBSDModemType ( -- a )	     Z" IOModemSerialStream" ;
: kIOSerialBSDRS232Type ( -- a )	     Z" IORS232SerialStream" ;

\ Properties that resolve to a /dev device node to open for
\ a particular service
: kIOTTYDeviceKey ( -- a )	           Z" IOTTYDevice" ;
: kIOTTYBaseNameKey ( -- a )	        Z" IOTTYBaseName" ;
: kIOTTYSuffixKey ( -- a )	           Z" IOTTYSuffix" ;
: kIOCalloutDeviceKey ( -- a )	     Z" IOCalloutDevice" ;
: kIODialinDeviceKey ( -- a )	        Z" IODialinDevice" ;

\ -- Matching:
FUNCTION: IOServiceMatching ( "name" -- CFMutableDictionaryRef )
FUNCTION: IOServiceGetMatchingServices ( mach_port_t CFDictionaryRef *io_iterator_t -- ret )
GLOBAL: kIOMasterPortDefault

: CHECK-MATCH ( ret iterator -- )   0= OR ABORT" No Match!" ;

: MATCH-BSD ( -- iterator )
	kIOMasterPortDefault @
	kIOSerialBSDServiceValue IOServiceMatching
	DUP kIOSerialBSDTypeKey >cfstring kIOSerialBSDAllTypes >cfstring CFDictionarySetValue DROP
	0 >R RP@ IOServiceGetMatchingServices R> ( check return later )
	TUCK CHECK-MATCH ;

\ -- Properties:

: ZTYPE  ( za -- )  ZCOUNT TYPE ;

: .PROPERTY$ ( key dic -- )
	OVER -ROT CFSTRING@ ZCOUNT ?DUP IF
		CR 3 SPACES ROT ZTYPE 3 SPACES TYPE
	ELSE 2DROP THEN ;

FUNCTION: IORegistryEntryCreateCFProperties ( device &properties kCFAllocatorDefault kNilOptions -- ret )

: SHOW-PROPERTIES ( io_object_t:device -- )
	0 >R RP@ CFAllocatorGetDefault kNilOptions IORegistryEntryCreateCFProperties DROP
	kIOTTYDeviceKey 		R@ .PROPERTY$
	kIOTTYBaseNameKey 	R@ .PROPERTY$
	kIOTTYSuffixKey 		R@ .PROPERTY$
	kIOCalloutDeviceKey 	R@ .PROPERTY$
	kIODialinDeviceKey 	R@ .PROPERTY$
   Z" USB Product Name" R@ .PROPERTY$  \ USB	
	Z" USB Vendor Name"  R@ .PROPERTY$  \ USB
	R> CFRelease DROP ;

FUNCTION: IOIteratorNext ( io_iterator_t -- io_object_t )
FUNCTION: IOObjectRelease ( io_object_t -- ret )
FUNCTION: IOObjectGetClass ( io_object_t io_name_t -- ret )
FUNCTION: IORegistryEntryGetPath ( io_registry_entry_t io_name_t io_string_t -- ret )

: SHOW-MATCHED ( ITERATOR -- )
	BEGIN
		DUP IOIteratorNext DUP
	WHILE
		DUP CR .H  \ testing
		DUP PAD IOObjectGetClass DROP
		CR PAD ZTYPE
		\ DUP Z" IOService" ( ioservicepath ) here IORegistryEntryGetPath DROP
		\ CR 3 SPACES ( ioservicepath ) HERE ZTYPE
		DUP SHOW-PROPERTIES
		IOObjectRelease DROP
	REPEAT DROP
	IOObjectRelease DROP ;

: SHOW-BSD ( -- )  MATCH-BSD SHOW-MATCHED ;

\ ------------------------------------------------------------------------

\ only finds the first usbmodem in the dictionary.
: FIND-CALLOUT ( io_object_t:device -- a n f )
	DUP >R
	0 >R RP@ CFAllocatorGetDefault kNilOptions IORegistryEntryCreateCFProperties DROP
	kIOCalloutDeviceKey 	R@ CFSTRING@ ZCOUNT
	R> CFRelease DROP
	2DUP S" /dev/cu.usbmodem" SEARCH NIP NIP
	R> IOObjectRelease DROP ;

: >SERIALUSB ( iterator -- a n )
	BEGIN
		DUP IOIteratorNext DUP
	WHILE
		FIND-CALLOUT IF ROT DROP EXIT THEN 2DROP
	REPEAT DROP
	IOObjectRelease DROP 0 DUP ;

: USBMODEM ( -- a n )   MATCH-BSD >SERIALUSB ;

CR .( USBMODEM finder loaded)

\\ ( eof )

\ testing:
show-bsd 
E29B 
IOSerialBSDClient
   IOTTYDevice   Bluetooth-Incoming-Port
   IOTTYBaseName   Bluetooth-Incoming-Port
   IOCalloutDevice   /dev/cu.Bluetooth-Incoming-Port
   IODialinDevice   /dev/tty.Bluetooth-Incoming-Port
E29F 
IOSerialBSDClient
   IOTTYDevice   Bluetooth-Modem
   IOTTYBaseName   Bluetooth-Modem
   IOCalloutDevice   /dev/cu.Bluetooth-Modem
   IODialinDevice   /dev/tty.Bluetooth-Modem ok
