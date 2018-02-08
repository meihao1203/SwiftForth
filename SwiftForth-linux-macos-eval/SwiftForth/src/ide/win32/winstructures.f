{ ====================================================================
Window data types

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman
==================================================================== }

?( Window data types)

{ --------------------------------------------------------------------
A rectangle in memory is, from lowest to highest, x y cx cy
A rectangle on the stack is, from deepest to top, x y cx cy
-------------------------------------------------------------------- }

ICODE @RECT ( a -- a[0] a[1] a[2] a[3] )
   12 # EBP SUB                                 \ room for 3 cells
    0 [EBX] EAX MOV  EAX 8 [EBP] MOV
    4 [EBX] EAX MOV  EAX 4 [EBP] MOV
    8 [EBX] EAX MOV  EAX 0 [EBP] MOV
   12 [EBX] EBX MOV
   RET END-CODE

ICODE !RECT ( a[0] a[1] a[2] a[3] a -- )
    0 [EBP] EAX MOV  EAX 12 [EBX] MOV
    4 [EBP] EAX MOV  EAX  8 [EBX] MOV
    8 [EBP] EAX MOV  EAX  4 [EBX] MOV
   12 [EBP] EAX MOV  EAX  0 [EBX] MOV
   16 [EBP] EBX MOV  20 # EBP ADD
   RET END-CODE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS POINT
   VARIABLE x
   VARIABLE y
END-CLASS

CLASS RECT
    VARIABLE left
    VARIABLE top
    VARIABLE right
    VARIABLE bottom

   : FETCH ( -- l t r b )   ADDR @RECT ;
   : STORE ( l t r b -- )   ADDR !RECT ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS NMHDR
    VARIABLE hwndFrom
    VARIABLE idFrom
    VARIABLE code
END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS FILENAME-BUFFER
   MAX_PATH BUFFER: FileName
END-CLASS

CLASS FILETIME
   VARIABLE LowDateTime
   VARIABLE HighDateTime
END-CLASS

CLASS WIN32_FIND_DATA
   VARIABLE FileAttributes
   FILETIME BUILDS CreationTime
   FILETIME BUILDS LastAccessTime
   FILETIME BUILDS LastWriteTime
   VARIABLE FileSizeHigh
   VARIABLE FileSizeLow
   VARIABLE Reserved0
   VARIABLE Reserved1
   MAX_PATH BUFFER: FileName
   14 BUFFER: AlternateFileName
    2 BUFFER: DUMMY
END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS OPENFILENAME

   VARIABLE  StructSize         \ size in CVARIABLEs of structure
   VARIABLE  Owner              \ hwnd of the owner's window
   VARIABLE  Instance           \ hinst, used for overlay templates
   VARIABLE  zFilter            \ pairs of zstr, followed by null
   VARIABLE  zCustomFilter      \ buffer to save user filters in
   VARIABLE  MaxCustFilter      \ length of custfilter buffer
   VARIABLE  FilterIndex        \ filter index for initial view
   VARIABLE  zFile              \ buffer for filename
   VARIABLE  MaxFile            \ length of zfile
   VARIABLE  zFileTitle         \ buffer for file title
   VARIABLE  MaxFileTitle       \ length of zfiletitle
   VARIABLE  zInitialDir        \ where to run, NULL is current
   VARIABLE  zTitle             \ title of dialog
   VARIABLE  Flags              \ creation flags, see api
   HVARIABLE FileOffset         \ offset in zfile past path info
   HVARIABLE FileExtension      \ offset in zfile past path & name
   VARIABLE  zDefExt            \ buffer with default extension
   VARIABLE  CustData           \ custom data for hook
   VARIABLE  Hook               \ callback address of custom routine
   VARIABLE  zTemplateName      \ resourse name of new template

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS TEXTMETRIC

   VARIABLE  Height
   VARIABLE  Ascent
   VARIABLE  Descent
   VARIABLE  InternalLeading
   VARIABLE  ExternalLeading
   VARIABLE  AveCharWidth
   VARIABLE  MaxCharWidth
   VARIABLE  Weight
   VARIABLE  Overhang
   VARIABLE  DigitizedAspectX
   VARIABLE  DigitizedAspectY
   CVARIABLE FirstChar
   CVARIABLE LastChar
   CVARIABLE DefaultChar
   CVARIABLE BreakChar
   CVARIABLE Italic
   CVARIABLE Underlined
   CVARIABLE StruckOut
   CVARIABLE PitchAndFamily
   CVARIABLE CharSet

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS WNDCLASS
   VARIABLE style
   VARIABLE WndProc
   VARIABLE ClsExtra
   VARIABLE WndExtra
   VARIABLE Instance
   VARIABLE Icon
   VARIABLE Cursor
   VARIABLE Background
   VARIABLE MenuName
   VARIABLE ClassName
END-CLASS

CLASS WNDCLASSEX
   VARIABLE size
   VARIABLE style
   VARIABLE WndProc
   VARIABLE ClsExtra
   VARIABLE WndExtra
   VARIABLE Instance
   VARIABLE Icon
   VARIABLE Cursor
   VARIABLE Background
   VARIABLE MenuName
   VARIABLE ClassName
   VARIABLE IconSm

   : Construct ( -- )   [ THIS SIZEOF ] LITERAL size ! ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS PRINTDIALOG       \ original PRINTDLG -- case ambiguous name

    VARIABLE  StructSize
    VARIABLE  Owner
    VARIABLE  DevMode
    VARIABLE  DevNames
    VARIABLE  DC
    VARIABLE  Flags
    HVARIABLE FromPage
    HVARIABLE ToPage
    HVARIABLE MinPage
    HVARIABLE MaxPage
    HVARIABLE Copies
    VARIABLE  Instance
    VARIABLE  CustData
    VARIABLE  PrintHook
    VARIABLE  SetupHook
    VARIABLE  PrintTemplateName
    VARIABLE  SetupTemplateName
    VARIABLE  PrintTemplate
    VARIABLE  SetupTemplate

   : Construct ( -- )
      [ THIS SIZEOF ] LITERAL  ADDR OVER ERASE  StructSize ! ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS CHOOSE-FONT       \ original CHOOSEFONT -- case ambiguous name

    VARIABLE StructSize
    VARIABLE Owner
    VARIABLE DC
    VARIABLE LogFont
    VARIABLE PointSize
    VARIABLE Flags
    VARIABLE rgbColors
    VARIABLE CustData
    VARIABLE Hook
    VARIABLE TemplateName
    VARIABLE Instance
    VARIABLE Style
    VARIABLE FontType
    VARIABLE SizeMin
    VARIABLE SizeMax

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS LOGICAL-FONT

   VARIABLE   Height
   VARIABLE   Width
   VARIABLE   Escapement
   VARIABLE   Orientation
   VARIABLE   Weight
   CVARIABLE  Italic
   CVARIABLE  Underline
   CVARIABLE  StrikeOut
   CVARIABLE  CharSet
   CVARIABLE  OutPrecision
   CVARIABLE  ClipPrecision
   CVARIABLE  Quality
   CVARIABLE  PitchAndFamily
   32 BUFFER: FaceName

END-CLASS
