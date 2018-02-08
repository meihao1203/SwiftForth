{ ====================================================================
Notepad support

Copyright 2001  FORTH, Inc.
==================================================================== }

?( Notepad support)

PACKAGE FILE-VIEWER

THROW#
   S" Failed to start NOTEPAD" >THROW ENUM IOR_NOTEPADSTART
   S" Input did not go idle"   >THROW ENUM IOR_NOIDLE
TO THROW#

{ --------------------------------------------------------------------
After starting NOTEPAD, we have to find it. We search for it with
the EnumWindows function, looking at all top level windows for
a title containing NOTEPAD and the name minus path information of
the file we were interested in editing.

The buffer passed to NOTEPAD-LOCATOR in MSG (the second parameter
in the callback) is | cell | zstr(250) | .  The handle of the
notepad is returned in the cell, and the filename to match is
sent in the zstr(250).  We also assume (because we understand
notepad) that the only child of the window is the actual edit
control, which is where we must send commands to anyway!

After creating the process for notepad, we wait for the
input idle signal -- this indicates that we can access the
application now.

To go to a particular line of the file, we can simply use the
EM_LINEINDEX function to find the character offset then set the
selection to that position. This leaves the cursor on the bottom
line of the screen most times. So, we first position the cursor
to the end of file, then reposition it to the proper line. This
makes a much prettier display.

NOTEPAD-EDIT-FILE starts notepad.exe editing the specified file
   and positions the cursor at the beginning of the given line.
-------------------------------------------------------------------- }

:NONAME ( hwnd zname -- flag )  \ return -1 if continue, 0 if exit
   HWND PAD 100 GetWindowText DROP
   PAD ZCOUNT S" NOTEPAD" SEARCH(NC) NIP NIP  0=  DUP ?EXIT  DROP
   PAD ZCOUNT MSG CELL+ ZCOUNT SEARCH(NC) NIP NIP ( true if found)
   IF HWND MSG ! THEN  MSG @ ;

2 CB: NOTEPAD-LOCATOR

: FIND-NOTEPAD ( addr len -- handle )
   R-BUF  R@ OFF  -PATH R@ CELL+ ZPLACE
   NOTEPAD-LOCATOR R@ EnumWindows DROP
   R> @ GW_CHILD GetWindow ;

: START-NOTEPAD ( addr len -- )
   R-BUF  S" NOTEPAD.EXE " R@ ZPLACE  ( addr len) R@ ZAPPEND
   R> >PROCESS DUP 0= IOR_NOTEPADSTART ?THROW
   2000 WaitForInputIdle 0<> IOR_NOIDLE ?THROW ;

: NOTEPAD-GOTO-LINE ( line handle -- )
   ?DUP IF  SWAP 1- 0 MAX >R
      DUP EM_GETLINECOUNT 0 0 SendMessage 1- >R
      DUP EM_LINEINDEX R> 0 SendMessage >R
      DUP EM_SETSEL R> DUP SendMessage DROP
      DUP EM_SCROLLCARET 0 0 SendMessage DROP
      DUP EM_LINEINDEX R> 0 SendMessage >R
      DUP EM_SETSEL R> DUP SendMessage DROP
          EM_SCROLLCARET 0 0 SendMessage
   THEN DROP ;

: NOTEPAD-EDIT ( line addr len -- )
   ?DUP IF
      2DUP FIND-NOTEPAD 0= IF
         2DUP START-NOTEPAD
      THEN FIND-NOTEPAD NOTEPAD-GOTO-LINE
   ELSE 2DROP THEN ;

PUBLIC

VARIABLE USE-NOTEPAD

CONFIG: USENOTEPAD ( -- addr len )   USE-NOTEPAD CELL ;

END-PACKAGE
