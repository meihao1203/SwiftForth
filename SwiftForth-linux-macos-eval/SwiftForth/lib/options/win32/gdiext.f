{ ====================================================================
GDI Extensions

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL GDIEXT Extensions to the Win32 GDI

LIBRARY GDI32

FUNCTION: CreatePen             ( style width color -- hpen )
FUNCTION: MoveToEx              ( hdc x y 'old -- bool )
FUNCTION: LineTo                ( hdc x y -- bool )
FUNCTION: GetCurrentObject      ( dc obj -- hobj )
FUNCTION: SetTextAlign          ( dc align -- old )

: DrawColorLine ( dc x y x y rgb -- bool )
   LOCALS| rgb y2 x2 y x dc |
   dc PS_SOLID 1 rgb CreatePen SelectObject >R
   dc x y 0 MoveToEx DROP  dc x2 y2 LineTo
   dc R> SelectObject DeleteObject DROP ;

: VerticalTextOut ( dc x y addr len -- bool )
   0 0 LOCALS| hf vf l a y x dc |
   [OBJECTS LOGICAL-FONT MAKES LF OBJECTS]
   dc OBJ_FONT GetCurrentObject TO hf
   LF Height @ 2* LF Height !
   hf LOGICAL-FONT SIZEOF LF ADDR GetObject DROP
   2700 LF Escapement !  2700 LF Orientation !  0 LF FaceName !
   LF ADDR CreateFontIndirect TO vf
   dc vf SelectObject >R
   dc x y a l TextOut
   dc R> SelectObject DeleteObject DROP ;


{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

HWND GetDC VALUE DC
DC 0 0 400 100 $FF0000 DrawColorLine DROP
DC 400 100 S" TESTING" VerticalTextOut DROP

KEY DROP BYE  [THEN]
