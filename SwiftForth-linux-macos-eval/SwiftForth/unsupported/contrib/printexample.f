{ ============================================================================
Printing Examples

Created 04/29/2007 by Mike Ghan

=========================================================================== }

ONLY FORTH ALSO DEFINITIONS DECIMAL

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


\ ****************************************************************************
\  Simple Printing
\ ****************************************************************************

PRINTING +ORDER  \ Need stuff from Preview.F

DOCINFO BUILDS MY-DI

: START-OF-DOC   MY-DC  MY-DI ADDR StartDoc 0> NOT IOR_PRT_BADSTARTDOC ?THROW ;
: START-OF-PAGE  MY-DC  StartPage 0> NOT IOR_PRT_BADSTARTPAGE ?THROW ;
: END-OF-PAGE    MY-DC  EndPage 0> NOT IOR_PRT_BADENDPAGE ?THROW  ;
: END-OF-DOC     MY-DC  EndDoc 0> NOT IOR_PRT_BADENDDOC ?THROW ;

: MY-DEFAULT-PRINTER  DEFAULT-PRINTER  pd DC @ IS-MY-DC ;

: SET-DOC-NAME  ( zName -- )  \ Name Print Job
   DOCINFO SIZEOF MY-DI Size !
   ( doc name )  MY-DI DocName !
   0 MY-DI Output !  0 MY-DI Datatype !  0 MY-DI Type ! ;

: YADA  ( -- )
   MY-DC 100 200 ( x y )
   Z" SwiftForth is FORTH, Inc.’s integrated development system." ZCOUNT
   TextOut DROP ( Output Text ) ;

: PRINT-TEST  ( -- )
   MY-DEFAULT-PRINTER
   Z" Test Document" SET-DOC-NAME
   START-OF-DOC
   START-OF-PAGE ( We must manage our paging )
   ( Now we render our output )
   YADA ( something to output )
   END-OF-PAGE
   END-OF-DOC
   MY-DC DeleteDC DROP ( Delete Printer DC ) ;


PRINTING -ORDER

CR
CR .( Type PRINT-TEST to run the demo.)
CR


\ ****************************************************************************
\ Formatted Printing
\ ****************************************************************************

\ The following example requires FontTools.F and FormatText.F
INCLUDE FontTools
INCLUDE FormatText

0 VALUE PrtWidth   \ Physical paper width, in pixels
0 VALUE PrtHeight  \ Physical paper height, in pixels
0 VALUE PrtOffsetX \ Distance  from the left edge of the physical page to the left edge of the printable area
0 VALUE PrtOffsetY \ Distance  from the top edge of the physical page to the top edge of the printable area
0 VALUE PrtHres    \ Horizontal resolution, pixels per inch
0 VALUE PrtVres    \ Vertical resolution, pixels per inch

: SET-PRT-METRICS  ( -- )
   MY-DC PHYSICALWIDTH   GetDeviceCaps ( PixWidth )  TO PrtWidth
   MY-DC PHYSICALHEIGHT  GetDeviceCaps ( PixHeight ) TO PrtHeight
   MY-DC PHYSICALOFFSETX GetDeviceCaps ( PixWidth )  TO PrtOffsetX
   MY-DC PHYSICALOFFSETY GetDeviceCaps ( PixWidth )  TO PrtOffsetY
   MY-DC LOGPIXELSX      GetDeviceCaps ( pix/inch )  TO PrtHres
   MY-DC LOGPIXELSY      GetDeviceCaps ( pix/inch )  TO PrtVres ;

: INCHES  ( deci-inchesX deci-inchesY -- printerX printerY )   \ 100ths of an inch
   SWAP PrtHres 100 */  PrtOffsetX - 0 MAX
   SWAP PrtVres 100 */  PrtOffsetY - 0 MAX ;


0 VALUE hMY-FONT
0 VALUE hMY-FONT-FIXED

: CREATE-MY-FONTS  ( -- )   \ create as many fonts as needed here.
   hMY-FONT NOT
   IF  100 ( decipts ) GET-PROP-FONT TO hMY-FONT THEN
   hMY-FONT-FIXED NOT
   IF  120 ( decipts ) GET-FIXED-FONT TO hMY-FONT-FIXED THEN
   ;

: DESTROY-MY-FONTS  ( -- )
   hMY-FONT       ?DUP IF DeleteObject DROP  0 TO hMY-FONT       THEN
   hMY-FONT-FIXED ?DUP IF DeleteObject DROP  0 TO hMY-FONT-FIXED THEN ;

FORMATTER BUILDS TEST-FORMAT  \ Our Test Instance

: (SF)  ( -- addr cnt )  \ Something to say
   S" SwiftForth is an extremely fast, ANS Forth compliant Forth system, which is fully integrated with the Windows API." ;

: PRINT-FORMATTED
   MY-DEFAULT-PRINTER
   SET-PRT-METRICS
   Z" Test Format Document" SET-DOC-NAME
   START-OF-DOC
   CREATE-MY-FONTS
   START-OF-PAGE ( We must manage our paging )
   \ Now we render our output.
   \ We'll render in a rectangle at 1.5", 3" to 3.25", 5" from the paper edge.
   hMY-FONT TEST-FORMAT SELECT-FONT ( Set Font & Metrics )
   150 300 INCHES  325 500 INCHES ( bounding rect in 100th inch ) TEST-FORMAT SET-RECT
   TEST-FORMAT FRAME-RECT \ Optional frame
   (SF) ( addr cnt ) TEST-FORMAT SET-TEXT  TEST-FORMAT OUTPUT-TEXT ( print text )
   \ Next We'll render in a rectangle at 3.5", 5.25" to 5.75", 7" from the paper edge.
   hMY-FONT-FIXED TEST-FORMAT SELECT-FONT ( Set Font & Metrics )
   350 525 INCHES  575 700 INCHES ( bounding rect in 100th inch ) TEST-FORMAT SET-RECT
   (SF) ( addr cnt ) TEST-FORMAT SET-TEXT  TEST-FORMAT OUTPUT-TEXT ( print text )
   END-OF-PAGE
   END-OF-DOC
   MY-DC DeleteDC DROP ( Delete Printer DC )
   DESTROY-MY-FONTS ;

CR
CR .( Type PRINT-FORMATTED to run the format print demo.)
CR

