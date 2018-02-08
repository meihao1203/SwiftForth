{ ====================================================================
SwiftForth Windows Application Template

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL WINAPP A skeletal Windows application to build from. The source contains deferred words that you vector to suit your application.

{ --------------------------------------------------------------------
All defers contain reasonable defaults and may be used (at least
initially) as defined.

Defers for the application to set:

ClassName ( -- zstr )
AppTitle ( -- zstr )
MakeStatus ( -- )
SizeStatus ( -- )
MakeToolbar ( -- )
SizeToolbar ( -- )
MakeMenu ( -- )
CreateMore ( -- )
AboutApp ( -- )

Exports

AppMessages ( msg -- res )      a switch to process windows messages
AppCommands ( cmd -- )          a switch to process WM_COMMAND messages
AppStart ( -- hwnd )
M_USED ( -- n )                 integer VALUE to begin menu item definitions
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
The base class
-------------------------------------------------------------------- }

0 VALUE hApp

DEFER ClassName  :NONAME   Z" SwiftApp" ;   IS ClassName
DEFER AppTitle   :NONAME   Z" SwiftApp" ;   IS AppTitle

: ENDAPP ( -- res )
   'MAIN @ [ HERE CODE> ] LITERAL < IF ( not an application yet)
      0 TO hApp
   ELSE ( is an application)
      0 PostQuitMessage DROP
   THEN 0 ;

[SWITCH AppMessages DEFWINPROC ( msg -- res )
   WM_DESTROY RUNS ENDAPP
SWITCH]

:NONAME ( -- res )
   MSG LOWORD AppMessages ; 4 CB: APP-WNDPROC

: /APP-CLASS ( -- )
      0  CS_OWNDC   OR
         CS_HREDRAW OR
         CS_VREDRAW OR                  \ class style
      APP-WNDPROC                       \ wndproc
      0                                 \ class extra
      0                                 \ window extra
      HINST                             \ hinstance
      HINST 101 LoadIcon
      NULL IDC_ARROW LoadCursor         \
      WHITE_BRUSH GetStockObject        \
      0                                 \ no menu
      ClassName                         \ class name
   DefineClass DROP ;

: /APP-WINDOW ( -- hwnd )
   0 TO hApp
      0                                 \ extended style
      ClassName                         \ window class name
      AppTitle                          \ window caption
      WS_OVERLAPPEDWINDOW
      40 40 500 350                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx DUP -EXIT
   DUP TO hApp
   DUP SW_SHOW ShowWindow DROP
   DUP UpdateWindow DROP ;

:PRUNE   ?PRUNE -EXIT
   hApp IF hApp WM_CLOSE 0 0 SendMessage DROP THEN
   ClassName HINST UnregisterClass DROP ;

: AppStart ( -- hwnd )
   hApp ?EXIT /APP-CLASS /APP-WINDOW ;

{ --------------------------------------------------------------------
Define a menu with the button classes, exit, and about
-------------------------------------------------------------------- }

100 ENUM M_EXIT
    ENUM M_ABOUT
VALUE M_USED

MENU APP-MENU

   POPUP "&File"
      M_EXIT   MENUITEM "E&xit"
   END-POPUP

   POPUP "&Help"
      M_ABOUT  MENUITEM "&About"
   END-POPUP

END-MENU

{ --------------------------------------------------------------------
ABOUT box
-------------------------------------------------------------------- }

: APP-ABOUT ( -- )
   HWND Z" SwiftForth Application Template"  Z" About" MB_OK MessageBox DROP ;

: MAKE-MENU ( -- )
   HWND APP-MENU LoadMenuIndirect SetMenu DROP ;

{ --------------------------------------------------------------------
DEFERS
-------------------------------------------------------------------- }

DEFER MakeStatus   ' NOOP      IS MakeStatus
DEFER SizeStatus   ' NOOP      IS SizeStatus
DEFER MakeToolbar  ' NOOP      IS MakeToolbar
DEFER SizeToolbar  ' NOOP      IS SizeToolbar
DEFER MakeMenu     ' MAKE-MENU IS MakeMenu
DEFER CreateMore   ' NOOP      IS CreateMore
DEFER AboutApp     ' APP-ABOUT IS AboutApp

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: APP-EXIT ( -- )
   HWND WM_CLOSE 0 0 PostMessage DROP ;

[SWITCH AppCommands DROP ( cmd -- )
   M_EXIT   RUNS APP-EXIT
   M_ABOUT  RUNS AboutApp
SWITCH]

[+SWITCH AppMessages ( -- res )
   WM_SIZE    RUN: SizeStatus SizeToolbar 0 ;
   WM_COMMAND RUN: WPARAM LOWORD AppCommands 0 ;
   WM_CREATE  RUN: MakeMenu MakeStatus MakeToolbar CreateMore 0 ;
   WM_CLOSE   RUN: HWND GetMenu DestroyMenu DROP
                   HWND DestroyWindow DROP 0 ;
SWITCH]

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

AppStart

KEY DROP BYE  [THEN]
