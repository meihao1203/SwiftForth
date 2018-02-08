{ ====================================================================
bundle utillities

Copyright (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
Application bundling utils load file.
Implements TURNKEY.
Last: 7 Nov 2016 00:36:37 CET  -rt
==================================================================== }

PUSHPATH
MAC

INCLUDE utils/folderops.f
INCLUDE bundling/app-specifics.f
INCLUDE bundling/resources.f
INCLUDE bundling/turnkey.f

POPPATH

\\ ( eof )