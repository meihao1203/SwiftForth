{ ====================================================================
Miscellaneous graphic and window tools

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL GDITOOLS Miscellaneous graphic and window tools

{ --------------------------------------------------------------------
Graphics Device Interface (GDI)

The GDI provides a set of generic graphics functionsthat can be used to
draw to the screen, to memory, or even to printers.

The GDI revolves around an object called the Device Context (DC),
represented by the data type HDC (Handle to Device Context). An HDC is
a handle to something you can draw on; it can represent the entire
screen, an entire window, the client area of a window, a bitmap stored
in memory, or a printer. You don't need to know which one it refers
to, which is especially handy for writing custom drawing functions .

An HDC, like most GDI objects, is opaque; you can't access its data
directly, but you can pass it to various GDI functions that will
operate on it, either to draw something, get information about it, or
change the object in some way.
-------------------------------------------------------------------- }

LIBRARY GDI32

FUNCTION: Polygon ( hdc *lpPoints nCount -- b )
FUNCTION: RoundRect ( hdc nLeftRect nTopRect nRightRect nBottomRect nWidth nHeight -- b )
FUNCTION: Rectangle ( hdc nLeftRect nTopRect nRightRect nBottomRect -- b )
FUNCTION: Ellipse ( hdc nLeftRect nTopRect nRightRect nBottomRect -- b )
FUNCTION: LineTo ( hdc nXEnd nYEnd -- b )
FUNCTION: MoveToEx ( hdc X Y lpPoint -- b )
FUNCTION: DrawFocusRect ( hDC *lprc -- b )

{ --------------------------------------------------------------------
Vector operators
-------------------------------------------------------------------- }

: V+ ( v v -- v )   ROT + >R + R> ;
: V- ( v v -- v )   ROT SWAP - >R - R> ;
: V! ( v a -- )   >R SWAP R> 2! ;
: V@ ( a -- v )   2@ SWAP ;

{ --------------------------------------------------------------------
Point manipulation routines
-------------------------------------------------------------------- }

: MID ( n0 n1 -- )   OVER - 2/ + ;

: CENTER ( x y x y -- x y )
   ROT SWAP MID >R MID R> ;

: CENTERED ( x y x y -- cx cy x y x y )
   2OVER 2OVER  CENTER  2ROT 2ROT ;

{ --------------------------------------------------------------------
Write a string centered in a rectangle
-------------------------------------------------------------------- }

: TEXT-HEIGHT ( hdc a n rect -- height )
   4 CELLS R-ALLOC >R  R@ 4 CELLS CMOVE
   R> DT_CENTER DT_WORDBREAK OR DT_CALCRECT OR DrawText ;

: DrawTextCentered ( hdc a n rect -- height )
   4 CELLS R-ALLOC >R  R@ 4 CELLS CMOVE
   3DUP R@ TEXT-HEIGHT ( hdc a n height)
   R@ 3 CELLS + @ R@ CELL+ @ -  SWAP - 2/
   DUP R@ CELL+ +!  NEGATE R@ 3 CELLS + +!
   R> DT_CENTER DT_WORDBREAK OR DrawText ;

{ --------------------------------------------------------------------
Figure drawing, each in a rectangle
-------------------------------------------------------------------- }

: Diamond ( hdc ux uy lx ly -- bool )
   8 CELLS R-ALLOC LOCALS| data ly lx uy ux hdc |
   data  ux lx MID !+  uy         !+
         lx        !+  uy ly MID  !+
         ux lx MID !+  ly         !+
         ux        !+  uy ly MID  !+   DROP
   hdc data 4 Polygon ;

: Oval ( hdc ux uy lx ly -- bool )
   0 0 LOCALS| ch cw ly lx uy ux hdc |
   lx ux - 2/  ly uy - 2/   MAX  DUP TO cw  TO ch
   hdc ux uy lx ly cw ch RoundRect ;

: Rectangle ( hdc ux uy lx ly -- bool )   Rectangle ;
: Ellipse   ( hdc ux uy lx ly -- bool )   Ellipse   ;

: Nada      ( hdc ux uy lx ly -- bool )   DROP 2DROP 2DROP 0 ;

: Ring ( hdc ux uy lx ly -- bool )
   0 LOCALS| s ly lx uy ux hdc |   lx ux - 8 / ABS TO s
   hdc ux uy         lx ly        Ellipse DROP
   hdc ux uy s s V+  lx ly s s V- Ellipse ;

{ --------------------------------------------------------------------
Draw a line from one point to another
Draw a black triangle on the given vertices
-------------------------------------------------------------------- }

: DrawLine ( hdc x y x y -- bool )
   2>R THIRD >R 0 MoveToEx DROP  R> 2R> LineTo ;

: BlackPolygon ( dc 'points npoints -- bool )
   THIRD BLACK_BRUSH GetStockObject SelectObject >R  THIRD >R
   Polygon  R> R> SelectObject DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: Triangle ( hdc x y x y x y -- bool )
   6 CELLS R-ALLOC >R
   SWAP R@ 2!  SWAP R@ 2 CELLS + 2!  SWAP R@ 4 CELLS + 2!
   R> 3 Polygon ;

: ArrowHead ( hdc x y x y x y -- bool )
   6 CELLS R-ALLOC >R
   SWAP R@ 2!  SWAP R@ 2 CELLS + 2!  SWAP R@ 4 CELLS + 2!
   R> 3 BlackPolygon ;

: Arrow ( hdc x y x y tip -- bool )
   DUP 2/ LOCALS| t/2 tip ty tx fy fx dc |
   dc fx fy tx ty DrawLine DROP
   dc tx ty
   fx tx = IF ( vertical)
      fy ty < IF ( up)
         tx t/2 -  ty tip -  tx t/2 +  ty tip -
      ELSE ( down)
         tx t/2 -  ty tip +  tx t/2 +  ty tip +
      THEN
   ELSE ( horizontal)
      fx tx < if ( left)
         tx tip -  ty t/2 +  tx tip -  ty t/2 -
      ELSE ( right)
         tx tip +  ty t/2 +  tx tip +  ty t/2 -
      THEN
   THEN ArrowHead ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: Bubble ( hdc x y size -- bool )
   >R 2DUP R@ DUP V-  2SWAP R> DUP V+  Ellipse ;

: BlackBubble ( hdc x y size -- bool )
   FOURTH BLACK_BRUSH GetStockObject SelectObject >R  FOURTH >R
   Bubble R> R> SelectObject DROP ;

: InverseDrawTextCentered ( hdc a n rect -- height )
   LOCALS| r n a dc |
   dc GetBkColor  dc SWAP SetTextColor  dc SWAP SetBkColor DROP
   dc a n r DrawTextCentered
   dc GetBkColor  dc SWAP SetTextColor  dc SWAP SetBkColor DROP ;

: TextBubble ( hdc x y size addr len -- bool )
   4 CELLS R-ALLOC -ROT 2>R >R
   >R 2DUP R@ DUP V-  2SWAP R> DUP V+   R@ !RECT
   R> 2R> ROT InverseDrawTextCentered ;

{ --------------------------------------------------------------------
Knobs are part of the "i'm selected" visual cue
-------------------------------------------------------------------- }

: Knob ( dc x y size -- )
   THIRD OVER +  THIRD ROT + Rectangle DROP ;

: ShowSelection ( dc 'rect knob -- res )
   >R  DUP @RECT R>  0 0 LOCALS| mx my k cy cx y x rect dc |
   cx x - 2/ x + k 2/ - TO mx   cy y - 2/ y + k 2/ - TO my
   k negate  DUP +TO cx  +TO cy
   dc rect DrawFocusRect DROP
   dc  x  y k Knob   dc  x my k Knob
   dc  x cy k Knob   dc mx  y k Knob
   dc cx  y k Knob   dc cx my k Knob
   dc cx cy k Knob   dc mx cy k Knob  0 ;

{ --------------------------------------------------------------------
ResizeClient ( hwnd x y -- bool )
-------------------------------------------------------------------- }

: ResizeClient ( hwnd x y -- bool )   ROT >R
   R@ HERE GetWindowRect DROP
   R@ PAD GetClientRect DROP
   HERE @RECT ( x y x y)   ROT - >R  SWAP - R> ( x y wx wy)
   PAD @RECT 2SWAP 2DROP V- ( x y bx by) V+
   HERE CELL+ CELL+ V!
   R> HERE @RECT -1 MoveWindow ;


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: -@EXIT ( -- )   POSTPONE @ POSTPONE -EXIT ; IMMEDIATE

CODE SQRT ( n - i)   EBX EAX MOV   EDX EDX SUB   EDX EBX MOV
   16 # ECX MOV  BEGIN
      EAX SHL  EDX RCL  EAX SHL  EDX RCL
      EBX SHL  EBX SHL  EBX INC
      EBX EDX CMP  CS NOT  IF
         EBX EDX SUB   EBX INC  THEN
      EBX SHR
   LOOP RET END-CODE

