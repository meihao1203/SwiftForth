{ ====================================================================
Color picker

Copyright (C) 2012 FORTH, Inc.   Rick VanNorman

System color choice dialog

Windows uses 20 predefined colors.  These may be referenced by the
"palette index" mode of color specification, rather than by the RGB
model.  In palette index mode, a number from 0-19 occupies the low byte
of the color value, and the upper byte has a value of 1.
==================================================================== }

?( Color picker)

{ ----------------------------------------------------------------------
(COLOR-PICKER) is a modal dialog which uses the advanced layout tools
to build a 4x5 grid of user-drawn buttons. It is intended for use
with a class-based message handler. The ID values for the controls
are sequential, and the message handler for the dialog uses the low
byte of the ID to indicate what color to draw it with. The upper bytes
of the ID are arbitrary.
---------------------------------------------------------------------- }

DIALOG (COLOR-PICKER)

   0 0 =XY  12 12 =WH  12 =XTH 12 =YTH

   [MODAL " Pick Color"  10 10  4 5 XYTH  (CLASS SFDLG) ]

   [DRAWNBUTTON  256   0 0  XYTH  WH ]
   [DRAWNBUTTON  257   1 0  XYTH  WH ]
   [DRAWNBUTTON  258   2 0  XYTH  WH ]
   [DRAWNBUTTON  259   3 0  XYTH  WH ]
   [DRAWNBUTTON  260   0 1  XYTH  WH ]
   [DRAWNBUTTON  261   1 1  XYTH  WH ]
   [DRAWNBUTTON  262   2 1  XYTH  WH ]
   [DRAWNBUTTON  263   3 1  XYTH  WH ]
   [DRAWNBUTTON  264   0 2  XYTH  WH ]
   [DRAWNBUTTON  265   1 2  XYTH  WH ]
   [DRAWNBUTTON  266   2 2  XYTH  WH ]
   [DRAWNBUTTON  267   3 2  XYTH  WH ]
   [DRAWNBUTTON  268   0 3  XYTH  WH ]
   [DRAWNBUTTON  269   1 3  XYTH  WH ]
   [DRAWNBUTTON  270   2 3  XYTH  WH ]
   [DRAWNBUTTON  271   3 3  XYTH  WH ]
   [DRAWNBUTTON  272   0 4  XYTH  WH ]
   [DRAWNBUTTON  273   1 4  XYTH  WH ]
   [DRAWNBUTTON  274   2 4  XYTH  WH ]
   [DRAWNBUTTON  275   3 4  XYTH  WH ]

END-DIALOG

{ ----------------------------------------------------------------------
The behavior of the color picker is defined here. Dialogs present
actions to the message handler as WM_COMMAND messages with WPARAM set to
the control ID which caused the event. We expect the user to either
select a color with the mouse. A negative value returned indicates no
choice.

The alternate default values are IDCANCEL (2) and IDOK (1) which will
return -198 and -199 respectively.

The WM_CTLCOLORBTN gives the dialog box a chance to control the color of
an owner-drawn button. SetDCBrushColor creates a temporary brush handle
that the user is not required to track or delete when done. Simplify!
---------------------------------------------------------------------- }

GENERICDIALOG SUBCLASS COLOR-PICKER

   : TEMPLATE ( -- a )
      (COLOR-PICKER) ;

   WM_COMMAND MESSAGE:
      WPARAM $1F AND $1000000 OR  WPARAM $100 <  OR  CLOSE-DIALOG ;

   WM_CTLCOLORBTN MESSAGE: ( -- hbrush )
      WPARAM  LPARAM GetDlgCtrlID $FF AND  $1000000 OR SetDCBrushColor DROP
      ( DC_BRUSH) 18 GetStockObject ;

   WM_CLOSE MESSAGE: ( -- res )
      -1 CLOSE-DIALOG ;

END-CLASS

: PICKCOLOR ( -- res )
   [OBJECTS COLOR-PICKER MAKES CP OBJECTS]
   HWND CP MODAL ;

