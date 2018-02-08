{ ====================================================================
Put an icon in the tray

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL TRAYICON A SWOOP class for placing icons in the system tray.

LIBRARY USER32

FUNCTION: LoadImage ( hinst zname type width height flags -- handle )

LIBRARY SHELL32

FUNCTION: Shell_NotifyIcon ( fn 'icondata -- flag )

{ --------------------------------------------------------------------
NOTIFYICONDATA is simply a windows data structure
-------------------------------------------------------------------- }

CLASS NOTIFYICONDATA
   VARIABLE Size                \ size of structure
   VARIABLE hwnd                \ handle of window to get message
   VARIABLE ID                  \ application specified id for icon
   VARIABLE Flags               \ mask of which fields are valid
                                \   NIF_ICON     Icon is valid
                                \   NIF_MESSAGE  CallbackMessage is valid
                                \   NIF_TIP      szTip is valid
   VARIABLE CallbackMessage     \ message sent to hwnd on mouse event
   VARIABLE Icon                \ handle of icon to show
   64 BUFFER: Tip               \ tool tip text

   : CONSTRUCT ( -- )   [ THIS SIZEOF ] LITERAL Size ! ;

END-CLASS

{ --------------------------------------------------------------------
TRAYICON is a class for adding and deleting tray icons.
-------------------------------------------------------------------- }

NOTIFYICONDATA SUBCLASS TRAYICON

PROTECTED

   : SETUP ( hwnd id flags msg hicon ztext flags -- )
      ( flags) Flags !
      ( ztext) ZCOUNT Tip ZPLACE
      ( hicon) Icon !
      ( msg)   CallbackMessage !
      ( id)    ID !
      ( hwnd)  Hwnd ! ;

PUBLIC

   : ADD ( hwnd id msg hicon ztext -- flag )
      NIF_ICON NIF_MESSAGE OR NIF_TIP OR  SETUP
      NIM_ADD Size Shell_NotifyIcon ;

   : DEL ( hwnd id -- flag )
      0 0 0 0 SETUP
      NIM_DELETE Size Shell_NotifyIcon ;

END-CLASS

{ --------------------------------------------------------------------
Many people have had troubles using TrackPopupMenu. They have reported
that the popup menu will often not disappear once the mouse is clicked
outside of the menu, even though they have set the last parameter of
TrackPopupMenu() as NULL. This is a Microsoft "feature", and is by
design. The mind boggles, doesn't it?

Anyway - to workaround this "feature", one must set the current window
as the foreground window before calling TrackPopupMenu. This then
causes a second problem - namely that the next time the menu is
displayed it displays then immediately disappears. To fix this problem,
you must make the current application active after the menu
disappears. This can be done by sending a benign message such as
WM_USER to the current window.

So - what should have been a simple:

   TrackPopupMenu(hSubMenu, TPM_RIGHTBUTTON, pt.x,pt.y, 0, hDlg, NULL);

becomes
   SetForegroundWindow(hDlg);
   TrackPopupMenu(hSubMenu, TPM_RIGHTBUTTON, pt.x,pt.y, 0, hDlg, NULL);
   PostMessage(hDlg, WM_NULL, 0, 0);

Refer to Microsoft's KnowledgeBase article "PRB: Menus for Notification
Icons Don't Work Correctly" for more info.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

{ --------------------------------------------------------------------
An example of how to use the tray icon class
-------------------------------------------------------------------- }

MI_USER 100 +
   ENUM MI_TRAY
TO MI_USER

: /TRAY ( -- flag )
   [OBJECTS TRAYICON MAKES TI OBJECTS]
   HWND MI_TRAY WM_USER 1000 +
   HINST 101 LoadIcon
   Z" SwiftForth" TI ADD ;

: TRAY/ ( -- )
   [OBJECTS TRAYICON MAKES TI OBJECTS]
   HWND MI_TRAY TI DEL DROP ;

MENU TRAY-POPUP
   POPUP "TEST"
      100 MENUITEM "T0"
      101 MENUITEM "T1"
      102 MENUITEM "T2"
      103 MENUITEM "T3"
   END-POPUP
END-MENU

: TRAYMENU ( -- )
   HWND SetForegroundWindow DROP
   TRAY-POPUP LoadMenuIndirect  DUP >R
   0 GetSubMenu
   TPM_LEFTALIGN TPM_LEFTBUTTON OR TPM_RIGHTBUTTON OR
   MOUSEPOS 0 HWND 0 TrackPopupMenu DROP
   R> DestroyMenu DROP
   HWND WM_NULL 0 0 PostMessage DROP ;

: TRAYMESSAGE ( -- )
   LPARAM CASE
      WM_LBUTTONDOWN OF TRAYMENU ENDOF
   ENDCASE ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-MESSAGES
   WM_USER 1000 + RUN: TRAYMESSAGE 0 ;
SWITCH]

CONSOLE-WINDOW -ORDER

/TRAY
KEY DROP BYE [THEN]
