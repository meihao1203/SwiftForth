{ ====================================================================
toolbar.f
Toolbar compiler and class

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

?( Toolbar compiler and class)

PACKAGE TOOLBAR-COMPILER

: TGRAY ( index command -- )
   SWAP , , TBSTATE_INDETERMINATE C, TBSTYLE_BUTTON C, 0 C, 0 C, 0 , 0 , ;

: TBUTTON ( index command -- )
   SWAP , , TBSTATE_ENABLED C, TBSTYLE_BUTTON C, 0 C, 0 C, 0 , 0 , ;

: TSKIP
   0 , 0 , 0 C, TBSTYLE_SEP C, 0 C, 0 C, 0 , 0 , ;

PUBLIC

CREATE SWIFTFORTH-TOOLBAR   HERE
   TB_STOP    MI_BREAK    TBUTTON
                          TSKIP
   TB_PAGE    MI_CLEAR    TBUTTON
                          TSKIP
   TB_INCLUDE MI_INCLUDE  TBUTTON
   TB_EDIT    MI_EDIT     TBUTTON
   TB_PRINT   MI_PRINT    TBUTTON
                          TSKIP
   TB_COPY    MI_COPY     TBUTTON
   TB_PASTE   MI_PASTE    TBUTTON
                          TSKIP
   TB_WORDS   MI_WORDS    TBUTTON
   TB_WATCH3  MI_WATCH    TBUTTON
   TB_MEMORY  MI_MEMORY   TBUTTON
   TB_HISTORY MI_HISTORY  TBUTTON
                          TSKIP
   TB_RUN     MI_RUN      TBUTTON
                          TSKIP
   TB_FONT    MI_FONT     TBUTTON
   TB_COLOR   MI_PREFS    TBUTTON
                          TSKIP
                          TSKIP
   TB_INFO    MI_ABOUT    TBUTTON


HERE SWAP - 5 CELLS / VALUE #TOOLBUTTONS

PRIVATE


{ --------------------------------------------------------------------
Tooltips for the toolbar
-------------------------------------------------------------------- }

: ZNULL ( n -- z )   DROP Z"  " ;

[SWITCH SWIFTFORTH-TOOLTIP ZNULL ( n -- z )
   MI_BREAK    RUN: Z" Break" ;
   MI_INCLUDE  RUN: Z" Include a file" ;
   MI_EDIT     RUN: Z" Edit a file" ;
   MI_PRINT    RUN: Z" Print the command window" ;
   MI_COPY     RUN: Z" Copy text to clipboard" ;
   MI_PASTE    RUN: Z" Paste text from clipboard" ;
   MI_WORDS    RUN: Z" Words browser" ;
   MI_WATCH    RUN: Z" Variable watch window" ;
   MI_MEMORY   RUN: Z" Memory display window" ;
   MI_RUN      RUN: Z" Run an external command" ;
   MI_FONT     RUN: Z" Select font" ;
   MI_PREFS    RUN: Z" Set options" ;
   MI_ABOUT    RUN: Z" About SwiftForth" ;
   MI_CLEAR    RUN: Z" New page" ;
   MI_HISTORY  RUN: Z" Command history window" ;
SWITCH]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

DEFER TOOLTIP   ' SWIFTFORTH-TOOLTIP IS TOOLTIP
DEFER TOOLBAR   ' SWIFTFORTH-TOOLBAR IS TOOLBAR

END-PACKAGE


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

SIMPLEWINCLASS SUBCLASS TOOL-BAR

   VARIABLE BIG
   VARIABLE FLAT
   VARIABLE xtTOOLBAR
   VARIABLE #TOOLS

   VARIABLE hBIG
   VARIABLE hSMALL

   WS_CHILD
   WS_VISIBLE       OR
   CCS_TOP          OR
   TBSTYLE_TOOLTIPS OR
   CCS_ADJUSTABLE   OR  CONSTANT BUTTONS-STYLE

   WS_CHILD
   WS_VISIBLE       OR
   CCS_TOP          OR
   $800             OR  \   TBSTYLE_FLAT     OR
   TBSTYLE_TOOLTIPS OR
   CCS_ADJUSTABLE   OR  CONSTANT FLAT-STYLE

   : BUTTONSIZE ( -- n )
      BIG @ IF 24 ELSE 16 THEN ;

   : STYLE ( -- n )
      FLAT @ IF FLAT-STYLE ELSE BUTTONS-STYLE THEN ;

   : IMAGE ( -- handle )
      BIG @ IF  hBIG   @ DUP ?EXIT DROP  THEN
                hSMALL @ DUP ?EXIT DROP
      -1 ABORT" No bitmap specified for toolbar" ;

   : MAKE ( -- )
      OWNER @ STYLE
      1 TB_IMAGES 0 IMAGE
      xtTOOLBAR @EXECUTE #TOOLS @
      0 0 BUTTONSIZE DUP
      5 CELLS
      CreateToolbarEx HANDLE ! ;

   : BIG/SMALL ( flag -- )
      BIG !  CLOSE  MAKE  OWNER @ SIZES ;

   : FLAT/BUTTONS ( flag -- )
      FLAT !  CLOSE  MAKE  OWNER @ SIZES ;

   : CREATE-TOOLBAR ( owner -- )   OWNER !  MAKE ;

END-CLASS





