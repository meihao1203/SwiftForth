{ ====================================================================
Random maze generation

Copyright 2001  FORTH, Inc.
Contributed by Dennis Ruffer
==================================================================== }

OPTIONAL GUIMAZE A random maze generation program

{ --------------------------------------------------------------------

This game creates a random maze which has a variable number of rows
and columns. The graphics are sized, based upon the window size. Thus,
the window can be resized and the maze grid will adjust appropriately.

Requires: RANDOM RANDOM-WARMUP DRAW-SQUARE ROWS COLS -BUSY RIGHT BELOW
LEFT ABOVE OCCUPIED BEGINNING ENDING VISITED CORNER 'MAZE #MAZE /MAZE
+SQUARE -SQUARE ?SQUARE IN-MAZE ADJACENT START-TREE CONNECT-TREE OPEN-
TREE AT-SQUARE plus many SwiftForth and Windows functions

Exports: WIN-PLAY
-------------------------------------------------------------------- }

REQUIRES maze

TRUE CONSTANT [TASKING] IMMEDIATE       \ Use multi-tasking if true

\ Debugging support
\ REQUIRES MSGTEXT
\ REQUIRES CONSOLEBUG   TRUE TO BUGME

\ REQUIRES SINGLESTEP

{ ---------------------------------------------------------------------
Graphics constants

MAZE-CLASS is the handle of the window class.
hwndMAZE is the handle of the drawing window.
MAZE-hDC is the device context used for drawing on the window.

X .PAGE is the width and
Y .PAGE is the height of the graphics tablet.

X .DIM is the width and
Y .DIM is the height of a drawing element.

COLOR .WALL color of the walls of a square.
COLOR .CURR color of the center of a square when occupied.
COLOR .BEEN color of the trail that is left behind.
COLOR .OPEN color of an open element in a square.

HOLDBRUSH holds the handle of the previous brush.

--------------------------------------------------------------------- }

: 2H! ( n1 n2 a -- )   DUP >R H!  R> 2+ H! ;
: 2H@ ( a -- n1 n2 )   DUP 2+ H@  SWAP H@ ;

: MAZE-VERSION   Z" aMAZEing 2.00.0" ;
' MAZE-VERSION IS ABOUT-NAME

LIBRARY KERNEL32
FUNCTION: CreateDirectory ( lpPathName lpSecurityAttributes -- b )

LIBRARY USER32
FUNCTION: ScrollWindow ( hWnd XAmount YAmount *lpRect *lpClipRect -- b )

          0 VALUE MAZE-CLASS
          0 VALUE hwndMAZE
          0 VALUE hmenuMAZE
          0 VALUE MAZE-hDC
       TRUE VALUE FIRST-MAZE
ROWS COLS * VALUE ROWS*COLS
          0 VALUE MAZE-PHASE
       TRUE VALUE FIT-MAZE

CLASS tagSCROLLINFO
   VARIABLE cbSize
   VARIABLE fMask
   VARIABLE nMin
   VARIABLE nMax
   VARIABLE nPage
   VARIABLE nPos
   VARIABLE nTrackPos
END-CLASS

CLASS DIMENSIONS
   VARIABLE .MAX
   VARIABLE .PAGE
   VARIABLE .DIM
   VARIABLE .OFF
   VARIABLE .POS
   tagSCROLLINFO BUILDS SCROLLINFO
END-CLASS

DIMENSIONS BUILDS X   363 DUP X .MAX !  X .PAGE !
DIMENSIONS BUILDS Y   627 DUP Y .MAX !  Y .PAGE !

CLASS ELEMENTS
   VARIABLE .WALL
   VARIABLE .CURR
   VARIABLE .BEEN
   VARIABLE .OPEN
   VARIABLE .BACK
END-CLASS

ELEMENTS BUILDS COLOR
ELEMENTS BUILDS BRUSH

$1000000 COLOR .WALL !
$1000010 COLOR .CURR !
$1000013 COLOR .BEEN !
$100000E COLOR .OPEN !
$1000002 COLOR .BACK !

: DELETE-BRUSHES ( -- )
   BRUSH .WALL @ ?DUP IF  DeleteObject DROP  0 BRUSH .WALL !  THEN
   BRUSH .CURR @ ?DUP IF  DeleteObject DROP  0 BRUSH .CURR !  THEN
   BRUSH .BEEN @ ?DUP IF  DeleteObject DROP  0 BRUSH .BEEN !  THEN
   BRUSH .OPEN @ ?DUP IF  DeleteObject DROP  0 BRUSH .OPEN !  THEN
   BRUSH .BACK @ ?DUP IF  DeleteObject DROP  0 BRUSH .BACK !  THEN ;

: CREATE-BRUSHES ( -- )  DELETE-BRUSHES
   COLOR .WALL @ CreateSolidBrush BRUSH .WALL !
   COLOR .CURR @ CreateSolidBrush BRUSH .CURR !
   COLOR .BEEN @ CreateSolidBrush BRUSH .BEEN !
   COLOR .OPEN @ CreateSolidBrush BRUSH .OPEN !
   COLOR .BACK @ CreateSolidBrush BRUSH .BACK ! ;

{ ---------------------------------------------------------------------
Random square printing - Graphics version

CLEAR-MAZE overwrites the entire window with the background color.

G.CENT given a square byte i and a mask m prints the square center if
the mask is on in the byte.

G.WALL given a square byte i and a mask m prints the square wall if
the mask is on in the byte.

G.SQUARE prints the square at its proper location on the screen given
its row r and column c.  Each square takes up a 3 X 3 graphics array
in the drawing window.  The walls above and below the square will
overlap with the neighboring squares.

G.MAZE displays one row of the portion of the maze that has been
updated in the drawing window.  It then tells window that the rest of
the maze (if any) still needs to be updated.

--------------------------------------------------------------------- }

: FILL-RECTANGLE ( y x Y' X' brush -- )
   >R  PAD 2 CELLS + 2!  PAD 2!
   MAZE-hDC PAD R> FillRect DROP ;

: CLEAR-MAZE ( -- )   0 0  Y .PAGE @  X .PAGE @  BRUSH .BACK @
   FILL-RECTANGLE ;

