{ ====================================================================
Select a path

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL CHOOSEPATH An extension of the OpenFileName dialog to allow the user to pick a new working directory

PACKAGE OFN-DIALOGS

REQUIRES CommonDialogConstants

{ --------------------------------------------------------------------
GONE makes a control disappear from the ofn common dialog and
TEXT sets a new text value on an ofn common dialog control.
-------------------------------------------------------------------- }

: GONE ( id -- )
   HWND GetParent CDM_HIDECONTROL ROT 0 SendMessage DROP ;

: TEXT ( id z -- )
   HWND GetParent CDM_SETCONTROLTEXT 2SWAP SendMessage DROP ;

{ --------------------------------------------------------------------
[OFN-CHILD is shorthand for [MODAL with (+STYLE ...) and (-STYLE ...)
-------------------------------------------------------------------- }

PACKAGE DLGCOMP

(OR
   WS_CHILD
   WS_CLIPSIBLINGS
   WS_VISIBLE
   DS_3DLOOK
   DS_CONTROL)
DIALOG-HEADER [OFN-CHILD

END-PACKAGE

{ --------------------------------------------------------------------
This dialog overlays the open filename dialog.
-------------------------------------------------------------------- }

DIALOG OFN-OVERLAY
   [OFN-CHILD 0 0 280 110 (FONT 8, MS Sans Serif) ]

   [PUSHBUTTON " &Cancel"   IDCANCEL 230  90  45 15 ]
   [PUSHBUTTON " &Use Path" IDOK     180  90  45 15 ]
   [EDITTEXT   " C:\TEST"   102        5  90 170 15 (+STYLE ES_READONLY) ]
   [LTEXT      " NOTHING"   103        5 112 170 15 (-STYLE WS_VISIBLE) ]

{ --------------------------------------------------------------------
SHOW-PATH writes the current ofn path to the text control.

ACCEPT-PATH jams the current path into the filename field of the
OPENFILENAME data strcuture.

REJECT-PATH clears the filename field, so we can detect a cancel.

NOTIFIED handles the folder change notification so we can update the
text field of the dialog.

DONE send a close message to the parent, ie the ofn dialog.
-------------------------------------------------------------------- }

: SHOW-PATH ( -- )
   HWND GetParent CDM_GETFOLDERPATH 260 PAD SendMessage DROP
   HWND 102 PAD SetDlgItemText DROP ;

: ACCEPT-PATH ( -- )
   HWND 103 0 0 GetDlgItemInt
   [OBJECTS OPENFILENAME NAMES OFN OBJECTS]
   HWND 102 OFN zFILE @ OFN MaxFile @ GetDlgItemText ;

: REJECT-PATH ( -- )
   HWND 103 0 0 GetDlgItemInt
   [OBJECTS OPENFILENAME NAMES OFN OBJECTS]
   0 OFN zFILE @ C! ;

: NOTIFIED ( -- res )
   LPARAM 2 CELLS + @ CASE
      CDN_FOLDERCHANGE OF SHOW-PATH ENDOF
   ENDCASE 0 ;

: DONE ( -- )
   HWND GetParent WM_CLOSE 0 0 SendMessage DROP ;

{ --------------------------------------------------------------------
This is the message switch hook for my dialog overlay. It hides
some of the ofn dialog controls, manages notification messages, and
deals with our buttons for cancel or accept.
-------------------------------------------------------------------- }

:NONAME ( -- res )
   MSG CASE
      WM_INITDIALOG OF
         edt1 GONE                      \ file selection
         stc3 GONE                      \ file selection label
         cmb1 GONE                      \ filter selection
         stc2 GONE                      \ filter selection label
         IDOK GONE                      \ open button
         IDCANCEL GONE                  \ cancel button
         HWND 103 LPARAM 0 SetDlgItemInt DROP
         SHOW-PATH
      ENDOF
      WM_NOTIFY OF
         NOTIFIED
      ENDOF
      WM_COMMAND OF
         WPARAM LOWORD CASE
            IDCANCEL OF  REJECT-PATH DONE  ENDOF
            IDOK     OF  ACCEPT-PATH DONE  ENDOF
         ENDCASE 0
      ENDOF
      DUP OF ( unknown)   0  ENDOF
   ENDCASE ;   4 CB: MYHOOK

{ --------------------------------------------------------------------
CHOOSE-PATH-DIALOG extends the OFN-DIALOG class to use the dialog
overlay and the hook procedure.
-------------------------------------------------------------------- }

OFN-DIALOG SUBCLASS CHOOSE-PATH-DIALOG

   : CUSTOM ( -- title filter flags )
      MYHOOK HOOK !  OFN-OVERLAY INSTANCE !
      Z" Choose Path"  ALL-FILES
      DEFAULT-OPEN-FLAGS
      OFN_ENABLETEMPLATEHANDLE OR
      OFN_EXPLORER OR
      OFN_ENABLEHOOK OR ;

END-CLASS

END-PACKAGE

{ --------------------------------------------------------------------
TESTING
-------------------------------------------------------------------- }

OFN-DIALOGS +ORDER

: TEST ( -- )
   [OBJECTS CHOOSE-PATH-DIALOG MAKES CPD OBJECTS]
   CPD CHOOSE ;

OFN-DIALOGS -ORDER
