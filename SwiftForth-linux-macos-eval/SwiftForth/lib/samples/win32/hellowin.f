{ ====================================================================
Hello Windows! Sample

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL HELLOWIN Standalone windows application -- Displays and speaks "Hello, Windows!"

{ --------------------------------------------------------------------
From HELLOWIN.C -- Displays "Hello, Windows 95!" in client area
(c) Charles Petzold, 1996

Taken from Chapter 2, "Programming Windows 95"

This is a simple example of a windows program which does not need or
create a console window.  The file is rather large for a "hello world"
program, but it is self-contained (except for the HELLOWIN.WAV file)
and requires no run-time libraries such as Visual Basic does.
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS DECIMAL

{ --------------------------------------------------------------------
AppName is an ASCIIZ string for the name of the class.

HELLO-MESSAGES handles the callback messages for the HelloWin class.
It is through these messages that windows executes a program.  The
minimum required is that we handle the WM_DESTROY message; we will
include more later.

Note also that the switch is required to return a result. Every entry
in the switch must return a result.  Also, if we haven't defined a
switch for a given message, the default action is to call the windows
default message handler DEFWINPROC.

WNDPROC is the named callback for the class. Windows uses this as the
entry point for our message handler.  On entry, four frame values
(like user variables, but self-fetching) HWND MSG WPARAM and LPARAM
are set according to the rules windows uses in formatting messages.
Their content is beyond the scope of this documentation.
-------------------------------------------------------------------- }

CREATE AppName ,Z" HelloWin"

[SWITCH HELLO-MESSAGES DEFWINPROC ( -- res )
   WM_DESTROY RUN:  0 PostQuitMessage DROP  0 ;
SWITCH]

:NONAME  MSG LOWORD HELLO-MESSAGES ; 4 CB: WNDPROC

{ --------------------------------------------------------------------
MYCLASS builds a WNDCLASS structure which defines the overall
   characteristics of the windows we want to define.

MYWINDOW creates an instance of the class named HelloWin with
   default size and position, no parent, no window, and belonging
   to SwiftForth executing image.
-------------------------------------------------------------------- }

: MYWINDOW ( -- hwnd )
      0                                 \ extended style
      AppName                           \ window class name
      Z" The Hello Program"             \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      CW_USEDEFAULT                     \ initial x position
      CW_USEDEFAULT                     \ y
      CW_USEDEFAULT                     \ x size
      CW_USEDEFAULT                     \ y
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

{ --------------------------------------------------------------------
DEMO opens the system DLL -s, creates the class and instantiates a
   window, then displays the window and enters the message loop.
   This loop continues until the window is closed.  Since the
   DISPATCHER simply runs until the window is closed, this may be
   used interactively in Forth without the side effect of terminating
   the Forth window when the application is closed. I.e., you may
   run and debug the application interactively.

WINMAIN calls DEMO then exits the process. The call to ExitProcess
   renders this less useful under the interactive environment, since
   calling it terminates the entire running application (SwiftForth).

The vector 'MAIN is the earliest user entry point in the startup
   code of SwiftForth; it is called before any dll's have been linked
   and before any window has been created. If you hook this, be
   careful to do all your own initialization and not to depend on
   the SwiftForth command window being open.
-------------------------------------------------------------------- }

: DEMO ( -- )
   AppName WNDPROC DefaultClass DROP
   MYWINDOW DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP
   DISPATCHER DROP ;

: WINMAIN ( -- )
   DEMO 0 ExitProcess ;

' WINMAIN 'MAIN !

{ --------------------------------------------------------------------
WINMM.DLL is required for the

PlaySound function, which the application uses in

GREETING displays a message in the current window and plays a
   sound file.

PAINT updates the window if it has been obscured and made visible
   again.

HELLO-MESSAGES is extended here to handle WM_CREATE and WM_PAINT .
-------------------------------------------------------------------- }

LIBRARY WINMM

FUNCTION: PlaySound ( pszSound hmod fdwSound -- b )

CREATE HelloWinPath   INCLUDING HERE OVER 1+ ALLOT ZPLACE

: HelloWin ( -- z-addr)   HelloWinPath ZCOUNT  -NAME
   SWAP DUP >R + 0 SWAP C!  S" \HelloWin.wav" R@ ZAPPEND
   R> ;

: GREETING ( -- )
   S" HelloWin.wav" FILE-STATUS NIP IF  HelloWin
   ELSE  Z" HelloWin.wav"  THEN
   0 SND_FILENAME SND_ASYNC OR PlaySound DROP
   HWND GetDC >R
   ANSI_FIXED_FONT GetStockObject R@ SWAP SelectObject DROP
   HWND R> ReleaseDC DROP ;

: PAINT ( -- )
   HWND PAD BeginPaint ( hdc)
   HWND HERE GetClientRect DROP
   ( hdc)  S" Hello, Windows!" HERE
      DT_SINGLELINE DT_CENTER OR DT_VCENTER OR DrawText DROP
   HWND PAD EndPaint DROP ;

[+SWITCH HELLO-MESSAGES ( -- res )
   WM_CREATE  RUN:  GREETING 0 ;
   WM_PAINT   RUN:  PAINT 0 ;
SWITCH]

{ --------------------------------------------------------------------
Finish up
-------------------------------------------------------------------- }

CR
CR .( Type DEMO to run the program.)
CR

[DEFINED] PROGRAM [IF]

CR .( You may also type  PROGRAM-SEALED FOO.EXE  to save a turnkey executable)
CR .( of this demonstration named FOO.EXE.)
CR

[THEN]