: DRAW-ELEMENT ( y x brush -- y x' )   >R 2DUP 2DUP
   Y .DIM @  X .DIM @  D+  R> FILL-RECTANGLE  X .DIM @ + ;

: G.CENT ( y x r c b -- y x' )
   >R 2DUP R> ?SQUARE IF
      VISITED ?SQUARE IF
         BRUSH .BEEN @
      ELSE  BRUSH .OPEN @
   THEN  ELSE  2DROP BRUSH .CURR @
   THEN  DRAW-ELEMENT ;

: G.WALL ( y x r c b -- y x' )
   >R 2DUP R@ ?SQUARE IF
      2DUP VISITED ?SQUARE IF
         R@ ADJACENT VISITED ?SQUARE IF
            BRUSH .BEEN @
         ELSE  BRUSH .OPEN @
      THEN  ELSE  2DROP BRUSH .OPEN @  THEN
   ELSE  2DROP BRUSH .WALL @
   THEN  DRAW-ELEMENT  R> DROP ;

: G.[AL] ( y x r c b -- y x' )   DROP OR 0= IF
   BRUSH .WALL @ DRAW-ELEMENT  ELSE  X .DIM @ +  THEN ;
: G.[AR] ( y x r c b -- y x' )   DROP DROP 0= IF
   BRUSH .WALL @ DRAW-ELEMENT  ELSE  X .DIM @ +  THEN ;
: G.[BL] ( y x r c b -- y x' )   DROP NIP 0= IF
   BRUSH .WALL @ DRAW-ELEMENT  ELSE  X .DIM @ +  THEN ;
: G.[BR] ( y x r c b -- y x' )   DROP 2DROP
   BRUSH .WALL @ DRAW-ELEMENT ;

: Y.DIM+ ( y1 x1 y2 x2 -- y3 x1 y3 x1 )   2DROP  Y .DIM @ 0 D+  2DUP ;

: G.SQUARE ( r c -- )   IN-MAZE IF  2DUP -BUSY ?SQUARE IF
      2DUP 2>R  SWAP 2* Y .DIM @ * Y .OFF @ +
      Y .POS @ - DUP Y .PAGE @ < IF
         DUP Y .DIM @ 3 * + 0> IF
            SWAP 2* X .DIM @ * X .OFF @ +
            X .POS @ - DUP X .PAGE @ < IF
               DUP X .DIM @ 3 * + 0> IF  2DUP
      2R@ CORNER G.[AL]  2R@ ABOVE    G.WALL  2R@ CORNER G.[AR]  Y.DIM+
      2R@ LEFT   G.WALL  2R@ OCCUPIED G.CENT  2R@ RIGHT  G.WALL  Y.DIM+
      2R@ CORNER G.[BL]  2R@ BELOW    G.WALL  2R@ CORNER G.[BR]  2DROP
   THEN  THEN  THEN  THEN  THEN  THEN  2DROP 2R> 2DROP ;

' G.SQUARE IS DRAW-SQUARE

: G.MAZE ( -- )
   CLEAR-MAZE  ROWS 0 DO
      COLS 0 DO
         J I G.SQUARE
   LOOP  LOOP ;

{ ---------------------------------------------------------------------
Menu definition

Constants control what is passed to WM_COMMAND from menu selections.

The offset from WM_USER of 100 is merely a guess.  This software would
crash in MAZE-STATE if this offset was not included!

The menu itself is defined and created here, and its handle is saved
for later deletion.

--------------------------------------------------------------------- }

WM_USER 100 + ENUM MAZE_CREATE
        ENUM MAZE_REPAINT
        ENUM MAZE_PAINT
        ENUM MAZE_SQUARE
DROP

100 ENUM MAZE_FIT
    ENUM MAZE_SIZE
    ENUM MAZE_COLOR
    ENUM MAZE_ABOUT
    ENUM MAZE_HELP
    ENUM MAZE_NEW
    ENUM MAZE_OPEN
    ENUM MAZE_SAVE
    ENUM MAZE_SAVE-AS
    ENUM MAZE_EXIT
DROP

MENU MAZE-MENU

   POPUP "&File"
      MAZE_NEW     MENUITEM "&New"
      MAZE_OPEN    MENUITEM "&Open"
                   SEPARATOR
      MAZE_SAVE    MENUITEM "&Save"
      MAZE_SAVE-AS MENUITEM "Save &As"
                   SEPARATOR
      MAZE_EXIT    MENUITEM "E&xit"  \ What about accelerators*?*
   END-POPUP

   POPUP "&Options"
      MAZE_FIT    CHECKITEM "F&it to Window"
      MAZE_SIZE    GRAYITEM "&Size"
      MAZE_COLOR   MENUITEM "&Colors"
   END-POPUP

   POPUP "&Help"
      MAZE_HELP    GRAYITEM "&Help"
      MAZE_ABOUT   MENUITEM "&About"
   END-POPUP

END-MENU

: MAZEWIN/ ( -- )   HWND GetMenu DestroyMenu DROP ;

: /MAZEWIN ( -- )   HWND MAZE-MENU LoadMenuIndirect
   DUP TO hmenuMAZE SetMenu DROP ;

{ --------------------------------------------------------------------
Save and restore registry values

-------------------------------------------------------------------- }

CREATE SAVED-POS      4 CELLS DUP /ALLOT   CONSTANT #SAVED-POS
CREATE SAVED-SIZE     8 CELLS DUP /ALLOT   CONSTANT #SAVED-SIZE
CREATE SAVED-COLORS   5 CELLS DUP /ALLOT   CONSTANT #SAVED-COLORS

: MAZEKEY ( -- handle )
   HKEY_CURRENT_USER Z" SOFTWARE\SwiftForth\Maze" 0 >R RP@
   RegCreateKey DROP R> ;

: GET-POSITION ( -- )   MAZEKEY >R
   SAVED-POS #SAVED-POS Z" Position" R@ READ-REG 2DROP
   R> RegCloseKey DROP ;

: SAVE-POSITION ( -- )   MAZEKEY >R
   SAVED-POS #SAVED-POS Z" Position" R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

: GET-MAZE-SIZE ( -- )   SAVED-SIZE
   @+ TO ROWS  @+ Y .PAGE !  @+ Y .OFF !  @+ Y .DIM !
   @+ TO COLS  @+ X .PAGE !  @+ X .OFF !  @  X .DIM ! ;

: SAVE-MAZE-SIZE ( -- )   SAVED-SIZE
   ROWS !+  Y .PAGE @ !+  Y .OFF @ !+  Y .DIM @ !+
   COLS !+  X .PAGE @ !+  X .OFF @ !+  X .DIM @ !+  DROP ;

: GET-REGISTRY-SIZE ( -- )   MAZEKEY >R
   SAVED-SIZE #SAVED-SIZE Z" Size" R@ READ-REG NIP 0= IF
      GET-MAZE-SIZE  THEN  R> RegCloseKey DROP ;

: SAVE-REGISTRY-SIZE ( -- )   MAZEKEY >R  SAVE-MAZE-SIZE
   SAVED-SIZE #SAVED-SIZE Z" Size" R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

: GET-COLORS ( -- )   SAVED-COLORS
   @+ COLOR .WALL !  @+ COLOR .CURR !  @+ COLOR .BEEN !
   @+ COLOR .OPEN !  @  COLOR .BACK ! ;

: SAVE-COLORS ( -- )   SAVED-COLORS
   COLOR .WALL @ !+  COLOR .CURR @ !+  COLOR .BEEN @ !+
   COLOR .OPEN @ !+  COLOR .BACK @ !+  DROP ;

: GET-REGISTRY-COLORS ( -- )   MAZEKEY >R
   SAVED-COLORS #SAVED-COLORS Z" Colors" R@ READ-REG NIP 0= IF
      GET-COLORS  THEN  R> RegCloseKey DROP ;

: SAVE-REGISTRY-COLORS ( -- )   MAZEKEY >R  SAVE-COLORS
   SAVED-COLORS #SAVED-COLORS Z" Colors" R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

: GET-REGISTRY   GET-POSITION
   GET-REGISTRY-COLORS  GET-REGISTRY-SIZE ;
: SAVE-REGISTRY   SAVE-POSITION
   SAVE-REGISTRY-COLORS  SAVE-REGISTRY-SIZE ;

{ ---------------------------------------------------------------------
Maze window creation.

This follows the generic template for windows programs.

UPDATE-TITLE changes the window title to show the current size.
REDRAW-MAZE invalidates the drawing window so the maze is redrawn.

--------------------------------------------------------------------- }

CREATE AppName ,Z" SFMAZE"

[SWITCH MAZE-MESSAGES DEFWINPROC ( -- res )
   WM_DESTROY RUN:  MAZEWIN/  0 PostQuitMessage DROP  0 ;
SWITCH]

:NONAME ( -- res )
   [BUG  CR  MSG LOWORD WMTEXT COUNT TYPE  BUG]
   MSG LOWORD MAZE-MESSAGES ;  4 CB: WNDPROC

: CREATE-MAZE-CLASS ( -- res )
   [OBJECTS WNDCLASS MAKES wc OBJECTS]
      CS_HREDRAW
      CS_VREDRAW OR
      CS_OWNDC OR wc style !
      WNDPROC wc WndProc !
      0 wc ClsExtra !
      0 wc WndExtra !
      HINST wc Instance !
      HINST 101 LoadIcon wc Icon ! \ from SwiftForth
      NULL IDC_ARROW LoadCursor wc Cursor !
      BRUSH .BACK @ wc Background !
      MAZE-MENU wc MenuName !
      AppName wc ClassName !
   wc style RegisterClass ;

: MAZE-TITLE ( -- zaddr )
   ROWS (.) PAD ZPLACE  S" x" PAD ZAPPEND  COLS (.) PAD ZAPPEND
   S"  " PAD ZAPPEND  MAZE-VERSION DUP ZLENGTH PAD ZAPPEND  PAD ;

: WINDOW-POSITION ( -- x y w h )
   SAVED-POS @+ SWAP @+ SWAP @+ SWAP @
   >R THIRD - R> THIRD - ;

: CREATE-MAZE-WINDOW ( -- hwnd )
      0                                 \ extended style
      AppName                           \ window class name
      MAZE-TITLE                        \ caption
      WS_OVERLAPPEDWINDOW               \ window style
      WINDOW-POSITION 2DUP OR 0= IF
         2DROP 2DROP
         CW_USEDEFAULT                  \ initial x position
         CW_USEDEFAULT                  \ y
         CW_USEDEFAULT                  \ x size
         CW_USEDEFAULT                  \ y
      THEN
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx DUP TO hwndMAZE ;

: UPDATE-TITLE ( -- )   hwndMAZE MAZE-TITLE SetWindowText DROP ;
: REDRAW-MAZE ( -- )   hwndMAZE 0 1 InvalidateRect DROP ;

{ ---------------------------------------------------------------------
Maze scrolling and fitting to window

/DIMS sets the drawing element size based upon the window size and the
number of maze elements.

--------------------------------------------------------------------- }

: /xSCROLLINFO ( bar pos page max a -- )
   7 CELLS   X SCROLLINFO cbSize !
   SIF_ALL   X SCROLLINFO fMask  !
   0         X SCROLLINFO nMin   !
   X .MAX @  X SCROLLINFO nMax   !
   X .PAGE @ X SCROLLINFO nPage  !
   X .POS @  X SCROLLINFO nPos   !
   hwndMAZE SWAP X .MAX TRUE SetScrollInfo DROP ;

: /ySCROLLINFO ( bar pos page max a -- )
   7 CELLS   Y SCROLLINFO cbSize !
   SIF_ALL   Y SCROLLINFO fMask  !
   0         Y SCROLLINFO nMin   !
   Y .MAX @  Y SCROLLINFO nMax   !
   Y .PAGE @ Y SCROLLINFO nPage  !
   Y .POS @  Y SCROLLINFO nPos   !
   hwndMAZE SWAP Y .MAX TRUE SetScrollInfo DROP ;

: /SCROLL-BARS ( -- )
   SB_VERT /ySCROLLINFO  SB_HORZ /xSCROLLINFO ;

: !Y.POS ( n -- )
   0 MAX Y .MAX @ Y .PAGE @ - MIN Y .POS @ OVER Y .POS ! SWAP -
   hwndMAZE 0 ROT 0 0 ScrollWindow DROP
   /SCROLL-BARS ;

: !X.POS ( n -- )
   0 MAX X .MAX @ X .PAGE @ - MIN X .POS @ OVER X .POS ! SWAP -
   hwndMAZE SWAP 0 0 0 ScrollWindow DROP
   /SCROLL-BARS ;

: /xDIM ( n -- )   FIT-MAZE IF
      X .PAGE @ OVER 2* 1+ / 2 MAX X .DIM !
   THEN  X .DIM @ * 2* X .DIM @ + X .MAX !
   X .PAGE @ X .MAX @ - 0 MAX 2/ DUP X .OFF !  2* X .MAX +!
   X .MAX @ X .PAGE @ 2DUP = IF  1 X .PAGE +!  THEN
   - 0 MAX X .POS @ MIN X .POS ! ;

: /yDIM ( n -- )   FIT-MAZE IF
      Y .PAGE @ OVER 2* 1+ / 2 MAX Y .DIM !
   THEN  Y .DIM @ * 2* Y .DIM @ + Y .MAX !
   Y .PAGE @ Y .MAX @ - 0 MAX 2/ DUP Y .OFF !  2* Y .MAX +!
   Y .MAX @ Y .PAGE @ 2DUP = IF  1 Y .PAGE +!  THEN
   - 0 MAX Y .POS @ MIN Y .POS ! ;

: /DIMS ( -- )   ROWS /yDIM  COLS /xDIM ;

/DIMS

: SET-FIT-MAZE ( flag -- )   DUP TO FIT-MAZE
   hmenuMAZE MAZE_FIT ROT IF
      MF_CHECKED  ELSE  MF_UNCHECKED
   THEN CheckMenuItem DROP ;

: TOGGLE-FIT-MAZE ( -- )   FIT-MAZE NOT SET-FIT-MAZE
   Y .DIM @ X .DIM @  /DIMS  Y .DIM @ X .DIM @ D= NOT IF
      /SCROLL-BARS  REDRAW-MAZE  THEN ;

{ ---------------------------------------------------------------------
Maze updating

CURR-SQUARE holds the current row and column.

BEGINNING-SQUARE establishes the square where we start the game.  It
does not use the begin bit (5) because that is used by the paint
routine.

MAZE-STATES sends the MAZE_CREATE message to the drawing window with
the given maze phase and creation index. The PAUSE before sending the
message is neccessary to allow the window a chance to receive other
messages.

UPDATE-MAZE kicks the maze cration sequence off by sending the first
MAZE_CREATE message.

MAZE-STATE recreates a maze given its phase and index.  If the phase
has changed, then we stop because the user has asked that the size be
increased.  If the index is 0, we start the maze.  If the index has
covered all the squares, then we end it and establish the beginning
square. Otherwise, we pick a random frontier and connect it to the
maze.  Each of these states is done with a seperate MAZE_CREATE
message so that the window is still responsive.

--------------------------------------------------------------------- }

2VARIABLE CURR-SQUARE

: SET-CURR-SQUARE ( r c -- )   2DUP AT-SQUARE  CURR-SQUARE 2! ;

: BEGINNING-SQUARE ( -- )   ROWS RANDOM 0 SET-CURR-SQUARE ;

: MAZE-POST ( w l msg -- )   hwndMAZE SWAP 2SWAP PostMessage DROP ;

: UPDATE-MAZE ( -- )   MAZE-PHASE 0 MAZE_CREATE MAZE-POST ;

: MAZE-STATE ( phase n -- )   PAUSE
   OVER MAZE-PHASE = IF  DUP IF
         DUP ROWS*COLS = IF
            2DROP  OPEN-TREE  BEGINNING-SQUARE
            FALSE TO FIRST-MAZE  0 -1
         ELSE  CONNECT-TREE
      THEN  ELSE  CLEAR-MAZE  START-TREE
      THEN  1+  ELSE  DROP  0
   THEN  DUP IF  2DUP MAZE_CREATE MAZE-POST
   THEN  2DROP ;

{ ---------------------------------------------------------------------
Maze resizing

(MAX-COLS) returns the maximum number of colums for the window size.
(MAX-ROWS) returns the maximum number of rows for the window size.

MAX-COLS returns the maximum columns for the window ratio.
MAX-ROWS returns the maximum rows for the window ratio.
MIN-COLS returns the minimum columns for the window ratio.
MIN-ROWS returns the minimum rows for the window ratio.

SUB-ROWS decreases the rows if the column minimum not exceeded.
SUB-COLS decreases the columns if the row minimum not exceeded.
ADD-ROWS increases the rows if the column maximum not exceeded.
ADD-COLS increases the columns if the row maximum not exceeded.

+MAZE changes the size of the array, preserving a close approximation
of the window dimensions.  The maze will be clipped to no less than
2 elements and no less than 2 pixels per element.

NEW-MAZE changes the size of the maze array by the given size and
starts the game over again.  It will decrease the size of the maze
repeatedly until there is enough memory to hold it.

FRST-MAZE regenerates a maze of the same size.
NEXT-MAZE increases the size of the maze.
PREV-MAZE decreases the size of the maze.

--------------------------------------------------------------------- }

: (MAX-COLS) ( -- n )   FIT-MAZE NOT IF  32767
   ELSE  X .PAGE @ 4 /MOD  SWAP 2 < IF  1-  THEN  THEN ;
: (MAX-ROWS) ( -- n )   FIT-MAZE NOT IF  32767
   ELSE  Y .PAGE @ 4 /MOD  SWAP 2 < IF  1-  THEN  THEN ;

: MAX-COLS ( -- n )   X .PAGE @ Y .PAGE @ > IF  (MAX-COLS)
   ELSE  (MAX-ROWS) X .PAGE @ Y .PAGE @ */  THEN ;
: MAX-ROWS ( -- n )   Y .PAGE @ X .PAGE @ > IF  (MAX-ROWS)
   ELSE  (MAX-COLS) Y .PAGE @ X .PAGE @ */  THEN ;
: MIN-COLS ( -- n )   X .PAGE @ Y .PAGE @ < IF  2
   ELSE  2 X .PAGE @ Y .PAGE @ */  THEN ;
: MIN-ROWS ( -- n )   Y .PAGE @ X .PAGE @ < IF  2
   ELSE  2 Y .PAGE @ X .PAGE @ */  THEN ;

: SUB-ROWS ( n -- c r )
   DUP ROWS +  DUP X .PAGE @ Y .PAGE @ */  DUP MIN-COLS < IF
      DROP SWAP - MIN-COLS  ELSE  ROT DROP  THEN  SWAP ;
: SUB-COLS ( n -- c r )
   DUP COLS +  DUP Y .PAGE @ X .PAGE @ */  DUP MIN-ROWS < IF
      DROP SWAP - MIN-ROWS  ELSE  ROT DROP  THEN ;
: ADD-ROWS ( n - c r )
   DUP ROWS +  DUP X .PAGE @ Y .PAGE @ */  DUP MAX-COLS > IF
      DROP SWAP - MAX-COLS  ELSE  ROT DROP  THEN  SWAP ;
: ADD-COLS ( n -- c r )
   DUP COLS +  DUP Y .PAGE @ X .PAGE @ */  DUP MAX-ROWS > IF
      DROP SWAP - MAX-ROWS  ELSE  ROT DROP  THEN ;

: +MAZE ( n -- )   MAZE-PHASE 1+ TO MAZE-PHASE
   COLS MIN-COLS MAX MAX-COLS MIN TO COLS
   ROWS MIN-ROWS MAX MAX-ROWS MIN TO ROWS  DUP >R 0< IF
      COLS MIN-COLS = IF  ROWS MIN-ROWS = IF  R> DROP EXIT  THEN
         R@ SUB-ROWS  ELSE  ROWS MIN-ROWS =
         X .PAGE @ Y .PAGE @ > OR IF
            R@ SUB-COLS  ELSE  R@ SUB-ROWS
   THEN  THEN  ELSE  R@ 0> IF
         COLS MAX-COLS = IF  ROWS MAX-ROWS = IF  R> DROP EXIT  THEN
            R@ ADD-ROWS  ELSE  ROWS MAX-ROWS =
            X .PAGE @ Y .PAGE @ > OR IF
               R@ ADD-COLS  ELSE  R@ ADD-ROWS
      THEN  THEN  ELSE   X .PAGE @ Y .PAGE @ > IF
            COLS DUP Y .PAGE @ X .PAGE @ */
         ELSE  ROWS DUP X .PAGE @ Y .PAGE @ */ SWAP
   THEN  THEN  THEN  2DUP * TO ROWS*COLS
   TO ROWS  TO COLS  R> DROP ;

: NEW-MAZE ( n -- )   BEGIN  +MAZE  ['] /MAZE CATCH WHILE
      -1  REPEAT  /DIMS  TRUE TO FIRST-MAZE ;

: FRST-MAZE   0 NEW-MAZE  UPDATE-TITLE  /SCROLL-BARS  UPDATE-MAZE ;
: NEXT-MAZE   1 NEW-MAZE  UPDATE-TITLE  /SCROLL-BARS  UPDATE-MAZE ;
: PREV-MAZE  -1 NEW-MAZE  UPDATE-TITLE  /SCROLL-BARS  UPDATE-MAZE ;

{ ---------------------------------------------------------------------
Moving around the maze

FINISHED-MAZE displays a message box when we are finished.

MOVE-SQUARE moves to the next square based upon the given direction.
It verifies if the direction is legal and stops until a new maze is
drawn if we are at the end.

MOVE: defines words that move the current square around the maze.
   MOVE-ABOVE MOVE-BELOW MOVE-LEFT MOVE-RIGHT are the directions.

--------------------------------------------------------------------- }

: FINISHED-MAZE ( -- )
   hwndMAZE Z" You finished!" Z" Yea!" MB_OK MessageBox DROP ;

: MOVE-SQUARE ( n -- )
   FIRST-MAZE IF  DROP EXIT  THEN
   >R  CURR-SQUARE 2@  2DUP R@ ?SQUARE IF
      2DUP ENDING ?SQUARE NOT IF
         2DUP OCCUPIED +SQUARE  2DUP DRAW-SQUARE  R@ ADJACENT
         2DUP SET-CURR-SQUARE  2DUP ENDING ?SQUARE IF
            FINISHED-MAZE  NEXT-MAZE
   THEN  THEN  THEN  2DROP  R> DROP ;

: MOVE: ( n -- ) \ Usage: n MOVE: <name>
   CREATE  ,  DOES>  @ MOVE-SQUARE ;

ABOVE MOVE: MOVE-ABOVE   BELOW MOVE: MOVE-BELOW
 LEFT MOVE: MOVE-LEFT    RIGHT MOVE: MOVE-RIGHT

{ ---------------------------------------------------------------------
Repaint queues and timing

REPAINT-QUEUE is a facility to syncronize access to the repaint queue.

REPAINT-LINKS points to a linked list of rectangle structures in the
repaint queue.  Task syncronization is required before this queue can
be modified.

PAINT-LINKS points to a linked list of row/column structures in the
painting queue.

MARK-LINKS points to a linked list of row/column structures in the
marking queue.

AT-END returns the address of the last element in the given queue.
FROM-BEGINNING returns the address of the first element in the given
queue.  It's link address is cleared before it is returned.

START-TIME is the time when we last came back from a PAUSE.
TIMEOUT is the amount of time that we allow this task to run.

--------------------------------------------------------------------- }

2VARIABLE PAINT-QUEUE
2VARIABLE MARK-QUEUE

: AT-END ( a -- a' )   CELL+  BEGIN  DUP @ ?DUP WHILE  NIP  REPEAT ;
: FROM-BEGINNING ( a -- a' )   CELL+ DUP @  DUP DUP IF  @
   THEN  ROT ! DUP OFF ;

#USER CELL +USER START-TIME  TO #USER

10 VALUE TIMEOUT

: ALIVE ( -- )  ( PAUSE  COUNTER START-TIME ! ) ;
: KEEP-ALIVE ( -- flag )  ( START-TIME @ TIMEOUT + EXPIRED) FALSE ;

{ ---------------------------------------------------------------------
Rectangle and Row/Column structures

UPDATED-ROWS returns loop parameters for invalidated rows.
UPDATED-COLS returns loop parameters for invalidated columns.

REPAINT validates that the rectangle structure contains some maze
squares which need to be updated.  If it does, the rectangle structure
is converted to a row/column structure and it's address is returned
with a true flag.  Otherwise, only a false flag is returned.

RELINK-MAZE validates that a maze square still needs to be updated
from the given linked list.  If one does, it returns its row and
column with a true flag and places an incremented row/column structure
back into the end of the linked list.  Otherwise, it returns the
address of the link element, which has been removed from the list and
has had its index parameters reset, and a false flag.

--------------------------------------------------------------------- }

CREATE &ps   64 ALLOT

: UPDATED-ROWS ( -- last first )
   &ps 20 + @  Y .POS @ + Y .OFF @ - Y .DIM @ - Y .DIM @ 2* /
   1+ ROWS MIN 0 MAX
   &ps 12 + @  Y .POS @ + Y .OFF @ - Y .DIM @ - Y .DIM @ 2* / 0 MAX ;

: UPDATED-COLS ( -- last first )
   &ps 16 + @  X .POS @ + X .OFF @ - X .DIM @ - X .DIM @ 2* /
   1+ COLS MIN 0 MAX
   &ps  8 + @  X .POS @ + X .OFF @ - X .DIM @ - X .DIM @ 2* / 0 MAX ;

: REPAINT ( a -- a t|f )   >R
   UPDATED-COLS 2DUP = IF  R> DROP FALSE EXIT  THEN
      DUP R@ CELL+ H!  R@ 2 CELLS + 2H!
   UPDATED-ROWS 2DUP = IF  R> DROP FALSE EXIT  THEN
      DUP R@ CELL+ 2+ H!  R@ 3 CELLS + 2H!
   R> DUP OFF  TRUE ;

: RELINK-MAZE ( a -- r c t | a f )   DUP >R FROM-BEGINNING
   DUP >R CELL+ 2H@  DUP R@ 2 CELLS + 2+ H@ < NOT IF
      DROP R@ 2 CELLS + H@  SWAP
      1+ DUP R@ 3 CELLS + 2+ H@ < NOT IF
         DROP R@ 3 CELLS + H@  SWAP R@ CELL+ 2H!
         R> R> DROP  FALSE  EXIT
   THEN  SWAP  THEN  2DUP 1+ R@ CELL+ 2H!
   R> R> AT-END !  TRUE ;

{ ---------------------------------------------------------------------
Painting an invalidated maze

MARK-SQUARE sets the BEGINNING flag on the given square.
PAINT-SQUARE draws the given square if its BEGINNING flag is set and
then clears the flag.  This prevents multiple repaint cycles from
displaying the same square multiple times.

MARK-MAZE picks up the next repainting element.  If there is a square
that still needs to be marked, it returns the row and column of the
square and true.  Otherwise, it returns false and the element is
placed at the end of the paint queue.

PAINT-MAZE picks up the next paint element.  If there is a squares
that still needs to be painted, it returns the row and column of the
square and true.  Otherwise, it returns false and the element is
freed. The GDI buffers must then be flushed so screen is fully
updated.

REPAINT-MAZE is the main processing loop for repainting an invalidated
maze.  It is a sequence of 3 processing loop.  The 1st has the highest
priority and takes a rectangle strucutre from the repaint queue,
converting it into a row/column structure which is placed into the
marking queue.  Once the repaint queue is empty, the 2nd loop marks
the squares in the marking queue.  Once each marking element is
finished, it is passed to the painting queue.  Once the marking queue
is empty, the 3rd loop paints the squares in the painting queue.  When
all of the queues are empty, then this routine exits.  Both the 2nd
and 3rd loops will go back to the 1st when it is time to keep the
system alive.

--------------------------------------------------------------------- }

: PAINT-SQUARE ( r c -- )   IN-MAZE IF  2DUP -BUSY ?SQUARE IF
         2DUP BEGINNING ?SQUARE IF
            2DUP BEGINNING -SQUARE
            2DUP DRAW-SQUARE
   THEN  THEN  THEN  2DROP ;

: PAINT-MAZE ( -- r c t|f )   PAINT-QUEUE RELINK-MAZE DUP NOT IF
      SWAP FREE DROP  GdiFlush DROP  THEN ;

: REPAINT-MAZE ( -- )   BEGIN  ALIVE
      BEGIN  PAINT-QUEUE CELL+ @ WHILE
         PAINT-QUEUE GRAB  PAINT-MAZE
         PAINT-QUEUE RELEASE  IF
            PAINT-SQUARE  THEN  KEEP-ALIVE
   UNTIL  [ CS-SWAP ]  AGAIN  THEN ;

VARIABLE -PAINTING   -PAINTING ON

[TASKING] [IF]  4096 TASK MAZE-PAINTER  [THEN]

: REPAINTING ( -- )   [TASKING] [IF]  MAZE-PAINTER ACTIVATE  [THEN]
   REPAINT-MAZE  -PAINTING ON  [TASKING] [IF]  TERMINATE  [THEN] ;

: START-PAINTING   -PAINTING @ IF  -PAINTING OFF  REPAINTING  THEN ;

{ ---------------------------------------------------------------------
WM_PAINT processing

-PAINTING holds TRUE if the REPAINTER task needs to be started.

REPAINTER is the task which does the repainting of the maze squares.

REPAINTING activates the REPAINTER task to do the maze repainting.

START-PAINTING starts the REPAINTER task if it is not running.  It
turns off the -PAINTING flag itself to prevent a race condition under
Win95 and may be able to be removed if that race condition is
harmless.

>HDC and HDC< begins and ends the windows paint process which tells us
the dimensions of the pixel rectangle that has been invalidated.

PAINT.MAZE called by the WM_PAINT message when a portion of the
drawing window has been invalidated.  It kicks off the sequence of
MAZE_PAINT messages that will update that rectangle, by placing the
rectangle structure into the repaint queue and clearing it to the
background color.  It also starts the REPAINTER task if it is not
currently running.

--------------------------------------------------------------------- }

: MARK-SQUARE ( r c -- )   IN-MAZE IF  2DUP -BUSY ?SQUARE IF
         2DUP BEGINNING +SQUARE
   THEN  THEN  2DROP ;

: MARK-MAZE ( a -- )   DUP 3 CELLS + 2H@ ?DO
      DUP 2 CELLS + 2H@ ?DO
         J I MARK-SQUARE  KEEP-ALIVE IF  ALIVE
   THEN  LOOP  LOOP  DROP ;

: REMARK-MAZE ( -- )   BEGIN  ALIVE
      MARK-QUEUE CELL+ @ WHILE
         MARK-QUEUE GRAB  MARK-QUEUE FROM-BEGINNING
         MARK-QUEUE RELEASE  DUP MARK-MAZE
         PAINT-QUEUE GET  PAINT-QUEUE AT-END !
         PAINT-QUEUE RELEASE  START-PAINTING
   REPEAT ;

VARIABLE -MARKING   -MARKING ON

[TASKING] [IF]  4096 TASK MAZE-MARKER  [THEN]

: REMARKING ( -- )   [TASKING] [IF]  MAZE-MARKER ACTIVATE  [THEN]
   REMARK-MAZE  -MARKING ON  [TASKING] [IF]  TERMINATE  [THEN] ;

: START-MARKING   -MARKING @ IF  -MARKING OFF  REMARKING  THEN ;

: >HDC ( -- )   hwndMAZE &ps BeginPaint TO MAZE-hDC ;

: HDC< ( -- )   hwndMAZE &ps EndPaint DROP ;

: PAINT.MAZE ( -- )   BEGIN
      4 CELLS ALLOCATE WHILE  DROP PAUSE
   REPEAT  >HDC  REPAINT  HDC<  IF
      MARK-QUEUE GET  MARK-QUEUE AT-END !
      MARK-QUEUE RELEASE  START-MARKING
   THEN ;

{ ---------------------------------------------------------------------
MAZE Color selection dialog box

The simple box for swift forth is an example of a modal dialog.

--------------------------------------------------------------------- }

CREATE DIALOG-MAZE
   VISITED OCCUPIED OR BELOW OR C,
    ENDING OCCUPIED OR BELOW OR RIGHT OR C,
   VISITED OCCUPIED OR ABOVE OR RIGHT OR C,
   VISITED             ABOVE OR  LEFT OR C,

: COLOR-DIALOG-BRUSHES ( -- )  DELETE-BRUSHES
   SAVED-COLORS @+ CreateSolidBrush BRUSH .WALL !
                @+ CreateSolidBrush BRUSH .CURR !
                @+ CreateSolidBrush BRUSH .BEEN !
                @+ CreateSolidBrush BRUSH .OPEN !
                @  CreateSolidBrush BRUSH .BACK ! ;

: DEFAULT-COLORS ( -- )
   SAVED-COLORS [ COLOR .WALL @ ] LITERAL !+
                [ COLOR .CURR @ ] LITERAL !+
                [ COLOR .BEEN @ ] LITERAL !+
                [ COLOR .OPEN @ ] LITERAL !+
                [ COLOR .BACK @ ] LITERAL !+ DROP ;

DIALOG (MAZE-COLORS)
   [MODAL  " Set maze colors"                    10   10  160  130
                                           (FONT 8, MS Sans Serif) ]

\  [control        " default text"     id      xpos ypos xsiz ysiz ]
   [DEFPUSHBUTTON  " OK"               IDOK      05  110   45   15 ]
   [PUSHBUTTON     " Cancel"           IDCANCEL  55  110   45   15 ]
   [PUSHBUTTON     " Apply"            101      110  110   45   15 ]
   [PUSHBUTTON     " Defaults"         102      110   90   45   15 ]
   [PUSHBUTTON     " Walls"            103      110   10   45   15 ]
   [PUSHBUTTON     " Location"         104      110   25   45   15 ]
   [PUSHBUTTON     " Route"            105      110   40   45   15 ]
   [PUSHBUTTON     " Passage"          106      110   55   45   15 ]
   [PUSHBUTTON     " Background"       107      110   70   45   15 ]
   [GROUPBOX       " Sample"           108        5    5  100  100 ]
   [CTEXT                              109       10   14   89   87 ]

END-DIALOG

CREATE &temp 16 /ALLOT   \ rect update struct

: /xDIM+BORDER ( n -- )   X .PAGE @ OVER 2* 3 + / 2 MAX X .DIM !
   X .DIM @ * 2* X .DIM @ +  X .PAGE @ SWAP - 0 MAX 2/ X .OFF ! ;

: /yDIM+BORDER ( n -- )   Y .PAGE @ OVER 2* 3 + / 2 MAX Y .DIM !
   Y .DIM @ * 2* Y .DIM @ +  Y .PAGE @ SWAP - 0 MAX 2/ Y .OFF ! ;

: /DIMS+BORDER ( -- )   ROWS /yDIM+BORDER  COLS /xDIM+BORDER ;

: PAINT-MAZE-COLORS ( -- )
   hwndMAZE >R  MAZE-hDC >R  HWND 109 GetDlgItem TO hwndMAZE
   hwndMAZE GetDC TO MAZE-hDC  SAVE-MAZE-SIZE  'MAZE >R
   hwndMAZE &temp GetClientRect DROP  DIALOG-MAZE TO 'MAZE
   &temp 2 CELLS + 2@   X .PAGE !  Y .PAGE !  2 DUP TO ROWS  TO COLS
   /DIMS+BORDER  COLOR-DIALOG-BRUSHES  CLEAR-MAZE
   G.MAZE  GET-MAZE-SIZE  R> TO 'MAZE  CREATE-BRUSHES
   hwndMAZE MAZE-hDC ReleaseDC DROP
   R> TO MAZE-hDC  R> TO hwndMAZE ;

: UPDATE-DIALOG-MAZE ( -- )
   HWND 109 GetDlgItem  DUP 0 1 InvalidateRect DROP
   UpdateWindow DROP  PAINT-MAZE-COLORS ;

: PAINT.MAZE.COLORS ( -- )
   HWND PAD BeginPaint DROP  HWND PAD EndPaint DROP
   UPDATE-DIALOG-MAZE ;

: UPDATE-COLORS ( -- )   GET-COLORS  CREATE-BRUSHES
   hwndMAZE GCL_HBRBACKGROUND BRUSH .BACK @ SetClassLong DROP
   REDRAW-MAZE ;

: CHOOSE-COLOR ( n -- )   PICKCOLOR 1+ ?DUP IF
      1- OVER CELLS SAVED-COLORS + !
      UPDATE-DIALOG-MAZE
   THEN  DROP ;

: COLOR-CLOSE-DIALOG ( -- res )   HWND 0 EndDialog ;

[SWITCH COLOR-COMMANDS ZERO ( -- res )
   IDOK     RUN:  UPDATE-COLORS  COLOR-CLOSE-DIALOG ;
   IDCANCEL RUN:  COLOR-CLOSE-DIALOG ;
   101      RUN:  UPDATE-COLORS  0 ;
   102      RUN:  DEFAULT-COLORS  UPDATE-DIALOG-MAZE  0 ;
   103      RUN:  0 CHOOSE-COLOR  0 ;
   104      RUN:  1 CHOOSE-COLOR  0 ;
   105      RUN:  2 CHOOSE-COLOR  0 ;
   106      RUN:  3 CHOOSE-COLOR  0 ;
   107      RUN:  4 CHOOSE-COLOR  0 ;
SWITCH]

[SWITCH COLOR-MESSAGES ZERO
   WM_CLOSE      RUNS  COLOR-CLOSE-DIALOG
   WM_INITDIALOG RUN:  -1 ;
   WM_PAINT      RUN:  PAINT.MAZE.COLORS  0 ;
   WM_COMMAND    RUN:  WPARAM LOWORD COLOR-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD COLOR-MESSAGES ;  4 CB: RUN-COLORS

: MAZE-COLORS ( -- )   SAVE-COLORS
   HINST  (MAZE-COLORS)  HWND  RUN-COLORS
   0 DialogBoxIndirectParam DROP ;

{ ---------------------------------------------------------------------
Save and Open maze images.
--------------------------------------------------------------------- }

CREATE MAZE-FILTERS
   ,Z" Maze files (*.maz)"  ,Z" *.maz"
   ,Z" All files (*.*)"     ,Z" *.*"
   0 ,

CREATE "FILENAME   260 ALLOT  0 "FILENAME  !
CREATE "EXT        ,Z" maz"

   OFN_LONGNAMES
   OFN_HIDEREADONLY OR
CONSTANT DEFAULT-OFN-FLAGS

CLASS tagOFN
   VARIABLE lStructSize
   VARIABLE hwndOwner
   VARIABLE hInstance
   VARIABLE lpstrFilter
   VARIABLE lpstrCustomFilter
   VARIABLE nMaxCustFilter
   VARIABLE nFilterIndex
   VARIABLE lpstrFile
   VARIABLE nMaxFile
   VARIABLE lpstrFileTitle
   VARIABLE nMaxFileTitle
   VARIABLE lpstrInitialDir
   VARIABLE lpstrTitle
   VARIABLE Flags
  HVARIABLE nFileOffset
  HVARIABLE nFileExtension
   VARIABLE lpstrDefExt
   VARIABLE lCustData
   VARIABLE lpfnHook
   VARIABLE lpTemplateName
END-CLASS

tagOFN BUILDS OFN-TEMPLATE

: INIT-OFN ( -- )
   tagOFN SIZEOF OFN-TEMPLATE lStructSize !
   254           OFN-TEMPLATE nMaxFile !
   hwndMAZE      OFN-TEMPLATE hwndOwner !
   HINST         OFN-TEMPLATE hInstance !
   "EXT          OFN-TEMPLATE lpstrDefExt !
   MAZE-FILTERS  OFN-TEMPLATE lpstrFilter !
   "FILENAME 1+  OFN-TEMPLATE lpstrFile !
   "FILENAME OFF ;

: /OFN-TEMPLATE ( index ztitle flags -- )
   OFN-TEMPLATE Flags !
   OFN-TEMPLATE lpstrTitle !
   OFN-TEMPLATE nFilterIndex !  INIT-OFN ;

: X-OFN ( flags index ztitle -- addr n )
   ROT /OFN-TEMPLATE  OFN-TEMPLATE lStructSize GetOpenFileName IF
      "FILENAME 1+ ZLENGTH "FILENAME TUCK C!
   ELSE
      "FILENAME 256 + DUP OFF
   THEN  COUNT ;

: X-SFN ( flags index ztitle -- addr n )
   ROT /OFN-TEMPLATE  OFN-TEMPLATE lStructSize GetSaveFileName IF
      "FILENAME 1+ ZLENGTH "FILENAME TUCK C!
   ELSE
      "FILENAME 256 + DUP OFF
   THEN  COUNT ;

: INVALID-MAZE ( zstring -- flag )
   hwndMAZE SWAP Z" Maze file error!" MB_RETRYCANCEL
   MB_ICONWARNING OR MessageBox IDRETRY <> ;

: OPEN-MAZE ( handle -- )   >R
   PAD MAZE-VERSION ZLENGTH R@ READ-FILE THROW >R
   MAZE-VERSION DUP ZLENGTH 5 - PAD R> 5 - COMPARE THROW
   PAD #SAVED-COLORS R@ READ-FILE THROW
   #SAVED-COLORS - THROW  PAD SAVED-COLORS #SAVED-COLORS MOVE
   PAD #SAVED-SIZE R@ READ-FILE THROW
   #SAVED-SIZE - THROW  PAD SAVED-SIZE #SAVED-SIZE MOVE
   PAD #SAVED-POS R@ READ-FILE THROW
   #SAVED-POS - THROW  PAD SAVED-POS #SAVED-POS MOVE
   PAD 2 CELLS R@ READ-FILE THROW
   2 CELLS - THROW  PAD CURR-SQUARE 2 CELLS MOVE
   SAVED-SIZE @ TO ROWS  SAVED-SIZE 4 CELLS + @ TO COLS  /MAZE
   'MAZE #MAZE R@ READ-FILE THROW
   #MAZE - THROW  R> DROP ;

: $>Z ( caddr n buf -- buf )
   2DUP 2>R  SWAP MOVE  2R> TUCK + 0 SWAP C! ;

: OPEN-MAZE-FILE ( a n -- flag )
   -NAME PAD $>Z SetCurrentDirectory 0= IF
      Z" Invalid Directory" INVALID-MAZE  EXIT
   THEN  "FILENAME COUNT -PATH R/O OPEN-FILE IF
      Z" Can't Open File" INVALID-MAZE  EXIT
   THEN  DUP ['] OPEN-MAZE CATCH IF  DROP CLOSE-FILE DROP
      Z" Invalid Maze File" INVALID-MAZE DUP IF
         0 NEW-MAZE  UPDATE-MAZE  THEN  EXIT
   THEN  CLOSE-FILE DROP
   hwndMAZE WINDOW-POSITION TRUE MoveWindow 0<>
   GET-MAZE-SIZE  UPDATE-COLORS ;

: SAVE-MAZE ( handle -- )   >R
   MAZE-VERSION DUP ZLENGTH R@ WRITE-FILE THROW
   SAVE-COLORS SAVED-COLORS #SAVED-COLORS R@ WRITE-FILE THROW
   SAVE-MAZE-SIZE SAVED-SIZE #SAVED-SIZE R@ WRITE-FILE THROW
   SAVED-POS #SAVED-POS R@ WRITE-FILE THROW
   CURR-SQUARE 2 CELLS R@ WRITE-FILE THROW
   'MAZE #MAZE R@ WRITE-FILE THROW
   R> DROP ;

: SAVE-MAZE-FILE ( a n -- flag )
   -NAME PAD $>Z SetCurrentDirectory 0= IF
      PAD 0 CreateDirectory 0= IF
         Z" Can't Create Directory" INVALID-MAZE  EXIT
      THEN  PAD SetCurrentDirectory 0= IF
         Z" Invalid Directory" INVALID-MAZE  EXIT
   THEN  THEN  "FILENAME COUNT -PATH W/O CREATE-FILE IF
      Z" Can't Create File" INVALID-MAZE  EXIT
   THEN  DUP ['] SAVE-MAZE CATCH IF  2DROP
      Z" Can't Write to File" INVALID-MAZE  EXIT
   THEN  CLOSE-FILE DROP  TRUE ;

: MAZE-OPEN ( -- )   BEGIN
   DEFAULT-OFN-FLAGS OFN_FILEMUSTEXIST OR
   1 Z" Maze Input file"  X-OFN DUP WHILE
      OPEN-MAZE-FILE  UNTIL  ELSE  DROP  THEN ;

: MAZE-SAVE-AS ( -- )   BEGIN
   DEFAULT-OFN-FLAGS OFN_OVERWRITEPROMPT OR
   1 Z" Maze Output file"  X-SFN DUP WHILE
      SAVE-MAZE-FILE  UNTIL  ELSE  DROP  THEN ;

: MAZE-SAVE ( -- )  "FILENAME C@ IF
      "FILENAME COUNT SAVE-MAZE-FILE IF  EXIT
   THEN  THEN  MAZE-SAVE-AS ;

{ ---------------------------------------------------------------------
Drawing window management.
--------------------------------------------------------------------- }

[SWITCH KEYACTIONS DROP ( vkey -- )
   VK_UP     RUNS MOVE-ABOVE
   VK_DOWN   RUNS MOVE-BELOW
   VK_RIGHT  RUNS MOVE-RIGHT
   VK_LEFT   RUNS MOVE-LEFT
   VK_PRIOR  RUNS NEXT-MAZE
   VK_NEXT   RUNS PREV-MAZE
   VK_HOME   RUNS FRST-MAZE
   VK_ESCAPE RUN: HWND WM_CLOSE 0 0 PostMessage DROP ;
SWITCH]

[SWITCH MAZE-COMMANDS ZERO ( wparam -- )
   MAZE_ABOUT   RUNS ABOUT
   MAZE_FIT     RUNS TOGGLE-FIT-MAZE
   MAZE_COLOR   RUNS MAZE-COLORS
   MAZE_NEW     RUNS FRST-MAZE
   MAZE_OPEN    RUNS MAZE-OPEN
   MAZE_SAVE    RUNS MAZE-SAVE
   MAZE_SAVE-AS RUNS MAZE-SAVE-AS
   MAZE_EXIT    RUN: HWND WM_CLOSE 0 0 PostMessage DROP ;
SWITCH]

[SWITCH HSCROLL-COMMANDS ZERO ( nScrollCode -- )
   SB_BOTTOM        RUN:  X .MAX @ X .PAGE @ - !X.POS ;
   SB_ENDSCROLL     RUN:  ;
   SB_LINELEFT      RUN:  X .POS @ X .DIM @ 2* - !X.POS ;
   SB_LINERIGHT     RUN:  X .POS @ X .DIM @ 2* + !X.POS ;
   SB_PAGELEFT      RUN:  X .POS @ X .PAGE @ - !X.POS ;
   SB_PAGERIGHT     RUN:  X .POS @ X .PAGE @ + !X.POS ;
   SB_THUMBPOSITION RUN:  WPARAM HIWORD !X.POS ;
   SB_THUMBTRACK    RUN:  WPARAM HIWORD !X.POS ;
   SB_TOP           RUN:  0 !X.POS ;
SWITCH]

[SWITCH VSCROLL-COMMANDS ZERO ( nScrollCode -- )
   SB_BOTTOM        RUN:  Y .MAX @ Y .PAGE @ - !Y.POS ;
   SB_ENDSCROLL     RUN:  ;
   SB_LINEDOWN      RUN:  Y .POS @ Y .DIM @ 2* + !Y.POS ;
   SB_LINEUP        RUN:  Y .POS @ Y .DIM @ 2* - !Y.POS ;
   SB_PAGEDOWN      RUN:  Y .POS @ Y .PAGE @ + !Y.POS ;
   SB_PAGEUP        RUN:  Y .POS @ Y .PAGE @ - !Y.POS ;
   SB_THUMBPOSITION RUN:  WPARAM HIWORD !Y.POS ;
   SB_THUMBTRACK    RUN:  WPARAM HIWORD !Y.POS ;
   SB_TOP           RUN:  0 !Y.POS ;
SWITCH]

: DEF-PROC ( msg -- res )   HWND SWAP WPARAM LPARAM DefWindowProc ;
: STORE-POSITION ( -- )   HWND SAVED-POS GetWindowRect DROP  0 ;

[+SWITCH MAZE-MESSAGES
   MAZE_CREATE       RUN:  WPARAM LPARAM MAZE-STATE  0 ;
   MAZE_PAINT        RUN:  WPARAM LPARAM PAINT-MAZE  0 ;
   MAZE_REPAINT      RUN:  WPARAM LPARAM REPAINT-MAZE  0 ;
   WM_SIZE           RUN:  LPARAM HILO X .PAGE !  Y .PAGE !  /DIMS
                           /SCROLL-BARS  STORE-POSITION  0 ;
   WM_MOVE           RUN:  STORE-POSITION  0 ;
   WM_VSCROLL        RUN:  WPARAM LOWORD VSCROLL-COMMANDS  0 ;
   WM_HSCROLL        RUN:  WPARAM LOWORD HSCROLL-COMMANDS  0 ;
   WM_PAINT          RUN:  HWND TO hwndMAZE  PAINT.MAZE  0 ;
   WM_KEYDOWN        RUN:  WPARAM LOWORD KEYACTIONS  0 ;
   WM_COMMAND        RUN:  WPARAM LOWORD MAZE-COMMANDS  0 ;
   WM_CREATE         RUN:  HWND TO hwndMAZE  /MAZEWIN
                           /SCROLL-BARS  UPDATE-MAZE  0 ;
SWITCH]

[DEBUG
: WIN-PLAY ( -- )   RANDOM-WARMUP  GET-REGISTRY  0 NEW-MAZE
   CREATE-BRUSHES  CREATE-MAZE-CLASS TO MAZE-CLASS
   CREATE-MAZE-WINDOW DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP ;
DEBUG]

CR CR .( Type WIN-PLAY to run the graphic maze program. ) CR

{ --------------------------------------------------------------------
Windows main startup and executable generation.
-------------------------------------------------------------------- }

[DEFINED] PROGRAM-SEALED [IF]

: (WINMAIN)   WIN-PLAY  DISPATCHER DROP
   SAVE-REGISTRY  DELETE-BRUSHES ;

: WINMAIN   (WINMAIN)  0 ExitProcess ;

' WINMAIN 'MAIN !

-1 THRESHOLD

PROGRAM-SEALED Maze.exe

[THEN]
