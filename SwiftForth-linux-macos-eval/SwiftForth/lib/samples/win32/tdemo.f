{ ====================================================================
Turtle graphics demo

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL TDEMO A graphics demonstration using turtle graphics in its own window

{ --------------------------------------------------------------------
If you want to make a graphics routine in a standalone application,
you must be able to deal with the repaint operation.

You either modify the turtle drawing routine to record all lines; or
you save the actual bitmap image of the window when it is obscured; or
you define a particular word to redraw the image you are interested in
when a redraw is required.

The simplest is the third option. It fails that it cannot save and
reproduce arbitrary user drawing with the turtle, but can handily
reproduce a fixed algorithm.

The turtle already draws on the window that is active when the routines
are called, so the routine simply needs to go into the callback in
order to be effective.
-------------------------------------------------------------------- }

REQUIRES TURTLE

{ --------------------------------------------------------------------
Define the message handler and callback routine
-------------------------------------------------------------------- }

CREATE CLASSNAME ,Z" Spinning"

[SWITCH MESSAGE-HANDLER DEFWINPROC ( -- res )
   ( no behavior yet)
SWITCH]

:NONAME ( -- res )
   MSG LOWORD MESSAGE-HANDLER ;  4 CB: APPLICATION-CALLBACK

:PRUNE   ?PRUNE -EXIT
   BEGIN
      CLASSNAME 0 FindWindow ?DUP WHILE
      WM_CLOSE 0 0 SendMessage DROP
   REPEAT
   CLASSNAME HINST UnregisterClass DROP ;

{ --------------------------------------------------------------------
Register the class.
-------------------------------------------------------------------- }

: REGISTER-CLASS ( -- )
   CLASSNAME APPLICATION-CALLBACK DefaultClass DROP ;

{ --------------------------------------------------------------------
Create and show the window.
Run the message loop until the window is closed.
-------------------------------------------------------------------- }

: CREATE-WINDOW ( -- handle )
      0                                 \ extended style
      CLASSNAME                         \ window class name
      Z" Spiral Graphics Angle= 89"     \ Window title, has _active_ data!
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 400 400                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: START ( -- flag )
   REGISTER-CLASS CREATE-WINDOW DUP IF
      DUP SW_NORMAL ShowWindow DROP
      DUP UpdateWindow DROP
   THEN ;

{ --------------------------------------------------------------------
Encapsulate the functionality of the program.

This action is commented out here for simplicity, but would need
to be at the end of the compilation to work properly.

\   ' GO 'MAIN !
\   PROGRAM TEST.EXE

This is the behavior of a stand-alone
application, and not useful in the development environment.
-------------------------------------------------------------------- }

: GO ( -- )
   START IF  DISPATCHER
   ELSE 0 Z" Can't create window" Z" Error" MB_OK MessageBox
   THEN ExitProcess ;

{ --------------------------------------------------------------------
Define the window behavior in terms of message responses.
-------------------------------------------------------------------- }

\ REFRESH simply tells Windows to update the contents of the
\ current window, which is identified by HWND.

: REFRESH ( hwnd -- )
   0 -1 InvalidateRect DROP ;

DEFER DRAWING   ' NOOP IS DRAWING

: REPAINT ( -- res )
   HWND PAD BeginPaint ( hdc)
   DRAWING
   HWND PAD EndPaint DROP  0 ;

: -APP ( -- flag )
   'MAIN @ [ 'MAIN @ ] LITERAL = ;

[+SWITCH MESSAGE-HANDLER ( -- res )
   WM_PAINT RUNS REPAINT
   WM_CLOSE RUN: HWND DestroyWindow DROP  0 ;
   WM_DESTROY RUN: 0  -APP IF EXIT THEN 0 PostQuitMessage DROP ;
SWITCH]

{ --------------------------------------------------------------------
The caption in this application is used for a purpose that
Microsoft never intended. I keep window-specific data in it.

The turn angle is kept as the fourth word, the turn rate (if
in autospin) is kept in the second word.

To turn the spiral, we read the fourth parameter, change it,
use it, and write the new value back. Ditto for the autospin.

The caption looks like:
   Spiral Graphics Angle= nn
or
   Rate= nn  Angle= nn
depending on normal or autospin.

CAPTION returns the entire window caption

SPINNING? checks the first 5 chars of the caption to see if they
are "Rate=" .

@TURN extracts the angle from the caption and
@RATE extracts the period in ms from the caption.

!TURN replaces the current angle with a new one, leaving the
rest of the caption alone.

!RATE sets the entire caption to the autospin caption, retaining
only the current rate value.
-------------------------------------------------------------------- }

256 BUFFER: 'CAPTION

: CAPTION ( -- zaddr )
   HWND 'CAPTION 255 GetWindowText DROP  'CAPTION ;

: SPINNING? ( -- flag )
   CAPTION  S" Rate=" TUCK COMPARE 0= ;

