{ ====================================================================
Save content textview to a default file

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Saving and restoring textview content to and from worksheet.f
Content is saved in RTF format as TXT.rtf
Copyright (c) 2011-2013 Roelf Toxopeus
Last: 26 February 2013 08:34:55 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
WS-READ -- overwrites given textview with TXT.rtf in WORKSHEET folder.
WS-WRITE -- saves text in given textview. Overwrites TXT.rtf and creates
(new) TXT.rtf if not existing.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOA: @writeRTFDToFile:atomically: ( (NSString:path BOOL:atomicFlag -- BOOL:flag )
COCOA: @readRTFDFromFile: ( (NSString:path -- BOOL:flag )

CREATE WS-RPATH
	POCKET 256 ERASE
	ROOTPATH COUNT POCKET PLACE
	S" worksheet/TXT.rtf" POCKET APPEND
POCKET COUNT STRING,

CREATE WS-WPATH
	POCKET 256 ERASE
	ROOTPATH COUNT POCKET PLACE
	S" worksheet" POCKET APPEND
POCKET COUNT STRING,

:  WS-READ ( textview -- )
	WS-RPATH COUNT DROP
	>NSSTRING DUP ROT @readRTFDFromFile:
	SWAP @release DROP
	0= ABORT" Worksheet read error !" ;

: WS-WRITE ( textview -- )
	WS-WPATH COUNT DROP
	>NSSTRING TUCK YES ROT @writeRTFDToFile:atomically:
	SWAP @release DROP
	0= ABORT" Worksheet read error !" ;

cr .( Worksheet tool loaded )

\\ ( eof )