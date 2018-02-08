{ ==========================================================================
Vbuf data

Copyright (C) 2004  FORTH, Inc.

Buffers are defined by contained variables, like user variables.

========================================================================== }

{ --------------------------------------------------------------------
The nature of a reusable dll defining windows is that we have to
create window local data for each instantiation of a window.

Here we accomplish this by allocating all the persistent data required
by a window when the window is created, and associating the address
of the allocated data to the window via the property scheme.

On callback entry, we retrieve the address and put it into the
user variable 'VBUF.

PSTRUCT is a paint structure used during the callback.  Because
the user area is per callback, this is unique on each callback and
reentrant.  It does not need to be persistent.
-------------------------------------------------------------------- }

#USER
   CELL +USER 'VBUF
      0 +USER PSTRUCT
   CELL +USER PS.DC
   CELL +USER PS.ERASEBK
   CELL +USER PS.X
   CELL +USER PS.Y
   CELL +USER PS.CX
   CELL +USER PS.CY
   CELL +
   CELL +
   32   +

TO #USER

{ --------------------------------------------------------------------
Having defined a scheme for managing window-local persistent data,
we have to define the access method.

VAR defines fields in the persistent data, pointed to by 'VAR.

+VAR allows simple allocation of space by VAR.
-------------------------------------------------------------------- }

: VAR ( u -- )   CREATE , DOES> ( -- addr )   @ 'VBUF @ + ;

: +VAR ( u1 len -- u2)   OVER VAR + ;

{ --------------------------------------------------------------------
Persistent data for windows
-------------------------------------------------------------------- }

0
     CELL +VAR T                \ top line index
     CELL +VAR CX               \ cursor x and
     CELL +VAR CY               \ y position, for caret

     CELL +VAR VX               \ viewport x and
     CELL +VAR VY               \ y origin, for paint

     CELL +VAR WIDE             \ viewport width
     CELL +VAR HIGH             \ and height, in chars

     CELL +VAR RX0
     CELL +VAR RY0
     CELL +VAR WINW
     CELL +VAR WINH             \ pixel size of window

     CELL +VAR CHARH            \ how tall and
     CELL +VAR CHARW            \ how wide a character is

     CELL +VAR HFONT            \ handle of font for display

     CELL +VAR DC               \ hold the dc for drawing

     CELL +VAR DIRTY            \ text added to control
     CELL +VAR IN-SCROLLBACK    \ has true when scrollback is active
     CELL +VAR HIDDEN-CARET     \ update caret soon
     CELL +VAR MARKING
     CELL +VAR HAVE-FOCUS

     CELL +VAR INSERTING        \ has insert flag for text

  2 CELLS +VAR ICARET           \ caret sizes, fat is overstrike
  2 CELLS +VAR OCARET           \ thin is insert

     CELL +VAR KEYMODE          \ true means return all keyboard events
     CELL +VAR HEAD
     CELL +VAR TAIL
      512 +VAR KEYBUF           \ nasty constant, fix here and EKEY.F

  2 CELLS +VAR COLOR            \ index to the current color; last color used.
     CELL +VAR BKBRUSH          \ brush for background
     CELL +VAR BKCOLOR          \ index to current background color

     CELL +VAR WINHANDLE

  2 CELLS +VAR 'COPY            \ address where to copy data to (end, start)
     CELL +VAR HCOPY            \ handle of copy memory
     CELL +VAR 'PASTE           \ address where to read data from
     CELL +VAR HPASTE           \ handle of paste memory

     CELL +VAR MX
     CELL +VAR MY
     CELL +VAR MARK-BEGIN       \ upper left
     CELL +VAR MARK-END         \ and lower right of marking rectangle
     CELL +VAR MARK-ANCHOR      \ original click location, ie the anchor

     CELL +VAR RB-PRESS         \ holding spot for right button press data

     CELL +VAR PY               \ top of page

     CELL +VAR OLDVX
     CELL +VAR OLDVY
     CELL +VAR OLDWIDE
     CELL +VAR OLDHIGH

     256 +VAR WORD-BUF          \ clipboard text buffer

     CELL +VAR HRECORDER        \ handle for recording

     CELL +VAR BIGGEST-Y
     CELL +VAR GLINE            \ last to make easy view
     CELL +VAR GEND

