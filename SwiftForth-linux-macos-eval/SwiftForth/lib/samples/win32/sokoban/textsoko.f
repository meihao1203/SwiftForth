{ ====================================================================
textsoko.f
Sokoban (C) Copyright 1996 Rick VanNorman

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

{ --------------------------------------------------------------------
This file implements the Sokoban game engine with no assumed output
or input device.  It exports


   ROCK                 internal representations of the object
   SOKO
   WALL
   TILE
   GOAL
   GOLD

   PLAY ( n -- )        initialize play for a given level
   L                    move Sokoban left
   R                    move Sokoban right
   U                    move Sokoban up
   D                    move Sokoban down
   Z                    undo one move
   -FINISHED            true if the maze is not solved

   SHOW                 displays the entire maze
   REFRESH              updates the maze per UPDATES

   .OBJECT              is a deferred word to display an object
   PACE                 is a deferred word to slow down action
                        during replay
   /SOKOBAN             is a deferred word to perform any required
                        initialization before playing
   SOKOBAN/             is a deferred word to perform any required
                        shutdown actions on exit

The only tricky bit is that an object is represented in 7 bits
and if the object's value has the "128" bit set, it is resting on
a GOAL object. Otherwise, it is assumed to be resting on TILE and
may simply be displayed.  A ROCK with the "128" bit set is GOLD
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS DECIMAL

{ --------------------------------------------------------------------
Sokoban has 85 levels.

HIGH and WIDE represent the maximum size for a level: 20 by 20.

AREA is the number of squares in a given maze.

MAZES is an in-memory array of all the known mazes and
MAZE is the current maze being played.
-------------------------------------------------------------------- }

85 CONSTANT LEVELS

20 CONSTANT HIGH
20 CONSTANT WIDE

HIGH WIDE * CONSTANT AREA

LEVELS 2 CELLS * CONSTANT |WINNERS|

CREATE WINNERS   |WINNERS| /ALLOT

CREATE MAZE   AREA /ALLOT
CREATE MAZES  AREA LEVELS * /ALLOT

S" MAZES.DAT" R/O OPEN-FILE THROW ( fid)
( fid)     MAZES AREA LEVELS * THIRD READ-FILE ( fid n ior) NIP SWAP
( ior fid) CLOSE-FILE THROW
( ior)     THROW

{ --------------------------------------------------------------------
MOVES is how many steps Sokoban has taken and
PUSHES is how many times he has pushed an ingot.
POSITION is where Sokoban is standing
LOCALE is the current level number
-------------------------------------------------------------------- }

VARIABLE MOVES
VARIABLE PUSHES
VARIABLE POSITION
VARIABLE LOCALE

{ --------------------------------------------------------------------
There are 5 basic classes of things in the maze:

SOKO    the mover
ROCK    a lump of ore
GOAL    the place to move ROCKS to
WALL    the boundaries
TILE    the floor on which one walks

These are mapped onto characters for the human-readable file
that we use for input and for a simple display on an ascii terminal.
-------------------------------------------------------------------- }

CHAR @ CONSTANT SOKO
CHAR $ CONSTANT ROCK
CHAR . CONSTANT GOAL
CHAR # CONSTANT WALL
    BL CONSTANT TILE

{ --------------------------------------------------------------------
We track Sokoban's position in memory with an address instead of
via an x,y coordinate.

'LEVEL returns the address in the array of mazes of the given level.

/MAZE initializes the current game field.

/POSITION initializes Sokoban's position.

'WINNER is the address of thie locale's winner record.

WINNER sets the winner into the record.
-------------------------------------------------------------------- }

: 'LEVEL ( n -- a )
   LEVELS MIN 1- 0 MAX AREA * MAZES + ;

: /MAZE ( n -- )
   DUP LOCALE !  'LEVEL MAZE AREA CMOVE ;

: /POSITION ( -- )
   MAZE AREA SOKO SCAN DROP POSITION ! ;

: 'WINNER ( -- a )
   LOCALE @ LEVELS MIN 1- 0 MAX 2 CELLS * WINNERS + ;

: WINNER ( -- )
   'WINNER @ ?DUP IF ( non-zero)
      MOVES @ < ?EXIT
   THEN PUSHES @ MOVES @ 'WINNER 2! ;

{ --------------------------------------------------------------------
When Sokoban moves, we keep all moves in a short array without
displaying them, then show all the updates at once.

UPDATES contains the addresses that changed in the maze
TRAIL contains addresses and objects that changed

>UPDATE writes an address to the updates array.

'TRAIL is the address of the next location in the breadcrumb trail.

CRUMB saves a value in TRAIL

BACKTRACK returns either an object and address for restoring and true
   or simply false if no trail information is present

UN backtracks a single change

UNDO-SOKO backtracks Sokoban's last move

UNDO-ROCK tests to see if the waiting-to-be-undone object is
   a ruck and either backtracks the rock or exits.

PUT writes an object to the address, keeping backtrack information
   and logging the address in UPDATES for speedy screen writing.
-------------------------------------------------------------------- }

CREATE UPDATES   0 ,   16 CELLS /ALLOT
CREATE TRAIL     0 ,   8192 2 CELLS * /ALLOT

: /UPDATES ( -- )   UPDATES OFF ;
: /TRAIL   ( -- )   TRAIL OFF ;

: >UPDATE ( addr -- )
   UPDATES @+ 15 AND CELLS + !  UPDATES ++ ;

: 'TRAIL ( -- addr )
   TRAIL @+ 8191 AND CELLS + ;

: CRUMB ( n -- )
   'TRAIL !  TRAIL ++ ;

: BACKTRACK ( -- obj addr true | false )
   TRAIL @ 0<> DUP IF
      -2 TRAIL +! 'TRAIL 2@ ROT
   THEN ;

: UN ( -- )
   BACKTRACK -EXIT  DUP >UPDATE  C!  /POSITION ;

: UNDO-SOKO ( -- )   UN UN ;

: UNDO-ROCK ( -- )
   TRAIL @ -EXIT
   'TRAIL CELL- CELL- CELL- @ 127 AND ROCK = -EXIT
   UN UN ;

: PUT ( obj addr -- )
   DUP CRUMB  DUP C@ CRUMB  DUP >UPDATE  ( obj addr) C! ;

{ ------------------------------------------------------------------------
REMOVE takes the object from the address and replaces it with
   either TILE or GOAL depending on the object being removed.

OBSTACLE returns the object from the space in the step direction.

CLEAR? is true if the space in the step direction is clear.

ROCK? is true if the space in the step direction has a rock.

PUSH moves the object at the address the specified step, accounting
   for pushing onto goals.  This is used to move Sokoban and rocks.

UNDO backtracks Sokoban's progress.
------------------------------------------------------------------------ }

: REMOVE ( addr -- obj )
   DUP C@ DUP 127 AND SWAP
   128 AND IF GOAL ELSE TILE THEN ROT PUT ;

: OBSTACLE ( step -- obj )
   POSITION @ + C@ 127 AND ;

: CLEAR? ( step -- flag )
   OBSTACLE DUP TILE =  SWAP GOAL = OR ;

: ROCK? ( step -- flag )
   OBSTACLE ROCK = ;

: PUSH ( step addr -- )
   DUP REMOVE  -ROT  +  ( obj addr2 )
   DUP C@ GOAL = IF  SWAP 128 OR SWAP  THEN  PUT ;

: UNDO ( -- )
   UNDO-SOKO UNDO-ROCK ;

{ --------------------------------------------------------------------
MOVE-ROCK if a rock is in Sokoban's path, and the space on the
   opposite side of the rock is clear, move the rock.

MOVE-SOKO  moves Sokoban the specified step if his way is clear.

-FINISHED returns false when the level is finished. We know because
   there are no more rocks visible.

STEP moves Sokoban and pushes a rock if necessary. The step value given
   is an offset value from the current standing location to the new
   position, which means it is a memory offset.
-------------------------------------------------------------------- }

: MOVE-ROCK ( step -- )
   DUP ROCK? IF
      DUP 2* CLEAR? IF
         DUP POSITION @ + PUSH  PUSHES ++
         EXIT
      THEN
   THEN DROP ;

: MOVE-SOKO ( step -- )
   DUP CLEAR? IF
      DUP POSITION @ PUSH  POSITION +!  MOVES ++  0
   THEN DROP ;

: -FINISHED ( -- flag )
   MAZE AREA ROCK SCAN NIP 0<>  ;

: STEP ( step -- )
   -FINISHED IF
      DUP MOVE-ROCK  MOVE-SOKO
   ELSE DROP
   THEN ;

{ --------------------------------------------------------------------
WIDTH returns the lwidth of the maze.

HEIGHT returns the height of the maze.
-------------------------------------------------------------------- }

: WIDTH ( -- x )
   0 MAZE HIGH 0 DO ( x a)
      WIDE -TRAILING ROT MAX SWAP WIDE +
   LOOP DROP ;

: HEIGHT ( -- y )
   MAZE AREA -TRAILING WIDE / 1+ NIP ;

{ --------------------------------------------------------------------
TEXT.OBJECT is the default object display routine. It depends only on
   AT-XY and EMIT.
TEXT.STATUS is the default status display routine.

.OBJECT and
.STATUS are deferred so we can redefine the api later.

SHOW displays the entire maze.

A>XY translates a maze address into an x,y coordinate.

REFRESH updates the display from the address list in UPDATES.

PLAY initializes the game for the given level.

NEXT moves to the next level of play and
PREV moves to the previous level of play.
-------------------------------------------------------------------- }

: TEXT.OBJECT ( obj x y -- )   AT-XY 127 AND EMIT ;
: TEXT.STATUS ( -- )   ;

DEFER .OBJECT ( obj x y -- )   ' TEXT.OBJECT IS .OBJECT
DEFER .STATUS ( -- )           ' TEXT.STATUS IS .STATUS

: SHOW ( -- )
   MAZE HEIGHT 0 DO ( a)
      DUP WIDTH 0 DO ( a)
         COUNT I J .OBJECT
      LOOP DROP WIDE +
   LOOP DROP .STATUS ;

: A>XY ( a -- x y )
   MAZE - WIDE /MOD ;

: REFRESH
   UPDATES @+ CELLS BOUNDS ?DO
      I @ ( a) DUP C@  SWAP A>XY .OBJECT
   CELL +LOOP /UPDATES .STATUS ;

: GAME ( n -- )
   /MAZE  /POSITION  /UPDATES /TRAIL  MOVES OFF  PUSHES OFF SHOW ;

: NEXT   LOCALE @ 1+ LEVELS MIN GAME ;
: PREV   LOCALE @ 1-      1 MAX GAME ;

{ --------------------------------------------------------------------
PACE is a defer to slow down the system in automatic mode.
CHECK is a defer to check for finished and act on the information.

WALK moves Sokoban. If the distance is zero, do an UNDO. If the
   distance is greater than the size of a board, go to the next/prev
   screen. Otherwise, move left right up or down.

D U R L move Sokoban
Z undoes the last move
N goes forward one next level and
P goes back one level/
-------------------------------------------------------------------- }

DEFER PACE  :NONAME   50 MS                   ;  IS PACE
DEFER CHECK :NONAME   -FINISHED ?EXIT WINNER  ;  IS CHECK

: WALK ( n -- )
   DUP ABS AREA = IF
      0< IF PREV ELSE NEXT THEN EXIT THEN
   ?DUP IF
      -FINISHED IF STEP ELSE DROP THEN
   ELSE UNDO THEN ;

: MOTION
   CREATE , DOES> @ WALK PACE REFRESH CHECK ;

   0 HIGH + MOTION D
   0 HIGH - MOTION U
   0    1 + MOTION R
-? 0    1 - MOTION L
   0        MOTION Z
-? 0 AREA + MOTION N
   0 AREA - MOTION P

{ --------------------------------------------------------------------
MAZE 1 SOLUTION
-------------------------------------------------------------------- }

: TEST
   ( FIRST STONE)  U L L L U U U L U L L D L L D D D R R R R R R R R R R R R R
   ( SECOND STONE) R L L L L L L L L L L L L L U L L D R R R R R R R R R R R R
                   R R R D R U L U R
   ( THIRD STONE)  D L L L L L L L L L L L L L U U U R R D D U U L L D D D R R
                   R R R R R R R R R R U R D L D R
   ( FOURTH STONE) U L L L L L L L L U U U L L U U U R D D L L D D D U U L L D
                   D D R R R R R R R R R R R R D R U
   ( FIFTH STONE)  L L L L L L L L U U U L L U L D D D U U L L D D D R R R R R
                   R R R R R R R
   ( SIXTH STONE)  L L L L L L L U U U L U U U L L D D D D D U U L L D D D R R
                   R R R R R R R R R U R D L D R
   ;

