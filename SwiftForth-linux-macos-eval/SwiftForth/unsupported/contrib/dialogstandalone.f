{ ========================================================
Standalone Dialog Example

Mike Ghan 2/25/2007
========================================================= }

FUNCTION: DrawMenuBar ( hWnd -- res )

101 CONSTANT MID_FOO
102 CONSTANT MID_BAR

MENU my-MENU
   POPUP "&File"
      MID_FOO  MENUITEM "Foo"
   END-POPUP
   MID_BAR  MENUITEM "Bar"
END-MENU


DIALOG DLG-TMPL
[MODAL " Test Dialog" 20 20 300 70
 (CLASS SFDLG) (FONT 8, MS Sans Serif)
 (+STYLE WS_SYSMENU DS_CENTER) ]
 [DEFPUSHBUTTON  " OK"           IDOK     4   40  40  14 ]
 [PUSHBUTTON     " Cancel"       IDCANCEL 94  40  40  14 ]
 [RTEXT          " # of Widgets" 101      4   20  64  10 ]
 [EDITTEXT                       102      72  20  36  10 ]
END-DIALOG


GENERICDIALOG SUBCLASS TEST-DIALOG

   : TEMPLATE ( -- addr )   DLG-TMPL ;

   : INIT-MENU  ( -- )
      HWND MY-MENU LoadMenuIndirect SetMenu DROP
      HWND DrawMenuBar DROP ;

   WM_INITDIALOG MESSAGE: ( -- res )
      INIT-MENU ( Optional )
      TRUE ( Windows sets focus ) ;

   MID_FOO COMMAND:  ( -- )
      Z" Foo Message"  Z" Foo Title" MB_OK MessageBox DROP
      ;
   IDOK COMMAND:  ( -- )
      1 CLOSE-DIALOG ;

   IDCANCEL COMMAND:
      0 CLOSE-DIALOG ;

END-CLASS

TEST-DIALOG BUILDS MY-DLG

: WINMAIN
   GetDesktopWindow MY-DLG MODAL DROP
   'ONSYSEXIT CALLS  \ Execute System Exit Chain
   0 ExitProcess ;

\ Save App

' WINMAIN 'MAIN !
PROGRAM-SEALED TEST-DLG.EXE

BYE
