{ =====================================================================
maze.f
Random maze generation - Generic Text Version

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
===================================================================== }

OPTIONAL MAZE A random maze generation program

{ --------------------------------------------------------------------
This game creates a random maze which has 11 rows by 19 columns.  This
is the most that can be displayed using character graphics on an 80X24
display.  However, by changing the way squares are displayed by
.SQUARE and changing the constants ROWS and COLS to allow for a new
display size, all the other routines should still work.

Makes a maze by the method described in the December '81 issue of BYTE
(Vol. 6 No. 12) on page 190. Thanks to David Matuszek for this
interesting technique.

Requires: Extended keys and Graphic characters.
   IRN55 RANDOM @TIME DEFER IS

Exports: RANDOM-WARMUP DRAW-SQUARE ROWS COLS -BUSY RIGHT BELOW LEFT
ABOVE OCCUPIED BEGINNING ENDING VISITED CORNER 'MAZE #MAZE /MAZE
+SQUARE -SQUARE ?SQUARE IN-MAZE ADJACENT START-TREE CONNECT-TREE
OPEN-TREE AT-SQUARE PLAY
-------------------------------------------------------------------- }

EMPTY

REQUIRES irn55

{ ---------------------------------------------------------------------
Environmental dependencies

These are the things that would have to be changed for this to run in
a different environment.

CENT-CHAR character used in the center of a square when it is occupied.
WALL-CHAR character used to surround a square to create walls.

ABOVE-KEY extended key code to move up.
LEFT-KEY extended key code to move left.
RIGHT-KEY extended key code to move right.
BELOW-KEY extended key code to move down.

RANDOM-WARMUP seeds the random number generator randomly.

DRAW-SQUARE displays the given square.  Forward referenced so we can
display while updating.

--------------------------------------------------------------------- }

176 CONSTANT CENT-CHAR
219 CONSTANT WALL-CHAR

65574 CONSTANT ABOVE-KEY
65573 CONSTANT LEFT-KEY
65575 CONSTANT RIGHT-KEY
65576 CONSTANT BELOW-KEY

: RANDOM-WARMUP ( -- )   RND.SETUP
   @TIME DROP 10 + RANDOM 10 MOD 0 ?DO
      2 RANDOM DROP
   LOOP ;

DEFER DRAW-SQUARE

{ ---------------------------------------------------------------------
Maze constants and variables

ROWS and COLS identify the size of the maze.

-BUSY is a special flag to tell if a square is being initialized.

RIGHT BELOW LEFT and ABOVE are the masks to the square walls.

'MAZE the maze square array where the walls surrounding every
   square are defined as follows:
      bit 0 = RIGHT wall open     bit 1 = BELOW wall open
      bit 2 = LEFT wall open      bit 3 = ABOVE wall open
      bit 4 = Square is OCCUPIED  bit 5 = BEGINNING square
      bit 6 = ENDING square       bit 7 = Square was VISITED
      bit 8 = Impossible, used to display CORNERs.

#MAZE size of the maze array.

/MAZE is used to dynamically change the size of the maze array.

FRONTIERS contains # of frontier squares that are in maze.
SIDES indexes of adjacent squares in the spanning tree.

--------------------------------------------------------------------- }

11 VALUE ROWS    19 VALUE COLS

         0 CONSTANT -BUSY
1 0 LSHIFT CONSTANT RIGHT
1 1 LSHIFT CONSTANT BELOW
1 2 LSHIFT CONSTANT LEFT
1 3 LSHIFT CONSTANT ABOVE
1 4 LSHIFT CONSTANT OCCUPIED
1 5 LSHIFT CONSTANT BEGINNING
1 6 LSHIFT CONSTANT ENDING
1 7 LSHIFT CONSTANT VISITED
1 8 LSHIFT CONSTANT CORNER

0 VALUE 'MAZE

: #MAZE ( -- )   ROWS COLS * ;

: /MAZE ( -- )
   'MAZE ?DUP IF
      #MAZE RESIZE THROW
   ELSE  #MAZE ALLOCATE THROW
   THEN  TO 'MAZE ;

VARIABLE FRONTIERS

CREATE SIDES   4 ALLOT

{ ---------------------------------------------------------------------
Maze generation

>SQUARE calculates the address of the square at row r, column c.

+SQUARE turnes on the bit b in the square at row r, column c.

-SQUARE turns off the bit b in the square at row r, column c.

?SQUARE checks if the bit b is on in the square at row r, column c.  The
-BUSY "bit" is zero and is treated as a special case.

IN-MAZE checks the row and column to see if it is in the maze.

?BEGINNING finds the beginning square, returning its row and col.

--------------------------------------------------------------------- }

: >SQUARE ( r c -- asquare )
   COLS 1- MIN 0 MAX  SWAP
   ROWS 1- MIN 0 MAX  COLS * +  'MAZE + ;

