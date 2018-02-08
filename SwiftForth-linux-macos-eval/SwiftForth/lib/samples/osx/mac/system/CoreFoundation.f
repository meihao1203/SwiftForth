{ ====================================================================
CoreFoundation

Copyright (c) 2001-2017 Roelf Toxopeus

SwiftForth version.
Handy Corefoundation utillities from Ward and Roelf.
More stuff gets in and out...
Last: 2 December 2017 at 21:43:32 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
CoreFoundation.framework -- liason framework, C API.

>CFSTRING -- create CFStringRef from given 0string or cstring.
Use CFRelease when done with string.
CF" -- convert following string to a CFString, works like S"
Use CFRelease when done with string.
CFSTRING> -- convert CFString to 0string in pocket.
Take care of it immediate. Aborts if not a CFString !

>CFNUMBER -- create CFNumber from given integer.
Use CFRelease when done with number.
CFNUMBER> -- convert CFNumber to integer

CFNUMBER@ -- using key-id, fetch number from CFDictionary
CFSTRING@) -- using key-id, fetch zstring from CFDictionary

>CFURL -- create a CFURL from given zstring. Allows Posix pathstyle
with spaces it seems. Use CFRelease when done with url.

Note: return from CFAllocatorGetDefault changes with machines and OS,
-1598992704 on 10.6 and -1407864448 on 10.7
CFAllocatorGetDefault CONSTANT myCFAllocatorSystemDefault
won't survive running turnkeyed 10.6 coco-sf on 10.7 
better to use 0 were possible
or  CFAllocatorGetDefault
or	(the global) kCFAllocatorSystemDefault @

Tip: in general when using CoreFoundation API, anything that is
returned by an API with "Get" in the name does not need to be released,
and anything returned by an API with "Create" or "Copy" in the name
DOES need to be released.
CFGetRetainCount -- returns reference count from CFTypeRef, should go
to 0 if we created the CFTypeRef, to avoid memory leaks.
CFRelease to decrement and CFRetain to increment the reference count.
Reference count = 0 means memory will be deallocated by OS.
Quitting the app (Forth) has same effect.
-------------------------------------------------------------------- }


/FORTH
DECIMAL

FRAMEWORK CoreFoundation.framework

\ --------------------------------------------------------------------
\ used a lot

FUNCTION: CFAllocatorGetDefault ( -- CFAllocatorRef )
FUNCTION: CFRelease ( CFTypeRef -- ret )
FUNCTION: CFRetain ( CFTypeRef -- CFTypeRef )
FUNCTION: CFGetRetainCount ( CFTypeRef -- CFIndex )

0 CONSTANT kNilOptions

GLOBAL: kCFAllocatorSystemDefault

\ --------------------------------------------------------------------
\ info

FUNCTION: CFShow ( CFTypeRef -- ret )	\ show information about CFTypeRef in CONSOLE
FUNCTION: CFGetTypeID ( CFTypeRef -- CFTypeID )

\ --------------------------------------------------------------------
\ CFArray

FUNCTION: CFArrayCreate ( CFAllocatorRef **values numValues CFArrayCallBacks -- CFArrayRef )
FUNCTION: CFArrayCreateMutable ( CFAllocatorRef capacity CFArrayCallBacks -- CFMutableArrayRef )

\ --------------------------------------------------------------------
\ CFString stuff

FUNCTION: CFStringCreateWithCString ( CFAllocatorRef ^0Str CFStringEncoding -- CFStringRef )
FUNCTION: CFStringCreateWithBytes ( CFAllocatorRef addr cnt CFStringEncoding externalFlag -- CFStringRef )
FUNCTION: CFStringCreateWithPascalString ( CFAllocatorRef pStr CFStringEncoding -- CFStringRef )

FUNCTION: CFStringGetIntValue    ( CFStringRef -- u )
FUNCTION: CFStringGetDoubleValue ( CFStringRef -- ud )

FUNCTION: CFDataGetLength ( CFDataRef -- u )
FUNCTION: CFDataGetBytes ( CFDataRef startCFIndex endCFIndex ^buffer -- ret )
FUNCTION: CFStringGetCString ( CFStringRef *buffer bufferSize CFStringEncoding -- Boolean )

0 CONSTANT kCFStringEncodingMacRoman

