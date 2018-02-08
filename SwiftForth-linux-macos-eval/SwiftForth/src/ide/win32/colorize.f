{ ====================================================================
colorize.f
Colorize the words listing

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

PACKAGE COLORIZED

: INLINE? ( xt -- flag )
   >INLINE COUNT ?EXIT C@ $C3 = ;

: IMMED? ( xt -- flag )
   NFA-FLAGS $40 AND ;

: MENU? ( xt -- FLAG )
   NFA-FLAGS $20 AND ;

CONSOLE-WINDOW +ORDER

' SF-MESSAGES PARENT CONSTANT (SWITCH)

CONSOLE-WINDOW -ORDER

: COLORIZE ( xt -- color )
   DUP INLINE? IF DROP 2 EXIT THEN
   DUP IMMED?  IF DROP 3 EXIT THEN
   DUP MENU?   IF DROP 4 EXIT THEN
   DUP >R
   PARENT CASE
      ['] (CONSTANT)  OF   5 ENDOF
      ['] (2CONSTANT) OF   6 ENDOF
      ['] (CREATE)    OF   7 ENDOF
      ['] (USER)      OF   8 ENDOF
      ['] (VALUE)     OF   9 ENDOF
          (SWITCH)    OF  10 ENDOF
      R@ 17 +         OF  11 ENDOF
                  DUP OF  12 ENDOF
   ENDCASE R> DROP ;

PUBLIC

VARIABLE COLORING

CONFIG: COLORING ( -- addr len )   COLORING CELL ;

PRIVATE

: NORMAL ( -- )   0 ATTRIBUTE ;

: COLOR.ID ( na -- )
   COLORING @ 0= IF (.ID) EXIT THEN
   ?DUP IF
      DUP NAME> COLORIZE ATTRIBUTE
      COUNT ?TYPE
      NORMAL
   ELSE
      S" [no name]"
   THEN 2 SPACES ;

' COLOR.ID IS .ID

END-PACKAGE


