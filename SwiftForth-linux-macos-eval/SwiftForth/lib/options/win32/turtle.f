{ ====================================================================
Simple, integer based turtle graphics

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL TURTLE Simple, integer based turtle graphics

LIBRARY GDI32

FUNCTION: LineTo ( dc x y -- )
FUNCTION: MoveToEx ( dc x y 'point -- )
FUNCTION: CreatePen ( style width color -- hpen )

REQUIRES SINE

{ ------------------------------------------------------------------------
Turtle Graphics primitives

LINE  draws a line from one xy coordinate to another.

X  is the X half of the current turtle location and
Y  is the Y half.

FX  is the fine X half of the current turtle location and
FY  is the fine Y half.

SET  moves the turtle to a location without drawing.

DRAWTO  makes a line from the current XY to the new XY.

PEN  is the state of the drawing device.

PU  picks up the pen and
PD  puts it down again.

ANGLE  is the direction of the turtle.

ASPECT  is the aspect ratio of the screen * 100 .

------------------------------------------------------------------------ }


0 VALUE INK
1 VALUE WPEN
0 VALUE HPEN
0 VALUE X
0 VALUE Y
0 VALUE FX
0 VALUE FY
0 VALUE ANGLE
0 VALUE ASPECT
0 VALUE XMAX
0 VALUE YMAX


-? : LINE ( x y x y -- )
   HWND DUP GetDC LOCALS| dc hw y2 x2 y1 x1 |   dc -EXIT
   dc HPEN SelectObject >R
   dc x1 y1 0 MoveToEx DROP dc x2 y2 LineTo DROP
   dc R> SelectObject DROP
   hw dc ReleaseDC DROP ;

: SETXY ( x y -- )
   TO Y  TO X  ;

: GETXY ( x y -- )
   X Y ;

: DRAWTO ( x y -- )
   X Y 2OVER LINE SETXY ;

: PEN ( color -- )
   HPEN DUP IF DeleteObject THEN DROP
   PS_SOLID 1 MAX WPEN ROT CreatePen TO HPEN ;

: PENWIDTH ( n -- )
   TO WPEN ;

: PU ( -- )   0 TO INK ;
: PD ( -- )   1 TO INK ;

{ ------------------------------------------------------------------------
Turtle graphics commands

RIGHT  turns the turtle to the right and
LEFT  turns it to the left.

DXDY  calculates the change in XY based on the angle given.

FINE  moves the turtle forward the number of fine units specified. The
internal representation of the position is kept in FX and FY, which
guarantees a little better resolution since they are scaled.

FORE  moves the turtle forward the specified number of units and
AFT  moves the turtle back.

CENTER  initializes the display.
------------------------------------------------------------------------ }

: DIRECTION ( n -- )
   720000 + 360 MOD  TO ANGLE ;

: RIGHT ( n -- )
   ANGLE + DIRECTION ;

: LEFT ( n -- )
   NEGATE RIGHT ;

: DXDY ( n -- dx dy )
   DUP  ANGLE COS ONE */
   SWAP ANGLE SIN ONE */ ASPECT 100 */ ;

: FINE ( n -- )
   DXDY
   OVER FX + 50 /
   OVER FY + 50 /
   INK IF DRAWTO ELSE SETXY THEN
   FY + TO FY  FX + TO FX ;

: FORE ( n -- )   50 *   FINE ;
: AFT ( n -- )   NEGATE FORE ;

-? : SETXY ( x y -- )
   2DUP SETXY  50 * TO FY  50 * TO FX ;

: GETTURTLE ( -- x y )
   FX FY ;

: SETTURTLE ( x y -- )
   TO FY  TO FX  0 FINE ;

: -INSIDE ( -- flag )
   0 X XMAX >= OR  Y YMAX >= OR  Y 0< OR  X 0< OR ;

: CENTER ( -- )
   HWND PAD GetClientRect DROP
   PAD 2 CELLS + 2@  DUP TO XMAX  OVER TO YMAX
   2/ SWAP 2/ SETXY   270 TO ANGLE  100 TO ASPECT ;

: NEW
   HPEN 0= IF  RED $1000000 OR PEN  THEN  CENTER PD ;

CENTER PD

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

AKA PD   PENDOWN
AKA PU   PENUP
AKA FORE FORWARD
AKA AFT  BACKWARD

{ ------------------------------------------------------------------------
Turtle graphics demos

( Try 27 BUSH )
( Try 118 SPIRAL or 89 SPIRAL for starts. )

------------------------------------------------------------------------ }

: BUSH ( n -- )
   DUP ABS 3 > IF
      30 LEFT  DUP FORE DUP 3 4 */ RECURSE DUP AFT
      60 RIGHT DUP FORE DUP 3 4 */ RECURSE DUP AFT
      30 LEFT
   THEN DROP ;

: SPIRAL ( angle -- )
   0 BEGIN
      DUP 2* FORE OVER RIGHT 1+
   2DUP = UNTIL 2DROP ;

: POLYGON ( len sides -- )
   360 OVER / >R BEGIN
      DUP WHILE 1- OVER
      FORE R@ RIGHT
   REPEAT R> DROP 2DROP ;


{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

-? : HELP
   PAGE
   CR ." Turtle Graphics for SwiftForth"
   CR ." (C) Copyright 1999 FORTH, Inc.   www.forth.com"
   CR
   CR ."  Command        Description
   CR ."  n FORE         move turtle forward N pixels"
   CR ."  angle RIGHT    change heading by degrees clockwise"
   CR ."  angle LEFT     change heading by degrees counter-clockwise"
   CR ."  PU             move without drawing"
   CR ."  PD             move while drawing"
   CR ."  NEW            clear screen and center turtle"
   CR ."  CENTER         center turtle"
   CR ."  x y SETTURTE   move the turtle"
   CR ."  GETTURTLE      returns the xy position of the turtle"
   CR ."  HELP           display this message"
   CR
   CR ."  angle SPIRAL   draw a polyspiral with the angle; 89 SPIRAL"
   CR ."  n BUSH         draw a fractal bush of period N; 30 BUSH"
   CR CR ;

HELP

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

PAGE 100 MS 89 SPIRAL KEY DROP
PAGE 100 MS 40 BUSH  KEY DROP

BYE [THEN]