: @TURN ( -- n )
   CAPTION ZCOUNT 3 ARGV ATOI ;

: @RATE
   CAPTION ZCOUNT 1 ARGV ATOI ;

: !TURN ( n -- )
   CAPTION  0 OVER ZCOUNT 3 ARGV DROP C! ZCOUNT
   <% ( n a len) %s %d %>
   HWND SWAP SetWindowText DROP ;

: !RATE ( n -- )
   <% S" Rate= " %s  ( n) %d  S"  Angle= " %s  @TURN %d %>
   HWND SWAP SetWindowText DROP ;

{ --------------------------------------------------------------------
INSTRUCTIONS prints minimal instructions on the given HDC based
on the current mode, either autospin or not.

SPIN sets a new turn angle and refreshes the display. The act
of refreshing causes WM_PAINT to be sent, which causes the
polyspiral to be redrawn.

STARTAUTO resets the timer to 100ms and sets the caption so that
it reflects the autospin state.

STOPAUTO resets the timer to 100ms and clears the autospin state.

SPINNING is run via the mouse button clicks. The right button
is positive, the left negative.  If we are in autospin, we use
the value as a modifier for the rate, up to 1000 ms or down to
50 ms.  If not in autospin, we increase or decrease the turn angle.

SHIFT? returns true if the shift key is pressed and the current
window has the focus.
-------------------------------------------------------------------- }

: SHIFT? ( -- flag )
   VK_SHIFT GetKeyState $8000 AND 0<>  GetFocus HWND =  AND ;

: INSTRUCTIONS ( hdc -- )
   SPINNING? IF
      S" Left faster, right slower, shift stops autospin"
   ELSE
      S" Left decreases, right increases, shift starts autospin"
   THEN
   10 0 2SWAP TextOut DROP ;

: SPIN ( angle -- )
   3600000 + 360 MOD 1 MAX 359 MIN !TURN  HWND REFRESH ;

: STARTAUTO ( -- )
   HWND 1 KillTimer DROP
   100 !RATE
   HWND 1 100 0 SetTimer DROP ;

: STOPAUTO ( -- )
   HWND 1 KillTimer DROP
   HWND 1 100 0 SetTimer DROP
   <% S" Spiral Graphics Angle= " %s @TURN %d %>
   HWND SWAP SetWindowText DROP
   HWND REFRESH ;

: SPINNING ( n -- )
   SPINNING? IF
      10 *  @RATE +  50 MAX  1000 MIN  DUP !RATE
      HWND 1 KillTimer DROP
      HWND 1 ROT 0 SetTimer DROP
   ELSE
      @TURN + SPIN
   THEN ;

{ --------------------------------------------------------------------
DOTIMER runs constantly, checking for the shift key. If we are in
autospin and the shift key is pressed, we clear the autospin and
resume interactive mode. Otherwise, we increment the turn angle.
If not in autospin, we setup for autospin and continue.

MESSAGE-HANDLER is extended to handle the events we are interested
in; in particular we create a timer on WM_CREATE, kill it on WM_CLOSE,
change things on mouse clicks, and deal with what the user told us
to do on timer events.
-------------------------------------------------------------------- }

: DOTIMER
   SPINNING? IF
      SHIFT? IF  STOPAUTO  100 Sleep DROP  ELSE  @TURN 1+ SPIN  THEN
   ELSE
      SHIFT? IF  STARTAUTO  THEN
   THEN ;

[+SWITCH MESSAGE-HANDLER ( -- res )
   WM_LBUTTONDOWN RUN: -1 SPINNING 0 ;
   WM_RBUTTONDOWN RUN:  1 SPINNING 0 ;
   WM_TIMER       RUN:  DOTIMER 0 ;
   WM_CLOSE       RUN:  HWND 1 KillTimer DROP  HWND DestroyWindow DROP  0 ;
   WM_CREATE      RUN:  HWND 1 100 0 SetTimer DROP 0 ;
SWITCH]

{ --------------------------------------------------------------------
SPIRAL draws a polyspi of the given angle.

DRAWIT is the resolved repaint behavior. It writes the instructions
on the screen and draws the spiral.
-------------------------------------------------------------------- }

: SPIRAL ( angle -- )
   0 BEGIN
      DUP 2* FORE OVER RIGHT 1+
      GETXY OR 0< UNTIL 2DROP ;

: DRAWIT ( hdc -- )
   INSTRUCTIONS CENTER PD @TURN SPIRAL ;

' DRAWIT IS DRAWING

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CR
CR .( Turtle graphics demonstration program loaded.)
CR
CR .( Type START to run the application now.)

[DEFINED] PROGRAM [IF]

: SAVE
   ['] GO 'MAIN !  -1 THRESHOLD
   S" PROGRAM TDEMO.EXE" EVALUATE ;

CR
CR .( Type SAVE to create TDEMO.EXE for standalone use.)
CR

[THEN]
