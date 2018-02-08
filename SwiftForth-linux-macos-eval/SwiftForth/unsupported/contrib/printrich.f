{ ====================================================================
An example of printing Rich Edit text.
==================================================================== }

ONLY FORTH ALSO DEFINITIONS DECIMAL

PRINTING +ORDER

CLASS XCHARFORMAT
    VARIABLE Size
    VARIABLE Mask
    VARIABLE Effects
    VARIABLE Height
    VARIABLE Offset
    VARIABLE TextColor
   CVARIABLE CharSet
   CVARIABLE PitchAndFamily
  32 BUFFER: FaceName
   2 BUFFER: wPad2

: GET ( -- mask )   THIS SIZEOF Size !
   RICH-EDIT-HANDLE EM_GETCHARFORMAT
   0 ADDR  SendMessage ;

: SET ( -- flag )   THIS SIZEOF Size !
   RICH-EDIT-HANDLE EM_SETCHARFORMAT
   SCF_SELECTION  ADDR  SendMessage ;

: SET-ALL ( -- flag )   THIS SIZEOF Size !
   RICH-EDIT-HANDLE EM_SETCHARFORMAT
   SCF_ALL  ADDR  SendMessage ;

\ Changed this to OR with exisiting attributes
: +Mask    ( mask -- )   Mask @ OR Mask !  SET DROP ;
: +Effects ( mask -- )   Effects @ OR Effects ! ;
: -Effects ( mask -- )   INVERT Effects @ AND Effects ! ;

: AGAIN  ( -- )  SET DROP ;
: RESET  ( -- )  Mask OFF  SET DROP ;
: +BOLD ( -- )   CFE_BOLD +Effects  CFM_BOLD +Mask ;
: -BOLD ( -- )   CFE_BOLD -Effects  CFM_BOLD +Mask ;
: +ITALIC ( -- )   CFE_ITALIC +Effects  CFM_ITALIC +Mask ;
: -ITALIC ( -- )   CFE_ITALIC -Effects  CFM_ITALIC +Mask ;
: +UNDERLINE ( -- )   CFE_UNDERLINE +Effects  CFM_UNDERLINE +Mask ;
: -UNDERLINE ( -- )   CFE_UNDERLINE -Effects  CFM_UNDERLINE +Mask ;
: +STRIKEOUT ( -- )   CFE_STRIKEOUT +Effects  CFM_STRIKEOUT +Mask ;
: -STRIKEOUT ( -- )   CFE_STRIKEOUT -Effects  CFM_STRIKEOUT +Mask ;
: +PROTECTED ( -- )   CFE_PROTECTED +Effects  CFM_PROTECTED +Mask ;
: -PROTECTED ( -- )   CFE_PROTECTED -Effects  CFM_PROTECTED +Mask ;
: +AUTOCOLOR ( -- )   CFE_AUTOCOLOR +Effects  CFM_COLOR +Mask ;
: -AUTOCOLOR ( -- )   CFE_AUTOCOLOR -Effects  CFM_COLOR +Mask ;

: TEXT-COLOR ( n -- )   TextColor !  -AUTOCOLOR ;

: HIGH ( twips -- )   Height !  CFM_SIZE +Mask ;

: SUPERSCRIPT ( twips -- )   Offset !  CFM_OFFSET +Mask ;

: FAMILY ( n -- )   PitchAndFamily C!  0 FaceName C!  CFM_FACE +Mask ;

: FONT ( a n -- )   31 MIN FaceName ZPLACE  CFM_FACE +Mask ;

: SHOW  ( -- )
   CR
   ." Mask           "  Mask @ H.             CR
   ." Effects        "  Effects @ H.          CR
   ." Height         "  Height @ H.           CR
   ." Offset         "  Offset @ H.           CR
   ." TextColor      "  TextColor @ H.        CR
   ." CharSet        "  CharSet C@ H.         CR
   ." PitchAndFamily "  PitchAndFamily C@ H.  CR
   ." FaceName       "  FaceName ZCOUNT TYPE  CR
   ;

END-CLASS


XCHARFORMAT BUILDS PRT-FORMAT
PARAFORMAT BUILDS PRT-PARA

: YADA  ( -- )
   S" SwiftForth is FORTH, Inc.’s integrated development system." TYPE
 \ PRT-FORMAT SHOW ( Devel )
   CR ;

: TEST ( -- )
   WINPRINT OPEN-PERSONALITY
   S" Arial" PRT-FORMAT FONT
   SHOW-PRNBUF ( Optional Print Preview )
   PRT-FORMAT RESET
   YADA
   S" Arial" PRT-FORMAT FONT
   YADA
   PRT-FORMAT AGAIN
   YADA
   PRT-FORMAT +ITALIC
   YADA
   YADA
   PRT-FORMAT AGAIN
   YADA
   PRT-FORMAT +BOLD  14 POINTS PRT-FORMAT HIGH
   YADA
   PRT-FORMAT -ITALIC
   YADA
   $0000FF PRT-FORMAT TEXT-COLOR  10 POINTS PRT-FORMAT HIGH
   YADA
   PRT-FORMAT AGAIN
   PRT-PARA +BULLETS
   YADA
   PRT-FORMAT RESET  PRT-FORMAT +BOLD 10 POINTS PRT-FORMAT HIGH
   YADA
   PRT-PARA -BULLETS
   CLOSE-PERSONALITY ;

PRINTING -ORDER

CR
CR .( Type TEST to run the demo.)
CR
