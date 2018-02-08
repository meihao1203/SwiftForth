{ --------------------------------------------------------------------
Dialog compiler

Copyright 2001  FORTH, Inc.
Rick VanNorman
-------------------------------------------------------------------- }

?( Dialog compiler)

{ --------------------------------------------------------------------
The dialog compiler is complicated, and exists in its own wordlist.
DLGCOMP is the handle of the wordlist,

[DLG] interprets/compiles the next token in the DLGCOMP context.
-------------------------------------------------------------------- }

PACKAGE DLGCOMP

THROW#
   S" DLG: Wrong number of arguments" >THROW ENUM IOR_DLG_PARAMS

TO THROW#

{ --------------------------------------------------------------------
Tools for the dialog compiler

EVAL evaluates the string and returns the stack depth change.

EVALUATOR uses LPARSE to extract a longer than
   one line string from the input stream and evaluates it.

BRACKET-EVAL parses a string delimited by a ] and
PAREN-EVAL parses a string delimited by ) .  Both functions evaluate
   the string, which should leave a series of numbers on the stack.

OR-S combines the n items on the data stack by or-ing them.

(OR parses a string and ors all the values returned.

[(OR is the immediate compile-time version of (OR

OR! and AND! do logical operations on variables, like +!

/EVEN aligns the dictionary to an even address.
-------------------------------------------------------------------- }

?( ... internal tools)

: EVAL ( addr n -- i*x n )
   DEPTH 2- >R EVALUATE DEPTH R> - 0 MAX ;

: EVALUATOR ( char -- i*x n )
   4100 R-ALLOC 4096 ROT LPARSE EVAL ;

: BRACKET-EVAL ( -- i*x n )   [CHAR] ] EVALUATOR ;
: PAREN-EVAL ( -- i*x n )   [CHAR] ) EVALUATOR ;

: OR-S ( x x x n -- x )
   1- 0 MAX 0 ?DO OR LOOP ;

: (OR  ( -- n )
   PAREN-EVAL DUP IF OR-S THEN ;

: OR! ( n addr -- )
   DUP @ ROT OR SWAP ! ;

: AND! ( n addr -- )
   DUP @ ROT AND SWAP ! ;

: /EVEN ( -- )
   HERE 2 AND IF 0 H, THEN ;

{ --------------------------------------------------------------------
Compiler variables

STR holds a pointer to allocated memory for a large string buffer.
FONTNAME is a buffer holding the dialog's default font name.

STYLES, in the Windows dialog paradigm, are things that are combined
via "OR" operations.  A dialog, or a control, has exactly one style

FONTSIZE has the point size of a specified font.
-------------------------------------------------------------------- }

?( ... variables and values)

VARIABLE ITEMS
VARIABLE STYLE
VARIABLE FONTSIZE
VARIABLE TEMPLATE
VARIABLE ID

CREATE RECT  4 CELLS ALLOT

CREATE FONTNAME    64 ALLOT
CREATE CLASSNAME   64 ALLOT

0 VALUE STR

: ++ITEMS ( -- )
   ITEMS @ IF  ITEMS @ H@ 1+ ITEMS @ H! THEN ;

{ ------------------------------------------------------------------------
/STR initializes the STR buffer.

>STR appends a string to the STR buffer

"  appends a string to the STR buffer.

\N  appends a line-end sequence to the STR buffer.

On system load we allocate the buffers, and on system exit we
free them. While compiling this, we run the allocation so that
we can use them before a fresh startup.
------------------------------------------------------------------------ }

?( ... string buffers)

: /STR   4096 ALLOCATE THROW  TO STR ;

/STR

:ONENVLOAD   0 TO STR  /STR ;
:ONENVEXIT   STR FREE THROW   0 TO STR  ;

: >STR ( addr -- )   COUNT STR XAPPEND ;

: "   [CHAR] " WORD >STR ;

STRING-TOOLS +ORDER

: \" ( -- )   "\PARSE >STR ;

STRING-TOOLS -ORDER

: \N   <EOL> >STR ;

: RESOURCE ( n -- )
   -1 STR !  STR CELL+ ! ;

{ --------------------------------------------------------------------
(STYLE builds the style bitmask,
(+STYLE adds bits to STYLE
(-STYLE removes bits from STYLE.

(FONT parses a font name and points from syntax: (FONT nn, fontname)
   and sets the DS-SETFONT style of the current dialog.
-------------------------------------------------------------------- }

?( ... styles and fonts)

: (STYLE ( -- )
   PAREN-EVAL ?DUP IF OR-S STYLE ! THEN ;

: (+STYLE ( -- )
   PAREN-EVAL ?DUP IF OR-S STYLE OR! THEN ;

: (-STYLE ( -- )
   PAREN-EVAL ?DUP IF OR-S -1 XOR STYLE AND! THEN ;

: (FONT ( -- )
   DS_SETFONT STYLE OR!
   [CHAR] , WORD COUNT ATOI ( n) FONTSIZE !
   [CHAR] ) WORD COUNT -TRAILING BL SKIP FONTNAME PLACE ;

: (CLASS ( -- )
   [CHAR] ) WORD COUNT -TRAILING BL SKIP CLASSNAME PLACE ;

{ --------------------------------------------------------------------
Dialog item template compiler

   [CONTROL " text" x y cx cy id (STYLE style1 style2 ... ) ]

-------------------------------------------------------------------- }

?( ... item compiler)

: STYLE, ( -- )
   STYLE @ ,  0 , ;                     \ style, ext-style

: RECT, ( -- )
   RECT @+ H, @+ H, @+ H, @ H, ;        \ x y cx cy

: ITEM, ( -- )
   ID @ H, ;

: ITEM-CLASS, ( -- )
   TEMPLATE @  DUP H@ 0< IF  @ ,  ELSE ZCOUNT U,  THEN ;

: TEXT, ( -- )
   STR @+ DUP 0< IF ( resource)  H, @ H, ELSE  U,  THEN ;

: PARSE-ITEM ( -- )   STR OFF
   BRACKET-EVAL 5 <> IOR_DLG_PARAMS ?THROW  RECT !RECT  ID ! ;

: COMPILE-ITEM ( 'item -- )
   @+ STYLE !  TEMPLATE !  PARSE-ITEM
   STYLE, RECT, ITEM, ITEM-CLASS, TEXT, 0 H, /EVEN ;

: CONTROL ( class style -- )   \ use: ( class style) CONTROL FOO
   CREATE ( class style)
      WS_CHILD OR WS_VISIBLE OR ,
      DUP $FFFF AND $FFFF = IF ( atomic class)  ,  ELSE Z, THEN
   DOES> COMPILE-ITEM  ++ITEMS ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

?( ... define a dialog)

: PARSE-DIALOG ( style -- )   DLGCOMP +ORDER
   STYLE !  STR OFF  FONTSIZE OFF  CLASSNAME OFF
   BRACKET-EVAL  4 <> IOR_DLG_PARAMS ?THROW  RECT !RECT ;

: ITEMS, ( -- )
   HERE ITEMS !  0 H, ;

: MENU, ( -- )   0 H, ;

: DIALOG-CLASS, ( -- )
   CLASSNAME C@ IF CLASSNAME COUNT U, ELSE 0 H, THEN ;

: FONT, ( -- )
   FONTSIZE @ ?DUP IF   H,  FONTNAME COUNT U,  THEN ;

: COMPILE-DIALOG ( -- )
   STYLE, ITEMS, RECT, MENU, DIALOG-CLASS, TEXT, FONT, /EVEN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

?( ... dialog compiler user interface)

: DIALOG-HEADER ( x -- )
   CREATE , DOES> @  PARSE-DIALOG COMPILE-DIALOG ;

(OR
   WS_POPUP
   WS_CAPTION
   DS_MODALFRAME
   WS_VISIBLE)
DIALOG-HEADER [MODAL

(OR
   WS_POPUP
   WS_SYSMENU
   WS_CAPTION
   WS_BORDER
   WS_VISIBLE)
DIALOG-HEADER [MODELESS

{ ----------------------------------------------------------------------
IDSTRINGS

IDSTRINGS makes dialog boxes easier to build; no separate definitions
of constants, no actual numbers in the dialog box template.  The whole
thing is compiled into the DLGCOMP package as an extension.

Original Author:  Rick VanNorman
Initial release:  12 Jun 2011
---------------------------------------------------------------------- }

PUBLIC

0 VALUE IDN

PRIVATE

0 VALUE IDSTRINGS

: ?IDSTRINGS ( -- )
   IDSTRINGS 0= ABORT" idstrings not initialized"
   IDSTRINGS @ 65000 > ABORT" idstrings memory full" ;

\ dispose of the idstring memory

: IDSTRINGS/ ( -- )
   IDSTRINGS IF  IDSTRINGS FREE THROW  0 TO IDSTRINGS  THEN ;

\ initialize the idstring memory

: /IDSTRINGS ( -- )
   IDSTRINGS/  1000 TO IDN
   65536 ALLOCATE ABORT" failed to allocate idstrings" TO IDSTRINGS ;

\ the idstrings memory is a compendium of constants that can be evaluated
\ after the dialog is defined to present names for the dialog behavior to
\ reference. evaluate instantiates it into the dictionary

: CREATE-IDS ( -- )
   ?IDSTRINGS  IDSTRINGS @+ EVALUATE  ;

\ append the definition of the idstring constant to the memory pool,
\ increment the idn counter, and return it for the dialog compiler

: >IDSTRINGS ( addr len -- )
   IDSTRINGS XAPPEND ;

: ID: ( -- n )
   ?IDSTRINGS
   IDN (.) >IDSTRINGS  S"  CONSTANT ID_" >IDSTRINGS
   BL WORD COUNT >IDSTRINGS  s"  " >IDSTRINGS
   IDN  1 +TO IDN ;

{ ----------------------------------------------------------------------
Advanced layout tools for repetitive dialog boxes (see PICKCOLOR)

=XY sets the origin of a group of controls.
=WH sets the width and height of a group of controls.
=XTH sets the x delta between columns of controls, left to left.
=YTH sets the y delta between rows of controls, top to top.

+ATOI adds the parses and adds the result to the integer on the stack.

XTH calculates the offset to the X'th column from the origin.
XTH calculates the offset to the Y'th row from the origin.
XYTH calculates both offsets from the origin.
XY adds the following numbers to the origin.
WH returns the width and height saved by =WH.
---------------------------------------------------------------------- }

0 VALUE OX      \ x and
0 VALUE OY      \ y origin
0 VALUE XW      \ x and
0 VALUE YW      \ y, a control width and height
0 VALUE DXPOS   \ dx and
0 VALUE DYPOS   \ dy, the distance from one control to the next

: =XY ( x y -- )   TO OY  TO OX ;
: =WH ( w h -- )   TO YW  TO XW ;
: =YTH ( n -- )   TO DYPOS ;
: =XTH ( n -- )   TO DXPOS ;

: +ATOI ( n -- n )   BL WORD COUNT ATOI + ;

: XTH ( x y -- X y )   >R  OX - DXPOS * OX +  R> ;
: YTH ( n -- n )   OY - DYPOS * OY + ;
: XYTH ( x y -- X Y )   XTH YTH ;
: XY ( -- n n )   OX +ATOI  OY +ATOI ;
: WH ( -- n n )   XW YW ;

\ ----------------------------------------------------------------------

: END-DIALOG ( -- )
   DLGCOMP -ORDER  0 ITEMS !  CREATE-IDS  IDSTRINGS/ ;

PUBLIC

: DIALOG ( -- )
   CREATE  DLGCOMP +ORDER  0 ,  /IDSTRINGS
   DOES> CELL+ ;

END-PACKAGE

{ --------------------------------------------------------------------
SIMPLE SAMPLE
-------------------------------------------------------------------- }

0 [IF]

DIALOG (ABOUT)

[MODAL " About SwiftForth"  22 17 167 73  (FONT 8, MS Sans Serif) ]

[DEFPUSHBUTTON " OK"                                    IDOK     3 42  24 24 ]
[ICON          101 RESOURCE                             -1       3  2  24 24 ]
[LTEXT         " SwiftForth Version 2.0 alpha"          -1      30 12 100  8 ]
[LTEXT         " Development Environment for Windows"   -1      30 22 150  8 ]
[LTEXT         " (C) Copyright 1997-1999 Forth, Inc."   -1      30 42 150  8 ]

END-DIALOG

:NONAME ( -- res )
   MSG LOWORD WM_COMMAND = IF
      WPARAM LOWORD  DUP IDOK = SWAP IDCANCEL = OR IF
         HWND 1 EndDialog -1 EXIT
      THEN
   THEN
   0 ;  ( xt) 4 CB: RUNABOUT

: ABOUT ( -- )
   HINST (ABOUT) HWND RUNABOUT 0 DialogBoxIndirectParam DROP ;

[THEN]

{ --------------------------------------------------------------------
All modeless dialogs need to respond to the WM_ACTIVATE message with
this routine. It ensures that the message loop will handle dialog
directed messages properly when one has the focus.

Dialogs also need to be mixed font. The default when creating a dialog
without specifying a font will be fixed, but this is not windows-nominal
practice, so most dialogs will have a font specified, for instance
   (FONT 8, MS Sans Serif)
which will make the default similar to the system default font.

This implies that dialogs need a fixed method to change a field back
to a fixed font. Hence, SetDlgItemFont, which takes a handle to a font
and sets the item to it.

SetDlgItemFixedFont changes the item to a system-defined fixed font.

-------------------------------------------------------------------- }

?( ... modeless dialogs, and dialog fonts)

: MODELESS-ACTIVATE ( -- res )
   WPARAM $FFFF AND IF HWND ELSE 0 THEN DLGACTIVE !  0 ;

: SetDlgItemFont ( hfont item -- )
   HWND SWAP GetDlgItem
   WM_SETFONT
   ROT
   0
   SendMessage DROP ;

: SetDlgItemFixedFont ( item -- )
   ANSI_FIXED_FONT GetStockObject SWAP SetDlgItemFont ;
