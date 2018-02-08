{ ====================================================================
Mouse click and text output demo

opyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL CLICKS A simple window demonstrating mouse clicks and text output

{ --------------------------------------------------------------------
This is a step-by-step tutorial describing the steps required to
develop a simple Windows application. The steps are laid out in an
order that has proven to work for us, but is by no means the only
order in which they could be done.

A Windows program is not like a traditional single-point entry,
do things until we are finished program. It has an entry point,
and a main routine, but almost all the work is accomplished during
callbacks.

The purpose of this program is to count mouse clicks (or button
presses) inside a window and display the tally for both right and
left buttons.  To do this, we need 1) a window 2) a routine to
recognize mouse clicks and count them, and 3) a routine to display
the results.

Notes regarding the code:
1) All references WM_xxx are constants associated with Windows
   Messages ( WM_ ).  References to words such as
   WS_OVERLAPPEDWINDOW are also constants.  These constants are
   not found in the Forth dictionary, but are automatically
   resolved as literals by the compiler from the WINCON.DLL file.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
1. Define the message handler and callback routine

This doesn't have to be first, but it is convenient to have it
already defined, and then extend it as the program grows.

A message switch is required to define the callback, and the
callback is required before the class can be registered, and
the class must be registered before the window can be created.
-------------------------------------------------------------------- }

\ hAPP holds the application handle. This is used to detect
\ that the application is active and for accessing the application
\ from the SwiftForth interactive environment.

0 VALUE hAPP

CREATE CLASSNAME ,Z" Counting"

\ Define the message handler. It is initially an empty switch whose
\ default behavior is to call the default Windows message handler.
\ We will add specific message handlers to the switch later.

[SWITCH MESSAGE-HANDLER DEFWINPROC ( -- res )
   ( no behavior yet)
SWITCH]

\ Having defined the switch, we can now define the callback. We use
\ a :NONAME since the function is useless in any other context.
\ The parameters to the function are held in the pseudo values
\ HWND MSG WPARAM and LPARAM -- not on the stack! These parameters
\ are available to any routine running during the execution of the
\ callback. The function must return a result.

:NONAME ( -- res )
   MSG LOWORD MESSAGE-HANDLER ;  4 CB: APPLICATION-CALLBACK

\ It is very nice to be able to repeatedly reload an application
\ being debugged. During the PRUNE operatino, SwiftForth
\ needs to be able to close the window if it is open and to
\ unregister the class so things don't crash.
\
\ After a class is registered, Windows may exercise the callback
\ at any time. If SwiftForth is going to prune the callback, it
\ must unregister the class so that Windows will not attempt to
\ call it.

:PRUNE   ?PRUNE -EXIT
   hAPP IF hAPP WM_CLOSE 0 0 SendMessage DROP THEN
   CLASSNAME HINST UnregisterClass DROP ;

{ --------------------------------------------------------------------
2. Register the class.

We register the class here via the DefaultClass SwiftForth function.
Note that this is _not_ a Windows function, but an abstraction of
the Windows RegisterClass function and the Windows WNDCLASS structure.
-------------------------------------------------------------------- }

\ Register a class for the application. The DefaultClass sets the
\ following styles, etc for the class:
\
\  style                = cs_hredraw
\                       | cs_vredraw
\                       | cs_owndc
\  class extra bytes  = 0
\  window extra bytes = 0
\  instance           = HINST (of SwiftForth)
\  icon               = HINST 101 LoadIcon
\  cursor             = IDC_ARROW
\  brush              = WHITE_BRUSH
\  menu               = null
\
\ plus your callback and your application name.

: REGISTER-CLASS ( -- )
   CLASSNAME APPLICATION-CALLBACK DefaultClass DROP ;

{ --------------------------------------------------------------------
3. Create and show the window.
4. Run the message loop until the window is closed.

Only after the class is registered are we allowed to create a window
of that class.  Here we create a window, specifying its styles and
size and title.  The return value is a handle to the window.

If we are debugging this application from SwiftForth, and we always
intend to run it from SwiftForth, this is all we need to do. The
reason is that SwiftForth already has a message loop running, and
all Windows created by SwiftForth will be processed automatically.
-------------------------------------------------------------------- }

: CREATE-WINDOW ( -- handle )
      0                                 \ extended style
      CLASSNAME                         \ window class name
      Z" Counting clicks"               \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 600 400                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: SHOW ( -- )
   hAPP 0 0 InvalidateRect DROP ;

