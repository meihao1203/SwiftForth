{ ==========================================================================
Viewport management

Copyright (C) 2004  FORTH, Inc.

These routines will fail if the counters exceed 2^31-1

buffer geometry for tty

        |                             |
        |0                            |cols
      --+-----------------------------+------
    top |                             |    ^
        |                             |    |
        |       |vleft   |vleft+wide  |    |
        |     --+--------+----------  |    |
        |   vtop|        |   ^        |    |
        |       |        |   |        |    |
        |       |        | high       |    |
        |       |        |   |        |   rows
        |       |        |   v        |    |
        |       +--------+----------  |    |
        |       |        |  vtop+high |    |
        |       |<-wide->|            |    |
        |                             |    |
        |                             |    |
        |    (valid for exam)         |    |
        |                             |    v
      --+-----------------------------+------
    bot |                             |    t+rows
        |<------cols----------------->|
        |                             |


e = top + rows

x : [0..cols-1]
y : [0..2^31-1]
t : [0..2^31-1]

0 <= vleft < (cols-wide)
t <= vtop < (rows-high)

when y = e, the buffer must track via changing t

========================================================================== }

{ --------------------------------------------------------------------
These functions must maintain the overall buffer and the pointers
which regard the viewport on the buffer.  VY must track the progress
of Y and T; VX must track X, moving forth and back as X returns to 0.

Cursor positioning can only act in the realm of (0,0)=(0,VY)

TOP is the line number of the top of the buffer
BOT is the line number of the bottom of the buffer.
-------------------------------------------------------------------- }

: TOP ( -- n )   T @ ;
: BOT ( -- n )   T @ ROWS + ;

: VTOP ( -- n )   VY @ ;
: VLEFT ( -- n )   VX @ ;

: VRIGHT ( -- n )   VX @ WIDE @ + ;
: VBOT ( -- n )   VY @ HIGH @ + ;

: X ( -- x )   CX @ ;
: Y ( -- y )   CY @ ;

: BIGY ( y -- )   BIGGEST-Y @ MAX BIGGEST-Y ! ;

{ --------------------------------------------------------------------
Buffer address translations

XY>V translates from arbitrary xy to a virtual text address.
V>BUF translates from a virtual address to a real text address.
XY> translates from an arbitrary xy to a real text address.

>INK translates from a real text address to a real ink address.
V>INK translates from a virtual text address to a real ink address.
-------------------------------------------------------------------- }

: V>BUF ( vaddr -- bufaddr )   &VISIBLE AND 'DATA + ;

: XY>V ( x y -- vaddr )   COLS * + ;

: XY> ( x y -- addr )   XY>V V>BUF ;

: >INK ( addr -- addr )   |VISIBLE| + ;
: V>INK ( vaddr -- addr )   V>BUF >INK ;

: VC@ ( vaddr -- char )   V>BUF C@ ;

: 'CURSOR ( -- addr )   X Y XY> ;
: 'INK ( -- addr )   'CURSOR >INK ;

{ --------------------------------------------------------------------
FRAMEX and FRAMEY adjust VX and VY so that the cursor is visible.

+T  srolls the virtual top of viewport down, blanking the newly
   exposed line.

+Y moves the cursor vertically one line at a time, scrolling the
   viewport. FRAMEY makes sure the cursor is visible when done.

+X moves the cursor horizontally, wrapping to the next line if
   needed. FRAMEX makes sure the cursor is visible when done.
-------------------------------------------------------------------- }

: FRAMEX ( -- )
   X VLEFT < IF  X VX !  EXIT  THEN
   X VRIGHT < NOT IF  X WIDE @ - 1+ VX ! THEN ;

: FRAMEY ( -- )
   Y VTOP < IF  Y VY !  EXIT  THEN
   Y VBOT < NOT IF  Y HIGH @ - 1+ VY !  THEN ;

: FRAMED ( -- )   FRAMEX FRAMEY ;

: +T ( n -- )   0 MAX  BEGIN
      0 TOP XY>  DUP
      COLS BLANK  >INK COLS ERASE
   ?DUP WHILE  1-  T ++  PY ++ REPEAT ;

: +Y ( n -- )
   Y + TOP MAX  DUP BIGY  CY ! BEGIN Y BOT < NOT WHILE 1 +T REPEAT ;

: +X ( n -- )
   X +  0 MAX  COLS /MOD +Y CX ! ;

{ --------------------------------------------------------------------
pan moves the viewport by an x,y increment
   for instance, moving it to 0 0 puts it as high and left as possible.
-------------------------------------------------------------------- }

: PANTO ( x y -- )
   BOT HIGH @ - MIN  TOP MAX  VY !
   COLS WIDE @ - MIN  0 MAX  VX !  ;

: PAN ( dx dy -- )
   VTOP +  SWAP  VLEFT +  SWAP  PANTO ;

{ --------------------------------------------------------------------
INDEXED-COLORS sets a color scheme based on a color table index.

NEWCOLOR helps to minimize the windows calls to change text colors.
   The cells at COLOR contain current and last required color.

DISPLAY-STRING writes a string on the HDC at the cursor position.

PUT-STRING writes a string to the display and the buffer, updates
   the ink data, and advances the cursor.
-------------------------------------------------------------------- }

