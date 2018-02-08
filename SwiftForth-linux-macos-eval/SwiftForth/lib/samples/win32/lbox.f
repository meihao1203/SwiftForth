{ ====================================================================
Listbox Example

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL LISTBOX A listbox control demonstration

{ --------------------------------------------------------------------
Taken from the Microsoft Windows SDK Listbox Example
Adapted for SwiftForth 25 Feb 1998 Rick VanNorman
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS
DECIMAL EMPTY

ABSENT Z," [IF]

: Z," ( -- )
   [CHAR] " WORD COUNT HERE OVER 1+ ALLOT ZPLACE ;

[THEN]

{ ------------------------------------------------------------------------
Define the softball team data.

ZSKIP moves to the end of an ASCIIZ string.
ADV moves to the next record in our data structure

------------------------------------------------------------------------ }

CREATE TEAM-DATA
   Z," Pete"       Z," shortstop"          26 ,  90  , 608 ,    Z," Rutabaga"
   Z," Suzanna"    Z," catcher"            16 ,  53  , 286 ,    Z," Toast"
   Z," Jack"       Z," pitcher"            27 , 110  , 542 ,    Z," Animal Crackers"
   Z," Karen"      Z," second base"        26 , 140  , 238 ,    Z," Pez"
   Z," Dave"       Z," first base"         28 , 138  , 508 ,    Z," Suds"
   Z," Wendy"      Z," third base"         25 , 154  , 493 ,    Z," Ham"
   Z," Matt"       Z," shortstop"          24 , 112  , 579 ,    Z," Oats"
   Z," Jenny"      Z," right field"        22 , 101  , 509 ,    Z," Mashed Potatoes"
   Z," Seth"       Z," left-center field"  20 ,  76  , 407 ,    Z," Otter Pop"
   Z," Kathie"     Z," left field"         26 , 127  , 353 ,    Z," Baba Ganouj"
   Z," Colin"      Z," pitcher"            26 ,  96  , 456 ,    Z," Lefse"
   Z," Penny"      Z," right field"        24 , 112  , 393 ,    Z," Zotz"
   Z," Art"        Z," left-center field"  17 ,  56  , 375 ,    Z," Cannelloni"
   Z," Cindy"      Z," second base"        13 ,  58  , 207 ,    Z," Tequila"
   Z," David"      Z," center field"       18 , 101  , 612 ,    Z," Bok Choy"
   0 ,

: ZSKIP ( addr -- addr' )
   ZCOUNT + 1+ ;

: ADV ( addr -- addr' )
   DUP @ IF
      ZSKIP ZSKIP 3 CELLS + ZSKIP
   THEN ;

{ ------------------------------------------------------------------------
Define the dialog

We define constants to make life easier and then we don't have to
remember numbers of the parts of the dialog.
------------------------------------------------------------------------ }

100 CONSTANT IDS_SOFTBALL
101 CONSTANT IDS_POSITION
102 CONSTANT IDS_GAME
103 CONSTANT IDS_INN
104 CONSTANT IDS_BA
105 CONSTANT IDS_FOOD

\ 12 MODAL [DIALOG (LBOX) 10 10 250 100 ]
DIALOG (LBOX)
   [MODAL 10 10 250 100 ]

[DEFPUSHBUTTON " OK" IDOK 155 85 30 12 ]
[LISTBOX  IDS_SOFTBALL 5 5 85 95 (+STYLE LBS_SORT WS_VSCROLL) ]

[RTEXT " Position:"        -1 100 10 60 13 ]   [LTEXT  IDS_POSITION  165 10   70 13 ]
[RTEXT " Games played:"    -1 100 25 60 13 ]   [LTEXT  IDS_GAME      165 25   70 13 ]
[RTEXT " Innings played:"  -1 100 40 60 13 ]   [LTEXT  IDS_INN       165 40   70 13 ]
[RTEXT " Batting average:" -1 100 55 60 13 ]   [LTEXT  IDS_BA        165 55   70 13 ]
[RTEXT " Food on jersey:"  -1 100 70 60 13 ]   [LTEXT  IDS_FOOD      165 70   70 13 ]
END-DIALOG

{ ------------------------------------------------------------------------
Dialog actions

ROSTER updates the data from the team data when an item is selected.

ROSTER-INIT builds the team roster in the listbox on WM_INITDIALOG.

LBOX-INIT sets up the listbox and leaves the window focus set to it.

LBOX-CLOSE  simply ends the session.

LBOX-COMMANDS is a switch to deal with WM_COMMAND messages.

LBOX-MESSAGES  is a switch to deal with all primary windows messages to
the dialog.

RUNLBOX is the address of the callback for the dialog procedure.

LBOX sets up and runs the dialog.

------------------------------------------------------------------------ }

: ROSTER ( -- )
   WPARAM LOWORD IDS_SOFTBALL <> ?EXIT
   WPARAM HIWORD LBN_SELCHANGE <> ?EXIT

   HWND IDS_SOFTBALL GetDlgItem >R

   R@ LB_GETCURSEL 0 0 SendMessage ( index)             \ current selection
   R> LB_GETITEMDATA ROT 0 SendMessage  ZSKIP  ( addr)  \ addr of data in roster

   HWND IDS_POSITION THIRD SetDlgItemText DROP    ZSKIP
   HWND IDS_GAME     THIRD @ 0 SetDlgItemInt DROP CELL+
   HWND IDS_INN      THIRD @ 0 SetDlgItemInt DROP CELL+
   HWND IDS_BA       THIRD @ 0 SetDlgItemInt DROP CELL+
   HWND IDS_FOOD     THIRD SetDlgItemText DROP    DROP ;

: ROSTER-INIT ( hwndlist -- )
   TEAM-DATA BEGIN ( hwnd a)
      DUP @ WHILE
      ( h a) 2DUP LB_ADDSTRING 0 ROT SendMessage ( index) >R
      ( h a) 2DUP LB_SETITEMDATA R> ROT  SendMessage DROP
      ADV
   REPEAT 2DROP ;

: LBOX-INIT ( -- )
   HWND IDS_SOFTBALL GetDlgItem DUP ROSTER-INIT   SetFocus DROP ;

: LBOX-CANCEL ( -- res )
   HWND -1 EndDialog ;

: LBOX-CLOSE ( -- res )
   HWND IDS_SOFTBALL GetDlgItem
   LB_GETCURSEL 0 0 SendMessage ( index)             \ current selection
   HWND SWAP EndDialog ;


[SWITCH LBOX-COMMANDS ZERO
   IDOK         RUN: ( -- res )   LBOX-CLOSE ;
   IDCANCEL     RUN: ( -- res )   LBOX-CANCEL ;
   IDS_SOFTBALL RUN: ( -- res )   ROSTER 1 ;
SWITCH]

[SWITCH LBOX-MESSAGES ZERO
   WM_COMMAND    RUN: ( -- res )   WPARAM LOWORD LBOX-COMMANDS ;
   WM_INITDIALOG RUN: ( -- res )   LBOX-INIT 0 ;
   WM_CLOSE      RUN: ( -- res )   LBOX-CLOSE ;
SWITCH]

:NONAME ( -- res )   MSG $FFFF AND LBOX-MESSAGES ;  4 CB: RUNLBOX

: LBOX ( -- res )
   HINST  (LBOX)  HWND  RUNLBOX  0  DialogBoxIndirectParam ;

CR CR .( Type LBOX to run the demo.)  CR CR
