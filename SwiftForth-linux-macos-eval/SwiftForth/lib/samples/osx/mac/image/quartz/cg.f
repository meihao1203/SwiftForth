{ ====================================================================
Quartz 2D

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
Load file for CoreGraphic stuff, aka Quartz 2D
Last: 13 September 2017 at 20:54:01 GMT+2  -rt
==================================================================== }

{ --------------------------------------------------------------------
The CoreGraphic frameworks, contains among others the Quartz 2D drawing
stuff: drawing context, processing modes, drawing in layers etc.
Here the files are loaded, to create a MacForth like drawing API based
on Quartz rather than QuickDraw, which is deprecated.
-------------------------------------------------------------------- }

CR .( CoreGraphic stuff loading ...)

PUSHPATH
MAC

LACKING CFRelease INCLUDE system/corefoundation.f

LACKING CG4! INCLUDE image/quartz/quartz-utils.f

INCLUDE image/quartz/quartz-cgcontext.f
INCLUDE image/quartz/quartz-cgblendmode.f
INCLUDE image/quartz/quartz-cgdrawing.f
INCLUDE image/quartz/quartz-atf.f
INCLUDE image/quartz/quartz-cgimage.f
INCLUDE image/quartz/quartz-cglayer.f

POPPATH

\\ ( eof )