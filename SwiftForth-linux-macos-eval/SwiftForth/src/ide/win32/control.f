{ ====================================================================
control.f
A very reduced object-windows programming paradigm

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

{ --------------------------------------------------------------------
The basis for an object window package is the object callback.
We deal with this in XFC with a single callback. All XFC window
objects use the same callback; they differ only in which message
dispatcher is used.

The first message we can get our paws on is WM_NCCREATE. When we
see this message, we set the handle value in the object. So, how
do we know what the address of the object is? It is given in the
first parameter of the "creation parameters" array generated when
the createwindowex function was called. Since the user might want
his own value here, we have packed both in a structure. After using
the first, we replace it with the user's and dispatch a WM_NCCREATE
message to the object. Clever. The address of the object is stored
in a window property associated with the window's handle.

The callback assumes that the first cell of the object is reserved
for the window handle. Never, ever, disappoint this expectation!

After the initial message is received, each message is dispatched
as a CLASS-MESSAGE to the object whose address is contained in the
named window property. Any unknown message (i.e., not found in
the ANONYMOUS member list) is passed intact to DEFWINPROC.

***** this could be optimized by collapsing the entire forth context
here and using the values on the windows call parameter list.

***** this should probably trap the WM_NCDESTROY message and punt
at that point...
-------------------------------------------------------------------- }

PACKAGE OOP

PUBLIC

: DEFWINPROC ( -- res )
   HWND MSG WPARAM LPARAM DefWindowProc ;

HERE CONSTANT WINDOW-OBJECT-TAG

CODE CALLBACK-BINDING ( object 'member -- )
   12 # EBX ADD  0 [EBP] EAX MOV
   8 [EAX] EAX MOV  EAX 'THIS [U] MOV
   -4 [EBX] EAX MOV  EDI EAX ADD  EAX JMP
   RET END-CODE

: CLASS-MESSAGE ( object member-id -- res )
   OVER CELL+ @ WINDOW-OBJECT-TAG = IF
      OVER 2 CELLS + @  >ANONYMOUS BELONGS? IF
         CALLBACK-BINDING EXIT
   THEN THEN
   2DROP DEFWINPROC ;

CREATE SFTAG   ,Z" SFOBJECT"

:NONAME ( -- res )
   BEGIN
      HWND SFTAG GetProp DUP IF
         MSG LOWORD CLASS-MESSAGE EXIT
      THEN DROP
      MSG WM_NCCREATE = WHILE
         HWND LPARAM @ @ !
         HWND SFTAG LPARAM @ @ SetProp DROP
         LPARAM @ CELL+ @  LPARAM @ !
   REPEAT   DROP DEFWINPROC ; ( xt) 4 CB: CLASS-CALLBACK

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

: DERIVED-CLASS-MESSAGE ( object member-id -- res )
   OVER CELL+ @ WINDOW-OBJECT-TAG = IF
      OVER 2 CELLS + @  >ANONYMOUS BELONGS? IF
         CALLBACK-BINDING EXIT
      THEN ( else) DROP
      3 CELLS + @ HWND MSG WPARAM LPARAM CallWindowProc EXIT
   THEN 2DROP DEFWINPROC ;

:NONAME ( -- res )
   HWND SFTAG GetProp DUP IF
       MSG LOWORD DERIVED-CLASS-MESSAGE EXIT
   THEN ( else) DROP DEFWINPROC ; ( xt) 4 CB: DERIVED-CLASS-CALLBACK

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

VARIABLE DLG-OBJECT

: SYNC-NCCREATE ( -- )
   BEGIN
      [C  DLG-OBJECT @  WHILE  C]  PAUSE
   REPEAT  SELF DLG-OBJECT !  C] ;

: DEFDIALOGPROC ( -- )
   HWND MSG WPARAM LPARAM DefDlgProc ;

: SUPERCLASS-DLGMESSAGE ( object member-id -- res )
   OVER CELL+ @ WINDOW-OBJECT-TAG = IF
      OVER 2 CELLS + @  >ANONYMOUS3 BELONGS? IF
         CALLBACK-BINDING DUP -EXIT DROP
   THEN THEN
   2DROP DEFDIALOGPROC ;

: CLASS-DLGMESSAGE ( object member-id -- res )
   OVER CELL+ @ WINDOW-OBJECT-TAG = IF
      OVER 2 CELLS + @  >ANONYMOUS BELONGS? IF
         CALLBACK-BINDING EXIT
   THEN THEN
   2DROP 0 ;

:NONAME ( -- res )   BEGIN
      HWND SFTAG GetProp DUP IF
         MSG LOWORD SUPERCLASS-DLGMESSAGE EXIT
      THEN DROP
      MSG WM_NCCREATE = WHILE
         [C  DLG-OBJECT @  0 DLG-OBJECT !  C]
         HWND OVER !  HWND SFTAG ROT SetProp DROP
   REPEAT   DROP DEFDIALOGPROC ; ( xt) 4 CB: SUPERCLASS-DLG-CALLBACK

:NONAME ( -- res )
   HWND SFTAG GetProp DUP IF
       MSG LOWORD CLASS-DLGMESSAGE EXIT
   THEN ( else) DROP 0  ; ( xt) 4 CB: CLASS-DLG-CALLBACK


END-PACKAGE