CONSTANT |PARAMS|

{ --------------------------------------------------------------------
A few simple macros for common data.

HDC returns the DC. This depends on the class of the window having
the CS_OWNDC attribute.

CARETSIZE returns caret size information based on the insert flag.
-------------------------------------------------------------------- }

: HDC ( -- dc )   DC @ ;

: CARETSIZE ( -- width height )
   INSERTING @ IF ICARET ELSE OCARET THEN 2@ ;

{ --------------------------------------------------------------------
The text buffer is a fixed array in memory.

ROWS and COLS (defined in app.f) define the size of the buffer, and
|VISIBLE| is the total size of the text buffer.  Note that the buffer
itself is double the apparent size -- the other |VISIBLE| allocation
is used to hold color information on a per-character basis.
-------------------------------------------------------------------- }

ROWS COLS * CONSTANT |VISIBLE|          \ must be a power of 2
|VISIBLE| 1- CONSTANT &VISIBLE          \ mask for buffer wrap

{ --------------------------------------------------------------------
Total allocations.

Parameters, color map, text, ink.

Note that the color data must follow the text data immediately
so that INK can get the correct address in color for any address
in data.
-------------------------------------------------------------------- }

0
   |PARAMS| +VAR 'PARAMS        \ this is where the variables go
    COLS 2+ +VAR 'TEXTBUF       \ a one-line text buffer
 |COLORMAP| +VAR 'FOREGROUNDS   \ foreground and
 |COLORMAP| +VAR 'BACKGROUNDS   \ background colors
  |VISIBLE| +VAR 'DATA          \ visible screen
  |VISIBLE| +VAR 'ATTR          \ visible screen's attribute data
CONSTANT |VBUF|

{ --------------------------------------------------------------------
System interface to per-window property values

"BUFNAME" is the string for getting the property containing the
buffer address. It is factored so that the actual name only
appears once, ie a constant.

VBUF-ENTRY sets the user variable on callback entry.

/VBUF creates the buffer and sets the property, and VBUF/ destroys
it. The callback's user variable 'VBUF is set here and on each callback
entry; on vbuf initialization we also set the interactive operator's
copy of 'VBUF so he can get to the frame variables which define tty.
-------------------------------------------------------------------- }

: "BUFNAME" ( -- zstr )
   Z" VBUF" ;

: VBUF-ENTRY ( -- addr )
   HWND "BUFNAME" GetProp DUP 'VBUF ! ;

: /VBUF ( -- )
   HWND "BUFNAME"  |VBUF| ALLOCATE DROP
   DUP 'VBUF !  DUP OPERATOR 'VBUF HIS !
   SetProp DROP ;

: VBUF/ ( -- )
   HWND "BUFNAME" GetProp FREE DROP  HWND "BUFNAME" RemoveProp DROP ;

{ --------------------------------------------------------------------
/COLORS initializes the vbuf data from the default color tables.

NEW initializes buffer data and clears the text area without
disturbing things like the selected font and colors.

/VVARS initializes everything.
-------------------------------------------------------------------- }

: 'XCOLOR ( n -- offset )
   #COLORS 1- MIN 0 MAX  CELLS ;


: /COLORS ( -- )
   WHITE 'BACKGROUNDS !  BLACK 'FOREGROUNDS ! ;

: NEW ( -- )
   T OFF  PY OFF  VY OFF  VX OFF  CX OFF  CY OFF   BIGGEST-Y OFF
   HEAD OFF  TAIL OFF  DIRTY OFF  IN-SCROLLBACK OFF
   -1 DUP MARK-ANCHOR !  DUP MARK-BEGIN !  MARK-END !
   1 0 COLOR 2!  0 HRECORDER !
   'DATA |VISIBLE| BL FILL
   'ATTR |VISIBLE| COLOR @ FILL ;

: /VVARS ( -- )
   HFONT OFF  INSERTING ON
   /COLORS 0 COLOR ! -1 BKCOLOR !
   NEW ;

{ --------------------------------------------------------------------
margins are made around the window so that text is not slam
against the borders
-------------------------------------------------------------------- }

3 CONSTANT XMARGIN
3 CONSTANT YMARGIN
