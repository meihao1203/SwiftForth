{ ====================================================================
Simple GUI console

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

This is the interface to SwiftForth debug window.

==================================================================== }

{ --------------------------------------------------------------------
KEYREADY has a flag indicating that a keystroke is ready.

COOKED and RAW set key input modes for the debug window. COOKED is
considered to be accepting only the keys that TTY is not interested
in, while RAW accepts all keystrokes, including the ones that windows
normally eats before the application can see them.

AKEY? and AKEY are cousins to EKEY; they accept cooked keystrokes and
are used only by ACCEPT.

EKEY? and EKEY are the generic, give me the keystroke no matter what,
vectors.  They will return the ALT-F4 keystroke and anything else that
windows can generate.

KEY and KEY? return only ascii keystrokes. This is done by filtering
EKEY strokes, throwing away any non-ascii events while waiting.
-------------------------------------------------------------------- }

VARIABLE KEYREADY

: COOKED ( -- )   0 PHANDLE TtyKeymode DROP ;
: RAW    ( -- )   1 PHANDLE TtyKeymode DROP ;

: AKEY?(G) ( -- flag )   COOKED
   KEYREADY OFF  PAUSE  PHANDLE TtyEkeyq  0 MAX ;

: AKEY(G) ( -- echar )
   BEGIN  AKEY?(G) NOT WHILE  STOP  REPEAT  PHANDLE TtyEkey ;

: EKEY?(G) ( -- flag )   RAW
   KEYREADY OFF  PAUSE  PHANDLE TtyEkeyq  0 MAX ;

: EKEY(G) ( -- echar )
   BEGIN  EKEY?(G) NOT WHILE  STOP  REPEAT  PHANDLE TtyEkey ;

: KEY?(G) ( -- flag )
   BEGIN
      KEYREADY @ 0= WHILE
      EKEY?(G) IF
         EKEY(G) DUP 256 < IF
            DUP KEYREADY !
         THEN
         DROP
      ELSE
         0 EXIT
      THEN
   REPEAT -1 ;

: KEY(G) ( -- char )
   BEGIN
      KEY?(G) NOT WHILE STOP
   REPEAT
   KEYREADY @  KEYREADY OFF ;

{ --------------------------------------------------------------------
Each output function advances the caret.

EMIT sends a character to TTY.
TYPE sends a string.  Faster than one EMIT at a time.
CR advances the caret to the start of the next line.
?TYPE prints the string, wrapping to the next line if needed.
-------------------------------------------------------------------- }

: EMIT(G) ( char -- )   PHANDLE TtyEmit DROP PAUSE ;
: TYPE(G) ( addr len -- )   PHANDLE TtyType DROP PAUSE ;
: CR(G) ( -- )  PHANDLE TtyCr DROP PAUSE ;
: ?TYPE(G) ( addr len -- )   PHANDLE TtyWrap DROP PAUSE ;

{ --------------------------------------------------------------------
AT-XY sets the cursor position relative to the position of the last
   PAGE operation.
GET-XY returns the cursor position.

GET-SIZE returns the visible size of the output device.

PUSHTEXT places text into the input stream. Max 128 characters.

PAGE clears the screen and orients the caret at the upper left.

/INPUT resets the input stream.

ATTRIBUTE sets the character display color.
-------------------------------------------------------------------- }

: AT-XY(G) ( x y -- )   16 LSHIFT OR PHANDLE TtySetxy DROP PAUSE ;

: GET-XY(G) ( -- x y )   PHANDLE TtyGetxy LOHI PAUSE ;

: GET-SIZE(G) ( -- x y )   PHANDLE TtyGetsize LOHI PAUSE ;

: PUSHTEXT(G) ( addr len -- )   PHANDLE TtyPushtext DROP PAUSE ;

: PAGE(G) ( -- )   PHANDLE TtyNew DROP ;

: /INPUT(G) ( -- )   PHANDLE TtyBreak DROP ;

