{ ====================================================================
richedit.f
Rich Edit 1.0 control support

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

PACKAGE PRINTING

{ --------------------------------------------------------------------
This file provides support for a Rich Edit control.  It assumes that
this control will be placed within an owner window.  The following
functions must be placed into the message switch statement of this
owner window:

   WM_CREATE   RUN: MAKE-RICH-EDIT-CONTROL 0 ;
   WM_SIZE     RUN: SIZE-RICH-EDIT-CONTROL 0 ;
   WM_CLOSE    RUN: CLOSE-RICH-EDIT-CONTROL 0 ;
   WM_SETFOCUS RUN: HRE SetFocus DROP 0 ;

Requires: Window's Rich Edit version 1.0 controls

Exports: Everything
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Rich Edit control support

These words are used in the message callback functions of the window
which owns the Rich Edit control.

-------------------------------------------------------------------- }

0 VALUE RICH-EDIT-HANDLE

0 WS_CHILD OR WS_VISIBLE OR ES_WANTRETURN OR ES_MULTILINE OR
  ES_NOHIDESEL OR ES_AUTOVSCROLL OR ES_AUTOHSCROLL OR ES_LEFT OR
  WS_VSCROLL OR WS_HSCROLL OR WS_BORDER OR
CONSTANT RICH-EDIT-STYLE

: CREATE-RICH-EDIT-WINDOW ( -- handle )
      0                                 \ extended style
      Z" RICHEDIT"                      \ window class name
      0                                 \ window caption
      RICH-EDIT-STYLE                   \ window style
      0 0 0 0                           \ position and size
      HWND                              \ parent window handle
      1                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

: HRE ( -- handle )   HWND 0 GetWindowLong ;

: MAKE-RICH-EDIT-CONTROL ( -- )
   Z" RICHED32.DLL" LoadLibrary DROP
   CREATE-RICH-EDIT-WINDOW DUP TO RICH-EDIT-HANDLE >R
   R@ WM_SETFONT OEM_FIXED_FONT GetStockObject 1 SendMessage DROP
   HWND 0 R> SetWindowLong DROP ;

: SIZE-RICH-EDIT-CONTROL ( -- )
   HRE 0 0 LPARAM LOHI 1 MoveWindow DROP ;

: CLOSE-RICH-EDIT-CONTROL ( -- )
   HRE WM_CLOSE 0 0 SendMessage DROP
   HWND DestroyWindow DROP
   0 TO RICH-EDIT-HANDLE ;

{ --------------------------------------------------------------------
Units of measure

TWIP is a unit of measurement equal to 1/20th of a printers point.
There are 1440 twips to and inch, 567 twips to a centimeter.

INCHES POINTS and CMS are immediate words that determine how many
decimal points were in the previous number and scale to twips
appropriately.

-------------------------------------------------------------------- }

1440 CONSTANT TWIPS/INCH
 567 CONSTANT TWIPS/CM
  20 CONSTANT TWIPS/POINT

: >TWIPS ( n factor -- twips )   DPL @  DUP 0< IF
      DROP 1  ELSE  1  SWAP 0 DO  10 *  LOOP  STATE @ IF
         POSTPONE DROP  ELSE  ROT DROP  THEN
   THEN  STATE @ IF  POSTPONE 2LITERAL  POSTPONE */
   ELSE  */  THEN ;

: INCHES ( inches -- twips )   TWIPS/INCH >TWIPS ; IMMEDIATE
: POINTS ( points -- twips )   TWIPS/POINT >TWIPS ; IMMEDIATE
: CMS ( cms -- twips )   TWIPS/CM >TWIPS ; IMMEDIATE

{ --------------------------------------------------------------------
The PARAFORMAT structure contains information about paragraph
formatting attributes in a rich edit control.

Size number of bytes of this structure. Must be filled before passing
to the rich edit control.

Mask members containing valid information or attributes to set. This
parameter can be zero or more of these values:

Value             Meaning
PFM_ALIGNMENT     The Alignment member is valid.
PFM_NUMBERING     The Numbering member is valid.
PFM_OFFSET        The Offset member is valid.
PFM_OFFSETINDENT  The StartIndent member is valid and specifies
                    a relative value.
PFM_RIGHTINDENT   The RightIndent member is valid.
PFM_STARTINDENT   The StartIndent member is valid.
PFM_TABSTOPS      The TabCount and Tabs members are valid.

If both PFM_STARTINDENT and PFM_OFFSETINDENT are specified,
PFM_STARTINDENT takes precedence.

Numbering value specifying numbering options. This member can be zero
or PFN_BULLET.

StartIndent indentation, in twips, of the first line in the paragraph.
If the paragraph formatting is being set and PFM_OFFSETINDENT is
specified, this member is treated as a relative value that is added to
the starting indentation of each affected paragraph.

RightIndent size, in twips, of the right indentation, relative to the
right margin.

Offset indentation, in twips, of the second line and subsequent lines,
relative to the starting indentation. The first line is indented if
this member is negative, or outdented is this member is positive.

Alignment value specifying the paragraph alignment. This member can be
one of the following values:

Value           Meaning
PFA_LEFT	Paragraphs are aligned with the left margin.
PFA_RIGHT	Paragraphs are aligned with the right margin.
PFA_CENTER	Paragraphs are centered.

TabCount number of tab stops.

Tabs array of absolute tab stop positions.

\ PARAFORMAT mask values
       $1 CONSTANT PFM_STARTINDENT
       $2 CONSTANT PFM_RIGHTINDENT
       $4 CONSTANT PFM_OFFSET
       $8 CONSTANT PFM_ALIGNMENT
      $10 CONSTANT PFM_TABSTOPS
      $20 CONSTANT PFM_NUMBERING
$80000000 CONSTANT PFM_OFFSETINDENT

\ PARAFORMAT numbering options
1 CONSTANT PFN_BULLET

\ PARAFORMAT alignment options
1 CONSTANT PFA_LEFT
2 CONSTANT PFA_RIGHT
3 CONSTANT PFA_CENTER

GET gets the current paragraph formatting settings.  Returns the
current mask setting.

SET sets the current paragraph format.  Returns TRUE if successful.

+BULLETS turns on paragraph bullets.
-BULLETS turns off paragraph bullets.

ALIGN-LEFT ALIGN-RIGHT ALIGN-CENTER set current alignment.

INDENT-LEFT INDENT-RIGHT INDENT-SECOND set indentation in twips.

SET-TABS sets the given number of tab stops from the twips values on
the stack.

-------------------------------------------------------------------- }

CLASS PARAFORMAT
   HVARIABLE Size
   2 BUFFER: wPad1
    VARIABLE Mask
   HVARIABLE Numbering
   HVARIABLE Reserved
    VARIABLE StartIndent
    VARIABLE RightIndent
    VARIABLE Offset
   HVARIABLE Alignment
   HVARIABLE TabCount
 32 CELLS BUFFER: Tabs

: GET ( -- mask )   RICH-EDIT-HANDLE EM_GETPARAFORMAT
   0 Size  THIS SIZEOF OVER H!  SendMessage ;

: SET ( -- flag )   RICH-EDIT-HANDLE EM_SETPARAFORMAT
   0 Size  THIS SIZEOF OVER H!  SendMessage ;

: +Mask ( mask -- )   Mask !  SET DROP ;

: +BULLETS ( -- )   PFN_BULLET Numbering H!  PFM_NUMBERING +Mask ;
: -BULLETS ( -- )   0 Numbering H!  PFM_NUMBERING +Mask ;

: ALIGN-LEFT ( -- )   PFA_LEFT Alignment H!  PFM_ALIGNMENT +Mask ;
: ALIGN-RIGHT ( -- )   PFA_RIGHT Alignment H!  PFM_ALIGNMENT +Mask ;
: ALIGN-CENTER ( -- )   PFA_CENTER Alignment H!  PFM_ALIGNMENT +Mask ;

: INDENT-LEFT ( tipws -- )   StartIndent !  PFM_STARTINDENT +Mask ;
: INDENT-RIGHT ( twips -- )   RightIndent !  PFM_RIGHTINDENT +Mask ;
: INDENT-SECOND ( twips -- )   Offset !  PFM_OFFSET +Mask ;

: SET-TABS ( twips ... n -- )   DUP TabCount H!
   0 DO  Tabs I CELLS + !  LOOP
   PFM_TABSTOPS +Mask ;

END-CLASS

{ --------------------------------------------------------------------
The CHARFORMAT structure contains information about character
formatting in a rich edit control.

Size number of bytes of this structure. Must be set before passing the
structure to the rich edit control.

Mask members containing valid information or attributes to set. This
member can be zero or more of the following values:

Value           Meaning
CFM_BOLD        The CFE_BOLD value of the Effects member is valid.
CFM_ITALIC      The CFE_ITALIC value of the Effects member is valid.
CFM_PROTECTED   The CFE_PROTECTED value of the Effects member is valid.
CFM_STRIKEOUT   The CFE_STRIKEOUT value of the Effects member is valid.
CFM_UNDERLINE   The CFE_UNDERLINE value of the Effects member is valid.
CFM_COLOR       The TextColor member and the CFE_AUTOCOLOR value of
                  the Effects member are valid.
CFM_FACE        The FaceName member is valid.
CFM_OFFSET      The Offset member is valid.
CFM_SIZE        The Height member is valid.
CFM_CHARSET     The CharSet member is valid.

Effects character effects. This member can be a combination of the
following values:

Value           Meaning
CFE_AUTOCOLOR   The text color is the return value of GetSysColor
                (COLOR_WINDOWTEXT).
CFE_BOLD	Characters are bold.
CFE_ITALIC	Characters are italic.
CFE_STRIKEOUT	Characters are struck out.
CFE_UNDERLINE	Characters are underlined.
CFE_PROTECTED   Characters are protected; an attempt to modify them
                will cause an EN_PROTECTED notification message.

Height character height, in twips.

Offset character offset, in twips, from the baseline. If this member
is positive, the character is a superscript; if it is negative, the
character is a subscript.

TextColor this member is ignored if the CFE_AUTOCOLOR character effect
is specified.

CharSet character set value. Can be one of the values specified for
the lfCharSet member of the LOGFONT structure.

PitchAndFamily specifies the pitch and family of the font. The two
low-order bits specify the pitch of the font and can be one of the
following values:

DEFAULT_PITCH
FIXED_PITCH
VARIABLE_PITCH

Bits 4 through 7 of the member specify the font family. Font families
describe the look of a font in a general way. They are intended for
specifying fonts when the exact typeface desired is not available. The
values for font families are as follows:

FF_DECORATIVE Novelty fonts. Old English is an example.
FF_DONTCARE Don't care or don't know.
FF_MODERN Fonts with constant stroke width (monospace), with or
without serifs. Monospace fonts are usually modern. Pica, Elite, and
CourierNew are examples.

FF_ROMAN Fonts with variable stroke width (proportional) and with
serifs. MS Serif is an example.

FF_SCRIPT Fonts designed to look like handwriting. Script and Cursive
are examples.

FF_SWISS Fonts with variable stroke width (proportional) and without
serifs. MS Sans Serif is an example.

The proper value can be obtained by using the Boolean OR operator to
join one pitch constant with one family constant.

FaceName is a null-terminated string that specifies the typeface name
of the font. The length of this string must not exceed 32 characters,
including the null terminator. The EnumFontFamilies function can be
used to enumerate the typeface names of all currently available fonts.
If FaceName is an empty string, GDI uses the first font that matches
the other specified attributes.

\ EM_SETCHARFORMAT wParam masks
1 CONSTANT SCF_SELECTION
2 CONSTANT SCF_WORD
0 CONSTANT SCF_DEFAULT    \ set the default charformat or paraformat
4 CONSTANT SCF_ALL        \ not valid with SCF_SELECTION or SCF_WORD
8 CONSTANT SCF_USEUIRULES \ modifier for SCF_SELECTION; says that
                          \ the format came from a toolbar, etc. and
                          \ therefore UI formatting rules should be
                          \ used instead of strictly formatting the
                          \ selection.

\ CHARFORMAT masks
       $1 CONSTANT CFM_BOLD
       $2 CONSTANT CFM_ITALIC
       $4 CONSTANT CFM_UNDERLINE
       $8 CONSTANT CFM_STRIKEOUT
      $10 CONSTANT CFM_PROTECTED
$08000000 CONSTANT CFM_CHARSET
$10000000 CONSTANT CFM_OFFSET
$20000000 CONSTANT CFM_FACE
$40000000 CONSTANT CFM_COLOR
$80000000 CONSTANT CFM_SIZE

\ CHARFORMAT effects
       $1 CONSTANT CFE_BOLD
       $2 CONSTANT CFE_ITALIC
       $4 CONSTANT CFE_UNDERLINE
       $8 CONSTANT CFE_STRIKEOUT
      $10 CONSTANT CFE_PROTECTED
$40000000 CONSTANT CFE_AUTOCOLOR

GET gets the current character format.  Returns the mask value.

SET sets the current character format.  Returns true if successful.

+BOLD -BOLD turns on or off bold characters.
+ITALIC -ITALIC turns on or off italic characters.
+UNDERLINE -UNDERLINE turns on or off underlines.
+STRIKEOUT -STRIKEOUT turns on or off strikeout.
+PROTECTED -PROTECTED turns of or off protected characters.
+AUTOCOLOR -AUTOCOLOR turns on or off auto character coloring.

TEXT-COLOR sets the current character coloring and turns off auto
coloring.

HIGH sets the height of the current font.

SUPERSCRIPT sets the subscript value of the current font.

FAMILY sets the font family value.

FONT sets the font name.

-------------------------------------------------------------------- }

CLASS CHARFORMAT
   HVARIABLE Size
   2 BUFFER: wPad1
    VARIABLE Mask
    VARIABLE Effects
    VARIABLE Height
    VARIABLE Offset
    VARIABLE TextColor
   CVARIABLE CharSet
   CVARIABLE PitchAndFamily
  32 BUFFER: FaceName
   2 BUFFER: wPad2

: GET ( -- mask )   RICH-EDIT-HANDLE EM_GETCHARFORMAT
   0 Size  THIS SIZEOF OVER H!  SendMessage ;

: SET ( -- flag )   RICH-EDIT-HANDLE EM_SETCHARFORMAT
   SCF_SELECTION Size  THIS SIZEOF OVER H!  SendMessage ;

: +Mask ( mask -- )   Mask !  SET DROP ;
: +Effects ( mask -- )   Effects @ OR Effects ! ;
: -Effects ( mask -- )   INVERT Effects @ AND Effects ! ;

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

END-CLASS

{ --------------------------------------------------------------------
The EDITSTREAM structure contains information that an application
passes to a rich edit control in a EM_STREAMIN or EM_STREAMOUT
message. The rich edit control uses the information to transfer a
stream of data into or out of the control.

Cookie specifies an application-defined value that the rich edit
control passes to the EditStreamCallback callback function specified
by the Callback member.

Error indicates the results of the stream-in (read) or stream-out
(write) operation. A value of zero indicates no error. A nonzero value
can be the return value of the EditStreamCallback function or a code
indicating that the control encountered an error.

Callback pointer to an EditStreamCallback function, which is an
application-defined function that the control calls to transfer data.
The control calls the callback function repeatedly, transferring a
portion of the data with each call.

-------------------------------------------------------------------- }

2VARIABLE StreamIn

:NONAME ( cookie a n pcb -- ior )
   StreamIn 2@  OVER SWAP _PARAM_2 OVER MIN  DUP >R
   /STRING  StreamIn 2!  _PARAM_1 R@ MOVE
   R> _PARAM_3 !  0 ;   4 CB: EditStreamInCallback

CLASS EDITSTREAM
    VARIABLE Cookie
    VARIABLE Error
    VARIABLE Callback
END-CLASS

EDITSTREAM BUILDS EditStreamIn

EditStreamInCallback EditStreamIn Callback !

{ --------------------------------------------------------------------
Rich Edit output functions

WRITE-TEXT sends the given text string to the Rich Edit control.  It
returns the number of characters that were actually added.

WRITE-RTF send RTF commands to the Rich Edit control.  These commands
must be surrounded by squiggly braces (the same ones that are used to
surround this comment block) and preceeded by a backslash.  So far, I
have not found this function to be useful.

TEXT-LENGTH returns the number of characters in the Rich Edit control.

\ Stream formats
    1 CONSTANT SF_TEXT
    2 CONSTANT SF_RTF
$8000 CONSTANT SFF_SELECTION
$4000 CONSTANT SFF_PLAINRTF

-------------------------------------------------------------------- }

: WRITE-TEXT ( a n -- n' )   StreamIn 2!
   RICH-EDIT-HANDLE EM_STREAMIN  SF_TEXT SFF_SELECTION OR
   EditStreamIn Cookie SendMessage ;

: WRITE-RTF ( a n -- n' )   StreamIn 2!
   RICH-EDIT-HANDLE EM_STREAMIN  SF_RTF SFF_SELECTION OR
   EditStreamIn Cookie SendMessage ;

: TEXT-LENGTH ( -- )
   RICH-EDIT-HANDLE WM_GETTEXTLENGTH 0 0 SendMessage ;

{ --------------------------------------------------------------------
The CHARRANGE structure specifies a range of characters in a rich edit
control. This structure is used with the EM_EXGETSEL and EM_EXSETSEL
messages.

If the Min and Max members are equal, the range is empty. The range
includes everything if Min is 0 and Max is -1.

Min index of first intercharacter position.

Max index of last intercharacter position.

-------------------------------------------------------------------- }

CLASS CHARRANGE
    VARIABLE Min
    VARIABLE Max
END-CLASS

{ --------------------------------------------------------------------
The FORMATRANGE structure contains information that a rich edit
control uses to format its output for a particular device. This
structure is used with the EM_FORMATRANGE message.

hdc device to render to.

hdcTarget target device to format for.

rc area to render to. Units are in TWIPS

rcPage entire area of rendering device. Units are in TWIPS

chrg range of text to format.

CLOSE cleans up after using the FORMATRANGE structure.

MEASURE simply counts the number of characters output.

RENDER sends the output to the selected device.

-------------------------------------------------------------------- }

CLASS FORMATRANGE
    VARIABLE hdc
    VARIABLE hdcTarget
 RECT BUILDS rc
 RECT BUILDS rcPage
 CHARRANGE BUILDS chrg

: CLOSE ( -- )
   RICH-EDIT-HANDLE EM_FORMATRANGE 0 0 SendMessage DROP ;

: MEASURE ( -- n )
   RICH-EDIT-HANDLE EM_FORMATRANGE FALSE hdc SendMessage ;

: RENDER ( -- n )
   RICH-EDIT-HANDLE EM_FORMATRANGE TRUE hdc SendMessage ;

END-CLASS

{ --------------------------------------------------------------------
The REQRESIZE structure contains the requested size of a rich edit
control. A rich edit control sends this structure to its parent window
as part of an EN_REQUESTRESIZE notification message.

nmhdr notification header.

rc requested new size.

Your application can resize a rich edit control (CRichEditCtrl) as
needed so that it is always the same size as its contents. A rich edit
control supports this so-called "bottomless" functionality by sending
its parent window an EN_REQUESTRESIZE notification message whenever
the size of its contents changes.

-------------------------------------------------------------------- }

CLASS REQRESIZE
   NMHDR BUILDS nmhdr
    RECT BUILDS rc
END-CLASS

END-PACKAGE
