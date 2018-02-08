{ ====================================================================
Tetris load file

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL TETRIS The game of Tetris implemented in SwiftForth

[UNDEFINED] PROGRAM [IF]

CR
.( This demo is not available for the SwiftForth Evaluation version)
CR

-1 THROW

[THEN]

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CD %SwiftForth\lib\samples\win32\tetris
include guitetris

-1 THRESHOLD

PROGRAM Tetris.exe

CR
CR .( The program was saved as Tetris.exe )
CR
CR .( Press <escape> to exit SwiftForth...)
KEY 27 = [IF] BYE [THEN]
CR
