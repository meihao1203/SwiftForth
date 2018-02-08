OPTIONAL CCmdTarget The base class for the SFC message-map architecture.

{ ====================================================================
CCmdTarget is the base class for the SFC message-map architecture.

Copyright (c) 1972-1999, FORTH, Inc.

CCmdTarget is the base class for the Swift Foundation Class Library
message-map architecture. A message map routes commands or messages to
the member functions you write to handle them. (A command is a message
from a menu item, command button, or accelerator key.)

Requires: CObject

Exports: see MFC documentation

==================================================================== }

REQUIRES CObject

{ --------------------------------------------------------------------
CLASS-MESSAGE is a variation of SENDMSG particular to accepting a
   windows message. Note that it doesn't throw, but calls the
   default winproc if no message handler exists.

CLASS-CALLBACK is a generic callback for class-based windows. On the
   WM_NCCREATE message, it assumes the object address is in the
   first cell of the creation data and binds it to a window property.
   On all other messages, the property is retrieved and the message is
   dispatched to the object.
-------------------------------------------------------------------- }

CLASS CWaitCursor

   : Restore ( -- ) ;

   : Construct ( -- ) ;

   : Destroy ( -- ) ;

END-CLASS

CObject SUBCLASS CCmdTarget

PRIVATE

   CWaitCursor BUILDS wc

PUBLIC

\ Attributes

   : FromIDispatch ( lpDispatch -- CCmdTarget )   N/I ;

   : GetIDispatch ( bAddRef -- lpDispatch )   N/I ;

   : IsResultExpected ( -- )   FALSE ;

\ Operations
   : BeginWaitCursor ( -- )   wc Construct ;

   : EnableAutomation ( -- )   N/I ;

   : EndWaitCursor ( -- )   wc Destroy ;

   : RestoreWaitCursor ( -- )   wc Restore ;

\ Overridables

   DEFER: OnCmdMsg ( nID nCode pExtra pHandlerInfo -- flag )   N/I ;

   DEFER: OnFinalRelease ( -- ) ;

END-CLASS

PACKAGE OOP

PUBLIC

: CLASS-MESSAGE ( object member-id -- res )
   OVER 2 CELLS - @ OBJTAG = IF
      OVER CELL- @  >ANONYMOUS BELONGS? IF
         [DEFINED] BUGME [IF]
            [BUG  S"  ! " TYPE BUG]
         [THEN]
         LATE-BINDING EXIT
      THEN
   THEN 2DROP
         [DEFINED] BUGME [IF]
            [BUG  S"  ? " TYPE BUG]
         [THEN]
   DEFWINPROC ;

CREATE SFCTAG   ,Z" SFC0100"

:NONAME ( -- res )
   [DEFINED] BUGME [IF]
      [BUG  CR  MSG LOWORD WMTEXT COUNT TYPE  BUG]
   [THEN]
   BEGIN
      HWND SFCTAG GetProp DUP IF
         MSG LOWORD CLASS-MESSAGE EXIT
      THEN
      MSG WM_NCCREATE = WHILE
         HWND SFCTAG LPARAM @ @ SetProp DROP
         LPARAM @ CELL+ @  LPARAM @ !
   REPEAT   DROP DEFWINPROC ; ( xt) 4 CB: CLASS-CALLBACK


END-PACKAGE

