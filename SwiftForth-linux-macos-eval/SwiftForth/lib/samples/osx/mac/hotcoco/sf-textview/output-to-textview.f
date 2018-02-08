{ ====================================================================
Output to TextView

Copyright (c) 2011-2017 Roelf Tooxpeus
An example of using a Cocoa window for text output.
Last: 26 February 2013 07:41:49 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
I/O 'personality' output words to a TextView in a Cocoa window.
Rather than setting up a PERSONALITY, just changing the output words.

Some actions on the textview will be performed on the main thread:
insertText:-sel

'TEXTVIEW -- variable contains textview for output
The following Forth I/O words are changed: EMIT TYPE ?TYPE and CR.
VIEW-OUTPUT -- set textiew for output, by setting the output parts of
the current personality.
SAVE-OUTPUT -- saves the current n I/O output parameters
RESTORE-OUTPUT -- restores the n I/O output parameters

Note: you can have input from Terminal console and output to Textview
window, by not restoring output.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

VARIABLE 'TEXTVIEW		\ contains current textview in use for I/O

: insertText:-sel ( -- sel )   Z" insertText:" @SELECTOR ;

1024 BUFFER: VIEWBUFFER

: TYPE>VIEW ( a n -- )
	VIEWBUFFER 1024 ERASE
	VIEWBUFFER ZPLACE VIEWBUFFER >NSSTRING >R
	INSERTTEXT:-SEL R@ YES 'TEXTVIEW @ FORMAIN DROP
	R> @release DROP
	PAUSE
;

: EMIT>VIEW ( c -- )   >R RP@ 1 TYPE>VIEW R> DROP ;

: CR>VIEW ( -- )   10 EMIT>VIEW PAUSE ;

: VIEW-OUTPUT ( textview -- )
	'TEXTVIEW ! ['] TYPE>VIEW DUP 'TYPE ! '?TYPE ! ['] EMIT>VIEW 'EMIT ! ['] CR>VIEW 'CR ! ;

: SAVE-OUTPUT ( -- ... n )  'TYPE @ '?TYPE @ 'EMIT @ 'CR @ 4 ;

: RESTORE-OUTPUT  ( ... n -- )
	4 <> ABORT" Bad arguments to RESTORE-OUTPUT !"
	'CR ! 'EMIT ! '?TYPE ! 'TYPE ! ;

cr .( TextView Output redirection loaded)

\\ ( eof )

\ example:

\ our window
NEW.WINDOW MYTVWIN
s" A Text View" MYTVWIN W.TITLE

VARIABLE MYTEXTVIEW
: /MYWINDOW ( -- )
	MYTVWIN ADD.WINDOW
	10 MS ( OSX 10.11 El Capitan quirk)
	MYTVWIN WINDOWFORTEXT
	DUP >R MYTEXTVIEW !
	0" MONACO" 14 R> VIEWFONT
;

: TT ( -- )  SAVE-OUTPUT MYTEXTVIEW @ VIEW-OUTPUT   .FILES   RESTORE-OUTPUT ;

\ try:
/MYWINDOW
TT

\ if worksheet-tools is loaded:
MYTEXTVIEW @ WS-WRITE