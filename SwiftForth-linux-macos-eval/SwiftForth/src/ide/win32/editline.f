{ ====================================================================
Command line editor

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

Enhancements:
1) Allow up/down arrow keys to invoke auto-complete if not at line start.
2) Save all lines 1 or more chars long into history buffer.
3) Ctl Shift Del = Delete to End of Line
4) Ctl Home = Show History
5) F3 = Append Last to EOL (ala DOS)
6) Auto-complete comparison is now case-insensitive.
7) Fixed a few zero length bugs (ie DO >> ?DO).

Future:
1) If new line exists in history, delete old entry

==================================================================== }

?( Command line editor)

DEFER TOGGLE-BROWSER

PACKAGE ACCEPTOR

{ ------------------------------------------------------------------------
ACCEPT  The built-in function is very simple -- it responds to only
the backspace, escape, and carriage return controls.

Backspace does the obvious, moving the cursor backwards until it
reaches the beginning of the line.

Escape kills all characters in the current line.

Carriage return ends the input, leaving the number of characters
accepted on the stack.
------------------------------------------------------------------------ }

{ --------------------------------------------------------------------
Line Buffering

Text is managed in a buffer LBUF of packed strings.  Each new
string is added to the beginning by PUSHLINE, and the oldest strings
will simply fall off the end.

We index the array of strings via NTH-LINE, which returns the
address and length of the Nth string, and #LBUF which counts
the strings in the buffer.

CLAMP-LINE  will guarantee that a specified line is valid.
HISTORY  displays the most recent N lines in LBUF.
------------------------------------------------------------------------ }

8192 CONSTANT |LBUF|

0 VALUE LBUF

: /LBUFFER    |LBUF| ALLOCATE THROW TO LBUF  LBUF |LBUF| ERASE ;

/LBUFFER

{ --------------------------------------------------------------------
Lines in the line buffer

PUSHLINE places string addr u at the head of the buffer if it isn't
already there.

-LBUF is true if the string starting at the address is not complete in
LBUF. This is important because strings can be pushed off the end of
the buffer.

NTH-LINE returns addr and len of the Nth line in the buffer.

#LBUF is how many complete strings are in the buffer.
-------------------------------------------------------------------- }

: PUSHLINE ( addr u -- )
   DUP 0> IF
      2DUP LBUF COUNT COMPARE(CS) IF
         LBUF                           \ a n l
         OVER LBUF + 1+                 \ a n l l'
         |LBUF| FOURTH 1+ -             \ a n l l' n'
         CMOVE>                         \ a n
         LBUF PLACE  EXIT
   THEN THEN  2DROP ;

: -LBUF ( a -- flag )
   COUNT +  LBUF |LBUF| + < NOT ;

: NTH-LINE ( n -- addr n )
   LBUF SWAP   0 ?DO ( a)
      DUP -LBUF IF 0 UNLOOP EXIT THEN
      COUNT +
   LOOP COUNT ;

: #LBUF ( -- n )
   0  LBUF BEGIN ( a)
      DUP C@ WHILE
      DUP -LBUF 0= WHILE
      COUNT +  SWAP 1+ SWAP
   REPEAT THEN DROP ;

{ --------------------------------------------------------------------
THELINE holds the current consideration line when reviewing the
   contents of the line buffer.

CLAMP-LINE translates line numbers into guaranteed valid range.

GET-LINE sets the consideration line up and returns it.

+LINE moves +/- n lines from the current consideration line.

.HISTORY prints the top N items in the line buffer.

TYPE-KEYBOARD-HISTORY prints the entire line buffer.
-------------------------------------------------------------------- }

VARIABLE THELINE        \ 0..n where n is variable
VARIABLE RECALLED?
VARIABLE RECALLING?

: CLAMP-LINE ( n -- n )
   #LBUF ?DUP IF
      >R BEGIN ( n)
         DUP 0 R@ WITHIN NOT WHILE
         DUP 0< IF R@ + ELSE R@ - THEN
      REPEAT R> DROP
   THEN ;

: GET-LINE ( n -- addr n )
   CLAMP-LINE  DUP THELINE !  NTH-LINE ;

: +LINE ( n -- addr n )
   THELINE @ + GET-LINE ;

PUBLIC

: .HISTORY ( n -- )
   #LBUF MIN
   1- 0 MAX 0 SWAP ?DO
      CR I NTH-LINE TYPE
   -1 +LOOP CR ;

: TYPE-KEYBOARD-HISTORY ( -- )   #LBUF .HISTORY ;

