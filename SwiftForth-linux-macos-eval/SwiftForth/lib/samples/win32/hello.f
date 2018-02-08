{ ====================================================================
Simple "Hello World" Windows app

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL HELLO Simple "Hello world" demonstration

{ --------------------------------------------------------------------
This program is a simple application which demonstrates windows
programming in SwiftForth.  It registers a class for a new window
type, defines callbacks for it, has a dialog box, uses menus, handles
messages and painting on a device context.

It requires almost all of the underlying SwiftForth development
environment to compile and run.
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS DECIMAL

{ ------------------------------------------------------------------------
About box

Even a simple application like Hello needs an about box. This one is a
trivial modal dialog with three text controls and a single pushbutton.

HELLO-CLOSE-ABOUT  closes the dialog. It is factored instead of inline
because it is used in three places.

HELLO-ABOUT-COMMANDS  handles the messages to the individual dialog
controls.  In this case, the only defined control is the OK button,
which we interpret as meaning: close the box.

HELLO-ABOUT-MESSAGES  handles all the window messages to the about
box.  We care about only three, two of which close it. IDOK and IDCANCEL
are system constants that also correspond to the key presses for
<space> and <escape>.

The NONAME definition is the Forth code that the actual callback routine
for the dialog vectors to.

RUNHELLOABOUT  is the actual entry point for the callback.

HELLO-ABOUT  builds and runs the dialog.
------------------------------------------------------------------------ }

DIALOG (HELLO-ABOUT)
[MODELESS " About Hello" 10 10 120 70
   (FONT 8, MS Sans Serif) ]
\  [class           text                        id   x   y   sx xy ]

   [CTEXT           " HELLO"                    -1  10  10  100 10 ]
   [CTEXT           " (C) 1997 Forth, Inc."     -1  10  25  100 10 ]
   [CTEXT           " http://www.forth.com"     -1  10  35  100 10 ]
   [DEFPUSHBUTTON   " OK"                     IDOK  35  50   50 14 ]
END-DIALOG

: HELLO-CLOSE-ABOUT ( -- res )
   HWND 0 EndDialog ;

[SWITCH HELLO-ABOUT-COMMANDS ZERO
   IDOK     RUN: ( -- res )   HELLO-CLOSE-ABOUT ;
   IDCANCEL RUN: ( -- res )   HELLO-CLOSE-ABOUT ;
SWITCH]

[SWITCH HELLO-ABOUT-MESSAGES ZERO
   WM_CLOSE      RUN: ( -- res )   HELLO-CLOSE-ABOUT ;
   WM_COMMAND    RUN: ( -- res )   WPARAM LOWORD HELLO-ABOUT-COMMANDS ;
   WM_INITDIALOG RUN: ( -- res )   -1 ;
SWITCH]

:NONAME ( -- res )
   MSG LOWORD HELLO-ABOUT-MESSAGES ;  4 CB: RUNHELLOABOUT

: HELLO-ABOUT
   HINST (HELLO-ABOUT) HWND RUNHELLOABOUT 0
   DialogBoxIndirectParam DROP ;

{ ------------------------------------------------------------------------
Menu

The Hello program supports a simple menu. Selections are only exit
and about.  The menus could easily be extended to perform other
actions.

HELLO-MENU  defines the menu template
------------------------------------------------------------------------ }

MENU HELLO-MENU
   POPUP "&File"
      MI_EXIT MENUITEM "E&xit"
   END-POPUP

   POPUP "&Help"
      MI_ABOUT MENUITEM "&About"
   END-POPUP
END-MENU

: CREATE-HELLO-MENU ( -- hmenu )
   HELLO-MENU LoadMenuIndirect ;

{ ------------------------------------------------------------------------
Names, values, and variables

AppName  is simply the string constant name of the windows class created.

HELLOS  is a value which indicates how many instances of the hello
window are open.

hClass  is the handle to the registered class for hello.

PRESSES  counts the total presses in all the hello windows.

The class HELLOAPP is created with an extra 8 bytes of storage, which
effectively gives each instance its own copy of data.  These extra bytes
are used to count ticks and mouse presses.

COUNTER@  reads the tick counter and
COUNTER!  writes it.

PRESSES@  reads the mouse press counter and
PRESSES!  writes it.
------------------------------------------------------------------------ }

: AppName ( -- zaddr )   Z" HelloApp"    ;

0 VALUE HELLOS
0 VALUE hClass
0 VALUE PRESSES

: COUNTER@  ( -- n )  HWND 0 GetWindowLong ;
: COUNTER!  ( n -- )  HWND 0 ROT SetWindowLong DROP ;

: PRESSES@  ( -- n )  HWND 4 GetWindowLong ;
: PRESSES!  ( n -- )  HWND 4 ROT SetWindowLong DROP ;

{ ------------------------------------------------------------------------
Runtime actions

.HELLO  refreshes the data displayed in the window.  Note that it
initializes it's local user area and creates a tiny local dictionary
so that the numeric conversion routines will work.  The device context
for the output is given to .HELLO .

HELLO-PAINT  redraws the display and increments the tick counter.

HELLO-CReATE  initializes the tick counter and creates a 200 ms timer.

HELLO-DEFAULT  is called if our message switch cannot match the message
The N passed to it is the message id which was not handled and it calls
the default windows message handler.

HELLO-CLOSE  kills the timer, destroys the window, and (if this is
the last instance of the hello application) unregisters the class.

------------------------------------------------------------------------ }
\ Here we get to draw in the window. The counter will increment every
\ time PAINT is called.

: .HELLO ( hdc -- )
   DUP ( hdc) 20 20 COUNTER@ (.)      TextOut DROP
   DUP ( hdc) 20 40 PRESSES@ (.)      TextOut DROP
   DUP ( hdc) 20 60 PRESSES  (.)      TextOut DROP
   DUP ( hdc) 20 80 HELLOS   (.)      TextOut DROP
   DUP ( hdc) 50 20 S" Ticks"         TextOut DROP
   DUP ( hdc) 50 40 S" Presses here"  TextOut DROP
   DUP ( hdc) 50 60 S" Presses total" TextOut DROP
   DUP ( hdc) 50 80 S" Hellos open"   TextOut DROP
   DROP ;

: HELLO-PAINT ( -- )
   64 R-ALLOC >R ( paint structure)
   HWND R@ BeginPaint ( hdc)
   ( hdc) .HELLO
   COUNTER@ 1+ COUNTER!
   HWND R> EndPaint DROP ;

: HELLO-CREATE ( -- )
   HWND CREATE-HELLO-MENU SetMenu DROP
   1 COUNTER!  HWND 1 200 0 SetTimer DROP
   1 +TO HELLOS ;

: HELLO-DEFAULT ( n -- res )
   DROP HWND MSG WPARAM LPARAM DefWindowProc ;

: HELLO-CLOSE ( -- )
   HWND 1 KillTimer DROP
   HWND DUP GetMenu  DestroyMenu DROP
   HWND DestroyWindow DROP
   -1 +TO HELLOS ;

{ ------------------------------------------------------------------------
COMMANDS and MESSAGES

HELLO-COMMMANDS  manages the messages generated by the menu.

HELLO-MESSAGES  handles the normal system messages.  When the mouse
button is pressed, it increments PRESSES.  When the timer ticks, it
repaints the display (which increments COUNTER).

NONAME  is the forth callback for the windows proc.

HELLO-WNDPROC is the actual entry point for the WNDPROC for the
registered class HelloApp.
------------------------------------------------------------------------ }

[SWITCH HELLO-COMMANDS ZERO
   MI_EXIT  RUN: ( -- res )   HELLO-CLOSE 0 ;
   MI_ABOUT RUN: ( -- res )   HELLO-ABOUT 0 ;
SWITCH]

[SWITCH HELLO-MESSAGES HELLO-DEFAULT
   WM_COMMAND     RUN: ( -- res )   WPARAM LOWORD HELLO-COMMANDS ;
   WM_PAINT       RUN: ( -- res )   HELLO-PAINT 0 ;
   WM_CREATE      RUN: ( -- res )   HELLO-CREATE 0 ;
   WM_LBUTTONDOWN RUN: ( -- res )   PRESSES@ 1+ PRESSES!  1 +TO PRESSES  0 ;
   WM_TIMER       RUN: ( -- res )   HWND 0 1 InvalidateRect DROP 0 ;
   WM_CLOSE       RUN: ( -- res )   HELLO-CLOSE 0 ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD HELLO-MESSAGES ;  4 CB: HELLO-WNDPROC

{ ------------------------------------------------------------------------
HELLO WORLD

REGISTER-CLASS  build the class information structure at HERE, registers
the class, and then disposes of the strucure.

CREATE-HELLO-WINDOW  creates the hello world window.

HelloWorld  regsiters the class, creates the window and displays the window.

DEMO  just runs HelloWorld .

DEMOS  opens N copies of the hello world window.
------------------------------------------------------------------------ }

: REGISTER-CLASS  ( -- )
   0 CS_HREDRAW OR
     CS_VREDRAW OR
   HELLO-WNDPROC
   0
   8
   HINST
   HINST 101 LoadIcon
   0 IDC_ARROW LoadCursor
   WHITE_BRUSH GetStockObject
   0
   AppName
   DefineClass DROP ;

: CREATE-HELLO-WINDOW  ( -- res )
   0                       \ exended style
   AppName                 \ class name
   Z" Hello World"         \ window title
   WS_OVERLAPPEDWINDOW     \ window style
   HELLOS 80 * DUP 300 200 \ x y cx cy
   0                       \ parent window
   0                       \ menu
   HINST                   \ instance handle
   0                       \ creation parameters
   CreateWindowEx ;

: HelloWorld ( -- )
   CREATE-HELLO-MENU DROP
   REGISTER-CLASS
   CREATE-HELLO-WINDOW  DUP 0= ABORT" create window failed"
   DUP 1 ShowWindow DROP
   DUP UpdateWindow DROP
   DROP ;

: DEMO ( -- )
   HelloWorld ;

: DEMOS ( n -- )
   1 MAX  8 MIN  0 DO DEMO LOOP ;

{ ------------------------------------------------------------------------
Instructions for running the demo

------------------------------------------------------------------------ }

CR
CR
CR .( HelloWorld demo for SwiftForth)
CR
CR .( Each window will count how many times it has been repainted,)
CR .( how many mouse clicks happened to it, how many mouse clicks)
CR .( have happened to all the HelloWorld windows, and how many)
CR .( HelloWorld windows are currently open.)
CR
CR .( Type "DEMO" to begin.)
CR .( Type "DEMO" again to create a second window.)
CR .( Type "4 DEMOS" to create four more windows.)
CR
CR
