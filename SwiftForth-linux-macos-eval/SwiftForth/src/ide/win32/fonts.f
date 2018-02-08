{ ====================================================================
fonts.f
Font support

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

?( Font support)

{ --------------------------------------------------------------------
FONT-PICKER extends the CHOOSE-FONT data structure to include methods
for choosing a font for a given window.

PICK-FIXED will present the user with a choosefont dialog and allow
him to choose a fixed-width font.

GUI-FONT is a static instance of FONT-PICKER. It represents the
globally used font for the swiftforth console window.
-------------------------------------------------------------------- }

CHOOSE-FONT SUBCLASS FONT-PICKER

   LOGICAL-FONT BUILDS FONT

   0 CF_FIXEDPITCHONLY OR
     CF_SCREENFONTS OR
     CF_INITTOLOGFONTSTRUCT OR
   CONSTANT FIXED

   : INIT ( hwnd style -- )
      Flags !  DUP Owner !  GetDC DC !  FONT Height LogFont !
      SCREEN_FONTTYPE FontType !  CHOOSE-FONT SIZEOF StructSize ! ;

   : FINISH ( -- )
      Owner @ DC @ ReleaseDC DROP ;

   : SELECT ( hwnd -- res )
      FIXED INIT  ADDR ChooseFont
      FONT FaceName C@ 0<> AND   FINISH ;

   : 'FONT ( -- addr )   FONT ADDR ;

END-CLASS

FONT-PICKER BUILDS GUI-FONT

{ --------------------------------------------------------------------
USE-FONT creates a font from the data in GUI-FONT and tells TTY
to use it.

SELECT-FONT lets the user choose a font for SwiftForth, then installs
it in tty.

The caret width is set either to zero (which indicates that tty
should base the width on the font) or an actual width value which
will be used. This is not set in a configuration menu, and should
be set manually. It is a configured variable and will be saved
and restored on system startup.

The font is saved in the registry, and is automatically reloaded
on system startup.
-------------------------------------------------------------------- }

CONSOLE-WINDOW +ORDER

: USE-FONT ( -- )
   GUI-FONT FONT Height @ IF
      GUI-FONT 'FONT CreateFontIndirect
      DUP OPERATOR'S PHANDLE TtySetfont DROP
      SF-STATUS SETFONT  RESIZE-STATUS  RESIZE-TTY
   THEN ;

: SELECT-FONT ( -- )
   OPERATOR'S PHANDLE  GUI-FONT SELECT IF  USE-FONT  THEN ;

[+SWITCH SF-COMMANDS
   MI_FONT        RUNS SELECT-FONT
SWITCH]

VARIABLE CARET-WIDTH   0 CARET-WIDTH !

CONSOLE-WINDOW -ORDER

CONFIG: TTYFONT ( -- addr len )   GUI-FONT 'FONT  LOGICAL-FONT SIZEOF ;
CONFIG: TTYCARET ( -- addr len )   CARET-WIDTH CELL ;

: SET-CARET ( width -- )   DUP CARET-WIDTH !
   PHANDLE TtySetCaret DROP ;

:ONENVLOAD ( -- )   USE-FONT   CARET-WIDTH @ SET-CARET ;

{ --------------------------------------------------------------------
\ load and start a sample application

REQUIRES CLICKS
START DROP

\ create a font data structure

FONT-PICKER BUILDS FOO

\ create a font description for the application window

HAPP FOO PICK-FIXED ( -- flag ) DROP

\ create the actual font

FOO 'FONT CREATEFONTINDIRECT ( -- hfont )

\ make the application use the new font

HAPP GETDC SWAP SELECTOBJECT DROP
-------------------------------------------------------------------- }


