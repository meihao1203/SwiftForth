{ ====================================================================
texttetris.f
(C) Copyright 1972-1998 FORTH, Inc.

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

HERE THRESHOLD  /REFERENCES

REQUIRES RND

BL CONSTANT VOID

VARIABLE PIECES
VARIABLE LEVEL
VARIABLE TOCKS
VARIABLE SCORE
VARIABLE HIGHEST
VARIABLE DONE

{ --------------------------------------------------------------------
Bricks are defined explicitly in each rotation so I don't have to
calculate the rotations at run time.

BRICK-ALLOT allocates the space for a given brick.

BRICK, stores a row into the brick memory, assuming that the row
   consists of 4 sets of 4 chars, each a single row from a rotation.

BRICK-VALUES is the score for each brick type.

BRICKS is the text array of the possible bricks. Note that each is
   defined with a different character -- this determines the color
   the brick will display in if the .OBJECT routine uses color.
-------------------------------------------------------------------- }

: BRICK-ALLOT ( -- a )
   HERE  64 /ALLOT ;

: BRICK, ( dest addr n -- dest+4 )
   THIRD >R
   DROP 4 0 DO ( dest addr)
      2DUP SWAP 4 CMOVE  4 +  SWAP 16 + SWAP
   LOOP 2DROP
   R> 4 + ;

CREATE BRICK-VALUES
   1 C, 2 C, 3 C, 3 C, 4 C, 5 C, 5 C,

CREATE BRICKS

   BRICK-ALLOT
      S" 111 1    1   1  "  BRICK,
      S"  1  11  111 11  "  BRICK,
      S"     1        1  "  BRICK,
      S"                 "  BRICK,  DROP

   BRICK-ALLOT
      S"      2       2  "  BRICK,
      S" 2222 2  2222 2  "  BRICK,
      S"      2       2  "  BRICK,
      S"      2       2  "  BRICK,  DROP

   BRICK-ALLOT
      S" 333 3        33 "  BRICK,
      S" 3   3     3   3 "  BRICK,
      S"     33  333   3 "  BRICK,
      S"                 "  BRICK,  DROP

   BRICK-ALLOT
      S" 444 44        4 "  BRICK,
      S"   4 4   4     4 "  BRICK,
      S"     4   444  44 "  BRICK,
      S"                 "  BRICK,  DROP

   BRICK-ALLOT
      S" 55  55  55  55  "  BRICK,
      S" 55  55  55  55  "  BRICK,
      S"                 "  BRICK,
      S"                 "  BRICK,  DROP

   BRICK-ALLOT
      S" 66   6  66   6  "  BRICK,
      S"  66 66   66 66  "  BRICK,
      S"     6       6   "  BRICK,
      S"                 "  BRICK,  DROP

   BRICK-ALLOT
      S"  77 7    77 7   "  BRICK,
      S" 77  77  77  77  "  BRICK,
      S"      7       7  "  BRICK,
      S"                 "  BRICK,  DROP

{ --------------------------------------------------------------------
The pit is where the bricks fall fall down.
The pot is the saved image, so we can do more optimal screen updates.

WIDE and HIGH define the size of the pit, inclusive of the pit walls.

'PIT is the address of a particular spot in the PIT.

/POT copies the pit into the pot.

/PIT initializes the pit for a game.
-------------------------------------------------------------------- }

12 CONSTANT WIDE
20 CONSTANT HIGH

CREATE PIT  WIDE HIGH * /ALLOT
CREATE POT  WIDE HIGH * /ALLOT

: 'PIT ( x y -- addr )
   WIDE * + PIT + ;

: /POT ( -- )
   PIT POT WIDE HIGH * CMOVE ;

: /PIT ( -- )
   PIT WIDE HIGH * BLANK
   HIGH 0 DO
      [CHAR] | 0 I 'PIT C!
      [CHAR] | WIDE 1- I 'PIT C!
   LOOP
   WIDE 0 DO
      [CHAR] - I HIGH 1- 'PIT C!
   LOOP
   PIECES OFF  1 LEVEL ! /POT ;

/PIT

{ --------------------------------------------------------------------
We defer some actions so we can easily port to a graphical environment.

.REMATCH asks the user if he wishes to play again.
.OBJECT displays a graphics object on the screen.
.PREVIEW displays a preview of the next brick.
.STATUS updates the status display.
.CLS clears the screen.
!TICK sets the timer for the tick period.
-------------------------------------------------------------------- }

DEFER .REMATCH ( -- flag )        ' FALSE IS .REMATCH
DEFER .OBJECT  ( object x y -- )  ' 3DROP IS .OBJECT
DEFER .PREVIEW ( object -- )      ' DROP  IS .PREVIEW
DEFER .STATUS  ( -- )             ' NOOP  IS .STATUS
DEFER .CLS     ( -- )             ' NOOP  IS .CLS
DEFER !TICK    ( ms -- )          ' NOOP  IS !TICK

{ --------------------------------------------------------------------
SHOW is the high level interface to display the game board.  It
   redraws the entire board from scratch, using only the deferred
   words from above.

REFRESH updates the screen, assuming that the representation in POT
   is correct visually and that PIT is the new display.
-------------------------------------------------------------------- }

: SHOW ( -- )
   .CLS  PIT  HIGH 0 DO
      WIDE 0 DO
         COUNT I J .OBJECT
      LOOP
   LOOP DROP  .STATUS /POT ;

: REFRESH ( -- )
   POT PIT  HIGH 0 DO ( old new)
      WIDE 0 DO
         OVER C@ OVER C@ <> IF
            DUP C@ ( o n c) DUP FOURTH C!  I J .OBJECT
         THEN
         SWAP 1+ SWAP 1+
      LOOP
   LOOP 2DROP  .STATUS ;

{ --------------------------------------------------------------------
PX and PY track the current location of the falling brick.

ROTATION specifies the rotational position of a brick. Only the
   lowest 2 bits are used.

THIS is the address of the base picture for the current brick.

CHOSEN selects a new brick.

BRICK returns the address of the current rotation picture of the
   current brick.

ROTATE turns the current brick clockwise.

-ROTATE turns the current brick counter-clockwise.
-------------------------------------------------------------------- }

0 VALUE PX
0 VALUE PY

VARIABLE ROTATION
-? VARIABLE THIS

: CHOSEN ( n -- )
   DUP BRICK-VALUES + C@ SCORE +!
   ROTATION OFF  64 * BRICKS + THIS ! ;

: BRICK ( -- a )
   ROTATION @ 3 AND 16 * THIS @ + ;

: ROTATE ( -- )   ROTATION ++ ;

: -ROTATE ( -- )   -1 ROTATION +! ;

{ --------------------------------------------------------------------
-CLEAR tests if the given brick row would fit at the pit address.

FITS tests the current brick for fit at the XY location.

LAY puts one row of the brick into the pit.

UNLAY erases one row of the brick from the pit.

INSERT records where and places a brick in the pit.

REMOVE erases the brick from the pit.
-------------------------------------------------------------------- }

: -CLEAR ( brick pit -- flag )
   4 BOUNDS DO
      COUNT VOID <> IF
         I C@ VOID <> IF DROP TRUE UNLOOP EXIT THEN
      THEN
   LOOP DROP FALSE ;

: FITS ( x y -- flag )
   BRICK SWAP 4 BOUNDS DO ( x brick)
      DUP THIRD I 'PIT  -CLEAR IF 2DROP FALSE UNLOOP EXIT THEN  4+
   LOOP 2DROP TRUE ;

: LAY ( brick pit -- )
   4 BOUNDS DO
      COUNT DUP VOID <> IF I C! ELSE DROP THEN
   LOOP DROP ;

: UNLAY ( from to -- )
   4 BOUNDS DO
      COUNT VOID <> IF VOID I C! THEN
   LOOP DROP ;

: INSERT ( x y -- )   2DUP TO PY TO PX
   BRICK SWAP 4 BOUNDS DO ( x brick)    ( i is pity)
      DUP THIRD  I 'PIT LAY 4+
   LOOP 2DROP ;

: REMOVE ( x y -- )
   BRICK SWAP 4 BOUNDS DO ( x brick)
      DUP THIRD  I 'PIT UNLAY 4+
   LOOP 2DROP ;

{ --------------------------------------------------------------------
These routines return a flag indicating success. If the flag is
false, the routine failed and no action was taken.

PUT makes sure the brick will fit at the XY position in the pit and
   places it there.

NEW chooses a random brick and puts it at the top center of the pit.

DOWN moves the current brick down.

LEFT moves the current brick left and
RIGHT moves it right.

TURN rotates the brick clockwise.
-------------------------------------------------------------------- }

: PUT ( x y -- flag )
   2DUP FITS IF INSERT TRUE ELSE 2DROP FALSE THEN ;

: NEW ( -- flag )
   7 RND CHOSEN  WIDE 2/ 2- 0 PUT
   BUD @ 7 RND .PREVIEW  BUD ! ;

: DOWN ( -- flag )
   PX PY REMOVE
   PX PY 1+ PUT DUP ?EXIT
   PX PY INSERT ;

: LEFT ( -- flag )
   PX PY REMOVE
   PX 1- PY PUT DUP ?EXIT
   PX PY INSERT ;

: RIGHT ( -- flag )
   PX PY REMOVE
   PX 1+ PY PUT DUP ?EXIT
   PX PY INSERT ;

: TURN ( -- flag )
   PX PY REMOVE
   ROTATE
   PX PY PUT DUP ?EXIT
   -ROTATE
   PX PY INSERT ;

{ --------------------------------------------------------------------
FULL tests the indicated line to see if it is solid.

THUMP deletes the indicated line and drops the lines above it
   down one line, filling the top line with void.

-LINE deletes the indicated line if it is full and scores appropriately.

-LINES deletes all full lines, with a 20 point bonus for multiple lines.

DEXTERITY returns an decreasing value from 99 to 0 based on the game level.

/SPEED sets the drop speed based on dexterity.
-------------------------------------------------------------------- }

: FULL ( y -- flag )
   0 SWAP 'PIT WIDE VOID SCAN NIP 0= ;

: THUMP ( y -- )
   ?DUP IF
      0 SWAP 'PIT PIT -
      PIT DUP WIDE + ROT CMOVE>
   THEN
   1 0 'PIT WIDE 2- VOID FILL ;

: -LINE ( y -- )
   DUP FULL IF 10 SCORE +! LEVEL ++ DUP THUMP REFRESH THEN DROP ;

: -LINES
   LEVEL @  HIGH 1- 0 DO I -LINE  LOOP
   LEVEL @ - 2+ 0< IF 20 SCORE +! THEN ;

: DEXTERITY ( level -- n )
   DUP  50 < IF 100 SWAP -      EXIT THEN
   DUP 100 < IF  62 SWAP  4 / - EXIT THEN
   DUP 500 < IF  31 SWAP 16 / - EXIT THEN
   DROP 0 ;

: /SPEED ( -- )
   LEVEL @ DEXTERITY 5 * DUP TOCKS ! !TICK ;

{ --------------------------------------------------------------------
Tetris is played by an event driven engine. Here we enumerate the messages
that it responds to.
-------------------------------------------------------------------- }

0
  ENUM T_SHOW           \ redisplay the entire game board
  ENUM T_REFRESH        \ refresh the display
  ENUM T_READY          \ start a new brick into the pit
  ENUM T_LEFT           \ move the current brick left
  ENUM T_RIGHT          \ move the current brick right
  ENUM T_DOWN           \ move the current brick down
  ENUM T_TICK           \ timer tick, move the brick down or start a new brick
  ENUM T_TURN           \ rotate the brick
  ENUM T_PLAY           \ initiate play
  ENUM T_BANG           \ drop the brick to the bottom of the pit
  ENUM T_QUIT           \ quit the game
  ENUM T_DONE           \ pit is full
  ENUM T_IGNORE         \ do nothing
DROP

DEFER SEND ( n -- )     \ send a message to the engine and interpret it

{ --------------------------------------------------------------------
/SCORE updates the high score and clears the current score.

NEWBRICK removes any full lines, sets the speed, and starts a new
   brick into the pit. Returns true if a new brick could be inserted.

BONG drops the current brick to the bottom of the pit. Note that
   the implementation of the state transition below makes this effectively
   a recursive routine.
-------------------------------------------------------------------- }

: /SCORE ( -- )
   SCORE @ HIGHEST @ MAX HIGHEST !  SCORE OFF ;

: NEWBRICK ( -- flag )
   -LINES /SPEED NEW DUP IF PIECES ++ THEN ;

: BONG ( -- flag )
   PX PY OR 0= IF FALSE EXIT THEN
   DOWN DUP IF T_REFRESH SEND THEN ;

{ --------------------------------------------------------------------
EITHER-OR chooses a new message to send based on a flag.

GO-xxx are the state responses to messages sent to the tetris engine.
-------------------------------------------------------------------- }

: EITHER-OR ( true false flag -- )
   IF SWAP THEN NIP SEND ;

: GO-READY    T_REFRESH T_DONE      NEWBRICK EITHER-OR ;
: GO-TICK     T_REFRESH T_READY     DOWN     EITHER-OR ;
: GO-DOWN     T_REFRESH T_READY     DOWN     EITHER-OR ;
: GO-LEFT     T_REFRESH T_IGNORE    LEFT     EITHER-OR ;
: GO-RIGHT    T_REFRESH T_IGNORE    RIGHT    EITHER-OR ;
: GO-TURN     T_REFRESH T_IGNORE    TURN     EITHER-OR ;
: GO-BANG     T_BANG    T_IGNORE    BONG     EITHER-OR ;
: GO-DONE     T_PLAY    T_QUIT     .REMATCH  EITHER-OR ;

: GO-QUIT   DONE ON ;

: GO-PLAY   /RND /PIT /SCORE
   500 !TICK DONE OFF T_SHOW SEND T_READY SEND ;

: GO-SHOW    SHOW ;
: GO-REFRESH REFRESH ;

{ --------------------------------------------------------------------
ACTIONS is the event driven tetris engine. Send it a message and
   it will respond.  It resolves the SEND vector.
-------------------------------------------------------------------- }

[SWITCH ACTIONS DROP ( n -- )
   T_REFRESH RUNS GO-REFRESH
   T_SHOW    RUNS GO-SHOW
   T_READY   RUNS GO-READY
   T_TICK    RUNS GO-TICK
   T_DOWN    RUNS GO-DOWN
   T_LEFT    RUNS GO-LEFT
   T_RIGHT   RUNS GO-RIGHT
   T_TURN    RUNS GO-TURN
   T_BANG    RUNS GO-BANG
   T_PLAY    RUNS GO-PLAY
   T_QUIT    RUNS GO-QUIT
   T_DONE    RUNS GO-DONE
SWITCH]

' ACTIONS IS SEND

{ --------------------------------------------------------------------
The text-based tetris engine uses EKEY strokes, AT-XY, EMIT, and
the milli-second COUNTER to play the game.

The TEXT.xxx functions run in the console window.
-------------------------------------------------------------------- }

: TEXT.OBJECT ( object x y -- )
   AT-XY CASE
      [CHAR] 1 OF [CHAR] # ENDOF
      [CHAR] 2 OF [CHAR] # ENDOF
      [CHAR] 3 OF [CHAR] # ENDOF
      [CHAR] 4 OF [CHAR] # ENDOF
      [CHAR] 5 OF [CHAR] # ENDOF
      [CHAR] 6 OF [CHAR] # ENDOF
      [CHAR] 7 OF [CHAR] # ENDOF
      [CHAR] - OF [CHAR] # ENDOF
      [CHAR] | OF [CHAR] # ENDOF
           DUP OF BL       ENDOF
   ENDCASE EMIT ;

: TEXT.STATUS ( -- )
   20 2 AT-XY ." Level   " LEVEL ?
   20 3 AT-XY ." Pieces  " PIECES ?
   20 4 AT-XY ." Score   " SCORE ?
   20 5 AT-XY ." Highest " HIGHEST ?
   20 6 AT-XY ." Delay   " TOCKS ? ;

: TEXT.REMATCH ( -- flag )
   BEGIN
      20 9 AT-XY ." Play again?  "  8 EMIT
      KEY UPPER DUP EMIT CASE
         [CHAR] Y OF TRUE  1 ENDOF
         [CHAR] N OF FALSE 1 ENDOF
              DUP OF       0 ENDOF
      ENDCASE
      250 MS
   UNTIL
   20 5 AT-XY ."             " ;

VARIABLE PERIOD

: T!TICK ( n -- )
   COUNTER + PERIOD ! ;

' TEXT.REMATCH IS .REMATCH
' TEXT.OBJECT  IS .OBJECT
' TEXT.STATUS  IS .STATUS
' PAGE         IS .CLS
' T!TICK       IS !TICK


[SWITCH TRANSLATE ZERO ( n -- n )
   $10026 ( up)    RUNS T_TURN
   $10028 ( down)  RUNS T_DOWN
   $10025 ( left)  RUNS T_LEFT
   $10027 ( right) RUNS T_RIGHT
       27 ( esc)   RUNS T_DONE
       32 ( space) RUNS T_BANG
   CHAR Q ( Q)     RUNS T_DONE
SWITCH]

: TEXT-GAME
   DEPTH >R
   T_PLAY SEND
   BEGIN
      DEPTH R@ <> ABORT" STACK ERROR"
      PERIOD @ EXPIRED IF
         TOCKS @ COUNTER + PERIOD !
         T_TICK SEND THEN
      EKEY? IF EKEY TRANSLATE SEND THEN
   DONE @ UNTIL
   R> DROP ;


