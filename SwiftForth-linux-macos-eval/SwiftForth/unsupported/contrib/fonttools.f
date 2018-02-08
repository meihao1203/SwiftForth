{ ============================================================================
Font Tools

Created 6/2/2003 by Mike Ghan
Released into the Public Domain  2/25/2007 Mike Ghan

=========================================================================== }

FUNCTION: GetTextFace ( hDC count buffer -- count )

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

: GET-FONT-NAME  ( hDC -- addr cnt )
   ( hDC ) 100 DUP R-ALLOC DUP>R GetTextFace DROP R> ZCOUNT ;


: TEXT-FG  ( rgb -- )  MY-DC SWAP SetTextColor DROP ;
: TEXT-BG  ( rgb -- )  MY-DC SWAP SetBkColor DROP ;


: GET-FONT-AVE-WIDTH  ( -- width )
   [OBJECTS  TEXTMETRIC MAKES TM OBJECTS]
   MY-DC TM ADDR GetTextMetrics DROP
   TM AveCharWidth @ ;

: GET-FONT-MAX-WIDTH  ( -- width )
   [OBJECTS  TEXTMETRIC MAKES TM OBJECTS]
   MY-DC TM ADDR GetTextMetrics DROP
   TM MaxCharWidth @ ;

: GET-FONT-HEIGHT  ( -- height )
   [OBJECTS  TEXTMETRIC MAKES TM OBJECTS]
   MY-DC TM ADDR GetTextMetrics DROP
   TM Height @  TM ExternalLeading @ + ;

: GET-FONT-MIN-HEIGHT  ( -- height )  \ Font Height w/o External Leading
   [OBJECTS  TEXTMETRIC MAKES TM OBJECTS]
   MY-DC TM ADDR GetTextMetrics DROP
   TM Height @ ;


\ ****************************************************************************
\   Font Selections
\ ****************************************************************************

\ Be sure to DeleteObject when done.  Assume MY-DC is valid
: GET-PROP-FONT  ( decipointsize -- hFont )
   [OBJECTS  LOGICAL-FONT MAKES FONT OBJECTS]
   ( point ) MY-DC LOGPIXELSY GetDeviceCaps  720 */ NEGATE FONT Height !
   ANSI_CHARSET FONT CharSet C!
   VARIABLE_PITCH FF_SWISS OR FONT PitchAndFamily C!
   FW_NORMAL FONT Weight !
   PROOF_QUALITY FONT Quality C!
   S" Arial" FONT FaceName ZPLACE
   FONT ADDR CreateFontIndirect ;

\ Be sure to DeleteObject when done.  Assume MY-DC is valid
: GET-FIXED-FONT  ( decipointsize -- hFont )
   [OBJECTS  LOGICAL-FONT MAKES FONT OBJECTS]
   ( point ) MY-DC LOGPIXELSY GetDeviceCaps  720 */ NEGATE FONT Height !
   ANSI_CHARSET FONT CharSet C!
   FIXED_PITCH FF_MODERN OR FONT PitchAndFamily C!
   FW_NORMAL FONT Weight !
   PROOF_QUALITY FONT Quality C!
 \ S" Andale Mono" FONT FaceName ZPLACE
   S" Courier New" FONT FaceName ZPLACE
   FONT ADDR CreateFontIndirect ;


