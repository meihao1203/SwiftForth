{ ====================================================================
Load scrap/paste/clipboard

Copyright (c) 2010-2017 Roelf Toxopeus

SwiftForth version.
Dealing with scrap on the main pasteboard a.k.a. Clipboard
Last: 5 March 2014 15:18:56 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
For now only looking for text scrap (from editors).

PUT.SCRAP -- paste/put string in clipboard. Returns true if succes.
GET.SCRAP --  copy/get text from clipboard. Returns string pair if succes,
false flag if not.
INTERPRET-MAPPED -- interprets the mapped clipboard text. Uses parts from
INCLUDE-FILE in sf.
Setting 'SOURCE-ID to -2 indicates scrap is source.
LOAD-SCRAP -- include/load contents clipboard if any.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSPasteboard

COCOA: @generalPasteboard ( -- id ) \ NSPasteboard object
: CLIPBOARD ( -- ref ) NSPasteboard @generalPasteboard ;

COCOA: @dataForType: ( type -- data ) \ NSstring object -- NSData object
GLOBAL: NSPasteboardTypeString  ( text type, in NSPasteboard.h )

\ temporary fix, hard coded, take care:
\ : paste.string.type	( -- NSString:object )   @" public.utf8-plain-text" ;
	
: scrap.text ( -- a | 0 )
	NSPasteboardTypeString @		\ problem when run on other OSX than compiled
	\ paste.string.type dup >r		\ fix
	CLIPBOARD @dataForType:
	\ r> @release drop ;				\ fix
;

COCOA: @clearContents ( -- n )		\ NSInteger
COCOA: @setString:forType: ( string datatype -- flag ) \ NSString object, NSstring object -- BOOL

: PUT.SCRAP ( a n -- bool )
	CLIPBOARD @clearContents DROP
	PAD ZPLACE PAD >NSSTRING
	NSPasteboardTypeString @		\ problem when run on other OSX than compiled
	\ paste.string.type dup >r		\ fix
	CLIPBOARD @setString:forType:
	\ r> @release drop ;				\ fix
;

COCOA: @stringForType: ( type -- concatstring ) \ NSString object -- NSString object

: GET.SCRAP ( -- a n | 0 )
	NSPasteboardTypeString @		\ problem when run on other OSX than compiled
	\ paste.string.type dup >r		\ fix
	CLIPBOARD @stringForType:
	DUP IF >4THSTRING THEN
	\ r> @release drop ;				\ fix	
;

\ --------------------------------------------------------------------
\ Include contents clipboard.

: INTERPRET-MAPPED ( -- )
	SAVE-INPUT N>R  >IN OFF  LINE OFF
	-2 'SOURCE-ID !    \ added 24 February 2014 10:25:53 CET -rt
	BEGIN  REFILL-NEXTLINE  WHILE  MONITOR INTERPRET  REPEAT
	NR> RESTORE-INPUT DROP ;

: LOAD-SCRAP ( -- )
	GET.SCRAP DUP IF >MAPPED 2!  INTERPRET-MAPPED  EXIT THEN
	DROP ;

\\ ( eof )