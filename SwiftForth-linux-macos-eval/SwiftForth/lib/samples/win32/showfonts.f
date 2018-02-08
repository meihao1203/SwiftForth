{ ====================================================================
Enumerate system fonts as an example of how to use a callback.

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL SHOWFONTS Enumerate system fonts

DECIMAL

{ --------------------------------------------------------------------
The "EnumFonts" Windows call requires an application callback that
will be called repeatedly to process each font in the system. We are
just displaying the fonts, so we just look at the "dwType" to decide
how to display each font.
-------------------------------------------------------------------- }

: FontFunc ( lplf lptm dwType lpData -- )
   LOCALS| lpData dwType lptm lplf |
   OPERATOR'S CR
   dwType
   dup TRUETYPE_FONTTYPE and
   IF    ."     "
   ELSE  ." Non-"
   THEN    ." TrueType "
   dup RASTER_FONTTYPE and
   IF      ." Raster "
   ELSE    ." Vector "
   THEN
   DEVICE_FONTTYPE and
   IF      ." Device "
   ELSE    ." GDI    "
   THEN
   lplf 28 + LF_FACESIZE 2DUP 0 SCAN NIP - TYPE
   60 GET-XY DROP - 0 MAX SPACES
   lplf  DUP @ 4 .R             \ height
   4 + DUP @ 4 .R               \ width
   4 + DUP @ 6 .R               \ escapement angle
   4 + DUP @ 6 .R               \ orientation angle
   4 + DUP @ 4 .R               \ weight
   4 + DUP C@ 1 AND 2 .R        \ italics
   1 + DUP C@ 1 AND 2 .R        \ underline
   1 + DUP C@ 1 AND 2 .R        \ strike-out
   1 + DUP C@ 4 .R              \ character set
   1 + DUP C@ 2 .R              \ output precision
   1 + DUP C@ 4 .R              \ clip precision
   1 + DUP C@ 2 .R              \ output quality
   1 +     C@ 4 H.R             \ family and pitch
   ;

: SHOWFONT ( -- res )
   HWND MSG WPARAM LPARAM FontFunc  1 ;

' SHOWFONT 4 CB: &SHOWFONTS

LIBRARY GDI32
FUNCTION: EnumFonts ( hdc lpFaceName lpFontFunc lParam -- n )

: .FONTS ( -- )
   CR 60 spaces ."   ht wide  esc  ornt  wt I U S set p  cp q  fp"
   HWND GetDC
   0                    \ no particular font name
   &SHOWFONTS           \ address of enumerate callback routine
   0                    \ no application supplied data
   EnumFonts
   DROP ;

CR CR .( Type .FONTS to display installed system fonts.)  CR
