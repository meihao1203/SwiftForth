{ ====================================================================
Drag and drop handler

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

Drag and drop into the SwiftForth debug window is implemented here.
==================================================================== }

?( Drag and drop support)

PACKAGE CONSOLE-WINDOW

PUBLIC

VARIABLE DROPOK    DROPOK ON

PRIVATE

: DO-DROP-IN ( -- )
   WPARAM -1 0 0 DragQueryFile 1 <> IF
      HWND Z" Drop one file at a time" Z" Error!"
      MB_ICONSTOP MessageBox DROP
      EXIT THEN
   DROPOK @ 0= IF
      HWND Z" Enable drag and drop?" Z" Warning!"
      MB_ICONQUESTION MB_YESNO OR MessageBox
      IDNO = IF EXIT THEN
      DROPOK ON
   THEN
   S\" \zDROP-INCLUDE " PAD PLACE
   WPARAM 0 HERE 255 DragQueryFile DROP
   HERE ZCOUNT PAD APPEND
   S\" \r" PAD APPEND  PAD COUNT  OPERATOR'S PUSHTEXT
   HWND SetForegroundWindow DROP ;

[+SWITCH SF-MESSAGES
   WM_DROPFILES RUN: ( -- res )   DO-DROP-IN  WPARAM DragFinish  0 ;
SWITCH]

HWND 1 DragAcceptFiles

:ONENVLOAD    HWND 1 DragAcceptFiles ;

PUBLIC

: DROP-INCLUDE ( -- )   \ Usage: DROP-INCLUDE <filename>
   PUSHPATH >IN @ >R
   0 WORD COUNT -NAME HERE ZPLACE  HERE SetCurrentDirectory DROP
   R> >IN ! INCLUDE POPPATH ;

END-PACKAGE
