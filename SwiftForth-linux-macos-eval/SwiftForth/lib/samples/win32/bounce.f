{ ====================================================================
Bouncing Ball Program

Copyright (C) 2001 FORTH, Inc.

Adapted from BOUNCE.C -- Bouncing Ball Program
  (c) Charles Petzold, 1996
==================================================================== }

OPTIONAL BOUNCE Bouncing ball demo, from Petzold

{ --------------------------------------------------------------------
This sample demonstrates the use of the multi-media timer functions as
well as bitblt and very simple animation.
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS

LIBRARY GDI32

FUNCTION: Rectangle ( hdc nLeftRect nTopRect nRightRect nBottomRect -- b )
FUNCTION: Ellipse ( hdc nLeftRect nTopRect nRightRect nBottomRect -- b )
FUNCTION: CreateHatchBrush ( fnStyle clrref -- h )

LIBRARY WINMM

FUNCTION: timeKillEvent ( uTimerID -- res )
FUNCTION: timeBeginPeriod ( uPeriod -- res )
FUNCTION: timeEndPeriod ( uPeriod -- res )
FUNCTION: timeSetEvent ( uDelay uResolution lpTimeProc dwUser fuEvent -- res )

WM_USER 100 + CONSTANT WM_BOUNCE

20 CONSTANT SPEED

0 VALUE hBounce
0 VALUE timeID
0 VALUE cxClient
0 VALUE cyClient
0 VALUE xPixel
0 VALUE yPixel
0 VALUE xCenter
0 VALUE yCenter
0 VALUE iScale
0 VALUE cxRadius
0 VALUE cyRadius
0 VALUE cxMove
0 VALUE cyMove
0 VALUE cxTotal
0 VALUE cyTotal
0 VALUE hBitmap
0 VALUE hBrush
0 VALUE hdcMem

{ ------------------------------------------------------------------------

------------------------------------------------------------------------ }

: BOUNCE-MMTIMER ( -- res )
   hBounce WM_BOUNCE 0 0 PostMessage ;

' BOUNCE-MMTIMER 5 CB: &BOUNCE-TIMER

: BOUNCE-CREATE ( -- res )
   HWND GetDC ( hdc)
   DUP ASPECTX GetDeviceCaps TO xPixel
   DUP ASPECTY GetDeviceCaps TO yPixel
   HWND SWAP ReleaseDC DROP
   0 ;

: BOUNCE-SIZE ( -- res )
   LPARAM LOWORD  DUP TO cxClient  2/ TO xCenter
   LPARAM HIWORD  DUP TO cyClient  2/ TO yCenter
   cxClient xPixel *  cyClient yPixel *  MIN  16 / TO iScale
   iScale xPixel / TO cxRadius
   iScale yPixel / TO cyRadius
   cxRadius 2/ 1 MAX TO cxMove
   cyRadius 2/ 1 MAX TO cyMove
   cxRadius cxMove + 2* TO cxTotal
   cyRadius cyMove + 2* TO cyTotal
   hBitmap IF  hBitmap DeleteObject DROP  THEN
   HWND GetDC ( hdc) >R
   R@ CreateCompatibleDC TO hdcMem
   R@ cxTotal cyTotal CreateCompatibleBitmap TO hBitmap
   HWND R> ReleaseDC DROP
   hdcMem hBitmap SelectObject DROP
   hdcMem -1 -1 cxTotal 1+ cyTotal 1+ Rectangle DROP
   HS_DIAGCROSS 0 CreateHatchBrush TO hBrush
   hdcMem hBrush SelectObject DROP
   hdcMem $00ff00ff SetBkColor DROP
   hdcMem cxMove cyMove cxTotal cxMove - cyTotal cyMove - Ellipse DROP
   hdcMem DeleteDC DROP
   hBrush DeleteObject DROP

   hBounce PAD GetClientRect drop
   hBounce GetDC PAD
   WHITE $1000000 or CreateSolidBrush dup>r
   FillRect drop
   r> DeleteObject drop
   0 ;

: BOUNCE-DEFAULT ( n -- res )
   DROP HWND MSG WPARAM LPARAM DefWindowProc ;

: BOUNCE-TIMER ( -- res )
   hBitmap 0= IF 0 BOUNCE-DEFAULT EXIT THEN
   HWND GetDC >R
   R@ CreateCompatibleDC TO hdcMem
   hdcMem hBitmap SelectObject DROP
   R@ xCenter cxTotal 2/ -
       yCenter cyTotal 2/ -  cxTotal cyTotal
       hdcMem 0 0 SRCCOPY BitBlt DROP
   HWND R> ReleaseDC DROP
   hdcMem DeleteDC DROP
   cxMove +TO xCenter
   cyMove +TO yCenter
   xCenter cxRadius + cxClient >=  xCenter cxRadius - 0<  OR IF
      cxMove NEGATE TO cxMove
   THEN
   yCenter cyRadius + cyClient >=  yCenter cyRadius - 0<  OR IF
      cyMove NEGATE TO cyMove
   THEN
   0 ;

: BOUNCE-CLOSE ( -- res )
   hBitmap IF  hBitmap DeleteObject DROP  THEN
   timeID timeKillEvent DROP  0 TO timeID
   SPEED timeEndPeriod DROP
   hBounce DestroyWindow DROP
   0 TO hBounce
   0 ;

: BOUNCE-DESTROY ( -- res )
   0 'MAIN @ ?EXIT  PostQuitMessage ;

: BOUNCE-TURN ( -- res )
   WPARAM CASE
      VK_UP     OF  cxMove ABS 1+ 16 MIN DUP TO cxMove TO cyMove  ENDOF
      VK_DOWN   OF  cxMove ABS 1-  1 MAX DUP TO cxMove TO cyMove  ENDOF
   ENDCASE 0 ;


{ ------------------------------------------------------------------------

------------------------------------------------------------------------ }

[SWITCH BOUNCE-MESSAGES BOUNCE-DEFAULT
   WM_CREATE      RUNS   BOUNCE-CREATE
   WM_BOUNCE      RUNS   BOUNCE-TIMER
   WM_DESTROY     RUNS   BOUNCE-DESTROY
   WM_SIZE        RUNS   BOUNCE-SIZE
   WM_KEYDOWN     RUNS   BOUNCE-TURN
SWITCH]

:NONAME ( -- res )   MSG $FFFF AND BOUNCE-MESSAGES ;  4 CB: BOUNCE-WNDPROC

0 VALUE hClass

: AppName   Z" Bounce" ;

: CREATE-BOUNCE-WINDOW  ( -- hwindow )
   0                       \ exended style
   AppName                 \ class name
   Z" Bouncing Ball"       \ window title
   WS_OVERLAPPEDWINDOW     \ window style
   CW_USEDEFAULT
   CW_USEDEFAULT
   CW_USEDEFAULT
   CW_USEDEFAULT
   0                       \ parent window
   0                       \ menu
   HINST                   \ instance handle
   0                       \ creation parameters
   CreateWindowEx ;

: BOUNCE ( -- )
   hBounce ABORT" Only one instance at a time, please!"
   AppName HINST UnregisterClass DROP
   AppName BOUNCE-WNDPROC DefaultClass TO hClass
   hClass 0= ABORT" Class is not registered"
   CREATE-BOUNCE-WINDOW  DUP 0= ABORT" create window failed"  TO hBounce
   SPEED timeBeginPeriod ABORT" Can't set timer"
   SPEED SPEED &BOUNCE-TIMER hBounce TIME_PERIODIC timeSetEvent TO timeID
   hBounce 1 ShowWindow DROP
   hBounce UpdateWindow DROP ;

{ ------------------------------------------------------------------------
Turnkey application

This snippet converts the bounce program into a standalone
application. It will run with no console window opened, and the Forth
interpreter basically turned off.  This feature is not available in
the Evaluation Version.
------------------------------------------------------------------------ }

[DEFINED] PROGRAM-SEALED [IF]

: BOUNCER ( -- )
   BOUNCE DISPATCHER DROP ;

: MAIN ( -- )   0 'MAIN !
   ['] BOUNCER CATCH DUP IF
      0 SWAP Z(.) Z" Bounce threw " 0 MessageBox DROP
   THEN 0 ExitProcess ;

' MAIN 'MAIN !

PROGRAM-SEALED bounce.exe

[THEN]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CR CR .( Type BOUNCE to start the bouncing ball demo.) CR CR
