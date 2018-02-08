{ ====================================================================
Window shell access

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( ... Window shell access)

{ --------------------------------------------------------------------
CreateProcess

This is the better way to start an exernal process (and the only way if
you want to wait for that process to complete).

>PROCESS takes an executable command as a zstr and starts it. The value
returned is the process handle. This is not a window handle.  Returns 0
instead of a handle if the call to CreateProcess failed.

>PROCESS-WAIT calls >PROCESS and waits for that process to complete
before returning.  Aborts on failure.  Stores the exit code of the
process in ExitCodeProcess.
-------------------------------------------------------------------- }

FUNCTION: GetExitCodeProcess ( handle addr -- bool )

: >PROCESS ( zcmd -- handle )   R-BUF  R@ 256 ERASE
   0 SWAP 0 0 0 0 0 0 R@ 4 CELLS + R@ CreateProcess IF
   R> @  ELSE  R> DROP 0  THEN ;

VARIABLE ExitCodeProcess

: >PROCESS-WAIT ( zcmd -- )   >PROCESS
   DUP 0= ABORT" Can't execute command string"
   DUP INFINITE WaitForSingleObject DROP
   DUP ExitCodeProcess -1 OVER !
   GetExitCodeProcess DROP  CloseHandle DROP ;

{ --------------------------------------------------------------------
ShellExecute

>SHELL assumes that the first non-blank-containing string is the name of
a program that windows can "run" and that the rest of the string is the
command line to pass to it
-------------------------------------------------------------------- }

PACKAGE SHELL-TOOLS

VARIABLE SHELLERR

PUBLIC

: >SHELL ( addr len -- )   512 R-ALLOC  >R
   BL SKIP  2DUP BL SCAN  2SWAP  THIRD -
   ( a n a n)  R@ ZPLACE  R@ 256 +  ZPLACE
   HWND 0 R> DUP 256 + 0 SW_NORMAL ShellExecute SHELLERR ! ;

AKA >SHELL RUNEXE

END-PACKAGE

: RESTART ( -- )
   POPPATH-ALL
   GetCommandLine ZCOUNT >SHELL
   BYE ;