: INDEXED-COLORS ( hdc index -- )   CELLS  2DUP
   'FOREGROUNDS + @ SetTextColor DROP
   'BACKGROUNDS + @ SetBkColor DROP ;

: NEWCOLOR ( -- )
   COLOR 2@ <> IF
      HDC COLOR @ INDEXED-COLORS  COLOR @+ !+ DROP
   THEN ;

: DISPLAY-STRING ( addr len -- )   2>R  NEWCOLOR
   HDC  X VLEFT - CHARW @ *  XMARGIN + Y VTOP  - CHARH @ * YMARGIN +
   2R> TextOut DROP ;

: PUT-STRING ( addr len -- )   2DUP DISPLAY-STRING
   'INK OVER COLOR @ FILL  TUCK  'CURSOR SWAP CMOVE  +X ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: ?RECORDS ( addr len -- addr len )
   HRECORDER @ IF
      2DUP HRECORDER @ WRITE-FILE DROP
   THEN ;

: RECORD-CR ( -- )
   HRECORDER @ IF
      13 SP@ 1 HRECORDER @ WRITE-FILE 2DROP
   THEN ;

: RECORD-LF ( -- )
   HRECORDER @ IF
      10 SP@ 1 HRECORDER @ WRITE-FILE 2DROP
   THEN ;

{ --------------------------------------------------------------------
PUTCR moves the cursor to the left margin,
PUTLF moves the cursor down one line, and
PUTCRLF moves the cursor down and left.

PUTBS moves the cursor to the left, but not past the edge.

#RIGHT is how many columns are to the right of the cursor.

PUTS writes a string on the display and buffer, never writing more
   than the current line at one time.

WRAPS writes a string, but wraps at the right visible edge.

PUTC writes a single character, any character.

PUTCHAR traps CR, LF, BS; otherwise writes the character.
-------------------------------------------------------------------- }

: PUTCR ( -- )   RECORD-CR  X NEGATE +X ;
: PUTLF ( -- )   RECORD-LF  1 +Y ;

: PUTCRLF ( -- )   PUTCR PUTLF ;

: PUTBS ( -- )   -1 +X ;

: #RIGHT ( -- n )   COLS X - ;

: PUTS ( addr len -- )   ?RECORDS
   BEGIN  DUP WHILE  ( a n)
      #RIGHT DIVIDE ( right n left n) PUT-STRING
   REPEAT 2DROP ;

: WRAPS ( addr len -- flag )
   2>R  VRIGHT  R@ 2 + X + < 2R> 2 PICK IF PUTCRLF THEN PUTS ;

: PUTC ( char -- )   SP@ 1 PUTS DROP ;

: PUTCHAR ( char -- )   CASE
   13 OF  PUTCR  ENDOF
   10 OF  PUTLF  ENDOF
    8 OF  PUTBS  ENDOF
      DUP PUTC
   ENDCASE ;

{ --------------------------------------------------------------------
Cursor position

!XY moves the cursor on the visible screen, and
@XY returns the cursor position on the visible screen.

?XY returns true if the xy specified is already visible.

PUT-PAGE clears the screen and positions the cursor at upper left.

MORE-LINES clears N lines below the bottom of the current screen.
This is used during a screen resize operation.
-------------------------------------------------------------------- }

: PUT-PAGE ( -- )
   CX OFF  VX OFF  BIGGEST-Y @ 1+ >R
   R@ CY !  R@ PY !  R@ VY !
   HIGH @ 1+ 0 ?DO PUTCRLF LOOP
   R@ CY !  R@ VY ! R> BIGGEST-Y ! ;

: EXPAND-Y ( line -- )
   DUP BIGGEST-Y @ < IF DROP EXIT THEN
   X >R  Y >R  PY @ >R
   BIGGEST-Y @ DUP CY !  ?DO  PUTCRLF  LOOP
   R> PY ! R> CY !  R> CX ! ;

: !XY ( x y -- )
   0 MAX  ROWS 1- MIN  PY @ +
   DUP BIGGEST-Y @ > IF  DUP EXPAND-Y  THEN  CY !
   0 MAX  COLS 1- MIN  CX ! ;

: @XY ( -- x y )
   X Y PY @ - ROWS 1- MIN ;

{ --------------------------------------------------------------------
Produce text on demand
-------------------------------------------------------------------- }

: NEXT-LINE ( -- zaddr )
   GLINE @ GEND @ <= IF
      0 GLINE @ XY> COLS -TRAILING 'TEXTBUF ZPLACE
      1 GLINE +!  'TEXTBUF
   ELSE 0 THEN ;

: FIRST-LINE ( -- zaddr )
   TOP GLINE !  BIGGEST-Y @ GEND !  NEXT-LINE ;

{ --------------------------------------------------------------------
/RECORDING returnS zero if recording is off, non-zero if on.
-------------------------------------------------------------------- }

: RECORDING/ ( -- )
   HRECORDER @ ?DUP IF CLOSE-FILE DROP THEN  HRECORDER OFF ;

: /RECORDING ( zstr -- ior )
   ZCOUNT R/W CREATE-FILE ( h ior)
   IF DROP 0 ELSE DUP THEN HRECORDER ! ;
