{ ====================================================================
CoreGraphic Blendmodes

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
The possible blendmodes when displaying images in Quartz.
Last: 24 March 2011 11:35:39 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
Many blendmodes are defined here as constants.

BLENDMODE -- a temporary storage for current blendmode. Used by some: 
SET.BLENDMODE -- set the CGContext's blend mode.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: CGContextSetBlendMode ( cgcontext blendmode -- ret )

32 CONSTANT blend
33 CONSTANT addpin
34 CONSTANT addOver
35 CONSTANT subPin
36 CONSTANT transparent
37 CONSTANT addMax
38 CONSTANT subOver
39 CONSTANT adMin
64 CONSTANT ditherCopy

\ CGBlendModes
0
ENUM kCGBlendModeNormal
ENUM kCGBlendModeMultiply
ENUM kCGBlendModeScreen
ENUM kCGBlendModeOverlay
ENUM kCGBlendModeDarken
ENUM kCGBlendModeLighten
ENUM kCGBlendModeColorDodge
ENUM kCGBlendModeColorBurn
ENUM kCGBlendModeSoftLight
ENUM kCGBlendModeHardLight
ENUM kCGBlendModeDifference
ENUM kCGBlendModeExclusion
ENUM kCGBlendModeHue
ENUM kCGBlendModeSaturation
ENUM kCGBlendModeColor
ENUM kCGBlendModeLuminosity
ENUM kCGBlendModeClear
ENUM kCGBlendModeCopy
ENUM kCGBlendModeSourceIn
ENUM kCGBlendModeSourceOut
ENUM kCGBlendModeSourceAtop
ENUM kCGBlendModeDestinationOver
ENUM kCGBlendModeDestinationIn
ENUM kCGBlendModeDestinationOut
ENUM kCGBlendModeDestinationAtop
ENUM kCGBlendModeXOR
ENUM kCGBlendModePlusDarker
ENUM kCGBlendModePlusLighter
CONSTANT #BLENDMODES

VARIABLE BLENDMODE kCGBlendModeNormal BLENDMODE !

: SET.BLENDMODE ( mode context -- )   SWAP DUP BLENDMODE ! CGContextSetBlendMode DROP ;

cr .( CGBlendmode loaded)

\\ ( eof )
