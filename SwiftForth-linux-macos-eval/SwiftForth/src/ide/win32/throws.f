{ ====================================================================
Exception report dialog

Copyright (C) 2001-2011 FORTH, Inc.
Rick VanNorman
==================================================================== }

?( Exception information in dialog boxes)

PACKAGE ERROR-HANDLERS

{ ----------------------------------------------------------------------
DETAILSBOX displays the .EXCEPT text in a dialog box for an unignorable
user alert. The user to choose to terminate the application, continue,
or display more details.
---------------------------------------------------------------------- }

DIALOG PROCESSOR-EXCEPTION-TEMPLATE
   [MODELESS " Processor Exception"  10 10 400 220  (CLASS SFDLG) (FONT 8, MS Sans Serif) ]

   [TEXTBOX                          ID: PET_TEXT     5   5  390 190  (+STYLE WS_BORDER ES_AUTOHSCROLL ES_AUTOVSCROLL WS_HSCROLL WS_VSCROLL) ]
   [DEFPUSHBUTTON   " &OK"           IDOK            80 200   40  14 ]
   [AUTOCHECKBOX    " &Terminate"    ID: PET_TERM    20 200   50  14 ]

END-DIALOG

\ Must use PARAMDIALOG so not to break existing code
PARAMDIALOG SUBCLASS PROCESSOR-EXCEPTION-DIALOG

  : TEMPLATE ( -- a )
     PROCESSOR-EXCEPTION-TEMPLATE ;

   : DONE ( -- res )
      mHWND DUP  ID_PET_TERM IsDlgButtonChecked 0<> EndDialog ;

   IDOK     COMMAND: DONE ;
   IDCANCEL COMMAND: DONE ;

   WM_INITDIALOG MESSAGE: ( -- res )
      R-BUF  WINERROR R@ ZPLACE
      mHWND R> SetWindowText DROP
      mHWND ID_PET_TEXT SetDlgItemFixedFont
      mHWND ID_PET_TEXT LPARAM SetDlgItemText DROP
      -1 ;

END-CLASS

: DETAILSBOX ( -- res )
   [OBJECTS PROCESSOR-EXCEPTION-DIALOG MAKES PED OBJECTS]
   [BUF .EXCEPT BUF] ( leaves text in bufz )
   HWND BUFZ PED MODALP ;

{ --------------------------------------------------------------------
ERRORBOX is the first level of gui-based throw exposition. It simply
tells the user an error has occurred and allows the user to choose
to terminate the application, continue, or display more details.
-------------------------------------------------------------------- }

DIALOG ERRORBOX-TEMPLATE
   [MODAL " Error!"  10 10 150 45  (CLASS SFDLG)  (FONT 8, MS Sans Serif) ]

   [DEFPUSHBUTTON " &OK"         IDOK          60  25   40 15 ]
   [AUTOCHECKBOX  " &Terminate"  ID: EB_TERM    5  25   50 15 ]
   [PUSHBUTTON    " &Details"    ID: EB_MORE  105  25   40 15 ]
   [LTEXT                        ID: EB_TEXT    5   5  140 15 ]

END-DIALOG

\ Must use PARAMDIALOG so not to break existing code
PARAMDIALOG SUBCLASS ERRORBOX-DIALOG

   : TEMPLATE ( -- a )   ERRORBOX-TEMPLATE ;

   : ?TERMINATE ( -- res )
      mHWND ID_EB_TERM IsDlgButtonChecked 0<>  CLOSE-DIALOG ;

   256 BUFFER: THROW-MESSAGE

   : INIT ( -- res )
      LPARAM (THROW) THROW-MESSAGE ZPLACE
      mHWND ID_EB_TEXT THROW-MESSAGE SetDlgItemText DROP -1 ;

   IDOK       COMMAND: ?TERMINATE ;
   IDCANCEL   COMMAND: ?TERMINATE ;
   ID_EB_MORE COMMAND: 1 CLOSE-DIALOG ;

   WM_INITDIALOG MESSAGE: INIT ;
   WM_CLOSE      MESSAGE: ?TERMINATE ;

END-CLASS

: ERRORBOX ( n -- )
   [OBJECTS ERRORBOX-DIALOG MAKES EBD OBJECTS]
   HWND SWAP EBD MODALP
   DUP 1 = IF DROP DETAILSBOX THEN  0< IF  1 ExitProcess  THEN ;

{ ------------------------------------------------------------------------
Reporting the cause of exceptions and THROW events is enhanced here.
.THROW displays messages on the console or in a dialog box depending
on WARNING-LEVEL. The .CATCH defer is pointed to .THROW.
------------------------------------------------------------------------ }

PUBLIC

: WARNING-LEVEL ( -- n )
   WARNING CELL+ @ DUP -4 AND SWAP  3 AND 1 MAX  OR ;

PRIVATE

: TTY-ERRMSG ( ior -- )
   WARNING-LEVEL DUP 1 AND IF
      4 AND  OVER IOR_WINEXCEPT =  AND IF
         CR ." >>> " .EXCEPT  EXIT
      THEN  ERRORMSG EXIT
   THEN 2DROP ;

: GUI-ERRMSG ( ior -- )
   WARNING-LEVEL DUP 2 AND IF
      4 AND  OVER IOR_WINEXCEPT =  AND IF
         DETAILSBOX EXIT
      THEN  ERRORBOX EXIT
   THEN 2DROP ;

: .THROW ( ior -- )
   /INPUT
   DUP -1 = IF DROP EXIT THEN
   DUP TTY-ERRMSG GUI-ERRMSG ;

' .THROW IS .CATCH

WINDOWS-INTERFACE +ORDER
' DETAILSBOX IS CAUGHT
WINDOWS-INTERFACE -ORDER

END-PACKAGE

WARNING ON   $11 WARNING CELL+ !        \ Set defaults
