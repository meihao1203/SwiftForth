{ ====================================================================
TextView Personality

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
The personality table for TextView I/O.
Last: 21 April 2014 08:04:49 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
Operator (ObjC Runtime) will pass characters to Impostor (Forth).
This interaction needs flags, semaphores and task sleep/wake control.
'TEXTVIEW	-- contains current textview in use for I/O, USER ?
<FORTH> -- flags wether Forth or the ObjC Runtime does the work.
(CBUF) -- i/o semaphore

Some methods need to be executed on the main thread (OPERATOR). Their
selectors are sent to OPERATOR. Only their selectors are defined here,
because you can't run them properly on a secondary thread.
Apologies for their awful names.

The output part of the Personality:
VIEWBUFFER -- conversion buffer for chars to NSString
TYPE>VIEW -- TYPE
EMIT>VIEW -- EMIT
CR>VIEW   -- CR

The input part of the Personality:
CBUF -- character buffer
VIEW>KEY?      -- KEY?
VIEW>KEY       -- KEY AKEY EKEY
Note: Impostor will sleep till a character is available
DOCOMMAND -- execute key command in textview.
VIEWSTROKE? -- filters keystrokes and acts upon special cases. See code.
VIEW>ACCEPT    -- ACCEPT

PAGE>VIEW      -- PAGE
ATTRIBUTE>VIEW -- ATTRIBUTE
VIEW>XY        -- GET-XY
VIEW>SIZE      -- GET-SIZE
TEXTVIEW-MODE  -- TextView Personality
-------------------------------------------------------------------- }

/FORTH
DECIMAL

VARIABLE 'TEXTVIEW
VARIABLE <FORTH>
VARIABLE (CBUF)

\ --------------------------------------------------------------------
\ I/O 'personality' output words to a textView

1024 BUFFER: VIEWBUFFER

: INSERTTEXT:-SEL ( -- sel )   Z" insertText:" @SELECTOR ;

: TYPE>VIEW ( a n -- )  (* optimize code *)
	VIEWBUFFER 1024 ERASE
	VIEWBUFFER ZPLACE VIEWBUFFER >NSSTRING >R
	<FORTH> ON									\ signal Forth is inserting characters
	INSERTTEXT:-SEL R@ YES 'TEXTVIEW @ FORMAIN DROP
	R> @release DROP
	PAUSE ;

: EMIT>VIEW ( c -- )   >R RP@ 1 TYPE>VIEW R> DROP ;

: CR>VIEW ( -- )   10 EMIT>VIEW ;

\ --------------------------------------------------------------------
\ I/O 'personality' input words from a textView

VARIABLE CBUF

: VIEW>KEY? ( -- f )   (CBUF) GET  CBUF C@ 0<>  (CBUF) RELEASE PAUSE ;

: VIEW>KEY ( -- char )
   VIEW>KEY? 0= IF STOP THEN  (CBUF) GET  CBUF C@ 0 CBUF C!  (CBUF) RELEASE PAUSE ;

\ --- special actions on commands

: DOCOMMAND ( sel -- )
	<FORTH> ON
	( sel) 0 YES 'TEXTVIEW @ FORMAIN DROP
	PAUSE ;

\ deal with backspace, '8 emit space 8 emit' won't work, send a bs command
: BS-SEL ( -- sel )   Z" deleteBackward:" @SELECTOR ;

: DOCOMMANDBS ( -- )   BS-SEL DOCOMMAND ;

: ?BS ( n1 -- n2 flag )  DUP IF 1- 0 MAX DOCOMMANDBS THEN FALSE ;

\ deal with return key, should only insert newline, not stop accepting keys
: NL-SEL ( -- sel )   Z" insertNewline:" @SELECTOR ;

: DOCOMMANDNL ( -- )   NL-SEL DOCOMMAND ;

\ erase to beginning of line
: CLL-SEL ( -- sel )   Z" deleteToBeginningOfLine:" @SELECTOR ;

: DOCOMMANDCLL ( -- )   CLL-SEL DOCOMMAND ;

: VIEWSTROKE? ( lim addr n char -- lim addr n flag )
	DUP  3 = IF DROP TRUE EXIT THEN				               \ enter key, done, out
	DUP 13 = IF DROP TRUE EXIT THEN				               \ return key, done,out
	DUP  8 = IF DROP ?BS  EXIT THEN		                     \ backspace, decrease accepted chars, again
	DUP 27 = IF DROP DROP 0 DOCOMMANDCLL FALSE EXIT THEN		\ esc, erase line, start again
	>R SWAP >R 2DUP = IF R> SWAP R> DROP TRUE EXIT THEN		\ reached limit, done, out
	R> SWAP 2DUP + R> DUP EMIT SWAP C! 1+ FALSE ;    			\ echo char and again

: VIEW>ACCEPT ( addr lim -- n )
   SWAP 0 BEGIN ( lim addr n )
      AKEY
      VIEWSTROKE?
   UNTIL -ROT 2DROP ;

\ clear from insertion point to beginng text
: DEL-SEL ( -- sel )   Z" deleteToMark:" @SELECTOR ;

: DOCOMMANDDEL ( -- )   DEL-SEL DOCOMMAND ;

\ select all text
: SALL-SEL ( -- sel )   Z" selectAll:" @SELECTOR ;

: DOCOMMANDSALL ( -- )   SALL-SEL DOCOMMAND ;

: PAGE>VIEW ( -- )   DOCOMMANDSALL DOCOMMANDDEL ;  \ color attributes removed  30 Oct 2014 21:54:56 CET -rt

: ATTRIBUTE>VIEW ( n -- )   DROP ;     \ Removed color attributes 30 Oct 2014 21:54:43 CET -rt

\ textView-mode stubs for now
: VIEW>XY ( -- x y )  0 0 ;
: VIEW>SIZE ( -- x y )  0 0 ;

CREATE TEXTVIEW-MODE
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
   ' ATTRIBUTE>VIEW ,   \ ATTRIBUTE ( n -- )
   ' VIEW>KEY  ,        \ KEY   (C-KEY)  ( -- char )
   ' VIEW>KEY? ,        \ KEY?  (C-KEY?) ( -- flag )
   ' VIEW>KEY ,         \ EKEY  (C-KEY)  ( -- echar )
   ' VIEW>KEY? ,        \ EKEY? (C-KEY?) ( -- flag )
   ' VIEW>KEY ,         \ AKEY  (C-KEY)  ( -- char )
   ' 2DROP ,            \ PUSHTEXT  ( addr len -- )
   ' 2DROP ,         	\ AT-XY     ( x y -- )
   ' VIEW>XY ,        	\ GET-XY    ( -- x y )
   ' VIEW>SIZE ,      	\ GET-SIZE  ( -- x y )
   ' VIEW>ACCEPT ,      \ ACCEPT    ( addr u1 -- u2 )

cr .( TextVIew Personality loaded )

\\ ( eof )