\ We need to chain together the bits defined so far. Note that the
\ message handler is already linked to the class via the class's
\ callback routine. We return zero if we did not create the
\ window and nonzero (the window's handle) if we did.
\ This routine is usable in the SwiftForth environment and
\ will allow the interactive testing of the running window,
\ i.e., you may change the value of either variable and
\ execute SHOW and the window will update.

: START ( -- flag )
   REGISTER-CLASS CREATE-WINDOW DUP IF
      DUP SW_NORMAL ShowWindow DROP
      DUP UpdateWindow DROP
      DUP TO hAPP
   THEN ;

{ --------------------------------------------------------------------
5. Encapsulate the functionality of the program.

However, if we want to run this as a standalone application, we
must provide a full message loop and application termination.
This word does not return to SwiftForth -- on entering it, the
system will run the application until it is closed and then close
SwiftForth as well.

We establish this program as an application by placing the xt of GO
into 'MAIN and saving the image via the PROGRAM-SEALED function.

This action is commented out here for simplicity, but would need
to be at the end of the compilation to work properly.

' GO 'MAIN !
PROGRAM-SEALED TEST.EXE

This is the behavior of a stand-alone
application, and not useful in the development environment.
-------------------------------------------------------------------- }

: GO ( -- )
   START IF  DISPATCHER
   ELSE 0 Z" Can't create window" Z" Error" MB_OK MessageBox
   THEN ExitProcess ;

{ --------------------------------------------------------------------
6. Define the window behavior in terms of message responses.

So far, we have defined a very default window with no custom
responses to anything. In order for this to be an application,
we have to implement message behaviors that are appropriate
to our goals.

Almost none of these words is directly executable from the
Forth interpreter but must instead be called via the Windows
callback routine.

The message responses may be either named words referenced by
RUNS or un-named and referenced by RUN: .

This application will simply count left and right mouse clicks in
its client area. It is designed to be run directly from the
SwiftForth environment to aid in debugging it, but will have
hooks to let it run as a standalone application when finished.
-------------------------------------------------------------------- }

\ REFRESH simply tells Windows to update the contents of the
\ current window, which is identified by HWND.

: REFRESH ( -- )
   HWND 0 0 InvalidateRect DROP ;

\ Define variables to hold the button click counts.

VARIABLE RIGHT-CLICKS
VARIABLE LEFT-CLICKS

\ Mouse button clicks are sent as messages to the active window.
\ Add message actions for right and left button presses.

[+SWITCH MESSAGE-HANDLER ( -- res )
   WM_RBUTTONDOWN RUN:  1 RIGHT-CLICKS +! REFRESH 0 ;
   WM_LBUTTONDOWN RUN:  1 LEFT-CLICKS +!  REFRESH 0 ;
SWITCH]

\ (SHOW-CLICKS) formats the window's text at HERE.
\ Note that normal display words such as EMIT may not be used during
\ a callback, but the output formatting words such as (.) may.
\ HERE is also a valid (and reentrant) address during a callback,
\ so we build our output string at HERE.

: (SHOW-CLICKS) ( -- addr n )
   LEFT-CLICKS @ (.) HERE PLACE
   S"   left right " HERE APPEND
   RIGHT-CLICKS @ (.) HERE APPEND
   HERE COUNT ;

\ SHOW-CLICKS is the core of the REPAINT function. It formats the
\ text at HERE, determines the size of the display on which to show
\ the text, and draws the text.

: SHOW-CLICKS ( hdc -- )
   (SHOW-CLICKS)
   HWND PAD GetClientRect DROP  PAD
   DT_SINGLELINE DT_CENTER OR DT_VCENTER OR
   DrawText DROP ;

\ The hard bit is that nothing is automatic in Windows. We can
\ display messages pretty easily, but if another window obscures
\ our window, the information already displayed is lost. We must
\ be able to repaint the window on demand. This means handling
\ the WM_PAINT message.

: REPAINT ( -- res )
   HWND PAD BeginPaint ( hdc)
   HWND HERE GetClientRect DROP
   ( hdc)  SHOW-CLICKS
   HWND PAD EndPaint DROP  0 ;

[+SWITCH MESSAGE-HANDLER ( -- res )
   WM_PAINT RUNS REPAINT
SWITCH]

\ The last messages we must handle are related to closing the window.

\ We need to destroy the window and release resources when we
\ receive WM_CLOSE.  The act of destroying the window sends the
\ WM_DESTROY message, which we must also respond to by posting
\ the quit message which notifies the dispatcher that the application
\ is finished.

\ Note that the dispatcher will see the PostQuitMessage
\ terminate the application _and_ as a side-effect will terminate
\ SwiftForth as well. This is not acceptable for a development
\ session, and may not be acceptable even for a main application.


[+SWITCH MESSAGE-HANDLER ( -- res )
   WM_CLOSE RUN: HWND DestroyWindow DROP  0 TO hAPP  0 ;
   WM_DESTROY RUN: 0 'MAIN @ ?EXIT PostQuitMessage ;
SWITCH]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CR
CR .( Type START to run the Clicks demo.)
CR .( Press the left and right mouse button in the window, and)
CR .( watch the counters increment.)
CR
