{ ====================================================================
TextView Delegate

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Implements a delegate for a textview.
Works together with textview-personality.f
Last: 21 April 2014 08:08:42 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Very interesting:
using the textview instance as its own delegate.
The necessary delegate methods are added to the NSTextView class.
Testing preventing mouse and up/down arrow keys to change insertion point.
Only simple edit commands: escape, backspace and return.
Add commands in forthCommand? for extra editting.

Some methods need to be executed on the main thread (OPERATOR). Their
selectors are sent to OPERATOR. Only their selectors are defined here,
because you can't run them properly on a secondary thread.
Apologies for their awful names.

3 delegate methods are added to the NSTextView class:

textView:doCommandBySelector: -- issued when a text command like BS
is typed. First check if command was sent by Forth, if so ignore.
When there's a command sent by the textview, deal with it and wake
IMPOSTOR if necessary. Always return yes, we deal with it.

textView:shouldChangeTextInRange:replacementString: -- issued when
a character is type in the textview. First check if command was sent
by Forth, if so ignore. When there's a command sent by the textview,
wake IMPOSTOR and send it.	

textView:willChangeSelectionFromCharacterRange:toCharacterRange: --
this one deals with the mouse. If a mouse event caused the issue of
this method, ignore it.

/VIEWDELEGATE -- initialise a given textview as its own delegate.
-VIEWDELEGATE -- decouple the delegate.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Commands for TextView

: ESC-SEL ( -- sel )   Z" cancelOperation:" @SELECTOR ;

: BS2-SEL ( -- sel )   Z" deleteBackwardByDecomposingPreviousCharacter:" @SELECTOR ;

\ could make this a table	
: FORTHCOMMAND? ( sel -- char )
	DUP NL-SEL = IF DROP 13 EXIT THEN		\ no difference enter and return
	DUP ESC-SEL = IF DROP 27 EXIT THEN
	DUP BS-SEL = IF DROP 8 EXIT THEN
	BS2-SEL = IF 8 EXIT THEN
	0 ;

CALLBACK: *textView:doCommandBySelector: ( rec sel sender:textview command:selector -- bool )
	<FORTH> @ IF  <FORTH> OFF  NO EXIT THEN		\ this message was triggered by Forth doing TYPE
	_PARAM_3 FORTHCOMMAND? ?DUP IF
	   (CBUF) GET  CBUF C!  (CBUF) RELEASE
	   IMPOSTOR WAKE PAUSE
	THEN YES ;

: TYPESDOCOMMAND   0" c@:@:" ;

\ --------------------------------------------------------------------
\ Characters for TextView

CALLBACK: *textView:shouldChangeTextInRange:replacementString: ( rec sel sender:textview range:location range:lenght nsstring:string -- bool )
	<FORTH> @ IF <FORTH> OFF YES EXIT THEN		\ this message was triggered by Forth doing TYPE
	_PARAM_5 >4THSTRING 1 = IF
	   (CBUF) GET  C@ CBUF C!  (CBUF) RELEASE
	   IMPOSTOR WAKE  NO  PAUSE
	ELSE DROP YES THEN ;

\ : typesShouldChange   0" c@:@{NSRange=II)@" ;
: TYPESSHOULDCHANGE  0" c24@0:4@8{_NSRange=II}12@20" ; \ this is retrieved from shouldChangeTextInRange:replacementString:

\ --------------------------------------------------------------------
\ Mouse will not change insertion point
(* mouse events, less than 5
 1 CONSTANT NSLeftMouseDown
 2 CONSTANT NSLeftMouseUp
 3 CONSTANT NSRightMouseDown
 4 CONSTANT NSRightMouseUp
*)

COCOA: @currentEvent ( -- event )
COCOA: @type ( -- type )

: MOUSE-EVENT? ( -- f )	  NSApp @ @currentEvent @type 5 < ;

CALLBACK: *textView:willChangeSelectionFromCharacterRange:toCharacterRange: ( rec sel textview loc1 len1 loc2 len2 -- loc3 len3 )
	MOUSE-EVENT? IF
			_PARAM_3 _PARAM_4
	ELSE  _PARAM_5 _PARAM_6
	THEN >2RET ;

: TYPESRANGE ( -- addr )   0" " ; \ can't find type encoding, try nil string

\ --------------------------------------------------------------------
\ Add the necessary delegate methods to the NSTextView class:

*textView:doCommandBySelector:
TYPESDOCOMMAND
0" textView:doCommandBySelector:"
NSTextView ADD.METHOD

*textView:shouldChangeTextInRange:replacementString:
TYPESSHOULDCHANGE
0" textView:shouldChangeTextInRange:replacementString:" 
NSTextView ADD.METHOD

*textView:willChangeSelectionFromCharacterRange:toCharacterRange:
TYPESRANGE
0" textView:willChangeSelectionFromCharacterRange:toCharacterRange:" 
NSTextView ADD.METHOD

\ --------------------------------------------------------------------
\ Delegation: 'self' will be the delegate

COCOA: @setDelegate: ( id -- ret ) \ NSTextView
COCOA: @delegate ( -- id )         \ NSTextView

: /VIEWDELEGATE ( NSTextViewRef -- )
	CBUF OFF
	DUP @setDelegate: DROP ;

: -VIEWDELEGATE  ( NSTextViewRef -- )   0 SWAP @setDelegate: DROP ;

cr .( TextView I/O Delegate loaded)

\\ ( eof )