{ ====================================================================
Simple "DOS box" style console window

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL DOSBOX A "DOS box" style console (non-GUI) window

/FORTH DECIMAL
PACKAGE DOS-BOX

LIBRARY KERNEL32

FUNCTION: AllocConsole ( -- b )
FUNCTION: FreeConsole ( -- b )
FUNCTION: GetStdHandle ( nStdHandle -- h )
FUNCTION: WriteConsole ( hConsoleOutput *lpBuffer nNumberOfCharsToWrite lpNumberOfCharsWritten lpReserved -- b )
FUNCTION: PeekConsoleInput ( hConsoleInput lpBuffer nLength lpNumberOfEventsRead -- b )
FUNCTION: ReadConsole ( hConsoleInput lpBuffer nNumberOfCharsToRead lpNumberOfCharsRead pInputControl -- b )
FUNCTION: SetConsoleMode ( hConsoleHandle dwMode -- b )
FUNCTION: GetConsoleMode ( hConsoleHandle lpMode -- b )
FUNCTION: SetConsoleScreenBufferSize ( hConsoleOutput dwSize -- b )

{ ------------------------------------------------------------------------
Windows Console Personality

The bug console is only created via allocconsole once. thereafter, the
invoke and revoke will simply do nothing. This behavior is controlled by
the values INH and OUTH -- non-zero means don't initialize again!

So, just in case the option is saved as a system component, they must
be initialized to zero in the onload chain
------------------------------------------------------------------------ }

: PDATA ( n "name" -- )
   CREATE CELLS , DOES> @ 'PERSONALITY @ + ;

4 PDATA INH
5 PDATA OUTH
6 PDATA C#

: KEY?(C) ( -- flag )
   7 CELLS R-ALLOC >R   R@ 7 CELLS ERASE
   INH @ R@ 1 OVER 6 CELLS + PeekConsoleInput DROP
   R@ H@ 1 =
   R> 7 CELLS + @ 0<> AND ;

: KEY(C) ( -- char )   0 >R
   0 SP@ 1 INH @ -ROT RP@ 0 ReadConsole DROP  R> DROP ;

: TYPE(C) ( addr n -- )   0 >R   DUP C# +!
   OUTH @ -ROT RP@ 0 WriteConsole DROP R> DROP ;

: EMIT(C) ( char -- )
   SP@ 1 TYPE(C) DROP ;

: CR(C) ( -- )
   13 EMIT(C) 10 EMIT(C) ;

: INVOKE(C) ( -- )
   INH @ 0=  OUTH @ 0=  OR IF
      AllocConsole DROP
      -11 ( STD_OUTPUT_HANDLE) GetStdHandle OUTH !
      -10 ( STD_INPUT_HANDLE) GetStdHandle INH !
      INH @ 0 SetConsoleMode DROP
      OUTH @ 80 1000 >H< OR SetConsoleScreenBufferSize DROP
      OUTH @ ENABLE_PROCESSED_OUTPUT SetConsoleMode DROP
   THEN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

CREATE DOS-CONSOLE
   7 CELLS ,            \ datasize
        18 ,            \ maxvector
         0 ,            \ PHANDLE
         0 ,            \ PREVIOUS
         0 ,            \ inh
         0 ,            \ outh
         0 ,            \ c#
   ' INVOKE(C) ,        \ INVOKE    ( -- )
   ' NOOP ,             \ REVOKE    ( -- )
   ' NOOP ,             \ /INPUT    ( -- )
   ' EMIT(C) ,          \ EMIT      ( char -- )
   ' TYPE(C) ,          \ TYPE      ( addr len -- )
   ' TYPE(C) ,          \ ?TYPE     ( addr len -- )
   ' CR(C) ,            \ CR        ( -- )
   ' NOOP ,             \ PAGE      ( -- )
   ' DROP ,             \ ATTRIBUTE ( n -- )
   ' KEY(C) ,           \ KEY       ( -- char )
   ' KEY?(C) ,          \ KEY?      ( -- flag )
   ' KEY(C) ,           \ EKEY      ( -- echar )
   ' KEY?(C) ,          \ EKEY?     ( -- flag )
   ' KEY(C) ,           \ AKEY      ( -- char )
   ' 2DROP ,            \ PUSHTEXT  ( addr len -- )
   ' 2DROP ,            \ AT-XY     ( x y -- )
   ' 2DUP ,             \ AT-XY?    ( -- x y )
   ' 2DUP ,             \ GET-SIZE  ( -- x y )

\ PRIVATE

: /DOS-CONSOLE ( -- )   DOS-CONSOLE 4 CELLS + 3 CELLS ERASE ;

:ONSYSLOAD ( -- )   /DOS-CONSOLE ;

END-PACKAGE

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS SPECIAL-RELEASE-TESTING [IF]

: TEST ( -- )
   CR CR ." This should be displayed in the dos console."
   CR ." Press any key to exit" KEY DROP ;

/DOS-CONSOLE
' TEST DOS-CONSOLE P-EXECUTE

BYE  [THEN]
