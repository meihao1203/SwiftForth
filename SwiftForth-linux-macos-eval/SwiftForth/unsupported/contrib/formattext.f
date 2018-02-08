{ ============================================================================
Formatted Text Output

Created 4/19/2001 by Mike Ghan
Revised for multiple page support  6/14/2002 MAG
Added FILL-RECT  6/14/2002 MAG
Fixed blank line handling  6/15/02 MAG
Released into the Public Domain  2/25/2007 Mike Ghan

=========================================================================== }

FUNCTION: GetTextExtentPoint32 ( hdc lpString cbString lpSize -- res )
FUNCTION: SetTextJustification ( hdc nBreakExtra nBreakCount -- res )
FUNCTION: TextOut ( hdc nXStart nYStart lpString cbString -- res )
FUNCTION: ExtTextOut ( hdc X Y fuOptions *lprc lpString cbCount *lpDx -- res )
FUNCTION: InflateRect ( lpRect dx dy -- res )

[UNDEFINED] CURRENT-DC [IF]
\ User Vars
 #USER
   CELL +USER CURRENT-DC  \ Device Context
 TO #USER

: MY-DC  ( -- hDC )     CURRENT-DC @ ;
: IS-MY-DC  ( hDC -- )  CURRENT-DC ! ;  \ Set at BeginPaint etc
: GET-MY-DC  ( -- )     HWND GetDC IS-MY-DC ;
: RELEASE-MY-DC ( -- )  HWND MY-DC ReleaseDC DROP ;
[THEN]


[UNDEFINED] DRAW-RECT [IF]
FUNCTION: SetROP2    ( hDC ROP2 -- res )
FUNCTION: Rectangle  ( hdc nLeftRect nTopRect nRightRect nBottomRect -- res )

: DRAW-RECT  ( x1 y1 x2 y2 -- )
   LOCALS| y2 x2 y1 x1 |
   MY-DC NULL_BRUSH GetStockObject ( hDC hBrush ) SelectObject ( PrevBrush ) >R
   MY-DC R2_COPYPEN SetROP2 ( prevROP ) >R
   MY-DC x1 y1 x2 y2 Rectangle DROP
   MY-DC R> ( prevROP)    SetROP2 DROP
   MY-DC R> ( PrevBrush ) SelectObject DROP ;
[THEN]

