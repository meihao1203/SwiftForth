{ ====================================================================
Print Preview

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
Rick VanNorman

This file supports the Print Preview function.
==================================================================== }

PACKAGE PRINTING

{ --------------------------------------------------------------------
Printer buffer window
-------------------------------------------------------------------- }

CREATE PRNBUF-CLASS ,Z" PRNBUF"
CREATE PRNBUF-NAME  ,Z" Print Buffer"

[SWITCH PRNBUF-MESSAGES DEFWINPROC ( -- res )
   WM_DESTROY  RUN: 0  ;
   WM_CREATE   RUN: MAKE-RICH-EDIT-CONTROL 0 ;
   WM_SIZE     RUN: SIZE-RICH-EDIT-CONTROL 0 ;
   WM_CLOSE    RUN: CLOSE-RICH-EDIT-CONTROL 0 ;
   WM_SETFOCUS RUN: HRE SetFocus DROP 0 ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD PRNBUF-MESSAGES ;
   4 CB: PRNBUF-CALLBACK

:PRUNE   ?PRUNE -EXIT
   BEGIN
      PRNBUF-CLASS 0 FindWindow ?DUP WHILE
      WM_CLOSE 0 0 SendMessage DROP
   REPEAT
   PRNBUF-CLASS HINST UnregisterClass DROP ;

: REGISTER-PRNBUF-CLASS ( -- )
   0 CS_OWNDC   OR
     CS_HREDRAW OR
     CS_VREDRAW OR                      \ class style
   PRNBUF-CALLBACK                     \ wndproc
   0                                    \ class extra
   2 CELLS                              \ window extra
   HINST                                \ hinstance
   HINST 101 LoadIcon                   \ icon
   NULL IDC_ARROW LoadCursor            \ cursor
   COLOR_BTNFACE 1+                     \ background brush
   0                                    \ no menu
   PRNBUF-CLASS                        \ class name
   DefineClass DROP ;

: CREATE-PRNBUF-WINDOW ( -- handle )
      0                                 \ extended style
      PRNBUF-CLASS                     \ window class name
      PRNBUF-NAME                      \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 400 300                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

0 VALUE PRNBUF-HANDLE

: OPEN-PRNBUF ( -- )
   REGISTER-PRNBUF-CLASS
   CREATE-PRNBUF-WINDOW DUP IF
\      DUP SW_NORMAL ShowWindow DROP
\      DUP UpdateWindow DROP
   THEN  TO PRNBUF-HANDLE ;

: SHOW-PRNBUF ( -- )   PRNBUF-HANDLE SW_NORMAL ShowWindow DROP ;
: CLOSE-PRNBUF ( -- )   PRNBUF-HANDLE WM_CLOSE 0 0 SendMessage DROP
                        0 TO PRNBUF-HANDLE ;

: TEST-LINES ( n -- )   0 DO
      I (.) WRITE-TEXT DROP
      S"  Now is the time for all good men..." WRITE-TEXT DROP
      <EOL> COUNT WRITE-TEXT DROP
   LOOP ;

{ --------------------------------------------------------------------
Default printer

DEFAULT-PRINTER sets up the pd structure with a device context for the
current default printer.  That can be used to determine the initial
settings for the printer dialog.

CHOOSE-PRINTER-PAGES opens the common printer dialog box with the
given number of pages.  It returns a true flag if the user selects OK
and everything is setup correctly.
-------------------------------------------------------------------- }

PRINTDIALOG BUILDS pd

: DEFAULT-PRINTER ( -- )
   0 pd DevMode !  0 pd DevNames !
   PD_RETURNDC PD_RETURNDEFAULT OR  pd Flags !
   PRINTDIALOG SIZEOF pd StructSize !
   pd StructSize PrintDlg 0= IOR_PRT_NODEFPRINTER ?THROW ;

: CHOOSE-PRINTER-PAGES ( n -- flag )
   1 pd MinPage H!  DUP pd MaxPage H!
   1 pd FromPage H!  pd ToPage H!
   PD_RETURNDC PD_NOSELECTION OR pd Flags !
   pd StructSize PrintDlg ;

{ --------------------------------------------------------------------
The PAGESETUPDLG structure contains information the PageSetupDlg
function uses to initialize the Page Setup common dialog box. After
the user closes the dialog box, the system returns information about
the user-defined page parameters in this structure.

The DEVMODE data structure contains information about the device
initialization and environment of a printer.

-------------------------------------------------------------------- }

CLASS PAGESETUPDIALOG
   VARIABLE StructSize
   VARIABLE Owner
   VARIABLE DevMode
   VARIABLE DevNames
   VARIABLE Flags
   POINT BUILDS PaperSize
    RECT BUILDS MinMargin
    RECT BUILDS Margin
   VARIABLE Instance
   VARIABLE CustData
   VARIABLE PageSetupHook
   VARIABLE PagePaintHook
   VARIABLE PageSetupTemplateName
   VARIABLE PageSetupTemplate
END-CLASS

PAGESETUPDIALOG BUILDS psd

: PAGE-SETUP ( -- flag )   PAGESETUPDIALOG SIZEOF psd StructSize !
   psd StructSize PageSetupDlg ;

CLASS DEVMODE
   32 BUFFER: DeviceName
    HVARIABLE SpecVersion
    HVARIABLE DriverVersion
    HVARIABLE Size
    HVARIABLE DriverExtra
     VARIABLE Fields
    HVARIABLE Orientation
    HVARIABLE PaperSize
    HVARIABLE PaperLength
    HVARIABLE PaperWidth
    HVARIABLE Scale
    HVARIABLE Copies
    HVARIABLE DefaultSource
    HVARIABLE PrintQuality
    HVARIABLE Color
    HVARIABLE Duplex
    HVARIABLE YResolution
    HVARIABLE TTOption
    HVARIABLE Collate
   32 BUFFER: FormName
    HVARIABLE LogPixels
     VARIABLE BitsPerPel
     VARIABLE PelsWidth
     VARIABLE PelsHeight
     VARIABLE DisplayFlags
     VARIABLE DisplayFrequency
END-CLASS

{ --------------------------------------------------------------------
PAGE-RANGE calculates the size of the printed page based upong the
following Device Capabilities:

LOGPIXELSX Number of pixels per logical inch along the screen width.
In a system with multiple display monitors, this value is the same for
all monitors.

LOGPIXELSY Number of pixels per logical inch along the screen height.
In a system with multiple display monitors, this value is the same for
all monitors.

PHYSICALWIDTH For printing devices: the width of the physical page, in
device units. For example, a printer set to print at 600 dpi on
8.5"x11" paper has a physical width value of 5100 device units. Note
that the physical page is almost always greater than the printable
area of the page, and never smaller.

PHYSICALHEIGHT For printing devices: the height of the physical page,
in device units. For example, a printer set to print at 600 dpi on
8.5"x11" paper has a physical height value of 6600 device units. Note
that the physical page is almost always greater than the printable
area of the page, and never smaller.

PHYSICALOFFSETX For printing devices: the distance from the left edge
of the physical page to the left edge of the printable area, in device
units. For example, a printer set to print at 600 dpi on 8.5"x11"
paper, that cannot print on the leftmost 0.25" of paper, has a
horizontal physical offset of 150 device units.

PHYSICALOFFSETY For printing devices: the distance from the top edge
of the physical page to the top edge of the printable area, in device
units. For example, a printer set to print at 600 dpi on 8.5"x11"
paper, that cannot print on the topmost 0.5" of paper, has a vertical
physical offset of 300 device units.

TWIP is a unit of measurement equal to 1/20th of a printers point.
There are 1440 twips to and inch, 567 twips to a centimeter.

-------------------------------------------------------------------- }

FORMATRANGE BUILDS fr

: PAGE-RANGE ( -- )   0 fr rcPage top !  0 fr rcPage left !

   1440 pd DC @ LOGPIXELSX GetDeviceCaps 2>R
   pd DC @ PHYSICALWIDTH GetDeviceCaps 2R@ */ fr rcPage right !
   pd DC @ PHYSICALOFFSETX GetDeviceCaps 2R> */ fr rc left !
   fr rcPage right @  fr rc left @ 2* -  fr rc right !

   1440 pd DC @ LOGPIXELSY GetDeviceCaps 2>R
   pd DC @ PHYSICALHEIGHT GetDeviceCaps 2R@ */ fr rcPage bottom !
   pd DC @ PHYSICALOFFSETY GetDeviceCaps 2R> */ fr rc top !
   fr rcPage bottom @  fr rc top @ 2* -  fr rc bottom ! ;

: PAGES ( -- n )   DEFAULT-PRINTER  PAGE-RANGE
   pd DC @ fr hdc !  0 fr hdcTarget !
   0 fr chrg Min !  TEXT-LENGTH fr chrg Max !
   0  BEGIN  fr chrg Max @  fr chrg Min @  > WHILE
      fr MEASURE ?DUP WHILE  fr chrg Min !  1+
   REPEAT THEN  fr CLOSE ;

{ --------------------------------------------------------------------
The DOCINFO structure contains the input and output filenames and
other information used by the StartDoc function.

Size specifies the size, in bytes, of the structure.

DocName pointer to a null-terminated string that specifies the name of
the document.

Output pointer to a null-terminated string that specifies the name of
an output file. If this pointer is NULL, the output will be sent to
the device identified by the device context handle that was passed to
the StartDoc function.

Datatype pointer to a null-terminated string that specifies the type
of data, such as "raw" or "emf", used to record the print job. This
member can be NULL. If it is not NULL, the StartDoc function passes it
to the printer driver. Note that the printer driver might ignore the
requested data type

Type specifies additional information about the print job. This member
must be zero or DI_APPBANDING.
-------------------------------------------------------------------- }

CLASS DOCINFO
   VARIABLE Size
   VARIABLE DocName
   VARIABLE Output
   VARIABLE Datatype
   VARIABLE Type        \ Windows 95 only; ignored on Windows NT
END-CLASS

{ --------------------------------------------------------------------
Print the contents of the Rich Edit window
-------------------------------------------------------------------- }

DOCINFO BUILDS di

: START-DOC   fr hdc @ di Size StartDoc 0> NOT IOR_PRT_BADSTARTDOC ?THROW ;
: START-PAGE  fr hdc @ StartPage 0> NOT IOR_PRT_BADSTARTPAGE ?THROW ;
: END-PAGE    fr hdc @ EndPage 0> NOT IOR_PRT_BADENDPAGE ?THROW ;
: END-DOC     fr hdc @ EndDoc 0> NOT IOR_PRT_BADENDDOC ?THROW ;

: ON-PAGE ( n -- flag )
   pd Flags @ PD_PAGENUMS AND IF
      pd FromPage H@ pd ToPage H@ 1+ WITHIN
   ELSE  DROP TRUE  THEN ;

: PRINT-PAGES ( -- )   0  BEGIN  1+
      fr chrg Max @  fr chrg Min @  > WHILE
         pd Flags @ PD_COLLATE AND IF  1
         ELSE  pd Copies H@  THEN  0 SWAP 0 DO  DROP
            DUP ON-PAGE IF
               START-PAGE  fr RENDER  END-PAGE
            ELSE  fr MEASURE
            THEN  DUP 0= IF  LEAVE
         THEN  LOOP  ?DUP WHILE
            fr chrg Min !
   REPEAT THEN  DROP  END-DOC ;

: PRINT-DOC ( -- )
   START-DOC  ['] PRINT-PAGES CATCH  DUP IF
      fr hdc @ AbortDoc DROP
   THEN  THROW ;

: /DOCUMENT ( -- )
   pd DC @ fr hdc !  0 fr hdcTarget !  TEXT-LENGTH fr chrg Max !
   DOCINFO SIZEOF di Size !  Z" Swift Document" di DocName !
   0 di Output !  0 di Datatype !  0 di Type ! ;

: PRINT-RICH-EDIT ( -- )   PAGES ?DUP IF
      CHOOSE-PRINTER-PAGES IF
         /DOCUMENT  pd Flags @ PD_COLLATE AND IF
            pd Copies H@  ELSE  1
         THEN  0 DO  PAGE-RANGE  0 fr chrg Min !
            ['] PRINT-DOC CATCH  fr CLOSE  THROW
   LOOP  THEN  THEN ;

END-PACKAGE
