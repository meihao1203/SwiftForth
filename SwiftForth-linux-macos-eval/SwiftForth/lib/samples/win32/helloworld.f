{ ====================================================================
Template based HelloWorld

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL HELLOWORLD The simplest Windows application using the WINAPP template

REQUIRES WINAPP

: HELLO-PAINT ( -- res )
   HWND PAD GetClientRect DROP
   HWND HERE BeginPaint ( hdc)
   ( hdc) Z" Hello, World!" -1 PAD DT_SINGLELINE DT_CENTER OR DT_VCENTER OR
      DrawText DROP
   HWND HERE EndPaint DROP 0 ;

[+SWITCH AppMessages
  WM_PAINT RUNS HELLO-PAINT
SWITCH]

: GO ( -- )   AppStart DROP ;

CR
CR .( Type GO to run the demonstration)
CR
