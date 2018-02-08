{ ====================================================================
Resource constants

Copyright (C) 2001 FORTH, Inc.  All rights reserved.

Enumerated constants for the SwiftForth environment
==================================================================== }

{ --------------------------------------------------------------------
Windows programs pass lots of data, and most of it is based on
constants that either windows defines or the user defines. These are
the ones defined by SwiftForth as resources in order to collect them
all in a single place.

The MI_ items are menu items whose value is of interest to the menu
toolbar functions (SFMENUS and TOOLBAR).  When menu items selected or
toolbar buttons are pressed, a WM_COMMAND message is sent to the
window callback (FPROC, defined in WINPROC.F) with the MI_ value in
the WPARAM LOWORD parameter. The WM_COMMAND switch statement selects
what to do with the message. Note that execution is being done in the
callback, which is equivalent to an interrupt and one should not
assume the use of the dictionary here.

The TB_ items are simply names for the toolbar button bitmaps. The
buttons are contained in (one each, large and small) a single bmp
with the individual buttons arranged in a horizontal row. The indices
begin at zero and go thru n-1 .
-------------------------------------------------------------------- }

?( Menu, message, and toolbar resources)

{ --------------------------------------------------------------------
Menu items.
These constants define the menu items used by SwiftForth. They can be
extended by beginning at MI_USER which should be updated when the
extension is finished.
-------------------------------------------------------------------- }

100
   ENUM MI_INCLUDE
   ENUM MI_EDIT
   ENUM MI_PRINT
   ENUM MI_SAVECOMMAND
   ENUM MI_SAVEHISTORY
   ENUM MI_LOGGING
   ENUM MI_EXIT
   ENUM MI_COPY
   ENUM MI_PASTE
   ENUM MI_CLEAR
   ENUM MI_FONT
   ENUM MI_EDITOR
   ENUM MI_PREFS
   ENUM MI_SAVEOPTIONS
   ENUM MI_WORDS
   ENUM MI_WATCH
   ENUM MI_MEMORY
   ENUM MI_RUN
   ENUM MI_HISTORY
   ENUM MI_USERMANUAL
   ENUM MI_HANDBOOK
   ENUM MI_VERSIONS
   ENUM MI_ONLINE
   ENUM MI_ABOUT
   ENUM MI_APIHELP
   ENUM MI_MSDN
   ENUM MI_BREAK
   ENUM MI_PAGE
   ENUM MI_SHOWSTAT
   ENUM MI_SHOWTOOL
   ENUM MI_OPTIONALS
   ENUM MI_SAMPLES
   ENUM MI_SFCSAMPLES
   ENUM MI_SFC
   ENUM MI_WINSAMPLES
   ENUM MI_WINOPTIONALS
   ENUM MI_WARNCFG
   ENUM MI_FPOPTIONS
   ENUM MI_RIGHTMENU
   ENUM MI_LOCATE
   ENUM MI_EDITWORD
   ENUM MI_SEE
   ENUM MI_XREF
   ENUM MI_EXECUTE
   ENUM MI_REFRESH
   ENUM MI_XLOCATE
   ENUM MI_MONCFG
   ENUM MI_SELALL
   ENUM MI_ANSMAN
( n) VALUE MI_USER


{ --------------------------------------------------------------------
Toolbar button images

These must correspond to the order of the button image tiles in
SWIFTBAR.BMP.  The relationship between name and image is entirely
subjective!
-------------------------------------------------------------------- }

0 ENUM TB_INCLUDE
  ENUM TB_PRINT
  ENUM TB_EDIT
  ENUM TB_COPY
  ENUM TB_PASTE
  ENUM TB_WORDS
  ENUM TB_WATCH
  ENUM TB_MEMORY
  ENUM TB_STOP
  ENUM TB_HELP
  ENUM TB_SAVE
  ENUM TB_FONT
  ENUM TB_COLOR
  ENUM TB_RUN
  ENUM TB_WATCH2
  ENUM TB_EDIT2
  ENUM TB_TOOL1
  ENUM TB_TOOL2
  ENUM TB_TOOL3
  ENUM TB_TOOL4
  ENUM TB_TOOL5
  ENUM TB_TOOL6
  ENUM TB_TOOL7
  ENUM TB_TOOL8
  ENUM TB_OPENPROJECT
  ENUM TB_NEWPROJECT
  ENUM TB_CONNECT
  ENUM TB_BREAK
  ENUM TB_SINGLE
  ENUM TB_BUILD
  ENUM TB_DEBUG
  ENUM TB_PROM
  ENUM TB_PAGE
  ENUM TB_HELPQ
  ENUM TB_WATCH3
  ENUM TB_FLASH
  ENUM TB_INFO
  ENUM TB_BULB
  ENUM TB_TOOLS
  ENUM TB_TOOLS2
  ENUM TB_CARHOOD
  ENUM TB_HISTORY

( n) CONSTANT TB_IMAGES
