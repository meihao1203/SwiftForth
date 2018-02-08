{ ====================================================================
Character type classification

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL ISCHAR Character type classification ala C with IS-ALPHA etc.

$01 CONSTANT CTYPE_UPPER         \ upper case letters
$02 CONSTANT CTYPE_LOWER         \ lower case letters
$04 CONSTANT CTYPE_DIGIT         \ digit characters
$08 CONSTANT CTYPE_WS            \ white space
$10 CONSTANT CTYPE_PUNCT         \ punctuation characters
$20 CONSTANT CTYPE_HEX           \ hexadecimal digits
$40 CONSTANT CTYPE_CONTROL       \ control characters
$80 CONSTANT CTYPE_GRAPH         \ is printable [ie., "graphic"]

CREATE CTYPE_ARRAY
   $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, $048 C, ( $00-$07 )
   $048 C, $048 C, $048 C, $048 C, $048 C, $048 C, $040 C, $040 C, ( $08-$0F )
   $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, ( $10-$17 )
   $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, $040 C, ( $18-$1F )
   $088 C, $090 C, $090 C, $090 C, $090 C, $090 C, $090 C, $090 C, ( $20-$27 )
   $090 C, $090 C, $090 C, $090 C, $090 C, $090 C, $090 C, $090 C, ( $28-$2F )
   $0A4 C, $0A4 C, $0A4 C, $0A4 C, $0A4 C, $0A4 C, $0A4 C, $0A4 C, ( $30-$37 )
   $0A4 C, $0A4 C, $090 C, $090 C, $090 C, $090 C, $090 C, $090 C, ( $38-$3F )
   $090 C, $0A1 C, $0A1 C, $0A1 C, $0A1 C, $0A1 C, $0A1 C, $081 C, ( $40-$47 )
   $081 C, $081 C, $081 C, $081 C, $081 C, $081 C, $081 C, $081 C, ( $48-$4F )
   $081 C, $081 C, $081 C, $081 C, $081 C, $081 C, $081 C, $081 C, ( $50-$57 )
   $081 C, $081 C, $081 C, $090 C, $090 C, $090 C, $090 C, $090 C, ( $58-$5F )
   $090 C, $0A2 C, $0A2 C, $0A2 C, $0A2 C, $0A2 C, $0A2 C, $082 C, ( $60-$67 )
   $082 C, $082 C, $082 C, $082 C, $082 C, $082 C, $082 C, $082 C, ( $68-$6F )
   $082 C, $082 C, $082 C, $082 C, $082 C, $082 C, $082 C, $082 C, ( $70-$77 )
   $082 C, $082 C, $082 C, $090 C, $090 C, $090 C, $090 C, $040 C, ( $78-$7F )

: CTYPE@ ( n -- x )
   DUP $7F > OVER 0< OR IF  DROP CTYPE_CONTROL
   ELSE  CTYPE_ARRAY + C@  THEN ;

: TYPETEST ( flags -- res )   CREATE ,
   DOES> ( n -- flag ) @ SWAP CTYPE@ AND 0<> ;


CTYPE_UPPER CTYPE_LOWER OR      TYPETEST IS-ALPHA ( n -- flag )
CTYPE_LOWER                     TYPETEST IS-LOWER
CTYPE_UPPER                     TYPETEST IS-UPPER
CTYPE_DIGIT                     TYPETEST IS-DIGIT ( n -- flag )
CTYPE_HEX                       TYPETEST IS-HEX ( n -- flag )
CTYPE_WS                        TYPETEST IS-SPACE ( n -- flag )
CTYPE_WS CTYPE_CONTROL OR       TYPETEST IS-FORTH-SPACE ( n -- flag )
CTYPE_PUNCT                     TYPETEST IS-PUNCT ( n -- flag )
CTYPE_GRAPH                     TYPETEST IS-PRINT ( n -- flag )
CTYPE_CONTROL                   TYPETEST IS-CNTRL ( n -- flag )
CTYPE_PUNCT CTYPE_UPPER OR
 CTYPE_LOWER CTYPE_DIGIT OR OR  TYPETEST IS-GRAPH ( n -- flag )
CTYPE_UPPER CTYPE_LOWER OR
 CTYPE_DIGIT OR                 TYPETEST IS-ALNUM ( n -- flag )

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF]

-? : . ( n -- )   6 .R ;

: ISIT ( n -- )   CR  DUP 3 .R SPACE DUP EMIT SPACE
   DUP 2DUP 2DUP 2DUP 2DUP 2DUP
   IS-ALPHA .  IS-LOWER . IS-UPPER . IS-DIGIT . IS-HEX .
   IS-SPACE .  IS-FORTH-SPACE .  IS-PUNCT . IS-PRINT . IS-CNTRL .
   IS-GRAPH .  IS-ALNUM . ;

.(
       alpha lower upper digit   hex space 4thsp punct print  ctrl graph alnum)

CHAR A ISIT
CHAR a ISIT
CHAR 0 ISIT
CHAR $ ISIT
CHAR _ ISIT
    BL ISIT
CTRL G ISIT

KEY DROP BYE  [THEN]
