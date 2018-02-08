{ ====================================================================
WM_COMMAND responses for the console window

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman
==================================================================== }

PACKAGE CONSOLE-WINDOW

{ --------------------------------------------------------------------
FORTH-POPUP defines the menu that pops up when the right mouse button
is pressed. When an item is selected, it generates a corresponding
WM_COMMAND message.
-------------------------------------------------------------------- }


MENU FORTH-POPUP
   POPUP " "
      MI_LOCATE   MENUITEM "Locate"
      MI_EDITWORD MENUITEM "Edit"
      MI_SEE      MENUITEM "See"
      MI_XREF     MENUITEM "Cross Ref"
      MI_EXECUTE  MENUITEM "Execute"
                  SEPARATOR
      MI_COPY     MENUITEM "Copy"
      MI_PASTE    MENUITEM "Paste"
   END-POPUP
END-MENU

{ --------------------------------------------------------------------
MOUSEPOS returns the position of the mouse in the client window. This
is used to set the position where the popup menu appears.

POPMENU creates the popup menu (it has only a transient existence,
during the execution of this word), displays it at the mouse position,
and destroys it after the user has selected something or canceled the
operation.

GET-MARKED asks the TTY dll for the marked text. If there is none,
it will retrieve the blank delimited word under the cursor.

PASTE-COMMAND jams a command into the forth text interpreter via
the PUSHTEXT personality command and ACCEPT.

xxx-COMMAND paste various commands into the Forth interpreter. The \z
(null) character in the string is an escape character that ACCEPT
recognizes; it forces interpret mode and cancels the current line.

The SF-COMMANDS switch is extended to accomodate the new features.
-------------------------------------------------------------------- }

PUBLIC

: MOUSEPOS ( -- x y )
   0 0 SP@ GetCursorPos DROP SWAP ;

PRIVATE

: POPMENU ( -- )
   FORTH-POPUP LoadMenuIndirect  DUP >R
   0 GetSubMenu
   TPM_LEFTALIGN TPM_LEFTBUTTON OR TPM_RIGHTBUTTON OR
   MOUSEPOS 0 HWND 0 TrackPopupMenu DROP
   R> DestroyMenu DROP ;

: GET-MARKED ( -- zstr )
   OPERATOR'S PHANDLE TtyGetword ;

: PASTE-COMMAND ( zstr addr len -- )
   S\" \z" PAD PLACE  ( addr len) PAD APPEND
   ZCOUNT  PAD APPEND  S\" \r" PAD APPEND  PAD COUNT
   OPERATOR'S PUSHTEXT ;

: EXECUTE-COMMAND ( z -- )   0 0          PASTE-COMMAND ;
: LOCATE-COMMAND  ( z -- )   S" LOCATE "  PASTE-COMMAND ;
: SEE-COMMAND     ( z -- )   S" SEE "     PASTE-COMMAND ;
: EDIT-COMMAND    ( z -- )   S" EDIT "    PASTE-COMMAND ;
: XREF-COMMAND    ( z -- )   S" WH "      PASTE-COMMAND ;

: DEBUG-COMMAND ( -- )   0 S" INCLUDE DEBUG" PASTE-COMMAND ;
: BUILD-COMMAND ( -- )   0 S" INCLUDE BUILD" PASTE-COMMAND ;

[+SWITCH SF-COMMANDS
   MI_RIGHTMENU RUNS POPMENU
   MI_LOCATE    RUN: GET-MARKED LOCATE-COMMAND ;
   MI_EDITWORD  RUN: GET-MARKED EDIT-COMMAND ;
   MI_SEE       RUN: GET-MARKED SEE-COMMAND ;
   MI_XREF      RUN: GET-MARKED XREF-COMMAND ;
   MI_EXECUTE   RUN: GET-MARKED EXECUTE-COMMAND ;
   MI_XLOCATE   RUN: LPARAM LOCATE-COMMAND ;
SWITCH]

ACCEPTOR +ORDER

[+SWITCH CONTROL ( a n # echar -- a n # )
   $10077 RUNS BUILD-COMMAND         \ F8
   $10078 RUNS DEBUG-COMMAND         \ F9
SWITCH]

ACCEPTOR -ORDER

END-PACKAGE