PRIVATE

{ --------------------------------------------------------------------
Initialize, save
-------------------------------------------------------------------- }

LIBRARY KERNEL32

FUNCTION: CreateDirectory ( lpPathName lpSecurityAttributes -- b )

: SAVE-LBUF ( -- )
   #LBUF IF  S" USERPROFILE" FIND-ENV IF  R-BUF  2DUP R@ ZPLACE
      S" \Application Data\ForthInc" R@ ZAPPEND  R@ 0 CreateDirectory DROP
      S" \SwiftForth_history.dat" R@ ZAPPEND  R> ZCOUNT R/W CREATE-FILE
      0= IF  >R  LBUF |LBUF| R@ WRITE-FILE DROP  R@ CLOSE-FILE DROP  R>
   THEN DROP  THEN 2DROP  THEN ;

: RESTORE-LBUF ( -- )
   S" USERPROFILE" FIND-ENV IF  R-BUF  2DUP R@ PLACE
      S" \Application Data\ForthInc\SwiftForth_history.dat" R@ APPEND
      R> COUNT R/O OPEN-FILE 0= IF  >R
      LBUF |LBUF| R@ READ-FILE 2DROP  R@ CLOSE-FILE DROP  R>
   THEN DROP  THEN 2DROP ;

:ONENVLOAD ( -- )
   /LBUFFER  RESTORE-LBUF ;

:ONENVEXIT ( -- )
   SAVE-LBUF ;

{ --------------------------------------------------------------------
Input pattern matching is convenient. Look thru history for a string
whose beginning matches the given string.
-------------------------------------------------------------------- }

CREATE PATTERN   256 /ALLOT

