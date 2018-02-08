OPTIONAL DIALOG_APPLICATION An example of using a dialog box as a standalone application

{ ======================================================================
Modeless dialog box application

The dialog building mechanisms are complex, and difficult to master.

Here is an example of a modeless dialog box, which could be embedded
as part of a larger application or can serve as a stand-alone application.
Many simple windows applications don't need more than a dialog box, and
using one takes a lot of the mundane stuff out of the implementation path.

This dialog uses the IDSTRINGS extension to make defining the controls
easier. It also defines its behavior based on the Swoop class for
GENERICDIALOG, and serves as an example to extend into more complex
applications.

Original Author:  Rick VanNorman
Initial release:  12 Jun 2011
====================================================================== }

1 CONSTANT STANDALONE

\ ----------------------------------------------------------------------
\ define the dialog template. "(CLASS SFDLG)" indicates we are going
\ to use swoop for behavior and message handling.

DIALOG MY-TEMPLATE

[MODELESS " Dialog Example" 20 20 50 52  (CLASS SFDLG) (FONT 10, MS Sans Serif )]
 [PUSHBUTTON        " Browse"                ID: BROWSE_SRC    5 5  40  12  ]
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

   ID_BROWSE_SRC COMMAND: ( -- res )
      Z" Browsing" BOX 0 ;

   ID_CLIP COMMAND: ( -- res )
      Z" Clipping" BOX 0 ;

   ID_CONVERT COMMAND: ( -- res )
      Z" Converting" BOX 0 ;

   \ inhibit <ENTER> and <ESC> behavior so it acts like an application window

   IDCANCEL COMMAND: ( -- res )   0 ;
   IDOK     COMMAND: ( -- res )   0 ;

   \ WM_DESTROY should only send the quit message if we are compiled
   \ and executing as a stand-alone application. during debug, or while
   \ using swiftforth for the host environment, the quit message would
   \ cause the ide to quit -- which is not desired.

   WM_DESTROY MESSAGE: ( -- res )
      STANDALONE IF 0 PostQuitMessage DROP THEN 0 ;

   WM_CLOSE MESSAGE: ( -- res )
      mHWND DestroyWindow DROP 0 ;

   WM_INITDIALOG MESSAGE: ( -- res )
      0 ;

END-CLASS

\ ----------------------------------------------------------------------
\ instantiate a dialog, and a word to run it.
\ the dialog is modeless, so returns to the forth interpreter immediately.

MY-DIALOG BUILDS MYSTUFF

STANDALONE 0= [IF]

: GO ( -- )
   0 MYSTUFF MODELESS DROP ;

[THEN]

{ ----------------------------------------------------------------------
To make the dialog completely standalone, the following code is used.
Note that the message dispatcher contained in SwiftForth services the
ide interactions, and also dispatches messages for dialog boxes. It
works, but isn't suitable for a dialog box that is a standalone
application. The following is a much better implementation.
---------------------------------------------------------------------- }

STANDALONE [IF]

: DISPATCHING ( -- )
   BEGIN
      WINMSG 0 0 0 GetMessage ( status)
      1+ 1 U> WHILE ( -1 or 0 will terminate the loop )
      MYSTUFF mHWND WINMSG IsDialogMessage 0= IF
         WINMSG TranslateMessage DROP
         WINMSG DispatchMessage DROP
      THEN
   REPEAT WINMSG 2 CELLS + @ ( wparam) ;

\ 'ONSYSLOAD is called before the 'MAIN vector is considered, so
\ we only need to call 'ONSYSEXIT.

: WINMAIN ( -- )
   0 MYSTUFF  MODELESS  DISPATCHING
   'ONSYSEXIT CALLS  0 ExitProcess ;

' WINMAIN 'MAIN !
-1 THRESHOLD
PROGRAM-SEALED TEST.EXE

[THEN]
