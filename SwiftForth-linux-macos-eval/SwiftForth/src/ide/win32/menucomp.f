{ ====================================================================
menucomp.f
Simple menu compiler

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

?( Menu compiler)

PACKAGE MENUCOMP
DLGCOMP +ORDER

{ --------------------------------------------------------------------
Menus are identifiers, styles, and unicode strings organized in
memory. See the definition of FORTH-MENU and FORTH-POPUP for examples of
use. 
-------------------------------------------------------------------- }

: QUOTED ( -- a n )
   /SOURCE DROP C@ [CHAR] " <> IF
      [CHAR] " WORD DROP THEN
   [CHAR] " WORD COUNT FORMAT COUNT ;

: FINISHED ( a -- )
   ?DUP IF  DUP H@ MF_END OR SWAP H!  THEN ;

: POPUP ( a -- x a p )
   DROP HERE DUP MF_POPUP H,  QUOTED U,  HERE -ROT ;

: END-POPUP ( x a p -- a )
   ROT HERE = ABORT" empty popup menu" FINISHED  ;

: ONEITEM ( a n style -- a )
   HERE >R  H, H, QUOTED U, DROP R> ;

: MENUITEM  ( a n -- a )   MF_STRING               ONEITEM ;
: GRAYITEM  ( a n -- a )   MF_STRING MF_GRAYED  OR ONEITEM ;
: CHECKITEM ( a n -- a )   MF_STRING MF_CHECKED OR ONEITEM ;

: SEPARATOR ( a -- a )
   DROP HERE   MF_SEPARATOR H,  0  H,  0 H, ;


{ ----------------------------------------------------------------------
provide automatic identifier creation like dialogs have; not required to
be present, just helpful. END-MENU closes any open IDSTRING definitions.
---------------------------------------------------------------------- }

: MI: ( -- n )
   ?IDSTRINGS
   IDN (.) >IDSTRINGS  S"  CONSTANT MI_" >IDSTRINGS
   BL WORD COUNT >IDSTRINGS  s"  " >IDSTRINGS
   IDN  1 +TO IDN ;

: END-MENU ( tag a -- )
   SWAP MENUCOMP <> ABORT" Unbalanced menu definition"
   FINISHED  MENUCOMP -ORDER  CREATE-IDS IDSTRINGS/ ;

{ --------------------------------------------------------------------
MENU uses the wordlist identifier for MENUCOMP as a stack checking
tag which is checked by END-MENU. 
-------------------------------------------------------------------- }

PUBLIC

: MENU ( -- tag 0 )   /IDSTRINGS
   CREATE  MENUCOMP  DUP +ORDER  BAL OFF   0 ,  0 ;

: CHECKMARK ( hmenu item flag -- )
   IF MF_CHECKED ELSE MF_UNCHECKED THEN CheckMenuItem DROP ;

: UNCHECKED ( flag menuitem -- )
   HCON GetMenu SWAP ROT 0= CHECKMARK ;

: CHECKED ( item addr -- )   HCON GetMenu ROT ROT @ CHECKMARK ;

DLGCOMP -ORDER
END-PACKAGE


{ --------------------------------------------------------------------
SIMPLE EXAMPLE
-------------------------------------------------------------------- }

0 [IF]

MENU FOO
   POPUP "THIS"
      101 MENUITEM "THIS"
      102 MENUITEM "THAT"
   END-POPUP
END-MENU

or

MENU BAR   WM_USER 1000 + TO IDN
   POPUP "THIS"
      MI: THIS MENUITEM "THIS"
      MI: THAT MENUITEM "THAT"
   END-POPUP
END-MENU
   
: ZOT HWND FOO LoadMenuIndirect SetMenu DROP ;




[THEN]