: >CFSTRING ( zaddr -- CFStringRef )   0 SWAP kCFStringEncodingMacRoman CFStringCreateWithCString ;

: CF" ( <string>"  -- CFStringRef )
	[COMPILE] 0"
	STATE @   IF	 POSTPONE >CFSTRING  ELSE  >CFSTRING  THEN ; IMMEDIATE

: CFSTRING> ( CFStringRef -- zaddr )     POCKET TUCK 256 kCFStringEncodingMacRoman CFStringGetCString 0= ABORT" Not a CFString !" ;
	
\ --------------------------------------------------------------------
\ CFNumber utillities

FUNCTION: CFNumberCreate ( CFAllocatorRef CFNumberType *valuePtr -- CFNumberRef )
FUNCTION: CFNumberGetValue ( object kCFNumberLongType &number -- ret )

 9 CONSTANT kCFNumberIntType
10 CONSTANT kCFNumberLongType

: >CFNUMBER ( u -- CFNumberRef )  >R 0 kCFNumberIntType RP@ CFNumberCreate R> DROP ;

: CFNUMBER> ( CFNumberRef -- u ) kCFNumberLongType 0 >R RP@ CFNumberGetValue DROP R> ;

\ --------------------------------------------------------------------
\ CFDictionary things

FUNCTION: CFDictionaryCreateMutable ( allocator capacity *keyCallBacks *valueCallBacks -- CFMutableDictionaryRef )
FUNCTION: CFDictionarySetValue ( dictionary cfstring:key cfnumber:value -- ret )
FUNCTION: CFDictionaryGetValue ( dictionary cfstring:key -- CFTypeRef:object )
FUNCTION: CFDictionaryContainsKey ( dictionary string -- flag )
FUNCTION: CFDictionaryGetCount ( dictionary -- CFIndex )
FUNCTION: CFDictionaryGetKeysAndValues ( dictionary *keys *values -- ret )

GLOBAL: kCFCopyStringDictionaryKeyCallBacks
GLOBAL: kCFTypeDictionaryKeyCallBacks
GLOBAL: kCFTypeDictionaryValueCallBacks

: CFNUMBER@ ( key dictionary -- n )
	SWAP >CFSTRING CFDictionaryGetValue DUP 0= IF DROP $DEADBEEF EXIT THEN
	CFNUMBER> ;

: CFSTRING@ ( key dictionary -- zaddr )
	SWAP >CFSTRING CFDictionaryGetValue DUP 0= IF DROP 0" " EXIT THEN
	CFSTRING> ;

\ --------------------------------------------------------------------
\ CFRunLoop

FUNCTION: CFMachPortCreateWithPort ( CFAllocatorRef portnum CFMachPortCallBack CFMachPortContext Boolean -- CFMachPort )
FUNCTION: CFRunLoopGetCurrent ( -- CFRunLoopRef )
FUNCTION: CFRunLoopGetMain ( -- CFRunLoopRef )
FUNCTION: CFMachPortCreateRunLoopSource ( CFAllocatorRef CFMachPortRef CFIndex -- CFRunLoopSourceRef )
FUNCTION: CFRunLoopAddSource ( CFRunLoopRef CFRunLoopSourceRef CFStringRef:mode -- ret )
FUNCTION: CFRunLoopContainsSource ( CFRunLoopRef CFRunLoopSourceRef CFStringRef:mode -- Boolean )

GLOBAL:   kCFRunLoopDefaultMode

\ --------------------------------------------------------------------
\ CFURL stuff

(*
FUNCTION: CFURLCreateWithString ( CFAllocatorRef CFStringRef:URLString CFURLRef:baseURL -- CFURLRef )

: >CFURL ( zaddr -- CFURLRef )
		( kCFAllocatorSystemDefault @ ) 0 SWAP >CFSTRING 0 CFURLCreateWithString ;
*)

FUNCTION: CFURLCreateWithFileSystemPath ( allocator CFString:filePath pathStyle isDirectory	-- CFURLRef )

: >CFURL ( za -- CFURLRef )
	>CFSTRING DUP >R
	( kCFAllocatorSystemDefault @ ) 0
	SWAP
	( kCFURLPOSIXPathStyle ) 0
	( = not a directory ) 0 CFURLCreateWithFileSystemPath
	R> CFRelease DROP ;

CR .( Corefoundation words loaded)

\\ ( eof )