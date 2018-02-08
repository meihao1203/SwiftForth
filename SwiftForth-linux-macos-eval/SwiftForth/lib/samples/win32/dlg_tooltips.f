OPTIONAL DIALOG_TOOLTIPS An example of a dialog box with tooltips for its controls

{ ====================================================================
Dialog box with tooltips

The dialog building mechanisms are complex, and difficult to master.

Here is an example of a modeless dialog box, which could be embedded
as part of a larger application or can serve as a stand-alone
application. Many simple windows applications don't need more than a
dialog box, and using one takes a lot of the mundane stuff out of the
implementation path.

This dialog uses the IDSTRINGS extension to make defining the controls
easier. It also defines its behavior based on the Swoop class for
GENERICDIALOG, and serves as an example to extend into more complex
applications.

This file extends the original test dialog to include tooltips for
each of the buttons. I'm not sure that I'm completely happy with the
code which deals with creating the tips etc., but it does the job for
now and will be revised later.

Original Author:  Rick VanNorman
Initial release:  12 Jun 2011
====================================================================== }

0 CONSTANT STANDALONE

REQUIRES TOOLTIPS

\ ----------------------------------------------------------------------
\ define the dialog template. "(CLASS SFDLG)" indicates we are going
\ to use swoop for behavior and message handling.

DIALOG MY-TEMPLATE

[MODELESS " Dialog Example" 20 20 50 52  (CLASS SFDLG) (FONT 10, MS Sans Serif )]
 [PUSHBUTTON        " Browse"                ID: BROWSE        5 5  40  12  ]
 [PUSHBUTTON        " Convert"               ID: CONVERT       5 20 40  12  ]
 [PUSHBUTTON        " Clip"                  ID: CLIP          5 35 40  12  ]
END-DIALOG

\ ----------------------------------------------------------------------
\ define behavior for the dialog

GENERICDIALOG SUBCLASS MY-DIALOG

   \ required: the class must link to the template

   : TEMPLATE ( -- a )
      MY-TEMPLATE ;

   : BOX ( z -- )
      mHWND SWAP Z" Test" MB_OK MessageBox DROP ;

   ID_BROWSE COMMAND: ( -- res )
      Z" Browsing" BOX 0 ;

   ID_CLIP COMMAND: ( -- res )
      Z" Clipping" BOX 0 ;

   ID_CONVERT COMMAND: ( -- res )
      Z" Converting" BOX 0 ;

   \ inhibit <ENTER> and <ESC> behavior so it acts like an application window

   IDCANCEL COMMAND: ( -- res )   0 ;
   IDOK     COMMAND: ( -- res )   0 ;

\ ----------------------------------------------------------------------

   TOOLTIPS BUILDS TI

   : ADD-TIP ( control ztext -- )
      TI 'TEXT !  mHWND SWAP GetDlgItem TI ID !  TI ADD-TIP ;

   : ADD-TIPS ( -- )
      ID_CLIP    Z" clip"    ADD-TIP
      ID_CONVERT Z" convert" ADD-TIP
      ID_BROWSE  Z" browse"  ADD-TIP ;

   : INIT-TIPS ( -- )
      mHWND TI ATTACH  TTF_IDISHWND TTF_SUBCLASS OR  TI FLAGS !
      ADD-TIPS ;

\ ----------------------------------------------------------------------


   \ WM_DESTROY should only send the quit message if we are compiled
   \ and executing as a stand-alone application. during debug, or while
   \ using swiftforth for the host environment, the quit message would
   \ cause the ide to quit -- which is not desired.

   WM_DESTROY MESSAGE: ( -- res )
      STANDALONE IF 0 PostQuitMessage DROP THEN 0 ;

   WM_CLOSE MESSAGE: ( -- res )
      mHWND DestroyWindow DROP 0 ;

   WM_INITDIALOG MESSAGE: ( -- res )
      INIT-TIPS  0 ;

END-CLASS

\ ----------------------------------------------------------------------
\ instantiate a dialog, and a word to run it.
\ the dialog is modeless, so returns to the forth interpreter immediately.

MY-DIALOG BUILDS MYSTUFF

: GO ( -- )
   0 MYSTUFF MODELESS DROP ;
