{ ====================================================================
Output to TextView using a Personality change

SwiftForth version
Copyright (c) 2011-2017 Roelf Tooxpeus

An example of using a Cocoa window for text output.
Utility file for sf-outview-personality.ldr
Last: 17 Apr 2017 20:16:27 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
[TV -- open a personality for outputting text to given textview,
       and save current personality.
       
TV] -- close the personality and restore previous personality.

Note: you need to use these as a pair, when used in a regular
I/O console (REPL). The input words are noop's in this personality,
resulting in a CR stream send to the console.
There is no recovering from that!

Use /TEXT>VIEW when you can't be bothered to have input. Like output
windows for (background) tasks.

See sf-outview-personality.ldr what more is needed.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: NULL ( -- n )   0 ;
: NOBUF ( n1 n2 -- n3 )  2DROP 0 ;

CREATE TEXT>VIEW-MODE
        16 ,            \ datasize
        19 ,            \ maxvector
         0 ,            \ PHANDLE
         0 ,            \ PREVIOUS
   ' NOOP ,             \ INVOKE    ( -- )
   ' NOOP ,             \ REVOKE    ( -- )
   ' NOOP ,             \ /INPUT    ( -- )
   ' EMIT>VIEW ,        \ EMIT      ( char -- )
   ' TYPE>VIEW ,        \ TYPE      ( addr len -- )
   ' TYPE>VIEW ,        \ ?TYPE     ( addr len -- )
   ' CR>VIEW ,          \ CR        ( -- )
   ' PAGE>VIEW ,        \ PAGE      ( -- )
   ' ATTRIBUTE>VIew ,   \ ATTRIBUTE ( n -- )
   ' NULL ,        		\ KEY   (C-KEY)  ( -- char )
   ' NULL ,        		\ KEY?  (C-KEY?) ( -- flag )
   ' NULL ,         	   \ EKEY  (C-KEY)  ( -- echar )
   ' NULL ,        		\ EKEY? (C-KEY?) ( -- flag )
   ' NULL ,         	   \ AKEY  (C-KEY)  ( -- char )
   ' 2DROP ,            \ PUSHTEXT  ( addr len -- )
   ' 2DROP ,         	\ AT-XY     ( x y -- )
   ' VIEW>XY ,        	\ GET-XY    ( -- x y )
   ' VIEW>SIZE ,      	\ GET-SIZE  ( -- x y )
   ' NOBUF ,      		\ ACCEPT    ( addr u1 -- u2 )

: [TV ( tv -- )   'TEXTVIEW !  TEXT>VIEW-MODE OPEN-PERSONALITY ;

: TV] ( -- )   CLOSE-PERSONALITY 'TEXTVIEW OFF ;

: /TEXT>VIEW	( ID -- )  [TV ;

CR .( outview personality loaded)

\\

\ example:

\ our window
NEW.WINDOW TVWIN
S" A Text View" TVWIN W.TITLE

VARIABLE MYTEXTVIEW
: /MYWINDOW
	TVWIN ADD.WINDOW
	TVWIN WINDOWFORTEXT
	DUP >R MYTEXTVIEW !
	0" Monaco" 14 R> VIEWFONT
;

: TT   MYTEXTVIEW @ [TV .FILES  TV] ;

\ try:
/MYWINDOW
TT

\ if worksheet-tools is loaded:
MYTEXTVIEW @ WS-WRITE

\\ ( eof)