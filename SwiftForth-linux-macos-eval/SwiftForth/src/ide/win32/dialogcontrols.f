{ ====================================================================
dialogcontrols.f
Pre-defined controls for the Dialog compiler.

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

PACKAGE DLGCOMP

{ --------------------------------------------------------------------
Simple controls are based on the built-in windows control classes.
These are the standard variations on the classes that are
documented in the CreateWindow api call.
-------------------------------------------------------------------- }

$80FFFF CONSTANT #BUTTON
$81FFFF CONSTANT #EDIT
$82FFFF CONSTANT #STATIC
$83FFFF CONSTANT #LIST
$84FFFF CONSTANT #SCROLL
$85FFFF CONSTANT #COMBO

#BUTTON (OR BS_OWNERDRAW WS_BORDER)        CONTROL [DRAWNBUTTON
#BUTTON (OR BS_AUTO3STATE WS_TABSTOP)      CONTROL [AUTO3STATE
#BUTTON (OR BS_AUTOCHECKBOX WS_TABSTOP)    CONTROL [AUTOCHECKBOX
#BUTTON (OR BS_AUTORADIOBUTTON WS_TABSTOP) CONTROL [AUTORADIOBUTTON
#BUTTON (OR BS_CHECKBOX WS_TABSTOP)        CONTROL [CHECKBOX
#BUTTON (OR BS_DEFPUSHBUTTON WS_TABSTOP)   CONTROL [DEFPUSHBUTTON
#BUTTON (OR BS_GROUPBOX WS_GROUP)          CONTROL [GROUPBOX
#BUTTON (OR BS_PUSHBUTTON WS_TABSTOP)      CONTROL [PUSHBUTTON
#BUTTON (OR BS_RADIOBUTTON WS_TABSTOP)     CONTROL [RADIOBUTTON
#BUTTON (OR BS_3STATE WS_TABSTOP)          CONTROL [STATE3
#EDIT   (OR ES_LEFT WS_BORDER WS_TABSTOP)  CONTROL [EDITTEXT
#STATIC (OR WS_BORDER)                     CONTROL [STATIC
#STATIC (OR SS_ICON)                       CONTROL [ICON
#STATIC (OR SS_LEFT WS_GROUP)              CONTROL [LTEXT
#STATIC (OR SS_CENTER WS_GROUP)            CONTROL [CTEXT
#STATIC (OR SS_RIGHT WS_GROUP)             CONTROL [RTEXT
#LIST   (OR LBS_NOTIFY WS_BORDER)          CONTROL [LISTBOX
#SCROLL (OR SBS_HORZ)                      CONTROL [HSCROLLBAR
#SCROLL (OR SBS_VERT)                      CONTROL [VSCROLLBAR
#COMBO  (OR CBS_SIMPLE WS_TABSTOP)         CONTROL [COMBOBOX
#EDIT   (OR ES_MULTILINE ES_READONLY)      CONTROL [TEXTBOX
#EDIT   (OR ES_READONLY)                   CONTROL [TEXT1BOX

#EDIT   (OR ES_LEFT WS_BORDER WS_TABSTOP
            ES_MULTILINE)                  CONTROL [EDITBOX

{ --------------------------------------------------------------------
Windows also comes with extended classes of controls, called
the "common controls".  These are documented in the api, but
are not standard classes and so are defined by their actual
class names.

They are usable in any dialog just like the built-in controls are.
-------------------------------------------------------------------- }

S" msctls_updown32"
   (OR UDS_ALIGNRIGHT UDS_ARROWKEYS
       UDS_AUTOBUDDY UDS_SETBUDDYINT) CONTROL [UPDOWN

S" RichEdit"
   (OR ES_LEFT WS_BORDER WS_TABSTOP
       ES_MULTILINE)                  CONTROL [RICHBOX

S" msctls_progress32"
   (OR WS_GROUP WS_CLIPSIBLINGS)      CONTROL [PROGRESS

S" msctls_trackbar32"
   (OR WS_GROUP WS_CLIPSIBLINGS)      CONTROL [TRACKBAR

END-PACKAGE
