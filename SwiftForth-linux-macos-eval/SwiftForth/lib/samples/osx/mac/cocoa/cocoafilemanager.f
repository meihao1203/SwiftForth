{ ====================================================================
File Manager

Copyright (c) 2014-2017 Roelf Toxopeus

SwiftForth version.
Implements useful file and directory utillites, using NSFileManager.
Last: 18 March 2014 08:20:57 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
(COPY-ITEM) -- expects the source and destination paths as NSString
references. You should reference the item you're copying in the
destination string as well:
 @" ~/Documents/mydoc.txt" @" ~/Desktop/mydoc.txt" (COPY-ITEM)
You don't have to quote paths with spaces, they are recognized allright.
The given NSString refs are not released.

COPY-ITEM differs from (COPY-ITEM): expects zero terminated strings
for source and destination paths. The created NSString refs will be
released.

(MOVE-ITEM) and MOVE-ITEM similar to (COPY-ITEM) and COPY-ITEM respectively,
but moving instead of copying.

RENAME-ITEM -- rename item at path pointed to by zstring a1 with newname
pointed to by zstring a2. A version of MOVE-ITEM.
-------------------------------------------------------------------- }

COCOACLASS NSFileManager
COCOA: @defaultManager ( -- object )
COCOA: @copyItemAtPath:toPath:error: ( NSString:source NSString:destination **error -- boolean )
COCOA: @moveItemAtPath:toPath:error: ( NSString:source NSString:destination **error -- boolean )
COCOA: @localizedDescription ( -- NSStringRef )  \ NSError

: (COPY-ITEM) ( NSString:source NSString:destination -- )
	0 >R RP@ NSFileManager @defaultManager @copyItemAtPath:toPath:error:
	R> SWAP 0= IF @localizedDescription >4THSTRING TYPE ELSE DROP THEN ;

: COPY-ITEM ( a1 a2 -- )
	>NSSTRING SWAP >NSSTRING SWAP
	2DUP (COPY-ITEM)
	@release DROP @release DROP ;

: (MOVE-ITEM) ( NSString:source NSString:destination -- )
	0 >R RP@ NSFileManager @defaultManager @moveItemAtPath:toPath:error:
	R> SWAP 0= IF @localizedDescription >4THSTRING TYPE ELSE DROP THEN ;

: MOVE-ITEM ( a1 a2 -- )
	>NSSTRING SWAP >NSSTRING SWAP
	2DUP (MOVE-ITEM)
	@release DROP @release DROP ;

: RENAME-ITEM  ( a1 a2 -- )
	OVER >R ZCOUNT
	R> ZCOUNT -NAME PAD ZPLACE S" /" PAD ZAPPEND
	PAD ZAPPEND
	PAD MOVE-ITEM ;

\\ ( eof )