: +SQUARE ( r c b -- )   >R  >SQUARE DUP C@  R> OR  SWAP C! ;
: +SQUARE-DRAW ( r c b -- )   >R 2DUP R> +SQUARE DRAW-SQUARE ;

: -SQUARE ( r c b -- )   INVERT >R  >SQUARE DUP C@  R> AND  SWAP C! ;

: ?SQUARE ( r c b -- )   >R >SQUARE C@ R> ?DUP IF
      AND 0<>  ELSE  DUP 255 <> AND 0<>  THEN ;

: IN-MAZE ( r c -- r c flag )
   OVER 0 ROWS WITHIN
   OVER 0 COLS WITHIN AND ;

: ?BEGINNING ( -- r c )
   ROWS 0 DO
      COLS 0 DO
         J I BEGINNING ?SQUARE IF
            J I  LEAVE
   THEN  LOOP  LOOP ;

{ ---------------------------------------------------------------------
Random square printing - Text verstion

.CENT given a square byte i and a mask m prints the square center if
the mask is on in the byte.

.WALL given a square byte i and a mask m prints the square wall if the
mask is on in the byte.

.SQUARE prints the square at its proper location on the screen given
its row r and column c.  Each square takes up a 4 X 3 character array
on the screen.  The walls above and below the square will overlap with
the neighboring squares.

.MAZE prints the whole maze on the screen and the warning message for
the game play.

--------------------------------------------------------------------- }

: .CENT ( r c m -- )   ?SQUARE IF  SPACE  ELSE  CENT-CHAR EMIT  THEN ;
: .WALL ( r c m -- )   ?SQUARE IF  SPACE  ELSE  WALL-CHAR EMIT  THEN ;

: .SQUARE ( r c -- )
   2DUP 2>R  SWAP 2*  SWAP 4 *  SWAP  2DUP AT-XY
   2R@ CORNER   .WALL  2R@ ABOVE    .WALL
   2R@ ABOVE    .WALL  2R@ CORNER   .WALL  1+  2DUP AT-XY
   2R@ LEFT     .WALL  2R@ OCCUPIED .CENT
   2R@ OCCUPIED .CENT  2R@ RIGHT    .WALL  1+  2DUP AT-XY
   2R@ CORNER   .WALL  2R@ BELOW    .WALL
   2R@ BELOW    .WALL  2R@ CORNER   .WALL  1- 1. D+ AT-XY
   2R> 2DROP ;

' .SQUARE IS DRAW-SQUARE

: .WARNING ( -- )   0 ROWS 2* 1+ AT-XY
   ." !!!! WARNING !!!! Maze will disappear as soon as you move " ;

: .MAZE ( -- )
   ROWS 0 DO
      COLS 0 DO
         J I .SQUARE
   LOOP  LOOP  CR CR
   .WARNING ;

{ ---------------------------------------------------------------------
Maze wall removal

ADJACENT calaculates the row r' and column c' of the square neighboring
the square at row r and column c in the direction d.

-WALL removes the walls between the square at row r and column c in the
direction d.  Returns true if both squares are in the maze.

NEXT-FRONTIER given an address in the maze, searches forward in the
maze for the next frontier square (no bits turned on).

@FRONTIER finds a random frontier square in the maze to be added to the
spanning tree.

--------------------------------------------------------------------- }

: ADJACENT ( r c d --- r' c' )   CASE
      RIGHT OF  0 1  ENDOF   LEFT OF  0 -1  ENDOF
      BELOW OF  1 0  ENDOF  ABOVE OF  -1 0  ENDOF
   ENDCASE  >R ROT +  R> ROT + ;

: -WALL ( r c d --- flag )
   >R  IN-MAZE >R  2DUP R> R@ SWAP >R ADJACENT
   IN-MAZE R> AND IF
      R@ 2 LSHIFT DUP ABOVE > IF  4 RSHIFT
      THEN  +SQUARE-DRAW  R@ +SQUARE-DRAW  1
   ELSE  2DROP 2DROP 0
   THEN  R> DROP ;

