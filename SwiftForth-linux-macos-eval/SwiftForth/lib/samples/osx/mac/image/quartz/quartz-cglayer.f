{ ====================================================================
Quartz Core Graphics Layers

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
Functions for CoreGraphic Layers are defined here.
Last: 2 April 2012 09:08:00 CEST  -rt
==================================================================== }

{ --------------------------------------------------------------------
More to add...
-------------------------------------------------------------------- }

/FORTH
DECIMAL

FUNCTION: CGLayerCreateWithContext ( CGContext sfloat:width sfloat:height NULL -- CGLayer )
FUNCTION: CGLayerGetContext ( CGLayer -- CGContext )
FUNCTION: CGContextDrawLayerInRect ( CGContext sfoat:x sfloat:y sfloat:width sfloat:height CGLayer -- ret )
FUNCTION: CGLayerRetain ( cglayer -- cglayer )
FUNCTION: CGLayerRelease ( cglayer -- ret )

\ VARIABLE CGLayer

cr .( CoreGraphics layering loaded)

\\ ( eof )