: /COMPLETE ( a n # -- a n # )
   THIRD PATTERN COUNT TUCK COMPARE(NC)
   PATTERN C@ 0=  OR  IF  THIRD OVER PATTERN PLACE
   -1 THELINE !  THEN ;

: REPATTERN ( a n # -- a n # )
   THIRD OVER PATTERN PLACE
   -1 THELINE ! ;

{ ------------------------------------------------------------------------
Line Editing

The functions associated with editing a line involve moving a cursor
around, redisplaying text, and overstriking or inserting new characters
into the buffer.

The functions with the A- prefix implement the accept editor.  They
(mostly) expect the address and length (A N) of the buffer to edit,
and the current position (#) of the cursor in the buffer.

Input is finished when the cursor position is negative.
------------------------------------------------------------------------ }

VARIABLE INSERTING      \ 0=overstrike, nonzero=insert

CONFIG: INSERTING ( -- addr len )   INSERTING CELL ;

: SET-CARET ( -- )
   INSERTING @ PHANDLE TtyCaretMode DROP ;

CONSOLE-WINDOW +ORDER

: .INSERTING ( -- )
   INSERTING @ IF S" ins" ELSE S" ovr" THEN 5 SF-STATUS PANE-TYPE ;

CONSOLE-WINDOW -ORDER

: A-TOGGLE-INSERT ( a n # -- a n # )
   INSERTING @ 0= INSERTING !  SET-CARET .INSERTING ;

:ONENVLOAD ( -- )   SET-CARET  .INSERTING ;

: TOGGLE-INSERT ( -- )
   OPERATOR'S A-TOGGLE-INSERT ;

' TOGGLE-INSERT  SBLHITS 5 CELLS + !

{ --------------------------------------------------------------------
TAIL returns the original string plus the addr/len of its tail.

-------------------------------------------------------------------- }

: TAIL ( a n # -- a n # a' n' )
   3DUP /STRING ;

{ --------------------------------------------------------------------
A-SPREAD inserts a single character gap in the given string at the
   offset # .  The end of the string goes to the bit bucket.

A-TUCK removes the character at offset # .  The end of string is
   filled with a blank.
-------------------------------------------------------------------- }

: A-SPREAD ( a n # -- )
   TUCK  - 1-  0 MAX  -ROT  + DUP 1+  ROT CMOVE> ;

: A-TUCK ( a n # -- )   3DUP
   TUCK  - 1-  0 MAX  -ROT  + DUP 1+ SWAP ROT CMOVE
   DROP + 1-  BL SWAP C! ;

: A-LEFT ( a n # -- a n # )
   DUP IF 1- 8 EMIT THEN ;

: A-LEFTDEL ( a n # -- a n # )
   DUP IF  1-  8 EMIT  BL EMIT  8 EMIT  THEN ;

: A-RIGHT ( a n # -- a n # )
   2DUP > IF  THIRD OVER + C@ EMIT 1+ THEN ;

: A-LEFTWORD ( a n # -- a n # )
   A-LEFT BEGIN
      DUP WHILE
      THIRD OVER + C@ BL = WHILE
      A-LEFT
   REPEAT THEN
   BEGIN
      DUP WHILE
      THIRD OVER + C@ BL <> WHILE
      A-LEFT
   REPEAT THEN
   DUP IF A-RIGHT THEN  REPATTERN ;

: A-RIGHTWORD ( a n # -- a n # )
   THIRD THIRD -TRAILING NIP >R ( max)  BEGIN
      DUP R@ < WHILE
      THIRD OVER + C@ BL <> WHILE
      A-RIGHT
   REPEAT THEN
   BEGIN
      DUP R@ < WHILE
      THIRD OVER + C@ BL = WHILE
      A-RIGHT
   REPEAT THEN
   R> DROP REPATTERN ;

: A-HOME ( a n # -- a n 0 )
   BEGIN DUP WHILE A-LEFT REPEAT ;

: A-END ( a n # -- a n # )
   THIRD THIRD -TRAILING NIP BEGIN ( a n # x)
      2DUP <> WHILE
      2DUP < IF    >R A-RIGHT R>
             ELSE  >R A-LEFT  R> THEN
   REPEAT DROP ;

: A-CR ( a n # -- a n # )
   3DUP A-END -ROT 2DROP MAX  NIP -1 ;

\ the string is the text remaining to eol
\ cursor is in the place where the char was just deleted (from a-delete)
\ remember where we are (xy1)
\ type text, which leaves cursor at (xy2)
\ position at start of line (xy3) to force screen realignment
\ position back at (xy1) to set cursor position

: A-TYPE< ( a n -- )
  ?DUP IF
     GET-XY ( xy1)
     2SWAP -TRAILING TYPE S"  " TYPE 
     0 OVER ( xy3) AT-XY ( xy1) AT-XY
     EXIT
   THEN DROP ;

: A-DELETE ( a n # -- a n # )
   3DUP A-TUCK  TAIL A-TYPE< ;

: A-BACKSPACE ( a n # -- a n # )
   DUP IF
      INSERTING @ IF
         A-LEFT A-DELETE
      ELSE
         A-LEFTDEL  TAIL DROP BL SWAP C!
      THEN
   THEN  REPATTERN ;

: A-ESCAPE ( a n # -- a n # )
   BEGIN  DUP WHILE  A-LEFT  REPEAT DROP
   2DUP BLANK  GET-XY 2>R  2DUP TYPE   2R> AT-XY   0 ;

: A-OVERSTRIKE ( a n # char -- a n # )
   >R  2DUP > IF ( a n #)
      THIRD OVER + R@ SWAP C!  R@ EMIT  1+
   THEN R> DROP ;

: A-INSERT ( a n # char -- a n # )
   >R  2DUP > IF
      3DUP A-SPREAD  TAIL DROP R@ SWAP C!  R@ EMIT  1+
      TAIL -TRAILING A-TYPE<
   THEN R> DROP ;

: A-REPLACE ( a n # a n -- a n # )
   2>R A-ESCAPE 2R> BOUNDS ?DO
      I C@ A-OVERSTRIKE
   LOOP  A-HOME A-END ;

: A-RECALL-UP ( a n # -- a n # )
   #LBUF -EXIT   1 +LINE A-REPLACE ;

: A-RECALL-DOWN ( a n # -- a n # )
   #LBUF -EXIT  -1 +LINE A-REPLACE ;

: A-MATCH-LINE?  ( a n # -- a n # flag )  \ True = Match
   THELINE @ NTH-LINE   PATTERN COUNT  ROT MIN TUCK COMPARE(NC) 0= ( Match? ) ;

: A-LINE-REPLACE  ( a n # -- a n # )
   THELINE @ NTH-LINE  A-REPLACE ;

: A-COMPLETE  ( a n # -- a n # )
   /COMPLETE
   #LBUF 0
   ?DO  THELINE @ 1+ #LBUF OVER U> AND THELINE !
      A-MATCH-LINE?
      IF  A-LINE-REPLACE  UNLOOP EXIT  THEN
   LOOP ;

: -A-COMPLETE ( a n # -- a n # )
   /COMPLETE  THELINE @ 0 MAX THELINE !
   #LBUF 0
   ?DO  #LBUF 1- THELINE @ ?DUP IF  1- NIP THEN THELINE !
      A-MATCH-LINE?
      IF  A-LINE-REPLACE  UNLOOP EXIT  THEN
   LOOP ;

: A-UP-ARROW   ( a n # -- a n # )
   DUP RECALLING? @ NOT AND IF
   A-COMPLETE  RECALLED? OFF  EXIT  THEN
   A-RECALL-UP  RECALLED? ON ;

: A-DN-ARROW   ( a n # -- a n # )
   DUP RECALLING? @ NOT AND IF
   -A-COMPLETE  RECALLED? OFF  EXIT  THEN
   A-RECALL-DOWN  RECALLED? ON ;

: A-SHOW-HIST  ( a n # -- a n # )  A-ESCAPE  10 .HISTORY ;

: A-DEL-EOL  ( a n # -- a n # )
   R-BUF THIRD OVER R@ PLACE R> COUNT A-REPLACE ;

: A-APPEND-LAST  ( a n # -- a n # )
   A-DEL-EOL
   0 NTH-LINE THIRD /STRING 0 MAX BOUNDS
   ?DO  I C@ A-OVERSTRIKE  LOOP  REPATTERN ;

: A-LEFT-REPAT       ( a n # -- a n # )  A-LEFT      REPATTERN ;
: A-RIGHT-REPAT      ( a n # -- a n # )  A-RIGHT     REPATTERN ;
: A-END-REPAT        ( a n # -- a n # )  A-END       REPATTERN ;

: CHARACTER ( a n # char -- a n # )
   INSERTING @ IF A-INSERT ELSE A-OVERSTRIKE THEN ;

{ ------------------------------------------------------------------------
Line Editing Functions

Control characters mapped are:
   cr           end input
   bs           destroy last character typed
   esc          destroy current line
   tab          completion
   null         destroy current line, enter interpreter mode

Extended characters mapped are:
   del          delete character under the cursor
   left arrow   move cursor left
   right arrow  move cursor right
   home         move cursor to start of line
   end          move cursor to end of line
   ins          toggle insert mode
   up arrow     replace current line with most recent line
   down arrow   replace current line with oldest line
   ctrl home    display 10 most recent lines

------------------------------------------------------------------------ }

: A-FRESH ( a n # -- a n # )
   POSTPONE [  A-ESCAPE ;

[SWITCH CONTROL DROP ( a n # echar -- a n # )
         8 RUNS A-BACKSPACE
        13 RUNS A-CR
        27 RUNS A-ESCAPE
         0 RUNS A-FRESH
        10 RUNS NOOP
         9 RUNS A-COMPLETE
   $01002E RUNS A-DELETE
   $010025 RUNS A-LEFT-REPAT
   $010027 RUNS A-RIGHT-REPAT
   $010024 RUNS A-HOME
   $010023 RUNS A-END-REPAT
\  $010026 RUNS A-RECALL-UP
\  $010028 RUNS A-RECALL-DOWN
   $010026 RUNS A-UP-ARROW
   $010028 RUNS A-DN-ARROW
   $01002D RUNS A-TOGGLE-INSERT
   $030025 RUNS A-LEFTWORD
   $030027 RUNS A-RIGHTWORD
   $030024 RUNS A-SHOW-HIST    \ Ctl Home
   $07002E RUNS A-DEL-EOL      \ Ctl Shift Del
   $010072 RUNS A-APPEND-LAST  \ F3 - Append Last to EOL (ala DOS)
   $01007B RUNS TOGGLE-BROWSER \ F12 - Toggle Word Browser
SWITCH]

DEFER >HISTORY   ' 2DROP IS >HISTORY

: ESTROKE  ( a n # echar -- a n # )
   DUP 32 256 WITHIN IF  CHARACTER REPATTERN  ELSE  CONTROL  THEN ;

: ~ACCEPT~  ( a n -- n )
   -1 THELINE !  PATTERN OFF
   2DUP BLANK  0 BEGIN ( a n # )
      AKEY
      RECALLED? @ RECALLING? !  RECALLED? OFF
      ESTROKE
      RECALLED? @ RECALLING? !
   DUP 0< UNTIL DROP ;

: E-ACCEPT  ( a n -- n )
   ~ACCEPT~  TUCK  2DUP >HISTORY   PUSHLINE ;

' E-ACCEPT IS (ACCEPT)

PUBLIC

: CONSOLE-ACCEPT  ( a n -- n )  ~ACCEPT~  ;

PRIVATE

END-PACKAGE