: NEXT-FRONTIER ( a -- a' )   1+ #MAZE 0 SCAN DROP ;

: @FRONTIER ( -- r c )
   'MAZE 1-  FRONTIERS @ RANDOM 1+ 0 DO
      NEXT-FRONTIER
   LOOP  'MAZE -  COLS /MOD SWAP ;

{ ---------------------------------------------------------------------
Create spanning tree within maze

!TREE stores the maze square at row r and column c into the spanning
tree and adds any un-initialized neighboring squares into the frontier
list.  Removes the given maze square from the frontier list.

START-TREE initializes the maze, choosing a random square for the
start of the spanning tree.  The neighboring squares start the list of
frontier squares.

?SIDES calculates out how many squares are adjacent to the square in
row r and column c and in the spanning tree, storing their indexes in
SIDES and returns the number of valid sides.

--------------------------------------------------------------------- }

: !TREE ( r c -- )
   RIGHT  4 0 DO
      >R 2DUP R@ ADJACENT  IN-MAZE IF
         >SQUARE DUP C@  255 = IF
            0 SWAP C!  1 FRONTIERS +!
         ELSE  DROP  THEN
      ELSE  2DROP  THEN  R> 1 LSHIFT
   LOOP  DROP  OCCUPIED +SQUARE  -1 FRONTIERS +! ;

: START-TREE ( -- )
   'MAZE ROWS COLS * 255 FILL  1 FRONTIERS !
   ROWS RANDOM  COLS RANDOM  2DUP 255 -SQUARE  !TREE ;

: ?SIDES ( r c -- n )
   0 ROT ROT  RIGHT  4 0 DO
      >R 2DUP R@ ADJACENT IN-MAZE >R
      OCCUPIED ?SQUARE  R> AND IF
         ROT DUP  R@ SIDES ROT + C!  1+ ROT ROT
   THEN  R> 1 LSHIFT  LOOP  DROP 2DROP ;

{ ---------------------------------------------------------------------
Open beginning and ending - get move

CONNECT-TREE chooses and connects a square to the spanning tree.  If
the square has more than one square adjacent to it in the spanning
tree, it will be connected to a random one of these.  Aborts if it can
not connect it to the tree.

OPEN-TREE chooses a random beginning square on the left and a random
ending square on the right.  The beginning square is marked in bit 5.
The ending square is marked in bit 6 and opened on the right.

?MOVE waits for a keyboard movement and returns the proper direction
index d.

--------------------------------------------------------------------- }

: CONNECT-TREE ( -- )   @FRONTIER  2DUP !TREE
   2DUP ?SIDES  RANDOM SIDES + C@  -WALL 0= ABORT" Can't " ;

: OPEN-TREE ( -- )
   ROWS RANDOM 0 BEGINNING +SQUARE-DRAW
   ROWS RANDOM COLS 1- 2DUP ENDING +SQUARE  RIGHT +SQUARE-DRAW ;

: TIRED ( -- )
   0 Z" Are you sure you want to quit?" Z" Maze" MB_YESNO MessageBox
   IDYES = THROW ;

: ?MOVE ( -- d )
   BEGIN  EKEY CASE
      [CHAR] q OF  TIRED 0  ENDOF
      [CHAR] Q OF  TIRED 0  ENDOF
         65574 OF  ABOVE 1  ENDOF
         65573 OF   LEFT 1  ENDOF
         65575 OF  RIGHT 1  ENDOF
         65576 OF  BELOW 1  ENDOF
         >R 0 R>
   ENDCASE  UNTIL ;

{ ---------------------------------------------------------------------
Make maze, find beginning, and test for end

MAKE-MAZE makes a new maze by the method described in the December '81
issue of BYTE (Vol. 6 No. 12) on page 190. Thanks to David Matuszek
for this interesting technique.

AT-SQUARE toggles the occupied bit in the square at row r and column c
and marks the square as having been visited.

CLEAR clears the screen if the square at row r and column c is at the
beginning of the maze.  It removes the beginning bit from the square
and returns the row and column unchanged.

--------------------------------------------------------------------- }

: MAKE-MAZE ( -- )
   START-TREE  ROWS COLS * 1- 0 DO
      CONNECT-TREE
   LOOP  OPEN-TREE ;

: AT-SQUARE ( r c -- )   2DUP OCCUPIED -SQUARE  VISITED +SQUARE-DRAW ;

: CLEAR ( r c -- r c )
   2DUP BEGINNING ?SQUARE IF
      PAGE  2DUP BEGINNING -SQUARE
   THEN ;

{ ---------------------------------------------------------------------
Maze generation - Text version

PLAY this game creates a random maze which has 11 rows by 19 columns.
This is the most that can be displayed using character graphics on an
80X24 display.  However, by changing the way squares are displayed by
.SQUARE and changing the constants ROWS and COLS to allow for a new
display size, all the other routines should still work.

--------------------------------------------------------------------- }

: PLAY ( -- )
   PAGE  /MAZE  RANDOM-WARMUP  ['] .SQUARE IS DRAW-SQUARE
   MAKE-MAZE  .WARNING  ?BEGINNING  BEGIN
      2DUP AT-SQUARE  BEGIN
         ?MOVE >R  CLEAR  2DUP R@ ?SQUARE NOT WHILE
            R> DROP
      REPEAT  2DUP OCCUPIED +SQUARE  2DUP .SQUARE
      R> ADJACENT  2DUP ENDING ?SQUARE
   UNTIL  AT-SQUARE  3 SPACES  ." YEA!"
   1000 MS  .MAZE ;

CR CR .( Type PLAY to run the text maze program. ) CR

