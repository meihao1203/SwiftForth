{ ====================================================================
Screen saver template

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL SCREENSAVER A simple Windows screen saver template for SwiftForth. See the source for the user API.

{ --------------------------------------------------------------------
EXPORTS:
   SHOW    Run the saver full-screen.
   TEST    Run the saver in debug mode, 1/4 screen.
   SETUP   Run the saver configuration dialog.

   SAVERRATE    deferred word, ( -- zstr )
   DOSAVER      deferred word, ( hwnd -- )
   DOCONFIG     deferred word, ( hwnd -- )

These three words are all that is required to extend this template
into a full screen saver.

SAVERRATE is a registry key name for saving the update rate.  This is
the only required registry entry for the screen saver. If this defer
is not set, the saver will default to a rate of 50 ms.  Otherwise, it
will clip to a rate of 1 ms thru 10 seconds.

DOSAVER executes one iteration of the screen saver. The only information
passed is the HWND to draw the saver on. Do not assume that the system
variable HWND is valid during this operation!

DOCONFIG runs a configuration dialog for the saver. HWND is the owner
of this modal dialog.
-------------------------------------------------------------------- }


DECIMAL

{ --------------------------------------------------------------------
The timer interface is a little strange.  Under 95/98/NT, we can't
predict the actual rate of the WM_TIMER messages or the response
of the system to the SetTimer function. So, we set the rate to whatever
we want it to be and when we get the callback, we note how many we
should have gotten since the last one and _simulate_ this many calls
via the PostMessage function to ourself.
-------------------------------------------------------------------- }

WM_USER 100 + CONSTANT USER_TIMER

 0 VALUE TID
 0 VALUE TICKED

VARIABLE RATE   10 RATE !

:NONAME ( -- )
   GetTickCount DUP TICKED - RATE @ /MOD -ROT - TO TICKED
   100 MIN 0 ?DO HWND USER_TIMER 0 0 PostMessage DROP LOOP ;  4 CB: TPROC

: TIMER/ ( -- )
   TID IF  HWND 0 KillTimer DROP  THEN  ;

: /TIMER ( n -- )
   TIMER/  RATE ! GetTickCount TO TICKED
   HWND 0 RATE @ TPROC SetTimer TO TID ;

{ --------------------------------------------------------------------
API for user savers...
-------------------------------------------------------------------- }

0 CONSTANT 0RATE

DEFER SAVERRATE  ( -- zstr )        ' 0RATE IS SAVERRATE
DEFER DOSAVER    ( hwnd -- )        ' DROP IS DOSAVER
DEFER DOCONFIG   ( hwnd -- )        ' 0<> IS DOCONFIG

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

0 VALUE SCRMODE
0 VALUE DEBUGGING

0 ENUM SMDEBUG
  ENUM SMPREVIEW
  ENUM SMSAVER
  DROP

2VARIABLE INITPOS
2VARIABLE THISPOS

  0 VALUE TICKS
 40 VALUE NOTICABLE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: MOVED ( -- flag )
   THISPOS GetCursorPos DROP
   THISPOS 2@ INITPOS 2@ ( x y x y)   ROT - ABS  -ROT - ABS
   MAX NOTICABLE > ;

: SS-CREATE ( -- res )
   SAVERRATE ?DUP IF REG@ 1 MAX 10000 MIN ELSE 50 THEN  RATE !
   INITPOS GetCursorPos DROP  RATE @ /TIMER 0 DEFWINPROC ;

: SS-TIMER ( -- res )
   TICKS 1+ TO TICKS   HWND DOSAVER  0 ;

: SS-END ( -- res )
   SCRMODE SMSAVER = IF
      HWND WM_CLOSE 0 0 PostMessage DROP
   THEN 0 DEFWINPROC ;

: SS-MOVED ( -- res )
   SCRMODE SMSAVER = IF
      MOVED IF
         HWND WM_CLOSE 0 0 PostMessage DROP
      THEN
   THEN 0 DEFWINPROC ;

: SS-DEACTIVATE ( -- res )
   SCRMODE SMSAVER =
   DEBUGGING 0= AND
   WPARAM LOWORD WA_INACTIVE = AND IF
      HWND WM_CLOSE 0 0 PostMessage DROP
   THEN 0 DEFWINPROC ;

: SS-SYSCOMMAND ( -- res )
   SCRMODE SMSAVER = IF
      WPARAM SC_SCREENSAVE = IF
         0 EXIT THEN
      WPARAM SC_CLOSE =  DEBUGGING 0= AND IF
         0 EXIT THEN
   THEN
   0 DEFWINPROC ;

: SS-CLOSE ( -- res )
   SCRMODE SMSAVER = IF
      HWND DestroyWindow DROP 0 EXIT
   THEN 0 DEFWINPROC ;

: SS-DESTROY ( -- res )
   TIMER/  DEBUGGING ?EXIT
   0 PostQuitMessage DROP  0 DEFWINPROC ;

: SS-CURSOR ( -- res )
   SCRMODE SMSAVER = IF
      DEBUGGING 0= IF
         0 SetCursor DROP 0 EXIT
      THEN
   THEN
   0 IDC_ARROW LoadCursor SetCursor DROP
   0 DEFWINPROC ;


[SWITCH SAVER-MESSAGES DEFWINPROC ( msg -- res )
   WM_DESTROY     RUNS SS-DESTROY
   WM_CLOSE       RUNS SS-CLOSE
   WM_SETCURSOR   RUNS SS-CURSOR
   WM_KEYDOWN     RUNS SS-END
   WM_SYSKEYDOWN  RUNS SS-END
   WM_LBUTTONDOWN RUNS SS-END
   WM_RBUTTONDOWN RUNS SS-END
   WM_MBUTTONDOWN RUNS SS-END
   WM_MOUSEMOVE   RUNS SS-MOVED
   WM_SYSCOMMAND  RUNS SS-SYSCOMMAND
   WM_CREATE      RUNS SS-CREATE
   WM_ACTIVATE    RUNS SS-DEACTIVATE
   WM_ACTIVATEAPP RUNS SS-DEACTIVATE
   WM_NCACTIVATE  RUNS SS-DEACTIVATE
   USER_TIMER     RUNS SS-TIMER
SWITCH]

:NONAME
   MSG LOWORD SAVER-MESSAGES ; 4 CB: SAVER-WNDPROC

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CREATE SAVER-CLASS   ,Z" SfScrClass"
CREATE SAVER-TITLE1  ,Z" Sf Screen Saver"
CREATE SAVER-TITLE2  ,Z" Sf SCR Preview"
CREATE SAVER-TITLE3  ,Z" Sf SCR Debug"

: /SAVER-CLASS ( -- atom )
      0 CS_HREDRAW OR
         CS_VREDRAW OR                  \ class style
      SAVER-WNDPROC                     \ wndproc
      0                                 \ class extra
      0                                 \ window extra
      HINST                             \ hinstance
      0                                 \ ICON
      0                                 \ CURSOR
      BLACK_BRUSH GetStockObject        \
      0                                 \ no menu
      SAVER-CLASS                       \ class name
   DefineClass DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: /PREVIEW ( hparent -- hwnd )   LOCALS| hparent |
   SMPREVIEW TO SCRMODE
   hparent PAD GetWindowRect DROP
   PAD @RECT ( x y cx cy) ROT - >R SWAP - >R
      0                                 \ extended style
      SAVER-CLASS                       \ window class name
      SAVER-TITLE2                      \ window caption
      WS_CHILD WS_VISIBLE OR            \ style
      0 0 2R> SWAP                      \ x y cx cy
      hparent                           \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: /REAL-WINDOW ( hparent -- hwnd )   DROP
   SMSAVER TO SCRMODE
   SM_CXSCREEN GetSystemMetrics >R
   SM_CYSCREEN GetSystemMetrics >R
      WS_EX_TOPMOST WS_EX_TOOLWINDOW OR \ extended style
      SAVER-CLASS                       \ window class name
      SAVER-TITLE1                      \ window caption
      WS_POPUP WS_VISIBLE OR            \ style
      0 0 2R>                           \ x y cx cy
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: /DEBUG-WINDOW ( hparent -- hwnd )   DROP
   SMDEBUG TO SCRMODE
   SM_CXSCREEN GetSystemMetrics 3 / >R
   SM_CYSCREEN GetSystemMetrics 3 / >R
      0                                 \ extended style
      SAVER-CLASS                       \ window class name
      SAVER-TITLE3                      \ window caption
      WS_OVERLAPPEDWINDOW WS_VISIBLE OR \ style
      0 0 2R>                           \ x y cx cy
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: /SAVER ( hparent -- hwnd )
   DEBUGGING IF /DEBUG-WINDOW ELSE /REAL-WINDOW THEN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: RUNSAVER ( hparent flag -- res )  \ true, preview
   0 TO DEBUGGING
   /SAVER-CLASS  IF /PREVIEW ELSE /SAVER THEN
   DUP -EXIT DROP DISPATCHER DROP ;

: BUGSAVER ( hparent flag -- res )  \ true, preview
   1 TO DEBUGGING
   /SAVER-CLASS  IF /PREVIEW ELSE /SAVER THEN
   DUP -EXIT DROP ;

{ --------------------------------------------------------------------
/c, /c ####, or no arguments at all - in response to any of these the
   saver should pop up its configuration dialog. If there are no
   Arguments then NULL should be used as the parent: this will end
   up happening if the user clicks on the saver in the Explorer.
   With /c as an argument, the dialog should use GetForegroundWindow()
   as its parent. With /c #### the saver should treat #### as the
   decimal representation of an HWND, and use this as its parent.

/s - this indicates that the saver should run itself as a
   full-screen saver.

/p ####, or /l #### - here the saver should treat the #### as the
   decimal representation of an HWND, should pop up a child
   window of this HWND, and should run in preview mode inside that window.

/a #### - this command-line argument is only ever used in '95 and Plus!
   The saver should pop up a password-configuration dialog as a
   child of ####.
-------------------------------------------------------------------- }

: FIXUP ( a n -- )
   2DUP [CHAR] - [CHAR] / REPLACE-CHAR
   [CHAR] : BL REPLACE-CHAR ;

: /PARAMETERS ( -- hwnd mode )
   CMDLINE UPCASE  CMDLINE FIXUP
   CMDLINE 1 ARGV ATOI
   CMDLINE 0 ARGV ( a n) [CHAR] / SKIP DROP C@ ;

: WINMAIN ( -- )
   0 TO HCON  /PARAMETERS CASE
      [CHAR] P OF 1 RUNSAVER ENDOF
      [CHAR] L OF 1 RUNSAVER ENDOF
      [CHAR] S OF 0 RUNSAVER ENDOF
      [CHAR] D OF 0 BUGSAVER ENDOF
           DUP OF   DOCONFIG ENDOF
   ENDCASE
   0 ExitProcess ;

' WINMAIN 'MAIN !

{ --------------------------------------------------------------------
SHOW    Run the saver full-screen.
TEST    Run the saver in debug mode, 1/4 screen.
SETUP   Run the saver configuration dialog.
-------------------------------------------------------------------- }

: SHOW    HWND 0 RUNSAVER ;
: TEST    HWND 0 BUGSAVER ;
: SETUP   HWND DOCONFIG ;



