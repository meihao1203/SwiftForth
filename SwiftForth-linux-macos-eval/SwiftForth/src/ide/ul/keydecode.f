{ ====================================================================
Keyboard function key decoding

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

This file supplies the EKEY and AKEY behaviors with decoding of escape
key sequences and mapping to the global extended key codes in
keymap.f.  DO NOT USE LITERAL VALUES FOR EKEY CODES.  USE THE NAMED
CONSTANTS IN keymap.f.
==================================================================== }

PACKAGE KEY-DECODER

{ --------------------------------------------------------------------
Decode tables

K1, K2, and K3 are the mapping tables for 3-, 4-, and 5-character
escape sequences.  The first cell of each entry is the key sequence to
match on.  The second cell is the extended character code.

The algorithm used to search the table requires that it be sorted in
ascending order on the first cell.  IF ENTRIES ARE ADDED, BE SURE THE
TABLE REMAINS IN SORT ORDER!
-------------------------------------------------------------------- }

HEX

CREATE K3
   4F41 , K-CTRL_UP ,
   4F42 , K-CTRL_DOWN ,
   4F43 , K-CTRL_RIGHT ,
   4F44 , K-CTRL_LEFT ,
   4F46 , K-END ,
   4F48 , K-HOME ,
   4F50 , K-F1 ,
   4F51 , K-F2 ,
   4F52 , K-F3 ,
   4F53 , K-F4 ,
   5B41 , K-UP ,
   5B42 , K-DOWN ,
   5B43 , K-RIGHT ,
   5B44 , K-LEFT ,
   5B46 , K-END ,
   5B48 , K-HOME ,
   FFFFFFFF ,           \ Stopper

CREATE K4
   5B317E , K-HOME ,
   5B327E , K-INSERT ,
   5B337E , K-DELETE ,
   5B347E , K-END ,
   5B357E , K-NEXT ,
   5B367E , K-PRIOR ,
   5B377E , K-HOME ,
   5B387E , K-END ,
   FFFFFFFF ,           \ Stopper

CREATE K5
   5B31317E , K-F1 ,
   5B31327E , K-F2 ,
   5B31337E , K-F3 ,
   5B31347E , K-F4 ,
   5B31357E , K-F5 ,
   5B31377E , K-F6 ,
   5B31387E , K-F7 ,
   5B31397E , K-F8 ,
   5B32307E , K-F9 ,
   5B32317E , K-F10 ,
   5B32337E , K-F11 ,
   5B32347E , K-F12 ,
   FFFFFFFF ,           \ Stopper

DECIMAL

{ --------------------------------------------------------------------
Extended key processing

TKEY is a timed key function.  Timeout does a -1 THROW which is
tested for in (C-EKEY) below.

(<<KEY) takes the accumulated key match value from the stack, shifts
it up, and ors in the next received key code, returning the result.
This is the pattern that will be used to match in the Kx tables above.

-KEYCODE takes an accumulated key match value and table adddress,
returning the mapped code and false if found, or the same match
pattern and true if not found.

(C-EKEY) replaces 'EKEY and 'AKEY for the console terminal I/O
personality.  It decodes Esc sequences and returns system extended key
codes.  If a timeout occurs before an entire Esc sequence is read and
decoded, a single Esc code is returned.
-------------------------------------------------------------------- }

: TKEY ( -- char )
   COUNTER 250 + BEGIN
      DUP EXPIRED THROW
   KEY? UNTIL  DROP  KEY ;

: (<<KEY) ( x1 -- x2 )
   8 LSHIFT TKEY OR ;

: -KEYCODE ( x addr -- x true | echar 0 )
   BEGIN  2DUP @ <> WHILE  2 CELLS +
   2DUP @ U< UNTIL  DROP -1 EXIT  THEN          \ Not found: return x and true
   NIP CELL+ @ 0 ;                              \ Found: return echar from table and false

: ((C-EKEY)) ( -- echar )
   KEY  DUP $1B = IF  DROP 0  (<<KEY) (<<KEY)
      K3 -KEYCODE IF  (<<KEY) K4 -KEYCODE IF
   (<<KEY) K5 -KEYCODE THROW   THEN THEN THEN ;

: (C-EKEY) ( -- echar )
   ['] ((C-EKEY)) CATCH ?DUP IF
      DUP 1+ IF  THROW  THEN
   DROP $1B EXIT  THEN ;

' (C-EKEY) DUP 'EKEY !  'AKEY !

END-PACKAGE