CLASS FORMATTER

   RECT  BUILDS FMT-RECT  \ Clipping Rect
   POINT BUILDS OUT-SIZE  \ Most Recent Output Size

   SINGLE posX   \ Text Starting X Position
   SINGLE posY   \ Text Starting Y Position
   SINGLE pTEXT  \ Text Pointer
   SINGLE rCNT   \ Text Count
   SINGLE FNT-W  \ Font Ave Width
   SINGLE FNT-H  \ Font Height

   : GET-RECT  ( -- x1 y1 x2 y2 )
      FMT-RECT ADDR @RECT ;

   : SET-RECT  ( x1 y1 x2 y2 -- )
      FMT-RECT ADDR !RECT ;

   : SET-TEXT  ( addr cnt -- )
      -TRAILING
      TO rCNT TO pTEXT ;

   : CLEAR-OUTSIZE  ( -- )
      OUT-SIZE ADDR POINT SIZEOF ERASE ;

   : SET-FONT-METRICS
      GET-FONT-MIN-HEIGHT TO FNT-H ( Set Font Height )
      GET-FONT-AVE-WIDTH  TO FNT-W ( Set Font Ave Width ) ;

   : SELECT-FONT  ( hFont -- )
      MY-DC SWAP SelectObject DROP
      SET-FONT-METRICS ;

   : HOME-POS
      FMT-RECT left @ TO posX ( Init X Position )
      FMT-RECT top @  TO posY ( Init Y Position ) ;

   : USED-HEIGHT  ( -- height )
      posY FMT-RECT top @ - 0 MAX ;

   : L-MARG-PXL  ( #pixels -- )
      FMT-RECT left @ + TO posX ;

   : L-MARG-CURRENT  ( -- )  \ Position left margin at end of last output line
      OUT-SIZE x @ L-MARG-PXL ;

   : +L-MARG-PXL  ( #pixels -- )  \ Incr by #pixels
      +TO posX ;

   : NO-L-MARG  ( -- )  0 L-MARG-PXL ;

   : L-MARG  ( #chars -- )
      FNT-W ( Font Ave Width ) * L-MARG-PXL ;

   : +L-MARG  ( #chars -- )  \ Inc by #Chars
      FNT-W ( Font Ave Width ) * +L-MARG-PXL ;

   : L-MARG"  ( 100thInch -- )
      MY-DC LOGPIXELSX GetDeviceCaps ( pix/inch ) 100 */  L-MARG-PXL ;

   : CR  ( -- )
      NO-L-MARG
      FNT-H +TO posY ( Inc posY ) ;

   : INC-Y-POSITION  ( -- )
      rCNT ( More? ) -EXIT
      FNT-H +TO posY ( Inc posY ) ;


   : VERT-FITS?  ( -- flag )  \ True = Fits Vertically
      FMT-RECT bottom @ posY -  FNT-H >= ( Room? ) ;

   \ Test if string at 'addr cnt' fits into formatting rect FMT-RECT
   : FITS?  ( addr cnt -- flag )  \ True = Fits
      [OBJECTS  POINT MAKES SIZE OBJECTS]
      MY-DC -ROT  SIZE ADDR GetTextExtentPoint32 DROP
      VERT-FITS? ( High enough? )
      FMT-RECT right @ posX -  SIZE x @ >= ( Wide enough? )  AND ;

   : SKIP-CHAR  1 +TO pTEXT  -1 +TO rCNT ;


   \ Output one line of string at  pTEXT rCNT  into Formatting Rect  FMT-RECT
   : OUTPUT-LINE  ( -- )
      pTEXT 0 0 LOCALS| #words #chars pBEGIN |
      CLEAR-OUTSIZE
      BEGIN  0 ( count )
         ( Include any Leading Blanks )  rCNT 0
         ?DO  DUP pTEXT + C@  BL =
            IF  1+ ( Inc Count )  ELSE  LEAVE  THEN
         LOOP
         ( Next, Parse Word )  rCNT OVER - 0 MAX 0
         ?DO  DUP pTEXT + C@  BL > ( Non Blank AND Non Control? )
            IF  1+ ( Inc Count )  ELSE  LEAVE  THEN
         LOOP
         DUP ( count )
         IF  pBEGIN OVER #chars + FITS? ( Will it Fit? )
            #words 0= VERT-FITS? AND ( first word and fits vertically? ) OR
            0<> AND
         THEN ?DUP
      WHILE
         DUP ( count ) +TO #chars
         rCNT OVER ( count ) - 0 MAX TO rCNT
         ( count ) +TO pTEXT
         1 +TO #words
      REPEAT
      MY-DC pBEGIN #chars OUT-SIZE ADDR GetTextExtentPoint32 DROP ( Update Size )
      MY-DC  posX posY ( x y )  ETO_CLIPPED  FMT-RECT ADDR
      pBEGIN #chars NULL ExtTextOut DROP ( Output the Line )
      FALSE ( found CR? )
      rCNT 0
      ?DO
         pTEXT C@  13 = ( CR? ) OR ( with CR Found Flag )
         pTEXT C@   BL <= ( Skip Leading Blanks )
         IF  SKIP-CHAR  ELSE  LEAVE  THEN
         DUP ( CR Found? )
         IF LEAVE  THEN
      LOOP ( found a CR? ) -EXIT
      pTEXT C@  10 = ( Matching LF? ) -EXIT
      SKIP-CHAR ;

   : OUTPUT-LINE-ADV  ( -- )
      VERT-FITS? ( High enough? )  rCNT ( More? ) AND -EXIT
      OUTPUT-LINE  INC-Y-POSITION ;

   \ Output from current position until end or finished
   : (OUTPUT-TEXT)  ( -- )  \ Assumes MY-DC, SET-TEXT,
      BEGIN  OUTPUT-LINE-ADV
         VERT-FITS? ( High enough? )  rCNT ( More? ) AND  NOT
      UNTIL ;

   \ Output from start until end or finished
   : OUTPUT-TEXT  ( -- )  \ Assumes MY-DC, SET-TEXT
      SET-FONT-METRICS ( Set Font Width/Height )
      CLEAR-OUTSIZE
      HOME-POS ( Init XY Position )
      (OUTPUT-TEXT) ;

   : OUTPUT-TEXT-IN-RECT  ( x1 y1 x2 y2 -- )  \ Assumes MY-DC, SET-TEXT
      SET-RECT  OUTPUT-TEXT ;

   \ Draw Rectange and Shrink Formatting Rectangle for Text by 1/2 Char
   : FRAME-RECT  ( -- )
      GET-RECT DRAW-RECT
      FMT-RECT ADDR
      FNT-W 2/ NEGATE FNT-H 4 / NEGATE InflateRect DROP ;

   \ Fill the Formatting Rectangle with hBrush
   : FILL-RECT  ( hBrush -- )
      MY-DC FMT-RECT ADDR ROT FillRect DROP ;


END-CLASS


\ Examples:  TEST, SIMPLE and SHOW-FILE


FUNCTION: SaveDC  ( hDC -- save# )
FUNCTION: RestoreDC ( hDC save# -- res )
FUNCTION: MessageBeep  ( sound_type -- flag )   \ True = Error

: PLAY-DEFAULT    MB_OK MessageBeep DROP ;

\ Something to display
: "SF" S" SwiftForth is FORTH, Inc.’s integrated development system for Windows 95, 98, and NT." ;

FORMATTER BUILDS MY-FORMAT  \ Our Test Instance


\ ****************************************************************************
\  Simple Test
\ ****************************************************************************

400 VALUE X2
300 VALUE Y2

: SIMPLE
   GET-MY-DC
      "SF" ( addr cnt ) MY-FORMAT SET-TEXT
      10 50 X2 Y2 ( x1 y1 x2 y2 ) MY-FORMAT OUTPUT-TEXT-IN-RECT
   RELEASE-MY-DC ;


\ ****************************************************************************
\ Demo numerous capabilities
\ ****************************************************************************

0 VALUE hFONT
0 VALUE hFONT-SMALL
0 VALUE hFONT-BIG
0 VALUE hFONT-FIXED

: CREATE-FONTS  ( -- )
   hFONT NOT
   IF  100 ( decipts ) GET-PROP-FONT TO hFONT THEN
   hFONT-SMALL NOT
   IF  80 ( decipts )  GET-PROP-FONT TO hFONT-SMALL THEN
   hFONT-BIG NOT
   IF  120 ( decipts ) GET-PROP-FONT TO hFONT-BIG THEN
   hFONT-FIXED NOT
   IF  100 ( decipts ) GET-FIXED-FONT TO hFONT-FIXED THEN
   ;

: ?DELETE-OBJECT  ( handle -- )
   ?DUP -EXIT
   DeleteObject DROP ;


: DESTROY-FONTS  ( -- )
   hFONT       ?DELETE-OBJECT  0 TO hFONT
   hFONT-SMALL ?DELETE-OBJECT  0 TO hFONT-SMALL
   hFONT-BIG   ?DELETE-OBJECT  0 TO hFONT-BIG
   hFONT-FIXED ?DELETE-OBJECT  0 TO hFONT-FIXED
   ;

$C0C0C0 CONSTANT LTGRAY-COLOR
$FFFFFF CONSTANT WHITE-COLOR

: FORMAT-TEST  ( addr cnt -- )
   2>R ( Stash Text )
   50 50 300 300 MY-FORMAT SET-RECT
   MY-DC SaveDC DROP ( Save DC )
   CREATE-FONTS
   hFONT MY-FORMAT SELECT-FONT ( Set Font & Metrics )
   WHITE_BRUSH GetStockObject MY-FORMAT FILL-RECT ( Optional - Set BkGrnd )
   MY-FORMAT FRAME-RECT
   MY-FORMAT HOME-POS ( Init XY Position )
   hFONT-SMALL MY-FORMAT SELECT-FONT ( Set Font & Metrics )
   MY-DC LTGRAY-COLOR SetBkColor DROP
   S" Description:" MY-FORMAT SET-TEXT
   MY-FORMAT OUTPUT-LINE
   hFONT MY-FORMAT SELECT-FONT ( Set Font & Metrics )
   MY-DC WHITE-COLOR SetBkColor DROP
 \  MY-FORMAT HOME-POS ( Re-init XY Position )
   MY-FORMAT L-MARG-CURRENT  ( set left margin to end of last output )
   1 MY-FORMAT +L-MARG ( Add 1 char space )
   2R> MY-FORMAT SET-TEXT  MY-FORMAT OUTPUT-LINE-ADV
   MY-FORMAT NO-L-MARG ( Reset Margin to 0 after first Line )
   MY-FORMAT rCNT ( More? )
   IF  MY-FORMAT (OUTPUT-TEXT) ( Output remainder of 1st page )  THEN
   BEGIN MY-FORMAT rCNT ( More? )
   WHILE  PLAY-DEFAULT KEY DROP ( Formatting Rectangle is Full )
      WHITE_BRUSH GetStockObject MY-FORMAT FILL-RECT ( Optional - Set BkGrnd )
      MY-FORMAT OUTPUT-TEXT ( Output next Page until end or finished )
   REPEAT
   MY-DC -1 ( Previous State ) RestoreDC DROP
   DESTROY-FONTS ;

: TEST  GET-MY-DC CR "SF" FORMAT-TEST RELEASE-MY-DC ;


\ ****************************************************************************
\  Show Text File
\ ****************************************************************************

0 VALUE SHOWFILE-HDL

: CLOSE-SHOWFILE  ( -- )
   SHOWFILE-HDL -EXIT
   SHOWFILE-HDL 0 TO SHOWFILE-HDL CLOSE-FILE THROW ;

: OPEN-SHOWFILE-R/O  ( addr count -- )   \ Read Only, SHOWFILE-HDL = 0 if Not Found
   CLOSE-SHOWFILE
   R/O OPEN-FILE ( ior ) THROW
   TO SHOWFILE-HDL ;


0 VALUE hTEXT-BUFFER

: FREE-TEXT-BUFFER  ( -- )
   hTEXT-BUFFER ( AllocateAddr ) ?DUP -EXIT
   0 TO hTEXT-BUFFER
   FREE ABORT" Can't Free Bufr" ;

: ALLOC-TEXT-BUFFER  ( size -- )
   FREE-TEXT-BUFFER
   ( size ) 1+ ALLOCATE ABORT" Can't Allocate Bufr"
   TO hTEXT-BUFFER ;

: SHOW-FILE  ( filename count -- )
   GET-MY-DC
   OPEN-SHOWFILE-R/O  SHOWFILE-HDL 0= ABORT" File Not Found"
   SHOWFILE-HDL FILE-SIZE 2DROP ( size ) DUP ALLOC-TEXT-BUFFER
   hTEXT-BUFFER SWAP ( addr size )  SHOWFILE-HDL READ-FILE DROP
   hTEXT-BUFFER SWAP ( #bytes read ) FORMAT-TEST
   FREE-TEXT-BUFFER
   CLOSE-SHOWFILE
   RELEASE-MY-DC ;

: SHOW-TEXT  CR S" FormatText.F" SHOW-FILE ;


