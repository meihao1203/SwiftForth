{ ==========================================================================
Repaint window

Copyright (C) 2004  FORTH, Inc.

Repaint is the hardest thing to manage correctly in TTY!

========================================================================== }

{ --------------------------------------------------------------------
Measurements

MEASURED counts consective characters starting at addr given a maximum
length to measure over.  It returns the length of the string of
consective characters, and the character itself as an index.

This is used to calculate the length of a string of any given color
by measuring the color data corresponding to a text address.

MEASURE-MARKS is similar to MEASURED, but allows the mark begin and
end addresses to over-ride what is considered to be consecutive.
So, if a string of characters has only one color, but the mark begins
or ends or encloses it entirely, the normally specified color attribute
is ignored and the mark attribute is returned instead.

MarkedTextOut parallels the TextOut function of windows, but 1) uses
a virtual buffer address instead of a physical address and 2) accounts
for both color data and selected text in the buffer.
-------------------------------------------------------------------- }

CODE MEASURED ( len addr -- index n )
   EBX EDX MOV                  \ save addr
   0 [EBP] ECX MOV              \ ebx = addr, ecx = len
   EAX EAX XOR                  \ eax =
   0 [EBX] AL MOV               \ reference byte
   BEGIN
      ECX ECX OR  0<> WHILE
      ECX DEC  EBX INC
      0 [EBX] AL CMP 0<>
   UNTIL THEN
   EDX EBX SUB
   EAX 0 [EBP] MOV
   RET  END-CODE

: MEASURE-MARKS ( addr len -- index n )
   OVER MARK-END @ U< NOT IF            \ entire string after mark
      SWAP V>INK MEASURED EXIT THEN

   2DUP + MARK-BEGIN @ U> NOT IF        \ entire string before mark
      SWAP V>INK MEASURED EXIT THEN

   OVER MARK-BEGIN @ U< IF              \ part is before mark
      DROP MARK-BEGIN @ OVER - SWAP V>INK MEASURED EXIT THEN

   ( a n)  MARK-END @ ROT - MIN 0 MAX 1 SWAP ;

: MarkedTextOut ( hdc x y vaddr len -- )
   0 LOCALS| n len vaddr y x hdc |
   BEGIN
      len 0> WHILE
      hdc vaddr len MEASURE-MARKS  TO n  INDEXED-COLORS
      hdc x y vaddr V>BUF n TextOut DROP
      n DUP CHARW @ *  +TO x  DUP +TO vaddr  NEGATE +TO len
   REPEAT ;

{ --------------------------------------------------------------------
SHOW-MARKED writes the text on the given screen line proper colors.

DISPLAY only redraws the lines that the paint structure says need to
be redrawn, but does not discriminate on columns, does the whole line.
-------------------------------------------------------------------- }

: SHOW-MARKED ( line# -- )   >R
   HDC XMARGIN R@ CHARH @ * YMARGIN +   \ hdc x y
   VLEFT R> VTOP + XY>V WIDE @ 1+       \ hdc x y vaddr len
   MarkedTextOut ;

: DISPLAY ( -- )
   PS.CY @ YMARGIN - CHARH @ / 1 + HIGH @ 1+ MIN
   PS.Y  @ YMARGIN - CHARH @ / 0 MAX
   ?DO ( over visible lines)
         I SHOW-MARKED
   LOOP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: NEWBKCOLOR ( -- )
   BKBRUSH @ DeleteObject DROP
   'BACKGROUNDS @  DUP BKCOLOR !  CreateSolidBrush  BKBRUSH ! ;

: ERASEBK ( -- )
   'BACKGROUNDS @ BKCOLOR @ <> IF  NEWBKCOLOR  THEN
   HWND PAD GetClientRect DROP
   WPARAM PAD BKBRUSH @ FillRect DROP ;