: ATTRIBUTE(G) ( n -- )   PHANDLE TtyUsecolor DROP ;

{ --------------------------------------------------------------------
SIMPLE-GUI is a personality vector for TTY.

/CONSOLE sets SIMPLE-GUI as the personality and opens a window that
uses it for the interactive user environment.
-------------------------------------------------------------------- }

CREATE SIMPLE-GUI
        16 ,            \ datasize
        19 ,            \ maxvector
         0 ,            \ PHANDLE
         0 ,            \ PREVIOUS
   ' NOOP ,             \ INVOKE    ( -- )
   ' NOOP ,             \ REVOKE    ( -- )
   ' /INPUT(G) ,        \ /INPUT    ( -- )
   ' EMIT(G) ,          \ EMIT      ( char -- )
   ' TYPE(G) ,          \ TYPE      ( addr len -- )
   ' ?TYPE(G) ,         \ ?TYPE     ( addr len -- )
   ' CR(G) ,            \ CR        ( -- )
   ' PAGE(G) ,          \ PAGE      ( -- )
   ' ATTRIBUTE(G) ,     \ ATTRIBUTE ( n -- )
   ' KEY(G) ,           \ KEY       ( -- char )
   ' KEY?(G) ,          \ KEY?      ( -- flag )
   ' EKEY(G) ,          \ EKEY      ( -- echar )
   ' EKEY?(G) ,         \ EKEY?     ( -- flag )
   ' AKEY(G) ,          \ AKEY      ( -- char )
   ' PUSHTEXT(G) ,      \ PUSHTEXT  ( addr len -- )
   ' AT-XY(G) ,         \ AT-XY     ( x y -- )
   ' GET-XY(G) ,        \ AT-XY?    ( -- x y )
   ' GET-SIZE(G) ,      \ GET-SIZE  ( -- x y )
   ' (ACCEPT) ,         \ ACCEPT    ( addr u1 -- u2 )


{ --------------------------------------------------------------------
SwiftForth has four named color attributes in the console window.
Here they are defined, and SET-COLORS will tell TTY to use them.

They are kept in the registry and restored on startup.

There are four named color sets, and an "invisible" color -- 31 -- where
text and background are the same.
-------------------------------------------------------------------- }

CREATE COLOR-TABLE

\  TEXT                BACKGROUND
   BLACK        ,      WHITE ,          \ normal
   WHITE        ,      BLACK ,          \ inverse
   RED          ,      WHITE ,          \ bright
   BLUE         ,      WHITE ,          \ bold
   CYAN         ,      WHITE ,          \
   MAGENTA      ,      WHITE ,          \
   YELLOW       ,      WHITE ,          \
   GREEN        ,      WHITE ,          \
   DARK-RED     ,      WHITE ,          \
   DARK-GREEN   ,      WHITE ,          \
   DARK-YELLOW  ,      WHITE ,          \
   DARK-BLUE    ,      WHITE ,          \
   DARK-MAGENTA ,      WHITE ,          \
   DARK-CYAN    ,      WHITE ,          \
   GRAY         ,      WHITE ,          \
   DARK-GRAY    ,      WHITE ,          \

HERE COLOR-TABLE - CELL / 2/ CONSTANT #COLORS

: SET-COLORS ( addr -- )
   DUP 2@ = IF  WHITE BLACK THIRD 2!  THEN
   #COLORS 0 DO ( a)
      DUP 2@ I PHANDLE TtySetcolor DROP  CELL+ CELL+
   LOOP DROP
   COLOR-TABLE CELL+ @  DUP 31 PHANDLE TtySetcolor DROP ;

: USE-COLORS ( -- )   COLOR-TABLE SET-COLORS ;

CONFIG: COLORMAP ( -- addr len )   COLOR-TABLE #COLORS 2* CELLS ;
LOCALCONFIG: COLORMAP ( -- addr len )   COLOR-TABLE 8 CELLS ;

:ONENVLOAD ( -- )   USE-COLORS ;

